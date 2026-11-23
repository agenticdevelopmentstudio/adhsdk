import AppKit
import WebKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// The privacy toolbar's "Hide elements from agent" (recipe
/// workspace/browser/hide-from-agent, spec section 2.5): the button and its
/// menu, picks on the live page and in the Agent preview, and the agent list
/// they write. Dialogs are captured rather than run modally and the notice is
/// counted rather than shown, so nothing here takes the screen; no test pops
/// the button's menu, which would track the mouse.
@MainActor
final class BrowserHideFromAgentTests: XCTestCase {

    private var directory: URL!
    private var store: BrowserHiddenItemsStore!
    private var settings: UserSettings!
    private var engine: WebKitBrowserEngine!
    private var button: BrowserHideFromAgentButton!
    private var dialogs: [BrowserPickDialogController] = []

    private let page = URL(string: "https://example.com/news")!
    private static let html = """
        <!doctype html><html><body><main>
        <div id="promo"><p>Promo paragraph</p></div><p id="content">Content paragraph</p>
        </main></body></html>
        """

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHideFromAgentTests-\(UUID().uuidString)")
        store = try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent(BrowserHiddenItemsStore.fileName))
        settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        settings.set(true, for: UserSettings.browserHiddenItemsNoticeShown)
        engine = WebKitBrowserEngine(settings: settings)
        button = BrowserHideFromAgentButton()
        dialogs = []
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

    // MARK: Helpers

    /// The Agent preview as the mode sees it, without a sealed web view's
    /// rule-list compile: the page it shows and its load hook.
    @MainActor
    private final class FakePreview: BrowserAgentPickSurface {
        let pickWebView = WKWebView(frame: .zero)
        var shownPage: AgentPage?
        var onPageLoad: (() -> Void)?
    }

    private func makeMode(preview: FakePreview? = nil) -> BrowserSelectingMode {
        BrowserSelectingMode(
            engine: engine, store: store, list: .agent, button: button, preview: preview, settings: settings,
            presentDialog: { [weak self] dialog, _ in self?.dialogs.append(dialog) },
            presentNotice: { _ in })
    }

    /// An agent page with the promo paragraph at ref `e2`, its selector the
    /// live page's `#promo`, walked from `url` under `privacy`.
    private func agentPage(url: URL? = nil, privacy: BrowserAgentPrivacy = .off) throws -> AgentPage {
        func node(_ ref: String, _ kind: String, selector: String, text: String? = nil,
                  children: [[String: Any]] = []) -> [String: Any] {
            var out: [String: Any] = ["ref": ref, "kind": kind, "selector": selector]
            if let text { out["text"] = text }
            if !children.isEmpty { out["children"] = children }
            return out
        }
        let root = node("e0", "document", selector: "html", children: [
            node("e1", "paragraph", selector: "#content", children: [
                node("e3", "text", selector: "#content", text: "Content paragraph")
            ]),
            node("e2", "paragraph", selector: "#promo", children: [
                node("e4", "text", selector: "#promo > p", text: "Promo paragraph")
            ])
        ])
        let data = try JSONSerialization.data(
            withJSONObject: ["url": (url ?? page).absoluteString, "title": "News", "root": root])
        let built = AgentPageBuilder(privacy: privacy, hideImages: false).build(payload: data, error: nil)
        XCTAssertNil(built.unavailableReason)
        return built
    }

    private func candidate(ref: String?) -> BrowserPickCandidate {
        BrowserPickCandidate(
            kind: .pick, thisItem: "body > p:nth-of-type(2)", allLikeIt: "p", allLikeItCount: 2,
            pageElementCount: 6, label: "p \"Promo paragraph\"", ref: ref)
    }

    private func agentReading() async -> AgentPage {
        await AgentPageSource(engine: engine, hiddenItems: store, privacy: { .off }, hideImages: { false })
            .agentPage(options: BrowserSnapshotOptions())
    }

    // MARK: Tests

    func test_buttonHasTooltipAndMenu() async throws {
        XCTAssertEqual(button.symbolName, "person.crop.circle.badge.xmark")
        XCTAssertEqual(button.toolTip, "Hide elements from agent")
        XCTAssertEqual(button.accessibilityIdentifier(), "browser.hide-from-agent")
        let target = NSObject()
        let menu = BrowserHideFromAgentButton.makeMenu(
            target: target, select: #selector(NSObject.copy), list: #selector(NSObject.mutableCopy))
        XCTAssertEqual(menu.items.map(\.title), ["Select Items to Hide from the Agent", "Hidden from the Agent…"])
        XCTAssertEqual(menu.items.map(\.action), [#selector(NSObject.copy), #selector(NSObject.mutableCopy)])
        XCTAssertTrue(menu.items.allSatisfy { $0.target === target && $0.isEnabled })
        // While agent selecting runs it is the stop control, then idle again.
        let mode = makeMode()
        mode.begin()
        XCTAssertEqual(button.symbolName, BrowserHideItemsButton.selectingSymbol)
        XCTAssertEqual(button.toolTip, BrowserHideItemsButton.selectingToolTip)
        mode.end(.stop)
        XCTAssertEqual(button.symbolName, "person.crop.circle.badge.xmark")
        XCTAssertEqual(button.toolTip, "Hide elements from agent")
        // In the pane: in the privacy toolbar's row, wired to the pane.
        let pane = WebBrowserPaneViewController(
            makeEngine: { WebKitBrowserEngine(configuration: $0) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        defer { pane.paneContentWillBeDiscarded() }
        pane.settings.set(true, for: UserSettings.browserPrivacyShowToolbar)
        pane.refreshAddressRowControls()
        XCTAssertEqual(pane.hideFromAgentButton.superview?.accessibilityIdentifier(), "browser.privacy-strip.agents")
        XCTAssertTrue(pane.hideFromAgentButton.target === pane)
        XCTAssertEqual(pane.hideFromAgentButton.action, #selector(pane.hideFromAgentButtonClicked(_:)))
        try await pane.loadForTesting(page, html: Self.html)
        // Agent selecting from the pane drives this button, not the address box's.
        pane.beginSelectingItems(store: store, list: .agent)
        let paneMode = try XCTUnwrap(pane.selectingMode)
        XCTAssertEqual(paneMode.list, .agent)
        XCTAssertEqual(paneMode.view, .website)
        XCTAssertEqual(pane.hideFromAgentButton.symbolName, BrowserHideItemsButton.selectingSymbol)
        XCTAssertEqual(pane.addressBox.hideItemsButton.symbolName, BrowserHideItemsButton.idleSymbol)
        // A click on it while selecting is Stop, never the menu.
        pane.hideFromAgentButtonClicked(nil)
        XCTAssertEqual(paneMode.state, .idle)
        XCTAssertEqual(pane.hideFromAgentButton.symbolName, BrowserHideFromAgentButton.agentIdleSymbol)
    }

    func test_pickOnWebsiteWritesAgentList() async throws {
        let mode = makeMode()
        XCTAssertEqual(mode.view, .website)
        mode.begin()
        let pick = BrowserPickCandidate(
            kind: .pick, thisItem: "#promo", allLikeIt: "div", allLikeItCount: 1,
            pageElementCount: 6, label: "div \"Promo paragraph\"", ref: nil)
        mode.handlePick(pick)
        let dialog = try XCTUnwrap(dialogs.first)
        XCTAssertEqual(dialog.questionLabel.stringValue, "Hide this from the agent?")
        dialog.confirm(nil)
        await mode.lastSave?.value
        let saved = try await store.items(list: .agent, for: page)
        XCTAssertEqual(saved.map(\.selector), ["#promo"])
        XCTAssertEqual(saved.first?.site, "example.com/*")
        XCTAssertEqual(saved.first?.list, .agent)
        XCTAssertEqual(mode.state, .selecting)
        mode.end(.stop)
    }

    /// A Website-view pick for the page's root opens no dialog for the agent
    /// list either: saving it would hide the whole page from the agent.
    func test_pickOfPageRootOpensNoDialog() {
        let mode = makeMode()
        mode.begin()
        mode.handlePick(BrowserPickCandidate(
            kind: .pick, thisItem: "body", allLikeIt: nil, allLikeItCount: 0,
            pageElementCount: 6, label: "body", ref: nil))
        XCTAssertTrue(dialogs.isEmpty)
        XCTAssertEqual(mode.state, .selecting)
        mode.end(.stop)
    }

    func test_previewPickMapsRefToSelector() async throws {
        let shown = try agentPage()
        let mapped = try XCTUnwrap(BrowserSelectingMode.mapPreviewPick(candidate(ref: "e2"), in: shown))
        XCTAssertEqual(mapped.thisItem, "#promo")
        XCTAssertNil(mapped.allLikeIt)
        XCTAssertEqual(mapped.ref, "e2")
        XCTAssertEqual(mapped.label, "paragraph \"Promo paragraph\"")
        XCTAssertEqual(BrowserSelectingMode.refSelector("e2"), "[data-adk-ref=\"e2\"]")

        let preview = FakePreview()
        preview.shownPage = shown
        let mode = makeMode(preview: preview)
        XCTAssertEqual(mode.view, .agentPreview)
        XCTAssertTrue(mode.pickWebView === preview.pickWebView)
        mode.begin()
        XCTAssertNotNil(preview.onPageLoad, "the picker reinstalls itself on each preview load")
        mode.handlePick(candidate(ref: "e2"))
        let dialog = try XCTUnwrap(dialogs.first)
        XCTAssertEqual(dialog.questionLabel.stringValue, "Hide this from the agent?")
        XCTAssertFalse(dialog.scopeControl.isEnabled(forSegment: 1), "no looser selector is recorded")
        XCTAssertEqual(dialog.scopeControl.toolTip(forSegment: 1), BrowserPickDialogController.noLooserToolTip)
        dialog.confirm(nil)
        await mode.lastSave?.value
        let saved = try await store.items(list: .agent, for: page)
        // The live page's selector the agent page recorded, not one computed on the preview's markup.
        XCTAssertEqual(saved.map(\.selector), ["#promo"])
        XCTAssertEqual(saved.first?.scope, .thisItem)
        mode.end(.stop)
        XCTAssertNil(preview.onPageLoad)
    }

    func test_previewPickWithoutRefRefused() throws {
        let shown = try agentPage()
        XCTAssertNil(BrowserSelectingMode.mapPreviewPick(candidate(ref: nil), in: shown))
        XCTAssertNil(BrowserSelectingMode.mapPreviewPick(candidate(ref: "e99"), in: shown))
        XCTAssertNil(BrowserSelectingMode.mapPreviewPick(candidate(ref: "e2"), in: nil))
        // The blank space between nodes carries the document's ref: hiding it would hide the page.
        XCTAssertNil(BrowserSelectingMode.mapPreviewPick(candidate(ref: "e0"), in: shown))

        let preview = FakePreview()
        preview.shownPage = shown
        let mode = makeMode(preview: preview)
        mode.begin()
        mode.handlePick(candidate(ref: nil))
        XCTAssertTrue(dialogs.isEmpty)
        XCTAssertEqual(mode.state, .selecting)
        XCTAssertNil(mode.lastSave)
        mode.end(.stop)
    }

    func test_agentListEntryRemovedFromPreview() async throws {
        let before = await agentReading()
        XCTAssertNil(before.unavailableReason)
        XCTAssertTrue(before.html().contains("Promo paragraph"), before.html())

        let mode = makeMode()
        mode.begin()
        mode.handlePick(BrowserPickCandidate(
            kind: .pick, thisItem: "#promo", allLikeIt: nil, allLikeItCount: 0,
            pageElementCount: 6, label: "div \"Promo paragraph\"", ref: nil))
        try XCTUnwrap(dialogs.first).confirm(nil)
        await mode.lastSave?.value
        mode.end(.stop)

        // What the preview is rebuilt from (the pane rebuilds on the store's change).
        let after = await agentReading()
        XCTAssertNil(after.unavailableReason)
        XCTAssertFalse(after.html().contains("Promo paragraph"), after.html())
        XCTAssertTrue(after.html().contains("Content paragraph"), after.html())
    }

    func test_userListUnaffected() async throws {
        let mode = makeMode()
        mode.begin()
        mode.handlePick(BrowserPickCandidate(
            kind: .pick, thisItem: "#promo", allLikeIt: nil, allLikeItCount: 0,
            pageElementCount: 6, label: "div \"Promo paragraph\"", ref: nil))
        try XCTUnwrap(dialogs.first).confirm(nil)
        await mode.lastSave?.value
        mode.end(.stop)

        let agentItems = try await store.items(list: .agent, for: page)
        XCTAssertEqual(agentItems.count, 1)
        let userItems = try await store.items(list: .user, for: page)
        XCTAssertEqual(userItems, [])
        // The user list's selectors are what the live page's style sheet is
        // built from, so an empty list is no `__adk_hidden_items` rule.
        let userSelectors = try await store.enabledSelectors(list: .user, for: page)
        XCTAssertEqual(userSelectors, [])
    }

    func test_previewPickSavesTheLiveSiteUnderPrivacy() async throws {
        // A privacy word in the host: the agent page's address is concealed,
        // the entry's site must still be the live page's.
        let live = try XCTUnwrap(URL(string: "https://acme.example/news"))
        engine.webView.loadSimulatedRequest(URLRequest(url: live), responseHTML: Self.html)
        for _ in 0..<250 where engine.url != live || engine.webView.isLoading {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(engine.url, live)
        let privacy = BrowserAgentPrivacy.enabled(
            TextSubstitutionFilter(pairs: [.init(alias: "zed", real: "acme")]))
        let shown = try agentPage(url: live, privacy: privacy)
        XCTAssertNotEqual(shown.url?.host, "acme.example", "the agent page's address is concealed")

        let preview = FakePreview()
        preview.shownPage = shown
        let mode = makeMode(preview: preview)
        mode.begin()
        mode.handlePick(candidate(ref: "e2"))
        try XCTUnwrap(dialogs.first).confirm(nil)
        await mode.lastSave?.value
        mode.end(.stop)

        let saved = try await store.items(list: .agent, for: live)
        XCTAssertEqual(saved.map(\.site), ["acme.example/*"])
        XCTAssertEqual(saved.map(\.selector), ["#promo"])
    }

    func test_popoverToggleMatchesTheClosingPress() throws {
        let window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: 200, height: 100),
            styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let anchor = NSButton(frame: NSRect(x: 10, y: 10, width: 40, height: 20))
        window.contentView?.addSubview(anchor)
        let popover = BrowserHiddenItemsPopover(list: .agent, store: store, url: page) {}
        popover.anchor = anchor
        func mouse(_ type: NSEvent.EventType, at point: NSPoint, number: Int) throws -> NSEvent {
            try XCTUnwrap(NSEvent.mouseEvent(
                with: type, location: point, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: number, clickCount: 1, pressure: 1))
        }
        let inside = NSPoint(x: 20, y: 20)
        // The press on the anchor that closed it: its own mouse-up is the toggle.
        popover.noteClosing(by: try mouse(.leftMouseDown, at: inside, number: 7))
        XCTAssertEqual(popover.closingPressNumber, 7)
        XCTAssertTrue(popover.closesOnAnchorClick(try mouse(.leftMouseUp, at: inside, number: 7)))
        XCTAssertNil(popover.closingPressNumber)
        // Released off the button (no action), then a real click: it opens the popover.
        popover.noteClosing(by: try mouse(.leftMouseDown, at: inside, number: 8))
        XCTAssertFalse(popover.closesOnAnchorClick(try mouse(.leftMouseUp, at: inside, number: 9)))
        // A press elsewhere closes it without arming the toggle.
        popover.noteClosing(by: try mouse(.leftMouseDown, at: NSPoint(x: 150, y: 80), number: 10))
        XCTAssertNil(popover.closingPressNumber)
        XCTAssertFalse(popover.closesOnAnchorClick(try mouse(.leftMouseUp, at: inside, number: 10)))
        // Nothing recorded: a click is an ordinary click.
        XCTAssertFalse(popover.closesOnAnchorClick(nil))
    }
}
