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
    /// The commit HEAD resolves to; nil on an unborn HEAD, an orphan branch included.
    public private(set) var headCommit: String?
    /// The checked-out branch's (or a detached HEAD's) tip and newest reflog entries,
    /// loaded with the refs, for Undo (`GitRepositoryModel+Reflog`); `.empty` before the
    /// first load.
    public private(set) var undoState: GitUndoState = .empty
    /// Whether and how the repository uses Git LFS; nil until it first loads, with the
    /// refs, and kept at its last good value when a load fails.
    public private(set) var lfs: GitLFSState?
    /// The repository's open pull requests, read through `gh`; nil (no `GitHubCLI`)
    /// leaves `pullRequests` nil (GitRepositoryModel+PullRequests.swift).
    public internal(set) var pullRequestList: GitPullRequestsModel?

    public private(set) var commits: [GitCommit] = []
    public private(set) var graphRows: [CommitGraphLayout<String>.Row] = []
    public private(set) var query = GitLogQuery()

    public private(set) var staged: [GitFileChange] = []
    public private(set) var unstaged: [GitFileChange] = []
    /// The unmerged paths, each with how it is unmerged; each is also `.conflicted` in `unstaged`.
    public private(set) var conflicts: [String: GitConflictKind] = [:]

    /// The merge, rebase, cherry-pick or revert the working tree is in the middle of; none
    /// before it first loads. Reloaded with the working copy, so after every `perform`.
    public private(set) var operationState: GitOperationState = .none

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
    private var operationGeneration = 0

    private var observers: [WeakObserver] = []

    /// Commit signatures, checked lazily for the rows the history draws and cached by sha
    /// for the model's life (GitRepositoryModel+Signatures.swift). Each batch that lands
    /// posts `.annotations`; one that fails is logged.
    private(set) lazy var signatureLoader = makeSignatureLoader()

    // Built in a method, not in the lazy initializer: the compiler cannot evaluate the
    // loader's main-actor default arguments there.
    private func makeSignatureLoader() -> GitShaBatchLoader<GitSignature> {
        GitShaBatchLoader<GitSignature>(
            provider: { [client, root] shas in
                try await client.signatures(for: shas, in: root)
            },
            onLoad: { [weak self] in self?.notify([.annotations]) },
            onFailure: { [weak self] error in self?.logFailure("signatures", error) }
        )
    }

    /// Where the history's Coding Partner reviews are read from; nil leaves every review
    /// absent (GitRepositoryModel+Reviews.swift). Read-only: the model never writes one.
    public let reviewsProvider: (any GitReviewsProviding)?

    /// The reviews of the rows the history draws, cached by sha until `invalidateReviews()`;
    /// nil without a provider. Each batch that lands posts `.annotations`.
    private(set) lazy var reviewLoader: GitShaBatchLoader<GitCommitReview>? = makeReviewLoader()

    private func makeReviewLoader() -> GitShaBatchLoader<GitCommitReview>? {
        guard let provider = reviewsProvider else { return nil }
        let path = root.path
        return GitShaBatchLoader<GitCommitReview>(
            provider: { shas in await provider.reviews(repoPath: path, shas: shas) },
            onLoad: { [weak self] in self?.notify([.annotations]) }
        )
    }

    public init(root: URL, client: GitClient = .shared, watcher: GitRepositoryWatching,
                reviews: (any GitReviewsProviding)? = nil) {
        self.root = root
        self.client = client
        self.watcher = watcher
        self.reviewsProvider = reviews
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
    /// them actually changed. `.operation` and `.workingCopy` each reload both the working
    /// copy, where a merge or rebase shows its conflicts, and the operation state; an
    /// operation state that changed is reported as `.operation` even when only
    /// `.workingCopy` was named (an operation started outside the app).
    public func refresh(_ changes: Set<GitRepositoryChange>) async {
        async let refsLoaded = changes.contains(.refs) ? reloadRefs() : false
        async let historyLoaded = changes.contains(.history) ? reloadHistory() : false
        let wantsStatus = changes.contains(.workingCopy) || changes.contains(.operation)
        async let statusLoaded = wantsStatus ? reloadStatus() : false
        async let operation = wantsStatus ? reloadOperation() : OperationReload(loaded: false, changed: false)

        var applied: Set<GitRepositoryChange> = []
        if await refsLoaded { applied.insert(.refs) }
        if await historyLoaded { applied.insert(.history) }
        let operationReload = await operation
        if await statusLoaded || operationReload.loaded {
            applied.formUnion(changes.intersection([.workingCopy, .operation]))
        }
        if operationReload.changed { applied.insert(.operation) }
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
        async let head = Self.load { try await client.resolveCommit("HEAD", in: root) }
        async let lfs = Self.load { try await client.lfsState(in: root) }
        async let reflog = Self.load { try await client.undoState(in: root) }
        let loaded = await (refs: refs, stashes: stashes, submodules: submodules, worktrees: worktrees, head: head)
        let lfsLoaded = await lfs
        let reflogLoaded = await reflog
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
        switch loaded.head {
        case .success(let value):
            if value != headCommit {
                headCommit = value
                applied = true
            }
        case .failure(let error): logFailure("HEAD", error)
        }
        switch lfsLoaded {
        case .success(let value):
            if value != self.lfs {
                self.lfs = value
                applied = true
            }
        case .failure(let error): logFailure("LFS", error)
        }
        switch reflogLoaded {
        case .success(let value):
            if value != undoState {
                undoState = value
                applied = true
            }
        case .failure(let error): logFailure("reflog", error)
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
            conflicts = status.conflicts
            return true
        } catch {
            logFailure("status", error)
            return false
        }
    }

    // MARK: Resolution

    /// Writes `text` over `path`, relative to the root, as UTF-8 — the one file the window
    /// writes itself, a merge view's result; every other change goes through `perform`.
    /// The write is atomic and off the main actor, keeps the file's POSIX permissions, and
    /// is followed by a working-copy refresh. A path that leaves the root is refused with
    /// `GitClientError.invalidArgument` before anything is written; the root and the
    /// file's folder are compared with their symbolic links resolved, so a linked folder
    /// inside the root cannot lead the write outside it. An atomic write replaces a
    /// symbolic link to the file itself with a regular file.
    public func writeResolution(_ text: String, to path: String) async throws {
        let base = root.resolvingSymlinksInPath().standardizedFileURL
        let named = root.appendingPathComponent(path).standardizedFileURL
        let url = named.deletingLastPathComponent().resolvingSymlinksInPath()
            .appendingPathComponent(named.lastPathComponent)
        guard !path.isEmpty, url.path.hasPrefix(base.path + "/") else {
            let reason = "“\(path)” is not inside the repository."
            throw GitClientError.invalidArgument(verb: "resolve", argument: reason)
        }
        let data = Data(text.utf8)
        try await Task.detached(priority: .userInitiated) {
            let manager = FileManager.default
            let permissions = (try? manager.attributesOfItem(atPath: url.path))?[.posixPermissions]
            try data.write(to: url, options: .atomic)
            if let permissions {
                try manager.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
            }
        }.value
        await refresh([.workingCopy])
    }

    // MARK: Operation state

    private struct OperationReload {
        let loaded: Bool
        let changed: Bool
    }

    /// Reads the operation state; a failure keeps the last value and is logged.
    private func reloadOperation() async -> OperationReload {
        operationGeneration += 1
        let generation = operationGeneration
        do {
            let state = try await client.operationState(in: root)
            guard generation == operationGeneration else { return OperationReload(loaded: false, changed: false) }
            let changed = state != operationState
            operationState = state
            return OperationReload(loaded: true, changed: changed)
        } catch {
            logFailure("operation state", error)
            return OperationReload(loaded: false, changed: false)
        }
    }

    // MARK: Actions

    /// Whether a `perform` is running its git command. It goes false before the refresh
    /// that follows, so observers told of that refresh already see it false.
    public private(set) var isPerforming = false
    private var performingCount = 0 {
        didSet { isPerforming = performingCount > 0 }
    }

    /// HEAD's reflog, newest first, at most `limit` entries, for the reflog browser.
    public func reflog(limit: Int) async throws -> [GitReflogEntry] {
        try await client.reflog(limit: limit, in: root)
    }

    /// Undo's state read fresh from git at the moment Undo is pressed, off the main thread.
    public func undoPreflight() async throws -> GitUndoPreflight {
        try await client.undoPreflight(in: root)
    }

    /// The checked-out local branch; nil on a detached HEAD or before the refs load.
    public var headBranch: GitRef? {
        refs.first { $0.kind == .localBranch && $0.isHead }
    }

    /// False on an unborn HEAD, including an orphan branch beside others: HEAD names no
    /// commit, so there is nothing to amend.
    public var hasCommits: Bool {
        headCommit != nil
    }

    /// Runs `action`, then refreshes every part whether it succeeded or failed (a failed
    /// merge or pull can still have changed the repository), and rethrows its error.
    public func perform(_ action: GitAction, caller: GitCaller = GitCaller()) async throws {
        performingCount += 1
        var failure: Error?
        do {
            try await client.perform(action, in: root, caller: caller)
        } catch {
            failure = error
        }
        performingCount -= 1
        await refresh(Set(GitRepositoryChange.allCases))
        if let failure { throw failure }
    }

    /// The repository's remote names, sorted.
    public func remotes(caller: GitCaller = GitCaller()) async throws -> [String] {
        try await client.remotes(in: root, caller: caller)
    }

    /// The stash list as git reports it now, not as the last refresh left it: a stash's
    /// `stash@{N}` shifts whenever another is pushed or dropped.
    public func currentStashes(caller: GitCaller = GitCaller()) async throws -> [GitStash] {
        try await client.stashes(in: root, caller: caller)
    }

    /// HEAD's full message, or nil on an unborn HEAD.
    public func lastCommitMessage(caller: GitCaller = GitCaller()) async throws -> String? {
        try await client.lastCommitMessage(in: root, caller: caller)
    }

    /// The interactive rebase of the checked-out branch onto `commit`, every entry picked.
    public func rebasePlan(onto commit: String, caller: GitCaller = GitCaller()) async throws -> GitRebasePlan {
        try await client.rebasePlan(onto: commit, in: root, caller: caller)
    }

    /// The full message of every commit after `onto` on HEAD's first-parent line, by sha.
    public func commitMessages(after onto: String, caller: GitCaller = GitCaller()) async throws
        -> [String: String] {
        try await client.commitMessages(after: onto, in: root, caller: caller)
    }

    /// Where `git push` would send local `branch` (its `@{push}`, such as `origin/feature`).
    public func pushDestination(of branch: String, caller: GitCaller = GitCaller()) async throws -> String {
        try await client.pushDestination(of: branch, in: root, caller: caller)
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
