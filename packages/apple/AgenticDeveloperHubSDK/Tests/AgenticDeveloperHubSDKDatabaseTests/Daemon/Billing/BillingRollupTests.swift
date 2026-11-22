import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The rollup's contract in one line: an unbilled entry is a view of its
/// segments and may be recomputed freely; a billed or paid entry is history and
/// may not be touched at all.
final class BillingRollupTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-rollup-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-rollup.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    private let options = BillingRollupOptions(
        granularity: .day, defaultRateCents: 0, currency: "USD"
    )

    private func makeProject(rate: Int? = 10_000, enabled: Bool = true) throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: rate, billingEnabled: enabled),
            database: database
        )
    }

    /// Writes a closed segment directly — this task's subject is what happens
    /// *after* derivation, so the segments are given, not derived.
    @discardableResult
    private func segment(
        project: BillingProjectDTO,
        startMinute: Int,
        seconds: Int,
        sessionId: String = "s1",
        day: String = "2026-09-22",
        ended: Bool = true
    ) throws -> BillingSegmentDTO {
        let dto = BillingSegmentDTO(
            id: UUID().uuidString, sessionId: sessionId, origin: "auto",
            projectId: project.id, projectRoot: "/src/app", branch: "main",
            startedAt: "\(day)T\(clock(startMinute))Z",
            endedAt: ended ? "\(day)T\(clock(startMinute + seconds / 60))Z" : "",
            tz: "UTC", seconds: ended ? seconds : 0
        )
        try database.upsertBillingSegment(dto)
        return dto
    }

    private func clock(_ minutes: Int) -> String {
        let total = 9 * 3600 + minutes * 60
        return String(format: "%02d:%02d:00", total / 3600, (total % 3600) / 60)
    }

    /// Every entry row, the zero-second ones the listing hides included.
    private func entries() throws -> [BillingEntryDTO] {
        var ids: [String] = []
        try database.query("SELECT id FROM billing_entry ORDER BY day DESC, created_at, id") { row in
            ids.append(row["id"] ?? "")
        }
        return try ids.compactMap { try database.billingEntry(id: $0) }
    }

    // MARK: - Grouping

    func testRollupCreatesOneEntryPerProjectDay() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800)
        try segment(project: project, startMinute: 60, seconds: 1800)

        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1)
        let all = try entries()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].rawSeconds, 3600)
        XCTAssertEqual(all[0].day, "2026-09-22")
        XCTAssertEqual(all[0].status, BillingStatus.unbilled.rawValue)
        XCTAssertEqual(all[0].groupKey, "rate:10000", "a day entry is keyed by its rate")
    }

    /// Two sessions in one repo over the same ten minutes bill ten minutes.
    func testParallelSessionsInOneProjectBillTheUnion() throws {
        let project = try makeProject(rate: 10_000)
        try segment(project: project, startMinute: 0, seconds: 600, sessionId: "a")
        try segment(project: project, startMinute: 0, seconds: 600, sessionId: "b")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 600)
    }

    /// Re-running must recompute the unbilled entry, not stack a second one.
    func testRollupIsIdempotent() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800)
        for _ in 0..<3 { _ = try BillingRollup.run(options: options, database: database) }
        XCTAssertEqual(try entries().count, 1)
        XCTAssertEqual(try entries()[0].rawSeconds, 1800)
    }

    /// Rounding applies once, to the entry. Rounding each segment first is the
    /// classic way to turn five five-minute checks into 75 billed minutes.
    func testRoundingHappensOncePerEntry() throws {
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: 10_000, roundingMinutes: 15),
            database: database
        )
        for index in 0..<5 { try segment(project: project, startMinute: index * 20, seconds: 300) }

        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        XCTAssertEqual(entry.rawSeconds, 1500)
        XCTAssertEqual(entry.billedSeconds, 1800, "one 15-minute increment above 25 minutes, not five")
    }

    func testRunGranularityCreatesOneEntryPerSegment() throws {
        let project = try makeProject()
        let first = try segment(project: project, startMinute: 0, seconds: 1800)
        let second = try segment(project: project, startMinute: 60, seconds: 1800)

        let perRun = BillingRollupOptions(granularity: .run, defaultRateCents: 0, currency: "USD")
        XCTAssertEqual(try BillingRollup.run(options: perRun, database: database), 2)
        let keys = Set(try entries().map(\.groupKey))
        XCTAssertEqual(keys, [BillingRollup.runGroupKey(for: first), BillingRollup.runGroupKey(for: second)],
                       "the run is the group at run granularity")
        XCTAssertEqual(BillingRollup.runGroupKey(for: first), "s1|\(first.startedAt)",
                       "keyed on the run's identity, not its row id")
    }

    // MARK: - App time at run granularity

    /// An app segment, offset in seconds from 09:00 on 2026-09-22.
    private func appSegment(project: BillingProjectDTO, span: String, from: Int, seconds: Int) throws {
        func at(_ offset: Int) -> String {
            let total = 9 * 3600 + offset
            return String(format: "2026-09-22T%02d:%02d:%02dZ", total / 3600, (total % 3600) / 60, total % 60)
        }
        try database.upsertBillingSegment(BillingSegmentDTO(
            id: UUID().uuidString, sessionId: ActivitySpanSession.sessionId(spanId: span), origin: "auto",
            projectId: project.id, projectRoot: "/src/app", branch: "main",
            startedAt: at(from), endedAt: at(from + seconds), tz: "UTC", seconds: seconds))
    }

    private let perRun = BillingRollupOptions(granularity: .run, defaultRateCents: 0, currency: "USD")

    /// Forty app switches in an hour are an hour of work, not forty rounded runs.
    func testRunGranularityRollsAppSpansIntoOneDayEntry() throws {
        let project = try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: 10_000, roundingMinutes: 15),
            database: database)
        for index in 0..<40 { try appSegment(project: project, span: "s\(index)", from: index * 90, seconds: 90) }

        _ = try BillingRollup.run(options: perRun, database: database)
        let all = try entries()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].rawSeconds, 3600)
        XCTAssertEqual(all[0].billedSeconds, 3600, "rounded once, not forty times")
        XCTAssertTrue(BillingRollup.isAppGroupKey(all[0].groupKey))
    }

    /// Claude runs keep their own entries; app time they already cover is not billed again.
    func testRunGranularityBillsAClaudeRunAndOverlappingAppTimeOnce() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")   // 09:00–09:30
        try appSegment(project: project, span: "x", from: 900, seconds: 1800)               // 09:15–09:45

        _ = try BillingRollup.run(options: perRun, database: database)
        let all = try entries()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.map(\.rawSeconds).reduce(0, +), 2700, "the union, 09:00–09:45")
        let app = try XCTUnwrap(all.first { BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(app.rawSeconds, 900, "only the app time no Claude run covers")
    }

    /// Order must not matter: a Claude run arriving after the app entry exists
    /// still takes the overlap out of the app entry.
    func testALaterClaudeRunShrinksTheAppEntry() throws {
        let project = try makeProject()
        try appSegment(project: project, span: "x", from: 900, seconds: 1800)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 1800)

        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try entries().map(\.rawSeconds).reduce(0, +), 2700)
    }

    /// A billed app entry never shrinks, so a Claude run arriving after it
    /// must give up the overlap instead — or that overlap bills twice.
    func testALockedAppEntryTakesTheOverlapOutOfALaterClaudeRun() throws {
        let project = try makeProject()
        try appSegment(project: project, span: "x", from: 900, seconds: 1800)               // 09:15–09:45
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)

        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")   // 09:00–09:30
        _ = try BillingRollup.run(options: perRun, database: database)
        let all = try entries()
        XCTAssertEqual(all.first { $0.id == app.id }?.rawSeconds, 1800, "billed: never touched")
        let claude = try XCTUnwrap(all.first { !BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(claude.rawSeconds, 900, "the run less the 15 minutes already billed")
    }

    /// The other order: the app entry gave up the overlap to a Claude run
    /// before it froze, so it never billed that time — a later recompute of
    /// the run must keep it, or the overlap bills zero times.
    func testAnAppEntryShrunkBeforeItFrozeLeavesTheOverlapWithTheClaudeRun() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")   // 09:00–09:30
        try appSegment(project: project, span: "x", from: 900, seconds: 1800)               // 09:15–09:45
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(entries().first { BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(app.rawSeconds, 900)
        _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)

        try BillingRollup.recomputeOwnedEntries(database: database)
        let all = try entries()
        let claude = try XCTUnwrap(all.first { !BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(claude.rawSeconds, 1800, "the run keeps the overlap the app entry never billed")
        XCTAssertEqual(all.map(\.rawSeconds).reduce(0, +), 2700, "the union, billed once")
    }

    /// App time a Claude run covers entirely bills nothing: the app entry is
    /// the residual, and here the residual is zero.
    func testAppTimeAClaudeRunCoversEntirelyBillsNothingTwice() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")   // 09:00–09:30
        try appSegment(project: project, span: "x", from: 600, seconds: 600)                // 09:10–09:20

        _ = try BillingRollup.run(options: perRun, database: database)
        let all = try entries()
        XCTAssertEqual(all.map(\.rawSeconds).reduce(0, +), 1800, "the union, billed once")
        let app = try XCTUnwrap(all.first { BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(app.rawSeconds, 0, "the Claude run owns all of it")
    }

    /// The candidates are read project by project. Driven from the segments, the
    /// query walked every unrolled segment even with no project billing, and a
    /// busy disk pushed that read past its deadline.
    func testRollupCandidatesAreReadProjectByProject() throws {
        var plan: [String] = []
        try database.query("EXPLAIN QUERY PLAN " + DaemonDatabase.billingRollupCandidatesSQL) { row in
            plan.append(row["detail"] ?? "")
        }
        XCTAssertTrue(plan.first?.hasPrefix("SCAN p") ?? false, plan.joined(separator: "\n"))
        XCTAssertTrue(plan.contains { $0.hasPrefix("SEARCH s USING INDEX") && $0.contains("project_id=?") },
                      plan.joined(separator: "\n"))
    }

    /// A roll with nothing new to attach and nothing changed writes nothing.
    func testASecondRollWithNothingNewWritesNothing() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")   // 09:00–09:30
        try appSegment(project: project, span: "x", from: 600, seconds: 1800)               // 09:10–09:40
        _ = try BillingRollup.run(options: perRun, database: database)

        XCTAssertEqual(try database.billingRollupCandidates(ids: nil).count, 0)
        XCTAssertEqual(try BillingRollup.run(options: perRun, database: database), 0, "the steady state")
    }

    /// Covered app time comes back when the Claude run covering it moves away.
    func testCoveredAppTimeBillsOnceTheClaudeRunMoves() throws {
        let project = try makeProject()
        let claude = try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")
        try appSegment(project: project, span: "x", from: 600, seconds: 600)                // 09:10–09:20
        _ = try BillingRollup.run(options: perRun, database: database)

        try database.upsertBillingSegment(BillingSegmentDTO(
            id: claude.id, sessionId: claude.sessionId, origin: claude.origin,
            projectId: claude.projectId, projectRoot: claude.projectRoot, branch: claude.branch,
            startedAt: claude.startedAt, endedAt: "2026-09-22T09:05:00Z", tz: "UTC", seconds: 300))
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(entries().first { BillingRollup.isAppGroupKey($0.groupKey) })
        XCTAssertEqual(app.rawSeconds, 600)
    }

    /// The same, the other way round: a Claude run swallowing an app entry
    /// that already exists takes all its time, leaving it at zero.
    func testALaterClaudeRunCoveringAnAppEntryTakesAllItsTime() throws {
        let project = try makeProject()
        try appSegment(project: project, span: "x", from: 600, seconds: 600)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 600)

        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")
        _ = try BillingRollup.run(options: perRun, database: database)
        let all = try entries()
        XCTAssertEqual(all.map(\.rawSeconds).reduce(0, +), 1800)
        XCTAssertEqual(all.first { BillingRollup.isAppGroupKey($0.groupKey) }?.rawSeconds, 0)
    }

    /// A billed app entry stays, even at zero: it is history.
    func testALockedAppEntryIsKeptWhenAClaudeRunCoversIt() throws {
        let project = try makeProject()
        try appSegment(project: project, span: "x", from: 600, seconds: 600)
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)

        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "claude")
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try database.billingEntry(id: app.id)?.rawSeconds, 600)
    }

    // MARK: - What is not rolled up

    func testOpenSegmentsAreNotRolledUp() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 0, ended: false)
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 0)
        XCTAssertTrue(try entries().isEmpty, "time still being worked is not yet billable")
    }

    func testUnassignedSegmentsAreNotRolledUp() throws {
        let orphan = BillingSegmentDTO(
            id: "seg", sessionId: "s1", origin: "auto", projectRoot: "/src/unknown",
            startedAt: "2026-09-22T09:00:00Z", endedAt: "2026-09-22T09:30:00Z",
            tz: "UTC", seconds: 1800
        )
        try database.upsertBillingSegment(orphan)
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 0)
        XCTAssertNotNil(try database.billingSegment(id: "seg"), "tracked, just not billed")
    }

    /// `billing_enabled = 0` means track the time and bill nothing — which is
    /// deliberately different from a zero rate, and the next test proves it.
    func testBillingDisabledProjectTracksTimeButCreatesNoEntry() throws {
        let project = try makeProject(enabled: false)
        try segment(project: project, startMinute: 0, seconds: 1800)
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 0)
        XCTAssertTrue(try entries().isEmpty)
    }

    func testAZeroRateStillProducesAnEntry() throws {
        let project = try makeProject(rate: 0)
        try segment(project: project, startMinute: 0, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        XCTAssertEqual(entry.amountCents, 0)
        XCTAssertEqual(entry.rawSeconds, 1800, "the hours are recorded even at no charge")
    }

    // MARK: - Money

    func testAmountUsesIntegerCentsRoundedHalfUp() {
        XCTAssertEqual(BillingRollup.amountCents(billedSeconds: 3600, rateCents: 10_000), 10_000)
        XCTAssertEqual(BillingRollup.amountCents(billedSeconds: 1800, rateCents: 10_000), 5_000)
        // 10001 ¢/h for half an hour is 5000.5 ¢ — half-up, so 5001.
        XCTAssertEqual(BillingRollup.amountCents(billedSeconds: 1800, rateCents: 10_001), 5_001)
        XCTAssertEqual(BillingRollup.amountCents(billedSeconds: 0, rateCents: 10_000), 0)
    }

    /// The one decision that cannot be retrofitted: an entry carries the rate
    /// it was written with, so raising a rate in March leaves January alone.
    func testRateAndRoundingAreSnapshottedOntoTheEntry() throws {
        let project = try makeProject(rate: 10_000)
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entryId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(
            entryId: entryId, to: .billed, source: "user", database: database
        )

        _ = try BillingStore.saveProject(
            BillingProjectDTO(id: project.id, name: "P", defaultRateCents: 20_000), database: database
        )
        _ = try BillingRollup.run(options: options, database: database)

        let entry = try XCTUnwrap(database.billingEntry(id: entryId))
        XCTAssertEqual(entry.rateCents, 10_000, "the billed entry keeps January's rate")
        XCTAssertEqual(entry.amountCents, 10_000)
    }

    // MARK: - Frozen entries

    func testLateSegmentsOnALockedEntryProduceASupplementalEntry() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let originalId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(
            entryId: originalId, to: .billed, source: "user", database: database
        )

        // 20 more minutes land on the same day, after the invoice went out.
        try segment(project: project, startMinute: 300, seconds: 1200)
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1)

        let all = try entries().sorted { $0.createdAt < $1.createdAt }
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(try XCTUnwrap(database.billingEntry(id: originalId)).rawSeconds, 3600,
                       "the billed figure never moves")
        let supplement = try XCTUnwrap(all.first { $0.supplementsEntryId != nil })
        XCTAssertEqual(supplement.supplementsEntryId, originalId)
        XCTAssertEqual(supplement.rawSeconds, 1200, "only the delta")
        XCTAssertEqual(supplement.status, BillingStatus.unbilled.rawValue)
    }

    func testASupplementalEntryIsNotItselfSupplementedTwice() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let originalId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(
            entryId: originalId, to: .billed, source: "user", database: database
        )

        try segment(project: project, startMinute: 300, seconds: 1200)
        _ = try BillingRollup.run(options: options, database: database)
        try segment(project: project, startMinute: 400, seconds: 600)
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try entries().count, 2, "the open supplement absorbs the next delta")
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId != nil })
        XCTAssertEqual(supplement.rawSeconds, 1800)
    }

    /// Deleting an entry that has an open supplement must release the
    /// supplement's segments too, not just the deleted entry's own — else
    /// they're left pointing at a row that no longer exists, invisible to
    /// `billingRollupCandidates` (which requires `entry_id IS NULL`), and
    /// their time silently vanishes instead of being re-rolled.
    func testDeletingAnEntryReleasesItsSupplementsSegmentsToo() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let originalId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(
            entryId: originalId, to: .billed, source: "user", database: database
        )

        // A late segment lands after the invoice, spawning a supplement.
        let lateSegment = try segment(project: project, startMinute: 300, seconds: 1200)
        _ = try BillingRollup.run(options: options, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == originalId })
        XCTAssertEqual(try XCTUnwrap(database.billingSegment(id: lateSegment.id)).entryId, supplement.id)

        // Reopening the original unlocks it, so it can be deleted.
        _ = try BillingRollup.setStatus(
            entryId: originalId, to: .unbilled, source: "user", database: database
        )
        try BillingRollup.deleteEntry(id: originalId, database: database)

        XCTAssertNil(try database.billingEntry(id: originalId))
        XCTAssertNil(try database.billingEntry(id: supplement.id), "the supplement is deleted with its parent")
        XCTAssertNil(try XCTUnwrap(database.billingSegment(id: lateSegment.id)).entryId,
                     "the supplement's segment must be released, not orphaned")

        // No time lost: the next run re-rolls both freed segments (the
        // original entry's own, released as before, plus the supplement's,
        // released by this fix) back into a single fresh entry for the slot.
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1)
        let rerolled = try XCTUnwrap(entries().first)
        XCTAssertEqual(rerolled.rawSeconds, 4800, "both the original and supplemental time come back")
        XCTAssertEqual(try XCTUnwrap(database.billingSegment(id: lateSegment.id)).entryId, rerolled.id)
    }

    // MARK: - Status and audit

    func testStatusTransitionLocksTheEntryAndWritesAnAuditRow() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entryId = try XCTUnwrap(entries().first?.id)

        let billed = try BillingRollup.setStatus(
            entryId: entryId, to: .billed, source: "user", database: database
        )
        XCTAssertEqual(billed.status, BillingStatus.billed.rawValue)
        XCTAssertTrue(billed.locked)

        let audit = try database.billingEntryAudit(entryId: entryId, limit: 10)
        XCTAssertEqual(audit.count, 1)
        XCTAssertEqual(audit[0].field, "status")
        XCTAssertEqual(audit[0].oldValue, "unbilled")
        XCTAssertEqual(audit[0].newValue, "billed")
    }

    /// Going backwards is allowed — mistakes happen — but it is recorded.
    func testMovingBackToUnbilledUnlocksAndAudits() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entryId = try XCTUnwrap(entries().first?.id)

        _ = try BillingRollup.setStatus(entryId: entryId, to: .paid, source: "user", database: database)
        let reopened = try BillingRollup.setStatus(
            entryId: entryId, to: .unbilled, source: "user", database: database
        )
        XCTAssertFalse(reopened.locked)
        XCTAssertEqual(try database.billingEntryAudit(entryId: entryId, limit: 10).count, 2)
    }

    func testEditingALockedEntryIsRefused() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: entry.id, to: .billed, source: "user", database: database)

        let edited = BillingEntryDTO(
            id: entry.id, projectId: entry.projectId, day: entry.day,
            rawSeconds: 99, billedSeconds: 99, rateCents: 1, amountCents: 1
        )
        XCTAssertThrowsError(try BillingRollup.saveEntry(edited, database: database)) { error in
            // The app shows this verbatim, and its test double reads the same constant.
            XCTAssertEqual(error.localizedDescription, BillingRefusalText.entryIsLocked)
        }
        XCTAssertThrowsError(try BillingRollup.deleteEntry(id: "no-such-entry", database: database)) { error in
            XCTAssertEqual(error.localizedDescription, BillingRefusalText.unknownEntry)
        }
    }

    /// A manual edit to an unbilled entry is allowed, and the rollup must not
    /// silently overwrite it on the next pass.
    func testAManuallyEditedEntryIsNotRecomputed() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        var entry = try XCTUnwrap(entries().first)

        entry = try BillingRollup.saveEntry(
            BillingEntryDTO(
                id: entry.id, projectId: entry.projectId, day: entry.day,
                rawSeconds: entry.rawSeconds, billedSeconds: 7200,
                rateCents: entry.rateCents, amountCents: 20_000,
                description: "Agreed two hours", origin: "user", updatedAt: entry.updatedAt
            ),
            database: database
        )
        _ = try BillingRollup.run(options: options, database: database)

        let after = try XCTUnwrap(database.billingEntry(id: entry.id))
        XCTAssertEqual(after.billedSeconds, 7200, "a user-owned entry is left alone")
        XCTAssertEqual(after.description, "Agreed two hours")
    }

    // MARK: - Description

    func testDescriptionAutoFillsFromSessionTitles() throws {
        let project = try makeProject()
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, transcript_title, summary) VALUES (?, '/src/app', ?, '')
        """, params: ["s1", "Rewrite the importer"])
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, transcript_title, summary) VALUES (?, '/src/app', '', ?)
        """, params: ["s2", "Fix the flaky test"])
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "s1")
        try segment(project: project, startMinute: 60, seconds: 1800, sessionId: "s2")

        _ = try BillingRollup.run(options: options, database: database)
        let description = try XCTUnwrap(entries().first?.description)
        XCTAssertTrue(description.contains("Rewrite the importer"))
        XCTAssertTrue(description.contains("Fix the flaky test"), "falls back to summary when untitled")
    }

    /// Rows pruned or never titled must not blank or shrink a description
    /// the entry already carries.
    func testRecomputeKeepsTheDescriptionOnceItsTitlesAreGone() throws {
        let project = try makeProject()
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, transcript_title, summary)
            VALUES ('s1', '/src/app', 'Rewrite the importer', '')
        """)
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "s1")
        _ = try BillingRollup.run(options: options, database: database)
        let before = try XCTUnwrap(entries().first?.description)
        XCTAssertTrue(before.contains("Rewrite the importer"))

        try database.execute("DELETE FROM sessions WHERE session_id = 's1'")
        try segment(project: project, startMinute: 60, seconds: 600, sessionId: "s1")   // forces a recompute
        _ = try BillingRollup.run(options: options, database: database)
        let after = try XCTUnwrap(entries().first)
        XCTAssertEqual(after.rawSeconds, 2400, "the entry did recompute")
        XCTAssertEqual(after.description, before)
    }

    /// A session that exists but has no title yet is not "gone": it must not
    /// freeze the description against a titled session joining later.
    func testAnUntitledSessionDoesNotFreezeTheDescription() throws {
        let project = try makeProject()
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, transcript_title, summary) VALUES ('s1', '/src/app', '', '')
        """)
        try segment(project: project, startMinute: 0, seconds: 1800, sessionId: "s1")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertFalse(try XCTUnwrap(entries().first?.description).contains("Fix the flaky test"))

        try database.execute("""
            INSERT INTO sessions (session_id, cwd, transcript_title, summary)
            VALUES ('s2', '/src/app', 'Fix the flaky test', '')
        """)
        try segment(project: project, startMinute: 60, seconds: 1800, sessionId: "s2")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertTrue(try XCTUnwrap(entries().first?.description).contains("Fix the flaky test"))
    }

    // MARK: - Assigning and promoting

    func testAssigningSegmentsMakesThemRollupCandidates() throws {
        let project = try makeProject()
        let orphan = BillingSegmentDTO(
            id: "seg", sessionId: "s1", origin: "auto", projectRoot: "/src/unknown",
            startedAt: "2026-09-22T09:00:00Z", endedAt: "2026-09-22T09:30:00Z",
            tz: "UTC", seconds: 1800
        )
        try database.upsertBillingSegment(orphan)

        XCTAssertEqual(
            try BillingRollup.assignSegments(ids: ["seg"], projectId: project.id, database: database), 1
        )
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1)
        XCTAssertEqual(try entries().first?.rawSeconds, 1800)
    }

    func testPromotingRollsTheNamedSegmentsImmediately() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 1800)
        let ids = try database.billingSegments(since: "", limit: 10).map(\.id)
        XCTAssertEqual(try BillingRollup.promoteSegments(ids: ids, options: options, database: database), 1)
        XCTAssertEqual(try entries().count, 1)
    }

    // MARK: - Overview

    func testOverviewBucketsByStatus() throws {
        let project = try makeProject(rate: 10_000)
        try segment(project: project, startMinute: 0, seconds: 3600)
        try segment(project: project, startMinute: 0, seconds: 3600, day: "2026-09-23")
        _ = try BillingRollup.run(options: options, database: database)

        let first = try XCTUnwrap(entries().first { $0.day == "2026-09-22" })
        _ = try BillingRollup.setStatus(entryId: first.id, to: .paid, source: "user", database: database)

        let overview = try BillingRollup.overview(database: database)
        XCTAssertEqual(overview.unbilled.entryCount, 1)
        XCTAssertEqual(overview.unbilled.amountCents, 10_000)
        XCTAssertEqual(overview.billed.entryCount, 0)
        XCTAssertEqual(overview.paid.entryCount, 1)
        XCTAssertEqual(overview.paid.seconds, 3600)
    }

    // MARK: - Final-review regressions

    private func repo(
        project: BillingProjectDTO, root: String, branch: String = "", rate: Int?
    ) throws -> BillingRepoDTO {
        try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: root, branch: branch, rateCents: rate),
            database: database
        )
    }

    @discardableResult
    private func segment(
        project: BillingProjectDTO, repo: BillingRepoDTO, startMinute: Int, seconds: Int,
        sessionId: String = "s1"
    ) throws -> BillingSegmentDTO {
        let dto = BillingSegmentDTO(
            id: UUID().uuidString, sessionId: sessionId, origin: "auto",
            projectId: project.id, repoId: repo.id, projectRoot: repo.projectRoot, branch: repo.branch,
            startedAt: "2026-09-22T\(clock(startMinute))Z",
            endedAt: "2026-09-22T\(clock(startMinute + seconds / 60))Z",
            tz: "UTC", seconds: seconds
        )
        try database.upsertBillingSegment(dto)
        return dto
    }

    /// The ladder's second step, in the rollup: a branch row without a rate
    /// bills at its repo's any-branch rate, not the project default.
    func testTheRollupUsesTheAnyBranchRateForARatelessBranchRow() throws {
        let project = try makeProject(rate: 10_000)
        _ = try repo(project: project, root: "/src/app", rate: 9_000)
        let branchRow = try repo(project: project, root: "/src/app", branch: "rush", rate: nil)
        try segment(project: project, repo: branchRow, startMinute: 0, seconds: 3600)

        _ = try BillingRollup.run(options: options, database: database)

        let entry = try XCTUnwrap(entries().first)
        XCTAssertEqual(entry.rateCents, 9_000)
        XCTAssertEqual(entry.amountCents, 9_000)
    }

    /// One project, two repos, two rates, one day: two entries, each at its
    /// own rate — never all the time at whichever repo came first.
    func testTwoRatesOnOneProjectDayMakeTwoEntries() throws {
        let project = try makeProject(rate: 10_000)
        let standard = try repo(project: project, root: "/src/app", rate: nil)
        let premium = try repo(project: project, root: "/src/rush", rate: 20_000)
        try segment(project: project, repo: standard, startMinute: 0, seconds: 3600, sessionId: "a")
        try segment(project: project, repo: premium, startMinute: 120, seconds: 3600, sessionId: "b")

        _ = try BillingRollup.run(options: options, database: database)

        let byRate = Dictionary(uniqueKeysWithValues: try entries().map { ($0.rateCents, $0) })
        XCTAssertEqual(Set(byRate.keys), [10_000, 20_000])
        XCTAssertEqual(byRate[10_000]?.groupKey, "rate:10000")
        XCTAssertEqual(byRate[20_000]?.groupKey, "rate:20000")
        XCTAssertEqual(byRate[20_000]?.amountCents, 20_000)
    }

    /// Review F38: two claims made in the same second tie on `created_at`.
    /// The tie goes to the lower rate, by number — never by the group key's
    /// text, where "rate:15000" sorts before "rate:9000".
    func testATieOnCreationGoesToTheLowerRateByNumber() throws {
        let project = try makeProject(rate: 10_000)
        let cheap = try repo(project: project, root: "/src/app", rate: 9_000)
        let dear = try repo(project: project, root: "/src/rush", rate: 15_000)
        try segment(project: project, repo: dear, startMinute: 0, seconds: 3600, sessionId: "a")
        try segment(project: project, repo: cheap, startMinute: 0, seconds: 3600, sessionId: "b")
        _ = try BillingRollup.run(options: options, database: database)
        try database.execute("UPDATE billing_entry SET created_at = '2026-09-22T08:00:00Z'")
        _ = try BillingRollup.recomputeOwnedEntries(database: database)

        let byRate = Dictionary(uniqueKeysWithValues: try entries().map { ($0.rateCents, $0) })
        XCTAssertEqual(byRate[9_000]?.rawSeconds, 3600)
        XCTAssertEqual(byRate[15_000]?.rawSeconds ?? 0, 0)
    }

    /// Review F53: the figures come from the write path alone. A segment
    /// whose start does not parse is billed as its seconds (never negative);
    /// sources overlapping three deep count once.
    func testLooseAndOverlappingSegmentsAreCountedByTheWritePath() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600, sessionId: "a")
        try segment(project: project, startMinute: 30, seconds: 3600, sessionId: "b")
        try segment(project: project, startMinute: 0, seconds: 5400, sessionId: "c")
        let loose = try segment(project: project, startMinute: 300, seconds: 120, sessionId: "d")
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 5400 + 120)

        try database.execute("UPDATE billing_segment SET started_at = 'garbage' WHERE id = ?", params: [loose.id])
        _ = try BillingRollup.recomputeOwnedEntries(database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 5400 + 120, "unplaceable, billed as its seconds")

        try database.execute("UPDATE billing_segment SET seconds = -50 WHERE id = ?", params: [loose.id])
        _ = try BillingRollup.recomputeOwnedEntries(database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 5400, "negative seconds count as none")
    }

    /// An auto entry is a view of its segments: when one goes away the entry
    /// shrinks, and when the last goes the entry goes too.
    func testAnAutoEntryFollowsItsSegmentsAndGoesWhenTheyDo() throws {
        let project = try makeProject()
        let first = try segment(project: project, startMinute: 0, seconds: 3600)
        let second = try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertEqual(try entries().first?.rawSeconds, 5400)

        try database.deleteBillingSegment(id: second.id)
        XCTAssertEqual(try BillingRollup.run(options: options, database: database), 1, "recomputed")
        XCTAssertEqual(try entries().first?.rawSeconds, 3600)
        XCTAssertEqual(try entries().first?.amountCents, 10_000)

        try database.deleteBillingSegment(id: first.id)
        _ = try BillingRollup.run(options: options, database: database)
        XCTAssertTrue(try entries().isEmpty, "an auto entry with no time left is removed")
    }

    /// Only entries the rollup owns are recomputed or removed.
    func testALockedEntryIsNeverRecomputedOrRemoved() throws {
        let project = try makeProject()
        let only = try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entryId = try XCTUnwrap(entries().first?.id)
        _ = try BillingRollup.setStatus(entryId: entryId, to: .billed, source: "user", database: database)

        try database.deleteBillingSegment(id: only.id)
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try database.billingEntry(id: entryId)?.rawSeconds, 3600)
    }

    /// Rewording today's billable is not taking it over: it stays the
    /// rollup's, keeps growing with the day's work, and keeps the wording.
    func testADescriptionOnlyEditKeepsTheEntryGrowing() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)

        let saved = try BillingRollup.saveEntry(
            BillingEntryDTO(
                id: entry.id, projectId: entry.projectId, clientId: entry.clientId, day: entry.day,
                groupKey: entry.groupKey, startedAt: entry.startedAt, endedAt: entry.endedAt,
                rawSeconds: entry.rawSeconds, billedSeconds: entry.billedSeconds, rateCents: entry.rateCents,
                currency: entry.currency, amountCents: entry.amountCents,
                roundingMinutes: entry.roundingMinutes, roundingMode: entry.roundingMode,
                status: entry.status, description: "Importer rewrite", origin: entry.origin,
                updatedAt: entry.updatedAt
            ), database: database
        )
        XCTAssertEqual(saved.origin, "auto", "a description edit keeps the entry the rollup's")

        try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)

        let all = try entries()
        XCTAssertEqual(all.count, 1, "no supplement for an entry that only changed its words")
        XCTAssertEqual(all[0].rawSeconds, 5400, "the later work is added")
        XCTAssertEqual(all[0].description, "Importer rewrite", "and the wording survives the recompute")
    }

    /// Changing the figures does take the entry over; later work that day then
    /// lands on a supplement, with its seconds, rather than vanishing into the
    /// hand-set figure.
    func testAFigureEditRoutesLaterWorkToASupplement() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)

        let saved = try BillingRollup.saveEntry(
            BillingEntryDTO(
                id: entry.id, projectId: entry.projectId, day: entry.day, groupKey: entry.groupKey,
                startedAt: entry.startedAt, endedAt: entry.endedAt,
                rawSeconds: entry.rawSeconds, billedSeconds: 7200, rateCents: entry.rateCents,
                currency: entry.currency, amountCents: 20_000,
                roundingMinutes: entry.roundingMinutes, roundingMode: entry.roundingMode,
                status: entry.status, description: entry.description, origin: entry.origin,
                updatedAt: entry.updatedAt
            ),
            database: database
        )
        XCTAssertEqual(saved.origin, "user")

        let late = try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try database.billingEntry(id: entry.id)?.billedSeconds, 7200, "the typed figure stands")
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == entry.id })
        XCTAssertEqual(supplement.rawSeconds, 1800, "the later work is billed, not swallowed")
        XCTAssertEqual(try database.billingSegment(id: late.id)?.entryId, supplement.id)
    }

    /// A supplement the user then hand-edits is frozen like any other typed
    /// entry. Later work must open a new supplement, not be composed back
    /// into the edited one as `auto` with recomputed figures.
    func testAHandEditedSupplementIsNotReusedForLaterWork() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        try database.execute("UPDATE billing_entry SET origin = 'user' WHERE id = ?", params: [entry.id])

        try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)
        let first = try XCTUnwrap(entries().first { $0.supplementsEntryId == entry.id })
        let edited = try BillingRollup.saveEntry(
            BillingEntryDTO(
                id: first.id, projectId: first.projectId, day: first.day, groupKey: first.groupKey,
                startedAt: first.startedAt, endedAt: first.endedAt,
                rawSeconds: first.rawSeconds, billedSeconds: 900, rateCents: first.rateCents,
                currency: first.currency, amountCents: 2_500,
                roundingMinutes: first.roundingMinutes, roundingMode: first.roundingMode,
                status: first.status, description: first.description, origin: first.origin,
                supplementsEntryId: first.supplementsEntryId, updatedAt: first.updatedAt
            ),
            database: database
        )
        XCTAssertEqual(edited.origin, "user")

        let later = try segment(project: project, startMinute: 240, seconds: 600)
        _ = try BillingRollup.run(options: options, database: database)

        let kept = try XCTUnwrap(database.billingEntry(id: first.id))
        XCTAssertEqual(kept.origin, "user", "the edited supplement stays the user's")
        XCTAssertEqual(kept.billedSeconds, 900)
        XCTAssertEqual(kept.amountCents, 2_500)
        let supplements = try entries().filter { $0.supplementsEntryId == entry.id }
        XCTAssertEqual(supplements.count, 2, "later work opens a new supplement")
        let second = try XCTUnwrap(supplements.first { $0.id != first.id })
        XCTAssertEqual(second.rawSeconds, 600)
        XCTAssertEqual(try database.billingSegment(id: later.id)?.entryId, second.id)
    }

    /// The description path writes the words and nothing else, so a stale
    /// window can't freeze a growing entry at the figures it last saw.
    func testSettingTheDescriptionNeverFreezesTheFigures() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let stale = try XCTUnwrap(entries().first)

        // The entry grows after the window read it.
        try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)

        let saved = try BillingRollup.setDescription(
            entryId: stale.id, description: "  Importer rewrite ", database: database
        )
        XCTAssertEqual(saved.origin, "auto")
        XCTAssertEqual(saved.rawSeconds, 5400, "the current figures, not the window's")
        XCTAssertEqual(saved.description, "Importer rewrite")

        try segment(project: project, startMinute: 240, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)

        let all = try entries()
        XCTAssertEqual(all.count, 1, "still one entry, no supplement")
        XCTAssertEqual(all[0].rawSeconds, 7200, "and it keeps growing")
        XCTAssertEqual(all[0].description, "Importer rewrite", "the words survive the recompute")
    }

    func testSettingTheDescriptionOfALockedEntryIsRefused() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: entry.id, to: .billed, source: "user", database: database)

        XCTAssertThrowsError(try BillingRollup.setDescription(
            entryId: entry.id, description: "Too late", database: database
        ))
        XCTAssertEqual(try database.billingEntry(id: entry.id)?.description, entry.description)
    }

    /// Status moves only through `setStatus`, which writes the audit row. A
    /// save that tries to move it is refused rather than silently unaudited.
    func testSavingCannotChangeStatus() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)

        let moved = BillingEntryDTO(
            id: entry.id, projectId: entry.projectId, day: entry.day, groupKey: entry.groupKey,
            rawSeconds: entry.rawSeconds, billedSeconds: entry.billedSeconds, rateCents: entry.rateCents,
            amountCents: entry.amountCents, status: BillingStatus.paid.rawValue
        )
        XCTAssertThrowsError(try BillingRollup.saveEntry(moved, database: database)) { error in
            XCTAssertTrue(error.localizedDescription.contains("Change its status instead"),
                          error.localizedDescription)
        }
        XCTAssertEqual(try database.billingEntry(id: entry.id)?.status, "unbilled")
        XCTAssertTrue(try database.billingEntryAudit(entryId: entry.id, limit: 10).isEmpty)

        let newAndPaid = BillingEntryDTO(
            id: "", projectId: project.id, day: "2026-09-23",
            rawSeconds: 0, billedSeconds: 900, rateCents: 10_000, amountCents: 2_500, status: "paid"
        )
        XCTAssertThrowsError(try BillingRollup.saveEntry(newAndPaid, database: database),
                             "a new entry starts unbilled; paying it is a status change")
    }

    /// Amounts are never summed across currencies.
    func testTheOverviewKeepsCurrenciesApart() throws {
        let project = try makeProject()
        for (index, currency) in ["USD", "EUR", "EUR"].enumerated() {
            _ = try BillingRollup.saveEntry(BillingEntryDTO(
                id: "", projectId: project.id, day: "2026-09-2\(index)", groupKey: "manual-\(index)",
                rawSeconds: 3600, billedSeconds: 3600, rateCents: 10_000, currency: currency,
                amountCents: 10_000
            ), database: database)
        }

        let overview = try BillingRollup.overview(database: database)

        XCTAssertEqual(overview.byCurrency.map(\.currency), ["EUR", "USD"], "most entries first")
        XCTAssertEqual(overview.byCurrency[0].unbilled.amountCents, 20_000)
        XCTAssertEqual(overview.byCurrency[1].unbilled.amountCents, 10_000)
        XCTAssertEqual(overview.currency, "EUR")
        XCTAssertEqual(overview.unbilled.amountCents, 20_000, "the top level is one currency, never a mix")
    }

    // MARK: - Review batch b1

    /// The row as the editor would send it back, with the named figures changed.
    private func copy(
        _ entry: BillingEntryDTO, billedSeconds: Int? = nil, rateCents: Int? = nil, amountCents: Int? = nil
    ) -> BillingEntryDTO {
        BillingEntryDTO(
            id: entry.id, projectId: entry.projectId, clientId: entry.clientId, day: entry.day,
            groupKey: entry.groupKey, startedAt: entry.startedAt, endedAt: entry.endedAt,
            rawSeconds: entry.rawSeconds, billedSeconds: billedSeconds ?? entry.billedSeconds,
            rateCents: rateCents ?? entry.rateCents, currency: entry.currency,
            amountCents: amountCents ?? entry.amountCents,
            roundingMinutes: entry.roundingMinutes, roundingMode: entry.roundingMode,
            status: entry.status, description: entry.description, origin: entry.origin,
            locked: entry.locked, supplementsEntryId: entry.supplementsEntryId,
            createdAt: entry.createdAt, updatedAt: entry.updatedAt
        )
    }

    /// V22-a: raising the project's rate mid-day leaves the morning at the
    /// morning's rate; the afternoon gets an entry of its own.
    func testARateChangeMidDayNeverRepricesEarlierTime() throws {
        let project = try makeProject(rate: 10_000)
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let morning = try XCTUnwrap(entries().first)

        _ = try BillingStore.saveProject(
            BillingProjectDTO(id: project.id, name: "P", defaultRateCents: 12_000), database: database
        )
        try segment(project: project, startMinute: 240, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)

        let byRate = Dictionary(uniqueKeysWithValues: try entries().map { ($0.rateCents, $0) })
        XCTAssertEqual(Set(byRate.keys), [10_000, 12_000])
        XCTAssertEqual(byRate[10_000]?.id, morning.id)
        XCTAssertEqual(byRate[10_000]?.amountCents, 10_000, "the morning is not repriced")
        XCTAssertEqual(byRate[12_000]?.amountCents, 12_000)
    }

    /// A day entry written before keys carried the rate (`''`) still owns
    /// time at its own rate, and is re-keyed rather than duplicated.
    func testALegacyPlainKeyedEntryKeepsCollectingItsRate() throws {
        let project = try makeProject(rate: 10_000)
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let entry = try XCTUnwrap(entries().first)
        try database.execute("UPDATE billing_entry SET group_key = '' WHERE id = ?", params: [entry.id])

        try segment(project: project, startMinute: 120, seconds: 1800)
        _ = try BillingRollup.run(options: options, database: database)

        let all = try entries()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, entry.id)
        XCTAssertEqual(all.first?.rawSeconds, 5400)
        XCTAssertEqual(all.first?.groupKey, "rate:10000")
    }

    /// V2-b: overlapping sessions — the entry ends when the last work ends,
    /// not when the segment that started last ends.
    func testAnEntryEndsAtTheLatestEnd() throws {
        let project = try makeProject()
        let long = try segment(project: project, startMinute: 0, seconds: 8 * 3600, sessionId: "a")
        try segment(project: project, startMinute: 60, seconds: 3600, sessionId: "b")
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try entries().first?.endedAt, long.endedAt)
    }

    /// V5-c: a save built from a row the rollup has since grown is refused,
    /// never written over the time just attached.
    func testAStaleSaveIsRefused() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let stale = try XCTUnwrap(entries().first)

        try segment(project: project, startMinute: 120, seconds: 2700)
        _ = try BillingRollup.run(options: options, database: database)

        let edited = copy(stale, rateCents: 17_500, amountCents: 17_500)
        XCTAssertThrowsError(try BillingRollup.saveEntry(edited, database: database)) { error in
            XCTAssertTrue(error.localizedDescription.contains("changed since you opened it"),
                          error.localizedDescription)
        }
        let kept = try XCTUnwrap(database.billingEntry(id: stale.id))
        XCTAssertEqual(kept.rawSeconds, 6300, "the attached time is still billed")
        XCTAssertEqual(kept.origin, "auto")
    }

    /// V4-a: the rollup's write is guarded in SQL — a row billed since it was
    /// read is never unlocked or reset to unbilled by it.
    func testTheRollupsWriteNeverOverwritesABilledEntry() throws {
        let project = try makeProject()
        try segment(project: project, startMinute: 0, seconds: 3600)
        _ = try BillingRollup.run(options: options, database: database)
        let stale = try XCTUnwrap(entries().first)
        _ = try BillingRollup.setStatus(entryId: stale.id, to: .billed, source: "user", database: database)

        let written = try database.upsertBillingEntry(
            copy(stale, billedSeconds: 5400), overwrite: .rollupOwned
        )

        XCTAssertFalse(written)
        let kept = try XCTUnwrap(database.billingEntry(id: stale.id))
        XCTAssertEqual(kept.status, "billed")
        XCTAssertTrue(kept.locked)
        XCTAssertEqual(kept.billedSeconds, 3600)
    }

    /// V4-b: a promote racing the scheduled pass rolls each segment once —
    /// no unique-index collision, no double count.
    func testAPromoteRacingThePassRollsEachSegmentOnce() throws {
        let project = try makeProject()
        var ids: [String] = []
        for index in 0..<8 {
            ids.append(try segment(project: project, startMinute: index * 30, seconds: 1200,
                                   sessionId: "s\(index)").id)
        }
        let database = self.database!
        let options = self.options
        let failures = LockedCounter()
        DispatchQueue.concurrentPerform(iterations: 4) { index in
            do {
                if index.isMultiple(of: 2) {
                    _ = try BillingRollup.run(options: options, database: database)
                } else {
                    _ = try BillingRollup.promoteSegments(ids: ids, options: options, database: database)
                }
            } catch {
                failures.increment()
            }
        }

        XCTAssertEqual(failures.value, 0)
        let all = try entries()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.rawSeconds, 8 * 1200)
    }

    /// V2-c: the note typed on a timer reaches the billable.
    func testATimersNoteReachesTheDescription() throws {
        let project = try makeProject()
        try database.upsertBillingSegment(BillingSegmentDTO(
            id: "timer", origin: "manual", projectId: project.id,
            startedAt: "2026-09-22T09:00:00Z", endedAt: "2026-09-22T10:00:00Z",
            tz: "UTC", seconds: 3600, note: "Call with the client"
        ))
        _ = try BillingRollup.run(options: options, database: database)

        XCTAssertEqual(try entries().first?.description, "Call with the client")
    }
}

/// A counter the concurrent test's workers can share.
private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.withLock { count } }
    func increment() { lock.withLock { count += 1 } }
}
