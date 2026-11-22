import Foundation

extension Sessions {

    /// The one test for "an item key the account router may pool", shared by
    /// the daemon (which refuses anything else), the CLI and the Settings panel
    /// (which offer only these). A legacy bare-name key has no kind to route by.
    public enum AccountRouterItemKey {
        public static func isRoutable(_ key: String) -> Bool {
            guard let parsed = ClaudeCredentialKind.parse(itemKey: key) else { return false }
            return !parsed.name.isEmpty
        }
    }

    /// One pool entry as `steno router status`, `GET /router/status` and the
    /// Settings panel show it. Secret-free by construction: it has no field that
    /// could hold a token.
    public struct AccountRouterPoolEntryDTO: Codable, Sendable, Equatable {
        /// The saved credential's item key (`oauth:<email>` / `long-lived:<name>`).
        public let account: String
        /// The daemon holds a token for it.
        public let held: Bool
        /// Held, not within the expiry margin (300 s by default), not cooling down.
        public let available: Bool
        /// Passes the policy's `eligible` right now.
        public let eligible: Bool
        /// Seconds of cool-down left, nil when not cooling.
        public let coolingDownFor: Int?
        /// 0–1 fractions, epoch-second resets and statuses, as last read.
        public let fiveHourUtilization: Double?
        public let fiveHourResetsAt: Int?
        public let fiveHourStatus: String?
        public let sevenDayUtilization: Double?
        public let sevenDayResetsAt: Int?
        public let sevenDayStatus: String?
        /// First `anthropic-organization-id` the router saw for it.
        public let organizationId: String?
        /// Sessions currently stuck to it.
        public let sessions: Int

        public init(
            account: String, held: Bool, available: Bool, eligible: Bool, coolingDownFor: Int?,
            fiveHourUtilization: Double?, fiveHourResetsAt: Int?, fiveHourStatus: String?,
            sevenDayUtilization: Double?, sevenDayResetsAt: Int?, sevenDayStatus: String?,
            organizationId: String?, sessions: Int
        ) {
            self.account = account
            self.held = held
            self.available = available
            self.eligible = eligible
            self.coolingDownFor = coolingDownFor
            self.fiveHourUtilization = fiveHourUtilization
            self.fiveHourResetsAt = fiveHourResetsAt
            self.fiveHourStatus = fiveHourStatus
            self.sevenDayUtilization = sevenDayUtilization
            self.sevenDayResetsAt = sevenDayResetsAt
            self.sevenDayStatus = sevenDayStatus
            self.organizationId = organizationId
            self.sessions = sessions
        }
    }

    /// The router's whole state. `baseUrl` (not `baseURL`) so the snake-case
    /// wire key `base_url` round-trips through `convertFromSnakeCase`.
    public struct AccountRouterStatusDTO: Codable, Sendable, Equatable {
        public let enabled: Bool
        public let port: Int
        public let listening: Bool
        public let baseUrl: String
        public let fiveHourCeiling: Double
        public let pool: [AccountRouterPoolEntryDTO]
        /// Item keys of every credential the daemon holds — what the pool can be chosen from.
        public let savedCredentials: [String]
        /// Seconds an entry sits out after a 401, a 429, or being found unusable.
        public let cooldownSeconds: Int
        /// A token this close to expiry (seconds) is not handed out.
        public let expiryMarginSeconds: Int
        /// A routed 401/429 is retried once on another entry.
        public let retry: Bool
        /// Sessions stay on their entry while it is eligible.
        public let sticky: Bool
        /// Days of routing history kept; 0 is forever.
        public let retentionDays: Int
        /// Model routing; nil from a daemon older than it.
        public let models: ModelRouterStatusDTO?

        public static let defaultCooldownSeconds = 60
        public static let defaultExpiryMarginSeconds = 300
        public static let defaultRetentionDays = 30

        public init(
            enabled: Bool, port: Int, listening: Bool, baseUrl: String, fiveHourCeiling: Double,
            pool: [AccountRouterPoolEntryDTO], savedCredentials: [String],
            cooldownSeconds: Int = AccountRouterStatusDTO.defaultCooldownSeconds,
            expiryMarginSeconds: Int = AccountRouterStatusDTO.defaultExpiryMarginSeconds,
            retry: Bool = true, sticky: Bool = true,
            retentionDays: Int = AccountRouterStatusDTO.defaultRetentionDays,
            models: ModelRouterStatusDTO? = nil
        ) {
            self.models = models
            self.enabled = enabled
            self.port = port
            self.listening = listening
            self.baseUrl = baseUrl
            self.fiveHourCeiling = fiveHourCeiling
            self.pool = pool
            self.savedCredentials = savedCredentials
            self.cooldownSeconds = cooldownSeconds
            self.expiryMarginSeconds = expiryMarginSeconds
            self.retry = retry
            self.sticky = sticky
            self.retentionDays = retentionDays
        }

        private enum CodingKeys: String, CodingKey {
            case enabled, port, listening, baseUrl, fiveHourCeiling, pool, savedCredentials
            case cooldownSeconds, expiryMarginSeconds, retry, sticky, retentionDays, models
        }

        /// A daemon older than the tuning rows sends none of them: each reads as its default.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try container.decode(Bool.self, forKey: .enabled)
            port = try container.decode(Int.self, forKey: .port)
            listening = try container.decode(Bool.self, forKey: .listening)
            baseUrl = try container.decode(String.self, forKey: .baseUrl)
            fiveHourCeiling = try container.decode(Double.self, forKey: .fiveHourCeiling)
            pool = try container.decode([AccountRouterPoolEntryDTO].self, forKey: .pool)
            savedCredentials = try container.decode([String].self, forKey: .savedCredentials)
            cooldownSeconds = try container.decodeIfPresent(Int.self, forKey: .cooldownSeconds)
                ?? Self.defaultCooldownSeconds
            expiryMarginSeconds = try container.decodeIfPresent(Int.self, forKey: .expiryMarginSeconds)
                ?? Self.defaultExpiryMarginSeconds
            retry = try container.decodeIfPresent(Bool.self, forKey: .retry) ?? true
            sticky = try container.decodeIfPresent(Bool.self, forKey: .sticky) ?? true
            retentionDays = try container.decodeIfPresent(Int.self, forKey: .retentionDays) ?? Self.defaultRetentionDays
            models = try container.decodeIfPresent(ModelRouterStatusDTO.self, forKey: .models)
        }
    }

    /// One account's line in `steno router report`.
    public struct AccountRouterReportRowDTO: Codable, Sendable, Equatable {
        /// Item key; nil for requests forwarded verbatim.
        public let account: String?
        public let requests: Int
        /// 429s relayed from it plus 429s it answered that a retry hid.
        public let rateLimited: Int
        public let peakFiveHour: Double?
        public let peakSevenDay: Double?
        public let organizationIds: [String]

        public init(
            account: String?, requests: Int, rateLimited: Int, peakFiveHour: Double?, peakSevenDay: Double?,
            organizationIds: [String]
        ) {
            self.account = account
            self.requests = requests
            self.rateLimited = rateLimited
            self.peakFiveHour = peakFiveHour
            self.peakSevenDay = peakSevenDay
            self.organizationIds = organizationIds
        }
    }

    public struct AccountRouterReportDTO: Codable, Sendable, Equatable {
        /// The window asked for; 0 is all time.
        public let sinceHours: Int
        public let total: Int
        public let rows: [AccountRouterReportRowDTO]
        /// Per requested/served model and provider; nil from a daemon older than model routing.
        public let models: [ModelUsageRowDTO]?

        public init(sinceHours: Int, total: Int, rows: [AccountRouterReportRowDTO], models: [ModelUsageRowDTO]? = nil) {
            self.models = models
            self.sinceHours = sinceHours
            self.total = total
            self.rows = rows
        }

        /// The account a rule says answered `status` before a retry, or nil. Ported
        /// from model-router `cli.py`'s `\(retry after (\S+) 429\)$`.
        public static func retriedAccount(in rule: String, status: Int) -> String? {
            let suffix = " \(status))"
            let marker = "(retry after "
            guard rule.hasSuffix(suffix), let open = rule.range(of: marker, options: .backwards) else { return nil }
            let nameEnd = rule.index(rule.endIndex, offsetBy: -suffix.count)
            // "(retry after 429)": the marker and the suffix overlap, so there is no name.
            guard open.upperBound <= nameEnd else { return nil }
            let name = rule[open.upperBound..<nameEnd]
            guard !name.isEmpty, !name.contains(where: \.isWhitespace) else { return nil }
            return String(name)
        }
    }

    /// One `account_router_exchange` row as the routing log shows it. Secret-free
    /// by construction: these are the table's columns, none of which holds a
    /// token, header value or body, and `error` was scrubbed before it was stored.
    public struct AccountRouterExchangeDTO: Codable, Sendable, Equatable {
        public let id: Int
        /// ISO-8601 with fractional seconds, exactly as stored.
        public let startedAt: String
        public let durationMs: Int
        public let sessionId: String?
        public let method: String
        /// Without the query.
        public let path: String
        /// Final status relayed; nil when the client went away first.
        public let status: Int?
        /// Item key that served it; nil when it was forwarded verbatim.
        public let account: String?
        /// nil when routing was off.
        public let routingRule: String?
        public let fiveHourUtilization: Double?
        public let sevenDayUtilization: Double?
        public let fiveHourStatus: String?
        public let sevenDayStatus: String?
        public let organizationId: String?
        public let error: String?
        /// The model the client asked for; nil when model routing was off or passed it by.
        public let requestedModel: String?
        /// Set only when the body sent upstream named another model.
        public let routedModel: String?
        /// The model the response named.
        public let servedModel: String?
        /// nil when model routing was off.
        public let modelRule: String?
        public let provider: String?
        /// `ModelThreadKind` raw value.
        public let threadKind: String?
        public let writes: Bool?
        public let inputTokens: Int?
        public let outputTokens: Int?
        public let cacheReadTokens: Int?
        public let cacheCreationTokens: Int?
        public let stopReason: String?

        public init(
            id: Int, startedAt: String, durationMs: Int, sessionId: String?, method: String, path: String,
            status: Int?, account: String?, routingRule: String?,
            fiveHourUtilization: Double?, sevenDayUtilization: Double?,
            fiveHourStatus: String?, sevenDayStatus: String?, organizationId: String?, error: String?,
            requestedModel: String? = nil, routedModel: String? = nil, servedModel: String? = nil,
            modelRule: String? = nil, provider: String? = nil, threadKind: String? = nil, writes: Bool? = nil,
            inputTokens: Int? = nil, outputTokens: Int? = nil, cacheReadTokens: Int? = nil,
            cacheCreationTokens: Int? = nil, stopReason: String? = nil
        ) {
            self.requestedModel = requestedModel
            self.routedModel = routedModel
            self.servedModel = servedModel
            self.modelRule = modelRule
            self.provider = provider
            self.threadKind = threadKind
            self.writes = writes
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.cacheReadTokens = cacheReadTokens
            self.cacheCreationTokens = cacheCreationTokens
            self.stopReason = stopReason
            self.id = id
            self.startedAt = startedAt
            self.durationMs = durationMs
            self.sessionId = sessionId
            self.method = method
            self.path = path
            self.status = status
            self.account = account
            self.routingRule = routingRule
            self.fiveHourUtilization = fiveHourUtilization
            self.sevenDayUtilization = sevenDayUtilization
            self.fiveHourStatus = fiveHourStatus
            self.sevenDayStatus = sevenDayStatus
            self.organizationId = organizationId
            self.error = error
        }
    }

    /// The routing log's rule filter. Each matches a family of `routing_rule`
    /// strings (see `DatabaseManager.routerExchangePage`); `retried` overlaps the
    /// others, and `off` is a NULL rule (routing was off).
    public enum AccountRouterRuleFilter: String, Codable, Sendable, CaseIterable {
        case sticky, ranked, switched, allIneligible = "all-ineligible", passthrough, retried, off

        /// "sticky, ranked, …, off" — for a refusal that says what is accepted.
        public static var validList: String { allCases.map(\.rawValue).joined(separator: ", ") }

        /// A refusal for an unknown rule name.
        public static func unknown(_ raw: String) -> String {
            "Unknown rule \"\(raw)\"; use one of \(validList)."
        }
    }

    /// One routing-log question. Every field is optional; nil means "no filter".
    public struct AccountRouterExchangeQueryDTO: Codable, Sendable, Equatable {
        /// Only rows with a larger id (newer).
        public var afterId: Int?
        /// Only rows with a smaller id (older).
        public var beforeId: Int?
        /// Rows per page: `defaultLimit` when nil, clamped to 1…`maxLimit`.
        public var limit: Int?
        /// An item key, or `verbatimAccount` for rows forwarded verbatim.
        public var account: String?
        public var rule: AccountRouterRuleFilter?
        /// The last N hours; nil or 0 (or less) is all time.
        public var sinceHours: Int?

        public static let defaultLimit = 200
        public static let maxLimit = 1000
        public static let verbatimAccount = "-"

        public init(
            afterId: Int? = nil, beforeId: Int? = nil, limit: Int? = nil, account: String? = nil,
            rule: AccountRouterRuleFilter? = nil, sinceHours: Int? = nil
        ) {
            self.afterId = afterId
            self.beforeId = beforeId
            self.limit = limit
            self.account = account
            self.rule = rule
            self.sinceHours = sinceHours
        }

        /// `limit` as the daemon applies it.
        public var effectiveLimit: Int { min(max(limit ?? Self.defaultLimit, 1), Self.maxLimit) }

        private enum CodingKeys: String, CodingKey {
            case afterId, beforeId, limit, account, rule, sinceHours
        }

        /// An unknown rule is refused with the list of known ones, not a generic decoding error.
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            afterId = try container.decodeIfPresent(Int.self, forKey: .afterId)
            beforeId = try container.decodeIfPresent(Int.self, forKey: .beforeId)
            limit = try container.decodeIfPresent(Int.self, forKey: .limit)
            account = try container.decodeIfPresent(String.self, forKey: .account)
            sinceHours = try container.decodeIfPresent(Int.self, forKey: .sinceHours)
            if let raw = try container.decodeIfPresent(String.self, forKey: .rule) {
                guard let parsed = AccountRouterRuleFilter(rawValue: raw) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .rule, in: container, debugDescription: AccountRouterRuleFilter.unknown(raw))
                }
                rule = parsed
            } else {
                rule = nil
            }
        }
    }

    /// One page of the routing log, newest first.
    public struct AccountRouterExchangePageDTO: Codable, Sendable, Equatable {
        public let exchanges: [AccountRouterExchangeDTO]

        public init(exchanges: [AccountRouterExchangeDTO]) {
            self.exchanges = exchanges
        }
    }

    /// A partial settings write: nil fields are left as they are.
    public struct AccountRouterPreferencesRequestDTO: Codable, Sendable, Equatable {
        public var enabled: Bool?
        public var accounts: [String]?
        public var fiveHourCeiling: Double?
        /// 1–3600 seconds.
        public var cooldownSeconds: Int?
        /// 0–3600 seconds.
        public var expiryMarginSeconds: Int?
        public var retry: Bool?
        public var sticky: Bool?
        /// 0–3650 days; 0 keeps routing history forever.
        public var retentionDays: Int?
        /// Model routing, written whole; nil leaves it as it is.
        public var models: ModelRouterPreferencesDTO?

        public init(
            enabled: Bool? = nil, accounts: [String]? = nil, fiveHourCeiling: Double? = nil,
            cooldownSeconds: Int? = nil, expiryMarginSeconds: Int? = nil, retry: Bool? = nil, sticky: Bool? = nil,
            retentionDays: Int? = nil, models: ModelRouterPreferencesDTO? = nil
        ) {
            self.models = models
            self.enabled = enabled
            self.accounts = accounts
            self.fiveHourCeiling = fiveHourCeiling
            self.cooldownSeconds = cooldownSeconds
            self.expiryMarginSeconds = expiryMarginSeconds
            self.retry = retry
            self.sticky = sticky
            self.retentionDays = retentionDays
        }
    }
}
