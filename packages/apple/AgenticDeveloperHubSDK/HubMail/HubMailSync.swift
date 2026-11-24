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

    /// Purges every mirrored row, the cursor and the outbox for the departing
    /// identity. The engine is paused around the purge and resumed after it,
    /// never stopped, so the next identity syncs through the same engine.
    public func signOut() async throws {
        await engine.pause()
        do {
            try await syncStore.purgeForIdentityChange()
        } catch {
            await engine.resume()
            throw error
        }
        await engine.resume()
    }
}
