import XCTest
import Foundation
import GRDB
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// `TrimService`: the rollup guard on the cutoff, the snapshot trim, the main
/// vacuum gate, and what a pass never touches.
final class TrimServiceTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    var store: EventStore!

    /// 2026-06-15T12:00:00Z.
    static let now = Date(timeIntervalSince1970: 1_781_524_800)
    private var future: Date { Date().addingTimeInterval(600) }

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        tmpPath = opened.path
        store = try EventStore(path: directory.appendingPathComponent(EventStore.fileName).path)
    }

    override func tearDownWithError() throws {
        store = nil
        database = nil
        TestDaemonDatabase.remove(path: tmpPath)
    }

    private var directory: URL { URL(fileURLWithPath: tmpPath).deletingLastPathComponent() }

    // MARK: - Helpers

    private static func day(_ daysAgo: Int) -> String {
        UTCDay.string(from: now.addingTimeInterval(-Double(daysAgo) * 86400))
    }

    private static func midnight(_ daysAgo: Int) -> Double {
        Double(UTCTimestamp.epochSeconds("\(day(daysAgo))T00:00:00Z")!)
    }

    private func service(
        historyDays: Int = 7, covered: String?, eventStore: EventStore?? = .none,
        snapshotsReadThrough: (@Sendable () -> Int?)? = nil,
        hold: TrimHold? = nil,
        holdFails: Bool = false,
        extra: [@Sendable (Double, Date) throws -> Int] = []
    ) -> TrimService {
        TrimService(
            database: database, eventStore: eventStore ?? store, historyDays: historyDays,
            coveredThroughDay: { covered }, snapshotsReadThrough: snapshotsReadThrough,
            hold: {
                if holdFails { throw HoldUnreadable() }
                return hold
            }, extraMainTrims: extra, now: { Self.now })
    }

    private struct HoldUnreadable: Error {}

    /// One event, turn and message for `session`, `daysAgo` before now (at noon).
    private func storeRows(_ session: String, daysAgo: Int, key: String? = nil) throws {
        let time = Self.now.addingTimeInterval(-Double(daysAgo) * 86400)
        let key = key ?? "\(session)-\(daysAgo)"
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "e-\(key)", sessionID: session, kind: .toolCall, providerType: "PreToolUse",
            time: time, rawRef: 1)]
        batch.turns = [TurnRow(dedupKey: "t-\(key)", sessionID: session, time: time, inputTokens: 1, rawRef: 2)]
        batch.messages = [MessageRow(
            dedupKey: "m-\(key)", uuid: "u-\(key)", sessionID: session, role: "user", time: time,
            text: "hi", rawRef: 3)]
        try store.write(batch, provider: ClaudeProvider.name)
    }

    private func count(_ table: String) throws -> Int {
        try store.read { conn in try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM \(table)") ?? 0 }
    }

    private func snapshot(_ timestamp: String, account: String?) throws {
        if let account {
            try database.execute(
                "INSERT INTO rate_limit_snapshots(timestamp, session_id, account_email) VALUES (?, 's', ?)",
                params: [timestamp, account])
        } else {
            try database.execute(
                "INSERT INTO rate_limit_snapshots(timestamp, session_id) VALUES (?, 's')",
                params: [timestamp])
        }
    }

    private func snapshotRows() throws -> [String] {
        var rows: [String] = []
        try database.query(
            "SELECT timestamp, COALESCE(NULLIF(account_email, ''), '-') FROM rate_limit_snapshots ORDER BY id"
        ) { row in rows.append("\(database.string(row, 0))|\(database.string(row, 1))") }
        return rows
    }

    // MARK: - Cutoff

    /// Review Focus 1: a fresh install has no rollup watermark yet.
    func testNoWatermarkDeletesNothingAndWaitsForRollups() throws {
        try storeRows("old", daysAgo: 100)
        try snapshot("\(Self.day(100))T00:00:00Z", account: "a@x")
        try snapshot("\(Self.day(99))T00:00:00Z", account: "a@x")

        let report = try service(covered: nil).run(deadline: future)

        XCTAssertEqual(report.waitingFor, "rollups")
        XCTAssertNil(report.cutoff)
        XCTAssertNil(report.error, "waiting for the rollups is not an error")
        XCTAssertTrue(report.finished)
        XCTAssertEqual([report.events, report.messages, report.turns, report.sessions, report.rateLimitSnapshots],
                       [0, 0, 0, 0, 0])
        XCTAssertEqual(try count("events"), 1)
        XCTAssertEqual(try count("turns"), 1)
        XCTAssertEqual(try count("messages"), 1)
        XCTAssertEqual(try snapshotRows().count, 2)
        XCTAssertEqual(TrimService.lastReport(database), report, "even a no-op pass stores its report")
    }

    func testCutoffIsTheWindowFlooredToMidnight() {
        let cutoff = TrimService.cutoff(now: Self.now, historyDays: 30, coveredThroughDay: Self.day(1))
        XCTAssertEqual(cutoff, Self.midnight(30))
    }

    func testCutoffNeverKeepsLessThanSevenDays() {
        XCTAssertEqual(TrimService.cutoff(now: Self.now, historyDays: 0, coveredThroughDay: Self.day(1)),
                       Self.midnight(7))
    }

    func testCutoffIsClampedToTheDayAfterTheWatermark() {
        // Covered through 20 days ago: day 19-ago is not frozen, so nothing from it goes.
        XCTAssertEqual(TrimService.cutoff(now: Self.now, historyDays: 7, coveredThroughDay: Self.day(20)),
                       Self.midnight(19))
        XCTAssertNil(TrimService.cutoff(now: Self.now, historyDays: 7, coveredThroughDay: "garbage"))
        XCTAssertNil(TrimService.cutoff(now: Self.now, historyDays: 7, coveredThroughDay: ""))
    }

    func testTrimDeletesOnlyRowsBeforeTheWatermarkDay() throws {
        try storeRows("s", daysAgo: 21)   // before the clamp: goes
        try storeRows("s", daysAgo: 15)   // older than the window, but not yet frozen: stays

        let report = try service(historyDays: 7, covered: Self.day(20)).run(deadline: future)

        XCTAssertEqual(report.cutoff, Self.midnight(19))
        XCTAssertEqual([report.events, report.messages, report.turns], [1, 1, 1])
        XCTAssertEqual(try count("events"), 1)
        XCTAssertEqual(try count("turns"), 1)
        XCTAssertEqual(try count("messages"), 1)
        XCTAssertTrue(report.finished)
        XCTAssertNil(report.error)
    }

    /// A hold that lowers the cutoff trims up to it and says why, in the report
    /// returned and the one stored; one that lowers nothing says nothing.
    func testAHoldThatLowersTheCutoffIsReportedAsWaitingFor() throws {
        try storeRows("s", daysAgo: 40)   // before the hold: goes
        try storeRows("s", daysAgo: 25)   // after the hold, inside the window's reach: stays

        let held = TrimHold(day: Self.day(30), reason: TrimService.waitingForBilling)
        let report = try service(covered: Self.day(1), hold: held).run(deadline: future)

        XCTAssertEqual(report.cutoff, Self.midnight(29))
        XCTAssertEqual(report.waitingFor, "billing")
        XCTAssertEqual(report.turns, 1)
        XCTAssertEqual(try count("turns"), 1)
        XCTAssertTrue(report.finished)
        XCTAssertEqual(TrimService.lastReport(database)?.waitingFor, "billing")

        // A hold later than the window holds nothing back.
        let loose = TrimHold(day: Self.day(2), reason: TrimService.waitingForBilling)
        let unheld = try service(covered: Self.day(1), hold: loose).run(deadline: future)
        XCTAssertEqual(unheld.cutoff, Self.midnight(7))
        XCTAssertNil(unheld.waitingFor)
    }

    /// The hold fails closed: one that cannot be read, or names no day, deletes
    /// nothing at all and reports the pass unfinished, "billing unreadable" (N3).
    func testAHoldThatCannotBeReadDeletesNothing() throws {
        try storeRows("s", daysAgo: 40)
        try snapshot("\(Self.day(40))T01:00:00Z", account: "a@x")
        try snapshot("\(Self.day(39))T01:00:00Z", account: "a@x")
        let extra: @Sendable (Double, Date) throws -> Int = { _, _ in
            XCTFail("no main-db trim runs while the hold is unreadable")
            return 0
        }

        for report in [
            try service(covered: Self.day(1), holdFails: true, extra: [extra]).run(deadline: future),
            try service(covered: Self.day(1), hold: TrimHold(day: "not a day", reason: "billing"))
                .run(deadline: future)
        ] {
            XCTAssertNil(report.cutoff)
            XCTAssertEqual(report.waitingFor, TrimService.waitingForBillingUnreadable)
            XCTAssertEqual(report.waitingFor, "billing unreadable")
            XCTAssertFalse(report.finished)
            XCTAssertEqual(report.turns, 0)
            XCTAssertEqual(report.rateLimitSnapshots, 0)
            XCTAssertEqual(TrimService.lastReport(database)?.waitingFor, "billing unreadable")
        }
        XCTAssertEqual(try count("turns"), 1)
        XCTAssertEqual(try count("events"), 1)
        XCTAssertEqual(try snapshotRows().count, 2)
    }

    // MARK: - Snapshots

    func testSnapshotTrimKeepsTheNewestRowPerAccount() throws {
        try snapshot("\(Self.day(40))T01:00:00Z", account: "a@x")
        try snapshot("\(Self.day(39))T01:00:00Z", account: "a@x")    // a@x's newest, still old: kept
        try snapshot("\(Self.day(40))T01:00:00Z", account: "b@x")
        try snapshot("\(Self.day(2))T01:00:00Z", account: "b@x")     // recent: kept
        try snapshot("\(Self.day(41))T01:00:00Z", account: nil)
        try snapshot("\(Self.day(40))T01:00:00Z", account: nil)      // the no-account newest: kept

        let report = try service(historyDays: 30, covered: Self.day(1)).run(deadline: future)

        XCTAssertEqual(report.rateLimitSnapshots, 3)
        XCTAssertEqual(try snapshotRows(), [
            "\(Self.day(39))T01:00:00Z|a@x",
            "\(Self.day(2))T01:00:00Z|b@x",
            "\(Self.day(40))T01:00:00Z|-"
        ])
    }

    func testSnapshotTrimNeverPassesTheReadCursor() throws {
        try snapshot("\(Self.day(50))T01:00:00Z", account: "a@x")   // id 1
        try snapshot("\(Self.day(49))T01:00:00Z", account: "a@x")   // id 2: not read yet
        try snapshot("\(Self.day(1))T01:00:00Z", account: "a@x")    // id 3

        var report = try service(covered: Self.day(1), snapshotsReadThrough: { 1 }).run(deadline: future)
        XCTAssertEqual(report.rateLimitSnapshots, 1)
        XCTAssertEqual(try snapshotRows().count, 2)

        report = try service(covered: Self.day(1), snapshotsReadThrough: { nil }).run(deadline: future)
        XCTAssertEqual(report.rateLimitSnapshots, 0, "no read cursor yet: no snapshot is deleted")
    }

    // MARK: - Sessions (Review Focus 2)

    func testTrimNeverDeletesAMainDatabaseSessionRow() throws {
        _ = try database.createSessionStubIfMissing(
            sessionId: "old", cwd: "/src/app", model: "m", startedAt: "2026-01-01T00:00:00Z",
            lastActivityAt: "2026-01-01T00:00:00Z", accountEmail: "a@x")
        try database.execute(
            "UPDATE sessions SET transcript_title = 'Title', status = 'ended' WHERE session_id = 'old'")
        let before = try database.read { conn in
            try Row.fetchOne(conn, sql: "SELECT * FROM sessions WHERE session_id = 'old'")
        }
        try storeRows("old", daysAgo: 160)

        let report = try service(covered: Self.day(1)).run(deadline: future)

        XCTAssertEqual(report.events, 1)
        let after = try database.read { conn in
            try Row.fetchOne(conn, sql: "SELECT * FROM sessions WHERE session_id = 'old'")
        }
        XCTAssertNotNil(after)
        XCTAssertEqual(after, before, "the main sessions row is untouched, title and all")
    }

    // MARK: - events.db states

    /// Review Focus 5: a store created without INCREMENTAL auto_vacuum.
    func testStoreWithoutIncrementalAutoVacuumStillTrimsAndSaysWhy() throws {
        let legacyPath = directory.appendingPathComponent("legacy-events.db").path
        do {
            let queue = try DatabaseQueue(path: legacyPath)
            try queue.writeWithoutTransaction { conn in
                try conn.execute(sql: "PRAGMA auto_vacuum = NONE")
                try conn.execute(sql: "CREATE TABLE legacy(x)")
            }
        }
        store = try EventStore(path: legacyPath)
        XCTAssertEqual(try store.fileStats().autoVacuum, 0)
        try storeRows("s", daysAgo: 60)

        let report = try service(covered: Self.day(1)).run(deadline: future)

        XCTAssertEqual(report.events, 1)
        XCTAssertEqual(try count("events"), 0)
        XCTAssertEqual(report.vacuum, "unavailable (auto_vacuum=none)")
        XCTAssertNil(report.error)
        XCTAssertTrue(report.finished)
    }

    func testIncrementalStoreIsVacuumed() throws {
        try storeRows("s", daysAgo: 60)
        let report = try service(covered: Self.day(1)).run(deadline: future)
        XCTAssertTrue(report.vacuum.hasPrefix("incremental"), report.vacuum)
    }

    func testNoEventStoreSkipsEventsDbAndSaysSo() throws {
        try snapshot("\(Self.day(50))T01:00:00Z", account: "a@x")
        try snapshot("\(Self.day(49))T01:00:00Z", account: "a@x")

        let report = try service(covered: Self.day(1), eventStore: .some(nil)).run(deadline: future)

        XCTAssertEqual(report.waitingFor, "events.db unavailable")
        XCTAssertEqual(report.rateLimitSnapshots, 1, "the main-db trims still run")
        XCTAssertNil(report.error)
    }

    func testBulkLoadSkipsEventsDbWithoutAnError() throws {
        try storeRows("s", daysAgo: 60)
        try store.beginBulkLoad()

        let report = try service(covered: Self.day(1)).run(deadline: future)

        XCTAssertEqual(report.waitingFor, "skipped: bulk load")
        XCTAssertNil(report.error)
        XCTAssertFalse(report.finished, "rows are still due: the caller retries soon, not a day later")
        XCTAssertEqual(report.vacuum, "skipped")
        try store.endBulkLoad()
        XCTAssertEqual(try count("events"), 1)
    }

    func testPassedDeadlineReportsUnfinished() throws {
        for index in 0..<3 { try storeRows("s\(index)", daysAgo: 60) }

        let report = try service(covered: Self.day(1)).run(deadline: .distantPast)

        XCTAssertFalse(report.finished, "a pass stopped by its deadline asks for a rerun")
        XCTAssertEqual(report.vacuum, "skipped")
    }

    func testExtraMainTrimsGetTheCutoff() throws {
        let seen = OSAllocatedUnfairLockBox()
        let report = try service(covered: Self.day(1), extra: [{ cutoff, _ in seen.set(cutoff); return 4 }])
            .run(deadline: future)
        XCTAssertEqual(seen.value, report.cutoff)
    }

    func testAFailingExtraTrimIsReportedAndTheRestStillRuns() throws {
        struct Boom: Error {}
        try storeRows("s", daysAgo: 60)
        let report = try service(covered: Self.day(1), extra: [{ _, _ in throw Boom() }]).run(deadline: future)
        XCTAssertNotNil(report.error)
        XCTAssertFalse(report.finished, "a failed stage asks for a rerun")
        XCTAssertEqual(report.events, 1)
    }

    /// A batch that fails after earlier ones committed: the report carries what
    /// was deleted, names the failure and asks for a rerun.
    func testAnEventsDbFailureReportsThePartialCounts() throws {
        for index in 0..<3 { try storeRows("s\(index)", daysAgo: 60) }
        try store.pool.write { conn in
            try conn.execute(sql: """
                CREATE TRIGGER refuse_message_delete BEFORE DELETE ON messages
                BEGIN SELECT RAISE(ABORT, 'refused'); END
                """)
        }

        let report = try service(covered: Self.day(1)).run(deadline: future)

        XCTAssertEqual(report.events, 3, "the events batch committed before the messages batch failed")
        XCTAssertEqual(report.messages, 0)
        XCTAssertEqual(report.turns, 0)
        XCTAssertEqual(try count("events"), 0)
        XCTAssertEqual(try count("messages"), 3)
        XCTAssertEqual(try count("turns"), 3)
        XCTAssertTrue(report.error?.hasPrefix("events.db:") == true, report.error ?? "no error")
        XCTAssertFalse(report.finished)
        XCTAssertEqual(report.vacuum, "skipped", "nothing is vacuumed after a failed stage")
        XCTAssertEqual(TrimService.lastReport(database), report, "the partial report is stored")
    }

    // MARK: - Main vacuum gate

    func testMainVacuumGateMatrix() {
        let now = Self.now
        let day: Double = 86400
        let recent = now.timeIntervalSince1970 - 6 * day
        let old = now.timeIntervalSince1970 - 7 * day
        let small: Int64 = 100 << 20
        let big: Int64 = 1 << 30

        func gate(_ bytes: Int64, _ pages: Int, _ free: Int, _ last: Double?) -> Bool {
            TrimService.shouldVacuumMain(
                bytes: bytes, pageCount: pages, freelistCount: free, lastVacuum: last, now: now)
        }
        // All three conditions hold.
        XCTAssertTrue(gate(small, 100, 26, nil))
        XCTAssertTrue(gate(small, 100, 26, old))
        // Size: 1 GiB and over never.
        XCTAssertFalse(gate(big, 100, 90, nil))
        XCTAssertFalse(gate(69 << 30, 100, 90, nil))
        // Freelist: more than 25 % only.
        XCTAssertFalse(gate(small, 100, 25, nil))
        XCTAssertFalse(gate(small, 0, 0, nil))
        // Seven-day gate.
        XCTAssertFalse(gate(small, 100, 90, recent))
    }

    func testMainVacuumRunsUnderTheGateAndRecordsWhen() throws {
        // Fill then empty a table so the main file has a large freelist.
        try database.execute("CREATE TABLE filler (x BLOB)")
        for _ in 0..<200 {
            try database.execute("INSERT INTO filler(x) VALUES (zeroblob(8192))")
        }
        try database.execute("DELETE FROM filler")

        let report = try service(covered: Self.day(1)).run(deadline: future)

        XCTAssertTrue(report.vacuum.contains("full main"), report.vacuum)
        XCTAssertEqual(try database.setting(for: TrimService.lastMainVacuumKey).flatMap(Double.init),
                       Self.now.timeIntervalSince1970)

        // Within seven days the next pass leaves it alone.
        for _ in 0..<200 {
            try database.execute("INSERT INTO filler(x) VALUES (zeroblob(8192))")
        }
        try database.execute("DELETE FROM filler")
        let second = try service(covered: Self.day(1)).run(deadline: future)
        XCTAssertFalse(second.vacuum.contains("full main"), second.vacuum)
    }
}

/// A Sendable box a test closure records into.
private final class OSAllocatedUnfairLockBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Double?
    func set(_ value: Double) { lock.withLock { stored = value } }
    var value: Double? { lock.withLock { stored } }
}
