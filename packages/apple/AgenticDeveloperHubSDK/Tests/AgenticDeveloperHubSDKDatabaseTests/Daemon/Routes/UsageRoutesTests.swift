import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The usage surface's bounds: a bound that does not parse is a 400, never a
/// page that compares a stray string against the stored days or timestamps.
final class UsageRoutesTests: XCTestCase {

    // swiftlint:disable:next identifier_name
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var table: RouteTable!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        table = UsageRoutes.table(database: db)
        for day in ["2026-10-31", "2026-11-01", "2026-11-02"] {
            try db.execute(
                "INSERT INTO daily_metric (day, metric, dimension, count, value_sum) VALUES (?, 'event', '', 1, 0)",
                params: [day]
            )
        }
    }

    override func tearDownWithError() throws {
        table = nil
        db = nil
        TestDaemonDatabase.remove(path: dbPath)
    }

    private func get(_ target: String) async throws -> RouteResponse? {
        let components = try XCTUnwrap(URLComponents(string: target))
        var query: [String: [String]] = [:]
        for item in components.queryItems ?? [] {
            query[item.name, default: []].append(item.value ?? "")
        }
        return await table.handle(RouteRequest(method: "GET", path: components.path, queryValues: query))
    }

    private func days(_ response: RouteResponse?) throws -> [String] {
        let body = try XCTUnwrap(response?.body)
        let rows = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        return rows.compactMap { $0["day"] as? String }
    }

    func testDailyMetricsRefusesAMalformedBound() async throws {
        for query in ["from=11/01/2026", "to=11/02/2026", "from=2026-11-01garbage", "to=2026-02-30", "from=yesterday"] {
            let response = try await get("/insights/daily-metrics?\(query)")
            XCTAssertEqual(response?.status, 400, query)
        }
    }

    func testDailyMetricsFiltersByDayOrATimestampsDay() async throws {
        let all = try await get("/insights/daily-metrics")
        let byDay = try await get("/insights/daily-metrics?from=2026-11-01&to=2026-11-01")
        let byTimestamp = try await get("/insights/daily-metrics?from=2026-11-01T12:00:00Z&to=2026-11-02T00:00:00Z")
        let emptyBounds = try await get("/insights/daily-metrics?from=&to=")

        XCTAssertEqual(try days(all), ["2026-10-31", "2026-11-01", "2026-11-02"])
        XCTAssertEqual(try days(byDay), ["2026-11-01"])
        XCTAssertEqual(try days(byTimestamp), ["2026-11-01", "2026-11-02"])
        XCTAssertEqual(try days(emptyBounds).count, 3, "an empty bound is no bound")
    }
}
