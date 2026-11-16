import AppKit
import WebKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Agent preview and Agent source views and the control that picks them
/// (recipe `workspace/browser/agent-views`, spec section 2.4).
@MainActor
final class BrowserAgentViewsTests: XCTestCase {

    // MARK: Fixtures

    private func makePane() -> WebBrowserPaneViewController {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, providesOwnToolbar: false) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        return pane
    }

    private func node(_ ref: String, _ kind: String, text: String? = nil, attrs: [String: String]? = nil,
                      children: [[String: Any]] = []) -> [String: Any] {
        var out: [String: Any] = ["ref": ref, "kind": kind, "selector": "#\(ref)"]
        if let text { out["text"] = text }
        if let attrs { out["attrs"] = attrs }
        if !children.isEmpty { out["children"] = children }
        return out
    }

    /// A page with a heading, a paragraph, a link and an image whose source
    /// the walker reported.
    private func samplePage() -> AgentPage {
        let root = node("e0", "document", children: [
            node("e1", "heading", text: "Title"),
            node("e2", "paragraph", text: "Body text"),
            node("e3", "link", text: "Go", attrs: ["href": "https://a.example/"]),
            node("e4", "image", attrs: ["alt": "Logo", "src": "https://a.example/logo.png"])
        ])
        let object: [String: Any] = ["url": "https://site.example/", "title": "Page", "root": root]
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: object)
        } catch {
            XCTFail("payload did not serialize: \(error)")
            data = Data()
        }
        return AgentPageBuilder(privacy: .off, hideImages: false).build(payload: data, error: nil)
    }

    /// Spins the main run loop until `condition` holds or `timeout` passes.
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { return false }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return true
    }

    // MARK: Control

    func test_segmentsHaveTooltips() {
        let control = makePane().agentViewControl
        XCTAssertEqual(control.accessibilityIdentifier(), "browser.agent-view")
        XCTAssertEqual(control.trackingMode, .selectOne)
        XCTAssertEqual(control.segmentCount, BrowserAgentViewMode.allCases.count)
        for (index, mode) in BrowserAgentViewMode.allCases.enumerated() {
            XCTAssertEqual(control.toolTip(forSegment: index), mode.toolTip)
            XCTAssertFalse(mode.toolTip.isEmpty)
            XCTAssertNotNil(control.image(forSegment: index), "segment \(index) has no image")
            XCTAssertEqual(control.label(forSegment: index) ?? "", "", "segments carry images only")
        }
        XCTAssertEqual(BrowserAgentViewMode.website.toolTip, "Website — the page as it is")
        XCTAssertEqual(BrowserAgentViewMode.agentPreview.toolTip,
                       "Agent preview — what the agent can see, with privacy filters applied")
        XCTAssertEqual(BrowserAgentViewMode.agentSource.toolTip,
                       "Agent source — the page the agent receives, as source")
    }

    func test_defaultModeIsWebsite() {
        let pane = makePane()
        XCTAssertEqual(pane.agentViewMode, .website)
        XCTAssertNil(pane.activeAgentViews, "no agent views are made until a tab leaves Website")
        XCTAssertEqual(pane.agentViewControl.selectedSegment, BrowserAgentViewMode.website.segment)
    }

    func test_websiteModeRestoresPage() async {
        let pane = makePane()
        let saved = BrowserHiddenItemsStore.shared
        BrowserHiddenItemsStore.shared = nil
        defer { BrowserHiddenItemsStore.shared = saved }
        pane.view.layoutSubtreeIfNeeded()
        pane.setAgentViewMode(.agentPreview)
        XCTAssertEqual(pane.agentViewControl.selectedSegment, BrowserAgentViewMode.agentPreview.segment)
        XCTAssertTrue(pane.engine.view.isHiddenOrHasHiddenAncestor, "the page sits hidden under the preview")
        pane.setAgentViewMode(.website)
        XCTAssertEqual(pane.agentViewMode, .website)
        XCTAssertNil(pane.activeAgentViews?.contentView)
        XCTAssertFalse(pane.engine.view.isHiddenOrHasHiddenAncestor, "Website shows the same page again")
    }

    // MARK: Preview

    func test_previewBlocksNetwork() async {
        let html = samplePage().html()
        XCTAssertTrue(html.contains("[image: Logo]"), html)
        XCTAssertFalse(html.contains("src"), "the agent page names no resource to load: \(html)")
        XCTAssertEqual(BrowserContentRules.blockEverythingJSON,
                       #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#)

        let preview = BrowserAgentPreviewViewController()
        preview.show(samplePage())
        let installed = await waitUntil { preview.ruleList != nil }
        XCTAssertTrue(installed, "the block-everything list was never installed")
        XCTAssertEqual(preview.shownHTML, html, "the page loads once the list is in place")
    }

    func test_previewWaitsForRuleList() async {
        struct CompileFailed: Error {}
        let preview = BrowserAgentPreviewViewController(ruleList: { throw CompileFailed() })
        preview.show(samplePage())
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertNil(preview.ruleList)
        XCTAssertNil(preview.shownHTML, "without its rule list the preview loads nothing")
    }

    func test_previewHasJavaScriptOff() {
        let preview = BrowserAgentPreviewViewController()
        XCTAssertFalse(preview.webView.configuration.defaultWebpagePreferences.allowsContentJavaScript)
        XCTAssertFalse(preview.webView.configuration.websiteDataStore.isPersistent)
    }

    func test_previewCancelsNavigation() {
        let blank = URL(string: "about:blank")
        let site = URL(string: "https://a.example/")
        typealias Policy = BrowserAgentPreviewViewController
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: blank, navigationType: .other), .allow)
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: nil, navigationType: .other), .allow)
        XCTAssertEqual(Policy.policy(allowedLoads: 0, url: blank, navigationType: .other), .cancel,
                       "a load the controller did not start")
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: site, navigationType: .other), .cancel)
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: site, navigationType: .linkActivated), .cancel)
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: blank, navigationType: .linkActivated), .cancel)
        XCTAssertEqual(Policy.policy(allowedLoads: 1, url: site, navigationType: .formSubmitted), .cancel)
    }

    /// A frame WebKit would report, main or not.
    private final class FakeFrame: WKFrameInfo {
        let main: Bool
        init(main: Bool) {
            self.main = main
            super.init()
        }
        override var isMainFrame: Bool { main }
    }

    /// A navigation action as WebKit would ask about it.
    private final class FakeAction: WKNavigationAction {
        let url: URL?
        let frame: WKFrameInfo?
        let kind: WKNavigationType
        init(url: URL?, frame: WKFrameInfo?, kind: WKNavigationType = .other) {
            self.url = url
            self.frame = frame
            self.kind = kind
            super.init()
        }
        override var request: URLRequest {
            url.map { URLRequest(url: $0) } ?? URLRequest(url: URL(fileURLWithPath: "/"))
        }
        override var targetFrame: WKFrameInfo? { frame }
        override var navigationType: WKNavigationType { kind }
    }

    /// The delegate itself, not only the policy matrix: one `show` lets
    /// exactly one main-frame `about:blank` load through, and a subframe or
    /// frameless load never.
    func test_previewDelegateAllowsOnlyItsOwnLoad() async {
        let preview = BrowserAgentPreviewViewController()
        // Detached so WebKit's own question about the load cannot spend the
        // credit before the fake actions below ask.
        preview.webView.navigationDelegate = nil
        preview.show(samplePage())
        let installed = await waitUntil { preview.shownHTML != nil }
        XCTAssertTrue(installed, "the page never loaded")
        let blank = URL(string: "about:blank")
        let webView = preview.webView
        let inner = FakeAction(url: blank, frame: FakeFrame(main: false))
        let subframe = await preview.webView(webView, decidePolicyFor: inner)
        XCTAssertEqual(subframe, .cancel, "a subframe's load is never the controller's own")
        let frameless = await preview.webView(webView, decidePolicyFor: FakeAction(url: blank, frame: nil))
        XCTAssertEqual(frameless, .cancel, "a load with no target frame is cancelled")
        let main = FakeFrame(main: true)
        let first = await preview.webView(webView, decidePolicyFor: FakeAction(url: blank, frame: main))
        XCTAssertEqual(first, .allow, "the controller's own load goes through")
        let second = await preview.webView(webView, decidePolicyFor: FakeAction(url: blank, frame: main))
        XCTAssertEqual(second, .cancel, "one load, one credit")
    }

    // MARK: Source

    func test_sourceShowsSameHTML() {
        let page = samplePage()
        let source = BrowserAgentSourceViewController()
        _ = source.view
        source.show(page)
        XCTAssertEqual(source.textView.string, page.html())
        XCTAssertFalse(source.textView.isEditable)
        XCTAssertTrue(source.textView.isSelectable)
    }

    func test_sourceHighlightsFourKinds() {
        let html = #"<p data-adk-ref="e1">Hi</p>"#
        let runs = BrowserAgentSourceHighlighter.tokens(in: html).map { range, kind in
            ((html as NSString).substring(with: range), kind)
        }
        let expected: [(String, BrowserAgentSourceHighlighter.Kind)] = [
            ("<p", .tag), (" ", .text), ("data-adk-ref", .attributeName), ("=", .tag),
            ("\"e1\"", .attributeValue), (">", .tag), ("Hi", .text), ("</p>", .tag)
        ]
        XCTAssertEqual(runs.map(\.0), expected.map(\.0))
        XCTAssertEqual(runs.map(\.1), expected.map(\.1))

        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let colors = BrowserAgentSourceHighlighter.Colors(
            tag: .systemRed, attributeName: .systemOrange, attributeValue: .systemGreen, text: .systemBlue)
        let styled = BrowserAgentSourceHighlighter.highlight(html, font: font, colors: colors)
        XCTAssertEqual(styled.string, html)
        func color(at index: Int) -> NSColor? {
            styled.attribute(.foregroundColor, at: index, effectiveRange: nil) as? NSColor
        }
        XCTAssertEqual(color(at: 0), .systemRed)
        XCTAssertEqual(color(at: 3), .systemOrange)
        XCTAssertEqual(color(at: 16), .systemGreen)
        XCTAssertEqual(color(at: 21), .systemBlue)
        XCTAssertEqual(styled.attribute(.font, at: 0, effectiveRange: nil) as? NSFont, font)
    }

    // MARK: Refresh

    /// Counts reads without a captured `var`, which a Sendable closure may not mutate.
    @MainActor private final class Counter { var reads = 0 }

    func test_refreshIsCoalesced() async {
        let counter = Counter()
        let page = samplePage()
        let views = BrowserAgentViews(
            interval: 0.05,
            ruleList: { try await BrowserContentRules.blockEverything() },
            read: {
                counter.reads += 1
                return page
            })
        views.setMode(.agentSource)
        let first = await waitUntil { views.shownPage != nil }
        XCTAssertTrue(first)
        XCTAssertEqual(counter.reads, 1, "entering an agent mode reads once, at once")
        for _ in 0..<5 { views.setNeedsRefresh() }
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(counter.reads, 2, "five triggers inside the interval are one read")
        views.setMode(.website)
        views.setNeedsRefresh()
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(counter.reads, 2, "Website never reads")
    }

    // MARK: Parity with the tools

    /// A pane whose own settings layer over a global store, as a real pane's do.
    private func makeLayeredPane() -> (WebBrowserPaneViewController, LayeredSettingsStore) {
        let global = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let layered = LayeredSettingsStore(overrides: InMemorySettingsStorageProvider(), fallback: global)
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, providesOwnToolbar: false) },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: layered, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        return (pane, layered)
    }

    /// The anti-goal "an agent preview that differs from what the agent
    /// receives": with a pane override of Hide Images, the tools' reader
    /// (through the handle, filled as the app's directory adapter fills it)
    /// and the views' reader get the same value.
    func test_toolsAndViewsGetSameHideImages() {
        let (pane, layered) = makeLayeredPane()
        for override in [true, false] {
            layered.set(override, for: UserSettings.browserPrivacyHideImages)
            XCTAssertEqual(pane.agentHidesImages, override, "the pane's override wins")
            let handle = BrowserPaneHandle(
                id: "pane", project: "project", tab: "tab", automation: pane.automation,
                hidesImages: pane.agentHidesImages)
            let tools = BrowserToolSet.agentPageSource(for: handle, privacy: .off, hiddenItems: nil)
            let views = pane.agentPageSource(engine: pane.engine)
            XCTAssertEqual(tools.hidesImages, override)
            XCTAssertEqual(views.hidesImages, tools.hidesImages, "tools and views read one value")
        }
    }

    func test_refreshOnAgentListChange() async {
        let saved = BrowserHiddenItemsStore.shared
        BrowserHiddenItemsStore.shared = nil
        defer { BrowserHiddenItemsStore.shared = saved }
        let pane = makePane()
        pane.setAgentViewMode(.agentSource)
        guard let views = pane.activeAgentViews else { return XCTFail("no agent views after leaving Website") }
        let first = await waitUntil { views.shownPage != nil }
        XCTAssertTrue(first, "the first rebuild never finished")
        let before = views.rebuildCount
        NotificationCenter.default.post(name: BrowserHiddenItemsStore.didChangeNotification, object: nil)
        let rebuilt = await waitUntil { views.rebuildCount > before }
        XCTAssertTrue(rebuilt, "a change to the agent list rebuilds the agent view")
        // With no agent list the page is unavailable, and says so.
        XCTAssertTrue(views.source.textView.string.contains(AgentPage.unavailablePrefix),
                      views.source.textView.string)
    }
}
