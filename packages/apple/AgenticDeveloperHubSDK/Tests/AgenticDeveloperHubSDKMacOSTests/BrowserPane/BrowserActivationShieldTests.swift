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
        let webView = WKWebView(frame: .zero)
        let source = try XCTUnwrap(BrowserActivationShield(webView: webView).source,
                                   "BrowserActivationShield.js must be a resource")
        XCTAssertTrue(source.hasPrefix(BrowserActivationShield.marker))
    }

    func testShieldInstallsScriptWhenActive() throws {
        let settings = makeSettings()
        settings.set(true, for: UserSettings.browserPrivacyHideActivation)
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)

        XCTAssertTrue(pane.activationShield.isActive)
        XCTAssertEqual(shieldScriptCount(pane.webView), 1)
        XCTAssertEqual(consoleScriptCount(pane.webView), 1, "the console hook stays installed beside it")
        let script = try XCTUnwrap(pane.activationShield.userScript)
        XCTAssertEqual(script.injectionTime, .atDocumentStart)
        XCTAssertFalse(script.isForMainFrameOnly, "every frame gets the shield")
    }

    func testShieldRemovesScriptWhenInactive() {
        let settings = makeSettings()
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
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
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
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
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        let firstShield = pane.activationShield

        pane.rebuildEngine()

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

    /// The shield's token is readable by the page, so two web views on
    /// different jars must not share it, or it would link them (spec
    /// section 4).
    func testShieldedWebViewsOnDifferentJarsReadDifferentTokens() async throws {
        var tokens: [String] = []
        for _ in 0..<2 {
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            let webView = try await loadedWebView("<p>jar</p>", configuration: configuration)
            let shield = BrowserActivationShield(webView: webView)
            shield.apply(active: true)
            let raised = try await waitFor(
                "String(typeof window.__adkActivationShield === 'function')", toBe: "true", in: webView
            )
            XCTAssertEqual(raised, "true")
            let token = try await webView.evaluateJavaScript(
                "__adkActivationShield('x').proof.split('|')[1]"
            ) as? String
            XCTAssertEqual(token, shield.token)
            tokens.append(try XCTUnwrap(token))
        }
        XCTAssertNotEqual(tokens[0], tokens[1])
    }

    /// Loads `html` into a fresh offscreen web view and waits for it, or
    /// skips when this test host cannot load a page at all.
    private func loadedWebView(
        _ html: String,
        configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    ) async throws -> WKWebView {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 320, height: 240), configuration: configuration)
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
        let shield = BrowserActivationShield(webView: webView)
        let source = try XCTUnwrap(shield.source)
        _ = try await webView.evaluateJavaScript(source)
        _ = try await webView.evaluateJavaScript(source)
        _ = try await webView.evaluateJavaScript(try XCTUnwrap(shield.liftSource))
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
        let shield = BrowserActivationShield(webView: webView)
        _ = try await webView.evaluateJavaScript("""
        window.__forgedLiftRan = false;
        window.__adkActivationShield = function (challenge) {
          return { proof: challenge + '|guess', doc: document,
                   lift: function () { window.__forgedLiftRan = true; } };
        };
        true
        """)
        _ = try await webView.evaluateJavaScript(try XCTUnwrap(shield.source))
        let raised = try await webView.evaluateJavaScript("""
        String(Object.getOwnPropertyDescriptor(document, 'hidden') !== undefined)
        """) as? String
        XCTAssertEqual(raised, "true", "the forged record did not make the shield skip the window")

        _ = try await webView.evaluateJavaScript(try XCTUnwrap(shield.liftSource))
        let lifted = try await webView.evaluateJavaScript("""
        [String(window.__forgedLiftRan),
         String(Object.getOwnPropertyDescriptor(document, 'hidden') === undefined)].join(',')
        """) as? String
        XCTAssertEqual(lifted, "false,true", "the shim's own lift ran, the page's did not")
    }

    /// The record is per document. A window whose record names another
    /// document — what a reused Window keeps after its document is replaced
    /// — has that record lifted and its current document shielded, rather
    /// than being taken for shielded already.
    ///
    /// WebKit gives no reliable way to reuse a frame's Window from a test,
    /// so the stale record is made by hand: frames[1] is lifted, then given
    /// frames[0]'s record, which names frames[0]'s document. Lifting that
    /// stale record runs frames[0]'s lift — the record's owner — which is
    /// how the test sees the stale path ran; a second raise restores
    /// frames[0], as the next document-start copy or raise would.
    func testAStaleRecordIsLiftedAndTheCurrentDocumentShielded() async throws {
        let webView = try await loadedWebView(
            "<iframe srcdoc='<p>zero</p>'></iframe><iframe srcdoc='<p>one</p>'></iframe>")
        let ready = try await waitFor("""
            String(frames.length === 2
              && frames[0].document.readyState === 'complete'
              && frames[1].document.readyState === 'complete')
            """, toBe: "true", in: webView)
        XCTAssertEqual(ready, "true", "both srcdoc frames loaded")
        let raise = try XCTUnwrap(BrowserActivationShield(webView: webView).source)

        // Hidden-descriptor state of a frame's current document: "shielded"
        // when the shim's own descriptor is on it, "plain" when not.
        func state(_ index: Int) -> String {
            "(Object.getOwnPropertyDescriptor(frames[\(index)].document, 'hidden') ? 'shielded' : 'plain')"
        }

        _ = try await webView.evaluateJavaScript(raise)
        let raised = try await webView.evaluateJavaScript(
            "[\(state(0)), \(state(1))].join(',')") as? String
        XCTAssertEqual(raised, "shielded,shielded")

        // Lift frames[1] alone through its own record, then hand it
        // frames[0]'s record: a valid record that names another document.
        let staged = try await webView.evaluateJavaScript("""
            (function () {
              frames[1].__adkActivationShield('test').lift();
              var lifted = \(state(1));
              var stale = frames[0].__adkActivationShield;
              Object.defineProperty(frames[1], '__adkActivationShield',
                { configurable: true, enumerable: false, writable: false, value: stale });
              window.__staleRecord = stale;
              return [lifted,
                      String(frames[1].__adkActivationShield('t').doc === frames[0].document)].join(',');
            })()
            """) as? String
        XCTAssertEqual(staged, "plain,true",
                       "frames[1] is lifted and holds a record naming frames[0]'s document")

        _ = try await webView.evaluateJavaScript(raise)
        let afterRaise = try await webView.evaluateJavaScript("""
            [\(state(1)),
             String(typeof frames[1].__adkActivationShield === 'function'
                    && frames[1].__adkActivationShield !== window.__staleRecord),
             String(frames[1].__adkActivationShield('t').doc === frames[1].document),
             String(frames[1].document.hidden), frames[1].document.visibilityState,
             \(state(0)), typeof frames[0].__adkActivationShield].join(',')
            """) as? String
        XCTAssertEqual(afterRaise,
                       "shielded,true,true,false,visible,plain,undefined",
                       "frames[1]'s current document is shielded under a fresh record; "
                       + "the stale record's lift ran, which took frames[0]'s shim off")

        _ = try await webView.evaluateJavaScript(raise)
        let again = try await webView.evaluateJavaScript("""
            [\(state(0)), String(frames[0].__adkActivationShield('t').doc === frames[0].document),
             \(state(1)), String(frames[1].__adkActivationShield('t').doc === frames[1].document)].join(',')
            """) as? String
        XCTAssertEqual(again, "shielded,true,shielded,true",
                       "a further raise shields frames[0] again and leaves frames[1] as it was")
    }
}
