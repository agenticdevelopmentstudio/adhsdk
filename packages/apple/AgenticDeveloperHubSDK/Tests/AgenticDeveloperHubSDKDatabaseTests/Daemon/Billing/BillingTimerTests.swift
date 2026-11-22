import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

final class BillingTimerTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-timer-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-timer.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    private func makeProject(_ name: String = "P") throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: name, defaultRateCents: 10_000), database: database
        )
    }

    private func at(_ minutes: Int) -> String {
        String(format: "2026-09-22T%02d:%02d:00Z", 9 + minutes / 60, minutes % 60)
    }

    // MARK: - Start and stop

    func testStartingATimerCreatesARunningManualSegment() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id, projectRoot: "/src/app",
                                 branch: "main", note: "Call with the client"),
            now: at(0), database: database
        )

        XCTAssertEqual(timer.origin, "manual")
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.seconds, 0)
        XCTAssertEqual(timer.note, "Call with the client")
        XCTAssertEqual(timer.projectId, project.id)
        XCTAssertFalse(timer.tz.isEmpty, "a segment must know the zone its day is bucketed in")
    }

    func testStoppingATimerClosesItAndRecordsTheDuration() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )
        let stopped = try BillingTimer.stop(id: timer.id, now: at(45), database: database)

        XCTAssertFalse(stopped.isRunning)
        XCTAssertEqual(stopped.seconds, 45 * 60)
        XCTAssertEqual(stopped.endedAt, at(45))
    }

    func testStoppingATimerTwiceIsRefused() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )
        _ = try BillingTimer.stop(id: timer.id, now: at(10), database: database)
        XCTAssertThrowsError(try BillingTimer.stop(id: timer.id, now: at(20), database: database))
    }

    func testStoppingAnUnknownTimerIsRefused() {
        XCTAssertThrowsError(try BillingTimer.stop(id: "nope", now: at(1), database: database))
    }

    /// The invariant that makes manual time defensible: one running timer.
    func testStartingASecondTimerStopsTheFirst() throws {
        let alpha = try makeProject("Alpha")
        let beta = try makeProject("Beta")

        let first = try BillingTimer.start(
            BillingTimerStartDTO(projectId: alpha.id), now: at(0), database: database
        )
        let second = try BillingTimer.start(
            BillingTimerStartDTO(projectId: beta.id), now: at(30), database: database
        )

        let closed = try XCTUnwrap(database.billingSegment(id: first.id))
        XCTAssertFalse(closed.isRunning, "the same minute cannot be billed to two clients")
        XCTAssertEqual(closed.seconds, 30 * 60)
        XCTAssertEqual(closed.endedAt, at(30), "the first timer ends exactly where the second begins")
        XCTAssertTrue(second.isRunning)
        XCTAssertEqual(try BillingTimer.running(database: database).count, 1)
    }

    func testStopAllClosesEveryRunningManualTimer() throws {
        let project = try makeProject()
        _ = try BillingTimer.start(BillingTimerStartDTO(projectId: project.id),
                                   now: at(0), database: database)
        XCTAssertEqual(try BillingTimer.stopAll(now: at(20), database: database), 1)
        XCTAssertTrue(try BillingTimer.running(database: database).isEmpty)
    }

    /// A derived run in progress is not a manual timer and must survive
    /// `stopAll` — closing it by hand would fight the next derivation pass.
    func testStopAllLeavesDerivedRunsAlone() throws {
        try database.upsertBillingSegment(BillingSegmentDTO(
            id: "auto1", sessionId: "s1", origin: "auto", projectRoot: "/src/app",
            startedAt: at(0), endedAt: "", tz: "UTC", seconds: 0
        ))
        XCTAssertEqual(try BillingTimer.stopAll(now: at(20), database: database), 0)
        XCTAssertTrue(try XCTUnwrap(database.billingSegment(id: "auto1")).isRunning)
    }

    // MARK: - Rate context

    /// An unassigned start still records where the work happened, so the
    /// segment can be assigned to a project later without losing its context.
    func testAnUnassignedTimerKeepsItsRootAndBranch() throws {
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectRoot: "/src/unknown", branch: "spike"),
            now: at(0), database: database
        )
        XCTAssertNil(timer.projectId)
        XCTAssertEqual(timer.projectRoot, "/src/unknown")
        XCTAssertEqual(timer.branch, "spike")
    }

    /// Starting with only a path resolves the project the way derivation does,
    /// so a timer started from the Activity window lands in the right place.
    func testAStartWithOnlyAPathResolvesTheMappedProject() throws {
        let project = try makeProject()
        _ = try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/app"),
            database: database
        )
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectRoot: "/src/app"), now: at(0), database: database
        )
        XCTAssertEqual(timer.projectId, project.id)
        XCTAssertNotNil(timer.repoId)
    }

    // MARK: - Runaway cap

    func testATimerPastTheCapIsFlaggedAndLeftRunning() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )

        let flagged = try BillingTimer.flagRunaways(
            capSeconds: 4 * 3600, now: at(9 * 60), database: database
        )
        XCTAssertEqual(flagged, 1)

        let after = try XCTUnwrap(database.billingSegment(id: timer.id))
        XCTAssertTrue(after.flags.contains("runaway"))
        XCTAssertTrue(after.isRunning, "the daemon does not know whether you worked or forgot")
        XCTAssertEqual(after.seconds, 0, "and it invents no duration")
    }

    func testATimerInsideTheCapIsNotFlagged() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )
        XCTAssertEqual(
            try BillingTimer.flagRunaways(capSeconds: 4 * 3600, now: at(60), database: database), 0
        )
        XCTAssertTrue(try XCTUnwrap(database.billingSegment(id: timer.id)).flags.isEmpty)
    }

    func testFlaggingIsIdempotent() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )
        _ = try BillingTimer.flagRunaways(capSeconds: 3600, now: at(300), database: database)
        XCTAssertEqual(
            try BillingTimer.flagRunaways(capSeconds: 3600, now: at(360), database: database), 0,
            "an already-flagged timer is not re-flagged every pass"
        )
        XCTAssertEqual(try XCTUnwrap(database.billingSegment(id: timer.id)).flags, "runaway")
    }

    // MARK: - Rollup

    /// Manual time is billable time. A stopped timer must roll up through the
    /// same path as a derived run — no second pipeline.
    func testAStoppedTimerRollsIntoAnEntry() throws {
        let project = try makeProject()
        let timer = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id, projectRoot: "/src/app"),
            now: at(0), database: database
        )
        _ = try BillingTimer.stop(id: timer.id, now: at(60), database: database)

        let options = BillingRollupOptions(granularity: .day, defaultRateCents: 0, currency: "USD")
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1)
        let entry = try XCTUnwrap(database.billingEntries(projectId: nil, status: nil, since: "").first)
        XCTAssertEqual(entry.rawSeconds, 3600)
        XCTAssertEqual(entry.amountCents, 10_000)
    }

    /// Stopping the running timer and inserting the new one are one write: a
    /// start that fails part-way must not leave the user with no timer at all.
    func testAFailedStartLeavesTheRunningTimerRunning() throws {
        let project = try makeProject()
        let first = try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id), now: at(0), database: database
        )
        try database.execute("""
            CREATE TRIGGER boom BEFORE INSERT ON billing_segment WHEN NEW.note = 'boom'
            BEGIN SELECT RAISE(ABORT, 'boom'); END
        """)

        XCTAssertThrowsError(try BillingTimer.start(
            BillingTimerStartDTO(projectId: project.id, note: "boom"), now: at(10), database: database
        ))

        let still = try XCTUnwrap(database.billingSegment(id: first.id))
        XCTAssertTrue(still.isRunning, "the stop rolled back with the failed insert")
        XCTAssertEqual(try BillingTimer.running(database: database).map(\.id), [first.id])
    }
}
