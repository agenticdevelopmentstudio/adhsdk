import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Which topics the Browser settings list, in what order, and that a control
/// moved to a new topic keeps its key and is still found by search (the Web
/// Browser Settings Topics recipe: `topic-order`, `removed-topics`,
/// `keys-never-change`, `open-sites-in-tabs-rename`, `keywords-follow-controls`,
/// `container-keywords-union`). Asserted through the panel's topics, rows and
/// keywords, never pixels.
@MainActor
final class BrowserSettingsTopicLayoutTests: XCTestCase {

    // MARK: - Fixtures

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    /// The Settings window's panel, Chrome compiled out (no engine handed
    /// in), with every topic's view loaded so every row exists.
    private func makePanel(settings: SettingsStore) -> BrowserSettingsPanelViewController {
        let panel = BrowserSettingsPanelViewController(
            history: nil,
            siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: settings
        )
        _ = panel.view
        panel.panels.forEach { _ = $0.view }
        return panel
    }

    private func topicTitles(of panel: BrowserSettingsPanelViewController) -> [String] {
        panel.panels.map(\.descriptor.title)
    }

    // MARK: - Tests

    /// browser-settings-001. "Extensions" is the Safari engine's extensions
    /// topic, listed only where extensions are available, so the expected
    /// list follows that.
    func test_topicOrder() {
        let panel = makePanel(settings: makeSettings())
        var expected = ["General", "Behavior", "Appearance", "Privacy and Security", "Downloads"]
        if panel.safariExtensionsAvailable { expected.append("Extensions") }
        expected.append("Reset")
        XCTAssertEqual(topicTitles(of: panel), expected)
    }

    /// browser-settings-003: the renamed row in Behavior writes the old key.
    func test_openSitesInTabsKeepsKey() throws {
        let settings = makeSettings()
        let panel = makePanel(settings: settings)
        let key = UserSettings.browserNewOpensTabs
        XCTAssertEqual(key.name, "browser.new_opens_tabs")

        let rows = panel.binding.rows(named: key.name)
        XCTAssertEqual(rows.count, 1, "one Open sites in tabs row, in the Settings window")
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.group, "Windows")
        let model = try XCTUnwrap(row.model as? ComposableSettings.ViewModel<Bool>)
        XCTAssertEqual(model.title, "Open sites in tabs")

        let behavior = try XCTUnwrap(panel.panels.first { $0.descriptor.title == "Behavior" })
        XCTAssertTrue(row.view.isDescendant(of: behavior.view), "the row is in the Behavior topic")

        XCTAssertFalse(settings.get(key))
        model.settingObserver.value = true
        XCTAssertTrue(settings.get(key))
    }

    /// keywords-follow-controls and container-keywords-union: the container
    /// lists its topics' words before any topic is opened, moved controls
    /// included.
    func test_searchFindsMovedControls() {
        let panel = BrowserSettingsPanelViewController(
            history: nil,
            siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: makeSettings()
        )
        let keywords = Set(panel.searchKeywords)
        for word in ["Autoplay", "Zoom", "Web Inspector", "Open sites in tabs"] {
            XCTAssertTrue(keywords.contains(word), "search does not find \(word)")
        }
    }

    /// browser-settings-002 (the Safari half).
    func test_noSafariTopic() {
        let panel = makePanel(settings: makeSettings())
        XCTAssertFalse(topicTitles(of: panel).contains("Safari"))
        // extensions-topic-001: the extensions topic was renamed.
        XCTAssertFalse(topicTitles(of: panel).contains("Safari Extensions"))
    }

    /// The titles of the cards a topic shows, top to bottom. A card inside a
    /// card is not walked into.
    private func groupTitles(in view: NSView) -> [String] {
        view.subviews.flatMap { subview -> [String] in
            if let group = subview as? ComposableSettings.GroupView { return [group.title ?? ""] }
            return groupTitles(in: subview)
        }
    }

    /// privacy-and-security-groups, keys-never-change and
    /// manage-site-data-button: the topic's own groups stay where they were,
    /// the five moved ones follow in order, every moved row keeps its key and
    /// its group, and Site Data is one button with no table inline.
    func test_privacyAndSecurityGroups() throws {
        let panel = makePanel(settings: makeSettings())
        let privacy = try XCTUnwrap(panel.panels.first { $0.descriptor.title == "Privacy and Security" })

        XCTAssertEqual(groupTitles(in: privacy.view), [
            "General", "Input", "Focus and visibility", "Coding Partner", "Agent Privacy", "Storage", "Scripts",
            "Cookies", "Camera and Microphone", "Protection", "Site Data", "History"
        ])

        let moved: [(key: String, group: String)] = [
            (UserSettings.browserAcceptsCookies.name, "Cookies"),
            (UserSettings.browserPrivateBrowsing.name, "Cookies"),
            (UserSettings.browserMediaCapture.name, "Camera and Microphone"),
            (UserSettings.browserFraudWarning.name, "Protection"),
            (UserSettings.browserUpgradesToHTTPS.name, "Protection"),
            (UserSettings.browserLockdownMode.name, "Protection"),
            (UserSettings.browserRecordsHistory.name, "History"),
            (UserSettings.browserHistoryRetention.name, "History")
        ]
        for (key, group) in moved {
            let rows = panel.binding.rows(named: key)
            XCTAssertEqual(rows.count, 1, "one row for \(key)")
            XCTAssertEqual(rows.first?.group, group, "\(key) is in \(group)")
            if let row = rows.first {
                XCTAssertTrue(row.view.isDescendant(of: privacy.view), "\(key) is in Privacy and Security")
            }
        }
        // History's rows in order (history-group-contents).
        let historyRows = panel.binding.rows.filter { $0.group == "History" }.map(\.name)
        XCTAssertEqual(historyRows, [
            UserSettings.browserRecordsHistory.name, UserSettings.browserHistoryRetention.name,
            UserSettings.browserAgentHistoryAccess.name
        ])

        XCTAssertNotNil(panel.binding.buttons["settings.browser.site-data.manage"])
        func tables(in view: NSView) -> Int {
            view.subviews.reduce(view is ComposableSettings.EditableTableCard ? 1 : 0) { $0 + tables(in: $1) }
        }
        XCTAssertEqual(tables(in: privacy.view), 0, "the site data table is in its own window")

        let keywords = Set(BrowserPrivacySettingsPanel.keywords)
        for word in ["Accept cookies", "Private browsing", "When a page asks", "Warn about fraudulent websites",
                     "Upgrade known sites to HTTPS", "Lockdown Mode", "Manage Site Data…", "Record history",
                     "Keep visits for"] {
            XCTAssertTrue(keywords.contains(word), "Privacy and Security's keywords miss \(word)")
            XCTAssertTrue(panel.searchKeywords.contains(word), "search does not find \(word)")
        }
    }

    /// removed-topics: History, Cookies, Media and Permissions and Safari are
    /// no longer topics, and Privacy is Privacy and Security.
    func test_removedTopicsAreGone() {
        let titles = topicTitles(of: makePanel(settings: makeSettings()))
        for removed in ["History", "Cookies", "Global Cookies", "Media and Permissions", "Safari", "Privacy"] {
            XCTAssertFalse(titles.contains(removed), "\(removed) is still a topic")
        }
        XCTAssertFalse(titles.contains { $0.hasPrefix("Cookies") }, "no per-jar Cookies topic")
        XCTAssertTrue(titles.contains("Privacy and Security"))
    }
}
