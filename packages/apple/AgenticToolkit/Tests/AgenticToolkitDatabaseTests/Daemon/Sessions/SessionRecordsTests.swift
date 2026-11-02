import AgenticToolkitCore
import XCTest
import Foundation
@testable import AgenticToolkitDatabase

/// The `sessions` table through the `DaemonDatabase` methods: status writes,
/// the existence probe and the counts.
final class SessionRecordsTests: XCTestCase {

    private var store: DaemonDatabase!
    private var path: String!

    private var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        (store, path) = try TestDaemonDatabase.makeSessionDatabase()
        let pipeline = URL(fileURLWithPath: path).deletingLastPathComponent().appendingPathComponent("pipeline")
        harness = try ClaudePipelineTestHarness(directory: pipeline, database: store)
    }

    override func tearDownWithError() throws {
        harness = nil
        store = nil
        TestDaemonDatabase.remove(path: path)
    }

    private func start(_ id: String) throws {
        try harness.ingest(ClaudePipelineTestHarness.event(
            "SessionStart", sessionId: id, timestamp: "2026-06-01T12:00:00Z", cwd: "/tmp/\(id)"))
    }

    func testUpdateSessionStatusIsReadBack() throws {
        try start("s1")
        store.updateSessionStatus(.ended, sessionId: "s1")
        XCTAssertEqual(try store.fetchSession(sessionId: "s1")?.status, "ended")
    }

    func testExistingSessionIdsReturnsOnlyThePresentOnes() throws {
        try start("s1")
        try start("s2")
        XCTAssertEqual(try store.existingSessionIds(["s1", "s3", "s2", "s4"]), ["s1", "s2"])
        XCTAssertEqual(try store.existingSessionIds([]), [])
    }

    func testCountsAfterTwoIngests() throws {
        try start("s1")
        try start("s2")
        store.updateSessionStatus(.ended, sessionId: "s2")
        XCTAssertEqual(try store.activeSessionCount(), 1)
        XCTAssertEqual(try store.totalEventCount(), 2)
    }
}
