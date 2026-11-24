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
/// its pane leaves the saved layout, a worktree jar goes when no pane in that
/// worktree is left in the layout, and a WebKit store whose identifier is in no
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
    public struct DataStores: Sendable {
        public var identifiers: @MainActor @Sendable () async -> [UUID]
        public var remove: @MainActor @Sendable (UUID) async throws -> Void

        public init(
            identifiers: @escaping @MainActor @Sendable () async -> [UUID],
            remove: @escaping @MainActor @Sendable (UUID) async throws -> Void
        ) {
            self.identifiers = identifiers
            self.remove = remove
        }

        public static var webKit: DataStores {
            DataStores(
                // WebKit's class-level store calls reply on WebKit's main
                // RunLoop, which WebKit only creates when its first object is
                // made. Called at launch, before any web view exists, the
                // reply dispatches to a null RunLoop and the app dies
                // (SIGSEGV in `WTF::RunLoop::dispatch`). Touching the default
                // store first initializes WebKit; the completion-handler forms
                // keep the calls on the main actor.
                identifiers: { @MainActor in
                    _ = WKWebsiteDataStore.default()
                    return await withCheckedContinuation { done in
                        WKWebsiteDataStore.fetchAllDataStoreIdentifiers { done.resume(returning: $0) }
                    }
                },
                remove: { @MainActor id in
                    _ = WKWebsiteDataStore.default()
                    try await withCheckedThrowingContinuation { (done: CheckedContinuation<Void, Error>) in
                        WKWebsiteDataStore.remove(forIdentifier: id) { error in
                            if let error { done.resume(throwing: error) } else { done.resume() }
                        }
                    }
                }
            )
        }

        /// Every store of every engine: WebKit's, then each one an engine
        /// registered with `registerEngineStores(_:)`. A jar is one session
        /// whichever engine holds it, so a leftover is swept from all of them.
        @MainActor public static var allEngines: DataStores {
            combined([.webKit] + BrowserJarReconciler.engineStores)
        }

        /// Several engines' stores as one: the union of their identifiers,
        /// and a removal that asks each engine holding the identifier. Every
        /// engine is asked even when one refuses; the first refusal is
        /// rethrown so the store is retried on a later pass.
        public static func combined(_ stores: [DataStores]) -> DataStores {
            DataStores(
                identifiers: {
                    var all: [UUID] = []
                    for store in stores {
                        for id in await store.identifiers() where !all.contains(id) { all.append(id) }
                    }
                    return all
                },
                remove: { id in
                    var failure: Error?
                    for store in stores where await store.identifiers().contains(id) {
                        do { try await store.remove(id) } catch { failure = failure ?? error }
                    }
                    if let failure { throw failure }
                }
            )
        }
    }

    /// Stores other engines keep jars in. The Chromium framework registers
    /// its on-disk jar directories here, so the toolkit's reconciler sweeps a
    /// Chrome pane's leftover session without linking Chromium.
    public private(set) static var engineStores: [DataStores] = []

    /// Adds an engine's jar stores to every later sweep.
    public static func registerEngineStores(_ stores: DataStores) {
        engineStores.append(stores)
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
    ///   - dataStores: The WebKit stores to sweep.
    ///   - now: The time the grace period is measured to; a test moves it on.
    public static func reconcile(
        database: ProjectDatabase,
        dataStores: DataStores = .allEngines,
        now: Date = Date()
    ) async {
        do {
            let records = try database.allBrowserJars()
            let live = try database.liveBrowserPanes()
            let stale = staleJarIDs(
                records: records,
                livePanes: live,
                liveNodeIDs: try database.livePaneNodeIDs(),
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
    /// A jar is kept while a pane that could use it is in the layout,
    /// whatever that pane's setting now says — moving panes off a jar and
    /// back again should find the session they left. So a pane jar is kept
    /// while its pane is live, and a worktree jar while any live pane of that
    /// project and worktree is, whichever jar it resolves to. Re-pointing a
    /// pane, or the app-wide default, never deletes a jar; removing the last
    /// pane that could use it does. `inUse` is kept
    /// regardless: it is what open panes hold, whether or not their layout has
    /// been saved yet. `liveNodeIDs` adds panes the layout knows only by a
    /// state key (`ProjectDatabase.livePaneNodeIDs()`) to `livePanes`' own.
    /// A row younger than `newJarGracePeriod` by `createdAt` is kept too; a
    /// row with no date there has no such protection.
    public static func staleJarIDs(
        records: [BrowserJarRecord],
        livePanes: [LiveBrowserPane],
        liveNodeIDs extraLiveNodeIDs: Set<UUID> = [],
        inUse: Set<UUID> = [],
        createdAt: [UUID: Date] = [:],
        now: Date = Date()
    ) -> Set<UUID> {
        let liveNodeIDs = Set(livePanes.map(\.nodeID)).union(extraLiveNodeIDs)
        let worktreesInUse = Set(livePanes.map { WorktreeKey(repoID: $0.repoID, path: $0.worktreePath) })
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
    public static func start(database: ProjectDatabase) {
        observation = NotificationCenter.default
            .publisher(for: ProjectWorkspace.didPersistTabsNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                MainActor.assumeIsolated { schedule(database: database, delay: 1) }
            }
        schedule(database: database, delay: 0)
    }

    private static func schedule(database: ProjectDatabase, delay: TimeInterval) {
        guard !isRunning else {
            isPending = true
            return
        }
        isRunning = true
        Task { @MainActor in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            await reconcile(database: database)
            isRunning = false
            if isPending {
                isPending = false
                schedule(database: database, delay: 1)
            }
        }
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
