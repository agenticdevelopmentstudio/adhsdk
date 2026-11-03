import XCTest
import Foundation
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// The empty-session reaper. A main-db session is reaped only when it is ended,
/// events.db holds no events, messages or turns for it, and no keep table (a
/// daemon's per-session summary) has a row for it. It never deletes event history.
final class RetentionServiceTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
    }

    override func tearDownWithError() throws {
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    // MARK: - Helpers

    private func iso8601() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: Date())
    }

    private func ingestEvents(count: Int, sessionId: String) throws {
        let sessionHook: [String: Any] = [
            "session_id": sessionId, "cwd": "/tmp", "model": "sonnet", "pid": 0, "term_program": "TestRunner"
        ]
        try database.ingestEvent(eventType: "SessionStart", timestamp: iso8601(), hookData: sessionHook)
        for _ in 0..<count {
            let hookData: [String: Any] = [
                "session_id": sessionId, "cwd": "/tmp", "tool_name": "Read",
                "tool_use_id": "tu-\(UUID().uuidString)", "tool_input": [String: Any]()
            ]
            try database.ingestEvent(eventType: "PreToolUse", timestamp: iso8601(), hookData: hookData)
        }
    }

    /// Attaches a fresh event store and raw archive beside the session database.
    @discardableResult
    private func attachEventStore() throws -> EventStore {
        let directory = URL(fileURLWithPath: tmpPath).deletingLastPathComponent()
        let store = try EventStore(path: directory.appendingPathComponent(EventStore.fileName).path)
        let archive = try RawArchive(
            path: directory.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        database.attachEventReads(store, archive: archive)
        return store
    }

    private func endedSession(_ sessionId: String) throws {
        _ = try database.createSessionStubIfMissing(
            sessionId: sessionId, cwd: "/tmp", model: "m",
            startedAt: "2026-01-01T00:00:00Z", lastActivityAt: "2026-01-01T00:00:00Z", accountEmail: "")
        database.updateSessionStatus(.ended, sessionId: sessionId)
    }

    private func storeEvent(_ sessionId: String, in store: EventStore, provider: String = ClaudeProvider.name) throws {
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "e-\(sessionId)-\(provider)", sessionID: sessionId, kind: .toolCall,
            providerType: "PreToolUse", time: Date(), rawRef: 1)]
        try store.write(batch, provider: provider)
    }

    private func storeTurn(_ sessionId: String, in store: EventStore) throws {
        var batch = NormalizedBatch()
        batch.turns = [TurnRow(
            dedupKey: "t-\(sessionId)", sessionID: sessionId, time: Date(), model: "m",
            inputTokens: 1, outputTokens: 1, rawRef: 1)]
        try store.write(batch, provider: ClaudeProvider.name)
    }

    private func storeMessage(_ sessionId: String, in store: EventStore) throws {
        var batch = NormalizedBatch()
        batch.messages = [MessageRow(
            dedupKey: "m-\(sessionId)", uuid: "u-\(sessionId)", sessionID: sessionId, role: "user",
            time: Date(), text: "hello", rawRef: 1)]
        try store.write(batch, provider: ClaudeProvider.name)
    }

    /// A per-session summary table, as a daemon keeps one.
    private func makeSummaryTable(_ name: String = "summary_keep") throws {
        try database.execute("CREATE TABLE \(name) (session_id TEXT NOT NULL, day TEXT NOT NULL)")
    }

    // MARK: - events.db rows

    func testEndedSessionWithOnlyStoreEventsSurvives() throws {
        let store = try attachEventStore()
        try endedSession("events-only")
        try storeEvent("events-only", in: store)

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 0)
        XCTAssertNotNil(try database.fetchSession(sessionId: "events-only"),
                       "an ended session with events.db events is kept, though event_log has none")
    }

    func testEndedSessionWithOnlyStoreTurnsSurvives() throws {
        let store = try attachEventStore()
        try endedSession("turns-only")
        try storeTurn("turns-only", in: store)

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 0)
        XCTAssertNotNil(try database.fetchSession(sessionId: "turns-only"),
                        "an ended session with only transcript turns is kept")
    }

    func testEndedSessionWithOnlyMessagesSurvives() throws {
        let store = try attachEventStore()
        try endedSession("messages-only")
        try storeMessage("messages-only", in: store)

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 0)
        XCTAssertNotNil(try database.fetchSession(sessionId: "messages-only"),
                        "an ended session with only messages is kept")
    }

    func testEndedSessionWithNeitherIsReaped() throws {
        let store = try attachEventStore()
        try endedSession("empty")
        try storeEvent("empty", in: store, provider: "other")   // another provider's row never protects it
        try endedSession("events-only")
        try storeEvent("events-only", in: store)
        try ingestEvents(count: 0, sessionId: "active")         // active, no events anywhere: not ended

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 1)
        XCTAssertNil(try database.fetchSession(sessionId: "empty"))
        XCTAssertNotNil(try database.fetchSession(sessionId: "events-only"))
        XCTAssertNotNil(try database.fetchSession(sessionId: "active"))
    }

    func testNoEventStoreReapsNothing() throws {
        try endedSession("empty")
        try database.execute("DELETE FROM event_log WHERE session_id = ?", params: ["empty"])

        XCTAssertNil(database.eventReads)
        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(), 0,
                       "an absent store must never read as 'no events'")
        XCTAssertNotNil(try database.fetchSession(sessionId: "empty"))
    }

    func testReapPagesPastSessionsThatHaveEvents() throws {
        // More kept sessions than one page, ordered before the empty one, so the
        // reaper has to page past them to find it.
        let store = try attachEventStore()
        var batch = NormalizedBatch()
        for index in 0..<(DaemonDatabase.claudeReadChunk + 5) {
            let sessionId = String(format: "a-%04d", index)
            try endedSession(sessionId)
            batch.events.append(NormalizedEvent(
                dedupKey: "e-\(sessionId)", sessionID: sessionId, kind: .toolCall,
                providerType: "PreToolUse", time: Date(), rawRef: 1))
        }
        try store.write(batch, provider: ClaudeProvider.name)
        try endedSession("z-empty")

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(batchSize: 10), 1)
        XCTAssertNil(try database.fetchSession(sessionId: "z-empty"))
        XCTAssertEqual(try database.fetchSessions().count, DaemonDatabase.claudeReadChunk + 5)
    }

    func testReapStopsAtTheBatchSize() throws {
        try attachEventStore()
        for index in 0..<3 { try endedSession("empty-\(index)") }

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(batchSize: 2), 2)
        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(batchSize: 2), 1)
        XCTAssertEqual(try database.fetchSessions().count, 0)
    }

    // MARK: - Keep tables (a trimmed session keeps its summary, so it is never reaped)

    func testTrimmedSessionWithASummaryRowIsKept() throws {
        try attachEventStore()                       // events.db holds nothing for it: trimmed
        try makeSummaryTable()
        try endedSession("trimmed")
        try database.execute("INSERT INTO summary_keep(session_id, day) VALUES ('trimmed', '2026-01-01')")
        try endedSession("empty")

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(keepSessionTables: ["summary_keep"]), 1)
        XCTAssertNotNil(try database.fetchSession(sessionId: "trimmed"),
                        "a session whose rows were trimmed keeps its summary row, so it is never reaped")
        XCTAssertNil(try database.fetchSession(sessionId: "empty"),
                     "an ended session with no rows and no summary is reaped")
    }

    func testMissingKeepTableReapsNothing() throws {
        try attachEventStore()
        try endedSession("empty")

        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(keepSessionTables: ["no_such_table"]), 0,
                       "a keep table that is not there must never read as 'no summary'")
        XCTAssertEqual(try database.deleteEndedSessionsWithNoEvents(keepSessionTables: ["bad name;"]), 0)
        XCTAssertNotNil(try database.fetchSession(sessionId: "empty"))
    }

    func testRunOnceReapsWithTheKeepTables() throws {
        try attachEventStore()
        try makeSummaryTable()
        try endedSession("kept")
        try database.execute("INSERT INTO summary_keep(session_id, day) VALUES ('kept', '2026-01-01')")
        try endedSession("empty")

        let service = RetentionService(database: database, keepSessionTables: ["summary_keep"])
        XCTAssertEqual(try service.runOnce(), .complete)
        XCTAssertNotNil(try database.fetchSession(sessionId: "kept"))
        XCTAssertNil(try database.fetchSession(sessionId: "empty"))
    }

    func testReaperNeverDeletesEventHistory() throws {
        try attachEventStore()
        try ingestEvents(count: 3, sessionId: "live")
        database.updateSessionStatus(.ended, sessionId: "live")
        var before = 0
        try database.query("SELECT COUNT(*) FROM event_log") { row in before = Int(database.int(row, 0)) }

        _ = try RetentionService(database: database).runOnce()

        var after = 0
        try database.query("SELECT COUNT(*) FROM event_log") { row in after = Int(database.int(row, 0)) }
        XCTAssertEqual(after, before, "the reaper deletes no event_log row")
        XCTAssertNotNil(try database.fetchSession(sessionId: "live"), "legacy event_log rows still protect it")
    }
}
