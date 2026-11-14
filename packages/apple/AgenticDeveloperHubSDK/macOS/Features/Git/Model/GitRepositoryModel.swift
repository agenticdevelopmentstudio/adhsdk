import Foundation
import os
import AgenticDeveloperHubSDKCore

/// One repository's refs, history and working copy, kept current by a watcher, and
/// the content reads a view asks for on demand (recipe
/// `workspace/git/git-repository-model`).
///
/// Every git call goes through `GitClient`, off the main thread; the model applies the
/// results on the main actor. A failed reload keeps the last good state and is logged,
/// never thrown, so a repository deleted underneath leaves its window showing what it
/// last knew. Each part carries a generation, so a result that a newer request has
/// overtaken is dropped rather than applied over the newer one.
@MainActor
public final class GitRepositoryModel: GitRefsDataSource, GitHistoryDataSource, GitWorkingCopyDataSource,
    GitContentSource {
    public let root: URL

    public private(set) var refs: [GitRef] = []
    public private(set) var stashes: [GitStash] = []
    public private(set) var submodules: [GitSubmodule] = []
    public private(set) var worktrees: [GitWorktree] = []

    public private(set) var commits: [GitCommit] = []
    public private(set) var graphRows: [CommitGraphLayout<String>.Row] = []
    public private(set) var query = GitLogQuery()

    public private(set) var staged: [GitFileChange] = []
    public private(set) var unstaged: [GitFileChange] = []

    private let client: GitClient
    private let watcher: GitRepositoryWatching

    private var layout = CommitGraphLayout<String>()
    private var commitIndex: [String: Int] = [:]
    private var refsByTarget: [String: [GitRef]] = [:]
    private var hasMoreHistory = false
    private var loadingMoreGeneration: Int?

    private var refsGeneration = 0
    private var historyGeneration = 0
    private var statusGeneration = 0

    private var observers: [WeakObserver] = []

    public init(root: URL, client: GitClient = .shared, watcher: GitRepositoryWatching) {
        self.root = root
        self.client = client
        self.watcher = watcher
    }

    // MARK: Lifecycle

    /// Starts the watcher and loads every part.
    public func start() async {
        watcher.start { [weak self] changes in
            Task { @MainActor [weak self] in
                await self?.refresh(changes)
            }
        }
        await refresh(Set(GitRepositoryChange.allCases))
    }

    /// Stops the watcher. The state stays as it was.
    public func stop() {
        watcher.stop()
    }

    /// Reloads the parts `changes` names, concurrently, then tells observers which of
    /// them actually changed. `.operation` reloads the working copy, where a merge or
    /// rebase shows its conflicts.
    public func refresh(_ changes: Set<GitRepositoryChange>) async {
        async let refsLoaded = changes.contains(.refs) ? reloadRefs() : false
        async let historyLoaded = changes.contains(.history) ? reloadHistory() : false
        let wantsStatus = changes.contains(.workingCopy) || changes.contains(.operation)
        async let statusLoaded = wantsStatus ? reloadStatus() : false

        var applied: Set<GitRepositoryChange> = []
        if await refsLoaded { applied.insert(.refs) }
        if await historyLoaded { applied.insert(.history) }
        if await statusLoaded {
            applied.formUnion(changes.intersection([.workingCopy, .operation]))
        }
        notify(applied)
    }

    // MARK: Observation

    /// Calls `handler` with the kinds of change after each refresh that changed
    /// something. Observation lasts as long as the returned token is held.
    public func observe(_ handler: @escaping (Set<GitRepositoryChange>) -> Void) -> AnyObject {
        let observer = Observer(handler: handler)
        observers.append(WeakObserver(observer: observer))
        return observer
    }

    private func notify(_ changes: Set<GitRepositoryChange>) {
        guard !changes.isEmpty else { return }
        observers.removeAll { $0.observer == nil }
        for observer in observers.compactMap(\.observer) {
            observer.handler(changes)
        }
    }

    // MARK: History

    /// Replaces the query, clears the history at once, and loads its first page.
    public func setQuery(_ query: GitLogQuery) async {
        self.query = query
        clearHistory()
        _ = await reloadHistory()
        notify([.history])
    }

    /// Appends the next page of history and its graph rows, if there is one.
    public func loadMore() async {
        guard hasMoreHistory, loadingMoreGeneration != historyGeneration else { return }
        let generation = historyGeneration
        loadingMoreGeneration = generation
        defer {
            if loadingMoreGeneration == generation { loadingMoreGeneration = nil }
        }
        var request = query
        request.skip = commits.count
        do {
            let page = try await client.log(request, in: root)
            guard generation == historyGeneration else { return }
            append(page)
            hasMoreHistory = request.limit > 0 && page.count >= request.limit
            notify([.history])
        } catch {
            logFailure("history page", error)
        }
    }

    public func refs(at commitID: String) -> [GitRef] {
        refsByTarget[commitID] ?? []
    }

    private func clearHistory() {
        historyGeneration += 1
        layout = CommitGraphLayout()
        commits = []
        graphRows = []
        commitIndex = [:]
        hasMoreHistory = false
    }

    /// Reloads from the top as many commits as are already shown (at least a page),
    /// so a refresh never shortens a list someone has scrolled.
    private func reloadHistory() async -> Bool {
        historyGeneration += 1
        let generation = historyGeneration
        var request = query
        request.skip = 0
        request.limit = max(query.limit, commits.count)
        do {
            let page = try await client.log(request, in: root)
            guard generation == historyGeneration else { return false }
            // Bumped again on apply, so a page `loadMore` started against the old list
            // is dropped rather than appended at the wrong offset.
            historyGeneration += 1
            layout = CommitGraphLayout()
            commits = []
            graphRows = []
            commitIndex = [:]
            append(page)
            hasMoreHistory = request.limit > 0 && page.count >= request.limit
            return true
        } catch {
            logFailure("history", error)
            return false
        }
    }

    private func append(_ page: [GitCommit]) {
        let rows = layout.append(page.map { (id: $0.id, parents: $0.parents) })
        for commit in page {
            commitIndex[commit.id] = commits.count
            commits.append(commit)
        }
        graphRows += rows
    }

    // MARK: Refs

    private func reloadRefs() async -> Bool {
        refsGeneration += 1
        let generation = refsGeneration
        do {
            async let refs = client.refs(in: root)
            async let stashes = client.stashes(in: root)
            async let submodules = client.submodules(in: root)
            async let worktrees = client.worktrees(in: root)
            let loaded = try await (refs, stashes, submodules, worktrees)
            guard generation == refsGeneration else { return false }
            self.refs = loaded.0
            self.stashes = loaded.1
            self.submodules = loaded.2
            self.worktrees = loaded.3
            refsByTarget = Dictionary(grouping: loaded.0, by: \.target)
            return true
        } catch {
            logFailure("refs", error)
            return false
        }
    }

    // MARK: Working copy

    private func reloadStatus() async -> Bool {
        statusGeneration += 1
        let generation = statusGeneration
        do {
            let status = try await client.status(in: root)
            guard generation == statusGeneration else { return false }
            staged = GitFileChange.list(status.stagedFiles)
            unstaged = GitFileChange.list(status.unstagedFiles)
            return true
        } catch {
            logFailure("status", error)
            return false
        }
    }

    // MARK: Content

    public func diff(_ target: GitDiffTarget, options: GitDiffOptions) async throws -> GitDiff {
        try await client.diff(target, options: options, in: root)
    }

    public func contents(path: String, at revision: String?) async throws -> Data? {
        try await client.fileContents(path: path, at: revision, in: root)
    }

    public func blame(path: String, at revision: String?) async throws -> GitBlame {
        try await client.blame(path: path, at: revision, in: root)
    }

    /// The commits that changed `path`, following it across renames.
    public func fileHistory(path: String) async throws -> [GitCommit] {
        var history = GitLogQuery()
        history.path = path
        history.followRenames = true
        return try await client.log(history, in: root)
    }

    /// A loaded commit by id; nil when it is not in the history loaded so far.
    public func commit(_ id: String) -> GitCommit? {
        commitIndex[id].map { commits[$0] }
    }

    // MARK: Failures

    private func logFailure(_ part: String, _ error: Error) {
        let description = (error as? GitClientError)?.logDescription ?? String(describing: type(of: error))
        Self.logger.error(
            "Git \(part, privacy: .public) reload failed, keeping the last state: \(description, privacy: .public)"
        )
    }
}

extension GitRepositoryModel: Loggable {
    public static nonisolated let logger = makeLogger()
}

@MainActor
private final class Observer {
    let handler: (Set<GitRepositoryChange>) -> Void

    init(handler: @escaping (Set<GitRepositoryChange>) -> Void) {
        self.handler = handler
    }
}

@MainActor
private struct WeakObserver {
    weak var observer: Observer?
}
