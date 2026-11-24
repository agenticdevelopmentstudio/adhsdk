import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Extensions topic of the Web Browser panel: which profile it lists,
/// and that each control reaches Chrome through `BrowserEngineMaintenance`.
@MainActor
final class ChromeExtensionsTopicTests: XCTestCase {

    /// Records every call; answers `extensions(in:)` with `installed`, or
    /// throws `failure` when set.
    @MainActor
    private final class FakeMaintenance: BrowserEngineMaintenance {
        var engineVersion: String { "test" }
        var installed: [BrowserExtension] = []
        var failure: Error?
        private(set) var calls: [String] = []

        func removeAllCookies() async {}

        func extensions(in profile: BrowserExtensionProfile) async throws -> [BrowserExtension] {
            calls.append("list \(profile)")
            if let failure { throw failure }
            return installed
        }

        func setExtension(_ id: String, enabled: Bool, in profile: BrowserExtensionProfile) async throws {
            calls.append("set \(id) \(enabled) \(profile)")
        }

        func removeExtension(_ id: String, in profile: BrowserExtensionProfile) async throws {
            calls.append("remove \(id) \(profile)")
        }

        func checkForExtensionUpdates(in profile: BrowserExtensionProfile) async throws {
            calls.append("update \(profile)")
        }

        func endExtensionManagement() {
            calls.append("end")
        }
    }

    private func item(_ id: String = "abc", enabled: Bool = true) -> BrowserExtension {
        BrowserExtension(
            id: id, name: "JSON Formatter", version: "0.7.1", summary: "", isEnabled: enabled,
            isFromWebStore: true, iconPNG: nil, optionsURL: URL(string: "chrome-extension://\(id)/options.html"))
    }

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makePanel(
        _ fake: FakeMaintenance, scope: BrowserSettingsScope = .global
    ) -> BrowserSettingsPanelViewController {
        let panel = BrowserSettingsPanelViewController(
            history: nil, siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: makeSettings(), scope: scope, chrome: fake)
        _ = panel.view
        panel.panels.forEach { _ = $0.view }
        return panel
    }

    private func topic(in panel: BrowserSettingsPanelViewController) -> ChromeExtensionsTopicPanel? {
        panel.panels.lazy.compactMap { $0 as? ChromeExtensionsTopicPanel }.first
    }

    /// The topic, loaded and with its first read finished.
    private func loadedTopic(_ fake: FakeMaintenance) async throws -> ChromeExtensionsTopicPanel {
        let topic = try XCTUnwrap(topic(in: makePanel(fake)))
        topic.reload()
        await topic.reloadTask?.value
        return topic
    }

    private func text(_ cell: ComposableSettings.EditableTableCellValue?) -> String? {
        if case .text(let value) = cell { return value }
        return nil
    }

    private func toggle(_ cell: ComposableSettings.EditableTableCellValue?) -> Bool? {
        if case .toggle(let value) = cell { return value }
        return nil
    }

    private func settle(_ topic: ChromeExtensionsTopicPanel) async {
        await topic.changeTask?.value
        await topic.reloadTask?.value
    }

    // MARK: - Tests

    func test_globalScopeListsGlobalProfile() async throws {
        let fake = FakeMaintenance()
        fake.installed = [item()]
        let topic = try await loadedTopic(fake)

        XCTAssertEqual(topic.profile, .global)
        XCTAssertEqual(fake.calls.last, "list global")
        let row = try XCTUnwrap(topic.table?.rows.first)
        XCTAssertEqual(row.id, "abc")
        XCTAssertEqual(text(row.cells["name"]), "JSON Formatter")
        XCTAssertEqual(text(row.cells["source"]), "Chrome Web Store")
        XCTAssertEqual(toggle(row.cells["enabled"]), true)
    }

    func test_toggleCallsSetEnabled() async throws {
        let fake = FakeMaintenance()
        fake.installed = [item()]
        let topic = try await loadedTopic(fake)

        topic.table?.onToggle?("abc", "enabled", false)
        await settle(topic)

        XCTAssertTrue(fake.calls.contains("set abc false global"))
        XCTAssertEqual(fake.calls.last, "list global", "the list is re-read after the change")
    }

    func test_removeConfirmsBeforeRemoving() async throws {
        let fake = FakeMaintenance()
        fake.installed = [item()]
        let topic = try await loadedTopic(fake)
        var asked: [String] = []
        var answer = false
        topic.confirmRemoval = { ext, completion in
            asked.append(ext.id)
            completion(answer)
        }

        topic.remove("abc")
        await settle(topic)
        XCTAssertEqual(asked, ["abc"])
        XCTAssertFalse(fake.calls.contains { $0.hasPrefix("remove") }, "declined: nothing removed")

        answer = true
        topic.remove("abc")
        await settle(topic)
        XCTAssertTrue(fake.calls.contains("remove abc global"))
        XCTAssertEqual(fake.calls.last, "list global")
    }

    func test_checkForUpdatesReloads() async throws {
        let fake = FakeMaintenance()
        let topic = try await loadedTopic(fake)
        fake.installed = [item(enabled: false)]

        topic.checkForUpdates()
        await settle(topic)

        XCTAssertTrue(fake.calls.contains("update global"))
        XCTAssertEqual(toggle(topic.table?.rows.first?.cells["enabled"]), false)
    }

    func test_privatePaneHasNoExtensionsTopic() throws {
        let fake = FakeMaintenance()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: makeSettings())
        layered.set(true, for: UserSettings.browserPrivateBrowsing)
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog) },
            engineKind: .chrome, minimizedSymbol: "globe", store: EphemeralPaneStateStore(),
            settings: layered, history: nil, homeURL: WebBrowserPaneViewController.blankPage)
        XCTAssertTrue(pane.resolvedJar.isEphemeral)

        let panel = makePanel(fake, scope: .pane(layered, pane))
        XCTAssertNil(topic(in: panel), "a private pane keeps no extensions")
        XCTAssertTrue(panel.panels.contains { $0 is ChromeBrowserTopicPanel }, "its Chrome topic stays")
    }

    func test_closingTheTopicStopsAPendingReadFromAskingChrome() async throws {
        let fake = FakeMaintenance()
        let topic = try await loadedTopic(fake)
        let before = fake.calls.count

        topic.reload()
        topic.viewDidDisappear()
        await topic.reloadTask?.value

        XCTAssertEqual(Array(fake.calls.dropFirst(before)), ["end"], "no list after management ended")
    }

    func test_closingTheTopicStopsAPendingChangeFromReloading() async throws {
        let fake = FakeMaintenance()
        fake.installed = [item()]
        let topic = try await loadedTopic(fake)
        let before = fake.calls.count

        topic.checkForUpdates()
        topic.viewDidDisappear()
        await settle(topic)

        let after = Array(fake.calls.dropFirst(before))
        XCTAssertEqual(after.first, "end")
        XCTAssertFalse(after.contains { $0.hasPrefix("list") }, "nothing asks Chrome once the topic is gone")
    }

    /// A pane on a jar of its own: the store opens on that jar, beside it.
    func test_getExtensionsOpensTheStoreBesideAPaneOnAJarOfItsOwn() throws {
        let fake = FakeMaintenance()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: makeSettings())
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog) },
            engineKind: .chrome, minimizedSymbol: "globe", store: EphemeralPaneStateStore(),
            settings: layered, history: nil, homeURL: WebBrowserPaneViewController.blankPage)
        let topic = try XCTUnwrap(topic(in: makePanel(fake, scope: .pane(layered, pane))))
        topic.openInExtensionsWindow = nil
        var opened: [(WebBrowserPaneViewController, URL)] = []
        topic.canOpenPage = { _ in true }
        topic.openPage = { opened.append(($0, $1)); return true }
        topic.updateButtons()

        XCTAssertEqual(topic.getButton?.isEnabled, true)
        topic.getExtensions()

        XCTAssertEqual(opened.count, 1)
        XCTAssertTrue(opened.first?.0 === pane, "opened for the pane whose sheet it is")
        XCTAssertEqual(opened.first?.1, ChromeExtensionsTopicPanel.webStore)
    }

    func test_getExtensionsIsOffWithNoRoomBesideTheDestinationPane() throws {
        let (topic, _) = try paneTopic()
        topic.openInExtensionsWindow = nil
        var room = false
        var opened = 0
        topic.canOpenPage = { _ in room }
        topic.openPage = { _, _ in opened += 1; return false }
        topic.updateButtons()
        XCTAssertEqual(topic.getButton?.isEnabled, false, "no room for a Chrome pane beside it")

        room = true
        topic.updateButtons()
        XCTAssertEqual(topic.getButton?.isEnabled, true)

        room = false
        topic.getExtensions()
        XCTAssertEqual(opened, 1)
        XCTAssertEqual(topic.getButton?.isEnabled, false, "a refused open turns the button off")
    }

    /// The global jar's store opens in the extensions window, from the
    /// Settings window and from the sheet of a pane on the global jar alike,
    /// never beside a pane.
    func test_getExtensionsOpensTheExtensionsWindowForTheGlobalJar() throws {
        let settingsWindowTopic = try XCTUnwrap(topic(in: makePanel(FakeMaintenance())))
        let (sheetTopic, _) = try paneTopic()
        for topic in [settingsWindowTopic, sheetTopic] {
            XCTAssertEqual(topic.profile, .global)
            XCTAssertNotNil(topic.openInExtensionsWindow, "the global jar's pages go to the extensions window")
            var canBuild = false
            var opened: [URL] = []
            var besidePane = 0
            topic.canOpenExtensionsWindow = { canBuild }
            topic.openInExtensionsWindow = { opened.append($0); return true }
            topic.canOpenPage = { _ in true }
            topic.openPage = { _, _ in besidePane += 1; return true }
            topic.updateButtons()
            XCTAssertEqual(topic.getButton?.isEnabled, false, "no window can be built")

            canBuild = true
            topic.updateButtons()
            XCTAssertEqual(topic.getButton?.isEnabled, true)
            topic.getExtensions()
            XCTAssertEqual(opened, [ChromeExtensionsTopicPanel.webStore])
            XCTAssertEqual(besidePane, 0)
        }
    }

    func test_updateIntervalShowsOnlyInTheSettingsWindow() throws {
        let global = try XCTUnwrap(topic(in: makePanel(FakeMaintenance())))
        XCTAssertNotNil(view(in: global.view, identifier: ChromeExtensionsTopicPanel.updateIntervalIdentifier))

        let (paneTopic, _) = try paneTopic()
        XCTAssertNil(view(in: paneTopic.view, identifier: ChromeExtensionsTopicPanel.updateIntervalIdentifier))
    }

    private func view(in root: NSView, identifier: String) -> NSView? {
        if root.accessibilityIdentifier() == identifier { return root }
        return root.subviews.lazy.compactMap { self.view(in: $0, identifier: identifier) }.first
    }

    private func paneTopic() throws -> (ChromeExtensionsTopicPanel, WebBrowserPaneViewController) {
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: makeSettings())
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog) },
            engineKind: .chrome, minimizedSymbol: "globe", store: EphemeralPaneStateStore(),
            settings: layered, history: nil, homeURL: WebBrowserPaneViewController.blankPage)
        let topic = try XCTUnwrap(topic(in: makePanel(FakeMaintenance(), scope: .pane(layered, pane))))
        return (topic, pane)
    }

    func test_failureShowsInTable() async throws {
        let fake = FakeMaintenance()
        fake.failure = BrowserExtensionError.unavailable("Chrome did not start")
        let topic = try await loadedTopic(fake)

        XCTAssertEqual(topic.table?.rows.count, 0)
        XCTAssertEqual(topic.table?.emptyLabel.stringValue, "Chrome did not start")
        XCTAssertEqual(topic.table?.emptyLabel.isHidden, false)

        fake.failure = nil
        fake.installed = [item()]
        topic.reload()
        await topic.reloadTask?.value
        XCTAssertEqual(topic.table?.rows.count, 1, "a later read clears the failure")
    }

    /// An empty list stays empty: no inline "nothing installed" text.
    func test_emptyListShowsNoText() async throws {
        let topic = try await loadedTopic(FakeMaintenance())

        XCTAssertEqual(topic.table?.rows.count, 0)
        XCTAssertEqual(topic.table?.emptyLabel.stringValue, "")
    }
}
