import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `RoutingPolicy`, table-driven at a fixed clock. Every case is a port of a
/// row in model-router's `tests/test_policy.py`. A session's assignment is
/// handed in as `current`, because the pool looks it up, not the policy.
final class RoutingPolicyTests: XCTestCase {
    private let now = 1_785_000_000.0
    private let hour = 3600.0

    private func acct(
        _ name: String, available: Bool = true,
        five: Double? = nil, fiveReset: Double? = nil, fiveStatus: String? = nil,
        seven: Double? = nil, sevenReset: Double? = nil, sevenStatus: String? = nil
    ) -> RouterAccountState {
        RouterAccountState(
            name: name, available: available,
            fiveHour: RouterWindow(utilization: five, reset: fiveReset, status: fiveStatus),
            sevenDay: RouterWindow(utilization: seven, reset: sevenReset, status: sevenStatus))
    }

    func testRouteTable() {
        let cases: [(String, [RouterAccountState], String?, RoutingDecision)] = [
            ("normal ranking: highest urgency wins",
             [acct("a", seven: 0.5, sevenReset: now + 100 * hour), acct("b", seven: 0.2, sevenReset: now + 10 * hour)],
             nil, RoutingDecision(account: "b", rule: "ranked")),
            ("all ineligible: no account",
             [acct("a", five: 0.97, fiveReset: now + hour), acct("b", fiveReset: now + hour, fiveStatus: "rejected")],
             nil, RoutingDecision(account: nil, rule: "all-ineligible")),
            ("single account",
             [acct("a", seven: 0.9, sevenReset: now + hour)],
             nil, RoutingDecision(account: "a", rule: "ranked")),
            ("imminent reset is floored at 0.05h, not divided by ~0",
             [acct("a", seven: 0.9, sevenReset: now + 60), acct("b", seven: 0.0, sevenReset: now + hour)],
             nil, RoutingDecision(account: "a", rule: "ranked")),
            ("clock skew past reset: a stale reading counts as an empty window",
             [acct("a", five: 0.99, fiveReset: now - 10, seven: 0.99, sevenReset: now - 10),
              acct("b", seven: 0.0, sevenReset: now + hour)],
             nil, RoutingDecision(account: "a", rule: "ranked")),
            ("stickiness holds across turns even when another is more urgent",
             [acct("a", seven: 0.5, sevenReset: now + 100 * hour), acct("b", seven: 0.0, sevenReset: now + hour)],
             "a", RoutingDecision(account: "a", rule: "sticky")),
            ("a session whose account became ineligible switches",
             [acct("a", five: 0.96, fiveReset: now + hour), acct("b")],
             "a", RoutingDecision(account: "b", rule: "switched: a ineligible")),
            ("all ineligible keeps no account even for an assigned session",
             [acct("a", available: false)],
             "a", RoutingDecision(account: nil, rule: "all-ineligible")),
            ("ties go to the account listed first",
             [acct("a"), acct("b")],
             nil, RoutingDecision(account: "a", rule: "ranked")),
            ("another session's assignment is not this session's",
             [acct("a"), acct("b", seven: 0.0, sevenReset: now + hour)],
             nil, RoutingDecision(account: "b", rule: "ranked")),
            ("an assignment to an account no longer in the pool switches",
             [acct("b")],
             "gone", RoutingDecision(account: "b", rule: "switched: gone ineligible"))
        ]
        for (name, accounts, current, expected) in cases {
            XCTAssertEqual(RoutingPolicy.route(accounts, current: current, now: now, ceiling: 0.95), expected, name)
        }
    }

    func testEligibleTable() {
        let cases: [(RouterAccountState, Bool, String)] = [
            (acct("a"), true, "no reading"),
            (acct("a", available: false), false, "cooling down"),
            (acct("a", five: 0.95, fiveReset: now + 1), false, "at the ceiling"),
            (acct("a", five: 0.9499, fiveReset: now + 1), true, "just under the ceiling"),
            (acct("a", five: 0.99), false, "unknown reset counts as current"),
            (acct("a", fiveStatus: "rejected"), false, "5h rejected"),
            (acct("a", fiveReset: now - 1, fiveStatus: "rejected"), true, "5h rejected but reset"),
            (acct("a", sevenReset: now + 1, sevenStatus: "rejected"), false, "7d rejected"),
            (acct("a", sevenReset: now - 1, sevenStatus: "rejected"), true, "7d rejected but reset"),
            (acct("a", seven: 1.0, sevenReset: now + 1), true, "7d utilization alone never excludes")
        ]
        for (state, expected, name) in cases {
            XCTAssertEqual(RoutingPolicy.eligible(state, now: now, ceiling: 0.95), expected, name)
        }
    }

    func testTheCeilingIsTheCallersNotAConstant() {
        let accounts = [acct("a", five: 0.85, fiveReset: now + hour)]
        XCTAssertNil(RoutingPolicy.route(accounts, current: nil, now: now, ceiling: 0.8).account)
        XCTAssertEqual(RoutingPolicy.route(accounts, current: nil, now: now, ceiling: 0.95).account, "a")
    }

    func testUrgencyTable() {
        let cases: [(RouterAccountState, Double, String)] = [
            (acct("a"), 1.0 / 168, "nothing known"),
            (acct("a", seven: 0.5), 0.5 / 168, "no reset known"),
            (acct("a", sevenReset: now + 2 * hour), 1.0 / 2, "no utilization"),
            (acct("a", seven: 0.75, sevenReset: now + 5 * hour), 0.25 / 5, "both known"),
            (acct("a", seven: 1.3, sevenReset: now + hour), 0.0, "over 100% clamps to 0"),
            (acct("a", seven: -0.2, sevenReset: now + hour), 1.0, "negative clamps to 1"),
            (acct("a", seven: 0.9, sevenReset: now - 1), 1.0 / 0.05, "stale reading is a full window, floored hours")
        ]
        for (state, expected, name) in cases {
            XCTAssertEqual(RoutingPolicy.urgency(state, now: now), expected, accuracy: 1e-9, name)
        }
    }
}
