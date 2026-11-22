import AgenticDeveloperHubSDKCore
import XCTest
import SQLite3
@testable import AgenticDeveloperHubSDKDatabase

/// `sessions.last_event_type` is the state behind the Sessions window's activity icon.
/// Only events about the main agent's turn may set it (`HookEventType.setsTurnState`), and an
/// interrupt — which fires no hook — is read out of the transcript by
/// `InterruptedTurnTask`.
final class TurnStateTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    private var tempFiles: [String] = []

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "turn-state-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/turn-state.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        for path in [(tmpPath as NSString).deletingLastPathComponent] + tempFiles {
            try? FileManager.default.removeItem(atPath: path)
        }
        tempFiles = []
    }

    private func ingest(_ type: String, _ session: String, at second: Int, _ extra: [String: Any] = [:]) throws {
        var hook: [String: Any] = ["session_id": session, "cwd": "/tmp"]
        hook.merge(extra) { _, new in new }
        try database.ingestEvent(
            eventType: type, timestamp: String(format: "2026-06-01T12:00:%02dZ", second), hookData: hook
        )
    }

    private func state(_ session: String) throws -> String? {
        try database.fetchSession(sessionId: session)?.lastEventType
    }

    // MARK: - The rule

    func testOnlyEventsAboutTheMainTurnSetTheState() {
        let sets = { (type: String, data: [String: Any]) in HookEventType.setsTurnState(type, hookData: data) }

        for type in ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "StopFailure", "SessionEnd"] {
            XCTAssertTrue(sets(type, [:]), type)
        }
        for type in ["SubagentStart", "SubagentStop", "TaskCreated", "TaskCompleted", "TeammateIdle",
                     "PreCompact", "PostCompact", "FileChanged", "ConfigChange", "StatusLine", "InstructionsLoaded"] {
            XCTAssertFalse(sets(type, [:]), type)
        }
        XCTAssertFalse(sets("PreToolUse", ["agent_id": "a1"]), "a subagent's tool call is not the main turn")
        XCTAssertFalse(sets("StopFailure", ["agent_id": "a1"]))
        XCTAssertTrue(sets("PermissionRequest", ["agent_id": "a1"]), "a subagent's request still waits on the user")

        XCTAssertFalse(sets("Notification", ["notification_type": "idle_prompt"]))
        XCTAssertFalse(sets("Notification", ["notification_type": "auth_success"]))
        XCTAssertTrue(sets("Notification", ["notification_type": "permission_prompt"]))
        XCTAssertTrue(sets("Notification", ["notification_type": "elicitation_dialog"]))
        XCTAssertTrue(sets("Notification", [:]), "an untyped notification keeps reading as waiting")

        XCTAssertTrue(sets("SessionStart", ["source": "startup"]))
        XCTAssertFalse(sets("SessionStart", ["source": "compact"]))
    }

    // MARK: - The upsert

    /// A background subagent finishing after the turn's Stop left the finished
    /// session spinning forever.
    func testASubagentFinishingAfterStopKeepsTheSessionIdle() throws {
        try ingest("PreToolUse", "s", at: 1)
        try ingest("Stop", "s", at: 2)
        try ingest("SubagentStop", "s", at: 3, ["agent_id": "a1"])
        try ingest("PostToolUse", "s", at: 4, ["agent_id": "a1"])
        XCTAssertEqual(try state("s"), "Stop")
        XCTAssertEqual(try database.fetchSession(sessionId: "s")?.lastActivityAt.suffix(8), "12:00:04",
                       "the subagent's events are still activity")
    }

    /// Claude Code sends the idle reminder a minute after every finished turn; stored,
    /// it turned every idle session into one waiting for attention.
    func testTheIdleReminderDoesNotMakeASessionWaiting() throws {
        try ingest("Stop", "s", at: 1)
        try ingest("Notification", "s", at: 2, ["notification_type": "idle_prompt"])
        XCTAssertEqual(try state("s"), "Stop")

        try ingest("Notification", "s", at: 3, ["notification_type": "permission_prompt"])
        XCTAssertEqual(try state("s"), "Notification")
    }

    func testARowCreatedByAnOffTurnEventRecordsNoState() throws {
        try ingest("SubagentStop", "fresh", at: 1, ["agent_id": "a1"])
        XCTAssertEqual(try state("fresh"), "")
        try ingest("UserPromptSubmit", "fresh", at: 2)
        XCTAssertEqual(try state("fresh"), "UserPromptSubmit")
    }

    // MARK: - Interrupts

    /// A transcript whose newest record is a user record reading `text`, written at
    /// `second` past 12:00 (with milliseconds, as Claude Code writes them).
    private func transcript(endingWith text: String, at second: Int = 3) throws -> String {
        let path = (tmpPath as NSString).deletingLastPathComponent + "/turn-state-\(UUID().uuidString).jsonl"
        tempFiles.append(path)
        let records: [[String: Any]] = [
            ["type": "assistant", "timestamp": "2026-06-01T12:00:00.100Z",
             "message": ["content": [["type": "tool_use", "name": "Bash"]]]],
            ["type": "user", "timestamp": String(format: "2026-06-01T12:00:%02d.500Z", second),
             "message": ["content": [["type": "text", "text": text]]]]
        ]
        var body = Data()
        for record in records {
            body.append(try JSONSerialization.data(withJSONObject: record))
            body.append(0x0A)
        }
        try body.write(to: URL(fileURLWithPath: path))
        return path
    }

    func testAnInterruptedTurnIsRecordedAndAFinishedOneIsLeftAlone() throws {
        let interrupted = try transcript(endingWith: "[Request interrupted by user for tool use]")
        let resumed = try transcript(endingWith: "carry on")
        try ingest("PreToolUse", "cut", at: 1)
        try ingest("PreToolUse", "busy", at: 1)
        try ingest("Stop", "done", at: 1)
        let paths = ["cut": interrupted, "busy": resumed, "done": interrupted]
        let task = InterruptedTurnTask(database: database, findTranscriptPath: { paths[$0] })

        XCTAssertEqual(try task.markInterruptedTurns(), ["cut"])
        XCTAssertEqual(try state("cut"), HookEventType.interruptedEventType)
        XCTAssertEqual(try state("busy"), "PreToolUse")
        XCTAssertEqual(try state("done"), "Stop", "a finished turn is never re-read")
        XCTAssertEqual(try task.markInterruptedTurns(), [], "an interrupt is recorded once")

        // The user's next prompt is newer news than the interrupt.
        try ingest("UserPromptSubmit", "cut", at: 5)
        XCTAssertEqual(try state("cut"), "UserPromptSubmit")
    }

    /// A hook that lands between the transcript read and the write wins.
    func testTheInterruptWriteLosesToAnyNewerState() throws {
        try ingest("PreToolUse", "s", at: 1)
        let candidate = try XCTUnwrap(try database.turnStateCandidates().first { $0.sessionId == "s" })
        XCTAssertEqual(candidate.turnStateAt, "2026-06-01 12:00:01")
        try ingest("PostToolUse", "s", at: 2)

        XCTAssertFalse(try database.markTurnInterrupted(
            sessionId: "s", ifEventType: candidate.lastEventType, setAt: candidate.turnStateAt,
            interruptedAt: "2026-06-01T12:00:03.000Z"
        ))
        XCTAssertEqual(try state("s"), "PostToolUse")
    }

    /// The transcript lags the hooks: the next prompt's `UserPromptSubmit` lands while
    /// the old interrupt is still the transcript's newest record. That session is
    /// working again, not interrupted.
    func testAnInterruptOlderThanTheStateIsNotNews() throws {
        let stale = try transcript(endingWith: "[Request interrupted by user]", at: 3)
        try ingest("PreToolUse", "s", at: 1)
        try ingest("UserPromptSubmit", "s", at: 9)
        let task = InterruptedTurnTask(database: database, findTranscriptPath: { _ in stale })

        XCTAssertEqual(try task.markInterruptedTurns(), [])
        XCTAssertEqual(try state("s"), "UserPromptSubmit")
    }

    /// A background subagent still at work after the user cut the main turn short
    /// moves the session's clock, but not the turn state the interrupt is weighed against.
    func testASubagentStillRunningDoesNotHideTheInterrupt() throws {
        let cut = try transcript(endingWith: "[Request interrupted by user for tool use]", at: 3)
        try ingest("PreToolUse", "s", at: 1)
        try ingest("PostToolUse", "s", at: 5, ["agent_id": "a1"])
        let task = InterruptedTurnTask(database: database, findTranscriptPath: { _ in cut })

        XCTAssertEqual(try task.markInterruptedTurns(), ["s"])
        XCTAssertEqual(try state("s"), HookEventType.interruptedEventType)
    }

    /// A blank `turn_state_at` — what migration041 leaves when the event it re-derived
    /// state from carried no parseable timestamp — made the ordering guard vacuously
    /// true, because SQLite sorts every datetime string above `''`. Any marker, however
    /// old, could then flip the row.
    func testAnInterruptIsWeighedAgainstActivityWhenTheStateHasNoTime() throws {
        try ingest("SubagentStop", "blank", at: 9, ["agent_id": "a1"])
        XCTAssertEqual(try state("blank"), "", "precondition: an off-turn event records no state")

        XCTAssertFalse(try database.markTurnInterrupted(
            sessionId: "blank", ifEventType: "", setAt: "",
            interruptedAt: "2026-06-01T12:00:03.000Z"
        ), "an interrupt older than the row's only known clock is not news")
        XCTAssertEqual(try state("blank"), "")

        XCTAssertTrue(try database.markTurnInterrupted(
            sessionId: "blank", ifEventType: "", setAt: "",
            interruptedAt: "2026-06-01T12:00:11.000Z"
        ), "one newer than it still applies")
        XCTAssertEqual(try state("blank"), HookEventType.interruptedEventType)
    }

    /// An interrupt is not activity, so `markTurnInterrupted` moves `turn_state_at`
    /// and leaves `last_activity_at` where it was. Weighed against activity, the
    /// upsert's comparison value therefore froze at the pre-interrupt event and every
    /// straggler that arrived afterwards — a drop-dir backlog, a quarantine Retry-All
    /// — still compared `>=` and regressed the state, which the task then re-marked.
    func testAStragglerOlderThanTheInterruptDoesNotRegressTheState() throws {
        let cut = try transcript(endingWith: "[Request interrupted by user for tool use]", at: 3)
        try ingest("PreToolUse", "s", at: 1)
        let task = InterruptedTurnTask(database: database, findTranscriptPath: { _ in cut })
        XCTAssertEqual(try task.markInterruptedTurns(), ["s"])

        // Replayed out of order: newer than the frozen `last_activity_at` (1),
        // older than the interrupt's `turn_state_at` (3).
        try ingest("PreToolUse", "s", at: 2)

        XCTAssertEqual(try state("s"), HookEventType.interruptedEventType,
                       "a straggler older than the interrupt is not news")
        try ingest("PostToolUse", "s", at: 4)
        XCTAssertEqual(try state("s"), "PostToolUse", "a genuinely newer event still wins")
    }

    func testTheTaskIsScheduled() async throws {
        let task = InterruptedTurnTask(database: database, findTranscriptPath: { _ in nil })
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        _ = try await task.execute(context: ctx)
        XCTAssertTrue(task.schedule.enabled)
    }

    // MARK: - The subagent clock

    /// An event with no timestamp is stamped `datetime('now')` by the upsert, which
    /// is what the five-minute freshness window is measured against — a fixture
    /// pinned to 2026-06-01 is always stale by construction.
    private func ingestNow(_ type: String, _ session: String, _ extra: [String: Any] = [:]) throws {
        var hook: [String: Any] = ["session_id": session, "cwd": "/tmp"]
        hook.merge(extra) { _, new in new }
        try database.ingestEvent(eventType: type, timestamp: "", hookData: hook)
    }

    /// An event `seconds` before now — fresh enough to count, old enough to be
    /// overtaken by one ingested with no timestamp.
    private func ingestAgo(_ seconds: Int, _ type: String, _ session: String, _ extra: [String: Any] = [:]) throws {
        var hook: [String: Any] = ["session_id": session, "cwd": "/tmp"]
        hook.merge(extra) { _, new in new }
        let stamp = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(seconds)))
        try database.ingestEvent(eventType: type, timestamp: stamp, hookData: hook)
    }

    private func subagentWorking(_ session: String) throws -> Bool? {
        try database.fetchSession(sessionId: session)?.subagentWorking
    }

    func testTheSubagentClockHearsOnlySubagents() {
        let clock = { (type: String, data: [String: Any]) in HookEventType.subagentClock(type, hookData: data) }

        XCTAssertEqual(clock("PreToolUse", ["agent_id": "a1"]), 1)
        XCTAssertEqual(clock("PostToolUse", ["agent_id": "a1"]), 1)
        XCTAssertEqual(clock("SubagentStart", ["agent_id": "a1"]), 1)
        XCTAssertEqual(clock("SubagentStop", ["agent_id": "a1"]), -1,
                       "a stop is terminal — it clears rather than stamps")
        XCTAssertEqual(clock("SubagentStop", [:]), -1, "terminal even without the id")
        XCTAssertEqual(clock("PreToolUse", [:]), 0, "the main agent's own tool call says nothing")
        XCTAssertEqual(clock("Stop", [:]), 0)
        XCTAssertEqual(clock("PreToolUse", ["agent_id": ""]), 0, "a blank id is no id")
        XCTAssertEqual(clock("StopFailure", ["agent_id": "a1"]), -1,
                       "a subagent the API refused is finished, and rarely sends a SubagentStop")
        XCTAssertEqual(clock("StopFailure", [:]), 0, "the main turn failing says nothing of subagents")
    }

    func testASubagentStopFailureClearsTheClock() throws {
        try ingestNow("PostToolUse", "s", ["agent_id": "a1"])
        try ingestNow("StopFailure", "s", ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), false)
    }

    /// The clear used to forget when the stop happened, so any older subagent event
    /// ingested after it — a drained backlog, a re-feed — compared above '' and
    /// brought the finished subagent back to life.
    func testAnEventOlderThanTheStopCannotReviveTheSubagent() throws {
        // Seconds apart: the columns keep whole seconds, and an event in the
        // same second as the stop cannot be told from one before it.
        try ingestAgo(5, "SubagentStop", "s", ["agent_id": "a1"])
        try ingestAgo(30, "PostToolUse", "s", ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), false)
        try ingestNow("PreToolUse", "s", ["agent_id": "a2"])
        XCTAssertEqual(try subagentWorking("s"), true, "a hook newer than the stop still stamps")
    }

    /// An interrupt kills the turn's foreground subagents without a `SubagentStop`.
    func testAnInterruptClearsTheSubagentClock() throws {
        try ingestAgo(60, "PreToolUse", "s")
        try ingestAgo(30, "PostToolUse", "s", ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), true, "precondition")
        let setAt = try database.turnStateCandidates().first { $0.sessionId == "s" }?.turnStateAt ?? ""
        XCTAssertTrue(try database.markTurnInterrupted(
            sessionId: "s", ifEventType: "PreToolUse", setAt: setAt,
            interruptedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-10))))
        XCTAssertEqual(try subagentWorking("s"), false)
        try ingestNow("PostToolUse", "s", ["agent_id": "background"])
        XCTAssertEqual(try subagentWorking("s"), true, "a subagent that outlived the interrupt re-stamps")
    }

    /// The gap `last_event_type` cannot describe: the main agent has handed back
    /// while a background subagent is still working.
    func testASessionWaitingOnASubagentReadsAsWorking() throws {
        try ingestNow("Stop", "s")
        try ingestNow("PostToolUse", "s", ["agent_id": "a1"])
        XCTAssertEqual(try state("s"), "Stop", "the turn's own state is untouched")
        XCTAssertEqual(try subagentWorking("s"), true)
    }

    func testASubagentStopClearsTheClockOutright() throws {
        try ingestNow("PostToolUse", "s", ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), true)
        try ingestNow("SubagentStop", "s", ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), false,
                       "one per subagent, so it ends the reading rather than ageing out")
    }

    /// A subagent that died without its terminal stop must not read as working
    /// forever — the window is the backstop the clear can't be.
    func testAStaleSubagentStampAgesOut() throws {
        try ingest("PostToolUse", "s", at: 1, ["agent_id": "a1"])
        XCTAssertEqual(try subagentWorking("s"), false)
    }

    /// Monotonic like the turn's clock: a replayed backlog can't resurrect one.
    func testAnOlderSubagentEventCannotOverwriteANewerStamp() throws {
        try ingestNow("PostToolUse", "s", ["agent_id": "a1"])
        try ingest("PreToolUse", "s", at: 2, ["agent_id": "a2"])
        XCTAssertEqual(try subagentWorking("s"), true, "the fresh stamp stands")
    }

    func testTheMainAgentsOwnEventsNeverTouchTheClock() throws {
        try ingestNow("PreToolUse", "s")
        try ingestNow("Stop", "s")
        XCTAssertEqual(try subagentWorking("s"), false)
    }

    // MARK: - Migration 041

    /// Rows the old upsert left stuck are re-derived from their own hook events on the
    /// next launch; imported transcript rows and ended sessions are left out of it.
    func testMigration041ReDerivesStuckActiveSessions() throws {
        try ingest("PreToolUse", "stuck", at: 1)
        try ingest("Stop", "stuck", at: 2)
        try ingest("Notification", "stuck", at: 3, ["notification_type": "idle_prompt"])
        try ingest("SubagentStop", "stuck", at: 4, ["agent_id": "a1"])
        _ = try database.insertImportedEvent(
            eventType: "UserPromptSubmit", timestamp: "2026-06-01T12:00:09Z",
            sessionId: "stuck", cwd: "/tmp", detail: "", messageId: "user:stuck:9"
        )
        try ingest("PreToolUse", "busy", at: 6)
        try ingest("PreToolUse", "gone", at: 1)
        database.updateSessionStatus(.ended, sessionId: "gone")
        database.waitForPendingWrites()
        database = nil

        var handle: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tmpPath, &handle), SQLITE_OK)
        let seed = """
            UPDATE sessions SET last_event_type = 'SubagentStop', turn_state_at = '';
            DELETE FROM schema_migrations WHERE version = 41;
            """
        XCTAssertEqual(sqlite3_exec(handle, seed, nil, nil, nil), SQLITE_OK,
                       "precondition seed must succeed: \(String(cString: sqlite3_errmsg(handle)))")
        sqlite3_close(handle)

        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)  // reopen runs migration041

        XCTAssertEqual(try state("stuck"), "Stop")
        XCTAssertEqual(try state("busy"), "PreToolUse")
        XCTAssertEqual(try database.turnStateCandidates().first { $0.sessionId == "busy" }?.turnStateAt,
                       "2026-06-01 12:00:06", "the state's own time is recovered with it")
        XCTAssertEqual(try state("gone"), "SubagentStop", "an ended session reads idle whatever it stores")
    }
}
