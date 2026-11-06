#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

/// Where a per-type count takes its dimension from: the `tool_name` column, or
/// one top-level key of the event's `attrs` JSON (a hook payload field such
/// as `agent_type` or `trigger`).
public enum ClaudeEventDimension: Sendable, Equatable {
    case toolName
    case attr(String)

    /// The SQL expression reading the dimension off an `events` row, and the
    /// row filter it needs. An attrs key is bound, never spliced, so any key is
    /// safe; `attrs` is opaque TEXT, so a row whose JSON is malformed is skipped
    /// rather than aborting the whole read.
    fileprivate var sql: (expression: String, filter: String, arguments: [any DatabaseValueConvertible]) {
        switch self {
        case .toolName: return ("tool_name", "", [])
        case .attr(let key):
            let quoted = key.replacingOccurrences(of: "\"", with: "\"\"")
            return ("json_extract(attrs, ?)", " AND json_valid(attrs)", ["$.\"\(quoted)\""])
        }
    }
}

/// One `(model, TTL)` group of differenced prompt-cache counters. `attributed`
/// false is the group of deltas whose model or TTL changed between the two
/// ticks — counted, but never priced.
public struct ClaudeCacheMissGroup: Sendable, Equatable {
    public let attributed: Bool
    public let model: String
    public let ttl: String
    public let misses: Int
    public let requests: Int
    public let recacheTokens: Int

    public init(attributed: Bool, model: String, ttl: String, misses: Int, requests: Int, recacheTokens: Int) {
        self.attributed = attributed
        self.model = model
        self.ttl = ttl
        self.misses = misses
        self.requests = requests
        self.recacheTokens = recacheTokens
    }
}

/// One session's events within a time range, as
/// `DaemonDatabase.claudeSessionEventActivity(from:until:deadline:)` reads them.
public struct ClaudeSessionEventActivity: Sendable, Equatable {
    public let sessionId: String
    public let eventCount: Int
    public let firstTime: Double
    public let lastTime: Double
    /// The newest non-empty `cwd` in the range, or "".
    public let cwd: String

    public init(sessionId: String, eventCount: Int, firstTime: Double, lastTime: Double, cwd: String) {
        self.sessionId = sessionId
        self.eventCount = eventCount
        self.firstTime = firstTime
        self.lastTime = lastTime
        self.cwd = cwd
    }
}

/// The insights and daily-rollup reads over the event store's Claude events.
///
/// Every read binds the Claude provider, leaves out rows before
/// ``DaemonDatabase/claudeEarliestKnownEventTime`` (an event whose time is
/// unknown), and answers empty when no event store is attached. Days are UTC
/// (`date(time, 'unixepoch')`). `from` is inclusive and `until` exclusive, both
/// epoch seconds; nil is no bound.
extension DaemonDatabase {

    /// The provider condition of an `events` or `turns` read bounded by time
    /// and nothing narrower. Those tables index time alone (`events_time`,
    /// `turns_time`) beside provider-led indexes (`(provider, session_id,
    /// time)`, `(provider, provider_type, time)`). Given a bare `provider = ?`,
    /// SQLite picks a provider-led index, and with one provider in the store
    /// that walks every row of it: a one-day read of a 10 GB store took
    /// minutes. The unary `+` keeps the condition but takes it out of index
    /// selection, so the time index answers. A read that also names a session
    /// or a hook type keeps the bare form, which its own index answers.
    static let claudeProviderOfTimeRead = "+provider = ?"

    /// The time condition every read here shares, with its arguments.
    private static func claudeTimeRange(
        from: Double?, until: Double?
    ) -> (sql: String, arguments: [any DatabaseValueConvertible]) {
        var sql = "time >= ?"
        var arguments: [any DatabaseValueConvertible] = [max(from ?? claudeEarliestKnownEventTime,
                                                             claudeEarliestKnownEventTime)]
        if let until {
            sql += " AND time < ?"
            arguments.append(until)
        }
        return (sql, arguments)
    }

    // MARK: - Counts by day

    /// Events per UTC day and hook type, unordered.
    public func claudeEventTypeCountsByDay(
        from: Double? = nil, until: Double? = nil, deadline: Duration? = nil
    ) throws -> [(day: String, providerType: String, count: Int)] {
        let range = Self.claudeTimeRange(from: from, until: until)
        return try withEventReads([], deadline: deadline) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT date(time, 'unixepoch') AS day, provider_type, COUNT(*)
                FROM events
                WHERE \(Self.claudeProviderOfTimeRead) AND \(range.sql)
                GROUP BY day, provider_type
                """, arguments: StatementArguments([ClaudeProvider.name] + range.arguments))
                .map { (day: $0[0] ?? "", providerType: $0[1] ?? "", count: $0[2] ?? 0) }
        }
    }

    /// One hook type's events per UTC day and dimension value, unordered. An
    /// event whose dimension is null or empty is left out, as the legacy
    /// per-type rollup left it out.
    public func claudeDimensionCountsByDay(
        providerType: String,
        dimension: ClaudeEventDimension,
        from: Double? = nil,
        until: Double? = nil,
        deadline: Duration? = nil
    ) throws -> [(day: String, dimension: String, count: Int)] {
        let range = Self.claudeTimeRange(from: from, until: until)
        let dim = dimension.sql
        // The dimension expression appears once, in a subquery, so its bound
        // path is bound once.
        let arguments: [any DatabaseValueConvertible] =
            dim.arguments + [ClaudeProvider.name, providerType] + range.arguments
        return try withEventReads([], deadline: deadline) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT day, dim, COUNT(*) FROM (
                    SELECT date(time, 'unixepoch') AS day, CAST(\(dim.expression) AS TEXT) AS dim
                    FROM events
                    WHERE provider = ? AND provider_type = ? AND \(range.sql)\(dim.filter)
                )
                WHERE dim IS NOT NULL AND dim != ''
                GROUP BY day, dim
                """, arguments: StatementArguments(arguments))
                .map { (day: $0[0] ?? "", dimension: $0[1] ?? "", count: $0[2] ?? 0) }
        }
    }

    /// One hook type's events per dimension value over the whole range,
    /// unordered — ``claudeDimensionCountsByDay(providerType:dimension:from:until:deadline:)``
    /// without the day split. Null and empty values are left out.
    public func claudeDimensionCounts(
        providerType: String,
        dimension: ClaudeEventDimension,
        from: Double? = nil,
        until: Double? = nil
    ) throws -> [(dimension: String, count: Int)] {
        let range = Self.claudeTimeRange(from: from, until: until)
        let dim = dimension.sql
        let arguments: [any DatabaseValueConvertible] =
            dim.arguments + [ClaudeProvider.name, providerType] + range.arguments
        return try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT dim, COUNT(*) FROM (
                    SELECT CAST(\(dim.expression) AS TEXT) AS dim
                    FROM events
                    WHERE provider = ? AND provider_type = ? AND \(range.sql)\(dim.filter)
                )
                WHERE dim IS NOT NULL AND dim != ''
                GROUP BY dim
                """, arguments: StatementArguments(arguments))
                .map { (dimension: $0[0] ?? "", count: $0[1] ?? 0) }
        }
    }

    /// How many events fall in the range.
    public func claudeEventCount(from: Double? = nil, until: Double? = nil) throws -> Int {
        let range = Self.claudeTimeRange(from: from, until: until)
        return try withEventReads(0) { conn in
            try Int.fetchOne(conn, sql: """
                SELECT COUNT(*) FROM events WHERE \(Self.claudeProviderOfTimeRead) AND \(range.sql)
                """, arguments: StatementArguments([ClaudeProvider.name] + range.arguments)) ?? 0
        }
    }

    /// Events per (cwd, session) in the range, unordered: what the project
    /// metric folds into last-path-component projects. An event with no cwd
    /// reports `""`.
    public func claudeCwdSessionCounts(
        from: Double? = nil, until: Double? = nil, deadline: Duration? = nil
    ) throws -> [(cwd: String, sessionId: String, count: Int)] {
        let range = Self.claudeTimeRange(from: from, until: until)
        return try withEventReads([], deadline: deadline) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT COALESCE(cwd, ''), session_id, COUNT(*)
                FROM events
                WHERE \(Self.claudeProviderOfTimeRead) AND \(range.sql)
                GROUP BY cwd, session_id
                """, arguments: StatementArguments([ClaudeProvider.name] + range.arguments))
                .map { (cwd: $0[0] ?? "", sessionId: $0[1] ?? "", count: $0[2] ?? 0) }
        }
    }

    /// New sessions per UTC day — distinct sessions with a `SessionStart` that
    /// day — oldest day first.
    public func claudeNewSessionsPerDay(from: Double? = nil) throws -> [(day: String, count: Int)] {
        let range = Self.claudeTimeRange(from: from, until: nil)
        return try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT date(time, 'unixepoch') AS day, COUNT(DISTINCT session_id)
                FROM events
                WHERE provider = ? AND provider_type = 'SessionStart' AND \(range.sql)
                GROUP BY day
                ORDER BY day ASC
                """, arguments: StatementArguments([ClaudeProvider.name] + range.arguments))
                .map { (day: $0[0] ?? "", count: $0[1] ?? 0) }
        }
    }

    // MARK: - Days present

    /// The earliest known event time, or nil when there is none.
    public func claudeEarliestEventTime(deadline: Duration? = nil) throws -> Double? {
        try withEventReads(nil, deadline: deadline) { conn in
            try Double.fetchOne(conn, sql: """
                SELECT MIN(time) FROM events WHERE \(Self.claudeProviderOfTimeRead) AND time >= ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime])
        }
    }

    /// The distinct UTC days holding an event in the range, oldest first, at
    /// most `limit` of them.
    ///
    /// Found by seeking, never by scanning: each day is one probe for the
    /// earliest event at or after the start of the day after the last one
    /// found, which the `events_time` index answers from its left edge. So the cost is one probe per day
    /// returned, however many events the range holds, and a `limit` stops the
    /// walk instead of trimming a sorted whole-range result. Empty calendar
    /// gaps cost nothing: the next probe lands on the next day that has events.
    public func claudeEventDays(
        from: Double? = nil, until: Double? = nil, limit: Int? = nil, deadline: Duration? = nil
    ) throws -> [String] {
        try claudeDays(table: .events, from: from, until: until, limit: limit, deadline: deadline)
    }

    /// The distinct UTC days holding a turn in the range, oldest first, at most
    /// `limit` of them — ``claudeEventDays(from:until:limit:deadline:)``'s seek
    /// walk over `turns` (its `turns_time` index). A transcript import lands
    /// turns on days no hook event covers, so a reader summarising turns per
    /// day must walk these as well as the event days.
    public func claudeTurnDays(
        from: Double? = nil, until: Double? = nil, limit: Int? = nil, deadline: Duration? = nil
    ) throws -> [String] {
        try claudeDays(table: .turns, from: from, until: until, limit: limit, deadline: deadline)
    }

    /// The turns stored after `afterId` (`turns.id`), in id order, at most
    /// `limit`: each one's id, and its time when it is a Claude turn (nil for
    /// another provider's, so a cursor still moves past it). A new turn gets a
    /// larger id than every turn held, so walking ids from a saved cursor finds
    /// the turns that arrived since, whatever day they belong to.
    ///
    /// Each arrival carries the turn's own columns, so a caller can add it to a
    /// summary whose day no longer holds the turns to recount.
    public func claudeTurnArrivals(
        afterId: Int64, limit: Int, deadline: Duration? = nil
    ) throws -> [ClaudeTurnArrival] {
        guard limit > 0 else { return [] }
        return try withEventReads([], deadline: deadline) { conn in
            try Row.fetchAll(conn, sql: """
                SELECT id, CASE WHEN provider = ? AND time >= ? THEN time END, session_id, COALESCE(model, ''),
                       COALESCE(input_tokens, 0), COALESCE(output_tokens, 0),
                       COALESCE(cache_read_tokens, 0), COALESCE(cache_write_tokens, 0),
                       CAST(COALESCE(json_extract(attrs, '$.cache_creation_1h_tokens'), 0) AS INTEGER), raw_ref
                FROM turns WHERE id > ? ORDER BY id LIMIT ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime, afterId, limit])
                .map { row in
                    ClaudeTurnArrival(
                        id: row[0] ?? 0, time: row[1], sessionId: row[2] ?? "", model: row[3] ?? "",
                        inputTokens: row[4] ?? 0, outputTokens: row[5] ?? 0, cacheReadTokens: row[6] ?? 0,
                        cacheCreationTokens: row[7] ?? 0, cacheCreation1hTokens: row[8] ?? 0, rawRef: row[9])
                }
        }
    }

    /// The history backfill's target archive id (`store_meta`
    /// ``ClaudeArchiveReplay/backfillTargetKey``), or nil when none was ever set.
    /// It stays after the backfill finishes: a turn whose `raw_ref` is at most it
    /// came from history the cutover's converted summaries already count, and a
    /// larger one was captured live.
    public func claudeHistoryBackfillTarget(deadline: Duration? = nil) throws -> Int64? {
        try withEventReads(nil, deadline: deadline) { conn in
            try String.fetchOne(conn, sql: "SELECT value FROM store_meta WHERE key = ?",
                                arguments: [ClaudeArchiveReplay.backfillTargetKey]).flatMap { Int64($0) }
        }
    }

    /// The largest `turns.id` held, every provider; 0 when there are none.
    public func turnsMaxId(deadline: Duration? = nil) throws -> Int64 {
        try withEventReads(0, deadline: deadline) { conn in
            try Int64.fetchOne(conn, sql: "SELECT COALESCE(MAX(id), 0) FROM turns") ?? 0
        }
    }

    /// The two tables a day walk can seek. Fixed names, never caller input.
    private enum ClaudeDayTable: String {
        case events, turns
    }

    private func claudeDays(
        table: ClaudeDayTable, from: Double?, until: Double?, limit: Int?, deadline: Duration?
    ) throws -> [String] {
        if let limit, limit <= 0 { return [] }
        let untilClause = until == nil ? "" : " AND time < ?"
        return try withEventReads([], deadline: deadline) { conn in
            var days: [String] = []
            var cursor = max(from ?? Self.claudeEarliestKnownEventTime, Self.claudeEarliestKnownEventTime)
            while limit.map({ days.count < $0 }) ?? true {
                var arguments: [any DatabaseValueConvertible] = [ClaudeProvider.name, cursor]
                if let until { arguments.append(until) }
                // ORDER BY + LIMIT 1 rather than MIN(): the probe walks the time
                // index in order and stops at the first matching row. No
                // INDEXED BY — a bulk load drops the index, and the read must
                // still answer (slowly) rather than fail.
                guard let time = try Double.fetchOne(conn, sql: """
                    SELECT time FROM \(table.rawValue)
                    WHERE \(Self.claudeProviderOfTimeRead) AND time >= ?\(untilClause)
                    ORDER BY time LIMIT 1
                    """, arguments: StatementArguments(arguments)) else { break }
                // Unix time has no leap seconds, so a UTC day is a whole multiple
                // of 86400 from the epoch.
                let dayStart = (time / 86400).rounded(.down) * 86400
                days.append(UTCDay.string(from: Date(timeIntervalSince1970: dayStart)))
                cursor = dayStart + 86400
            }
            return days
        }
    }

    /// Per session, its events in `[from, until)`: how many, the first and last
    /// event time, and the newest non-empty `cwd` among them ("" when none
    /// carried one). Unordered. What a per-session, per-day summary needs from
    /// `events`; the turns half comes from `claudeTurnTotals` grouped by session.
    public func claudeSessionEventActivity(
        from: Double, until: Double, deadline: Duration? = nil
    ) throws -> [ClaudeSessionEventActivity] {
        let range = Self.claudeTimeRange(from: from, until: until)
        return try withEventReads([], deadline: deadline) { conn in
            let rows = try Row.fetchAll(conn, sql: """
                SELECT session_id, COUNT(*), MIN(time), MAX(time)
                FROM events
                WHERE \(Self.claudeProviderOfTimeRead) AND \(range.sql)
                GROUP BY session_id
                """, arguments: StatementArguments([ClaudeProvider.name] + range.arguments))
            return try rows.map { row in
                let sessionId: String = row[0] ?? ""
                // Each lookup seeks `events_session_time` from its right edge.
                let cwd = try String.fetchOne(conn, sql: """
                    SELECT cwd FROM events
                    WHERE provider = ? AND session_id = ? AND \(range.sql) AND COALESCE(cwd, '') <> ''
                    ORDER BY time DESC LIMIT 1
                    """, arguments: StatementArguments([ClaudeProvider.name, sessionId] + range.arguments)) ?? ""
                return ClaudeSessionEventActivity(
                    sessionId: sessionId, eventCount: row[1] ?? 0,
                    firstTime: row[2] ?? 0, lastTime: row[3] ?? 0, cwd: cwd)
            }
        }
    }

    // MARK: - Prompt-cache misses

    /// The earliest status-line tick on disk, or nil when there is none: where
    /// the cache-miss report's coverage begins.
    public func claudeStatusLineCoverageStart() throws -> Double? {
        try withEventReads(nil) { conn in
            try Double.fetchOne(conn, sql: """
                SELECT MIN(time) FROM events
                WHERE provider = ? AND provider_type = 'StatusLine' AND time >= ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime])
        }
    }

    /// Every `prompt_cache_*` counter in a status-line tick is cumulative within
    /// a cache epoch and resets to zero on a cold rebuild, and the status line
    /// re-renders the same values on every tick. Each read below therefore
    /// differences consecutive ticks of one session (ordered by time, then id)
    /// and sums only the increases, treating a decrease as a reset whose new
    /// value is entirely new; a session's first tick contributes nothing.
    /// `since` filters the differenced ticks, never the window, so the first
    /// tick in range keeps its predecessor.
    ///
    /// A tick's model and TTL are carried forward across ticks that omit them
    /// (`COUNT(x) OVER w` numbers islands of last-known value, `FIRST_VALUE`
    /// fills them), and a delta whose model or TTL changed lands in the
    /// unattributed group.
    public func claudeCacheMissGroups(since: Double? = nil) throws -> [ClaudeCacheMissGroup] {
        try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                WITH raw AS (
                    SELECT session_id, id, time,
                           m, r, t, model_id, ttl,
                           COUNT(r) OVER w AS r_island,
                           COUNT(t) OVER w AS t_island,
                           COUNT(model_id) OVER w AS model_island,
                           COUNT(ttl) OVER w AS ttl_island
                    FROM (
                        SELECT session_id, id, time,
                               CAST(json_extract(attrs, '$.prompt_cache_misses') AS INTEGER) AS m,
                               CAST(json_extract(attrs, '$.prompt_cache_requests') AS INTEGER) AS r,
                               CAST(json_extract(attrs, '$.prompt_cache_miss_recache_tokens') AS INTEGER) AS t,
                               json_extract(attrs, '$.model_id') AS model_id,
                               json_extract(attrs, '$.prompt_cache_ttl') AS ttl
                        FROM events
                        WHERE provider = ? AND provider_type = 'StatusLine' AND time >= ?
                          AND json_valid(attrs)
                    )
                    WHERE m IS NOT NULL
                    WINDOW w AS (PARTITION BY session_id ORDER BY time, id)
                ),
                filled AS (
                    SELECT session_id, id, time, m,
                           FIRST_VALUE(r) OVER (PARTITION BY session_id, r_island ORDER BY time, id) AS r,
                           FIRST_VALUE(t) OVER (PARTITION BY session_id, t_island ORDER BY time, id) AS t,
                           COALESCE(FIRST_VALUE(model_id) OVER (PARTITION BY session_id, model_island
                                                                ORDER BY time, id), '') AS model,
                           COALESCE(FIRST_VALUE(ttl) OVER (PARTITION BY session_id, ttl_island
                                                           ORDER BY time, id), '') AS ttl
                    FROM raw
                ),
                ticks AS (
                    SELECT time AS ts, m, r, t, model, ttl,
                           LAG(m) OVER w AS pm,
                           LAG(r) OVER w AS pr,
                           LAG(t) OVER w AS pt,
                           LAG(model) OVER w AS pmodel,
                           LAG(ttl) OVER w AS pttl
                    FROM filled
                    WINDOW w AS (PARTITION BY session_id ORDER BY time, id)
                )
                SELECT (model = pmodel AND ttl = pttl) AS attributed,
                       CASE WHEN model = pmodel AND ttl = pttl THEN model ELSE '' END AS gmodel,
                       CASE WHEN model = pmodel AND ttl = pttl THEN ttl ELSE '' END AS gttl,
                       SUM(CASE WHEN m < pm THEN m ELSE m - pm END) AS misses,
                       SUM(CASE WHEN pr IS NULL OR r IS NULL THEN 0
                                WHEN r < pr THEN r ELSE r - pr END) AS requests,
                       SUM(CASE WHEN pt IS NULL OR t IS NULL THEN 0
                                WHEN t < pt THEN t ELSE t - pt END) AS recache
                FROM ticks
                WHERE pm IS NOT NULL AND ts >= ?
                GROUP BY attributed, gmodel, gttl
                ORDER BY attributed DESC, recache DESC, gmodel
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime,
                                 since ?? Self.claudeEarliestKnownEventTime])
                .map { row in
                    ClaudeCacheMissGroup(
                        attributed: (row[0] as Int64? ?? 0) != 0,
                        model: row[1] ?? "", ttl: row[2] ?? "",
                        misses: row[3] ?? 0, requests: row[4] ?? 0, recacheTokens: row[5] ?? 0)
                }
        }
    }

    /// The prompt-cache miss causes, most frequent first, at most `limit`.
    /// `prompt_cache_miss_causes` is one cumulative tally per cause; a cause
    /// missing from a tick stands for zero, so the previous value is looked up
    /// by key in the previous tick's whole object, and a decrease is a reset.
    public func claudeCacheMissCauses(since: Double? = nil, limit: Int) throws -> [(cause: String, count: Int)] {
        try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                WITH ticks AS (
                    SELECT time AS ts, causes,
                           LAG(causes) OVER (PARTITION BY session_id ORDER BY time, id) AS prev
                    FROM (
                        SELECT session_id, id, time,
                               json_extract(attrs, '$.prompt_cache_miss_causes') AS causes
                        FROM events
                        WHERE provider = ? AND provider_type = 'StatusLine' AND time >= ?
                          AND json_valid(attrs)
                    )
                    WHERE causes IS NOT NULL AND json_valid(causes) AND json_type(causes) = 'object'
                )
                SELECT j.key AS cause,
                       SUM(CASE
                             WHEN (SELECT CAST(p.value AS INTEGER) FROM json_each(t.prev) p
                                    WHERE p.key = j.key) IS NULL
                               THEN CAST(j.value AS INTEGER)
                             WHEN CAST(j.value AS INTEGER)
                                  < (SELECT CAST(p.value AS INTEGER) FROM json_each(t.prev) p
                                      WHERE p.key = j.key)
                               THEN CAST(j.value AS INTEGER)
                             ELSE CAST(j.value AS INTEGER)
                                  - (SELECT CAST(p.value AS INTEGER) FROM json_each(t.prev) p
                                      WHERE p.key = j.key)
                           END) AS n
                FROM ticks t, json_each(t.causes) j
                WHERE t.prev IS NOT NULL AND t.ts >= ?
                GROUP BY cause
                HAVING n > 0
                ORDER BY n DESC, cause
                LIMIT ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime,
                                 since ?? Self.claudeEarliestKnownEventTime, limit])
                .map { (cause: $0[0] ?? "", count: $0[1] ?? 0) }
        }
    }

    /// System-prompt size deltas read off `prompt_cache_last_miss_cause` at each
    /// tick where the miss counter moved: one observation per tick, most
    /// frequent first, at most `limit`. The `LAG` runs over every tick, so a
    /// session's first cause-bearing tick keeps its predecessor.
    public func claudeSystemPromptDeltas(since: Double? = nil, limit: Int) throws -> [(chars: Int, count: Int)] {
        try withEventReads([]) { conn in
            try Row.fetchAll(conn, sql: """
                WITH ticks AS (
                    SELECT ts, m, LAG(m) OVER w AS pm, chars
                    FROM (
                        SELECT session_id, id, time AS ts,
                               CAST(json_extract(attrs, '$.prompt_cache_misses') AS INTEGER) AS m,
                               json_extract(attrs, '$.prompt_cache_last_miss_cause.system_char_delta') AS chars
                        FROM events
                        WHERE provider = ? AND provider_type = 'StatusLine' AND time >= ?
                          AND json_valid(attrs)
                    )
                    WHERE m IS NOT NULL
                    WINDOW w AS (PARTITION BY session_id ORDER BY ts, id)
                )
                SELECT CAST(chars AS INTEGER) AS delta, COUNT(*) AS n
                FROM ticks
                WHERE pm IS NOT NULL AND m != pm AND ts >= ?
                  AND typeof(chars) IN ('integer', 'real')
                GROUP BY delta
                ORDER BY n DESC, delta
                LIMIT ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime,
                                 since ?? Self.claudeEarliestKnownEventTime, limit])
                .map { (chars: $0[0] ?? 0, count: $0[1] ?? 0) }
        }
    }
}
#endif
