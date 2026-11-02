#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

/// One Claude row of the event store's `events` table, as the session database's
/// readers hand it on: `providerType` is the hook name (the legacy `event_type`),
/// `summary` the legacy `detail`, and `id` the id every event DTO carries.
public struct ClaudeEventRow: Sendable, Equatable {
    public let id: Int64
    public let sessionId: String
    public let providerType: String
    public let time: Double
    public let cwd: String
    public let toolName: String
    public let summary: String
    public let attrs: String
    public let rawRef: Int64

    public init(id: Int64, sessionId: String, providerType: String, time: Double, cwd: String,
                toolName: String, summary: String, attrs: String, rawRef: Int64) {
        self.id = id
        self.sessionId = sessionId
        self.providerType = providerType
        self.time = time
        self.cwd = cwd
        self.toolName = toolName
        self.summary = summary
        self.attrs = attrs
        self.rawRef = rawRef
    }

    /// `time` as the wire instant every event DTO carries: whole seconds, UTC,
    /// `Z` — what `ISO8601DateFormatter` with `.withInternetDateTime` writes.
    public var timestamp: String { Self.timestamp(time) }

    public static func timestamp(_ time: Double) -> String {
        UTCTimestamp.string(from: Date(timeIntervalSince1970: time))
    }
}

/// Every read the session database's readers make of the event store
/// (`events.db`) and the raw archive. Each binds the Claude provider, and each
/// answers empty — never throws — when no event store is attached
/// (`DaemonDatabase.eventReads` is nil). Reads that need the session database
/// too are two steps in Swift, never an `ATTACH`.
extension DaemonDatabase {

    /// The columns `claudeEventRow(_:)` reads, by position.
    private static let claudeEventColumns = """
        id, session_id, provider_type, time, COALESCE(cwd, ''), COALESCE(tool_name, ''),
        COALESCE(summary, ''), attrs, raw_ref
        """

    /// How many session ids one `IN (…)` binds.
    static let claudeReadChunk = 500

    private static func claudeEventRow(_ row: Row) -> ClaudeEventRow {
        ClaudeEventRow(
            id: row[0] ?? 0, sessionId: row[1] ?? "", providerType: row[2] ?? "", time: row[3] ?? 0,
            cwd: row[4] ?? "", toolName: row[5] ?? "", summary: row[6] ?? "", attrs: row[7] ?? "{}",
            rawRef: row[8] ?? 0)
    }

    /// Runs `body` on the event store's reader, or returns `empty` without one.
    private func withEventReads<T>(_ empty: T, _ body: (Database) throws -> T) throws -> T {
        guard let store = eventReads else { return empty }
        return try store.read(body)
    }

    // MARK: - Counts

    /// Events per session for the given sessions; a session with none is absent.
    public func claudeEventCounts(sessionIds: [String]) throws -> [String: Int] {
        let unique = Array(Set(sessionIds))
        guard !unique.isEmpty else { return [:] }
        return try withEventReads([:]) { conn in
            var counts: [String: Int] = [:]
            for start in stride(from: 0, to: unique.count, by: Self.claudeReadChunk) {
                let chunk = Array(unique[start..<min(start + Self.claudeReadChunk, unique.count)])
                let marks = chunk.map { _ in "?" }.joined(separator: ",")
                let rows = try Row.fetchAll(conn, sql: """
                    SELECT session_id, COUNT(*) FROM events
                    WHERE provider = ? AND session_id IN (\(marks))
                    GROUP BY session_id
                    """, arguments: StatementArguments([ClaudeProvider.name] + chunk))
                for row in rows {
                    counts[row[0] ?? ""] = row[1] ?? 0
                }
            }
            return counts
        }
    }

    /// Every Claude event in the store.
    public func claudeEventTotal() throws -> Int {
        try withEventReads(0) { conn in
            try Int.fetchOne(
                conn, sql: "SELECT COUNT(*) FROM events WHERE provider = ?", arguments: [ClaudeProvider.name]) ?? 0
        }
    }

    // MARK: - Event lists

    /// Events newest first by event time (then id), filtered as the events
    /// endpoints filter. `since` is epoch seconds; an event counts when it falls
    /// in or after that second, as the legacy `datetime()` comparison did.
    /// `excludeRootCwd` drops events whose cwd is `/` (an event without a cwd
    /// stays, as an empty legacy cwd did).
    public func claudeEvents(
        sessionId: String? = nil,
        providerType: String? = nil,
        since: Double? = nil,
        excludeRootCwd: Bool = false,
        limit: Int,
        offset: Int = 0
    ) throws -> [ClaudeEventRow] {
        var conditions = ["provider = ?"]
        var arguments: [any DatabaseValueConvertible] = [ClaudeProvider.name]
        if let sessionId {
            conditions.append("session_id = ?")
            arguments.append(sessionId)
        }
        if let providerType {
            conditions.append("provider_type = ?")
            arguments.append(providerType)
        }
        if let since {
            conditions.append("time >= ?")
            arguments.append(since.rounded(.down))
        }
        if excludeRootCwd {
            conditions.append("COALESCE(cwd, '') != '/'")
        }
        arguments.append(max(limit, 0))
        arguments.append(max(offset, 0))
        let sql = """
            SELECT \(Self.claudeEventColumns) FROM events
            WHERE \(conditions.joined(separator: " AND "))
            ORDER BY time DESC, id DESC
            LIMIT ? OFFSET ?
            """
        return try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: sql, arguments: StatementArguments(arguments)).map(Self.claudeEventRow)
        }
    }

    /// One event by id, or nil.
    public func claudeEvent(id: Int64) throws -> ClaudeEventRow? {
        try withEventReads(nil) { conn in
            try Row.fetchOne(conn, sql: """
                SELECT \(Self.claudeEventColumns) FROM events WHERE provider = ? AND id = ?
                """, arguments: [ClaudeProvider.name, id]).map(Self.claudeEventRow)
        }
    }

    /// The hook name of the session's newest event, or "" when it has none.
    public func claudeLastEventType(sessionId: String) throws -> String {
        try withEventReads("") { conn in
            try String.fetchOne(conn, sql: """
                SELECT provider_type FROM events
                WHERE provider = ? AND session_id = ?
                ORDER BY time DESC, id DESC
                LIMIT 1
                """, arguments: [ClaudeProvider.name, sessionId]) ?? ""
        }
    }

    // MARK: - Tools

    /// `PreToolUse` counts per (session, tool) for the given sessions.
    public func claudeToolUseCounts(
        sessionIds: [String]
    ) throws -> [(sessionId: String, toolName: String, count: Int)] {
        let unique = Array(Set(sessionIds))
        guard !unique.isEmpty else { return [] }
        return try withEventReads([]) { conn in
            var out: [(sessionId: String, toolName: String, count: Int)] = []
            for start in stride(from: 0, to: unique.count, by: Self.claudeReadChunk) {
                let chunk = Array(unique[start..<min(start + Self.claudeReadChunk, unique.count)])
                let marks = chunk.map { _ in "?" }.joined(separator: ",")
                let rows = try Row.fetchAll(conn, sql: """
                    SELECT session_id, tool_name, COUNT(*) FROM events
                    WHERE provider = ? AND provider_type = 'PreToolUse'
                      AND tool_name IS NOT NULL AND tool_name != ''
                      AND session_id IN (\(marks))
                    GROUP BY session_id, tool_name
                    """, arguments: StatementArguments([ClaudeProvider.name] + chunk))
                for row in rows {
                    out.append((sessionId: row[0] ?? "", toolName: row[1] ?? "", count: row[2] ?? 0))
                }
            }
            return out
        }
    }

    /// Milliseconds from the session's newest `PreToolUse` carrying `toolUseId` to
    /// `postTime` (epoch seconds), or nil when there is no such `PreToolUse` or
    /// it is later than `postTime`. What a `PostToolUse` / `PostToolUseFailure`
    /// detail reports as `duration_ms`.
    public func claudeToolDurationMs(sessionId: String, toolUseId: String, postTime: Double) throws -> Int? {
        guard !sessionId.isEmpty, !toolUseId.isEmpty else { return nil }
        let preTime: Double? = try withEventReads(nil) { conn in
            try Double.fetchOne(conn, sql: """
                SELECT time FROM events
                WHERE provider = ? AND session_id = ? AND provider_type = 'PreToolUse'
                  AND json_extract(attrs, '$.tool_use_id') = ?
                ORDER BY id DESC
                LIMIT 1
                """, arguments: [ClaudeProvider.name, sessionId, toolUseId])
        }
        guard let preTime else { return nil }
        let delta = (postTime - preTime) * 1000.0
        guard delta >= 0 else { return nil }
        return Int(delta.rounded())
    }

    // MARK: - Billing

    /// The earliest event time (epoch seconds, 2000-01-01T00:00:00Z) a reader
    /// that derives activity or a time range trusts. The store keeps a
    /// transcript line that carried no timestamp at about epoch 0 — "time
    /// unknown" — and such a row must never become a session's start or a
    /// second of billed work.
    public static let claudeEarliestKnownEventTime: Double = 946_684_800

    /// The session's earliest known event time (epoch seconds), or nil when it
    /// has none. Rows before `claudeEarliestKnownEventTime` are ignored.
    public func claudeFirstEventTime(sessionId: String) throws -> Double? {
        try withEventReads(nil) { conn in
            try Double.fetchOne(conn, sql: """
                SELECT MIN(time) FROM events WHERE provider = ? AND session_id = ? AND time >= ?
                """, arguments: [ClaudeProvider.name, sessionId, Self.claudeEarliestKnownEventTime])
        }
    }

    /// The session's events with an id above `afterId`: id, hook name and event
    /// time. Unordered; the caller sorts. Rows before
    /// `claudeEarliestKnownEventTime` are left out.
    public func claudeEventTimes(
        sessionId: String, afterId: Int64
    ) throws -> [(id: Int64, providerType: String, time: Double)] {
        try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT id, provider_type, time FROM events
                WHERE provider = ? AND session_id = ? AND id > ? AND time >= ?
                """, arguments: [ClaudeProvider.name, sessionId, afterId, Self.claudeEarliestKnownEventTime])
                .map { row in
                    (id: row[0] ?? 0, providerType: row[1] ?? "", time: row[2] ?? 0)
                }
        }
    }

    /// The highest event id the store has ever issued (any provider), 0 for a
    /// store that has issued none, or nil when no store is attached.
    ///
    /// Ids are never reused (`AUTOINCREMENT`), and this is SQLite's own record of
    /// the last one handed out, not `MAX(id)`: retention deleting every row
    /// leaves it where it was. Only a replaced (rebuilt) store numbers from 1
    /// again, so a cursor above this means exactly that.
    public func eventIdHighWater() throws -> Int64? {
        try withEventReads(nil) { conn in
            try Int64.fetchOne(
                conn, sql: "SELECT seq FROM sqlite_sequence WHERE name = 'events'") ?? 0
        }
    }

    // MARK: - Raw archive

    /// What the archive holds behind an event, re-parsed: a hook's `hook_data`, or
    /// a transcript line's JSON object. Nil without an archive, for a missing
    /// record, or for a payload that no longer parses.
    public func claudeArchivedPayload(rawRef: Int64) -> (hookData: [String: Any]?, line: [String: Any]?) {
        guard let archive = rawArchive, let archived = try? archive.record(id: rawRef) else { return (nil, nil) }
        let record = archived.record
        switch record.sourceKind {
        case ClaudeProvider.hookKind, ClaudeProvider.legacyHookKind:
            guard let text = String(data: record.payload, encoding: .utf8),
                  case .event(let parsed) = ParseResult.parse(envelopeJSON: text) else { return (nil, nil) }
            return (parsed.hookData, nil)
        case ClaudeProvider.transcriptKind:
            guard let payload = try? ClaudeTranscriptPayload.decode(record.payload),
                  let object = try? JSONSerialization.jsonObject(with: Data(payload.line.utf8)) as? [String: Any]
            else { return (nil, nil) }
            return (nil, object)
        default:
            return (nil, nil)
        }
    }
}
#endif
