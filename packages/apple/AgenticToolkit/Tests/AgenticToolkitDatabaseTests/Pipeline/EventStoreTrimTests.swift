import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

final class EventStoreTrimTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-trim-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func path(_ name: String = EventStore.fileName) -> String {
        tmpDir.appendingPathComponent(name).path
    }

    private func makeStore(_ name: String = EventStore.fileName) throws -> EventStore {
        try EventStore(path: path(name))
    }

    private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: 1_800_000_000 + seconds) }

    private var future: Date { Date().addingTimeInterval(600) }

    private func event(_ key: String, session: String, at seconds: Double,
                       attrs: [String: NormalizedValue] = [:]) -> NormalizedEvent {
        NormalizedEvent(
            dedupKey: key, sessionID: session, kind: .toolCall, providerType: "PreToolUse",
            time: date(seconds), toolName: "Bash", attrs: attrs, rawRef: 1)
    }

    private func turn(_ key: String, session: String, at seconds: Double) -> TurnRow {
        TurnRow(dedupKey: key, sessionID: session, time: date(seconds), inputTokens: 1, rawRef: 2)
    }

    private func message(_ key: String, session: String, at seconds: Double) -> MessageRow {
        MessageRow(dedupKey: key, uuid: key, sessionID: session, role: "user", time: date(seconds),
                   text: "hi", rawRef: 3)
    }

    private func times(_ store: EventStore, _ table: String) throws -> [Double] {
        try store.read { conn in try Double.fetchAll(conn, sql: "SELECT time FROM \(table) ORDER BY time") }
    }

    private func sessionIDs(_ store: EventStore) throws -> [String] {
        try store.read { conn in try String.fetchAll(conn, sql: "SELECT session_id FROM sessions ORDER BY 1") }
    }

    // MARK: - trim

    func testTrimDeletesExactlyTheRowsOlderThanTheCutoff() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        for index in 0..<20 {
            let seconds = Double(index * 10)   // 0…190; the cutoff is 100
            batch.events.append(event("e\(index)", session: "s1", at: seconds))
            batch.turns.append(turn("t\(index)", session: "s1", at: seconds))
            batch.messages.append(message("m\(index)", session: "s1", at: seconds))
        }
        batch.sessions = [SessionUpsert(sessionID: "s1", asOf: date(0), status: "active", startedAt: date(0))]
        try store.write(batch, provider: "mock")

        let cutoff = date(100).timeIntervalSince1970
        let result = try store.trim(olderThan: cutoff, batch: 3, deadline: future)

        XCTAssertEqual(result, EventStoreTrimResult(events: 10, messages: 10, turns: 10, sessions: 0, finished: true))
        let kept = (10..<20).map { date(Double($0 * 10)).timeIntervalSince1970 }
        XCTAssertEqual(try times(store, "events"), kept)
        XCTAssertEqual(try times(store, "turns"), kept)
        XCTAssertEqual(try times(store, "messages"), kept)
        XCTAssertEqual(try sessionIDs(store), ["s1"])
        // A second pass finds nothing.
        XCTAssertEqual(try store.trim(olderThan: cutoff, deadline: future),
                       EventStoreTrimResult(events: 0, messages: 0, turns: 0, sessions: 0, finished: true))
    }

    func testTrimDeletesOnlyEndedSessionsLeftEmpty() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        // Ended by status; every row old, so the trim empties it.
        batch.sessions.append(SessionUpsert(sessionID: "ended-empty", asOf: date(5), status: "ended",
                                            startedAt: date(1), endedAt: date(5)))
        batch.events.append(event("a1", session: "ended-empty", at: 1))
        batch.messages.append(message("a2", session: "ended-empty", at: 2))
        batch.turns.append(turn("a3", session: "ended-empty", at: 3))
        // Ended by ended_at alone, with no rows at all.
        batch.sessions.append(SessionUpsert(sessionID: "ended-at-only", asOf: date(6), endedAt: date(6)))
        // Ended, but one turn survives the cutoff.
        batch.sessions.append(SessionUpsert(sessionID: "ended-with-turn", asOf: date(7), status: "ended",
                                            endedAt: date(7)))
        batch.events.append(event("b1", session: "ended-with-turn", at: 4))
        batch.turns.append(turn("b2", session: "ended-with-turn", at: 200))
        // Active with no rows.
        batch.sessions.append(SessionUpsert(sessionID: "active-empty", asOf: date(8), status: "active",
                                            startedAt: date(8)))
        try store.write(batch, provider: "mock")

        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)

        XCTAssertEqual(result, EventStoreTrimResult(events: 2, messages: 1, turns: 1, sessions: 2, finished: true))
        XCTAssertEqual(try sessionIDs(store), ["active-empty", "ended-with-turn"])
    }

    func testTrimKeepsAnEndedEmptySessionThatEndedAfterTheCutoff() throws {
        // A session's rows may land after its end record; one that ended inside the
        // kept window is not reaped yet.
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.sessions = [SessionUpsert(sessionID: "recent", asOf: date(500), status: "ended", endedAt: date(500))]
        try store.write(batch, provider: "mock")

        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)

        XCTAssertEqual(result.sessions, 0)
        XCTAssertEqual(try sessionIDs(store), ["recent"])
    }

    func testTrimPastDeadlineStopsAfterOneBatch() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.events = (0..<1200).map { event("e\($0)", session: "s", at: Double($0) / 100) }
        batch.turns = [turn("t", session: "s", at: 1)]
        try store.write(batch, provider: "mock")
        let cutoff = date(100).timeIntervalSince1970

        let first = try store.trim(olderThan: cutoff, batch: 500, deadline: .distantPast)

        XCTAssertFalse(first.finished)
        XCTAssertEqual(first.events + first.messages + first.turns + first.sessions, 500)
        XCTAssertEqual(try store.counts().events, 700)
        // Oldest first: what is left is the newest 700.
        XCTAssertEqual(try times(store, "events").first, date(5).timeIntervalSince1970)

        let rest = try store.trim(olderThan: cutoff, batch: 500, deadline: future)
        XCTAssertTrue(rest.finished)
        XCTAssertEqual(rest.events, 700)
        XCTAssertEqual(rest.turns, 1)
        XCTAssertEqual(try store.counts().events, 0)
    }

    // MARK: - incrementalVacuum and stats

    func testIncrementalVacuumEmptiesTheFreelistAndShrinksTheFile() throws {
        let store = try makeStore()
        let padding = NormalizedValue.string(String(repeating: "x", count: 400))
        var batch = NormalizedBatch()
        batch.events = (0..<10_000).map { event("e\($0)", session: "s", at: 1, attrs: ["pad": padding]) }
        try store.write(batch, provider: "mock")
        XCTAssertEqual(try store.trim(olderThan: date(100).timeIntervalSince1970, batch: 2000, deadline: future).events,
                       10_000)

        let before = try store.fileStats()
        XCTAssertEqual(before.autoVacuum, 2)
        XCTAssertGreaterThan(before.freelistCount, 0)

        let freed = try store.incrementalVacuum(pagesPerStep: 64, deadline: future)

        let after = try store.fileStats()
        XCTAssertEqual(freed, before.freelistCount)
        XCTAssertEqual(after.freelistCount, 0)
        XCTAssertLessThan(after.pageCount, before.pageCount)
        XCTAssertLessThan(after.bytes, before.bytes)
        XCTAssertEqual(after.path, store.path)
    }

    func testIncrementalVacuumIsUnavailableWithoutIncrementalAutoVacuum() throws {
        let filePath = path("legacy.db")
        do {
            // Built without the store's prepare: auto_vacuum stays NONE once page 1 exists.
            let queue = try DatabaseQueue(path: filePath)
            try queue.writeWithoutTransaction { conn in
                try conn.execute(sql: "PRAGMA auto_vacuum = NONE")
                try conn.execute(sql: "CREATE TABLE legacy(x)")
            }
        }
        let store = try EventStore(path: filePath)
        let before = try store.fileStats()
        XCTAssertEqual(before.autoVacuum, 0)

        XCTAssertNil(try store.incrementalVacuum(deadline: future))
        XCTAssertEqual(try store.fileStats().pageCount, before.pageCount)
    }

    func testFileStatsSumsTheMainFileWalAndShm() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.events = [event("e", session: "s", at: 1)]
        try store.write(batch, provider: "mock")

        let stats = try store.fileStats()
        let manager = FileManager.default
        var expected: Int64 = 0
        for suffix in ["", "-wal", "-shm"] {
            let attributes = try? manager.attributesOfItem(atPath: store.path + suffix)
            expected += (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        }
        XCTAssertEqual(stats.bytes, expected)
        XCTAssertGreaterThan(stats.pageSize, 0)
        XCTAssertGreaterThan(stats.pageCount, 0)
        XCTAssertEqual(try SQLiteFileStats.stats(path: store.path).pageSize, stats.pageSize)
        XCTAssertEqual(try SQLiteFileStats.stats(path: store.path).autoVacuum, 2)
    }

    func testSQLiteFileStatsThrowsOnAMissingFileAndNeverCreatesIt() {
        let missing = path("missing.db")
        XCTAssertThrowsError(try SQLiteFileStats.stats(path: missing))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing + "-wal"))
    }

    // MARK: - tool_use_id index

    func testToolUseIdLookupUsesItsIndex() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.events = [
            event("p1", session: "s", at: 10, attrs: ["tool_use_id": .string("toolu_1")]),
            event("p2", session: "s", at: 20, attrs: ["tool_use_id": .string("toolu_2")])
        ]
        try store.write(batch, provider: "claude")
        XCTAssertTrue(try store.indexNames().contains("events_tool_use_id"))

        let sql = DaemonDatabase.claudeToolDurationSQL
        let arguments: StatementArguments = ["claude", "toolu_2", "s"]
        let plan = try store.read { conn in
            try Row.fetchAll(conn, sql: "EXPLAIN QUERY PLAN " + sql, arguments: arguments)
                .map { $0["detail"] as String? ?? "" }
        }
        XCTAssertTrue(plan.contains { $0.contains("events_tool_use_id") }, "plan: \(plan)")
        XCTAssertEqual(try store.read { try Double.fetchOne($0, sql: sql, arguments: arguments) },
                       date(20).timeIntervalSince1970)
    }

    func testBulkLoadDropsAndRestoresTheToolUseIdIndex() throws {
        let store = try makeStore()
        try store.beginBulkLoad()
        XCTAssertFalse(try store.indexNames().contains("events_tool_use_id"))
        try store.endBulkLoad()
        XCTAssertTrue(try store.indexNames().contains("events_tool_use_id"))
    }
}
