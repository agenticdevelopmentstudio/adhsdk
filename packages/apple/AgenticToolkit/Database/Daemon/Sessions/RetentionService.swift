#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// Deletes old events and empty ended sessions from the daemon database.
///
/// **Opt-in.** Retention permanently deletes event history, so it stays off until
/// `retention_enabled` is explicitly truthy by Core's `RawSetting.bool` rule
/// (1/true/yes/on, any case) in the settings table — see ``isEnabled(_:)``. A seeded
/// `retention_days` is the deletion *window*, not consent to delete.
///
/// **Chunked.** One ``runOnce()`` deletes at most ``batchSize`` events, then reports
/// ``Outcome/rerun`` while more remain, so a multi-month backlog drains across many
/// short passes instead of holding the write lane for minutes. The caller owns the
/// schedule and re-runs on `.rerun`.
///
/// **Ceiling.** `finalizedThrough` returns the latest `yyyy-MM-dd` UTC day whose
/// events may be deleted. A daemon that freezes events into rollups before deleting
/// them passes its rollup watermark; one with no rollup passes `{ nil }`, and `nil`
/// means "no ceiling" — age alone decides.
public struct RetentionService: Sendable {
    /// Events deleted per pass.
    public static let batchSize = 50
    /// The window used when `retention_days` holds no integer.
    public static let defaultRetentionDays = 7

    /// What a pass left behind.
    public enum Outcome: Sendable, Equatable {
        /// The backlog is drained for this cycle.
        case complete
        /// A full batch was deleted; more remain, so run again at once.
        case rerun
    }

    public let database: DaemonDatabase
    public let retentionDays: Int
    public let finalizedThrough: @Sendable () throws -> String?

    public init(
        database: DaemonDatabase,
        retentionDays: Int,
        finalizedThrough: @escaping @Sendable () throws -> String?
    ) {
        self.database = database
        self.retentionDays = retentionDays
        self.finalizedThrough = finalizedThrough
    }

    /// Retention is opt-in: enabled only when `retention_enabled` is explicitly
    /// truthy. Absent, empty or anything else means disabled — the safe default for an
    /// operation that permanently deletes user data.
    public static func isEnabled(_ database: DaemonDatabase) -> Bool {
        RawSetting.bool((try? database.setting(for: "retention_enabled")) ?? nil, default: false)
    }

    /// The deletion window: `retention_days` when it holds an integer, else `fallback`.
    public static func effectiveRetentionDays(
        _ database: DaemonDatabase, fallback: Int = defaultRetentionDays
    ) -> Int {
        if let raw = try? database.setting(for: "retention_days"), let days = Int(raw) {
            return days
        }
        return fallback
    }

    /// One pass: a batch of old events, then — once events are drained — a batch of
    /// empty ended sessions.
    public func runOnce() throws -> Outcome {
        do {
            let deleted = try database.deleteOldEvents(
                olderThanDays: retentionDays,
                batchSize: Self.batchSize,
                notAfterDay: try finalizedThrough()
            )
            if deleted >= Self.batchSize {
                // More to delete — yield the queue and re-fire so other DB-queue
                // waiters can interleave.
                logger.debug("Retention batch deleted \(deleted) event(s); rescheduling")
                return .rerun
            }
            // Event backlog drained for this cycle. Reap empty ended sessions, which
            // is itself batched (LIMIT); if it hit the cap there are more, so
            // reschedule to drain the rest instead of leaving them for tomorrow.
            let deletedSessions = try database.deleteEndedSessionsWithNoEvents()
            if deletedSessions >= DaemonDatabase.emptySessionReapBatch {
                logger.debug("Retention reaped \(deletedSessions) empty session(s); rescheduling")
                return .rerun
            }
            logger.info(
                "Retention cleanup complete — final batch \(deleted) event(s), \(deletedSessions) empty session(s)"
            )
            return .complete
        } catch {
            logger.error("Retention cleanup failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

extension RetentionService: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension DaemonDatabase {

    // MARK: - Retention

    /// Deletes up to `batchSize` event_log rows older than `days`. Single batch only —
    /// the caller loops (see ``RetentionService``). That shares the write lane fairly
    /// with ingest + read handlers instead of holding it across an entire multi-month
    /// backlog. When `notAfterDay` (a `yyyy-MM-dd` UTC day) is supplied, deletion is
    /// additionally capped to events on that day or earlier — a rollup watermark, so a
    /// day's source is never deleted before it is frozen into a daily metric. nil = no
    /// cap.
    @discardableResult
    public func deleteOldEvents(
        olderThanDays days: Int,
        batchSize: Int = 50,
        notAfterDay: String? = nil
    ) throws -> Int {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = fmt.string(from: Date.now.addingTimeInterval(-Double(days) * 86400))
        // "<day>T99" sorts above every real timestamp on that UTC day but below
        // the next day (same trick as the daily-metric recompute); index-friendly.
        let watermarkClause = notAfterDay != nil ? "AND timestamp <= ?" : ""
        var params: [any Sendable] = [cutoff]
        if let notAfterDay { params.append(notAfterDay + "T99") }
        params.append(batchSize)
        return try write { database in
            try execute("""
                DELETE FROM event_log
                WHERE rowid IN (
                    SELECT rowid FROM event_log
                    WHERE timestamp <= ? \(watermarkClause)
                    LIMIT ?
                )
            """, params: params)
            return Int(database.changesCount)
        }
    }

    /// Per-cycle cap on empty-ended-session reaping, shared with ``RetentionService``
    /// so it knows a full batch means "more remain, reschedule".
    public static let emptySessionReapBatch = 500

    /// Deletes up to `batchSize` ended sessions that have nothing in the event
    /// store: no `events` row and no `turns` row for the Claude provider.
    ///
    /// The events live in `events.db`, a separate file, so this is two steps,
    /// never an `ATTACH`: page through the ended sessions here (keyset by id,
    /// `claudeReadChunk` at a time, so sessions that do have events never block
    /// the batch), ask the store which of each page have rows, then delete the
    /// rest. With no event store attached it reaps nothing: an absent store must
    /// never read as "no events".
    ///
    /// The delete re-checks `status = 'ended'`, so a session resumed between the
    /// two steps survives, and it keeps any session that still has legacy
    /// `event_log` rows, which only ever makes it reap less.
    @discardableResult
    public func deleteEndedSessionsWithNoEvents(
        batchSize: Int = DaemonDatabase.emptySessionReapBatch
    ) throws -> Int {
        guard batchSize > 0, let store = eventReads else { return 0 }
        let page = Self.claudeReadChunk
        var doomed: [String] = []
        var after = ""
        while doomed.count < batchSize {
            var ids: [String] = []
            try query("""
                SELECT session_id FROM sessions
                WHERE status = 'ended' AND session_id > ?
                ORDER BY session_id LIMIT ?
            """, params: [after, page]) { row in ids.append(row[0] ?? "") }
            guard let last = ids.last else { break }
            after = last
            let kept = try Self.sessionsWithStoredRows(ids, in: store)
            doomed += ids.filter { !kept.contains($0) }
            if ids.count < page { break }
        }
        doomed = Array(doomed.prefix(batchSize))
        guard !doomed.isEmpty else { return 0 }
        return try write { database in
            var deleted = 0
            for start in stride(from: 0, to: doomed.count, by: page) {
                let chunk = Array(doomed[start..<min(start + page, doomed.count)])
                let marks = chunk.map { _ in "?" }.joined(separator: ",")
                try execute("""
                    DELETE FROM sessions
                    WHERE status = 'ended' AND session_id IN (\(marks))
                      AND NOT EXISTS (
                          SELECT 1 FROM event_log WHERE event_log.session_id = sessions.session_id
                      )
                """, params: chunk)
                deleted += Int(database.changesCount)
            }
            return deleted
        }
    }

    /// The ids among `sessionIds` (at most `claudeReadChunk` of them) that have
    /// at least one Claude `events` or `turns` row in `store`.
    private static func sessionsWithStoredRows(_ sessionIds: [String], in store: EventStore) throws -> Set<String> {
        guard !sessionIds.isEmpty else { return [] }
        precondition(sessionIds.count <= claudeReadChunk, "one IN list binds at most claudeReadChunk ids")
        let marks = sessionIds.map { _ in "?" }.joined(separator: ",")
        let provider = ClaudeProvider.name
        let arguments = StatementArguments([provider] + sessionIds + [provider] + sessionIds)
        return try store.read { conn in
            let ids = try String.fetchAll(conn, sql: """
                SELECT DISTINCT session_id FROM events WHERE provider = ? AND session_id IN (\(marks))
                UNION
                SELECT DISTINCT session_id FROM turns WHERE provider = ? AND session_id IN (\(marks))
                """, arguments: arguments)
            return Set(ids)
        }
    }
}

#endif
