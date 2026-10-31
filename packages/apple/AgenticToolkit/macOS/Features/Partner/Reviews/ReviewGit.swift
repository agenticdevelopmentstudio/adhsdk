import Foundation
import AgenticToolkitCore

/// The git verbs the Coding Partner's reviews need, as a thin facade over `GitClient`, the toolkit's only
/// door to git. Failures are `GitClientError`; `.commandFailed` carries git's exit status and stderr.
public struct ReviewGit: Sendable {

    /// The hash of git's empty tree: the "parent" of a root commit, so a diff against it still works.
    public static let emptyTree = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

    /// Review verbs (`log`, `diff`, `worktree add`, `rebase`, `reset`) must never be killed partway, so they get
    /// far longer than the status-poll budget the shared client takes from settings.
    public static let reviewTimeoutSeconds: TimeInterval = 300

    /// The client reviews use: the user's executable path and settings, with a review-sized timeout and
    /// submodules included, so a dirty submodule never reads as a clean worktree.
    public static let reviewClient = GitClient(configuration: {
        var configuration = await GitClientConfiguration.fromSettings()
        configuration.timeout = reviewTimeoutSeconds
        configuration.submoduleHandling = .include
        return configuration
    })

    private let client: GitClient

    public init(client: GitClient = ReviewGit.reviewClient) {
        self.client = client
    }

    /// Runs `git <arguments>` in `directory`; the first argument is the verb.
    public func run(_ arguments: [String], in directory: URL) async throws -> String {
        guard let verb = arguments.first else {
            throw GitClientError.launchFailed(verb: "", reason: "no git verb given")
        }
        return try await client.run(verb, Array(arguments.dropFirst()), in: directory)
    }

    /// The first that is a local branch: the target of `origin/HEAD`, `main`, `master`, the current branch.
    /// Always a local branch, since the crawl and the worktree work on `refs/heads/<name>`: an `origin/HEAD` with
    /// no local branch of its name (a clone of another branch, a stale origin/HEAD) falls through. Throws when
    /// none is, with HEAD detached, rather than following whatever commit HEAD happens to be on.
    public func defaultBranch(in repo: URL) async throws -> String {
        let branches = try await localBranches(in: repo)
        do {
            let origin = try await run(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], in: repo)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if origin.hasPrefix("origin/") {
                let name = String(origin.dropFirst("origin/".count))
                if branches.contains(name) { return name }
            }
        } catch GitClientError.commandFailed {
            // No origin/HEAD: fall through to the local branches. Cancellation and timeouts still propagate.
        }
        for candidate in ["main", "master"] where branches.contains(candidate) { return candidate }
        if let current = try await client.currentBranch(in: repo), branches.contains(current) { return current }
        throw GitClientError.commandFailed(
            verb: "symbolic-ref", exitStatus: 1,
            standardError: "no default branch: origin/HEAD names no local branch, there is no main or master, "
                + "and HEAD is detached")
    }

    /// Whether git accepts `name` as a branch name (`check-ref-format --branch`).
    public func isValidBranchName(_ name: String, in repo: URL) async throws -> Bool {
        guard !name.hasPrefix("-") else { return false }
        do {
            _ = try await run(["check-ref-format", "--branch", name], in: repo)
            return true
        } catch GitClientError.commandFailed {
            return false
        }
    }

    /// The commit a fully qualified ref (`refs/heads/main`) names, or `nil` when it does not exist.
    public func resolveCommit(_ ref: String, in repo: URL) async throws -> String? {
        try await client.resolveCommit(ref, in: repo)
    }

    /// Every worktree of the repository containing `repo`, main checkout first.
    public func worktrees(in repo: URL) async throws -> [GitWorktree] {
        try await client.worktrees(in: repo)
    }

    public func localBranches(in repo: URL) async throws -> [String] {
        try await client.branches(in: repo).map(\.name)
    }

    /// Exit status 1 from `merge-base --is-ancestor` is the answer "no", not a failure.
    public func isAncestor(_ sha: String, of branch: String, in repo: URL) async throws -> Bool {
        do {
            _ = try await run(["merge-base", "--is-ancestor", sha, branch], in: repo)
            return true
        } catch GitClientError.commandFailed(_, 1, _) {
            return false
        }
    }

    /// The first parent of `sha`; the empty tree for a root commit.
    public func parent(of sha: String, in repo: URL) async throws -> String {
        let parents = try await run(["rev-list", "--parents", "-n", "1", sha], in: repo)
            .split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        return parents.count > 1 ? parents[1] : Self.emptyTree
    }

    public func changedFiles(parent: String, sha: String, in repo: URL) async throws -> [String] {
        lines(try await run(["diff", "--name-only", parent, sha], in: repo))
    }

    /// Commits after `sha` on `branch` that touch any of `files`, newest first.
    public func supersedingCommits(after sha: String, on branch: String, files: [String],
                                   in repo: URL) async throws -> [String] {
        guard !files.isEmpty else { return [] }
        return lines(try await run(["log", "--format=%H", "\(sha)..\(branch)", "--"] + files, in: repo))
    }

    /// The diff of `files` from `sha` to the tip of `branch`. One cut at `maxBytes` ends with a line saying
    /// so and naming the command for the rest. The default is small on purpose: the diff rides in the
    /// partner's `partner_review_start` result, which lands in one long-lived conversation and is replaced
    /// wholesale by a pointer to a file once it passes Claude Code's MCP output limit.
    public func tipDiff(from sha: String, to branch: String, files: [String], in repo: URL,
                        maxBytes: Int = 8_000) async throws -> String {
        guard !files.isEmpty else { return "" }
        let diff = try await run(["diff", sha, branch, "--"] + files, in: repo)
        guard diff.utf8.count > maxBytes else { return diff }
        let note = "\n[diff cut at \(maxBytes) bytes of \(diff.utf8.count); run `git diff \(sha) \(branch) --` "
            + "on the reviewed files for the rest]\n"
        // Back off at most three bytes so the cut never lands inside a multi-byte character.
        for cut in stride(from: maxBytes, through: max(0, maxBytes - 3), by: -1) {
            if let text = String(diff.utf8.prefix(cut)) { return text + note }
        }
        return note
    }

    /// Whether `worktree` is in the middle of a rebase (git's `rebase-merge` or `rebase-apply` exists).
    public func isRebasing(worktree: URL) async throws -> Bool {
        for state in ["rebase-merge", "rebase-apply"] {
            let path = try await run(["rev-parse", "--git-path", state], in: worktree)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : worktree.appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: url.path) { return true }
        }
        return false
    }

    /// No modified, staged or untracked files. Submodule changes count only when the client includes
    /// submodules, which `reviewClient` does.
    public func isClean(worktree: URL) async throws -> Bool {
        try await client.status(in: worktree).files.isEmpty
    }

    private func lines(_ output: String) -> [String] {
        output.split(separator: "\n").map(String.init)
    }
}
