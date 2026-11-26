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
/// **"Bottleneck" is about accounting, not about serialization.** This actor's
/// only isolated mutable state is `lfsInstalledFor`, a small cache no verb
/// waits on, and every verb suspends at
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
    let configurationProvider: @Sendable () async -> GitClientConfiguration

    /// The git executables `git lfs version` has already answered for. Whether
    /// git-lfs is installed is the machine's, not the repository's, so it is
    /// asked once per executable rather than on every refresh. Only a yes is
    /// kept: git-lfs installed while the app runs is seen on the next look, and
    /// a `git lfs track` that fails drops the yes and asks again, so git-lfs
    /// uninstalled while the app runs is seen too.
    var lfsInstalledFor: Set<String> = []

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
    ///
    /// Read with `-z` (git 2.36+), so a path holding a newline stays one record. A git too
    /// old for `-z` answers with its usage, exit status 129, and the list is read again
    /// without it.
    public func worktrees(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitWorktree] {
        let configuration = await configurationProvider()
        let output: String
        do {
            output = try await execute(verb: "worktree", arguments: ["list", "--porcelain", "-z"],
                                       directory: directory, caller: caller, configuration: configuration)
        } catch GitClientError.commandFailed(_, 129, _) {
            output = try await execute(verb: "worktree", arguments: ["list", "--porcelain"],
                                       directory: directory, caller: caller, configuration: configuration)
        }
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
        return Self.gitPathURL(output.trimmingCharacters(in: .whitespacesAndNewlines), in: directory)
    }

    /// The operation the working tree containing `directory` is in the middle of, read from
    /// the files git keeps for it in that working tree's own git directory (a linked
    /// worktree's are not the main one's). The five locations come from one
    /// `rev-parse --git-path` call naming them all, or one call each when its output does
    /// not split into one line per name; reading them never throws (`GitOperationState.read`).
    public func operationState(in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> GitOperationState {
        let names = GitOperationState.gitPathNames
        let output = try await execute(
            verb: "rev-parse",
            arguments: names.flatMap { ["--git-path", $0] },
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        var lines = output.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        if let files = GitOperationState.Files(lines.map { Self.gitPathURL($0, in: directory) }) {
            return GitOperationState.read(files)
        }
        var urls: [URL] = []
        for name in names {
            urls.append(try await gitPath(name, in: directory, caller: caller))
        }
        return GitOperationState.Files(urls).map(GitOperationState.read) ?? .none
    }

    /// The interactive rebase of the current branch onto `commit`, every commit picked: the
    /// commits `log --reverse --first-parent <onto>..HEAD` lists, oldest first, `onto` resolved
    /// to its full sha. Throws `.invalidArgument` when `commit` does not resolve, when the range
    /// is empty, or when it holds a merge commit: a plan replays a straight line of commits, and
    /// `rebase -i` without `--rebase-merges` would flatten a merge's side into it.
    public func rebasePlan(
        onto commit: String,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> GitRebasePlan {
        guard !commit.isEmpty, !commit.hasPrefix("-") else {
            throw GitClientError.invalidArgument(verb: "rebase", argument: commit)
        }
        guard let onto = try await resolveCommit(commit, in: directory, caller: caller) else {
            throw GitClientError.invalidArgument(verb: "rebase", argument: "“\(commit)” names no commit.")
        }
        let output = try await execute(
            verb: "log",
            arguments: ["--no-color", "--no-show-signature", "--reverse", "--first-parent",
                        "--format=" + GitCommit.logFormat, "--end-of-options", "\(onto)..HEAD"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        let commits = GitCommit.parse(log: output)
        if let merge = commits.first(where: { $0.parents.count > 1 }) {
            throw GitClientError.invalidArgument(
                verb: "rebase",
                argument: "the range holds the merge commit \(merge.id.prefix(10)), which a plan cannot replay."
            )
        }
        guard !commits.isEmpty else {
            throw GitClientError.invalidArgument(
                verb: "rebase", argument: "there are no commits after “\(commit)”."
            )
        }
        return GitRebasePlan(onto: onto, entries: commits.map { GitRebaseEntry(commit: $0.id, subject: $0.subject) })
    }

    /// The full message (`%B`, trailing whitespace and newlines trimmed) of every commit in
    /// `rebasePlan`'s range, `log --first-parent <onto>..HEAD`, by full sha: one `git log`
    /// for the whole range, so a plan's rewords can be prefilled up front. Throws
    /// `.invalidArgument` for an empty `onto` or one that begins with `-`.
    public func commitMessages(
        after onto: String,
        in directory: URL,
        caller: GitCaller = GitCaller()
    ) async throws -> [String: String] {
        guard !onto.isEmpty, !onto.hasPrefix("-") else {
            throw GitClientError.invalidArgument(verb: "log", argument: onto)
        }
        let output = try await execute(
            verb: "log",
            arguments: ["--no-color", "--no-show-signature", "--first-parent", "--format=%H%x1f%B%x1e",
                        "--end-of-options", "\(onto)..HEAD"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return Self.commitMessages(fromLog: output)
    }

    /// Parses `%H%x1f%B%x1e` records into messages by sha, each message's trailing
    /// whitespace trimmed; a record without a separator is dropped.
    static func commitMessages(fromLog output: String) -> [String: String] {
        var messages: [String: String] = [:]
        for raw in output.split(separator: "\u{1E}", omittingEmptySubsequences: true) {
            let record = raw.drop { $0 == "\n" }
            guard let separator = record.firstIndex(of: "\u{1F}") else { continue }
            let sha = String(record[..<separator])
            guard !sha.isEmpty else { continue }
            var message = record[record.index(after: separator)...]
            while let last = message.last, last.isWhitespace { message.removeLast() }
            messages[sha] = String(message)
        }
        return messages
    }

    /// `rev-parse --git-path` answers relative to the directory it ran in unless the path is absolute.
    private static func gitPathURL(_ path: String, in directory: URL) -> URL {
        path.hasPrefix("/") ? URL(fileURLWithPath: path) : directory.appendingPathComponent(path)
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

    /// The absolute git directory of the working tree containing `directory`: `.git` for
    /// the main worktree, `.git/worktrees/<name>` for a linked one.
    ///
    /// Asked on its own, so a path with a newline in it is read whole; only git's trailing
    /// newline is dropped.
    public func gitDirectory(of directory: URL, caller: GitCaller = GitCaller()) async throws -> URL {
        try await absoluteDirectory("--git-dir", of: directory, caller: caller)
    }

    /// The absolute common git directory of the repository containing `directory`, which
    /// every linked worktree shares with the main one (refs, config, objects). The same as
    /// `gitDirectory(of:)` in the main worktree. Only git's trailing newline is dropped.
    public func commonDirectory(of directory: URL, caller: GitCaller = GitCaller()) async throws -> URL {
        try await absoluteDirectory("--git-common-dir", of: directory, caller: caller)
    }

    private func absoluteDirectory(_ option: String, of directory: URL, caller: GitCaller) async throws -> URL {
        var path = try await execute(
            verb: "rev-parse",
            arguments: ["--path-format=absolute", option],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        if path.hasSuffix("\n") { path.removeLast() }
        return URL(fileURLWithPath: path, isDirectory: true)
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

    /// `path`'s history across renames, newest first, each commit with the file's path at
    /// that commit (`--follow --name-status`, paths unquoted by `core.quotePath=false`). An
    /// unborn HEAD is an empty history.
    public func fileHistory(path: String, in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> [GitFileHistoryEntry] {
        var query = GitLogQuery()
        query.path = path
        query.followRenames = true
        query.nameStatus = true
        query.limit = Self.fileHistoryLimit
        let configuration = await configurationProvider()
        do {
            let output = try await execute(verb: "log", arguments: query.arguments(), directory: directory,
                                           caller: caller, configuration: configuration,
                                           configOverrides: Self.pathConfigOverrides)
            return GitFileHistoryEntry.parse(log: output, path: path)
        } catch let error as GitClientError {
            guard case .commandFailed(_, 128, _) = error,
                  try await resolveCommit("HEAD", in: directory, caller: caller) == nil else {
                throw error
            }
            return []
        }
    }

    /// The wall-clock limit of one `signatures(for:in:caller:)` batch: verifying a page of
    /// signatures can take longer than a plain read.
    public static let signatureBudget: TimeInterval = 15

    /// The signature of each of `shas`, keyed by full sha (recipe `foundation/git/git-client`,
    /// "Signatures"): `git log --no-show-signature --no-walk=unsorted --ignore-missing
    /// --format=GitSignature.format <shas…> --`, bounded by `signatureBudget`. A sha the
    /// repository does not have (a stash dropped elsewhere) is skipped and simply absent
    /// from the answer, so it never fails the rest of the batch. No shas is an empty answer
    /// without running git; anything that is not a hex object name is refused before git
    /// runs, so it can never be read as an option.
    public func signatures(for shas: [String], in directory: URL, caller: GitCaller = GitCaller())
        async throws -> [String: GitSignature] {
        guard !shas.isEmpty else { return [:] }
        if let bad = shas.first(where: { $0.isEmpty || !$0.allSatisfy(\.isHexDigit) }) {
            throw GitClientError.invalidArgument(verb: "log", argument: bad)
        }
        let output = try await execute(
            verb: "log",
            arguments: ["--no-show-signature", "--no-walk=unsorted", "--ignore-missing",
                        "--format=\(GitSignature.format)"] + shas + ["--"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider(),
            budget: Self.signatureBudget
        )
        return GitSignature.parse(log: output)
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

    /// The submodules `git submodule status` reports; none when git has no `.gitmodules`
    /// to read.
    ///
    /// `git submodule status` is a shell script that costs hundreds of
    /// milliseconds, and the model asks on every refresh, so a repository with
    /// no `.gitmodules` anywhere git looks is answered without it: git would
    /// report nothing there, or refuse an orphan gitlink, which the model shows
    /// as no submodules either way. git (2.21+) reads `.gitmodules` from the
    /// working tree, else the index, else HEAD, so all three are looked in: one
    /// `ls-files` of the top-level path (on disk, tracked or not, or in the
    /// index, which a non-cone sparse checkout or an unstaged delete leaves it
    /// in), then a `rev-parse` of `HEAD:.gitmodules` (a staged delete) only when
    /// that finds nothing. A few milliseconds each, and both are git's, under its
    /// timeout: nothing here touches the file system on this actor.
    public func submodules(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [GitSubmodule] {
        guard try await hasGitmodules(directory, caller: caller) else { return [] }
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

    /// Whether git has a top-level `.gitmodules` to read for the repository holding
    /// `directory`: in the working tree, the index, or HEAD.
    private func hasGitmodules(_ directory: URL, caller: GitCaller) async throws -> Bool {
        // No `--exclude-standard`: git reads an ignored `.gitmodules` too.
        let listed = try await run("ls-files", ["-z", "--cached", "--others", "--", ":(top,literal).gitmodules"],
                                   in: directory, caller: caller)
        if !listed.isEmpty { return true }
        do {
            _ = try await run("rev-parse", ["--verify", "--quiet", "HEAD:.gitmodules"], in: directory, caller: caller)
            return true
        } catch GitClientError.commandFailed {
            // Exit 1: HEAD has none, or HEAD is unborn.
            return false
        }
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
            let base = try await diffBase(of: commit, in: directory, caller: caller)
            arguments += ["--end-of-options", base, commit]
            paths = only
        case .range(let from, let until, let only):
            arguments += ["--end-of-options", from, until]
            paths = only
        case .untracked(let path):
            return try await untrackedDiff(path: path, arguments: arguments, directory: directory, caller: caller,
                                           configuration: configuration)
        case .conflicted(let path):
            return try await conflictedDiff(path: path, arguments: arguments, directory: directory, caller: caller,
                                            configuration: configuration)
        }
        if !paths.isEmpty {
            arguments += ["--"] + paths.map { ":(top,literal)\($0)" }
        }
        let output = try await execute(verb: "diff", arguments: arguments, directory: directory, caller: caller,
                                       configuration: configuration, configOverrides: Self.diffConfigOverrides)
        return GitDiff.parse(patch: output)
    }

    /// The files `commit` changed, without the patch: `diff --name-status -z` against the
    /// same base `diff(.commit)` uses (the first parent, or the empty tree for a root
    /// commit), renames found. A commit view lists these and fetches one file's patch at
    /// a time, so a huge commit costs one name per file rather than every line.
    public func changedFiles(commit: String, in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> [GitFileListItem] {
        let base = try await diffBase(of: commit, in: directory, caller: caller)
        let output = try await execute(
            verb: "diff",
            arguments: ["--name-status", "-z", "--no-color", "--no-ext-diff", "--no-relative", "--find-renames",
                        "--end-of-options", base, commit],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider(),
            configOverrides: Self.diffConfigOverrides
        )
        return GitFileListItem.parse(nameStatus: output)
    }

    /// What a commit is diffed against: its first parent, or the empty tree for a root commit.
    private func diffBase(of commit: String, in directory: URL, caller: GitCaller) async throws -> String {
        if let parent = try await resolveCommit("\(commit)^1", in: directory, caller: caller) {
            return parent
        }
        return try await emptyTree(in: directory, caller: caller)
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
                                       configOverrides: Self.pathConfigOverrides)
        return GitBlame.parse(porcelain: output)
    }

    /// The bytes of `path` (top-level-relative), never decoded: at `revision` (`":0"` is the
    /// index entry, `":1"`–`":3"` a conflict's stages), or the working file when `revision`
    /// is nil. A working file must stay inside the top level, every symbolic link resolved,
    /// its folder's and its own: a `../` path, a linked folder or a linked file leading out
    /// throws `invalidArgument`; a link to a file inside is read through. Nil
    /// when the path is not a file there, including on an unborn HEAD, and nil when
    /// `maximumBytes` is given and the file is larger: the size is checked first (the file's
    /// attributes, or `cat-file -s`), so an oversized file is never read at all.
    ///
    /// The path never travels inside a `<rev>:<path>` argument. Foundation's `Process` hands
    /// arguments over decomposed (NFD), and `rev-parse` matches that path byte for byte
    /// against the precomposed (NFC) names git stores, so any non-ASCII name would read as
    /// absent. `ls-tree` and `ls-files` precompose their path arguments, so the blob is
    /// found through them, by a literal pathspec, and its id read with `cat-file`.
    public func fileContents(
        path: String,
        at revision: String?,
        in directory: URL,
        maximumBytes: Int? = nil,
        caller: GitCaller = GitCaller()
    ) async throws -> Data? {
        let top = try await topLevel(of: directory, caller: caller)
        guard let revision else {
            let base = top.resolvingSymlinksInPath().standardizedFileURL
            let named = top.appendingPathComponent(path).standardizedFileURL
            var file = named.deletingLastPathComponent().resolvingSymlinksInPath()
                .appendingPathComponent(named.lastPathComponent)
            // A symbolic link as the file itself is followed to the end, and where it lands
            // must be inside too.
            if (try? FileManager.default.destinationOfSymbolicLink(atPath: file.path)) != nil {
                file = file.resolvingSymlinksInPath()
            }
            guard !path.isEmpty, file.path.hasPrefix(base.path + "/") else {
                throw GitClientError.invalidArgument(verb: "cat-file", argument: path)
            }
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
                  !isDirectory.boolValue else { return nil }
            if let maximumBytes {
                let size = try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int ?? 0
                guard size <= maximumBytes else { return nil }
            }
            return try Data(contentsOf: file)
        }
        let configuration = await configurationProvider()
        let pathspec = ":(literal)" + path
        let listing: String
        let stage: String?
        if revision.count == 2, revision.first == ":", let digit = revision.last, ("0"..."3").contains(digit) {
            stage = String(digit)
            listing = try await execute(verb: "ls-files", arguments: ["--stage", "-z", "--", pathspec],
                                        directory: top, caller: caller, configuration: configuration)
        } else {
            stage = nil
            let tree: String
            do {
                tree = try await execute(
                    verb: "rev-parse",
                    arguments: ["--verify", "--quiet", "--end-of-options", revision + "^{tree}"],
                    directory: top,
                    caller: caller,
                    configuration: configuration
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch GitClientError.commandFailed(_, 1, _) {
                return nil
            }
            guard !tree.isEmpty else { return nil }
            listing = try await execute(verb: "ls-tree", arguments: ["-z", tree, "--", pathspec],
                                        directory: top, caller: caller, configuration: configuration)
        }
        guard let object = Self.blobObject(in: listing, path: path, stage: stage) else { return nil }
        if let maximumBytes {
            let size = try await execute(verb: "cat-file", arguments: ["-s", object], directory: top,
                                         caller: caller, configuration: configuration)
            guard let bytes = Int(size.trimmingCharacters(in: .whitespacesAndNewlines)),
                  bytes <= maximumBytes else { return nil }
        }
        let result = try await executeRaw(verb: "cat-file", arguments: ["blob", object], directory: top,
                                          caller: caller, configuration: configuration)
        return result.standardOutput
    }

    /// The blob id for exactly `path` in `ls-tree -z` output (`<mode> <type> <id>\t<path>`),
    /// or, given a `stage`, in `ls-files --stage -z` output (`<mode> <id> <stage>\t<path>`).
    /// A literal pathspec also lists what is under a directory of that name, so the path must
    /// match whole; Swift's `==` compares canonically, so NFC and NFD spellings are equal.
    static func blobObject(in listing: String, path: String, stage: String?) -> String? {
        for entry in listing.split(separator: "\0") {
            guard let tab = entry.firstIndex(of: "\t"), entry[entry.index(after: tab)...] == path else { continue }
            let fields = entry[..<tab].split(separator: " ")
            if let stage {
                if fields.count == 3, fields[2] == stage { return String(fields[1]) }
            } else if fields.count == 3, fields[1] == "blob" {
                return String(fields[2])
            }
        }
        return nil
    }

    /// The `-c` overrides every diff runs with: unquoted paths, and a blank context line kept
    /// as a space rather than written as an empty line.
    /// The most commits `fileHistory` lists. A history this long may have been cut off,
    /// so a caller that shows it says so in its log.
    public static let fileHistoryLimit = 500

    private static let diffConfigOverrides = ["core.quotePath=false", "diff.suppressBlankEmpty=false"]

    /// The `-c` overrides for a verb handed one path to find: unquoted output paths, and the
    /// path argument precomposed. `Process` passes arguments decomposed (NFD) while git stores
    /// names precomposed (NFC), so a repository without `core.precomposeUnicode` (made on
    /// another system, or with the setting cleared) would find no non-ASCII path at all.
    private static let pathConfigOverrides = ["core.quotePath=false", "core.precomposeUnicode=true"]

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

    /// `diff --base` for one unmerged path (git's "* Unmerged path" notice above the patch
    /// is no part of it), else, when that names no file (there is no base stage), the
    /// working file against `HEAD`, else, when that is empty too (an added-by-us conflict
    /// whose working file is ours), the working file as all added, so the detail is never
    /// blank while there is a file to show. Each file's `oldRevision` names the side used.
    private func conflictedDiff(
        path: String,
        arguments: [String],
        directory: URL,
        caller: GitCaller,
        configuration: GitClientConfiguration
    ) async throws -> GitDiff {
        func marked(_ diff: GitDiff, _ revision: String?) -> GitDiff {
            GitDiff(files: diff.files.map { file in
                var file = file
                file.oldRevision = file.oldPath == nil ? nil : revision
                return file
            })
        }
        let pathspec = ["--", ":(top,literal)\(path)"]
        let base = GitDiff.parse(patch: try await execute(
            verb: "diff", arguments: arguments + ["--base"] + pathspec, directory: directory, caller: caller,
            configuration: configuration, configOverrides: Self.diffConfigOverrides))
        if !base.files.isEmpty { return marked(base, ":1") }
        let head = GitDiff.parse(patch: try await execute(
            verb: "diff", arguments: arguments + ["--end-of-options", "HEAD"] + pathspec, directory: directory,
            caller: caller, configuration: configuration, configOverrides: Self.diffConfigOverrides))
        if !head.files.isEmpty { return marked(head, "HEAD") }
        let top = try await topLevel(of: directory, caller: caller)
        guard FileManager.default.fileExists(atPath: top.appendingPathComponent(path).path) else { return head }
        return try await untrackedDiff(path: path, arguments: arguments, directory: directory, caller: caller,
                                       configuration: configuration)
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

    // MARK: - Write verbs

    /// Merged over the parent's environment for every git child. `GIT_TERMINAL_PROMPT=0`
    /// stops a credential prompt from hanging a child nobody can answer. `LC_MESSAGES=C`
    /// keeps git's messages in English, so a caller that reads one (a branch "not fully
    /// merged") works in any locale. Only messages: `LC_CTYPE` and `LC_ALL` are left
    /// alone, so path encoding is the user's. A parent `LC_ALL` still outranks it.
    /// `GIT_OPTIONAL_LOCKS=0` stops a read (`git status` above all) from taking
    /// `index.lock` for its stat-cache refresh, so a background refresh never makes the
    /// user's own git fail with "index.lock: File exists" (as `ReadOnlyGit` does). Writes
    /// still take their mandatory locks: only the optional refresh is skipped.
    static let baseEnvironment = [
        "GIT_TERMINAL_PROMPT": "0", "LC_MESSAGES": "C", "GIT_OPTIONAL_LOCKS": "0"
    ]

    /// The least time a local write is given: a minute, whatever the (read) timeout says.
    public static let writeBudget: TimeInterval = 60

    /// The least time a long-running write (`GitAction.isLongRunning`) is given: ten minutes.
    public static let longWriteBudget: TimeInterval = 600

    /// `core.editor=true`, so no verb can stop to wait on an editor nobody will see.
    private static let writeConfigOverrides = ["core.editor=true"]

    /// `GIT_EDITOR=true` for every write, over the parent's environment and the configuration's
    /// extra environment: `GIT_EDITOR` outranks `core.editor`, so an app launched from a shell
    /// that sets it would otherwise have `merge --continue` or `rebase --continue` wait on an
    /// editor nobody sees. The message git prepared is kept as it is.
    static let writeEnvironment = ["GIT_EDITOR": "true"]

    /// Runs `action` in `directory` and returns git's standard output.
    ///
    /// Goes through `execute` like every read, so each write is logged, attributed and
    /// bounded; only the budget differs: `max(configuration.timeout, writeBudget)`, or
    /// `longWriteBudget` for a long-running action.
    ///
    /// An action with an operand git would read as an option or as nothing
    /// (`GitAction.invalidOperand`) throws `.invalidArgument` before anything is resolved or
    /// spawned: `createBranch(name: "--delete", startPoint: "main")` would otherwise run
    /// `git branch --delete main`. A path-taking action with no paths
    /// (`GitAction.hasEmptyPathList`) throws `.invalidArgument` too: git reads an empty
    /// pathspec list as the whole tree. So does an apply with an empty patch
    /// (`GitAction.hasEmptyPatch`), and so does a step the operation's verb does not take
    /// (`GitAction.isUnsupportedStep`, a merge's skip), naming that step's flag.
    ///
    /// Every write runs with `writeEnvironment` (`GIT_EDITOR=true`).
    ///
    /// Every perform that runs, whether git succeeds or fails, then removes the interactive
    /// rebase's helper folder (`rebaseHelperName`) if it exists and no operation is in progress,
    /// so a rebase finished or aborted outside the app does not leave it behind. A refused
    /// action spawns nothing, so it does not clean up.
    ///
    /// An action's `standardInput` (an apply's patch) is written to git's standard input;
    /// only the arguments are logged, so a patch never reaches `GitCommandLog`.
    ///
    /// Pass the top level as `directory` for an apply (`applyToIndex`, `applyToWorktree`):
    /// a patch's paths are top-level-relative, and `git apply` run in a subdirectory skips
    /// every path outside it and still exits 0.
    @discardableResult
    public func perform(_ action: GitAction, in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> String {
        if let operand = action.invalidOperand {
            throw GitClientError.invalidArgument(verb: action.verb, argument: operand)
        }
        if action.hasEmptyPathList || action.hasEmptyPatch {
            throw GitClientError.invalidArgument(verb: action.verb, argument: "")
        }
        if action.isUnsupportedStep {
            throw GitClientError.invalidArgument(verb: action.verb, argument: action.arguments.first ?? "")
        }
        if let path = action.relativeWorktreePath {
            throw GitClientError.invalidArgument(verb: action.verb, argument: "“\(path)” is not an absolute path.")
        }
        if case .interactiveRebase(let plan) = action {
            return try await performInteractiveRebase(plan, action: action, in: directory, caller: caller)
        }
        return try await runThenRemoveRebaseHelper(in: directory, caller: caller) {
            try await self.runWrite(action, in: directory, caller: caller)
        }
    }

    /// The name, under the git directory, of the folder an interactive rebase's todo and reword
    /// messages are written to. It sits beside `rebase-merge/`, so it lives as long as the rebase.
    static let rebaseHelperName = "adk-rebase"

    /// Runs one write through `execute`: `core.editor=true`, the write budget, the action's
    /// standard input, and `writeEnvironment` with `extraEnvironment` over it.
    private func runWrite(
        _ action: GitAction,
        in directory: URL,
        caller: GitCaller,
        extraEnvironment: [String: String] = [:]
    ) async throws -> String {
        let configuration = await configurationProvider()
        let floor = action.isLongRunning ? Self.longWriteBudget : Self.writeBudget
        return try await execute(
            verb: action.verb,
            arguments: action.arguments,
            directory: directory,
            caller: caller,
            configuration: configuration,
            configOverrides: Self.writeConfigOverrides,
            budget: max(configuration.timeout, floor),
            standardInput: action.standardInput,
            environment: Self.writeEnvironment.merging(extraEnvironment) { _, new in new }
        )
    }

    /// `rebase -i <onto>` with `plan` as its todo. The plan is checked first (its
    /// `validationError`, a commit that is not a hex sha, an operation already under way), then
    /// the helper folder is replaced by one holding `todo` and `message-<n>` per reword, and
    /// `GIT_SEQUENCE_EDITOR` copies that todo over the one git wrote. The folder is removed as
    /// soon as no operation is left, whether the rebase finished or failed to start; a rebase
    /// that stopped (an edit, a conflict) keeps it for its `exec` lines until it ends.
    private func performInteractiveRebase(
        _ plan: GitRebasePlan,
        action: GitAction,
        in directory: URL,
        caller: GitCaller
    ) async throws -> String {
        if let reason = plan.validationError {
            throw GitClientError.invalidArgument(verb: action.verb, argument: reason)
        }
        if let commit = plan.invalidCommit {
            throw GitClientError.invalidArgument(
                verb: action.verb, argument: "“\(commit)” is not a commit's object name."
            )
        }
        if try await operationState(in: directory, caller: caller) != .none {
            throw GitClientError.invalidArgument(
                verb: action.verb, argument: "another merge, rebase, cherry-pick or revert is in progress."
            )
        }
        let helper = try await gitPath(Self.rebaseHelperName, in: directory, caller: caller)
        let todo = helper.appendingPathComponent("todo")
        let executable = await configurationProvider().executableURL.path
        do {
            try Self.writeRebaseHelper(plan, git: executable, at: helper, todo: todo)
        } catch {
            try? FileManager.default.removeItem(at: helper)
            throw GitClientError.launchFailed(verb: action.verb, reason: error.localizedDescription)
        }
        let editor = ["GIT_SEQUENCE_EDITOR": "cp " + GitRebasePlan.shellQuoted(todo.path)]
        return try await runThenRemoveRebaseHelper(in: directory, caller: caller) {
            try await self.runWrite(action, in: directory, caller: caller, extraEnvironment: editor)
        }
    }

    /// Replaces the folder at `helper` with one holding `plan`'s todo and each reword's message.
    private static func writeRebaseHelper(_ plan: GitRebasePlan, git: String, at helper: URL, todo: URL) throws {
        let files = FileManager.default
        if files.fileExists(atPath: helper.path) { try files.removeItem(at: helper) }
        try files.createDirectory(at: helper, withIntermediateDirectories: true)
        let helperFile = { (name: String) in helper.appendingPathComponent(name).path }
        for (index, message) in plan.rewordMessages.enumerated() {
            try Data(message.utf8).write(to: URL(fileURLWithPath: helperFile(GitRebasePlan.messageFileName(index))))
        }
        try Data(plan.todo(git: git, helperFile: helperFile).utf8).write(to: todo)
    }

    /// Runs `body`, then, whether it returned or threw, removes the helper folder if the
    /// rebase is no longer under way.
    private func runThenRemoveRebaseHelper(
        in directory: URL,
        caller: GitCaller,
        _ body: () async throws -> String
    ) async throws -> String {
        let output: String
        do {
            output = try await body()
        } catch {
            await removeRebaseHelperIfIdle(in: directory, caller: caller)
            throw error
        }
        await removeRebaseHelperIfIdle(in: directory, caller: caller)
        return output
    }

    /// Removes the interactive rebase's helper folder when it exists and no operation is under way.
    func removeRebaseHelperIfIdle(in directory: URL, caller: GitCaller) async {
        guard let helper = try? await gitPath(Self.rebaseHelperName, in: directory, caller: caller),
              FileManager.default.fileExists(atPath: helper.path),
              (try? await operationState(in: directory, caller: caller)) == GitOperationState.none
        else { return }
        try? FileManager.default.removeItem(at: helper)
    }

    /// The repository's remote names that have a URL, sorted (`git remote -v`). A remote
    /// named only by a setting, such as a global `remote.origin.prune`, is listed by a
    /// plain `git remote` in every repository, but there is nothing to push to.
    public func remotes(in directory: URL, caller: GitCaller = GitCaller()) async throws -> [String] {
        let output = try await execute(
            verb: "remote",
            arguments: ["-v"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        return Self.remoteNames(fromVerbose: output)
    }

    /// The names in `git remote -v` output whose URL is not empty, once each, sorted.
    static func remoteNames(fromVerbose output: String) -> [String] {
        var names = Set<String>()
        for line in output.split(separator: "\n") {
            let fields = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard fields.count == 2, !fields[0].isEmpty,
                  !fields[1].trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            names.insert(String(fields[0]))
        }
        return names.sorted()
    }

    /// HEAD's full message (`%B`) with trailing whitespace and newlines trimmed, or nil on an
    /// unborn HEAD — what an amend starts from.
    public func lastCommitMessage(in directory: URL, caller: GitCaller = GitCaller()) async throws -> String? {
        guard let head = try await resolveCommit("HEAD", in: directory, caller: caller) else { return nil }
        let output = try await execute(
            verb: "log",
            arguments: ["-1", "--no-color", "--no-show-signature", "--format=%B", head],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        var message = Substring(output)
        while let last = message.last, last.isWhitespace { message.removeLast() }
        return String(message)
    }

    /// Where `git push` would send local `branch`, as git resolves it: `<branch>@{push}`
    /// (`rev-parse --abbrev-ref --symbolic-full-name`), short, such as `origin/feature`.
    /// It honours `push.default`, `branch.<name>.pushRemote` and `remote.pushDefault`.
    ///
    /// Throws `.commandFailed` with git's message when git cannot name one destination:
    /// no upstream, `simple` with a name unlike the upstream's, a local (`.`) upstream, or
    /// a destination whose remote-tracking branch does not exist yet. A `branch` that is
    /// empty or begins with `-` throws `.invalidArgument` before anything is spawned.
    public func pushDestination(of branch: String, in directory: URL, caller: GitCaller = GitCaller())
        async throws -> String {
        guard !branch.isEmpty, !branch.hasPrefix("-") else {
            throw GitClientError.invalidArgument(verb: "rev-parse", argument: branch)
        }
        let output = try await execute(
            verb: "rev-parse",
            arguments: ["--abbrev-ref", "--symbolic-full-name", "\(branch)@{push}"],
            directory: directory,
            caller: caller,
            configuration: await configurationProvider()
        )
        let destination = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !destination.isEmpty else {
            throw GitClientError.commandFailed(verb: "rev-parse", exitStatus: 0, standardError: "")
        }
        return destination
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
        acceptedExitCodes: Set<Int32> = [0],
        budget: TimeInterval? = nil,
        standardInput: Data? = nil,
        environment: [String: String] = [:]
    ) async throws -> String {
        let result = try await executeRaw(verb: verb, arguments: arguments, directory: directory, caller: caller,
                                          configuration: configuration, configOverrides: configOverrides,
                                          acceptedExitCodes: acceptedExitCodes, budget: budget,
                                          standardInput: standardInput, environment: environment)
        return GitOutputDecoding.string(result.standardOutput)
    }

    /// `execute` before decoding: the raw result, for a verb whose output is bytes
    /// (`cat-file blob`) or whose exit status and standard error are part of its answer.
    /// The record, the failure mapping and the cancellation rule above are this method's.
    ///
    /// `configOverrides` are `key=value` pairs passed as `-c key=value` ahead of the verb and
    /// logged there too, ahead of the verb. An exit status outside `acceptedExitCodes`
    /// throws `.commandFailed`. `budget` replaces `configuration.timeout` as the wall-clock
    /// limit when given; only the write verbs pass one. `standardInput` is written to the
    /// child's standard input and is never recorded: the log is told the arguments only.
    /// `environment` merges last, over `configuration.extraEnvironment`.
    private func executeRaw(
        verb: String,
        arguments verbArguments: [String],
        directory: URL,
        caller: GitCaller,
        configuration: GitClientConfiguration,
        configOverrides: [String] = [],
        acceptedExitCodes: Set<Int32> = [0],
        budget: TimeInterval? = nil,
        standardInput: Data? = nil,
        environment: [String: String] = [:]
    ) async throws -> SubprocessChannel.RunResult {
        let overrides = configOverrides.flatMap { ["-c", $0] }
        let executablePath = configuration.executableURL.path
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            // Recorded even though nothing was spawned. A user who types a
            // wrong path into Settings makes every git call fail here, and an
            // empty log is the least useful thing to hand them.
            GitCommandLog.record(verb: verb, arguments: verbArguments, configOverrides: configOverrides,
                                 directory: directory, caller: caller, duration: 0, exitStatus: nil)
            throw GitClientError.executableNotFound(path: executablePath)
        }
        let channelConfiguration = SubprocessChannel.Configuration(
            executableURL: configuration.executableURL,
            arguments: overrides + [verb] + verbArguments,
            // A non-empty environment is what makes `.mergeOverParent` merge
            // rather than inherit wholesale; git needs PATH and HOME, and
            // `baseEnvironment` says what it adds and why. `extraEnvironment`
            // merges on top so a caller (a test redirecting
            // `GIT_CONFIG_GLOBAL`, say) can add overrides of its own without
            // touching process-wide state — see
            // `GitClientConfiguration.extraEnvironment`. `childEnvironment` also
            // repairs PATH, so git finds git-lfs when launched from Finder.
            environment: Self.childEnvironment(configuration: configuration, environment: environment),
            environmentPolicy: .mergeOverParent,
            currentDirectoryURL: directory
        )
        let started = Date()
        let result: SubprocessChannel.RunResult
        do {
            result = try await SubprocessChannel.run(channelConfiguration, standardInput: standardInput,
                                                     budget: budget ?? configuration.timeout)
        } catch is WallClockBudgetExceeded {
            GitCommandLog.record(
                verb: verb, arguments: verbArguments, configOverrides: configOverrides,
                directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw GitClientError.timedOut(verb: verb)
        } catch let error as CancellationError {
            GitCommandLog.record(
                verb: verb, arguments: verbArguments, configOverrides: configOverrides,
                directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw error
        } catch {
            GitCommandLog.record(
                verb: verb, arguments: verbArguments, configOverrides: configOverrides,
                directory: directory, caller: caller,
                duration: Date().timeIntervalSince(started), exitStatus: nil
            )
            throw GitClientError.launchFailed(verb: verb, reason: error.localizedDescription)
        }
        GitCommandLog.record(
            verb: verb, arguments: verbArguments, configOverrides: configOverrides,
            directory: directory, caller: caller,
            duration: result.duration, exitStatus: result.exitStatus,
            // Kept by the log only for a status other than 0, in memory, never in OSLog.
            standardError: result.standardError
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
