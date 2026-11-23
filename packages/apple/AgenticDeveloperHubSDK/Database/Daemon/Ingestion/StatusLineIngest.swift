#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

// MARK: - StatusLine payload routing
//
// The Usage half of ingesting a `StatusLine` event. `ingestEvent` records the event
// itself and then hands the payload to the database's `statusLineIngest`; a session
// daemon passes ``DaemonDatabase/sessionStatusLineIngest`` there, which runs
// `ingestStatusLinePayload`. Oversight reads `session_metrics.context_used_pct` and
// `context_window_size`, so a daemon that passes no handler sees every session at 0.

extension DaemonDatabase {

    /// The session daemon's ``StatusLineIngest``: runs
    /// ``ingestStatusLinePayload(sessionId:hookData:timestamp:accountEmail:)``.
    public static let sessionStatusLineIngest: StatusLineIngest = { database, sessionId, hookData, timestamp, account in
        try database.ingestStatusLinePayload(
            sessionId: sessionId, hookData: hookData, timestamp: timestamp, accountEmail: account
        )
    }

    /// The pre-rename handler: session metrics and the version schema only,
    /// no rate-limit snapshots, as it always did. Kept, deprecated, so a
    /// consumer that still names it builds and behaves as before.
    @available(*, deprecated, renamed: "sessionStatusLineIngest",
               message: "sessionStatusLineIngest also records rate_limit_snapshots")
    public static var statusLineMetricsIngest: StatusLineIngest {
        { database, sessionId, hookData, _, accountEmail in
            try database.recordStatusLineMetrics(sessionId: sessionId, hookData: hookData, accountEmail: accountEmail)
        }
    }

    /// The pre-rename entry point: records the payload's version schema in
    /// `claude_versions` and its figures in `session_metrics`, and no
    /// rate-limit snapshot. Must run inside `ingestEvent`'s write transaction.
    @available(*, deprecated, renamed: "ingestStatusLinePayload(sessionId:hookData:timestamp:accountEmail:)",
               message: "ingestStatusLinePayload also records rate_limit_snapshots")
    public func ingestStatusLineMetrics(sessionId: String, hookData: [String: Any], accountEmail: String) throws {
        try recordStatusLineMetrics(sessionId: sessionId, hookData: hookData, accountEmail: accountEmail)
    }

    /// Routes a StatusLine hook payload into three places:
    ///   1. `rate_limit_snapshots` — one row per render, deduped against the
    ///      session's most recent row when `weekly_pct` / `five_hour_pct` /
    ///      `projected_pct` are all unchanged (mirrors CSL's
    ///      `append_weekly_usage`).
    ///   2. `claude_versions` — first capture stores the full JSON blob and
    ///      the union of field paths extracted from it; subsequent captures
    ///      merge new paths into that union without touching the blob.
    ///   3. `session_metrics` extended columns — claude_version, project_dir,
    ///      transcript_path, context_window_size, api_duration_ms,
    ///      lines_added/removed, context_used_pct.
    ///
    /// Must run inside `ingestEvent`'s write transaction (calls `execute` /
    /// `query` directly without re-entering the queue).
    public func ingestStatusLinePayload(
        sessionId: String,
        hookData: [String: Any],
        timestamp: String,
        accountEmail: String
    ) throws {
        let rateLimits = hookData["rate_limits"] as? [String: Any] ?? [:]
        let sevenDay = rateLimits["seven_day"] as? [String: Any] ?? [:]
        let fiveHour = rateLimits["five_hour"] as? [String: Any] ?? [:]
        // Present only behind a Claude apps gateway that sets a spend limit; each
        // window is independently absent, so this one can be the only one there.
        let spendLimit = rateLimits["spend_limit"] as? [String: Any] ?? [:]

        let weeklyPct = doubleValue(sevenDay["used_percentage"])
        let fiveHourPct = doubleValue(fiveHour["used_percentage"])
        let fiveHourResets = intValue(fiveHour["resets_at"])
        let sevenDayResets = intValue(sevenDay["resets_at"])
        let spendPct = doubleValue(spendLimit["used_percentage"])
        let spendResets = intValue(spendLimit["resets_at"])

        let projection = computeWeeklyProjection(
            sessionId: sessionId,
            sevenDayResetsAt: sevenDayResets,
            weeklyPct: weeklyPct
        )

        // 1. rate_limit_snapshots dedup + insert. Only persist when any of
        // the quota signals moved — keeps the table from accumulating
        // identical rows on every status-line render (~once per turn).
        //
        // `spendResets > 0` joins the gate rather than `spendPct > 0`: a gateway
        // may report a spend window while five-hour and seven-day are absent, and
        // 0% spent is a real reading that must still open the row. The percentage
        // is never gated on, so a genuine 0 is preserved.
        if weeklyPct > 0 || fiveHourPct > 0 || projection.projectedPct > 0 || spendResets > 0 {
            var lastWeekly: Double?
            var lastFiveHour: Double?
            var lastProjected: Double?
            var lastAccount: String?
            var lastSpend: Double?
            var lastSpendResets: Int?
            try query("""
                SELECT weekly_pct, five_hour_pct, projected_pct, account_email,
                       spend_pct, spend_resets_at
                FROM rate_limit_snapshots
                WHERE session_id = ?
                ORDER BY id DESC LIMIT 1
            """, params: [sessionId]) { row in
                lastWeekly = double(row, 0)
                lastFiveHour = double(row, 1)
                lastProjected = double(row, 2)
                lastAccount = string(row, 3)
                lastSpend = double(row, 4)
                lastSpendResets = Int(int64(row, 5))
            }

            // `spend_resets_at` is in the comparison because migration031 makes
            // it the presence sentinel for the whole spend window — `spend_pct`
            // of 0 cannot tell absent from a legitimate 0% — so a row that moves
            // only the sentinel is real news. On a gateway-only install it is
            // also the ONLY field here that can vary: seven-day and five-hour are
            // absent, which pins weekly, five-hour and projected at 0 forever.
            // Leaving it out froze the spend row against an elapsed reset for the
            // life of the session, and left a phantom row standing after the
            // gateway stopped reporting one.
            let unchanged = lastWeekly == weeklyPct
                && lastFiveHour == fiveHourPct
                && lastProjected == projection.projectedPct
                && lastAccount == accountEmail
                && lastSpend == spendPct
                && lastSpendResets == spendResets
            if !unchanged, try !olderThanNewestSnapshot(timestamp: timestamp, accountEmail: accountEmail) {
                try execute("""
                    INSERT INTO rate_limit_snapshots (
                        timestamp, session_id, week_start, elapsed_hours,
                        elapsed_day, weekly_pct, daily_avg_pct, five_hour_pct,
                        five_hour_resets_at, seven_day_resets_at, projected_pct,
                        account_email, spend_pct, spend_resets_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, params: [
                    timestamp,
                    sessionId,
                    projection.weekStart,
                    projection.elapsedHours,
                    projection.elapsedDay,
                    weeklyPct,
                    projection.dailyAvgPct,
                    fiveHourPct,
                    fiveHourResets,
                    sevenDayResets,
                    projection.projectedPct,
                    accountEmail,
                    spendPct,
                    spendResets
                ])
            }
        }

        try recordStatusLineMetrics(sessionId: sessionId, hookData: hookData, accountEmail: accountEmail)
    }

    /// Parts 2 and 3 of ``ingestStatusLinePayload(sessionId:hookData:timestamp:accountEmail:)``:
    /// the version schema and the `session_metrics` columns, inside the
    /// caller's write transaction.
    private func recordStatusLineMetrics(sessionId: String, hookData: [String: Any], accountEmail: String) throws {
        // 2. claude_versions: union field paths across captures. First-seen
        // blob wins; subsequent captures only enlarge the path set.
        let claudeVersion = hookData["version"] as? String ?? ""
        if !claudeVersion.isEmpty {
            try ingestClaudeVersion(claudeVersion: claudeVersion, payload: hookData)
        }

        // 3. session_metrics extended columns. Inlined because we're already
        // inside the write transaction; calling `upsertSessionMetricsExtended` would
        // deadlock.
        guard !sessionId.isEmpty else { return }
        let workspace = hookData["workspace"] as? [String: Any] ?? [:]
        let contextWindow = hookData["context_window"] as? [String: Any] ?? [:]
        let cost = hookData["cost"] as? [String: Any] ?? [:]
        let projectDir = workspace["project_dir"] as? String ?? ""
        let transcriptPath = hookData["transcript_path"] as? String ?? ""
        let contextWindowSize = intValue(contextWindow["context_window_size"])
        let apiDurationMs = intValue(cost["total_api_duration_ms"])
        let linesAdded = intValue(cost["total_lines_added"])
        let linesRemoved = intValue(cost["total_lines_removed"])
        let remainingPct = contextWindow["remaining_percentage"] as? Double
            ?? Double(contextWindow["remaining_percentage"] as? Int ?? 100)
        let contextUsedPct = max(0, min(100, 100 - Self.saturatingInt(remainingPct.rounded())))

        try execute("""
            INSERT INTO session_metrics (
                session_id, total_input_tokens, total_output_tokens,
                cache_read_tokens, cache_creation_tokens, total_cost_usd,
                turn_count, model, first_turn_at, last_turn_at, updated_at,
                claude_version, project_dir, transcript_path,
                context_window_size, api_duration_ms, lines_added,
                lines_removed, context_used_pct, account_email
            ) VALUES (?, 0, 0, 0, 0, 0, 0, '', '', '', datetime('now'),
                      ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(session_id) DO UPDATE SET
                claude_version = excluded.claude_version,
                project_dir = excluded.project_dir,
                transcript_path = excluded.transcript_path,
                context_window_size = excluded.context_window_size,
                api_duration_ms = excluded.api_duration_ms,
                lines_added = excluded.lines_added,
                lines_removed = excluded.lines_removed,
                context_used_pct = excluded.context_used_pct,
                updated_at = datetime('now'),
                account_email = CASE WHEN excluded.account_email != '' AND session_metrics.account_email = ''
                                      THEN excluded.account_email ELSE session_metrics.account_email END
        """, params: [
            sessionId,
            claudeVersion, projectDir, transcriptPath,
            contextWindowSize, apiDurationMs, linesAdded,
            linesRemoved, contextUsedPct, accountEmail
        ])
    }

    /// Whether `accountEmail`'s newest stored snapshot is later than `timestamp`.
    ///
    /// The storage trim deletes old snapshots (keeping the newest per account),
    /// so a redelivered old StatusLine (a quarantine retry, a spool replay) no
    /// longer matches the sink's (session, timestamp) dedup. Stored, it would
    /// take the highest id and `latestRateLimitSnapshot` (newest id first) would
    /// serve its stale numbers. A render older than what the account already
    /// has is never news, so it is not stored. Compared by `julianday`, so a
    /// stamp with and one without fractional seconds still order correctly.
    ///
    /// A newest row stamped more than a minute ahead of the clock (written
    /// before the clock stepped back) is not "newer": trusting it would drop
    /// every render for the account until wall time caught up with it.
    private func olderThanNewestSnapshot(timestamp: String, accountEmail: String) throws -> Bool {
        var older = false
        try query("""
            SELECT julianday(timestamp) > julianday(?)
                   AND julianday(timestamp) <= julianday('now', '+1 minute')
            FROM rate_limit_snapshots
            WHERE account_email = ?
            ORDER BY id DESC LIMIT 1
            """, params: [timestamp, accountEmail]) { row in
            older = int(row, 0) == 1
        }
        return older
    }

    private struct WeeklyProjection {
        let weekStart: String
        let elapsedHours: Int
        let elapsedDay: Double
        let dailyAvgPct: Double
        let projectedPct: Double
    }

    /// Ports CSL's `compute_projection` and `get_week_start` into the
    /// daemon. Returns zeroed fields when the seven-day reset timestamp
    /// is missing or stale — callers will still write the row so the
    /// raw quotas are preserved.
    private func computeWeeklyProjection(
        sessionId: String,
        sevenDayResetsAt: Int,
        weeklyPct: Double
    ) -> WeeklyProjection {
        let now = Date()
        let nowTs = Int(now.timeIntervalSince1970)
        let maxReset = nowTs + 7 * 86400 + 3600
        let effective = (sevenDayResetsAt > nowTs && sevenDayResetsAt <= maxReset)
            ? sevenDayResetsAt
            : 0
        guard effective > 0 else {
            return WeeklyProjection(
                weekStart: "",
                elapsedHours: 0,
                elapsedDay: 0,
                dailyAvgPct: 0,
                projectedPct: 0
            )
        }

        let weekStartDate = Date(timeIntervalSince1970: TimeInterval(effective - 7 * 86400))
        let weekStartStr = UTCDay.string(from: weekStartDate)

        let elapsedSeconds = now.timeIntervalSince(weekStartDate)
        let elapsedHours = max(1, Int(elapsedSeconds / 3600))
        let elapsedDay = min(elapsedSeconds / 86400, 7.0)
        let daysOfWork = max(1.0, elapsedSeconds / 86400)
        let dailyAvg = weeklyPct / daysOfWork
        let projected = dailyAvg * 7.0

        return WeeklyProjection(
            weekStart: weekStartStr,
            elapsedHours: elapsedHours,
            elapsedDay: (elapsedDay * 100).rounded() / 100,
            dailyAvgPct: (dailyAvg * 10).rounded() / 10,
            projectedPct: (projected * 10).rounded() / 10
        )
    }

    /// First capture: insert the JSON blob + sorted path union.
    /// Subsequent captures: merge any newly observed paths into the
    /// stored union (`field_paths`), leaving the blob alone. Mirrors
    /// CSL's `insert_version` behavior so a Claude version that drops
    /// conditional fields (rate_limits, worktree, etc.) on a later
    /// render doesn't look like Anthropic removed them.
    private func ingestClaudeVersion(claudeVersion: String, payload: [String: Any]) throws {
        let observed = Self.withoutLocalInjections(payload)
        let newPaths = Set(Self.extractFieldPaths(observed))

        var existingPaths: Set<String>?
        try query("""
            SELECT field_paths FROM claude_versions WHERE claude_version = ?
        """, params: [claudeVersion]) { row in
            let raw = string(row, 0)
            if let data = raw.data(using: .utf8),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
                existingPaths = Set(parsed)
            } else {
                existingPaths = []
            }
        }

        if let existingPaths {
            let merged = existingPaths.union(newPaths)
            guard merged != existingPaths else { return }
            let sortedPaths = merged.sorted()
            let pathsJSON = (try? JSONSerialization.data(
                withJSONObject: sortedPaths
            )).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            try execute("""
                UPDATE claude_versions
                   SET field_paths = ?, fields_count = ?
                 WHERE claude_version = ?
            """, params: [pathsJSON, sortedPaths.count, claudeVersion])
        } else {
            let sortedPaths = newPaths.sorted()
            let blobJSON = (try? JSONSerialization.data(
                withJSONObject: observed,
                options: [.prettyPrinted, .sortedKeys]
            )).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            let pathsJSON = (try? JSONSerialization.data(
                withJSONObject: sortedPaths
            )).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            try execute("""
                INSERT INTO claude_versions
                    (claude_version, fields, fields_count, first_seen, field_paths)
                VALUES (?, ?, ?, datetime('now'), ?)
            """, params: [
                claudeVersion, blobJSON, sortedPaths.count, pathsJSON
            ])
        }
    }

    /// Namespace reserved for keys the daemon's own status-line CLI adds to a
    /// hook payload before the daemon sees it — currently only
    /// `stenographer_git`, which `steno statusline` injects (see
    /// `GitContextFingerprint.payloadKey`, which documents the same namespace
    /// from the writing side). The prefix is a wire name in payloads already
    /// written, not a product name, so it stays as it is.
    ///
    /// A prefix rather than a shared list of literal keys: the two live in
    /// targets that cannot import each other, and a list would have to be
    /// spelled twice — which is how a filter silently stops filtering when the
    /// third key is added.
    static let localInjectionPrefix = "stenographer_"

    /// `payload` with the daemon's own injected keys removed.
    ///
    /// `claude_versions` is what forces this. That table records *Anthropic's*
    /// payload schema per Claude Code version: its blob is first-seen-wins and
    /// its `field_paths` union is only ever added to, so a locally injected
    /// subtree misreports the schema permanently, in an audit table with no
    /// mechanism to clean itself. Storage is unaffected — `flattenLeaves` still
    /// sees the whole payload, and `stenographer_git_*` still becomes columns.
    static func withoutLocalInjections(_ payload: [String: Any]) -> [String: Any] {
        payload.filter { !$0.key.hasPrefix(localInjectionPrefix) }
    }

    /// Recursively collect dotted field paths from a JSON object. Mirrors
    /// the Python `_extract_paths` walker in `references/statusline/db.py`:
    /// dicts contribute every key (recursing into values); lists contribute
    /// `[]` appended to the prefix and recurse into the first element. Used
    /// to build the `claude_versions.field_paths` union.
    static func extractFieldPaths(_ value: Any, prefix: String = "") -> [String] {
        var paths: [String] = []
        if let dict = value as? [String: Any] {
            for (key, val) in dict {
                let path = prefix.isEmpty ? key : "\(prefix).\(key)"
                paths.append(path)
                paths.append(contentsOf: extractFieldPaths(val, prefix: path))
            }
        } else if let array = value as? [Any], let first = array.first {
            paths.append(contentsOf: extractFieldPaths(first, prefix: prefix + "[]"))
        }
        return paths
    }

    private func doubleValue(_ value: Any?) -> Double {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let int64 = value as? Int64 { return Double(int64) }
        if let str = value as? String, let parsed = Double(str) { return parsed }
        return 0
    }

    private func intValue(_ value: Any?) -> Int {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let double = value as? Double { return Self.saturatingInt(double) }
        if let str = value as? String, let parsed = Int(str) { return parsed }
        return 0
    }

    /// `Int` from a payload double, saturating at the `Int` bounds.
    ///
    /// `Int(someDouble)` is not a throwing conversion — an out-of-range value is
    /// a Swift runtime *fault*, uncatchable, which kills the daemon rather than
    /// failing the event. That matters because these doubles come out of
    /// `JSONSerialization`: a `resets_at` in the wrong unit, a "never" sentinel
    /// past 9.2e18, or the literal `1e400` (which decodes to `+inf`) all reach
    /// here intact, and a crash bypasses the whole quarantine path that exists
    /// to survive malformed payloads — launchd just restarts the daemon onto the
    /// same drop file. Saturating keeps a nonsense reading nonsense, which the
    /// callers already tolerate (`resets_at` is sanity-checked against now), and
    /// keeps ingestion alive.
    static func saturatingInt(_ value: Double) -> Int {
        // NaN is the only value with no defensible answer — it is not above or
        // below anything, so it cannot saturate in either direction. Infinity
        // can: it is on one side, and the comparisons below already put it
        // there. Rejecting it to 0 instead would turn an absurdly large
        // `resets_at` into the epoch, which reads as a plausible past instant.
        guard !value.isNaN else { return 0 }
        if value >= Double(Int.max) { return .max }
        if value <= Double(Int.min) { return .min }
        return Int(value)
    }
}
#endif
