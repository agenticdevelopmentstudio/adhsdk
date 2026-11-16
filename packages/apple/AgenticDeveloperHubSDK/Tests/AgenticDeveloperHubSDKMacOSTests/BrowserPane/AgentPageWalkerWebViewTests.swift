import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// `AgentPageWalker.js` through `AgentPageSource`, in a real offscreen web
/// view (recipe workspace/browser/agent-page-builder, vectors 010 and
/// 016–021).
@MainActor
final class AgentPageWalkerWebViewTests: XCTestCase {

    private static let fixture = """
    <!doctype html>
    <html><head><title>Fixture</title>
    <style>.user-hidden { display: none !important; }</style>
    </head><body>
      <main>
        <h1>Visible heading</h1>
        <p style="display:none">Gone by display</p>
        <p style="visibility:hidden">Gone by visibility</p>
        <p hidden>Gone by attribute</p>
        <div aria-hidden="true"><p>Gone by aria</p></div>
        <div class="ad"><p>Sponsored paragraph</p><a href="/ad">Ad link</a></div>
        <div id="promo" class="user-hidden"><p>Promo paragraph</p></div>
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
        let store = try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent(BrowserHiddenItemsStore.fileName))
        for selector in agentSelectors {
            try store.add(BrowserHiddenItem(
                list: .agent, pageURL: URL(string: "http://fixture.test/"), selector: selector,
                scope: .allLikeIt, label: selector))
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
        let reading = await source(nil).read(options: BrowserSnapshotOptions())
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
        let unfiltered = tree(await source(nil).agentPage(options: BrowserSnapshotOptions()))
        XCTAssertTrue(unfiltered.contains("Sponsored paragraph"), unfiltered)
    }

    func test_userListHiddenItemAlsoHiddenFromAgent() async throws {
        // The user list hides by style (display: none), as the pane's injected sheet does;
        // the agent list is empty.
        let page = await source(try store(agentSelectors: [])).agentPage(options: BrowserSnapshotOptions())
        let text = tree(page)
        XCTAssertNil(page.unavailableReason)
        XCTAssertFalse(text.contains("Promo paragraph"), text)
        XCTAssertFalse(page.html().contains("Promo paragraph"))
    }

    func test_scopeInsideExcludedSubtreeIsEmpty() async throws {
        let first = await source(nil).read(options: BrowserSnapshotOptions())
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
        let page = await source(nil).agentPage(options: BrowserSnapshotOptions())
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
        let concealing = AgentPageSource(driver: driver, hiddenItems: nil, privacy: { .enabled(filter) },
                                         hideImages: { false })
        let concealed = await concealing.agentPage(options: BrowserSnapshotOptions())
        XCTAssertFalse(concealed.text().contains("Acme"), concealed.text())
        XCTAssertTrue(concealed.text().contains("Zed"), concealed.text())
        XCTAssertFalse(concealed.html().contains("Acme"), concealed.html())
    }

    func test_timeoutIsUnavailable() async throws {
        let rows = (0..<3000).map { "<div><span>Row \($0)</span><a href=\"/r\($0)\">Link \($0)</a></div>" }
        await host.load(html: "<!doctype html><html><body>\(rows.joined())</body></html>")
        let reading = await source(nil, timeoutMs: 0).read(options: BrowserSnapshotOptions())
        let reason = try XCTUnwrap(reading.page.unavailableReason)
        XCTAssertTrue(reason.hasPrefix(AgentPage.unavailablePrefix), reason)
        XCTAssertNil(reading.page.root)
        XCTAssertNil(reading.generation)
    }

    func test_refsWorkWithClick() async throws {
        let reading = await source(nil).read(options: BrowserSnapshotOptions())
        let button = try XCTUnwrap(firstNode(reading.page, kind: .button, named: "Press me"))
        let generation = try XCTUnwrap(reading.generation)
        XCTAssertFalse(button.selector.isEmpty)

        let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
        _ = try await automation.click(ref: button.ref, generation: generation, native: false)
        let title = try await host.webView.evaluateJavaScript("document.title") as? String
        XCTAssertEqual(title, "Clicked")
    }
}
