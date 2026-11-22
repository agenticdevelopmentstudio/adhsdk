import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The read-only billing surface. These tests care about shape and bounds:
/// the numbers themselves are the store's contract and are tested there.
final class BillingRoutesTests: XCTestCase {

    // swiftlint:disable:next identifier_name
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var table: RouteTable!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        table = BillingRoutes.table(database: db)
    }

    override func tearDownWithError() throws {
        table = nil
        db = nil
        TestDaemonDatabase.remove(path: dbPath)
    }

    // MARK: - Helpers

    /// Sends `method path` through the table; nil when no route claims it.
    private func send(_ method: String, _ target: String) async throws -> RouteResponse? {
        let components = try XCTUnwrap(URLComponents(string: target))
        var query: [String: [String]] = [:]
        for item in components.queryItems ?? [] {
            query[item.name, default: []].append(item.value ?? "")
        }
        return await table.handle(RouteRequest(method: method, path: components.path, queryValues: query))
    }

    private func array(_ response: RouteResponse?) throws -> [[String: Any]] {
        let body = try XCTUnwrap(response?.body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
    }

    private func object(_ response: RouteResponse?) throws -> [String: Any] {
        let body = try XCTUnwrap(response?.body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @discardableResult
    private func seedProject(name: String = "Rewrite") throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: name, defaultRateCents: 12_000), database: db
        )
    }

    private func seedSegment(id: String, startedAt: String, endedAt: String) throws {
        try db.upsertBillingSegment(BillingSegmentDTO(
            id: id, sessionId: "s1", origin: "auto", projectRoot: "/src/app",
            startedAt: startedAt, endedAt: endedAt, tz: "UTC", seconds: 1800
        ))
    }

    // MARK: - Listing

    func testClientsRouteRepliesSnakeCaseJSON() async throws {
        _ = try BillingStore.saveClient(
            BillingClientDTO(id: "", name: "Acme", contactName: "Dana Reed"), database: db
        )

        let rows = try array(try await send("GET", "/billing/clients"))

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["name"] as? String, "Acme")
        XCTAssertEqual(rows[0]["contact_name"] as? String, "Dana Reed",
                       "HTTP speaks snake_case; a camelCase key here would be a silent break")
    }

    func testProjectsRoute() async throws {
        try seedProject()

        let rows = try array(try await send("GET", "/billing/projects"))

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["default_rate_cents"] as? Int, 12_000)
    }

    func testEntriesRouteFiltersByProjectAndStatus() async throws {
        let project = try seedProject()
        _ = try BillingRollup.saveEntry(BillingEntryDTO(
            id: "", projectId: project.id, day: "2026-09-22",
            rawSeconds: 3600, billedSeconds: 3600, rateCents: 12_000, amountCents: 12_000
        ), database: db)

        let all = try array(try await send("GET", "/billing/entries"))
        let byProject = try array(try await send("GET", "/billing/entries?project_id=\(project.id)"))
        let byOtherProject = try array(try await send("GET", "/billing/entries?project_id=nope"))
        let byStatus = try array(try await send("GET", "/billing/entries?status=paid"))

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(byProject.count, 1)
        XCTAssertTrue(byOtherProject.isEmpty)
        XCTAssertTrue(byStatus.isEmpty)
    }

    func testEntriesRouteRejectsAMalformedSince() async throws {
        let response = try await send("GET", "/billing/entries?since=last%20tuesday")

        XCTAssertEqual(response?.status, 400, "a bad filter is a bad request, not an empty list")
    }

    /// The shape is not enough: a month or day that no calendar has is a
    /// typo, and answering it with an empty (or unfiltered) list hides that.
    func testEntriesRouteRejectsAnImpossibleDay() async throws {
        for since in ["2026-13-01", "2026-00-15", "2026-02-30", "2026-99-99"] {
            let response = try await send("GET", "/billing/entries?since=\(since)")
            XCTAssertEqual(response?.status, 400, since)
        }
        let valid = try await send("GET", "/billing/entries?since=2028-02-29")
        XCTAssertEqual(valid?.status, 200, "a leap day is a real day")
    }

    func testSegmentsRouteIsBounded() async throws {
        for index in 0..<5 {
            try seedSegment(
                id: "seg\(index)",
                startedAt: "2026-09-22T09:0\(index):00Z",
                endedAt: "2026-09-22T09:3\(index):00Z"
            )
        }

        let limited = try array(try await send("GET", "/billing/segments?limit=2"))
        let absurd = try array(try await send("GET", "/billing/segments?limit=99999"))

        XCTAssertEqual(limited.count, 2)
        XCTAssertEqual(absurd.count, 5, "an absurd limit clamps instead of failing")
    }

    func testSegmentsRouteFiltersBySince() async throws {
        try seedSegment(id: "old", startedAt: "2026-09-20T09:00:00Z", endedAt: "2026-09-20T09:30:00Z")
        try seedSegment(id: "new", startedAt: "2026-09-22T09:00:00Z", endedAt: "2026-09-22T09:30:00Z")

        let rows = try array(try await send("GET", "/billing/segments?since=2026-09-21T00:00:00Z"))

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["id"] as? String, "new")
    }

    // MARK: - Overview

    func testOverviewRouteRepliesEveryBucket() async throws {
        let overview = try object(try await send("GET", "/billing/overview"))

        for bucket in ["unbilled", "billed", "paid"] {
            let node = try XCTUnwrap(overview[bucket] as? [String: Any])
            XCTAssertEqual(node["entry_count"] as? Int, 0)
            XCTAssertEqual(node["amount_cents"] as? Int, 0)
        }
        XCTAssertEqual(overview["currency"] as? String, "USD")
    }

    // MARK: - Method and shape

    func testBillingRoutesAreReadOnly() async throws {
        let response = try await send("POST", "/billing/entries")
        XCTAssertEqual(response?.status, 405, "HTTP must not be able to write billing state")
    }

    func testAnUnknownBillingSubpathIs404() async throws {
        let response = try await send("GET", "/billing/nonsense")
        XCTAssertEqual(response?.status, 404)
    }

    func testAPathOutsideBillingIsLeftToTheDaemon() async throws {
        let response = try await send("GET", "/sessions")
        XCTAssertNil(response)
    }
}
