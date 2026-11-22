import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The billing half of the session upsert: an event OLDER than the session's
/// clock (a recovered quarantine burst) forgets the derivation watermark so the
/// session is queued for one re-derivation. Newer and ambient events leave it.
final class BillingWatermarkReplayTests: XCTestCase {

    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-replay-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-replay.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    private func ingest(_ type: String, at timestamp: String) throws {
        try database.ingestEvent(
            eventType: type, timestamp: timestamp,
            hookData: ["session_id": "replay", "cwd": "/tmp/replay"]
        )
    }

    private func markDerived() throws {
        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
    }

    func testAReplayedOlderEventClearsTheBillingWatermark() throws {
        try ingest("PreToolUse", at: "2026-06-01T12:00:00Z")
        try markDerived()

        try ingest("PreToolUse", at: "2026-06-01T11:00:00Z")

        var stored: [String] = []
        try database.query(
            "SELECT billing_derived_at FROM sessions WHERE session_id = 'replay'"
        ) { row in
            stored.append(row["billing_derived_at"] ?? "<null>")
        }
        XCTAssertEqual(stored, [""], "the replay forgets the watermark by blanking it")
        XCTAssertEqual(
            try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["replay"]
        )
    }

    func testANewerEventLeavesTheWatermarkToTheNormalClock() throws {
        try ingest("PreToolUse", at: "2026-06-01T12:00:00Z")
        try markDerived()

        try ingest("PreToolUse", at: "2026-06-01T12:30:00Z")

        // Queued because the clock moved past the watermark, not because it was forgotten.
        XCTAssertEqual(
            try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["replay"]
        )
        try markDerived()
        try ingest("PreToolUse", at: "2026-06-01T12:30:00Z")
        XCTAssertTrue(
            try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty,
            "an event at exactly the session's clock is not a replay"
        )
    }

    func testAnAmbientEventNeverTouchesTheWatermark() throws {
        let ambient = try XCTUnwrap(HookEventType.ambientEventTypes.sorted().first)
        try ingest("PreToolUse", at: "2026-06-01T12:00:00Z")
        try markDerived()

        try ingest(ambient, at: "2026-06-01T10:00:00Z")

        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
    }
}
