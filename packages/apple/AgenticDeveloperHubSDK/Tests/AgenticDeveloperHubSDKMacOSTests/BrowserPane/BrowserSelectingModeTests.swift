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

    private func escapeEvent(windowNumber: Int = 0) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: windowNumber,
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
        // The page in a window of its own (never ordered in), so Esc from
        // another window — here, none — is told apart from Esc in the pane's.
        let window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: 400, height: 300),
            styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = engine.webView
        defer { window.contentView = nil }
        let mode = makeMode()
        mode.begin()
        XCTAssertFalse(mode.handleKeyDown(try escapeEvent()))
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertTrue(mode.handleKeyDown(try escapeEvent(windowNumber: window.windowNumber)))
        XCTAssertEqual(mode.state, .idle)
        XCTAssertNil(mode.picker)
        XCTAssertEqual(button.symbolName, BrowserHideItemsButton.idleSymbol)
        // Once idle, Esc goes on to whoever wants it.
        XCTAssertFalse(mode.handleKeyDown(try escapeEvent(windowNumber: window.windowNumber)))
    }

    func test_endBeforeStartLeavesNoPicker() async throws {
        let mode = makeMode()
        mode.begin()
        mode.end(.stop)
        await mode.startTask?.value
        let installed = try await engine.webView.evaluateJavaScript(
            "typeof globalThis.__adkPicker", in: nil, contentWorld: BrowserElementPicker.world)
        XCTAssertEqual(installed as? String, "undefined")
    }

    /// A pick only ever comes from a started picker, so each pick test waits
    /// for the start first; before it, `pause()` has no picker to pause.
    func test_pickPausesAndShowsDialog() async throws {
        let mode = makeMode()
        mode.begin()
        await mode.startTask?.value
        XCTAssertEqual(mode.picker?.isRunning, true)
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
        await mode.startTask?.value
        mode.handlePick(candidate)
        XCTAssertEqual(mode.picker?.isPaused, true)
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

    func test_cancelSavesNothingAndResumes() async throws {
        let mode = makeMode()
        mode.begin()
        await mode.startTask?.value
        mode.handlePick(candidate)
        XCTAssertEqual(mode.picker?.isPaused, true)
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

    func test_navigationEndsSelectingMode() async throws {
        settings.set(true, for: UserSettings.browserHiddenItemsNoticeShown)
        let pane = WebBrowserPaneViewController(
            makeEngine: { WebKitBrowserEngine(configuration: $0) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        defer { pane.paneContentWillBeDiscarded() }
        try await pane.loadForTesting(page, html: Self.html)
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

    /// A page with no host has no site to scope an entry to, so selecting
    /// refuses to begin there rather than save an entry for every site.
    func test_hostlessPageRefusesToBeginSelecting() async throws {
        engine.webView.loadHTMLString(Self.html, baseURL: URL(fileURLWithPath: "/tmp/hidden-items-page.html"))
        for _ in 0..<250 where engine.url?.isFileURL != true || engine.webView.isLoading {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(engine.url?.isFileURL, true)
        let mode = makeMode()
        mode.begin()
        XCTAssertEqual(mode.state, .idle)
        XCTAssertNil(mode.picker)
        XCTAssertEqual(button.symbolName, BrowserHideItemsButton.idleSymbol)
        XCTAssertEqual(noticeCount, 0)
        XCTAssertEqual(try store.items(list: .user, for: URL(string: "https://example.com/")!), [])
        XCTAssertFalse(BrowserSelectingMode.canSelect(on: URL(string: "about:blank")))
        XCTAssertFalse(BrowserSelectingMode.canSelect(on: URL(string: "data:text/html,hi")))
        XCTAssertFalse(BrowserSelectingMode.canSelect(on: nil))
        XCTAssertTrue(BrowserSelectingMode.canSelect(on: page))
    }

    /// The pane turns both hide-items buttons off on a hostless page, keeps
    /// their tooltips, refuses to select there, and turns them on again on
    /// a page with a site.
    func test_paneDisablesHideItemsButtonsOnHostlessPage() async throws {
        settings.set(true, for: UserSettings.browserHiddenItemsNoticeShown)
        let pane = WebBrowserPaneViewController(
            makeEngine: { WebKitBrowserEngine(configuration: $0) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        defer { pane.paneContentWillBeDiscarded() }
        pane.updateHideItemsAvailability()
        XCTAssertFalse(pane.addressBox.hideItemsButton.isEnabled)
        XCTAssertFalse(pane.hideFromAgentButton.isEnabled)
        XCTAssertEqual(pane.addressBox.hideItemsButton.toolTip, BrowserHideItemsButton.idleToolTip)
        XCTAssertEqual(pane.hideFromAgentButton.toolTip, BrowserHideFromAgentButton.agentIdleToolTip)
        pane.beginSelectingItems(store: store)
        pane.beginSelectingItems(store: store, list: .agent)
        XCTAssertNil(pane.selectingMode)
        try await pane.loadForTesting(page, html: Self.html)
        XCTAssertTrue(pane.addressBox.hideItemsButton.isEnabled)
        XCTAssertTrue(pane.hideFromAgentButton.isEnabled)
    }
}

extension WebBrowserPaneViewController {
    /// Loads `html` as `url` in the front engine, as if served, and waits
    /// for it to land and the pane to hear of it.
    func loadForTesting(_ url: URL, html: String) async throws {
        let webKit = try XCTUnwrap(engine as? WebKitBrowserEngine)
        webKit.webView.loadSimulatedRequest(URLRequest(url: url), responseHTML: html)
        for _ in 0..<250 where engine.url != url || webKit.webView.isLoading {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(engine.url, url)
    }
}
