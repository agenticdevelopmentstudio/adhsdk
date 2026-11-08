import XCTest
import AppKit
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class BrowserInputGateTests: XCTestCase {

    private let channels: [BrowserInputChannel] = [.keyboard, .mouse, .pointer, .dragAndDrop]

    private func blocked(paused: Bool = false, agentPausedToo: Bool = false) -> BrowserInputGate {
        BrowserInputGate(keyboard: .block, mouse: .block, pointer: .never, dragAndDrop: false,
                         isPaused: paused, agentPausedToo: agentPausedToo)
    }

    func testOpenGateAllowsEverything() {
        for channel in channels {
            let open = BrowserInputGate.open
            XCTAssertTrue(open.allows(channel, synthesized: false, pageHasFocus: false), channel.rawValue)
            XCTAssertTrue(open.allows(channel, synthesized: true, pageHasFocus: false), channel.rawValue)
        }
    }

    func testBlockedKeyboardWithholdsUserKeys() {
        var gate = BrowserInputGate.open
        gate.keyboard = .block
        XCTAssertFalse(gate.allows(.keyboard, synthesized: false, pageHasFocus: true))
        XCTAssertTrue(gate.allows(.mouse, synthesized: false, pageHasFocus: true))
    }

    func testSynthesizedInputPassesABlockedMouseGate() {
        let gate = blocked()
        XCTAssertFalse(gate.allows(.mouse, synthesized: false, pageHasFocus: true))
        XCTAssertTrue(gate.allows(.mouse, synthesized: true, pageHasFocus: true))
    }

    func testPausedWithholdsAllUserInput() {
        var gate = BrowserInputGate.open
        gate.isPaused = true
        for channel in channels {
            XCTAssertFalse(gate.allows(channel, synthesized: false, pageHasFocus: true), channel.rawValue)
            XCTAssertTrue(gate.allows(channel, synthesized: true, pageHasFocus: true), channel.rawValue)
        }
    }

    func testAgentPausedTooWithholdsSynthesizedInput() {
        let gate = blocked(paused: true, agentPausedToo: true)
        for channel in channels {
            XCTAssertFalse(gate.allows(channel, synthesized: true, pageHasFocus: true), channel.rawValue)
        }
        let notPaused = blocked(paused: false, agentPausedToo: true)
        XCTAssertTrue(notPaused.allows(.mouse, synthesized: true, pageHasFocus: false))
    }

    func testPointerWhenFocusedNeedsFocus() {
        var gate = BrowserInputGate.open
        gate.pointer = .whenFocused
        XCTAssertTrue(gate.allows(.pointer, synthesized: false, pageHasFocus: true))
        XCTAssertFalse(gate.allows(.pointer, synthesized: false, pageHasFocus: false))
    }

    /// WebKit's hover tracking area belongs to an internal observer that
    /// would hand events straight to WebKit, past the gate; the web view
    /// takes every such area over, so each pointer event is decided first.
    func testTheWebViewOwnsEveryTrackingArea() {
        let webView = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                                     configuration: WKWebViewConfiguration())
        let window = NSWindow(contentRect: webView.frame, styleMask: [.titled], backing: .buffered, defer: true)
        window.contentView = webView
        let foreign = NSTrackingArea(rect: webView.bounds, options: [.mouseMoved, .activeAlways], owner: NSObject(),
                                     userInfo: nil)
        webView.addTrackingArea(foreign)
        webView.adoptForeignTrackingAreas()
        XCTAssertFalse(webView.trackingAreas.isEmpty)
        for area in webView.trackingAreas {
            XCTAssertTrue(area.owner as AnyObject === webView, "\(area) is owned elsewhere")
        }
        let count = webView.trackingAreas.count
        webView.adoptForeignTrackingAreas()
        XCTAssertEqual(webView.trackingAreas.count, count, "taking over twice changes nothing")
        withExtendedLifetime(foreign) {}
    }

    func testBlockedKeyboardDisablesEditActions() {
        let webView = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                                     configuration: WKWebViewConfiguration())
        var gate = BrowserInputGate.open
        gate.keyboard = .block
        webView.gate = gate
        XCTAssertEqual(BrowserWebView.gatedEditActions.count, 12)
        for action in BrowserWebView.gatedEditActions {
            let item = NSMenuItem(title: "", action: action, keyEquivalent: "")
            XCTAssertFalse(webView.validateUserInterfaceItem(item), "\(action)")
            XCTAssertTrue(webView.responds(to: action), "\(action)")
        }

        webView.gate = .open
        let undo = #selector(BrowserWebView.gatedUndo(_:))
        XCTAssertFalse(webView.responds(to: undo), "an open gate leaves undo: to the window")
        XCTAssertTrue(webView.responds(to: #selector(NSText.paste(_:))))
    }

    func testBlockedEditActionIsDroppedAndReported() {
        let webView = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                                     configuration: WKWebViewConfiguration())
        var gate = BrowserInputGate.open
        gate.keyboard = .block
        webView.gate = gate
        var decisions: [(BrowserInputChannel, String, Bool, Bool)] = []
        webView.onInputDecision = { channel, event, delivered, synthesized, _ in
            decisions.append((channel, event, delivered, synthesized))
        }
        webView.gatedPaste(nil)
        XCTAssertEqual(decisions.count, 1)
        XCTAssertEqual(decisions.first?.0, .keyboard)
        XCTAssertEqual(decisions.first?.1, "paste:")
        XCTAssertEqual(decisions.first?.2, false)
        XCTAssertEqual(decisions.first?.3, false)
    }

    private func keyboardBlockedWebView() -> (BrowserWebView, () -> [(BrowserInputChannel, String, Bool, Bool)]) {
        let webView = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                                     configuration: WKWebViewConfiguration())
        var gate = BrowserInputGate.open
        gate.keyboard = .block
        webView.gate = gate
        var decisions: [(BrowserInputChannel, String, Bool, Bool)] = []
        webView.onInputDecision = { channel, event, delivered, synthesized, _ in
            decisions.append((channel, event, delivered, synthesized))
        }
        return (webView, { decisions })
    }

    func testKeyEquivalentForAnotherViewIsNotDecided() throws {
        let (webView, decisions) = keyboardBlockedWebView()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let field = NSTextField(frame: NSRect(x: 0, y: 150, width: 100, height: 22))
        window.contentView?.addSubview(webView)
        window.contentView?.addSubview(field)
        window.makeFirstResponder(field)
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: "l",
            charactersIgnoringModifiers: "l", isARepeat: false, keyCode: 37))
        XCTAssertTrue(window.firstResponder !== window && window.firstResponder !== webView)
        _ = webView.performKeyEquivalent(with: event)
        XCTAssertTrue(decisions().isEmpty, "a shortcut for the address bar is not the page's")

        window.makeFirstResponder(webView)
        XCTAssertFalse(webView.performKeyEquivalent(with: event))
        XCTAssertEqual(decisions().map(\.1), ["performKeyEquivalent"], "the page's own shortcut is gated")
    }

    func testBlockedTextInputAndTransformationsAreDropped() {
        let (webView, decisions) = keyboardBlockedWebView()
        webView.gatedInsertText("dictated", replacementRange: NSRange(location: NSNotFound, length: 0))
        webView.gatedInsertText("emoji")
        webView.gatedSetMarkedText("interim", selectedRange: NSRange(location: 0, length: 0),
                                   replacementRange: NSRange(location: NSNotFound, length: 0))
        webView.gatedDelete(nil)
        webView.gatedUppercaseWord(nil)
        XCTAssertEqual(decisions().map(\.1), [
            "insertText:replacementRange:", "insertText:", "setMarkedText:selectedRange:replacementRange:",
            "delete:", "uppercaseWord:"
        ])
        XCTAssertTrue(decisions().allSatisfy { $0.0 == .keyboard && !$0.2 && !$0.3 })
    }

    func testAutomationInputPassesABlockedKeyboard() {
        let (webView, decisions) = keyboardBlockedWebView()
        webView.deliveringAutomationInput { webView.gatedSelectAll(nil) }
        XCTAssertEqual(decisions().count, 1)
        XCTAssertEqual(decisions().first?.1, "selectAll:")
        XCTAssertEqual(decisions().first?.2, true, "delivered")
        XCTAssertEqual(decisions().first?.3, true, "synthesized")
        webView.gatedSelectAll(nil)
        XCTAssertEqual(decisions().last?.2, false, "outside the bracket the user's action is withheld")
    }

    func testGateReadsSettings() {
        let store = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        store.set(.block, for: UserSettings.browserPrivacyKeyboard)
        store.set(.allow, for: UserSettings.browserPrivacyMouse)
        store.set(.never, for: UserSettings.browserPrivacyPointerTracking)
        store.set(false, for: UserSettings.browserPrivacyDragAndDrop)
        store.set(.paused, for: UserSettings.browserPrivacyAgentWhilePaused)
        let gate = BrowserInputGate(settings: store, isPaused: true)
        XCTAssertEqual(gate.keyboard, .block)
        XCTAssertEqual(gate.mouse, .allow)
        XCTAssertEqual(gate.pointer, .never)
        XCTAssertFalse(gate.dragAndDrop)
        XCTAssertTrue(gate.isPaused)
        XCTAssertTrue(gate.agentPausedToo)
    }
}
