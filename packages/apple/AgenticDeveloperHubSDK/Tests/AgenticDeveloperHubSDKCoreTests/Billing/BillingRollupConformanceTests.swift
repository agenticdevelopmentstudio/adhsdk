import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors billing-rollup-001 ... 017, run against an in-memory
/// persistence so the real rollup rules (`BillingRollup`) are what is tested.
final class BillingRollupConformanceTests: XCTestCase {

    private let day = "2026-09-22"

    private func makeDatabase(rate: Int? = 12000) -> InMemoryBillingPersistence {
        let database = InMemoryBillingPersistence()
        database.projects = [BillingProjectDTO(id: "p1", name: "Site", defaultRateCents: rate)]
        return database
    }

    private func segment(
        _ id: String, start: String, seconds: Int, session: String = "s1", projectId: String? = "p1",
        root: String = "/app"
    ) -> BillingSegmentDTO {
        BillingSegmentDTO(
            id: id, sessionId: session, origin: "auto", projectId: projectId, projectRoot: root,
            startedAt: start, endedAt: UTCTimestamp.string(
                epochSeconds: (UTCTimestamp.epochSeconds(start) ?? 0) + seconds
            ), tz: "UTC", seconds: seconds
        )
    }

    private func at(_ time: String) -> String { "\(day)T\(time)Z" }

    @discardableResult
    private func rollOne(_ database: InMemoryBillingPersistence, options: BillingRollupOptions = BillingRollupOptions())
        throws -> BillingEntryDTO {
        try BillingRollup.run(options: options, database: database)
        return try XCTUnwrap(database.entries.first { $0.supplementsEntryId == nil })
    }

    func testV001_dayGranularityGroupKeyIsTheRate() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database, options: BillingRollupOptions(granularity: .day))
        XCTAssertEqual(entry.groupKey, "rate:12000")
        XCTAssertEqual(BillingRollup.dayGroupKey(rateCents: 12000), "rate:12000")
    }

    func testV002_runGranularityGroupKeyIsTheRunIdentity() throws {
        let start = at("14:00:00")
        let auto = segment("a", start: start, seconds: 900, session: "s1")
        XCTAssertEqual(BillingRollup.runGroupKey(for: auto), "s1|\(start)")

        let database = makeDatabase()
        database.segments = [auto]
        let entry = try rollOne(database, options: BillingRollupOptions(granularity: .run))
        XCTAssertEqual(entry.groupKey, "s1|\(start)")
    }

    func testV003_roundsOnceOverTheTotal() throws {
        let database = makeDatabase()
        database.segments = (0..<5).map {
            segment("s\($0)", start: at(String(format: "10:%02d:00", $0 * 10)), seconds: 300)
        }
        let entry = try rollOne(database)
        XCTAssertEqual(entry.rawSeconds, 1500)
        XCTAssertEqual(entry.billedSeconds, 1800)
        XCTAssertEqual(database.entries.count, 1)
    }

    func testV004_amountIsBilledSecondsTimesRate() throws {
        XCTAssertEqual(BillingRollup.amountCents(billedSeconds: 5400, rateCents: 12000), 18000)
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 5400)]
        let entry = try rollOne(database)
        XCTAssertEqual(entry.billedSeconds, 5400)
        XCTAssertEqual(entry.amountCents, 18000)
    }

    func testV005_frozenOwnerGetsASupplement() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let owner = try rollOne(database)
        let billed = try BillingRollup.setStatus(
            entryId: owner.id, to: .billed, source: "test", database: database
        )
        database.segments.append(segment("b", start: at("12:00:00"), seconds: 900))

        try BillingRollup.run(options: BillingRollupOptions(), database: database)

        let supplements = database.entries.filter { $0.supplementsEntryId == owner.id }
        XCTAssertEqual(supplements.count, 1)
        XCTAssertEqual(supplements.first?.rawSeconds, 900)
        XCTAssertEqual(database.segment("b")?.entryId, supplements.first?.id)
        XCTAssertEqual(database.entries.first { $0.id == owner.id }, billed)
    }

    func testV006_entryKeepsItsSnapshottedRate() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        XCTAssertEqual(entry.rateCents, 12000)

        database.projects = [BillingProjectDTO(id: "p1", name: "Site", defaultRateCents: 20000)]
        try BillingRollup.recomputeOwnedEntries(database: database)

        let after = try XCTUnwrap(database.entries.first { $0.id == entry.id })
        XCTAssertEqual(after.rateCents, 12000)
        XCTAssertEqual(after.amountCents, 3000)
    }

    func testV007_lockedEntryIsNotRecomputed() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        let billed = try BillingRollup.setStatus(
            entryId: entry.id, to: .billed, source: "test", database: database
        )
        database.segments = []

        XCTAssertEqual(try BillingRollup.recomputeOwnedEntries(database: database), 0)
        XCTAssertEqual(database.entries, [billed])
    }

    func testV008_entryWithNoSegmentsIsDeleted() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        database.segments = []

        XCTAssertEqual(try BillingRollup.recomputeOwnedEntries(database: database), 1)
        XCTAssertNil(try database.billingEntry(id: entry.id))
    }

    func testV009_descriptionOnlyEditKeepsAutoOrigin() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        XCTAssertEqual(entry.origin, "auto")

        let saved = try BillingRollup.saveEntry(entry.testCopy(description: "Reworked the header"), database: database)

        XCTAssertEqual(saved.origin, "auto")
        XCTAssertEqual(saved.description, "Reworked the header")
        XCTAssertTrue(database.isDescriptionEdited(entry.id))
    }

    func testV010_changingHoursMakesTheEntryUser() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)

        let saved = try BillingRollup.saveEntry(
            entry.testCopy(billedSeconds: 3600, amountCents: 12000), database: database
        )

        XCTAssertEqual(saved.origin, "user")
        XCTAssertEqual(saved.billedSeconds, 3600)
    }

    func testV011_staleSaveThrowsEntryChanged() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)

        XCTAssertThrowsError(try BillingRollup.saveEntry(
            entry.testCopy(updatedAt: "1999-01-01T00:00:00Z"), database: database
        )) { error in
            guard case BillingRollup.RollupError.entryChanged = error else {
                return XCTFail("expected entryChanged, got \(error)")
            }
        }
    }

    func testV012_savingALockedEntryThrowsEntryIsLocked() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        let billed = try BillingRollup.setStatus(
            entryId: entry.id, to: .billed, source: "test", database: database
        )

        XCTAssertThrowsError(try BillingRollup.saveEntry(billed, database: database)) { error in
            guard case BillingRollup.RollupError.entryIsLocked = error else {
                return XCTFail("expected entryIsLocked, got \(error)")
            }
        }
    }

    func testV013_unbilledToBilledLocksAndAudits() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)

        let billed = try BillingRollup.setStatus(
            entryId: entry.id, to: .billed, source: "test", database: database
        )

        XCTAssertTrue(billed.locked)
        XCTAssertEqual(billed.status, "billed")
        XCTAssertEqual(
            database.audits,
            [InMemoryBillingPersistence.Audit(
                entryId: entry.id, field: "status", oldValue: "unbilled", newValue: "billed", source: "test"
            )]
        )
    }

    func testV014_billedToUnbilledUnlocksAndAudits() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900)]
        let entry = try rollOne(database)
        try BillingRollup.setStatus(entryId: entry.id, to: .billed, source: "test", database: database)

        let reopened = try BillingRollup.setStatus(
            entryId: entry.id, to: .unbilled, source: "test", database: database
        )

        XCTAssertFalse(reopened.locked)
        XCTAssertEqual(database.audits.count, 2)
        XCTAssertEqual(database.audits.last?.oldValue, "billed")
        XCTAssertEqual(database.audits.last?.newValue, "unbilled")
    }

    func testV015_entryWithABilledSupplementCannotBeDeleted() throws {
        let database = makeDatabase()
        let owner = BillingEntryDTO(
            id: "owner", projectId: "p1", day: day, groupKey: "rate:12000", rawSeconds: 900, billedSeconds: 900,
            rateCents: 12000, amountCents: 3000
        )
        let supplement = BillingEntryDTO(
            id: "supp", projectId: "p1", day: day, groupKey: "rate:12000", rawSeconds: 900, billedSeconds: 900,
            rateCents: 12000, amountCents: 3000, status: "billed", locked: true, supplementsEntryId: "owner"
        )
        database.entries = [owner, supplement]

        XCTAssertThrowsError(try BillingRollup.deleteEntry(id: "owner", database: database)) { error in
            guard case BillingRollup.RollupError.entryHasFrozenSupplements(_, let count) = error else {
                return XCTFail("expected entryHasFrozenSupplements, got \(error)")
            }
            XCTAssertEqual(count, 1)
        }
        XCTAssertEqual(database.entries.count, 2)
    }

    func testV016_overviewHasARowPerCurrencyAndTopLevelIsTheFirst() throws {
        let database = makeDatabase()
        database.entries = [
            BillingEntryDTO(id: "usd", projectId: "p1", day: day, rawSeconds: 900, billedSeconds: 900,
                            rateCents: 12000, currency: "USD", amountCents: 3000),
            BillingEntryDTO(id: "eur", projectId: "p1", day: day, groupKey: "x", rawSeconds: 1800,
                            billedSeconds: 1800, rateCents: 10000, currency: "EUR", amountCents: 5000)
        ]

        let overview = try BillingRollup.overview(database: database)

        XCTAssertEqual(overview.byCurrency.map(\.currency), ["USD", "EUR"])
        XCTAssertEqual(overview.currency, "USD")
        XCTAssertEqual(overview.unbilled, overview.byCurrency[0].unbilled)
        XCTAssertEqual(overview.unbilled.amountCents, 3000)
        XCTAssertEqual(overview.byCurrency[1].unbilled.amountCents, 5000)
        XCTAssertEqual(overview.byCurrency[1].billed.entryCount, 0)
    }

    func testV017_assignRepositoryWithEmptyRootReturnsZero() throws {
        let database = makeDatabase()
        database.segments = [segment("a", start: at("10:00:00"), seconds: 900, projectId: nil, root: "")]

        let moved = try BillingRollup.assignRepository(
            projectRoot: "", projectId: "p1", options: BillingRollupOptions(), database: database
        )

        XCTAssertEqual(moved, 0)
        XCTAssertNil(database.segment("a")?.projectId)
    }
}
