#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import OSLog

extension DaemonDatabase {

    // MARK: - Session metrics (JSONL import)

    /// UPSERT per-session rollups from the importer. `updated_at` is
    /// refreshed by the row default on insert and by the SET clause on
    /// update so downstream consumers can tell when the numbers changed.
    public func upsertSessionMetrics(_ metrics: SessionMetricsDTO, accountEmail: String) throws {
        try write { _ in
            try execute("""
                INSERT INTO session_metrics (
                    session_id, total_input_tokens, total_output_tokens,
                    cache_read_tokens, cache_creation_tokens, total_cost_usd,
                    turn_count, model, first_turn_at, last_turn_at, updated_at,
                    account_email
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), ?)
                ON CONFLICT(session_id) DO UPDATE SET
                    total_input_tokens = excluded.total_input_tokens,
                    total_output_tokens = excluded.total_output_tokens,
                    cache_read_tokens = excluded.cache_read_tokens,
                    cache_creation_tokens = excluded.cache_creation_tokens,
                    total_cost_usd = excluded.total_cost_usd,
                    turn_count = excluded.turn_count,
                    model = excluded.model,
                    first_turn_at = excluded.first_turn_at,
                    last_turn_at = excluded.last_turn_at,
                    updated_at = datetime('now'),
                    account_email = CASE WHEN excluded.account_email != '' AND session_metrics.account_email = ''
                                          THEN excluded.account_email ELSE session_metrics.account_email END
            """, params: [
                metrics.sessionId,
                metrics.totalInputTokens,
                metrics.totalOutputTokens,
                metrics.cacheReadTokens,
                metrics.cacheCreationTokens,
                metrics.totalCostUsd,
                metrics.turnCount,
                metrics.model,
                metrics.firstTurnAt,
                metrics.lastTurnAt,
                accountEmail
            ])
        }
    }

    /// Aggregate a single session's metrics directly from the persisted,
    /// deduplicated `transcript_turns` rows — the source of truth the JSONL
    /// importer upserts into `session_metrics`. Sourcing from the table
    /// (not an in-memory per-run bucket) keeps totals correct no matter how
    /// the import was chunked: a session whose turns arrive across several
    /// files/chunks, or a growing live file re-scanned with a `since`
    /// turn-filter, sums every persisted turn instead of letting the
    /// REPLACE upsert overwrite earlier slices. Idempotent — a re-import
    /// inserts zero new turns, so the aggregate is unchanged.
    ///
    /// Tokens are grouped by model so each model's rate is applied only to
    /// its own tokens (a session that switched models is costed correctly);
    /// `model` reports the chronologically-latest non-empty model, breaking
    /// exact-timestamp ties by model name so the result is deterministic.
    /// Returns nil when the session has no turns.
    public func sessionMetricsFromTranscriptTurns(sessionId: String) throws -> SessionMetricsDTO? {
        var groups: [TurnModelGroup] = []
        try query("""
            SELECT model,
                   COUNT(*),
                   COALESCE(SUM(input_tokens), 0),
                   COALESCE(SUM(output_tokens), 0),
                   COALESCE(SUM(cache_read_tokens), 0),
                   COALESCE(SUM(cache_creation_tokens), 0),
                   COALESCE(SUM(cache_creation_1h_tokens), 0),
                   COALESCE(MIN(NULLIF(timestamp, '')), ''),
                   COALESCE(MAX(NULLIF(timestamp, '')), '')
            FROM transcript_turns
            WHERE session_id = ?
            GROUP BY model
            """, params: [sessionId]) { row in
            groups.append(TurnModelGroup(
                model: string(row, 0), turnCount: Int(int64(row, 1)),
                input: Int(int64(row, 2)), output: Int(int64(row, 3)),
                cacheRead: Int(int64(row, 4)), cacheCreate: Int(int64(row, 5)),
                cacheCreate1h: Int(int64(row, 6)), firstTs: string(row, 7), lastTs: string(row, 8)))
        }
        return Self.sessionMetrics(sessionId: sessionId, groups: groups)
    }

    /// `sessionMetricsFromTranscriptTurns` over an event store's `turns` (provider
    /// `claude`) instead of `transcript_turns`: the same GROUP BY model, the same
    /// pricing and model pick. The store keeps a turn's time as epoch seconds, so
    /// `firstTurnAt`/`lastTurnAt` are written back in a transcript's own form
    /// (`yyyy-MM-ddTHH:mm:ss.SSSZ`); a turn from a line with no timestamp sits at
    /// the epoch and, like an empty `timestamp` there, sets neither.
    /// Returns nil when the session has no turns.
    public func sessionMetricsFromTurns(sessionId: String, reads: EventStore) throws -> SessionMetricsDTO? {
        let rows = try reads.read { conn in
            try Row.fetchAll(conn, sql: """
                SELECT COALESCE(model, ''),
                       COUNT(*),
                       COALESCE(SUM(input_tokens), 0),
                       COALESCE(SUM(output_tokens), 0),
                       COALESCE(SUM(cache_read_tokens), 0),
                       COALESCE(SUM(cache_write_tokens), 0),
                       CAST(COALESCE(SUM(json_extract(attrs, '$.cache_creation_1h_tokens')), 0) AS INTEGER),
                       MIN(CASE WHEN time > 0 THEN time END),
                       MAX(CASE WHEN time > 0 THEN time END)
                FROM turns
                WHERE provider = ? AND session_id = ?
                GROUP BY COALESCE(model, '')
                """, arguments: [ClaudeProvider.name, sessionId])
        }
        let groups = rows.map { row in
            TurnModelGroup(
                model: row[0], turnCount: row[1], input: row[2], output: row[3],
                cacheRead: row[4], cacheCreate: row[5], cacheCreate1h: row[6],
                firstTs: (row[7] as Double?).map { Self.transcriptTimestamp($0) } ?? "",
                lastTs: (row[8] as Double?).map { Self.transcriptTimestamp($0) } ?? "")
        }
        return Self.sessionMetrics(sessionId: sessionId, groups: groups)
    }

    /// Epoch seconds as a transcript writes a time: UTC, millisecond precision
    /// (`2026-10-30T12:00:01.500Z`). With `omitZeroMilliseconds`, a whole second
    /// drops the fraction (`2026-10-30T12:00:00Z`), the form a hook envelope uses.
    static func transcriptTimestamp(_ seconds: Double, omitZeroMilliseconds: Bool = false) -> String {
        let millis = Int64((seconds * 1000).rounded())
        // Floor division, so a time before the epoch still gets a 0…999 fraction.
        let fraction = ((millis % 1000) + 1000) % 1000
        let whole = Date(timeIntervalSince1970: TimeInterval((millis - fraction) / 1000))
        let base = transcriptSecondFormatter.string(from: whole)  // "…:ssZ"
        if fraction == 0 && omitZeroMilliseconds { return base }
        return String(base.dropLast()) + String(format: ".%03lldZ", fraction)
    }

    nonisolated(unsafe) private static let transcriptSecondFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// One `GROUP BY model` row of a session's turns.
    private struct TurnModelGroup {
        let model: String
        let turnCount: Int
        let input: Int
        let output: Int
        let cacheRead: Int
        let cacheCreate: Int
        let cacheCreate1h: Int
        let firstTs: String
        let lastTs: String
    }

    /// Folds a session's per-model turn groups into its `session_metrics` totals.
    private static func sessionMetrics(sessionId: String, groups: [TurnModelGroup]) -> SessionMetricsDTO? {
        struct ModelBucket {
            var turnCount = 0
            var input = 0
            var output = 0
            var cacheRead = 0
            var cacheCreate = 0
            var cacheCreate1h = 0
            var lastTs = ""
        }
        var perModel: [String: ModelBucket] = [:]
        var totalTurns = 0
        var firstTs = ""
        var lastTs = ""

        for group in groups {
            var bucket = ModelBucket()
            bucket.turnCount = group.turnCount
            bucket.input = group.input
            bucket.output = group.output
            bucket.cacheRead = group.cacheRead
            bucket.cacheCreate = group.cacheCreate
            bucket.cacheCreate1h = group.cacheCreate1h
            bucket.lastTs = group.lastTs
            perModel[group.model] = bucket
            totalTurns += bucket.turnCount
            if !group.firstTs.isEmpty, firstTs.isEmpty || group.firstTs < firstTs { firstTs = group.firstTs }
            if group.lastTs > lastTs { lastTs = group.lastTs }
        }

        guard totalTurns > 0 else { return nil }

        var input = 0, output = 0, cacheRead = 0, cacheCreate = 0
        var cost = 0.0
        var latestModel = ""
        var latestModelTs = ""
        for (model, bucket) in perModel {
            input += bucket.input
            output += bucket.output
            cacheRead += bucket.cacheRead
            cacheCreate += bucket.cacheCreate
            cost += TranscriptPricing.cost(
                model: model,
                inputTokens: bucket.input,
                outputTokens: bucket.output,
                cacheReadTokens: bucket.cacheRead,
                cacheCreationTokens: bucket.cacheCreate,
                cacheCreation1hTokens: bucket.cacheCreate1h
            )
            // `perModel` is a Dictionary, so iteration order is unstable.
            // Break ties on `lastTs` deterministically by model name so the
            // representative model doesn't flip between otherwise-identical
            // imports.
            if !model.isEmpty,
               latestModel.isEmpty
                || bucket.lastTs > latestModelTs
                || (bucket.lastTs == latestModelTs && model > latestModel) {
                latestModel = model
                latestModelTs = bucket.lastTs
            }
        }

        return SessionMetricsDTO(
            sessionId: sessionId,
            totalInputTokens: input,
            totalOutputTokens: output,
            cacheReadTokens: cacheRead,
            cacheCreationTokens: cacheCreate,
            totalCostUsd: cost,
            turnCount: totalTurns,
            model: latestModel,
            firstTurnAt: firstTs,
            lastTurnAt: lastTs,
            updatedAt: ""
        )
    }

    public func metricsForSession(sessionId: String) throws -> SessionMetricsDTO? {
        var result: SessionMetricsDTO?
        try query("""
            SELECT total_input_tokens, total_output_tokens, cache_read_tokens,
                   cache_creation_tokens, total_cost_usd, turn_count, model,
                   first_turn_at, last_turn_at, updated_at
            FROM session_metrics
            WHERE session_id = ?
        """, params: [sessionId]) { row in
            result = SessionMetricsDTO(
                sessionId: sessionId,
                totalInputTokens: Int(int64(row, 0)),
                totalOutputTokens: Int(int64(row, 1)),
                cacheReadTokens: Int(int64(row, 2)),
                cacheCreationTokens: Int(int64(row, 3)),
                totalCostUsd: double(row, 4),
                turnCount: Int(int64(row, 5)),
                model: self.string(row, 6),
                firstTurnAt: self.string(row, 7),
                lastTurnAt: self.string(row, 8),
                updatedAt: self.string(row, 9)
            )
        }
        return result
    }

    /// The `settings` key holding the ``TranscriptPricing/revision`` the
    /// persisted `session_metrics.total_cost_usd` values were computed at.
    private static let pricingRevisionKey = "transcript_pricing_revision"

    /// Re-cost every persisted `session_metrics` row when the pricing table
    /// moves, and record the revision that produced the numbers now on disk.
    ///
    /// `total_cost_usd` is the one figure a daemon *stores* rather than
    /// recomputes: `/turns` and `/insights/usage-rows` price live from the
    /// event store's turns on every request, but `/sessions/:id/metrics` serves
    /// what the importer wrote. And the importer never revisits a transcript
    /// whose mtime hasn't moved (`JSONLImporter.run`), so a finished session's
    /// `.jsonl` is read exactly once, ever. Without this pass a price
    /// correction reaches new sessions only, and the two endpoints disagree
    /// about the same session forever — the kind of divergence that is
    /// invisible until someone reconciles two screens.
    ///
    /// Idempotent, and nothing at all on every launch after the first at a given
    /// revision — but NOT cheap: the scan below groups every Claude turn in the
    /// event store, and the legacy `transcript_turns` scan it replaced took
    /// minutes on a multi-gigabyte DB.
    ///
    /// The costs come from the event store (`events.db` `turns`). Without one
    /// attached there is nothing to price from, so the pass logs and leaves the
    /// revision unrecorded — the next launch, with a store, runs it. A session
    /// with no turns in the store keeps the cost it has.
    ///
    /// Which is why this is maintenance that runs AFTER the listener is up
    /// (the daemon's run loop), never from `runMigrations()`. It did run there,
    /// and on a 39 GB database the scan exceeded the serving read deadline
    /// (which is why the scan now runs under `maintenanceReadDeadline`),
    /// threw, aborted the daemon's startup phase A, and left launchd restarting
    /// the daemon every ten seconds — the whole daemon down over a cost figure.
    /// A migration gates startup because a wrong schema must not serve; a
    /// maintenance pass must not gate it, because a stale cost figure is not
    /// worth an outage.
    ///
    /// So it cannot throw at all: the only caller gets the logged version, and
    /// the revision is recorded only on success, so a failed pass simply runs
    /// again next launch.
    public func repriceSessionMetricsIfNeeded() {
        do {
            try repriceSessionMetrics()
        } catch {
            logger.error("repricing failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func repriceSessionMetrics() throws {
        let recorded = (try? setting(for: Self.pricingRevisionKey)) ?? nil
        guard recorded != String(TranscriptPricing.revision) else { return }

        guard eventReads != nil else {
            logger.info("repricing deferred: no event store attached")
            return
        }

        // Group by (session, model) so each model's rate is applied only to its
        // own tokens — the same rule `sessionMetricsFromTurns` follows for a
        // single session, which is what keeps the two agreeing.
        var costs: [String: Double] = [:]
        // A whole-store grouped scan: on a converted history it outlives the
        // store's 30 s read deadline, so it gets the maintenance one.
        for group in try claudeTurnTotals(groupBy: .session, deadline: Self.maintenanceReadDeadline) {
            costs[group.key, default: 0] += TranscriptPricing.cost(
                model: group.model,
                inputTokens: group.inputTokens,
                outputTokens: group.outputTokens,
                cacheReadTokens: group.cacheReadTokens,
                cacheCreationTokens: group.cacheCreationTokens,
                cacheCreation1hTokens: group.cacheCreation1hTokens
            )
        }

        try migrationTransaction {
            for (sessionId, cost) in costs {
                try execute(
                    "UPDATE session_metrics SET total_cost_usd = ? WHERE session_id = ?",
                    params: [cost, sessionId]
                )
            }
            try setSetting(Self.pricingRevisionKey, String(TranscriptPricing.revision))
        }
        logger.info("""
            repriced \(costs.count, privacy: .public) sessions at pricing revision \
            \(TranscriptPricing.revision, privacy: .public)
            """)
    }
}
#endif
