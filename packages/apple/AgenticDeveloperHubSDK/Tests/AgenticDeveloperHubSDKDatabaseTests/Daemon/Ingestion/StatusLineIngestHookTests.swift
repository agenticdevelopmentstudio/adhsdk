import AgenticDeveloperHubSDKCore
import XCTest
import Foundation
import GRDB
@testable import AgenticDeveloperHubSDKDatabase

/// The injected `StatusLine` hook: `ingestEvent` hands a StatusLine payload to
/// the consumer's closure, and only that event type.
final class StatusLineIngestHookTests: XCTestCase {

    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var calls: [(sessionId: String, version: String, account: String)] = []

        func record(sessionId: String, hookData: [String: Any], account: String) {
            lock.lock(); defer { lock.unlock() }
            calls.append((sessionId, hookData["version"] as? String ?? "", account))
        }

        var all: [(sessionId: String, version: String, account: String)] {
            lock.lock(); defer { lock.unlock() }
            return calls
        }
    }

    /// The deprecated `statusLineMetricsIngest` still records the session's
    /// figures and version schema, and still writes no rate-limit snapshot.
    @available(*, deprecated)
    func testTheDeprecatedMetricsIngestKeepsItsOldBehavior() throws {
        let (store, path) = try TestDaemonDatabase.makeSessionDatabase(
            statusLineIngest: DaemonDatabase.statusLineMetricsIngest
        )
        defer { TestDaemonDatabase.remove(path: path) }

        try store.ingestEvent(
            eventType: "StatusLine", timestamp: "2026-06-01T12:01:00Z",
            hookData: [
                "session_id": "old", "cwd": "/tmp", "version": "2.1.0",
                "context_window": ["context_window_size": 200_000, "remaining_percentage": 40],
                "rate_limits": ["seven_day": ["used_percentage": 12.0, "resets_at": 1_780_000_000]]
            ]
        )

        let (used, versions, snapshots) = try store.read { conn in
            (try Int.fetchOne(conn, sql: "SELECT context_used_pct FROM session_metrics WHERE session_id = 'old'"),
             try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM claude_versions WHERE claude_version = '2.1.0'"),
             try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM rate_limit_snapshots"))
        }
        XCTAssertEqual(used, 60)
        XCTAssertEqual(versions, 1)
        XCTAssertEqual(snapshots, 0, "the old handler never wrote rate-limit snapshots")
    }

    func testOnlyAStatusLineEventReachesTheHook() throws {
        let recorder = Recorder()
        let (store, path) = try TestDaemonDatabase.makeSessionDatabase(
            statusLineIngest: { _, sessionId, hookData, _, account in
                recorder.record(sessionId: sessionId, hookData: hookData, account: account)
            }
        )
        defer { TestDaemonDatabase.remove(path: path) }

        try store.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-06-01T12:00:00Z",
            hookData: ["session_id": "hook", "cwd": "/tmp"]
        )
        XCTAssertTrue(recorder.all.isEmpty, "a PreToolUse must not reach the StatusLine hook")

        try store.ingestEvent(
            eventType: "StatusLine", timestamp: "2026-06-01T12:01:00Z",
            hookData: ["session_id": "hook", "cwd": "/tmp", "version": "2.1.0"],
            accountEmail: "me@example.com"
        )
        XCTAssertEqual(recorder.all.count, 1)
        XCTAssertEqual(recorder.all.first?.sessionId, "hook")
        XCTAssertEqual(recorder.all.first?.version, "2.1.0")
        XCTAssertEqual(recorder.all.first?.account, "me@example.com")
    }
}
