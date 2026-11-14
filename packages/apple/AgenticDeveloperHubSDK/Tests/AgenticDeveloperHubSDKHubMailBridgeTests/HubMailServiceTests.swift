import XCTest
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKIntegrations
import AgenticDeveloperHubSDKHubMail
import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubMailBridge

/// Vectors hub-mail-bridge-023 to 029: sign-in opens the mirror behind one
/// stable client, sign-out purges it, and the routed client follows a switch.
@MainActor
final class HubMailServiceTests: XCTestCase {

    private var dir: URL!
    private var database: BoundedDatabase!

    override func setUp() async throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hub-mail-service-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        database = try BoundedDatabase(path: dir.appendingPathComponent("mail.db").path)
    }

    override func tearDown() async throws {
        database = nil
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Helpers

    private func oneMessagePull() -> ScriptedSyncTransport {
        let manifest = [
            SyncResource(resource: HubMailResource.labels, schemaVersion: 1),
            SyncResource(resource: HubMailResource.messages, schemaVersion: 1)
        ]
        return ScriptedSyncTransport(pulls: [
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
                    ])
                ],
                cursor: "c1",
                hasMore: false
            ))
        ])
    }

    private func service(
        transport: ScriptedSyncTransport? = nil,
        fails: Bool = false
    ) -> HubMailService {
        let database = database!
        let transport = transport ?? oneMessagePull()
        return HubMailService(syncInterval: nil) {
            if fails { throw CocoaError(.fileReadNoPermission) }
            let sync = try HubMailSync(database: database, transport: transport, deviceId: "test-device")
            return HubMailService.Connection(sync: sync, writeLabels: { _ in })
        }
    }

    private func remoteMessage(_ body: () async throws -> Void) async -> String? {
        do {
            try await body()
            return nil
        } catch MailClientError.remote(let message) {
            return message
        } catch {
            return "unexpected: \(error)"
        }
    }

    // MARK: - Vectors

    // 023
    func testSignedOutClientRefusesWithTheSignInMessage() async {
        let service = service()
        let message = await remoteMessage { _ = try await service.client.accounts() }
        XCTAssertEqual(message, HubMailService.signedOutMessage)
        XCTAssertEqual(service.status, .signedOut)
    }

    // 024
    func testSignInPullsAndTheSameClientReadsTheMirror() async throws {
        let service = service()
        let client = service.client
        var changes = 0
        service.onChange = { changes += 1 }

        await service.signedIn()

        XCTAssertEqual(service.status, .connected)
        XCTAssertEqual(changes, 1)
        let accounts = try await client.accounts()
        XCTAssertEqual(accounts.map(\.id), ["c1"])
        await service.signedOut()
    }

    // 025
    func testSignOutPurgesAndRefusesAgain() async throws {
        let service = service()
        await service.signedIn()
        await service.signedOut()

        XCTAssertEqual(service.status, .signedOut)
        let message = await remoteMessage { _ = try await service.client.accounts() }
        XCTAssertEqual(message, HubMailService.signedOutMessage)
        let store = try HubMailStore(database: database)
        XCTAssertEqual(try store.connections(), [])
    }

    // 026
    func testASecondSignInWhileConnectedDoesNotReconnect() async throws {
        var connects = 0
        let database = database!
        let service = HubMailService(syncInterval: nil) {
            connects += 1
            let sync = try HubMailSync(database: database, transport: ScriptedSyncTransport(), deviceId: "d")
            return HubMailService.Connection(sync: sync, writeLabels: { _ in })
        }
        await service.signedIn()
        await service.signedIn()
        XCTAssertEqual(connects, 1)
        await service.signedOut()
    }

    // 027
    func testAConnectFailureIsReportedAndSignOutClearsIt() async {
        let service = service(fails: true)
        await service.signedIn()
        guard case .failed = service.status else {
            return XCTFail("expected .failed, got \(service.status)")
        }
        let message = await remoteMessage { _ = try await service.client.accounts() }
        XCTAssertEqual(message, HubMailService.signedOutMessage)
        await service.signedOut()
        XCTAssertEqual(service.status, .signedOut)
    }

    // 028
    func testRestoringAndErrorLeaveTheMirrorAlone() async throws {
        let service = service()
        await service.follow(.restoring)
        XCTAssertEqual(service.status, .signedOut)

        await service.signedIn()
        await service.follow(.error("offline"))
        XCTAssertEqual(service.status, .connected)
        let accounts = try await service.client.accounts()
        XCTAssertEqual(accounts.map(\.id), ["c1"])
        await service.follow(.signedOut)
        XCTAssertEqual(service.status, .signedOut)
    }

    // 029
    func testTheRoutedClientFollowsTheSwitchPerRequest() async throws {
        let hub = service()
        await hub.signedIn()
        let direct = MailClient { _ in
            try JSONEncoder().encode(MailResponse.accounts([]))
        }
        let source = SourceBox(.direct)
        let routed = MailClient.routed {
            source.value == .hub ? hub.client : direct
        }

        let fromDirect = try await routed.accounts()
        XCTAssertEqual(fromDirect.map(\.id), [])
        source.value = .hub
        let fromHub = try await routed.accounts()
        XCTAssertEqual(fromHub.map(\.id), ["c1"])
        await hub.signedOut()
    }
}

/// A switch the routed client reads from any thread.
private final class SourceBox: @unchecked Sendable {
    private let lock = NSLock()
    private var current: MailSource

    init(_ value: MailSource) {
        current = value
    }

    var value: MailSource {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }
}
