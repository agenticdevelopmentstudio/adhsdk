import XCTest
import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// `POST /storage/preferences`: the history-window write a client makes over
/// HTTP now that stenographerd's XPC write is gone (apps suite phase 3).
final class StorageRoutesTests: XCTestCase {

    // swiftlint:disable:next identifier_name
    private var db: DaemonDatabase!
    private var dbPath: String!
    private var table: RouteTable!

    override func setUpWithError() throws {
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        db = opened.db
        dbPath = opened.path
        table = StorageRoutes.table(database: db, storage: { nil }, claudePipeline: nil)
    }

    override func tearDownWithError() throws {
        table = nil
        db = nil
        TestDaemonDatabase.remove(path: dbPath)
    }

    private func post(_ body: String) async -> RouteResponse? {
        await table.handle(RouteRequest(
            method: "POST", path: "/storage/preferences", queryValues: [:], headers: [:], body: Data(body.utf8)))
    }

    func testTheEndpointIndexListsTheWrite() {
        XCTAssertTrue(StorageRoutes.endpoints.contains("POST /storage/preferences"))
    }

    func testAWindowIsStoredSnappedAndTheStatusAnswered() async throws {
        let response = try XCTUnwrap(await post(#"{"history_days":10}"#))

        XCTAssertEqual(response.status, 200, String(bytes: response.body, encoding: .utf8) ?? "")
        let stored = StorageHistoryWindow.snap(10)
        XCTAssertEqual(try db.setting(for: StorageSettings.key), String(stored))
        let status = try StenographerWire.decoder().decode(StorageStatusDTO.self, from: response.body)
        XCTAssertEqual(status.historyDays, stored)
    }

    func testZeroDaysIsRefusedAndNothingIsStored() async throws {
        let before = try db.setting(for: StorageSettings.key)

        let response = try XCTUnwrap(await post(#"{"history_days":0}"#))

        XCTAssertEqual(response.status, 400)
        XCTAssertEqual(try db.setting(for: StorageSettings.key), before)
    }

    func testAMalformedBodyIsRefused() async throws {
        let response = try XCTUnwrap(await post(#"{"days":30}"#))

        XCTAssertEqual(response.status, 400)
    }

    func testAGetIsNotTheWrite() async throws {
        let response = await table.handle(RouteRequest(
            method: "GET", path: "/storage/preferences", queryValues: [:]))

        XCTAssertNil(response, "only POST claims /storage/preferences")
    }
}
