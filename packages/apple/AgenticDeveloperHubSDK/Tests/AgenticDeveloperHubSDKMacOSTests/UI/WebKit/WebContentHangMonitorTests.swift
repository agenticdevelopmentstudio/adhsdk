import AppKit
import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Drives a real `WKWebView` and its content process: the hang is a real
/// infinite loop in the page, and the recovery is a real process termination.
@MainActor
final class WebContentHangMonitorTests: XCTestCase {

    /// Fast enough for a test; the shape of `Timing.standard`. For the tests
    /// that expect an end.
    private let quick = WebContentHangMonitor.Timing(interval: .milliseconds(100), timeout: .milliseconds(800))

    /// For the tests that expect a responsive page to be left alone: a
    /// timeout long enough that a slow process launch on a busy machine is
    /// never read as a hang.
    private let patient = WebContentHangMonitor.Timing(interval: .milliseconds(100), timeout: .seconds(5))

    /// A page that finishes loading, then never lets its main thread go —
    /// the shape of the hang that froze a status site: a loop spinning on
    /// `Array.indexOf`.
    private let hangingPage = """
    <html><body>hangs<script>
    window.addEventListener('load', () => setTimeout(() => { const a = []; for (;;) { a.indexOf(1); } }, 50));
    </script></body></html>
    """

    private let quietPage = "<html><body>fine</body></html>"

    private var host: HostedWebView!

    override func setUp() async throws {
        host = HostedWebView()
    }

    override func tearDown() async throws {
        host.webView.terminateWebContentProcess()
        host = nil
    }

    func testEndsTheProcessOfAHungPage() async throws {
        await host.load(html: hangingPage)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor.start()

        let terminated = await host.waitForTermination(within: .seconds(10))
        XCTAssertTrue(terminated, "a page stuck in a loop must have its content process ended")
        XCTAssertTrue(monitor.isRunning, "the monitor keeps watching the page that replaces it")
        monitor.stop()
    }

    func testAPageReloadedAfterTheHangIsLeftRunning() async throws {
        await host.load(html: hangingPage)
        let first = WebContentHangMonitor(webView: host.webView, timing: quick)
        first.start()
        let firstTermination = await host.waitForTermination(within: .seconds(10))
        XCTAssertTrue(firstTermination)
        first.stop()

        // What a host does in webViewWebContentProcessDidTerminate(_:), with
        // a monitor that tolerates a slow relaunch.
        let monitor = WebContentHangMonitor(webView: host.webView, timing: patient)
        monitor.start()
        await host.load(html: quietPage)
        let terminatedAgain = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(terminatedAgain, "the fresh, responsive process must be left alone")
        let answer = try await host.webView.evaluateJavaScript("document.body.textContent")
        XCTAssertEqual(answer as? String, "fine")
        monitor.stop()
    }

    func testLeavesAResponsivePageAlone() async throws {
        await host.load(html: quietPage)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: patient)
        monitor.start()

        let terminated = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(terminated, "a page that answers its pings is never ended")
        monitor.stop()
    }

    func testAStallOfTheAppsOwnMainThreadEndsNothing() async throws {
        await host.load(html: quietPage)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor.start()
        try await Task.sleep(for: .milliseconds(150))

        // Longer than the timeout: the page's answer queues behind this.
        stallMainThread(seconds: 1.5)

        let terminated = await host.waitForTermination(within: .seconds(2))
        XCTAssertFalse(terminated, "a page whose answer waited on the app itself is not hung")
        monitor.stop()
    }

    /// Blocks the main thread outright, as a slow synchronous call in the app
    /// would.
    private func stallMainThread(seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func testAPageUnderASheetIsNotEndedUntilTheSheetCloses() async throws {
        await host.load(html: hangingPage)
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: .titled, backing: .buffered, defer: false)
        sheet.isReleasedWhenClosed = false
        host.window.beginSheet(sheet, completionHandler: nil)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor.start()

        let underSheet = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(underSheet, "a page may be waiting on the dialog the sheet shows")

        host.window.endSheet(sheet)
        let afterSheet = await host.waitForTermination(within: .seconds(10))
        XCTAssertTrue(afterSheet, "once the sheet is gone, the hang is the page's own")
        monitor.stop()
    }

    func testAnInspectablePageIsNeverEnded() async throws {
        host.webView.isInspectable = true
        await host.load(html: hangingPage)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor.start()

        let terminated = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(terminated, "it may be paused at a breakpoint")
        monitor.stop()
    }

    func testAStoppedMonitorEndsNothing() async throws {
        await host.load(html: hangingPage)
        let monitor = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor.start()
        monitor.stop()
        XCTAssertFalse(monitor.isRunning)

        let terminated = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(terminated, "stop() must stop the watching")
    }

    func testAReleasedMonitorEndsNothing() async throws {
        await host.load(html: hangingPage)
        var monitor: WebContentHangMonitor? = WebContentHangMonitor(webView: host.webView, timing: quick)
        monitor?.start()
        weak let released = monitor
        monitor = nil
        XCTAssertNil(released, "the running loop must not keep the monitor alive")

        let terminated = await host.waitForTermination(within: .seconds(3))
        XCTAssertFalse(terminated, "releasing the monitor must stop the watching")
    }

    func testDescribesAPageByItsHostOrItsURL() {
        func describe(_ string: String) -> String { WebContentHangMonitor.describe(URL(string: string)) }
        XCTAssertEqual(describe("https://status.example.com/x"), "Page on status.example.com")
        XCTAssertEqual(describe("file:///tmp/index.html"), "Page file:///tmp/index.html")
        XCTAssertEqual(describe("about:blank"), "Page about:blank")
        XCTAssertEqual(WebContentHangMonitor.describe(nil), "A page with no URL")
    }
}

/// A web view in an off-screen window, recording when WebKit reports its
/// content process ended.
@MainActor
private final class HostedWebView: NSObject, WKNavigationDelegate {
    let window: NSWindow
    let webView: WKWebView
    private var loaded: CheckedContinuation<Void, Never>?
    private var terminations = 0

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: -20000, y: -20000, width: 400, height: 300),
            styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        super.init()
        window.contentView = webView
        webView.navigationDelegate = self
    }

    /// Loads `html` and returns once the load ends — finished, failed, or cut
    /// short by its process ending.
    func load(html: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            loaded = continuation
            webView.loadHTMLString(html, baseURL: URL(string: "https://fixture.test/"))
        }
    }

    /// Whether a termination is reported within `limit` of the call.
    func waitForTermination(within limit: Duration) async -> Bool {
        let before = terminations
        let deadline = ContinuousClock.now + limit
        while ContinuousClock.now < deadline {
            if terminations > before { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return terminations > before
    }

    private func finishLoad() {
        loaded?.resume()
        loaded = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoad()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishLoad()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        finishLoad()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        terminations += 1
        finishLoad()
    }
}
