import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors billing-timer-001 ... 011, against an in-memory
/// persistence.
final class BillingTimerConformanceTests: XCTestCase {

    private func running(_ id: String, origin: String = "manual", start: String = "2026-09-22T09:00:00Z")
        -> BillingSegmentDTO {
        BillingSegmentDTO(id: id, origin: origin, startedAt: start)
    }

    func testV001_startClosesOtherTimersInOneTransaction() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("A", start: "2026-09-22T09:00:00Z")]
        let now = "2026-09-22T10:00:00Z"

        let started = try BillingTimer.start(
            BillingTimerStartDTO(projectId: "p1", note: "b"), now: now, database: database
        )

        let closed = try XCTUnwrap(database.segment("A"))
        XCTAssertEqual(closed.endedAt, now)
        XCTAssertEqual(closed.seconds, 3600)
        XCTAssertTrue(try XCTUnwrap(database.segment(started.id)).isRunning)
        XCTAssertEqual(database.transactionCalls, 1)
    }

    func testV002_failedInsertLeavesThePreviousTimerRunning() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("A")]
        database.failSegmentUpserts = true

        XCTAssertThrowsError(try BillingTimer.start(
            BillingTimerStartDTO(projectId: "p1"), now: "2026-09-22T10:00:00Z", database: database
        ))

        XCTAssertTrue(try XCTUnwrap(database.segment("A")).isRunning)
        XCTAssertEqual(database.segments.count, 1)
    }

    func testV003_startResolvesProjectAndRepoFromTheRoot() throws {
        let database = InMemoryBillingPersistence()
        database.projects = [BillingProjectDTO(id: "p1", name: "Site")]
        database.repos = [BillingRepoDTO(id: "r1", projectId: "p1", projectRoot: "/app")]

        let started = try BillingTimer.start(
            BillingTimerStartDTO(projectRoot: "/app", branch: "main"), now: "2026-09-22T10:00:00Z",
            database: database
        )

        XCTAssertEqual(started.projectId, "p1")
        XCTAssertEqual(started.repoId, "r1")
        XCTAssertEqual(database.segment(started.id)?.projectId, "p1")
    }

    func testV004_startKeepsANamedProject() throws {
        let database = InMemoryBillingPersistence()
        database.projects = [BillingProjectDTO(id: "p1", name: "Site"), BillingProjectDTO(id: "p2", name: "Other")]
        database.repos = [BillingRepoDTO(id: "r1", projectId: "p1", projectRoot: "/app")]

        let started = try BillingTimer.start(
            BillingTimerStartDTO(projectId: "p2", projectRoot: "/app", branch: "main"),
            now: "2026-09-22T10:00:00Z", database: database
        )

        XCTAssertEqual(started.projectId, "p2")
        XCTAssertNil(started.repoId)
    }

    func testV005_stopClosesWithElapsedSeconds() throws {
        let database = InMemoryBillingPersistence()
        let started = try BillingTimer.start(
            BillingTimerStartDTO(projectId: "p1"), now: "2026-09-22T10:00:00Z", database: database
        )

        let closed = try BillingTimer.stop(id: started.id, now: "2026-09-22T10:30:00Z", database: database)

        XCTAssertFalse(closed.isRunning)
        XCTAssertEqual(closed.endedAt, "2026-09-22T10:30:00Z")
        XCTAssertEqual(closed.seconds, 1800)
    }

    func testV006_stopOfAnUnknownTimerThrows() throws {
        let database = InMemoryBillingPersistence()
        XCTAssertThrowsError(try BillingTimer.stop(id: "missing", database: database)) { error in
            guard case BillingTimer.TimerError.unknownTimer = error else {
                return XCTFail("expected unknownTimer, got \(error)")
            }
        }
    }

    func testV007_stopOfAClosedTimerThrows() throws {
        let database = InMemoryBillingPersistence()
        let started = try BillingTimer.start(
            BillingTimerStartDTO(projectId: "p1"), now: "2026-09-22T10:00:00Z", database: database
        )
        try BillingTimer.stop(id: started.id, now: "2026-09-22T10:30:00Z", database: database)

        XCTAssertThrowsError(try BillingTimer.stop(id: started.id, database: database)) { error in
            guard case BillingTimer.TimerError.notRunning = error else {
                return XCTFail("expected notRunning, got \(error)")
            }
        }
    }

    func testV008_stopAllClosesManualTimersOnly() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("manual"), running("derived", origin: "auto")]

        let stopped = try BillingTimer.stopAll(now: "2026-09-22T10:00:00Z", database: database)

        XCTAssertEqual(stopped, 1)
        XCTAssertFalse(try XCTUnwrap(database.segment("manual")).isRunning)
        XCTAssertTrue(try XCTUnwrap(database.segment("derived")).isRunning)
    }

    func testV009_timerPastTheCapIsFlaggedAndKeepsRunning() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("long", start: "2026-09-22T01:00:00Z")]

        let flagged = try BillingTimer.flagRunaways(
            capSeconds: 8 * 3600, now: "2026-09-22T10:00:00Z", database: database
        )

        XCTAssertEqual(flagged, 1)
        let timer = try XCTUnwrap(database.segment("long"))
        XCTAssertTrue(timer.flags.contains("runaway"))
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.seconds, 0)
    }

    func testV010_timerUnderTheCapIsNotFlagged() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("short", start: "2026-09-22T03:00:00Z")]

        let flagged = try BillingTimer.flagRunaways(
            capSeconds: 8 * 3600, now: "2026-09-22T10:00:00Z", database: database
        )

        XCTAssertEqual(flagged, 0)
        XCTAssertFalse(try XCTUnwrap(database.segment("short")).flags.contains("runaway"))
    }

    func testV011_nonPositiveCapFlagsNothing() throws {
        let database = InMemoryBillingPersistence()
        database.segments = [running("long", start: "2026-09-21T01:00:00Z")]

        XCTAssertEqual(try BillingTimer.flagRunaways(capSeconds: 0, now: "2026-09-22T10:00:00Z", database: database), 0)
        XCTAssertEqual(
            try BillingTimer.flagRunaways(capSeconds: -5, now: "2026-09-22T10:00:00Z", database: database), 0)
        XCTAssertEqual(try XCTUnwrap(database.segment("long")).flags, "")
    }
}
