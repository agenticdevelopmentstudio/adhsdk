import XCTest
import AppKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Browser pane's gear items and Pause Events (spec sections 7 and 11).
@MainActor
final class BrowserPaneMenuTests: XCTestCase {

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makePane(settings: SettingsStore? = nil) -> BrowserPaneViewController {
        BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings ?? makeSettings())
    }

    private func item(_ title: String, in pane: BrowserPaneViewController) throws -> NSMenuItem {
        try XCTUnwrap(pane.makePaneMenuItems().first { $0.title == title }, "no \(title) item")
    }

    /// The current web view's gate; every pane web view is a `BrowserWebView`.
    private func gate(of pane: BrowserPaneViewController) throws -> BrowserInputGate {
        try XCTUnwrap(pane.webView as? BrowserWebView).gate
    }

    /// Whether the current web view's controller holds the shield's
    /// document-start script: the half of the shield a rebuild can lose.
    private func hasShieldScript(_ pane: BrowserPaneViewController) -> Bool {
        pane.webView.configuration.userContentController.userScripts
            .contains { $0.source.contains(BrowserActivationShield.marker) }
    }

    func testMenuItemsInOrder() {
        let pane = makePane()
        var expected = ["Pause Events", "Settings…"]
        #if DEBUG
        expected.append("Show Browser Log")
        #endif
        let items = pane.makePaneMenuItems()
        XCTAssertEqual(items.map(\.title), expected)
        XCTAssertTrue(items.allSatisfy { $0.target === pane }, "every item targets the pane")
        var identifiers = ["pane.options.browser.pause", "pane.options.browser.settings"]
        #if DEBUG
        identifiers.append("pane.options.browser.log")
        #endif
        XCTAssertEqual(items.map { $0.accessibilityIdentifier() }, identifiers)
    }

    func testPauseTogglesCheckmark() throws {
        let pane = makePane()
        let pause = try item("Pause Events", in: pane)
        XCTAssertEqual(pause.state, .off)

        let action = try XCTUnwrap(pause.action)
        _ = pane.perform(action, with: pause)
        XCTAssertTrue(pane.isEventsPaused)
        XCTAssertEqual(try item("Pause Events", in: pane).state, .on, "the menu is asked again on every click")

        _ = pane.perform(action, with: pause)
        XCTAssertFalse(pane.isEventsPaused)
        XCTAssertEqual(try item("Pause Events", in: pane).state, .off)
    }

    func testPauseClosesTheGate() throws {
        let pane = makePane()
        let webView = try XCTUnwrap(pane.webView as? BrowserWebView)
        XCTAssertFalse(webView.gate.isPaused)

        pane.setEventsPaused(true)
        XCTAssertTrue(try gate(of: pane).isPaused)
        XCTAssertTrue(pane.pausedBadge.isShowing)

        pane.setEventsPaused(false)
        XCTAssertFalse(try gate(of: pane).isPaused)
        XCTAssertFalse(pane.pausedBadge.isShowing)
    }

    /// Pause raises the activation shield; unpause hands it back to the Hide
    /// Focus setting, which here is off.
    func testPauseRaisesTheShieldAndUnpauseReturnsItToTheSetting() {
        let settings = makeSettings()
        settings.set(false, for: UserSettings.browserPrivacyHideActivation)
        let pane = makePane(settings: settings)
        XCTAssertFalse(pane.activationShield.isActive)

        XCTAssertFalse(hasShieldScript(pane))

        pane.setEventsPaused(true)
        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertNotNil(pane.activationShield.userScript)
        XCTAssertTrue(hasShieldScript(pane), "the shield's script is installed for the next load")

        pane.setEventsPaused(false)
        XCTAssertFalse(pane.activationShield.isActive)
        XCTAssertNil(pane.activationShield.userScript)
        XCTAssertFalse(hasShieldScript(pane), "and taken off again")
    }

    /// The order of a pause and a settings change does not matter: turning
    /// Hide Focus off while paused leaves the shield up and the gate closed,
    /// because both are recomputed from the settings *and* the pause.
    func testHideFocusOffWhilePausedKeepsTheShieldAndTheGate() throws {
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        let pane = makePane(settings: settings)
        pane.setEventsPaused(true)

        settings.set(false, for: UserSettings.browserPrivacyHideActivation)
        // Settings changes reach the pane through `receive(on: .main)`.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertTrue(hasShieldScript(pane))
        XCTAssertTrue(try gate(of: pane).isPaused)
        XCTAssertTrue(pane.pausedBadge.isShowing)

        pane.setEventsPaused(false)
        XCTAssertFalse(pane.activationShield.isActive, "unpaused, the setting (now off) decides")
        XCTAssertFalse(try gate(of: pane).isPaused)
    }

    /// With Hide Focus on, unpausing leaves the shield up: it was the
    /// setting's before the pause and stays the setting's after it.
    func testUnpauseKeepsTheShieldTheSettingAsksFor() {
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        let pane = makePane(settings: settings)
        pane.setEventsPaused(true)
        pane.setEventsPaused(false)
        XCTAssertTrue(pane.activationShield.isActive)
    }

    /// A rebuilt web view is still paused: the pause is the pane's, not the
    /// web view's.
    func testARebuiltWebViewStaysPaused() throws {
        let pane = makePane()
        pane.setEventsPaused(true)
        pane.rebuildWebView()
        XCTAssertTrue(try gate(of: pane).isPaused)
        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertTrue(hasShieldScript(pane), "the new web view has the shield's script")
        XCTAssertTrue(pane.pausedBadge.isShowing)
    }

    func testPauseMakesTheWebViewFirstResponder() throws {
        let pane = makePane()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = pane
        defer { window.close() }
        // The pane restores to the blank page as its view loads; let that
        // settle, so a load the pause started would be the only one.
        let deadline = Date().addingTimeInterval(5)
        while (pane.webView.isLoading || pane.isHoldingLoad) && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
        XCTAssertFalse(pane.webView.isLoading)
        let urlBefore = pane.webView.url

        // An entry that would resolve and load if the edit's end navigated.
        pane.addressField.stringValue = "example.com"
        XCTAssertTrue(window.makeFirstResponder(pane.addressField))
        XCTAssertNotNil(pane.addressField.currentEditor(), "the address field is being edited")

        pane.setEventsPaused(true)

        let responder = try XCTUnwrap(window.firstResponder as? NSView)
        XCTAssertTrue(responder === pane.webView || responder.isDescendant(of: pane.webView),
                      "the page holds focus when it is frozen")
        XCTAssertNil(pane.addressField.currentEditor(), "the edit ended")
        XCTAssertEqual(pane.addressField.stringValue, "example.com")
        // `load` marks the web view loading at once, or holds the request
        // for the content rules; neither happened, and the address is the
        // blank page the pane restored to (nil or about:blank), not the entry.
        XCTAssertFalse(pane.webView.isLoading, "ending the edit did not navigate")
        XCTAssertFalse(pane.isHoldingLoad, "nor held a navigation for later")
        XCTAssertEqual(pane.webView.url, urlBefore)
        XCTAssertTrue(pane.webView.url == nil || pane.webView.url == BrowserPaneViewController.blankPage)
    }

    func testShowBrowserLogCallsTheHost() throws {
        #if DEBUG
        let pane = makePane()
        var asked: BrowserPaneViewController?
        pane.onShowBrowserLog = { asked = $0 }
        let log = try item("Show Browser Log", in: pane)
        _ = pane.perform(try XCTUnwrap(log.action), with: log)
        XCTAssertTrue(asked === pane)
        #else
        throw XCTSkip("Show Browser Log is a debug-build item")
        #endif
    }
}
