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

/// One Claude row of the event store's `messages` table, as the Conversations
/// feed reads it: `time` is epoch seconds (0 for a line that carried no
/// timestamp) and `attrs` the stored JSON object text.
public struct ClaudeMessageRow: Sendable, Equatable {
    public let id: Int64
    public let sessionId: String
    public let role: String
    public let time: Double
    public let text: String
    public let attrs: String

    public init(id: Int64, sessionId: String, role: String, time: Double, text: String, attrs: String) {
        self.id = id
        self.sessionId = sessionId
        self.role = role
        self.time = time
        self.text = text
        self.attrs = attrs
    }

    /// `time` as the feed's wire timestamp: ISO-8601 UTC with milliseconds,
    /// rounded to the nearest one — the precision transcripts write, and what
    /// a timestamp read back from a stored `…00.123Z` must render as again
    /// (the stored double is a hair below it).
    public var timestamp: String { Self.timestamp(time) }

    public static func timestamp(_ time: Double) -> String {
        let millis = Int((time * 1000).rounded())
        let (seconds, fraction) = (millis >= 0 ? millis / 1000 : (millis - 999) / 1000, ((millis % 1000) + 1000) % 1000)
        let whole = UTCTimestamp.string(epochSeconds: seconds)
        return String(whole.dropLast()) + String(format: ".%03dZ", fraction)
    }
}

/// How `claudeTurnTotals` keys its rows: one key for everything, the model,
/// or the session id.
public enum ClaudeTurnGrouping: Sendable {
    case all, model, session
}

/// One turn as `claudeTurnArrivals` reads it: `time` is nil for another
/// provider's turn or an untimed one; `rawRef` is the archive record it came from.
public struct ClaudeTurnArrival: Sendable, Equatable {
    public let id: Int64
    public let time: Double?
    public let sessionId: String
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheCreationTokens: Int
    public let cacheCreation1hTokens: Int
    public let rawRef: Int64?

    public init(id: Int64, time: Double?, sessionId: String = "", model: String = "", inputTokens: Int = 0,
                outputTokens: Int = 0, cacheReadTokens: Int = 0, cacheCreationTokens: Int = 0,
                cacheCreation1hTokens: Int = 0, rawRef: Int64? = nil) {
        self.id = id
        self.time = time
        self.sessionId = sessionId
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheCreation1hTokens = cacheCreation1hTokens
        self.rawRef = rawRef
    }
}

/// Token totals of one (key, model) group of Claude turns. `key` is `"all"`,
/// the model or the session id, per the read's `ClaudeTurnGrouping`; `model`
/// is "" for turns that carried none.
public struct ClaudeTurnTotals: Sendable, Equatable {
    public let key: String
    public let model: String
    public let turnCount: Int
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheCreationTokens: Int
    public let cacheCreation1hTokens: Int

    public init(key: String, model: String, turnCount: Int, inputTokens: Int, outputTokens: Int,
                cacheReadTokens: Int, cacheCreationTokens: Int, cacheCreation1hTokens: Int) {
        self.key = key
        self.model = model
        self.turnCount = turnCount
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreationTokens = cacheCreationTokens
        self.cacheCreation1hTokens = cacheCreation1hTokens
    }

    func adding(_ other: ClaudeTurnTotals) -> ClaudeTurnTotals {
        ClaudeTurnTotals(
            key: key, model: model, turnCount: turnCount + other.turnCount,
            inputTokens: inputTokens + other.inputTokens, outputTokens: outputTokens + other.outputTokens,
            cacheReadTokens: cacheReadTokens + other.cacheReadTokens,
            cacheCreationTokens: cacheCreationTokens + other.cacheCreationTokens,
            cacheCreation1hTokens: cacheCreation1hTokens + other.cacheCreation1hTokens)
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
    /// `deadline` nil is the store's own read deadline. Internal so the other
    /// Claude read extensions in this module share it.
    func withEventReads<T>(
        _ empty: T, deadline: Duration? = nil, _ body: (Database) throws -> T
    ) throws -> T {
        guard let store = eventReads else { return empty }
        return try store.read(deadline: deadline, body)
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

    /// The PreToolUse lookup behind `claudeToolDurationMs`; arguments are provider,
    /// tool_use_id, session_id. It repeats `events_tool_use_id`'s expression and
    /// its `json_valid(attrs)` predicate so the planner can use that partial index;
    /// the unary `+` keeps `session_id` and `provider_type` off the other indexes,
    /// so the plan does not depend on the planner's tie-break.
    static let claudeToolDurationSQL = """
        SELECT time FROM events
        WHERE provider = ? AND json_extract(attrs,'$.tool_use_id') = ? AND json_valid(attrs)
          AND +session_id = ? AND +provider_type = 'PreToolUse'
        ORDER BY id DESC
        LIMIT 1
        """

    /// Milliseconds from the session's newest `PreToolUse` carrying `toolUseId` to
    /// `postTime` (epoch seconds), or nil when there is no such `PreToolUse` or
    /// it is later than `postTime`. What a `PostToolUse` / `PostToolUseFailure`
    /// detail reports as `duration_ms`.
    public func claudeToolDurationMs(sessionId: String, toolUseId: String, postTime: Double) throws -> Int? {
        guard !sessionId.isEmpty, !toolUseId.isEmpty else { return nil }
        let preTime: Double? = try withEventReads(nil) { conn in
            try Double.fetchOne(
                conn, sql: Self.claudeToolDurationSQL, arguments: [ClaudeProvider.name, toolUseId, sessionId])
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

    // MARK: - Messages and titles

    /// User and assistant messages of the main thread (a sub-agent's sidechain
    /// is a different conversation), newest first by time, then by id — the
    /// order they were stored in. `sessionId` nil is every session; `before`
    /// (epoch seconds) keeps only messages strictly earlier.
    ///
    /// A message whose line carried no timestamp (stored at about the epoch,
    /// below `claudeEarliestKnownEventTime`) is not part of the timeline and
    /// is left out, as the transcript-line feed left out an empty timestamp:
    /// sorted below everything, such lines would fill the oldest page and could
    /// never be paged past.
    public func claudeConversationMessages(
        sessionId: String?, before: Double?, limit: Int
    ) throws -> [ClaudeMessageRow] {
        var conditions = ["provider = ?", "is_sidechain = 0", "role IN ('user', 'assistant')", "time >= ?"]
        var arguments: [any DatabaseValueConvertible] = [ClaudeProvider.name, Self.claudeEarliestKnownEventTime]
        if let sessionId {
            conditions.append("session_id = ?")
            arguments.append(sessionId)
        }
        if let before {
            conditions.append("time < ?")
            arguments.append(before)
        }
        arguments.append(max(limit, 0))
        // `messages_session_time (provider, session_id, time)` answers the
        // scoped read in order and `messages_time (provider, time)` the merged
        // one, so `LIMIT` stops either scan instead of sorting the table.
        let sql = """
            SELECT id, session_id, role, time, COALESCE(text, ''), attrs FROM messages
            WHERE \(conditions.joined(separator: " AND "))
            ORDER BY time DESC, id DESC
            LIMIT ?
            """
        return try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: sql, arguments: StatementArguments(arguments)).map { row in
                ClaudeMessageRow(
                    id: row[0] ?? 0, sessionId: row[1] ?? "", role: row[2] ?? "", time: row[3] ?? 0,
                    text: row[4] ?? "", attrs: row[5] ?? "{}")
            }
        }
    }

    /// The session's `custom-title` titles, newest first by event time (then
    /// id). Empty titles are left out.
    public func claudeCustomTitles(sessionId: String) throws -> [String] {
        try withEventReads([]) { conn in
            try String.fetchAll(conn, sql: """
                SELECT COALESCE(json_extract(attrs, '$.title'), summary, '') FROM events
                WHERE provider = ? AND session_id = ? AND provider_type = 'custom-title'
                ORDER BY time DESC, id DESC
                """, arguments: [ClaudeProvider.name, sessionId])
            .filter { !$0.isEmpty }
        }
    }

    /// Whether the store holds any message for the session.
    public func claudeHasMessages(sessionId: String) throws -> Bool {
        try withEventReads(false) { conn in
            try Bool.fetchOne(conn, sql: """
                SELECT EXISTS(SELECT 1 FROM messages WHERE provider = ? AND session_id = ?)
                """, arguments: [ClaudeProvider.name, sessionId]) ?? false
        }
    }

    // MARK: - Turns

    /// The time-range and tool filters of a turn read, with their arguments
    /// (the provider first). A ranged read leaves out turns stored before
    /// `claudeEarliestKnownEventTime` — a line with no timestamp sits at the
    /// epoch, and a range must never catch it.
    ///
    /// A ranged read that names no sessions binds the provider through
    /// ``claudeProviderOfTimeRead`` so `turns_time` answers it; one scoped to
    /// sessions (`sessionScoped`) keeps `provider = ?` for `turns_session`.
    ///
    /// `throughTurnId` keeps only turns with `id <= throughTurnId` (nil: all).
    static func claudeTurnFilter(
        since: Double?, until: Double?, toolName: String?, sessionScoped: Bool, throughTurnId: Int64? = nil
    ) -> (conditions: [String], arguments: [any DatabaseValueConvertible]) {
        let ranged = since != nil || until != nil
        var conditions = [ranged && !sessionScoped ? claudeProviderOfTimeRead : "provider = ?"]
        var arguments: [any DatabaseValueConvertible] = [ClaudeProvider.name]
        if since != nil || until != nil {
            conditions.append("time >= ?")
            arguments.append(claudeEarliestKnownEventTime)
        }
        if let since {
            conditions.append("time >= ?")
            arguments.append(since)
        }
        if let until {
            conditions.append("time < ?")
            arguments.append(until)
        }
        if let toolName, !toolName.isEmpty {
            conditions.append("tool_name = ?")
            arguments.append(toolName)
        }
        if let throughTurnId {
            conditions.append("id <= ?")
            arguments.append(throughTurnId)
        }
        return (conditions, arguments)
    }

    /// Token totals of the Claude turns matching the filters, one row per
    /// (group key, model) — a model's rate applies only to its own tokens, so a
    /// caller pricing the rows never prices a mixed sum.
    ///
    /// - `since`/`until`: epoch seconds, `[since, until)`; either one also drops
    ///   untimed turns (see `claudeTurnFilter`).
    /// - `sessionIds`: nil reads every session; a list (any length — it binds in
    ///   chunks) reads only those, and an empty list reads nothing.
    /// - `topKeys`: keep only the that-many keys with the most turns (ties by
    ///   key), every model row of each. Without session ids the cut is made in
    ///   SQL, so a whole-history read never materialises every group.
    /// - `throughTurnId`: count only turns with `turns.id` at most this (nil: all)
    ///   — what a summary that has read the turns up to an id needs.
    /// - `deadline`: nil is the store's read deadline; a whole-store scan
    ///   (repricing) passes `DaemonDatabase.maintenanceReadDeadline`.
    public func claudeTurnTotals(
        since: Double? = nil,
        until: Double? = nil,
        toolName: String? = nil,
        sessionIds: [String]? = nil,
        groupBy: ClaudeTurnGrouping = .all,
        topKeys: Int? = nil,
        throughTurnId: Int64? = nil,
        deadline: Duration? = nil
    ) throws -> [ClaudeTurnTotals] {
        let unique = sessionIds.map { Array(Set($0)).sorted() }
        if let unique, unique.isEmpty { return [] }
        let filter = Self.claudeTurnFilter(
            since: since, until: until, toolName: toolName, sessionScoped: unique != nil,
            throughTurnId: throughTurnId)
        let keySQL: String
        switch groupBy {
        case .all: keySQL = "'all'"
        case .model: keySQL = "COALESCE(model, '')"
        case .session: keySQL = "session_id"
        }
        let select = """
            SELECT \(keySQL), COALESCE(model, ''), COUNT(*),
                   COALESCE(SUM(input_tokens), 0), COALESCE(SUM(output_tokens), 0),
                   COALESCE(SUM(cache_read_tokens), 0), COALESCE(SUM(cache_write_tokens), 0),
                   CAST(COALESCE(SUM(json_extract(attrs, '$.cache_creation_1h_tokens')), 0) AS INTEGER)
            FROM turns
            """
        func totals(_ row: Row) -> ClaudeTurnTotals {
            ClaudeTurnTotals(
                key: row[0] ?? "", model: row[1] ?? "", turnCount: row[2] ?? 0, inputTokens: row[3] ?? 0,
                outputTokens: row[4] ?? 0, cacheReadTokens: row[5] ?? 0, cacheCreationTokens: row[6] ?? 0,
                cacheCreation1hTokens: row[7] ?? 0)
        }

        let rows: [ClaudeTurnTotals] = try withEventReads([], deadline: deadline) { conn in
            guard let unique else {
                let whereSQL = filter.conditions.joined(separator: " AND ")
                if let topKeys, groupBy != .all {
                    // Rank the keys in their own pass, then aggregate only the winners.
                    let arguments = filter.arguments + [max(topKeys, 0)] + filter.arguments
                    return try Row.fetchAll(conn, sql: """
                        WITH ranked AS (
                            SELECT \(keySQL) AS rank_key FROM turns
                            WHERE \(whereSQL)
                            GROUP BY \(keySQL)
                            ORDER BY COUNT(*) DESC, rank_key
                            LIMIT ?
                        )
                        \(select)
                        WHERE \(whereSQL) AND \(keySQL) IN (SELECT rank_key FROM ranked)
                        GROUP BY \(keySQL), COALESCE(model, '')
                        """, arguments: StatementArguments(arguments)).map(totals)
                }
                return try Row.fetchAll(conn, sql: """
                    \(select)
                    WHERE \(whereSQL)
                    GROUP BY \(keySQL), COALESCE(model, '')
                    """, arguments: StatementArguments(filter.arguments)).map(totals)
            }
            var merged: [String: ClaudeTurnTotals] = [:]
            for start in stride(from: 0, to: unique.count, by: Self.claudeReadChunk) {
                let chunk = Array(unique[start..<min(start + Self.claudeReadChunk, unique.count)])
                let marks = chunk.map { _ in "?" }.joined(separator: ",")
                let conditions = filter.conditions + ["session_id IN (\(marks))"]
                let arguments = filter.arguments + chunk.map { $0 as any DatabaseValueConvertible }
                for row in try Row.fetchAll(conn, sql: """
                    \(select)
                    WHERE \(conditions.joined(separator: " AND "))
                    GROUP BY \(keySQL), COALESCE(model, '')
                    """, arguments: StatementArguments(arguments)).map(totals) {
                    let id = "\(row.key)\u{0}\(row.model)"
                    merged[id] = merged[id].map { $0.adding(row) } ?? row
                }
            }
            return Array(merged.values)
        }
        guard let topKeys, unique != nil, groupBy != .all else { return rows }
        var counts: [String: Int] = [:]
        for row in rows { counts[row.key, default: 0] += row.turnCount }
        let kept = Set(counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(max(topKeys, 0)).map(\.key))
        return rows.filter { kept.contains($0.key) }
    }

    /// The sums of the Claude turns the storage trim deleted, one row per
    /// (session, model), keyed by session id (`EventStore` `trimmed_turns`).
    /// Empty without an attached store.
    public func claudeTrimmedTurnTotals(deadline: Duration? = nil) throws -> [ClaudeTurnTotals] {
        try withEventReads([], deadline: deadline) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT session_id, model, turn_count, input_tokens, output_tokens,
                       cache_read_tokens, cache_write_tokens, cache_write_1h_tokens
                FROM trimmed_turns WHERE provider = ?
                """, arguments: [ClaudeProvider.name]).map { row in
                ClaudeTurnTotals(
                    key: row[0], model: row[1], turnCount: row[2], inputTokens: row[3], outputTokens: row[4],
                    cacheReadTokens: row[5], cacheCreationTokens: row[6], cacheCreation1hTokens: row[7])
            }
        }
    }

    /// Every Claude turn's (session, time) in `[since, until)` (epoch seconds),
    /// ordered by session then time — what the active-hours walk needs. Untimed
    /// turns are left out. `sessionIds`, `throughTurnId` and `deadline` as in
    /// `claudeTurnTotals`.
    public func claudeTurnTimes(
        since: Double, until: Double, sessionIds: [String]?, throughTurnId: Int64? = nil,
        deadline: Duration? = nil
    ) throws -> [(sessionId: String, time: Double)] {
        let unique = sessionIds.map { Array(Set($0)).sorted() }
        if let unique, unique.isEmpty { return [] }
        let filter = Self.claudeTurnFilter(since: since, until: until, toolName: nil, sessionScoped: unique != nil,
                                           throughTurnId: throughTurnId)
        func fetch(_ conn: Database, _ chunk: [String]?) throws -> [(sessionId: String, time: Double)] {
            var conditions = filter.conditions
            var arguments = filter.arguments
            if let chunk {
                conditions.append("session_id IN (\(chunk.map { _ in "?" }.joined(separator: ",")))")
                arguments += chunk.map { $0 as any DatabaseValueConvertible }
            }
            return try Row.fetchAll(conn, sql: """
                SELECT session_id, time FROM turns
                WHERE \(conditions.joined(separator: " AND "))
                ORDER BY session_id, time
                """, arguments: StatementArguments(arguments)).map { (sessionId: $0[0] ?? "", time: $0[1] ?? 0) }
        }
        return try withEventReads([], deadline: deadline) { conn in
            guard let unique else { return try fetch(conn, nil) }
            // Chunks are cut from the sorted ids, so concatenating them keeps the order.
            var out: [(sessionId: String, time: Double)] = []
            for start in stride(from: 0, to: unique.count, by: Self.claudeReadChunk) {
                out += try fetch(conn, Array(unique[start..<min(start + Self.claudeReadChunk, unique.count)]))
            }
            return out
        }
    }

    /// One Claude turn by its dedup key (a transcript turn's message id), as the
    /// columns of a stored turn: `time` epoch seconds (0 when untimed), `attrs`
    /// the JSON object text.
    func claudeTurn(dedupKey: String) throws -> Row? {
        try withEventReads(nil) { conn in
            try Row.fetchOne(conn, sql: """
                SELECT session_id, time, COALESCE(json_extract(attrs, '$.kind'), ''), COALESCE(model, ''),
                       input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
                       COALESCE(tool_name, ''), COALESCE(json_extract(attrs, '$.is_subagent'), 0),
                       COALESCE(agent, '')
                FROM turns WHERE provider = ? AND dedup_key = ?
                """, arguments: [ClaudeProvider.name, dedupKey])
        }
    }

    /// Claude turns in the store, optionally for one session.
    public func claudeTurnCount(sessionId: String? = nil) throws -> Int {
        try withEventReads(0) { conn in
            if let sessionId {
                return try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM turns WHERE provider = ? AND session_id = ?",
                                        arguments: [ClaudeProvider.name, sessionId]) ?? 0
            }
            return try Int.fetchOne(
                conn, sql: "SELECT COUNT(*) FROM turns WHERE provider = ?", arguments: [ClaudeProvider.name]) ?? 0
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
