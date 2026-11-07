import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

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

    /// Polls, with a deadline, until the pane's rules are `policy`'s.
    private func waitForRules(_ policy: BrowserThirdPartyContent, on pane: BrowserPaneViewController) async {
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline, pane.appliedThirdPartyContent != policy {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

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
            "media", "popup", "ping", "fetch", "websocket", "other"
        ])
        XCTAssertFalse(types.contains("document"), "the page itself is never blocked")
        XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
    }

    func testIdentifiersAreNamedAfterTheValue() {
        XCTAssertEqual(BrowserContentRules.identifier(for: .blockScripts), "adk.third-party.blockScripts")
        XCTAssertEqual(BrowserContentRules.identifier(for: .blockAll), "adk.third-party.blockAll")
    }

    func testRulesCompile() async throws {
        let allow = try await BrowserContentRules.ruleList(for: .allow)
        XCTAssertNil(allow)
        for policy in [BrowserThirdPartyContent.blockScripts, .blockAll] {
            let list = try await BrowserContentRules.ruleList(for: policy)
            XCTAssertEqual(list?.identifier, BrowserContentRules.identifier(for: policy))
            // The second ask is answered from the store.
            let again = try await BrowserContentRules.ruleList(for: policy)
            XCTAssertEqual(again?.identifier, BrowserContentRules.identifier(for: policy))
        }
    }

    // MARK: - The pane

    func testPaneAppliesTheSettingAtConstruction() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        await waitForRules(.blockScripts, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts)
    }

    func testPaneFollowsTheSettingLive() async {
        let settings = makeSettings()
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertEqual(pane.appliedThirdPartyContent, .allow)

        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitForRules(.blockAll, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockAll)

        settings.set(BrowserThirdPartyContent.allow, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitForRules(.allow, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .allow)
    }

    /// Two changes in a row: whichever compile finishes last, the pane ends on
    /// the newer value, because the older request's result is dropped.
    func testALaterChangeWins() async {
        let settings = makeSettings()
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        settings.set(BrowserThirdPartyContent.blockScripts, for: UserSettings.browserPrivacyThirdPartyContent)
        await waitForRules(.blockScripts, on: pane)
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockScripts)
    }

    func testARebuiltWebViewGetsTheRulesAgain() async {
        let settings = makeSettings()
        settings.set(BrowserThirdPartyContent.blockAll, for: UserSettings.browserPrivacyThirdPartyContent)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        await waitForRules(.blockAll, on: pane)

        pane.rebuildWebView()
        XCTAssertNil(pane.appliedThirdPartyContent, "a new web view starts with no rule lists")
        await waitForRules(.blockAll, on: pane)
        XCTAssertEqual(pane.appliedThirdPartyContent, .blockAll)
    }
}
