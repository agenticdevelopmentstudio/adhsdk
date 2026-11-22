#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import GRDB
import OSLog
import Foundation

// The daily metric rollup and the reads over it.
extension DaemonDatabase {

    // MARK: - Daily metric rollup

    /// One per-type rollup: the `daily_metric.metric` it produces, the Claude
    /// hook type it counts in the event store, and what becomes its `dimension`.
    typealias RollupSource = (metric: String, providerType: String, dimension: ClaudeEventDimension)

    /// The legacy per-type table each rollup was defined over, as the hook type
    /// whose events filled it.
    private static let rollupHookTypes: [String: String] = [
        "pre_tool_use_events": "PreToolUse",
        "post_tool_use_failure_events": "PostToolUseFailure",
        "subagent_start_events": "SubagentStart",
        "notification_events": "Notification",
        "pre_compact_events": "PreCompact"
    ]

    /// `SessionSchema.perTypeRollups` read against the event store: each metric
    /// counts its hook type's events, by `tool_name` (a column of its own) or by
    /// the attribute the legacy column held (`agent_type`, `notification_type`,
    /// `trigger`). `event` (every hook type) is handled separately. A hook type
    /// the store has never seen simply produces no rows, so every source is
    /// always available; the name is kept for ``RollupTask``.
    func availableRollupSources() -> [RollupSource] {
        SessionSchema.perTypeRollups.compactMap { rollup in
            guard let hook = Self.rollupHookTypes[rollup.table] else { return nil }
            let dimension: ClaudeEventDimension = rollup.column == "tool_name" ? .toolName : .attr(rollup.column)
            return (rollup.metric, hook, dimension)
        }
    }

    /// One UTC day's aggregates, read from the event store before the main
    /// database's write transaction opens — the two files are never joined.
    private struct DayAggregates {
        var eventTypes: [(type: String, count: Int)] = []
        var dimensions: [(metric: String, dimension: String, count: Int)] = []
        var projects: [(project: String, events: Int, sessions: Int)] = []
    }

    /// The `project` rows of `[start, end)`: project = last path component of
    /// `cwd` (computed in Swift — SQLite has no rindex), count = events,
    /// sessions = distinct sessions.
    private func projectAggregates(from start: Double, until end: Double) throws
        -> [(project: String, events: Int, sessions: Int)] {
        var events: [String: Int] = [:]
        var sessions: [String: Set<String>] = [:]
        for row in try claudeCwdSessionCounts(
            from: start, until: end, deadline: Self.maintenanceReadDeadline) {
            let project = Self.lastPathComponent(row.cwd)
            guard !project.isEmpty, project != "/" else { continue }
            events[project, default: 0] += row.count
            sessions[project, default: []].insert(row.sessionId)
        }
        return events.map { ($0.key, $0.value, sessions[$0.key]?.count ?? 0) }
    }

    private func dayAggregates(start: Double, sources: [RollupSource]) throws -> DayAggregates {
        let end = start + 86400
        var result = DayAggregates()
        result.eventTypes = try claudeEventTypeCountsByDay(
            from: start, until: end, deadline: Self.maintenanceReadDeadline
        ).map { ($0.providerType, $0.count) }
        for source in sources {
            result.dimensions += try claudeDimensionCountsByDay(
                providerType: source.providerType, dimension: source.dimension,
                from: start, until: end, deadline: Self.maintenanceReadDeadline
            ).map { (source.metric, $0.dimension, $0.count) }
        }
        result.projects = try projectAggregates(from: start, until: end)
        return result
    }

    private func insertProjectRows(day: String, _ projects: [(project: String, events: Int, sessions: Int)]) throws {
        for row in projects {
            try execute("""
                INSERT INTO daily_metric(day, metric, dimension, count, value_sum, updated_at)
                VALUES (?, 'project', ?, ?, ?, datetime('now'))
                """, params: [day, row.project, row.events, Double(row.sessions)])
        }
    }

    /// Recomputes every `daily_metric` row for a single UTC `day` ('YYYY-MM-DD')
    /// from the event store: the day's aggregates are read from events.db first,
    /// then the day is DELETEd and re-INSERTed in one main transaction, so the
    /// day is atomic and the operation is idempotent (running twice yields the
    /// same rows). Safe to call only while the day's events still exist;
    /// `RollupTask` never recomputes a finalized day, so deleting old events
    /// can't zero out frozen history. `value_sum` is 0 except on `project`
    /// rows, where it is the day's distinct sessions.
    ///
    /// A day the event store holds no events for is left exactly as it is: its
    /// existing rows (written from the legacy `event_log` before the cutover, or
    /// by an earlier run before the store lost the day) are never deleted and
    /// refrozen as zeros. With nothing to insert and nothing to keep, there is
    /// nothing to do either way.
    ///
    /// The `event` metric counts every Claude event type the store holds, which
    /// includes the transcript-derived types `ai-title`, `custom-title` and
    /// `agent-dispatch` (each its own `dimension`). The legacy rollup over
    /// `event_log` never saw those, and counted the transcript importer's
    /// synthesized `UserPromptSubmit`/`PreToolUse` rows instead; `eventsPerDay`
    /// and the insights summary's total read the same store and change the same
    /// way.
    /// - Parameter sources: the per-type rollups to compute (defaults to
    ///   ``availableRollupSources()``).
    func recomputeDailyMetrics(forDay day: String, sources: [RollupSource]? = nil) throws {
        guard let start = Self.utcDayStart(day) else { return }
        let aggregates = try dayAggregates(start: start, sources: sources ?? availableRollupSources())
        // Every dimension and project row is a subset of the day's events, so no
        // event types means no events at all.
        guard !aggregates.eventTypes.isEmpty else { return }
        try transaction {
            try execute("DELETE FROM daily_metric WHERE day = ?", params: [day])
            for row in aggregates.eventTypes {
                try execute("""
                    INSERT INTO daily_metric(day, metric, dimension, count, value_sum, updated_at)
                    VALUES (?, 'event', ?, ?, 0, datetime('now'))
                    """, params: [day, row.type, row.count])
            }
            for row in aggregates.dimensions {
                try execute("""
                    INSERT INTO daily_metric(day, metric, dimension, count, value_sum, updated_at)
                    VALUES (?, ?, ?, ?, 0, datetime('now'))
                    """, params: [day, row.metric, row.dimension, row.count])
            }
            // `project` — powers "Top projects by event count".
            try insertProjectRows(day: day, aggregates.projects)
        }
    }

    /// The last UTC day the `project` backfill has examined: every event day up
    /// to it either has its `project` rows or was walked past. Kept in main
    /// `settings` so a run starts after it instead of rewalking history.
    static let projectBackfillMarkerKey = "stats_project_backfilled_through"

    /// How many event days one probe batch of the backfill walk asks for.
    private static let projectBackfillWalkBatch = 256

    /// Backfills the `project` metric onto already-finalized days that predate it
    /// (``recomputeDailyMetrics`` emits it for the mutable tail and all future
    /// finalizations; this catches up frozen history exactly once). Additive and
    /// source-gated: only days that still have events in the event store and no
    /// `project` row yet are touched, each in its own transaction writing only
    /// that day's `project` rows — so frozen history for other metrics is never
    /// disturbed and a day whose events are gone is simply skipped.
    ///
    /// Bounded: the candidate days come from ``claudeEventDays(from:until:limit:deadline:)``'s
    /// seek walk (one index probe per event day, never a scan of the events),
    /// in batches, starting after ``projectBackfillMarkerKey``. The marker
    /// advances to the last day examined when `limit` days are done, and to
    /// `finalizedDay` once the walk reaches the end — so steady state walks only
    /// the days finalized since the last run, and a day whose events yield no
    /// project (no cwd) is passed once rather than retried forever. Idempotent
    /// and crash-safe: the marker moves only after the days before it are
    /// written, and a day that already has `project` rows is skipped. Like
    /// the rest of the frozen region, a day imported into the store after the
    /// marker passed it is not revisited. Returns the number of days processed
    /// so ``RollupTask`` can reschedule.
    func backfillProjectMetric(through finalizedDay: String, limit: Int) throws -> Int {
        guard limit > 0, let end = Self.utcDayStart(UTCDay.dayAfter(finalizedDay)) else { return 0 }
        let marker = try setting(for: Self.projectBackfillMarkerKey).flatMap { $0.isEmpty ? nil : $0 }
        if let marker, marker >= finalizedDay { return 0 }
        // Candidate days come from events.db, the days already done from main;
        // the two are joined here, never in SQL.
        var doneDays: Set<String> = []
        try query("SELECT DISTINCT day FROM daily_metric WHERE metric = 'project' AND day > ?",
                  params: [marker ?? ""]) { row in
            doneDays.insert(string(row, 0))
        }
        var cursor = marker.flatMap { Self.utcDayStart(UTCDay.dayAfter($0)) }
        var done = 0
        while true {
            let batch = try claudeEventDays(
                from: cursor, until: end, limit: Self.projectBackfillWalkBatch,
                deadline: Self.maintenanceReadDeadline)
            for day in batch where !doneDays.contains(day) {
                guard let start = Self.utcDayStart(day) else { continue }
                let projects = try projectAggregates(from: start, until: start + 86400)
                // Each day is its OWN transaction: a completed day commits and is
                // skipped next run (crash-safe, per-day durable), and one huge day
                // can't eject the whole chunk's progress.
                try transaction {
                    // DELETE keeps it idempotent if a prior run inserted partial rows.
                    try execute("DELETE FROM daily_metric WHERE day = ? AND metric = 'project'", params: [day])
                    try insertProjectRows(day: day, projects)
                }
                done += 1
                if done == limit {
                    try setSetting(Self.projectBackfillMarkerKey, day)
                    return done
                }
            }
            guard batch.count == Self.projectBackfillWalkBatch, let last = batch.last,
                  let next = Self.utcDayStart(UTCDay.dayAfter(last)) else { break }
            cursor = next
        }
        try setSetting(Self.projectBackfillMarkerKey, finalizedDay)
        return done
    }

    /// Earliest UTC day holding an event in the event store, or nil when it is
    /// empty (or absent).
    func minEventDay() throws -> String? {
        try claudeEarliestEventTime(deadline: Self.maintenanceReadDeadline)
            .map { UTCDay.string(from: Date(timeIntervalSince1970: $0)) }
    }

    /// Distinct UTC days holding an event in the event store within [from, to]
    /// inclusive, ascending. `limit` caps the result for chunked backfill.
    func distinctEventDays(from fromDay: String, to toDay: String, limit: Int? = nil) throws -> [String] {
        guard let start = Self.utcDayStart(fromDay), let last = Self.utcDayStart(toDay) else { return [] }
        return try claudeEventDays(
            from: start, until: last + 86400, limit: limit, deadline: Self.maintenanceReadDeadline)
    }

    /// Watermark: the most recent UTC day whose metrics are finalized (frozen).
    /// Days `<= this` are never recomputed, so retention can delete their source.
    func rollupFinalizedThrough() throws -> String? {
        let value = try setting(for: "stats_rollup_finalized_through")
        return (value?.isEmpty ?? true) ? nil : value
    }

    func setRollupFinalizedThrough(_ day: String) throws {
        try setSetting("stats_rollup_finalized_through", day)
    }

    /// Reads rolled-up daily metrics. All filters optional: `metric` (nil = all),
    /// `dimension`, and an inclusive `from`/`to` day range. Ordered by day.
    func dailyMetrics(
        metric: String? = nil,
        dimension: String? = nil,
        from fromDay: String? = nil,
        to toDay: String? = nil,
        limit: Int = 1000
    ) throws -> [Sessions.DailyMetricDTO] {
        var conditions: [String] = []
        var params: [any Sendable] = []
        if let metric { conditions.append("metric = ?"); params.append(metric) }
        if let dimension { conditions.append("dimension = ?"); params.append(dimension) }
        if let fromDay { conditions.append("day >= ?"); params.append(fromDay) }
        if let toDay { conditions.append("day <= ?"); params.append(toDay) }
        let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        let capped = min(max(limit, 1), 10000)
        let sql = """
            SELECT day, metric, dimension, count, value_sum
            FROM daily_metric
            \(whereClause)
            ORDER BY day ASC, metric ASC, dimension ASC
            LIMIT ?
            """
        params.append(capped)

        var rows: [Sessions.DailyMetricDTO] = []
        try query(sql, params: params) { row in
            rows.append(Sessions.DailyMetricDTO(
                day: string(row, 0),
                metric: string(row, 1),
                dimension: string(row, 2),
                count: Int(int64(row, 3)),
                valueSum: double(row, 4)
            ))
        }
        return rows
    }

    /// Top-N projects by total event count, derived from the last path
    /// component of each event's `cwd`. Also reports the number of distinct
    /// sessions seen in that project. Last-component extraction happens
    /// in Swift (SQLite has no `rindex` / `reverse`), then re-aggregated
    /// in memory.
    func projectActivity(since: String? = nil, limit: Int = 10) throws -> [Sessions.ProjectActivityDTO] {
        guard let split = try insightsSplit(since: since) else { return [] }
        struct Agg { var events = 0; var sessions = 0 }
        var byProject: [String: Agg] = [:]

        // Frozen history — rollup `project` rows: count = events, value_sum = the
        // day's distinct sessions. Summing value_sum across days slightly
        // over-counts a session active on multiple days, which is fine for the
        // secondary "N sess" label.
        if let toDay = split.rollupToDay {
            var sql = "SELECT dimension, SUM(count), SUM(value_sum) "
                + "FROM daily_metric WHERE metric = 'project' AND day <= ?"
            var params: [any Sendable] = [toDay]
            if let from = split.rollupFromDay { sql += " AND day >= ?"; params.append(from) }
            sql += " GROUP BY dimension"
            try query(sql, params: params) { row in
                let project = string(row, 0)
                byProject[project, default: Agg()].events += Int(int64(row, 1))
                byProject[project, default: Agg()].sessions += Int(double(row, 2))
            }
        }
        // Live tail from the event store; last path component computed in Swift
        // (SQLite has no rindex). Distinct sessions counted exactly over the tail.
        var tailSessions: [String: Set<String>] = [:]
        for row in try claudeCwdSessionCounts(from: split.tailFrom) {
            let project = Self.lastPathComponent(row.cwd)
            guard !project.isEmpty, project != "/" else { continue }
            byProject[project, default: Agg()].events += row.count
            tailSessions[project, default: []].insert(row.sessionId)
        }
        for (project, sessions) in tailSessions {
            byProject[project, default: Agg()].sessions += sessions.count
        }

        let capped = min(max(limit, 1), 100)
        return byProject
            .map {
                Sessions.ProjectActivityDTO(
                    project: $0.key, eventCount: $0.value.events, sessionCount: $0.value.sessions)
            }
            .sorted { ($0.eventCount, $0.project) > ($1.eventCount, $1.project) }
            .prefix(capped)
            .map { $0 }
    }

    static func lastPathComponent(_ cwd: String) -> String {
        let trimmed = cwd.hasSuffix("/") ? String(cwd.dropLast()) : cwd
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        return String(trimmed[trimmed.index(after: slash)...])
    }

    /// New sessions per day: distinct sessions with a `SessionStart` event in
    /// the event store, oldest day first.
    func sessionsPerDay(since: String? = nil) throws -> [Sessions.SessionsPerDayDTO] {
        guard case .success(let from) = Self.insightsSinceTime(since) else { return [] }
        return try claudeNewSessionsPerDay(from: from)
            .map { Sessions.SessionsPerDayDTO(day: $0.day, newSessions: $0.count) }
    }
}
#endif
