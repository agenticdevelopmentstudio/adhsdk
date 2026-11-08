import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A rule-list source that holds every request until the test releases it,
/// so the order compiles finish in is the test's to choose.
@MainActor
private final class GatedRuleLists {
    private(set) var requested: [BrowserThirdPartyContent] = []
    private(set) var finished = 0
    private var gates: [CheckedContinuation<Void, Never>?] = []

    func provide(_ policy: BrowserThirdPartyContent) async throws -> WKContentRuleList? {
        requested.append(policy)
        await withCheckedContinuation { gates.append($0) }
        defer { finished += 1 }
        return try await BrowserContentRules.ruleList(for: policy)
    }

    func release(_ index: Int) {
        gates[index]?.resume()
        gates[index] = nil
    }
}

private struct CompileFailed: Error {}

@MainActor
final class BrowserContentRulesTests: XCTestCase {

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    /// The one rule in `policy`'s JSON, decoded.
    private func onlyRule(_ policy: BrowserThirdPartyContent) throws -> [String: Any] {
        let json = try XCTUnwrap(BrowserContentRules.json(for: policy))
        let rules = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]])
        XCTAssertEqual(rules.count, 1)
        return try XCTUnwrap(rules.first)
    }

    /// Polls, with a deadline, until `condition` holds. Settings changes and
    /// finished compiles reach the pane on the main queue, which this yields.
    private func waitUntil(_ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, !condition() {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitForRules(_ policy: BrowserThirdPartyContent, on pane: SafariBrowserPaneViewController) async {
        await waitUntil { pane.appliedThirdPartyContent == policy }
    }

    /// A pane on `.allow` whose later rule requests go through `gated`.
    private func gatedPane(_ settings: SettingsStore, _ gated: GatedRuleLists) -> SafariBrowserPaneViewController {
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        pane.contentRuleListProvider = { try await gated.provide($0) }
        return pane
    }

    // MARK: - Rules

    func testAllowHasNoRules() {
        XCTAssertNil(BrowserContentRules.json(for: .allow))
    }

    func testBlockScriptsJSON() throws {
        let rule = try onlyRule(.blockScripts)
        let trigger = try XCTUnwrap(rule["trigger"] as? [String: Any])
        XCTAssertEqual(trigger["url-filter"] as? String, ".*")
        XCTAssertEqual(trigger["resource-type"] as? [String], ["script"])
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
        XCTAssertEqual((rule["action"] as? [String: Any])?["type"] as? String, "block")
    }

    func testBlockAllExcludesDocument() throws {
        let trigger = try XCTUnwrap(try onlyRule(.blockAll)["trigger"] as? [String: Any])
        let types = try XCTUnwrap(trigger["resource-type"] as? [String])
        XCTAssertEqual(types, [
            "image", "style-sheet", "script", "font", "raw", "svg-document",
            "media", "popup", "ping", "fetch", "websocket", "other", "child-document"
        ])
        XCTAssertFalse(types.contains("document"), "the page itself is never blocked")
        XCTAssertFalse(types.contains("top-document"), "the page itself is never blocked")
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
    }

    func testIdentifierIsTheValueAndAHashOfTheRules() throws {
        let json = try XCTUnwrap(BrowserContentRules.json(for: .blockScripts))
        let identifier = BrowserContentRules.identifier(for: .blockScripts, json: json)
        XCTAssertTrue(identifier.hasPrefix("adk.third-party.blockScripts."), identifier)
        let hash = identifier.dropFirst("adk.third-party.blockScripts.".count)
        XCTAssertEqual(hash.count, 12)
        XCTAssertTrue(hash.allSatisfy { $0.isHexDigit && !$0.isUppercase }, identifier)
    }

    func testDifferentRulesGetDifferentIdentifiers() {
        let first = BrowserContentRules.identifier(for: .blockAll, json: #"[{"a":1}]"#)
        let second = BrowserContentRules.identifier(for: .blockAll, json: #"[{"a":2}]"#)
        XCTAssertNotEqual(first, second, "a changed rule set must never reuse a stale compiled list")
    }

    func testTheSameRulesAlwaysGetTheSameIdentifier() {
        let json = #"[{"a":1}]"#
        XCTAssertEqual(
            BrowserContentRules.identifier(for: .blockAll, json: json),
            BrowserContentRules.identifier(for: .blockAll, json: json)
        )
    }

    func testRulesCompile() async throws {
        let allow = try await BrowserContentRules.ruleList(for: .allow)
        XCTAssertNil(allow)
        for policy in [BrowserThirdPartyContent.blockScripts, .blockAll] {
            let json = try XCTUnwrap(BrowserContentRules.json(for: policy))
            let expected = BrowserContentRules.identifier(for: policy, json: json)
            let list = try await BrowserContentRules.ruleList(for: policy)
            XCTAssertEqual(list?.identifier, expected)
            // The second ask is answered from the store.
            let again = try await BrowserContentRules.ruleList(for: policy)
            XCTAssertEqual(again?.identifier, expected)
        }
    }

    // MARK: - The pane

    func testPaneAppliesTheSettingAtConstruction() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        await waitForRules(.blockScripts, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts)
    }

    func testPaneFollowsTheSettingLive() async {
        let settings = makeSettings()
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertEqual(pane.appliedThirdPartyContent, .allow)

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitForRules(.blockAll, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockAll)

        settings.set(BrowserThirdPartyContent.allow, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitForRules(.allow, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .allow)
    }

    /// Two requests in flight, the newer finishing first: when the older one
    /// finishes afterwards, its result is dropped. Without the generation
    /// check the pane would end on `.blockAll`.
    func testALaterChangeWins() async {
        let settings = makeSettings()
        let gated = GatedRuleLists()
        let pane = gatedPane(settings, gated)

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 1 }
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 2 }
        XCTAssertEqual(gated.requested, [.blockAll, .blockScripts])

        gated.release(1)
        await waitForRules(.blockScripts, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts)

        gated.release(0)
        await waitUntil { pane.droppedContentRules == 1 }
        XCTAssertEqual(pane.droppedContentRules, 1, "the older compile came back and was dropped")
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts, "the older compile's result is dropped")
    }

    /// A rebuild while a compile is in flight: the old web view's compile
    /// goes with its engine, and the new web view gets the current policy
    /// from its own.
    func testARebuildDuringACompileEndsOnTheCurrentPolicy() async {
        let settings = makeSettings()
        let gated = GatedRuleLists()
        let pane = gatedPane(settings, gated)

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 1 }
        let oldWebView = pane.webView

        pane.rebuildEngine()
        XCTAssertFalse(pane.webView === oldWebView)
        await waitUntil { gated.requested.count == 2 }
        XCTAssertEqual(gated.requested, [.blockAll, .blockAll], "the new web view asks for its own list")

        gated.release(0)
        await Task.yield()
        XCTAssertEqual(pane.droppedContentRules, 0, "the new engine dropped nothing of its own")
        XCTAssertNil(pane.appliedThirdPartyContent, "the old web view's compile is not applied to the new one")

        gated.release(1)
        await waitForRules(.blockAll, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockAll)
    }

    func testARebuiltWebViewGetsTheRulesAgain() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        await waitForRules(.blockAll, on: pane)

        pane.rebuildEngine()
        XCTAssertNil(pane.appliedThirdPartyContent, "a new web view starts with no rule lists")
        await waitForRules(.blockAll, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockAll)
    }

    /// Fail open: a failed compile releases the held load, leaves no rules
    /// claimed, and is tried again on the next settings change.
    func testAFailedCompileFailsOpenAndRetries() async {
        let settings = makeSettings()
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        var attempts = 0
        pane.contentRuleListProvider = { _ in
            attempts += 1
            throw CompileFailed()
        }

        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { attempts == 1 }
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotEqual(pane.appliedThirdPartyContent, .blockScripts)

        pane.contentRuleListProvider = { try await BrowserContentRules.ruleList(for: $0) }
        settings.set(1.1, for: UserSettings.browserPageZoom)
        await waitForRules(.blockScripts, on: pane)
        XCTAssertEqual(attempts, 1)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts, "the next settings change retried")
    }

    // MARK: - Held loads

    /// Under a blocking policy the first page waits for the rule list: when
    /// its navigation starts, the list is already on the web view.
    func testFirstNavigationStartsAfterTheRulesAreOn() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        let home = URL(string: "data:text/html,held")!
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings, homeURL: home)
        var rulesAtNavigation: [BrowserThirdPartyContent?] = []
        pane.onNavigationStart = { [unowned pane] in rulesAtNavigation.append(pane.appliedThirdPartyContent) }

        _ = pane.view
        XCTAssertTrue(pane.isHoldingLoad, "the first load waits for the compile")
        await waitUntil { !rulesAtNavigation.isEmpty }
        XCTAssertEqual(rulesAtNavigation.first, .blockScripts)
        XCTAssertFalse(pane.isHoldingLoad)
    }

    /// A failed compile still lets the held load go.
    func testAFailedCompileReleasesTheHeldLoad() async {
        let settings = makeSettings()
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        _ = pane.view
        let gated = GatedRuleLists()
        var failNext = true
        pane.contentRuleListProvider = { policy in
            if failNext {
                failNext = false
                _ = try await gated.provide(policy)
                throw CompileFailed()
            }
            return try await BrowserContentRules.ruleList(for: policy)
        }
        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 1 }

        let after = URL(string: "data:text/html,after")!
        pane.load(after)
        XCTAssertTrue(pane.isHoldingLoad)
        gated.release(0)
        await waitUntil { !pane.isHoldingLoad }
        XCTAssertFalse(pane.isHoldingLoad)
        await waitUntil { pane.webView.url == after }
        XCTAssertEqual(pane.webView.url, after, "the held load is what was released")
    }

    /// A stale failure, coming back after a newer request, neither forgets
    /// the newer request nor lets go of the load it still holds.
    func testAStaleFailureLeavesTheCurrentRequestAndItsHeldLoad() async {
        let settings = makeSettings()
        let gated = GatedRuleLists()
        let pane = gatedPane(settings, gated)
        _ = pane.view
        var calls = 0
        pane.contentRuleListProvider = { policy in
            calls += 1
            let first = calls == 1
            let list = try await gated.provide(policy)
            if first { throw CompileFailed() }
            return list
        }

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 1 }
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 2 }
        let held = URL(string: "data:text/html,still-held")!
        pane.load(held)
        XCTAssertTrue(pane.isHoldingLoad)

        gated.release(0)
        await waitUntil { pane.droppedContentRules == 1 }
        XCTAssertEqual(pane.droppedContentRules, 1, "the stale failure came back and was dropped")
        XCTAssertTrue(pane.isHoldingLoad, "the newer request still holds its load")
        // A forgotten request would be asked for again on the next change.
        settings.set(1.1, for: UserSettings.browserPageZoom)
        await waitUntil { abs(pane.webView.pageZoom - 1.1) < 0.001 }
        XCTAssertEqual(gated.requested.count, 2, "the current request was not forgotten")

        gated.release(1)
        await waitForRules(.blockScripts, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts)
        await waitUntil { pane.webView.url == held }
        XCTAssertEqual(pane.webView.url, held)
    }

    func testUnderAllowTheFirstLoadIsNotHeld() {
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: makeSettings())
        _ = pane.view
        XCTAssertFalse(pane.isHoldingLoad)
    }

    /// A rebuild under a blocking policy holds its load for the new web
    /// view's rules too.
    func testARebuildHoldsItsLoadForTheNewRules() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        let home = URL(string: "data:text/html,rebuilt")!
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings, homeURL: home)
        var rulesAtNavigation: [BrowserThirdPartyContent?] = []
        pane.onNavigationStart = { [unowned pane] in rulesAtNavigation.append(pane.appliedThirdPartyContent) }
        _ = pane.view
        // Let the first page start and finish, so nothing of it is counted
        // as the rebuilt web view's navigation.
        await waitUntil { !rulesAtNavigation.isEmpty }
        await waitUntil { !pane.webView.isLoading }
        rulesAtNavigation.removeAll()

        pane.rebuildEngine()
        XCTAssertTrue(pane.isHoldingLoad)
        await waitUntil { !rulesAtNavigation.isEmpty }
        XCTAssertEqual(rulesAtNavigation.first, .blockScripts)
    }

    /// A navigation held when the web view is rebuilt is carried to the new
    /// one: it, not the page the old web view was showing, is what loads.
    func testAHeldNavigationSurvivesARebuild() async {
        let settings = makeSettings()
        let gated = GatedRuleLists()
        let home = URL(string: "data:text/html,home")!
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings, homeURL: home)
        pane.contentRuleListProvider = { try await gated.provide($0) }
        _ = pane.view
        await waitUntil { pane.webView.url == home && !pane.webView.isLoading }

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitUntil { gated.requested.count == 1 }
        let held = URL(string: "data:text/html,held-across")!
        pane.load(held)
        XCTAssertTrue(pane.isHoldingLoad)

        var started: [URL?] = []
        pane.onNavigationStart = { [unowned pane] in started.append(pane.webView.url) }
        pane.rebuildEngine()
        XCTAssertTrue(pane.isHoldingLoad, "the rebuilt web view holds the load for its own rules")
        await waitUntil { gated.requested.count == 2 }
        gated.release(0)
        gated.release(1)
        await waitUntil { !started.isEmpty }
        XCTAssertEqual(started.first, held, "the held navigation, not the shown page, is what loads")
    }
}
