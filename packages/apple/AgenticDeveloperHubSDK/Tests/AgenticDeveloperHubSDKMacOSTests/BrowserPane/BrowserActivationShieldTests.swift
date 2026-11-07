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

        // Offscreen and windowless, the page reports itself hidden and unfocused
        // until the shield runs on it.
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
}
