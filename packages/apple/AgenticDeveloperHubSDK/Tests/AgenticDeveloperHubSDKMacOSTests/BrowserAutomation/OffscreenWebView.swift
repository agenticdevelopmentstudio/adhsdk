import AppKit
import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A web view in a window that is never ordered front, so layout and
/// `getBoundingClientRect` work without taking the screen.
@MainActor
final class OffscreenWebView: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var automation: BrowserAutomation?
    let window: NSWindow
    let webView: WKWebView
    private var continuation: CheckedContinuation<Void, Never>?
    private var lastError: Error?

    override init() {
        self.window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: 800, height: 600),
            styleMask: .borderless, backing: .buffered, defer: false)
        self.webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        super.init()
        self.window.contentView = self.webView
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
    }

    /// Orders the window in behind everything, still far off every display,
    /// so `isVisible` is true: a screenshot refuses a window that is not.
    /// Never ordered front and never key, so it takes nothing from the screen.
    func orderInOffscreen() {
        window.orderBack(nil)
    }

    func load(html: String, baseURL: URL? = URL(string: "http://fixture.test/")) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    /// A real navigation to `url` that serves `html`. Unlike `load(html:)` (`loadHTMLString`, which
    /// on macOS 26 adds no back-forward item), it leaves an entry to go back from.
    func navigate(to url: URL, html: String) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.webView.loadSimulatedRequest(URLRequest(url: url), responseHTML: html)
        }
    }

    /// Loads a local file and returns once WebKit has finished (or failed) it,
    /// with the failure, if any, so a test can say why there is nothing to go back to.
    @discardableResult
    func load(fileURL url: URL) async -> Error? {
        lastError = nil
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return lastError
    }

    func load(fixture name: String) async throws {
        let url = try XCTUnwrap(Bundle(for: OffscreenWebView.self).url(forResource: name, withExtension: "html"))
        await self.load(html: try String(contentsOf: url, encoding: .utf8))
    }

    static func expected(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle(for: OffscreenWebView.self).url(forResource: name, withExtension: "txt"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.continuation?.resume()
        self.continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        lastError = error
        self.continuation?.resume()
        self.continuation = nil
    }

    /// A load that never commits (a file WebKit may not read, say) fails here, not
    /// in `didFail`; without this the loader would wait forever.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        lastError = error
        self.continuation?.resume()
        self.continuation = nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor @Sendable () -> Void) {
        self.automation?.dialogRaised(kind: .alert, message: message)
        completionHandler()
    }
}

/// What `browser_snapshot` prints of a page, through the agent page with an
/// empty agent list and privacy off: the only snapshot there is.
struct AgentTestSnapshot {
    let text: String
    let generation: Int
    let page: AgentPage
}

/// One empty agent list for every automation test, made once per run.
@MainActor
enum AgentTestPages {
    private static var shared: BrowserHiddenItemsStore?

    static func store() throws -> BrowserHiddenItemsStore {
        if let shared { return shared }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentTestPages-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent(BrowserHiddenItemsStore.fileName))
        shared = store
        return store
    }
}

/// Test reads of a page. The raw reads are gone from `BrowserAutomation`
/// (every read a model gets is the agent page's), so a test reads the agent
/// page as the tools do, or the page's own text in the page world.
@MainActor
extension BrowserAutomation {
    private func agentSource() throws -> AgentPageSource {
        AgentPageSource(driver: driver, hiddenItems: try AgentTestPages.store(),
                        privacy: { .off }, hideImages: { false })
    }

    /// A snapshot walk, rendered as `browser_snapshot` renders it (delta included).
    func agentSnapshot(_ options: BrowserSnapshotOptions = .init()) async throws -> AgentTestSnapshot {
        let source = try agentSource()
        let reading = await source.read(options: options, keepingRefs: false)
        if let failure = reading.failure { throw failure }
        let tree = reading.page.snapshotTree(AgentPageSource.renderingOptions(options))
        return AgentTestSnapshot(text: agentSnapshotText(tree, delta: options.delta),
                                 generation: reading.generation ?? 0, page: reading.page)
    }

    /// The agent page's whole text, from a walk that keeps the refs: what
    /// `browser_wait_for` polls.
    func agentText() async -> String? {
        guard let source = try? agentSource() else { return nil }
        let page = await source.read(options: BrowserSnapshotOptions(), keepingRefs: true).page
        return BrowserToolSet.wholeText(page)
    }

    /// The page's own `innerText` of `scope` (main, else body), read in the
    /// page world: the test's view of what the page did, not the agent's.
    func pageText(scope: String?) async throws -> String {
        let body = "const el = scope ? document.querySelector(scope)"
            + " : (document.querySelector('main') || document.body);"
            + " return el ? el.innerText : '';"
        let value = try await driver.callAsyncFunction(body: body, arguments: ["scope": scope ?? NSNull()],
                                                       world: .page)
        return value as? String ?? ""
    }
}
