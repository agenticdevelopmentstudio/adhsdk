import XCTest
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKMail
import AgenticDeveloperHubSDKHubMail
import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubMailBridge

/// Vectors hub-mail-bridge-023 to 029, 038 to 041 and 043: sign-in opens the
/// mirror behind one stable client, sign-out purges it (even one a previous
/// launch left on disk), a sign-in waits for that purge, a refused token is
/// renewed or retried, and the routed client follows a switch.
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
        ScriptedSyncTransport(pulls: [messagePull()])
    }

    private func messagePull() -> ScriptedSyncTransport.Outcome<SyncPullResponse> {
        let manifest = [
            SyncResource(resource: HubMailResource.labels, schemaVersion: 1),
            SyncResource(resource: HubMailResource.messages, schemaVersion: 1)
        ]
        return .success(SyncPullResponse(
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
    }

    private func service(
        transport: ScriptedSyncTransport? = nil,
        fails: Bool = false,
        refresh: @escaping @Sendable () async -> Bool = { false },
        authRetryDelay: Duration = .seconds(60)
    ) -> HubMailService {
        let database = database!
        let transport = transport ?? oneMessagePull()
        return HubMailService(syncInterval: nil, authRetryDelay: authRetryDelay) {
            if fails { throw CocoaError(.fileReadNoPermission) }
            let sync = try HubMailSync(database: database, transport: transport, deviceId: "test-device")
            return HubMailService.Connection(sync: sync, writeLabels: { _ in }, refreshSession: refresh)
        }
    }

    /// Polls `condition` for up to three seconds.
    private func eventually(_ condition: () async throws -> Bool) async rethrows -> Bool {
        for _ in 0..<300 {
            if try await condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return false
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

    // 038
    func testASignedOutRestorePurgesTheMirrorAPreviousLaunchLeft() async throws {
        // A previous launch signed in and quit without signing out.
        let previous = service()
        await previous.signedIn()
        XCTAssertEqual(try HubMailStore(database: database).connections(), ["c1"])

        // This launch's restore ends signed out, with no mirror open.
        let next = service(transport: ScriptedSyncTransport())
        await next.follow(.signedOut)

        XCTAssertEqual(next.status, .signedOut)
        XCTAssertEqual(try HubMailStore(database: database).connections(), [])
    }

    // 039
    func testASignInDuringSignOutWaitsForThePurge() async throws {
        let service = service(transport: ScriptedSyncTransport(pulls: [messagePull(), messagePull()]))
        await service.signedIn()

        // The sign-out starts and suspends inside its purge...
        let out = Task { await service.signedOut() }
        await Task.yield()
        XCTAssertEqual(service.status, .signedOut)
        // ...and the sign-in that arrives meanwhile waits for it, so the
        // purge never runs over the rows the new sign-in pulls.
        await service.signedIn()
        await out.value

        XCTAssertEqual(service.status, .connected)
        XCTAssertEqual(try await service.client.accounts().map(\.id), ["c1"])
        await service.signedOut()
    }

    // 040
    func testARefusedTokenIsRenewedAndThePullRuns() async throws {
        let renewals = Counter()
        let transport = ScriptedSyncTransport(pulls: [.failure(.unauthorized), messagePull()])
        let service = service(transport: transport, refresh: { await renewals.increment(); return true })

        await service.signedIn()

        let pulled = try await eventually { try await service.client.accounts().map(\.id) == ["c1"] }
        XCTAssertTrue(pulled)
        let count = await renewals.value
        XCTAssertEqual(count, 1)
        XCTAssertEqual(service.status, .connected)
        await service.signedOut()
    }

    // 041
    func testAFailedRenewalShowsTheRetryAndTheNextPullClearsIt() async throws {
        let transport = ScriptedSyncTransport(pulls: [.failure(.unauthorized), messagePull()])
        let service = service(transport: transport, refresh: { false }, authRetryDelay: .milliseconds(50))
        var seen: [HubMailService.Status] = []
        service.onChange = { seen.append(service.status) }

        await service.signedIn()

        let recovered = try await eventually { try await service.client.accounts().map(\.id) == ["c1"] }
        XCTAssertTrue(recovered)
        let connected = await eventually { service.status == .connected }
        XCTAssertTrue(connected)
        XCTAssertEqual(seen, [.connected, .failed(HubMailService.authRetryMessage), .connected])
        await service.signedOut()
    }

    // 043
    func testEachCompletedPullMovesTheAccountsLastSync() async throws {
        // The second pull finds the script empty and answers no changes.
        let service = service()

        await service.signedIn()
        let first = try await firstSync(service)
        XCTAssertNotNil(first)

        try await Task.sleep(for: .milliseconds(5))
        await service.syncNow()
        let moved = try await eventually { try await firstSync(service) != first }
        XCTAssertTrue(moved)
        await service.signedOut()
    }

    /// The first account's `lastSyncAt`, once the pull that created it completed.
    private func firstSync(_ service: HubMailService) async throws -> String? {
        _ = try await eventually { try await service.client.accounts().first?.lastSyncAt != nil }
        return try await service.client.accounts().first?.lastSyncAt
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

private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
