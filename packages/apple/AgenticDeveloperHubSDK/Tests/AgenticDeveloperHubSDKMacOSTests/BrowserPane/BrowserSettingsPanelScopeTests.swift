import AppKit
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

    /// Settings changes reach the pane through `receive(on: .main)`; draining
    /// the main queue delivers them, however loaded the machine is.
    private func settle() {
        pumpMainQueueUntilDrained()
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
            panel.panels.contains { $0.descriptor.title == "Privacy and Security" },
            "the Privacy and Security topic is listed"
        )
        XCTAssertFalse(
            panel.panels.contains { $0.descriptor.title == "Agent Privacy" },
            "Agent Privacy is a group of the Privacy and Security topic, not a topic of its own"
        )
        XCTAssertEqual(
            panel.binding.rows(named: UserSettings.browserAgentPrivacy.name).count, 1,
            "the Agent Privacy switch is shown globally too"
        )
    }

    /// The drag-and-drop row is "Disable drag and drop": checking it writes
    /// false (no drag and drop) into this pane's override only.
    func testPaneScopeWritesOnlyTheOverride() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        let dragAndDrop = try row(UserSettings.browserPrivacyDragAndDrop, in: panel)
        let marker = try XCTUnwrap(dragAndDrop.row.marker)
        XCTAssertFalse(marker.isShowingOverride)
        XCTAssertFalse(dragAndDrop.model.value, "drag and drop is allowed, so Disable reads unchecked")

        dragAndDrop.model.settingObserver.value = true
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
        XCTAssertTrue(layered.get(UserSettings.browserPrivacyDragAndDrop), "back to the global value, allowed")
        XCTAssertFalse(dragAndDrop.model.value, "allowed again, so Disable reads unchecked")
    }

    /// "Use Global Setting" re-reads the row by force, discarding an edit in
    /// progress, rather than waiting for the store's change notice, whose
    /// refresh skips a field that still has focus.
    func testUseGlobalSettingDiscardsAnEditInProgress() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        let dragAndDrop = try row(UserSettings.browserPrivacyDragAndDrop, in: panel)
        // Checking "Disable drag and drop" writes the override being reverted.
        dragAndDrop.model.settingObserver.value = true
        settle()
        XCTAssertTrue(layered.hasOverride(UserSettings.browserPrivacyDragAndDrop))
        var refreshes: [Bool] = []
        dragAndDrop.model.refreshHandler = { force in refreshes.append(force) }

        let item = try XCTUnwrap(dragAndDrop.row.marker).useGlobalItem
        _ = item.target?.perform(item.action, with: item)

        XCTAssertEqual(refreshes, [true], "the revert itself forces the re-read")
        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyDragAndDrop))
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
        XCTAssertEqual(BrowserSettingsPanelViewController.jarLabel(for: ownPane), "This Pane")

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
        XCTAssertEqual(BrowserSettingsPanelViewController.jarLabel(for: sharedPane), "All Browser Panes")

        // Within a worktree's jar, likewise, and the row names the worktree.
        global.set(BrowserStorageJar.worktree, for: UserSettings.browserPrivacyStorageJar)
        let worktreeLayer = makeLayered(over: global)
        let worktreePane = try makePane(settings: worktreeLayer)
        XCTAssertEqual(worktreePane.resolvedJar.jar, .worktree)
        let worktreePanel = makePanel(settings: global, scope: .pane(worktreeLayer, worktreePane))
        XCTAssertFalse(try row(UserSettings.browserAcceptsCookies, in: worktreePanel).row.isEnabled)
        XCTAssertEqual(BrowserSettingsPanelViewController.jarLabel(for: worktreePane), "wt")
    }

    /// Manage Site Data… acts on the jar Storage names when it is pressed,
    /// not the one the sheet opened on, and names that jar.
    func testSiteDataFollowsTheStorageSettingTheSheetShows() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        XCTAssertEqual(pane.resolvedJar.jar, .pane)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))
        let privacy = try XCTUnwrap(panel.panels.compactMap { $0 as? BrowserPrivacySettingsPanel }.first)

        // Unchanged: the store the page uses.
        let own = try XCTUnwrap(BrowserSettingsPanelViewController.siteData(for: pane, under: layered))
        XCTAssertTrue(own.dataStore === pane.webView.configuration.websiteDataStore)
        XCTAssertEqual(privacy.siteDataJarName, BrowserStorageJar.pane.label)

        // Storage moved to the shared jar in the sheet: the shared store,
        // never the pane's own, and the window says so.
        layered.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        let shared = try XCTUnwrap(BrowserSettingsPanelViewController.siteData(for: pane, under: layered))
        XCTAssertTrue(shared.dataStore === WKWebsiteDataStore.default())
        XCTAssertEqual(privacy.siteDataJarName, BrowserStorageJar.global.label)
        XCTAssertEqual(
            BrowserSiteDataWindowController.title(jarName: privacy.siteDataJarName),
            "Site Data \u{2014} Shared by all browser panes"
        )
        XCTAssertEqual(
            BrowserSiteDataViewController.removeAllMessage(jarName: "This pane only"),
            "Remove all Safari site data in \u{201C}This pane only\u{201D}?"
        )

        // Private browsing: an in-memory store, never the shared one.
        layered.set(true, for: UserSettings.browserPrivateBrowsing)
        let privateData = try XCTUnwrap(BrowserSettingsPanelViewController.siteData(for: pane, under: layered))
        XCTAssertFalse(privateData.dataStore.isPersistent)
        XCTAssertNotEqual(privacy.siteDataJarName, BrowserStorageJar.global.label)

        // Back to the jar it was built on: the page's store again.
        layered.set(false, for: UserSettings.browserPrivateBrowsing)
        layered.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let back = try XCTUnwrap(BrowserSettingsPanelViewController.siteData(for: pane, under: layered))
        XCTAssertTrue(back.dataStore === pane.webView.configuration.websiteDataStore)
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

        let controller = try XCTUnwrap(BrowserPaneSettingsViewController(pane: pane, history: nil))
        XCTAssertEqual(controller.title, "Settings for \(pane.paneTitle)")
        let unlayered = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: global)
        panes.append(unlayered)
        XCTAssertNil(BrowserPaneSettingsViewController(pane: unlayered, history: nil),
                     "a pane with no layer of its own has no settings")
    }

    /// The settings close through OK as well as the window's close button:
    /// OK is the default button and sends the window's close.
    func testSettingsViewEndsInAnOKButton() throws {
        let pane = try makePane(settings: makeLayered(over: makeSettings()))
        let controller = try XCTUnwrap(BrowserPaneSettingsViewController(pane: pane, history: nil))
        let buttons = allSubviews(of: controller.view).compactMap { $0 as? NSButton }
        let okButton = try XCTUnwrap(buttons.first {
            $0.accessibilityIdentifier() == BrowserPaneSettingsViewController.okIdentifier
        })
        XCTAssertEqual(okButton.title, "OK")
        XCTAssertEqual(okButton.keyEquivalent, "\r", "OK is the default button")
        XCTAssertTrue(okButton.target === controller)
        XCTAssertNotNil(okButton.action)
        controller.finish()
    }

    private func allSubviews(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }

    /// Accept cookies belongs to a jar, so a pane's row names the one the
    /// pane is on; the Settings window's row names none.
    func testAcceptCookiesNamesThePaneJar() throws {
        let global = makeSettings()
        let globalRow = try row(UserSettings.browserAcceptsCookies, in: makePanel(settings: global))
        XCTAssertNil(globalRow.model.explanation)

        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panePanel = makePanel(settings: global, scope: .pane(layered, pane))
        let paneRow = try row(UserSettings.browserAcceptsCookies, in: panePanel)
        XCTAssertEqual(paneRow.model.explanation, "Applies to the jar: This Pane.")
    }

    // MARK: - The settings' open and close

    func testSettingsCloseRebuildsForAChangeMadeWhileOpen() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.webView

        let controller = try XCTUnwrap(pane.makePaneSettingsController())
        XCTAssertTrue(pane.isSettingsOpen)
        layered.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        settle()
        XCTAssertTrue(pane.webView === built, "nothing is rebuilt while the settings are up")

        controller.finish()

        XCTAssertFalse(pane.webView === built, "closing the settings rebuilds the pane")
        XCTAssertFalse(pane.capturesConsole)
        XCTAssertFalse(pane.isSettingsOpen)
    }

    func testSettingsCloseIgnoresGlobalChangesMadeBeforeTheyOpened() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.webView
        // Global construction-time changes an open pane does not follow.
        global.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        global.set(true, for: UserSettings.browserPrivateBrowsing)
        settle()
        XCTAssertTrue(pane.webView === built)

        let controller = try XCTUnwrap(pane.makePaneSettingsController())
        controller.finish()

        XCTAssertTrue(pane.webView === built, "a Done that changed nothing rebuilds nothing")
        XCTAssertTrue(pane.capturesConsole)
        XCTAssertEqual(pane.resolvedJar.jar, .pane, "still on its jar, not moved to private browsing")
    }

    func testJarChangeInTheSettingsWaitsForThemToClose() throws {
        let global = makeSettings()
        global.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
        let layered = makeLayered(over: global)
        layered.set(BrowserStorageJar.pane, for: UserSettings.browserPrivacyStorageJar)
        let pane = try makePane(settings: layered)
        XCTAssertEqual(pane.resolvedJar.jar, .pane)
        let built = pane.webView

        let controller = try XCTUnwrap(pane.makePaneSettingsController())
        _ = controller.view
        controller.panels.panels.forEach { _ = $0.view }
        let useGlobal = try XCTUnwrap(controller.panels.binding.buttons["settings.browser.reset.use-global"])
        useGlobal.wasPressedCallback?()
        settle()

        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyStorageJar))
        XCTAssertTrue(pane.webView === built, "the jar does not move under open settings")
        XCTAssertEqual(pane.resolvedJar.jar, .pane)

        controller.finish()

        XCTAssertFalse(pane.webView === built)
        XCTAssertEqual(pane.resolvedJar.jar, .global, "the close applies the jar change")
    }

    func testSettingsCloseOncePerPresentation() throws {
        let layered = makeLayered(over: makeSettings())
        let pane = try makePane(settings: layered)
        let controller = try XCTUnwrap(pane.makePaneSettingsController())
        let paneClose = controller.onClose
        var closes = 0
        controller.onClose = { closes += 1; paneClose?() }

        controller.finish()
        controller.finish()

        XCTAssertEqual(closes, 1)
        XCTAssertFalse(pane.isSettingsOpen)
    }

    /// The settings window and the Privacy popover can both be up on one
    /// pane. Whichever closes first leaves the snapshot to the other, and
    /// the last close rebuilds for a change made while either was up.
    func testTwoSessionsShareOneSnapshotAndTheLastCloseRebuilds() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let built = pane.webView

        let window = try XCTUnwrap(pane.makePaneSettingsController())
        layered.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        settle()
        let popover = try XCTUnwrap(pane.makePaneSettingsController())

        window.finish()
        XCTAssertTrue(pane.isSettingsOpen, "the popover is still up")
        XCTAssertTrue(pane.webView === built, "nothing is rebuilt while a session is up")

        popover.finish()
        XCTAssertFalse(pane.isSettingsOpen)
        XCTAssertFalse(pane.webView === built, "the last close rebuilds for the change the first session made")
        XCTAssertFalse(pane.capturesConsole)
    }

    func testAcceptCookiesLockFollowsTheJarTheSettingsShow() throws {
        let global = makeSettings()
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let controller = try XCTUnwrap(pane.makePaneSettingsController())
        _ = controller.view
        controller.panels.panels.forEach { _ = $0.view }
        let cookies = try row(UserSettings.browserAcceptsCookies, in: controller.panels)
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
        controller.finish()
    }

    // MARK: - Privacy

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

        // The General / Events / Agents tabs, in order. Agent access is two
        // checkboxes over its one three-way key.
        XCTAssertEqual(layout, [
            "Storage / Cookie and storage jar",
            "Scripts / Third-party content",
            "Scripts / Capture page console",
            "Input / Disable keyboard events",
            "Input / Disable mouse and scrolling events",
            "Input / Disable pointer tracking",
            "Input / Disable drag and drop",
            "Focus and visibility / Disable activation events",
            "Agent Access / Agent access",
            "Agent Access / Read only",
            "Agent Access / Agent while paused"
        ])
    }

    /// A stored `whenFocused`, which no row offers, still restricts the page,
    /// so Disable pointer tracking reads checked; checking it again keeps it,
    /// and only unchecking it lets the page track the pointer (`always`).
    func testDisablePointerTrackingReadsAnyRestrictionAsChecked() throws {
        let global = makeSettings()
        global.set(BrowserPointerTracking.whenFocused, for: UserSettings.browserPrivacyPointerTracking)
        let panel = makePanel(settings: global)
        let row = try XCTUnwrap(panel.binding.rows(named: UserSettings.browserPrivacyPointerTracking.name).first)
        let model = try XCTUnwrap(row.model as? ComposableSettings.ViewModel<Bool>)
        XCTAssertTrue(model.value)

        model.settingObserver.value = true
        XCTAssertEqual(global.get(UserSettings.browserPrivacyPointerTracking), .whenFocused)
        model.settingObserver.value = false
        XCTAssertEqual(global.get(UserSettings.browserPrivacyPointerTracking), .always)
        model.settingObserver.value = true
        XCTAssertEqual(global.get(UserSettings.browserPrivacyPointerTracking), .never)
    }

    // MARK: - Every key has a home

    /// Answers the Chrome topics' reads with nothing, so the Settings window
    /// lists them and their rows exist.
    @MainActor
    private final class NoChromeMaintenance: BrowserEngineMaintenance {
        var engineVersion: String { "test" }
        func removeAllCookies() async {}
        func extensions(in profile: BrowserExtensionProfile) async throws -> [BrowserExtension] { [] }
        func setExtension(_ id: String, enabled: Bool, in profile: BrowserExtensionProfile) async throws {}
        func removeExtension(_ id: String, in profile: BrowserExtensionProfile) async throws {}
        func checkForExtensionUpdates(in profile: BrowserExtensionProfile) async throws {}
        func endExtensionManagement() {}
    }

    /// After the regroup no browser key is orphaned: each one is a row in the
    /// Settings window (Chrome's topics included) or in a Safari pane's sheet,
    /// where the pane-only tab position lives.
    func test_everyBrowserKeyHasAHome() throws {
        let global = makeSettings()
        let window = BrowserSettingsPanelViewController(
            history: nil,
            siteData: BrowserSiteData(dataStore: .nonPersistent()),
            settings: global,
            chrome: NoChromeMaintenance()
        )
        _ = window.view
        window.panels.forEach { _ = $0.view }

        let layered = makeLayered(over: global)
        let sheet = makePanel(settings: global, scope: .pane(layered, try makePane(settings: layered)))

        let shown = Set(window.binding.rows.map(\.name)).union(sheet.binding.rows.map(\.name))
        // The privacy toolbar's visibility lives in the View menu (Show / Hide
        // Privacy Toolbar), not in a settings row.
        let menuOnly: Set<String> = [UserSettings.browserPrivacyShowToolbar.name]
        for name in BrowserSettings.allKeyNames where !menuOnly.contains(name) {
            XCTAssertTrue(shown.contains(name), "\(name) is a row in no topic")
        }
    }

    // MARK: - History in a pane's sheet

    /// browser-settings-014 (pane half) and browser-settings-019: a pane's
    /// History group has Record history and Agent can see history but not
    /// the global-only Keep visits for; a pane write marks the agent row, and
    /// Use Global Setting puts it back on the global value.
    func test_paneHistoryGroupAndAgentAccessOverride() throws {
        let global = makeSettings()
        let key = UserSettings.browserAgentHistoryAccess
        // A global value off the default, so going back to it is observable:
        // with both at None, Use Global Setting would change nothing to see.
        global.set(BrowserAgentHistoryAccess.all, for: key)
        let layered = makeLayered(over: global)
        let pane = try makePane(settings: layered)
        let panel = makePanel(settings: global, scope: .pane(layered, pane))

        let historyRows = panel.binding.rows.filter { $0.group == "History" }.map(\.name)
        XCTAssertEqual(historyRows, [
            UserSettings.browserRecordsHistory.name, UserSettings.browserAgentHistoryAccess.name
        ])
        XCTAssertFalse(historyRows.contains(UserSettings.browserHistoryRetention.name))

        let row = try XCTUnwrap(panel.binding.rows(named: key.name).first)
        let model = try XCTUnwrap(row.model as? ComposableSettings.ChoiceViewModel<BrowserAgentHistoryAccess>)
        let marker = try XCTUnwrap(row.marker, "a pane row carries an override marker")
        XCTAssertFalse(marker.isShowingOverride)
        XCTAssertEqual(model.value, .all, "the row starts on the global value")

        model.settingObserver.value = .currentTab
        settle()

        XCTAssertTrue(layered.hasOverride(key))
        XCTAssertEqual(layered.get(key), .currentTab)
        XCTAssertEqual(global.get(key), .all, "the global value is untouched")
        XCTAssertTrue(marker.isShowingOverride)
        XCTAssertTrue(row.hasOverride())

        let item = marker.useGlobalItem
        _ = item.target?.perform(item.action, with: item)
        settle()

        XCTAssertFalse(layered.hasOverride(key))
        XCTAssertFalse(row.hasOverride())
        XCTAssertFalse(marker.isShowingOverride)
        XCTAssertEqual(layered.get(key), .all, "the pane follows the global value again")
        XCTAssertEqual(model.value, .all, "the row shows the global value again")
    }

    // MARK: - Help

    private func helpTitles(_ topic: String, in panel: BrowserSettingsPanelViewController) throws -> [String] {
        let panel = try XCTUnwrap(panel.panels.first { $0.descriptor.title == topic }, "no \(topic) topic")
        return try XCTUnwrap(panel.helpContent, "\(topic) has no help").topics.map(\.title)
    }

    private func helpBody(
        _ title: String, of topic: String, in panel: BrowserSettingsPanelViewController
    ) throws -> String {
        let panel = try XCTUnwrap(panel.panels.first { $0.descriptor.title == topic })
        let help = try XCTUnwrap(panel.helpContent?.topics.first { $0.title == title }, "no \(title) help")
        return help.body
    }

    /// browser-settings-028: the regrouped topics' help follows the groups
    /// each scope shows, History's help sends the reader to Browser ▸ Show
    /// History, and Agent can see history has a topic of its own.
    func test_regroupedTopicsHelpFollowsTheScope() throws {
        let global = makeSettings()
        let window = makePanel(settings: global)
        let layered = makeLayered(over: global)
        let sheet = makePanel(settings: global, scope: .pane(layered, try makePane(settings: layered)))

        XCTAssertEqual(try helpTitles("Behavior", in: window), ["Open Sites in Tabs", "Page", "Home Page", "Playback"])
        XCTAssertEqual(try helpTitles("Behavior", in: sheet), ["Page", "Home Page", "Playback"],
                       "Open sites in tabs is not in a pane's sheet, nor is its help")
        XCTAssertEqual(try helpTitles("Appearance", in: window), ["Page", "Tab Position"])
        XCTAssertEqual(try helpTitles("Appearance", in: sheet), ["Page", "Tab Position"])

        for panel in [window, sheet] {
            let privacy = try helpTitles("Privacy and Security", in: panel)
            XCTAssertTrue(privacy.contains("Agent Can See History"))
            XCTAssertTrue(privacy.contains("History"))
            XCTAssertTrue(try helpBody("History", of: "Privacy and Security", in: panel)
                .contains("Browser ▸ Show History"))
        }
    }

    /// browser-settings-026: the moved Behavior and Appearance controls carry
    /// no explanation of what they do; Autoplay's note says when it applies,
    /// which differs by scope and engine, and stays.
    func test_regroupedRowsHaveNoInlineHelp() throws {
        let panel = makePanel(settings: makeSettings())
        for key in [
            UserSettings.browserJavaScriptEnabled.name, UserSettings.browserBlocksPopups.name,
            UserSettings.browserHomePage.name, UserSettings.browserMinimumFontSize.name,
            UserSettings.browserLockdownMode.name, UserSettings.browserHistoryRetention.name
        ] {
            let row = try XCTUnwrap(panel.binding.rows(named: key).first, "no row for \(key)")
            XCTAssertNil(row.model?.explanation, "\(key) explains itself inline")
        }
    }
}
