//
//  BrowserJarReconciler.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import Combine
import WebKit
import AgenticDeveloperHubSDKCore
import os

/// Collects storage jars nothing uses any more, from both the registry and
/// WebKit's disk.
///
/// A jar is a cookie and site-data store; one left behind when its pane closes
/// is a logged-in session nobody can see or sign out of. So a pane jar goes when
/// its pane leaves the saved layout, a worktree jar goes when no live pane in
/// that worktree resolves to it, and a WebKit store whose identifier is in no
/// row goes too — the last covers a crash between deleting a row and deleting
/// its store.
///
/// Every pass starts from what is on disk and in the registry now, and touches
/// only what that says is unused, so running it twice, or after a crash part
/// of the way through, is the same as running it once (`idempotency`).
///
/// **`browser_jars` owns every named WebKit data store in the process.** The
/// sweep removes any `WKWebsiteDataStore(forIdentifier:)` store whose
/// identifier is in no row, whoever made it. Today the jars are the only code
/// that makes named stores; a future feature that wants one of its own must
/// register it in `browser_jars` or be exempted from the sweep here, or its
/// store is deleted on the next pass.
@MainActor
public enum BrowserJarReconciler {

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserJars")

    /// The named WebKit stores on disk, and how one is removed — WebKit's own
    /// by default; a test hands in a fake so it never sweeps the test host's
    /// real stores.
    public struct DataStores {
        public var identifiers: @MainActor () async -> [UUID]
        public var remove: @MainActor (UUID) async throws -> Void

        public init(
            identifiers: @escaping @MainActor () async -> [UUID],
            remove: @escaping @MainActor (UUID) async throws -> Void
        ) {
            self.identifiers = identifiers
            self.remove = remove
        }

        public static var webKit: DataStores {
            DataStores(
                identifiers: { await WKWebsiteDataStore.allDataStoreIdentifiers },
                remove: { try await WKWebsiteDataStore.remove(forIdentifier: $0) }
            )
        }
    }

    /// How long a new jar row is safe from the reconciler.
    ///
    /// The in-use set is this process's alone, and a Debug build lets several
    /// copies share one database: a row another copy made a moment ago, for a
    /// pane whose layout it has not saved yet, is in no saved layout and in
    /// none of this copy's panes. A minute covers that gap; a leftover is
    /// collected on a later pass.
    public static let newJarGracePeriod: TimeInterval = 60

    /// One pass. Safe to call at any time and from anywhere on the main actor.
    ///
    /// - Parameters:
    ///   - settings: Where a pane without its own storage-jar override reads
    ///     the value from — the same store the panes fall back to, so the
    ///     reconciler resolves a pane the way the pane does.
    ///   - dataStores: The WebKit stores to sweep.
    ///   - now: The time the grace period is measured to; a test moves it on.
    public static func reconcile(
        database: ProjectDatabase,
        settings: SettingsStore = UserSettings.shared,
        dataStores: DataStores = .webKit,
        now: Date = Date()
    ) async {
        do {
            let records = try database.allBrowserJars()
            let live = try database.liveBrowserPanes()
            let stale = staleJarIDs(
                records: records,
                livePanes: live,
                liveNodeIDs: try database.livePaneNodeIDs(),
                effectiveJar: { effectiveJar(of: $0, database: database, settings: settings) },
                inUse: jarIDsInUse(database: database),
                createdAt: try database.browserJarCreationDates(),
                now: now
            )
            for id in stale {
                try database.deleteBrowserJar(id: id)
            }
        } catch {
            logger.error("browser jar reconcile failed: \(error.localizedDescription, privacy: .public)")
            // The WebKit sweep below is driven by the registry, so it must not
            // run off a registry that could not be read.
            return
        }

        let identifiers = await dataStores.identifiers()
        for identifier in identifiers {
            // Asked afresh for each store: the await above and each removal
            // below let a pane be built in between, and a pane that made its
            // jar a moment ago must not lose it.
            guard let kept = try? keptIdentifiers(database: database), !kept.contains(identifier) else {
                continue
            }
            do {
                try await dataStores.remove(identifier)
            } catch {
                // WebKit refuses while a web view still holds the store; the
                // next pass gets it.
                logger.info("browser jar store not removed yet: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// The jars no live pane uses, out of `records`.
    ///
    /// A pane jar is kept while its pane is in the layout, whatever the pane's
    /// setting now says — moving a pane off its own jar and back again should
    /// find the session it left. A worktree jar is kept while any live pane of
    /// that project and worktree resolves to `.worktree`. `inUse` is kept
    /// regardless: it is what open panes hold, whether or not their layout has
    /// been saved yet. `liveNodeIDs` adds panes the layout knows only by a
    /// state key (`ProjectDatabase.livePaneNodeIDs()`) to `livePanes`' own.
    /// A row younger than `newJarGracePeriod` by `createdAt` is kept too; a
    /// row with no date there has no such protection.
    public static func staleJarIDs(
        records: [BrowserJarRecord],
        livePanes: [LiveBrowserPane],
        liveNodeIDs extraLiveNodeIDs: Set<UUID> = [],
        effectiveJar: (LiveBrowserPane) -> BrowserStorageJar,
        inUse: Set<UUID> = [],
        createdAt: [UUID: Date] = [:],
        now: Date = Date()
    ) -> Set<UUID> {
        let liveNodeIDs = Set(livePanes.map(\.nodeID)).union(extraLiveNodeIDs)
        let worktreesInUse = Set(livePanes.filter { effectiveJar($0) == .worktree }
            .map { WorktreeKey(repoID: $0.repoID, path: $0.worktreePath) })
        func isNew(_ record: BrowserJarRecord) -> Bool {
            createdAt[record.id].map { now.timeIntervalSince($0) < newJarGracePeriod } ?? false
        }
        var stale: Set<UUID> = []
        for record in records where !inUse.contains(record.id) && !isNew(record) {
            switch record.kind {
            case .pane:
                if !(record.paneNodeID.map(liveNodeIDs.contains) ?? false) {
                    stale.insert(record.id)
                }
            case .worktree:
                let key = WorktreeKey(repoID: record.repoID, path: record.worktreePath)
                if !worktreesInUse.contains(key) {
                    stale.insert(record.id)
                }
            }
        }
        return stale
    }

    // MARK: - Running it

    private static var observation: AnyCancellable?
    private static var isRunning = false
    private static var isPending = false

    /// Runs a pass now and after every project window saves its tabs, which
    /// is when panes leave the layout.
    ///
    /// Saves arrive in bursts — a drag fires several — so passes are spaced a
    /// second apart and a save during a pass asks for one more, never for one
    /// per save.
    public static func start(database: ProjectDatabase, settings: SettingsStore = UserSettings.shared) {
        observation = NotificationCenter.default
            .publisher(for: ProjectWorkspace.didPersistTabsNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                MainActor.assumeIsolated { schedule(database: database, settings: settings, delay: 1) }
            }
        schedule(database: database, settings: settings, delay: 0)
    }

    private static func schedule(database: ProjectDatabase, settings: SettingsStore, delay: TimeInterval) {
        guard !isRunning else {
            isPending = true
            return
        }
        isRunning = true
        Task { @MainActor in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            await reconcile(database: database, settings: settings)
            isRunning = false
            if isPending {
                isPending = false
                schedule(database: database, settings: settings, delay: 1)
            }
        }
    }

    // MARK: - Reading a pane's jar

    /// What `pane` resolves to: its own override if it has one, else the
    /// shared setting. Private browsing is not consulted — a private pane
    /// holds no jar, and the jar it would return to when private browsing is
    /// turned off is the one worth keeping.
    static func effectiveJar(
        of pane: LiveBrowserPane,
        database: ProjectDatabase,
        settings: SettingsStore
    ) -> BrowserStorageJar {
        // The pane's own decode path, over its own rows: the override is read
        // exactly as the pane's layered settings would read it. A nested pane's
        // rows are under its owner, with its own id in the key.
        let overrides = PaneStateSettingsStorageProvider(
            store: DatabasePaneStateReader(
                database: database,
                repoID: pane.repoID,
                nodeID: pane.stateNodeID,
                prefix: pane.stateKeyPrefix(ComposableTabsViewRegistry.browserStatePrefix)
            )
        )
        let key = UserSettings.browserPrivacyStorageJar
        return overrides.contains(key) ? overrides.get(key) : settings.get(key)
    }

    private static func jarIDsInUse(database: ProjectDatabase) -> Set<UUID> {
        BrowserJarRegistry.existing(for: database)?.jarIDsInUse ?? []
    }

    private static func keptIdentifiers(database: ProjectDatabase) throws -> Set<UUID> {
        Set(try database.allBrowserJars().map(\.id)).union(jarIDsInUse(database: database))
    }
}

private struct WorktreeKey: Hashable {
    let repoID: UUID
    let path: String
}

/// A pane's state rows, read straight from the database for a pane that may
/// have no window open. Read-only: the reconciler decides nothing by writing.
@MainActor
private final class DatabasePaneStateReader: PaneStateStore {
    let database: ProjectDatabase
    let repoID: UUID
    let nodeID: UUID
    let prefix: String

    init(database: ProjectDatabase, repoID: UUID, nodeID: UUID, prefix: String) {
        self.database = database
        self.repoID = repoID
        self.nodeID = nodeID
        self.prefix = prefix
    }

    func paneStateValue(forKey key: String) -> String? {
        try? database.paneState(repoID: repoID, nodeID: nodeID, key: prefix + key)
    }

    func setPaneStateValue(_ value: String?, forKey key: String) {}
}
