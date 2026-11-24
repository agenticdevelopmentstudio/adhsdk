import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The hidden-items style's scripts (recipe
/// workspace/browser/hidden-items-rendering, vectors 001–005, 011, 012).
@MainActor
final class BrowserHiddenItemsStyleTests: XCTestCase {

    // MARK: - Preparing a navigation's rules

    /// Every read superseded: a last read nothing supersedes decides, never
    /// the previous site's rules (re-review follow-up).
    func test_prepareEndsWithAnUncheckedReadWhenEveryReadIsSuperseded() async {
        var asked: [Bool] = []
        let selectors = await WebKitBrowserEngine.preparedHiddenItemSelectors(
            isTornDown: { false },
            read: { checks in
                asked.append(checks)
                return checks ? .superseded : .selectors(["#new-site"])
            })
        XCTAssertEqual(selectors, ["#new-site"])
        XCTAssertEqual(asked, [true, true, true, false])
    }

    /// The last read failing starts the document with no rules: fail closed
    /// against the previous site's (re-review follow-up).
    func test_prepareStartsWithNoRulesWhenTheLastReadFails() async {
        let selectors = await WebKitBrowserEngine.preparedHiddenItemSelectors(
            isTornDown: { false },
            read: { checks in checks ? .superseded : .failed })
        XCTAssertEqual(selectors, [])
    }

    func test_prepareKeepsTheRulesOnTeardownOrAnOutrightFailure() async {
        let tornDown = await WebKitBrowserEngine.preparedHiddenItemSelectors(
            isTornDown: { true }, read: { _ in .superseded })
        XCTAssertNil(tornDown)
        let failed = await WebKitBrowserEngine.preparedHiddenItemSelectors(
            isTornDown: { false }, read: { _ in .failed })
        XCTAssertNil(failed)
        let first = await WebKitBrowserEngine.preparedHiddenItemSelectors(
            isTornDown: { false }, read: { _ in .selectors(["#ad"]) })
        XCTAssertEqual(first, ["#ad"])
    }

    // MARK: - Script text

    func test_cssOneRulePerSelector() {
        let css = BrowserHiddenItemsStyle.css(selectors: ["a.ad", "#promo"])
        XCTAssertTrue(css.contains("a.ad { display: none !important; }"))
        XCTAssertTrue(css.contains("#promo { display: none !important; }"))
        XCTAssertEqual(css.components(separatedBy: "\n").count, 2)
    }

    func test_selectorsPassedAsJSON() throws {
        let evil = "x\"]); alert(1)//"
        let script = BrowserHiddenItemsStyle.applyScript(selectors: [evil])
        let json = try XCTUnwrap(String(data: try JSONEncoder().encode([evil]), encoding: .utf8))
        XCTAssertTrue(script.contains(json))
        // The raw quote never closes a string in the source.
        XCTAssertFalse(script.contains("x\"]); alert(1)"))
    }

    func test_emptySelectorsRemovesStyle() {
        let script = BrowserHiddenItemsStyle.applyScript(selectors: [])
        XCTAssertTrue(script.contains("\"\(BrowserHiddenItemsStyle.styleElementID)\""))
        XCTAssertTrue(script.contains("getElementById(ID)"))
        XCTAssertTrue(script.contains("existing?.remove()"))
    }

    // MARK: - On a page

    private static let fixture = """
        <!doctype html><html><head></head><body>
        <div class="ad" id="first">Ad</div>
        <div id="x">X</div>
        <p id="content">Content</p>
        </body></html>
        """

    private var host: OffscreenWebView!

    override func setUp() async throws {
        host = OffscreenWebView()
        await host.load(html: Self.fixture)
    }

    override func tearDown() async throws {
        host = nil
    }

    private func run(_ script: String) async throws {
        _ = try await host.webView.evaluateJavaScript(script + "\n;true", in: nil, contentWorld: .page)
    }

    private func page(_ body: String) async throws -> Any? {
        try await host.webView.callAsyncJavaScript(body, arguments: [:], in: nil, contentWorld: .page)
    }

    private func display(_ id: String) async throws -> String? {
        try await page("return getComputedStyle(document.getElementById('\(id)')).display;") as? String
    }

    private func styleCount(_ id: String) async throws -> Int {
        (try await page("return document.querySelectorAll('#\(id)').length;") as? Int) ?? -1
    }

    func test_emptySelectorsRemovesStyleOnPage() async throws {
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: [".ad"]))
        let value1 = try await styleCount(BrowserHiddenItemsStyle.styleElementID)
        XCTAssertEqual(value1, 1)
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: []))
        let value2 = try await styleCount(BrowserHiddenItemsStyle.styleElementID)
        XCTAssertEqual(value2, 0)
        let value3 = try await display("first")
        XCTAssertEqual(value3, "block")
    }

    func test_reapplyReplacesRulesInOneElement() async throws {
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: [".ad"]))
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: ["#x"]))
        let value4 = try await styleCount(BrowserHiddenItemsStyle.styleElementID)
        XCTAssertEqual(value4, 1)
        let value5 = try await display("first")
        XCTAssertEqual(value5, "block")
        let value6 = try await display("x")
        XCTAssertEqual(value6, "none")
    }

    func test_badSelectorIsolated() async throws {
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: ["::not-a-selector((", ".ad"]))
        let value7 = try await display("first")
        XCTAssertEqual(value7, "none")
        let value8 = try await display("content")
        XCTAssertEqual(value8, "block")
    }

    func test_lateContentHidden() async throws {
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: [".ad"]))
        _ = try await page("""
            const el = document.createElement('div');
            el.className = 'ad'; el.id = 'late'; el.textContent = 'Late';
            document.body.appendChild(el);
            return true;
            """)
        let value9 = try await display("late")
        XCTAssertEqual(value9, "none")
    }

    func test_previewIndependentOfSavedRules() async throws {
        try await run(BrowserHiddenItemsStyle.applyScript(selectors: [".ad"]))
        try await run(BrowserHiddenItemsStyle.previewScript(selectors: ["#x"]))
        let v10 = try await styleCount(BrowserHiddenItemsStyle.previewStyleElementID)
        XCTAssertEqual(v10, 1)
        let v11 = try await display("x")
        XCTAssertEqual(v11, "none")
        try await run(BrowserHiddenItemsStyle.previewScript(selectors: []))
        let v12 = try await styleCount(BrowserHiddenItemsStyle.previewStyleElementID)
        XCTAssertEqual(v12, 0)
        let v13 = try await display("x")
        XCTAssertEqual(v13, "block")
        let v14 = try await styleCount(BrowserHiddenItemsStyle.styleElementID)
        XCTAssertEqual(v14, 1)
        let v15 = try await display("first")
        XCTAssertEqual(v15, "none")
    }

    func test_installScriptHidesFromDocumentStart() async throws {
        host.webView.configuration.userContentController.addUserScript(WKUserScript(
            source: BrowserHiddenItemsStyle.installScript(selectors: [".ad"]),
            injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page))
        await host.load(html: Self.fixture)
        let v16 = try await styleCount(BrowserHiddenItemsStyle.styleElementID)
        XCTAssertEqual(v16, 1)
        let v17 = try await display("first")
        XCTAssertEqual(v17, "none")
    }
}
