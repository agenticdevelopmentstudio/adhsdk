import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The planner's rule table, without a network: what each kind of request is
/// planned as, what a retry is planned as, and what gets observed.
final class AccountRoutingPlannerTests: XCTestCase {
    private final class SettingsBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored = AccountRouterSettings()
        var value: AccountRouterSettings {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    private var source: FakeQuotaSource!
    private var box: SettingsBox!
    private var planner: AccountRoutingPlanner!
    private var pool: AccountPool!
    private var tmpDir: URL!
    private var fingerprints: String!

    override func setUpWithError() throws {
        source = FakeQuotaSource()
        box = SettingsBox()
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("router-fingerprints-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        fingerprints = tmpDir.appendingPathComponent("fingerprints.json").path
        let box = self.box!
        pool = AccountPool(source: source)
        planner = AccountRoutingPlanner(
            settings: { box.value },
            fence: CredentialFence(source: source, fingerprintsPath: fingerprints),
            pool: pool)
        source.hold("oauth:pool@x.com", token: "sk-ant-oat01-pool")
        source.hold("oauth:me@x.com", token: "sk-ant-oat01-mine")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func enable(_ accounts: [String] = ["oauth:pool@x.com"]) {
        box.value = AccountRouterSettings(enabled: true, accounts: accounts, fiveHourCeiling: 0.95)
    }

    private func head(_ method: String, _ target: String, _ fields: [(String, String)]) -> RouterRequestHead {
        RouterRequestHead(method: method, target: target, version: "HTTP/1.1",
                          fields: fields.map { HTTPHeaderField(name: $0.0, value: $0.1) })
    }

    /// `POST /v1/messages`, the common case.
    private func head(_ fields: [(String, String)]) -> RouterRequestHead {
        head("POST", "/v1/messages", fields)
    }

    private func bearer(_ token: String) -> [(String, String)] {
        [("Authorization", "Bearer \(token)"), ("X-Claude-Code-Session-Id", "s1")]
    }

    func testRoutingOffIsVerbatimWithANullRule() {
        XCTAssertEqual(planner.plan(head(bearer("sk-ant-oat01-mine"))), .verbatim)
    }

    func testRequestsThatCannotBeRoutedSaySo() {
        enable()
        let notRoutable = ExchangePlan(account: nil, bearer: nil, rule: "passthrough: not routable")
        XCTAssertEqual(planner.plan(head("GET", "/v1/models", bearer("sk-ant-oat01-mine"))), notRoutable)
        XCTAssertEqual(planner.plan(head(bearer("sk-ant-api03-key"))), notRoutable)
        XCTAssertEqual(planner.plan(head(bearer("sk-ant-oat01-mine") + [("x-api-key", "k")])), notRoutable)
        XCTAssertEqual(planner.plan(head("POST", "/v1/messages/../x", bearer("sk-ant-oat01-mine"))), notRoutable)
    }

    func testAForgedTokenIsFencedBeforeThePool() {
        enable()
        let plan = planner.plan(head(bearer("sk-ant-oat01-forged")))
        XCTAssertEqual(plan, ExchangePlan(account: nil, bearer: nil, rule: "passthrough: unknown credential"))
    }

    func testAnOwnedTokenIsRoutedToThePool() {
        enable()
        let plan = planner.plan(head(bearer("sk-ant-oat01-mine")))
        XCTAssertEqual(plan, ExchangePlan(account: "oauth:pool@x.com", bearer: "sk-ant-oat01-pool", rule: "ranked"))
    }

    func testAnEmptyPoolIsVerbatimWithThePolicysRule() {
        enable([])
        let plan = planner.plan(head(bearer("sk-ant-oat01-mine")))
        XCTAssertEqual(plan, ExchangePlan(account: nil, bearer: nil, rule: "all-ineligible"))
    }

    func testRetryWithRoutingOffIsVerbatimWithANullRule() {
        let plan = planner.replan(head(bearer("sk-ant-oat01-mine")), after: "oauth:pool@x.com", status: 429)
        XCTAssertEqual(plan, .verbatim)
    }

    func testRetryOfAForgedBearerIsFencedLikeAFirstAttempt() {
        enable(["oauth:pool@x.com", "oauth:me@x.com"])
        let plan = planner.replan(head(bearer("sk-ant-oat01-forged")), after: "oauth:pool@x.com", status: 429)
        XCTAssertNil(plan.account)
        XCTAssertNil(plan.bearer)
        XCTAssertEqual(plan.rule, "passthrough: unknown credential (retry after oauth:pool@x.com 429)")
        XCTAssertEqual(planner.plan(head(bearer("sk-ant-oat01-mine"))).rule, "ranked",
                       "the forged retry left no session assignment behind")
    }

    func testRetryOfANotRoutableRequestIsVerbatim() {
        enable()
        let request = head(bearer("sk-ant-oat01-mine") + [("x-api-key", "k")])
        let plan = planner.replan(request, after: "oauth:pool@x.com", status: 401)
        XCTAssertEqual(plan, ExchangePlan(
            account: nil, bearer: nil, rule: "passthrough: not routable (retry after oauth:pool@x.com 401)"))
    }

    func testRetryDecidesAgainAndAppendsTheReason() {
        enable(["oauth:pool@x.com", "oauth:me@x.com"])
        let request = head(bearer("sk-ant-oat01-mine"))
        let first = planner.plan(request)
        XCTAssertEqual(first.account, "oauth:pool@x.com")
        planner.observe(first, head: UpstreamHead(status: 429, headers: [:]))
        let retry = planner.replan(request, after: "oauth:pool@x.com", status: 429)
        XCTAssertEqual(retry.account, "oauth:me@x.com")
        XCTAssertEqual(retry.rule, "switched: oauth:pool@x.com ineligible (retry after oauth:pool@x.com 429)")
    }

    func testAllowsRetryFollowsTheSettings() {
        XCTAssertTrue(planner.allowsRetry(), "retry is on by default")
        box.value.retry = false
        XCTAssertFalse(planner.allowsRetry())
        box.value.retry = true
        XCTAssertTrue(planner.allowsRetry())
        XCTAssertFalse(VerbatimPlanner().allowsRetry())
    }

    func testObserveCoolsForTheConfiguredCooldown() {
        enable(["oauth:pool@x.com", "oauth:me@x.com"])
        box.value.cooldownSeconds = 5
        let request = head(bearer("sk-ant-oat01-mine"))
        let first = planner.plan(request)
        XCTAssertEqual(first.account, "oauth:pool@x.com")
        planner.observe(first, head: UpstreamHead(status: 429, headers: [:]))
        let cooling = pool.snapshot(settings: box.value).first { $0.account == "oauth:pool@x.com" }
        XCTAssertEqual(cooling?.coolingDownFor, 5)
    }

    func testOnlyRoutedPlansAreObserved() {
        let headers = ["anthropic-ratelimit-unified-5h-utilization": "0.4"]
        planner.observe(.verbatim, head: UpstreamHead(status: 200, headers: headers))
        XCTAssertTrue(source.observed.isEmpty)
        planner.observe(ExchangePlan(account: "oauth:pool@x.com", bearer: "sk-ant-oat01-pool", rule: "ranked"),
                        head: UpstreamHead(status: 200, headers: headers))
        XCTAssertEqual(source.observed, [FakeQuotaSource.Observation(
            account: "pool@x.com", credentialKind: "oauth", headers: headers)])
    }
}
