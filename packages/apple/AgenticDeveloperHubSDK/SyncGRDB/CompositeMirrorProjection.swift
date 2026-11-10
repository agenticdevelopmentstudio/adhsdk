import Foundation
import GRDB
import AgenticDeveloperHubSDKSync

/// Several projections behind the one `GRDBSyncStore` accepts.
///
/// A store takes a single projection, and an app that keeps two unrelated
/// resources in typed tables (persona memories and document passages, say)
/// would otherwise have to write one projection that knows both. This routes
/// each call to the child that claims the resource, so each child stays the
/// one place its resource is stored.
///
/// Children must claim disjoint resources: a resource two children claim has
/// no single owner, and the composite refuses it at construction.
///
/// `truncate` hands each child only its own resources, in one call per child,
/// which keeps the store's whole-family guarantee for each child.
/// `createTables` and `purgeIdentityState` reach every child.
public struct CompositeMirrorProjection: SyncMirrorProjection {

    public let resources: Set<String>
    private let children: [any SyncMirrorProjection]

    public init(_ children: [any SyncMirrorProjection]) {
        var claimed: Set<String> = []
        for child in children {
            let overlap = claimed.intersection(child.resources)
            precondition(overlap.isEmpty, "resources claimed by two projections: \(overlap.sorted())")
            claimed.formUnion(child.resources)
        }
        self.resources = claimed
        self.children = children
    }

    private func child(for resource: String) throws -> any SyncMirrorProjection {
        guard let child = children.first(where: { $0.resources.contains(resource) }) else {
            throw SyncStoreFailure.unknownResource(resource)
        }
        return child
    }

    public func createTables(in conn: Database) throws {
        for child in children { try child.createTables(in: conn) }
    }

    public func upsert(
        resource: String, id: String, syncVersion: Int, data: [String: JSONValue], in conn: Database
    ) throws {
        try child(for: resource).upsert(resource: resource, id: id, syncVersion: syncVersion, data: data, in: conn)
    }

    public func upsert(
        resource: String, id: String, syncVersion: Int, data: [String: JSONValue], isFullRow: Bool,
        in conn: Database
    ) throws {
        try child(for: resource).upsert(
            resource: resource, id: id, syncVersion: syncVersion, data: data, isFullRow: isFullRow, in: conn)
    }

    public func markDeleted(resource: String, id: String, syncVersion: Int?, in conn: Database) throws {
        try child(for: resource).markDeleted(resource: resource, id: id, syncVersion: syncVersion, in: conn)
    }

    public func setSyncVersion(_ version: Int, resource: String, id: String, in conn: Database) throws {
        try child(for: resource).setSyncVersion(version, resource: resource, id: id, in: conn)
    }

    public func syncVersion(resource: String, id: String, in conn: Database) throws -> Int? {
        try child(for: resource).syncVersion(resource: resource, id: id, in: conn)
    }

    public func truncate(resources: [String], in conn: Database) throws {
        for child in children {
            let own = resources.filter { child.resources.contains($0) }
            if !own.isEmpty { try child.truncate(resources: own, in: conn) }
        }
    }

    public func purgeIdentityState(in conn: Database) throws {
        for child in children { try child.purgeIdentityState(in: conn) }
    }

    public func rows(resource: String, limit: Int, offset: Int, in conn: Database) throws -> [[String: JSONValue]] {
        try child(for: resource).rows(resource: resource, limit: limit, offset: offset, in: conn)
    }

    public func row(resource: String, id: String, in conn: Database) throws -> [String: JSONValue]? {
        try child(for: resource).row(resource: resource, id: id, in: conn)
    }
}
