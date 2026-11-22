import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// A router that cannot bind at start keeps trying: Claude Code stays pointed
/// at it, so one failed bind must not leave every request refused until the
/// daemon is restarted by hand.
final class AccountRouterBindRetryTests: XCTestCase {
    private var database: DaemonDatabase!
    private var tmpDir: URL!

    override func setUpWithError() throws {
        database = try DaemonDatabase(
            path: ":memory:", migrations: SessionSchema.migrations, postMigration: SessionSchema.postMigration)
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-router-bind-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeRouter(port: UInt16) -> AccountRouterServer {
        AccountRouterServer(
            database: database, source: FakeQuotaSource(), port: port, upstream: URL(fileURLWithPath: "/"),
            fingerprintsPath: tmpDir.appendingPathComponent("fp.json").path,
            templateStore: ModelRouterTemplateStore(
                directory: tmpDir.appendingPathComponent("templates"), database: database),
            bindRetry: AccountRouterServer.BindRetry(first: 0.05, cap: 0.2))
    }

    private func waitUntil(_ timeout: TimeInterval = 10, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return condition()
    }

    func testRouterBindsOnceThePortIsFreed() async throws {
        let blocker = AccountRouterListener(port: 0) { $0.cancel() }
        let port = try await blocker.start(timeout: 5)
        let router = makeRouter(port: port)
        defer { router.stop() }
        let starting = Task { await router.start() }

        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(router.status().listening, "the port is still held")
        blocker.stop()

        let bound = await waitUntil { router.status().listening }
        XCTAssertTrue(bound, "the router never bound after the port was freed")
        XCTAssertEqual(router.status().port, Int(port))
        await starting.value
    }

    func testRouterStopEndsTheBindRetries() async throws {
        let blocker = AccountRouterListener(port: 0) { $0.cancel() }
        let port = try await blocker.start(timeout: 5)
        let router = makeRouter(port: port)
        let starting = Task { await router.start() }
        try await Task.sleep(nanoseconds: 200_000_000)
        router.stop()

        let ended = expectation(description: "start returns")
        Task {
            await starting.value
            ended.fulfill()
        }
        await fulfillment(of: [ended], timeout: 10)

        blocker.stop()
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(router.status().listening, "a stopped router must not bind later")
    }
}
