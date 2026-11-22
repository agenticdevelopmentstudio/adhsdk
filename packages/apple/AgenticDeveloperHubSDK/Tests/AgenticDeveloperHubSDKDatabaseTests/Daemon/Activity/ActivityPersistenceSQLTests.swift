import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

final class ActivityPersistenceSQLTests: XCTestCase {
    var paths: [String] = []
    override func tearDownWithError() throws { paths.forEach { try? FileManager.default.removeItem(atPath: $0) } }

    private func makeDB() throws -> DaemonDatabase {
        let dir = NSTemporaryDirectory() + "activity-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        paths.append(dir)
        return try TestDaemonDatabase.openFeatureDatabase(path: dir + "/activity.store")
    }

    private func idleRows(_ store: DaemonDatabase) throws -> [(from: String, until: String)] {
        var rows: [(from: String, until: String)] = []
        try store.query("SELECT idle_from, idle_until FROM activity_presence ORDER BY idle_from") { row in
            rows.append((from: row["idle_from"] ?? "", until: row["idle_until"] ?? ""))
        }
        return rows
    }

    func testSQLAdapterMeetsTheContract() throws {
        let failures = try ActivityPersistenceContract.runAll { try makeDB() }
        XCTAssertEqual(failures, [])
    }

    func testPruneKeepsUnderivedSpans() throws {
        let store = try makeDB()
        func open(_ id: String, _ start: String) throws {
            try store.openActivitySpan(ActivitySpanDTO(id: id, bundleId: "x", appName: "X",
                                                       startedAt: start, tz: "UTC"))
        }
        try open("old", "2026-01-01T09:00:00Z")
        try store.closeActivitySpan(id: "old", endedAt: "2026-01-01T10:00:00Z")
        try open("recent", "2026-07-01T09:00:00Z")
        try store.closeActivitySpan(id: "recent", endedAt: "2026-07-01T10:00:00Z")
        try open("live", "2026-01-02T09:00:00Z")
        try store.openIdleInterval(from: "2026-01-03T09:00:00Z")   // stays open
        let cutoff = "2026-06-01T00:00:00Z"

        XCTAssertEqual(try store.pruneActivity(endedBefore: cutoff), 0, "nothing derived yet")
        try store.markAppSpanBillingDerived(spanId: "old", at: "2026-01-01T10:00:00Z")
        try store.markAppSpanBillingDerived(spanId: "recent", at: "2026-07-01T10:00:00Z")
        try store.markAppSpanBillingDerived(spanId: "live", at: "2026-01-02T09:30:00Z")
        XCTAssertEqual(try store.pruneActivity(endedBefore: cutoff), 1, "only the old derived span")
        XCTAssertEqual(Set(try store.activitySpans(since: "", limit: 10).map(\.id)), ["recent", "live"],
                       "newer derived and open spans are kept")
        XCTAssertEqual(try idleRows(store).map(\.until), [""], "open idle row is kept")

        try store.closeIdleInterval(until: "2026-01-03T10:00:00Z")
        try store.openIdleInterval(from: "2026-07-02T09:00:00Z")
        XCTAssertEqual(try store.pruneActivity(endedBefore: cutoff), 0,
                       "the old idle row overlaps the still-open live span, which needs it")
        try store.closeActivitySpan(id: "live", endedAt: "2026-01-03T12:00:00Z")
        try store.markAppSpanBillingDerived(spanId: "live", at: "2026-01-03T12:00:00Z")
        XCTAssertEqual(try store.pruneActivity(endedBefore: cutoff), 2, "the live span, then its idle row")
        XCTAssertEqual(try idleRows(store).map(\.from), ["2026-07-02T09:00:00Z"])
    }

    func testPruneKeepsIdleTimeAKeptSpanStillOverlaps() throws {
        let store = try makeDB()
        try store.openActivitySpan(ActivitySpanDTO(id: "derived", bundleId: "x", appName: "X",
                                                   startedAt: "2026-01-01T09:00:00Z", tz: "UTC"))
        try store.closeActivitySpan(id: "derived", endedAt: "2026-01-01T10:00:00Z")
        try store.markAppSpanBillingDerived(spanId: "derived", at: "2026-01-01T10:00:00Z")
        try store.openActivitySpan(ActivitySpanDTO(id: "pending", bundleId: "x", appName: "X",
                                                   startedAt: "2026-01-01T11:00:00Z", tz: "UTC"))
        try store.closeActivitySpan(id: "pending", endedAt: "2026-01-01T12:00:00Z")   // not derived yet
        try store.openIdleInterval(from: "2026-01-01T09:15:00Z")
        try store.closeIdleInterval(until: "2026-01-01T09:30:00Z")
        try store.openIdleInterval(from: "2026-01-01T11:15:00Z")
        try store.closeIdleInterval(until: "2026-01-01T11:30:00Z")

        XCTAssertEqual(try store.pruneActivity(endedBefore: "2026-06-01T00:00:00Z"), 2,
                       "the derived span and the idle only it overlapped")
        XCTAssertEqual(try store.activitySpans(since: "", limit: 10).map(\.id), ["pending"])
        XCTAssertEqual(try idleRows(store).map(\.from), ["2026-01-01T11:15:00Z"],
                       "the pending span's idle time survives, so its derivation still splits there")
        let kept = try store.billingIdleIntervals(from: "2026-01-01T11:00:00Z", to: "2026-01-01T12:00:00Z")
        XCTAssertEqual(kept.count, 1)
    }

    func testRecoveryNeverBillsDowntime() throws {
        let store = try makeDB()
        try store.openActivitySpan(ActivitySpanDTO(id: "s", bundleId: "x", appName: "X",
                                                startedAt: "2026-10-01T09:00:00Z", tz: "UTC"))
        try store.touchActivitySpan(id: "s", at: "2026-10-01T09:05:00Z")
        XCTAssertEqual(try store.recoverActivity(now: "2026-10-02T08:00:00Z"), 1)
        XCTAssertEqual(try store.activitySpans(since: "", limit: 5).first?.endedAt, "2026-10-01T09:05:00Z")
    }

    func testIdleRowsHoldExactValuesAfterCloseAndRecovery() throws {
        let store = try makeDB()
        try store.openIdleInterval(from: "2026-10-01T09:10:00Z")
        try store.openIdleInterval(from: "2026-10-01T09:11:00Z")   // ignored: one is open
        var rows = try idleRows(store)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.from, "2026-10-01T09:10:00Z")
        XCTAssertEqual(rows.first?.until, "")

        try store.closeIdleInterval(until: "2026-10-01T09:20:00Z")
        rows = try idleRows(store)
        XCTAssertEqual(rows.first?.from, "2026-10-01T09:10:00Z")
        XCTAssertEqual(rows.first?.until, "2026-10-01T09:20:00Z")

        try store.openIdleInterval(from: "2026-10-01T10:00:00Z")
        try store.recoverActivity(now: "2026-10-02T08:00:00Z")
        rows = try idleRows(store)
        XCTAssertEqual(rows.count, 2)
        XCTAssertFalse(rows.contains { $0.until.isEmpty }, "recovery leaves no open idle row")
        XCTAssertEqual(rows[0].until, "2026-10-01T09:20:00Z", "already-closed row untouched")
        XCTAssertEqual(rows[1].from, "2026-10-01T10:00:00Z")
        XCTAssertEqual(rows[1].until, "2026-10-02T08:00:00Z")
    }

    private func segmentIds(_ store: DaemonDatabase) throws -> [String] {
        var ids: [String] = []
        try store.query("SELECT id FROM billing_segment ORDER BY id") { row in ids.append(row["id"] ?? "") }
        return ids
    }

    /// Review F7: a span recovered to under a second is deleted, and the open
    /// app: segment billing derived from it goes too — nothing else would ever
    /// close it, so it would read Running forever. A billed one is left alone.
    func testRecoveryDeletingASubSecondSpanDeletesItsOpenAppSegment() throws {
        let store = try makeDB()
        let start = "2026-10-01T09:00:00Z"
        try store.openActivitySpan(ActivitySpanDTO(id: "S", bundleId: "x", appName: "X", startedAt: start, tz: "UTC"))
        try store.openActivitySpan(ActivitySpanDTO(id: "L", bundleId: "x", appName: "X", startedAt: start, tz: "UTC"))
        try store.touchActivitySpan(id: "L", at: "2026-10-01T09:05:00Z")
        try store.execute("""
            INSERT INTO billing_segment (id, session_id, origin, started_at) VALUES
                ('seg-s', ?, 'auto', ?), ('seg-l', ?, 'auto', ?), ('seg-other', 'claude-1', 'auto', ?)
        """, params: [ActivitySpanSession.sessionId(spanId: "S"), start,
                      ActivitySpanSession.sessionId(spanId: "L"), start, start])

        XCTAssertEqual(try store.recoverActivity(now: "2026-10-01T10:00:00Z"), 1,
                       "only the span that survived is counted (review F31)")
        XCTAssertEqual(try store.activitySpans(since: "", limit: 10).map(\.id), ["L"])
        XCTAssertEqual(try segmentIds(store), ["seg-l", "seg-other"], "only the deleted span's segment goes")
    }

    /// Re-review N7: billing selects an open span, then the recorder deletes
    /// it for being under a second (taking its segments) before billing
    /// writes. The write must find the span gone and add nothing, or the open
    /// app: segment it leaves reads Running forever. A live span still derives.
    func testDerivingASpanDeletedSinceSelectionWritesNothing() throws {
        let store = try makeDB()
        let start = "2026-10-01T09:00:00Z"
        try store.openActivitySpan(ActivitySpanDTO(id: "S", bundleId: "x", appName: "X", startedAt: start, tz: "UTC"))
        try store.openActivitySpan(ActivitySpanDTO(id: "L", bundleId: "x", appName: "X", startedAt: start, tz: "UTC"))
        try store.closeActivitySpan(id: "S", endedAt: start)    // under a second: deleted
        let run = BillingRun(startedAt: start, endedAt: "", seconds: 0)
        let context = BillingSegmentContext(projectId: nil, repoId: nil, projectRoot: "/repo", branch: "main",
                                            tz: "UTC", tracked: true)

        XCTAssertEqual(try store.replaceDerivedSegments(
            sessionId: ActivitySpanSession.sessionId(spanId: "S"), runs: [run], context: context), 0)
        XCTAssertEqual(try store.replaceDerivedSegments(
            sessionId: ActivitySpanSession.sessionId(spanId: "L"), runs: [run], context: context), 1)
        var sessions: [String] = []
        try store.query("SELECT session_id FROM billing_segment") { row in sessions.append(row["session_id"] ?? "") }
        XCTAssertEqual(sessions, [ActivitySpanSession.sessionId(spanId: "L")])
    }

    /// Review F32: the boundary is fixed against an explicit reference date,
    /// so a raw (non-`datetime(?)`) compare fails at any time of day: the
    /// edge row sits on the cutoff's own calendar day, after the cutoff.
    func testKnownRepoRootsUnionsBillingReposAndSessionsSinceTheCutoff() throws {
        let store = try makeDB()
        let reference = try XCTUnwrap(UTCTimestamp.date(from: "2026-10-05T18:00:00Z"))
        let cutoff = UTCTimestamp.string(daysAgo: 30, from: reference)        // 2026-09-05T18:00:00Z
        XCTAssertEqual(cutoff, "2026-09-05T18:00:00Z")
        try store.execute("INSERT INTO billing_repo (id, project_id, project_root) VALUES ('r1', 'p1', '/repo/billed')")
        try store.execute("""
            INSERT INTO sessions (session_id, cwd, project_root, last_activity_at) VALUES
                ('s1', '/repo/recent', '/repo/recent', '2026-10-04 12:00:00'),
                ('s2', '/repo/recent', '/repo/recent', '2026-10-03 12:00:00'),
                ('s3', '/repo/billed', '/repo/billed', '2026-10-04 12:00:00'),
                ('s4', '/repo/old', '/repo/old', '2026-08-01 12:00:00'),
                ('s5', '/tmp', '', '2026-10-04 12:00:00'),
                ('s6', '/repo/edge', '/repo/edge', '2026-09-05 20:00:00'),
                ('s7', '/repo/justout', '/repo/justout', '2026-09-05 17:00:00')
        """)
        XCTAssertEqual(try store.knownRepoRoots(activeSince: cutoff).sorted(),
                       ["/repo/billed", "/repo/edge", "/repo/recent"],
                       "deduplicated; the cutoff day's later hours kept; earlier and blank roots left out")
    }
}
