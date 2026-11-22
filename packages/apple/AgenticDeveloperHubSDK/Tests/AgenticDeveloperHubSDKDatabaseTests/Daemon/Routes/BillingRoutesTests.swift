import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
import GRDB
@testable import AgenticDeveloperHubSDKDatabase

/// The billing surface over HTTP, reads and writes. These tests care about
/// shape, bounds and how a refusal travels: the numbers and the rules
/// themselves are the stores' contract and are tested there.
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
    private func send(_ method: String, _ target: String, body: Data = Data()) async throws -> RouteResponse? {
        let components = try XCTUnwrap(URLComponents(string: target))
        var query: [String: [String]] = [:]
        for item in components.queryItems ?? [] {
            query[item.name, default: []].append(item.value ?? "")
        }
        return await table.handle(RouteRequest(
            method: method, path: components.path, queryValues: query, body: body
        ))
    }

    /// `POST path` with `value` as the snake_case JSON body an app sends.
    private func post<T: Encodable>(_ target: String, _ value: T) async throws -> RouteResponse? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try await send("POST", target, body: try encoder.encode(value))
    }

    /// `POST path` with a literal JSON body.
    private func post(_ target: String, json: String) async throws -> RouteResponse? {
        try await send("POST", target, body: Data(json.utf8))
    }

    private func message(_ response: RouteResponse?) throws -> String? {
        try object(response)["error"] as? String
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

    func testArchivedRowsAreListedOnlyWhenAsked() async throws {
        _ = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Live"), database: db)
        _ = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Old", archived: true), database: db)

        let current = try array(try await send("GET", "/billing/clients"))
        let all = try array(try await send("GET", "/billing/clients?include_archived=true"))
        let allByDigit = try array(try await send("GET", "/billing/projects?include_archived=1"))

        XCTAssertEqual(current.map { $0["name"] as? String }, ["Live"])
        XCTAssertEqual(all.count, 2, "the app's windows list archived rows too")
        XCTAssertTrue(allByDigit.isEmpty)
    }

    func testReposRouteFiltersByProject() async throws {
        let project = try seedProject()
        _ = try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/app"), database: db
        )

        let mine = try array(try await send("GET", "/billing/repos?project_id=\(project.id)"))
        let others = try array(try await send("GET", "/billing/repos?project_id=nope"))

        XCTAssertEqual(mine.count, 1)
        XCTAssertEqual(mine[0]["project_root"] as? String, "/src/app")
        XCTAssertTrue(others.isEmpty)
    }

    func testTimersRouteListsRunningTimers() async throws {
        let rows = try array(try await send("GET", "/billing/timers"))
        XCTAssertTrue(rows.isEmpty)
    }

    func testAuditRouteAnswersAList() async throws {
        let rows = try array(try await send("GET", "/billing/entries/nope/audit"))
        XCTAssertTrue(rows.isEmpty, "an entry with no history has an empty trail, not a 404")
    }

    // MARK: - Writes

    func testSavingAClientRepliesTheStoredRowInSnakeCase() async throws {
        let saved = try object(try await post(
            "/billing/clients", BillingClientDTO(id: "", name: "Acme", contactName: "Dana Reed")
        ))

        XCTAssertFalse((saved["id"] as? String ?? "").isEmpty, "an empty id inserts and is given one")
        XCTAssertEqual(saved["contact_name"] as? String, "Dana Reed")
        XCTAssertEqual(try db.billingClients(includeArchived: true).map(\.name), ["Acme"])
    }

    /// A store's refusal reaches the app as the sentence it shows in an alert.
    func testAStoreRefusalIsA400WithItsSentence() async throws {
        _ = try await post("/billing/clients", BillingClientDTO(id: "", name: "Acme"))

        let duplicate = try await post("/billing/clients", BillingClientDTO(id: "", name: "Acme"))
        let nameless = try await post("/billing/projects", BillingProjectDTO(id: "", name: ""))

        XCTAssertEqual(duplicate?.status, 400)
        XCTAssertEqual(try message(duplicate), BillingStore.BillingError.duplicateName("Acme").errorDescription)
        XCTAssertEqual(nameless?.status, 400)
        XCTAssertEqual(try message(nameless), BillingStore.BillingError.missingName.errorDescription)
    }

    func testAnUnreadableBodyWritesNothing() async throws {
        let response = try await post("/billing/clients", json: "{\"nope\":1}")

        XCTAssertEqual(response?.status, 400)
        XCTAssertEqual(try message(response), BillingRoutes.BillingWireError.undecodable.errorDescription)
        XCTAssertTrue(try db.billingClients(includeArchived: true).isEmpty)
    }

    func testDeletingAClientIsA204() async throws {
        let client = try BillingStore.saveClient(BillingClientDTO(id: "", name: "Acme"), database: db)

        let response = try await send("POST", "/billing/clients/\(client.id)/delete")

        XCTAssertEqual(response?.status, 204)
        XCTAssertTrue(try db.billingClients(includeArchived: true).isEmpty)
    }

    func testEntryStatusRefusesANameItDoesNotKnow() async throws {
        let project = try seedProject()
        let entry = try BillingRollup.saveEntry(BillingEntryDTO(
            id: "", projectId: project.id, day: "2026-09-22",
            rawSeconds: 3600, billedSeconds: 3600, rateCents: 12_000, amountCents: 12_000
        ), database: db)

        let unknown = try await post("/billing/entries/\(entry.id)/status", json: "{\"status\":\"lost\"}")
        // Described before it is billed: a billed entry is locked, and the
        // description route refuses a locked entry.
        let described = try await post(
            "/billing/entries/\(entry.id)/description", json: "{\"description\":\"Sprint 4\"}"
        )
        let billed = try await post("/billing/entries/\(entry.id)/status", json: "{\"status\":\"billed\"}")

        XCTAssertEqual(unknown?.status, 400)
        XCTAssertEqual(try message(unknown), BillingRoutes.BillingWireError.unknownStatus("lost").errorDescription)
        XCTAssertEqual(try object(billed)["status"] as? String, "billed")
        XCTAssertEqual(try object(described)["description"] as? String, "Sprint 4")
    }

    /// The day must be the whole value, or a full timestamp: a prefix that
    /// happens to be a day is not one.
    func testEntriesRouteRejectsTrailingJunk() async throws {
        for since in ["2026-09-01garbage", "2026-09-01T", "2026-09-01T25:00:00Z", "2026-09-01%20"] {
            let response = try await send("GET", "/billing/entries?since=\(since)")
            XCTAssertEqual(response?.status, 400, since)
        }
        let timestamp = try await send("GET", "/billing/entries?since=2026-09-01T12:00:00Z")
        XCTAssertEqual(timestamp?.status, 200)
    }

    /// An empty `since` would re-derive every session, a non-date nothing,
    /// both answering 200: each is a 400 that changes nothing.
    func testBackfillRejectsAnInvalidSince() async throws {
        for since in ["", "garbage", "sept 1", "2026-09-01garbage", "2026-02-30", "2026-09-01T25:00:00Z"] {
            let response = try await post("/billing/backfill", json: "{\"since\":\"\(since)\"}")
            XCTAssertEqual(response?.status, 400, since)
        }
        let valid = ["2026-09-01", "2026-09-01T00:00:00Z", "2026-09-01T00:00:00.250Z", "2026-09-01T02:00:00+02:00"]
        for since in valid {
            let response = try await post("/billing/backfill", json: "{\"since\":\"\(since)\"}")
            XCTAssertEqual(response?.status, 200, since)
        }
    }

    func testBackfillSinceIsADayOrAUTCInstant() {
        XCTAssertEqual(BillingRoutes.backfillSince("2026-09-01"), "2026-09-01")
        XCTAssertEqual(BillingRoutes.backfillSince("2026-09-01T02:00:00+02:00"), "2026-09-01T00:00:00Z")
        XCTAssertEqual(BillingRoutes.backfillSince("2026-09-01T00:00:00.750Z"), "2026-09-01T00:00:00Z")
        XCTAssertNil(BillingRoutes.backfillSince(""))
    }

    func testSegmentWritesAnswerACount() async throws {
        let project = try seedProject()
        try seedSegment(id: "seg1", startedAt: "2026-09-22T09:00:00Z", endedAt: "2026-09-22T09:30:00Z")

        let assigned = try object(try await post(
            "/billing/segments/assign", json: "{\"ids\":[\"seg1\"],\"project_id\":\"\(project.id)\"}"
        ))
        let backfilled = try object(try await post("/billing/backfill", json: "{\"since\":\"2026-09-01\"}"))

        XCTAssertEqual(assigned["count"] as? Int, 1)
        XCTAssertNotNil(backfilled["count"] as? Int)
    }

    func testPreferencesApplyAndReplyTheSnapshot() async throws {
        let key = db.billingSettingsKeys.defaultRateCents

        let snapshot = try object(try await post("/billing/preferences", json: "{\"\(key)\":\"15000\"}"))
        let unchanged = try object(try await send("POST", "/billing/preferences", body: Data()))

        XCTAssertEqual(snapshot["default_rate_cents"] as? Int, 15_000)
        XCTAssertEqual(unchanged["default_rate_cents"] as? Int, 15_000,
                       "an empty body writes nothing and answers what is in force")
    }

    /// Numbers and bools are values, not a decode failure that reads as a save.
    func testPreferencesTakeJSONNumbersAndBools() async throws {
        let keys = db.billingSettingsKeys

        let reply = try object(try await post(
            "/billing/preferences",
            json: "{\"\(keys.roundingMinutes)\":15,\"\(keys.idleCutoffMinutes)\":10,\"\(keys.trackUnassigned)\":false}"
        ))

        XCTAssertEqual(reply["rounding_minutes"] as? Int, 15)
        XCTAssertEqual(reply["idle_cutoff_minutes"] as? Int, 10)
        XCTAssertEqual(reply["track_unassigned"] as? Bool, false)
        XCTAssertEqual(try db.setting(for: keys.roundingMinutes), "15")
        XCTAssertEqual(try db.setting(for: keys.trackUnassigned), "false")
    }

    /// A body that is not an object of scalars writes nothing and is a 400.
    func testAnUnreadablePreferencesBodyIs400AndWritesNothing() async throws {
        let key = db.billingSettingsKeys.defaultRateCents
        _ = try await post("/billing/preferences", json: "{\"\(key)\":\"15000\"}")

        for body in ["not json", "[]", "{\"\(key)\":null}", "{\"\(key)\":[1]}", "{\"\(key)\":{\"a\":1}}"] {
            let response = try await post("/billing/preferences", json: body)
            XCTAssertEqual(response?.status, 400, body)
            XCTAssertEqual(try message(response), BillingRoutes.BillingWireError.undecodable.errorDescription, body)
        }
        XCTAssertEqual(try db.setting(for: key), "15000")
    }

    func testAPreferenceValueKeepsTheTextTheSettingsTableStores() throws {
        let decoded = try JSONDecoder().decode(
            [String: BillingRoutes.PreferenceValue].self,
            from: Data(#"{"a":"day","b":15,"c":true,"d":1.5,"e":0}"#.utf8)
        )
        XCTAssertEqual(decoded.mapValues(\.settingText), ["a": "day", "b": "15", "c": "true", "d": "1.5", "e": "0"])
    }

    // MARK: - Failures

    /// Only a store's refusal is a 400, the status the app treats as final.
    func testAStoresRefusalIs400WithItsSentence() throws {
        let refusals: [Error] = [
            BillingStore.BillingError.missingName,
            BillingRollup.RollupError.unknownEntry("e1"),
            BillingTimer.TimerError.unknownTimer("t1"),
            BillingRoutes.BillingWireError.undecodable
        ]
        for refusal in refusals {
            let response = BillingRoutes.storeFailure(refusal)
            XCTAssertEqual(response.status, 400, "\(refusal)")
            XCTAssertEqual(try message(response), refusal.localizedDescription)
        }
    }

    /// A busy or locked database, however it arrives, is a 503 the app may
    /// retry, and its text never reaches the reply.
    func testABusyDatabaseIs503WithoutSQLitesText() throws {
        let busy: [Error] = [
            DaemonDatabaseError.stepFailed(message: "database is locked", code: ResultCode.SQLITE_BUSY.rawValue),
            DaemonDatabaseError.stepFailed(message: "database is locked", code: 517), // SQLITE_BUSY_SNAPSHOT
            DaemonDatabaseError.stepFailed(message: "table is locked", code: ResultCode.SQLITE_LOCKED.rawValue),
            DaemonDatabase.mapDBError(BoundedDatabaseError.deadlineExceeded(lane: "write", elapsedMs: 61_000)),
            DatabaseError(resultCode: .SQLITE_BUSY, message: "database is locked")
        ]
        for error in busy {
            let response = BillingRoutes.storeFailure(error)
            XCTAssertEqual(response.status, 503, "\(error)")
            XCTAssertEqual(try message(response), BillingRoutes.busyMessage)
        }
    }

    func testAnyOtherFailureIs500WithoutItsText() throws {
        let failures: [Error] = [
            DaemonDatabaseError.stepFailed(message: "database disk image is malformed", code: 11),
            DaemonDatabaseError.stepFailed(message: "disk I/O error", code: 10),
            NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "/private/path/sessions.db"])
        ]
        for error in failures {
            let response = BillingRoutes.storeFailure(error)
            XCTAssertEqual(response.status, 500, "\(error)")
            XCTAssertEqual(try message(response), BillingRoutes.failedMessage)
        }
    }

    func testAppNamesReadsAtMostTheCap() async throws {
        let ids = (0..<(BillingRoutes.maxAppNameIds + 10)).map { "s\($0)" }
        let encoder = JSONEncoder()
        let body = try encoder.encode(["session_ids": ids])

        let response = try await send("POST", "/billing/app-names", body: body)
        let garbage = try await post("/billing/app-names", json: "[]")

        XCTAssertEqual(response?.status, 200)
        XCTAssertTrue(try array(response).isEmpty)
        XCTAssertEqual(garbage?.status, 400)
    }

    // MARK: - Method and shape

    func testAMethodOtherThanGetOrPostIs405() async throws {
        let response = try await send("PUT", "/billing/entries")
        XCTAssertEqual(response?.status, 405)
    }

    func testAnUnknownWriteIs404() async throws {
        let response = try await send("POST", "/billing/clients/x/archive")
        XCTAssertEqual(response?.status, 404)
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
