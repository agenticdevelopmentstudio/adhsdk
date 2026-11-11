//
//  BrowserExtensionManagerCache.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// One extension manager per profile for the whole process, however many
/// settings topics are open on it, so two topics on one profile drive one
/// hidden extensions page and see each other's changes.
///
/// A topic holds the cache while it is open (`manager(for:holder:)`) and
/// lets go when it closes (`release(holder:)`); the managers are closed when
/// the last holder lets go, so one topic closing never pulls the page out
/// from under another. A manager whose page failed is closed and rebuilt on
/// the next call, so a failure is not cached. Engine-free: the engine says
/// how a manager is made, whether it failed and how it is closed.
@MainActor
public final class BrowserExtensionManagerCache<Manager: AnyObject> {

    private let hasFailed: (Manager) -> Bool
    private let close: (Manager) -> Void
    private var managers: [BrowserExtensionProfile: Manager] = [:]
    /// Held weakly: a holder freed without letting go (a topic whose
    /// disappearance never came) stops counting instead of pinning the
    /// hidden pages open for the life of the app, and a later object at its
    /// address is never taken for it.
    private let holders = NSHashTable<AnyObject>.weakObjects()

    public init(hasFailed: @escaping (Manager) -> Bool, close: @escaping (Manager) -> Void) {
        self.hasFailed = hasFailed
        self.close = close
    }

    /// The profiles with a manager right now.
    public var profiles: Set<BrowserExtensionProfile> { Set(managers.keys) }

    /// The profile's manager, made by `make` when there is none or the one
    /// there failed. `holder` keeps every manager open until it lets go.
    public func manager(
        for profile: BrowserExtensionProfile, holder: AnyObject, make: () throws -> Manager
    ) throws -> Manager {
        holders.add(holder)
        if let manager = managers[profile] {
            if !hasFailed(manager) { return manager }
            close(manager)
            managers[profile] = nil
        }
        let manager = try make()
        managers[profile] = manager
        return manager
    }

    /// `holder` is done; the managers close once nobody holds them.
    public func release(holder: AnyObject) {
        holders.remove(holder)
        guard holders.allObjects.isEmpty else { return }
        let open = managers.values
        managers = [:]
        open.forEach(close)
    }
}
