import Foundation

/// The toolkit's only door to git.
///
/// Every verb goes through `execute`, which resolves the configuration, spawns
/// the process with `SubprocessChannel.run`, records the invocation in
/// `GitCommandLog`, and maps every failure onto `GitClientError`. Nothing else
/// in the toolkit or in the app may spawn git directly: one door is what makes
/// git usage — by the app and by agents driving it — countable, attributable
/// and bounded by a single timeout.
///
/// **"Bottleneck" is about accounting, not about serialization.** This actor
/// holds no isolated mutable state, and every verb suspends at
/// `await SubprocessChannel.run`, which releases the actor for the whole
/// lifetime of the child. Ten concurrent callers therefore run ten concurrent
/// git processes, not one at a time — intentionally, since a `status` on one
/// repository has no reason to wait behind a `worktree list` on another. If a
/// limit is ever wanted, this is where it goes.
///
/// An actor rather than a struct so the door is a single, identifiable place at
/// runtime as well as in the source, and so later work (rate limiting, caching,
/// an in-memory ring of recent invocations) has somewhere to live that does not
/// change any caller.
public actor GitClient {
    /// The process-wide client; reads its configuration from `UserSettings` on
    /// every call, so a settings change takes effect on the next invocation
    /// without anything having to be rebuilt or re-injected.
    public static let shared = GitClient(configuration: { await GitClientConfiguration.fromSettings() })

    /// Where the `--global` config verbs start the process.
    ///
    /// `git config --global` neither discovers nor reads a repository, so this
    /// is only somewhere for the child to stand; it is never a repository this
    /// client touches. Home is used rather than a scratch path so the call is
    /// legible in the log.
    private static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    /// Resolved on every call rather than captured once, so `shared` follows
    /// the user's settings.
    private let configurationProvider: @Sendable () async -> GitClientConfiguration

    public init(configuration provider: @escaping @Sendable () async -> GitClientConfiguration) {
        self.configurationProvider = provider
    }

    public init(configuration: GitClientConfiguration) {
        self.configurationProvider = { configuration }
    }

    // MARK: - Read-only verbs

    /// The working tree's status, as `git status --porcelain=v1 -z -uall`
    /// reports it. `-z` NUL-delimits each record instead of newline-
    /// terminating it and disables `core.quotePath`'s C-quoting of non-ASCII
    /// paths, so `GitStatus.parse` sees every path exactly as it is on disk.
    /// See `GitStatus.parse` for the record shape this produces.
    public func status(in directory: URL, caller: GitCaller = GitCaller()) async throws -> GitStatus {
        let configuration = await configurationProvider()
        var arguments = ["--porcelain=v1", "-z", "-uall"]
        if configuration.submoduleHandling == .ignore {
            arguments.append("--ignore-submodules")
        }
        let output = try await execute(
            verb: "status",
            arguments: arguments,
            directory: directory,
            caller: caller,
            configuration: configuration
        )
        return GitStatus.parse(porcelain: output)
    }

    /// The short name of HEAD's branch, or `nil` when HEAD is detached.
    public func currentBranch(in directory: URL, caller: GitCaller = GitCaller()) async throws -> String? {
        let output = try await execute(
            verb: "rev-parse",
            arguments: ["--abbrev-ref", "HEAD"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        let name = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty || name == "HEAD" ? nil : name
    }

    /// Every local branch, in `git for-each-ref` order.
    public func branches(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitBranch] {
        let output = try await execute(
            verb: "for-each-ref",
            arguments: ["--format=\(GitBranch.forEachRefFormat)", "refs/heads"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return GitBranch.parse(forEachRef: output)
    }

    /// Every worktree of the repository containing `directory`, main one first.
    public func worktrees(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitWorktree] {
        let output = try await execute(
            verb: "worktree",
            arguments: ["list", "--porcelain"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return GitWorktree.parse(porcelain: output)
    }

    /// The full hash of the commit `ref` names, or `nil` when no such ref exists.
    ///
    /// Pass a fully qualified ref (`refs/heads/main`): an unqualified name that a tag
    /// shares with a branch resolves to the tag. `--end-of-options` keeps a ref that
    /// starts with a dash from being read as a flag, and `^{commit}` peels a tag to
    /// the commit under it. Exit status 1 from `--verify --quiet` is the answer
    /// "no such ref", not a failure; every other failure still throws.
    public func resolveCommit(
        _ ref: String,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> String? {
        do {
            let output = try await execute(
                verb: "rev-parse",
                arguments: ["--verify", "--quiet", "--end-of-options", "\(ref)^{commit}"],
                directory: directory,
                caller: caller,
                configuration: await configurationProvider()
            )
            let hash = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return hash.isEmpty ? nil : hash
        } catch GitClientError.commandFailed(_, 1, _) {
            return nil
        }
    }

    /// Where git keeps `name` inside the repository's git directory (`rebase-merge`, `MERGE_HEAD`, …),
    /// resolved to an absolute URL. The file need not exist: the answer is where it would be.
    public func gitPath(
        _ name: String,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> URL {
        let output = try await execute(
            verb: "rev-parse",
            arguments: ["--git-path", name],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.hasPrefix("/") ? URL(fileURLWithPath: path) : directory.appendingPathComponent(path)
    }

    // MARK: - History, refs, diff, blame and contents

    /// The top level of the working tree containing `directory`.
    ///
    /// Only the trailing newline is dropped: a directory name may itself end in whitespace.
    public func topLevel(of directory: URL, caller: GitCaller = GitCaller()) async throws -> URL {
        var path = try await execute(
            verb: "rev-parse",
            arguments: ["--show-toplevel"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        if path.hasSuffix("\n") { path.removeLast() }
        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }

    /// The commits `query` asks for, newest first in date order.
    ///
    /// An unborn HEAD is an empty history, not an error: `git log` exits 128 naming the
    /// revision `HEAD`, so on that failure — and only when HEAD really does not resolve —
    /// the walk is retried without `HEAD`, or answers empty when nothing else is left to
    /// walk (a follow-mode request always walks from `HEAD`).
    public func log(_ query: GitLogQuery, in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> [GitCommit] {
        let configuration = await configurationProvider()
        do {
            let output = try await execute(verb: "log", arguments: query.arguments(), directory: directory,
                                           caller: caller, configuration: configuration)
            return GitCommit.parse(log: output)
        } catch let error as GitClientError {
            guard case .commandFailed(_, 128, _) = error,
                  try await resolveCommit("HEAD", in: directory, caller: caller) == nil else {
                throw error
            }
            var unborn = query
            unborn.revisions.removeAll { $0 == "HEAD" }
            if (query.path != nil && query.followRenames) || unborn.revisions.isEmpty { return [] }
            let output = try await execute(verb: "log", arguments: unborn.arguments(), directory: directory,
                                           caller: caller, configuration: configuration)
            return GitCommit.parse(log: output)
        }
    }

    /// Every local branch, remote-tracking branch and tag, with each tag peeled to its commit.
    public func refs(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitRef] {
        let output = try await execute(
            verb: "for-each-ref",
            arguments: ["--format=\(GitRef.forEachRefFormat)", "refs/heads", "refs/remotes", "refs/tags"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return GitRef.parse(forEachRef: output)
    }

    /// The stash entries, newest first.
    public func stashes(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitStash] {
        let output = try await execute(
            verb: "stash",
            arguments: ["list", "-z", "--no-show-signature", "--format=\(GitStash.listFormat)"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return GitStash.parse(list: output)
    }

    /// The submodules `git submodule status` reports; none without `.gitmodules`.
    public func submodules(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitSubmodule] {
        let output = try await execute(
            verb: "submodule",
            arguments: ["status"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider(),
            configOverrides: ["core.quotePath=false"]
        )
        return GitSubmodule.parse(status: output)
    }

    /// The patch `target` describes, parsed.
    ///
    /// Every flag a user's configuration could otherwise flip is spelled out — prefixes,
    /// colour, external and textconv drivers, `diff.relative`, path quoting, blank-line
    /// suppression — so `GitDiff.parse` always reads the same shape. Combined (`--cc`) output
    /// is never asked for: a merge and a stash diff against their first parent, and a root
    /// commit against the empty tree. Paths are top-level-relative literal pathspecs.
    public func diff(
        _ target: GitDiffTarget,
        options: GitDiffOptions,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> GitDiff {
        let configuration = await configurationProvider()
        var arguments = ["--no-color", "--no-ext-diff", "--no-textconv", "--no-relative",
                         "--src-prefix=a/", "--dst-prefix=b/", "--find-renames", "-U\(max(0, options.contextLines))"]
        if options.ignoreWhitespace { arguments.append("-w") }
        let paths: [String]
        switch target {
        case .unstaged(let only):
            paths = only
        case .staged(let only):
            arguments.append("--cached")
            paths = only
        case .commit(let commit, let only):
            let base: String
            if let parent = try await resolveCommit("\(commit)^1", in: directory, caller: caller) {
                base = parent
            } else {
                base = try await emptyTree(in: directory, caller: caller)
            }
            arguments += ["--end-of-options", base, commit]
            paths = only
        case .range(let from, let until, let only):
            arguments += ["--end-of-options", from, until]
            paths = only
        case .untracked(let path):
            return try await untrackedDiff(path: path, arguments: arguments, directory: directory, caller: caller,
                                           configuration: configuration)
        }
        if !paths.isEmpty {
            arguments += ["--"] + paths.map { ":(top,literal)\($0)" }
        }
        let output = try await execute(verb: "diff", arguments: arguments, directory: directory, caller: caller,
                                       configuration: configuration, configOverrides: Self.diffConfigOverrides)
        return GitDiff.parse(patch: output)
    }

    /// Who last changed each line of `path` (top-level-relative) at `revision`, or in the
    /// working tree when `revision` is nil.
    ///
    /// `git blame` does not take `--end-of-options` (it reads the next word as the path), so
    /// the revision is first resolved to a commit hash, which can never be read as an option;
    /// a revision that names no commit throws `.commandFailed` with exit status 128, as
    /// blame itself would.
    public func blame(
        path: String,
        at revision: String?,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> GitBlame {
        let top = try await topLevel(of: directory, caller: caller)
        var arguments = ["--porcelain"]
        if let revision {
            guard let commit = try await resolveCommit(revision, in: top, caller: caller) else {
                throw GitClientError.commandFailed(verb: "blame", exitStatus: 128,
                                                   standardError: "fatal: bad revision '\(revision)'\n")
            }
            arguments.append(commit)
        }
        arguments += ["--", path]
        let output = try await execute(verb: "blame", arguments: arguments, directory: top, caller: caller,
                                       configuration: await configurationProvider(),
                                       configOverrides: ["core.quotePath=false"])
        return GitBlame.parse(porcelain: output)
    }

    /// The bytes of `path` (top-level-relative), never decoded: at `revision` (`":0"` is the
    /// index entry), or the working file when `revision` is nil. Nil when the path does not
    /// exist there, including on an unborn HEAD.
    public func fileContents(
        path: String,
        at revision: String?,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> Data? {
        let top = try await topLevel(of: directory, caller: caller)
        guard let revision else {
            let file = top.appendingPathComponent(path)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
                  !isDirectory.boolValue else { return nil }
            return try Data(contentsOf: file)
        }
        let configuration = await configurationProvider()
        let object: String
        do {
            object = try await execute(
                verb: "rev-parse",
                arguments: ["--verify", "--quiet", "--end-of-options", "\(revision):\(path)"],
                directory: top,
                caller: caller,
                configuration: configuration
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch GitClientError.commandFailed(_, 1, _) {
            return nil
        }
        guard !object.isEmpty else { return nil }
        let result = try await executeRaw(verb: "cat-file", arguments: ["blob", object], directory: top,
                                          caller: caller, configuration: configuration)
        return result.standardOutput
    }

    /// The `-c` overrides every diff runs with: unquoted paths, and a blank context line kept
    /// as a space rather than written as an empty line.
    private static let diffConfigOverrides = ["core.quotePath=false", "diff.suppressBlankEmpty=false"]

    /// The empty tree's object name in this repository's hash algorithm.
    private func emptyTree(in directory: URL, caller: GitCaller) async throws -> String {
        try await execute(
            verb: "hash-object",
            arguments: ["-t", "tree", "/dev/null"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// An untracked file as one added file: `diff --no-index -- /dev/null <path>` in the top
    /// level. `--no-index` exits 1 when the two differ, so 1 is success — unless git wrote no
    /// patch at all, which is git failing to read the file.
    private func untrackedDiff(
        path: String,
        arguments: [String],
        directory: URL,
        caller: GitCaller,
        configuration: GitClientConfiguration
    ) async throws -> GitDiff {
        let top = try await topLevel(of: directory, caller: caller)
        let result = try await executeRaw(
            verb: "diff",
            arguments: arguments + ["--no-index", "--", "/dev/null", path],
            directory: top,
            caller: caller,
            configuration: configuration,
            configOverrides: Self.diffConfigOverrides,
            acceptedExitCodes: [0, 1]
        )
        if result.exitStatus == 1 && result.standardOutput.isEmpty {
            throw GitClientError.commandFailed(verb: "diff", exitStatus: 1, standardError: result.standardError)
        }
        return GitDiff.parse(patch: GitOutputDecoding.string(result.standardOutput))
    }

    // MARK: - Verbs no typed method models

    /// Runs `git <verb> <arguments>` in `directory` and returns its standard output.
    ///
    /// The door for verbs that no typed method above models — `log`, `diff`,
    /// `merge-base` and the like — so a caller that needs one still goes through
    /// `execute` and is counted, attributed and bounded like every other
    /// invocation. A non-zero exit throws `GitClientError.commandFailed`, which
    /// carries the exit status for a caller that treats one as an answer
    /// (`merge-base --is-ancestor` exits 1 for "no").
    public func run(
        _ verb: String,
        _ arguments: [String],
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> String {
        try await execute(
            verb: verb,
            arguments: arguments,
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
    }

    // MARK: - Global configuration

    /// Everything in the user's global git configuration.
    public func globalConfig(caller: GitCaller = GitCaller()) async throws -> [GitConfigEntry] {
        let output = try await execute(
            verb: "config",
            arguments: ["--global", "--list", "--null"],
            directory: Self.homeDirectory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return GitConfigEntry.parse(nullSeparated: output)
    }

    /// Sets one key in the user's global git configuration. The value is
    /// redacted in `GitCommandLog`; see `GitCommandLog.redactedArguments`.
    public func setGlobalConfig(key: String, value: String, caller: GitCaller = GitCaller()) async throws {
        _ = try await execute(
            verb: "config",
            arguments: ["--global", key, value],
            directory: Self.homeDirectory,
            caller: caller,
            configuration: await configurationProvider()
        )
    }

    /// Removes one key from the user's global git configuration. Throws
    /// `.commandFailed` (git's exit status 5) when the key was not set.
    public func unsetGlobalConfig(key: String, caller: GitCaller = GitCaller()) async throws {
        _ = try await execute(
            verb: "config",
            arguments: ["--global", "--unset", key],
            directory: Self.homeDirectory,
            caller: caller,
            configuration: await configurationProvider()
        )
    }

    // MARK: - The bottleneck

    /// The single place this framework spawns git.
    ///
    /// Every exit is recorded in `GitCommandLog` before it becomes a return
    /// value or an error, so the log is a complete census of *attempts* rather
    /// than of successes — a missing executable and a cancelled caller each
    /// leave a record, which is the state of affairs someone reading the log is
    /// most likely trying to explain.
    ///
    /// The failure mapping is **total, by construction**: the `do` block ends
    /// in an unqualified `catch`, so no error can leave this method unrecorded
    /// or as a type outside `GitClientError`. Enumerating error types is what
    /// leaves gaps — `SubprocessChannel` can finish its stdout stream with a
    /// raw POSIX `NSError`, and its decoder with a `MessageFramingError`, and
    /// neither is anything a caller of `status(in:)` should have to know about.
    ///
    /// **`CancellationError` is the one exception, and it is deliberate.** It
    /// is recorded and then rethrown *unchanged*, because a cancelled task must
    /// keep seeing cancellation: wrapping it would break `Task.isCancelled`
    /// propagation and structured-concurrency cleanup for every caller,
    /// starting with a SwiftUI `.task` that is torn down while a `status` is in
    /// flight. It is therefore possible for a `GitClient` verb to throw
    /// something that is not a `GitClientError`, and only this.
    private func execute(
        verb: String,
        arguments: [String],
        directory: URL,
        caller: GitCaller,
        configuration: GitClientConfiguration,
        configOverrides: [String] = [],
        acceptedExitCodes: Set<Int32> = [0]
    ) async throws -> String {
        let result = try await executeRaw(verb: verb, arguments: arguments, directory: directory, caller: caller,
                                          configuration: configuration, configOverrides: configOverrides,
                                          acceptedExitCodes: acceptedExitCodes)
        return GitOutputDecoding.string(result.standardOutput)
    }

    /// `execute` before decoding: the raw result, for a verb whose output is bytes
    /// (`cat-file blob`) or whose exit status and standard error are part of its answer.
    /// The record, the failure mapping and the cancellation rule above are this method's.
    ///
    /// `configOverrides` are `key=value` pairs passed as `-c key=value` ahead of the verb and
    /// logged at the front of the arguments. An exit status outside `acceptedExitCodes`
    /// throws `.commandFailed`.
    private func executeRaw(
        verb: String,
        arguments verbArguments: [String],
        directory: URL,
        caller: GitCaller,
        configuration: GitClientConfiguration,
        configOverrides: [String] = [],
        acceptedExitCodes: Set<Int32> = [0]
    ) async throws -> SubprocessChannel.RunResult {
        let overrides = configOverrides.flatMap { ["-c", $0] }
        let arguments = overrides + verbArguments
        let executablePath = configuration.executableURL.path
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            // Recorded even though nothing was spawned. A user who types a
            // wrong path into Settings makes every git call fail here, and an
            // empty log is the least useful thing to hand them.
            GitCommandLog.record(verb: verb, arguments: arguments, directory: directory, caller: caller,
                                 duration: 0, exitStatus: nil)
            throw GitClientError.executableNotFound(path: executablePath)
        }
        let channelConfiguration = SubprocessChannel.Configuration(
            executableURL: configuration.executableURL,
            arguments: overrides + [verb] + verbArguments,
            // A non-empty environment is what makes `.mergeOverParent` merge
            // rather than inherit wholesale; git needs PATH and HOME, and this
            // one override stops a credential prompt from hanging the child
            // forever behind a terminal nobody is watching. `extraEnvironment`
            // merges on top so a caller (a test redirecting
            // `GIT_CONFIG_GLOBAL`, say) can add overrides of its own without
            // touching process-wide state — see
            // `GitClientConfiguration.extraEnvironment`.
            environment: ["GIT_TERMINAL_PROMPT": "0"]
                .merging(configuration.extraEnvironment) { _, override in override },
            environmentPolicy: .mergeOverParent,
            currentDirectoryURL: directory
        )
        let started = Date()
        let result: SubprocessChannel.RunResult
        do {
            result = try await SubprocessChannel.run(channelConfiguration, budget: configuration.timeout)
        } catch is WallClockBudgetExceeded {
            GitCommandLog.record(
                verb: verb, arguments: arguments, directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw GitClientError.timedOut(verb: verb)
        } catch let error as CancellationError {
            GitCommandLog.record(
                verb: verb, arguments: arguments, directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw error
        } catch {
            GitCommandLog.record(
                verb: verb, arguments: arguments, directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw GitClientError.launchFailed(verb: verb, reason: error.localizedDescription)
        }
        GitCommandLog.record(
            verb: verb, arguments: arguments, directory: directory, caller: caller,
            duration: result.duration, exitStatus: result.exitStatus
        )
        guard acceptedExitCodes.contains(result.exitStatus) else {
            throw GitClientError.commandFailed(
                verb: verb,
                exitStatus: result.exitStatus,
                standardError: result.standardError
            )
        }
        return result
    }
}
