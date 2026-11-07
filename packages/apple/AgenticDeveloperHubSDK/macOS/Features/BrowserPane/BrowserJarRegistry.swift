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
/// Anything this cannot resolve — a detached pane, a context without a node or
/// a project, a database that refuses — falls back to the default store with a
/// log line. A pane that cannot be isolated still browses; it browses in the
/// shared jar, which is the behaviour every pane had before jars existed
/// (`graceful-degradation`).
@MainActor
public final class BrowserJarRegistry {

    /// What a pane ends up with: the store, the jar it actually got, and the
    /// row naming it (`nil` for the global jar).
    public struct Resolution {
        public let dataStore: WKWebsiteDataStore
        /// The jar in effect — `.global` when a worktree or pane jar was asked
        /// for but could not be resolved, so a caller never believes it is
        /// isolated when it is not.
        public let jar: BrowserStorageJar
        public let jarID: UUID?
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
        let shared = Resolution(dataStore: .default(), jar: .global, jarID: nil)
        guard jar != .global else { return shared }
        guard let wanted = recordShape(for: jar, context: context, label: label) else {
            logger.info(
                "browser pane has no project or pane node; using the shared jar for \(jar.rawValue, privacy: .public)"
            )
            return shared
        }
        do {
            let record = try findOrInsert(wanted)
            return Resolution(dataStore: WKWebsiteDataStore(forIdentifier: record.id), jar: jar, jarID: record.id)
        } catch {
            logger.error(
                "browser jar lookup failed; using the shared jar: \(error.localizedDescription, privacy: .public)"
            )
            return shared
        }
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

/// Decides when a pane renames its jar: at most once per committed
/// navigation.
///
/// A page may change its title as often as it likes — an unread counter, a
/// clock, a typing indicator — and every change was a database write. The
/// name a jar is listed under only has to say what the pane was last for, so
/// one write per page is enough: the first real title after a commit, or,
/// for a page that never sets one, the pane's fallback title once the load
/// finishes. A title changed later by script on the same page waits for the
/// next navigation.
struct BrowserJarLabelGate {

    private(set) var isArmed = false

    /// A navigation committed: the next title is the new page's.
    mutating func navigationDidCommit() { isArmed = true }

    /// The label to write now, or `nil`.
    /// - Parameters:
    ///   - pageTitle: The page's own title, blank while it has none.
    ///   - fallback: What the pane calls itself without one (its host, or
    ///     "Browser"), taken only once the load has finished.
    ///   - finished: Whether the committed navigation has finished loading.
    ///   - current: The label the row already has.
    mutating func label(pageTitle: String?, fallback: String, finished: Bool, current: String?) -> String? {
        guard isArmed else { return nil }
        let candidate: String
        if let pageTitle, !pageTitle.isEmpty {
            candidate = pageTitle
        } else if finished {
            candidate = fallback
        } else {
            return nil
        }
        isArmed = false
        return candidate == current ? nil : candidate
    }
}
