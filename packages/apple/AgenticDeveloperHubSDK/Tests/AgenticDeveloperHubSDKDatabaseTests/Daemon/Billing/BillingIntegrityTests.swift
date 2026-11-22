import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// Billed time must neither vanish nor be billed twice, whatever happens to
/// the events it was derived from or the rows around it. Each test here pins
/// one way it used to: retention trimming history, deleting an owner with a
/// billed supplement, time tracked while tracking was off, a late event that
/// never re-derived, a rewrite that detached rolled time, and so on.
final class BillingIntegrityTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-integrity-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-integrity.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
    }

    override func tearDownWithError() throws {
        harness = nil
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    private let options = BillingRollupOptions(granularity: .day, defaultRateCents: 0, currency: "USD")

    @discardableResult
    private func makeProject(
        name: String = "P", clientId: String? = nil, enabled: Bool = true
    ) throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(
                id: "", clientId: clientId, name: name, defaultRateCents: 10_000, billingEnabled: enabled
            ),
            database: database
        )
    }

    @discardableResult
    private func mapRepo(to project: BillingProjectDTO, root: String = "/src/app") throws -> BillingRepoDTO {
        try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: root), database: database
        )
    }

    private func seedSession(_ sessionId: String, eventMinutes: [Int], root: String = "/src/app") throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status, git_branch, project_root)
            VALUES (?, ?, ?, ?, 'ended', 'main', ?)
        """, params: [sessionId, root, at(0), at(eventMinutes.last ?? 0), root])
        try addEvents(sessionId, minutes: eventMinutes, root: root)
    }

    private func addEvents(_ sessionId: String, minutes: [Int], root: String = "/src/app") throws {
        for minute in minutes {
            try harness.seed(sessionId: sessionId, type: "PreToolUse", timestamp: at(minute), cwd: root)
        }
        try database.execute(
            "UPDATE sessions SET last_activity_at = MAX(last_activity_at, ?) WHERE session_id = ?",
            params: [at(minutes.max() ?? 0), sessionId]
        )
    }

    /// One event every ten minutes from `start` through `end`: one run.
    private func span(_ start: Int, _ end: Int) -> [Int] {
        Array(stride(from: start, through: end, by: 10))
    }

    private func at(_ minutes: Int) -> String {
        let total = 9 * 3600 + minutes * 60
        return String(format: "2026-09-22T%02d:%02d:00Z", total / 3600, (total % 3600) / 60)
    }

    /// Forces one session through derivation, the way a new event does.
    private func rederive(_ sessionId: String = "s1") throws {
        try database.markBillingDerived(sessionId: sessionId, at: "")
        let row = try XCTUnwrap(
            database.sessionsNeedingBillingDerivation(limit: 50).first { $0.sessionId == sessionId }
        )
        _ = try BillingStore.deriveSegments(for: row, cutoffSeconds: 900, now: at(600), database: database)
    }

    private func entries() throws -> [BillingEntryDTO] {
        try database.billingEntries(projectId: nil, status: nil, since: "")
    }

    private func segments(_ sessionId: String = "s1") throws -> [BillingSegmentDTO] {
        try database.billingSegments(since: "", limit: 100)
            .filter { $0.sessionId == sessionId }
            .sorted { $0.startedAt < $1.startedAt }
    }

    private func rowid(ofSegment id: String) throws -> Int64 {
        var value: Int64 = -1
        try database.query("SELECT rowid FROM billing_segment WHERE id = ?", params: [id]) { row in
            value = row[0] ?? -1
        }
        return value
    }

    // MARK: - V3-c: retention trims a session's early events

    /// Retention deleted the events the first run was derived from. A full
    /// re-read derives only the second run; the first run's segment, and the
    /// unbilled entry holding it, must survive rather than silently vanish.
    func testTrimmedHistoryKeepsTheTimeAlreadyDerivedFromIt() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: [0, 5, 100, 105])
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try segments().count, 2)
        XCTAssertEqual(try entries().first?.rawSeconds, 600)

        try harness.deleteEvents(
            where: "session_id = 's1' AND time IN (?, ?)",
            arguments: [ClaudePipelineTestHarness.epoch(at(0)) ?? 0, ClaudePipelineTestHarness.epoch(at(5)) ?? 0]
        )
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try segments().map(\.startedAt), [at(0), at(100)], "the trimmed run's segment stays")
        XCTAssertEqual(try entries().map(\.rawSeconds), [600], "and so does its billable time")
    }

    /// The trim took every event of the session. Nothing is left to re-derive
    /// from, so a re-derivation (a cutoff change, a remap) keeps every closed
    /// segment and the billable time they hold, rather than deleting them.
    func testATrimOfEveryEventKeepsAllTheTimeAlreadyDerived() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: [0, 5, 100, 105])
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 600)

        try harness.deleteEvents(where: "session_id = 's1'")
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try segments().map(\.startedAt), [at(0), at(100)], "both segments stay")
        XCTAssertEqual(try entries().map(\.rawSeconds), [600], "and so does their billable time")
    }

    // MARK: - V1-a: deleting an owner with a billed supplement

    func testAnEntryWithABilledSupplementCannotBeDeleted() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let ownerId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(entryId: ownerId, to: .billed, source: "user", database: database)

        try seedSession("s2", eventMinutes: span(200, 220))
        try rederive("s2")
        _ = try BillingRollup.run(options: options, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == ownerId })
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)

        _ = try BillingRollup.setStatus(entryId: ownerId, to: .unbilled, source: "user", database: database)
        XCTAssertThrowsError(try BillingRollup.deleteEntry(id: ownerId, database: database)) { error in
            guard case BillingRollup.RollupError.entryHasFrozenSupplements(_, let count) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(count, 1)
        }
        XCTAssertNotNil(try database.billingEntry(id: ownerId))
        XCTAssertEqual(try database.billingEntry(id: supplement.id)?.status, BillingStatus.billed.rawValue,
                       "invoiced time stays invoiced")
    }

    // MARK: - V1-b: an emptied owner that a billed supplement points at

    func testAnEmptiedOwnerWithABilledSupplementStaysAtZero() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let ownerId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(entryId: ownerId, to: .billed, source: "user", database: database)
        try seedSession("s2", eventMinutes: span(200, 220))
        try rederive("s2")
        _ = try BillingRollup.run(options: options, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == ownerId })
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: ownerId, to: .unbilled, source: "user", database: database)

        // Re-derivation moved the owner's time elsewhere.
        try database.execute(
            "UPDATE billing_segment SET entry_id = NULL, project_id = NULL WHERE entry_id = ?", params: [ownerId]
        )
        _ = try BillingRollup.recomputeOwnedEntries(database: database)

        let owner = try XCTUnwrap(database.billingEntry(id: ownerId), "the supplement's parent must still exist")
        XCTAssertEqual(owner.rawSeconds, 0)
        XCTAssertEqual(owner.amountCents, 0)
        XCTAssertEqual(try database.billingEntry(id: supplement.id)?.supplementsEntryId, ownerId)
    }

    // MARK: - V10-a: time worked while Track Time was off

    func testTimeWorkedWhileTrackingWasOffIsNotBilledWhenItIsTurnedBackOn() throws {
        let project = try makeProject(enabled: false)
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        let offSegment = try XCTUnwrap(segments().first)
        XCTAssertTrue(offSegment.flags.contains(DaemonDatabase.untrackedFlag))

        _ = try BillingStore.saveProject(
            BillingProjectDTO(
                id: project.id, name: project.name, defaultRateCents: 10_000, billingEnabled: true
            ),
            database: database
        )
        try addEvents("s1", minutes: [62])
        try rederive()
        XCTAssertTrue(try XCTUnwrap(segments().first).flags.contains(DaemonDatabase.untrackedFlag),
                      "re-derivation keeps the off-period untracked")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertTrue(try entries().isEmpty, "the off-period is not billed after tracking is turned back on")

        // Time worked after the switch is tracked as usual.
        try seedSession("s2", eventMinutes: span(300, 330))
        try rederive("s2")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().map(\.rawSeconds), [1800])

        // A hand assignment is the user choosing to bill it after all.
        XCTAssertEqual(try BillingRollup.assignSegments(ids: [offSegment.id], projectId: project.id,
                                                        database: database), 1)
        let assigned = try XCTUnwrap(database.billingSegment(id: offSegment.id))
        XCTAssertFalse(assigned.flags.contains(DaemonDatabase.untrackedFlag))
        XCTAssertTrue(assigned.flags.contains(DaemonDatabase.assignedFlag))
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().map(\.rawSeconds), [1800 + 3720])
    }

    // MARK: - V3-d: a late, older event on an ended session

    func testALateOlderEventReselectsAnEndedDerivedSession() throws {
        for stamp in ["2026-09-22T10:00:00Z", "2026-09-22T12:10:00Z"] {
            _ = try database.ingestEvent(
                eventType: "PreToolUse", timestamp: stamp, hookData: ["session_id": "s1", "cwd": "/src/app"]
            )
        }
        try database.execute("UPDATE sessions SET status = 'ended' WHERE session_id = 's1'")
        // Ingest stores its own form of the stamp; the pass stamps that.
        var stamp = ""
        try database.query("SELECT last_activity_at FROM sessions WHERE session_id = 's1'") { row in
            stamp = row["last_activity_at"] ?? ""
        }
        try database.markBillingDerived(sessionId: "s1", at: stamp)
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 50).isEmpty)

        // A quarantined burst is recovered after the session ended.
        _ = try database.ingestEvent(
            eventType: "PreToolUse", timestamp: "2026-09-22T11:00:00Z",
            hookData: ["session_id": "s1", "cwd": "/src/app"]
        )
        XCTAssertEqual(try database.sessionsNeedingBillingDerivation(limit: 50).map(\.sessionId), ["s1"],
                       "recovered work is derived, not lost")
    }

    // MARK: - V22-b / V25-d: a later run closing leaves rolled time alone

    /// A later run closing used to delete and re-insert every segment of the
    /// session with its entry cleared, so a status change landing before the
    /// re-roll sent the same time to a supplement. An unchanged run is now
    /// not rewritten at all.
    func testALaterRunClosingLeavesAnUnchangedRolledRunUntouched() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try database.execute("UPDATE sessions SET status = 'active' WHERE session_id = 's1'")
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let rolled = try XCTUnwrap(segments().first)
        let entryId = try XCTUnwrap(rolled.entryId)
        let rowidBefore = try rowid(ofSegment: rolled.id)
        // A marker no rewrite can reproduce: the wall clock stamps updated_at.
        let untouched = "2000-01-01T00:00:00Z"
        try database.execute(
            "UPDATE billing_segment SET updated_at = ? WHERE id = ?", params: [untouched, rolled.id]
        )

        try addEvents("s1", minutes: span(200, 230))
        try rederive()
        let after = try XCTUnwrap(database.billingSegment(id: rolled.id))
        XCTAssertEqual(after.entryId, entryId, "still attached before any roll runs")
        XCTAssertEqual(after.updatedAt, untouched, "not rewritten")
        XCTAssertEqual(try rowid(ofSegment: rolled.id), rowidBefore, "not deleted and re-inserted")

        // The user bills the day before the pass's roll runs.
        _ = try BillingRollup.setStatus(entryId: entryId, to: .billed, source: "user", database: database)
        _ = try BillingRollup.run(options: options, database: database)
        let supplements = try entries().filter { $0.supplementsEntryId == entryId }
        XCTAssertEqual(supplements.map(\.rawSeconds), [1800], "only the new run is supplemental, never the billed hour")
    }

    // MARK: - V1-c / V20-d: deleting a client with billed entries

    func testAClientWithABilledEntryCannotBeDeleted() throws {
        let client = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Acme"), database: database)
        let project = try makeProject(clientId: client.id)
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        XCTAssertEqual(entry.clientId, client.id)
        _ = try BillingRollup.setStatus(entryId: entry.id, to: .paid, source: "user", database: database)

        XCTAssertThrowsError(try BillingStore.deleteClient(id: client.id, database: database)) { error in
            guard case BillingStore.BillingError.clientHasBilledEntries(_, let count) = error else {
                return XCTFail("wrong error: \(error)")
            }
            XCTAssertEqual(count, 1)
        }
        XCTAssertNotNil(try database.billingClient(id: client.id))
        XCTAssertEqual(try database.billingEntry(id: entry.id)?.clientId, client.id,
                       "a paid entry keeps who it was billed to")
    }

    func testAClientWithOnlyUnbilledEntriesIsStillDeletable() throws {
        let client = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Acme"), database: database)
        let project = try makeProject(clientId: client.id)
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)

        try BillingStore.deleteClient(id: client.id, database: database)
        XCTAssertNil(try database.billingClient(id: client.id))
        XCTAssertNil(try entries().first?.clientId)
    }

    // MARK: - V20-e: locked follows status in the database

    func testADirectStatusChangeKeepsLockedInStep() throws {
        let project = try makeProject()
        try mapRepo(to: project)
        try seedSession("s1", eventMinutes: span(0, 60))
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let id = try XCTUnwrap(entries().first?.id)

        try database.execute("UPDATE billing_entry SET status = 'billed' WHERE id = ?", params: [id])
        XCTAssertEqual(try database.billingEntry(id: id)?.locked, true, "a billed row is protected")
        try database.execute("UPDATE billing_entry SET locked = 0 WHERE id = ?", params: [id])
        XCTAssertEqual(try database.billingEntry(id: id)?.locked, true, "and cannot be unprotected by hand")
        try database.execute("UPDATE billing_entry SET status = 'unbilled' WHERE id = ?", params: [id])
        XCTAssertEqual(try database.billingEntry(id: id)?.locked, false)
    }

    // MARK: - V7-a: description order is stable

    func testSessionTitlesAreNewestStartedFirstAndStable() throws {
        let rows: [(String, String, String, String)] = [
            ("s-a", "Fix auth", "2026-09-22T10:00:00Z", "2026-09-22T10:30:00Z"),
            ("s-b", "Refactor", "2026-09-22T11:00:00Z", "2026-09-22T11:30:00Z"),
            ("s-c", "Fix auth", "2026-09-22T12:00:00Z", "2026-09-22T12:30:00Z")
        ]
        for (id, title, started, last) in rows {
            try database.execute("""
                INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status, transcript_title)
                VALUES (?, '/src/app', ?, ?, 'active', ?)
            """, params: [id, started, last, title])
        }
        let ids = rows.map(\.0)
        XCTAssertEqual(try database.billingSessionTitles(sessionIds: ids).titles, ["Fix auth", "Refactor"])

        // Sessions taking turns being most recent must not reorder the words.
        try database.execute(
            "UPDATE sessions SET last_activity_at = '2026-09-23T09:00:00Z' WHERE session_id = 's-b'"
        )
        XCTAssertEqual(try database.billingSessionTitles(sessionIds: ids).titles, ["Fix auth", "Refactor"])
    }

    // MARK: - V25-c: selecting sessions seeks an index

    func testSelectingSessionsToDeriveDoesNotWalkEverySession() throws {
        var plan: [String] = []
        try database.query(
            "EXPLAIN QUERY PLAN " + DaemonDatabase.sessionsNeedingBillingDerivationSQL(excluding: 0),
            params: [50]
        ) { row in plan.append((row[3] as String?) ?? "") }

        XCTAssertTrue(plan.contains { $0.contains("idx_sessions_billing_pending") }, "\(plan)")
        XCTAssertFalse(
            plan.contains { $0.hasPrefix("SCAN sessions") && !$0.contains("idx_sessions_billing_pending") },
            "every pass would read every session: \(plan)"
        )
    }
}
