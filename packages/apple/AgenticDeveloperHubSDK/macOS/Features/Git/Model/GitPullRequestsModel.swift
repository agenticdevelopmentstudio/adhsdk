import AppKit
import AgenticDeveloperHubSDKCore
import os

/// One repository's open pull requests, read through the user's own `gh` (recipe
/// `workspace/git/git-views`, "Pull requests").
///
/// A load runs `availability` first, then lists the open pull requests. An answer that
/// `gh` cannot be asked (not installed, not logged in, no GitHub remote) at either step
/// leaves `pullRequests` nil, which hides the sidebar's section without a word; any other
/// failure (a timeout, a `gh` error, cancellation) leaves the section and the head
/// branch's pull request as they were. Loads come when the window opens, after a Fetch (forced) and on each `.refs`
/// change of the repository model, at most one per `minimumInterval`: a change inside
/// the interval is answered once, when it ends. A refs change while a forced load runs,
/// or inside the interval after one, is already answered by it and starts nothing; a
/// change of the checked-out branch always loads at once.
///
/// Each load also asks `gh` for the checked-out branch's own pull request
/// (`GitHubCLI.pullRequest(forBranch:in:)`, which drops forks and is not capped by the
/// list's limit), and the repository's default branch for the create form.
///
/// It runs `gh` only through `GitHubCLI` and git only through `GitClient`, never on
/// the main thread. Used on the main thread.
@MainActor
public final class GitPullRequestsModel {

    /// The shortest time between two loads a refs change starts.
    public static let minimumInterval: Duration = .seconds(30)

    /// The open pull requests; nil while `gh` cannot be asked, or before the first load
    /// that got an answer.
    public private(set) var pullRequests: [GitPullRequest]?

    /// The checked-out branch's open pull request from this repository (never a fork's);
    /// nil when there is none, on a detached HEAD, or while `gh` is unavailable.
    public private(set) var headPullRequest: GitPullRequest?

    /// Called after a load that changed `pullRequests`.
    var onChange: (() -> Void)?

    /// Opens a pull request's page in the browser. The browser coming forward is what
    /// the user asked for; the Kitchen never activates itself. Tests replace it.
    var openInBrowser: @MainActor (URL) -> Void = { url in
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(url, configuration: configuration) { _, error in
            guard let error else { return }
            let description = error.localizedDescription
            GitPullRequestsModel.logger.error("Could not open a pull request: \(description, privacy: .public)")
        }
    }

    /// The load in flight or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?

    let root: URL
    private weak var model: GitRepositoryModel?
    private let gitHub: GitHubCLI
    private let client: GitClient
    private let now: @MainActor () -> ContinuousClock.Instant
    private var lastLoad: ContinuousClock.Instant?
    /// When the last forced load started; refs changes inside the interval after it are
    /// its own echo (a Fetch moving remote branches) and start nothing.
    private var lastForcedLoad: ContinuousClock.Instant?
    /// How many loads are running or waiting for the one before them.
    private var loadsRunning = 0
    /// The checked-out branch the last load asked about; a different one loads at once.
    private var loadedHead: String?
    /// The load a refs change inside the interval asked for, waiting for it to end.
    private var trailingTask: Task<Void, Never>?
    private var observation: AnyObject?

    /// - Parameters:
    ///   - model: the repository model whose `.refs` changes start a load.
    ///   - gitHub: the one `gh` client the Git windows share.
    ///   - client: reads the commit subjects a new pull request's form starts with.
    public convenience init(model: GitRepositoryModel, gitHub: GitHubCLI, client: GitClient = .shared) {
        self.init(model: model, gitHub: gitHub, client: client, now: { ContinuousClock.now })
    }

    /// As the public initialiser, with the clock the interval is measured on.
    init(model: GitRepositoryModel, gitHub: GitHubCLI, client: GitClient,
         now: @escaping @MainActor () -> ContinuousClock.Instant) {
        root = model.root
        self.model = model
        self.gitHub = gitHub
        self.client = client
        self.now = now
        observation = model.observe { [weak self] changes in
            guard changes.contains(.refs) else { return }
            self?.refsDidChange()
        }
    }

    /// Whether the repository model has read its refs, so a load knows the head branch.
    var canLoad: Bool { !(model?.refs.isEmpty ?? true) }

    // MARK: - Loading

    /// A `.refs` change: a new checked-out branch loads at once; otherwise nothing while
    /// a forced load runs or just ran, else a throttled load.
    private func refsDidChange() {
        if model?.headBranch?.name != loadedHead {
            load(force: true)
            return
        }
        if loadsRunning > 0 { return }
        if let lastForcedLoad, now() - lastForcedLoad < Self.minimumInterval { return }
        load(force: false)
    }

    /// Reads the pull requests again: at once when `force`, otherwise at once when the
    /// last load was at least `minimumInterval` ago, else once when the interval ends.
    func load(force: Bool) {
        if force {
            trailingTask?.cancel()
            trailingTask = nil
            lastForcedLoad = now()
            startLoad()
            return
        }
        guard trailingTask == nil else { return }
        if let lastLoad {
            let wait = lastLoad + Self.minimumInterval - now()
            if wait > .zero {
                trailingTask = Task { [weak self] in
                    try? await Task.sleep(for: wait)
                    guard let self, !Task.isCancelled else { return }
                    self.trailingTask = nil
                    self.startLoad()
                }
                return
            }
        }
        startLoad()
    }

    /// Loads now and waits for it: after a create, so the new pull request is listed.
    func reload() async {
        load(force: true)
        await loadTask?.value
    }

    /// Stops listening for refs changes and drops a waiting load; the window closed.
    func stop() {
        trailingTask?.cancel()
        trailingTask = nil
        loadTask?.cancel()
        observation = nil
    }

    private func startLoad() {
        lastLoad = now()
        loadsRunning += 1
        let head = model?.headBranch?.name
        loadedHead = head
        let previous = loadTask
        let gitHub = gitHub
        let root = root
        loadTask = Task { [weak self] in
            // One `gh` at a time: a forced load waits for the one before it.
            await previous?.value
            let loaded = await Self.read(gitHub, in: root, head: head)
            guard let self else { return }
            self.loadsRunning -= 1
            guard !Task.isCancelled else { return }
            self.apply(loaded, head: head)
        }
    }

    /// What one load read.
    struct Loaded: Equatable {
        var pullRequests: [GitPullRequest]?
        var headPullRequest: GitPullRequest?
        /// The head branch's lookup failed for a passing reason: the head pull request shown
        /// stays, when it is still that branch's.
        var keepsHeadPullRequest = false
    }

    /// Whether `error` says `gh` cannot be asked at all (not installed, not logged in, no
    /// GitHub remote), which hides the section; anything else is passing and keeps it.
    nonisolated static func hidesPullRequests(_ error: Error) -> Bool {
        switch error as? GitHubCLIError {
        case .notInstalled?, .notAuthenticated?, .notGitHub?: true
        default: false
        }
    }

    /// `availability`, then the open pull requests and `head`'s own open one. nil keeps
    /// what is shown (a passing failure of either of the first two steps); an empty
    /// `Loaded` hides it (`hidesPullRequests`). A passing failure of the head lookup keeps
    /// the head pull request shown; one that says `gh` cannot be asked drops it.
    nonisolated static func read(_ gitHub: GitHubCLI, in root: URL, head: String?) async -> Loaded? {
        if case .failure(let error) = await gitHub.availability(in: root) {
            logger.info("gh unavailable: \(String(describing: error), privacy: .public)")
            return hidesPullRequests(error) ? Loaded() : nil
        }
        let list: [GitPullRequest]
        do {
            list = try await gitHub.pullRequests(in: root)
        } catch {
            logger.info("Pull requests unavailable: \(String(describing: error), privacy: .public)")
            return hidesPullRequests(error) ? Loaded() : nil
        }
        guard let head else { return Loaded(pullRequests: list) }
        do {
            let own = try await gitHub.pullRequest(forBranch: head, in: root)
            return Loaded(pullRequests: list, headPullRequest: own?.state.uppercased() == "OPEN" ? own : nil)
        } catch {
            logger.info("Branch pull request unavailable: \(String(describing: error), privacy: .public)")
            return Loaded(pullRequests: list, keepsHeadPullRequest: !hidesPullRequests(error))
        }
    }

    /// Shows what a load of `head` read. A kept head pull request (nil `loaded`, or
    /// `keepsHeadPullRequest`) survives only while it is `head`'s, so a branch switch
    /// never leaves the old branch's pull request on the new one.
    private func apply(_ loaded: Loaded?, head: String?) {
        let kept = headPullRequest.flatMap { $0.headRefName == head ? $0 : nil }
        let list = loaded.map(\.pullRequests) ?? pullRequests
        let own: GitPullRequest?
        if let loaded, !loaded.keepsHeadPullRequest {
            own = loaded.headPullRequest
        } else {
            own = kept
        }
        guard list != pullRequests || own != headPullRequest else { return }
        pullRequests = list
        headPullRequest = own
        onChange?()
    }

    // MARK: - Actions

    /// `gh pr checkout <number>`.
    func checkout(_ number: Int) async throws {
        try await gitHub.checkout(number, in: root)
    }

    /// `gh pr create` with `draft`'s values, returning the new pull request's URL. No `--head`:
    /// a bare branch name means a branch in the base repository, which breaks a fork or an
    /// upstream branch named differently, so `gh` takes the head from the checked-out branch's
    /// tracking ref. The caller re-reads the branch after the form, so that is the form's branch.
    func create(_ draft: GitPullRequestDraft) async throws -> URL {
        try await gitHub.create(title: draft.title, body: draft.body, base: draft.base,
                                draft: draft.draft, in: root)
    }

    /// The repository's default branch: `gh`'s answer, else `<remote>/HEAD` as git
    /// records it locally; nil when neither knows. Never guessed.
    func defaultBranch(remote: String?) async -> String? {
        if let name = try? await gitHub.defaultBranch(in: root) { return name }
        guard let remote else { return nil }
        let output = try? await client.run("symbolic-ref", ["--short", "refs/remotes/\(remote)/HEAD"], in: root)
        let target = output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let prefix = remote + "/"
        guard target.hasPrefix(prefix), target.count > prefix.count else { return nil }
        return String(target.dropFirst(prefix.count))
    }

    /// The subjects of HEAD's commits that are not on `base` (a remote branch's full
    /// name), newest first; with no base, those on no remote branch.
    func branchSubjects(notOn base: String?) async throws -> [String] {
        var query = GitLogQuery()
        query.revisions = base.map { ["HEAD", "^\($0)"] } ?? ["HEAD", "--not", "--remotes"]
        query.limit = 100
        return try await client.log(query, in: root).map(\.subject)
    }
}

extension GitPullRequestsModel: Loggable {
    public static nonisolated let logger = makeLogger()
}
