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

    func testBlockedKeyboardDisablesEditActions() {
        let webView = BrowserWebView(frame: NSRect(x: 0, y: 0, width: 100, height: 100),
                                     configuration: WKWebViewConfiguration())
        var gate = BrowserInputGate.open
        gate.keyboard = .block
        webView.gate = gate
        XCTAssertEqual(BrowserWebView.gatedEditActions.count, 8)
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
        webView.onInputDecision = { decisions.append(($0, $1, $2, $3)) }
        webView.gatedPaste(nil)
        XCTAssertEqual(decisions.count, 1)
        XCTAssertEqual(decisions.first?.0, .keyboard)
        XCTAssertEqual(decisions.first?.1, "paste:")
        XCTAssertEqual(decisions.first?.2, false)
        XCTAssertEqual(decisions.first?.3, false)
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
