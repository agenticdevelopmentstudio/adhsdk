import AppKit
import AgenticDeveloperHubSDKCore
import os

/// One repository's open pull requests, read through the user's own `gh` (recipe
/// `workspace/git/git-views`, "Pull requests").
///
/// A load runs `availability` first, then lists the open pull requests; any error at
/// either step leaves `pullRequests` nil, which hides the sidebar's section without a
/// word. Loads come when the window opens (`load(force: true)`), after a Fetch (forced
/// too) and on each `.refs` change of the repository model, at most one per
/// `minimumInterval`: a change inside the interval is answered once, when it ends.
///
/// It runs `gh` only through `GitHubCLI` and git only through `GitClient`, never on
/// the main thread. Used on the main thread.
@MainActor
public final class GitPullRequestsModel {

    /// The shortest time between two loads a refs change starts.
    public static let minimumInterval: Duration = .seconds(30)

    /// The open pull requests; nil while `gh` is unavailable or before the first load.
    public private(set) var pullRequests: [GitPullRequest]?

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
    private let gitHub: GitHubCLI
    private let client: GitClient
    private let now: @MainActor () -> ContinuousClock.Instant
    private var lastLoad: ContinuousClock.Instant?
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
        self.gitHub = gitHub
        self.client = client
        self.now = now
        observation = model.observe { [weak self] changes in
            guard changes.contains(.refs) else { return }
            self?.load(force: false)
        }
    }

    // MARK: - Loading

    /// Reads the pull requests again: at once when `force`, otherwise at once when the
    /// last load was at least `minimumInterval` ago, else once when the interval ends.
    func load(force: Bool) {
        if force {
            trailingTask?.cancel()
            trailingTask = nil
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
        let previous = loadTask
        let gitHub = gitHub
        let root = root
        loadTask = Task { [weak self] in
            // One `gh` at a time: a forced load waits for the one before it.
            await previous?.value
            let loaded = await Self.read(gitHub, in: root)
            guard let self, !Task.isCancelled else { return }
            self.apply(loaded)
        }
    }

    /// `availability`, then the open pull requests; nil on any error.
    private nonisolated static func read(_ gitHub: GitHubCLI, in root: URL) async -> [GitPullRequest]? {
        guard case .success = await gitHub.availability(in: root) else { return nil }
        do {
            return try await gitHub.pullRequests(in: root)
        } catch {
            logger.info("Pull requests unavailable: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    private func apply(_ loaded: [GitPullRequest]?) {
        guard loaded != pullRequests else { return }
        pullRequests = loaded
        onChange?()
    }

    // MARK: - Actions

    /// `gh pr checkout <number>`.
    func checkout(_ number: Int) async throws {
        try await gitHub.checkout(number, in: root)
    }

    /// `gh pr create` with `draft`'s values, returning the new pull request's URL.
    func create(_ draft: GitPullRequestDraft) async throws -> URL {
        try await gitHub.create(title: draft.title, body: draft.body, base: draft.base, draft: draft.draft, in: root)
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
