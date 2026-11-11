import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

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

    /// A batch ejected by the write deadline is run again at half the size, and the
    /// size that went through is kept; at the minimum the deadline error is thrown.
    func testABatchThatRunsOutOfTimeIsRetriedSmaller() throws {
        var limit = 500
        var tried: [Int] = []
        let deleted = try EventStore.shrinkingOnDeadline(&limit) { size in
            tried.append(size)
            if size > 100 { throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000) }
            return size
        }
        XCTAssertEqual(tried, [500, 250, 125, 62])
        XCTAssertEqual(deleted, 62)
        XCTAssertEqual(limit, 62)

        var floor = 50
        XCTAssertThrowsError(try EventStore.shrinkingOnDeadline(&floor) { _ in
            throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
        }) { error in
            XCTAssertEqual(error as? BoundedDatabaseError,
                           .deadlineExceeded(lane: "write", elapsedMs: 60_000))
        }
        XCTAssertEqual(floor, EventStore.minimumTrimBatch)
    }

    /// Out of pass time, an ejected batch is not retried: the stage stops with
    /// nothing from it, and the halved size is kept for the next pass.
    func testABatchOutOfPassTimeStopsHalving() throws {
        var limit = 500
        var tried: [Int] = []
        let deleted = try EventStore.shrinkingOnDeadline(&limit, until: .now) { size -> Int in
            tried.append(size)
            throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
        }
        XCTAssertNil(deleted)
        XCTAssertEqual(tried, [500])
        XCTAssertEqual(limit, 250)
    }

    func testAFastBatchGrowsTheNextBackToTheFullBatch() {
        XCTAssertEqual(EventStore.grownTrimBatch(62, upTo: 500, took: .seconds(1)), 124)
        XCTAssertEqual(EventStore.grownTrimBatch(400, upTo: 500, took: .seconds(1)), 500)
        XCTAssertEqual(EventStore.grownTrimBatch(500, upTo: 500, took: .seconds(1)), 500)
        XCTAssertEqual(EventStore.grownTrimBatch(62, upTo: 500, took: .seconds(10)), 62)
        XCTAssertEqual(EventStore.grownTrimBatch(62, upTo: 500, took: .seconds(70)), 62)
    }

    func testTheNextTrimStartsFromTheBatchTheLastOneEndedOn() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        for index in 0..<20 {
            batch.messages.append(message("m\(index)", session: "s1", at: Double(index * 10)))
        }
        batch.sessions = [SessionUpsert(sessionID: "s1", asOf: date(0), status: "active", startedAt: date(0))]
        try store.write(batch, provider: "mock")
        XCTAssertNil(store.carriedTrimBatch)

        // A carried size below the full batch is where the next trim starts, and
        // fast batches grow it back.
        store.carriedTrimBatch = 1
        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, batch: 500, deadline: future)
        XCTAssertEqual(result, EventStoreTrimResult(events: 0, messages: 10, turns: 0, sessions: 0, finished: true))
        let carried = try XCTUnwrap(store.carriedTrimBatch)
        XCTAssertGreaterThan(carried, 1)
        XCTAssertLessThanOrEqual(carried, 500)

        // Never above the batch the caller passes.
        store.carriedTrimBatch = 1000
        _ = try store.trim(olderThan: date(150).timeIntervalSince1970, batch: 3, deadline: future)
        XCTAssertEqual(store.carriedTrimBatch, 3)
    }

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

    /// `maxTurnId` keeps every old timed turn with a higher id; events and
    /// messages are trimmed as usual.
    func testMaxTurnIdKeepsNewerTurns() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        for index in 0..<4 {
            batch.events.append(event("e\(index)", session: "s1", at: Double(index)))
            batch.turns.append(turn("t\(index)", session: "s1", at: Double(index)))
            batch.messages.append(message("m\(index)", session: "s1", at: Double(index)))
        }
        batch.sessions = [SessionUpsert(sessionID: "s1", asOf: date(0), status: "active", startedAt: date(0))]
        try store.write(batch, provider: "mock")
        let ids = try store.read { conn in try Int64.fetchAll(conn, sql: "SELECT id FROM turns ORDER BY id") }

        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, maxTurnId: ids[1], deadline: future)

        XCTAssertEqual(result, EventStoreTrimResult(events: 4, messages: 4, turns: 2, sessions: 0, finished: true))
        XCTAssertEqual(try store.read { conn in try Int64.fetchAll(conn, sql: "SELECT id FROM turns ORDER BY id") },
                       Array(ids[2...]))
        // With no bound, the rest go.
        XCTAssertEqual(try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future).turns, 2)
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

    /// A row with no time (epoch 0) has an unknown age: a live session keeps it,
    /// and it goes only with a session that ended before the cutoff (a turn folded
    /// into `trimmed_turns` like any other).
    func testUntimedRowsGoOnlyWithASessionThatEndedBeforeTheCutoff() throws {
        let store = try makeStore()
        let epoch = Date(timeIntervalSince1970: 0)
        var batch = NormalizedBatch()
        for session in ["live", "gone", "ended-late"] {
            batch.events.append(NormalizedEvent(
                dedupKey: "e-\(session)", sessionID: session, kind: .toolCall, providerType: "PreToolUse",
                time: epoch, toolName: "Bash", attrs: [:], rawRef: 1))
            batch.messages.append(MessageRow(dedupKey: "m-\(session)", uuid: "m-\(session)", sessionID: session,
                                             role: "user", time: epoch, text: "hi", rawRef: 3))
            batch.turns.append(TurnRow(dedupKey: "t-\(session)", sessionID: session, time: epoch,
                                       inputTokens: 7, rawRef: 2))
        }
        batch.sessions = [
            SessionUpsert(sessionID: "live", asOf: date(1), status: "active", startedAt: date(1)),
            SessionUpsert(sessionID: "gone", asOf: date(5), status: "ended", startedAt: date(1), endedAt: date(5)),
            SessionUpsert(sessionID: "ended-late", asOf: date(500), status: "ended", endedAt: date(500))
        ]
        try store.write(batch, provider: "mock")

        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)

        XCTAssertEqual(result, EventStoreTrimResult(events: 1, messages: 1, turns: 1, sessions: 1, finished: true))
        XCTAssertEqual(try sessionIDs(store), ["ended-late", "live"])
        let left = try store.read { conn in
            try String.fetchAll(conn, sql: "SELECT session_id FROM turns ORDER BY 1")
        }
        XCTAssertEqual(left, ["ended-late", "live"])
        let folded = try store.read { conn in
            try Row.fetchAll(conn, sql: "SELECT session_id, input_tokens FROM trimmed_turns")
        }
        XCTAssertEqual(folded.map { $0["session_id"] as String }, ["gone"])
        XCTAssertEqual(folded.map { $0["input_tokens"] as Int }, [7])
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
        XCTAssertEqual(first, EventStoreTrimResult(events: 500, finished: false))
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

    /// The vacuum's large page cache is the vacuum's alone: the writer's cache
    /// size is back to what it was once the vacuum returns.
    func testIncrementalVacuumPutsTheWritersCacheSizeBack() throws {
        let store = try makeStore()
        let padding = NormalizedValue.string(String(repeating: "x", count: 400))
        var batch = NormalizedBatch()
        batch.events = (0..<2_000).map { event("e\($0)", session: "s", at: 1, attrs: ["pad": padding]) }
        try store.write(batch, provider: "mock")
        _ = try store.trim(olderThan: date(100).timeIntervalSince1970, batch: 2000, deadline: future)
        let cacheSize = {
            try store.pool.writeWithoutTransaction { conn in try Int.fetchOne(conn, sql: "PRAGMA cache_size") }
        }
        let before = try cacheSize()

        XCTAssertGreaterThan(try store.incrementalVacuum(pagesPerStep: 64, deadline: future) ?? 0, 0)

        XCTAssertEqual(try cacheSize(), before)
        XCTAssertNotEqual(before, -EventStore.vacuumCacheKiB)
    }

    /// A vacuum step ejected by the write deadline runs again at half the size and
    /// the vacuum carries on; a quick step grows the next back to the full size.
    func testAVacuumStepThatRunsOutOfTimeIsRetriedSmaller() throws {
        var tried: [Int] = []
        var left = 3000
        var carry: Int?
        let freed = try EventStore.vacuumSteps(pagesPerStep: 2048, carry: &carry,
                                               until: .now + .seconds(3600)) { size in
            tried.append(size)
            if size > 600 && tried.count == 1 {
                throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
            }
            let step = min(size, left)
            left -= step
            return (step, left)
        }
        XCTAssertEqual(tried, [2048, 1024, 2048])
        XCTAssertEqual(freed, 3000)
        XCTAssertEqual(left, 0)
        XCTAssertEqual(carry, 2048)
    }

    /// A vacuum starts from the step size the last one ended on, not the full step.
    func testAVacuumStartsFromTheCarriedStep() throws {
        var tried: [Int] = []
        var left = 1000
        var carry: Int? = 256
        _ = try EventStore.vacuumSteps(pagesPerStep: 2048, carry: &carry, until: .now + .seconds(3600)) { size in
            tried.append(size)
            if tried.count == 1 {
                throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
            }
            let step = min(size, left)
            left -= step
            return (step, left)
        }
        XCTAssertEqual(tried.prefix(2), [256, 128])
        XCTAssertEqual(left, 0)
    }

    /// Out of pass time, an ejected step is not retried: the vacuum returns what it
    /// freed and carries the halved size to the next pass.
    func testAVacuumOutOfPassTimeStopsHalvingAndCarriesTheSmallerStep() throws {
        var tried: [Int] = []
        var carry: Int?
        let freed = try EventStore.vacuumSteps(pagesPerStep: 2048, carry: &carry, until: .now) { size in
            tried.append(size)
            throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
        }
        XCTAssertEqual(tried, [2048])
        XCTAssertEqual(freed, 0)
        XCTAssertEqual(carry, 1024)
    }

    /// At the minimum step the deadline error is thrown, after the steps that went through.
    func testAVacuumStepAtTheMinimumThatRunsOutOfTimeThrows() {
        var tried: [Int] = []
        var carry: Int?
        XCTAssertThrowsError(try EventStore.vacuumSteps(pagesPerStep: 256, carry: &carry,
                                                               until: .now + .seconds(3600)) { size in
            tried.append(size)
            if tried.count == 1 { return (size, 10_000) }
            throw BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 60_000)
        }) { error in
            XCTAssertEqual(error as? BoundedDatabaseError, .deadlineExceeded(lane: "write", elapsedMs: 60_000))
        }
        XCTAssertEqual(tried, [256, 256, 128, 64, 32, EventStore.minimumVacuumStep])
    }

    /// A step that went through slowly halves the next before the deadline can eject
    /// it; a quick one doubles it; one in between keeps its size.
    func testTheNextVacuumStepFollowsTheTimeTheLastOneTook() {
        let ceiling = EventStore.trimGrowthCeiling
        XCTAssertEqual(EventStore.nextVacuumStep(512, upTo: 2048, minimum: 16, took: ceiling * 3), 256)
        XCTAssertEqual(EventStore.nextVacuumStep(16, upTo: 2048, minimum: 16, took: ceiling * 3), 16)
        XCTAssertEqual(EventStore.nextVacuumStep(512, upTo: 2048, minimum: 16, took: ceiling / 2), 1024)
        XCTAssertEqual(EventStore.nextVacuumStep(512, upTo: 2048, minimum: 16, took: ceiling * 3 / 2), 512)
        XCTAssertLessThan(ceiling * 2, EventStore.vacuumStepDeadline)
    }

    /// The trim's ended-before test reads sessions through `sessions_last_seen`, and
    /// the untimed stages keep sessions outside, never scanning a whole table.
    func testTheTrimFindsEndedSessionsThroughTheirIndex() throws {
        let store = try makeStore()
        let plan = { (sql: String) in
            try store.pool.read { conn in
                try Row.fetchAll(conn, sql: "EXPLAIN QUERY PLAN " + sql, arguments: [0, 25])
                    .map { row -> String in row["detail"] }.joined(separator: " | ")
            }
        }
        let plans = try ["events", "messages", "turns"].map { try plan(EventStore.untimedRows(of: $0)) }
            + [try plan("SELECT 1 FROM sessions s WHERE \(EventStore.endedBefore) LIMIT ?")]
        for found in plans {
            XCTAssertTrue(found.contains("sessions_last_seen"), found)
            XCTAssertFalse(found.contains("SCAN"), found)
        }
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

    /// A status read answers while long maintenance reads hold every reader.
    func testFileStatsAndMetaValueAnswerWhileEveryReaderIsHeld() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.events = [event("e", session: "s", at: 1)]
        try store.write(batch, provider: "mock")
        try store.setMetaValue("42", forKey: "probe")

        let release = DispatchSemaphore(value: 0)
        let holding = DispatchGroup()
        let finished = DispatchGroup()
        for _ in 0..<3 {
            holding.enter()
            finished.enter()
            DispatchQueue.global().async {
                _ = try? store.read { _ in holding.leave(); release.wait() }
                finished.leave()
            }
        }
        XCTAssertEqual(holding.wait(timeout: .now() + 10), .success, "every reader is held")
        let answered = expectation(description: "fileStats answers")
        DispatchQueue.global().async {
            XCTAssertGreaterThan((try? store.fileStats().pageCount) ?? 0, 0)
            XCTAssertEqual(try? store.metaValue(forKey: "probe"), "42")
            answered.fulfill()
        }
        wait(for: [answered], timeout: 5)
        for _ in 0..<3 { release.signal() }
        XCTAssertEqual(finished.wait(timeout: .now() + 10), .success)
    }

    func testSQLiteFileStatsThrowsOnAMissingFileAndNeverCreatesIt() {
        let missing = path("missing.db")
        XCTAssertThrowsError(try SQLiteFileStats.stats(path: missing))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing + "-wal"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing + "-shm"))
    }

    func testSQLiteFileStatsOnAClosedWALFileReadsTheHeaderAndCreatesNoSidecars() throws {
        let filePath = path("closed-wal.db")
        let expected: (pageSize: Int, pageCount: Int, freelist: Int, autoVacuum: Int)
        do {
            var configuration = Configuration()
            configuration.prepareDatabase { conn in
                if !conn.configuration.readonly { try conn.execute(sql: "PRAGMA auto_vacuum = INCREMENTAL") }
            }
            let pool = try DatabasePool(path: filePath, configuration: configuration)
            try pool.write { conn in
                try conn.execute(sql: "CREATE TABLE t(x TEXT)")
                for index in 0..<2000 {
                    try conn.execute(sql: "INSERT INTO t VALUES (?)",
                                     arguments: [String(repeating: "y", count: 200) + "\(index)"])
                }
            }
            try pool.write { conn in try conn.execute(sql: "DELETE FROM t WHERE rowid % 2 = 0") }
            try pool.writeWithoutTransaction { conn in
                _ = try Row.fetchOne(conn, sql: "PRAGMA wal_checkpoint(TRUNCATE)")
            }
            expected = try pool.read { conn in
                (try Int.fetchOne(conn, sql: "PRAGMA page_size") ?? 0,
                 try Int.fetchOne(conn, sql: "PRAGMA page_count") ?? 0,
                 try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0,
                 try Int.fetchOne(conn, sql: "PRAGMA auto_vacuum") ?? 0)
            }
            XCTAssertEqual(try pool.read { try String.fetchOne($0, sql: "PRAGMA journal_mode") }, "wal")
            try pool.close()
        }
        // Apple's SQLite keeps the sidecars after a clean close; other builds delete
        // them. The WAL was checkpointed with TRUNCATE (empty), so removing them
        // leaves the state a non-persistent build's clean close leaves.
        let manager = FileManager.default
        let walSize = (try? manager.attributesOfItem(atPath: filePath + "-wal"))?[.size] as? NSNumber
        XCTAssertEqual(walSize?.int64Value ?? 0, 0)
        try? manager.removeItem(atPath: filePath + "-wal")
        try? manager.removeItem(atPath: filePath + "-shm")

        let stats = try SQLiteFileStats.stats(path: filePath)

        XCTAssertFalse(manager.fileExists(atPath: filePath + "-wal"))
        XCTAssertFalse(manager.fileExists(atPath: filePath + "-shm"))
        XCTAssertGreaterThan(expected.freelist, 0)
        XCTAssertEqual(stats.pageSize, expected.pageSize)
        XCTAssertEqual(stats.pageCount, expected.pageCount)
        XCTAssertEqual(stats.freelistCount, expected.freelist)
        XCTAssertEqual(stats.autoVacuum, 2)
        XCTAssertEqual(expected.autoVacuum, 2)
        let size = (try manager.attributesOfItem(atPath: filePath)[.size] as? NSNumber)?.int64Value
        XCTAssertEqual(stats.bytes, size)
    }

    func testSQLiteFileStatsRefusesAFileThatIsNotSQLite() throws {
        let filePath = path("not-sqlite.db")
        try Data(repeating: 0x41, count: 200).write(to: URL(fileURLWithPath: filePath))
        XCTAssertThrowsError(try SQLiteFileStats.stats(path: filePath)) { error in
            XCTAssertEqual(error as? SQLiteFileStatsError, .notSQLite(path: filePath))
        }
    }

    // MARK: - Fix round 1

    func testTrimKeepsAResumedSessionWithAStaleEndedAt() throws {
        let store = try makeStore()
        var ended = NormalizedBatch()
        ended.sessions = [SessionUpsert(sessionID: "resumed", asOf: date(5), status: "ended", endedAt: date(5))]
        try store.write(ended, provider: "mock")
        var resumed = NormalizedBatch()
        resumed.sessions = [SessionUpsert(sessionID: "resumed", asOf: date(500), status: "active")]
        try store.write(resumed, provider: "mock")

        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)

        XCTAssertEqual(result.sessions, 0)
        XCTAssertEqual(try sessionIDs(store), ["resumed"])
    }

    func testTrimAndVacuumAreRefusedDuringABulkLoad() throws {
        let store = try makeStore()
        var batch = NormalizedBatch()
        batch.events = [event("e", session: "s", at: 1)]
        try store.write(batch, provider: "mock")
        try store.beginBulkLoad()

        XCTAssertThrowsError(try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)) {
            XCTAssertEqual($0 as? EventStoreError, .bulkLoadInProgress)
        }
        XCTAssertThrowsError(try store.incrementalVacuum(deadline: future)) {
            XCTAssertEqual($0 as? EventStoreError, .bulkLoadInProgress)
        }
        XCTAssertEqual(try store.counts().events, 1)

        try store.endBulkLoad()
        XCTAssertEqual(try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future).events, 1)
    }

    func testTrimIsRefusedWhenACrashLeftTheBulkLoadFlag() throws {
        // The on-disk flag without this process's bulk window: what another process's
        // crashed replay leaves on a file this store already has open.
        let store = try makeStore()
        try store.pool.write { conn in
            try conn.execute(sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES('bulk_load', '1')")
        }
        XCTAssertThrowsError(try store.trim(olderThan: date(100).timeIntervalSince1970, deadline: future)) {
            XCTAssertEqual($0 as? EventStoreError, .bulkLoadInProgress)
        }
    }

    func testTrimDeletesOldMessagesOfEveryProvider() throws {
        let store = try makeStore()
        for provider in ["mock", "claude", "zeta"] {
            var batch = NormalizedBatch()
            batch.messages = (0..<7).map { message("\(provider)-\($0)", session: "s", at: Double($0 * 30)) }
            try store.write(batch, provider: provider)
        }

        // 0, 30, 60, 90 are older than 100 in each provider; batch 2 loops per provider.
        let result = try store.trim(olderThan: date(100).timeIntervalSince1970, batch: 2, deadline: future)

        XCTAssertEqual(result.messages, 12)
        XCTAssertTrue(result.finished)
        let left = try store.read { conn in
            try Row.fetchAll(
                conn, sql: "SELECT provider, COUNT(*) AS n, MIN(time) AS t FROM messages GROUP BY provider")
        }
        XCTAssertEqual(left.count, 3)
        for row in left {
            XCTAssertEqual(row["n"] as Int, 3)
            XCTAssertEqual(row["t"] as Double, date(120).timeIntervalSince1970)
        }
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
