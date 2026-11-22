import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// CRUD is deliberately boring; what these tests defend is the derivation
/// write path — the one place a re-run could duplicate or destroy billable
/// time — and the referential rules that keep a delete from stranding rows.
final class BillingStoreTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!
    var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-store-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-store.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
    }

    override func tearDownWithError() throws {
        harness = nil
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeClient(name: String = "Acme") throws -> BillingClientDTO {
        try BillingStore.saveClient(
            BillingClientDTO(id: "", name: name), database: database
        )
    }

    @discardableResult
    private func makeProject(
        name: String = "Rewrite",
        clientId: String? = nil,
        rate: Int? = 15_000
    ) throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(id: "", clientId: clientId, name: name, defaultRateCents: rate),
            database: database
        )
    }

    @discardableResult
    private func makeRepo(
        projectId: String,
        root: String = "/src/app",
        branch: String = "",
        rate: Int? = nil
    ) throws -> BillingRepoDTO {
        try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: projectId, projectRoot: root, branch: branch, rateCents: rate),
            database: database
        )
    }

    /// Seeds a session plus activity events at the given minute offsets.
    private func seedSession(
        _ sessionId: String,
        root: String = "/src/app",
        branch: String = "main",
        status: String = "ended",
        startMinute: Int = 0,
        eventMinutes: [Int],
        eventType: String = "PreToolUse"
    ) throws {
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status, git_branch, project_root)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, params: [
            sessionId, root, at(startMinute), at(eventMinutes.last ?? startMinute), status, branch, root
        ])
        for minute in eventMinutes {
            try harness.seed(sessionId: sessionId, type: eventType, timestamp: at(minute), cwd: root)
        }
    }

    private func at(_ minutes: Int) -> String {
        let total = 14 * 3600 + minutes * 60
        return String(format: "2026-09-22T%02d:%02d:00Z", total / 3600, (total % 3600) / 60)
    }

    // MARK: - Clients

    func testSavingAClientAssignsAnIdAndReadsBack() throws {
        let saved = try makeClient(name: "Acme Ltd")
        XCTAssertFalse(saved.id.isEmpty, "an empty id means insert; the store assigns one")
        XCTAssertEqual(try database.billingClient(id: saved.id)?.name, "Acme Ltd")
        XCTAssertEqual(try database.billingClients(includeArchived: false).count, 1)
    }

    func testSavingAnExistingClientUpdatesInPlace() throws {
        let saved = try makeClient()
        let edited = BillingClientDTO(id: saved.id, name: "Acme Ltd", email: "ap@acme.test")
        _ = try BillingStore.saveClient(edited, database: database)
        XCTAssertEqual(try database.billingClients(includeArchived: false).count, 1, "update, not insert")
        XCTAssertEqual(try database.billingClient(id: saved.id)?.email, "ap@acme.test")
    }

    func testAClientNeedsAName() throws {
        XCTAssertThrowsError(try BillingStore.saveClient(BillingClientDTO(id: "", name: "  "), database: database))
    }

    func testArchivedClientsAreHiddenByDefault() throws {
        let saved = try makeClient()
        _ = try BillingStore.saveClient(
            BillingClientDTO(id: saved.id, name: saved.name, archived: true), database: database
        )
        XCTAssertTrue(try database.billingClients(includeArchived: false).isEmpty)
        XCTAssertEqual(try database.billingClients(includeArchived: true).count, 1)
    }

    /// Deleting a client must not orphan its projects into a dangling id.
    func testDeletingAClientDetachesItsProjects() throws {
        let client = try makeClient()
        let project = try makeProject(clientId: client.id)
        try BillingStore.deleteClient(id: client.id, database: database)
        XCTAssertNil(try database.billingProject(id: project.id)?.clientId)
    }

    // MARK: - Projects and repos

    func testAProjectRejectsANonPositiveRoundingInterval() throws {
        let bad = BillingProjectDTO(id: "", name: "P", roundingMinutes: 0)
        XCTAssertThrowsError(try BillingStore.saveProject(bad, database: database))
    }

    func testARepoNeedsAProjectThatExists() throws {
        let orphan = BillingRepoDTO(id: "", projectId: "nope", projectRoot: "/src/app")
        XCTAssertThrowsError(try BillingStore.saveRepo(orphan, database: database))
    }

    func testARepoNeedsARoot() throws {
        let project = try makeProject()
        XCTAssertThrowsError(
            try BillingStore.saveRepo(
                BillingRepoDTO(id: "", projectId: project.id, projectRoot: ""), database: database
            )
        )
    }

    /// `UNIQUE(project_root, branch)` is what makes rate resolution
    /// deterministic; claiming a pair twice must fail loudly, not silently
    /// reassign the repo to whichever project saved last.
    func testTwoProjectsCannotClaimTheSameRootAndBranch() throws {
        let first = try makeProject(name: "First")
        let second = try makeProject(name: "Second")
        _ = try makeRepo(projectId: first.id, root: "/src/app", branch: "main")
        XCTAssertThrowsError(try makeRepo(projectId: second.id, root: "/src/app", branch: "main"))
    }

    func testDeletingAProjectDeletesItsRepos() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id)
        try BillingStore.deleteProject(id: project.id, database: database)
        XCTAssertTrue(try database.billingRepos(projectId: nil).isEmpty)
    }

    /// `billing_entry.project_id` is `NOT NULL`; there is no "unassigned" to
    /// fall back to the way a segment has. A project with any entry at all —
    /// whatever its status — must refuse deletion rather than strand one.
    func testDeletingAProjectWithABillingEntryIsRefused() throws {
        let project = try makeProject()
        try database.execute(
            "INSERT INTO billing_entry (id, project_id, day, raw_seconds) VALUES ('e1', ?, '2026-09-22', 60)",
            params: [project.id]
        )

        XCTAssertThrowsError(try BillingStore.deleteProject(id: project.id, database: database)) { error in
            guard case BillingStore.BillingError.projectHasEntries = error else {
                return XCTFail("expected .projectHasEntries, got \(error)")
            }
        }
        XCTAssertNotNil(try database.billingProject(id: project.id), "the project survives the refusal")
        var entryCount = 0
        try database.query("SELECT COUNT(*) FROM billing_entry WHERE id = 'e1'") { row in
            entryCount = row[0] ?? 0
        }
        XCTAssertEqual(entryCount, 1, "the entry survives too")
    }

    /// Review 5, item 4: an auto entry the rollup left owning nothing is not
    /// listed, so it must not block deleting its project either — it goes
    /// with the project, and the segment it held falls back to unassigned.
    /// One the user can see (hand-described) or that a supplement points at
    /// still refuses.
    func testDeletingAProjectWhoseOnlyEntriesAreHiddenEmptyRowsSucceeds() throws {
        let project = try makeProject()
        try database.execute(
            "INSERT INTO billing_entry (id, project_id, day) VALUES ('hidden', ?, '2026-09-22')",
            params: [project.id]
        )
        try database.execute("""
            INSERT INTO billing_segment (id, origin, project_id, started_at, ended_at, seconds, entry_id)
            VALUES ('s1', 'auto', ?, '2026-09-22T09:00:00Z', '2026-09-22T09:10:00Z', 600, 'hidden')
        """, params: [project.id])

        try BillingStore.deleteProject(id: project.id, database: database)

        XCTAssertNil(try database.billingProject(id: project.id))
        XCTAssertNil(try database.billingEntry(id: "hidden"), "the hidden row goes with its project")
        var detached = false
        try database.query("SELECT entry_id, project_id FROM billing_segment WHERE id = 's1'") { row in
            let entry: String? = row["entry_id"]
            let project: String? = row["project_id"]
            detached = entry == nil && project == nil
        }
        XCTAssertTrue(detached, "the segment it held is unassigned, not stranded")
    }

    func testAHiddenEntryTheUserDescribedOrASupplementFollowsStillBlocksTheDelete() throws {
        for blocker in ["described", "supplemented"] {
            let project = try makeProject(name: blocker)
            let described = blocker == "described" ? 1 : 0
            try database.execute("""
                INSERT INTO billing_entry (id, project_id, day, description_edited)
                VALUES (?, ?, '2026-09-22', ?)
            """, params: ["root-\(blocker)", project.id, described])
            if blocker == "supplemented" {
                // A supplement the window shows: one with time in it.
                try database.execute("""
                    INSERT INTO billing_entry (id, project_id, day, supplements_entry_id, raw_seconds)
                    VALUES ('sup', ?, '2026-09-22', 'root-supplemented', 600)
                """, params: [project.id])
            }
            XCTAssertThrowsError(try BillingStore.deleteProject(id: project.id, database: database), blocker)
            XCTAssertNotNil(try database.billingEntry(id: "root-\(blocker)"), blocker)
        }
    }

    /// Review F39/F50: the delete guard counts exactly the rows the Projects
    /// window lists. A hidden root that only a hidden supplement points at is
    /// listed by neither, so it no longer blocks the delete; both go.
    func testTheEntryCountIsTheListedRows() throws {
        let project = try makeProject()
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day) VALUES ('root', ?, '2026-09-22')
        """, params: [project.id])
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, supplements_entry_id)
            VALUES ('sup', ?, '2026-09-22', 'root')
        """, params: [project.id])
        let listed = try database.billingEntries(projectId: project.id, status: nil, since: "").count
        XCTAssertEqual(listed, 0)
        XCTAssertEqual(try database.billingEntryCount(projectId: project.id), listed)

        try BillingStore.deleteProject(id: project.id, database: database)
        XCTAssertNil(try database.billingEntry(id: "root"))
        XCTAssertNil(try database.billingEntry(id: "sup"))
    }

    /// Review F45: the first pass settles only the days settling can change —
    /// one with an unfrozen entry, or a frozen entry holding a segment its
    /// recorded ranges do not cover — never an all-frozen, fully covered day.
    func testUnsettledDaysSkipFrozenDaysTheirRangesCover() throws {
        let project = try makeProject()
        let nine = try XCTUnwrap(UTCTimestamp.epochSeconds("2026-09-20T09:00:00Z"))
        func frozen(_ id: String, day: String, ranges: String) throws {
            try database.execute("""
                INSERT INTO billing_entry (id, project_id, day, locked, status, billed_ranges)
                VALUES (?, ?, ?, 1, 'billed', ?)
            """, params: [id, project.id, day, ranges])
        }
        func held(by entryId: String, start: String, seconds: Int) throws {
            try database.execute("""
                INSERT INTO billing_segment (id, origin, project_id, started_at, ended_at, seconds, entry_id)
                VALUES (?, 'auto', ?, ?, ?, ?, ?)
            """, params: [UUID().uuidString, project.id, start,
                          UTCTimestamp.string(epochSeconds: (UTCTimestamp.epochSeconds(start) ?? 0) + seconds),
                          seconds, entryId])
        }
        let covered = "\(nine)-\(nine + 3600)"
        try frozen("covered", day: "2026-09-20", ranges: covered)
        try held(by: "covered", start: "2026-09-20T09:00:00Z", seconds: 3600)
        try frozen("orphaned", day: "2026-09-21", ranges: "\(nine + 86_400)-\(nine + 86_400 + 1800)")
        try held(by: "orphaned", start: "2026-09-21T09:00:00Z", seconds: 3600)
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day) VALUES ('open', ?, '2026-09-22')
        """, params: [project.id])

        XCTAssertEqual(try database.billingUnsettledDays().map(\.day), ["2026-09-21", "2026-09-22"])
    }

    /// A frozen entry is found by its recorded ranges, wherever its shown
    /// times lie: one whose ranges start before the window and run into it is
    /// reached through the longest-span lookback; one ending as the window
    /// opens, or starting as it closes, is not.
    func testAFrozenEntryIsFoundByRangesThatStartBeforeTheWindow() throws {
        let project = try makeProject()
        let nine = try XCTUnwrap(UTCTimestamp.epochSeconds("2026-09-22T09:00:00Z"))
        // One entry per project, day and group: each takes its own group.
        func frozen(_ id: String, ranges: String) throws {
            try database.execute("""
                INSERT INTO billing_entry (id, project_id, day, group_key, started_at, ended_at, locked, status,
                                           billed_ranges)
                VALUES (?, ?, '2026-09-25', ?, '2026-09-25T09:00:00Z', '2026-09-25T10:00:00Z', 1, 'billed', ?)
            """, params: [id, project.id, id, ranges])
        }
        // Starts six hours before the window and crosses into it.
        try frozen("long", ranges: "\(nine - 21_600)-\(nine - 18_000);\(nine - 600)-\(nine + 600)")
        try frozen("before", ranges: "\(nine - 1800)-\(nine)")
        try frozen("after", ranges: "\(nine + 3600)-\(nine + 5400)")

        let found = try database.billingEntriesOverlapping(
            projectId: project.id, from: "2026-09-22T09:00:00Z", until: "2026-09-22T10:00:00Z"
        ).map(\.entry.id)
        XCTAssertEqual(found, ["long"])
    }

    /// The frozen lookback is one seek off the end of its span index, not a
    /// read of the project's frozen entries (re-check of review F5).
    func testTheLongestFrozenSpanIsReadOffItsIndex() throws {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + DaemonDatabase.longestFrozenSpanSQL, params: ["p"]) { row in
            plan.append(row["detail"] ?? "")
        }
        let text = plan.joined(separator: "\n")
        XCTAssertTrue(text.contains("idx_billing_entry_project_billed_span (project_id=?)"), text)
        XCTAssertFalse(text.contains("TEMP B-TREE"), text)
    }

    /// Review 5, item 2: the overlap read behind every settle seeks one
    /// project's entries and segments by start through their indexes rather
    /// than reading the whole project (or every project's segments).
    func testTheOverlapQueryIsServedByIndexes() throws {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + DaemonDatabase.billingEntriesOverlappingSQL, params: [
            "p", "2026-09-15T00:00:00Z", "2026-09-23T00:00:00Z", "2026-09-22T00:00:00Z",
            "p", "2026-09-15T00:00:00Z", "2026-09-23T00:00:00Z", "2026-09-22T00:00:00Z",
            "p", 1_790_000_000, 1_789_900_000,
            "p", 1_789_900_000, 1_790_000_000, 1_790_000_000, 1_789_900_000,
            "p", "p"
        ]) { row in plan.append(row["detail"] ?? "") }
        let text = plan.joined(separator: "\n")
        let range = "(project_id=? AND started_at>? AND started_at<?)"
        XCTAssertTrue(text.contains("idx_billing_entry_project_started \(range)"), text)
        XCTAssertTrue(text.contains("idx_billing_segment_project_started \(range)"), text)
        XCTAssertTrue(text.contains("idx_billing_entry_project_started (project_id=? AND started_at=?)"), text)
        XCTAssertTrue(text.contains("idx_billing_entry_project_billed_start (project_id=? AND <expr>>? AND <expr><?)"),
                      text)
        XCTAssertTrue(text.contains("idx_billing_entry_supplements"), text)
        XCTAssertFalse(text.contains("idx_billing_entry_project_day_all"), text)
        XCTAssertFalse(plan.contains {
            $0.hasPrefix("SCAN e") || $0.hasPrefix("SCAN s") || $0.hasPrefix("SCAN billing_")
        }, text)
    }

    func testRateResolutionReadsThroughTheDatabase() throws {
        let project = try makeProject(rate: 15_000)
        let branchRow = try makeRepo(projectId: project.id, root: "/src/app", branch: "release", rate: 20_000)
        let anyBranch = try makeRepo(projectId: project.id, root: "/src/app", branch: "")

        let release = try BillingStore.resolveRate(
            projectRoot: "/src/app", branch: "release", database: database
        )
        XCTAssertEqual(release.repoId, branchRow.id, "the branch-specific repo wins")
        XCTAssertEqual(release.projectId, project.id)

        let other = try BillingStore.resolveRate(
            projectRoot: "/src/app", branch: "spike", database: database
        )
        XCTAssertEqual(other.repoId, anyBranch.id, "falls back to the wildcard repo")
        XCTAssertEqual(BillingRate.rateCents(
            repo: anyBranch, repos: try database.billingRepos(projectId: nil),
            project: project, globalDefaultRateCents: 0
        ), 15_000, "and through it to the project's rate")
    }

    // MARK: - Derivation persistence

    func testDerivationWritesSegmentsAndStampsTheWatermark() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 10])

        let written = try BillingStore.deriveSegments(
            for: try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first),
            cutoffSeconds: 900, now: at(600), database: database
        )
        XCTAssertEqual(written, 1)

        let segments = try database.billingSegments(since: "", limit: 100)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].projectId, project.id)
        XCTAssertEqual(segments[0].seconds, 600)
        XCTAssertEqual(segments[0].origin, "auto")
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty,
                      "the watermark stops it being re-derived with no new activity")
    }

    /// The whole reason segments are derived rather than driven: running twice
    /// over the same events must not double the billable time.
    func testRederivingIsIdempotent() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 10])

        for _ in 0..<3 {
            try database.markBillingDerived(sessionId: "s1", at: "")   // force a re-run
            let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
            _ = try BillingStore.deriveSegments(
                for: row, cutoffSeconds: 900, now: at(600), database: database
            )
        }
        XCTAssertEqual(try database.billingSegments(since: "", limit: 100).count, 1)
    }

    func testResettingDerivationQueuesOnlySessionsSinceTheCutoff() throws {
        try seedSession("recent", eventMinutes: [0, 5])
        try seedSession("ancient", eventMinutes: [0, 5])
        try database.execute(
            "UPDATE sessions SET last_activity_at = '2020-01-01T00:00:00Z' WHERE session_id = 'ancient'"
        )
        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)

        XCTAssertEqual(try database.resetBillingDerivation(since: "2025-01-01T00:00:00Z"), 1)
        XCTAssertEqual(
            try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["recent"]
        )
    }

    /// Later activity extends the same run rather than creating a second one,
    /// because the run is identified by its start instant.
    func testLateActivityExtendsTheSameSegment() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5])

        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        XCTAssertEqual(try database.billingSegments(since: "", limit: 100).first?.seconds, 300)

        try harness.seed(sessionId: "s1", type: "PreToolUse", timestamp: at(12))
        try database.execute(
            "UPDATE sessions SET last_activity_at = ? WHERE session_id = ?", params: [at(12), "s1"]
        )

        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        let segments = try database.billingSegments(since: "", limit: 100)
        XCTAssertEqual(segments.count, 1, "same start instant, same segment")
        XCTAssertEqual(segments[0].seconds, 720)
    }

    /// A segment already rolled into a locked (billed/paid) entry is history.
    /// Re-derivation must leave it untouched even if the raw events changed.
    func testRederivationLeavesSegmentsOnALockedEntryAlone() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5])

        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        let segmentId = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first?.id)

        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, status, locked) VALUES ('e1', ?, '2026-09-22', 'billed', 1)
        """, params: [project.id])
        try database.execute(
            "UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [segmentId]
        )

        try harness.deleteEvents(where: "session_id = 's1'")
        try database.markBillingDerived(sessionId: "s1", at: "")
        let again = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: again, cutoffSeconds: 900, now: at(600), database: database
        )

        let survivor = try database.billingSegment(id: segmentId)
        XCTAssertNotNil(survivor, "a billed segment is never deleted by re-derivation")
        XCTAssertEqual(survivor?.entryId, "e1")
    }

    /// A manual segment (a hand-entered timer, `origin = 'manual'`) is never
    /// touched by derivation at all — the delete-and-replace in
    /// `replaceDerivedSegments` only ever targets `origin = 'auto'` rows.
    func testReDerivationLeavesAManualSegmentByteForByteUnchanged() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5])

        let manual = BillingSegmentDTO(
            id: "manual-1", sessionId: "s1", origin: "manual", projectId: project.id,
            projectRoot: "/src/app", branch: "main", startedAt: at(100), endedAt: at(160),
            seconds: 3_600, note: "offline pairing session",
            createdAt: at(100), updatedAt: at(100)
        )
        try database.upsertBillingSegment(manual)

        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )

        let survivor = try XCTUnwrap(database.billingSegment(id: "manual-1"))
        XCTAssertEqual(survivor, manual, "a manual segment is never touched by derivation")
    }

    /// Raising the cutoff can merge a run that already has a locked segment
    /// with a later, still-unlocked run under the locked run's own start
    /// instant. Matching on `startedAt` alone would make the merged run
    /// collide with the lock and get skipped whole, silently losing the later
    /// run's time. Subtracting the locked interval instead must let the
    /// later time survive, starting exactly where the lock ends.
    func testCutoffIncreaseMergesALockedRunWithALaterUnlockedRun() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 20, 25])

        // Small cutoff: the 15-minute gap between minute 5 and minute 20
        // splits the activity into two separate runs.
        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 600, now: at(600), database: database
        )
        let early = try XCTUnwrap(
            try database.billingSegments(since: "", limit: 10).first { $0.startedAt == at(0) }
        )
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, status, locked)
            VALUES ('e1', ?, '2026-09-22', 'billed', 1)
        """, params: [project.id])
        try database.execute("UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [early.id])

        // Raise the cutoff past that gap: the two runs now derive as one,
        // starting at the locked run's own start instant.
        try database.markBillingDerived(sessionId: "s1", at: "")
        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 1_200, now: at(600), database: database
        )

        let segments = try database.billingSegments(since: "", limit: 10)
        XCTAssertEqual(segments.count, 2, "the lock plus one surviving remainder — never zero, never three")

        let lockedStillThere = try XCTUnwrap(database.billingSegment(id: early.id))
        XCTAssertEqual(lockedStillThere.startedAt, at(0))
        XCTAssertEqual(lockedStillThere.endedAt, at(5))
        XCTAssertEqual(lockedStillThere.seconds, 300, "untouched by re-derivation")

        let remainder = try XCTUnwrap(segments.first { $0.id != early.id })
        XCTAssertEqual(remainder.startedAt, at(5), "starts exactly where the locked segment ends")
        XCTAssertEqual(remainder.endedAt, at(25))
        XCTAssertEqual(remainder.seconds, 1_200, "the later run's time is not lost")
        XCTAssertNil(remainder.entryId, "not itself locked")
    }

    /// Lowering the cutoff can split a run that is already fully locked into
    /// pieces that no longer start at the lock's own start instant. Matching
    /// on `startedAt` alone would let the non-initial piece slip through as
    /// "new" unlocked time, double-billing it. Subtracting the locked
    /// interval from every piece must leave nothing behind.
    func testCutoffDecreaseSplitsALockedRunWithoutDoublingUnlockedSeconds() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 20, 25])

        // Big cutoff: the whole stretch derives as one run.
        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 1_200, now: at(600), database: database
        )
        let whole = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(whole.startedAt, at(0))
        XCTAssertEqual(whole.endedAt, at(25))
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, status, locked)
            VALUES ('e1', ?, '2026-09-22', 'billed', 1)
        """, params: [project.id])
        try database.execute("UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [whole.id])

        // Lower the cutoff below that gap: the same activity now derives as
        // two runs, both of them entirely inside the locked interval.
        try database.markBillingDerived(sessionId: "s1", at: "")
        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 600, now: at(600), database: database
        )

        let segments = try database.billingSegments(since: "", limit: 10)
        XCTAssertEqual(segments.count, 1, "no auto segment overlaps the locked interval")
        XCTAssertEqual(segments[0].id, whole.id)
        XCTAssertEqual(segments[0].seconds, 1_500, "the locked segment is untouched")

        let unlockedSeconds = segments.filter { $0.entryId != "e1" }.reduce(0) { $0 + $1.seconds }
        XCTAssertEqual(unlockedSeconds, 0, "nothing outside the locked interval happened, so nothing is billed")
    }

    /// Re-deriving again after either cutoff change must not duplicate or
    /// further mutate anything: the remainder computation is a pure function
    /// of the runs and the (unchanged) locked intervals.
    func testReDerivingAfterACutoffChangeStaysStable() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 20, 25])

        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 600, now: at(600), database: database
        )
        let early = try XCTUnwrap(
            try database.billingSegments(since: "", limit: 10).first { $0.startedAt == at(0) }
        )
        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, status, locked)
            VALUES ('e1', ?, '2026-09-22', 'billed', 1)
        """, params: [project.id])
        try database.execute("UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [early.id])

        try database.markBillingDerived(sessionId: "s1", at: "")
        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 1_200, now: at(600), database: database
        )
        let afterFirstMerge = try database.billingSegments(since: "", limit: 10)
            .sorted { $0.startedAt < $1.startedAt }

        // Re-derive again with the same (already-merged) cutoff and no new
        // activity, forcing the pass.
        try database.markBillingDerived(sessionId: "s1", at: "")
        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 1_200, now: at(600), database: database
        )
        let afterSecondPass = try database.billingSegments(since: "", limit: 10)
            .sorted { $0.startedAt < $1.startedAt }

        XCTAssertEqual(afterFirstMerge.count, afterSecondPass.count, "no duplicates")
        XCTAssertEqual(afterFirstMerge.map(\.startedAt), afterSecondPass.map(\.startedAt))
        XCTAssertEqual(afterFirstMerge.map(\.endedAt), afterSecondPass.map(\.endedAt))
        XCTAssertEqual(afterFirstMerge.map(\.seconds), afterSecondPass.map(\.seconds))
    }

    /// A protected (locked) auto segment can itself be zero-length —
    /// `started_at == ended_at` — when the run behind it was a single,
    /// isolated event. Subtracting `[t, t)` removes nothing, so a naive
    /// remainder would still start at exactly `t` and collide with the lock
    /// on `idx_billing_segment_auto_identity`. The fix nudges such a
    /// remainder one second later instead of throwing.
    func testARemainderStartingOnAZeroLengthLockedSegmentIsNudgedASecondLater() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0])

        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        let zeroLength = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(zeroLength.startedAt, zeroLength.endedAt, "a single-event run derives with zero length")

        try database.execute("""
            INSERT INTO billing_entry (id, project_id, day, status, locked)
            VALUES ('e1', ?, '2026-09-22', 'billed', 1)
        """, params: [project.id])
        try database.execute("UPDATE billing_segment SET entry_id = 'e1' WHERE id = ?", params: [zeroLength.id])

        // Activity resumes at that very same instant and continues past it.
        try harness.seed(sessionId: "s1", type: "PreToolUse", timestamp: at(5))
        try database.execute(
            "UPDATE sessions SET last_activity_at = ? WHERE session_id = ?", params: [at(5), "s1"]
        )
        try database.markBillingDerived(sessionId: "s1", at: "")

        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        XCTAssertNoThrow(
            try BillingStore.deriveSegments(
                for: row, cutoffSeconds: 900, now: at(600), database: database
            ),
            "the partial unique index must not be violated by a remainder starting on the lock"
        )

        let expectedStart = zeroLength.startedAt.replacingOccurrences(of: ":00Z", with: ":01Z")
        let segments = try database.billingSegments(since: "", limit: 10)
        XCTAssertEqual(segments.count, 2, "the lock plus one nudged remainder")
        XCTAssertEqual(try XCTUnwrap(database.billingSegment(id: zeroLength.id)).seconds, 0, "the lock is untouched")

        let remainder = try XCTUnwrap(segments.first { $0.id != zeroLength.id })
        XCTAssertEqual(remainder.startedAt, expectedStart, "nudged 1 second past the zero-length lock")
        XCTAssertEqual(remainder.seconds, UTCTimestamp.seconds(from: expectedStart, to: remainder.endedAt))

        // A second pass with no further changes must not duplicate or move anything.
        try database.markBillingDerived(sessionId: "s1", at: "")
        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        let again = try database.billingSegments(since: "", limit: 10)
        XCTAssertEqual(again.count, 2, "idempotent — no duplicates")
        XCTAssertEqual(again.first { $0.id != zeroLength.id }?.startedAt, expectedStart)
    }

    /// Ambient event types are noise, not work. A session with only
    /// `StatusLine` renders has done nothing billable.
    func testAmbientEventsAloneProduceNoSegments() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", eventMinutes: [0, 5, 10], eventType: "StatusLine")

        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        XCTAssertEqual(
            try BillingStore.deriveSegments(
                for: row, cutoffSeconds: 900, now: at(600), database: database
            ),
            0
        )
        XCTAssertTrue(try database.billingSegments(since: "", limit: 10).isEmpty)
    }

    /// An unmapped repo is tracked, not discarded — the time is real even
    /// though nobody has said whose it is.
    func testAnUnmappedRepoStillProducesAnUnassignedSegment() throws {
        try seedSession("s1", root: "/src/unknown", eventMinutes: [0, 10])
        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        let segment = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertNil(segment.projectId, "unassigned")
        XCTAssertEqual(segment.projectRoot, "/src/unknown", "but the root is kept so it can be assigned later")
        XCTAssertEqual(segment.seconds, 600)
    }

    /// A live session's tail run is stored open, and `runningBillingSegments`
    /// is how the UI finds it without scanning.
    func testALiveSessionLeavesARunningSegment() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", status: "active", eventMinutes: [0, 5])

        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(7), database: database
        )
        let running = try database.runningBillingSegments()
        XCTAssertEqual(running.count, 1)
        XCTAssertTrue(running[0].isRunning)
        XCTAssertEqual(running[0].seconds, 0, "an open run has no settled duration")
    }

    /// The forgotten-timer case. A session goes quiet and is later marked
    /// `ended` without emitting anything, so its watermark never moves — the
    /// open run must still close, and at its last real event, not at "now".
    func testAnAbandonedRunIsClosedOnTheNextPass() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id, root: "/src/app")
        try seedSession("s1", status: "active", eventMinutes: [0, 5])

        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(7), database: database
        )
        XCTAssertEqual(try database.runningBillingSegments().count, 1)

        // Nothing new arrives; the liveness task ends the session.
        try database.execute("UPDATE sessions SET status = 'ended' WHERE session_id = 's1'")
        row = try XCTUnwrap(
            database.sessionsNeedingBillingDerivation(limit: 10).first,
            "a session holding an open segment must be re-examined even with no new activity"
        )
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )

        XCTAssertTrue(try database.runningBillingSegments().isEmpty)
        let closed = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(closed.endedAt, at(5), "closes at the last real event, never at 'now'")
        XCTAssertEqual(closed.seconds, 300)
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty,
                      "and then stops asking")
    }

    func testASessionWithNoNewActivityIsNotReDerived() throws {
        try seedSession("s1", eventMinutes: [0, 5])
        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)
    }

    // MARK: - Final-review regressions (derive + roll across passes)

    /// Forces one session through derivation again, the way a new event does.
    private func rederive(_ sessionId: String = "s1") throws {
        try database.markBillingDerived(sessionId: sessionId, at: "")
        let row = try XCTUnwrap(
            database.sessionsNeedingBillingDerivation(limit: 50).first { $0.sessionId == sessionId }
        )
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, now: at(600), database: database
        )
    }

    private func addEvent(_ sessionId: String = "s1", minute: Int) throws {
        try harness.seed(sessionId: sessionId, type: "PreToolUse", timestamp: at(minute))
        try database.execute(
            "UPDATE sessions SET last_activity_at = ? WHERE session_id = ?", params: [at(minute), sessionId]
        )
    }

    private func entries() throws -> [BillingEntryDTO] {
        try database.billingEntries(projectId: nil, status: nil, since: "")
    }

    /// At run granularity a run is one billable however many passes see it.
    /// A fresh segment id per pass used to mint a new billable every time.
    func testRunGranularityDoesNotDuplicateAcrossPasses() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id)
        try seedSession("s1", eventMinutes: [0, 5])
        let perRun = BillingRollupOptions(granularity: .run, defaultRateCents: 0, currency: "USD")

        try rederive()
        _ = try BillingRollup.run(options: perRun, database: database)
        let segmentId = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first?.id)

        try addEvent(minute: 12)
        try rederive()
        _ = try BillingRollup.run(options: perRun, database: database)
        try rederive()
        _ = try BillingRollup.run(options: perRun, database: database)

        XCTAssertEqual(try database.billingSegments(since: "", limit: 10).map(\.id), [segmentId],
                       "the run keeps its id through re-derivation")
        let all = try entries()
        XCTAssertEqual(all.count, 1, "one run, one billable")
        XCTAssertEqual(all.first?.rawSeconds, 720, "grown, not duplicated")
    }

    /// When re-derivation takes a run's time away, the auto billable that
    /// held it follows: shrunk while time remains, gone when none does.
    func testAnAutoBillableFollowsReDerivation() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id)
        try seedSession("s1", eventMinutes: [0, 5, 10])
        let options = BillingRollupOptions(granularity: .day, defaultRateCents: 0, currency: "USD")

        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 600)

        try harness.deleteEvents(
            where: "session_id = 's1' AND time = ?", arguments: [ClaudePipelineTestHarness.epoch(at(10)) ?? 0])
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().map(\.rawSeconds), [300])

        // Every event gone is the trim taking the session's history, not the
        // time un-happening: what was derived from it stays.
        try harness.deleteEvents(where: "session_id = 's1'")
        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().map(\.rawSeconds), [300], "trimmed history keeps its billable")
    }

    /// "Assign to Project" is the user's decision; the next pass must not put
    /// the run back where the repo mapping says.
    func testAHandAssignmentSurvivesReDerivation() throws {
        let project = try makeProject()
        try seedSession("s1", root: "/src/unmapped", eventMinutes: [0, 5])
        try rederive()
        let segmentId = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first?.id)
        XCTAssertNil(try database.billingSegment(id: segmentId)?.projectId)

        XCTAssertEqual(try BillingRollup.assignSegments(
            ids: [segmentId], projectId: project.id, database: database), 1)
        try harness.seed(sessionId: "s1", type: "PreToolUse", timestamp: at(8), cwd: "/src/unmapped")
        try rederive()

        let segment = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(segment.projectId, project.id, "the assignment stands")
        XCTAssertEqual(segment.seconds, 480, "and the run still grows")
    }

    /// The zone a run was worked in is a fact about the run, not about where
    /// the laptop is when the next pass happens.
    func testReDerivationKeepsTheRunsTimeZone() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id)
        try seedSession("s1", eventMinutes: [0, 5])
        try rederive()
        try database.execute("UPDATE billing_segment SET tz = 'Europe/Lisbon'")

        try addEvent(minute: 9)
        try rederive()

        let segment = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(segment.tz, "Europe/Lisbon")
        XCTAssertEqual(segment.seconds, 540)
    }

    /// `last_activity_at` is written in SQLite's space form, which sorts below
    /// the `T` form on the same day — so the backfill's first day was skipped.
    func testBackfillIncludesTheFirstDayForSpaceFormTimestamps() throws {
        try seedSession("same-day", eventMinutes: [0, 5])
        try seedSession("day-before", eventMinutes: [0, 5])
        try database.execute(
            "UPDATE sessions SET last_activity_at = '2026-09-22 10:00:00' WHERE session_id = 'same-day'"
        )
        try database.execute(
            "UPDATE sessions SET last_activity_at = '2026-09-21 23:59:59' WHERE session_id = 'day-before'"
        )
        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")

        XCTAssertEqual(try database.resetBillingDerivation(since: "2026-09-22T00:00:00Z"), 1)
        XCTAssertEqual(try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["same-day"])
    }

    // MARK: - Review batch b1

    /// V2-a: re-deriving January after a March rate change must not reprice
    /// January. The reshaped runs stay on the entry that already priced them.
    func testReDerivedHistoryKeepsItsEntrysRate() throws {
        let project = try makeProject(rate: 15_000)
        _ = try makeRepo(projectId: project.id)
        try seedSession("s1", eventMinutes: [0, 2, 4, 10, 12])
        let options = BillingRollupOptions(granularity: .day, defaultRateCents: 0, currency: "USD")

        try rederive()
        _ = try BillingRollup.run(options: options, database: database)
        let original = try XCTUnwrap(entries().first)
        XCTAssertEqual(original.rawSeconds, 720)
        XCTAssertEqual(original.rateCents, 15_000)

        _ = try BillingStore.saveProject(
            BillingProjectDTO(id: project.id, name: "Rewrite", defaultRateCents: 30_000), database: database
        )
        // A shorter idle cutoff splits the one run in two.
        try database.markBillingDerived(sessionId: "s1", at: "")
        let row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(for: row, cutoffSeconds: 300, now: at(600), database: database)
        _ = try BillingRollup.run(options: options, database: database)

        let all = try entries()
        XCTAssertEqual(all.count, 1, "the reshaped time stays on its entry")
        XCTAssertEqual(all.first?.id, original.id)
        XCTAssertEqual(all.first?.rateCents, 15_000, "at the rate it was first billed at")
        XCTAssertEqual(all.first?.rawSeconds, 360)
    }

    /// V3-a: turning Track Unassigned off must still close a run it opened
    /// before — otherwise it shows Running forever.
    func testTurningOffUnassignedTrackingClosesARunningRun() throws {
        try seedSession("s1", root: "/src/unknown", status: "active", eventMinutes: [0, 5])
        var row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(for: row, cutoffSeconds: 900, now: at(7), database: database)
        XCTAssertEqual(try database.runningBillingSegments().count, 1)

        row = try XCTUnwrap(database.sessionsNeedingBillingDerivation(limit: 10).first)
        _ = try BillingStore.deriveSegments(
            for: row, cutoffSeconds: 900, trackUnassigned: false, now: at(30), database: database
        )

        XCTAssertTrue(try database.runningBillingSegments().isEmpty, "the old run is closed")
        let closed = try XCTUnwrap(database.billingSegments(since: "", limit: 10).first)
        XCTAssertEqual(closed.endedAt, at(5), "at its last real event")
        XCTAssertEqual(closed.seconds, 300)
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty, "and stops asking")
    }

    /// V7-c: the same ranges the global settings are clamped to, refused at
    /// the edge so an absurd value can't overflow the money arithmetic.
    func testRatesAndRoundingOutsideTheLimitsAreRefused() throws {
        let tooLong = BillingProjectDTO(id: "", name: "P", roundingMinutes: 241)
        XCTAssertThrowsError(try BillingStore.saveProject(tooLong, database: database))
        for rate in [-1, BillingLimits.defaultRateCents.upperBound + 1] {
            XCTAssertThrowsError(try BillingStore.saveProject(
                BillingProjectDTO(id: "", name: "P", defaultRateCents: rate), database: database
            ), "\(rate)")
        }
        let project = try makeProject()
        XCTAssertThrowsError(try makeRepo(projectId: project.id, rate: -500))
        XCTAssertNoThrow(try makeRepo(projectId: project.id, rate: 0), "a zero rate is a rate")
    }

    /// V3-b: a new idle cutoff re-derives every session with derived time,
    /// not just the ones a pass happens to re-select.
    func testAnIdleCutoffChangeQueuesEveryDerivedSession() throws {
        let project = try makeProject()
        _ = try makeRepo(projectId: project.id)
        try seedSession("s1", eventMinutes: [0, 5])
        try rederive()
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty)

        try BillingPrefs.apply([database.billingSettingsKeys.currency: "EUR"], database: database)
        XCTAssertTrue(try database.sessionsNeedingBillingDerivation(limit: 10).isEmpty,
                      "other knobs don't touch history")

        let snapshot = try BillingPrefs.apply([database.billingSettingsKeys.idleCutoffMinutes: "5"], database: database)
        XCTAssertEqual(snapshot.idleCutoffSeconds, 300)
        XCTAssertEqual(try database.sessionsNeedingBillingDerivation(limit: 10).map(\.sessionId), ["s1"])
    }

    /// V25-a: the per-entry segment read and the supplement lookup are
    /// index seeks, not whole-table scans.
    func testTheBillingLookupIndexesExist() throws {
        var names: Set<String> = []
        try database.query("SELECT name FROM sqlite_master WHERE type = 'index'") { row in
            names.insert(row["name"] ?? "")
        }
        XCTAssertTrue(names.contains("idx_billing_segment_entry"))
        XCTAssertTrue(names.contains("idx_billing_entry_supplements"))
    }
}
