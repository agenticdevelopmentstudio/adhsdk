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

        pane.setEventsPaused(true)
        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertNotNil(pane.activationShield.userScript)

        pane.setEventsPaused(false)
        XCTAssertFalse(pane.activationShield.isActive)
        XCTAssertNil(pane.activationShield.userScript)
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
    }

    func testPauseMakesTheWebViewFirstResponder() throws {
        let pane = makePane()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = pane
        defer { window.close() }

        pane.addressField.stringValue = "half typed"
        XCTAssertTrue(window.makeFirstResponder(pane.addressField))
        XCTAssertNotNil(pane.addressField.currentEditor(), "the address field is being edited")

        pane.setEventsPaused(true)

        let responder = try XCTUnwrap(window.firstResponder as? NSView)
        XCTAssertTrue(responder === pane.webView || responder.isDescendant(of: pane.webView),
                      "the page holds focus when it is frozen")
        XCTAssertNil(pane.addressField.currentEditor(), "the edit ended")
        XCTAssertEqual(pane.addressField.stringValue, "half typed", "ending the edit did not navigate")
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
