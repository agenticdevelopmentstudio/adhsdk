import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `GitHubCLI` against a stub runner: nothing here spawns `gh`, reaches the network
/// or touches a real repository. The JSON fixtures are `gh … --json` output, written
/// by hand in the shape `gh` 2.x prints.
struct GitHubCLITests {

    // MARK: - Harness

    struct Call: Sendable {
        let executable: URL
        let arguments: [String]
        let directory: URL
        let environment: [String: String]
        let budget: Duration
    }

    actor Recorder {
        private(set) var calls: [Call] = []
        func append(_ call: Call) { calls.append(call) }
    }

    enum Reply: Sendable {
        case output(String)
        case failure(status: Int32, standardError: String)
        case thrown(WallClockBudgetExceeded)
    }

    static let ghPath = "/opt/homebrew/bin/gh"
    static let directory = URL(fileURLWithPath: "/tmp/github-cli-tests/repo")

    /// A client whose `gh` is at `ghPath` (when `installed`) and whose runner answers `reply`.
    static func client(_ reply: Reply, installed: Bool = true, recorder: Recorder,
                       book: GitCommandLogBook = GitCommandLogBook(capacity: 16)) -> GitHubCLI {
        let locator = ExecutableLocator(
            environment: ["PATH": "/usr/bin:/bin"],
            isExecutable: { installed && $0 == ghPath })
        let runner: GitHubCLI.Runner = { executable, arguments, directory, environment, budget in
            await recorder.append(Call(executable: executable, arguments: arguments, directory: directory,
                                       environment: environment, budget: budget))
            switch reply {
            case .output(let text):
                return SubprocessChannel.RunResult(standardOutput: Data(text.utf8), standardError: "",
                                                   exitStatus: 0, duration: 0.05)
            case .failure(let status, let standardError):
                return SubprocessChannel.RunResult(standardOutput: Data(), standardError: standardError,
                                                   exitStatus: status, duration: 0.05)
            case .thrown(let error):
                throw error
            }
        }
        return GitHubCLI(locator: locator, runner: runner, commandLog: book)
    }

    static let fields = "number,title,state,isDraft,author,headRefName,baseRefName,url,updatedAt,"
        + "statusCheckRollup,reviewDecision,isCrossRepository"
    static let branchFields = fields + ",headRepositoryOwner"

    /// One `pr list --head main --state all --limit 20` row, in gh's shape.
    static func branchRow(number: Int, state: String, updatedAt: String, crossRepository: Bool,
                          owner: String) -> String {
        """
        {"author": {"login": "\(owner)"}, "baseRefName": "main", "headRefName": "main",
         "headRepositoryOwner": {"id": "MDQ6VXNlcjM=", "login": "\(owner)"},
         "isCrossRepository": \(crossRepository), "isDraft": false, "number": \(number),
         "reviewDecision": "", "state": "\(state)", "statusCheckRollup": [], "title": "PR \(number)",
         "updatedAt": "\(updatedAt)", "url": "https://github.com/o/r/pull/\(number)"}
        """
    }

    /// Three pull requests whose head is called `main`: a stranger's newest one from
    /// their fork, then this repository's own, one merged and one older but open.
    static let sameNameFromAFork = "[" + [
        branchRow(number: 90, state: "OPEN", updatedAt: "2026-11-15T12:00:00Z", crossRepository: true,
                  owner: "stranger"),
        branchRow(number: 80, state: "MERGED", updatedAt: "2026-11-14T12:00:00Z", crossRepository: false,
                  owner: "o"),
        branchRow(number: 70, state: "OPEN", updatedAt: "2026-11-01T12:00:00Z", crossRepository: false,
                  owner: "o")
    ].joined(separator: ",") + "]"

    /// `gh pr list --json <fields>` for two pull requests: one with a mixed check
    /// rollup and an approval, one draft with no checks and no review decision.
    static let twoPullRequests = """
    [
      {
        "author": {"id": "MDQ6VXNlcjE=", "is_bot": false, "login": "octocat", "name": "The Octocat"},
        "baseRefName": "main",
        "headRefName": "feature/login",
        "isDraft": false,
        "number": 42,
        "reviewDecision": "APPROVED",
        "state": "OPEN",
        "statusCheckRollup": [
          {"__typename": "CheckRun", "completedAt": "2026-11-14T09:10:00Z", "conclusion": "SUCCESS",
           "detailsUrl": "https://github.com/o/r/actions/runs/1", "name": "build", "startedAt": "2026-11-14T09:00:00Z",
           "status": "COMPLETED", "workflowName": "CI"},
          {"__typename": "CheckRun", "completedAt": "2026-11-14T09:11:00Z", "conclusion": "FAILURE",
           "detailsUrl": "https://github.com/o/r/actions/runs/2", "name": "lint", "startedAt": "2026-11-14T09:00:00Z",
           "status": "COMPLETED", "workflowName": "CI"},
          {"__typename": "CheckRun", "completedAt": "0001-01-01T00:00:00Z", "conclusion": "",
           "detailsUrl": "https://github.com/o/r/actions/runs/3", "name": "test", "startedAt": "2026-11-14T09:00:00Z",
           "status": "IN_PROGRESS", "workflowName": "CI"},
          {"__typename": "StatusContext", "context": "ci/legacy", "startedAt": "2026-11-14T09:00:00Z",
           "state": "SUCCESS", "targetUrl": "https://ci.example.com/1"},
          {"__typename": "StatusContext", "context": "ci/deploy", "startedAt": "2026-11-14T09:00:00Z",
           "state": "PENDING", "targetUrl": "https://ci.example.com/2"}
        ],
        "title": "Add the login screen",
        "updatedAt": "2026-11-14T09:30:00Z",
        "url": "https://github.com/o/r/pull/42"
      },
      {
        "author": {"id": "MDQ6VXNlcjI=", "is_bot": false, "login": "hubot", "name": ""},
        "baseRefName": "main",
        "headRefName": "wip/refactor",
        "isDraft": true,
        "number": 41,
        "reviewDecision": "",
        "state": "OPEN",
        "statusCheckRollup": [],
        "title": "Refactor the store",
        "updatedAt": "2026-11-13T18:05:12Z",
        "url": "https://github.com/o/r/pull/41"
      }
    ]
    """

    /// `gh pr list --head <branch> --state all --limit 1 --json <fields>` for one merged
    /// pull request.
    static let onePullRequest = """
    [{
      "author": {"login": "octocat"},
      "baseRefName": "main",
      "headRefName": "feature/login",
      "isDraft": false,
      "number": 42,
      "reviewDecision": "CHANGES_REQUESTED",
      "state": "MERGED",
      "statusCheckRollup": [
        {"__typename": "StatusContext", "context": "ci/legacy", "state": "ERROR"}
      ],
      "title": "Add the login screen",
      "updatedAt": "2026-11-14T09:30:00Z",
      "url": "https://github.com/o/r/pull/42"
    }]
    """

    // MARK: - Environment and arguments

    @Test func environmentHoldsTheThreeVariables() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output(#"{"url":"https://github.com/o/r"}"#), recorder: recorder)
        _ = await subject.availability(in: Self.directory)
        let call = try #require(await recorder.calls.first)
        #expect(call.environment["GH_PROMPT_DISABLED"] == "1")
        #expect(call.environment["NO_COLOR"] == "1")
        #expect(call.environment["GH_NO_UPDATE_NOTIFIER"] == "1")
        #expect(call.environment["GH_TOKEN"] == nil)
        #expect(call.executable == URL(fileURLWithPath: Self.ghPath))
        #expect(call.directory == Self.directory)
    }

    @Test func availabilityArgumentsAndAnswer() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output(#"{"url":"https://github.com/o/r"}"#), recorder: recorder)
        let answer = await subject.availability(in: Self.directory)
        #expect(answer == .success(URL(string: "https://github.com/o/r")!))
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == ["repo", "view", "--json", "url"])
        #expect(call.budget == .seconds(10))
    }

    @Test func defaultBranchArgumentsAndAnswer() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output(#"{"defaultBranchRef":{"name":"develop"}}"#), recorder: recorder)
        #expect(try await subject.defaultBranch(in: Self.directory) == "develop")
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == ["repo", "view", "--json", "defaultBranchRef"])
        #expect(call.budget == .seconds(10))
    }

    @Test func emptyDefaultBranchIsFailed() async {
        let recorder = Recorder()
        let subject = Self.client(.output(#"{"defaultBranchRef":{"name":""}}"#), recorder: recorder)
        await #expect(throws: GitHubCLIError.failed("gh reported no default branch")) {
            try await subject.defaultBranch(in: Self.directory)
        }
    }

    @Test func pullRequestsArguments() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output("[]"), recorder: recorder)
        _ = try await subject.pullRequests(in: Self.directory)
        _ = try await subject.pullRequests(in: Self.directory, state: "all", limit: 5)
        let calls = await recorder.calls
        #expect(calls.map(\.arguments) == [
            ["pr", "list", "--state", "open", "--limit", "50", "--json", Self.fields],
            ["pr", "list", "--state", "all", "--limit", "5", "--json", Self.fields]
        ])
        #expect(calls.allSatisfy { $0.budget == .seconds(10) })
    }

    @Test func pullRequestForBranchArguments() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output(Self.onePullRequest), recorder: recorder)
        _ = try await subject.pullRequest(forBranch: "feature/login", in: Self.directory)
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == [
            "pr", "list", "--head", "feature/login", "--state", "all", "--limit", "20", "--json", Self.branchFields
        ])
        #expect(call.budget == .seconds(10))
    }

    /// A branch named like a pull request number is still a branch: `--head` keeps gh
    /// from reading `4521` as pull request #4521, which `gh pr view 4521` would.
    @Test func numericBranchNameIsLookedUpAsAHead() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output("[]"), recorder: recorder)
        let request = try await subject.pullRequest(forBranch: "4521", in: Self.directory)
        #expect(request == nil)
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == [
            "pr", "list", "--head", "4521", "--state", "all", "--limit", "20", "--json", Self.branchFields
        ])
    }

    @Test func checkoutArguments() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output(""), recorder: recorder)
        try await subject.checkout(42, in: Self.directory)
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == ["pr", "checkout", "42"])
        #expect(call.budget == .seconds(60))
    }

    @Test func createArgumentsAndPrintedURL() async throws {
        let recorder = Recorder()
        let printed = "Warning: 1 uncommitted change\nhttps://github.com/o/r/pull/43\n"
        let subject = Self.client(.output(printed), recorder: recorder)
        let plain = try await subject.create(title: "Fix it", body: "Body text", base: nil, draft: false,
                                             in: Self.directory)
        let full = try await subject.create(title: "Fix it", body: "", base: "develop", draft: true,
                                            in: Self.directory)
        #expect(plain == URL(string: "https://github.com/o/r/pull/43")!)
        #expect(full == plain)
        let calls = await recorder.calls
        #expect(calls.map(\.arguments) == [
            ["pr", "create", "--title", "Fix it", "--body", "Body text"],
            ["pr", "create", "--title", "Fix it", "--body", "", "--base", "develop", "--draft"]
        ])
        #expect(calls.allSatisfy { $0.budget == .seconds(60) })
    }

    @Test func createPassesTheHeadBranch() async throws {
        let recorder = Recorder()
        let subject = Self.client(.output("https://github.com/o/r/pull/43\n"), recorder: recorder)
        _ = try await subject.create(title: "Fix it", body: "", base: "main", head: "parser", draft: true,
                                     in: Self.directory)
        let call = try #require(await recorder.calls.first)
        #expect(call.arguments == [
            "pr", "create", "--title", "Fix it", "--body", "", "--base", "main", "--head", "parser", "--draft"
        ])
    }

    @Test(arguments: ["", "-R", "--web"])
    func createRefusesAHeadThatIsNotABranchName(_ head: String) async throws {
        let recorder = Recorder()
        let subject = Self.client(.output("https://github.com/o/r/pull/43\n"), recorder: recorder)
        await #expect(throws: GitHubCLIError.failed("not a branch name: \(head)")) {
            try await subject.create(title: "Fix it", body: "", base: nil, head: head, draft: false,
                                     in: Self.directory)
        }
        #expect(await recorder.calls.isEmpty)
    }

    // MARK: - Decoding

    @Test func decodesARecordedTwoPullRequestList() async throws {
        let subject = Self.client(.output(Self.twoPullRequests), recorder: Recorder())
        let requests = try await subject.pullRequests(in: Self.directory)
        #expect(requests.count == 2)

        let first = requests[0]
        #expect(first.number == 42)
        #expect(first.id == 42)
        #expect(first.title == "Add the login screen")
        #expect(first.state == "OPEN")
        #expect(first.isDraft == false)
        #expect(first.author == "octocat")
        #expect(first.headRefName == "feature/login")
        #expect(first.baseRefName == "main")
        #expect(first.url == URL(string: "https://github.com/o/r/pull/42")!)
        #expect(first.updatedAt == Date(timeIntervalSince1970: 1_794_648_600))
        #expect(first.reviewDecision == "APPROVED")
        #expect(first.checks == GitPullRequestChecks(passing: 2, failing: 1, pending: 2))
        #expect(first.checks?.total == 5)

        let second = requests[1]
        #expect(second.number == 41)
        #expect(second.isDraft)
        #expect(second.author == "hubot")
        #expect(second.checks == nil)
        #expect(second.reviewDecision == nil)
    }

    /// `--head` matches the name in any repository: the fork's pull request is skipped,
    /// and of this repository's two the open one wins over the newer merged one.
    @Test func forkPullRequestWithTheSameBranchNameIsSkipped() async throws {
        let subject = Self.client(.output(Self.sameNameFromAFork), recorder: Recorder())
        let request = try #require(try await subject.pullRequest(forBranch: "main", in: Self.directory))
        #expect(request.number == 70)
    }

    @Test func onlyForkPullRequestsIsNil() async throws {
        let fork = Self.branchRow(number: 90, state: "OPEN", updatedAt: "2026-11-15T12:00:00Z",
                                  crossRepository: true, owner: "stranger")
        let subject = Self.client(.output("[\(fork)]"), recorder: Recorder())
        #expect(try await subject.pullRequest(forBranch: "main", in: Self.directory) == nil)
    }

    @Test func withNoOpenPullRequestTheNewestWins() {
        let rows = [GitPullRequest].self
        let data = Data(("[" + [
            Self.branchRow(number: 5, state: "CLOSED", updatedAt: "2026-11-01T00:00:00Z",
                           crossRepository: false, owner: "o"),
            Self.branchRow(number: 6, state: "MERGED", updatedAt: "2026-11-10T00:00:00Z",
                           crossRepository: false, owner: "o")
        ].joined(separator: ",") + "]").utf8)
        let requests = (try? JSONDecoder().decode(rows, from: data)) ?? []
        #expect(GitHubCLI.preferred(requests)?.number == 6)
    }

    @Test func staleCheckRunIsPending() throws {
        let rollup = """
        [{"__typename": "CheckRun", "status": "COMPLETED", "conclusion": "STALE"},
         {"__typename": "CheckRun", "status": "COMPLETED", "conclusion": "SKIPPED"}]
        """
        let checks = try JSONDecoder().decode([GitHubStatusCheck].self, from: Data(rollup.utf8))
        #expect(GitPullRequestChecks.rollUp(checks) == GitPullRequestChecks(passing: 1, failing: 0, pending: 1))
    }

    @Test func pullRequestForBranchDecodesOne() async throws {
        let subject = Self.client(.output(Self.onePullRequest), recorder: Recorder())
        let request = try #require(try await subject.pullRequest(forBranch: "feature/login", in: Self.directory))
        #expect(request.state == "MERGED")
        #expect(request.reviewDecision == "CHANGES_REQUESTED")
        #expect(request.checks == GitPullRequestChecks(passing: 0, failing: 1, pending: 0))
    }

    @Test func unreadableOutputIsFailed() async {
        let subject = Self.client(.output("not json"), recorder: Recorder())
        let error = await #expect(throws: GitHubCLIError.self) {
            _ = try await subject.pullRequests(in: Self.directory)
        }
        guard case .failed? = error else {
            Issue.record("expected .failed, got \(String(describing: error))")
            return
        }
    }

    // MARK: - Errors

    @Test func notLoggedInIsNotAuthenticated() async {
        let stderr = "To get started with GitHub CLI, please run:  gh auth login\n"
        let subject = Self.client(.failure(status: 4, standardError: stderr), recorder: Recorder())
        #expect(await subject.availability(in: Self.directory) == .failure(.notAuthenticated))
    }

    @Test func notLoggedIntoHostIsNotAuthenticated() async {
        let stderr = "You are NOT LOGGED into any GitHub hosts."
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        await #expect(throws: GitHubCLIError.notAuthenticated) {
            _ = try await subject.pullRequests(in: Self.directory)
        }
    }

    /// gh's whole message, which ends by suggesting `gh auth login`: still not GitHub.
    @Test func noGitHubRemoteIsNotGitHub() async {
        let stderr = "none of the git remotes configured for this repository point to a known GitHub host. "
            + "To tell gh about a new GitHub host, please use `gh auth login`\n"
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        #expect(await subject.availability(in: Self.directory) == .failure(.notGitHub))
    }

    /// A repository with no remote at all, as `gh repo view` answers it.
    @Test func noRemotesIsNotGitHub() async {
        let stderr = "no git remotes found\n"
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        #expect(await subject.availability(in: Self.directory) == .failure(.notGitHub))
    }

    /// Several remotes and no `gh repo set-default`, as the `pr` commands answer it.
    @Test func noDefaultRemoteIsNotGitHub() async {
        let stderr = "No default remote repository has been set. To learn more about the default repository, "
            + "run: gh repo set-default --help\n"
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        await #expect(throws: GitHubCLIError.notGitHub) {
            _ = try await subject.pullRequests(in: Self.directory)
        }
    }

    @Test func notAGitHubRepositoryIsNotGitHub() async {
        let stderr = "error: Not a GitHub repository"
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        await #expect(throws: GitHubCLIError.notGitHub) {
            try await subject.checkout(7, in: Self.directory)
        }
    }

    @Test func budgetExceededIsTimedOut() async {
        let subject = Self.client(.thrown(WallClockBudgetExceeded(seconds: 10)), recorder: Recorder())
        #expect(await subject.availability(in: Self.directory) == .failure(.timedOut))
        await #expect(throws: GitHubCLIError.timedOut) {
            _ = try await subject.create(title: "t", body: "b", base: nil, draft: false, in: Self.directory)
        }
    }

    @Test func anythingElseIsFailedWithStandardError() async {
        let stderr = "HTTP 502: Bad Gateway (https://api.github.com/graphql)\n"
        let subject = Self.client(.failure(status: 1, standardError: stderr), recorder: Recorder())
        await #expect(throws: GitHubCLIError.failed("HTTP 502: Bad Gateway (https://api.github.com/graphql)")) {
            _ = try await subject.pullRequests(in: Self.directory)
        }
    }

    /// `gh pr list --json` answers an empty array, with exit 0, when nothing matches.
    @Test func noPullRequestForBranchIsNil() async throws {
        let subject = Self.client(.output("[]\n"), recorder: Recorder())
        let request = try await subject.pullRequest(forBranch: "feature/none", in: Self.directory)
        #expect(request == nil)
    }

    @Test func missingBinaryIsNotInstalledWithoutSpawning() async {
        let recorder = Recorder()
        let book = GitCommandLogBook(capacity: 4)
        let subject = Self.client(.output("[]"), installed: false, recorder: recorder, book: book)
        #expect(await subject.availability(in: Self.directory) == .failure(.notInstalled))
        await #expect(throws: GitHubCLIError.notInstalled) {
            _ = try await subject.pullRequests(in: Self.directory)
        }
        #expect(await recorder.calls.isEmpty)
        #expect(book.entries().map(\.exitStatus) == [nil, nil])
    }

    // MARK: - Logging

    @Test func entriesAreLoggedWithToolGh() async throws {
        let book = GitCommandLogBook(capacity: 8)
        let subject = Self.client(.output("[]"), recorder: Recorder(), book: book)
        let caller = GitCaller(file: "AgenticDeveloperHubSDKCoreTests/GitHubCLITests.swift",
                               function: "entriesAreLoggedWithToolGh()")
        _ = try await subject.pullRequests(in: Self.directory, limit: 3, caller: caller)
        let entry = try #require(book.entries().last)
        #expect(entry.tool == "gh")
        #expect(entry.arguments == ["pr", "list", "--state", "open", "--limit", "3", "--json", Self.fields])
        #expect(entry.directory == Self.directory.path)
        #expect(entry.exitStatus == 0)
        // An explicit caller, as GitCommandLogTests checks it: a `GitCaller()` default argument
        // expands `#fileID` where the default is written, so it names GitHubCLI.swift, not this file.
        #expect(entry.caller == "AgenticDeveloperHubSDKCoreTests/GitHubCLITests.swift:entriesAreLoggedWithToolGh()")
    }

    @Test func failedEntryKeepsStandardError() async throws {
        let book = GitCommandLogBook(capacity: 8)
        let stderr = "To get started with GitHub CLI, please run:  gh auth login"
        let subject = Self.client(.failure(status: 4, standardError: stderr), recorder: Recorder(), book: book)
        _ = await subject.availability(in: Self.directory)
        let entry = try #require(book.entries().last)
        #expect(entry.tool == "gh")
        #expect(entry.exitStatus == 4)
        #expect(entry.standardError == stderr)
    }

    @Test func createTitleAndBodyAreRedactedInTheLog() async throws {
        let book = GitCommandLogBook(capacity: 8)
        let subject = Self.client(.output("https://github.com/o/r/pull/9\n"), recorder: Recorder(), book: book)
        _ = try await subject.create(title: "Secret title", body: "token abc", base: "main", draft: true,
                                     in: Self.directory)
        let entry = try #require(book.entries().last)
        #expect(entry.arguments == [
            "pr", "create", "--title", "<redacted:12>", "--body", "<redacted:9>", "--base", "main", "--draft"
        ])
    }

    @Test func ghRedactionLeavesGitRulesAlone() {
        #expect(GitCommandLog.redactedArguments(tool: "gh", verb: "pr", arguments: ["view", "-m"])
                == ["view", "-m"])
        #expect(GitCommandLog.redactedArguments(verb: "commit", arguments: ["--title", "x"]) == ["--title", "x"])
    }
}
