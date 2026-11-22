import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// `/activity/*` as the routes see it. The tracker is a recording fake: what
/// the controller does with Accessibility is `WorkTrackingControllerTests`'
/// contract, and these tests prove only which call each route makes — above
/// all that reading the status never reaches `recheck`, the one call that asks
/// the system.
final class ActivityRoutesTests: XCTestCase {

    /// Counts each control call and answers a fixed status.
    private final class FakeTracker: @unchecked Sendable {
        struct Refused: Error {}
        private let lock = NSLock()
        private var calls: [String] = []
        private var applied: [WorkTrackingPreferences] = []
        var applyThrows = false

        var log: [String] { lock.withLock { calls } }
        var appliedPreferences: [WorkTrackingPreferences] { lock.withLock { applied } }

        private func record(_ name: String) { lock.withLock { calls.append(name) } }

        var control: ActivityRoutes.WorkTrackingControl {
            ActivityRoutes.WorkTrackingControl(
                status: { [self] in
                    record("status")
                    return WorkTrackingStatus(enabled: false, accessibility: .unknown)
                },
                apply: { [self] prefs in
                    record("apply")
                    lock.withLock { applied.append(prefs) }
                    if applyThrows { throw Refused() }
                    return WorkTrackingStatus(enabled: prefs.enabled, accessibility: .granted)
                },
                recheck: { [self] in
                    record("recheck")
                    return WorkTrackingStatus(enabled: false, accessibility: .denied)
                }
            )
        }
    }

    // swiftlint:disable:next identifier_name
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var tracker: FakeTracker!
    private var table: RouteTable!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        tracker = FakeTracker()
        table = ActivityRoutes.table(database: db, workTracking: tracker.control, appRegistry: nil)
    }

    override func tearDownWithError() throws {
        table = nil
        tracker = nil
        db = nil
        TestDaemonDatabase.remove(path: dbPath)
    }

    // MARK: - Helpers

    private func send(
        _ method: String, _ target: String, body: Data = Data(), table: RouteTable? = nil
    ) async throws -> RouteResponse? {
        let components = try XCTUnwrap(URLComponents(string: target))
        var query: [String: [String]] = [:]
        for item in components.queryItems ?? [] {
            query[item.name, default: []].append(item.value ?? "")
        }
        return await (table ?? self.table).handle(RouteRequest(
            method: method, path: components.path, queryValues: query, body: body
        ))
    }

    private func object(_ response: RouteResponse?) throws -> [String: Any] {
        let body = try XCTUnwrap(response?.body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func array(_ response: RouteResponse?) throws -> [[String: Any]] {
        let body = try XCTUnwrap(response?.body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
    }

    private func prefsBody(enabled: Bool) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        var prefs = WorkTrackingPreferences.default
        prefs.enabled = enabled
        return try encoder.encode(prefs)
    }

    private func seedSpan(_ id: String, startedAt: String, endedAt: String = "") throws {
        try db.openActivitySpan(ActivitySpanDTO(
            id: id, bundleId: "com.apple.dt.Xcode", appName: "Xcode",
            startedAt: startedAt, endedAt: endedAt, tz: "UTC"
        ))
    }

    // MARK: - Status

    func testStatusAnswersSnakeCaseAndNeverRechecks() async throws {
        let response = try await send("GET", "/activity/status")

        XCTAssertEqual(response?.status, 200)
        let status = try object(response)
        XCTAssertNotNil(status["enabled"])
        XCTAssertNotNil(status["write_failures"])
        XCTAssertEqual(tracker.log, ["status"], "a status read must never ask the system for Accessibility")
    }

    func testWithoutATrackerEveryWorkTrackingRouteIs503() async throws {
        let bare = ActivityRoutes.table(database: db, workTracking: nil, appRegistry: nil)

        let status = try await send("GET", "/activity/status", table: bare)
        let prefs = try await send("POST", "/activity/preferences", body: try prefsBody(enabled: true), table: bare)
        let recheck = try await send("POST", "/activity/recheck", table: bare)

        XCTAssertEqual(status?.status, 503)
        XCTAssertEqual(prefs?.status, 503)
        XCTAssertEqual(recheck?.status, 503)
    }

    // MARK: - Controls

    func testPreferencesApplyAndAnswerTheStatusTheyProduced() async throws {
        let response = try await send("POST", "/activity/preferences", body: try prefsBody(enabled: true))

        XCTAssertEqual(response?.status, 200)
        XCTAssertEqual(try object(response)["enabled"] as? Bool, true)
        XCTAssertEqual(tracker.log, ["apply"])
        XCTAssertEqual(tracker.appliedPreferences.first?.enabled, true)
        XCTAssertEqual(tracker.appliedPreferences.first?.retentionDays, WorkTrackingPreferences.defaultRetentionDays)
    }

    func testAnUnreadablePreferencesBodyAppliesNothing() async throws {
        let response = try await send("POST", "/activity/preferences", body: Data("not json".utf8))

        XCTAssertEqual(response?.status, 400)
        XCTAssertTrue(tracker.log.isEmpty)
    }

    func testAFailedApplyIsA500NotAStatus() async throws {
        tracker.applyThrows = true

        let response = try await send("POST", "/activity/preferences", body: try prefsBody(enabled: false))

        XCTAssertEqual(response?.status, 500, "a push that was not applied must not read as delivered")
    }

    func testRecheckIsThePostThatAsksAgain() async throws {
        let response = try await send("POST", "/activity/recheck")

        XCTAssertEqual(try object(response)["accessibility"] as? String, "denied")
        XCTAssertEqual(tracker.log, ["recheck"])
    }

    func testRecheckHasNoGetRoute() async throws {
        let response = try await send("GET", "/activity/recheck")

        XCTAssertEqual(response?.status, 404)
        XCTAssertTrue(tracker.log.isEmpty, "a GET, which a link or a prefetch can send, never re-asks")
    }

    // MARK: - Spans

    func testSpansAreNewestFirstAndBounded() async throws {
        for index in 0..<3 {
            try seedSpan("s\(index)", startedAt: "2026-10-03T1\(index):00:00Z")
        }

        let rows = try array(try await send("GET", "/activity/spans?limit=1"))

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?["id"] as? String, "s2")
        XCTAssertEqual(rows.first?["app_name"] as? String, "Xcode")
    }

    func testSpansLimitIsClampedToTheCeiling() async throws {
        try db.transaction {
            for index in 0..<1005 {
                try seedSpan("c\(index)", startedAt: "2026-10-03T10:00:00.\(String(format: "%06d", index))Z")
            }
        }

        let rows = try array(try await send("GET", "/activity/spans?limit=5000"))
        let lowest = try array(try await send("GET", "/activity/spans?limit=-5"))

        XCTAssertEqual(rows.count, 1000)
        XCTAssertEqual(lowest.count, 1)
    }

    func testSpansBadSinceIs400() async throws {
        let response = try await send("GET", "/activity/spans?since=yesterday")
        XCTAssertEqual(response?.status, 400)
    }

    func testSinceIsWholeSecondAgainstStoredEndTimes() async throws {
        try seedSpan("on", startedAt: "2026-10-03T09:00:00Z", endedAt: "2026-10-03T11:00:00Z")
        try seedSpan("before", startedAt: "2026-10-03T09:00:00Z", endedAt: "2026-10-03T10:59:59Z")

        let rows = try array(try await send("GET", "/activity/spans?since=2026-10-03T11:00:00.500Z"))
        let all = try array(try await send("GET", "/activity/spans?since="))

        XCTAssertEqual(rows.compactMap { $0["id"] as? String }, ["on"])
        XCTAssertEqual(all.count, 2, "an empty since is absent")
    }

    // MARK: - App registry

    /// The daemon's pid in these tests; this test process plays the app.
    private let daemonPid: Int32 = 999_999
    private var appPid: Int32 { ProcessInfo.processInfo.processIdentifier }

    private func registryTable() -> RouteTable {
        ActivityRoutes.table(
            database: db, workTracking: tracker.control, appRegistry: SessionAppRegistry(daemonPid: daemonPid))
    }

    private func pidBody(_ pid: Int32) -> Data {
        Data(#"{"pid":\#(pid)}"#.utf8)
    }

    func testRegisteringZeroANegativeOrTheDaemonsPidIs400() async throws {
        let table = registryTable()
        for pid in [0, -1, daemonPid] {
            let response = try await send("POST", "/app/register", body: pidBody(pid), table: table)
            XCTAssertEqual(response?.status, 400, "pid \(pid)")
        }
        let real = try await send("POST", "/app/register", body: pidBody(appPid), table: table)
        XCTAssertEqual(real?.status, 200, "a refused pid must not hold the slot")
    }

    func testUnregisteringAnInvalidPidIs400AndReleasesNothing() async throws {
        let table = registryTable()
        _ = try await send("POST", "/app/register", body: pidBody(appPid), table: table)

        let response = try await send("POST", "/app/unregister", body: pidBody(-1), table: table)
        let again = try await send("POST", "/app/register", body: pidBody(appPid), table: table)

        XCTAssertEqual(response?.status, 400)
        XCTAssertEqual(try object(again)["registered"] as? Bool, true, "the owner still holds the slot")
    }

    /// The reply is the state after the call: a release, a repeat release
    /// and a release with nothing registered all say the caller holds nothing.
    func testUnregisterAnswersTheStateAfterTheCall() async throws {
        let table = registryTable()
        let none = try object(try await send("POST", "/app/unregister", body: pidBody(appPid), table: table))
        _ = try await send("POST", "/app/register", body: pidBody(appPid), table: table)
        let released = try object(try await send("POST", "/app/unregister", body: pidBody(appPid), table: table))
        let repeated = try object(try await send("POST", "/app/unregister", body: pidBody(appPid), table: table))

        for reply in [none, released, repeated] {
            XCTAssertEqual(reply["registered"] as? Bool, false)
            XCTAssertTrue(reply["owner_pid"] == nil || reply["owner_pid"] is NSNull, "\(reply)")
        }
    }

    /// A pid that does not own the slot releases nothing and is told who does.
    func testUnregisterFromANonOwnerNamesTheOwner() async throws {
        let table = registryTable()
        _ = try await send("POST", "/app/register", body: pidBody(appPid), table: table)

        let reply = try object(try await send("POST", "/app/unregister", body: pidBody(4_242), table: table))

        XCTAssertEqual(reply["registered"] as? Bool, false)
        XCTAssertEqual((reply["owner_pid"] as? NSNumber)?.int32Value, appPid)
    }
}
