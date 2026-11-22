import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The billing pass runs every minute over every live session. These defend
/// the three things that keep it cheap without changing what it derives: the
/// formatter-free clock, the cursor-fed activity cache, and skipping a rewrite
/// that would change nothing.
final class BillingIncrementalDerivationTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-incremental-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-incremental.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
    }

    override func tearDownWithError() throws {
        harness = nil
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    private func at(_ minutes: Int) -> String {
        let total = 14 * 3600 + minutes * 60
        return String(format: "2026-09-22T%02d:%02d:00Z", total / 3600, (total % 3600) / 60)
    }

    private func seedSession(_ sessionId: String, status: String = "active", eventMinutes: [Int]) throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status, git_branch, project_root)
            VALUES (?, '/src/app', ?, ?, ?, 'main', '/src/app')
        """, params: [sessionId, at(0), at(eventMinutes.last ?? 0), status])
        try addEvents(sessionId, minutes: eventMinutes)
    }

    private func addEvents(_ sessionId: String, minutes: [Int], type: String = "PreToolUse") throws {
        for minute in minutes {
            try harness.seed(sessionId: sessionId, type: type, timestamp: at(minute))
        }
        try database.execute(
            "UPDATE sessions SET last_activity_at = ? WHERE session_id = ?",
            params: [at(minutes.max() ?? 0), sessionId]
        )
    }

    private func row(_ sessionId: String) throws -> BillingSessionRow {
        try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 50).first { $0.sessionId == sessionId })
    }

    // MARK: - Clock

    /// The hand parser must agree with the formatters it replaces on every
    /// shape it accepts, and hand everything else back to them.
    func testFastParserAgreesWithTheFormatters() throws {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        let cases = [
            "2026-09-22T10:00:00Z", "2026-09-22T10:00:00.218Z", "2024-02-29T23:59:59Z",
            "1999-12-31T00:00:01.5Z", "2026-01-01T00:00:00Z"
        ]
        for text in cases {
            let reference = try XCTUnwrap(plain.date(from: text) ?? iso.date(from: text), text)
            XCTAssertEqual(
                UTCTimestamp.epochSeconds(fast: text),
                Int(reference.timeIntervalSince1970.rounded(.down)), text
            )
        }
        XCTAssertEqual(
            UTCTimestamp.epochSeconds(fast: "2026-09-22 10:00:00"),
            UTCTimestamp.epochSeconds(fast: "2026-09-22T10:00:00Z")
        )
        XCTAssertEqual(
            UTCTimestamp.epochSeconds(fast: "2026-09-22 10:00:00.999"),
            UTCTimestamp.epochSeconds(fast: "2026-09-22T10:00:00Z"),
            "fractions truncate"
        )
        for rejected in [
            "2026-09-22T10:00:00", "2026-09-22T10:00:00+02:00", "2026-02-30T10:00:00Z",
            "2023-02-29T10:00:00Z", "2026-09-22T24:00:00Z", "2026-09-22 10:00:00Z",
            "2026-09-22T10:00:00.Z", "nonsense", ""
        ] {
            XCTAssertNil(UTCTimestamp.epochSeconds(fast: rejected), rejected)
        }
        // A fractional offset form still parses — through the formatter fallback.
        XCTAssertEqual(
            UTCTimestamp.epochSeconds("2026-09-22T12:00:00.5+02:00"),
            UTCTimestamp.epochSeconds("2026-09-22T10:00:00Z")
        )
    }

    func testFormattingRoundTripsAcrossYearsAndLeapDays() throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        var seconds = -2_000_000_000
        while seconds < 4_000_000_000 {
            let expected = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
            XCTAssertEqual(UTCTimestamp.string(epochSeconds: seconds), expected)
            XCTAssertEqual(UTCTimestamp.epochSeconds(fast: expected), seconds)
            seconds += 7_777_777
        }
        XCTAssertEqual(UTCTimestamp.string(epochSeconds: 1_709_251_199), "2024-02-29T23:59:59Z")
    }

    // MARK: - Cache

    func testMergingKeepsAscendingUniqueOrder() {
        XCTAssertEqual(BillingActivityCache.merging([5, 3, 3], into: []), [3, 5])
        XCTAssertEqual(BillingActivityCache.merging([9, 7], into: [1, 4, 6]), [1, 4, 6, 7, 9])
        XCTAssertEqual(BillingActivityCache.merging([4, 2, 8], into: [1, 4, 6]), [1, 2, 4, 6, 8])
        XCTAssertEqual(BillingActivityCache.merging([], into: [1, 2]), [1, 2])
    }

    /// The cache reads only rows past its cursor. Deleting an already-read
    /// row proves it: a full re-read would lose it.
    func testCacheReadsOnlyRowsPastItsCursor() throws {
        try seedSession("s1", eventMinutes: [0, 5])
        let cache = BillingActivityCache()
        let first = try cache.activitySeconds(sessionId: "s1", database: database)
        XCTAssertEqual(first.count, 2)

        try harness.deleteEvents(
            where: "session_id = 's1' AND time = ?", arguments: [ClaudePipelineTestHarness.epoch(at(0)) ?? 0])
        try addEvents("s1", minutes: [10, 3])
        try addEvents("s1", minutes: [20], type: "StatusLine")

        let second = try cache.activitySeconds(sessionId: "s1", database: database)
        XCTAssertEqual(
            second, [0, 3, 5, 10].map { UTCTimestamp.epochSeconds(at($0))! },
            "old rows are kept, a late out-of-order row is merged, ambient rows are skipped"
        )
    }

    func testCacheEvictsTheLeastRecentlyUsedSession() throws {
        for id in ["a", "b", "c"] { try seedSession(id, eventMinutes: [0]) }
        let cache = BillingActivityCache(capacity: 2)
        _ = try cache.activitySeconds(sessionId: "a", database: database)
        _ = try cache.activitySeconds(sessionId: "b", database: database)
        _ = try cache.activitySeconds(sessionId: "a", database: database)
        _ = try cache.activitySeconds(sessionId: "c", database: database)
        XCTAssertEqual(cache.count, 2)
        cache.forget(sessionId: "a")
        XCTAssertEqual(cache.count, 1)
    }

    /// Which session went, observed: with its events deleted, a cached
    /// session still answers from memory and an evicted one reads nothing.
    func testTheEvictedSessionIsTheLeastRecentlyUsedOne() throws {
        for id in ["a", "b", "c"] { try seedSession(id, eventMinutes: [0]) }
        let cache = BillingActivityCache(capacity: 2)
        XCTAssertEqual(cache.capacity, 2)
        _ = try cache.activitySeconds(sessionId: "a", database: database)
        _ = try cache.activitySeconds(sessionId: "b", database: database)
        _ = try cache.activitySeconds(sessionId: "a", database: database)
        _ = try cache.activitySeconds(sessionId: "c", database: database)
        // Trimming every row is not a rebuilt store: the id high-water mark
        // stays where it was, so the cursors hold and "a" keeps its seconds.
        try harness.deleteEvents()

        XCTAssertEqual(try cache.activitySeconds(sessionId: "a", database: database).count, 1, "a was kept")
        XCTAssertEqual(try cache.activitySeconds(sessionId: "b", database: database), [], "b was evicted")
    }

    /// A store rebuilt under the cache numbers its rows from 1 again, below the
    /// cursor. Reading only "past the cursor" would then skip every new row;
    /// instead the session is read in full and replaces what was held.
    func testACursorAboveTheStoresIdHighWaterStartsTheSessionOver() throws {
        try seedSession("s1", eventMinutes: [0, 5, 10])
        let cache = BillingActivityCache()
        XCTAssertEqual(try cache.activitySeconds(sessionId: "s1", database: database).count, 3)

        try harness.rebuildEventIds()
        try addEvents("s1", minutes: [20])

        XCTAssertEqual(
            try cache.activitySeconds(sessionId: "s1", database: database),
            [UTCTimestamp.epochSeconds(at(20))!],
            "the rebuilt store's row is read, and the vanished ones are dropped")
        let direct = try database.billingActivitySeconds(sessionId: "s1", afterId: 3)
        XCTAssertEqual(direct.lastId, 1, "a cursor below the one asked from says the read started over")
    }

    /// A transcript line with no timestamp is kept at about epoch 0 ("time
    /// unknown"). It is never where a session's history starts, nor billed work.
    func testAnEventWithoutAKnownTimeIsNeitherHistoryStartNorActivity() throws {
        try seedSession("s1", eventMinutes: [5])
        try harness.seed(sessionId: "s1", type: "summary", timestamp: "1970-01-01T00:00:00Z")

        XCTAssertEqual(
            try database.billingHistoryStart(sessionId: "s1", sessionStartedAt: at(0)), at(5),
            "the epoch-0 row does not pull the start back to 1970")
        XCTAssertEqual(
            try database.billingActivitySeconds(sessionId: "s1").seconds, [UTCTimestamp.epochSeconds(at(5))!])
        XCTAssertEqual(
            try BillingActivityCache().activitySeconds(sessionId: "s1", database: database),
            [UTCTimestamp.epochSeconds(at(5))!])
    }

    /// Derivation fed from the cache, pass after pass, lands exactly where a
    /// single full derivation over the same events does.
    func testIncrementalDerivationMatchesAFullDerivation() throws {
        try seedSession("s1", eventMinutes: [0, 5, 10])
        let cache = BillingActivityCache()
        let derive = { (now: Int) in
            _ = try BillingStore.deriveSegments(
                for: try self.row("s1"), cutoffSeconds: 900,
                now: self.at(now), database: self.database, activity: cache
            )
        }
        try derive(12)
        try addEvents("s1", minutes: [40, 44])
        try derive(46)
        try addEvents("s1", minutes: [50, 90])
        try database.execute("UPDATE sessions SET status = 'ended' WHERE session_id = 's1'")
        try derive(200)
        let incremental = try database.billingSegments(since: "", limit: 100)
            .map { [$0.startedAt, $0.endedAt, String($0.seconds)] }

        try database.execute("DELETE FROM billing_segment")
        try database.markBillingDerived(sessionId: "s1", at: "")
        _ = try BillingStore.deriveSegments(
            for: try row("s1"), cutoffSeconds: 900,
            now: at(200), database: database
        )
        let full = try database.billingSegments(since: "", limit: 100)
            .map { [$0.startedAt, $0.endedAt, String($0.seconds)] }

        XCTAssertEqual(incremental.sorted { $0[0] < $1[0] }, full.sorted { $0[0] < $1[0] })
        XCTAssertEqual(full.count, 3)
    }

    // MARK: - No-op rewrite

    /// A pass that finds nothing new writes nothing: no delete-and-reinsert,
    /// so `updated_at` and the segment's link to its entry survive.
    func testRederivingUnchangedActivityWritesNothing() throws {
        try seedSession("s1", status: "ended", eventMinutes: [0, 5, 10])
        let first = try BillingStore.deriveSegments(
            for: try row("s1"), cutoffSeconds: 900, now: at(600), database: database
        )
        XCTAssertEqual(first, 1)
        let before = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        try database.execute("UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [before.id])

        try database.markBillingDerived(sessionId: "s1", at: "")
        let second = try BillingStore.deriveSegments(
            for: try row("s1"), cutoffSeconds: 900, now: at(600), database: database
        )
        XCTAssertEqual(second, 0)
        let after = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(after.updatedAt, before.updatedAt)
        XCTAssertEqual(after.entryId, "e1")
    }
}
