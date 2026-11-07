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

    /// An agent's withheld scroll keeps its own line beside the user's.
    func testCoalescingKeepsDetailsApart() {
        let log = makeLog()
        log.record(channel: "mouse", event: "scrollWheel", decision: .withheld)
        log.record(channel: "mouse", event: "scrollWheel", decision: .withheld, detail: "agent")
        log.record(channel: "mouse", event: "scrollWheel", decision: .withheld, detail: "agent")
        XCTAssertEqual(log.entries.map(\.detail), ["", "agent"])
        XCTAssertEqual(log.entries.map(\.count), [1, 2])
    }

    func testRingKeepsChronologicalOrderAcrossManyWraps() {
        let log = makeLog(capacity: 4)
        for index in 0..<11 {
            log.record(channel: "mouse", event: "mouseDown", decision: .delivered, detail: "\(index)")
        }
        XCTAssertEqual(log.entries.map(\.detail), ["7", "8", "9", "10"])
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
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "⇧character")
        log.record(channel: "keyboard", event: "insertText:replacementRange:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["keyDown"])
        XCTAssertEqual(log.entries.map(\.count), [1])

        log.record(channel: "keyboard", event: "insertText:", decision: .withheld)
        XCTAssertEqual(log.entries.last?.event, "insertText:", "a different decision is not the same keystroke")
    }

    /// The keystroke's own keyUp and a drifting pointer land between the
    /// keyDown and the input method's late call; the fold still happens.
    func testTextInputFoldsPastInterleavedEvents() {
        let clock = Clock()
        let log = makeLog(clock: clock)
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "character")
        clock.advance(0.1)
        log.record(channel: "pointer", event: "mouseMoved", decision: .delivered)
        log.record(channel: "keyboard", event: "keyUp", decision: .delivered, detail: "character")
        clock.advance(0.1)
        log.record(channel: "keyboard", event: "setMarkedText:selectedRange:replacementRange:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["keyDown", "mouseMoved", "keyUp"])

        clock.advance(0.5)
        log.record(channel: "keyboard", event: "insertText:replacementRange:", decision: .delivered)
        XCTAssertEqual(log.entries.last?.event, "insertText:replacementRange:", "past the window it is its own line")
    }

    /// Text arriving after a named key is not that key's echo (Dictation or
    /// the character viewer after a Return), so it gets its own line.
    func testTextInputAfterReturnIsNotFolded() {
        let log = makeLog()
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "Return")
        log.record(channel: "keyboard", event: "insertText:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["keyDown", "insertText:"])
    }

    /// The remembered keyDown follows the ring: once evicted it absorbs
    /// nothing, and one recorded after the ring wrapped still does.
    func testTrackedKeyDownSurvivesEviction() {
        let log = makeLog(capacity: 3)
        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "character")
        for index in 0..<3 {
            log.record(channel: "mouse", event: "mouseDown", decision: .delivered, detail: "\(index)")
        }
        log.record(channel: "keyboard", event: "insertText:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["mouseDown", "mouseDown", "insertText:"])

        log.record(channel: "keyboard", event: "keyDown", decision: .delivered, detail: "character")
        log.record(channel: "keyboard", event: "keyUp", decision: .delivered, detail: "character")
        log.record(channel: "keyboard", event: "insertText:", decision: .delivered)
        XCTAssertEqual(log.entries.map(\.event), ["insertText:", "keyDown", "keyUp"])
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

    func testPaneRecordsSettingsChangesAndRebuilds() throws {
        let settings = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: UserSettings(
                with: InMemorySettingsStorageProvider(),
                secureSettingsProvider: InMemorySecureSettingsStorageProvider()
            )
        )
        let pane = BrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        settings.set(1.5, for: UserSettings.browserPageZoom)
        // The pane hears settings through `receive(on: .main)`.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let change = try XCTUnwrap(pane.eventLog.entries.first { $0.channel == "settings" && $0.event == "changed" })
        XCTAssertEqual(change.detail, UserSettings.browserPageZoom.name)
        XCTAssertFalse(change.detail.contains("1.5"), "the key, never the value")

        pane.rebuildWebView()
        XCTAssertEqual(pane.eventLog.entries.last?.event, "rebuild")
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

    /// A discarded target is let go: the list empties and the title drops
    /// the pane's name, announced once.
    func testLogPaneLetsGoOfADiscardedTarget() {
        let pane = makePane()
        let logPane = BrowserLogPaneViewController(store: EphemeralPaneStateStore())
        _ = logPane.view
        var announcements = 0
        logPane.onPaneTitleChange = { announcements += 1 }
        logPane.attach(pane)
        XCTAssertEqual(announcements, 1)
        pane.eventLog.record(channel: "pane", event: "pause", decision: .info)
        logPane.reload()
        logPane.reload()
        XCTAssertEqual(announcements, 1, "an unchanged title is not announced again")

        pane.paneContentWillBeDiscarded()
        logPane.reload()
        XCTAssertEqual(logPane.paneTitle, "Browser Log")
        XCTAssertEqual(logPane.tableView.numberOfRows, 0)
        XCTAssertEqual(announcements, 2)
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
