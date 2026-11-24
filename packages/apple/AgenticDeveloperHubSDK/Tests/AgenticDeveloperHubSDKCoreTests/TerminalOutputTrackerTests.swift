import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("TerminalOutputTracker")
struct TerminalOutputTrackerTests {

    private func snapshot(
        _ lines: [String], cursor: Int, first: Int = 0, alternate: Bool = false
    ) -> TerminalScreenSnapshot {
        TerminalScreenSnapshot(lines: lines, firstRow: first, cursorRow: cursor, isAlternateScreen: alternate)
    }

    @Test("history from before the start is not reported")
    func startsAtTheCursor() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["old", "%"], cursor: 1))
        #expect(tracker.newOutput(in: snapshot(["old", "%"], cursor: 1)) == nil)
    }

    @Test("a command's echo is left out and its output and next prompt are reported")
    func dropsTheEcho() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        tracker.noteSent("echo hi")
        let output = tracker.newOutput(in: snapshot(["% echo hi", "hi", "%"], cursor: 2))
        #expect(output == "hi\n%")
    }

    @Test("a prompt already shown is not shown again")
    func stripsTheShownPrompt() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        _ = tracker.newOutput(in: snapshot(["%", "a", "%"], cursor: 2))
        tracker.noteSent("ls")
        let output = tracker.newOutput(in: snapshot(["%", "a", "% ls", "file", "%"], cursor: 4))
        #expect(output == "file\n%")
    }

    @Test("rows stay addressed correctly after older lines are trimmed")
    func survivesTrimming() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["x", "%"], cursor: 1))
        // Two lines scrolled off the top: row 1 is now lines[0].
        let output = tracker.newOutput(in: snapshot(["%", "out", "%"], cursor: 3, first: 1))
        #expect(output == "out\n%")
    }

    @Test("nothing is reported from the alternate screen")
    func ignoresAlternateScreen() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["%"], cursor: 0))
        #expect(tracker.newOutput(in: snapshot(["vim stuff"], cursor: 0, alternate: true)) == nil)
    }

    @Test("a cursor moved above where reading stopped restarts at the cursor")
    func recoversFromAClear() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["a", "b", "c", "%"], cursor: 3))
        #expect(tracker.newOutput(in: snapshot(["%", "", "", ""], cursor: 0)) == "%")
    }

    @Test("V7: init(fromTopOf:) reads everything the snapshot holds")
    func v7FromTopOfReadsStartupText() {
        let screen = snapshot(["boot", "%"], cursor: 1)
        var tracker = TerminalOutputTracker(fromTopOf: screen)
        #expect(tracker.newOutput(in: screen) == "boot\n%")
    }

    @Test("V8: a snapshot with no lines gives nil")
    func v8EmptySnapshotIsNil() {
        var tracker = TerminalOutputTracker()
        #expect(tracker.newOutput(in: snapshot([], cursor: 0)) == nil)
    }

    @Test("V9: a resume row trimmed away restarts at the cursor row")
    func v9TrimmedResumeRowRestartsAtCursor() {
        var tracker = TerminalOutputTracker(fromTopOf: snapshot(["a", "b"], cursor: 2, first: 1))
        #expect(tracker.newOutput(in: snapshot(["p", "q"], cursor: 6, first: 5)) == "q")
    }

    @Test("V10: a cursor beyond the last line is clamped without a crash")
    func v10CursorBeyondLastLineIsClamped() {
        var tracker = TerminalOutputTracker()
        #expect(tracker.newOutput(in: snapshot(["x", "y"], cursor: 9)) == "y")
    }

    @Test("V11: a whitespace-only send records no echo")
    func v11WhitespaceSendRecordsNothing() {
        var tracker = TerminalOutputTracker()
        tracker.noteSent("  \n")
        #expect(tracker.newOutput(in: snapshot(["% x"], cursor: 0)) == "% x")
    }

    @Test("V12: the echo match ignores case")
    func v12EchoMatchIgnoresCase() {
        var tracker = TerminalOutputTracker()
        tracker.noteSent("LS")
        #expect(tracker.newOutput(in: snapshot(["% ls"], cursor: 0)) == nil)
    }

    @Test("V13: a non-matching first row keeps its row and clears the echo")
    func v13NonMatchingRowClearsTheEcho() {
        var tracker = TerminalOutputTracker()
        tracker.noteSent("ls")
        #expect(tracker.newOutput(in: snapshot(["% pwd"], cursor: 0)) == "% pwd")
        #expect(tracker.newOutput(in: snapshot(["% pwd", "% ls"], cursor: 1)) == "% ls")
    }

    @Test("V14: the latest noteSent wins")
    func v14LatestSendWins() {
        var tracker = TerminalOutputTracker()
        tracker.noteSent("a")
        tracker.noteSent("b")
        #expect(tracker.newOutput(in: snapshot(["% b"], cursor: 0)) == nil)
    }

    @Test("V15: blank rows give nil")
    func v15BlankRowsGiveNil() {
        var tracker = TerminalOutputTracker()
        #expect(tracker.newOutput(in: snapshot(["", "  ", ""], cursor: 2)) == nil)
    }

    @Test("V16: rows are joined with trailing spaces removed and inner blank rows kept")
    func v16RowsJoinedAndTrimmed() {
        let screen = snapshot(["x   ", "", "y  "], cursor: 2)
        var tracker = TerminalOutputTracker(fromTopOf: screen)
        #expect(tracker.newOutput(in: screen) == "x\n\ny")
    }

    @Test("V17: a blank first row leaves the echo pending")
    func v17BlankFirstRowLeavesEchoPending() {
        let blank = snapshot(["", ""], cursor: 1)
        var tracker = TerminalOutputTracker(fromTopOf: blank)
        tracker.noteSent("ls")
        #expect(tracker.newOutput(in: blank) == nil)
        #expect(tracker.newOutput(in: snapshot(["", "% ls", "done", "%"], cursor: 3)) == "done\n%")
    }

    @Test("V18: an alternate-screen read changes nothing")
    func v18AlternateReadChangesNothing() {
        var tracker = TerminalOutputTracker(startingAt: snapshot(["old", "%"], cursor: 1))
        #expect(tracker.newOutput(in: snapshot(["zz"], cursor: 0, alternate: true)) == nil)
        #expect(tracker.newOutput(in: snapshot(["old", "%", "out", "%"], cursor: 3)) == "out\n%")
    }

    @Test("V19: a read that returns nil because only the echo was left still advances")
    func v19EchoOnlyReadStillAdvances() {
        let first = snapshot(["% ls"], cursor: 0)
        var tracker = TerminalOutputTracker(fromTopOf: first)
        tracker.noteSent("ls")
        #expect(tracker.newOutput(in: first) == nil)
        #expect(tracker.newOutput(in: snapshot(["% ls", "out", "%"], cursor: 2)) == "out\n%")
    }

    @Test("V20: the clamped cursor row, not the raw one, is the next row to read")
    func v20ClampedRowIsTheNextRow() {
        let first = snapshot(["a", "b"], cursor: 9)
        var tracker = TerminalOutputTracker(fromTopOf: first)
        #expect(tracker.newOutput(in: first) == "a\nb")
        #expect(tracker.newOutput(in: snapshot(["a", "b", "c", "d"], cursor: 3)) == "c\nd")
    }
}
