import Foundation

/// Why a `gh` call produced no answer.
public enum GitHubCLIError: Error, Equatable {
    /// No `gh` executable was found. Nothing was spawned.
    case notInstalled
    /// `gh` is installed but not logged in to the repository's host.
    case notAuthenticated
    /// The repository has no GitHub remote.
    case notGitHub
    /// `gh` ran past its budget and was stopped.
    case timedOut
    /// Anything else: `gh`'s standard error, or what went wrong reading its answer.
    case failed(String)
}

/// The GitHub CLI, `gh`, as the Git window uses it: pull requests for the
/// repository a directory belongs to.
///
/// `gh` is the user's own tool, logged in by the user. This client never stores a
/// token, never reads `gh`'s configuration, and never passes `--hostname` or
/// `GH_TOKEN`: whatever `gh` is logged in to is what it asks. It is the only place
/// in the toolkit that spawns `gh`. Every child runs with `GH_PROMPT_DISABLED=1`
/// (a prompt would wait for input nobody can give), `NO_COLOR=1` and
/// `GH_NO_UPDATE_NOTIFIER=1` (neither colour codes nor an update notice belong in
/// output that is parsed), and with `PATH` set to the locator's search
/// directories, so the `git` that `gh` itself runs is found the same way.
///
/// Every call is recorded in `GitCommandLog` with `tool: "gh"`, including one that
/// found no `gh` to run. Reads have a 10-second budget; checkout and create 60.
public actor GitHubCLI {

    public typealias Runner = @Sendable (
        _ executable: URL, _ arguments: [String], _ directory: URL,
        _ environment: [String: String], _ budget: Duration
    ) async throws -> SubprocessChannel.RunResult

    /// The budget of a call that only reads.
    public static let readBudget: Duration = .seconds(10)
    /// The budget of `pr checkout` and `pr create`, which run git and talk to the network.
    public static let writeBudget: Duration = .seconds(60)

    /// The fields every pull request query asks for, in `--json` order.
    public static let pullRequestFields = [
        "number", "title", "state", "isDraft", "author", "headRefName", "baseRefName",
        "url", "updatedAt", "statusCheckRollup", "reviewDecision", "isCrossRepository"
    ]

    /// The variables every `gh` child is given, beside `PATH`.
    public static let fixedEnvironment = [
        "GH_PROMPT_DISABLED": "1",
        "NO_COLOR": "1",
        "GH_NO_UPDATE_NOTIFIER": "1"
    ]

    private let locator: ExecutableLocator
    private let runner: Runner
    private let commandLog: GitCommandLogBook

    /// `runner` nil spawns through `SubprocessChannel.run`; tests pass a stub.
    public init(locator: ExecutableLocator = ExecutableLocator(), runner: Runner? = nil) {
        self.init(locator: locator, runner: runner, commandLog: GitCommandLog.book)
    }

    /// As the public initialiser, recording into `commandLog` instead of the shared ring.
    init(locator: ExecutableLocator, runner: Runner?, commandLog: GitCommandLogBook) {
        self.locator = locator
        self.runner = runner ?? Self.subprocessRunner
        self.commandLog = commandLog
    }

    // MARK: - Verbs

    /// The GitHub repository `directory` belongs to, as `gh repo view --json url`
    /// reports it: the answer to "can pull requests be shown here at all".
    /// A missing `gh` is `.notInstalled`, a `gh` that is not logged in
    /// `.notAuthenticated`, a repository without a GitHub remote `.notGitHub`.
    public func availability(in directory: URL,
                             caller: GitCaller = GitCaller()) async -> Result<URL, GitHubCLIError> {
        do {
            let output = try await run(["repo", "view", "--json", "url"], in: directory,
                                       budget: Self.readBudget, caller: caller)
            struct Repository: Decodable { let url: URL }
            let repository = try decode(Repository.self, from: output)
            return .success(repository.url)
        } catch let error as GitHubCLIError {
            return .failure(error)
        } catch {
            return .failure(.failed(error.localizedDescription))
        }
    }

    /// The repository's default branch, as `gh repo view --json defaultBranchRef` reports
    /// it (`main`, `develop`). An empty name, which `gh` prints for an empty repository,
    /// is `.failed`.
    public func defaultBranch(in directory: URL, caller: GitCaller = GitCaller()) async throws -> String {
        let output = try await run(["repo", "view", "--json", "defaultBranchRef"], in: directory,
                                   budget: Self.readBudget, caller: caller)
        struct Repository: Decodable {
            struct Ref: Decodable { let name: String }
            let defaultBranchRef: Ref?
        }
        let name = try decode(Repository.self, from: output).defaultBranchRef?.name ?? ""
        guard !name.isEmpty else { throw GitHubCLIError.failed("gh reported no default branch") }
        return name
    }

    /// `gh pr list --state <state> --limit <limit> --json …`, newest first as `gh` returns them.
    public func pullRequests(in directory: URL, state: String = "open", limit: Int = 50,
                             caller: GitCaller = GitCaller()) async throws -> [GitPullRequest] {
        let arguments = ["pr", "list", "--state", state, "--limit", String(max(limit, 1)),
                         "--json", Self.pullRequestFields.joined(separator: ",")]
        let output = try await run(arguments, in: directory, budget: Self.readBudget, caller: caller)
        return try decode([GitPullRequest].self, from: output)
    }

    /// How many pull requests with the branch's name `pullRequest(forBranch:)` looks through.
    static let branchCandidateLimit = 20

    /// The branch lookup's fields: every pull request field, and where its head lives.
    static let branchLookupFields = pullRequestFields + ["headRepositoryOwner"]

    /// The pull request whose head is this repository's `branch`, or nil when there is
    /// none: `gh pr list --head <branch> --state all --limit 20 --json …`, then the
    /// open one if there is one, else the most recently updated.
    ///
    /// Not `gh pr view <branch>`, which reads its argument as a number or URL first, so
    /// a branch named `4521` would answer pull request #4521. `--head` matches the head
    /// branch's name in any repository, so pull requests from forks
    /// (`isCrossRepository`) are dropped: a stranger's fork `main` or `patch-1` is not
    /// this branch. That also drops the user's own pull request opened from their fork.
    public func pullRequest(forBranch branch: String, in directory: URL,
                            caller: GitCaller = GitCaller()) async throws -> GitPullRequest? {
        guard !branch.isEmpty, !branch.hasPrefix("-") else {
            throw GitHubCLIError.failed("not a branch name: \(branch)")
        }
        let arguments = ["pr", "list", "--head", branch, "--state", "all",
                         "--limit", String(Self.branchCandidateLimit),
                         "--json", Self.branchLookupFields.joined(separator: ",")]
        let output = try await run(arguments, in: directory, budget: Self.readBudget, caller: caller)
        let candidates = try decode([BranchCandidate].self, from: output)
        return Self.preferred(candidates.filter { !$0.isCrossRepository }.map(\.pullRequest))
    }

    /// The open pull request among `requests`, else the one updated most recently.
    static func preferred(_ requests: [GitPullRequest]) -> GitPullRequest? {
        let open = requests.filter { $0.state.uppercased() == "OPEN" }
        return (open.isEmpty ? requests : open).max { $0.updatedAt < $1.updatedAt }
    }

    /// A `pr list` row with where its head lives, beside the pull request itself.
    struct BranchCandidate: Decodable {
        let pullRequest: GitPullRequest
        let isCrossRepository: Bool

        enum CodingKeys: String, CodingKey { case isCrossRepository }

        init(from decoder: any Decoder) throws {
            pullRequest = try GitPullRequest(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            isCrossRepository = try container.decodeIfPresent(Bool.self, forKey: .isCrossRepository) ?? false
        }
    }

    /// `gh pr checkout <number>`: fetches the pull request's head and switches to it.
    public func checkout(_ number: Int, in directory: URL, caller: GitCaller = GitCaller()) async throws {
        guard number > 0 else { throw GitHubCLIError.failed("not a pull request number: \(number)") }
        _ = try await run(["pr", "checkout", String(number)], in: directory,
                          budget: Self.writeBudget, caller: caller)
    }

    /// `gh pr create --title … --body … [--base …] [--head …] [--draft]`, returning the URL
    /// `gh` prints for the new pull request. `base` nil (or empty) leaves the base to `gh`,
    /// which uses the repository's default branch. `head` names the branch the pull request
    /// is from, so it never follows whatever is checked out when `gh` runs; nil leaves it to
    /// `gh` (the current branch). An empty head, or one starting with `-`, is `.failed` and
    /// nothing runs.
    public func create(title: String, body: String, base: String?, head: String? = nil, draft: Bool,
                       in directory: URL, caller: GitCaller = GitCaller()) async throws -> URL {
        var arguments = ["pr", "create", "--title", title, "--body", body]
        if let base, !base.isEmpty { arguments += ["--base", base] }
        if let head {
            guard !head.isEmpty, !head.hasPrefix("-") else {
                throw GitHubCLIError.failed("not a branch name: \(head)")
            }
            arguments += ["--head", head]
        }
        if draft { arguments.append("--draft") }
        let output = try await run(arguments, in: directory, budget: Self.writeBudget, caller: caller)
        guard let url = Self.lastURL(in: output) else {
            throw GitHubCLIError.failed("gh pr create printed no pull request URL")
        }
        return url
    }

    // MARK: - The one spawn point

    /// Runs `gh <arguments>` in `directory` and returns its standard output, or throws
    /// the mapped `GitHubCLIError`. Records the call in the command log whatever happens.
    private func run(_ arguments: [String], in directory: URL, budget: Duration,
                     caller: GitCaller) async throws -> Data {
        let verb = arguments.first ?? ""
        let verbArguments = Array(arguments.dropFirst())
        guard let executable = locator.find("gh") else {
            record(verb: verb, arguments: verbArguments, directory: directory, caller: caller,
                   duration: 0, exitStatus: nil, standardError: nil)
            throw GitHubCLIError.notInstalled
        }
        var environment = Self.fixedEnvironment
        environment["PATH"] = locator.searchDirectories.joined(separator: ":")
        let started = Date()
        let result: SubprocessChannel.RunResult
        do {
            result = try await runner(executable, arguments, directory, environment, budget)
        } catch is WallClockBudgetExceeded {
            record(verb: verb, arguments: verbArguments, directory: directory, caller: caller,
                   duration: Date().timeIntervalSince(started), exitStatus: nil, standardError: nil)
            throw GitHubCLIError.timedOut
        } catch let error as CancellationError {
            record(verb: verb, arguments: verbArguments, directory: directory, caller: caller,
                   duration: Date().timeIntervalSince(started), exitStatus: nil, standardError: nil)
            throw error
        } catch {
            record(verb: verb, arguments: verbArguments, directory: directory, caller: caller,
                   duration: Date().timeIntervalSince(started), exitStatus: nil, standardError: nil)
            throw GitHubCLIError.failed(error.localizedDescription)
        }
        record(verb: verb, arguments: verbArguments, directory: directory, caller: caller,
               duration: result.duration, exitStatus: result.exitStatus, standardError: result.standardError)
        guard result.exitStatus == 0 else { throw Self.error(forStandardError: result.standardError) }
        return result.standardOutput
    }

    private func record(verb: String, arguments: [String], directory: URL, caller: GitCaller,
                        duration: TimeInterval, exitStatus: Int32?, standardError: String?) {
        GitCommandLog.record(
            in: commandLog, tool: "gh", verb: verb, arguments: arguments, directory: directory,
            caller: caller, duration: duration, exitStatus: exitStatus, standardError: standardError)
    }

    // MARK: - Mapping

    /// Standard error that means the repository has no GitHub to ask: no GitHub remote,
    /// no remote at all, or several remotes and no `gh repo set-default`.
    static let notGitHubMarkers = [
        "none of the git remotes", "not a github", "no git remotes found", "no default remote repository"
    ]

    /// The error a failed `gh` call's standard error names, matched case-insensitively:
    /// a repository without a GitHub remote is `.notGitHub`, a login prompt
    /// `.notAuthenticated`, and anything else `.failed` with the standard error, trimmed.
    /// Not-GitHub is tested first: gh's "none of the git remotes … point to a known
    /// GitHub host" message goes on to suggest `gh auth login`.
    static func error(forStandardError standardError: String) -> GitHubCLIError {
        let text = standardError.lowercased()
        if notGitHubMarkers.contains(where: { text.contains($0) }) { return .notGitHub }
        if text.contains("gh auth login") || text.contains("not logged") { return .notAuthenticated }
        return .failed(standardError.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw GitHubCLIError.failed("unreadable gh output: \(error.localizedDescription)")
        }
    }

    /// The last line of `output` that is an `http` or `https` URL.
    static func lastURL(in output: Data) -> URL? {
        let text = String(data: output, encoding: .utf8) ?? ""
        for line in text.split(whereSeparator: \.isNewline).reversed() {
            let candidate = line.trimmingCharacters(in: .whitespaces)
            if let url = URL(string: candidate), let scheme = url.scheme?.lowercased(),
               scheme == "https" || scheme == "http", url.host != nil {
                return url
            }
        }
        return nil
    }

    // MARK: - The default runner

    /// Spawns through `SubprocessChannel.run`, merging `environment` over the app's own.
    static let subprocessRunner: Runner = { executable, arguments, directory, environment, budget in
        let configuration = SubprocessChannel.Configuration(
            executableURL: executable,
            arguments: arguments,
            environment: environment,
            environmentPolicy: .mergeOverParent,
            currentDirectoryURL: directory)
        return try await SubprocessChannel.run(configuration, budget: GitHubCLI.seconds(of: budget))
    }

    static func seconds(of duration: Duration) -> TimeInterval {
        let parts = duration.components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
