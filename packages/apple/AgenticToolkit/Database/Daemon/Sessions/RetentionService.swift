#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// The empty-session reaper: deletes main-db sessions that are ended and have
/// nothing left anywhere.
///
/// It never deletes event history; that is `TrimService`'s job, and trimming
/// never deletes a main-db `sessions` row. A session is reaped only when all of
/// these hold:
/// - it is ended;
/// - `events.db` has no events, messages or turns for it (an absent store
///   reaps nothing);
/// - no table named in `keepSessionTables` (a daemon's per-session summaries,
///   such as Stenographer's `session_summary`) has a row for it;
/// - its `last_activity_at` is before `lastActivityBefore`, the cutoff of a trim
///   pass that finished (an unparseable or empty `last_activity_at` keeps it).
///
/// The caller runs it only after such a pass: with no cutoff there is nothing
/// to reap against, and a fresh install must delete nothing.
///
/// A session that trimming emptied keeps its summary row, so it is never reaped
/// and keeps its title, project, tokens and cost.
///
/// **Chunked.** One ``runOnce()`` reaps at most `DaemonDatabase.emptySessionReapBatch`
/// sessions and reports ``Outcome/rerun`` while more may remain.
public struct RetentionService: Sendable {

    /// What a pass left behind.
    public enum Outcome: Sendable, Equatable {
        /// Nothing more to reap this cycle.
        case complete
        /// A full batch was reaped; more may remain, so run again.
        case rerun
    }

    public let database: DaemonDatabase
    public let keepSessionTables: [String]
    /// Epoch seconds: only sessions last active before this are reaped.
    public let lastActivityBefore: Double

    public init(database: DaemonDatabase, lastActivityBefore: Double, keepSessionTables: [String] = []) {
        self.database = database
        self.lastActivityBefore = lastActivityBefore
        self.keepSessionTables = keepSessionTables
    }

    /// One batch of empty ended sessions.
    public func runOnce() throws -> Outcome {
        do {
            let reaped = try database.deleteEndedSessionsWithNoEvents(
                keepSessionTables: keepSessionTables, lastActivityBefore: lastActivityBefore)
            if reaped >= DaemonDatabase.emptySessionReapBatch {
                logger.debug("Reaped \(reaped) empty session(s); rescheduling")
                return .rerun
            }
            logger.info("Empty-session reap complete — \(reaped) session(s)")
            return .complete
        } catch {
            logger.error("Empty-session reap failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}

extension RetentionService: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension DaemonDatabase {

    // MARK: - Empty-session reaping

    /// Per-cycle cap on empty-ended-session reaping, shared with ``RetentionService``
    /// so it knows a full batch means "more remain, reschedule".
    public static let emptySessionReapBatch = 500

    /// Deletes up to `batchSize` ended sessions that have nothing in the event
    /// store (no Claude `events`, `messages` or `turns` row) and no row, by
    /// `session_id`, in any of `keepSessionTables`; with `lastActivityBefore`
    /// (epoch seconds), only those whose `last_activity_at` is before it.
    ///
    /// The events live in `events.db`, a separate file, so this is two steps,
    /// never an `ATTACH`: page through the ended sessions here (keyset by id,
    /// `claudeReadChunk` at a time, so kept sessions never block the batch), drop
    /// those with a row in a keep table, ask the store which of the rest have rows,
    /// then delete what is left. With no event store attached, or with a keep
    /// table missing, it reaps nothing: an absent source must never read as "empty".
    ///
    /// The delete re-checks `status = 'ended'`, so a session resumed between the
    /// two steps survives, and it keeps any session that still has legacy
    /// `event_log` rows or a keep-table row written meanwhile, which only ever
    /// makes it reap less.
    @discardableResult
    public func deleteEndedSessionsWithNoEvents(
        batchSize: Int = DaemonDatabase.emptySessionReapBatch,
        keepSessionTables: [String] = [],
        lastActivityBefore: Double? = nil
    ) throws -> Int {
        guard batchSize > 0, let store = eventReads else { return 0 }
        for table in keepSessionTables {
            let plain = !table.isEmpty && table.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0) && $0.isASCII || $0 == "_"
            }
            guard plain, try tableHasColumn(table, "session_id") else { return 0 }
        }
        let page = Self.claudeReadChunk
        // julianday('') is NULL, so a session with no usable clock never passes this.
        let before = lastActivityBefore.map { _ in
            "AND julianday(last_activity_at) < julianday(?, 'unixepoch')"
        } ?? ""
        let beforeParams: [any Sendable] = lastActivityBefore.map { [$0] } ?? []
        var doomed: [String] = []
        var after = ""
        while doomed.count < batchSize {
            var ids: [String] = []
            try query("""
                SELECT session_id FROM sessions
                WHERE status = 'ended' AND session_id > ? \(before)
                ORDER BY session_id LIMIT ?
            """, params: [after] + beforeParams + [page]) { row in ids.append(row[0] ?? "") }
            guard let last = ids.last else { break }
            after = last
            let summarized = try sessionsWithRows(ids, in: keepSessionTables)
            let candidates = ids.filter { !summarized.contains($0) }
            let kept = try Self.sessionsWithStoredRows(candidates, in: store)
            doomed += candidates.filter { !kept.contains($0) }
            if ids.count < page { break }
        }
        doomed = Array(doomed.prefix(batchSize))
        guard !doomed.isEmpty else { return 0 }
        let keepClauses = keepSessionTables.map {
            "AND NOT EXISTS (SELECT 1 FROM \($0) k WHERE k.session_id = sessions.session_id)"
        }.joined(separator: "\n")
        return try write { database in
            var deleted = 0
            for start in stride(from: 0, to: doomed.count, by: page) {
                let chunk = Array(doomed[start..<min(start + page, doomed.count)])
                let marks = chunk.map { _ in "?" }.joined(separator: ",")
                try execute("""
                    DELETE FROM sessions
                    WHERE status = 'ended' AND session_id IN (\(marks)) \(before)
                      AND NOT EXISTS (
                          SELECT 1 FROM event_log WHERE event_log.session_id = sessions.session_id
                      )
                      \(keepClauses)
                """, params: chunk + beforeParams)
                deleted += Int(database.changesCount)
            }
            return deleted
        }
    }

    /// The ids among `sessionIds` (at most `claudeReadChunk`) with a row in any of `tables`.
    private func sessionsWithRows(_ sessionIds: [String], in tables: [String]) throws -> Set<String> {
        guard !sessionIds.isEmpty, !tables.isEmpty else { return [] }
        precondition(sessionIds.count <= Self.claudeReadChunk, "one IN list binds at most claudeReadChunk ids")
        let marks = sessionIds.map { _ in "?" }.joined(separator: ",")
        var found = Set<String>()
        for table in tables {
            try query(
                "SELECT DISTINCT session_id FROM \(table) WHERE session_id IN (\(marks))",
                params: sessionIds
            ) { row in found.insert(row[0] ?? "") }
        }
        return found
    }

    /// The ids among `sessionIds` (at most `claudeReadChunk` of them) that have
    /// at least one Claude `events`, `messages` or `turns` row in `store`.
    private static func sessionsWithStoredRows(_ sessionIds: [String], in store: EventStore) throws -> Set<String> {
        guard !sessionIds.isEmpty else { return [] }
        precondition(sessionIds.count <= claudeReadChunk, "one IN list binds at most claudeReadChunk ids")
        let marks = sessionIds.map { _ in "?" }.joined(separator: ",")
        let provider = ClaudeProvider.name
        let arguments = StatementArguments(
            [provider] + sessionIds + [provider] + sessionIds + [provider] + sessionIds)
        return try store.read { conn in
            let ids = try String.fetchAll(conn, sql: """
                SELECT DISTINCT session_id FROM events WHERE provider = ? AND session_id IN (\(marks))
                UNION
                SELECT DISTINCT session_id FROM messages WHERE provider = ? AND session_id IN (\(marks))
                UNION
                SELECT DISTINCT session_id FROM turns WHERE provider = ? AND session_id IN (\(marks))
                """, arguments: arguments)
            return Set(ids)
        }
    }
}

#endif
