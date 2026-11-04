import AppKit
import WebKit
import XCTest
@testable import AgenticToolkitMacOS

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
