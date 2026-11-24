import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for FSEvents: the model refreshes itself after each action.
private final class PullRequestIdleWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// Answers the new pull request form from a script and records every failure.
@MainActor
private final class PullRequestPresenter: GitActionPresenting {
    struct FormRequest: Equatable {
        let head: String
        let defaultTitle: String
        let defaultBody: String
        let bases: [String]
    }

    var failures: [String] = []
    var forms: [FormRequest] = []
    /// What the form answers; nil (the default) is Cancel.
    var formAnswer: GitPullRequestDraft?
    /// Runs while the form is open, after the request is recorded: what the user does
    /// elsewhere before pressing Create.
    var whileFilling: (() async throws -> Void)?

    func confirm(_ request: GitConfirmation) async -> Bool { false }
    func askForText(_ request: GitTextRequest) async -> [String]? { nil }
    func showFailure(title: String, message: String) { failures.append("\(title): \(message)") }
    func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan? { nil }

    func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                           bases: [String]) async -> GitPullRequestDraft? {
        forms.append(FormRequest(head: head, defaultTitle: defaultTitle, defaultBody: defaultBody, bases: bases))
        try? await whileFilling?()
        return formAnswer
    }
}

/// How the stub's reads fail, from the moment it is set.
private enum GitHubReadFailure: Sendable {
    /// `repo view --json url` and `pr list` run past their budget.
    case timeout
    /// `repo view --json url` and `pr list` answer with gh's login prompt.
    case notAuthenticated
    /// Only the per-branch `pr list --head` runs past its budget.
    case headLookupTimeout
}

/// Every `gh` argument list the stub runner was handed, in order.
private actor GitHubCallRecorder {
    private(set) var calls: [[String]] = []
    private var exists = false
    private(set) var failure: GitHubReadFailure?
    /// From `empty()` on, `pr list` lists nothing: every pull request was merged elsewhere.
    private(set) var isEmptied = false
    func empty() { isEmptied = true }
    func append(_ arguments: [String]) { calls.append(arguments) }
    /// Whether `pr create` has run (or #8 is made to exist), so `pr list` lists it.
    var created: Bool { exists || calls.contains { $0.starts(with: ["pr", "create"]) } }
    /// #8 exists from now on, as if it had been created before the window opened.
    func makeCreated() { exists = true }
    func fail(_ failure: GitHubReadFailure?) { self.failure = failure }
}

/// The Pull Requests section's actions through the session (recipe
/// `workspace/git/git-views`, "Pull requests"), against a real repository and a bare
/// remote in the temp directory, with `gh` replaced by a stub runner: nothing here
/// spawns `gh` or reaches GitHub. The JSON is `gh … --json` output written by hand.
@Suite("GitWindowSession pull requests", .serialized)
@MainActor
struct GitWindowSessionPullRequestTests {
    private static let epoch = 1_767_268_800
    private let client = GitClient(configuration: .default)

    /// `gh pr list --json …` for one open pull request, #7 from `feature`.
    nonisolated static let listJSON = """
        [{"author": {"login": "octocat"}, "baseRefName": "main", "headRefName": "feature",
          "isDraft": false, "number": 7, "reviewDecision": "REVIEW_REQUIRED", "state": "OPEN",
          "statusCheckRollup": [{"__typename": "CheckRun", "status": "COMPLETED", "conclusion": "SUCCESS"}],
          "title": "Add the parser", "updatedAt": "2026-11-14T12:00:00Z",
          "url": "https://github.com/o/r/pull/7"}]
        """

    /// #8 from `parser`, the pull request the stub's `pr create` makes.
    nonisolated static let createdJSON = """
        {"author": {"login": "octocat"}, "baseRefName": "main", "headRefName": "parser",
         "isDraft": true, "number": 8, "reviewDecision": null, "state": "OPEN", "statusCheckRollup": [],
         "title": "Parser", "updatedAt": "2026-11-14T13:00:00Z", "url": "https://github.com/o/r/pull/8",
         "isCrossRepository": false, "headRepositoryOwner": {"login": "o"}}
        """

    /// A fork's open pull request from a branch also called `parser`: the per-branch
    /// lookup drops it, so it never counts as the branch's own.
    nonisolated static let forkJSON = """
        {"author": {"login": "stranger"}, "baseRefName": "main", "headRefName": "parser",
         "isDraft": false, "number": 9, "reviewDecision": null, "state": "OPEN", "statusCheckRollup": [],
         "title": "Their parser", "updatedAt": "2026-11-14T11:00:00Z", "url": "https://github.com/o/r/pull/9",
         "isCrossRepository": true, "headRepositoryOwner": {"login": "stranger"}}
        """

    /// `gh pr list` in the stub: `--head` is the per-branch lookup (the fork's, then ours
    /// once created), otherwise the open list, #8 at the top once created.
    private nonisolated static func listReply(_ arguments: [String], created: Bool) -> String {
        // #7's object, without the list's brackets.
        let row = String(listJSON.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst().dropLast())
        if arguments.contains("--head") {
            return "[" + (created ? [forkJSON, createdJSON] : [forkJSON]).joined(separator: ",") + "]"
        }
        return "[" + (created ? [createdJSON, row] : [row]).joined(separator: ",") + "]"
    }

    /// What `pr checkout` does in the stub.
    enum CheckoutReply: Sendable {
        /// Writes `from-pr.txt` into the repository and succeeds.
        case writeFile
        /// Runs past its budget.
        case timeout
    }

    private static func gitHub(recorder: GitHubCallRecorder, checkout: CheckoutReply = .writeFile) -> GitHubCLI {
        let locator = ExecutableLocator(
            environment: ["PATH": "/opt/homebrew/bin"], extraDirectories: [],
            isExecutable: { $0 == "/opt/homebrew/bin/gh" })
        let runner: GitHubCLI.Runner = { _, arguments, directory, _, _ in
            await recorder.append(arguments)
            let isRead = arguments == ["repo", "view", "--json", "url"] || arguments.starts(with: ["pr", "list"])
            switch await recorder.failure {
            case .timeout? where isRead:
                throw WallClockBudgetExceeded(seconds: 30)
            case .notAuthenticated? where isRead:
                return SubprocessChannel.RunResult(
                    standardOutput: Data(), standardError: "To get started with GitHub CLI, please run:  gh auth login",
                    exitStatus: 4, duration: 0.01)
            case .headLookupTimeout? where arguments.starts(with: ["pr", "list"]) && arguments.contains("--head"):
                throw WallClockBudgetExceeded(seconds: 30)
            default: break
            }
            let output: String
            switch Array(arguments.prefix(2)) {
            case ["repo", "view"] where arguments.contains("defaultBranchRef"):
                output = #"{"defaultBranchRef": {"name": "main"}}"#
            case ["repo", "view"]: output = #"{"url": "https://github.com/o/r"}"#
            case ["pr", "list"] where await recorder.isEmptied: output = "[]"
            case ["pr", "list"]: output = await listReply(arguments, created: recorder.created)
            case ["pr", "checkout"]:
                if case .timeout = checkout { throw WallClockBudgetExceeded(seconds: 30) }
                try Data("from the pull request\n".utf8).write(to: directory.appendingPathComponent("from-pr.txt"))
                output = ""
            case ["pr", "create"]: output = "Creating pull request\nhttps://github.com/o/r/pull/8\n"
            default: output = ""
            }
            return SubprocessChannel.RunResult(standardOutput: Data(output.utf8), standardError: "",
                                               exitStatus: 0, duration: 0.01)
        }
        return GitHubCLI(locator: locator, runner: runner)
    }

    private func commitFile(_ repository: GitTestRepository, _ name: String, at offset: Int) async throws {
        try repository.write("\(name)\n", to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit("\(name) \(offset)", at: Self.epoch + offset)
    }

    /// A bare remote and a clone of it whose `main` is pushed and tracked.
    private func makeRemoteAndClone() async throws -> (GitTestRepository, GitTestRepository) {
        let remote = try await GitTestRepository.makeBare()
        let clone: GitTestRepository
        do {
            clone = try await GitTestRepository.clone(of: remote)
        } catch {
            remote.tearDown()
            throw error
        }
        try await commitFile(clone, "one.txt", at: 100)
        try await clone.run(["push", "--quiet", "-u", "origin", "main"])
        return (remote, clone)
    }

    /// A started session with the Pull Requests section on and its first load finished.
    private func makeSession(_ repository: GitTestRepository, gitHub: GitHubCLI,
                             presenter: PullRequestPresenter) async
        -> (GitRepositoryModel, GitWindowSession, GitPullRequestsModel) {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: PullRequestIdleWatcher())
        await model.start()
        let session = GitWindowSession(model: model, client: client, coloring: nil)
        for pane in [session.overviewPane, session.centre, session.commitPane] as [NSViewController] {
            pane.loadViewIfNeeded()
        }
        session.presenter = presenter
        let list = GitPullRequestsModel(model: model, gitHub: gitHub, client: client)
        session.configurePullRequests(list)
        await list.loadTask?.value
        return (model, session, list)
    }

    private func act(_ session: GitWindowSession, _ intent: GitPullRequestIntent) async {
        session.perform(.pullRequest(intent))
        await session.actionTask?.value
    }

    @Test("checkout runs gh pr checkout 7, then reads the refs and the working copy again")
    func checkoutRunsGhAndRefreshes() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        let (model, session, list) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                       presenter: presenter)
        defer { session.stop() }
        let pullRequest = try #require(list.pullRequests?.first)
        #expect(pullRequest.number == 7)

        await act(session, .checkout(pullRequest))

        #expect(await recorder.calls.contains(["pr", "checkout", "7"]))
        #expect(model.unstaged.contains(GitFileChange(path: "from-pr.txt", status: .untracked)))
        #expect(presenter.failures.isEmpty)
    }

    @Test("create on a branch with no upstream pushes it first, then passes the form's values to gh")
    func createPushesFirst() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        try await commitFile(clone, "two.txt", at: 200)
        try await commitFile(clone, "three.txt", at: 300)
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        presenter.formAnswer = GitPullRequestDraft(title: "Parser", body: "Adds it", base: "main", draft: true)
        let (model, session, _) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                    presenter: presenter)
        defer { session.stop() }
        #expect(model.headBranch?.upstream == nil)

        await act(session, .create)

        #expect(presenter.forms == [PullRequestPresenter.FormRequest(
            head: "parser", defaultTitle: "two.txt 200", defaultBody: "- two.txt 200\n- three.txt 300",
            bases: ["main"])])
        let pushed = try await remote.run(["rev-parse", "--verify", "--quiet", "refs/heads/parser"])
        #expect(!pushed.isEmpty)
        #expect(model.headBranch?.upstream == "origin/parser")
        let creates = await recorder.calls.filter { $0.starts(with: ["pr", "create"]) }
        #expect(creates == [["pr", "create", "--title", "Parser", "--body", "Adds it", "--base", "main",
                             "--draft"]])
        #expect(presenter.failures.isEmpty)
    }

    @Test("after Create the new pull request is listed, the branch's own, and selected")
    func createSelectsTheNewPullRequest() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        try await commitFile(clone, "two.txt", at: 200)
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        presenter.formAnswer = GitPullRequestDraft(title: "Parser", body: "", base: "main", draft: true)
        let (_, session, list) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                   presenter: presenter)
        defer { session.stop() }
        // The fork's #9 from a `parser` of its own is not this branch's pull request.
        #expect(list.headPullRequest == nil)

        await act(session, .create)

        #expect(list.pullRequests?.map(\.number) == [8, 7])
        #expect(list.headPullRequest?.number == 8)
        #expect(session.selection == .pullRequest(8))
        #expect(session.pullRequestView.pullRequest?.number == 8)
        // #8 is from `parser`, the checked-out branch, so there is nothing to check out.
        #expect(!session.pullRequestView.checkoutButton.isEnabled)
        #expect(presenter.failures.isEmpty)
    }

    @Test("a selected pull request that leaves the list empties the detail")
    func selectedPullRequestLeavingTheListEmptiesTheDetail() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        let (_, session, list) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                   presenter: presenter)
        defer { session.stop() }
        let pullRequest = try #require(list.pullRequests?.first)
        session.sidebar(session.sidebar, didRequestPullRequest: .show(pullRequest))
        #expect(session.pullRequestView.pullRequest == pullRequest)
        #expect(session.pullRequestView.checkoutButton.isEnabled)

        await recorder.empty()
        await list.reload()

        #expect(list.pullRequests == [])
        #expect(session.pullRequestView.pullRequest == nil)
        #expect(!session.pullRequestView.checkoutButton.isEnabled)
        #expect(!session.pullRequestView.openButton.isEnabled)
    }

    @Test("create on a branch ahead of its upstream pushes the new commits first")
    func createPushesWhenAhead() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        try await commitFile(clone, "two.txt", at: 200)
        try await clone.run(["push", "--quiet", "-u", "origin", "parser"])
        try await commitFile(clone, "three.txt", at: 300)
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        presenter.formAnswer = GitPullRequestDraft(title: "Parser", body: "", base: "main", draft: false)
        let (model, session, _) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                    presenter: presenter)
        defer { session.stop() }
        #expect(model.headBranch?.ahead == 1)

        await act(session, .create)

        let local = try await clone.run(["rev-parse", "HEAD"])
        let pushed = try await remote.run(["rev-parse", "refs/heads/parser"])
        #expect(pushed == local)
        #expect(model.headBranch?.ahead == 0)
        #expect(await recorder.calls.contains { $0.starts(with: ["pr", "create"]) })
        #expect(presenter.failures.isEmpty)
    }

    @Test("a cancelled form runs nothing: no push and no gh pr create")
    func cancelledFormRunsNothing() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        try await commitFile(clone, "two.txt", at: 200)
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        let (model, session, _) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                    presenter: presenter)
        defer { session.stop() }
        let before = await recorder.calls

        await act(session, .create)

        #expect(presenter.forms.count == 1)
        // Only the default branch was asked for, to fill the form.
        let after = await recorder.calls
        #expect(Array(after.dropFirst(before.count)) == [["repo", "view", "--json", "defaultBranchRef"]])
        #expect(model.headBranch?.upstream == nil)
        let pushed = try? await remote.run(["rev-parse", "--verify", "--quiet", "refs/heads/parser"])
        #expect(pushed == nil)
        #expect(presenter.failures.isEmpty)
    }

    @Test("a checkout that times out shows Pull request failed and leaves the list as it was")
    func timeoutShowsFailure() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        let (_, session, list) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder, checkout: .timeout),
                                                   presenter: presenter)
        defer { session.stop() }
        let before = try #require(list.pullRequests)

        await act(session, .checkout(before[0]))

        #expect(presenter.failures == ["Pull request failed: gh did not answer in time."])
        #expect(list.pullRequests == before)
    }

    @Test("a branch switched while the form is open aborts Create: no push and no gh pr create")
    func branchChangedDuringFormAborts() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        try await commitFile(clone, "two.txt", at: 200)
        let recorder = GitHubCallRecorder()
        let presenter = PullRequestPresenter()
        presenter.formAnswer = GitPullRequestDraft(title: "Parser", body: "", base: "main", draft: false)
        presenter.whileFilling = { _ = try await clone.run(["switch", "--quiet", "-c", "other"]) }
        let (model, session, _) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                    presenter: presenter)
        defer { session.stop() }

        await act(session, .create)

        #expect(presenter.forms.map(\.head) == ["parser"])
        #expect(presenter.failures == ["Pull request failed: \(GitWindowSession.branchChangedMessage)"])
        #expect(!(await recorder.calls.contains { $0.starts(with: ["pr", "create"]) }))
        let pushed = try? await remote.run(["rev-parse", "--verify", "--quiet", "refs/heads/other"])
        #expect(pushed == nil)
        #expect(model.headBranch?.name == "other")
    }

    /// A clone on `parser` whose open pull request #8 exists before the window opens.
    private func makeSessionWithHeadPullRequest(_ recorder: GitHubCallRecorder) async throws
        -> (GitTestRepository, GitTestRepository, GitWindowSession, GitPullRequestsModel) {
        let (remote, clone) = try await makeRemoteAndClone()
        try await clone.run(["switch", "--quiet", "-c", "parser"])
        await recorder.makeCreated()
        let (_, session, list) = await makeSession(clone, gitHub: Self.gitHub(recorder: recorder),
                                                   presenter: PullRequestPresenter())
        return (remote, clone, session, list)
    }

    @Test("a load that times out keeps the section and the head branch's pull request")
    func timedOutLoadKeepsTheSection() async throws {
        let recorder = GitHubCallRecorder()
        let (remote, clone, session, list) = try await makeSessionWithHeadPullRequest(recorder)
        defer { session.stop(); remote.tearDown(); clone.tearDown() }
        #expect(list.pullRequests?.map(\.number) == [8, 7])
        #expect(list.headPullRequest?.number == 8)

        await recorder.fail(.timeout)
        await list.reload()
        #expect(list.pullRequests?.map(\.number) == [8, 7])
        #expect(list.headPullRequest?.number == 8)

        await recorder.fail(.headLookupTimeout)
        await list.reload()
        #expect(list.pullRequests?.map(\.number) == [8, 7])
        #expect(list.headPullRequest?.number == 8)
    }

    @Test("a gh that is not logged in hides the section and the head branch's pull request")
    func notAuthenticatedHidesTheSection() async throws {
        let recorder = GitHubCallRecorder()
        let (remote, clone, session, list) = try await makeSessionWithHeadPullRequest(recorder)
        defer { session.stop(); remote.tearDown(); clone.tearDown() }
        #expect(list.headPullRequest?.number == 8)

        await recorder.fail(.notAuthenticated)
        await list.reload()

        #expect(list.pullRequests == nil)
        #expect(list.headPullRequest == nil)
    }
}
