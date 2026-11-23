import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// The address field follows the page's address unless it holds text the
/// user typed: focus alone does not make it theirs, since a new tab focuses
/// its empty field and a tool's `navigate` loads without taking focus.
@MainActor
final class BrowserPaneAddressFieldTests: XCTestCase {

    private func makePane() -> (WebBrowserPaneViewController, NSWindow) {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, providesOwnToolbar: false) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = pane
        return (pane, window)
    }

    private func move(_ pane: WebBrowserPaneViewController, to url: URL) throws {
        let engine = try XCTUnwrap(pane.engine as? StubBrowserEngine)
        engine.url = url
        pane.browserEngineAddressDidChange(engine)
    }

    func testAFocusedEmptyFieldShowsTheAddressALoadMovedTo() throws {
        let (pane, window) = makePane()
        defer { window.close() }
        XCTAssertTrue(window.makeFirstResponder(pane.addressField))
        XCTAssertNotNil(pane.addressField.currentEditor(), "the address field is being edited")

        try move(pane, to: URL(string: "https://example.com/")!)

        XCTAssertEqual(pane.addressField.stringValue, "https://example.com/")
        XCTAssertEqual(pane.addressField.currentEditor()?.string, "https://example.com/")
    }

    func testTypedTextIsKeptWhenTheAddressMoves() throws {
        let (pane, window) = makePane()
        defer { window.close() }
        XCTAssertTrue(window.makeFirstResponder(pane.addressField))
        let editor = try XCTUnwrap(pane.addressField.currentEditor())
        editor.string = "exam"

        try move(pane, to: URL(string: "https://example.com/")!)

        XCTAssertEqual(pane.addressField.currentEditor()?.string, "exam")
    }

    func testAFieldNotBeingEditedShowsTheAddress() throws {
        let (pane, window) = makePane()
        defer { window.close() }
        window.makeFirstResponder(nil)

        try move(pane, to: URL(string: "https://example.com/a")!)

        XCTAssertEqual(pane.addressField.stringValue, "https://example.com/a")
    }
}
