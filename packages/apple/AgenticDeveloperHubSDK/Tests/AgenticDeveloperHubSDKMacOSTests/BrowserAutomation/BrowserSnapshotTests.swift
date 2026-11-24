import XCTest
import WebKit
@testable import AgenticDeveloperHubSDKMacOS

/// `browser_snapshot`'s tree for the legacy fixtures, now through the agent
/// page (an empty agent list, privacy off): the agent page is the only
/// snapshot there is, and these pin it to the legacy shape.
@MainActor
final class BrowserSnapshotTests: XCTestCase {

    private var automations: [ObjectIdentifier: BrowserAutomation] = [:]

    /// One automation per page, so a scope by ref resolves the refs of the
    /// page's last snapshot.
    private func snapshot(
        _ page: OffscreenWebView, options: BrowserSnapshotOptions = .init()
    ) async throws -> AgentTestSnapshot {
        let key = ObjectIdentifier(page)
        let automation = automations[key] ?? BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())
        automations[key] = automation
        return try await automation.agentSnapshot(options)
    }

    func testFormFixtureRendersLikePlaywright() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, try OffscreenWebView.expected("form"))
        XCTAssertEqual(snap.page.title, "Sign in")
        XCTAssertGreaterThan(snap.generation, 0)
    }

    func testLandmarksFixtureSkipsHiddenAndCollapsesGenerics() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, try OffscreenWebView.expected("landmarks"))
    }

    func testRefsRestartEverySnapshotAndGenerationAdvances() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let first = try await snapshot(page)
        let second = try await snapshot(page)
        XCTAssertEqual(second.generation, first.generation + 1)
        XCTAssertTrue(second.text.contains("[ref=e1]"))
    }

    func testInteractiveOnlyKeepsRefsAndDropsText() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        var options = BrowserSnapshotOptions()
        options.interactiveOnly = true
        let snap = try await snapshot(page, options: options)
        XCTAssertFalse(snap.text.contains("- text:"))
        XCTAssertTrue(snap.text.contains("- link \"Forgot password?\""))
        XCTAssertFalse(snap.text.contains("- heading"))
    }

    func testIncludeURLsAddsUrlAttribute() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        var options = BrowserSnapshotOptions()
        options.includeURLs = true
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.contains("- link \"Forgot password?\" [ref=e11] [url=http://fixture.test/reset]"))
    }

    /// An SVG anchor's `href` property is an SVGAnimatedString, not a string.
    /// The snapshot must still decode, and name the link's destination.
    func testSVGLinkHasAStringURL() async throws {
        let page = OffscreenWebView()
        await page.load(html: """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="40">
            <a href="/chart"><text x="0" y="20">Chart</text></a>
            </svg>
            """)
        var options = BrowserSnapshotOptions()
        options.includeURLs = true
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.contains("- link \"Chart\""), snap.text)
        XCTAssertTrue(snap.text.contains("[url=http://fixture.test/chart]"), snap.text)
    }

    func testScopeByRefSnapshotsOnlyThatSubtree() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        _ = try await snapshot(page)
        var options = BrowserSnapshotOptions()
        options.scope = "e3"
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.hasPrefix("- navigation [ref=e1]:"))
        XCTAssertFalse(snap.text.contains("contentinfo"))
    }

    func testDepthLimitsTheTree() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "landmarks")
        var options = BrowserSnapshotOptions()
        options.depth = 2
        let snap = try await snapshot(page, options: options)
        XCTAssertTrue(snap.text.contains("- navigation [ref=e3]"))
        XCTAssertFalse(snap.text.contains("- list "))
    }

    func testLongNamesAreCut() async throws {
        let page = OffscreenWebView()
        let long = String(repeating: "x", count: 120)
        await page.load(html: "<button>\(long)</button>")
        let snap = try await snapshot(page)
        XCTAssertTrue(snap.text.contains("\"" + String(repeating: "x", count: 100) + "…\""))
    }

    func testEmptyDocumentRendersRootWithColon() async throws {
        let page = OffscreenWebView()
        await page.load(html: "", baseURL: URL(string: "about:blank"))
        let snap = try await snapshot(page)
        XCTAssertEqual(snap.text, "- document:\n")
    }

    func testFindReturnsMatchingRefs() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let snap = try await snapshot(page)
        let matches = BrowserToolSet.find("forgot", in: snap.page)
        XCTAssertEqual(matches.map(\.ref), ["e11"])
        XCTAssertEqual(matches.first?.role, "link")
    }

    /// The page's own scripts must not see or replace the runtime.
    func testRuntimeIsInvisibleToThePage() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        _ = try await snapshot(page)
        let seen = try await page.webView.evaluateJavaScript(
            "String(typeof window.__adkitchen) + ':' + String(typeof document.querySelector('a').__adkitchenRef)",
            in: nil, contentWorld: .page)
        XCTAssertEqual(seen as? String, "undefined:undefined")
    }

    func testTextReturnsInnerTextOfMain() async throws {
        let page = OffscreenWebView()
        try await page.load(fixture: "form")
        let snap = try await snapshot(page)
        let text = snap.page.text()
        XCTAssertTrue(text.hasPrefix("Sign in"))
        XCTAssertTrue(text.contains("Forgot password?"))
    }
}
