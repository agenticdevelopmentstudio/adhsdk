import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `LivenessTask` is the schedule adapter over the toolkit's `LivenessService`; the
/// reconciliation rules are covered there. This pins what the adapter owns: its
/// schedule, and that an `execute` pass reaches the service with the broadcast hook.
final class LivenessTaskTests: XCTestCase {

    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "liveness-task-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/liveness-task.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    func testScheduleRunsEveryCheckIntervalAndDoesNotBackOff() {
        let task = LivenessTask(
            database: database, checkInterval: 10, liveProcesses: { [] }, onStatusChange: { _, _ in })
        XCTAssertEqual(task.schedule.intervalSeconds, 10)
        XCTAssertTrue(task.schedule.enabled)
        XCTAssertFalse(task.schedule.backoffOnFailure)
    }

    func testExecuteEndsASessionWithNoLiveClaudeAndBroadcastsIt() async throws {
        let hook: [String: Any] = [
            "session_id": "gone", "cwd": "/tmp", "model": "sonnet", "pid": 0, "term_program": "TestRunner"
        ]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try database.ingestEvent(eventType: "SessionStart", timestamp: fmt.string(from: Date()), hookData: hook)

        let broadcast = LockedBox<[String]>([])
        let task = LivenessTask(
            database: database, liveProcesses: { [] },
            onStatusChange: { id, status in broadcast.mutate { $0.append("\(id):\(status.rawValue)") } }
        )
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        _ = try await task.execute(context: ctx)

        XCTAssertEqual(try database.fetchSession(sessionId: "gone")?.status, "ended")
        XCTAssertEqual(broadcast.value, ["gone:ended"])
    }
}

private final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value
    init(_ value: Value) { stored = value }
    var value: Value { lock.withLock { stored } }
    func mutate(_ body: (inout Value) -> Void) { lock.withLock { body(&stored) } }
}
