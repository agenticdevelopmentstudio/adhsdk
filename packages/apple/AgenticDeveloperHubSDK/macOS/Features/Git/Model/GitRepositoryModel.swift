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

    /// Loads the four sidebar sources independently, so one that fails (a submodule
    /// list git refuses over an orphan gitlink, say) costs only itself: a failed source
    /// is logged and keeps its last good value, except submodules, which a failure
    /// leaves empty rather than stale. True when any source was applied.
    private func reloadRefs() async -> Bool {
        refsGeneration += 1
        let generation = refsGeneration
        let client = client
        let root = root
        async let refs = Self.load { try await client.refs(in: root) }
        async let stashes = Self.load { try await client.stashes(in: root) }
        async let submodules = Self.load { try await client.submodules(in: root) }
        async let worktrees = Self.load { try await client.worktrees(in: root) }
        let loaded = await (refs: refs, stashes: stashes, submodules: submodules, worktrees: worktrees)
        guard generation == refsGeneration else { return false }

        var applied = false
        switch loaded.refs {
        case .success(let value):
            self.refs = value
            refsByTarget = Dictionary(grouping: value, by: \.target)
            applied = true
        case .failure(let error): logFailure("refs", error)
        }
        switch loaded.stashes {
        case .success(let value):
            self.stashes = value
            applied = true
        case .failure(let error): logFailure("stashes", error)
        }
        switch loaded.submodules {
        case .success(let value):
            self.submodules = value
            applied = true
        case .failure(let error):
            logFailure("submodules", error)
            if !self.submodules.isEmpty {
                self.submodules = []
                applied = true
            }
        }
        switch loaded.worktrees {
        case .success(let value):
            self.worktrees = value
            applied = true
        case .failure(let error): logFailure("worktrees", error)
        }
        return applied
    }

    private nonisolated static func load<T: Sendable>(
        _ body: @Sendable () async throws -> T
    ) async -> Result<T, Error> {
        do { return .success(try await body()) } catch { return .failure(error) }
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

    public func changedFiles(commit: String) async throws -> [GitFileListItem] {
        try await client.changedFiles(commit: commit, in: root)
    }

    public func contents(path: String, at revision: String?, maximumBytes: Int?) async throws -> Data? {
        try await client.fileContents(path: path, at: revision, in: root, maximumBytes: maximumBytes)
    }

    public func blame(path: String, at revision: String?) async throws -> GitBlame {
        try await client.blame(path: path, at: revision, in: root)
    }

    /// The commits that changed `path`, following it across renames, each with the
    /// file's path at that commit.
    /// At most `GitClient.fileHistoryLimit` commits; a history that reaches it is logged,
    /// since the list then stops there.
    public func fileHistory(path: String) async throws -> [GitFileHistoryEntry] {
        let entries = try await client.fileHistory(path: path, in: root)
        if entries.count >= GitClient.fileHistoryLimit {
            Self.logger.info("Git file history reached its limit of \(GitClient.fileHistoryLimit) commits")
        }
        return entries
    }

    /// A loaded commit by id; nil when it is not in the history loaded so far.
    public func commit(_ id: String) -> GitCommit? {
        commitIndex[id].map { commits[$0] }
    }

    // MARK: Failures

    /// Logs a failed load. A cancelled one (a search the window replaced, whose
    /// `git log` was terminated) is not a failure and is logged at debug level only.
    private func logFailure(_ part: String, _ error: Error) {
        if error is CancellationError {
            Self.logger.debug("Git \(part, privacy: .public) load cancelled")
            return
        }
        let description = GitClientError.logDescription(of: error)
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
