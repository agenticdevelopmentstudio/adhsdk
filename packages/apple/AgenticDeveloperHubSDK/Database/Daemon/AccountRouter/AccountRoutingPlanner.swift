#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The production `ExchangePlanning`: routing on or off, the fence, then the
/// pool. Nothing here throws. The only I/O is the settings read and, for a
/// bearer the daemon does not hold, the fence's read of the fingerprints file;
/// either failing reads as "off" or "not ours". So every path ends in a plan,
/// and every plan that is not a pool choice is verbatim.
///
/// `plan` and `replan` apply the same gates, so a retry never hands out a pool
/// bearer for a request the first attempt would not have routed, whoever the
/// caller is.
final class AccountRoutingPlanner: ExchangePlanning, @unchecked Sendable {
    static let notRoutable = "passthrough: not routable"
    static let unknownCredential = "passthrough: unknown credential"

    private let settings: @Sendable () -> AccountRouterSettings
    private let fence: CredentialFence
    private let pool: AccountPool

    init(settings: @escaping @Sendable () -> AccountRouterSettings, fence: CredentialFence, pool: AccountPool) {
        self.settings = settings
        self.fence = fence
        self.pool = pool
    }

    func plan(_ head: RouterRequestHead) -> ExchangePlan {
        let current = settings()
        guard current.enabled else { return .verbatim }
        if let refusal = refusal(head) { return Self.passthrough(refusal) }
        return decide(head, settings: current, note: nil)
    }

    /// Routing off is verbatim with no rule, as on a first attempt.
    func replan(_ head: RouterRequestHead, after account: String, status: Int) -> ExchangePlan {
        let note = "(retry after \(account) \(status))"
        let current = settings()
        guard current.enabled else { return .verbatim }
        if let refusal = refusal(head) { return Self.passthrough("\(refusal) \(note)") }
        return decide(head, settings: current, note: note)
    }

    func observe(_ plan: ExchangePlan, head: UpstreamHead) {
        guard let account = plan.account else { return }
        pool.observe(account: account, status: head.status, headers: head.headers,
                     cooldown: settings().cooldownSeconds)
    }

    func allowsRetry() -> Bool { settings().retry }

    /// The passthrough rule for a request that may not reach the pool, or nil.
    /// The fence runs before the pool, so a forged token never touches it.
    private func refusal(_ head: RouterRequestHead) -> String? {
        guard let token = RouterHeaders.candidateToken(head) else { return Self.notRoutable }
        guard fence.owns(token) else {
            AccountRouterLog.logger.info("Bearer credential is not a saved one; forwarding verbatim")
            return Self.unknownCredential
        }
        return nil
    }

    private func decide(_ head: RouterRequestHead, settings current: AccountRouterSettings,
                        note: String?) -> ExchangePlan {
        let decision = pool.decide(sessionId: head.value(RouterHeaders.sessionHeader), settings: current)
        let rule = note.map { "\(decision.rule) \($0)" } ?? decision.rule
        guard let choice = decision.choice else { return Self.passthrough(rule) }
        let line = AccountRouterLog.scrub("Routing to \(choice.account) (\(rule))")
        AccountRouterLog.logger.info("\(line, privacy: .public)")
        return ExchangePlan(account: choice.account, bearer: choice.token, rule: rule)
    }

    private static func passthrough(_ rule: String) -> ExchangePlan {
        ExchangePlan(account: nil, bearer: nil, rule: rule)
    }
}
#endif
