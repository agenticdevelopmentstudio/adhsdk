import Foundation

/// Watches every project's `.git` directory and refreshes a project's cached
/// state when its branches or worktrees change, and sweeps all of them once
/// when started, so a project being switched to already has a recent picture.
///
/// One FSEvents stream covers every repository. Only the files that say which
/// branches and worktrees exist trigger a refresh (`isRelevant`); the index,
/// objects and logs change on every `git status` and commit and say nothing
/// about either. Events are coalesced per repository over `debounce`.
@MainActor
public final class RepoStateWatcher {

    public typealias Repo = (id: UUID, directory: URL)
    public typealias WatcherFactory =
        (_ roots: [String], _ handler: @escaping @Sendable ([String]) -> Void) -> DirectoryWatching

    private let refresher: RepoStateRefresher
    private let makeWatcher: WatcherFactory
    private let debounce: Duration
    private var gitDirectories: [String: Repo] = [:]
    private var watcher: DirectoryWatching?
    private var pending: [UUID: Task<Void, Never>] = [:]
    private var sweepTask: Task<Void, Never>?

    public init(
        refresher: RepoStateRefresher,
        debounce: Duration = .milliseconds(750),
        makeWatcher: @escaping WatcherFactory = { roots, handler in
            FileSystemWatcher(rootPaths: roots, excludedPrefixes: [], handler: handler)
        }
    ) {
        self.refresher = refresher
        self.debounce = debounce
        self.makeWatcher = makeWatcher
    }

    /// Watches `repos` (replacing whatever was watched) and, when the set of
    /// repositories changed, sweeps them all in the given order.
    public func watch(_ repos: [Repo]) {
        var next: [String: Repo] = [:]
        for repo in repos {
            let gitDirectory = repo.directory.appendingPathComponent(".git").resolvingSymlinksInPath().path
            var isDirectory: ObjCBool = false
            // A worktree's `.git` is a file; its repository's own `.git`
            // directory is the one that changes, and that is watched for it.
            guard FileManager.default.fileExists(atPath: gitDirectory, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            next[gitDirectory] = repo
        }
        guard Set(next.keys) != Set(gitDirectories.keys) || watcher == nil else { return }
        gitDirectories = next
        watcher?.stop()
        let roots = Array(next.keys)
        watcher = makeWatcher(roots) { [weak self] paths in
            Task { @MainActor in self?.handle(paths) }
        }
        watcher?.start()
        sweepTask?.cancel()
        let ordered = repos.filter { repo in next.values.contains { $0.id == repo.id } }
        sweepTask = Task { [refresher] in await refresher.sweep(ordered) }
    }

    public func stop() {
        watcher?.stop()
        watcher = nil
        sweepTask?.cancel()
        pending.values.forEach { $0.cancel() }
        pending = [:]
        gitDirectories = [:]
    }

    func handle(_ paths: [String]) {
        for repo in Self.repos(touchedBy: paths, in: gitDirectories) {
            pending[repo.id]?.cancel()
            pending[repo.id] = Task { [weak self, debounce] in
                try? await Task.sleep(for: debounce)
                guard !Task.isCancelled, let self else { return }
                self.pending[repo.id] = nil
                await self.refresher.refresh(repo.id, at: repo.directory)
            }
        }
    }

    /// The repositories whose branches or worktrees `paths` may have changed.
    nonisolated static func repos(touchedBy paths: [String], in gitDirectories: [String: Repo]) -> [Repo] {
        var seen: Set<UUID> = []
        var result: [Repo] = []
        for path in paths {
            let owner = gitDirectories.first { path == $0.key || path.hasPrefix($0.key + "/") }
            guard let (gitDirectory, repo) = owner,
                  !seen.contains(repo.id) else { continue }
            let relative = path == gitDirectory ? "" : String(path.dropFirst(gitDirectory.count + 1))
            guard isRelevant(relative) else { continue }
            seen.insert(repo.id)
            result.append(repo)
        }
        return result
    }

    /// Whether a change to `relativePath` (inside a `.git` directory) can
    /// change which branches or worktrees exist or which branch is checked out.
    nonisolated static func isRelevant(_ relativePath: String) -> Bool {
        if relativePath.hasSuffix(".lock") { return false }
        let parts = relativePath.split(separator: "/")
        guard let first = parts.first else { return true }
        switch first {
        case "HEAD", "packed-refs": return parts.count == 1
        case "refs": return parts.count < 2 || parts[1] == "heads"
        case "worktrees": return parts.count <= 2 || (parts.count == 3 && parts[2] == "HEAD")
        default: return false
        }
    }
}
