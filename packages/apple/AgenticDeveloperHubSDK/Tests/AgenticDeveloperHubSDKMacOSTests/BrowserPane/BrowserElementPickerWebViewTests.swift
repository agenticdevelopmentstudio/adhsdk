import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The picker script in a real, offscreen web view (recipe
/// workspace/browser/element-picker, vectors 005–010 and 026).
@MainActor
final class BrowserElementPickerWebViewTests: XCTestCase {

    private static let longText = String(repeating: "Sponsored stories about everything ", count: 4)

    private static let fixture = """
    <!doctype html>
    <html><body>
      <div id="header">Header</div>
      <div class="css-1x2y3z ad-card" data-test="target">Sponsored stories</div>
      <div class="css-9q8w7e ad-card">Another sponsor</div>
      <div class="only" data-test="only">Lonely</div>
      <span id="promo" class="a8f3k2q9 x_9f8e7d promo-tag" data-test="random">Promo</span>
      <span class="b7e2c4d1 promo-tag">More promo</span>
      <div data-test="long">   \(BrowserElementPickerWebViewTests.longText)  </div>
      <img alt="Logo" data-test="img" src="data:image/gif;base64,R0lGODlhAQABAAAAACw=">
      <hr data-test="hr">
      <a href="http://fixture.test/elsewhere" data-test="link">Go</a>
      <button data-test="button" onclick="window.pageClicked = true">Press</button>
      <section><p>One</p><p>Two</p><p>Three</p><p>Four</p><p>Five</p><p>Six</p></section>
      <div data-test="frame-holder"><iframe data-test="frame" style="width: 200px; height: 100px"
        srcdoc="<a href='http://ads.test/'>Ad</a>"></iframe></div>
    </body></html>
    """

    private var host: OffscreenWebView!
    private var picks: [BrowserPickCandidate] = []
    private var cancels = 0
    private var pickExpectation: XCTestExpectation?
    private var picker: BrowserElementPicker!

    override func setUp() async throws {
        host = OffscreenWebView()
        await host.load(html: Self.fixture)
        picks = []
        cancels = 0
        picker = BrowserElementPicker(
            webView: host.webView, list: .user,
            onPick: { [weak self] candidate in
                self?.picks.append(candidate)
                self?.pickExpectation?.fulfill()
            },
            onCancel: { [weak self] in
                self?.cancels += 1
                self?.pickExpectation?.fulfill()
            })
        try await picker.start()
    }

    override func tearDown() async throws {
        picker.stop()
        picker = nil
        host = nil
    }

    /// Clicks `[data-test=<name>]` from the page's world, as a page click would
    /// arrive, and waits for the picker's message.
    private func pick(_ name: String) async throws -> BrowserPickCandidate {
        let expectation = expectation(description: "pick \(name)")
        pickExpectation = expectation
        _ = try await host.webView.callAsyncJavaScript(
            """
            const el = document.querySelector('[data-test="' + name + '"]');
            el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
            return true;
            """,
            arguments: ["name": name], in: nil, contentWorld: .page)
        await fulfillment(of: [expectation], timeout: 5)
        pickExpectation = nil
        return try XCTUnwrap(picks.last)
    }

    private func page(_ body: String, _ arguments: [String: Any] = [:]) async throws -> Any? {
        try await host.webView.callAsyncJavaScript(body, arguments: arguments, in: nil, contentWorld: .page)
    }

    func test_randomClassesRejected() async throws {
        let candidate = try await pick("target")
        XCTAssertEqual(candidate.allLikeIt, "div.ad-card")
        XCTAssertEqual(candidate.allLikeItCount, 2)
        XCTAssertTrue(candidate.allLikeItAllowed)
    }

    func test_idAndGeneratedClassesNeverInLooseSelector() async throws {
        let candidate = try await pick("random")
        let loose = try XCTUnwrap(candidate.allLikeIt, "two spans share promo-tag, so a loose selector exists")
        XCTAssertFalse(loose.contains("#"), "no id: \(loose)")
        XCTAssertTrue(loose.contains("promo-tag"), "the stable class is kept: \(loose)")
        for generated in ["a8f3k2q9", "x_9f8e7d", "b7e2c4d1"] {
            XCTAssertFalse(loose.contains(generated), "\(generated) looks generated: \(loose)")
        }
        XCTAssertEqual(loose, "span.promo-tag")
        XCTAssertEqual(candidate.allLikeItCount, 2)
    }

    /// A classless element has no "like it" selector: the bare tag would
    /// hide every `div` on the site.
    func test_classlessElementHasNoLooseSelector() async throws {
        let candidate = try await pick("long")
        XCTAssertNil(candidate.allLikeIt)
        XCTAssertEqual(candidate.allLikeItCount, 0)
        XCTAssertFalse(candidate.allLikeItAllowed)
    }

    func test_looseSelectorAbsentWhenSameAsThisItem() async throws {
        let candidate = try await pick("only")
        XCTAssertNil(candidate.allLikeIt)
        XCTAssertFalse(candidate.allLikeItAllowed)
    }

    func test_thisItemIsUnique() async throws {
        for name in ["target", "only", "random", "img", "hr", "button"] {
            let candidate = try await pick(name)
            let selector = try XCTUnwrap(candidate.thisItem, name)
            let unique = try await page(
                """
                const hits = document.querySelectorAll(selector);
                return hits.length === 1 && hits[0] === document.querySelector('[data-test="' + name + '"]');
                """, ["selector": selector, "name": name])
            XCTAssertEqual(unique as? Bool, true, "\(name): \(selector)")
        }
    }

    func test_labelFormat() async throws {
        let target = try await pick("target")
        XCTAssertEqual(target.label, "div \"Sponsored stories\"")
        let img = try await pick("img")
        XCTAssertEqual(img.label, "img \"Logo\"")
        let rule = try await pick("hr")
        XCTAssertEqual(rule.label, "hr")
        XCTAssertGreaterThan(target.pageElementCount, 10)
        let long = try await pick("long")
        let text = String(Self.longText.trimmingCharacters(in: .whitespaces).prefix(60))
        XCTAssertEqual(long.label, "div \"\(text)\"", "cut at 60 characters")
    }

    /// A click on blank space lands on `<body>`; the page's root never gets
    /// a This item selector, so that pick is refused and only the next
    /// click's pick arrives.
    func test_pageRootHasNoThisItem() async throws {
        _ = try await page(
            "document.body.dispatchEvent(new MouseEvent('click', "
                + "{ bubbles: true, cancelable: true, view: window })); "
                + "document.documentElement.dispatchEvent(new MouseEvent('click', "
                + "{ bubbles: true, cancelable: true, view: window })); return true;")
        let next = try await pick("only")
        XCTAssertEqual(picks.count, 1, "neither root pick reached onPick")
        XCTAssertNotNil(next.thisItem)
    }

    func test_pageCannotSeePickerWorld() async throws {
        let seen = try await page("return [typeof window.__adkFinder, typeof window.__adkPicker].join(',');")
        XCTAssertEqual(seen as? String, "undefined,undefined")
    }

    func test_pageClicksAreSwallowed() async throws {
        _ = try await pick("button")
        let clicked = try await page("return window.pageClicked === true;")
        XCTAssertEqual(clicked as? Bool, false, "the page's onclick never ran")

        _ = try await pick("link")
        let href = try await page("return location.href;")
        XCTAssertEqual(href as? String, "http://fixture.test/", "the link was not followed")
        XCTAssertEqual(picks.count, 2, "one pick message per click")
    }

    /// A frame's clicks never reach the main frame, so selecting turns its
    /// pointer events off: the click lands on what holds it and picks the
    /// frame element itself (vector 032).
    func test_clickOverFramePicksFrameElement() async throws {
        let pointer = try await page("return getComputedStyle(document.querySelector('iframe')).pointerEvents;")
        XCTAssertEqual(pointer as? String, "none", "frames take no pointer events while selecting")

        let expectation = expectation(description: "frame pick")
        pickExpectation = expectation
        _ = try await page(
            """
            const r = document.querySelector('[data-test="frame"]').getBoundingClientRect();
            document.querySelector('[data-test="frame-holder"]').dispatchEvent(new MouseEvent('click', {
              bubbles: true, cancelable: true, view: window,
              clientX: r.left + r.width / 2, clientY: r.top + r.height / 2 }));
            return true;
            """)
        await fulfillment(of: [expectation], timeout: 5)
        pickExpectation = nil
        let selector = try XCTUnwrap(picks.last?.thisItem)
        let isFrame = try await page(
            "return document.querySelector(selector) === document.querySelector('[data-test=\"frame\"]');",
            ["selector": selector])
        XCTAssertEqual(isFrame as? Bool, true, "picked the iframe: \(selector)")

        picker.stop()
        let restored = try await page("return getComputedStyle(document.querySelector('iframe')).pointerEvents;")
        XCTAssertEqual(restored as? String, "auto", "stop gives frames their pointer events back")
    }

    func test_escapePostsCancel() async throws {
        let expectation = expectation(description: "cancel")
        pickExpectation = expectation
        _ = try await page(
            "document.body.dispatchEvent(new KeyboardEvent('keydown', "
                + "{ key: 'Escape', bubbles: true, cancelable: true })); return true;")
        await fulfillment(of: [expectation], timeout: 5)
        XCTAssertEqual(cancels, 1)
    }

    func test_stopRemovesPicker() async throws {
        _ = try await page(
            "document.querySelector('[data-test=\"target\"]')"
                + ".dispatchEvent(new MouseEvent('mousemove', { bubbles: true })); return true;")
        let before = try await page("return document.documentElement.lastElementChild.tagName;")
        XCTAssertEqual(before as? String, "DIV", "the outline follows the pointer")
        picker.stop()
        let left = try await host.webView.evaluateJavaScript(
            "typeof globalThis.__adkPicker", in: nil, contentWorld: BrowserElementPicker.world)
        XCTAssertEqual(left as? String, "undefined")
        let outlines = try await page("return document.documentElement.lastElementChild.tagName;")
        XCTAssertEqual(outlines as? String, "BODY", "the outline is gone")
    }
}
