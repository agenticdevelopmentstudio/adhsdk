#if canImport(AgenticDeveloperHubSDKCore)
import Foundation
import AgenticDeveloperHubSDKCore

/// The mutable half of account routing: which entries are cooling down,
/// which session is on which entry, and the first organization id seen for
/// each. Readings and tokens are not kept here; they come from the quota
/// source on every decision, so a credential round or a probe is seen at once.
///
/// Pool entries are item keys (`oauth:<email>`, `long-lived:<name>`).
final class AccountPool: @unchecked Sendable {
    /// Sessions whose assignment is remembered, least recently used evicted first.
    static let maxSessions = 4096

    /// What a routed attempt sends. Never printed: `description` is redacted.
    struct Choice: Sendable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
        let account: String
        let token: String
        let credentialKind: String?

        var description: String { "Choice(account: \(account), token: [redacted])" }
        var debugDescription: String { description }
        var customMirror: Mirror { Mirror(self, children: ["account": account], displayStyle: .struct) }
    }

    struct Decision: Sendable, Equatable {
        let choice: Choice?
        let rule: String
    }

    private let source: any AccountRouterQuotaSource
    private let clock: @Sendable () -> Double
    private let sessionLimit: Int
    private let lock = NSLock()
    private var cooldownUntil: [String: Double] = [:]
    /// Entries cooling only because they held no usable token: the cool-down
    /// ends as soon as one is held, so a token saved mid-cool-down is used at once.
    private var tokenless: Set<String> = []
    /// Session id → item key. The key "" stands for requests with no session id;
    /// they share one assignment.
    private var assignments: [String: String] = [:]
    /// Session ids, least recently used first.
    private var recency: [String] = []
    private var organizations: [String: String] = [:]

    init(
        source: any AccountRouterQuotaSource,
        clock: @escaping @Sendable () -> Double = { Date().timeIntervalSince1970 },
        maxSessions: Int = AccountPool.maxSessions
    ) {
        self.source = source
        self.clock = clock
        self.sessionLimit = max(1, maxSessions)
    }

    /// Chooses an entry from `settings.accounts`. The cool-down, expiry margin
    /// and stickiness are the settings'. With sticky off every request is
    /// ranked afresh, but the assignment is still recorded so session counts hold.
    func decide(sessionId: String?, settings: AccountRouterSettings) -> Decision {
        let pool = settings.accounts
        let cooldown = Double(settings.cooldownSeconds)
        let margin = Double(settings.expiryMarginSeconds)
        let now = clock()
        lock.lock(); defer { lock.unlock() }
        var usable: [String: AccountQuotaProbe.HeldToken] = [:]
        var states: [RouterAccountState] = []
        for key in pool {
            let held = usableToken(key, now: now, margin: margin)
            if held == nil && !isCooling(key, now: now) {
                cooldownUntil[key] = now + cooldown
                tokenless.insert(key)
            }
            usable[key] = held
            states.append(state(for: key, available: held != nil && !isCooling(key, now: now)))
        }
        let session = sessionId ?? ""
        let current = settings.sticky ? assignments[session] : nil
        let decision = RoutingPolicy.route(states, current: current, now: now, ceiling: settings.fiveHourCeiling)
        guard let account = decision.account, let held = usable[account] else {
            return Decision(choice: nil, rule: decision.rule)
        }
        assign(session, to: account)
        let choice = Choice(account: account, token: held.token, credentialKind: held.credentialKind)
        return Decision(choice: choice, rule: decision.rule)
    }

    /// Folds one routed response into the source and the pool. `headers` are
    /// the response's, keys lowercased. A 401 or 429 cools the entry for `cooldown` seconds.
    func observe(account: String, status: Int?, headers: [String: String], cooldown: Int) {
        let parsed = ClaudeCredentialKind.parse(itemKey: account)
        source.observe(account: parsed?.name ?? account, credentialKind: parsed?.kind.rawValue, headers: headers)
        let now = clock()
        lock.lock(); defer { lock.unlock() }
        if organizations[account] == nil, let org = headers["anthropic-organization-id"], !org.isEmpty {
            organizations[account] = org
        }
        if status == 401 || status == 429 {
            cooldownUntil[account] = now + Double(cooldown)
            tokenless.remove(account)
        }
    }

    /// Ends every cool-down now, so each entry is ranked again on the next
    /// request. Sessions and organization ids are kept. An entry that is
    /// still unusable cools again on the next decision that reaches it.
    func clearCooldowns() {
        lock.lock(); defer { lock.unlock() }
        cooldownUntil.removeAll()
        tokenless.removeAll()
    }

    /// Per-entry state for status. Never a token.
    func snapshot(settings: AccountRouterSettings) -> [Sessions.AccountRouterPoolEntryDTO] {
        let margin = Double(settings.expiryMarginSeconds)
        let ceiling = settings.fiveHourCeiling
        let now = clock()
        lock.lock(); defer { lock.unlock() }
        var sessions: [String: Int] = [:]
        for account in assignments.values { sessions[account, default: 0] += 1 }
        return settings.accounts.map { key in
            let held = source.heldToken(itemKey: key) != nil
            let usable = usableToken(key, now: now, margin: margin) != nil
            let cooling = isCooling(key, now: now)
            let state = state(for: key, available: usable && !cooling)
            let left = cooling ? Int(((cooldownUntil[key] ?? now) - now).rounded(.up)) : nil
            return Sessions.AccountRouterPoolEntryDTO(
                account: key, held: held, available: state.available,
                eligible: RoutingPolicy.eligible(state, now: now, ceiling: ceiling),
                coolingDownFor: left,
                fiveHourUtilization: state.fiveHour.utilization,
                fiveHourResetsAt: state.fiveHour.reset.map { Int($0) },
                fiveHourStatus: state.fiveHour.status,
                sevenDayUtilization: state.sevenDay.utilization,
                sevenDayResetsAt: state.sevenDay.reset.map { Int($0) },
                sevenDayStatus: state.sevenDay.status,
                organizationId: organizations[key],
                sessions: sessions[key] ?? 0)
        }
    }

    // MARK: - Under the lock

    /// A usable token also ends a cool-down that was only for want of one.
    private func usableToken(_ key: String, now: Double, margin: Double) -> AccountQuotaProbe.HeldToken? {
        guard let held = source.heldToken(itemKey: key), !held.token.isEmpty else { return nil }
        if let expiry = held.expiresAt, expiry - now <= margin { return nil }
        if tokenless.remove(key) != nil { cooldownUntil[key] = nil }
        return held
    }

    private func isCooling(_ key: String, now: Double) -> Bool {
        now < (cooldownUntil[key] ?? -.infinity)
    }

    /// Readings are percentages (0–100) in the store; the policy wants fractions.
    private func state(for key: String, available: Bool) -> RouterAccountState {
        let parsed = ClaudeCredentialKind.parse(itemKey: key)
        let reading = source.reading(account: parsed?.name ?? key, credentialKind: parsed?.kind.rawValue)
        return RouterAccountState(
            name: key,
            available: available,
            fiveHour: RouterWindow(
                utilization: reading?.fiveHourPct.map { $0 / 100 },
                reset: reading?.fiveHourResetsAt.map { Double($0) },
                status: reading?.fiveHourStatus),
            sevenDay: RouterWindow(
                utilization: reading?.sevenDayPct.map { $0 / 100 },
                reset: reading?.sevenDayResetsAt.map { Double($0) },
                status: reading?.sevenDayStatus))
    }

    private func assign(_ session: String, to account: String) {
        assignments[session] = account
        recency.removeAll { $0 == session }
        recency.append(session)
        while recency.count > sessionLimit {
            assignments[recency.removeFirst()] = nil
        }
    }
}
#endif
