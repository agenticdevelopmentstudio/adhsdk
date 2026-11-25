import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BrowserSettingsTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Writes UserSettings.shared, which suites in the other framework share.
        await ExclusiveAccess.Resource.userSettings.acquire()
    }

    override func tearDown() async throws {
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    private func configuration(_ store: SettingsStore) -> WKWebViewConfiguration {
        WebKitBrowserEngine.makeConfiguration(settings: store, consoleLog: BrowserConsoleLog())
    }

    private func makeStore() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    // MARK: - Keys

    func testEveryBrowserKeyIsNamedUnderTheBrowserPrefix() {
        let names = BrowserSettings.allKeyNames
        XCTAssertEqual(names.count, 38)
        XCTAssertEqual(Set(names).count, names.count, "no two settings share a key")
        for name in names {
            XCTAssertTrue(name.hasPrefix("browser."), "\(name) is not a browser key")
        }
    }

    func testPrivacyDefaults() {
        let store = makeStore()
        XCTAssertEqual(store.get(UserSettings.browserPrivacyKeyboard), .allow)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyMouse), .allow)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyPointerTracking), .always)
        XCTAssertTrue(store.get(UserSettings.browserPrivacyDragAndDrop))
        XCTAssertFalse(store.get(UserSettings.browserPrivacyHideActivation))
        XCTAssertEqual(store.get(UserSettings.browserPrivacyAgentAccess), .full)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyAgentWhilePaused), .allowed)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyStorageJar), .pane)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyThirdPartyContent), .allow)
        XCTAssertTrue(store.get(UserSettings.browserPrivacyConsoleCapture))
    }

    func testResetRemovesPrivacyValues() {
        let store = makeStore()
        store.set(BrowserInputPolicy.block, for: UserSettings.browserPrivacyKeyboard)
        store.set(true, for: UserSettings.browserPrivacyHideActivation)
        BrowserSettings.reset(in: store)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyKeyboard), .allow)
        XCTAssertFalse(store.get(UserSettings.browserPrivacyHideActivation))
    }

    /// Reset must not hand the model back a pane the user hid or made read
    /// only, nor move panes off their jar, which would delete its site data.
    func testResetLeavesAgentAccessAndTheStorageJarAlone() {
        let store = makeStore()
        store.set(BrowserAgentAccess.hidden, for: UserSettings.browserPrivacyAgentAccess)
        store.set(BrowserAgentWhilePaused.paused, for: UserSettings.browserPrivacyAgentWhilePaused)
        store.set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        BrowserSettings.reset(in: store)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyAgentAccess), .hidden)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyAgentWhilePaused), .paused)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyStorageJar), .worktree)
    }

    /// What a reset keeps, named here so adding a key to the Agent Privacy
    /// group (or dropping one) has to be a decision this test records.
    func testResetKeepsExactlyAgentAccessThePauseRuleTheJarAgentPrivacyAndHideImages() {
        XCTAssertEqual(BrowserSettings.keptByResetNames, [
            UserSettings.browserPrivacyAgentAccess.name,
            UserSettings.browserPrivacyAgentWhilePaused.name,
            UserSettings.browserPrivacyStorageJar.name,
            UserSettings.browserAgentPrivacy.name,
            UserSettings.browserPrivacyHideImages.name
        ])
        XCTAssertTrue(BrowserSettings.keptByResetNames.isSubset(of: Set(BrowserSettings.allKeyNames)))
    }

    /// Reset must not hand the privacy words, or the page's images, back to
    /// the screen and to a model's screenshot.
    func testResetLeavesAgentPrivacyAndHideImagesAlone() {
        let store = makeStore()
        store.set(true, for: UserSettings.browserAgentPrivacy)
        store.set(true, for: UserSettings.browserPrivacyHideImages)
        store.set(true, for: UserSettings.browserPrivacyShowToolbar)
        BrowserSettings.reset(in: store)
        XCTAssertTrue(store.get(UserSettings.browserAgentPrivacy))
        XCTAssertTrue(store.get(UserSettings.browserPrivacyHideImages))
        XCTAssertFalse(store.get(UserSettings.browserPrivacyShowToolbar), "the toolbar is a preference, reset")
    }

    // MARK: - Reset

    /// A reset of the browsing preferences leaves model access as the user
    /// set it: off stays off, and evaluate stays on.
    func testResetLeavesTheAutomationSwitchesAlone() {
        let store = makeStore()
        store.set(false, for: UserSettings.browserAutomationEnabled)
        store.set(true, for: UserSettings.browserAutomationEvaluate)
        store.set("example.com", for: UserSettings.browserHomePage)
        BrowserSettings.reset(in: store)
        XCTAssertFalse(store.get(UserSettings.browserAutomationEnabled))
        XCTAssertTrue(store.get(UserSettings.browserAutomationEvaluate))
        XCTAssertEqual(store.get(UserSettings.browserHomePage), "")
    }

    func testResetRemovesEveryStoredBrowserValue() {
        let store = makeStore()
        store.set("example.com", for: UserSettings.browserHomePage)
        store.set(2.0, for: UserSettings.browserPageZoom)
        store.set(false, for: UserSettings.browserJavaScriptEnabled)
        store.set(BrowserHistoryRetention.oneWeek, for: UserSettings.browserHistoryRetention)
        store.set(BrowserMediaCapturePolicy.deny, for: UserSettings.browserMediaCapture)
        store.set("/tmp/downloads", for: UserSettings.browserDownloadDirectory)
        XCTAssertTrue(store.contains(UserSettings.browserPageZoom))

        BrowserSettings.reset(in: store)

        XCTAssertEqual(store.get(UserSettings.browserHomePage), "")
        XCTAssertEqual(store.get(UserSettings.browserPageZoom), 1.0)
        XCTAssertTrue(store.get(UserSettings.browserJavaScriptEnabled))
        XCTAssertEqual(store.get(UserSettings.browserHistoryRetention), .forever)
        XCTAssertEqual(store.get(UserSettings.browserMediaCapture), .ask)
        XCTAssertEqual(store.get(UserSettings.browserDownloadDirectory), "")
        XCTAssertFalse(store.contains(UserSettings.browserPageZoom),
                       "reset removes, so the default stays declared once")
        XCTAssertTrue(store.keys(withPrefix: "browser.").isEmpty)
    }

    func testResetLeavesOtherSettingsAlone() {
        let store = makeStore()
        let unrelated = UserSetting<String>("terminal.something", default: "")
        store.set("kept", for: unrelated)
        BrowserSettings.reset(in: store)
        XCTAssertEqual(store.get(unrelated), "kept")
    }

    // MARK: - Derived values

    func testTheHomePageResolvesLikeTheAddressBar() {
        let store = makeStore()
        XCTAssertNil(BrowserSettings.homePage(in: store), "blank is no home page")

        store.set("example.com", for: UserSettings.browserHomePage)
        XCTAssertEqual(BrowserSettings.homePage(in: store), URL(string: "https://example.com"))

        store.set("http://localhost:8080/", for: UserSettings.browserHomePage)
        XCTAssertEqual(BrowserSettings.homePage(in: store), URL(string: "http://localhost:8080/"))

        store.set("not a page", for: UserSettings.browserHomePage)
        XCTAssertNil(BrowserSettings.homePage(in: store), "an entry with inner whitespace is refused, as typed")
    }

    func testTheDownloadFolderFallsBackToDownloads() {
        let store = makeStore()
        XCTAssertEqual(BrowserSettings.downloadDirectory(in: store), BrowserSettings.defaultDownloadDirectory)

        store.set("~/Desktop/saved", for: UserSettings.browserDownloadDirectory)
        XCTAssertEqual(
            BrowserSettings.downloadDirectory(in: store).path,
            ("~/Desktop/saved" as NSString).expandingTildeInPath,
            "a tilde is expanded"
        )
    }

    func testRetentionCutoffs() {
        let now = Date(timeIntervalSince1970: 100 * 24 * 60 * 60)
        XCTAssertNil(BrowserHistoryRetention.forever.cutoff(from: now))
        XCTAssertEqual(BrowserHistoryRetention.oneWeek.cutoff(from: now), now.addingTimeInterval(-7 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.oneMonth.cutoff(from: now), now.addingTimeInterval(-30 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.threeMonths.cutoff(from: now),
                       now.addingTimeInterval(-90 * 24 * 60 * 60))
        XCTAssertEqual(BrowserHistoryRetention.oneYear.cutoff(from: now), now.addingTimeInterval(-365 * 24 * 60 * 60))
    }

    // MARK: - What the pane reads at creation

    func testPrivateBrowsingGivesTheConfigurationAThrowawayStore() {
        let store = makeStore()
        XCTAssertTrue(configuration(store).websiteDataStore.isPersistent)
        store.set(true, for: UserSettings.browserPrivateBrowsing)
        XCTAssertFalse(configuration(store).websiteDataStore.isPersistent)
    }

    func testAutoplayPolicyBecomesWebKitsPlaybackGate() {
        let store = makeStore()
        XCTAssertEqual(
            configuration(store).mediaTypesRequiringUserActionForPlayback,
            .audio, "the default lets muted video play"
        )
        store.set(BrowserAutoplayPolicy.never, for: UserSettings.browserAutoplay)
        XCTAssertEqual(
            configuration(store).mediaTypesRequiringUserActionForPlayback, .all
        )
        store.set(BrowserAutoplayPolicy.allowed, for: UserSettings.browserAutoplay)
        XCTAssertEqual(
            configuration(store).mediaTypesRequiringUserActionForPlayback, []
        )
    }

    func testUniqueDownloadDestinationsCountLikeEveryOtherName() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = WebBrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory)
        XCTAssertEqual(first.lastPathComponent, "file.zip")
        FileManager.default.createFile(atPath: first.path, contents: Data())

        let second = WebBrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory)
        XCTAssertEqual(second.lastPathComponent, "file 2.zip")
        FileManager.default.createFile(atPath: second.path, contents: Data())

        XCTAssertEqual(
            WebBrowserPaneViewController.uniqueDestination(for: "file.zip", in: directory).lastPathComponent,
            "file 3.zip"
        )
        XCTAssertEqual(
            WebBrowserPaneViewController.uniqueDestination(for: "", in: directory).lastPathComponent, "download",
            "a nameless download still gets a file"
        )
    }

    // MARK: - Agent history access

    /// agent-history-tool-001 / browser-settings-018: three choices in order,
    /// the key, and None with nothing stored.
    func test_agentHistoryAccessDefaultsToNone() {
        let key = UserSettings.browserAgentHistoryAccess
        XCTAssertEqual(key.name, "browser.agent.history_access")
        XCTAssertEqual(makeStore().get(key), BrowserAgentHistoryAccess.none)
        XCTAssertEqual(
            BrowserAgentHistoryAccess.allCases.map(\.displayName),
            ["All history", "Current tab only", "None"]
        )
        XCTAssertTrue(BrowserSettings.allKeyNames.contains(key.name))
    }

    /// agent-history-tool-002: a pane's layer takes its own value and the
    /// global one stays None.
    func test_agentHistoryAccessIsPaneOverridable() {
        let key = UserSettings.browserAgentHistoryAccess
        XCTAssertFalse(BrowserSettings.globalOnlyKeyNames.contains(key.name))

        let global = makeStore()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
        XCTAssertFalse(layered.hasOverride(key))
        layered.set(BrowserAgentHistoryAccess.currentTab, for: key)

        XCTAssertTrue(layered.hasOverride(key))
        XCTAssertEqual(layered.get(key), .currentTab)
        XCTAssertEqual(global.get(key), BrowserAgentHistoryAccess.none)
    }

    /// agent-history-tool-003: Privacy and Security's History group holds a
    /// pop-up row titled "Agent can see history" with the three choices.
    func test_rowPresent() throws {
        let panel = BrowserSettingsPanelViewController(
            history: nil,
            siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: makeStore()
        )
        _ = panel.view
        panel.panels.forEach { _ = $0.view }
        let privacy = try XCTUnwrap(panel.panels.first { $0.descriptor.title == "Privacy and Security" })

        let rows = panel.binding.rows(named: UserSettings.browserAgentHistoryAccess.name)
        XCTAssertEqual(rows.count, 1)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.group, "History")
        XCTAssertTrue(row.view.isDescendant(of: privacy.view))
        XCTAssertTrue(row.view is ComposableSettings.PopupMenuChoiceView<BrowserAgentHistoryAccess>)
        let model = try XCTUnwrap(row.model as? ComposableSettings.ChoiceViewModel<BrowserAgentHistoryAccess>)
        XCTAssertEqual(model.title, "Agent can see history")
        XCTAssertEqual(model.choices.map(\.label), ["All history", "Current tab only", "None"])
        XCTAssertEqual(model.choices.map(\.value), BrowserAgentHistoryAccess.allCases)
    }

    // MARK: - Tab position

    /// A pane whose layer overrides `browser.tabs.positions` puts its tabs on
    /// the override's first edge, not the app-wide one.
    func test_browserPaneOverrideBeatsGlobal() {
        let saved = UserSettings.shared
        defer { UserSettings.shared = saved }
        let global = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        UserSettings.shared = global
        global.set(TabPositions([.left]), for: UserSettings.tabsPositions)

        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
        layered.set(TabPositions([.bottom]), for: UserSettings.browserTabsPositions)

        let pane = WebBrowserPaneViewController(
            makeEngine: { FakeBrowserEngine(configuration: $0) },
            engineKind: .safari,
            minimizedSymbol: "safari",
            store: EphemeralPaneStateStore(),
            settings: layered,
            history: nil,
            homeURL: WebBrowserPaneViewController.blankPage
        )
        _ = pane.view

        XCTAssertEqual(BrowserSettings.tabPositionsOverride(in: layered), TabPositions([.bottom]))
        XCTAssertEqual(pane.tabStrip.primaryEdge, .bottom)
    }
}
