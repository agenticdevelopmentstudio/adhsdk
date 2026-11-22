import Foundation

extension Sessions {

    /// Wire types for the stenographer status-line endpoints introduced in
    /// Phase 4 of the consolidate-stenographer-status-line plan. Snake-case JSON on
    /// the wire; camelCase Swift on this side.

    /// One row of a `/turns` aggregation. `groupKey` is whatever the caller
    /// grouped by — model name, session id, or `"all"` when no grouping was
    /// requested. Token columns are pure sums over the matched turns; cost
    /// is computed server-side from stenographer's pricing table.
    public struct TurnAggregateDTO: Codable, Sendable {
        public let groupKey: String
        public let turnCount: Int
        public let inputTokens: Int
        public let outputTokens: Int
        public let cacheReadTokens: Int
        public let cacheCreationTokens: Int
        public let totalCostUsd: Double

        public init(
            groupKey: String,
            turnCount: Int,
            inputTokens: Int,
            outputTokens: Int,
            cacheReadTokens: Int,
            cacheCreationTokens: Int,
            totalCostUsd: Double
        ) {
            self.groupKey = groupKey
            self.turnCount = turnCount
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.cacheReadTokens = cacheReadTokens
            self.cacheCreationTokens = cacheCreationTokens
            self.totalCostUsd = totalCostUsd
        }
    }

    /// Reply for `/insights/active-hours`. Server-side port of CSL's
    /// `usage_hours.py:_active_seconds`: scans transcript_turns ordered by
    /// (session_id, timestamp), sums the spans of contiguous bursts whose
    /// inter-turn gaps stay below `idleThresholdS`.
    public struct ActiveHoursDTO: Codable, Sendable {
        public let since: String
        public let until: String
        public let idleThresholdS: Int
        public let activeSeconds: Double
        public let turnCount: Int

        public init(
            since: String,
            until: String,
            idleThresholdS: Int,
            activeSeconds: Double,
            turnCount: Int
        ) {
            self.since = since
            self.until = until
            self.idleThresholdS = idleThresholdS
            self.activeSeconds = activeSeconds
            self.turnCount = turnCount
        }
    }

    /// One row from `rate_limit_snapshots`. CSL's renderer treats every field
    /// optional except the quota percentages, so we serialize every column —
    /// missing values become 0 / "" — and let the client decide what to show.
    public struct RateLimitSnapshotDTO: Codable, Sendable {
        public let id: Int64
        public let timestamp: String
        public let sessionId: String
        public let weekStart: String
        public let elapsedHours: Int
        public let elapsedDay: Double
        public let weeklyPct: Double
        public let dailyAvgPct: Double
        public let fiveHourPct: Double
        public let fiveHourResetsAt: Int
        public let sevenDayResetsAt: Int
        public let projectedPct: Double
        public let accountEmail: String
        /// `rate_limits.spend_limit.used_percentage`. Runs 0-100 and above 100 once
        /// the limit is exceeded, so consumers must not clamp it.
        public let spendPct: Double
        /// `rate_limits.spend_limit.resets_at`, epoch seconds — and the presence
        /// sentinel for the whole window. `0` means no gateway ever reported a spend
        /// limit for this row (including every row predating the column), which is
        /// what distinguishes "absent" from a real `spendPct` of 0.
        public let spendResetsAt: Int

        public init(
            id: Int64,
            timestamp: String,
            sessionId: String,
            weekStart: String,
            elapsedHours: Int,
            elapsedDay: Double,
            weeklyPct: Double,
            dailyAvgPct: Double,
            fiveHourPct: Double,
            fiveHourResetsAt: Int,
            sevenDayResetsAt: Int,
            projectedPct: Double,
            accountEmail: String = "",
            spendPct: Double = 0,
            spendResetsAt: Int = 0
        ) {
            self.id = id
            self.timestamp = timestamp
            self.sessionId = sessionId
            self.weekStart = weekStart
            self.elapsedHours = elapsedHours
            self.elapsedDay = elapsedDay
            self.weeklyPct = weeklyPct
            self.dailyAvgPct = dailyAvgPct
            self.fiveHourPct = fiveHourPct
            self.fiveHourResetsAt = fiveHourResetsAt
            self.sevenDayResetsAt = sevenDayResetsAt
            self.projectedPct = projectedPct
            self.accountEmail = accountEmail
            self.spendPct = spendPct
            self.spendResetsAt = spendResetsAt
        }

        private enum CodingKeys: String, CodingKey {
            case id, timestamp, sessionId, weekStart, elapsedHours, elapsedDay,
                 weeklyPct, dailyAvgPct, fiveHourPct, fiveHourResetsAt,
                 sevenDayResetsAt, projectedPct, accountEmail, spendPct,
                 spendResetsAt
        }

        /// Custom decode so a payload missing `account_email` or the spend-limit
        /// pair (older callers, rows captured before those columns existed) falls
        /// back to `""` / `0` instead of throwing `keyNotFound` — mirrors
        /// `UsageRowsDTO`'s forward-compat pattern in this file. `./install` swaps
        /// the daemon while an older menu-bar app may still be running against it,
        /// so a newly-added key must never be required.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int64.self, forKey: .id)
            timestamp = try container.decode(String.self, forKey: .timestamp)
            sessionId = try container.decode(String.self, forKey: .sessionId)
            weekStart = try container.decode(String.self, forKey: .weekStart)
            elapsedHours = try container.decode(Int.self, forKey: .elapsedHours)
            elapsedDay = try container.decode(Double.self, forKey: .elapsedDay)
            weeklyPct = try container.decode(Double.self, forKey: .weeklyPct)
            dailyAvgPct = try container.decode(Double.self, forKey: .dailyAvgPct)
            fiveHourPct = try container.decode(Double.self, forKey: .fiveHourPct)
            fiveHourResetsAt = try container.decode(Int.self, forKey: .fiveHourResetsAt)
            sevenDayResetsAt = try container.decode(Int.self, forKey: .sevenDayResetsAt)
            projectedPct = try container.decode(Double.self, forKey: .projectedPct)
            accountEmail = try container.decodeIfPresent(String.self, forKey: .accountEmail) ?? ""
            spendPct = try container.decodeIfPresent(Double.self, forKey: .spendPct) ?? 0
            spendResetsAt = try container.decodeIfPresent(Int.self, forKey: .spendResetsAt) ?? 0
        }
    }

    /// One row of `/claude-versions`. `fieldsJson` is the first-seen payload
    /// blob; `fieldPaths` is the merged set of dotted paths observed across
    /// every capture of this version (matches CSL's `db._parse_version_row`).
    public struct ClaudeVersionDTO: Codable, Sendable {
        public let claudeVersion: String
        public let fieldsJson: String
        public let fieldsCount: Int
        public let firstSeen: String
        public let fieldPaths: [String]

        public init(
            claudeVersion: String,
            fieldsJson: String,
            fieldsCount: Int,
            firstSeen: String,
            fieldPaths: [String]
        ) {
            self.claudeVersion = claudeVersion
            self.fieldsJson = fieldsJson
            self.fieldsCount = fieldsCount
            self.firstSeen = firstSeen
            self.fieldPaths = fieldPaths
        }
    }

    /// Reply for `GET /insights/usage-rows`. The daemon computes every display
    /// string here so the Python status line and the Swift menu-bar Usage
    /// window render byte-identical output — they only apply color/dim styling
    /// on top of the strings the server provides.
    ///
    /// `available` is false when the daemon has no rate-limit snapshots yet
    /// (fresh install, no StatusLine events ingested) — clients should show a
    /// "no data yet" state. `weekRows` is empty when both windows have zero
    /// turns; otherwise it has one or two entries (last-week may be absent on
    /// a brand-new install).
    public struct UsageRowsDTO: Codable, Sendable {
        public let available: Bool
        public let quotaRows: [UsageQuotaRowDTO]
        public let weekRows: [UsageWeekRowDTO]
        public let hoursRows: [UsageHoursRowDTO]
        /// The HUD payload. Deliberately NOT named `hud` on the wire: it replaced a
        /// same-named payload of a different shape (today / weekly / projection), and
        /// `./install` swaps the daemon while leaving the previous menu-bar app
        /// running until it is relaunched. That app's synthesized `UsageHUDDTO`
        /// decoder REQUIRES the retired keys, so a present-but-changed `hud` would
        /// throw `keyNotFound` out of the enclosing `decodeIfPresent` and blank its
        /// ENTIRE Usage window (the failure `UsageAccountSectionDTO.isCurrent`
        /// documents). An ABSENT key decodes to nil, which every shipped client
        /// already degrades to `—` for — so a new key buys graceful skew for free.
        public let hudQuota: UsageHUDDTO?
        /// Per-account quota sections (7d/5h per saved credential), probed live from
        /// Anthropic's rate-limit headers by the app, which owns the Keychain items
        /// the tokens live in. Empty when nothing is saved or no probe has finished.
        public let accountSections: [UsageAccountSectionDTO]
        /// The oauth (Keychain) account email from `~/.claude.json`, resolved once
        /// by the daemon's mtime-cached `AccountResolver`. Shipped so the Python
        /// status-line renderer can badge the oauth account (🌐) without re-parsing
        /// the (large, frequently-rewritten) `~/.claude.json` on every render.
        /// `""` when unknown / API-key user.
        public let oauthEmail: String

        public init(
            available: Bool,
            quotaRows: [UsageQuotaRowDTO],
            weekRows: [UsageWeekRowDTO],
            hoursRows: [UsageHoursRowDTO] = [],
            hudQuota: UsageHUDDTO? = nil,
            accountSections: [UsageAccountSectionDTO] = [],
            oauthEmail: String = ""
        ) {
            self.available = available
            self.quotaRows = quotaRows
            self.weekRows = weekRows
            self.hoursRows = hoursRows
            self.hudQuota = hudQuota
            self.accountSections = accountSections
            self.oauthEmail = oauthEmail
        }

        private enum CodingKeys: String, CodingKey {
            case available, quotaRows, weekRows, hoursRows, hudQuota, accountSections, oauthEmail
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.available = try container.decode(Bool.self, forKey: .available)
            self.quotaRows = try container.decode([UsageQuotaRowDTO].self, forKey: .quotaRows)
            self.weekRows = try container.decode([UsageWeekRowDTO].self, forKey: .weekRows)
            self.hoursRows = try container.decodeIfPresent([UsageHoursRowDTO].self, forKey: .hoursRows) ?? []
            self.hudQuota = try container.decodeIfPresent(UsageHUDDTO.self, forKey: .hudQuota)
            self.accountSections = try container.decodeIfPresent(
                [UsageAccountSectionDTO].self, forKey: .accountSections
            ) ?? []
            self.oauthEmail = try container.decodeIfPresent(String.self, forKey: .oauthEmail) ?? ""
        }
    }

    /// One of the app's saved credentials, handed to the daemon so it can judge and
    /// measure that account.
    ///
    /// **This is the one DTO that carries a secret.** The keychain items belong to
    /// the menu-bar app: macOS names the *requesting process* in the permission
    /// dialog it raises for them, and only a process with a UI can answer one, so
    /// custody cannot move to a launchd job. Everything else about a credential —
    /// is this access token still worth sending, does it need refreshing, what did
    /// the refresh say, what quota is left — belongs in the daemon, where every
    /// consumer of the answer already lives, and where the CLI can reach it.
    ///
    /// So the app reads its items and pushes the **whole** login in, refresh token
    /// included; the daemon decides, refreshes what needs it, probes with the
    /// result, and hands any rotation straight back in the reply for the app to
    /// store — see ``ClaudeCredentialEvaluationDTO``. The daemon keeps all of it in
    /// memory and exposes no way to read a token back: the shared XPC listener
    /// accepts any peer that asks, so a getter would hand these to anything on the
    /// machine. The one thing that ever leaves is a rotation, and it leaves down the
    /// same connection that supplied the secret in the first place.
    ///
    /// Lives beside ``ClaudeCredentialKind`` because it is the same fact one layer
    /// down: which credential, for which account, and the token that proves it.
    public struct ClaudeCredentialDTO: Codable, Sendable {
        /// The account name (an email) this credential logs in as.
        public let account: String
        /// Which kind of credential this is, as ``ClaudeCredentialKind``'s raw value.
        /// Carried through to the reading, because a setup token and the same email's
        /// login bill against different buckets and may never be drawn as each other.
        public let credentialKind: String?
        /// The bearer token to probe with — an OAuth access token, or a
        /// `claude setup-token` token.
        public let token: String
        /// The keychain item this came out of, which is the address a rotation has to
        /// be written back to. Normally `"<kind>:<account>"`, but a legacy item the
        /// app couldn't migrate is still addressed by its bare account name, so it is
        /// carried rather than re-derived. Optional: a client older than this field
        /// sends nothing, and nothing it sends can be rotated.
        public let itemKey: String?
        /// The whole login, for a `.oauth` credential — the daemon reads the expiry
        /// off it and spends the refresh token when it has to. `nil` for a long-lived
        /// setup token, which never expires and never rotates, and for any credential
        /// the app is only offering to have probed.
        public let oauth: ClaudeOAuthCredential?
        /// Seconds of life below which this login's access token counts as expired
        /// for this one evaluation, so it is refreshed now rather than at the usual
        /// five-minute margin. Set only when a token is about to be handed to a
        /// terminal (`steno claude use`), which has no way to refresh it later; nil
        /// everywhere else. Never kept — ``probeOnly`` and ``carrying(_:)`` drop it.
        public let refreshWithin: Double?

        public init(
            account: String, credentialKind: String? = nil, token: String,
            itemKey: String? = nil, oauth: ClaudeOAuthCredential? = nil,
            refreshWithin: Double? = nil
        ) {
            self.account = account
            self.credentialKind = credentialKind
            self.token = token
            self.itemKey = itemKey
            self.oauth = oauth
            self.refreshWithin = refreshWithin
        }

        /// The same credential carrying a rotated login — what the daemon probes with
        /// after a refresh, and what it compares against the set it already held.
        public func carrying(_ rotated: ClaudeOAuthCredential) -> ClaudeCredentialDTO {
            ClaudeCredentialDTO(
                account: account, credentialKind: credentialKind, token: rotated.accessToken,
                itemKey: itemKey, oauth: rotated)
        }

        /// The same credential with the login dropped — everything a probe needs and
        /// nothing else.
        ///
        /// This is what the daemon *keeps*. A refresh token is the credential that
        /// can mint more credentials, so it is worth holding for exactly as long as
        /// the evaluation that might spend it and not one moment longer: after that
        /// call returns, what stays in the store is a bearer token good for eight
        /// hours, which is what the daemon held before any of this existed.
        public var probeOnly: ClaudeCredentialDTO {
            ClaudeCredentialDTO(
                account: account, credentialKind: credentialKind, token: token, itemKey: itemKey)
        }
    }

    /// One saved account's quota section: the account name (email) as the header
    /// plus its `7d quota` / `5h quota` rows, pre-formatted like `quotaRows`.
    /// `errorText` is set (and `rows` empty) when the probe for this account
    /// failed — e.g. an expired token.
    ///
    /// The current-account badge (👈🏻) is now computed client-side by the Python
    /// renderer, so `isCurrent` is unused by current clients. It is nonetheless
    /// still ENCODED (always `false`) for wire backward-compatibility: an app
    /// build ≤2.28.x has a synthesized decoder that REQUIRES the key and throws
    /// `keyNotFound` if it is absent — and `./install` replaces the daemon while
    /// leaving the old menu-bar app running until it is relaunched. Deleting the
    /// key outright blanked that app's Usage window during the skew window; keep
    /// emitting it until every shipped client tolerates its absence, then remove.
    public struct UsageAccountSectionDTO: Codable, Sendable {
        public let accountEmail: String
        /// Which credential these numbers were measured with, as
        /// `ClaudeCredentialKind`'s raw value; nil from a daemon that predates the
        /// per-credential split.
        ///
        /// A raw string rather than the enum: a kind this build has never heard of
        /// must degrade to one unlabeled section, not throw the whole payload on
        /// the floor during a version skew.
        public let credentialKind: String?
        public let rows: [UsageQuotaRowDTO]
        public let errorText: String?
        /// Deprecated: always `false`. Kept on the wire for backward-compat (see
        /// the type doc); the badge is computed client-side.
        public let isCurrent: Bool

        public init(
            accountEmail: String,
            credentialKind: String? = nil,
            rows: [UsageQuotaRowDTO],
            errorText: String? = nil
        ) {
            self.accountEmail = accountEmail
            self.credentialKind = credentialKind
            self.rows = rows
            self.errorText = errorText
            self.isCurrent = false
        }

        /// This section's own identity — what a per-credential preference is keyed
        /// by, and what tells two sections for one email apart. Built the same way
        /// as the keychain item's name, so the app's checkbox and this card agree.
        public var identity: String {
            ClaudeCredentialKind.key(account: accountEmail, kindRawValue: credentialKind)
        }

        /// True when these numbers were measured with the account's LOGIN rather
        /// than with a `claude setup-token` token.
        ///
        /// The unlabeled section a daemon predating the split sends counts as one:
        /// it is the only section its address has, so there is nothing for it to
        /// lose a tie against.
        private var isLogin: Bool {
            credentialKind != ClaudeCredentialKind.longLived.rawValue
        }

        /// One section per address, for a surface that displays USAGE.
        ///
        /// An address can have both a login and a `claude setup-token` token saved,
        /// and the daemon reports the two separately because they meter separately.
        /// That is the right answer for the Claude Authentication panel, which is a
        /// list OF credentials. It is the wrong answer for a usage display, which
        /// is a list of accounts: one address drew two cards carrying the same name
        /// and two different percentages, leaving no way to tell which of them the
        /// next session would actually spend.
        ///
        /// The login wins, because it is the credential Claude Code runs as and so
        /// the bucket a session about to start draws down. An address with only a
        /// token keeps that token's reading — the alternative is an account the
        /// display does not mention at all.
        ///
        /// Addresses keep the order they first arrive in, so de-duplicating cannot
        /// reshuffle a list against the one the daemon sent; callers sort after.
        public static func oneSectionPerAccount(
            _ sections: [UsageAccountSectionDTO]
        ) -> [UsageAccountSectionDTO] {
            var chosen: [String: UsageAccountSectionDTO] = [:]
            var order: [String] = []
            for section in sections {
                let key = section.accountEmail.trimmingCharacters(in: .whitespaces).lowercased()
                guard let existing = chosen[key] else {
                    chosen[key] = section
                    order.append(key)
                    continue
                }
                if section.isLogin, !existing.isLogin { chosen[key] = section }
            }
            return order.compactMap { chosen[$0] }
        }
    }

    /// One saved account's live quota reading, as the daemon measured it.
    ///
    /// The daemon probes, with credentials the app pushed in as
    /// ``ClaudeCredentialDTO``; it is the side every consumer of the answer already
    /// reads from — the status line, the widget, the HTTP API — and the app is a
    /// viewer that only hands over what it has custody of.
    ///
    /// Percentages are normalized to 0-100. `errorText` is set (and the quota fields
    /// nil) when the probe for that account failed.
    public struct AccountQuotaReadingDTO: Codable, Sendable {
        public let account: String
        /// Which of the account's credentials this reading measured, as
        /// `ClaudeCredentialKind`'s raw value.
        ///
        /// It is on the wire because the bucket it names is not the account's: a
        /// setup token and the same email's login are metered separately, so two
        /// readings for one address are two different measurements and neither one
        /// may be drawn as the other.
        public let credentialKind: String?
        public let fiveHourPct: Double?
        public let fiveHourResetsAt: Int?
        public let fiveHourStatus: String?
        public let sevenDayPct: Double?
        public let sevenDayResetsAt: Int?
        public let sevenDayStatus: String?
        /// Anthropic's own Fable bucket — the `7d_oi` window
        /// (`seven_day_overage_included`), which Claude Code labels "Fable limit" —
        /// as a percentage (0-100) of what the tier may spend, normalized like the
        /// utilizations beside it.
        ///
        /// Claude Code describes it as a per-model bucket "present only for
        /// accounts whose responses carry that window", and none of the accounts
        /// probed so far do: every one of them answers without it. So this is `nil`
        /// almost always, and the Fable row falls back to stenographer's own
        /// estimate (`DatabaseManager.fablePct`); when a response does carry it,
        /// the gateway's number is the answer and no estimate is made.
        ///
        /// (`fallback-percentage`, which every probe DOES carry, is not this. It is
        /// the model-fallback threshold — it read 0.2 in the wild before Fable
        /// existed, and Claude Code never reads it.)
        public let fableLimitPct: Double?
        /// When the `7d_oi` window resets (unix seconds), or nil with it.
        public let fableLimitResetsAt: Int?
        /// The `7d_oi` window's status — `rejected` once Fable is refused.
        public let fableLimitStatus: String?
        public let errorText: String?

        public init(
            account: String,
            credentialKind: String? = nil,
            fiveHourPct: Double? = nil,
            fiveHourResetsAt: Int? = nil,
            fiveHourStatus: String? = nil,
            sevenDayPct: Double? = nil,
            sevenDayResetsAt: Int? = nil,
            sevenDayStatus: String? = nil,
            fableLimitPct: Double? = nil,
            fableLimitResetsAt: Int? = nil,
            fableLimitStatus: String? = nil,
            errorText: String? = nil
        ) {
            self.account = account
            self.credentialKind = credentialKind
            self.fiveHourPct = Self.finite(fiveHourPct)
            self.fiveHourResetsAt = fiveHourResetsAt
            self.fiveHourStatus = fiveHourStatus
            self.sevenDayPct = Self.finite(sevenDayPct)
            self.sevenDayResetsAt = sevenDayResetsAt
            self.sevenDayStatus = sevenDayStatus
            self.fableLimitPct = Self.finite(fableLimitPct)
            self.fableLimitResetsAt = fableLimitResetsAt
            self.fableLimitStatus = fableLimitStatus
            self.errorText = errorText
        }

        /// `value` when it is a finite number, else nil. A percentage that is NaN
        /// or infinite is never stored, so it never reaches JSON or the UI.
        static func finite(_ value: Double?) -> Double? {
            guard let value, value.isFinite else { return nil }
            return value
        }

        /// Reads one probe's `anthropic-ratelimit-unified-*` response headers (keys
        /// lowercased).
        ///
        /// Utilization is a 0-1 fraction that can exceed 1.0 once an account is over
        /// quota (verified: header 0.27 == 27%; an over-quota account sends e.g.
        /// 1.05 == 105%), so always multiply by 100. The old
        /// `value <= 1 ? value * 100 : value` heuristic hit the `else` branch for
        /// over-quota fractions and silently truncated them (1.05 rendered "1.0%").
        ///
        /// Lives here, on the type both sides share, because the reading is the wire
        /// shape: the daemon builds it straight off the response it probed for, and
        /// the app decodes the same struct to draw it.
        public init(account: String, credentialKind: String? = nil, headers: [String: String]) {
            func pct(_ prefix: String) -> Double? {
                guard let raw = headers["anthropic-ratelimit-unified-\(prefix)-utilization"],
                      let value = Double(raw) else { return nil }
                // `nan`, `inf` and a value whose percentage overflows parse as
                // Doubles but are no reading at all: the wire coder cannot
                // encode them, and nothing can draw them.
                return Self.finite(value * 100)
            }
            func reset(_ prefix: String) -> Int? {
                guard let raw = headers["anthropic-ratelimit-unified-\(prefix)-reset"],
                      let value = Double(raw) else { return nil }
                // Millisecond epochs (>1e12) normalize to seconds. `inf`, `nan` and
                // out-of-range values parse as Doubles but would trap in `Int(_:)`;
                // they are no reading at all.
                let seconds = (value > 1e12 ? value / 1000 : value).rounded(.towardZero)
                return Int(exactly: seconds)
            }
            self.account = account
            self.credentialKind = credentialKind
            self.fiveHourPct = pct("5h")
            self.fiveHourResetsAt = reset("5h")
            self.fiveHourStatus = headers["anthropic-ratelimit-unified-5h-status"]
            self.sevenDayPct = pct("7d")
            self.sevenDayResetsAt = reset("7d")
            self.sevenDayStatus = headers["anthropic-ratelimit-unified-7d-status"]
            self.fableLimitPct = pct("7d_oi")
            self.fableLimitResetsAt = reset("7d_oi")
            self.fableLimitStatus = headers["anthropic-ratelimit-unified-7d_oi-status"]
            // Neither window answered: the call came back, and told us nothing. That
            // is a failed reading, not a reading of zero.
            self.errorText = (pct("5h") == nil && pct("7d") == nil)
                ? "no usage readings in response" : nil
        }
    }

    /// HUD-shaped projection of the same numbers `quotaRows` carries — the daemon
    /// ships exactly what the borderless one-line HUD renders, so the HUD needs no
    /// string parsing or threshold logic of its own:
    ///
    ///     [logo] │ 7d: 48.0% 2:14:35:09 │ 5h: 91.0% 3:47:12 │ me@example.com │ ⚙
    ///
    /// The percentages arrive pre-formatted (same strings and color thresholds as
    /// the Details window's quota rows). The reset instants are the one thing that
    /// deliberately does NOT arrive as text: the HUD re-derives both countdowns
    /// every second, and a once-per-refresh string would visibly stall between the
    /// model's 30s polls. Each is nil when the daemon has no trustworthy reset
    /// instant (stale/absent snapshot) — the HUD then shows `—` for that countdown.
    ///
    /// The 5h half is optional as a whole: `fiveHourPctText` is nil when the
    /// account has no five-hour window on record. Anthropic removed the 5h limit
    /// from some plans, and a plan without one reports no `5h` reading at all, so
    /// the HUD drops the 5h strip rather than drawing a 0% gauge for a limit that
    /// does not exist.
    public struct UsageHUDDTO: Codable, Sendable {
        public let sevenDayPctText: String
        public let sevenDayPctColor: String?
        /// Unix epoch seconds when the 7d window resets.
        public let sevenDayResetsAt: Int?
        /// Nil when there is no 5h window — see the type's doc.
        public let fiveHourPctText: String?
        public let fiveHourPctColor: String?
        /// Unix epoch seconds when the 5h window resets.
        public let fiveHourResetsAt: Int?
        /// The account these percentages are scoped to (same value as
        /// `UsageRowsDTO.oauthEmail`), carried here so the HUD renders one payload
        /// rather than stitching two. `""` when unknown / API-key user.
        public let accountEmail: String

        public init(
            sevenDayPctText: String,
            sevenDayPctColor: String? = nil,
            sevenDayResetsAt: Int? = nil,
            fiveHourPctText: String?,
            fiveHourPctColor: String? = nil,
            fiveHourResetsAt: Int? = nil,
            accountEmail: String = ""
        ) {
            self.sevenDayPctText = sevenDayPctText
            self.sevenDayPctColor = sevenDayPctColor
            self.sevenDayResetsAt = sevenDayResetsAt
            self.fiveHourPctText = fiveHourPctText
            self.fiveHourPctColor = fiveHourPctColor
            self.fiveHourResetsAt = fiveHourResetsAt
            self.accountEmail = accountEmail
        }
    }

    /// A single quota-row in the rendered table: `today`, `7d quota`,
    /// `fable quota`, `5h quota`, `spend`. All cells arrive pre-formatted from the
    /// daemon. Color/dim hints let clients style with terminal ANSI (Python) or
    /// NSColor (Swift) without re-running the threshold logic.
    public struct UsageQuotaRowDTO: Codable, Sendable {
        /// The `label` of the Fable sub-limit row.
        ///
        /// Fable may consume at most HALF the 7d window, so this row is a share of
        /// a share: the part of the weekly quota Fable has spent, measured against
        /// the fifty points it is allowed rather than against the hundred the
        /// window has. It resets when the 7d window does, and it is derived from
        /// stenographer's own per-model transcript costs — Anthropic reports no
        /// per-model rate-limit field, so no snapshot carries it.
        ///
        /// Named for the same reason `spendLabel` is: it is a *different kind* of
        /// row from the windows beside it, anything that reads a row's `pct` as
        /// window consumption has to be able to tell it apart, and the label is the
        /// only marker on the wire.
        public static let fableLabel = "fable quota"

        /// The share of a window that must have elapsed before anything is
        /// projected from its pace: the burn rate drawn under a gauge, and the
        /// daemon's run-out projection. 1% — 1h 41m into a 7d week, 3 min into a
        /// 5h window. One value on the wire's shared layer, so the pace and the
        /// projection it explains switch on at the same moment: a run-out shown
        /// with no pace beside it is a warning the reader cannot check.
        public static let minimumProjectionElapsed = 0.01

        /// The `label` of a spend-limit row.
        ///
        /// A spend row is a *different kind* of row from the quota gauges beside
        /// it: its percentage is a share of a dollar cap, not of a rate-limit
        /// window, and it may legitimately exceed 100. Anything that treats a row's
        /// `pct` as quota consumption — sorting spent accounts down, picking the
        /// soonest reset, filling a gauge — has to be able to tell it apart, and
        /// the label is the only marker on the wire. Named here rather than spelled
        /// as a literal at each site so producer and consumers share one spelling.
        public static let spendLabel = "spend"

        /// The `label` of the weekly rate-limit window, and how wide it is.
        ///
        /// Named for a third reason the two labels above are: a client orders the
        /// windows by width, and a row from a daemon too old to send
        /// `windowSeconds` still has to land in the right place. The label is the
        /// only other thing on the wire that says which window a row is, so it is
        /// the fallback — and a fallback keyed on a spelling only works while
        /// producer and consumer share one, which is what these are for.
        public static let sevenDayLabel = "7d quota"
        /// Seconds in the `sevenDayLabel` window.
        public static let sevenDayWindowSeconds = 7 * 86_400

        /// The `label` of the five-hour rate-limit window. See `sevenDayLabel`.
        public static let fiveHourLabel = "5h quota"
        /// Seconds in the `fiveHourLabel` window.
        public static let fiveHourWindowSeconds = 5 * 3_600

        /// How wide this row's window is, falling back to the label when the daemon
        /// that sent the row predates `windowSeconds`.
        ///
        /// Nil for a row that is not a rate-limit window — `spend`, whose period
        /// length Anthropic does not report, and `today`, which is not a window at
        /// all. A sub-limit is deliberately NOT resolved here: it carries its
        /// parent's width and what a caller wants to know about it differs by
        /// caller, so each one answers that for itself.
        public var resolvedWindowSeconds: Int? {
            if let windowSeconds { return windowSeconds }
            switch label {
            case Self.sevenDayLabel: return Self.sevenDayWindowSeconds
            case Self.fiveHourLabel: return Self.fiveHourWindowSeconds
            default: return nil
            }
        }

        public let label: String
        public let pctText: String
        public let pctColor: String?            // "red" | "yellow" | nil
        public let secondaryText: String
        public let secondaryDimmed: Bool
        public let trailingText: String
        public let trailingColor: String?       // "red" | nil
        public let trailingDimmed: Bool
        /// Unix epoch seconds when this window resets, when known. `secondaryText`
        /// is the daemon's snapshot of the countdown to this instant; a client that
        /// wants a live per-second countdown recomputes from here. Optional so old
        /// daemons (which never sent it) decode as nil and clients fall back to
        /// `secondaryText`.
        public let resetsAt: Int?
        /// Raw percentage of the window consumed, when known — the same number
        /// `pctText` formats. Shipped so clients can ORDER and THRESHOLD accounts
        /// (the Usage Details window sorts spent accounts to the bottom) without
        /// parsing a display string back into a number. Optional for the same
        /// reason as `resetsAt`: old daemons never sent it, so it decodes as nil.
        public let pct: Double?
        /// How far off the projected run-out is, in seconds — the same span
        /// `trailingText` writes as `2d 6h`, and `0` once the window is spent.
        ///
        /// Shipped for the same reason `pct` is: a client that has to pick the
        /// window running out SOONEST — both surfaces warn about one window rather
        /// than stacking a line per window — can only do it from a number, and the
        /// alternative is parsing `2d 6h` back into one. Nil whenever
        /// `trailingText` is empty (there is no projection to rank) and, as with
        /// every field below the original wire format, whenever an older daemon
        /// sent the row.
        public let runOutSeconds: Int?
        /// How WIDE this row's window is, in seconds — 5h is `18_000`, 7d is
        /// `604_800` — as opposed to `resetsAt`, which says when the current one
        /// ends.
        ///
        /// Shipped because it is the only stable way to ORDER the windows. The
        /// obvious alternative, ordering by `resetsAt`, reorders itself: the 7d
        /// window's reset instant falls sooner than the 5h window's for most of
        /// every five-hour period, so a reading-order built from the clock puts 7d
        /// first some of the time and 5h first the rest of it, and the two columns
        /// trade places under a reader who is comparing them. A window's width
        /// never changes, so an order built from it never moves. Nil for a row that
        /// is not a rate-limit window at all (`spend`), and, as with every field
        /// below the original wire format, whenever an older daemon sent the row.
        public let windowSeconds: Int?

        public init(
            label: String,
            pctText: String,
            pctColor: String? = nil,
            secondaryText: String = "",
            secondaryDimmed: Bool = false,
            trailingText: String = "",
            trailingColor: String? = nil,
            trailingDimmed: Bool = false,
            resetsAt: Int? = nil,
            pct: Double? = nil,
            runOutSeconds: Int? = nil,
            windowSeconds: Int? = nil
        ) {
            self.label = label
            self.pctText = pctText
            self.pctColor = pctColor
            self.secondaryText = secondaryText
            self.secondaryDimmed = secondaryDimmed
            self.trailingText = trailingText
            self.trailingColor = trailingColor
            self.trailingDimmed = trailingDimmed
            self.resetsAt = resetsAt
            self.pct = pct
            self.runOutSeconds = runOutSeconds
            self.windowSeconds = windowSeconds
        }
    }

    /// Week-comparison row (`last week` / `this week`). `deltaText` is empty
    /// on the last-week row and "+N%" / "-N%" on the this-week row when a
    /// comparison is possible. `deltaColor` mirrors the status line palette:
    /// green for negative (less usage), orange for positive.
    public struct UsageWeekRowDTO: Codable, Sendable {
        public let label: String
        public let tokensText: String
        public let costText: String
        public let deltaText: String
        public let deltaColor: String?          // "green" | "orange" | nil

        public init(
            label: String,
            tokensText: String,
            costText: String,
            deltaText: String = "",
            deltaColor: String? = nil
        ) {
            self.label = label
            self.tokensText = tokensText
            self.costText = costText
            self.deltaText = deltaText
            self.deltaColor = deltaColor
        }
    }

    /// One activity metric for one week — session-hours or wall-clock — as the three
    /// cells a table row needs: the total, the per-day average, and the change
    /// against the prior window.
    ///
    /// Split out of `UsageHoursRowDTO`'s composite `"86.1h / 42.0h"` cells, which
    /// pack two metrics into one column. A one-line status line has to double up
    /// like that; a window with a table does not, and the composite could not colour
    /// its two halves separately or say WHICH half was missing when only one of them
    /// had a prior window to compare against.
    public struct UsageHoursMetricDTO: Codable, Sendable {
        public let hoursText: String           // "86.1h"
        public let avgText: String             // "12.3h/d"
        public let deltaText: String           // "-65%" / "+12%" / "" (no baseline)
        public let deltaColor: String?         // "green" | "orange" | nil

        public init(
            hoursText: String,
            avgText: String,
            deltaText: String = "",
            deltaColor: String? = nil
        ) {
            self.hoursText = hoursText
            self.avgText = avgText
            self.deltaText = deltaText
            self.deltaColor = deltaColor
        }

        private enum CodingKeys: String, CodingKey {
            case hoursText, avgText, deltaText, deltaColor
        }

        /// Hand-written for the same reason `UsageHoursRowDTO`'s is, and it has to
        /// be: the tolerant decoder one level up guards this type with
        /// `decodeIfPresent`, which only catches an absent KEY. A `keyNotFound`
        /// raised INSIDE a nested type's own decoder propagates straight through it,
        /// so a synthesized decoder here would defeat the outer one — a producer
        /// omitting the delta these fields already default (`deltaText: String = ""`)
        /// would blank the whole Usage window over an optional percentage.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.hoursText = try container.decode(String.self, forKey: .hoursText)
            self.avgText = try container.decode(String.self, forKey: .avgText)
            self.deltaText = try container.decodeIfPresent(String.self, forKey: .deltaText) ?? ""
            self.deltaColor = try container.decodeIfPresent(String.self, forKey: .deltaColor)
        }
    }

    /// Active-hours comparison row (`hrs last week` / `hrs this week`). Pre-formatted
    /// by the daemon; clients render the strings verbatim and apply only the
    /// `deltaColor` hint (green for negative, orange for positive).
    ///
    /// Carries each week twice over: `hoursText`/`avgText`/`deltaText` are the
    /// composite `"session / wall"` cells the one-line status line renders, and
    /// `session`/`wallClock` are the same numbers split per metric, for a client with
    /// room to give each its own row. The composite is COMPOSED from the split pair
    /// in `UsageRowsCompute`, so the two renderings cannot drift apart.
    public struct UsageHoursRowDTO: Codable, Sendable {
        public let label: String
        public let hoursText: String           // "86.1h / 42.0h"
        public let avgText: String             // "12.3h/d / 6.0h/d"
        public let deltaText: String           // "-65% / -40%" or "+12%" or ""
        public let deltaColor: String?         // "green" | "orange" | nil
        /// The week without the metric — `"last week"` / `"this week"` — for a client
        /// that names the metric in a caption instead of in every row label. `""`
        /// from a daemon predating the split; fall back to `label`.
        public let weekLabel: String
        /// The two metrics on their own. nil from a daemon predating the split, where
        /// only the composite cells above are renderable.
        public let session: UsageHoursMetricDTO?
        public let wallClock: UsageHoursMetricDTO?

        public init(
            label: String,
            hoursText: String,
            avgText: String,
            deltaText: String = "",
            deltaColor: String? = nil,
            weekLabel: String = "",
            session: UsageHoursMetricDTO? = nil,
            wallClock: UsageHoursMetricDTO? = nil
        ) {
            self.label = label
            self.hoursText = hoursText
            self.avgText = avgText
            self.deltaText = deltaText
            self.deltaColor = deltaColor
            self.weekLabel = weekLabel
            self.session = session
            self.wallClock = wallClock
        }

        private enum CodingKeys: String, CodingKey {
            case label, hoursText, avgText, deltaText, deltaColor, weekLabel, session, wallClock
        }

        /// Hand-written so the three fields the per-metric split added are OPTIONAL
        /// on the wire. `./install` swaps the daemon while leaving the previous
        /// menu-bar app running until it is relaunched, and a synthesized decoder
        /// would throw `keyNotFound` on the older side of that skew — blanking a
        /// whole Usage window over a column layout. (The same reasoning as
        /// `UsageRowsDTO.hudQuota` and `UsageAccountSectionDTO.isCurrent`.)
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.label = try container.decode(String.self, forKey: .label)
            self.hoursText = try container.decode(String.self, forKey: .hoursText)
            self.avgText = try container.decode(String.self, forKey: .avgText)
            self.deltaText = try container.decodeIfPresent(String.self, forKey: .deltaText) ?? ""
            self.deltaColor = try container.decodeIfPresent(String.self, forKey: .deltaColor)
            self.weekLabel = try container.decodeIfPresent(String.self, forKey: .weekLabel) ?? ""
            self.session = try container.decodeIfPresent(UsageHoursMetricDTO.self, forKey: .session)
            self.wallClock = try container.decodeIfPresent(
                UsageHoursMetricDTO.self, forKey: .wallClock
            )
        }
    }
}
