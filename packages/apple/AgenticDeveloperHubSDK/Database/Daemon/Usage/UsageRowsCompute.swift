#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Server-side computation of the fully-rendered Usage display strings, so the
/// Python status line and the Swift menu-bar Usage window (plus its HUD) render
/// byte-identical text — neither client recomputes anything. (Descended from
/// CSL's `base_info.py:get_usage_columns` + `get_week_comparison_rows`.)
///
/// Inputs:
///   - the most recent `rate_limit_snapshots` row (captured by the StatusLine
///     event hook on every render) — the source of the raw 7d/5h percentages
///     and their reset instants.
///   - the event store's Claude turn cost/token aggregates for the current quota-day, the
///     current quota week, and the previous week.
///
/// What it produces:
///   - the 7d/5h quota gauges — the snapshot's percentages verbatim (no
///     cost-derived math); a per-quota run-out projection (`quotaRunOut`)
///     replaces the retired projected-usage trailing.
///   - the "today" row — tokens + cost summed across ALL accounts.
///   - live countdowns from Anthropic's `resets_at` instants, with a
///     most-recent-DB-snapshot fallback for a stale 5h reset.
///   - the weekly-comparison + activity-hours rows, which span every account
///     (unlike the per-account quota gauges above).
extension DaemonDatabase {

    func computeUsageRows() throws -> Sessions.UsageRowsDTO {
        let now = Date()
        let nowTs = now.timeIntervalSince1970

        // Scope the QUOTA figures to the account logged in right now — Anthropic
        // bills quota per account, so today/7d/5h % are meaningful only per
        // account. Resolve it once (currentAccountEmail re-reads ~/.claude.json);
        // empty ⇒ nil ⇒ no filter, so an API-key user with no account still sees
        // everything. NOTE: the weekly comparison + activity-hours rows below
        // deliberately ignore this and span all accounts (see their call site).
        let oauthEmail = currentAccountEmail
        let account: String? = oauthEmail.isEmpty ? nil : oauthEmail

        // Per-credential quota sections (every credential the app has saved,
        // not just the login in use). Empty until the app has pushed a probe
        // round — clients fall back to the current-account quotaRows below.
        //
        // Built before any snapshot is consulted, because they come from the
        // probe and need none. A Mac nobody has run Claude on since the last
        // weekly reset has no usable snapshot (its 7d reset is in the past),
        // and returning without these answered `available:false` with no
        // sections: the Account Quotas window dimmed its saved cards under a
        // spinner waiting for data that never came.
        let nowTsInt = Int(nowTs)
        let nowIso = Self.formatTimestamp(date: now)
        let accountSections = Self.buildAccountSections(
            readings: accountQuotaSource?.current() ?? [],
            now: nowTsInt,
            snapshotFor: { [weak self] email in
                try? self?.latestRateLimitSnapshot(account: email)
            },
            fableShareFor: { [weak self] reading, since in
                guard let self else { return nil }
                let sinceIso = Self.formatTimestamp(
                    date: Date(timeIntervalSince1970: Double(since))
                )
                return self.readingFableCostShare(
                    account: reading.account,
                    credential: reading.credentialKind.flatMap(ClaudeCredentialKind.init(rawValue:)),
                    since: sinceIso, until: nowIso
                )
            }
        )

        // Prefer the current account's latest snapshot, but use the globally
        // latest one when it is NEWER — the status line is rendered by the
        // actively-billed session, and in a multi-account setup that session
        // may be pinned (via CLAUDE_CODE_OAUTH_TOKEN) to an account OTHER than
        // the one logged in via ~/.claude.json. Scoping strictly to the oauth
        // account would then show a stale reading for the whole pinned period
        // (the old `?? global` fallback only fired when the account had NO
        // snapshot at all). Per-account figures still come from the account
        // sections above; this is only the top gauge. (id is autoincrement, so
        // a higher id is the newer capture.)
        let scopedSnap = try latestRateLimitSnapshot(account: account)
        let globalSnap = try latestRateLimitSnapshot()
        guard let snap = Self.freshestSnapshot(scoped: scopedSnap, global: globalSnap) else {
            return Sessions.UsageRowsDTO(
                available: !accountSections.isEmpty,
                quotaRows: [],
                weekRows: [],
                accountSections: accountSections,
                oauthEmail: oauthEmail
            )
        }
        let rate7d = snap.weeklyPct
        let rate5h = snap.fiveHourPct
        // A weekly reading of 0 is VALID, not "no data": right after a quota-week
        // reset — or when a session pinned (via CLAUDE_CODE_OAUTH_TOKEN) to a
        // near-unused account becomes the globally-latest snapshot (see
        // freshestSnapshot) — weekly_pct legitimately rounds to 0 while 5h is
        // still nonzero. The ingest path only stores a snapshot when SOME quota is
        // nonzero (DaemonDatabase: weekly || five_hour || projected > 0), so any
        // stored snapshot is real data worth rendering. An earlier `guard rate7d
        // > 0` here blanked the ENTIRE Usage section — account info included —
        // during the minutes each week when weekly sat at 0. All downstream math
        // tolerates rate7d == 0 (quotaRunOut guards pct > 0).

        guard let weekStart = Self.resolveWeekStart(snap: snap, nowTs: nowTs) else {
            // No usable 7d reset, so there is no week anchor and every row below
            // — today, 7d, 5h, the week and hours comparisons — is unanswerable.
            // A spend limit is not week-anchored though: it carries its own
            // reset instant, and on a Claude-apps gateway account it can be the
            // only quota reading there is. Returning a bare `available:false`
            // here threw it away, and (via `refreshUsageRowsCache`) replaced the
            // last good rows with a blank section.
            let spend = Self.spendRow(snap: snap, now: Int(nowTs))
            return Sessions.UsageRowsDTO(
                available: spend != nil || !accountSections.isEmpty,
                quotaRows: spend.map { [$0] } ?? [],
                weekRows: [],
                accountSections: accountSections,
                oauthEmail: oauthEmail
            )
        }

        let weekIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: weekStart))

        // Today = current 24h slice of the quota week, anchored on the
        // Anthropic reset moment (not local midnight). Matches Python's
        // get_usage_columns block-comment exactly.
        let daysSinceReset = Int((nowTs - weekStart) / 86400)
        let todayStart = weekStart + Double(daysSinceReset) * 86400
        let todayEnd = todayStart + 86400
        let todayRemainingS = max(0, Int(todayEnd - nowTs))
        let todayIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: todayStart))

        // The "today" ROW tracks overall usage across ALL accounts (tokens +
        // cost, like the week rows) — per-account quota state lives in the
        // account sections.
        let todayAllAggs = try turnAggregates(
            since: todayIso, until: nowIso, groupBy: "all", account: nil, limit: 1
        )
        let todayAllTokens = Self.sumTokens(todayAllAggs.first)
        let todayAllCost = todayAllAggs.first?.totalCostUsd ?? 0.0

        let elapsedS = nowTs - weekStart
        let elapsedDays = elapsedS / 86400
        let remainingDays = max(0.0, 7.0 - elapsedDays)
        let weekRemainingS = max(0, Int(remainingDays * 86400))

        // 5h countdown: prefer the snapshot's `five_hour_resets_at` when it
        // points to a future moment within 5h + 1h skew buffer; otherwise no
        // countdown (the Python falls back to a separate DB lookup, but the
        // snapshot we already loaded *is* that latest stored value).
        let maxReset5h = nowTsInt + 6 * 3600
        // `try?` (not `try`): the fallback query only runs in the already-degraded
        // stale-5h case, so a transient DB error there must degrade to "no 5h
        // countdown" (nil), NOT throw out of computeUsageRows and 500 the whole
        // /insights/usage-rows response (which would blank the entire Usage
        // section). Both a thrown error and a legitimate nil map to "no countdown".
        //
        // Yields the reset INSTANT rather than the remainder: the row carries
        // both, and deriving the countdown from the instant keeps them from
        // disagreeing. The reverse (`now + remaining`) cannot be used — it
        // re-anchors on each request, so a client scheduling work for the reset
        // would see the target drift forward by however long it waited.
        let fiveHourResetsAt: Int? = try? {
            let stored = snap.fiveHourResetsAt
            if stored > nowTsInt && stored <= maxReset5h {
                return stored
            }
            // The latest snapshot's 5h reset is stale/zero — recover the most
            // recent still-future reset from history so the countdown doesn't go
            // dark on a single stale payload (the retired Python MAX fallback).
            return try latestFutureFiveHourReset(
                now: nowTsInt, maxReset: maxReset5h, account: account
            )
        }()
        let fiveHourRemainingS: Int? = fiveHourResetsAt.map { max(0, $0 - nowTsInt) }

        // Per-quota run-out: projected time until the quota hits 100% at the
        // window's average burn rate. Replaces the old 👉🏻 projected-usage
        // trailing on the 7d row (the HUD keeps its projection).
        let weekRunOut = Self.quotaRunOut(
            pct: rate7d, resetsAt: snap.sevenDayResetsAt,
            windowSeconds: 7 * 86400, now: nowTsInt
        )
        let fiveHourRunOut = fiveHourResetsAt.flatMap { resetsAt in
            Self.quotaRunOut(
                pct: rate5h, resetsAt: resetsAt,
                windowSeconds: 5 * 3600, now: nowTsInt
            )
        }

        let quotaRows = Self.buildQuotaRows(
            todayTokens: todayAllTokens,
            todayCostAllAccounts: todayAllCost,
            todayRemainingS: todayRemainingS,
            weekPct: rate7d,
            weekRemainingS: weekRemainingS,
            // The week's own anchor, not `snap.sevenDayResetsAt`: the countdown
            // beside it is `weekStart + 7d - now`, and a row whose two fields
            // disagree about when the window turns over is worse than one that
            // omits the machine-readable half.
            weekResetsAt: Int(weekStart) + 7 * 86400,
            fiveHourPct: rate5h,
            fiveHourRemainingS: fiveHourRemainingS,
            fiveHourResetsAt: fiveHourResetsAt,
            weekRunOut: weekRunOut,
            fiveHourRunOut: fiveHourRunOut,
            spendSnapshot: snap,
            // Measured over the same week the reading above reports, and scoped
            // to the account AND credential that reading belongs to — which is
            // the snapshot's, not necessarily the logged-in one's (see
            // `freshestSnapshot`). The row multiplies that snapshot's weekly
            // percentage, so any other account's Fable must not enter it; a
            // credential with no turns of its own takes its account's mix.
            fablePct: Self.estimatedFablePct(weekPct: rate7d) {
                readingFableCostShare(
                    account: snap.accountEmail.isEmpty ? account : snap.accountEmail,
                    credential: Self.credentialKind(
                        forAuthMethod: authMethodForSession(snap.sessionId)),
                    since: weekIso, until: nowIso
                )
            },
            now: nowTsInt
        )

        // Weekly comparison + activity-hours rows track OVERALL usage across
        // every account — a longitudinal record of how much work happened, which
        // per-account scoping rendered useless (each account only saw its own
        // slice). Unlike the quota math above, these span all accounts.
        let weekRows = try computeWeekComparisonRows(
            weekStart: weekStart, now: now, nowIso: nowIso, weekIso: weekIso, elapsedDays: elapsedDays,
            source: .summary
        )

        // Four burst walks over every turn of three weeks — the largest share of a
        // recompute, for figures printed to a tenth of an hour. Memoized; see
        // `HoursRowsCache`.
        let hoursRows = try hoursRowsCache.rows(weekStart: weekStart, now: now) {
            try computeHoursComparisonRows(
                weekStart: weekStart, now: now, nowIso: nowIso, weekIso: weekIso, source: .summary
            )
        }

        // `resolveWeekStart` already rejected a 7d reset that isn't both future
        // and within the window, so the instant it derived `weekStart` from is
        // sound to hand the HUD for live ticking.
        let hud = Self.buildHUD(
            weekPct: rate7d,
            weekResetsAt: snap.sevenDayResetsAt,
            fiveHourPct: rate5h,
            fiveHourResetsAt: fiveHourRemainingS.map { nowTsInt + $0 },
            accountEmail: oauthEmail
        )

        return Sessions.UsageRowsDTO(
            available: true,
            quotaRows: quotaRows,
            weekRows: weekRows,
            hoursRows: hoursRows,
            hudQuota: hud,
            accountSections: accountSections,
            oauthEmail: oauthEmail
        )
    }

    /// The snapshot the top usage gauge should render: the current account's
    /// scoped snapshot, unless the globally latest one is NEWER (higher id) —
    /// the status line is rendered by the actively-billed session, which in a
    /// multi-account setup may be pinned to an account other than the one
    /// logged in. Falls back to whichever is non-nil. Extracted for testability.
    static func freshestSnapshot(
        scoped: Sessions.RateLimitSnapshotDTO?, global: Sessions.RateLimitSnapshotDTO?
    ) -> Sessions.RateLimitSnapshotDTO? {
        switch (scoped, global) {
        case let (scoped?, global?): return global.id > scoped.id ? global : scoped
        default: return scoped ?? global
        }
    }

    // MARK: - Per-account quota sections

    /// Maximum age of a rate-limit snapshot before an account's section rows
    /// fall back to the probe. Active sessions refresh snapshots every few
    /// seconds, so 30 min cleanly separates "in use" from "idle".
    static let accountSnapshotFreshness: TimeInterval = 30 * 60

    /// One section per probed credential: the 7d and 5h quota rows formatted
    /// exactly like the current-account `quotaRows` (pct + reset countdown +
    /// 🛑 run-out), so the client renders them with the same code path.
    ///
    /// **The probe is the source of truth for both windows.** It used to be
    /// overridden by the account's own fresh rate-limit SNAPSHOT, on the
    /// evidence that the probe's 5h header tracked a trickle of 1% `rejected`
    /// while the account's real bucket sat at 91%. That gap was the probe
    /// measuring a DIFFERENT CREDENTIAL from the session — one prober held
    /// every account's setup token — and the readings are per-credential now,
    /// so the same comparison no longer describes a disagreement to paper over.
    ///
    /// Removing it also removes a contamination path the override could not
    /// avoid: a snapshot is found by account string, and a lookup that matched
    /// nothing handed back the newest snapshot belonging to ANY account, which
    /// is how two different addresses came to display one identical percentage
    /// and one identical reset instant.
    ///
    /// A `rejected` probe status paints the pct red — the limiter is refusing
    /// requests, so a small % must not read as headroom.
    ///
    /// The Fable sub-limit is the gateway's own `7d_oi` bucket when the probe
    /// carried one. When it did not — every account probed so far — the row is
    /// estimated, and the estimate needs one thing the readings do not carry:
    /// what fraction of the week's spending went on the tier. That arrives the
    /// same way the spend row's snapshot does, as a closure. The builder stays
    /// a pure function of its arguments, which is what lets the ordering rules
    /// the whole card depends on be pinned by tests that own no database.
    ///
    /// - Parameter fableShareFor: the reading (its account and credential) and
    ///   the window's start (unix seconds) → Fable's fraction (0-1) of that
    ///   window's cost, or `nil` when it is unknown. Production passes
    ///   ``DaemonDatabase/readingFableCostShare(account:credential:since:until:now:)``:
    ///   the credential's own mix, or its account's when it has no turns.
    static func buildAccountSections(
        readings: [Sessions.AccountQuotaReadingDTO],
        now: Int,
        snapshotFor: (String) -> Sessions.RateLimitSnapshotDTO?,
        fableShareFor: (Sessions.AccountQuotaReadingDTO, Int) -> Double?
    ) -> [Sessions.UsageAccountSectionDTO] {
        readings.map { reading in
            var rows: [Sessions.UsageQuotaRowDTO] = []
            let rejected7d = reading.sevenDayStatus == "rejected"
            let rejected5h = reading.fiveHourStatus == "rejected"
            if let pct = reading.sevenDayPct {
                // The 7d window FIRST, and the Fable slice carved out of it
                // second — matching the order the card draws, which it decides
                // for itself from what each row is (see `fableRow`).
                rows.append(Self.accountQuotaRow(
                    label: "7d quota", pct: pct, resetsAt: reading.sevenDayResetsAt,
                    windowSeconds: 7 * 86400, now: now, longCountdown: true,
                    rejected: rejected7d
                ))
            }
            if let fable = Self.fableRow(for: reading, now: now, shareFor: fableShareFor) {
                rows.append(fable)
            }
            if let fiveHour = Self.fiveHourRow(for: reading, now: now, rejected: rejected5h) {
                rows.append(fiveHour)
            }
            // Spend limit — the one row the probe cannot take: no response
            // header reports a spend window, so it comes from the account's own
            // fresh rate-limit snapshot or not at all.
            //
            // And only onto a login's section. A snapshot is written by a live
            // Claude Code session, which runs as the logged-in account; a setup
            // token is something to bill against, never something a session
            // runs as, so a spend row on its card would be another credential's
            // number under this one's heading.
            if reading.credentialKind != ClaudeCredentialKind.longLived.rawValue,
               let spend = Self.spendRow(snap: Self.freshSnapshot(
                   for: reading.account, now: now, snapshotFor: snapshotFor), now: now) {
                rows.append(spend)
            }
            return Sessions.UsageAccountSectionDTO(
                accountEmail: reading.account,
                credentialKind: reading.credentialKind,
                rows: rows,
                errorText: reading.errorText
            )
        }
    }

    /// The account's own rate-limit snapshot, if it has one recent enough to
    /// mean anything.
    private static func freshSnapshot(
        for account: String, now: Int, snapshotFor: (String) -> Sessions.RateLimitSnapshotDTO?
    ) -> Sessions.RateLimitSnapshotDTO? {
        snapshotFor(account).flatMap { Self.isSnapshotFresh($0, now: now) ? $0 : nil }
    }

    // MARK: - The Fable sub-limit

    /// How much of the 7d window Fable is allowed, in quota points: half of it.
    ///
    /// This is the stated rule — Fable may consume up to 50% of the weekly
    /// quota — and it is the one allowance every path divides by. It is not
    /// read from `anthropic-ratelimit-unified-fallback-percentage`, although
    /// every probe carries one and it answers `0.5` today: that header is the
    /// model-FALLBACK threshold (it read `0.2` in the wild before Fable
    /// existed, and Claude Code never reads it), and a gauge that divided by it
    /// would move the day the fallback policy did, with Fable's allowance
    /// unchanged.
    ///
    /// Anthropic's own reading of the bucket, when a response carries it, is
    /// `Sessions.AccountQuotaReadingDTO.fableLimitPct` — already a percentage of the
    /// allowance, so this constant never touches it.
    static let fableAllowancePct: Double = 50

    /// How much of the Fable allowance is gone, as a percentage of the
    /// allowance.
    ///
    /// Two numbers, because two are needed. `weekPct` says how much of the week
    /// is gone; `fableShare` (0-1) says what fraction of that went on the Fable
    /// tier. Their product is Fable's own spending in the week's own hundred
    /// points, and dividing by ``fableAllowancePct`` restates it against the
    /// fifty points Fable is actually allowed:
    ///
    ///     week 100% × 3% Fable = 3 of the week's points = 6.0% of fifty
    ///
    /// **What this replaced, and why it was wrong.** The row used to be
    /// `weekPct / 50 * 100` — the WHOLE week's consumption held against
    /// Fable's allowance, which is only the right answer for an account that
    /// spent every token on Fable. A real capture: a fully-spent week whose
    /// Fable was 2.96% of cost (74 of 2508 dollars, 409 Fable turns against
    /// 48,000 Opus ones) drew **200%** — a maxed-out sub-limit on an account
    /// that had barely touched the tier.
    ///
    /// It is an estimate, and the share it rests on is the daemon's own
    /// (see ``DaemonDatabase/fableCostShare(account:credential:since:until:)``):
    /// it assumes quota points are spent in proportion to list-price cost.
    ///
    /// It can exceed 100: the allowance is a limit, not a ceiling on what the
    /// arithmetic may report.
    ///
    /// The daemon derives it (rather than each client) for the reason every
    /// other figure here is derived once: the Usage window, the widget and the
    /// status line must not be able to disagree about a number none of them can
    /// check against a payload.
    static func fablePct(weekPct: Double, fableShare: Double) -> Double {
        weekPct * fableShare / fableAllowancePct * 100
    }

    /// The estimated Fable percentage for a week, or nil when it is unknown.
    ///
    /// A week at 0% needs no share: Fable cannot have spent more than the week
    /// did, so the answer is 0 — and it is exactly the moment (just after a
    /// reset, before anything is captured) when there is no share to ask for.
    /// `share` is therefore only called for a week with something in it; its
    /// `nil` ("nothing priced landed in this window") is the row's unknown.
    static func estimatedFablePct(weekPct: Double, share: () -> Double?) -> Double? {
        guard weekPct > 0 else { return 0 }
        return share().map { fablePct(weekPct: weekPct, fableShare: $0) }
    }

    /// Where the seven days a weekly reading covers begin, in unix seconds.
    ///
    /// The seven days ending at the reset the reading named — but only a reset
    /// that can bound THIS week: in the future, and no more than a week (plus
    /// the hour of skew `resolveWeekStart` allows) away. Anything else — a
    /// reset already past, a millisecond epoch the parser missed, a bogus
    /// header — would put the window in 1969 or start it after it ends, so the
    /// share is asked for over the rolling seven days instead.
    static func fableWindowStart(resetsAt: Int?, now: Int) -> Int {
        let week = 7 * 86400
        if let resetsAt, resetsAt > now, resetsAt <= now + week + 3600 {
            return resetsAt - week
        }
        return now - week
    }

    /// The credential a session's `auth_method` says billed it, for scoping a
    /// Fable share to one of an account's credentials: `token` is a setup
    /// token, `oauth` the login. Anything else (`''`, `unknown`) is not known
    /// well enough to scope by, and the share then counts both.
    static func credentialKind(forAuthMethod authMethod: String) -> ClaudeCredentialKind? {
        switch authMethod {
        case "token": return .longLived
        case "oauth": return .oauth
        default: return nil
        }
    }

    /// The Fable sub-limit row for one probed credential, or nil when the
    /// reading has neither a Fable bucket nor a week to estimate one from.
    ///
    /// The gateway's own `7d_oi` bucket wins outright when the probe carried
    /// it: its percentage, its reset, its refusal, and no share is asked for.
    /// Otherwise the row is estimated from the 7d reading and Fable's share of
    /// the same seven days (``fableWindowStart(resetsAt:now:)``), for this
    /// account AND this credential — a setup token and the same address's
    /// login are metered separately — or, for a credential with no turns of
    /// its own that week, the whole account's (see `shareFor`).
    ///
    /// Either way a rejected 7d window paints it red: a refused week refuses
    /// Fable along with everything else, so a modest Fable figure must not
    /// read as headroom.
    static func fableRow(
        for reading: Sessions.AccountQuotaReadingDTO,
        now: Int,
        shareFor: (Sessions.AccountQuotaReadingDTO, Int) -> Double?
    ) -> Sessions.UsageQuotaRowDTO? {
        let weekRejected = reading.sevenDayStatus == "rejected"
        if let measured = reading.fableLimitPct {
            return fableRow(
                pct: measured,
                resetsAt: reading.fableLimitResetsAt ?? reading.sevenDayResetsAt,
                now: now,
                rejected: weekRejected || reading.fableLimitStatus == "rejected"
            )
        }
        guard let weekPct = reading.sevenDayPct else { return nil }
        let start = fableWindowStart(resetsAt: reading.sevenDayResetsAt, now: now)
        return fableRow(
            pct: estimatedFablePct(weekPct: weekPct) { shareFor(reading, start) },
            resetsAt: reading.sevenDayResetsAt,
            now: now,
            rejected: weekRejected
        )
    }

    /// The Fable sub-limit row for a window.
    ///
    /// `pct` nil is **unknown**, not zero: the row still stands, with `—` for
    /// its figure and no `pct`, because a column that appears and disappears
    /// between refreshes reshuffles the card (and recolours the widget's rings)
    /// under the reader. Clients that threshold on `pct` skip it, as they skip
    /// every row without one.
    ///
    /// It carries the 7d window's own reset instant (or the `7d_oi` bucket's,
    /// when the gateway sent one), because that is when the spending it
    /// measures is forgiven. That makes it tie with the 7d row in both orders
    /// that read `resetsAt`, and **neither order settles that tie here.**
    /// `readingOrder` stands the sub-limit last by asking what the row IS, and
    /// `ringOrder` refuses the tie in the opposite direction on the same
    /// grounds (see `UsageWidgetPresentation.ringWidth`) — so the column order
    /// is the app's property, and a daemon older than the app cannot move it.
    ///
    /// Appending it after the 7d row is therefore agreement, not instruction: a
    /// real window reads better next to the other real window, and the derived
    /// figure reads better at the end of the line.
    ///
    /// **And it projects no run-out**, for the reason `isSpent` already refuses
    /// to count it: an account that has spent its Fable allowance has not run
    /// out of anything — it can still work, on every other model, against the
    /// quota the 7d row is reporting beside it. A card shows ONE run-out
    /// warning, the soonest (`UsageWidgetPresentation.soonestRunOut`), and this
    /// row would take it and never give it back — a window already at 100
    /// projects `0` seconds, which wins that ranking against every real
    /// projection there will ever be.
    ///
    /// The projection would also be drawn from the wrong rate. `quotaRunOut`
    /// extrapolates the window's burn as if it were steady, and an estimated
    /// percentage is a product of two things that move independently: the week
    /// climbs, but the Fable share can fall as fast as it rose the moment the
    /// next session picks another model.
    static func fableRow(
        pct: Double?, resetsAt: Int?, now: Int, rejected: Bool = false
    ) -> Sessions.UsageQuotaRowDTO {
        let row = accountQuotaRow(
            label: Sessions.UsageQuotaRowDTO.fableLabel,
            pct: pct ?? 0,
            resetsAt: resetsAt,
            windowSeconds: 7 * 86400, now: now, longCountdown: true,
            rejected: rejected,
            projectRunOut: false
        )
        return pct == nil ? unreadRow(row, rejected: rejected) : row
    }

    /// The 5h window on an account card, or nil when the account has none.
    ///
    /// Anthropic removed the five-hour limit from some plans, and an account
    /// without one is probed with `7d-*` headers and no `5h-*` headers at all.
    /// A missing 5h reading is therefore "no 5h limit", not "0% of one": the
    /// card leaves the gauge off rather than drawing a permanent 0% for a limit
    /// that does not exist. (1.4.18 drew that 0%, reading the missing header as
    /// a window not yet opened; the data said otherwise — the account the fix
    /// was made on stopped reporting a 5h window the same morning, through a
    /// day of heavy use.)
    static func fiveHourRow(
        for reading: Sessions.AccountQuotaReadingDTO, now: Int, rejected: Bool
    ) -> Sessions.UsageQuotaRowDTO? {
        guard let pct = reading.fiveHourPct else { return nil }
        return accountQuotaRow(
            label: Sessions.UsageQuotaRowDTO.fiveHourLabel, pct: pct,
            resetsAt: reading.fiveHourResetsAt,
            windowSeconds: 5 * 3600, now: now, longCountdown: false,
            rejected: rejected
        )
    }

    /// `row` restated as a window whose percentage was never read: `—` in
    /// place of a number, no run-out, and no `pct` for clients to rank by.
    private static func unreadRow(_ row: Sessions.UsageQuotaRowDTO, rejected: Bool) -> Sessions.UsageQuotaRowDTO {
        Sessions.UsageQuotaRowDTO(
            label: row.label,
            pctText: "—",
            pctColor: rejected ? "red" : nil,
            secondaryText: row.secondaryText,
            secondaryDimmed: row.secondaryDimmed,
            trailingText: "",
            resetsAt: row.resetsAt,
            pct: nil,
            windowSeconds: row.windowSeconds
        )
    }

    /// True when the snapshot was captured within `accountSnapshotFreshness`
    /// of `now`. Unparseable timestamps count as stale.
    private static func isSnapshotFresh(_ snap: Sessions.RateLimitSnapshotDTO, now: Int) -> Bool {
        guard let captured = TimestampParsing.parse(snap.timestamp) else { return false }
        return Double(now) - captured.timeIntervalSince1970 <= accountSnapshotFreshness
    }

    private static func accountQuotaRow(
        label: String,
        pct: Double,
        resetsAt: Int?,
        windowSeconds: Int,
        now: Int,
        longCountdown: Bool,
        rejected: Bool = false,
        projectRunOut: Bool = true
    ) -> Sessions.UsageQuotaRowDTO {
        let secondary: String
        let secondaryDimmed: Bool
        if let resetsAt, resetsAt > now {
            let remaining = resetsAt - now
            secondary = longCountdown
                ? formatCountdownDHM(seconds: remaining)
                : formatCountdownHM(seconds: remaining)
            secondaryDimmed = false
        } else {
            secondary = "—"
            secondaryDimmed = true
        }
        // Off for the two rows that are not windows, for two different reasons.
        // A spend limit's period length isn't in the payload (only when it next
        // resets), so there is no honest burn rate to project from — the caller
        // turns the run-out off rather than have it invent a window. A Fable
        // sub-limit has no honest one either — its percentage is a product of
        // two things that move independently — and would say nothing worth
        // warning about if it did: see `fableRow`.
        let runOut = projectRunOut ? resetsAt.flatMap {
            quotaRunOut(pct: pct, resetsAt: $0, windowSeconds: windowSeconds, now: now)
        } : nil
        // A rejected probe means the limiter is refusing this account's
        // requests right now — red regardless of the (untrustworthy) %.
        return Sessions.UsageQuotaRowDTO(
            label: label,
            pctText: String(format: "%.1f%%", pct),
            pctColor: rejected ? "red" : quotaColor(pct: pct),
            secondaryText: secondary,
            secondaryDimmed: secondaryDimmed,
            trailingText: runOut?.text ?? "",
            trailingColor: runOut?.color,
            // Raw reset instant so clients can render a live countdown instead of
            // the once-per-refresh `secondaryText` snapshot.
            resetsAt: resetsAt,
            // Raw pct so clients can order/threshold accounts without parsing
            // `pctText` back into a number.
            pct: pct,
            // And the projection's own span, for the same reason: a card shows
            // one run-out warning, the soonest, and picks it by this.
            runOutSeconds: runOut?.seconds,
            // And the window's WIDTH, which is what clients order the columns
            // by. `resetsAt` cannot do that job: the 7d reset falls sooner than
            // the 5h reset for most of every five-hour period, so an order
            // built from it swaps the two columns under the reader. A width
            // never changes. `0` is the spend row's "no period in the payload"
            // sentinel — the same one that turns its run-out off — and travels
            // as nil rather than as a zero-wide window.
            windowSeconds: windowSeconds > 0 ? windowSeconds : nil
        )
    }

    // MARK: - Quota run-out projection

    /// Projected time until a quota window hits 100% at its average burn rate
    /// so far: the window began at `resetsAt - windowSeconds`, so the rate is
    /// `pct / elapsed`, and run-out lands `(100 - pct) / rate` from now.
    /// Returns nil when there's nothing to project (no usage, stale reset) or
    /// when the projected run-out lands after the reset — the window resets
    /// before the quota can run out, so there is nothing to warn about.
    /// Red when exhaustion is (or projects) within the hour, else yellow.
    ///
    /// The span is returned alongside the words for it, so a client can rank
    /// two projections against each other (`Sessions.UsageQuotaRowDTO.runOutSeconds`)
    /// without reading `2d 6h` back out of the text. A window already at 100%
    /// is `0` — no time at all, which is both what "now" means and what puts it
    /// ahead of every other projection in that ranking.
    static func quotaRunOut(
        pct: Double,
        resetsAt: Int,
        windowSeconds: Int,
        now: Int
    ) -> (text: String, color: String?, seconds: Int)? {
        guard resetsAt > now, pct > 0 else { return nil }
        if pct >= 100 { return ("🛑 now", "red", 0) }
        let elapsed = Double(now - (resetsAt - windowSeconds))
        // The same gate the pace under the gauge waits behind: before it, one
        // prompt divided by a sliver of the window projects a run-out within
        // hours that the window's own pace line is not yet allowed to explain.
        guard elapsed > 0,
              elapsed >= Double(windowSeconds) * Sessions.UsageQuotaRowDTO.minimumProjectionElapsed
        else { return nil }
        let ratePerSecond = pct / elapsed
        // `pct > 0` is not the same guard as "the projection is a number". A
        // reading small enough against a long enough window (a millionth of a
        // percent into a 7d week is already there) divides to a rate near zero,
        // and `(100 - pct) / rate` comes back as a Double larger than `Int` can
        // hold — or as infinity outright. `Int(_:)` on either of those is a
        // TRAP, not a saturation, and this runs inside a launchd daemon: one
        // account reporting an implausibly tiny percentage would take the whole
        // daemon down and every client's readings with it. A projection that
        // does not fit is one that lands long after the reset, and that was
        // already nothing to warn about — so the reset is what bounds the
        // conversion, and the `now + runOutSeconds < resetsAt` test that used to
        // follow it is now the guard itself rather than a second reading of the
        // same fact. Which also means nothing here can overflow into that sum.
        let projected = (100.0 - pct) / ratePerSecond
        guard projected.isFinite, projected < Double(resetsAt - now) else { return nil }
        let runOutSeconds = Int(projected)
        let color = runOutSeconds < 3600 ? "red" : "yellow"
        return ("🛑 \(formatRunOut(seconds: runOutSeconds))", color, runOutSeconds)
    }

    /// `Nd Xh` / `Xh Ym` / `Ym` — like the reset countdowns but without the
    /// leading minus (this is a projection forward, not time remaining).
    private static func formatRunOut(seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        let days = totalMinutes / (60 * 24)
        let remainderMinutes = totalMinutes % (60 * 24)
        let hours = remainderMinutes / 60
        let minutes = remainderMinutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return String(format: "%dh %02dm", hours, minutes) }
        return "\(minutes)m"
    }

    // MARK: - HUD projection

    /// Reuses the same percentages and color thresholds as the quota rows so
    /// the HUD stays byte-equal to the Details window.
    ///
    /// The two reset instants ship as raw epochs rather than countdown text —
    /// the HUD ticks them itself once a second (see `Sessions.UsageHUDDTO`). Both are
    /// already validated as future-and-plausible by the caller
    /// (`resolveWeekStart` bounds the 7d reset; the 5h reset carries the same
    /// stale-snapshot recovery the `5h quota` row uses). A nil 7d reset is
    /// "genuinely unknown", which the HUD renders as `—`; a nil 5h reset means
    /// no 5h window is on record, and the whole 5h half goes nil with it.
    private static func buildHUD(
        weekPct: Double,
        weekResetsAt: Int?,
        fiveHourPct: Double,
        fiveHourResetsAt: Int?,
        accountEmail: String
    ) -> Sessions.UsageHUDDTO {
        Sessions.UsageHUDDTO(
            sevenDayPctText: String(format: "%.1f%%", weekPct),
            sevenDayPctColor: quotaColor(pct: weekPct),
            sevenDayResetsAt: weekResetsAt,
            // Nil together, and in exactly the case the `5h quota` row is left
            // out: no 5h window on record (see `buildQuotaRows`).
            fiveHourPctText: fiveHourResetsAt.map { _ in String(format: "%.1f%%", fiveHourPct) },
            fiveHourPctColor: fiveHourResetsAt.flatMap { _ in quotaColor(pct: fiveHourPct) },
            fiveHourResetsAt: fiveHourResetsAt,
            accountEmail: accountEmail
        )
    }

    // MARK: - Hours-comparison rows (active hours last week / this week)

    /// Port of CSL's `usage_hours.run`. Reuses `activeHours` (the burst
    /// walker over the event store's turns) to compute total active time in
    /// each window, then mirrors the Python's averaging:
    /// last week is divided by 7 calendar days; this week is divided by
    /// elapsed continuous days since the quota reset (so the "h/d"
    /// figure starts low and rises as the week progresses).
    func computeHoursComparisonRows(
        weekStart: Double,
        now: Date,
        nowIso: String,
        weekIso: String,
        source: UsageHistorySource
    ) throws -> [Sessions.UsageHoursRowDTO] {
        func hoursMetrics(
            since: String, until: String, account: String?
        ) throws -> (active: Double, wallClock: Double) {
            switch source {
            case .liveTurns: return try self.hoursMetrics(since: since, until: until, account: account)
            case .summary: return try usageSummaryHours(since: since, until: until)
            }
        }
        let lastStart = weekStart - 7.0 * 86400
        let prevStart = weekStart - 14.0 * 86400
        let lastIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: lastStart))
        let prevIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: prevStart))
        // Same-elapsed slice of LAST week: [lastStart, lastStart + elapsed) —
        // "where last week stood at this many hours in".
        let elapsedS = now.timeIntervalSince1970 - weekStart
        let lastPartialIso = Self.formatTimestamp(
            date: Date(timeIntervalSince1970: lastStart + elapsedS)
        )

        // account: nil — activity hours are counted across ALL accounts (overall
        // usage), not just the one logged in now. See computeUsageRows.
        let thisM = try hoursMetrics(since: weekIso, until: nowIso, account: nil)
        let lastM = try hoursMetrics(since: lastIso, until: weekIso, account: nil)
        // active == 0 ⟺ no bursts ⟺ wallClock == 0, so this gates both metrics.
        if thisM.active == 0 && lastM.active == 0 { return [] }
        let prevM = try hoursMetrics(since: prevIso, until: lastIso, account: nil)
        let lastPartialM = try hoursMetrics(since: lastIso, until: lastPartialIso, account: nil)

        // One row per week; every cell pairs the two metrics as "session / wall":
        //   hrs  = session-hours — each session's active time, parallel sessions
        //          SUMMED (can exceed 24h/day).
        //   wall = wall-clock — those bursts MERGED across sessions so overlapping
        //          work counts once (≤ 24h/day).
        // Averages divide this week by elapsed days, last week by 7 (this-week
        // divisor clamped to 1d so a tiny fraction doesn't inflate h/d early on).
        //
        // Deltas: a partial week vs a full prior week is meaningless until the
        // week's last minute, so
        //   - "last week"  Δ = last week vs the week BEFORE it (two full weeks);
        //   - "this week"  Δ = trend — this week so far vs last week AT THE SAME
        //     elapsed point (the lastPartial window above).
        let elapsedDays = elapsedS / 86400.0
        let thisDays = max(1.0, elapsedDays)
        let lastDays = 7.0

        return [
            Self.hoursRow(
                label: "hrs last week", weekLabel: "last week",
                session: Self.hoursMetric(
                    seconds: lastM.active, days: lastDays, prior: prevM.active
                ),
                wallClock: Self.hoursMetric(
                    seconds: lastM.wallClock, days: lastDays, prior: prevM.wallClock
                )
            ),
            Self.hoursRow(
                label: "hrs this week", weekLabel: "this week",
                session: Self.hoursMetric(
                    seconds: thisM.active, days: thisDays, prior: lastPartialM.active
                ),
                wallClock: Self.hoursMetric(
                    seconds: thisM.wallClock, days: thisDays, prior: lastPartialM.wallClock
                )
            )
        ]
    }

    /// One metric's three cells for one week, plus the `down` flag the combined
    /// delta needs to decide whether the two metrics agree.
    private struct HoursMetric {
        let dto: Sessions.UsageHoursMetricDTO
        /// nil when the prior window is empty: there is no comparison to make,
        /// which is not the same as "no change".
        let down: Bool?
    }

    /// Totals, per-day average, and change-vs-prior for one activity metric.
    /// The change is omitted when the prior window is 0 — a percentage against a
    /// zero baseline is infinite, not "+0%".
    private static func hoursMetric(
        seconds: Double, days: Double, prior: Double
    ) -> HoursMetric {
        let hours = seconds / 3600.0
        var deltaText = ""
        var deltaColor: String?
        var down: Bool?
        if prior > 0 {
            let pct = (seconds - prior) / prior * 100
            let fell = pct < 0
            deltaText = fell ? String(format: "%.0f%%", pct) : String(format: "+%.0f%%", pct)
            deltaColor = fell ? "green" : "orange"
            down = fell
        }
        return HoursMetric(
            dto: Sessions.UsageHoursMetricDTO(
                hoursText: String(format: "%.1fh", hours),
                avgText: String(format: "%.1fh/d", hours / days),
                deltaText: deltaText,
                deltaColor: deltaColor
            ),
            down: down
        )
    }

    /// One week's row: the split metrics, plus the composite `session / wall`
    /// cells JOINED from them — the status line's one-line form is a rendering of
    /// the same strings, never a second computation of the same numbers.
    ///
    /// The composite delta carries ONE color, since a single cell cannot honestly
    /// show two: green when both metrics fell, orange when both rose, and none
    /// when they disagree (rare — session and wall move together). A metric whose
    /// prior window was empty contributes no side at all.
    private static func hoursRow(
        label: String, weekLabel: String, session: HoursMetric, wallClock: HoursMetric
    ) -> Sessions.UsageHoursRowDTO {
        func joined(_ pick: (Sessions.UsageHoursMetricDTO) -> String) -> String {
            [pick(session.dto), pick(wallClock.dto)].joined(separator: " / ")
        }
        let deltas = [session, wallClock].filter { $0.down != nil }
        let deltaColor: String?
        switch (session.down, wallClock.down) {
        case let (sessionDown?, wallDown?):
            deltaColor = sessionDown == wallDown ? (sessionDown ? "green" : "orange") : nil
        default:
            deltaColor = deltas.first?.dto.deltaColor
        }
        return Sessions.UsageHoursRowDTO(
            label: label,
            hoursText: joined(\.hoursText),
            avgText: joined(\.avgText),
            deltaText: deltas.map(\.dto.deltaText).joined(separator: " / "),
            deltaColor: deltaColor,
            weekLabel: weekLabel,
            session: session.dto,
            wallClock: wallClock.dto
        )
    }

    // MARK: - Week-comparison rows (last week / this week tokens + cost)

    func computeWeekComparisonRows(
        weekStart: Double,
        now: Date,
        nowIso: String,
        weekIso: String,
        elapsedDays: Double,
        source: UsageHistorySource
    ) throws -> [Sessions.UsageWeekRowDTO] {
        let lastStart = weekStart - 7.0 * 86400
        let prevStart = weekStart - 14.0 * 86400
        let lastIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: lastStart))
        let prevIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: prevStart))
        // Same-elapsed slice of LAST week — "where last week stood at this many
        // hours in" — for the this-week trend delta.
        let lastPartialIso = Self.formatTimestamp(
            date: Date(timeIntervalSince1970: lastStart + elapsedDays * 86400)
        )

        // account: nil — the weekly token/cost comparison spans ALL accounts
        // (overall usage), unlike the account-scoped quota math. See computeUsageRows.
        func totals(since: String, until: String) throws -> (tokens: Int, cost: Double) {
            switch source {
            case .liveTurns:
                let agg = try turnAggregates(
                    since: since, until: until, groupBy: "all", account: nil, limit: 1
                ).first
                return (Self.sumTokens(agg), agg?.totalCostUsd ?? 0)
            case .summary:
                return try usageSummaryTotals(since: since, until: until)
            }
        }
        let this = try totals(since: weekIso, until: nowIso)
        let thisTokens = this.tokens
        // The three windows behind this week are history — each one walks a week
        // of turns, and re-walking them every recompute was most of its time.
        // Memoized; see `WeekScopedMemo`. Only this week's own total stays live.
        // The memo serves the production (summary) path only, so a caller
        // comparing the two paths never gets one's answer from the other.
        let computeBaselines = {
            let last = try totals(since: lastIso, until: weekIso)
            return WeekBaselines(
                lastTokens: last.tokens,
                lastCost: last.cost,
                prevTokens: try totals(since: prevIso, until: lastIso).tokens,
                lastPartialTokens: try totals(since: lastIso, until: lastPartialIso).tokens
            )
        }
        let past = source == .summary
            ? try weekBaselinesCache.rows(weekStart: weekStart, now: now, compute: computeBaselines)
            : try computeBaselines()
        let lastTokens = past.lastTokens
        if thisTokens == 0 && lastTokens == 0 { return [] }
        let prevTokens = past.prevTokens
        let lastPartialTokens = past.lastPartialTokens

        let thisCost = this.cost
        let lastCost = past.lastCost

        // Deltas: a partial week vs a full prior week is meaningless until the
        // week's last minute, so
        //   - "last week"  Δ = last week vs the week BEFORE it (two full weeks);
        //   - "this week"  Δ = trend — this week so far vs last week at the
        //     same elapsed point.
        var rows: [Sessions.UsageWeekRowDTO] = []
        let lastDelta = Self.tokenDelta(current: lastTokens, prior: prevTokens)
        rows.append(Sessions.UsageWeekRowDTO(
            label: "last week",
            tokensText: Self.formatTokens(lastTokens),
            costText: String(format: "$%.2f", lastCost),
            deltaText: lastDelta?.text ?? "",
            deltaColor: lastDelta?.color
        ))
        let trend = Self.tokenDelta(current: thisTokens, prior: lastPartialTokens)
        rows.append(Sessions.UsageWeekRowDTO(
            label: "this week",
            tokensText: Self.formatTokens(thisTokens),
            costText: String(format: "$%.2f", thisCost),
            deltaText: trend?.text ?? "",
            deltaColor: trend?.color
        ))
        return rows
    }

    /// `+N%` / `-N%` between two like-for-like token totals; nil when the
    /// prior baseline is 0. Green = down, orange = up (status-line palette).
    private static func tokenDelta(current: Int, prior: Int) -> (text: String, color: String)? {
        guard prior > 0 else { return nil }
        let pct = Double(current - prior) / Double(prior) * 100
        if pct < 0 { return (String(format: "%.0f%%", pct), "green") }
        return (String(format: "+%.0f%%", pct), "orange")
    }

    // MARK: - Quota row construction (label + pre-formatted display strings)

    private static func buildQuotaRows(
        todayTokens: Int,
        todayCostAllAccounts: Double,
        todayRemainingS: Int,
        weekPct: Double,
        weekRemainingS: Int,
        weekResetsAt: Int,
        fiveHourPct: Double,
        fiveHourRemainingS: Int?,
        fiveHourResetsAt: Int?,
        weekRunOut: (text: String, color: String?, seconds: Int)?,
        fiveHourRunOut: (text: String, color: String?, seconds: Int)?,
        spendSnapshot: Sessions.RateLimitSnapshotDTO?,
        fablePct: Double?,
        now: Int
    ) -> [Sessions.UsageQuotaRowDTO] {
        var rows: [Sessions.UsageQuotaRowDTO] = []

        // "today" is an overall-usage row: tokens + cost across ALL accounts
        // (mirroring the week rows' shape), with the quota-day rollover
        // countdown trailing. The cells ride the generic pct/secondary/trailing
        // slots — clients render them as opaque strings. The old per-account
        // quota % + daily-average trailing moved out (quota state is per-account
        // now).
        rows.append(Sessions.UsageQuotaRowDTO(
            label: "today",
            pctText: formatTokens(todayTokens),
            secondaryText: String(format: "$%.2f", todayCostAllAccounts),
            trailingText: formatCountdownHM(seconds: todayRemainingS)
        ))

        // Trailing is the 🛑 run-out projection (time until 100% at the current
        // burn rate) — replaced the old 👉🏻 projected-usage figure. Empty when
        // the window resets before the quota can run out.
        rows.append(Sessions.UsageQuotaRowDTO(
            label: "7d quota",
            pctText: String(format: "%.1f%%", weekPct),
            pctColor: quotaColor(pct: weekPct),
            secondaryText: formatCountdownDHM(seconds: weekRemainingS),
            trailingText: weekRunOut?.text ?? "",
            trailingColor: weekRunOut?.color,
            // `secondaryText` says "-2d 6h 12m", which a client can only act on
            // by parsing a display string — and this fallback path is exactly
            // the one an API-key user (no account sections at all) is served
            // on, so the machine-readable instant has to be here too or that
            // reader never gets one.
            resetsAt: weekResetsAt,
            // Same raw pct the per-account rows carry. Both builders emit this
            // DTO, so a client thresholding on `pct` must not have to know which
            // one produced the row — a nil here would be indistinguishable from
            // the old-daemon case the field's optionality is reserved for.
            pct: weekPct,
            runOutSeconds: weekRunOut?.seconds,
            // Same reason as `pct`: both builders emit this DTO and the client
            // orders the columns by width, so this path has to state it too.
            windowSeconds: 7 * 86400
        ))

        // Fable's slice of the week, after the week itself — matching the order
        // the card draws rather than dictating it (see `fableRow`). Always
        // present, and `—` when the week's Fable share is unknown: a confident
        // 0.0% over a window nothing was measured in is the more expensive
        // lie, and a row that comes and goes reshuffles the card.
        rows.append(fableRow(pct: fablePct, resetsAt: weekResetsAt, now: now))

        // The 5h row only when a 5h window is on record: a future reset instant,
        // from the snapshot or recovered from history. Anthropic removed the 5h
        // limit from some plans, and a plan without one reports no 5h window
        // ever — its snapshots store 0% with no reset — so drawing the row
        // there showed a gauge for a limit that does not exist. (A plan that
        // still has one and has no window open loses nothing: nothing is used
        // until one opens, and the row comes back with it.)
        if let remaining = fiveHourRemainingS, let resetsAt = fiveHourResetsAt {
            rows.append(Sessions.UsageQuotaRowDTO(
                label: Sessions.UsageQuotaRowDTO.fiveHourLabel,
                pctText: String(format: "%.1f%%", fiveHourPct),
                pctColor: quotaColor(pct: fiveHourPct),
                secondaryText: formatCountdownHM(seconds: remaining),
                trailingText: fiveHourRunOut?.text ?? "",
                trailingColor: fiveHourRunOut?.color,
                resetsAt: resetsAt,
                pct: fiveHourPct,
                runOutSeconds: fiveHourRunOut?.seconds,
                windowSeconds: 5 * 3600
            ))
        }

        if let spend = spendRow(snap: spendSnapshot, now: now) {
            rows.append(spend)
        }

        return rows
    }

    /// The spend-limit row for a snapshot, or nil when there is none to show.
    ///
    /// Both row builders come through here so they cannot drift apart again:
    /// the account sections applied `isSnapshotFresh` (a stale snapshot falls
    /// back to the probe there) while `buildQuotaRows` applied nothing, so the
    /// same account could show a day-old spend figure in one panel and none in
    /// the other. Freshness wins for spend specifically because it is the one
    /// reading with no second source — the token probe reports no spend window,
    /// so nothing corroborates or replaces a stale value.
    ///
    /// `spendResetsAt > 0` is the presence sentinel, so historical rows (and
    /// every install without a Claude-apps gateway) read as absent rather than
    /// as 0% spent — gating on the percentage would hide a genuine 0% spend.
    /// No run-out projection and no clamp: a spend limit's period length isn't
    /// in the payload, and `used_percentage` legitimately exceeds 100 once the
    /// limit is passed.
    static func spendRow(snap: Sessions.RateLimitSnapshotDTO?, now: Int) -> Sessions.UsageQuotaRowDTO? {
        guard let snap, snap.spendResetsAt > 0, isSnapshotFresh(snap, now: now) else {
            return nil
        }
        return accountQuotaRow(
            label: Sessions.UsageQuotaRowDTO.spendLabel,
            pct: snap.spendPct, resetsAt: snap.spendResetsAt,
            windowSeconds: 0, now: now, longCountdown: true,
            projectRunOut: false
        )
    }

    // MARK: - Shared helpers

    private static func quotaColor(pct: Double) -> String? {
        if pct >= 100.0 { return "red" }
        if pct >= 95.0 { return "yellow" }
        return nil
    }

    /// `-Xh Ym` when hours > 0, else `-Ym`. Matches Python `c7`/`c8` format.
    private static func formatCountdownHM(seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return String(format: "-%dh %02dm", hours, minutes)
        }
        return "-\(minutes)m"
    }

    /// `-Nd Xh Ym` when days > 0, `-Xh Ym` when hours > 0, else `-Ym`.
    /// Matches Python `c5` (7d countdown) format.
    private static func formatCountdownDHM(seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        let days = totalMinutes / (60 * 24)
        let remainderMinutes = totalMinutes % (60 * 24)
        let hours = remainderMinutes / 60
        let minutes = remainderMinutes % 60
        if days > 0 {
            return String(format: "-%dd %dh %02dm", days, hours, minutes)
        }
        if hours > 0 {
            return String(format: "-%dh %02dm", hours, minutes)
        }
        return "-\(minutes)m"
    }

    /// 1.2M / 45.3k / 123 — matches Python `format_tokens` exactly.
    private static func formatTokens(_ value: Int) -> String {
        let abs = Swift.abs(Double(value))
        if abs >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if abs >= 1_000 {
            return String(format: "%.1fk", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private static func sumTokens(_ row: Sessions.TurnAggregateDTO?) -> Int {
        guard let row else { return 0 }
        return row.inputTokens + row.outputTokens
            + row.cacheReadTokens + row.cacheCreationTokens
    }

    /// Anthropic reset is the authoritative week-start. Snapshot's
    /// `sevenDayResetsAt` must be in the future and within 7d + 1h skew.
    /// Returns the `weekStart` epoch seconds, or nil when no usable reset.
    private static func resolveWeekStart(
        snap: Sessions.RateLimitSnapshotDTO,
        nowTs: Double
    ) -> Double? {
        let nowInt = Int(nowTs)
        let maxReset = nowInt + 7 * 86400 + 3600
        let resets = snap.sevenDayResetsAt
        guard resets > nowInt && resets <= maxReset else { return nil }
        return Double(resets) - 7.0 * 86400
    }

    /// `ISO8601` with millisecond precision + Z suffix, as Python's
    /// `to_utc_iso` writes it. The usage readers take these bounds and turn
    /// them into the event store's epoch seconds (`DaemonDatabase.usageRange`);
    /// millisecond precision keeps that conversion exact.
    nonisolated(unsafe) private static let isoMilliFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func formatTimestamp(date: Date) -> String {
        isoMilliFormatter.string(from: date)
    }
}

/// Where the weekly and hours rows read their history.
enum UsageHistorySource: Sendable, Equatable {
    /// events.db turns for every window — the path before the usage summary,
    /// kept so its answers can be checked against the summary's.
    case liveTurns
    /// `session_summary` and `usage_bursts` through the summary watermark,
    /// live turns after it (see `usageWindowParts`). Production.
    case summary
}

extension DaemonDatabase {
    /// The weekly and hours rows for a quota week starting at `weekStart`, as
    /// `computeUsageRows` builds them at `now`, read from `source`.
    func usageHistoryRows(
        weekStart: Double, now: Date, source: UsageHistorySource
    ) throws -> (weekRows: [Sessions.UsageWeekRowDTO], hoursRows: [Sessions.UsageHoursRowDTO]) {
        let nowIso = Self.formatTimestamp(date: now)
        let weekIso = Self.formatTimestamp(date: Date(timeIntervalSince1970: weekStart))
        let elapsedDays = (now.timeIntervalSince1970 - weekStart) / 86400
        return (
            try computeWeekComparisonRows(
                weekStart: weekStart, now: now, nowIso: nowIso, weekIso: weekIso, elapsedDays: elapsedDays,
                source: source),
            try computeHoursComparisonRows(
                weekStart: weekStart, now: now, nowIso: nowIso, weekIso: weekIso, source: source)
        )
    }
}

/// A value derived from past weeks of turns, memoized across Usage recomputes.
///
/// A recompute runs every `usageCacheTTL` (15s) while anything renders the
/// status line. Two of its parts walk weeks of turns to print
/// figures that barely move: the activity-hours rows (four burst walks over
/// three weeks — 6.3 of 20 sampled seconds on a real install) and the
/// week-comparison baselines (last week, the week before, and last week's
/// same-elapsed slice — ~4.5 of 20 sampled seconds). Five minutes of staleness
/// moves no digit a reader acts on: hours print tenths, and the baselines are
/// closed windows, bar the same-elapsed slice, whose five minutes of drift is
/// noise against a week. A new quota week (`weekStart` changes) recomputes at
/// once, and so does a clock that went backwards.
///
/// One slot per `weekStart`, not one slot overall. `weekStart` comes from the
/// newest rate-limit snapshot, and with two accounts active on different
/// 7-day reset instants the newest row flips between them from one recompute
/// to the next. A single slot would miss on every flip and rerun the very
/// walks it exists to avoid. Slots expire with the TTL and there are at most
/// ``capacity`` of them, so a stream of new week starts cannot grow it.
///
/// The expiring, bounded, clock-step-guarded store is the toolkit's
/// `ExpiringMemo`; this keeps only the `weekStart` key and the 300 s policy.
final class WeekScopedMemo<Value: Sendable>: Sendable {
    static var ttl: TimeInterval { 300 }
    /// Week starts held at once — more accounts than anyone runs side by side.
    static var capacity: Int { 8 }

    private let memo = ExpiringMemo<Double, Value>(ttl: ttl, capacity: capacity)

    /// How many week starts are held now.
    var count: Int { memo.count }

    /// Computed outside the memo's lock: it reads SQLite, and recomputes are
    /// already single-flight through `usageRefreshInFlight`.
    func rows(
        weekStart: Double,
        now: Date,
        compute: () throws -> Value
    ) rethrows -> Value {
        try memo.value(for: weekStart, now: now, compute: compute)
    }
}

typealias HoursRowsCache = WeekScopedMemo<[Sessions.UsageHoursRowDTO]>

/// Last week's totals and the two baselines its deltas are measured against.
struct WeekBaselines: Sendable, Equatable {
    let lastTokens: Int
    let lastCost: Double
    let prevTokens: Int
    let lastPartialTokens: Int
}
#endif
