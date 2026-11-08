import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Browser settings panel in its two scopes, the per-pane override rows
/// and the rebuild a construction-time change asks for (spec section 3).
/// Asserted through the panel's topics and row view models, never pixels.
@MainActor
final class BrowserSettingsPanelScopeTests: XCTestCase {

    private var tempRoot: URL!
    private var panes: [SafariBrowserPaneViewController] = []

    override func setUp() async throws {
        try await super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("browser-settings-scope-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        var storeIDs: [UUID] = []
        for pane in panes {
            if let id = pane.resolvedJar.jarID { storeIDs.append(id) }
            pane.paneContentWillBeDiscarded()
        }
        panes = []
        for id in storeIDs {
            try? await WKWebsiteDataStore.remove(forIdentifier: id)
        }
        try? FileManager.default.removeItem(at: tempRoot)
        try await super.tearDown()
    }

    // MARK: - Fixtures

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makeLayered(over global: SettingsStore) -> LayeredSettingsStore {
        LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global
        )
    }

    private func makePane(settings: LayeredSettingsStore) throws -> SafariBrowserPaneViewController {
        let registry = BrowserJarRegistry(
            database: try ProjectDatabase(path: tempRoot.appendingPathComponent("Test.db").path)
        )
        let pane = SafariBrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: settings,
            context: BrowserPaneContext(
                paneNodeID: UUID(), projectID: UUID(), projectName: "Test", worktreePath: "/tmp/wt", jars: registry
            )
        )
        panes.append(pane)
        return pane
    }

    /// A panel with every topic's view loaded, so every row exists.
    private func makePanel(
        settings: SettingsStore,
        scope: BrowserSettingsScope = .global
    ) -> BrowserSettingsPanelViewController {
        let panel = BrowserSettingsPanelViewController(
            history: nil,
            siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: settings,
            scope: scope
        )
        _ = panel.view
        panel.panels.forEach { _ = $0.view }
        return panel
    }

    private func row(_ key: UserSetting<Bool>, in panel: BrowserSettingsPanelViewController) throws
        -> (row: BrowserSettingsRow, model: ComposableSettings.ViewModel<Bool>) {
        let row = try XCTUnwrap(panel.binding.rows(named: key.name).first, "no row for \(key.name)")
        let model = try XCTUnwrap(row.model as? ComposableSettings.ViewModel<Bool>)
        return (row, model)
    }

    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    // MARK: - Tests

    func testGlobalScopeWritesTheSharedStore() throws {
        let global = makeSettings()
        let panel = makePanel(settings: global)
        let javaScript = try row(UserSettings.browserJavaScriptEnabled, in: panel)

        javaScript.model.settingObserver.value = false

        XCTAssertFalse(global.get(UserSettings.browserJavaScriptEnabled))
        XCTAssertTrue(javaScript.row.isEnabled)
        XCTAssertNil(javaScript.row.marker, "global rows carry no override marker")
        XCTAssertTrue(
            panel.panels.contains { $0.descriptor.title == "Session Privacy" },
            "the Session Privacy topic is listed"
        )
    }

    func testPaneScopeWritesOnlyTheOverride() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        let dragAndDrop = try row(UserSettings.browserPrivacyDragAndDrop, in: panel)
        let marker = try XCTUnwrap(dragAndDrop.row.marker)
        XCTAssertFalse(marker.isShowingOverride)

        dragAndDrop.model.settingObserver.value = false
        settle()

        XCTAssertFalse(layered.get(UserSettings.browserPrivacyDragAndDrop))
        XCTAssertTrue(global.get(UserSettings.browserPrivacyDragAndDrop), "the global value is untouched")
        XCTAssertTrue(layered.hasOverride(UserSettings.browserPrivacyDragAndDrop))
        XCTAssertTrue(marker.isShowingOverride)
        XCTAssertTrue(marker.useGlobalItem.isEnabled)

        // "Use Global Setting" drops the override and the marker with it.
        let item = marker.useGlobalItem
        _ = item.target?.perform(item.action, with: item)
        settle()

        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyDragAndDrop))
        XCTAssertFalse(marker.isShowingOverride)
        XCTAssertTrue(dragAndDrop.model.value)
    }

    func testPrivateBrowsingRowIsDisabledInPaneScope() throws {
        let global = makeSettings()
        global.set(true, for: UserSettings.browserPrivateBrowsing)
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        let privateBrowsing = try row(UserSettings.browserPrivateBrowsing, in: panel)

        XCTAssertFalse(privateBrowsing.row.isEnabled)
        XCTAssertNil(privateBrowsing.row.marker)
        XCTAssertTrue(privateBrowsing.model.value, "shows the global value")
        let toggle = try XCTUnwrap(privateBrowsing.row.view as? ComposableSettings.CheckboxView).toggle
        XCTAssertFalse(toggle.isEnabled)

        privateBrowsing.model.settingObserver.value = false
        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivateBrowsing), "a locked row writes nothing")
        XCTAssertTrue(global.get(UserSettings.browserPrivateBrowsing))
    }

    func testAcceptCookiesDisabledUnlessPaneJar() throws {
        // On its own jar (the default), the pane may override Accept cookies.
        let global = makeSettings()
        let ownLayer = makeLayered(over: global)
        let ownPane = try makePane(settings: ownLayer)
        XCTAssertEqual(ownPane.resolvedJar.jar, .pane)
        let ownPanel = makePanel(settings: global, scope: .pane(ownLayer, ownPane))
        let ownRow = try row(UserSettings.browserAcceptsCookies, in: ownPanel)
        XCTAssertTrue(ownRow.row.isEnabled)
        XCTAssertNotNil(ownRow.row.marker)
        XCTAssertEqual(ownPanel.cookiesTitle, "Cookies — This Pane")

        // On the shared jar, it may not: the policy belongs to every pane on it.
        global.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        global.set(false, for: UserSettings.browserAcceptsCookies)
        let sharedLayer = makeLayered(over: global)
        let sharedPane = try makePane(settings: sharedLayer)
        XCTAssertEqual(sharedPane.resolvedJar.jar, .global)
        let sharedPanel = makePanel(settings: global, scope: .pane(sharedLayer, sharedPane))
        let sharedRow = try row(UserSettings.browserAcceptsCookies, in: sharedPanel)
        XCTAssertFalse(sharedRow.row.isEnabled)
        XCTAssertEqual(sharedRow.row.marker?.isShowingOverride, false)
        XCTAssertFalse(sharedRow.model.value, "shows the global value")
        XCTAssertEqual(sharedPanel.cookiesTitle, "Cookies — All Browser Panes")

        // Within a worktree's jar, likewise, and the title names the worktree.
        global.set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        let worktreeLayer = makeLayered(over: global)
        let worktreePane = try makePane(settings: worktreeLayer)
        XCTAssertEqual(worktreePane.resolvedJar.jar, .worktree)
        let worktreePanel = makePanel(settings: global, scope: .pane(worktreeLayer, worktreePane))
        XCTAssertFalse(try row(UserSettings.browserAcceptsCookies, in: worktreePanel).row.isEnabled)
        XCTAssertEqual(worktreePanel.cookiesTitle, "Cookies — wt")
    }

    func testResetInPaneScopeClearsOverrides() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        layered.set(false, for: UserSettings.browserJavaScriptEnabled)
        layered.set(BrowserInputPolicy.block, for: UserSettings.browserPrivacyKeyboard)
        settle()
        XCTAssertTrue(try XCTUnwrap(try row(UserSettings.browserJavaScriptEnabled, in: panel).row.marker)
            .isShowingOverride)

        XCTAssertNil(panel.binding.buttons["settings.browser.reset.reset"], "pane scope offers no global reset")
        let useGlobal = try XCTUnwrap(panel.binding.buttons["settings.browser.reset.use-global"])
        XCTAssertEqual(useGlobal.title, "Use Global Settings for This Pane")
        useGlobal.wasPressedCallback?()
        settle()

        XCTAssertFalse(layered.hasOverride(UserSettings.browserJavaScriptEnabled))
        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyKeyboard))
        XCTAssertTrue(layered.get(UserSettings.browserJavaScriptEnabled))
        XCTAssertFalse(try XCTUnwrap(try row(UserSettings.browserJavaScriptEnabled, in: panel).row.marker)
            .isShowingOverride)
    }

    func testConstructionTimeChangeRequestsRebuild() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.builtConstructionSettings
        XCTAssertEqual(Set(built.keys), BrowserSettings.constructionTimeKeyNames)
        XCTAssertFalse(pane.needsRebuild(after: built))

        // A runtime setting does not ask for a rebuild.
        layered.set(false, for: UserSettings.browserJavaScriptEnabled)
        XCTAssertFalse(pane.needsRebuild(after: built))

        // A construction-time override does, and a rebuild catches up.
        layered.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        XCTAssertTrue(pane.needsRebuild(after: built))
        pane.rebuildEngine()
        XCTAssertFalse(pane.needsRebuild(after: pane.builtConstructionSettings))
        XCTAssertFalse(pane.capturesConsole)

        let sheet = try XCTUnwrap(BrowserPaneSettingsSheetController(pane: pane, history: nil))
        XCTAssertEqual(sheet.title, "Settings for \(pane.paneTitle)")
        let unlayered = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: global)
        panes.append(unlayered)
        XCTAssertNil(BrowserPaneSettingsSheetController(pane: unlayered, history: nil),
                     "a pane with no layer of its own has no sheet")
    }

    func testGlobalCookiesTopicTitle() throws {
        let panel = makePanel(settings: makeSettings())
        let titles = panel.panels.map(\.descriptor.title)
        XCTAssertTrue(titles.contains("Global Cookies"))
        XCTAssertFalse(titles.contains("Cookies"))
        let cookies = try XCTUnwrap(titles.firstIndex(of: "Global Cookies"))
        XCTAssertEqual(titles[cookies + 1], "Session Privacy", "Session Privacy follows Cookies")
    }

    // MARK: - The sheet's open and close

    func testSheetCloseRebuildsForAChangeMadeWhileOpen() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.webView

        let sheet = try XCTUnwrap(pane.makePaneSettingsSheet())
        XCTAssertTrue(pane.isSettingsSheetOpen)
        layered.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        settle()
        XCTAssertTrue(pane.webView === built, "nothing is rebuilt while the sheet is up")

        sheet.finish()

        XCTAssertFalse(pane.webView === built, "closing the sheet rebuilds the pane")
        XCTAssertFalse(pane.capturesConsole)
        XCTAssertFalse(pane.isSettingsSheetOpen)
    }

    func testSheetCloseIgnoresGlobalChangesMadeBeforeItOpened() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.webView
        // Global construction-time changes an open pane does not follow.
        global.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        global.set(true, for: UserSettings.browserPrivateBrowsing)
        settle()
        XCTAssertTrue(pane.webView === built)

        let sheet = try XCTUnwrap(pane.makePaneSettingsSheet())
        sheet.finish()

        XCTAssertTrue(pane.webView === built, "a Done that changed nothing rebuilds nothing")
        XCTAssertTrue(pane.capturesConsole)
        XCTAssertEqual(pane.resolvedJar.jar, .pane, "still on its jar, not moved to private browsing")
    }

    func testJarChangeInTheSheetWaitsForItToClose() throws {
        let global = makeSettings()
        global.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        let layered = makeLayered(over: global)
        layered.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let pane = try makePane(settings: layered)
        XCTAssertEqual(pane.resolvedJar.jar, .pane)
        let built = pane.webView

        let sheet = try XCTUnwrap(pane.makePaneSettingsSheet())
        _ = sheet.view
        sheet.panels.panels.forEach { _ = $0.view }
        let useGlobal = try XCTUnwrap(sheet.panels.binding.buttons["settings.browser.reset.use-global"])
        useGlobal.wasPressedCallback?()
        settle()

        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyStorageJar))
        XCTAssertTrue(pane.webView === built, "the jar does not move under an open sheet")
        XCTAssertEqual(pane.resolvedJar.jar, .pane)

        sheet.finish()

        XCTAssertFalse(pane.webView === built)
        XCTAssertEqual(pane.resolvedJar.jar, .global, "the close applies the jar change")
    }

    func testSheetClosesOncePerPresentation() throws {
        let layered = makeLayered(over: makeSettings())
        let pane = try makePane(settings: layered)
        let sheet = try XCTUnwrap(pane.makePaneSettingsSheet())
        let paneClose = sheet.onClose
        var closes = 0
        sheet.onClose = { closes += 1; paneClose?() }

        sheet.finish()
        sheet.finish(dismissing: false)

        XCTAssertEqual(closes, 1)
        XCTAssertFalse(pane.isSettingsSheetOpen)
    }

    func testAcceptCookiesLockFollowsTheJarTheSheetShows() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let sheet = try XCTUnwrap(pane.makePaneSettingsSheet())
        _ = sheet.view
        sheet.panels.panels.forEach { _ = $0.view }
        let cookies = try row(UserSettings.browserAcceptsCookies, in: sheet.panels)
        let marker = try XCTUnwrap(cookies.row.marker)
        let toggle = try XCTUnwrap(cookies.row.view as? ComposableSettings.CheckboxView).toggle
        XCTAssertTrue(cookies.row.isEnabled)

        cookies.model.settingObserver.value = false
        settle()
        XCTAssertTrue(marker.isShowingOverride)

        // Choosing the shared jar locks the row at once, hiding an override
        // the pane would ignore there, though the pane has not moved yet.
        layered.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        settle()
        XCTAssertEqual(pane.resolvedJar.jar, .pane)
        XCTAssertFalse(cookies.row.isEnabled)
        XCTAssertFalse(toggle.isEnabled)
        XCTAssertFalse(marker.isShowingOverride)
        XCTAssertTrue(cookies.model.value, "shows the global value")
        layered.removeOverride(UserSettings.browserAcceptsCookies)
        cookies.model.settingObserver.value = false
        XCTAssertFalse(layered.hasOverride(UserSettings.browserAcceptsCookies), "a locked row writes nothing")

        // Back to the pane's own jar, and it may be overridden again.
        layered.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        settle()
        XCTAssertTrue(cookies.row.isEnabled)
        XCTAssertTrue(toggle.isEnabled)
        sheet.finish()
    }

    // MARK: - Session Privacy

    func testSessionPrivacyGroupsAndRows() throws {
        let panel = makePanel(settings: makeSettings())
        let keys: Set<String> = [
            UserSettings.browserPrivacyKeyboard.name, UserSettings.browserPrivacyMouse.name,
            UserSettings.browserPrivacyPointerTracking.name, UserSettings.browserPrivacyDragAndDrop.name,
            UserSettings.browserPrivacyHideActivation.name, UserSettings.browserPrivacyAgentAccess.name,
            UserSettings.browserPrivacyAgentWhilePaused.name, UserSettings.browserPrivacyStorageJar.name,
            UserSettings.browserPrivacyThirdPartyContent.name, UserSettings.browserPrivacyConsoleCapture.name
        ]
        let layout = panel.binding.rows
            .filter { keys.contains($0.name) }
            .map { "\($0.group ?? "-") / \($0.model?.title ?? "-")" }

        // Spec section 10, in order.
        XCTAssertEqual(layout, [
            "Input / Keyboard",
            "Input / Mouse and scrolling",
            "Input / Pointer tracking",
            "Input / Drag and drop",
            "Focus and visibility / Hide focus and visibility changes",
            "Agent Partner / Agent access",
            "Agent Partner / Agent while paused",
            "Storage / Cookie and storage jar",
            "Scripts / Third-party content",
            "Scripts / Capture page console"
        ])
    }
}
