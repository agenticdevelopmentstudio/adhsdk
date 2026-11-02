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

    /// The SQL expression reading the dimension off an `events` row. An attrs
    /// key is bound, never spliced, so any key is safe.
    fileprivate var sql: (expression: String, arguments: [any DatabaseValueConvertible]) {
        switch self {
        case .toolName: return ("tool_name", [])
        case .attr(let key):
            let quoted = key.replacingOccurrences(of: "\"", with: "\"\"")
            return ("json_extract(attrs, ?)", ["$.\"\(quoted)\""])
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

/// The insights and daily-rollup reads over the event store's Claude events.
///
/// Every read binds the Claude provider, leaves out rows before
/// ``DaemonDatabase/claudeEarliestKnownEventTime`` (an event whose time is
/// unknown), and answers empty when no event store is attached. Days are UTC
/// (`date(time, 'unixepoch')`). `from` is inclusive and `until` exclusive, both
/// epoch seconds; nil is no bound.
extension DaemonDatabase {

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
                WHERE provider = ? AND \(range.sql)
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
                    WHERE provider = ? AND provider_type = ? AND \(range.sql)
                )
                WHERE dim IS NOT NULL AND dim != ''
                GROUP BY day, dim
                """, arguments: StatementArguments(arguments))
                .map { (day: $0[0] ?? "", dimension: $0[1] ?? "", count: $0[2] ?? 0) }
        }
    }

    /// How many events fall in the range.
    public func claudeEventCount(from: Double? = nil, until: Double? = nil) throws -> Int {
        let range = Self.claudeTimeRange(from: from, until: until)
        return try withEventReads(0) { conn in
            try Int.fetchOne(conn, sql: """
                SELECT COUNT(*) FROM events WHERE provider = ? AND \(range.sql)
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
                WHERE provider = ? AND \(range.sql)
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
                SELECT MIN(time) FROM events WHERE provider = ? AND time >= ?
                """, arguments: [ClaudeProvider.name, Self.claudeEarliestKnownEventTime])
        }
    }

    /// The distinct UTC days holding an event in the range, oldest first.
    public func claudeEventDays(
        from: Double? = nil, until: Double? = nil, limit: Int? = nil, deadline: Duration? = nil
    ) throws -> [String] {
        let range = Self.claudeTimeRange(from: from, until: until)
        var arguments: [any DatabaseValueConvertible] = [ClaudeProvider.name] + range.arguments
        var sql = """
            SELECT DISTINCT date(time, 'unixepoch') AS day
            FROM events
            WHERE provider = ? AND \(range.sql)
            ORDER BY day ASC
            """
        if let limit {
            sql += "\nLIMIT ?"
            arguments.append(limit)
        }
        return try withEventReads([], deadline: deadline) { conn in
            try String.fetchAll(conn, sql: sql, arguments: StatementArguments(arguments))
                .filter { !$0.isEmpty }
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
