#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The account router's read surface and the credential relay, as a route set
/// any daemon can mount: `GET /router/status`, `GET /router/report`,
/// `GET /router/exchanges` (what stenographerd served) and
/// `POST /accounts/credentials`.
///
/// No response carries a token. The router's status names saved credentials by
/// item key only, and the relay answers with whether the held set changed.
public enum AccountRouterRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /router/status",
        "GET /router/report",
        "GET /router/exchanges",
        "POST /accounts/credentials"
    ]

    /// `GET /router/report` without `since_hours`.
    public static let defaultReportHours = 24

    /// The relay's reply: no token, only whether the held set moved.
    public struct CredentialRelayReply: Codable, Sendable, Equatable {
        public let changed: Bool

        public init(changed: Bool) {
            self.changed = changed
        }
    }

    /// Every route in the set.
    ///
    /// - Parameters:
    ///   - router: the daemon's router, or nil when it runs none (a dev daemon
    ///     without a router port); `/router/*` then answers 503, not an empty 200.
    ///   - probe: the daemon's one quota probe, which takes custody of relayed
    ///     credentials.
    public static func table(router: AccountRouterServer?, probe: AccountQuotaProbe) -> RouteTable {
        RouteTable([
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "router" }) { request, components in
                routerRoute(sub: components[1], request: request, router: router)
            },
            RouteTable.exact("POST", ["accounts", "credentials"]) { request in
                await relayCredentials(request, probe: probe)
            }
        ])
    }

    // MARK: - /router/*

    private static func routerRoute(
        sub: String, request: RouteRequest, router: AccountRouterServer?
    ) -> RouteResponse {
        guard let router else {
            return RouteResponse(
                status: 503,
                body: Data(#"{"status":"unavailable","error":"no account router on this daemon"}"#.utf8))
        }
        switch sub {
        case "status":
            return .json(router.status())
        case "report":
            var hours = defaultReportHours
            if let raw = request.query("since_hours") {
                guard let parsed = reportHours(raw) else {
                    return .error("since_hours must be a whole number of hours (0 for all time)", status: 400)
                }
                hours = parsed
            }
            do {
                return .json(try router.report(sinceHours: hours))
            } catch {
                return .error(AccountRouterLog.scrub(error.localizedDescription), status: 500)
            }
        case "exchanges":
            let query: Sessions.AccountRouterExchangeQueryDTO
            switch exchangeQuery(request) {
            case .success(let parsed): query = parsed
            case .failure(let refusal): return .error(refusal.message, status: 400)
            }
            do {
                return .json(try router.exchanges(query))
            } catch {
                return .error(AccountRouterLog.scrub(error.localizedDescription), status: 500)
            }
        default:
            return .notFound("Unknown router endpoint: /router/\(sub)")
        }
    }

    struct ExchangeQueryRefusal: Error {
        let message: String
    }

    /// `GET /router/exchanges`' parameters. The numbers are digits only (a run
    /// too long for an `Int` reads as `Int.max`, which the database clamps or
    /// matches nothing with); `rule` must name an `AccountRouterRuleFilter`;
    /// `account` is any string, bound as a parameter.
    static func exchangeQuery(
        _ request: RouteRequest
    ) -> Result<Sessions.AccountRouterExchangeQueryDTO, ExchangeQueryRefusal> {
        var query = Sessions.AccountRouterExchangeQueryDTO(account: request.query("account"))
        let numbers: [(String, WritableKeyPath<Sessions.AccountRouterExchangeQueryDTO, Int?>)] = [
            ("after_id", \.afterId), ("before_id", \.beforeId), ("limit", \.limit), ("since_hours", \.sinceHours)
        ]
        for (name, field) in numbers {
            guard let raw = request.query(name) else { continue }
            guard isDigits(raw) else {
                return .failure(ExchangeQueryRefusal(message: "\(name) must be a whole, non-negative number"))
            }
            query[keyPath: field] = Int(raw) ?? Int.max
        }
        if let raw = request.query("rule") {
            guard let rule = Sessions.AccountRouterRuleFilter(rawValue: raw) else {
                return .failure(ExchangeQueryRefusal(
                    message: "rule must be one of \(Sessions.AccountRouterRuleFilter.validList)"))
            }
            query.rule = rule
        }
        return .success(query)
    }

    /// A `since_hours` value: digits only, clamped to
    /// ``AccountRouterServer/maxReportHours`` (a run of digits too long for an
    /// `Int` is that ceiling too). Nil when it is not a whole, non-negative number.
    static func reportHours(_ raw: String) -> Int? {
        guard isDigits(raw) else { return nil }
        return min(Int(raw) ?? AccountRouterServer.maxReportHours, AccountRouterServer.maxReportHours)
    }

    private static func isDigits(_ raw: String) -> Bool {
        !raw.isEmpty && raw.allSatisfy { $0.isASCII && $0.isNumber }
    }

    // MARK: - POST /accounts/credentials

    /// The client relay (apps suite Phase 3, decision 8): the app that holds the
    /// Keychain items posts the whole `[ClaudeCredentialDTO]` set, and the probe
    /// takes custody of it through ``AccountQuotaProbe/setCredentials(_:)``,
    /// keeping each credential's probe half only.
    ///
    /// Classify-only (`refreshing: false`): an HTTP reply that carries no token
    /// has nowhere to put a rotation, so spending a refresh token here would kill
    /// the login it was asked about. An empty set is a valid push (every account
    /// removed) and clears the store. Who may post is the daemon's own front-door
    /// check; this route trusts what reaches it.
    private static func relayCredentials(_ request: RouteRequest, probe: AccountQuotaProbe) async -> RouteResponse {
        let credentials: [Sessions.ClaudeCredentialDTO]
        do {
            credentials = try StenographerWire.decoder().decode([Sessions.ClaudeCredentialDTO].self, from: request.body)
        } catch {
            // Never the decoding error's text: it can quote the body, and the body is tokens.
            return .error("the body must be a JSON array of credentials", status: 400)
        }
        let evaluation = await probe.takeCredentials(credentials, refreshing: false)
        return .json(CredentialRelayReply(changed: evaluation.changed))
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
