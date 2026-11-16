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

    func confirm(_ request: GitConfirmation) async -> Bool { false }
    func askForText(_ request: GitTextRequest) async -> [String]? { nil }
    func showFailure(title: String, message: String) { failures.append("\(title): \(message)") }
    func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan? { nil }

    func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                           bases: [String]) async -> GitPullRequestDraft? {
        forms.append(FormRequest(head: head, defaultTitle: defaultTitle, defaultBody: defaultBody, bases: bases))
        return formAnswer
    }
}

/// Every `gh` argument list the stub runner was handed, in order.
private actor GitHubCallRecorder {
    private(set) var calls: [[String]] = []
    func append(_ arguments: [String]) { calls.append(arguments) }
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
    static let listJSON = """
        [{"author": {"login": "octocat"}, "baseRefName": "main", "headRefName": "feature",
          "isDraft": false, "number": 7, "reviewDecision": "REVIEW_REQUIRED", "state": "OPEN",
          "statusCheckRollup": [{"__typename": "CheckRun", "status": "COMPLETED", "conclusion": "SUCCESS"}],
          "title": "Add the parser", "updatedAt": "2026-11-14T12:00:00Z",
          "url": "https://github.com/o/r/pull/7"}]
        """

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
            let output: String
            switch Array(arguments.prefix(2)) {
            case ["repo", "view"]: output = #"{"url": "https://github.com/o/r"}"#
            case ["pr", "list"]: output = listJSON
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
        #expect(creates == [["pr", "create", "--title", "Parser", "--body", "Adds it", "--base", "main", "--draft"]])
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
        #expect(await recorder.calls == before)
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
}
