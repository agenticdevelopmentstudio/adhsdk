#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import GRDB
import OSLog
import Foundation

// The Usage section's compute and its stale-while-revalidate cache, the
// per-turn aggregates, Fable share and activity-hours queries behind it.
extension DaemonDatabase {

    // MARK: - Usage-rows cache

    /// Serve the Usage section without ever blocking on a DB lane.
    /// Returns the last cached rows immediately (or an `available:false`
    /// placeholder when nothing is cached yet) and, when the cache is older than
    /// `ttl`, kicks a single background refresh onto the DB queue. This keeps the
    /// status line's 2s render fast even while ingestion/import saturates the
    /// queue, and collapses many concurrent sessions' renders into one refresh
    /// per TTL (which itself relieves the contention). Both the HTTP
    /// `/insights/usage-rows` endpoint and the XPC `usageRows` reply go through
    /// here; only tests/refresh call `computeUsageRows` live.
    func statusLineUsageRows(
        ttl: TimeInterval = DaemonDatabase.usageCacheTTL,
        now: Date = Date()
    ) -> Sessions.UsageRowsDTO {
        usageCacheLock.lock()
        let cached = cachedUsageRows
        let fresh = cachedUsageRowsAt.map { now.timeIntervalSince($0) <= ttl } ?? false
        let startRefresh = !fresh && !usageRefreshInFlight
        if startRefresh { usageRefreshInFlight = true }
        usageCacheLock.unlock()

        if startRefresh {
            // Off the DB lanes entirely: refreshUsageRowsCache reads via the read
            // pool (query routes there), so it needs no write lane. A plain global
            // queue keeps it single-flight (usageRefreshInFlight) without holding
            // the writer.
            DispatchQueue.global(qos: .utility).async { [weak self] in self?.refreshUsageRowsCache() }
        }
        // Nudge the per-account quota probe on the same render. The app pushes
        // *credentials*, not readings — the daemon is what probes — so nothing
        // else in the daemon ever asks for a measurement: `setCredentials` only
        // invalidates the cache, and `remeasure` is reachable only from the Usage
        // window's Reload button. Without this line `accountQuotaSource.current()`
        // stays `[]` forever for the status line and the widget, which is exactly
        // what "the per-account sections are empty until you open the window and
        // press Reload" looks like. Non-blocking and single-flight, and it probes
        // only while someone is rendering, which is the schedule the TTL
        // describes.
        accountQuotaSource?.refreshIfStale()
        return cached ?? Sessions.UsageRowsDTO(available: false, quotaRows: [], weekRows: [])
    }

    /// Re-probe every account, then rebuild the usage rows from what that round
    /// measured, calling back once both are done — the Reload button's path.
    ///
    /// The rebuild is the half that matters to the window. The rows are a
    /// stale-while-revalidate cache built from the readings held when they were
    /// computed, so a Reload that only re-probed and then read them got back
    /// rows from *before* its own round: after a Wi-Fi drop, the very "offline"
    /// cards it was clicked to clear.
    func remeasureAccountQuotas(completion: @escaping @Sendable (Bool) -> Void) {
        guard let store = accountQuotaSource else {
            completion(false)
            return
        }
        store.remeasure { [weak self] measured in
            // Off the probe queue, as the background refresh is: the rows read
            // the database, and the probe queue is for network round-trips.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.refreshUsageRowsCache()
                completion(measured)
            }
        }
    }

    /// Recompute the Usage rows and store them in the cache. Invoked on the DB
    /// `queue` by `statusLineUsageRows`' background refresh (and directly by
    /// tests). Always clears the in-flight flag so a later stale read can refresh
    /// again, even if the computation returned an `available:false` placeholder.
    func refreshUsageRowsCache() {
        // A failure here (e.g. the aggregate read was deadline-ejected on a large
        // DB) is a transient/timing problem, not new data. NEVER overwrite a
        // previously-good cache with an `available:false` blank — that would strand
        // the Usage section empty until the process restarts, since every later
        // refresh would re-eject identically. Keep serving stale; only replace the
        // cache on success. Always clear the in-flight flag so a stale read retries.
        let computed = try? computeUsageRows()
        usageCacheLock.lock()
        // A SUCCESSFUL compute that reports `available:false` is not new data
        // either — it means this run found nothing usable (no snapshot, no week
        // anchor) — and it must not evict rows that were usable a moment ago.
        // That is the same eviction the paragraph above forbids, reached by a
        // different road: the value arrived rather than the call throwing.
        let keepCached = cachedUsageRows?.available == true && computed?.available != true
        if let computed, !keepCached {
            cachedUsageRows = computed
            cachedUsageRowsAt = Date()
        } else if cachedUsageRows == nil {
            // Nothing cached yet AND compute failed: seed an empty placeholder so the
            // first read gets a definite answer, and STAMP it so a persistently-failing
            // compute retries at the TTL cadence instead of launching a fresh
            // (10s-ejecting) refresh on every single status-line poll.
            cachedUsageRows = Sessions.UsageRowsDTO(available: false, quotaRows: [], weekRows: [])
            cachedUsageRowsAt = Date()
        } else {
            // Kept the previous good rows. Stamp them anyway, for the same
            // reason the placeholder above is stamped: without a fresh stamp a
            // persistently failing (or persistently blank) compute relaunches
            // on every single status-line poll instead of at the TTL cadence.
            cachedUsageRowsAt = Date()
        }
        usageRefreshInFlight = false
        usageCacheLock.unlock()
    }

    // MARK: - StatusLine queries (Phase 4)

    /// Append a `<column> = ?` account filter. Shared by the account-scoped
    /// usage reads so one rule about what an account argument means lives in one
    /// place — and the rule is that `nil` and `""` are different questions:
    ///
    /// - `nil` — no account was asked for. No filter: every account's rows, which
    ///   is what the cross-account rows (today, the weekly comparison, hours)
    ///   want and what an API-key install with no account at all must still see.
    /// - `""` — an account WAS asked for and its name came back empty. The three
    ///   usage tables declare `account_email TEXT NOT NULL DEFAULT ''`, so this
    ///   filters to exactly the rows nothing could be attributed to.
    ///
    /// `""` used to fall through to the `nil` case and drop the filter, which is
    /// how one account's numbers ended up on another's card: `buildAccountSections`
    /// asks for a snapshot per credential, and a credential with no email then got
    /// handed the globally-latest snapshot — whoever that happened to be. A read
    /// scoped to nobody must answer with nobody's rows, not with everybody's.
    func appendAccountFilter(
        _ account: String?,
        column: String,
        clauses: inout [String],
        params: inout [any Sendable]
    ) {
        guard let account else { return }
        clauses.append("\(column) = ?")
        params.append(account)
    }

    /// An ISO-8601 window as epoch seconds for the event store's turn reads.
    /// A nil or empty bound is no bound; nil when a bound does not parse — a
    /// window nobody can read covers no turns.
    static func usageRange(since: String?, until: String?) -> (since: Double?, until: Double?)? {
        func bound(_ iso: String?) -> Double?? {
            guard let iso, !iso.isEmpty else { return .some(nil) }
            guard let date = TimestampParsing.parse(iso) else { return nil }
            return .some(date.timeIntervalSince1970)
        }
        guard let lower = bound(since), let upper = bound(until) else { return nil }
        return (lower, upper)
    }

    /// The `sessions` condition selecting one account's sessions: its
    /// `account_email`, matched case-insensitively. For the logged-in account
    /// (`currentAccountEmail`) it also takes the sessions with no account —
    /// the legacy `resolvedAccountForSession` rule, under which every turn of
    /// such a session was stamped with whoever was logged in. Any other saved
    /// account stays strict, and `""` matches only the unattributed sessions.
    func accountSessionCondition(_ account: String) -> (sql: String, params: [any Sendable]) {
        let strict = "account_email = ? COLLATE NOCASE"
        guard !account.isEmpty,
              account.caseInsensitiveCompare(currentAccountEmail) == .orderedSame else {
            return (strict, [account])
        }
        return ("(\(strict) OR COALESCE(account_email, '') = '')", [account])
    }

    /// The sessions an account and/or project filter allows, read from this
    /// database for the event store's turn reads (a two-step read — the two
    /// files are never `ATTACH`ed). Nil when neither filter is given: every
    /// session, including turns whose session has no row here.
    ///
    /// - `account`: the sessions `accountSessionCondition` selects (`""`
    ///   matches only the sessions nothing was attributed to — see
    ///   `appendAccountFilter` for why `nil` and `""` differ).
    /// - `project`: sessions whose `session_metrics.project_dir` matches; an
    ///   empty project is no filter.
    func usageSessionIds(account: String?, project: String?) throws -> [String]? {
        var allowed: Set<String>?
        if let account {
            var ids = Set<String>()
            let condition = accountSessionCondition(account)
            try query("SELECT session_id FROM sessions WHERE \(condition.sql)",
                      params: condition.params) { row in ids.insert(self.string(row, 0)) }
            allowed = ids
        }
        if let project, !project.isEmpty {
            var ids = Set<String>()
            try query("SELECT session_id FROM session_metrics WHERE project_dir = ?",
                      params: [project]) { row in ids.insert(self.string(row, 0)) }
            allowed = allowed.map { $0.intersection(ids) } ?? ids
        }
        return allowed.map { Array($0) }
    }

    /// Sum the tokens of the Claude turns in the event store (`events.db`
    /// `turns`) matching the filter, grouped by model / session / "all". Cost
    /// is computed via ``TranscriptPricing`` so the value stays consistent
    /// across the codebase.
    ///
    /// For `groupBy: "all"` and `groupBy: "session"`, cost would be wrong
    /// if we applied one model's rate to the SUM of tokens — Opus is 5×
    /// Sonnet, Haiku 0.27×, so a mixed-model window costed at any single
    /// rate is materially off. The store read always aggregates by model
    /// within the requested key, each model's totals are costed via
    /// `TranscriptPricing`, then collapsed back into the requested grouping.
    ///
    /// `since`/`until` are ISO-8601 bounds, `[since, until)`; a ranged read
    /// leaves out turns from lines that carried no timestamp, and a bound that
    /// does not parse answers empty. Without an event store attached, empty.
    ///
    /// - Parameter limit: number of groups to return, capped at 500. The cap is
    ///   applied in the store read when ranking outer keys
    ///   (`claudeTurnTotals(topKeys:)`), so a whole-history `group_by=session`
    ///   never materialises every group. `groupBy: "all"` always returns at
    ///   most one row.
    func turnAggregates(
        since: String? = nil,
        until: String? = nil,
        groupBy: String = "all",
        toolName: String? = nil,
        project: String? = nil,
        account: String? = nil,
        limit: Int = 100
    ) throws -> [Sessions.TurnAggregateDTO] {
        let grouping: ClaudeTurnGrouping
        switch groupBy {
        case "model":   grouping = .model
        case "session": grouping = .session
        default:        grouping = .all
        }
        guard let range = Self.usageRange(since: since, until: until) else { return [] }
        let sessionIds = try usageSessionIds(account: account, project: project)
        let capped = min(max(limit, 1), 500)
        let groups = try claudeTurnTotals(
            since: range.since, until: range.until, toolName: toolName, sessionIds: sessionIds,
            groupBy: grouping, topKeys: capped)

        struct Bucket {
            var turnCount = 0
            var inputTokens = 0
            var outputTokens = 0
            var cacheRead = 0
            var cacheCreate = 0
            var cost = 0.0
        }
        var buckets: [(key: String, value: Bucket)] = []
        var index: [String: Int] = [:]

        for group in groups {
            let outerKey = group.key
            let count = group.turnCount
            let inputTokens = group.inputTokens
            let outputTokens = group.outputTokens
            let cacheRead = group.cacheReadTokens
            let cacheCreate = group.cacheCreationTokens
            let cost = TranscriptPricing.cost(
                model: group.model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheRead,
                cacheCreationTokens: cacheCreate,
                cacheCreation1hTokens: group.cacheCreation1hTokens
            )
            if let idx = index[outerKey] {
                buckets[idx].value.turnCount += count
                buckets[idx].value.inputTokens += inputTokens
                buckets[idx].value.outputTokens += outputTokens
                buckets[idx].value.cacheRead += cacheRead
                buckets[idx].value.cacheCreate += cacheCreate
                buckets[idx].value.cost += cost
            } else {
                index[outerKey] = buckets.count
                buckets.append((outerKey, Bucket(
                    turnCount: count,
                    inputTokens: inputTokens,
                    outputTokens: outputTokens,
                    cacheRead: cacheRead,
                    cacheCreate: cacheCreate,
                    cost: cost
                )))
            }
        }

        // `buckets` already holds at most `capped` entries — the sort is for the
        // caller's ordering, not for the cut.
        let sorted = buckets.sorted {
            $0.value.turnCount != $1.value.turnCount ? $0.value.turnCount > $1.value.turnCount : $0.key < $1.key
        }
        return sorted.prefix(capped).map { entry in
            Sessions.TurnAggregateDTO(
                groupKey: entry.key,
                turnCount: entry.value.turnCount,
                inputTokens: entry.value.inputTokens,
                outputTokens: entry.value.outputTokens,
                cacheReadTokens: entry.value.cacheRead,
                cacheCreationTokens: entry.value.cacheCreate,
                totalCostUsd: entry.value.cost
            )
        }
    }

    /// What fraction of one account's spending in a window went on the Fable
    /// tier — `0.0` to `1.0`, or `nil` when the window cost nothing.
    ///
    /// This is the measurement the Fable sub-limit row falls back on when the
    /// probe does not carry Anthropic's own Fable bucket (`7d_oi`, see
    /// `Sessions.AccountQuotaReadingDTO.fableLimitPct`) — which, for every account
    /// probed so far, is always. The status-line payload has never carried that
    /// window either, so the only place the split can come from is the
    /// transcripts the daemon already captures.
    ///
    /// **Cost, not tokens.** A quota is spent in dollars, and the tiers price
    /// very differently — Fable output bills at twice Opus's, while Fable 5.1's
    /// cache reads bill at half of Opus's — so a token count would misstate the
    /// mix in both directions. Each model's totals are priced separately
    /// through `TranscriptPricing.cost`, in ONE pass grouped by model with no cap on how many models there are:
    /// a cap ranked by turn count would drop the rarest models first, and
    /// Fable is exactly the rare one.
    ///
    /// **`nil` is not zero.** An account whose window holds no priced turns has
    /// an *unknown* share; the row draws `—` rather than a confident `0.0%`
    /// over a window it never measured.
    ///
    /// **It is the daemon's own estimate.** It sees the turns its hooks
    /// captured, so Claude run outside capture — another machine, a session
    /// predating the install, the API used directly — is missing from both
    /// halves of the ratio. The error is therefore in the *mix*, not a simple
    /// undercount.
    ///
    /// - Parameters:
    ///   - account: `nil` asks about every account (the API-key install that
    ///     has no account at all), `""` about the rows nothing could be
    ///     attributed to. Matched **case-insensitively**: a probe names the
    ///     account as the app stored it and a transcript as `~/.claude.json`
    ///     spells it, and the two differ in case in the wild. The logged-in
    ///     account also takes the sessions with no account
    ///     (`accountSessionCondition`).
    ///   - credential: which of the account's credentials billed the turns. A
    ///     setup token and the same address's login are metered separately, so
    ///     `.longLived` counts only sessions stamped `auth_method = 'token'`
    ///     and `.oauth` everything else (a session whose method was never
    ///     learned ran as the login far more often than not); `nil` counts both.
    func fableCostShare(
        account: String?,
        credential: ClaudeCredentialKind? = nil,
        since: String,
        until: String
    ) throws -> Double? {
        guard let range = Self.usageRange(since: since, until: until) else { return nil }

        // Two steps: which sessions count comes from this database (account and
        // auth method live on `sessions`), the turns from the event store.
        let credentialClause: String?
        switch credential {
        case nil:        credentialClause = nil
        case .longLived?: credentialClause = "COALESCE(auth_method, '') = 'token'"
        case .oauth?:     credentialClause = "COALESCE(auth_method, '') <> 'token'"
        }
        let groups: [ClaudeTurnTotals]
        if let account {
            var ids: [String] = []
            let condition = accountSessionCondition(account)
            try query("""
                SELECT session_id FROM sessions
                WHERE \(condition.sql)\(credentialClause.map { " AND \($0)" } ?? "")
                """, params: condition.params) { row in ids.append(self.string(row, 0)) }
            groups = try claudeTurnTotals(
                since: range.since, until: range.until, sessionIds: ids, groupBy: .model)
        } else if credential == .longLived {
            var ids: [String] = []
            try query("SELECT session_id FROM sessions WHERE COALESCE(auth_method, '') = 'token'") { row in
                ids.append(self.string(row, 0))
            }
            groups = try claudeTurnTotals(
                since: range.since, until: range.until, sessionIds: ids, groupBy: .model)
        } else if credential == .oauth {
            // Everything but the token sessions — a turn whose session has no
            // row here was never stamped `token`, so it counts as the login.
            var tokenSessions = Set<String>()
            try query("SELECT session_id FROM sessions WHERE COALESCE(auth_method, '') = 'token'") { row in
                tokenSessions.insert(self.string(row, 0))
            }
            groups = try claudeTurnTotals(since: range.since, until: range.until, groupBy: .session)
                .filter { !tokenSessions.contains($0.key) }
        } else {
            groups = try claudeTurnTotals(since: range.since, until: range.until, groupBy: .model)
        }

        var fable = 0.0
        var total = 0.0
        for group in groups {
            let cost = TranscriptPricing.cost(
                model: group.model,
                inputTokens: group.inputTokens,
                outputTokens: group.outputTokens,
                cacheReadTokens: group.cacheReadTokens,
                cacheCreationTokens: group.cacheCreationTokens,
                cacheCreation1hTokens: group.cacheCreation1hTokens
            )
            total += cost
            if TranscriptPricing.isFableTier(group.model) { fable += cost }
        }
        guard total > 0 else { return nil }
        return fable / total
    }

    /// ``fableCostShare(account:credential:since:until:)`` for the Usage hot
    /// path: held for ``fableShareCacheTTL`` per (account, credential, window
    /// start), and never throwing.
    ///
    /// A failed read is **logged**, and answered with the last good share for
    /// the same key if there is one — a busy DB lane must not blank the gauge
    /// or flip it between a number and `—` from one refresh to the next. With
    /// no good share to fall back on it answers `nil`, the row's "unknown".
    func cachedFableCostShare(
        account: String?,
        credential: ClaudeCredentialKind?,
        since: String,
        until: String,
        now: Date = Date()
    ) -> Double? {
        if case .measured(let share) = cachedFableShare(
            account: account, credential: credential, since: since, until: until, now: now) {
            return share
        }
        return nil
    }

    /// The Fable share for a quota reading: its credential's own mix, else the
    /// whole account's. A credential that billed no priced turn in the window
    /// (often the setup token the card shows) has no mix of its own, and the
    /// account's is the best estimate there is — without it the Fable gauge
    /// went blank on an account with plenty of measured spending.
    ///
    /// Only "no turns" falls back. A read that failed with nothing cached is
    /// unknown (nil), never the account's mix, so a credential with its own mix
    /// cannot switch between two estimates from one refresh to the next.
    /// Both Usage call sites — the current account's rows and every saved
    /// credential's section — ask this, so they cannot disagree.
    func readingFableCostShare(
        account: String?,
        credential: ClaudeCredentialKind?,
        since: String,
        until: String,
        now: Date = Date()
    ) -> Double? {
        switch cachedFableShare(account: account, credential: credential, since: since, until: until, now: now) {
        case .measured(let share):
            return share
        case .unknown:
            return nil
        case .noTurns:
            guard credential != nil else { return nil }
            return cachedFableCostShare(account: account, credential: nil, since: since, until: until, now: now)
        }
    }

    private enum CachedFableShare {
        case measured(Double)
        /// Read fine: nothing priced in the window.
        case noTurns
        /// The read failed and nothing good was cached.
        case unknown
    }

    private func cachedFableShare(
        account: String?,
        credential: ClaudeCredentialKind?,
        since: String,
        until: String,
        now: Date
    ) -> CachedFableShare {
        let key = "\(account?.lowercased() ?? "*")|\(credential?.rawValue ?? "*")|\(since)"
        fableShareCacheLock.lock()
        let cached = fableShareCache[key]
        fableShareCacheLock.unlock()
        if let cached, now.timeIntervalSince(cached.at) < Self.fableShareCacheTTL {
            return cached.share.map(CachedFableShare.measured) ?? .noTurns
        }
        do {
            let share = try fableCostShare(
                account: account, credential: credential, since: since, until: until)
            fableShareCacheLock.lock()
            fableShareCache[key] = (share, now)
            fableShareCacheLock.unlock()
            return share.map(CachedFableShare.measured) ?? .noTurns
        } catch {
            let reason = error.localizedDescription
            logger.error("fable cost share failed: \(reason, privacy: .public)")
            guard let cached else { return .unknown }
            return cached.share.map(CachedFableShare.measured) ?? .noTurns
        }
    }

    /// Server-side port of CSL's ``usage_hours.py:_active_seconds``.
    /// Walks the event store's Claude turns ordered by (session_id, time), sums
    /// the spans of contiguous bursts whose inter-turn gaps stay below
    /// `idleThresholdS`. A session boundary or oversized gap closes the
    /// current burst without contributing the gap itself.
    func activeHours(
        since: String,
        until: String,
        account: String? = nil,
        idleThresholdS: Int = 15 * 60
    ) throws -> Sessions.ActiveHoursDTO {
        let (intervals, turnCount) = try burstIntervals(
            since: since, until: until, account: account, idleThresholdS: idleThresholdS
        )
        let total = intervals.reduce(0.0) { $0 + ($1.end - $1.start) }
        return Sessions.ActiveHoursDTO(
            since: since,
            until: until,
            idleThresholdS: idleThresholdS,
            activeSeconds: total,
            turnCount: turnCount
        )
    }

    /// Active seconds two ways over `[since, until)`, from a single query/pass:
    ///  - `active`    — sums each session's in-burst spans; parallel sessions ADD
    ///                  (the status line's existing "hrs" metric — can top 24h/day).
    ///  - `wallClock` — merges those bursts across ALL sessions, so overlapping /
    ///                  parallel work counts once (real clock time, ≤ elapsed).
    /// Same 15-min idle threshold splits bursts in both.
    func hoursMetrics(
        since: String,
        until: String,
        account: String? = nil,
        idleThresholdS: Int = 15 * 60
    ) throws -> (active: Double, wallClock: Double) {
        let (intervals, _) = try burstIntervals(
            since: since, until: until, account: account, idleThresholdS: idleThresholdS
        )
        let active = intervals.reduce(0.0) { $0 + ($1.end - $1.start) }
        return (active, Self.mergedSeconds(intervals))
    }

    /// Walk turns in `[since, until)` into per-session active bursts: turns whose
    /// inter-arrival gap stays within `idleThresholdS` belong to one burst; a
    /// larger gap (or a new session) closes it. Returns each burst's
    /// `[start, end]` epoch span plus the total turn count — shared by
    /// `activeHours` (sums spans) and `hoursMetrics` (also unions them).
    private func burstIntervals(
        since: String,
        until: String,
        account: String?,
        idleThresholdS: Int
    ) throws -> (intervals: [(start: Double, end: Double)], turnCount: Int) {
        // The event store keeps each turn's time as epoch seconds, so the walk
        // never parses a date. A ranged read already leaves out turns from lines
        // that carried no timestamp (stored at the epoch), which would otherwise
        // wreck the burst-span math for their session. An unparseable bound
        // covers no turns.
        guard let range = Self.usageRange(since: since, until: until) else { return ([], 0) }
        let sessionIds = try usageSessionIds(account: account, project: nil)
        let times = try claudeTurnTimes(
            since: range.since ?? 0, until: range.until ?? .greatestFiniteMagnitude, sessionIds: sessionIds)

        // The rule's one home is `sessionBursts`, which the usage summary's
        // `usage_bursts` are cut with too.
        let intervals = Self.sessionBursts(times, idleGap: Double(idleThresholdS))
            .map { (start: $0.start, end: $0.end) }
        return (intervals, times.count)
    }

    /// Total length of a set of intervals after merging overlaps — the union
    /// (wall-clock) duration. The sweep is Core's `ActivityRuns.unionLength`.
    private static func mergedSeconds(_ intervals: [(start: Double, end: Double)]) -> Double {
        ActivityRuns.unionLength(intervals.map { ActivityRuns.Span(start: $0.start, end: $0.end) })
    }
}
#endif
