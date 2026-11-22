import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import os
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The daemon's storage trim: `StorageController`'s one-pass lock, `TrimTask`'s
/// results, and full passes over a real main database and `events.db`
/// (Review Focus 1, 2, 4 and 5).
final class TrimTaskTests: XCTestCase {

    private var tmpDir: URL!
    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("trim-task-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        tmpPath = tmpDir.appendingPathComponent("session.db").path
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Helpers

    private static let finishedReport = TrimReport(startedAt: 1, finishedAt: 2)

    private func execute(_ task: TrimTask) async throws -> SessionTaskResult {
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        return try await task.execute(context: ctx)
    }

    /// A controller whose pass blocks until `release` is signalled, and a
    /// running first request, returned once that pass is under way.
    private func blockedController(
        release: DispatchSemaphore, startedAt: Double = 1_000
    ) async throws -> (StorageController, Task<TrimNowResult, Never>) {
        let controller = StorageController(
            pass: { _ in
                release.wait()
                return Self.finishedReport
            },
            now: { Date(timeIntervalSince1970: startedAt) })
        let first = Task { await controller.trimNow() }
        let giveUp = Date().addingTimeInterval(10)
        while controller.runningSince == nil {
            guard Date() < giveUp else { throw XCTSkip("the first pass never started") }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        return (controller, first)
    }

    private func iso(daysAgo: Double) -> String {
        Date().addingTimeInterval(-daysAgo * 86400)
            .formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    private func setWatermarks(_ day: String) throws {
        try database.setRollupFinalizedThrough(day)
        try database.setSetting(DaemonDatabase.usageSummaryFinalizedKey, day)
    }

    /// Row counts of one `events.db` table, read on a connection of its own.
    private func count(_ table: String, in harness: ClaudePipelineTestHarness) throws -> Int {
        let queue = try DatabaseQueue(path: harness.directory.appendingPathComponent(EventStore.fileName).path)
        defer { try? queue.close() }
        return try queue.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM \(table)") ?? 0 }
    }

    /// Every column of every row of a main-db table, in a stable order.
    private func dump(_ sql: String, params: [any Sendable] = []) throws -> [String] {
        var out: [String] = []
        try database.query(sql, params: params) { row in
            out.append(row.databaseValues.map(\.description).joined(separator: "|"))
        }
        return out
    }

    private func pass(
        _ harness: ClaudePipelineTestHarness?, capturesWaiting: @escaping @Sendable () -> Bool = { false }
    ) -> TrimReport {
        StorageController.runPass(
            database: database, eventStore: harness?.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: Date.init,
            capturesWaiting: capturesWaiting)
    }

    private func insertSummary(sessionId: String, day: String) throws {
        try database.execute("""
            INSERT INTO session_summary(
                provider, session_id, day, segment_start, project, account, first_time, last_time,
                turn_count, event_count, input_tokens, output_tokens,
                cache_read_tokens, cache_write_tokens, cost_usd, updated_at)
            VALUES (?, ?, ?, 0, 'app', 'a@x', 0, 0, 1, 0, 10, 20, 0, 0, 0.5, 0)
            """, params: [ClaudeProvider.name, sessionId, day])
    }

    /// Marks every session as derived by billing, as `BillingTask` does within
    /// minutes: until then the trim holds back before the session's start.
    private func markAllBilled() throws {
        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")
    }

    /// A session stub last active `daysAgo` days ago, with `status`.
    private func stub(_ id: String, daysAgo: Double, status: String = "ended") throws {
        let stamp = iso(daysAgo: daysAgo)
        try database.createSessionStubIfMissing(
            sessionId: id, cwd: "/tmp", model: "", startedAt: stamp, lastActivityAt: stamp,
            accountEmail: "a@x", authMethod: "unknown")
        try database.execute("UPDATE sessions SET status = ? WHERE session_id = ?", params: [status, id])
    }

    /// The sessions left, in SQL literal form.
    private func sessionIds() throws -> [String] {
        try dump("SELECT session_id FROM sessions ORDER BY 1")
    }

    /// A rate-limit snapshot whose 7-day reset is a day from now, so the
    /// usage summary can finalize every earlier day.
    private func recordReset() throws {
        try database.execute(
            "INSERT INTO rate_limit_snapshots(timestamp, session_id, seven_day_resets_at) VALUES (?, ?, ?)",
            params: [iso(daysAgo: 0), "quota", Int(Date().timeIntervalSince1970) + 86400])
    }

    private func runRollupUntilSettled() async throws {
        let task = RollupTask(database: database, finalizeAfterDays: 2)
        for _ in 0..<20 {
            let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
            if try await task.execute(context: ctx).nextRunSeconds == nil { return }
        }
        XCTFail("the rollup never settled")
    }

    // MARK: - Schedule

    func testScheduleIsAlwaysOnAndOutlastsAPass() {
        let task = TrimTask(storage: StorageController(pass: { _ in Self.finishedReport }))
        XCTAssertEqual(task.name, "storage-trim")
        XCTAssertTrue(task.schedule.enabled)
        XCTAssertGreaterThan(task.schedule.timeout, StorageController.passSeconds)
    }

    func testAnUnfinishedPassRerunsImmediately() async throws {
        let unfinished = TrimReport(startedAt: 1, finishedAt: 2, finished: false)
        let task = TrimTask(storage: StorageController(pass: { _ in unfinished }))
        let result = try await execute(task)
        XCTAssertEqual(result.nextRunSeconds, 0)
    }

    /// A pending backfill trims after each slice, so the scheduled pass stands
    /// back rather than run on top of it; failing slices start no trim, so then
    /// it does not.
    func testTheScheduledPassStandsBackWhileAHealthyBackfillTrims() {
        XCTAssertFalse(TrimTask.defersToBackfill(nil))
        XCTAssertTrue(TrimTask.defersToBackfill(
            HistoryBackfillDTO(targetRawID: 10, lastRawID: 5, running: true)))
        XCTAssertFalse(TrimTask.defersToBackfill(
            HistoryBackfillDTO(targetRawID: 10, lastRawID: 5, running: false, lastError: "boom")))
        // Checked back soon: a finished backfill leaves this pass a backlog.
        XCTAssertLessThanOrEqual(TrimTask.backfillCheckSeconds, TrimTask.retrySeconds)
    }

    /// While a backfill is pending (its slice failed, so this pass ran), a pass
    /// that ran out of time waits instead of rerunning on top of the retry.
    func testAnUnfinishedPassWaitsWhileABackfillIsPending() {
        let failing = HistoryBackfillDTO(targetRawID: 10, lastRawID: 5, running: false, lastError: "boom")
        XCTAssertEqual(TrimTask.paced(.rerunImmediately, backfill: failing).nextRunSeconds, TrimTask.retrySeconds)
        XCTAssertEqual(TrimTask.paced(.rerunImmediately, backfill: nil).nextRunSeconds, 0)
    }

    /// While a backfill is pending, a finished pass (or a failure's longer
    /// back-off) checks back within ``backfillCheckSeconds``, not a day later:
    /// the backfill's end leaves a backlog, and the reaper waits on it.
    func testAnyPassChecksBackSoonWhileABackfillIsPending() {
        let failing = HistoryBackfillDTO(targetRawID: 10, lastRawID: 5, running: false, lastError: "boom")
        let check = TrimTask.backfillCheckSeconds
        XCTAssertEqual(TrimTask.paced(.empty, backfill: failing).nextRunSeconds, check)
        let paced = TrimTask.paced(SessionTaskResult(nextRunSeconds: 86400), backfill: failing)
        XCTAssertEqual(paced.nextRunSeconds, check)
        XCTAssertEqual(TrimTask.paced(SessionTaskResult(nextRunSeconds: 60), backfill: failing).nextRunSeconds, 60)
        XCTAssertNil(TrimTask.paced(.empty, backfill: nil).nextRunSeconds)
        XCTAssertEqual(TrimTask.paced(SessionTaskResult(nextRunSeconds: 86400), backfill: nil).nextRunSeconds, 86400)
    }

    func testAFinishedPassWaitsForTheNextInterval() async throws {
        let task = TrimTask(storage: StorageController(pass: { _ in Self.finishedReport }))
        let result = try await execute(task)
        XCTAssertNil(result.nextRunSeconds)
    }

    /// A finished pass whose vacuum ran out of time, with much of events.db
    /// still free pages, comes back in 600 s to keep vacuuming, not tomorrow
    /// and not in a tight loop; once the free pages are gone it waits a day.
    func testAPendingVacuumComesBackInTenMinutes() async throws {
        let pending = TrimReport(startedAt: 1, finishedAt: 2, vacuum: TrimService.vacuumIncremental,
                                 vacuumPending: true)
        XCTAssertEqual(TrimTask.result(for: pending).nextRunSeconds, TrimTask.retrySeconds)
        let unfinished = TrimReport(startedAt: 1, finishedAt: 2, finished: false, vacuumPending: true)
        XCTAssertEqual(TrimTask.result(for: unfinished).nextRunSeconds, 0, "rows first")
        XCTAssertNil(TrimTask.result(for: Self.finishedReport).nextRunSeconds)

        let task = TrimTask(storage: StorageController(pass: { _ in pending }))
        let result = try await execute(task)
        XCTAssertEqual(result.nextRunSeconds, TrimTask.retrySeconds)
    }

    /// A failed stage or a bulk load retries soon, not tomorrow and not in a
    /// tight loop.
    func testAFailedOrBulkLoadPassRetriesAfterAShortWait() {
        let failed = TrimReport(startedAt: 1, finishedAt: 2, finished: false, error: "events.db: refused")
        XCTAssertEqual(TrimTask.result(for: failed).nextRunSeconds, TrimTask.retrySeconds)
        let bulk = TrimReport(
            startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForBulkLoad, finished: false)
        XCTAssertEqual(TrimTask.result(for: bulk).nextRunSeconds, TrimTask.retrySeconds)
        let outOfTime = TrimReport(startedAt: 1, finishedAt: 2, finished: false)
        XCTAssertEqual(TrimTask.result(for: outOfTime).nextRunSeconds, 0)
        XCTAssertNil(TrimTask.result(for: Self.finishedReport).nextRunSeconds)
    }

    /// Ruling T3-3.2: failures in a row back off 600 s, doubling, capped at 6 h;
    /// a bulk load never backs off.
    func testRepeatedFailuresBackOffDoublingUpToSixHours() {
        let failed = TrimReport(startedAt: 1, finishedAt: 2, finished: false, error: "events.db: refused")
        let waits = (1...9).map { TrimTask.result(for: failed, consecutiveFailures: $0).nextRunSeconds }
        XCTAssertEqual(waits, [600, 1_200, 2_400, 4_800, 9_600, 19_200, 21_600, 21_600, 21_600])
        XCTAssertEqual(TrimTask.failureRetrySeconds(10_000), TrimTask.maxRetrySeconds)
        let bulk = TrimReport(
            startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForBulkLoad, finished: false)
        XCTAssertEqual(TrimTask.result(for: bulk, consecutiveFailures: 5).nextRunSeconds, TrimTask.retrySeconds)
    }

    /// A pass billing held back retries in 600 s, not the daily interval, when
    /// it finished (trimmed up to the held day) or its hold could not be read
    /// (unfinished, nothing deleted, "billing unreadable": never a tight loop)
    /// (B-4, N3). A held pass that ran out of time continues at once (R3).
    func testABillingHoldRetriesInTenMinutes() async throws {
        let held = TrimReport(startedAt: 1, finishedAt: 2, cutoff: 1, waitingFor: TrimService.waitingForBilling)
        XCTAssertTrue(held.finished)
        XCTAssertEqual(TrimTask.result(for: held).nextRunSeconds, TrimTask.retrySeconds)
        let unreadable = TrimReport(
            startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForBillingUnreadable, finished: false)
        XCTAssertEqual(TrimTask.result(for: unreadable).nextRunSeconds, TrimTask.retrySeconds)
        let heldOutOfTime = TrimReport(
            startedAt: 1, finishedAt: 2, cutoff: 1, waitingFor: TrimService.waitingForBilling, finished: false)
        XCTAssertEqual(TrimTask.result(for: heldOutOfTime).nextRunSeconds, 0, "continues from its cutoff")
        XCTAssertEqual(StorageController.failuresAfter(unreadable, previous: 3), 0)
        XCTAssertNil(StorageController.reapCutoff(unreadable))
        XCTAssertNil(StorageController.reapCutoff(heldOutOfTime))
        let resetWait = TrimReport(
            startedAt: 1, finishedAt: 2, cutoff: 1, waitingFor: StorageController.waitingForResetInstants)
        XCTAssertEqual(StorageController.reapCutoff(resetWait), 1, "the covered cutoff is safe to reap at")
        let waitingForRollups = TrimReport(startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForRollups)
        XCTAssertNil(TrimTask.result(for: waitingForRollups).nextRunSeconds)
        let rollups = TrimReport(startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForRollups)
        let failedRecount = StorageController.noting(.failed("disk I/O error"), in: rollups)
        XCTAssertEqual(failedRecount.waitingFor, StorageController.waitingForLateTurns)
        XCTAssertEqual(failedRecount.error, "late-turn recount: disk I/O error")
        XCTAssertFalse(failedRecount.finished)
        XCTAssertEqual(StorageController.failuresAfter(failedRecount, previous: 2), 3, "a failed recount backs off")
        XCTAssertEqual(StorageController.noting(.caughtUp, in: rollups), rollups)
        let billing = TrimReport(startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForBilling)
        XCTAssertEqual(StorageController.noting(.behind, in: billing).waitingFor, TrimService.waitingForBilling,
                       "a hold the pass reported keeps its own reason")

        let task = TrimTask(storage: StorageController(pass: { _ in held }))
        let result = try await execute(task)
        XCTAssertEqual(result.nextRunSeconds, 600)
    }

    /// A bulk-load skip neither grows nor resets the failures in a row, so a
    /// failing trim keeps backing off across one (B-5).
    func testABulkLoadSkipLeavesTheFailureCountAsItWas() async throws {
        let failed = TrimReport(startedAt: 1, finishedAt: 2, finished: false, error: "events.db: refused")
        let bulk = TrimReport(
            startedAt: 1, finishedAt: 2, waitingFor: TrimService.waitingForBulkLoad, finished: false)
        let next = OSAllocatedUnfairLock(initialState: [failed, failed, bulk, failed, Self.finishedReport])
        let controller = StorageController(pass: { _ in next.withLock { $0.removeFirst() } })
        let task = TrimTask(storage: controller)

        var waits: [TimeInterval?] = []
        var counts: [Int] = []
        for _ in 0..<5 {
            waits.append(try await execute(task).nextRunSeconds)
            counts.append(controller.consecutiveFailures)
        }
        XCTAssertEqual(counts, [1, 2, 2, 3, 0])
        XCTAssertEqual(waits, [600, 1_200, 600, 2_400, nil])
        XCTAssertEqual(StorageController.failuresAfter(bulk, previous: 4), 4)
        XCTAssertEqual(StorageController.failuresAfter(failed, previous: 4), 5)
        XCTAssertEqual(StorageController.failuresAfter(Self.finishedReport, previous: 4), 0)
    }

    /// The controller counts failed passes in a row and a clean one resets it,
    /// so the scheduled task's wait grows and then returns to normal.
    func testTheScheduledTaskBacksOffOnFailuresAndResetsOnSuccess() async throws {
        let failed = TrimReport(startedAt: 1, finishedAt: 2, finished: false, error: "events.db: refused")
        let fail = OSAllocatedUnfairLock(initialState: true)
        let controller = StorageController(pass: { _ in fail.withLock { $0 } ? failed : Self.finishedReport })
        let task = TrimTask(storage: controller)

        var waits: [TimeInterval?] = []
        for _ in 0..<3 { waits.append(try await execute(task).nextRunSeconds) }
        XCTAssertEqual(waits, [600, 1_200, 2_400])
        XCTAssertEqual(controller.consecutiveFailures, 3)

        fail.withLock { $0 = false }
        let afterSuccess = try await execute(task).nextRunSeconds
        XCTAssertNil(afterSuccess)
        XCTAssertEqual(controller.consecutiveFailures, 0)

        fail.withLock { $0 = true }
        let restarted = try await execute(task).nextRunSeconds
        XCTAssertEqual(restarted, 600, "the backoff starts over after a success")
    }

    // MARK: - Review Focus 4: one pass at a time

    func testTrimNowDuringARunningPassDoesNotStartASecond() async throws {
        let release = DispatchSemaphore(value: 0)
        let (controller, first) = try await blockedController(release: release, startedAt: 1_000)
        XCTAssertEqual(controller.runningSince, 1_000)

        let second = await controller.trimNow()
        XCTAssertEqual(second, .alreadyRunning(startedAt: 1_000))

        release.signal()
        let firstResult = await first.value
        XCTAssertEqual(firstResult, .started(Self.finishedReport))
        XCTAssertNil(controller.runningSince, "the lock is released when the pass ends")

        // A later request runs a pass of its own.
        release.signal()
        let third = await controller.trimNow()
        XCTAssertEqual(third, .started(Self.finishedReport))
    }

    func testConcurrentRequestsStartExactlyOnePass() async throws {
        let release = DispatchSemaphore(value: 0)
        let passes = OSAllocatedCounter()
        let controller = StorageController(pass: { _ in
            passes.increment()
            // Bounded, so a second pass (the failure) can never hang the suite.
            _ = release.wait(timeout: .now() + 10)
            return Self.finishedReport
        })
        async let one = controller.trimNow()
        async let two = controller.trimNow()
        let giveUp = Date().addingTimeInterval(10)
        while controller.runningSince == nil, Date() < giveUp {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        // Give the losing request time to arrive while the winner holds the lock.
        try await Task.sleep(nanoseconds: 300_000_000)
        release.signal()
        let results = await [one, two]
        let started = results.filter { if case .started = $0 { return true } else { return false } }
        XCTAssertEqual(started.count, 1)
        XCTAssertEqual(passes.value, 1)
    }

    func testTheScheduledTaskRetriesSoonWhileAPassRuns() async throws {
        let release = DispatchSemaphore(value: 0)
        let (controller, first) = try await blockedController(release: release)
        let result = try await execute(TrimTask(storage: controller))
        XCTAssertEqual(
            result.nextRunSeconds, TrimTask.retrySeconds,
            "the running pass may stop on its deadline, so the scheduled one comes back soon")
        release.signal()
        _ = await first.value
    }

    // MARK: - Review Focus 1: no watermark, nothing deleted

    func testWithNoWatermarkTheTrimDeletesNothingAndWaitsForRollups() async throws {
        try database.setSetting(StorageSettings.key, "7")
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: iso(daysAgo: 200))
        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 200), input: 5, output: 5)
        XCTAssertNil(try database.rollupFinalizedThrough())

        let report = pass(harness)
        XCTAssertEqual(report.waitingFor, TrimService.waitingForRollups)
        XCTAssertNil(report.cutoff)
        XCTAssertNil(report.error)
        XCTAssertEqual(report.events + report.messages + report.turns, 0)
        XCTAssertEqual(try count("events", in: harness), 1)
        XCTAssertEqual(try count("turns", in: harness), 1)

        // One watermark alone is still not enough.
        try database.setRollupFinalizedThrough(UTCDay.string(from: Date()))
        XCTAssertEqual(pass(harness).waitingFor, TrimService.waitingForRollups)
        XCTAssertEqual(try count("events", in: harness), 1)
    }

    func testWithNoEventStoreThePassSaysSoWithoutAnError() {
        let report = pass(nil)
        XCTAssertNil(report.error)
        XCTAssertNotNil(report.waitingFor)
    }

    /// A turn that lands on an old, finalized day after the rollup ran (an
    /// import, a history backfill slice) is summarised by the pass's own
    /// recount before the trim deletes it, so its day's stored totals grow
    /// and never fall.
    func testALateTurnOnAnOldDayIsSummarisedBeforeTheTrimDeletesIt() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        let oldDay = iso(daysAgo: 40)
        try harness.seedTurn(sessionId: "old", timestamp: oldDay, input: 1_000, output: 500, account: "a@x")
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: oldDay)
        try recordReset()
        try await runRollupUntilSettled()
        try markAllBilled()
        try database.setSetting(StorageSettings.key, "7")
        let turnsSQL = "SELECT COALESCE(SUM(turn_count), 0), COALESCE(SUM(input_tokens), 0) FROM session_summary"
        XCTAssertEqual(try dump(turnsSQL), ["1|1000"])

        // The late turn, on the same old day, before any rollup reads it.
        try harness.seedTurn(sessionId: "late", timestamp: oldDay, input: 30, output: 3, account: "a@x")
        try markAllBilled()

        let report = pass(harness)
        XCTAssertNil(report.error)
        XCTAssertNotNil(report.cutoff)
        XCTAssertEqual(report.turns, 2)
        XCTAssertEqual(try count("turns", in: harness), 0)
        XCTAssertEqual(try dump(turnsSQL), ["2|1030"], "the late turn was summarised before it was trimmed")

        // The next rollup keeps the day as stored, though events.db is empty.
        try await runRollupUntilSettled()
        XCTAssertEqual(try dump(turnsSQL), ["2|1030"])
    }

    /// While a history backfill is pending, a day where one session lost
    /// turns from events.db (not replayed yet) while another gained late ones
    /// keeps its stored rows, though the day as a whole holds more than is
    /// stored. (A trimmed day is never rebuilt at all, and with no backfill
    /// pending the day's totals decide: a turn can move between sessions.)
    func testASessionThatLostTurnsIsNotHiddenByOneThatGainedSome() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        let oldDay = iso(daysAgo: 40)
        for _ in 0..<2 {
            try harness.seedTurn(sessionId: "a", timestamp: oldDay, input: 100, output: 10, account: "a@x")
        }
        try harness.seedTurn(sessionId: "b", timestamp: oldDay, input: 100, output: 10, account: "a@x")
        try harness.seed(sessionId: "a", type: "PreToolUse", timestamp: oldDay)
        try harness.seed(sessionId: "b", type: "PreToolUse", timestamp: oldDay)
        try recordReset()
        try await runRollupUntilSettled()
        let perSession = "SELECT session_id, SUM(turn_count), SUM(input_tokens) FROM session_summary "
            + "GROUP BY session_id ORDER BY session_id"
        let stored = [#""a"|2|200"#, #""b"|1|100"#]
        XCTAssertEqual(try dump(perSession), stored)

        // Session a loses one turn; session b gains two late ones.
        let queue = try DatabaseQueue(path: harness.directory.appendingPathComponent(EventStore.fileName).path)
        try await queue.write { conn in
            try conn.execute(sql: """
                DELETE FROM turns WHERE id = (SELECT MIN(id) FROM turns WHERE session_id = 'a')
                """)
        }
        for _ in 0..<2 {
            try harness.seedTurn(sessionId: "b", timestamp: oldDay, input: 100, output: 10, account: "a@x")
        }
        try harness.store.setMetaValue("1000000", forKey: ClaudeArchiveReplay.backfillTargetKey)
        try await runRollupUntilSettled()
        XCTAssertEqual(try dump(perSession), stored, "session a's stored turns are not lowered")
    }

    /// A history window that cannot be read fails the pass rather than
    /// trimming to the default 30 days: nothing is deleted, the error shows.
    func testAnUnreadableHistoryWindowFailsThePassAndDeletesNothing() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 40), input: 5, output: 5)
        try setWatermarks(UTCDay.string(from: Date().addingTimeInterval(-2 * 86400)))
        try markAllBilled()
        try database.execute("DROP TABLE settings")

        let report = pass(harness)
        XCTAssertNotNil(report.error)
        XCTAssertFalse(report.finished)
        XCTAssertNil(report.cutoff)
        XCTAssertEqual(try count("turns", in: harness), 1)
        XCTAssertEqual(StorageSettings.historyDays(database), StorageHistoryWindow.defaultDays,
                       "the lenient read for display still answers")
    }

    /// While the recount is behind (more arrivals than one call reads, and
    /// the pass's time is up), the pass has no cutoff and deletes nothing.
    func testAPassWhoseRecountIsBehindDeletesNothing() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 40), input: 5, output: 5)
        try setWatermarks(UTCDay.string(from: Date().addingTimeInterval(-2 * 86400)))
        try markAllBilled()
        try database.setSetting(StorageSettings.key, "7")
        try database.setSetting(DaemonDatabase.usageSummaryTurnCursorKey, "0")
        // More arrivals than one recount call reads (20 chunks of 500).
        for index in 0..<10_001 {
            try harness.seedTurn(sessionId: "bulk", timestamp: iso(daysAgo: 1), dedupKey: "bulk-\(index)")
        }
        XCTAssertEqual(StorageController.lateTurnRecount(database, deadline: Date()), .behind)

        try database.setSetting(DaemonDatabase.usageSummaryTurnCursorKey, "0")
        let report = StorageController.runPass(
            database: database, eventStore: harness.store, deadline: Date(), now: Date.init)
        XCTAssertEqual(report.waitingFor, StorageController.waitingForLateTurns)
        XCTAssertNil(report.error, "a recount that is only behind is not a failure")
        XCTAssertEqual(TrimTask.result(for: report).nextRunSeconds, TrimTask.retrySeconds,
                       "the recount is retried soon, not a day later")
        XCTAssertNil(report.cutoff)
        XCTAssertEqual(try count("turns", in: harness), 10_002)
    }

    // MARK: - Review Focus 2 and 3: an old session keeps what it shows

    func testAnOldSessionKeepsItsRowAndSummaryAndIsNeverReaped() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        let started = iso(daysAgo: 40)
        try harness.seedTurn(sessionId: "old", timestamp: started, input: 1_000, output: 500, account: "a@x")
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: started)
        try database.execute("""
            UPDATE sessions SET transcript_title = 'Old work', summary = 'Did things', status = 'ended'
            WHERE session_id = 'old'
            """)
        // The summary and both watermarks come from the real rollup, not a
        // hand-written row.
        try recordReset()
        try await runRollupUntilSettled()
        let metrics = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        try database.upsertSessionMetrics(metrics, accountEmail: "a@x")
        try markAllBilled()
        try database.setSetting(StorageSettings.key, "7")

        let sessionSQL = "SELECT * FROM sessions WHERE session_id = 'old'"
        let sessionBefore = try dump(sessionSQL)
        let summaryBefore = try dump(
            "SELECT * FROM session_summary WHERE session_id = 'old' ORDER BY 1, 2, 3, 4")
        let burstsBefore = try dump("SELECT * FROM usage_bursts ORDER BY 1, 2, 3, 4")
        let metricsBefore = try dump("SELECT * FROM daily_metric ORDER BY 1, 2, 3")
        let sessionMetricsSQL = """
            SELECT total_input_tokens, total_output_tokens, total_cost_usd, turn_count, account_email
            FROM session_metrics WHERE session_id = 'old'
            """
        let sessionMetricsBefore = try dump(sessionMetricsSQL)
        XCTAssertEqual(sessionBefore.count, 1)
        XCTAssertFalse(summaryBefore.isEmpty, "the rollup summarised the session")
        XCTAssertEqual(sessionMetricsBefore.count, 1)
        XCTAssertTrue(sessionMetricsBefore[0].hasPrefix("1000|500|"), sessionMetricsBefore[0])

        let report = pass(harness)
        XCTAssertNil(report.error)
        XCTAssertNotNil(report.cutoff)
        XCTAssertEqual(report.events, 1)
        XCTAssertEqual(report.turns, 1)
        XCTAssertEqual(try count("events", in: harness), 0)
        XCTAssertEqual(try count("turns", in: harness), 0)

        XCTAssertEqual(try dump(sessionSQL), sessionBefore, "the main-db session row (project, cwd) is untouched")
        XCTAssertEqual(
            try dump("SELECT * FROM session_summary WHERE session_id = 'old' ORDER BY 1, 2, 3, 4"), summaryBefore)
        XCTAssertEqual(try dump("SELECT * FROM usage_bursts ORDER BY 1, 2, 3, 4"), burstsBefore)
        XCTAssertEqual(try dump("SELECT * FROM daily_metric ORDER BY 1, 2, 3"), metricsBefore)
        XCTAssertEqual(try dump(sessionMetricsSQL), sessionMetricsBefore, "tokens and cost are untouched")

        let listed = try database.fetchSessions(includeEventCount: false).first { $0.sessionId == "old" }
        XCTAssertNotNil(listed, "the session is still listed")
        XCTAssertEqual(listed?.transcriptTitle, "Old work")
        XCTAssertEqual(listed?.summary, "Did things")

        // A second pass (the reaper runs after every clean pass) still keeps it.
        _ = pass(harness)
        XCTAssertEqual(try dump(sessionSQL), sessionBefore)
    }

    /// Ruling T3-3.1: a trimmed session that resumes, with new turns that take
    /// its live total past the stored one, counts exactly the pre-trim totals
    /// plus the new turns: tokens, cost and turn count.
    func testAResumedTrimmedSessionsTotalsArePreTrimPlusNew() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seedTurn(
            sessionId: "old", timestamp: iso(daysAgo: 40), input: 1_000, output: 500, cacheRead: 300,
            cacheCreation: 40, account: "a@x")
        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 39), input: 7, output: 3, account: "a@x")
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: iso(daysAgo: 40))
        try recordReset()
        try await runRollupUntilSettled()
        let full = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        try database.upsertSessionMetrics(full, accountEmail: "a@x")
        try markAllBilled()
        try database.setSetting(StorageSettings.key, "7")

        let report = pass(harness)
        XCTAssertEqual(report.turns, 2, "\(report)")
        XCTAssertEqual(try count("turns", in: harness), 0)
        let trimmedOnly = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        XCTAssertEqual(trimmedOnly.totalInputTokens, full.totalInputTokens, "the baseline alone is the pre-trim total")
        XCTAssertEqual(trimmedOnly.turnCount, full.turnCount)
        XCTAssertEqual(trimmedOnly.totalCostUsd, full.totalCostUsd, accuracy: 1e-9)

        // The same new turns in a reference session price them on their own.
        for id in ["old", "ref"] {
            try harness.seedTurn(
                sessionId: id, timestamp: iso(daysAgo: 0), input: 2_000, output: 900, cacheRead: 50, account: "a@x")
            try harness.seedTurn(sessionId: id, timestamp: iso(daysAgo: 0), input: 11, output: 4, account: "a@x")
        }
        let new = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "ref", reads: harness.store))
        XCTAssertGreaterThan(new.totalInputTokens, full.totalInputTokens, "the live part alone outgrows the stored one")

        let resumed = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        try database.upsertSessionMetrics(resumed, accountEmail: "a@x")
        var stored: (input: Int, output: Int, cacheRead: Int, cost: Double, turns: Int) = (0, 0, 0, 0, 0)
        try database.query("""
            SELECT total_input_tokens, total_output_tokens, cache_read_tokens, total_cost_usd, turn_count
            FROM session_metrics WHERE session_id = 'old'
            """) { row in
            stored = (
                self.database.int(row, 0), self.database.int(row, 1), self.database.int(row, 2),
                self.database.double(row, 3), self.database.int(row, 4))
        }
        XCTAssertEqual(stored.input, full.totalInputTokens + new.totalInputTokens)
        XCTAssertEqual(stored.output, full.totalOutputTokens + new.totalOutputTokens)
        XCTAssertEqual(stored.cacheRead, full.cacheReadTokens + new.cacheReadTokens)
        XCTAssertEqual(stored.turns, full.turnCount + new.turnCount)
        XCTAssertEqual(stored.cost, full.totalCostUsd + new.totalCostUsd, accuracy: 1e-9)
    }

    /// Finding 1: a trimmed session that resumes recomputes its metrics from
    /// the turns left, a fraction of the whole; the stored totals must not fall.
    func testAResumedTrimmedSessionsTotalsNeverFall() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 40), input: 1_000, output: 500, account: "a@x")
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: iso(daysAgo: 40))
        try recordReset()
        try await runRollupUntilSettled()
        let full = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        try database.upsertSessionMetrics(full, accountEmail: "a@x")
        try markAllBilled()
        try database.setSetting(StorageSettings.key, "7")
        let totals = "SELECT total_input_tokens, total_output_tokens, total_cost_usd FROM session_metrics"
        let before = try dump(totals)

        let report = pass(harness)
        XCTAssertEqual(report.turns, 1, "\(report)")

        try harness.seedTurn(sessionId: "old", timestamp: iso(daysAgo: 0), input: 10, output: 5, account: "a@x")
        let partial = try XCTUnwrap(try database.sessionMetricsFromTurns(sessionId: "old", reads: harness.store))
        XCTAssertEqual(partial.totalInputTokens, 1_010, "the trimmed baseline plus the new turn")
        try database.upsertSessionMetrics(partial, accountEmail: "a@x")

        var input = 0, output = 0, cost = 0.0
        try database.query(totals) { row in
            input = self.database.int(row, 0)
            output = self.database.int(row, 1)
            cost = self.database.double(row, 2)
        }
        XCTAssertGreaterThanOrEqual(input, full.totalInputTokens, "\(before)")
        XCTAssertGreaterThanOrEqual(output, full.totalOutputTokens)
        XCTAssertGreaterThanOrEqual(cost, full.totalCostUsd)
    }

    // MARK: - The reaper

    /// Watermarks a day ago, a 7-day history: a pass with a real cutoff.
    private func readyForACleanPass() throws {
        try setWatermarks(UTCDay.string(from: Date().addingTimeInterval(-86400)))
        try database.setSetting(StorageSettings.key, "7")
        try markAllBilled()
    }

    func testTheReaperRemovesOnlyOldEmptyEndedSessionsWithNothingToKeep() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        for id in ["empty", "summarised", "metrics", "legacy"] {
            try stub(id, daysAgo: 40)
        }
        try stub("recent", daysAgo: 1)
        try stub("active", daysAgo: 40, status: "active")
        try insertSummary(sessionId: "summarised", day: UTCDay.string(from: Date().addingTimeInterval(-40 * 86400)))
        try database.execute("INSERT INTO session_metrics(session_id, total_input_tokens) VALUES ('metrics', 5)")
        try database.execute("""
            INSERT INTO transcript_turns(session_id, timestamp, kind, message_id)
            VALUES ('legacy', ?, 'assistant', 'm-legacy')
            """, params: [iso(daysAgo: 40)])
        try readyForACleanPass()

        let report = pass(harness)
        XCTAssertNotNil(report.cutoff)
        XCTAssertTrue(report.finished)
        XCTAssertEqual(
            try sessionIds(), ["\"active\"", "\"legacy\"", "\"metrics\"", "\"recent\"", "\"summarised\""],
            "values dump in SQL literal form")
    }

    func testWithNoWatermarkTheReaperRemovesNothing() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try stub("empty", daysAgo: 40)
        try database.setSetting(StorageSettings.key, "7")
        try markAllBilled()

        let report = pass(harness)
        XCTAssertNil(report.cutoff)
        XCTAssertEqual(try sessionIds(), ["\"empty\""])
    }

    func testWhileCapturesWaitTheReaperRemovesNothing() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try stub("empty", daysAgo: 40)
        try readyForACleanPass()

        _ = pass(harness, capturesWaiting: { true })
        XCTAssertEqual(try sessionIds(), ["\"empty\""])
        _ = pass(harness)
        XCTAssertEqual(try sessionIds(), [])
    }

    func testAnUndrainedCaptureCountsAsWaiting() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        XCTAssertFalse(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
        XCTAssertTrue(StorageController.capturesWaiting(pipeline: nil, legacySpool: nil))
        try harness.handles.capture(
            ClaudePipelineTestHarness.event("PreToolUse", sessionId: "s", timestamp: iso(daysAgo: 0)))
        XCTAssertTrue(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
        try harness.drain()
        XCTAssertFalse(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
    }

    /// N1: a capture the normalizer could not parse is quarantined for good (it
    /// can never become an events.db row), so it does not keep the reaper off;
    /// one quarantined for a reason a retry may fix still does.
    func testAnUnparseableQuarantineDoesNotKeepTheReaperOff() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        let spool = harness.handles.spool
        for sessionId in ["bad", "flaky"] {
            try harness.handles.capture(
                ClaudePipelineTestHarness.event("PreToolUse", sessionId: sessionId, timestamp: iso(daysAgo: 0)))
        }
        let ids = try spool.pendingBatch(limit: 2).map(\.id)
        XCTAssertEqual(ids.count, 2)
        try spool.quarantine(id: ids[0], reason: String(describing: ClaudeNormalizerError.unparseable("k")))
        XCTAssertTrue(
            StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil), "one still pending")

        try spool.quarantine(id: ids[1], reason: "SQLite error 5: database is locked")
        XCTAssertTrue(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
        try spool.deleteQuarantined(ids: [ids[1]])
        XCTAssertFalse(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
        XCTAssertEqual(try spool.quarantinedCount(), 1, "the unparseable record stays listed")
    }

    /// N2: a session billing waits for whose start is not a date fails the hold
    /// closed: the pass deletes nothing and says "billing unreadable".
    func testAMalformedStartOfASessionBillingWaitsForHoldsTheTrim() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try stub("good", daysAgo: 40)
        try stub("bad", daysAgo: 40)
        try harness.seed(sessionId: "good", type: "PreToolUse", timestamp: iso(daysAgo: 40))
        try readyForACleanPass()
        try database.execute("""
            UPDATE sessions SET billing_derived_at = '', started_at = 'not a date' WHERE session_id = 'bad'
            """)

        XCTAssertThrowsError(try StorageController.billingHoldDay(database)) { error in
            XCTAssertEqual(error as? StorageController.BillingHoldError, .unreadableStart(sessions: 1))
        }
        let report = pass(harness)
        XCTAssertEqual(report.waitingFor, TrimService.waitingForBillingUnreadable)
        XCTAssertNil(report.cutoff)
        XCTAssertFalse(report.finished)
        XCTAssertEqual(try count("events", in: harness), 1, "nothing deleted")
        XCTAssertEqual(try sessionIds(), ["\"bad\"", "\"good\""], "the reaper did not run")
        XCTAssertEqual(TrimTask.result(for: report).nextRunSeconds, TrimTask.retrySeconds)

        try markAllBilled()
        XCTAssertNil(try StorageController.billingHoldDay(database))
    }

    /// The hold is read off `idx_sessions_billing_pending`, never by walking
    /// every session: a full scan on a slow disk ran past the read deadline and
    /// left the pass "billing unreadable".
    func testTheBillingHoldIsReadOffThePendingIndex() throws {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + StorageController.billingHoldSQL) { row in
            plan.append(row["detail"] ?? "")
        }
        let text = plan.joined(separator: "\n")
        XCTAssertTrue(text.contains("USING INDEX idx_sessions_billing_pending"), text)
    }

    /// Observation 8 and ruling T3-3.3: a session billing has not derived holds
    /// the trim back to the day before it started, so its events are still there
    /// to derive, and the report says so as `waitingFor: "billing"`. The reaper
    /// still runs, below the held cutoff.
    func testASessionBillingHasNotDerivedHoldsTheCutoffBackAndSaysSo() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try stub("billed", daysAgo: 50)
        try markAllBilled()
        try stub("pending", daysAgo: 40)
        try harness.seed(sessionId: "pending", type: "PreToolUse", timestamp: iso(daysAgo: 40))
        let yesterday = UTCDay.string(from: Date().addingTimeInterval(-86400))
        try setWatermarks(yesterday)
        try database.setSetting(StorageSettings.key, "7")

        let pendingStart = UTCDay.string(from: Date().addingTimeInterval(-40 * 86400))
        let hold = try XCTUnwrap(try StorageController.billingHoldDay(database))
        XCTAssertLessThan(hold, pendingStart)
        XCTAssertEqual(StorageController.coveredThroughDay(database), yesterday, "the rollups alone")

        let held = pass(harness)
        XCTAssertNil(held.error)
        XCTAssertEqual(held.waitingFor, TrimService.waitingForBilling)
        let heldCutoff = try XCTUnwrap(held.cutoff)
        XCTAssertLessThanOrEqual(heldCutoff, Date().addingTimeInterval(-40 * 86400).timeIntervalSince1970)
        XCTAssertEqual(held.events, 0, "the pending session's events stay for billing")
        XCTAssertEqual(try count("events", in: harness), 1)
        XCTAssertEqual(TrimService.lastReport(database)?.waitingFor, TrimService.waitingForBilling)
        XCTAssertEqual(try sessionIds(), ["\"pending\""], "the reaper ran below the held cutoff")

        try markAllBilled()
        XCTAssertNil(try StorageController.billingHoldDay(database))
        let free = pass(harness)
        XCTAssertNil(free.waitingFor)
        XCTAssertEqual(free.events, 1)
    }

    // MARK: - A pending history backfill holds the trim behind its frontier

    /// A backfill delivers a day over several slices with a trim after each;
    /// a trim reaching a day it has not finished would leave that day's later
    /// turns out of the usage summary. The trim stops two days before the day
    /// the next unreplayed record was received, and says so.
    func testAPendingBackfillHoldsTheTrimBehindItsFrontier() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seed(sessionId: "older", type: "PreToolUse", timestamp: iso(daysAgo: 60))
        try harness.seed(sessionId: "nearer", type: "PreToolUse", timestamp: iso(daysAgo: 30))
        try setWatermarks(UTCDay.string(from: Date().addingTimeInterval(-2 * 86400)))
        try database.setSetting(StorageSettings.key, "7")
        try markAllBilled()
        let frontier = Date().addingTimeInterval(-40 * 86400)
        _ = try harness.archive.append([RawRecord(
            provider: "claude", sourceKind: "transcript", dedupKey: "frontier", receivedAt: frontier,
            payload: Data("{}".utf8))])
        let target = try harness.archive.maxID()
        try harness.store.setMetaValue(String(target), forKey: ClaudeArchiveReplay.backfillTargetKey)
        try harness.store.setMetaValue(String(target - 1), forKey: ClaudeArchiveReplay.lastRawIDKey)

        let hold = try XCTUnwrap(HistoryBackfill.trimHold(in: harness.handles))
        XCTAssertEqual(hold, TrimHold(day: HistoryBackfill.holdDay(frontier: frontier),
                                      reason: HistoryBackfill.waitingForBackfill))
        XCTAssertEqual(hold.day, UTCDay.string(from: frontier.addingTimeInterval(-2 * 86400)))

        let handles = harness.handles
        let backfillHold: @Sendable () -> TrimHold? = { HistoryBackfill.trimHold(in: handles) }
        let held = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: Date.init,
            backfillHold: backfillHold)
        XCTAssertNil(held.error)
        XCTAssertEqual(held.waitingFor, HistoryBackfill.waitingForBackfill)
        XCTAssertLessThanOrEqual(try XCTUnwrap(held.cutoff), frontier.timeIntervalSince1970)
        XCTAssertEqual(held.events, 1, "the day before the frontier is trimmed")
        XCTAssertEqual(try count("events", in: harness), 1, "the day after it waits for the backfill")

        try harness.store.setMetaValue(String(target), forKey: ClaudeArchiveReplay.lastRawIDKey)
        XCTAssertNil(HistoryBackfill.trimHold(in: harness.handles), "a finished backfill holds nothing")
        let free = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: Date.init,
            backfillHold: backfillHold)
        XCTAssertNil(free.waitingFor)
        XCTAssertEqual(free.events, 1)
    }

    func testNoBackfillTargetHoldsNothing() throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        XCTAssertNil(HistoryBackfill.trimHold(in: harness.handles))
        XCTAssertNil(HistoryBackfill.trimHold(in: nil))
    }

    func testTheEarlierOfTwoHoldsWins() {
        let billing = TrimHold(day: "2026-07-10", reason: TrimService.waitingForBilling)
        let backfill = TrimHold(day: "2026-07-03", reason: HistoryBackfill.waitingForBackfill)
        XCTAssertEqual(StorageController.earlierHold(billing, backfill), backfill)
        XCTAssertEqual(StorageController.earlierHold(backfill, billing), backfill)
        XCTAssertEqual(StorageController.earlierHold(nil, billing), billing)
        XCTAssertEqual(StorageController.earlierHold(billing, nil), billing)
        XCTAssertNil(StorageController.earlierHold(nil, nil))
    }

    // MARK: - Review Focus 5: an events.db without INCREMENTAL auto_vacuum

    func testAStoreWithoutIncrementalAutoVacuumStillTrimsAndSaysWhy() throws {
        let pipeline = tmpDir.appendingPathComponent("pipeline")
        try FileManager.default.createDirectory(at: pipeline, withIntermediateDirectories: true)
        do {
            let queue = try DatabaseQueue(path: pipeline.appendingPathComponent(EventStore.fileName).path)
            try queue.writeWithoutTransaction { conn in
                try conn.execute(sql: "PRAGMA auto_vacuum = NONE")
                try conn.execute(sql: "CREATE TABLE legacy(x)")
            }
            try queue.close()
        }
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        try harness.seed(sessionId: "old", type: "PreToolUse", timestamp: iso(daysAgo: 60))
        try harness.seed(sessionId: "new", type: "PreToolUse", timestamp: iso(daysAgo: 0))
        try setWatermarks(UTCDay.string(from: Date().addingTimeInterval(-2 * 86400)))
        try database.setSetting(StorageSettings.key, "7")
        try markAllBilled()

        let report = pass(harness)
        XCTAssertNil(report.error)
        XCTAssertEqual(report.events, 1)
        XCTAssertEqual(report.vacuum, TrimService.vacuumUnavailable)
        XCTAssertEqual(try count("events", in: harness), 1)
        XCTAssertEqual(TrimService.lastReport(database)?.vacuum, TrimService.vacuumUnavailable)
    }
}

/// A thread-safe counter for the passes a controller ran.
private final class OSAllocatedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func increment() { lock.withLock { count += 1 } }
    var value: Int { lock.withLock { count } }
}
