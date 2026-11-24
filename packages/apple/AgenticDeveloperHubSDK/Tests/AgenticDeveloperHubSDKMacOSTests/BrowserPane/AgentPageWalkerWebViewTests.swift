import AppKit
import Combine
import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKCore

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

    /// A scope inside an excluded subtree answers exactly as a scope that
    /// names nothing, so the answer cannot tell the agent a withheld
    /// element exists (final review A-I1). A CSS selector is not a scope.
    func test_scopeInsideExcludedSubtreeReadsAsNoMatch() async throws {
        let excluding = try store(agentSelectors: ["#side"])
        let first = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let sideButton = try XCTUnwrap(firstNode(first.page, kind: .button, named: "Side button"))

        var withheld = BrowserSnapshotOptions()
        withheld.scope = sideButton.ref
        let scoped = await source(excluding).agentPage(options: withheld)
        XCTAssertNil(scoped.unavailableReason)
        XCTAssertFalse(tree(scoped).contains("Side button"))

        var missing = BrowserSnapshotOptions()
        missing.scope = "e9999"
        let unmatched = await source(excluding).agentPage(options: missing)
        XCTAssertEqual(tree(scoped), tree(unmatched))
        XCTAssertEqual(scoped.html(), unmatched.html())

        for selector in ["#side-button", "#side", "[id^='side']", "button"] {
            var probe = BrowserSnapshotOptions()
            probe.scope = selector
            let probed = await source(excluding).agentPage(options: probe)
            XCTAssertEqual(tree(probed), tree(unmatched), "\(selector) answered differently")
        }
    }

    /// An agent-list entry naming the page root withholds the whole page,
    /// title and refs included: the walk starts beneath body, so the entry
    /// would otherwise withhold nothing (review f3).
    func test_pageRootAgentListEntryWithholdsThePage() async throws {
        let first = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let press = try XCTUnwrap(firstNode(first.page, kind: .button, named: "Press me"))
        let generation = try XCTUnwrap(first.generation)
        for selector in ["body", "html"] {
            var scoped = BrowserSnapshotOptions()
            scoped.scope = press.ref
            for options in [BrowserSnapshotOptions(), scoped] {
                let reading = await source(try store(agentSelectors: [selector])).read(options: options,
                                                                                      keepingRefs: true)
                XCTAssertNil(reading.page.unavailableReason, selector)
                XCTAssertEqual(reading.page.title, "", selector)
                XCTAssertTrue(reading.page.text().isEmpty, "\(selector): \(reading.page.text())")
                for shown in ["Visible heading", "Press me", "Keep link"] {
                    XCTAssertFalse(tree(reading.page).contains(shown), "\(selector): \(shown) reached the agent")
                    XCTAssertFalse(reading.page.html().contains(shown), "\(selector): \(shown) in the html")
                }
            }
            let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
            do {
                _ = try await automation.click(ref: press.ref, generation: generation, native: false)
                XCTFail("\(selector): a ref into a withheld page was clicked")
            } catch let error as BrowserAutomationError {
                guard case .staleRef = error else { return XCTFail("\(selector): \(error)") }
            }
        }
    }

    /// The structural selector is stored as a hide-from-agent entry, so the
    /// Kitchen's own <style> elements, inserted under <html> ahead of <head>
    /// (or into body), must not change which element it names (review f4).
    func test_structuralPathSurvivesInjectedStyles() async throws {
        await host.load(html: """
            <!doctype html><html><head><title>Paths</title></head><body>
            <div>One</div><style></style>
            <div><p>A</p><section><p>X</p><p id="target">T</p></section></div>
            <svg width="1" height="1"><defs><linearGradient id="grad"></linearGradient></defs></svg>
            </body></html>
            """)
        try await AgentPageWalkerRuntime.install(on: driver)
        let raw = try await driver.callAsyncFunction(body: """
            const results = {};
            for (const id of ['target', 'grad']) {
              const el = document.getElementById(id);
              const before = globalThis.__adkAgentStructuralPath(el);
              const head = document.createElement('style');
              document.documentElement.insertBefore(head, document.head);
              const inBody = document.createElement('style');
              document.body.insertBefore(inBody, document.body.firstChild);
              const matches = document.querySelectorAll(before);
              results[id] = { before: before, after: globalThis.__adkAgentStructuralPath(el),
                count: matches.length, same: matches[0] === el };
              head.remove();
            }
            return JSON.stringify(results);
            """, arguments: [:], world: .automation)
        let json = try XCTUnwrap(raw as? String)
        let results = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: [String: Any]])
        for id in ["target", "grad"] {
            let result = try XCTUnwrap(results[id], json)
            let before = try XCTUnwrap(result["before"] as? String, json)
            XCTAssertTrue(before.hasPrefix("html > body > "), before)
            XCTAssertFalse(before.contains("nth-child"), before)
            XCTAssertEqual(result["after"] as? String, before, "\(id): the path moved")
            XCTAssertEqual(result["count"] as? Int, 1, "\(id): \(before)")
            XCTAssertEqual(result["same"] as? Bool, true, "\(id): \(before)")
        }
    }

    /// A withheld option never reaches the agent through its select: not as
    /// the select's value, and not through the select action, which answers
    /// a withheld option's label as it answers one that names nothing (review f9).
    func test_withheldOptionStaysOutOfItsSelect() async throws {
        await host.load(html: """
            <!doctype html><html><body>
            <select id="account" name="account">
              <option value="acct-public">Public</option>
              <option id="secret" value="acct-secret" selected>Secret Account</option>
            </select>
            </body></html>
            """)
        let hiding = try store(agentSelectors: ["#secret"])
        let reading = await source(hiding).read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let select = try XCTUnwrap(nodes(reading.page.root).first { $0.kind == .select }, tree(reading.page))
        for leaked in ["acct-secret", "Secret Account"] {
            XCTAssertFalse(tree(reading.page).contains(leaked), tree(reading.page))
            XCTAssertFalse(reading.page.html().contains(leaked), reading.page.html())
        }
        let generation = try XCTUnwrap(reading.generation)

        let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
        var refusals: [String] = []
        for guess in ["Secret Account", "acct-secret", "No Such Option"] {
            do {
                _ = try await automation.select(ref: select.ref, generation: generation, value: guess)
                XCTFail("\(guess) was selected")
            } catch {
                refusals.append(String(describing: error).replacingOccurrences(of: guess, with: "<guess>"))
            }
        }
        XCTAssertEqual(Set(refusals).count, 1, "the refusals tell a withheld option from none: \(refusals)")
        let chosen = try await host.webView.evaluateJavaScript("document.getElementById('account').value")
        XCTAssertEqual(chosen as? String, "acct-secret", "a refused select changed the page")

        _ = try await automation.select(ref: select.ref, generation: generation, value: "Public")
        let picked = try await host.webView.evaluateJavaScript("document.getElementById('account').value")
        XCTAssertEqual(picked as? String, "acct-public")
    }

    /// An agent-list selector the page cannot evaluate would hide nothing,
    /// so the page is withheld rather than shown unfiltered (A-M1).
    func test_invalidExcludeSelectorFailsClosed() async throws {
        let reading = await source(try store(agentSelectors: ["::bad(", ".ad"]))
            .read(options: BrowserSnapshotOptions())
        let reason = try XCTUnwrap(reading.page.unavailableReason)
        XCTAssertTrue(reason.hasPrefix(AgentPage.unavailablePrefix), reason)
        XCTAssertTrue(reason.contains(AgentPageBuilder.agentListReason), reason)
        XCTAssertNil(reading.page.root)
        XCTAssertNil(reading.generation)
    }

    /// A ref taken before its element joined the agent list stops resolving
    /// once a walk has seen it excluded, even a reading walk that keeps the
    /// refs, and every ref goes stale when the store changes (A-M2).
    func test_refToNewlyExcludedElementIsStale() async throws {
        // Both stores before the automation: adding to a store is a change to
        // the lists, which by itself invalidates the automation's refs.
        let empty = try emptyStore()
        let withSide = try store(agentSelectors: ["#side"])
        let automation = BrowserAutomation(driver: driver, console: BrowserConsoleLog())
        let first = await source(empty).read(options: BrowserSnapshotOptions())
        let generation = try XCTUnwrap(first.generation)
        let sideButton = try XCTUnwrap(firstNode(first.page, kind: .button, named: "Side button"))
        let press = try XCTUnwrap(firstNode(first.page, kind: .button, named: "Press me"))

        let kept = await source(withSide).read(options: BrowserSnapshotOptions(), keepingRefs: true)
        XCTAssertEqual(kept.generation, generation, "a reading walk keeps the generation")
        do {
            _ = try await automation.click(ref: sideButton.ref, generation: generation, native: false)
            XCTFail("a withheld element was clicked")
        } catch let error as BrowserAutomationError {
            guard case .staleRef = error else { return XCTFail("\(error)") }
        }

        await automation.invalidateRefs()
        do {
            _ = try await automation.click(ref: press.ref, generation: generation, native: false)
            XCTFail("a ref outlived a change to the hidden-items lists")
        } catch let error as BrowserAutomationError {
            guard case .staleRef = error else { return XCTFail("\(error)") }
        }
    }

    /// Under Hide Images an image is never visited, so it spends no ref and
    /// the refs the agent sees stay consecutive (A-M3).
    func test_hiddenImagesSpendNoRefs() async throws {
        await host.load(html: """
            <!doctype html><html><body>
            <a href="/one">One</a><img src="data:," alt="Logo" width="10" height="10">
            <span role="img" aria-label="Badge">*</span><a href="/two">Two</a>
            </body></html>
            """)
        let hiding = AgentPageSource(driver: driver, hiddenItems: try emptyStore(), privacy: { .off },
                                     hideImages: { true })
        let page = await hiding.agentPage(options: BrowserSnapshotOptions())
        let refs = nodes(page.root).map(\.ref).filter { $0.hasPrefix("e") }
        XCTAssertEqual(refs, ["e1", "e2"], tree(page))
        XCTAssertFalse(tree(page).contains("Logo"), tree(page))
    }

    /// ARIA grid roles print as written, as today's snapshot prints them (A-I4).
    func test_gridRolesKeepTodaysRoles() async throws {
        await host.load(html: """
            <!doctype html><html><body>
            <div role="grid"><div role="row"><div role="gridcell">Alpha</div></div></div>
            <div role="treegrid"><div role="row"><div role="gridcell">Beta</div></div></div>
            </body></html>
            """)
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let lines = tree(reading.page).split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(Array(lines.dropFirst()), [
            "- grid [ref=e1]:", "- row [ref=e2]:", "- gridcell \"Alpha\" [ref=e3]",
            "- treegrid [ref=e4]:", "- row [ref=e5]:", "- gridcell \"Beta\" [ref=e6]"
        ])
        let html = reading.page.html()
        XCTAssertTrue(html.contains("<table") && html.contains("<td"), html)
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

    func test_lineStructureSurvivesTheWalk() async throws {
        // `browser_text` keeps the lines `innerText` reads: a `<br>`, a block
        // boundary and a `<pre>`'s newlines each start a new line.
        await host.load(html: """
        <!doctype html><html><body>
          <p>123 Main Street<br>Springfield</p>
          <div><div>Price</div><div>$10</div></div>
          <pre>let a = 1
        let b = 2</pre>
          <span>Buy</span> <b>now</b>
        </body></html>
        """)
        let page = await source(try emptyStore()).agentPage(options: BrowserSnapshotOptions())
        XCTAssertNil(page.unavailableReason)
        XCTAssertEqual(page.text(), "123 Main Street\nSpringfield\nPrice\n$10\nlet a = 1\nlet b = 2\nBuy now")
        let text = tree(page)
        XCTAssertFalse(text.contains("StreetSpringfield"), text)
        XCTAssertFalse(text.contains("Price$10"), text)
        XCTAssertFalse(text.contains("- text: \n"), text)
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

    /// A walk-local reference (`g` for a plain paragraph or label, `t` for a
    /// text piece) is never in the snapshot runtime's ref table, so an action
    /// given one is refused as an unknown ref, never resolved to an element.
    func test_walkLocalRefsAreUnknownToActions() async throws {
        let automation = BrowserAutomation(webView: host.webView, console: BrowserConsoleLog())
        let snap = try await automation.agentSnapshot()
        let refs = nodes(snap.page.root).map(\.ref)
        let generic = try XCTUnwrap(refs.first { $0.hasPrefix("g") }, "the fixture's paragraphs carry g refs")
        let text = try XCTUnwrap(refs.first { $0.hasPrefix("t") }, "the fixture's text carries t refs")
        for ref in [generic, text] {
            do {
                _ = try await automation.click(ref: ref, generation: snap.generation, native: false)
                XCTFail("\(ref) was clicked")
            } catch let error as BrowserAutomationError {
                guard case .unknownRef = error else { return XCTFail("\(ref): \(error)") }
            }
        }
    }

    /// The install guard compares the host's version with the one the walker
    /// leaves on the page; if they differ the walker reinstalls on every read.
    func test_walkerVersionMatchesTheHost() throws {
        let source = try AgentPageWalkerRuntime.source
        let pattern = try NSRegularExpression(pattern: #"const VERSION = (\d+);"#)
        let range = NSRange(source.startIndex..., in: source)
        let match = try XCTUnwrap(pattern.firstMatch(in: source, range: range), "no VERSION in the walker")
        let digits = try XCTUnwrap(Range(match.range(at: 1), in: source))
        XCTAssertEqual(Int(source[digits]), AgentPageWalkerRuntime.version)
    }

    /// Tables print as today's snapshot prints them: each `thead`, `tbody`
    /// and `tfoot` (implicit or written) as a numbered rowgroup, `th` as
    /// columnheader, and the explicit header and group roles kept.
    func test_tablesKeepTodaysRoles() async throws {
        await host.load(html: """
            <!doctype html><html><body><table>
            <thead><tr><th>Head</th></tr></thead>
            <tbody><tr><td role="rowheader">Side</td><td>Body</td></tr></tbody>
            </table><div role="rowgroup"><div role="row"><span role="columnheader">Col</span></div></div>
            </body></html>
            """)
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        let lines = tree(reading.page).split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(Array(lines.dropFirst()), [
            "- table [ref=e1]:", "- rowgroup [ref=e2]:", "- row [ref=e3]:", "- columnheader \"Head\" [ref=e4]",
            "- rowgroup [ref=e5]:", "- row [ref=e6]:", "- rowheader \"Side\" [ref=e7]", "- cell \"Body\" [ref=e8]",
            "- rowgroup [ref=e9]:", "- row [ref=e10]:", "- columnheader \"Col\" [ref=e11]"
        ])
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
        // Text pieces and the document root have no element of their own to
        // record; every other node must, so a pick on it maps back to the page.
        let unplaced = nodes(reading.page.root).filter {
            $0.kind != .text && $0.kind != .document && $0.selector.isEmpty
        }
        XCTAssertEqual(unplaced.map { "\($0.ref) \($0.kind)" }, [])
    }

    /// Thousands of rows in one container: the structural path counts each
    /// parent's children once, not once per row, so the walk stays inside
    /// the default budget and every path still names its own row (review f8).
    func test_wideContainerFitsTheBudget() async throws {
        let rows = (0..<3000).map { "<li><a href=\"/r\($0)\">Link \($0)</a></li>" }
        await host.load(html: "<!doctype html><html><body><ul id=\"rows\">\(rows.joined())</ul></body></html>")
        let reading = await source(try emptyStore()).read(options: BrowserSnapshotOptions())
        XCTAssertNil(reading.page.unavailableReason)
        let links = nodes(reading.page.root).filter { $0.kind == .link }
        XCTAssertEqual(links.count, 3000)
        let last = try XCTUnwrap(links.last)
        let named = try await host.webView.evaluateJavaScript(
            "Array.from(document.querySelectorAll(\(String(reflecting: last.selector)))).map(e => e.textContent)")
        XCTAssertEqual(named as? [String], ["Link 2999"], last.selector)
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
