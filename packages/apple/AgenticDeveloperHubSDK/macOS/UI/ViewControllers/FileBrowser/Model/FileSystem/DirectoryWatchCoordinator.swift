import Foundation
import Combine
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// Shared coordinator for directory tree scanning and filesystem watching.
///
/// Encapsulates the sync -> watch -> surgical-update lifecycle. All filesystem
/// I/O runs on background queues to avoid blocking the UI, and a sync reads one
/// level: the root's own entries. Everything below that is read when it is
/// shown — see `FileTreeNode.loadChildrenIfNeeded()`.
@MainActor
public final class DirectoryWatchCoordinator: ObservableObject {
    public let rootURL: URL
    public let excludedPrefixes: [String]
    public let config: FileTreeConfig

    /// `.gitignore`-style patterns for what to leave out of the tree, anchored
    /// at `rootURL`. Setting it re-filters the tree already on screen — every
    /// directory that has been read is read again — so a change shows at
    /// once, without collapsing anything the user had open.
    public var exclusions: GitIgnoreMatcher = .empty {
        didSet {
            guard exclusions != oldValue else { return }
            applyExclusions()
        }
    }

    /// The filter every read uses: `exclusions`, anchored at the root.
    private var filter: FileTreeFilter {
        FileTreeFilter(rootURL: rootURL, matcher: exclusions)
    }

    /// Bumped by every `applyExclusions()`, so a re-read that finishes after a
    /// newer one started is dropped instead of merging nodes that carry the
    /// filter it started with.
    private var exclusionsGeneration = 0

    @Published public var rootNode: FileTreeNode?
    @Published public var isSyncing: Bool = false

    private var watcher: FileSystemWatcher?
    private var onChangeCallback: (() -> Void)?

    public init(
        rootURL: URL,
        config: FileTreeConfig,
        excludedPrefixes: [String]
    ) {
        self.rootURL = rootURL
        self.config = config
        self.excludedPrefixes = excludedPrefixes
    }

    /// Reads the root directory and publishes it.
    ///
    /// Only the root's own entries: a directory's contents are read when the
    /// user opens it, so this is one `contentsOfDirectory` however big the
    /// checkout is.
    public func fullSync() {
        isSyncing = true
        let filter = self.filter
        let pkgExts = config.packageExtensions
        let rootURL = self.rootURL

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let tree = FileTreeNode(
                url: rootURL,
                isDirectory: true,
                loadChildren: true,
                filter: filter,
                packageExtensions: pkgExts
            )

            DispatchQueue.main.async {
                guard let self = self else { return }
                // Merged into the tree already on screen, not swapped for it.
                // A fresh root is a fresh object for every directory beneath
                // it, and the outline goes on holding the old ones — so a
                // folder the user had open stayed open while the read that
                // filled it belonged to a node nothing was showing any more,
                // and the folder came back empty. Re-using the nodes keeps
                // identity, and with it everything already read.
                if let existing = self.rootNode, existing.url == rootURL {
                    existing.merge(children: tree.children ?? [])
                } else {
                    self.rootNode = tree
                }
                self.isSyncing = false
                self.onChangeCallback?()
                self.logger.info("Sync complete for \(self.rootURL.lastPathComponent)")
                // The exclusions changed while this read was in flight, so it
                // read with the old ones.
                if filter != self.filter { self.applyExclusions() }
            }
        }
    }

    /// Starts filesystem watching. Calls onChange after each update.
    public func startWatching(onChange: (() -> Void)? = nil) {
        self.onChangeCallback = onChange
        watcher = FileSystemWatcher(rootPath: rootURL.path, excludedPrefixes: excludedPrefixes) { [weak self] paths in
            Task { @MainActor in
                self?.handleChanges(paths)
            }
        }
        watcher?.start()
    }

    public func stopWatching() {
        watcher?.stop()
        watcher = nil
    }

    /// Handles filesystem change events. Runs surgical updates on a background queue.
    private func handleChanges(_ paths: [String]) {
        logger.debug("FS changes: \(paths.count) path(s) in \(self.rootURL.lastPathComponent)")

        // A change that lands before the first sync has published a tree is
        // already covered by that sync — and clearing `isSyncing` here would
        // take the spinner down while it is still running, leaving the pane
        // claiming the directory is empty.
        guard let root = rootNode else { return }
        isSyncing = true

        // Collect affected directories
        var affectedDirs = Set<String>()
        for path in paths {
            affectedDirs.insert((path as NSString).deletingLastPathComponent)
        }

        // Build the path index on main (it's just pointer traversal, fast)
        var nodeIndex: [String: FileTreeNode] = [:]
        buildIndex(node: root, into: &nodeIndex)

        // Find the nodes that need updating
        let nodesToUpdate: [(FileTreeNode, URL)] = affectedDirs.compactMap { dirPath in
            guard let parentNode = nodeIndex[dirPath], parentNode.isDirectory else { return nil }
            return (parentNode, parentNode.url)
        }

        let filter = self.filter
        let pkgExts = config.packageExtensions

        // Do the filesystem I/O on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Load new children for each affected directory (this hits the filesystem)
            let updates: [(FileTreeNode, [FileTreeNode])] = nodesToUpdate.map { (node, url) in
                let newChildren = FileTreeNode.loadChildren(
                    for: url,
                    filter: filter,
                    packageExtensions: pkgExts
                )
                return (node, newChildren)
            }

            DispatchQueue.main.async {
                guard let self = self else { return }

                // Apply the updates on main thread (just pointer swaps).
                // Merged, not replaced: a fresh read hands back unread child
                // directories, and swapping those in would collapse whatever
                // the user had open below the directory that changed.
                for (node, newChildren) in updates {
                    node.merge(children: newChildren)
                }

                self.isSyncing = false
                self.onChangeCallback?()
            }
        }
    }

    /// Re-filters the tree on screen with the current `exclusions`.
    ///
    /// Every node gets the new filter, so a directory read later reads with
    /// it; every directory already read is read again, so what the change
    /// hides disappears and what it un-hides comes back. The reads are
    /// merged, so expanded folders stay expanded. Before the first sync there
    /// is nothing on screen, and the sync itself reads with the new filter.
    func applyExclusions() {
        guard let root = rootNode else { return }
        exclusionsGeneration += 1
        let generation = exclusionsGeneration
        let filter = self.filter
        let pkgExts = config.packageExtensions

        var loaded: [FileTreeNode] = []
        stampFilter(filter, on: root, collectingLoaded: &loaded)
        let targets = loaded.map { ($0, $0.url) }
        isSyncing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let updates = targets.map { node, url in
                (node, FileTreeNode.loadChildren(for: url, filter: filter, packageExtensions: pkgExts))
            }
            DispatchQueue.main.async {
                guard let self, generation == self.exclusionsGeneration else { return }
                for (node, fresh) in updates {
                    // `nil` for a read directory left with nothing to show,
                    // as `loadChildrenIfNeeded()` does: an empty array is
                    // "not read yet" and would keep a triangle that opens
                    // onto nothing. The root is always a list.
                    if fresh.isEmpty && node !== root {
                        node.children = nil
                    } else {
                        node.merge(children: fresh)
                    }
                }
                self.isSyncing = false
                self.onChangeCallback?()
            }
        }
    }

    /// Sets `filter` on `node` and everything below it, and collects the
    /// directories whose children have been read.
    private func stampFilter(
        _ filter: FileTreeFilter,
        on node: FileTreeNode,
        collectingLoaded loaded: inout [FileTreeNode]
    ) {
        node.filter = filter
        if node.isDirectory, !node.isPackage, node.childrenLoaded { loaded.append(node) }
        for child in node.children ?? [] {
            stampFilter(filter, on: child, collectingLoaded: &loaded)
        }
    }

    private func buildIndex(node: FileTreeNode, into index: inout [String: FileTreeNode]) {
        index[node.url.path] = node
        if let children = node.children {
            for child in children {
                buildIndex(node: child, into: &index)
            }
        }
    }
}

extension DirectoryWatchCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
