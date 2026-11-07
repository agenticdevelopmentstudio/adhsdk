import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BrowserActivationShieldTests: XCTestCase {

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    /// How many of the controller's user scripts are the shield's.
    private func shieldScriptCount(_ webView: WKWebView) -> Int {
        webView.configuration.userContentController.userScripts
            .filter { $0.source.contains(BrowserActivationShield.marker) }
            .count
    }

    private func consoleScriptCount(_ webView: WKWebView) -> Int {
        webView.configuration.userContentController.userScripts
            .filter { $0.source == BrowserConsoleLog.script }
            .count
    }

    /// Settings changes reach the pane through `receive(on: .main)`; one turn
    /// of the run loop delivers them.
    private func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    func testTheScriptResourceIsBundledAndMarked() throws {
        let source = try XCTUnwrap(BrowserActivationShield.source, "BrowserActivationShield.js must be a resource")
        XCTAssertTrue(source.hasPrefix(BrowserActivationShield.marker))
    }

    func testShieldInstallsScriptWhenActive() throws {
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)

        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertEqual(shieldScriptCount(pane.webView), 1)
        XCTAssertEqual(consoleScriptCount(pane.webView), 1, "the console hook stays installed beside it")
        let script = try XCTUnwrap(pane.activationShield.userScript)
        XCTAssertEqual(script.injectionTime, .atDocumentStart)
        XCTAssertFalse(script.isForMainFrameOnly, "every frame gets the shield")
    }

    func testShieldRemovesScriptWhenInactive() {
        let settings = makeSettings()
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertFalse(pane.activationShield.isActive)
        XCTAssertNil(pane.activationShield.userScript)
        XCTAssertEqual(shieldScriptCount(pane.webView), 0)

        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        settle()
        XCTAssertEqual(shieldScriptCount(pane.webView), 1)

        settings.set(false, for: UserSettings.browserPrivacyHideActivation)
        settle()
        XCTAssertFalse(pane.activationShield.isActive)
        XCTAssertEqual(shieldScriptCount(pane.webView), 0)
        XCTAssertEqual(consoleScriptCount(pane.webView), 1, "turning the shield off keeps the console hook")
    }

    /// A shield toggle puts every script back; with console capture off the
    /// console hook is not among them.
    func testShieldToggleWithCaptureOffAddsNoConsoleHook() {
        let settings = makeSettings()
        settings.set(false, for: UserSettings.browserPrivacyConsoleCapture)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        XCTAssertEqual(consoleScriptCount(pane.webView), 0)

        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        settle()
        XCTAssertEqual(shieldScriptCount(pane.webView), 1)
        XCTAssertEqual(consoleScriptCount(pane.webView), 0)

        settings.set(false, for: UserSettings.browserPrivacyHideActivation)
        settle()
        XCTAssertEqual(consoleScriptCount(pane.webView), 0)
    }

    func testARebuiltWebViewGetsTheShieldAgain() {
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        let firstShield = pane.activationShield

        pane.rebuildWebView()

        XCTAssertFalse(pane.activationShield === firstShield, "a new web view gets a new shield")
        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertEqual(shieldScriptCount(pane.webView), 1)
        XCTAssertEqual(consoleScriptCount(pane.webView), 1)
    }

    func testShieldScriptMasksVisibility() async throws {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        let shield = BrowserActivationShield(webView: webView)
        webView.loadHTMLString("<p>shield</p>", baseURL: URL(string: "about:blank"))
        let deadline = Date().addingTimeInterval(5)
        var loaded = false
        while Date() < deadline {
            loaded = (try? await webView.evaluateJavaScript("document.readyState === 'complete'") as? Bool) ?? false
            if loaded && !webView.isLoading { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        guard loaded else {
            throw XCTSkip("the offscreen web view did not load a page in this test host")
        }

        // Offscreen and windowless, the page should report itself hidden or
        // unfocused until the shield runs on it; without that baseline the
        // assertion below would pass whether the shield did anything or not.
        let baseline = try await webView.evaluateJavaScript(
            "document.visibilityState + ',' + document.hasFocus()"
        ) as? String
        if baseline == "visible,true" {
            throw XCTSkip("the offscreen test host already reports \"visible,true\" before the shield, "
                + "so masking cannot be observed here")
        }
        XCTAssertNotEqual(baseline, "visible,true")

        shield.apply(active: true)
        var answer: String?
        let answerDeadline = Date().addingTimeInterval(5)
        while Date() < answerDeadline {
            answer = try await webView.evaluateJavaScript(
                "document.visibilityState + ',' + document.hasFocus()"
            ) as? String
            if answer == "visible,true" { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(answer, "visible,true")
        let hidden = try await webView.evaluateJavaScript("document.hidden") as? Bool
        XCTAssertEqual(hidden, false)
    }

    func testShieldSwallowsWindowLevelEventsButNotElementFocus() async throws {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        let shield = BrowserActivationShield(webView: webView)
        webView.loadHTMLString("<input id='field'>", baseURL: URL(string: "about:blank"))
        let deadline = Date().addingTimeInterval(5)
        var loaded = false
        while Date() < deadline {
            loaded = (try? await webView.evaluateJavaScript("document.readyState === 'complete'") as? Bool) ?? false
            if loaded && !webView.isLoading { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        guard loaded else {
            throw XCTSkip("the offscreen web view did not load a page in this test host")
        }
        shield.apply(active: true)
        // The immediate run is asynchronous; wait for its getter to be in place.
        let shieldDeadline = Date().addingTimeInterval(5)
        while Date() < shieldDeadline {
            let focused = (try? await webView.evaluateJavaScript("document.hasFocus()") as? Bool) ?? false
            if focused { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        let probe = """
        (function () {
          const seen = [];
          window.addEventListener('blur', function () { seen.push('window-blur'); });
          document.addEventListener('visibilitychange', function () { seen.push('visibilitychange'); });
          const field = document.getElementById('field');
          field.addEventListener('focus', function () { seen.push('field-focus'); });
          window.dispatchEvent(new Event('blur'));
          document.dispatchEvent(new Event('visibilitychange'));
          field.dispatchEvent(new FocusEvent('focus'));
          return seen.join(',');
        })()
        """
        let seen = try await webView.evaluateJavaScript(probe) as? String
        XCTAssertEqual(seen, "field-focus")
    }

    // MARK: - The live page (Pause Events, spec section 7)

    /// Loads `html` into a fresh offscreen web view and waits for it, or
    /// skips when this test host cannot load a page at all.
    private func loadedWebView(_ html: String) async throws -> WKWebView {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        webView.loadHTMLString(html, baseURL: URL(string: "about:blank"))
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let loaded = (try? await webView.evaluateJavaScript("document.readyState === 'complete'") as? Bool) ?? false
            if loaded && !webView.isLoading { return webView }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        throw XCTSkip("the offscreen web view did not load a page in this test host")
    }

    /// Polls `script` until it answers `expected` or five seconds pass, and
    /// returns the last answer: the shield's immediate runs are asynchronous.
    private func waitFor(_ script: String, toBe expected: String, in webView: WKWebView) async throws -> String? {
        var answer: String?
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            answer = try await webView.evaluateJavaScript(script) as? String
            if answer == expected { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        return answer
    }

    /// The immediate run reaches a same-origin frame that is already loaded,
    /// not only the main frame.
    func testRaisingTheShieldReachesLoadedSameOriginFrames() async throws {
        let webView = try await loadedWebView("<iframe srcdoc='<p>inner</p>'></iframe>")
        let frameReady = try await waitFor(
            "String(frames.length === 1 && frames[0].document.readyState === 'complete')",
            toBe: "true", in: webView)
        guard frameReady == "true" else { throw XCTSkip("the srcdoc frame did not load in this test host") }
        let shield = BrowserActivationShield(webView: webView)

        shield.apply(active: true)

        let probe = "typeof frames[0].__adkActivationShield + ',' + frames[0].document.hidden"
        let answer = try await waitFor(probe, toBe: "function,false", in: webView)
        XCTAssertEqual(answer, "function,false")
    }

    /// Lowering the shield takes the shim off the page already showing, in
    /// the main frame and its same-origin frames, without waiting for a load.
    func testLoweringTheShieldLiftsItFromTheLivePage() async throws {
        let webView = try await loadedWebView("<iframe srcdoc='<p>inner</p>'></iframe>")
        let frameReady = try await waitFor(
            "String(frames.length === 1 && frames[0].document.readyState === 'complete')",
            toBe: "true", in: webView)
        guard frameReady == "true" else { throw XCTSkip("the srcdoc frame did not load in this test host") }
        let shield = BrowserActivationShield(webView: webView)
        shield.apply(active: true)
        // Both halves are shielded before the lift, so the lift's answer for
        // the frame below cannot pass because the frame was never reached.
        let raised = try await waitFor(
            "typeof window.__adkActivationShield + ',' + typeof frames[0].__adkActivationShield",
            toBe: "function,function", in: webView)
        XCTAssertEqual(raised, "function,function")

        shield.apply(active: false)

        let probe = """
        [typeof window.__adkActivationShield,
         String(Object.getOwnPropertyDescriptor(document, 'hidden') === undefined),
         String(Object.getOwnPropertyDescriptor(document, 'hasFocus') === undefined),
         typeof frames[0].__adkActivationShield,
         String(Object.getOwnPropertyDescriptor(frames[0].document, 'hidden') === undefined)].join(',')
        """
        let answer = try await waitFor(probe, toBe: "undefined,true,true,undefined,true", in: webView)
        XCTAssertEqual(answer, "undefined,true,true,undefined,true")

        // The window-level events reach the page's listeners again.
        let seen = try await webView.evaluateJavaScript("""
        (function () {
          var seen = [];
          window.addEventListener('blur', function () { seen.push('window-blur'); });
          window.dispatchEvent(new Event('blur'));
          return seen.join(',');
        })()
        """) as? String
        XCTAssertEqual(seen, "window-blur")
    }

    /// Raising twice over one document (the document-start copy, then the
    /// immediate run) shields it once: one lift takes it all off.
    func testASecondRunOverTheSameDocumentAddsNothing() async throws {
        let webView = try await loadedWebView("<p>twice</p>")
        let source = try XCTUnwrap(BrowserActivationShield.source)
        _ = try await webView.evaluateJavaScript(source)
        _ = try await webView.evaluateJavaScript(source)
        _ = try await webView.evaluateJavaScript(try XCTUnwrap(BrowserActivationShield.liftSource))
        let answer = try await webView.evaluateJavaScript("""
        [typeof window.__adkActivationShield,
         String(Object.getOwnPropertyDescriptor(document, 'hidden') === undefined)].join(',')
        """) as? String
        XCTAssertEqual(answer, "undefined,true")
    }

    /// A value the page put under the shim's name first neither makes the
    /// shield skip the window nor is run as the lift.
    func testAPageDefinedRecordCannotSuppressOrHijackTheShield() async throws {
        let webView = try await loadedWebView("<p>forged</p>")
        _ = try await webView.evaluateJavaScript("""
        window.__forgedLiftRan = false;
        window.__adkActivationShield = function (challenge) {
          return { proof: challenge + '|guess', doc: document,
                   lift: function () { window.__forgedLiftRan = true; } };
        };
        true
        """)
        _ = try await webView.evaluateJavaScript(try XCTUnwrap(BrowserActivationShield.source))
        let raised = try await webView.evaluateJavaScript("""
        String(Object.getOwnPropertyDescriptor(document, 'hidden') !== undefined)
        """) as? String
        XCTAssertEqual(raised, "true", "the forged record did not make the shield skip the window")

        _ = try await webView.evaluateJavaScript(try XCTUnwrap(BrowserActivationShield.liftSource))
        let lifted = try await webView.evaluateJavaScript("""
        [String(window.__forgedLiftRan),
         String(Object.getOwnPropertyDescriptor(document, 'hidden') === undefined)].join(',')
        """) as? String
        XCTAssertEqual(lifted, "false,true", "the shim's own lift ran, the page's did not")
    }

    /// The record is per document: a frame whose first navigation away from
    /// its initial about:blank keeps its Window gets the document-start copy
    /// on the new document, instead of being taken for shielded already.
    func testAReusedWindowsNewDocumentIsShielded() async throws {
        let webView = try await loadedWebView("<p>outer</p>")
        let shield = BrowserActivationShield(webView: webView)
        shield.apply(active: true)
        webView.configuration.userContentController.addUserScript(try XCTUnwrap(shield.userScript))
        let made = try await webView.evaluateJavaScript("""
        (function () {
          var frame = document.createElement('iframe');
          frame.id = 'late';
          document.body.appendChild(frame);
          return String(frames.length);
        })()
        """) as? String
        XCTAssertEqual(made, "1")
        // The immediate run, again, reaches the frame on its initial document.
        _ = try await webView.evaluateJavaScript(try XCTUnwrap(BrowserActivationShield.source))
        let first = try await webView.evaluateJavaScript(
            "frames[0].__reuseMark = 'kept'; typeof frames[0].__adkActivationShield"
        ) as? String
        XCTAssertEqual(first, "function")

        _ = try await webView.evaluateJavaScript(
            "document.getElementById('late').srcdoc = '<p>inner</p>'; true")
        let navigated = try await waitFor(
            "String(frames[0].document.body !== null && frames[0].document.body.textContent === 'inner')",
            toBe: "true", in: webView)
        guard navigated == "true" else { throw XCTSkip("the frame did not navigate in this test host") }
        let reused = try await webView.evaluateJavaScript("String(frames[0].__reuseMark)") as? String
        guard reused == "kept" else {
            throw XCTSkip("WebKit made a new Window for the frame here, so reuse cannot be observed")
        }
        let answer = try await waitFor(
            "String(Object.getOwnPropertyDescriptor(frames[0].document, 'hidden') !== undefined)",
            toBe: "true", in: webView)
        XCTAssertEqual(answer, "true", "the new document in the reused Window is shielded")
    }
}
