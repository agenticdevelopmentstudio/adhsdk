import XCTest
import AppKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The browser pane's event log and the pane recording into it (spec
/// section 12).
@MainActor
final class BrowserEventLogTests: XCTestCase {

    /// A clock the test moves by hand.
    private final class Clock {
        var now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    private func makeLog(capacity: Int = 2000, clock: Clock = Clock()) -> BrowserEventLog {
        BrowserEventLog(capacity: capacity, now: { clock.now })
    }

    private func keyEvent(
        _ characters: String, keyCode: UInt16, modifiers: NSEvent.ModifierFlags = []
    ) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0,
            context: nil, characters: characters, charactersIgnoringModifiers: characters,
            isARepeat: false, keyCode: keyCode))
    }

    func testCapacityDropsOldest() {
        let log = makeLog(capacity: 3)
        for index in 0..<5 {
            log.record(channel: "mouse", event: "mouseDown", decision: .delivered, detail: "\(index)")
        }
        XCTAssertEqual(log.entries.map(\.detail), ["2", "3", "4"])
    }

    func testMouseMovedCoalesces() {
        let clock = Clock()
        let log = makeLog(clock: clock)
        for _ in 0..<4 {
            log.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
            clock.advance(0.1)
        }
        log.record(channel: "mouse", event: "scrollWheel", decision: .withheld)
        log.record(channel: "mouse", event: "scrollWheel", decision: .withheld)
        log.record(channel: "mouse", event: "scrollWheel", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["mouseMoved", "scrollWheel", "scrollWheel"])
        XCTAssertEqual(log.entries.map(\.count), [4, 2, 1])
    }

    func testOtherEventsDoNotCoalesce() {
        let log = makeLog()
        log.record(channel: "mouse", event: "mouseDown", decision: .delivered)
        log.record(channel: "mouse", event: "mouseDown", decision: .delivered)
        XCTAssertEqual(log.entries.count, 2)
    }

    func testCoalescingStopsAfterHalfASecond() {
        let clock = Clock()
        let log = makeLog(clock: clock)
        log.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
        clock.advance(0.6)
        log.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.count), [1, 1])
    }

    /// An input method's asynchronous insertText for a keystroke the keyDown
    /// line already holds adds nothing; a different decision is its own line.
    func testTextInputAfterKeyDownIsFolded() {
        let log = makeLog()
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "character")
        log.record(channel: "keyboard", event: "setMarkedText:selectedRange:replacementRange:", decision: .delivered)
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "Return")
        log.record(channel: "keyboard", event: "insertText:replacementRange:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["keyDown", "keyDown"])
        XCTAssertEqual(log.entries.map(\.count), [1, 1])

        log.record(channel: "keyboard", event: "insertText:", decision: .withheld)
        XCTAssertEqual(log.entries.last?.event, "insertText:", "a different decision is not the same keystroke")
    }

    func testPrintableKeysAreNotRecorded() throws {
        XCTAssertEqual(BrowserEventLog.keyDetail(for: try keyEvent("a", keyCode: 0)), "character")
        XCTAssertEqual(BrowserEventLog.keyDetail(for: try keyEvent("\r", keyCode: 36)), "Return")
        XCTAssertEqual(BrowserEventLog.keyDetail(for: try keyEvent("s", keyCode: 1, modifiers: .command)), "⌘character")
        XCTAssertEqual(BrowserEventLog.keyDetail(for: try keyEvent("\u{1B}", keyCode: 53)), "Escape")
    }

    func testClearEmpties() {
        let log = makeLog()
        var changes = 0
        let subscription = log.changes.sink { changes += 1 }
        log.record(channel: "pane", event: "pause", decision: .info)
        log.clear()
        XCTAssertTrue(log.entries.isEmpty)
        XCTAssertEqual(changes, 2)
        subscription.cancel()
    }

    // MARK: - The pane records

    private func makePane() -> BrowserPaneViewController {
        BrowserPaneViewController(
            store: EphemeralPaneStateStore(),
            settings: UserSettings(
                with: InMemorySettingsStorageProvider(),
                secureSettingsProvider: InMemorySecureSettingsStorageProvider()
            )
        )
    }

    func testPaneRecordsPauseAndGateDecisions() throws {
        let pane = makePane()
        pane.setEventsPaused(true)
        let webView = try XCTUnwrap(pane.webView as? BrowserWebView)
        webView.keyDown(with: try keyEvent("p", keyCode: 35))
        let lines = pane.eventLog.entries.map { "\($0.channel) \($0.event) \($0.decision.rawValue) \($0.detail)" }
        XCTAssertEqual(lines, ["pane pause info ", "keyboard keyDown withheld character"])
    }

    func testPaneRecordsSettingsChangesAndRebuilds() {
        let pane = makePane()
        pane.paneSettings?.set(1.5, for: UserSettings.browserPageZoom)
        pane.rebuildWebView()
        let events = pane.eventLog.entries.map(\.event)
        XCTAssertTrue(events.contains("rebuild"), "\(events)")
    }

    func testLogPaneShowsTheTargetsEntriesWithCounts() {
        let pane = makePane()
        let logPane = BrowserLogPaneViewController(store: EphemeralPaneStateStore())
        _ = logPane.view
        logPane.attach(pane)
        pane.eventLog.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
        pane.eventLog.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
        logPane.reload()
        XCTAssertEqual(logPane.tableView.numberOfRows, 1)
        XCTAssertEqual(logPane.text(row: 0, column: "Detail"), "×2")
        XCTAssertEqual(logPane.paneTitle, "Browser Log — Browser")

        logPane.clearLog()
        logPane.reload()
        XCTAssertEqual(logPane.tableView.numberOfRows, 0)
    }

    func testLogPaneRemembersItsTarget() {
        let store = EphemeralPaneStateStore()
        let nodeID = UUID()
        BrowserLogPaneViewController(store: store).setTarget(nodeID)
        XCTAssertEqual(store.paneStateValue(forKey: "target"), nodeID.uuidString)
        XCTAssertEqual(BrowserLogPaneViewController(store: store).targetNodeID, nodeID)
        XCTAssertEqual(BrowserLogPaneViewController(store: store).paneTitle, "Browser Log", "no live target")
    }
}
