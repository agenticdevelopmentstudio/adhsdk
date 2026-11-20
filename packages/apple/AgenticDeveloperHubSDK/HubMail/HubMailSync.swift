import Foundation
import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKSyncGRDB
import AgenticDeveloperHubSDKHubSync

/// Wires Hub Mail over one database: the projection, a `GRDBSyncStore` and a
/// `SyncEngine` that mirrors only the two mail resources.
///
/// Both resources are pull-only, because the hub refuses pushes to tables its
/// worker owns. They are also the engine's `hostResources`, so nothing else the
/// user has enrolled lands in this database.
public final class HubMailSync: Sendable {

    public let store: HubMailStore
    public let engine: SyncEngine
    private let syncStore: GRDBSyncStore

    public init(database: BoundedDatabase, transport: any SyncTransport, deviceId: String) throws {
        store = try HubMailStore(database: database)
        syncStore = GRDBSyncStore(
            database: database,
            pullOnlyResources: HubMailResource.all,
            projections: [HubMailProjection()]
        )
        let hostResources = HubMailResource.all.sorted().map { SyncResource(resource: $0, schemaVersion: 1) }
        engine = SyncEngine(
            store: syncStore,
            transport: transport,
            configuration: SyncEngineConfiguration(deviceId: deviceId, hostResources: hostResources)
        )
    }

    /// The usual setup: the hub client's sync API through `ADHSyncTransport`.
    public convenience init(database: BoundedDatabase, api: ADHSyncAPI, deviceId: String) throws {
        try self.init(database: database, transport: ADHSyncTransport(api: api), deviceId: deviceId)
    }

    /// The engine's events. Re-read the store after each `pulledBatch`.
    public var events: AsyncStream<SyncEvent> { engine.events }

    public func syncNow() async {
        await engine.syncNow(reason: .manual)
    }

    /// Clears every mirrored mail row and the cursor for the departing
    /// identity. Both resources are pull-only, so the outbox is always empty
    /// and a resync reset is the whole of it: the hub holds the mail, and the
    /// next identity pulls its own. The engine is paused around the reset and
    /// resumed after it, never stopped, so the next identity syncs through the
    /// same engine.
    ///
    /// The store is also told nobody is signed in, so until the next
    /// `signIn(account:)` it refuses every push and pull.
    public func signOut() async throws {
        await engine.pause()
        do {
            try await syncStore.resetForResync()
        } catch {
            await engine.resume()
            throw error
        }
        syncStore.signOut()
        await engine.resume()
    }

    /// Declares `account` (a principal id) signed in and starts a sync. Mail
    /// is pull-only and the hub holds all of it, so a store bound to another
    /// account has nothing of its own to keep: its rows and cursor are
    /// cleared and it is rebound to `account`, which pulls its own mail.
    public func signIn(account: String) async throws {
        await engine.pause()
        do {
            switch try await syncStore.signIn(account: account) {
            case .bound:
                break
            case .mismatch, .unboundWithData:
                try await syncStore.resetForResync()
                try await syncStore.discardAccountState(rebindingTo: account)
            }
        } catch {
            await engine.resume()
            throw error
        }
        await engine.resume()
        await engine.syncNow(reason: .manual)
    }
}
