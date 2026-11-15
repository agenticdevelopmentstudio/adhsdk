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
    }
}
