#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// One rate-limit window as last read. `utilization` is a fraction (0–1);
/// `reset` is epoch seconds.
struct RouterWindow: Equatable, Sendable {
    var utilization: Double?
    var reset: Double?
    var status: String?
}

/// What the router last saw of one pool entry.
struct RouterAccountState: Equatable, Sendable {
    var name: String
    /// false while the entry cannot be used: no token, near expiry, cooling down.
    var available = true
    var fiveHour = RouterWindow()
    var sevenDay = RouterWindow()
}

struct RoutingDecision: Equatable, Sendable {
    /// nil: forward with the client's own credential.
    let account: String?
    let rule: String
}

/// Which pool entry serves a request. A verbatim port of model-router
/// `policy.py`. Pure: no I/O, no clock, no state beyond the arguments.
///
/// Eligibility is judged on the 5-hour window. Ranking is by how much 7-day
/// quota would otherwise expire unused. Sessions are sticky, because prompt
/// caching is per account and switching throws the cache away.
enum RoutingPolicy {
    static let defaultCeiling = 0.95
    /// Survives an imminent reset and clock skew without dividing by ~0.
    static let hoursFloor = 0.05
    /// An entry with no 7-day reset is ranked as if it had a full week left.
    static let unknownSevenDayHours = 168.0
    static let rejected = "rejected"

    /// A window's reading is current until its reset. An unknown reset never
    /// passes, so the reading counts as current.
    static func isCurrent(_ reset: Double?, now: Double) -> Bool {
        guard let reset else { return true }
        return now < reset
    }

    static func eligible(_ account: RouterAccountState, now: Double, ceiling: Double) -> Bool {
        guard account.available else { return false }
        let fiveCurrent = isCurrent(account.fiveHour.reset, now: now)
        if fiveCurrent && account.fiveHour.status == rejected { return false }
        if isCurrent(account.sevenDay.reset, now: now) && account.sevenDay.status == rejected { return false }
        guard fiveCurrent, let utilization = account.fiveHour.utilization else { return true }
        return utilization < ceiling
    }

    /// remaining 7-day quota ÷ hours until the 7-day reset: how fast unused
    /// quota is expiring.
    static func urgency(_ account: RouterAccountState, now: Double) -> Double {
        let reset = account.sevenDay.reset
        let hours = reset.map { max(hoursFloor, ($0 - now) / 3600) } ?? unknownSevenDayHours
        var remaining = 1.0
        if let utilization = account.sevenDay.utilization, isCurrent(reset, now: now) {
            remaining = min(1.0, max(0.0, 1.0 - utilization))
        }
        return remaining / hours
    }

    /// `current` is the entry this request's session is assigned to, if any.
    static func route(
        _ accounts: [RouterAccountState], current: String?, now: Double, ceiling: Double
    ) -> RoutingDecision {
        let candidates = accounts.filter { eligible($0, now: now, ceiling: ceiling) }
        if let current, candidates.contains(where: { $0.name == current }) {
            return RoutingDecision(account: current, rule: "sticky")
        }
        guard var best = candidates.first else { return RoutingDecision(account: nil, rule: "all-ineligible") }
        var bestUrgency = urgency(best, now: now)
        // Strictly greater, so ties go to the entry listed first (Python's max()).
        for candidate in candidates.dropFirst() {
            let value = urgency(candidate, now: now)
            if value > bestUrgency {
                best = candidate
                bestUrgency = value
            }
        }
        if let current {
            return RoutingDecision(account: best.name, rule: "switched: \(current) ineligible")
        }
        return RoutingDecision(account: best.name, rule: "ranked")
    }
}
#endif
