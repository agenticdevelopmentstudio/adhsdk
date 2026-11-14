import XCTest
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
@testable import AgenticDeveloperHubSDKHubMail

/// Vector hub-mail-010: a pull lands in the store, and sign-out purges it.
final class HubMailSyncTests: XCTestCase {

    private var dir: URL!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hub-mail-sync-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private let manifest = [
        SyncResource(resource: HubMailResource.labels, schemaVersion: 1),
        SyncResource(resource: HubMailResource.messages, schemaVersion: 1)
    ]

    // 010
    func testAPullReadsBackAndSignOutLeavesNothing() async throws {
        let database = try BoundedDatabase(path: dir.appendingPathComponent("mail.db").path)
        let transport = ScriptedSyncTransport(pulls: [
            .success(SyncPullResponse(
                manifest: manifest,
                changes: [
                    SyncChange(resource: HubMailResource.messages, id: "m1", op: .upsert, syncVersion: "3", data: [
                        "connection_id": .string("c1"),
                        "provider": .string("gmail"),
                        "external_id": .string("g-m1"),
                        "subject": .string("Hello"),
                        "label_ids": .array([.string("INBOX")]),
                        "internal_date": .string("2026-11-12T10:00:00Z")
                    ]),
                    SyncChange(resource: HubMailResource.labels, id: "l1", op: .upsert, syncVersion: "2", data: [
                        "connection_id": .string("c1"),
                        "external_id": .string("INBOX"),
                        "source_provider": .string("gmail"),
                        "name": .string("INBOX"),
                        "type": .string("system")
                    ])
                ],
                cursor: "c1",
                hasMore: false
            ))
        ])
        let sync = try HubMailSync(database: database, transport: transport, deviceId: "test-device")

        await sync.syncNow()

        XCTAssertEqual(try sync.store.message(id: "m1")?.subject, "Hello")
        XCTAssertEqual(try sync.store.messages(labelId: "INBOX").messages.map(\.id), ["m1"])
        XCTAssertEqual(try sync.store.labels(connectionId: "c1").map(\.externalId), ["INBOX"])

        try await sync.signOut()

        XCTAssertNil(try sync.store.message(id: "m1"))
        XCTAssertEqual(try sync.store.labels(connectionId: "c1"), [])
        XCTAssertEqual(try sync.store.connections(), [])
        await sync.engine.stop()
    }
}
