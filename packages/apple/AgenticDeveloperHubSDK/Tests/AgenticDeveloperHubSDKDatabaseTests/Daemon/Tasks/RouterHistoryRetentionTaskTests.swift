import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `RouterHistoryRetentionTask` over shared migration 1005's table. The router
/// that writes `account_router_exchange` rows is not in the toolkit, so the rows
/// go in by SQL here; the retention window is the task's injected closure, read
/// from a setting the way the daemon reads `account_router_retention_days`.
final class RouterHistoryRetentionTaskTests: XCTestCase {

    private static let retentionKey = "account_router_retention_days"

    private var tmpDir: URL!
    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("router-history-retention-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        tmpPath = tmpDir.appendingPathComponent("session.db").path
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        // The whole directory, so the WAL and shared-memory files go too.
        try? FileManager.default.removeItem(at: tmpDir)
    }

    /// The setting, 30 when unset or unreadable, as the router's settings read it.
    private static let retentionDays: @Sendable (DaemonDatabase) -> Int = { database in
        guard let raw = try? database.setting(for: retentionKey), let days = Int(raw) else { return 30 }
        return min(max(days, 0), 3650)
    }

    private func makeTask(now: @escaping @Sendable () -> Date = Date.init) -> RouterHistoryRetentionTask {
        RouterHistoryRetentionTask(database: database, retentionDays: Self.retentionDays, now: now)
    }

    private func insert(daysAgo: Double) throws {
        let startedAt = DaemonDatabase.routerTimestamp(Date().addingTimeInterval(-daysAgo * 86400))
        try database.execute("""
            INSERT INTO account_router_exchange (started_at, duration_ms, session_id, method, path, status)
            VALUES (?, 5, 's', 'POST', '/v1/messages', 200)
            """, params: [startedAt])
    }

    private func run() async throws -> SessionTaskResult {
        let task = makeTask()
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        return try await task.execute(context: ctx)
    }

    private func count() throws -> Int {
        var rows = 0
        try database.query("SELECT COUNT(*) FROM account_router_exchange") { row in rows = row[0] ?? 0 }
        return rows
    }

    private func newestStartedAt() throws -> String? {
        var newest: String?
        try database.query("SELECT MAX(started_at) FROM account_router_exchange") { row in newest = row[0] }
        return newest
    }

    func testScheduleIsAlwaysOnDaily() {
        let task = makeTask()
        XCTAssertEqual(task.name, "router-history-retention")
        XCTAssertTrue(task.schedule.enabled)
        XCTAssertEqual(task.schedule.intervalSeconds, 86400)
    }

    func testDeletesRowsOlderThanTheSettingAndKeepsNewer() async throws {
        try database.setSetting(Self.retentionKey, "30")
        try insert(daysAgo: 40)
        try insert(daysAgo: 10)
        _ = try await run()
        XCTAssertEqual(try count(), 1)
        let cutoff = DaemonDatabase.routerTimestamp(Date().addingTimeInterval(-20 * 86400))
        XCTAssertGreaterThan(try XCTUnwrap(newestStartedAt()), cutoff)
    }

    func testDefaultThirtyDaysAppliesWithNoSetting() async throws {
        try insert(daysAgo: 40)
        try insert(daysAgo: 10)
        _ = try await run()
        XCTAssertEqual(try count(), 1)
    }

    func testZeroKeepsEverything() async throws {
        try database.setSetting(Self.retentionKey, "0")
        try insert(daysAgo: 400)
        try insert(daysAgo: 1)
        _ = try await run()
        XCTAssertEqual(try count(), 2)
    }

    func testSettingIsReadFreshOnEveryRun() async throws {
        try database.setSetting(Self.retentionKey, "0")
        try insert(daysAgo: 40)
        _ = try await run()
        XCTAssertEqual(try count(), 1)
        try database.setSetting(Self.retentionKey, "30")
        _ = try await run()
        XCTAssertEqual(try count(), 0)
    }

    func testFullBatchRerunsImmediatelyThenDrains() async throws {
        try database.setSetting(Self.retentionKey, "30")
        for _ in 0...DaemonDatabase.routerPruneBatch { try insert(daysAgo: 40) }
        let first = try await run()
        XCTAssertEqual(first.nextRunSeconds, 0)
        XCTAssertEqual(try count(), 1)
        let second = try await run()
        XCTAssertNil(second.nextRunSeconds)
        XCTAssertEqual(try count(), 0)
    }

    func testInjectedClockDecidesTheCutoff() async throws {
        try database.setSetting(Self.retentionKey, "30")
        try insert(daysAgo: 10)
        let future = Date().addingTimeInterval(60 * 86400)
        let task = makeTask(now: { future })
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        _ = try await task.execute(context: ctx)
        XCTAssertEqual(try count(), 0)
    }

    func testTheStorageTrimNeverPrunesRouterRows() async throws {
        try database.setSetting(StorageSettings.key, "7")
        try database.setSetting(Self.retentionKey, "0")
        let today = UTCDay.string(from: Date())
        try database.setRollupFinalizedThrough(today)
        try database.setSetting(DaemonDatabase.usageSummaryFinalizedKey, today)
        try insert(daysAgo: 400)
        let task = TrimTask(storage: StorageController(database: database, claude: ClaudePipelineSlot()))
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        _ = try await task.execute(context: ctx)
        XCTAssertNotNil(TrimService.lastReport(database)?.cutoff, "the trim ran with a cutoff")
        XCTAssertEqual(try count(), 1)
    }
}
