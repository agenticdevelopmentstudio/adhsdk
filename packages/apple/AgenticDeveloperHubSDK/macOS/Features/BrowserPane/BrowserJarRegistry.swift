//
//  BrowserJarRegistry.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import WebKit
import os

/// Turns a pane's storage-jar setting into the `WKWebsiteDataStore` it uses.
///
/// A worktree or pane jar is a persistent WebKit store named by a UUID, and the
/// UUID is a `browser_jars` row: the row is what lets the same pane, or another
/// pane of the same worktree, find the same store after a relaunch, and what
/// the reconciler reads to tell a store in use from a leftover. The global jar
/// is WebKit's default store and needs no row.
///
/// A worktree or pane jar this cannot make — a context without a node or a
/// project, a database that refuses — fails closed: the pane gets a
/// non-persistent store of its own, never the shared one, and the resolution
/// says why so the pane can log it. A pane that asked to be kept apart still
/// browses, and is still apart; only its session does not outlive it.
@MainActor
public final class BrowserJarRegistry {

    /// What a pane ends up with: the store, the jar it asked for, and the
    /// row naming it (`nil` for the global jar and for a fallback).
    public struct Resolution {
        /// The WebKit store, made when first asked for and every time after:
        /// a Chrome pane reads only the jar and its row, and must never make
        /// a WebKit store it does not use. A WebKit pane reads it once.
        public var dataStore: WKWebsiteDataStore { makeDataStore() }
        private let makeDataStore: () -> WKWebsiteDataStore
        /// The jar asked for. A worktree or pane jar that could not be made
        /// keeps its name here, with a non-persistent store and a
        /// `fallbackReason`: the pane is isolated, just not kept.
        public let jar: BrowserStorageJar
        public let jarID: UUID?
        /// Why the jar asked for could not be made, when it could not; the
        /// pane's store is then a non-persistent one of its own.
        public let fallbackReason: String?

        public init(
            dataStore: @autoclosure @escaping () -> WKWebsiteDataStore,
            jar: BrowserStorageJar, jarID: UUID?, fallbackReason: String? = nil
        ) {
            self.makeDataStore = dataStore
            self.jar = jar
            self.jarID = jarID
            self.fallbackReason = fallbackReason
        }
    }

    public let database: ProjectDatabase

    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserJars")

    /// Who is using which jar right now, held weakly so a pane that is gone
    /// without saying so stops counting.
    private var users: [ObjectIdentifier: (user: WeakUser, jarID: UUID)] = [:]

    public init(database: ProjectDatabase) {
        self.database = database
    }

    // MARK: - One registry per database

    private static var registries: [ObjectIdentifier: WeakRegistry] = [:]

    /// The registry every pane over `database` shares.
    ///
    /// Shared so the in-use set covers every open pane of every window: the
    /// reconciler asks it which jars are still held, and a per-pane registry
    /// would each know only its own. Looked up rather than injected so the
    /// browser factory, which is handed a project and nothing else, needs no
    /// new parameter in every host that registers it.
    public static func shared(for database: ProjectDatabase) -> BrowserJarRegistry {
        if let existing = existing(for: database) { return existing }
        let registry = BrowserJarRegistry(database: database)
        registries = registries.filter { $0.value.registry != nil }
        registries[ObjectIdentifier(database)] = WeakRegistry(registry: registry)
        return registry
    }

    /// The shared registry for `database` if one is alive, without making one.
    /// An object identifier can be reused once its object is freed, so the
    /// registry's own database is compared too.
    static func existing(for database: ProjectDatabase) -> BrowserJarRegistry? {
        guard let registry = registries[ObjectIdentifier(database)]?.registry,
              registry.database === database else { return nil }
        return registry
    }

    // MARK: - Resolution

    /// The store a pane with `context` uses for `jar`, making the jar's row the
    /// first time it is asked for. `label` names a new pane jar; a worktree jar
    /// is named after its worktree.
    public func dataStore(
        for jar: BrowserStorageJar,
        context: BrowserPaneContext,
        label: String
    ) -> WKWebsiteDataStore {
        resolve(jar, context: context, label: label).dataStore
    }

    /// `dataStore(for:context:label:)` with what it resolved to.
    public func resolve(
        _ jar: BrowserStorageJar,
        context: BrowserPaneContext,
        label: String
    ) -> Resolution {
        guard jar != .global else { return Resolution(dataStore: .default(), jar: .global, jarID: nil) }
        guard let wanted = recordShape(for: jar, context: context, label: label) else {
            return fallback(for: jar, reason: "no project, worktree or pane node")
        }
        do {
            let record = try findOrInsert(wanted)
            return Resolution(dataStore: WKWebsiteDataStore(forIdentifier: record.id), jar: jar, jarID: record.id)
        } catch {
            return fallback(for: jar, reason: "jar lookup failed: \(error.localizedDescription)")
        }
    }

    /// A worktree or pane jar that could not be made: a store of the pane's
    /// own that is never written to disk, so the pane fails closed rather
    /// than onto the jar every other pane shares.
    private func fallback(for jar: BrowserStorageJar, reason: String) -> Resolution {
        logger.error(
            "browser \(jar.rawValue, privacy: .public) jar not made, non-persistent: \(reason, privacy: .public)"
        )
        return Resolution(dataStore: .nonPersistent(), jar: jar, jarID: nil, fallbackReason: reason)
    }

    /// The row `jar` resolves to for `context`, without making one — `nil`
    /// for the global jar, for a context that cannot have one, and for a jar
    /// not made yet.
    public func jarID(for jar: BrowserStorageJar, context: BrowserPaneContext) -> UUID? {
        guard let wanted = recordShape(for: jar, context: context, label: "") else { return nil }
        return try? existingRecord(like: wanted)?.id
    }

    /// Whether `context` has what `jar` needs — a project and worktree, and a
    /// node for a pane jar — so asking for it yields that jar rather than the
    /// shared one.
    public func canIsolate(_ jar: BrowserStorageJar, context: BrowserPaneContext) -> Bool {
        recordShape(for: jar, context: context, label: "") != nil
    }

    /// Every jar of one project, for a list that names them.
    public func records(repoID: UUID) -> [BrowserJarRecord] {
        do {
            return try database.browserJars(repoID: repoID)
        } catch {
            logger.error("browser jar list failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// Renames a jar, so the list keeps showing what its pane was last called.
    public func updateLabel(jarID: UUID, label: String) {
        do {
            try database.updateBrowserJarLabel(id: jarID, label: label)
        } catch {
            logger.error("browser jar rename failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - In use

    /// Marks `jarID` as held by `user`, replacing whatever `user` held before.
    /// `nil` releases it — a pane that moved to the global jar or to private
    /// browsing holds no row.
    ///
    /// The layout a pane lives in is saved after the pane is built, and only
    /// one window's layout is saved at a time, so a saved layout alone cannot
    /// say which jars are in use: a pane made a moment ago is in none. What is
    /// held here is the rest of the answer.
    public func noteUse(of jarID: UUID?, by user: AnyObject) {
        let key = ObjectIdentifier(user)
        if let jarID {
            users[key] = (WeakUser(object: user), jarID)
        } else {
            users.removeValue(forKey: key)
        }
    }

    public func endUse(by user: AnyObject) {
        users.removeValue(forKey: ObjectIdentifier(user))
    }

    /// Every jar a live pane holds.
    public var jarIDsInUse: Set<UUID> {
        users = users.filter { $0.value.user.object != nil }
        return Set(users.values.map(\.jarID))
    }

    // MARK: - Rows

    private func recordShape(
        for jar: BrowserStorageJar,
        context: BrowserPaneContext,
        label: String
    ) -> BrowserJarRecord? {
        guard let repoID = context.projectID, let path = context.worktreePath else { return nil }
        let worktreePath = LiveBrowserPane.standardizedPath(path)
        switch jar {
        case .global:
            return nil
        case .worktree:
            return BrowserJarRecord(
                kind: .worktree,
                repoID: repoID,
                worktreePath: worktreePath,
                paneNodeID: nil,
                label: URL(fileURLWithPath: worktreePath).lastPathComponent
            )
        case .pane:
            guard let nodeID = context.paneNodeID else { return nil }
            return BrowserJarRecord(
                kind: .pane, repoID: repoID, worktreePath: worktreePath, paneNodeID: nodeID, label: label
            )
        }
    }

    private func existingRecord(like wanted: BrowserJarRecord) throws -> BrowserJarRecord? {
        switch wanted.kind {
        case .worktree:
            return try database.browserJar(worktreeOf: wanted.repoID, path: wanted.worktreePath)
        case .pane:
            guard let nodeID = wanted.paneNodeID else { return nil }
            return try database.browserJar(pane: nodeID)
        }
    }

    /// Reads, then inserts; an insert that loses to another writer — a second
    /// app copy sharing the file — reads the winner's row instead, which the
    /// unique indexes guarantee is there.
    private func findOrInsert(_ wanted: BrowserJarRecord) throws -> BrowserJarRecord {
        if let found = try existingRecord(like: wanted) { return found }
        do {
            try database.insertBrowserJar(wanted)
            return wanted
        } catch {
            if let found = try existingRecord(like: wanted) { return found }
            throw error
        }
    }
}

private struct WeakRegistry {
    weak var registry: BrowserJarRegistry?
}

private struct WeakUser {
    weak var object: AnyObject?
}
