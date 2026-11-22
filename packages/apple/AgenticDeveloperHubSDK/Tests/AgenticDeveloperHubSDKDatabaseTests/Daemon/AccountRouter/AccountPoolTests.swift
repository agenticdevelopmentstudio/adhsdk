import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `AccountPool`: what feeds the policy (held tokens, expiry margin, cool-downs,
/// readings converted from percent), sticky sessions with an LRU bound, the
/// first-seen organization id, and the secret-free snapshot.
final class AccountPoolTests: XCTestCase {
    private let start = 1_785_000_000.0
    private var source: FakeQuotaSource!
    private var clock: TestClock!

    override func setUp() {
        source = FakeQuotaSource()
        clock = TestClock(start)
    }

    private func pool(maxSessions: Int = AccountPool.maxSessions) -> AccountPool {
        let clock = self.clock!
        return AccountPool(source: source, clock: { clock.now }, maxSessions: maxSessions)
    }

    /// Routing settings for `keys` at the 0.95 ceiling; the tuning rows default as stored.
    private func settings(_ keys: [String], cooldown: Int = 60, expiryMargin: Int = 300,
                          sticky: Bool = true) -> AccountRouterSettings {
        var settings = AccountRouterSettings(enabled: true, accounts: keys, fiveHourCeiling: 0.95)
        settings.cooldownSeconds = cooldown
        settings.expiryMarginSeconds = expiryMargin
        settings.sticky = sticky
        return settings
    }

    private func reading(_ name: String, kind: String = "oauth", five: Double? = nil,
                         seven: Double? = nil, sevenReset: Int? = nil) -> Sessions.AccountQuotaReadingDTO {
        Sessions.AccountQuotaReadingDTO(account: name, credentialKind: kind, fiveHourPct: five,
                            sevenDayPct: seven, sevenDayResetsAt: sevenReset)
    }

    func testRanksHeldAccountsAndHandsOutTheChosenToken() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.hold("oauth:b@x.com", token: "sk-ant-oat01-b")
        source.setReading(reading("a@x.com", seven: 50, sevenReset: Int(start) + 100 * 3600))
        source.setReading(reading("b@x.com", seven: 20, sevenReset: Int(start) + 10 * 3600))
        let decision = pool().decide(sessionId: "s1", settings: settings(["oauth:a@x.com", "oauth:b@x.com"]))
        XCTAssertEqual(decision.rule, "ranked")
        XCTAssertEqual(decision.choice?.account, "oauth:b@x.com")
        XCTAssertEqual(decision.choice?.token, "sk-ant-oat01-b")
        XCTAssertEqual(decision.choice?.credentialKind, "oauth")
    }

    func testPercentReadingsBecomeFractionsAgainstTheCeiling() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.setReading(reading("a@x.com", five: 96))
        let decision = pool().decide(sessionId: nil, settings: settings(["oauth:a@x.com"]))
        XCTAssertNil(decision.choice)
        XCTAssertEqual(decision.rule, "all-ineligible")
    }

    func testAnUnheldOrNearlyExpiredTokenIsUnavailableAndCools() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a", expiresAt: start + 299)
        let pool = pool()
        let keys = ["oauth:a@x.com", "oauth:missing@x.com"]
        XCTAssertNil(pool.decide(sessionId: nil, settings: settings(keys)).choice)
        let snapshot = pool.snapshot(settings: settings(keys))
        XCTAssertEqual(snapshot.map(\.held), [true, false])
        XCTAssertEqual(snapshot.map(\.available), [false, false])
        XCTAssertEqual(snapshot.map(\.coolingDownFor), [60, 60])
    }

    func testATokenArrivingEndsItsNoTokenCooldown() {
        let pool = pool()
        let keys = ["oauth:a@x.com"]
        XCTAssertNil(pool.decide(sessionId: nil, settings: settings(keys)).choice)
        XCTAssertEqual(pool.snapshot(settings: settings(keys)).map(\.coolingDownFor), [60])
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        XCTAssertEqual(pool.snapshot(settings: settings(keys)).map(\.coolingDownFor), [nil])
        XCTAssertEqual(pool.decide(sessionId: nil, settings: settings(keys)).choice?.account, "oauth:a@x.com")
    }

    func testA429CooldownOutlastsTheTokenArriving() {
        let pool = pool()
        let keys = ["oauth:a@x.com"]
        _ = pool.decide(sessionId: nil, settings: settings(keys))
        pool.observe(account: "oauth:a@x.com", status: 429, headers: [:], cooldown: 60)
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        XCTAssertNil(pool.decide(sessionId: nil, settings: settings(keys)).choice)
    }

    func testATokenWithMoreThanTheMarginLeftOrNoExpiryIsAvailable() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a", expiresAt: start + 301)
        source.hold("long-lived:b", token: "sk-ant-oat01-b")
        let snapshot = pool().snapshot(settings: settings(["oauth:a@x.com", "long-lived:b"]))
        XCTAssertEqual(snapshot.map(\.available), [true, true])
    }

    func testStickinessAndTheSharedNilSession() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.hold("oauth:b@x.com", token: "sk-ant-oat01-b")
        let pool = pool()
        let keys = ["oauth:a@x.com", "oauth:b@x.com"]
        XCTAssertEqual(pool.decide(sessionId: nil, settings: settings(keys)).choice?.account, "oauth:a@x.com")
        source.setReading(reading("b@x.com", seven: 0, sevenReset: Int(start) + 3600))
        let again = pool.decide(sessionId: nil, settings: settings(keys))
        XCTAssertEqual(again.choice?.account, "oauth:a@x.com")
        XCTAssertEqual(again.rule, "sticky")
        XCTAssertEqual(pool.decide(sessionId: "fresh", settings: settings(keys)).rule, "ranked")
    }

    func test429CoolsTheAccountAndTheSessionSwitches() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.hold("oauth:b@x.com", token: "sk-ant-oat01-b")
        let pool = pool()
        let keys = ["oauth:a@x.com", "oauth:b@x.com"]
        _ = pool.decide(sessionId: "s1", settings: settings(keys))
        pool.observe(account: "oauth:a@x.com", status: 429, headers: [:], cooldown: 60)
        let switched = pool.decide(sessionId: "s1", settings: settings(keys))
        XCTAssertEqual(switched.choice?.account, "oauth:b@x.com")
        XCTAssertEqual(switched.rule, "switched: oauth:a@x.com ineligible")
        clock.advance(61)
        pool.observe(account: "oauth:b@x.com", status: 401, headers: [:], cooldown: 60)
        XCTAssertEqual(pool.decide(sessionId: "s2", settings: settings(keys)).choice?.account, "oauth:a@x.com")
    }

    func testObserveForwardsHeadersByAccountNameAndKind() {
        let pool = pool()
        pool.observe(account: "long-lived:ci", status: 200,
                     headers: ["anthropic-ratelimit-unified-5h-utilization": "0.1"], cooldown: 60)
        XCTAssertEqual(source.observed, [FakeQuotaSource.Observation(
            account: "ci", credentialKind: "long-lived",
            headers: ["anthropic-ratelimit-unified-5h-utilization": "0.1"])])
    }

    func testOrganizationIdIsTheFirstSeen() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        let pool = pool()
        pool.observe(account: "oauth:a@x.com", status: 200, headers: ["anthropic-organization-id": "org-1"],
                     cooldown: 60)
        pool.observe(account: "oauth:a@x.com", status: 200, headers: ["anthropic-organization-id": "org-2"],
                     cooldown: 60)
        let entry = pool.snapshot(settings: settings(["oauth:a@x.com"])).first
        XCTAssertEqual(entry?.organizationId, "org-1")
        // A 200 is not a reason to cool.
        XCTAssertEqual(entry?.available, true)
        XCTAssertNil(entry?.coolingDownFor)
    }

    func testATokenExactlyTheMarginFromExpiryIsUnavailable() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a", expiresAt: start + 300)
        XCTAssertEqual(pool().snapshot(settings: settings(["oauth:a@x.com"])).map(\.available), [false])
    }

    func testTheCooldownComesFromTheSettings() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        let pool = pool()
        let tuned = settings(["oauth:a@x.com"], cooldown: 5)
        _ = pool.decide(sessionId: "s1", settings: tuned)
        pool.observe(account: "oauth:a@x.com", status: 429, headers: [:], cooldown: tuned.cooldownSeconds)
        XCTAssertEqual(pool.snapshot(settings: tuned).first?.coolingDownFor, 5)
        XCTAssertNil(pool.decide(sessionId: "s1", settings: tuned).choice)
        clock.advance(5.001)
        let entry = pool.snapshot(settings: tuned).first
        XCTAssertNil(entry?.coolingDownFor)
        XCTAssertEqual(entry?.available, true)
        XCTAssertEqual(pool.decide(sessionId: "s1", settings: tuned).choice?.account, "oauth:a@x.com")
    }

    func testClearCooldownsMakesACoolingEntryEligibleAtOnce() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        let pool = pool()
        let keys = settings(["oauth:a@x.com"])
        _ = pool.decide(sessionId: "s1", settings: keys)
        pool.observe(account: "oauth:a@x.com", status: 429, headers: [:], cooldown: 60)
        XCTAssertEqual(pool.snapshot(settings: keys).first?.coolingDownFor, 60)
        XCTAssertNil(pool.decide(sessionId: "s1", settings: keys).choice)

        pool.clearCooldowns()

        let entry = pool.snapshot(settings: keys).first
        XCTAssertNil(entry?.coolingDownFor)
        XCTAssertEqual(entry?.eligible, true)
        XCTAssertEqual(pool.decide(sessionId: "s1", settings: keys).choice?.account, "oauth:a@x.com")
    }

    func testClearCooldownsKeepsSessionsAndOrganizations() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        let pool = pool()
        let keys = settings(["oauth:a@x.com"])
        _ = pool.decide(sessionId: "s1", settings: keys)
        pool.observe(account: "oauth:a@x.com", status: 429, headers: ["anthropic-organization-id": "org-1"],
                     cooldown: 60)
        pool.clearCooldowns()
        let entry = pool.snapshot(settings: keys).first
        XCTAssertEqual(entry?.sessions, 1)
        XCTAssertEqual(entry?.organizationId, "org-1")
    }

    func testAnUnusableEntryCoolsForTheConfiguredCooldown() {
        let pool = pool()
        let tuned = settings(["oauth:missing@x.com"], cooldown: 7)
        XCTAssertNil(pool.decide(sessionId: nil, settings: tuned).choice)
        XCTAssertEqual(pool.snapshot(settings: tuned).first?.coolingDownFor, 7)
    }

    func testTheExpiryMarginComesFromTheSettings() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a", expiresAt: start + 10)
        XCTAssertEqual(pool().decide(sessionId: "s1", settings: settings(["oauth:a@x.com"], expiryMargin: 0))
            .choice?.account, "oauth:a@x.com", "a margin of 0 hands out a token with 10 s left")
        XCTAssertNil(pool().decide(sessionId: "s1", settings: settings(["oauth:a@x.com"], expiryMargin: 300)).choice,
                     "a margin of 300 holds back a token with 10 s left")
    }

    func testStickyOffRanksEveryRequestAndStillCountsSessions() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.hold("oauth:b@x.com", token: "sk-ant-oat01-b")
        let pool = pool()
        let keys = ["oauth:a@x.com", "oauth:b@x.com"]
        let loose = settings(keys, sticky: false)
        XCTAssertEqual(pool.decide(sessionId: "A", settings: loose).choice?.account, "oauth:a@x.com")
        XCTAssertEqual(pool.decide(sessionId: "B", settings: loose).choice?.account, "oauth:a@x.com")
        source.setReading(reading("b@x.com", seven: 0, sevenReset: Int(start) + 3600))
        let next = pool.decide(sessionId: "A", settings: loose)
        XCTAssertEqual(next.choice?.account, "oauth:b@x.com")
        XCTAssertEqual(next.rule, "ranked")
        XCTAssertEqual(pool.snapshot(settings: loose).map(\.sessions), [1, 1])
        XCTAssertEqual(pool.decide(sessionId: "B", settings: settings(keys)).rule, "sticky",
                       "sticky back on keeps B where it was")
    }

    func testConcurrentDecideAndObserveStayConsistent() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        source.hold("oauth:b@x.com", token: "sk-ant-oat01-b")
        let pool = pool(maxSessions: 64)
        let keys = ["oauth:a@x.com", "oauth:b@x.com"]
        let routing = settings(keys)
        DispatchQueue.concurrentPerform(iterations: 2_000) { index in
            let decision = pool.decide(sessionId: "s\(index % 200)", settings: routing)
            if let account = decision.choice?.account {
                pool.observe(account: account, status: 200, headers: ["anthropic-organization-id": "org-\(index)"],
                             cooldown: 60)
            }
        }
        let snapshot = pool.snapshot(settings: settings(keys))
        XCTAssertEqual(snapshot.map(\.available), [true, true])
        XCTAssertLessThanOrEqual(snapshot.map(\.sessions).reduce(0, +), 64)
    }

    func testSessionsAreBoundedLeastRecentlyUsedFirst() {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a")
        let pool = pool(maxSessions: 2)
        let keys = ["oauth:a@x.com"]
        _ = pool.decide(sessionId: "s1", settings: settings(keys))
        _ = pool.decide(sessionId: "s2", settings: settings(keys))
        _ = pool.decide(sessionId: "s1", settings: settings(keys))
        _ = pool.decide(sessionId: "s3", settings: settings(keys))
        XCTAssertEqual(pool.snapshot(settings: settings(keys)).first?.sessions, 2)
        XCTAssertEqual(pool.decide(sessionId: "s1", settings: settings(keys)).rule, "sticky")
        XCTAssertEqual(pool.decide(sessionId: "s2", settings: settings(keys)).rule, "ranked", "s2 was evicted")
    }

    func testNoDecisionAssignsNothing() {
        let pool = pool()
        XCTAssertEqual(pool.decide(sessionId: "s1", settings: settings([])).rule, "all-ineligible")
        XCTAssertTrue(pool.snapshot(settings: settings([])).isEmpty)
    }

    func testSnapshotIsSecretFreeAndChoiceIsRedacted() throws {
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-secret")
        source.setReading(reading("a@x.com", five: 40, seven: 10))
        let pool = pool()
        let decision = pool.decide(sessionId: "s1", settings: settings(["oauth:a@x.com"]))
        let entry = try XCTUnwrap(pool.snapshot(settings: settings(["oauth:a@x.com"])).first)
        XCTAssertEqual(entry.fiveHourUtilization ?? -1, 0.4, accuracy: 1e-9)
        XCTAssertEqual(entry.sevenDayUtilization ?? -1, 0.1, accuracy: 1e-9)
        XCTAssertTrue(entry.eligible)
        XCTAssertEqual(entry.sessions, 1)
        let json = try XCTUnwrap(String(bytes: JSONEncoder().encode(entry), encoding: .utf8))
        XCTAssertFalse(json.contains("sk-ant-"))
        let choice = try XCTUnwrap(decision.choice)
        XCTAssertFalse(String(describing: choice).contains("sk-ant-"))
        XCTAssertFalse(String(reflecting: choice).contains("sk-ant-"))
        XCTAssertFalse(String(describing: decision).contains("sk-ant-"))
    }
}
