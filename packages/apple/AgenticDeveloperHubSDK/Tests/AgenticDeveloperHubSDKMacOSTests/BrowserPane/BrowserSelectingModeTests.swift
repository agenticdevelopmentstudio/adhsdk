import AppKit
import WebKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Selecting mode and its pick dialog (recipe workspace/browser/element-picker).
/// The dialog is captured rather than run modally, and the notice is counted
/// rather than shown, so nothing here takes the screen.
@MainActor
final class BrowserSelectingModeTests: XCTestCase {

    private var directory: URL!
    private var store: BrowserHiddenItemsStore!
    private var settings: UserSettings!
    private var engine: WebKitBrowserEngine!
    private var button: BrowserHideItemsButton!
    private var dialogs: [BrowserPickDialogController] = []
    private var noticeCount = 0

    private let page = URL(string: "https://example.com/news")!
    private static let html = """
        <!doctype html><html><body>
        <div class="ad" id="first">Sponsored</div><p id="content">Content</p>
        </body></html>
        """

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserSelectingModeTests-\(UUID().uuidString)")
        store = try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent(BrowserHiddenItemsStore.fileName))
        settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        engine = WebKitBrowserEngine(settings: settings)
        button = BrowserHideItemsButton()
        dialogs = []
        noticeCount = 0
        engine.webView.loadSimulatedRequest(URLRequest(url: page), responseHTML: Self.html)
        for _ in 0..<250 where engine.url == nil || engine.webView.isLoading {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    override func tearDown() async throws {
        engine?.teardown()
        engine = nil
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeMode() -> BrowserSelectingMode {
        BrowserSelectingMode(
            engine: engine, store: store, list: .user, button: button, settings: settings,
            presentDialog: { [weak self] dialog, _ in self?.dialogs.append(dialog) },
            presentNotice: { [weak self] _ in self?.noticeCount += 1 })
    }

    private let candidate = BrowserPickCandidate(
        kind: .pick, thisItem: "#first", allLikeIt: "div.ad", allLikeItCount: 1,
        pageElementCount: 6, label: "div \"Sponsored\"", ref: nil)

    private func escapeEvent() throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false, keyCode: 53))
    }

    func test_beginShowsStopIcon() {
        let mode = makeMode()
        XCTAssertEqual(button.symbolName, BrowserHideItemsButton.idleSymbol)
        mode.begin()
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertEqual(button.symbolName, "stop.circle")
        XCTAssertEqual(button.toolTip, "Stop selecting")
        XCTAssertEqual(button.accessibilityIdentifier(), "browser.hide-items")
        mode.end(.stop)
        XCTAssertEqual(button.symbolName, "eye.slash")
        XCTAssertEqual(button.toolTip, "Hide distracting items")
    }

    func test_escapeEndsSelecting() throws {
        let mode = makeMode()
        mode.begin()
        XCTAssertTrue(mode.handleKeyDown(try escapeEvent()))
        XCTAssertEqual(mode.state, .idle)
        XCTAssertNil(mode.picker)
        XCTAssertEqual(button.symbolName, BrowserHideItemsButton.idleSymbol)
        // Once idle, Esc goes on to whoever wants it.
        XCTAssertFalse(mode.handleKeyDown(try escapeEvent()))
    }

    func test_pickPausesAndShowsDialog() throws {
        let mode = makeMode()
        mode.begin()
        mode.handlePick(candidate)
        XCTAssertEqual(mode.state, .dialog(candidate))
        XCTAssertEqual(mode.picker?.isPaused, true)
        let dialog = try XCTUnwrap(dialogs.first)
        XCTAssertEqual(dialogs.count, 1)
        XCTAssertEqual(dialog.questionLabel.stringValue, "Remove this from view?")
        XCTAssertEqual(dialog.scopeControl.label(forSegment: 0), "This item")
        XCTAssertEqual(dialog.scopeControl.label(forSegment: 1), "All items like it")
        XCTAssertTrue(dialog.scopeControl.isEnabled(forSegment: 1))
        XCTAssertEqual(dialog.okButton.keyEquivalent, "\r")
        // A second pick while the dialog is up is not a second dialog.
        mode.handlePick(candidate)
        XCTAssertEqual(dialogs.count, 1)
        // The preview checkbox is live.
        dialog.previewCheckbox.state = .on
        dialog.previewToggled(nil)
        XCTAssertEqual(mode.previewSelectors, ["#first"])
    }

    func test_okSavesWithDefaultSitePattern() async throws {
        let mode = makeMode()
        mode.begin()
        mode.handlePick(candidate)
        let dialog = try XCTUnwrap(dialogs.first)
        dialog.confirm(nil)
        await mode.lastSave?.value
        let saved = try store.items(list: .user, for: URL(string: "https://example.com/other")!)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.site, "example.com/*")
        XCTAssertEqual(saved.first?.scope, .thisItem)
        XCTAssertEqual(saved.first?.selector, "#first")
        XCTAssertEqual(saved.first?.label, candidate.label)
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertEqual(mode.picker?.isPaused, false)
        XCTAssertNil(mode.previewSelectors)
    }

    func test_cancelSavesNothingAndResumes() throws {
        let mode = makeMode()
        mode.begin()
        mode.handlePick(candidate)
        let dialog = try XCTUnwrap(dialogs.first)
        dialog.previewCheckbox.state = .on
        dialog.previewToggled(nil)
        dialog.cancel(nil)
        XCTAssertNil(mode.lastSave)
        XCTAssertEqual(try store.items(list: .user, for: page), [])
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertEqual(mode.picker?.isPaused, false)
        XCTAssertNil(mode.previewSelectors)
    }

    func test_navigationEndsSelectingMode() throws {
        settings.set(true, for: UserSettings.browserHiddenItemsNoticeShown)
        let pane = WebBrowserPaneViewController(
            makeEngine: { WebKitBrowserEngine(configuration: $0) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        defer { pane.paneContentWillBeDiscarded() }
        pane.beginSelectingItems(store: store)
        let mode = try XCTUnwrap(pane.selectingMode)
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertEqual(pane.addressBox.hideItemsButton.symbolName, BrowserHideItemsButton.selectingSymbol)
        pane.browserEngineDidCommitNavigation(pane.engine)
        XCTAssertEqual(mode.state, .idle)
        XCTAssertNil(mode.previewSelectors)
        XCTAssertNil(mode.picker)
        XCTAssertEqual(pane.addressBox.hideItemsButton.symbolName, BrowserHideItemsButton.idleSymbol)
    }

    func test_noticeShownOnce() {
        XCTAssertFalse(settings.get(UserSettings.browserHiddenItemsNoticeShown))
        let mode = makeMode()
        mode.begin()
        mode.end(.stop)
        mode.begin()
        mode.end(.stop)
        XCTAssertEqual(noticeCount, 1)
        XCTAssertTrue(settings.get(UserSettings.browserHiddenItemsNoticeShown))
        XCTAssertEqual(BrowserSelectingMode.noticeText, "Items that load again (such as ads) can reappear.")
        // A second pane's mode on the same settings shows none either.
        let other = makeMode()
        other.begin()
        other.end(.stop)
        XCTAssertEqual(noticeCount, 1)
    }
}
