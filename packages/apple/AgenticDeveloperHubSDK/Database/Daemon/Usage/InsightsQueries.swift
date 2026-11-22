#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import GRDB
import OSLog
import Foundation

// Insights: split reads over the daily rollup and the event store's tail, tool
// usage, cache misses and the summary helpers.
extension DaemonDatabase {

    // MARK: - Insights aggregations

    /// How a `since` filter splits across the rollup's finalized watermark.
    /// Insights reads combine frozen history from `daily_metric` (instant +
    /// retention-safe) with the small live tail read from the event store
    /// (events.db), so the current day is always live. See ``RollupTask`` for
    /// the frozen/tail model.
    struct InsightsSplit {
        /// Lower day bound for the frozen rollup read (`nil` = from the start).
        let rollupFromDay: String?
        /// Upper day bound for the frozen rollup read (`nil` = no rollup yet, so
        /// the whole range is read from the event store).
        let rollupToDay: String?
        /// Inclusive epoch lower bound for the live tail read (`nil` = no bound).
        let tailFrom: Double?
    }

    /// `since` as an epoch bound: `nil` or empty is "no bound", a bare
    /// `YYYY-MM-DD` is that UTC day's start, anything else must parse as a
    /// timestamp. Returns `.failure` for text that names no instant, which the
    /// readers answer with an empty result rather than an unbounded one.
    static func insightsSinceTime(_ since: String?) -> Result<Double?, InsightsSinceError> {
        guard let since, !since.isEmpty else { return .success(nil) }
        let text = since.count == 10 ? since + "T00:00:00Z" : since
        guard let date = TimestampParsing.parse(text) else { return .failure(InsightsSinceError()) }
        return .success(date.timeIntervalSince1970)
    }

    struct InsightsSinceError: Error {}

    /// The epoch start of a UTC `YYYY-MM-DD` day.
    static func utcDayStart(_ day: String) -> Double? {
        TimestampParsing.parse(day + "T00:00:00Z")?.timeIntervalSince1970
    }

    /// Splits `since` at the rollup watermark, or `nil` when `since` names no
    /// instant. With no watermark (cold start / fresh DB) the whole range is
    /// read from the event store. When the watermark is set, the `since`-day is
    /// read whole from the rollup (day granularity), so the oldest bar may
    /// include a few pre-`since` hours — intended for day-bucketed charts.
    func insightsSplit(since: String?) throws -> InsightsSplit? {
        guard case .success(let sinceTime) = Self.insightsSinceTime(since) else { return nil }
        let sinceDay = (since?.isEmpty ?? true) ? nil : since.map { String($0.prefix(10)) }
        guard let finalized = try rollupFinalizedThrough() else {
            return InsightsSplit(rollupFromDay: nil, rollupToDay: nil, tailFrom: sinceTime)
        }
        // The mutable tail starts the day after the frozen watermark; never read a
        // day from both sources. Honor `since` when it lands inside the tail.
        let tailStart = Self.utcDayStart(UTCDay.dayAfter(finalized))
        let tailFrom: Double?
        switch (sinceTime, tailStart) {
        case let (since?, start?): tailFrom = max(since, start)
        case let (since, start): tailFrom = since ?? start
        }
        return InsightsSplit(rollupFromDay: sinceDay, rollupToDay: finalized, tailFrom: tailFrom)
    }

    /// Events per day, bucketed by hook type. If `since` is supplied (ISO8601),
    /// only events at or after that day are counted. Rows come back
    /// chronologically, oldest first — what the stacked bar chart wants on its X
    /// axis. Frozen days come from the rollup; the live tail from events.db.
    ///
    /// Every Claude event type the store holds is a `byType` key, including the
    /// transcript-derived `ai-title`, `custom-title` and `agent-dispatch`, which
    /// the legacy `event_log` read never had (it counted the transcript
    /// importer's synthesized `UserPromptSubmit`/`PreToolUse` rows instead).
    /// The summary's `totalEventCount` and the rollup's `event` metric count
    /// them the same way.
    func eventsPerDay(since: String? = nil) throws -> [Sessions.EventsPerDayDTO] {
        guard let split = try insightsSplit(since: since) else { return [] }
        var byDay: [String: [String: Int]] = [:]

        // Frozen history — one rollup row per (day, event_type).
        if let toDay = split.rollupToDay {
            var sql = "SELECT day, dimension, count FROM daily_metric WHERE metric = 'event' AND day <= ?"
            var params: [any Sendable] = [toDay]
            if let from = split.rollupFromDay { sql += " AND day >= ?"; params.append(from) }
            try query(sql, params: params) { row in
                byDay[string(row, 0), default: [:]][string(row, 1), default: 0] += Int(int64(row, 2))
            }
        }
        // Live mutable tail from the event store.
        for row in try claudeEventTypeCountsByDay(from: split.tailFrom) {
            byDay[row.day, default: [:]][row.providerType, default: 0] += row.count
        }
        return byDay.keys.sorted().map { Sessions.EventsPerDayDTO(day: $0, byType: byDay[$0] ?? [:]) }
    }

    /// Top-N tools by `PreToolUse` event count: frozen `tool_use` rollup rows
    /// plus the tail's `PreToolUse` events in the event store, by `tool_name`.
    func toolUsage(since: String? = nil, limit: Int = 20) throws -> [Sessions.ToolUsageDTO] {
        guard let split = try insightsSplit(since: since) else { return [] }
        var counts: [String: Int] = [:]

        // Frozen history — summed tool counts from the rollup.
        if let toDay = split.rollupToDay {
            var sql = "SELECT dimension, SUM(count) FROM daily_metric WHERE metric = 'tool_use' AND day <= ?"
            var params: [any Sendable] = [toDay]
            if let from = split.rollupFromDay { sql += " AND day >= ?"; params.append(from) }
            sql += " GROUP BY dimension"
            try query(sql, params: params) { row in
                counts[string(row, 0), default: 0] += Int(int64(row, 1))
            }
        }
        // Live tail from the event store's PreToolUse events, grouped in SQL
        // over the whole tail (one row per tool, not per tool per day).
        for row in try claudeDimensionCounts(
            providerType: "PreToolUse", dimension: .toolName, from: split.tailFrom) {
            counts[row.dimension, default: 0] += row.count
        }
        let capped = min(max(limit, 1), 100)
        return counts
            .map { Sessions.ToolUsageDTO(toolName: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.toolName < $1.toolName }
            .prefix(capped)
            .map { $0 }
    }

    /// What prompt-cache misses cost, and which causes produced them.
    ///
    /// Read from the event store's `StatusLine` events. Every `prompt_cache_*`
    /// value is a counter that is **cumulative within a cache epoch** and
    /// resets to zero when the prefix is rebuilt cold, and the status line
    /// re-renders the same values on every tick — so the toolkit's readers
    /// (``DaemonDatabase/claudeCacheMissGroups(since:)`` and friends) difference
    /// consecutive ticks of one session and sum only the increases, treating a
    /// decrease as an epoch reset whose new value is entirely new. The first
    /// tick of a session contributes nothing. `since` filters the differenced
    /// ticks, never the window, and a tick's model and TTL are carried forward
    /// across nulls.
    ///
    /// **A delta whose model or TTL actually changed cannot be priced** at
    /// either regime. Those land in ``Sessions.CacheMissesDTO/unattributedMisses`` and
    /// friends rather than being charged to the arriving model.
    ///
    /// There is no store, an empty store, or a `since` that names no instant:
    /// each gives the empty report.
    func cacheMisses(since: String? = nil, limit: Int = 20) throws -> Sessions.CacheMissesDTO {
        let from = since ?? ""
        let capped = min(max(limit, 1), 100)
        func empty(_ coverageStart: String = "") -> Sessions.CacheMissesDTO {
            Sessions.CacheMissesDTO(
                since: from, coverageStart: coverageStart, misses: 0, requests: 0, missRate: 0,
                recacheTokens: 0, estimatedCostUsd: 0,
                unattributedMisses: 0, unattributedRequests: 0, unattributedRecacheTokens: 0,
                causes: [], models: [], systemPromptDeltas: []
            )
        }
        guard case .success(let sinceTime) = Self.insightsSinceTime(since) else { return empty() }

        // The oldest tick still on disk. There is no frozen `daily_metric` behind
        // these numbers, so once retention deletes old ticks a window asking for
        // more history than remains would answer with a total that is simply
        // short. Reporting where coverage begins lets a caller tell "no misses
        // in that window" from "no data left for it".
        let coverageStart = try claudeStatusLineCoverageStart().map { ClaudeEventRow.timestamp($0) } ?? ""

        // Totals per (model, TTL) — the grain at which a miss can be priced,
        // since the cache-write premium is 1.25x at 5m and 2x at 1h. Deltas that
        // straddle a model or TTL change come back unattributed, so they still
        // reach the miss-rate denominator without being charged at a rate that
        // never applied.
        var models: [Sessions.CacheMissModelDTO] = []
        var misses = 0, requests = 0, recacheTokens = 0, cost = 0.0
        var strayMisses = 0, strayRequests = 0, strayTokens = 0
        for group in try claudeCacheMissGroups(since: sinceTime) {
            // Every group reaches the totals — including the zero-miss ones and
            // the straddling ones. Filtering here is what inflated the reported
            // miss rate 91×: the denominator lost every group the numerator
            // didn't need.
            misses += group.misses
            requests += group.requests
            recacheTokens += group.recacheTokens
            guard group.attributed else {
                strayMisses += group.misses
                strayRequests += group.requests
                strayTokens += group.recacheTokens
                continue
            }
            let ttl: String? = group.ttl.isEmpty ? nil : group.ttl
            let rowCost = TranscriptPricing.cacheWriteCost(
                model: group.model, tokens: group.recacheTokens, ttl: ttl)
            cost += rowCost
            guard models.count < capped else { continue }
            models.append(Sessions.CacheMissModelDTO(
                model: group.model,
                ttl: group.ttl,
                ttlKnown: TranscriptPricing.isKnownTTL(ttl),
                misses: group.misses,
                requests: group.requests,
                recacheTokens: group.recacheTokens,
                estimatedCostUsd: rowCost
            ))
        }

        let causes = try claudeCacheMissCauses(since: sinceTime, limit: capped)
            .map { Sessions.CacheMissCauseDTO(cause: $0.cause, occurrences: $0.count) }
        let deltas = try claudeSystemPromptDeltas(since: sinceTime, limit: capped)
            .map { Sessions.SystemPromptDeltaDTO(chars: $0.chars, occurrences: $0.count) }

        return Sessions.CacheMissesDTO(
            since: from,
            coverageStart: coverageStart,
            misses: misses,
            requests: requests,
            missRate: requests > 0 ? Double(misses) / Double(requests) : 0,
            recacheTokens: recacheTokens,
            estimatedCostUsd: cost,
            unattributedMisses: strayMisses,
            unattributedRequests: strayRequests,
            unattributedRecacheTokens: strayTokens,
            causes: causes,
            models: models,
            systemPromptDeltas: deltas
        )
    }

    /// High-level metrics: active session count, total events, most-used
    /// tool, and longest session duration (in minutes). `since` is applied
    /// where it makes sense (event count, tool usage).
    func insightsSummary(since: String? = nil) throws -> Sessions.InsightsSummaryDTO {
        let active = (try? activeSessionCount()) ?? 0
        let totalEvents = try eventsCount(since: since)
        let topTool = try toolUsage(since: since, limit: 1).first?.toolName
        let longest = try longestSessionMinutes()
        return Sessions.InsightsSummaryDTO(
            activeSessionCount: active,
            totalEventCount: totalEvents,
            mostUsedTool: topTool,
            longestSessionMinutes: longest
        )
    }

    // MARK: - Insights helpers

    private func eventsCount(since: String?) throws -> Int {
        guard let split = try insightsSplit(since: since) else { return 0 }
        var total = 0
        // Frozen history — summed event counts from the rollup.
        if let toDay = split.rollupToDay {
            var sql = "SELECT COALESCE(SUM(count), 0) FROM daily_metric WHERE metric = 'event' AND day <= ?"
            var params: [any Sendable] = [toDay]
            if let from = split.rollupFromDay { sql += " AND day >= ?"; params.append(from) }
            try query(sql, params: params) { row in total += Int(int64(row, 0)) }
        }
        // Live tail from the event store.
        total += try claudeEventCount(from: split.tailFrom)
        return total
    }

    private func longestSessionMinutes() throws -> Int {
        let sql = """
            SELECT MAX(
                CAST((julianday(last_activity_at) - julianday(started_at)) * 24 * 60 AS INTEGER)
            )
            FROM sessions
            WHERE started_at IS NOT NULL AND last_activity_at IS NOT NULL
            """
        var minutes = 0
        try query(sql) { row in
            // Result can be NULL when there are no sessions at all.
            if let value = optionalInt(row, 0) { minutes = value }
        }
        return max(minutes, 0)
    }
}
#endif
