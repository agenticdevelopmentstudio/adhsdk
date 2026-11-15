import XCTest
@testable import AgenticDeveloperHubSDKCore

/// `BillingPersistence` is a protocol: its guard, transaction and cursor
/// semantics belong to the host's storage (Stenographer's SQLite
/// `DatabaseManager`), which lives outside this repository. The vectors that
/// need a real store are skipped with that reason; the value types the
/// contract defines are tested here.
final class BillingPersistenceConformanceTests: XCTestCase {

    private static let hostStore = "needs the host's SQLite store (DatabaseManager), which is outside this repository"

    func testV001_aThrowingTransactionRollsBackEveryWrite() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV002_unlockedGuardRefusesALockedEntry() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV003_rollupOwnedGuardRefusesAUserOriginEntry() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV004_aNewIdAlwaysInserts() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV005_activityCursorFromZeroReturnsEveryInstantAndTheLastId() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV006_activityCursorAtTheLastIdReturnsNothing() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV007_rollupCandidatesExcludeProjectsWithBillingOff() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV008_untrackedContextStoresAFlaggedSegmentNeverRolled() throws {
        throw XCTSkip(Self.hostStore)
    }

    func testV009_resetDerivationReturnsTheDerivedSessionCount() throws {
        throw XCTSkip(Self.hostStore)
    }

    // MARK: - Value types the contract defines

    func testSessionRowCarriesItsFields() {
        let row = BillingSessionRow(
            sessionId: "s1", projectRoot: "/r", branch: "main",
            startedAt: "2026-09-22T10:00:00Z", lastActivityAt: "2026-09-22T11:00:00Z", isActive: true
        )
        XCTAssertEqual(row.sessionId, "s1")
        XCTAssertEqual(row.projectRoot, "/r")
        XCTAssertEqual(row.branch, "main")
        XCTAssertEqual(row.startedAt, "2026-09-22T10:00:00Z")
        XCTAssertEqual(row.lastActivityAt, "2026-09-22T11:00:00Z")
        XCTAssertTrue(row.isActive)
    }

    func testSegmentContextForUnassignedHasNoProjectOrRepo() {
        let context = BillingSegmentContext(
            projectId: nil, repoId: nil, projectRoot: "/r", branch: "main", tz: "UTC", tracked: false
        )
        XCTAssertNil(context.projectId)
        XCTAssertNil(context.repoId)
        XCTAssertFalse(context.tracked)
        XCTAssertEqual(context.tz, "UTC")
    }

    func testStoredEntryPairsTheEntryWithItsDescriptionEditedFlag() {
        let entry = BillingEntryDTO(id: "e1", projectId: "p1", day: "2026-09-22",
            rawSeconds: 0, billedSeconds: 0, rateCents: 0, amountCents: 0)
        let stored = StoredBillingEntry(entry: entry, descriptionEdited: true)
        XCTAssertEqual(stored.entry, entry)
        XCTAssertTrue(stored.descriptionEdited)
        XCTAssertNil(stored.billedRanges, "ranges are never recorded unless given")
    }

    func testOverwriteGuardsAreDistinct() {
        XCTAssertNotEqual(BillingEntryOverwrite.any, .unlocked)
        XCTAssertNotEqual(BillingEntryOverwrite.unlocked, .rollupOwned)
    }
}
