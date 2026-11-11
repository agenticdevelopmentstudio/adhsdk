import XCTest
import Combine
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BrowserPaneAutomationTests: XCTestCase {

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makePane(settings: SettingsStore? = nil) -> SafariBrowserPaneViewController {
        let pane = SafariBrowserPaneViewController(
            store: EphemeralPaneStateStore(), settings: settings ?? makeSettings())
        _ = pane.view
        return pane
    }

    private func consoleScriptCount(_ webView: WKWebView) -> Int {
        webView.configuration.userContentController.userScripts
            .filter { $0.source == BrowserConsoleLog.script }
            .count
    }

    /// Whether the console message handler is registered, asked of a page:
    /// a registered handler is visible to the page world as
    /// `window.webkit.messageHandlers.<name>`. Loads a small page into
    /// `webView` to ask on. Safe either way, unlike adding a second handler,
    /// which raises an exception that takes the whole test bundle down.
    private func hasConsoleHandler(_ webView: WKWebView) async -> Bool? {
        loads += 1
        let marker = "handler-\(loads)"
        webView.loadHTMLString("<meta name=\"test-load\" content=\"\(marker)\">", baseURL: nil)
        let ready = "document.readyState === 'complete' && "
            + "document.querySelector('meta[name=test-load]')?.content === '\(marker)'"
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            if (try? await webView.evaluateJavaScript(ready) as? Bool) == true, !webView.isLoading { break }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        let probe = "!!(window.webkit && window.webkit.messageHandlers"
            + " && window.webkit.messageHandlers['\(BrowserConsoleLog.handlerName)'])"
        return try? await webView.evaluateJavaScript(probe) as? Bool
    }

    private var loads = 0

    /// Loads `html` and waits, with a deadline, until the page on screen is
    /// this one and has finished loading, and then until `until` holds.
    ///
    /// Polls for the page itself rather than for `isLoading`: right after
    /// `loadHTMLString` the web view can still report `false`, so a loop on
    /// `isLoading` could exit before the load had even started. A marker that
    /// changes on every load tells this page from the one before it.
    private func load(
        _ html: String,
        into pane: SafariBrowserPaneViewController,
        until: () -> Bool = { true }
    ) async {
        loads += 1
        let marker = "load-\(loads)"
        pane.webView.loadHTMLString("<meta name=\"test-load\" content=\"\(marker)\">" + html, baseURL: nil)
        let probe = "document.readyState === 'complete' && "
            + "document.querySelector('meta[name=test-load]')?.content === '\(marker)'"
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let loaded = (try? await pane.webView.evaluateJavaScript(probe) as? Bool) ?? false
            if loaded && !pane.webView.isLoading && until() { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    /// The `[ref=...]` on the first snapshot line that names `role`.
    private func ref(ofRole role: String, in snapshot: BrowserSnapshot) -> String? {
        for line in snapshot.text.split(separator: "\n") where line.contains("- \(role)") {
            guard let start = line.range(of: "[ref=") else { continue }
            let rest = line[start.upperBound...]
            if let end = rest.firstIndex(of: "]") { return String(rest[..<end]) }
        }
        return nil
    }

    func testConsoleScriptIsInstalledOnThePane() async {
        let pane = makePane()
        await load("<script>console.warn('hello pane')</script>", into: pane) {
            !pane.consoleLog.messages(level: nil).isEmpty
        }
        XCTAssertEqual(pane.consoleLog.messages(level: nil).map(\.text), ["hello pane"])
    }

    /// The brief's `makeConfiguration` count, tested where the script now
    /// lives: the pane's web view.
    func testConsoleCaptureOffInjectsNoConsoleScript() async {
        let settings = makeSettings()
        settings.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        let off = makePane(settings: settings)
        XCTAssertEqual(consoleScriptCount(off.webView), 0)
        let offHandler = await hasConsoleHandler(off.webView)
        XCTAssertEqual(offHandler, false)
        XCTAssertFalse(off.automation.isConsoleCaptureOn)
        await load("<script>console.warn('unheard')</script>", into: off)
        XCTAssertTrue(off.consoleLog.messages(level: nil).isEmpty)

        let captured = makePane()
        XCTAssertEqual(consoleScriptCount(captured.webView), 1)
        let onHandler = await hasConsoleHandler(captured.webView)
        XCTAssertEqual(onHandler, true)
        XCTAssertTrue(captured.automation.isConsoleCaptureOn)
    }

    /// `makeConfiguration` registers the handler only when told to.
    func testConfigurationRegistersTheHandlerOnlyWithCapture() async {
        let settings = makeSettings()
        let jar = SafariBrowserPaneViewController.resolveJar(settings: settings, context: .detached, label: "t")
        let off = WebKitBrowserEngine.makeConfiguration(
            settings: settings, consoleLog: BrowserConsoleLog(), jar: jar, capturesConsole: false
        )
        XCTAssertTrue(off.userContentController.userScripts.isEmpty)
        let offHandler = await hasConsoleHandler(WKWebView(frame: .zero, configuration: off))
        XCTAssertEqual(offHandler, false)

        let consoleLog = BrowserConsoleLog()
        let capturing = WebKitBrowserEngine.makeConfiguration(
            settings: settings, consoleLog: consoleLog, jar: jar, capturesConsole: true
        )
        XCTAssertTrue(capturing.userContentController.userScripts.isEmpty, "scripts belong to installUserScripts()")
        let onHandler = await hasConsoleHandler(WKWebView(frame: .zero, configuration: capturing))
        XCTAssertEqual(onHandler, true)
        capturing.userContentController.removeScriptMessageHandler(forName: BrowserConsoleLog.handlerName)
    }

    /// Console capture is read when a web view is built, never live: a change
    /// waits for the rebuild, which applies it to the script, the handler and
    /// the automation together.
    func testConsoleCaptureAppliesAtRebuild() async {
        let settings = makeSettings()
        let pane = makePane(settings: settings)
        let automation = pane.automation
        XCTAssertTrue(automation.isConsoleCaptureOn)

        settings.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(consoleScriptCount(pane.webView), 1, "not live: the current web view keeps its hook")

        pane.rebuildEngine()
        XCTAssertEqual(consoleScriptCount(pane.webView), 0)
        let offHandler = await hasConsoleHandler(pane.webView)
        XCTAssertEqual(offHandler, false)
        XCTAssertFalse(automation.isConsoleCaptureOn, "the retargeted automation follows the rebuild")

        settings.set(true, for: UserSettings.browserPrivacyConsoleCapture)
        pane.rebuildEngine()
        XCTAssertEqual(consoleScriptCount(pane.webView), 1)
        let onHandler = await hasConsoleHandler(pane.webView)
        XCTAssertEqual(onHandler, true)
        XCTAssertTrue(automation.isConsoleCaptureOn)
    }

    func testConsoleIsClearedOnNavigation() async {
        let pane = makePane()
        await load("<script>console.log('first')</script>", into: pane) {
            !pane.consoleLog.messages(level: nil).isEmpty
        }
        XCTAssertFalse(pane.consoleLog.messages(level: nil).isEmpty, "the first page must have logged")
        await load("<p>second</p>", into: pane)
        XCTAssertTrue(pane.consoleLog.messages(level: nil).isEmpty)
    }

    func testBadgeShowsWhileDrivingAndHidesAfterTheHold() async throws {
        let pane = makePane()
        await load("<button id='b'>Go</button>", into: pane)
        XCTAssertFalse(pane.drivenBadge.isShowing)
        try await pane.automation.drive { }
        XCTAssertTrue(pane.drivenBadge.isShowing, "the badge stays up through the hold")
        let deadline = Date().addingTimeInterval(6)
        while pane.drivenBadge.isShowing && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertFalse(pane.drivenBadge.isShowing, "the badge must hide once the hold is over")
    }

    func testBadgeHasTheAccessibilityIdentifier() {
        let pane = makePane()
        XCTAssertEqual(pane.drivenBadge.accessibilityIdentifier(), "browser.driven")
        XCTAssertEqual(pane.drivenBadge.toolTip, "A model is driving this pane")
    }

    func testAlertDuringAnActionIsDismissedAndReported() async throws {
        let pane = makePane()
        await load("<button id='b' onclick=\"alert('careful')\">Go</button>", into: pane)
        let snapshot = try await pane.automation.snapshot(BrowserSnapshotOptions())
        let button = try XCTUnwrap(ref(ofRole: "button", in: snapshot))
        let automation = pane.automation
        let delta = try await automation.drive {
            try await automation.click(ref: button, generation: snapshot.generation, native: false)
        }
        XCTAssertEqual(delta.dialog?.kind, .alert)
        XCTAssertEqual(delta.dialog?.message, "careful")
    }

    /// WebKit raises on a second handler under a name still registered, so
    /// adding the name again without a crash proves teardown removed it.
    func testTeardownRemovesTheConsoleMessageHandler() {
        let pane = makePane()
        pane.paneContentWillBeDiscarded()
        let controller = pane.webView.configuration.userContentController
        controller.add(pane.consoleLog, name: BrowserConsoleLog.handlerName)
        controller.removeScriptMessageHandler(forName: BrowserConsoleLog.handlerName)
    }

    func testConfirmOutsideAnActionIsDismissedWithFalse() async {
        let pane = makePane()
        await load("<script>window.answer = null</script>", into: pane)
        _ = try? await pane.webView.evaluateJavaScript("window.answer = confirm('sure?')")
        try? await Task.sleep(nanoseconds: 100_000_000)
        let answer = try? await pane.webView.evaluateJavaScript("String(window.answer)") as? String
        XCTAssertEqual(answer, "false")
    }

    /// A Chrome pane's page is in a window of its own, so the pane's window
    /// never sees its first responder: that window becoming key is what
    /// makes the pane the focused one.
    func test_pageWindowKeyMakesPaneFocused() {
        let pageWindow = NSWindow()
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, pageWindow: pageWindow) },
            engineKind: .chrome, minimizedSymbol: "globe", store: EphemeralPaneStateStore(),
            settings: makeSettings(), history: nil, homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        pane.viewDidAppear()
        let other = makePane()
        BrowserPaneFocus.shared.note(other)

        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: NSWindow())
        XCTAssertTrue(BrowserPaneFocus.shared.lastFocused === other, "another window going key is not the page")

        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: pageWindow)
        XCTAssertTrue(BrowserPaneFocus.shared.lastFocused === pane)
        pane.viewDidDisappear()
    }
}
