import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// An all-sessions source (the Conversations shelf's) reads the whole roster —
/// every session ever recorded, megabytes of JSON — only every
/// ``StenographerSessionListSource/rosterInterval``, and the recent slice on
/// every poll in between, laid over the last whole read.
final class SessionListSourceRosterTests: XCTestCase {

    private final class Box<Value>: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Value
        init(_ value: Value) { stored = value }
        var value: Value {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    private func session(_ id: String, tool: String = "") -> SessionWatcher.SessionWatcherSession {
        SessionWatcher.SessionWatcherSession(
            sessionId: id, cwd: "/tmp/\(id)", model: "test", startedAt: "", lastActivityAt: "",
            lastTool: tool, status: .active, gitBranch: "", summary: "", pid: 1,
            termProgram: "Test", projectRoot: "", termSessionId: ""
        )
    }

    func testReadsTheWholeRosterRarelyAndTheRecentSliceBetween() async throws {
        let clock = Box(Date(timeIntervalSince1970: 1_000_000))
        let requested = Box<[Int]>([])
        let whole = Box([session("old"), session("recent")])
        let recent = Box([session("recent")])
        let changes = Box(0)
        let source = StenographerSessionListSource(
            pollInterval: 0.01, sinceHours: 0, now: { clock.value },
            fetcher: { hours in
                requested.value.append(hours)
                return hours == 0 ? whole.value : recent.value
            })
        source.startObserving { changes.value += 1 }
        defer { source.stopObserving() }

        try await waitUntil("a few polls ran") { requested.value.count >= 4 }
        XCTAssertEqual(requested.value.first, 0, "the first read is the whole roster")
        XCTAssertEqual(
            Set(requested.value.dropFirst()), [StenographerSessionListSource.recentHours],
            "a poll between whole reads asked for every session again")
        var sessions = try await source.fetchSessions()
        XCTAssertEqual(sessions.map(\.sessionId), ["recent", "old"], "the old session dropped out")

        // A recent session changes; the slice carries it over the roster.
        recent.value = [session("recent", tool: "Bash"), session("new")]
        try await waitUntil("the slice landed") {
            (try? await source.fetchSessions())?.map(\.sessionId) == ["recent", "new", "old"]
        }
        sessions = try await source.fetchSessions()
        XCTAssertEqual(sessions.first?.lastTool, "Bash")

        // Past the interval the whole roster is read again.
        whole.value = [session("recent"), session("new")]
        let before = requested.value.count
        clock.value = clock.value.addingTimeInterval(StenographerSessionListSource.rosterInterval)
        try await waitUntil("the whole roster was read again") {
            requested.value.dropFirst(before).contains(0)
        }
    }

    func testATimeSliceSourceNeverReadsTheWholeRoster() async throws {
        let requested = Box<[Int]>([])
        let source = StenographerSessionListSource(
            pollInterval: 0.01, sinceHours: 24,
            fetcher: { hours in requested.value.append(hours); return [] })
        source.startObserving {}
        defer { source.stopObserving() }
        try await waitUntil("a few polls ran") { requested.value.count >= 3 }
        XCTAssertFalse(requested.value.contains(0))
    }

    private func waitUntil(
        _ what: String, timeout: Duration = .seconds(5), _ condition: () async -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while await !condition() {
            if ContinuousClock.now > deadline { return XCTFail("timed out waiting until \(what)") }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
