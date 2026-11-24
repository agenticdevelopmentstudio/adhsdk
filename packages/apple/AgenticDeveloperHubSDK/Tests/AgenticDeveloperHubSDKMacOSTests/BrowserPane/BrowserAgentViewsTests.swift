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

    /// The delegate's own accounting, not only the policy matrix: one `show`
    /// lets exactly one main-frame `about:blank` load through, and a subframe
    /// or frameless load never. Asked through `decidePolicy`, with the values
    /// the delegate reads off the action, because WebKit's frame and action
    /// classes cannot be faked (a subclass crashes WebKit when it is freed).
    func test_previewDelegateAllowsOnlyItsOwnLoad() async {
        let preview = BrowserAgentPreviewViewController()
        // Detached so WebKit's own question about the load cannot spend the
        // credit before the questions below ask.
        preview.webView.navigationDelegate = nil
        preview.show(samplePage())
        let installed = await waitUntil { preview.shownHTML != nil }
        XCTAssertTrue(installed, "the page never loaded")
        let blank = URL(string: "about:blank")
        let subframe = preview.decidePolicy(targetFrameIsMain: false, url: blank, navigationType: .other)
        XCTAssertEqual(subframe, .cancel, "a subframe's load is never the controller's own")
        let frameless = preview.decidePolicy(targetFrameIsMain: nil, url: blank, navigationType: .other)
        XCTAssertEqual(frameless, .cancel, "a load with no target frame is never the controller's own")
        let link = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .linkActivated)
        XCTAssertEqual(link, .cancel, "a link the page follows is not the controller's load")
        let first = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .other)
        XCTAssertEqual(first, .allow, "the controller's own load goes through")
        let second = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .other)
        XCTAssertEqual(second, .cancel, "one load, one credit")
    }

    /// Two `show` calls in quick succession: WebKit may ask about the
    /// superseded load before the newest one, so both questions must be
    /// answered `.allow`, or the newest page is cancelled and an older
    /// document stays on screen; a third question is cancelled.
    func test_previewTwoQuickShowsLetTheNewestPageLoad() async {
        let preview = BrowserAgentPreviewViewController()
        preview.webView.navigationDelegate = nil
        let installed = await waitUntil { preview.ruleList != nil }
        XCTAssertTrue(installed, "the block-everything list was never installed")
        let newest = AgentPage.unavailable("the walk failed.", url: nil)
        preview.show(samplePage())
        preview.show(newest)
        XCTAssertEqual(preview.shownHTML, newest.html())
        let blank = URL(string: "about:blank")
        let superseded = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .other)
        XCTAssertEqual(superseded, .allow, "the superseded load's question is answered")
        let latest = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .other)
        XCTAssertEqual(latest, .allow, "the newest page loads")
        let extra = preview.decidePolicy(targetFrameIsMain: true, url: blank, navigationType: .other)
        XCTAssertEqual(extra, .cancel, "two loads, two credits")
    }

    /// The same two quick shows with WebKit asking the real delegate: the
    /// document that ends up in the web view is the newest page.
    func test_previewTwoQuickShowsEndOnTheNewestPage() async throws {
        let preview = BrowserAgentPreviewViewController()
        let installed = await waitUntil { preview.ruleList != nil }
        XCTAssertTrue(installed, "the block-everything list was never installed")
        preview.show(samplePage())
        preview.show(AgentPage.unavailable("the walk failed.", url: nil))
        var text = ""
        let deadline = Date().addingTimeInterval(5)
        while !text.contains("the walk failed."), Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
            let script = "document.body ? document.body.innerText : ''"
            text = (try? await preview.webView.evaluateJavaScript(script)) as? String ?? ""
        }
        XCTAssertTrue(text.contains("the walk failed."), "the newest page never showed: \(text)")
        XCTAssertFalse(text.contains("Body text"), "an older document stayed on screen: \(text)")
    }

    // MARK: Source

    func test_sourceShowsSameHTML() async throws {
        let page = samplePage()
        let source = BrowserAgentSourceViewController()
        _ = source.view
        source.show(page)
        XCTAssertEqual(source.textView.string, page.html())
        XCTAssertFalse(source.textView.isEditable)
        XCTAssertTrue(source.textView.isSelectable)
        // The highlight lands from the off-main lex, on the same text.
        let plain = source.textView.textStorage?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        await source.highlighting?.value
        XCTAssertEqual(source.textView.string, page.html())
        let storage = try XCTUnwrap(source.textView.textStorage)
        var colors = Set<NSColor>()
        storage.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: storage.length)) { value, _, _ in
            if let color = value as? NSColor { colors.insert(color) }
        }
        XCTAssertGreaterThan(colors.count, 1, "tags are colored apart from text")
        XCTAssertNotNil(plain)
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

    /// Coming back from Website never shows the page read before: the page
    /// may have changed meanwhile, so the view is blank until the rebuild
    /// lands (final review A-M5).
    func test_returningFromWebsiteDoesNotShowThePreviousPage() async {
        let counter = Counter()
        let page = samplePage()
        let views = BrowserAgentViews(
            interval: 0.05,
            ruleList: { try await BrowserContentRules.blockEverything() },
            read: {
                counter.reads += 1
                if counter.reads > 1 { try? await Task.sleep(nanoseconds: 300_000_000) }
                return page
            })
        views.setMode(.agentSource)
        let first = await waitUntil { views.shownPage != nil }
        XCTAssertTrue(first)
        XCTAssertTrue(views.source.textView.string.contains("Body text"), views.source.textView.string)
        views.setMode(.website)
        views.setMode(.agentSource)
        XCTAssertNil(views.shownPage, "the earlier page is not the current one")
        XCTAssertFalse(views.source.textView.string.contains("Body text"), views.source.textView.string)
        let rebuilt = await waitUntil { views.shownPage != nil }
        XCTAssertTrue(rebuilt)
        XCTAssertTrue(views.source.textView.string.contains("Body text"), views.source.textView.string)
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
    func test_toolsAndViewsGetSameHideImages() async {
        let (pane, layered) = makeLayeredPane()
        for override in [true, false] {
            layered.set(override, for: UserSettings.browserPrivacyHideImages)
            XCTAssertEqual(pane.agentHidesImages, override, "the pane's override wins")
            let handle = BrowserPaneHandle(
                id: "pane", project: "project", tab: "tab", automation: pane.automation,
                hidesImages: pane.agentHidesImages)
            let tools = BrowserToolSet.agentPageSource(for: handle, privacy: .off, hiddenItems: nil)
            let views = await pane.agentPageSource(engine: pane.engine)
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
