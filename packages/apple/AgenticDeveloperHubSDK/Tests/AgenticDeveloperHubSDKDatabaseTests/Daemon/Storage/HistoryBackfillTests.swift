import AgenticDeveloperHubSDKCore
import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The history backfill a cutover leaves pending: its status in `/storage`,
/// the reaper staying off until it finishes, a slice reaching the target, and
/// `HistoryBackfillTask`'s results.
final class HistoryBackfillTests: XCTestCase {

    private var tmpDir: URL!
    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("history-backfill-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        tmpPath = tmpDir.appendingPathComponent("session.db").path
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func stamp() -> String {
        Date().formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    /// A pipeline whose archive holds two drained records, with the cutover's
    /// target set at the second: what a daemon started on a partly replayed
    /// `events.db` sees.
    private func pendingPipeline() throws -> ClaudePipelineTestHarness {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        for name in ["PreToolUse", "Stop"] {
            try harness.handles.capture(ClaudePipelineTestHarness.event(name, sessionId: "s", timestamp: stamp()))
        }
        try harness.drain()
        try harness.store.setMetaValue("2", forKey: ClaudeArchiveReplay.backfillTargetKey)
        return harness
    }

    func testNoTargetMeansNoBackfill() async throws {
        let harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
        let backfill = HistoryBackfill(claude: ClaudePipelineSlot(harness.handles))
        XCTAssertNil(backfill.status())
        XCTAssertFalse(HistoryBackfill.pending(in: harness.handles))
        let outcome = await backfill.runSlice()
        XCTAssertEqual(outcome, .idle)
    }

    func testWithNoPipelineASliceIsUnavailable() async {
        let backfill = HistoryBackfill(claude: ClaudePipelineSlot())
        XCTAssertNil(backfill.status())
        let outcome = await backfill.runSlice()
        XCTAssertEqual(outcome, .unavailable)
    }

    func testAPendingBackfillReportsAndKeepsTheReaperOffUntilASliceFinishesIt() async throws {
        let harness = try pendingPipeline()
        let backfill = HistoryBackfill(claude: ClaudePipelineSlot(harness.handles))

        XCTAssertEqual(backfill.status(), HistoryBackfillDTO(targetRawID: 2, lastRawID: 0, running: false))
        XCTAssertTrue(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))

        let outcome = await backfill.runSlice()
        XCTAssertEqual(outcome, .finished(lastRawID: 2))
        XCTAssertNil(backfill.status())
        XCTAssertFalse(StorageController.capturesWaiting(pipeline: harness.handles, legacySpool: nil))
        let again = await backfill.runSlice()
        XCTAssertEqual(again, .idle)
    }

    func testASliceOutOfTimeProgressesNoFurtherThanItsFirstChunk() async throws {
        let harness = try pendingPipeline()
        let backfill = HistoryBackfill(claude: ClaudePipelineSlot(harness.handles))
        // A slice whose deadline has passed still commits what it read, or nothing.
        let outcome = await backfill.runSlice(seconds: -1)
        switch outcome {
        case .progressed, .finished: break
        default: XCTFail("unexpected \(outcome)")
        }
        XCTAssertFalse(backfill.isRunning)
    }

    func testTheTaskResultForEachOutcome() {
        XCTAssertNil(HistoryBackfillTask.result(for: .idle).nextRunSeconds)
        XCTAssertNil(HistoryBackfillTask.result(for: .finished(lastRawID: 9)).nextRunSeconds)
        XCTAssertEqual(
            HistoryBackfillTask.result(for: .progressed(lastRawID: 9)).nextRunSeconds,
            HistoryBackfillTask.pauseSeconds)
        XCTAssertEqual(HistoryBackfillTask.result(for: .busy).nextRunSeconds, HistoryBackfillTask.pauseSeconds)
        XCTAssertEqual(HistoryBackfillTask.result(for: .unavailable).nextRunSeconds, HistoryBackfillTask.retrySeconds)
        XCTAssertEqual(HistoryBackfillTask.result(for: .failed("x")).nextRunSeconds, HistoryBackfillTask.retrySeconds)
    }

    /// A slice that moved the cursor trims, and so does the one that
    /// finishes; one that replayed nothing new, or no slice, does not.
    func testOnlyASliceThatMovedTheCursorTrims() {
        let first = HistoryBackfillTask.trimDecision(after: .progressed(lastRawID: 10), previous: nil)
        XCTAssertTrue(first.trim)
        XCTAssertEqual(first.remember, 10)
        let stalled = HistoryBackfillTask.trimDecision(after: .progressed(lastRawID: 10), previous: 10)
        XCTAssertFalse(stalled.trim)
        XCTAssertEqual(stalled.remember, 10)
        let moved = HistoryBackfillTask.trimDecision(after: .progressed(lastRawID: 11), previous: 10)
        XCTAssertTrue(moved.trim)
        XCTAssertEqual(moved.remember, 11)
        XCTAssertTrue(HistoryBackfillTask.trimDecision(after: .finished(lastRawID: 11), previous: 11).trim)
        for outcome: HistoryBackfill.SliceOutcome in [.idle, .busy, .unavailable, .failed("x")] {
            let decision = HistoryBackfillTask.trimDecision(after: outcome, previous: 7)
            XCTAssertFalse(decision.trim)
            XCTAssertEqual(decision.remember, 7)
        }
    }

    /// After a trim, a progressing slice waits out the spacing before the
    /// next one, keeping the old cursor so the slice that is due still trims;
    /// the finishing slice trims whenever it comes.
    func testProgressingSlicesTrimAtMostOncePerSpacing() {
        let spacing = HistoryBackfillTask.trimSpacingSeconds
        let early = HistoryBackfillTask.trimDecision(
            after: .progressed(lastRawID: 20), previous: 10, sinceLastTrim: spacing - 1)
        XCTAssertFalse(early.trim)
        XCTAssertEqual(early.remember, 10)
        let due = HistoryBackfillTask.trimDecision(
            after: .progressed(lastRawID: 30), previous: early.remember, sinceLastTrim: spacing)
        XCTAssertTrue(due.trim)
        XCTAssertEqual(due.remember, 30)
        XCTAssertTrue(HistoryBackfillTask.trimDecision(
            after: .finished(lastRawID: 31), previous: 30, sinceLastTrim: 1).trim)
    }

    func testTheTaskOutlastsASliceAndATrimPass() {
        let task = HistoryBackfillTask(storage: StorageController(database: database, claude: ClaudePipelineSlot()))
        XCTAssertEqual(task.name, "history-backfill")
        XCTAssertTrue(task.schedule.enabled)
        XCTAssertGreaterThan(task.schedule.timeout, HistoryBackfill.sliceSeconds + StorageController.passSeconds)
    }

    func testTheStatusReaderCarriesTheBackfill() throws {
        let harness = try pendingPipeline()
        let slot = ClaudePipelineSlot(harness.handles)
        let storage = StorageController(database: database, claude: slot)
        let status = StorageStatusReader.status(database: database, storage: storage, claudePipeline: slot)
        XCTAssertEqual(status.historyBackfill?.targetRawID, 2)
        XCTAssertEqual(status.historyBackfill?.lastRawID, 0)
    }
}
