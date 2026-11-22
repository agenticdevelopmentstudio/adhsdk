#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// How one attempt goes upstream. `bearer` is a secret, so no printed form
/// of a plan contains it.
struct ExchangePlan: Sendable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    /// The pool entry (item key) that serves it; nil forwards verbatim.
    let account: String?
    /// The token swapped in; nil keeps the client's own `Authorization`.
    let bearer: String?
    /// The `routing_rule` column; nil when routing is off.
    let rule: String?

    static let verbatim = ExchangePlan(account: nil, bearer: nil, rule: nil)

    var description: String {
        "ExchangePlan(account: \(account ?? "-"), bearer: \(bearer == nil ? "client's own" : "[redacted]"), "
            + "rule: \(rule ?? "-"))"
    }

    var debugDescription: String { description }

    var customMirror: Mirror {
        Mirror(self, children: ["account": account as Any, "rule": rule as Any], displayStyle: .struct)
    }
}

/// Chooses each attempt's plan. Implementations never throw and never block
/// on I/O beyond a settings read: every fault becomes a verbatim plan.
protocol ExchangePlanning: Sendable {
    func plan(_ head: RouterRequestHead) -> ExchangePlan
    /// The second and last attempt, after `account` answered `status` (401 or
    /// 429) before anything was relayed. Gated exactly like `plan`. The rule,
    /// where there is one, ends `(retry after <account> <status>)`; routing off
    /// is `.verbatim` with no rule.
    func replan(_ head: RouterRequestHead, after account: String, status: Int) -> ExchangePlan
    /// One upstream response head for `plan`: quota, organization id, cool-down.
    func observe(_ plan: ExchangePlan, head: UpstreamHead)
    /// Whether a routed 401/429 may be retried once on another entry. Read
    /// when such an answer arrives, so a settings change applies at once.
    func allowsRetry() -> Bool
}

/// Forwards everything with the client's own credential.
struct VerbatimPlanner: ExchangePlanning {
    func plan(_ head: RouterRequestHead) -> ExchangePlan { .verbatim }
    func replan(_ head: RouterRequestHead, after account: String, status: Int) -> ExchangePlan { .verbatim }
    func observe(_ plan: ExchangePlan, head: UpstreamHead) {}
    func allowsRetry() -> Bool { false }
}
#endif
