import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors billing-store-001 ... 012, against an in-memory
/// persistence.
final class BillingStoreConformanceTests: XCTestCase {

    private func database() -> InMemoryBillingPersistence {
        let database = InMemoryBillingPersistence()
        database.projects = [BillingProjectDTO(id: "p1", name: "Existing")]
        return database
    }

    func testV001_blankClientNameIsRefused() throws {
        XCTAssertThrowsError(try BillingStore.saveClient(
            BillingClientDTO(id: "", name: "  "), database: database()
        )) { error in
            guard case BillingStore.BillingError.missingName = error else {
                return XCTFail("expected missingName, got \(error)")
            }
        }
    }

    func testV002_duplicateProjectNameIsRefused() throws {
        let fakeDB = database()
        try fakeDB.upsertBillingProject(BillingProjectDTO(id: "other", name: "Site"))

        XCTAssertThrowsError(try BillingStore.saveProject(BillingProjectDTO(id: "", name: "Site"), database: fakeDB)) {
            guard case BillingStore.BillingError.duplicateName(let name) = $0 else {
                return XCTFail("expected duplicateName, got \($0)")
            }
            XCTAssertEqual(name, "Site")
        }
    }

    func testV003_roundingZeroIsRefused() throws {
        XCTAssertThrowsError(try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "New", roundingMinutes: 0), database: database()
        )) {
            guard case BillingStore.BillingError.invalidRounding(let minutes) = $0 else {
                return XCTFail("expected invalidRounding, got \($0)")
            }
            XCTAssertEqual(minutes, 0)
        }
    }

    func testV004_rounding241IsRefused() throws {
        XCTAssertThrowsError(try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "New", roundingMinutes: 241), database: database()
        )) {
            guard case BillingStore.BillingError.invalidRounding(let minutes) = $0 else {
                return XCTFail("expected invalidRounding, got \($0)")
            }
            XCTAssertEqual(minutes, 241)
        }
    }

    func testV005_negativeRepoRateIsRefused() throws {
        XCTAssertThrowsError(try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: "p1", projectRoot: "/app", rateCents: -1), database: database()
        )) {
            guard case BillingStore.BillingError.invalidRate(let cents) = $0 else {
                return XCTFail("expected invalidRate, got \($0)")
            }
            XCTAssertEqual(cents, -1)
        }
    }

    func testV006_secondRepoForTheSameRootAndBranchIsRefused() throws {
        let fakeDB = database()
        try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: "p1", projectRoot: "/app", branch: "main"), database: fakeDB
        )

        XCTAssertThrowsError(try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: "p1", projectRoot: " /app ", branch: "main"), database: fakeDB
        )) {
            guard case BillingStore.BillingError.repoAlreadyClaimed = $0 else {
                return XCTFail("expected repoAlreadyClaimed, got \($0)")
            }
        }
        XCTAssertEqual(fakeDB.repos.count, 1)
    }

    func testV007_danglingClientIsStoredAsNoClient() throws {
        let fakeDB = database()

        let stored = try BillingStore.saveProject(
            BillingProjectDTO(id: "", clientId: "gone", name: "New"), database: fakeDB
        )

        XCTAssertNil(stored.clientId)
        XCTAssertNil(fakeDB.projects.first { $0.id == stored.id }?.clientId)
    }

    func testV008_saveWithEmptyIdAssignsIdAndStamps() throws {
        let stored = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Acme"), database: database())

        XCTAssertFalse(stored.id.isEmpty)
        XCTAssertFalse(stored.createdAt.isEmpty)
        XCTAssertEqual(stored.createdAt, stored.updatedAt)
    }

    func testV009_projectWithAnEntryCannotBeDeleted() throws {
        let fakeDB = database()
        fakeDB.entries = [BillingEntryDTO(id: "e", projectId: "p1", day: "2026-09-22", rawSeconds: 900,
                                      billedSeconds: 900, rateCents: 0, amountCents: 0)]

        XCTAssertThrowsError(try BillingStore.deleteProject(id: "p1", database: fakeDB)) {
            guard case BillingStore.BillingError.projectHasEntries(_, let count) = $0 else {
                return XCTFail("expected projectHasEntries, got \($0)")
            }
            XCTAssertEqual(count, 1)
        }
        XCTAssertEqual(fakeDB.projects.count, 1)
    }

    func testV010_clientWithBilledEntriesCannotBeDeleted() throws {
        let fakeDB = database()
        try fakeDB.upsertBillingClient(BillingClientDTO(id: "c1", name: "Acme"))
        fakeDB.entries = ["e1", "e2"].map {
            BillingEntryDTO(id: $0, projectId: "p1", clientId: "c1", day: "2026-09-22", rawSeconds: 900,
                            billedSeconds: 900, rateCents: 0, amountCents: 0, status: "billed", locked: true)
        }

        XCTAssertThrowsError(try BillingStore.deleteClient(id: "c1", database: fakeDB)) {
            guard case BillingStore.BillingError.clientHasBilledEntries(_, let count) = $0 else {
                return XCTFail("expected clientHasBilledEntries, got \($0)")
            }
            XCTAssertEqual(count, 2)
        }
        XCTAssertEqual(fakeDB.clients.count, 1)
    }

    func testV011_repoWithBillingOffIsNotTracked() throws {
        let fakeDB = database()
        fakeDB.repos = [BillingRepoDTO(id: "r1", projectId: "p1", projectRoot: "/app", billingEnabled: false)]
        fakeDB.activity["s1"] = [1_790_000_000, 1_790_000_060]
        let session = BillingSessionRow(
            sessionId: "s1", projectRoot: "/app", branch: "main", startedAt: "2026-09-22T14:00:00Z",
            lastActivityAt: "2026-09-22T14:01:00Z", isActive: false
        )

        try BillingStore.deriveSegments(
            for: session, cutoffSeconds: 900, now: "2026-09-22T15:00:00Z", database: fakeDB
        )

        XCTAssertEqual(fakeDB.derivedCalls.count, 1)
        XCTAssertEqual(fakeDB.derivedCalls.first?.context.tracked, false)
        XCTAssertEqual(fakeDB.derivedCalls.first?.context.projectId, "p1")
    }

    func testV012_unassignedOptOutWritesNothingClosesRunsAndStampsTheWatermark() throws {
        let fakeDB = database()
        let start = 1_790_000_000
        fakeDB.activity["s1"] = [start, start + 60, start + 120]
        let startStamp = UTCTimestamp.string(epochSeconds: start)
        fakeDB.segments = [BillingSegmentDTO(id: "open", sessionId: "s1", origin: "auto", startedAt: startStamp)]
        let session = BillingSessionRow(
            sessionId: "s1", projectRoot: "/unclaimed", branch: "main", startedAt: startStamp,
            lastActivityAt: "2026-09-22T14:02:00Z", isActive: false
        )

        let written = try BillingStore.deriveSegments(
            for: session, cutoffSeconds: 900, trackUnassigned: false,
            now: UTCTimestamp.string(epochSeconds: start + 7200), database: fakeDB
        )

        XCTAssertEqual(written, 0)
        XCTAssertTrue(fakeDB.derivedCalls.isEmpty)
        let closed = try XCTUnwrap(fakeDB.segment("open"))
        XCTAssertFalse(closed.isRunning)
        XCTAssertEqual(closed.seconds, 120)
        XCTAssertEqual(fakeDB.derivedMarks["s1"], "2026-09-22T14:02:00Z")
    }
}
