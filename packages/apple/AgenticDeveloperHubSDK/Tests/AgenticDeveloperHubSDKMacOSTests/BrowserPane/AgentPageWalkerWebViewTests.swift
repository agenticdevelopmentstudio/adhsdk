import AppKit
import Combine
import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// `AgentPageWalker.js` through `AgentPageSource`, in a real offscreen web
/// view (recipe workspace/browser/agent-page-builder, vectors 010 and
/// 016–021). Every source is given a store: a nil store is the unavailable
/// page (`test_missingStoreIsUnavailable`).
@MainActor
final class AgentPageWalkerWebViewTests: XCTestCase {

    private static let fixture = """
    <!doctype html>
    <html><head><title>Fixture</title>
    </head><body>
      <main>
        <h1>Visible heading</h1>
        <p style="display:none">Gone by display</p>
        <p style="visibility:hidden">Gone by visibility</p>
        <p hidden>Gone by attribute</p>
        <div aria-hidden="true"><p>Gone by aria</p></div>
        <div class="ad"><p>Sponsored paragraph</p><a href="/ad">Ad link</a></div>
        <div id="promo"><p>Promo paragraph</p></div>
        <aside id="side"><button id="side-button">Side button</button></aside>
        <button id="press" onclick="document.title = 'Clicked'">Press me</button>
        <a href="/elsewhere">Keep link</a>
      </main>
    </body></html>
    """

    private var host: OffscreenWebView!
    private var driver: WebKitPageDriver!
    private var directory: URL!

    override func setUp() async throws {
        host = OffscreenWebView()
        driver = WebKitPageDriver(webView: host.webView)
        await host.load(html: Self.fixture)
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentPageWalkerWebViewTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
        host = nil
        driver = nil
    }

    // MARK: Helpers

    private func store(agentSelectors: [String]) throws -> BrowserHiddenItemsStore {
        // A file per store, so two stores in one test never share items.
        let store = try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent("\(UUID().uuidString)-\(BrowserHiddenItemsStore.fileName)"))
        for selector in agentSelectors {
            try store.add(BrowserHiddenItem(
                list: .agent, pageURL: URL(string: "http://fixture.test/"), selector: selector,
                scope: .allLikeIt, label: selector))
        }
        return store
    }

    private func emptyStore() throws -> BrowserHiddenItemsStore { try store(agentSelectors: []) }

    /// A store holding one agent-list item per `(site, selector)` pair.
    private func store(sites: [(String, String)]) throws -> BrowserHiddenItemsStore {
        let store = try store(agentSelectors: [])
        for (site, selector) in sites {
            try store.add(BrowserHiddenItem(
                list: .agent, pageURL: URL(string: site), selector: selector, scope: .allLikeIt, label: selector))
        }
        return store
    }

    private func source(_ store: BrowserHiddenItemsStore?, timeoutMs: Int = AgentPageSource.defaultTimeoutMs)
        -> AgentPageSource {
        AgentPageSource(driver: driver, hiddenItems: store, privacy: { .off }, hideImages: { false },
                        timeoutMs: timeoutMs)
    }

    private func tree(_ page: AgentPage) -> String {
        page.snapshotTree(BrowserSnapshotOptions())
    }

    private func nodes(_ node: AgentNode?) -> [AgentNode] {
        guard let node else { return [] }
        return [node] + node.children.flatMap { nodes($0) }
    }

    private func firstNode(_ page: AgentPage, kind: AgentNodeKind, named name: String) -> AgentNode? {
        nodes(page.root).first { $0.kind == kind && AgentPageText.allText($0).contains(name) }
    }

    // MARK: Tests

    func test_hiddenNodesNotVisited() async throws {
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let text = tree(reading.page)
        XCTAssertTrue(text.contains("Visible heading"), text)
        for gone in ["Gone by display", "Gone by visibility", "Gone by attribute", "Gone by aria"] {
            XCTAssertFalse(text.contains(gone), "\(gone) reached the agent:\n\(text)")
            XCTAssertFalse(reading.page.html().contains(gone))
        }
        XCTAssertNotNil(reading.generation)
    }

    func test_agentListSelectorExcludesSubtree() async throws {
        let page = await source(try store(agentSelectors: [".ad"])).agentPage(options: BrowserSnapshotOptions())
        let text = tree(page)
        XCTAssertNil(page.unavailableReason)
        XCTAssertFalse(text.contains("Sponsored paragraph"), text)
        XCTAssertFalse(text.contains("Ad link"), text)
        XCTAssertTrue(text.contains("Keep link"), text)
        // Without the list the same page shows it, so the exclusion is the list's doing.
        let unfiltered = tree(await source(try emptyStore()).agentPage(options: BrowserSnapshotOptions()))
        XCTAssertTrue(unfiltered.contains("Sponsored paragraph"), unfiltered)
    }

    func test_userListHiddenItemAlsoHiddenFromAgent() async throws {
        // The user list's own style sheet, applied in the page world as the pane applies it
        // (hidden-items-rendering-014); the agent list is empty.
        _ = try await host.webView.evaluateJavaScript(
            BrowserHiddenItemsStyle.applyScript(selectors: ["#promo"]) + "\n;true", in: nil, contentWorld: .page)
        let page = await source(try store(agentSelectors: [])).agentPage(options: BrowserSnapshotOptions())
        let text = tree(page)
        XCTAssertNil(page.unavailableReason)
        XCTAssertFalse(text.contains("Promo paragraph"), text)
        XCTAssertFalse(page.html().contains("Promo paragraph"))
    }

    func test_scopeInsideExcludedSubtreeIsEmpty() async throws {
        let first = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let sideButton = try XCTUnwrap(firstNode(first.page, kind: .button, named: "Side button"))

        var options = BrowserSnapshotOptions()
        options.scope = sideButton.ref
        let scoped = await source(try store(agentSelectors: ["#side"])).agentPage(options: options)
        XCTAssertNil(scoped.unavailableReason)
        let root = try XCTUnwrap(scoped.root)
        XCTAssertEqual(root.kind, .document)
        XCTAssertTrue(root.children.isEmpty)
        XCTAssertFalse(tree(scoped).contains("Side button"))
    }

    func test_invalidExcludeSelectorIsIsolated() async throws {
        let reading = await source(try store(agentSelectors: ["::bad(", ".ad"]))
            .read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let text = tree(reading.page)
        XCTAssertFalse(text.contains("Sponsored paragraph"), text)
        XCTAssertTrue(text.contains("Keep link"), text)
        XCTAssertTrue(reading.warnings.contains { $0.contains("::bad(") }, "\(reading.warnings)")
    }

    func test_tagBoundarySpaceSurvivesTheWalk() async throws {
        await host.load(html: """
        <!doctype html><html><body><ul>
          <li>Buy <b>now</b></li>
          <li><span>Pay</span> <span>later</span></li>
          <li>Ac<b>me</b></li>
        </ul></body></html>
        """)
        let page = await source(try emptyStore()).agentPage(options: BrowserSnapshotOptions())
        XCTAssertNil(page.unavailableReason)
        XCTAssertEqual(page.text(), "Buy now\nPay later\nAcme")
        let html = page.html()
        XCTAssertTrue(html.contains(">Buy now</li>"), html)
        XCTAssertTrue(html.contains(">Pay later</li>"), html)
        let text = tree(page)
        XCTAssertTrue(text.contains("- text: Buy\n"), text)
        XCTAssertTrue(text.contains("- text: now\n"), text)
        XCTAssertFalse(text.contains("- text: \n"), text)

        // A privacy word split with no space is still concealed as one word.
        let filter = TextSubstitutionFilter(pairs: [.init(alias: "Zed", real: "Acme")])
        let concealing = AgentPageSource(driver: driver, hiddenItems: try emptyStore(), privacy: { .enabled(filter) },
                                         hideImages: { false })
        let concealed = await concealing.agentPage(options: BrowserSnapshotOptions())
        XCTAssertFalse(concealed.text().contains("Acme"), concealed.text())
        XCTAssertTrue(concealed.text().contains("Zed"), concealed.text())
        XCTAssertFalse(concealed.html().contains("Acme"), concealed.html())
    }

    func test_timeoutIsUnavailable() async throws {
        let rows = (0..<3000).map { "<div><span>Row \($0)</span><a href=\"/r\($0)\">Link \($0)</a></div>" }
        await host.load(html: "<!doctype html><html><body>\(rows.joined())</body></html>")
        let reading = await source(try emptyStore(), timeoutMs: 0).read(options: BrowserSnapshotOptions())
        let reason = try XCTUnwrap(reading.page.unavailableReason)
        XCTAssertTrue(reason.hasPrefix(AgentPage.unavailablePrefix), reason)
        XCTAssertNil(reading.page.root)
        XCTAssertNil(reading.generation)
    }

    func test_refsWorkWithClick() async throws {
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let button = try XCTUnwrap(firstNode(reading.page, kind: .button, named: "Press me"))
        let generation = try XCTUnwrap(reading.generation)
        XCTAssertFalse(button.selector.isEmpty)

        let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
        _ = try await automation.click(ref: button.ref, generation: generation, native: false)
        let title = try await host.webView.evaluateJavaScript("document.title") as? String
        XCTAssertEqual(title, "Clicked")
    }

    func test_interactiveGenericElementsKeepRefs() async throws {
        await host.load(html: """
        <!doctype html><html><body>
          <div id="go" tabindex="0" onclick="document.title = 'Went'">Go there</div>
          <span onclick="document.title = 'Spanned'">Span control</span>
          <div contenteditable="true"><div>Edit me</div></div>
          <div onclick="void 0"><a href="/inner">Inner link</a></div>
        </body></html>
        """)
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let goButton = try XCTUnwrap(firstNode(reading.page, kind: .button, named: "Go there"), tree(reading.page))
        XCTAssertNotNil(firstNode(reading.page, kind: .button, named: "Span control"), tree(reading.page))
        XCTAssertNotNil(firstNode(reading.page, kind: .textField, named: "Edit me"), tree(reading.page))
        // A clickable wrapper keeps the link inside it.
        XCTAssertNotNil(firstNode(reading.page, kind: .link, named: "Inner link"), tree(reading.page))
        XCTAssertTrue(tree(reading.page).contains("[ref=\(goButton.ref)]"), tree(reading.page))

        let generation = try XCTUnwrap(reading.generation)
        let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
        _ = try await automation.click(ref: goButton.ref, generation: generation, native: false)
        let title = try await host.webView.evaluateJavaScript("document.title") as? String
        XCTAssertEqual(title, "Went")
    }

    func test_missingStoreIsUnavailable() async throws {
        let reading = await source(nil).read(options: BrowserSnapshotOptions())
        let reason = try XCTUnwrap(reading.page.unavailableReason)
        XCTAssertTrue(reason.hasPrefix(AgentPage.unavailablePrefix), reason)
        XCTAssertNil(reading.page.root)
        XCTAssertNil(reading.generation)
    }

    func test_excludesFollowTheWalkedPage() async throws {
        // The driver reports another site's address, as a navigation committing between
        // reading the list and walking would: the fixture's own list must still apply.
        let moved = MovedPageDriver(inner: driver, reportedURL: URL(string: "http://elsewhere.test/"))
        let store = try store(sites: [("http://fixture.test/", ".ad")])
        let source = AgentPageSource(driver: moved, hiddenItems: store, privacy: { .off }, hideImages: { false })
        let reading = await source.read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let text = tree(reading.page)
        XCTAssertFalse(text.contains("Sponsored paragraph"), text)
        XCTAssertTrue(text.contains("Keep link"), text)
    }

    func test_pageThatKeepsChangingIsUnavailable() async throws {
        // Every walk reports a new site with a list of its own, so no list is ever bound.
        let moving = MovedPageDriver(inner: driver, reportedURL: URL(string: "http://fixture.test/"),
                                     walkedAddresses: ["http://first.test/", "http://second.test/"])
        let store = try store(sites: [("http://fixture.test/", ".ad"), ("http://first.test/", "#side"),
                                      ("http://second.test/", "#press")])
        let source = AgentPageSource(driver: moving, hiddenItems: store, privacy: { .off }, hideImages: { false })
        let reading = await source.read(options: BrowserSnapshotOptions())
        let reason = try XCTUnwrap(reading.page.unavailableReason)
        XCTAssertTrue(reason.hasPrefix(AgentPage.unavailablePrefix), reason)
        XCTAssertNil(reading.generation)
    }

    func test_largePageFitsTheBudget() async throws {
        // Finder may spend only a share of the budget; the rest of the page records the
        // structural path, so a page this size still reads.
        let rows = (0..<1500).map {
            "<div class=\"row row-\($0 % 7)\"><span>Row \($0)</span><a href=\"/r\($0)\">Link \($0)</a></div>"
        }
        await host.load(html: "<!doctype html><html><body>\(rows.joined())</body></html>")
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        XCTAssertTrue(nodes(reading.page.root).allSatisfy { $0.kind == .text || !$0.selector.isEmpty })
    }

}

/// A page driver that reports `reportedURL` as its address while driving
/// `inner`'s page, and optionally rewrites each walk's reported address in
/// turn: a navigation between reading the agent list and walking, without
/// a real one.
@MainActor
private final class MovedPageDriver: BrowserPageDriver {
    private let inner: BrowserPageDriver
    private let reportedURL: URL?
    private var walkedAddresses: [String]

    init(inner: BrowserPageDriver, reportedURL: URL?, walkedAddresses: [String] = []) {
        self.inner = inner
        self.reportedURL = reportedURL
        self.walkedAddresses = walkedAddresses
    }

    var url: URL? { reportedURL }
    var title: String? { inner.title }
    var isLoading: Bool { inner.isLoading }
    var loadingChanges: AnyPublisher<Bool, Never> { inner.loadingChanges }
    var navigationRefusals: AnyPublisher<String, Never> { inner.navigationRefusals }
    var view: NSView { inner.view }
    var viewportSize: CGSize { inner.viewportSize }
    var backForwardVisits: [BrowserVisitLine] { inner.backForwardVisits }

    func load(_ url: URL) { inner.load(url) }
    func goBack() { inner.goBack() }
    func goForward() { inner.goForward() }
    func installAutomationRuntime() async throws { try await inner.installAutomationRuntime() }
    func snapshot(cssRect: CGRect?) async throws -> CGImage { try await inner.snapshot(cssRect: cssRect) }
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {
        try await inner.nativeClick(atViewportX: viewportX, viewportY: viewportY)
    }

    func callAsyncFunction(body: String, arguments: [String: Any], world: BrowserScriptWorld) async throws -> Any? {
        let result = try await inner.callAsyncFunction(body: body, arguments: arguments, world: world)
        guard body.contains("__adkAgentWalk("), !walkedAddresses.isEmpty, let json = result as? String,
              var payload = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
            return result
        }
        payload["url"] = walkedAddresses.removeFirst()
        return String(bytes: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8)
    }
}
