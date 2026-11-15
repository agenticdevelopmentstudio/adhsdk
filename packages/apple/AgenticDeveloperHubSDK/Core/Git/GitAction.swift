import Foundation

/// How far `git reset` moves: the branch only, the index too, or the working tree as well.
public enum GitResetMode: String, Sendable, Hashable, CaseIterable {
    case soft, mixed, hard
}

/// One write to a repository, as `GitClient.perform` runs it.
///
/// Each case is a fixed git command line: `verb` is the subcommand and `arguments` what
/// follows it, so a caller names an intent and never assembles flags. Every path list is
/// preceded by `--`, so a path that starts with a dash is never read as an option, and every
/// path is written as a `:(top,literal)` pathspec, so `[ab].txt` or `*.log` names that one
/// file rather than every file the glob matches, and is read from the top level, as status
/// reports it. An empty path list is refused (`emptyPathList`): git reads it as everything.
public enum GitAction: Sendable, Hashable {
    case stage(paths: [String])
    case stageAll
    case unstage(paths: [String])
    case unstageAll
    /// Restores tracked files' working-tree contents from the index (`restore --worktree`).
    case discard(paths: [String])
    /// Deletes untracked files and directories (`clean -f -d`).
    case removeUntracked(paths: [String])
    case commit(message: String, amend: Bool)
    /// `nil` fetches every remote.
    case fetch(remote: String?)
    case pull
    case push
    case pushSettingUpstream(remote: String, branch: String)
    /// Pushes local `branch` to `upstreamBranch` on `remote`, leaving its tracking as it is
    /// (`push remote refs/heads/branch:refs/heads/upstreamBranch`), so a branch whose name
    /// differs from its upstream's updates that upstream rather than a new namesake.
    case pushToUpstream(remote: String, branch: String, upstreamBranch: String)
    case createBranch(name: String, startPoint: String?, checkout: Bool)
    case checkout(branch: String)
    /// `origin/x` becomes a local `x` that tracks it.
    case checkoutTracking(remoteBranch: String)
    case checkoutDetached(commit: String)
    // swiftlint:disable:next identifier_name
    case renameBranch(from: String, to: String)
    case deleteBranch(name: String, force: Bool)
    case deleteRemoteBranch(remote: String, name: String)
    /// Lightweight without a message, annotated with one.
    case createTag(name: String, commit: String, message: String?)
    case deleteTag(name: String)
    case pushTag(name: String, remote: String)
    /// Always includes untracked files; an empty message is the same as none.
    case stashSave(message: String?)
    case stashApply(index: Int)
    case stashPop(index: Int)
    case stashDrop(index: Int)
    case cherryPick(commit: String, mainline: Int?)
    case revert(commit: String, mainline: Int?)
    case reset(commit: String, mode: GitResetMode)
    /// Applies `patch` (as `GitPatchBuilder` builds it) to the index only
    /// (`apply --cached`), reversed when `reverse` is set: staging and unstaging lines.
    case applyToIndex(patch: String, reverse: Bool)
    /// Applies `patch` to the working tree only (`apply`), reversed when `reverse` is set:
    /// discarding lines.
    case applyToWorktree(patch: String, reverse: Bool)

    /// The git subcommand.
    public var verb: String {
        switch self {
        case .stage, .stageAll: "add"
        case .unstage, .unstageAll, .reset: "reset"
        case .discard: "restore"
        case .removeUntracked: "clean"
        case .commit: "commit"
        case .fetch: "fetch"
        case .pull: "pull"
        case .push, .pushSettingUpstream, .pushToUpstream, .deleteRemoteBranch, .pushTag: "push"
        case .createBranch(_, _, let checkout): checkout ? "switch" : "branch"
        case .checkout, .checkoutTracking, .checkoutDetached: "switch"
        case .renameBranch, .deleteBranch: "branch"
        case .createTag, .deleteTag: "tag"
        case .stashSave, .stashApply, .stashPop, .stashDrop: "stash"
        case .cherryPick: "cherry-pick"
        case .revert: "revert"
        case .applyToIndex, .applyToWorktree: "apply"
        }
    }

    /// Everything after the verb.
    public var arguments: [String] {
        switch self {
        case .stage(let paths): ["--"] + Self.literal(paths)
        case .stageAll: ["-A"]
        case .unstage(let paths): ["-q", "--"] + Self.literal(paths)
        case .unstageAll: ["-q"]
        case .discard(let paths): ["--worktree", "--"] + Self.literal(paths)
        case .removeUntracked(let paths): ["-f", "-d", "--"] + Self.literal(paths)
        case let .commit(message, amend): ["--cleanup=strip", "-m", message] + (amend ? ["--amend"] : [])
        case .fetch(let remote): remote.map { ["--prune", $0] } ?? ["--all", "--prune"]
        case .pull: ["--no-edit"]
        case .push: []
        case let .pushSettingUpstream(remote, branch): ["--set-upstream", remote, branch]
        case let .pushToUpstream(remote, branch, upstreamBranch):
            [remote, "refs/heads/\(branch):refs/heads/\(upstreamBranch)"]
        case let .createBranch(name, startPoint, checkout):
            (checkout ? ["-c", name] : [name]) + (startPoint.map { [$0] } ?? [])
        case .checkout(let branch): [branch]
        case .checkoutTracking(let remoteBranch): ["--track", remoteBranch]
        case .checkoutDetached(let commit): ["--detach", commit]
        case let .renameBranch(oldName, newName): ["-m", oldName, newName]
        case let .deleteBranch(name, force): [force ? "-D" : "-d", name]
        case let .deleteRemoteBranch(remote, name): [remote, "--delete", name]
        case let .createTag(name, commit, message):
            message.map { ["-a", name, "-m", $0, commit] } ?? [name, commit]
        case .deleteTag(let name): ["-d", name]
        case let .pushTag(name, remote): [remote, "refs/tags/\(name)"]
        case .stashSave(let message):
            ["push", "--include-untracked"] + (message.flatMap { $0.isEmpty ? nil : ["-m", $0] } ?? [])
        case .stashApply(let index): ["apply", "stash@{\(index)}"]
        case .stashPop(let index): ["pop", "stash@{\(index)}"]
        case .stashDrop(let index): ["drop", "stash@{\(index)}"]
        case let .cherryPick(commit, mainline): Self.mainlineArguments(mainline) + [commit]
        case let .revert(commit, mainline): ["--no-edit"] + Self.mainlineArguments(mainline) + [commit]
        case let .reset(commit, mode): ["--\(mode.rawValue)", commit]
        case .applyToIndex(_, let reverse): ["--cached"] + Self.applyArguments(reverse: reverse)
        case .applyToWorktree(_, let reverse): Self.applyArguments(reverse: reverse)
        }
    }

    /// Whether the action can take far longer than a local write: anything that talks to a
    /// remote, and a commit, which runs the repository's hooks.
    public var isLongRunning: Bool {
        switch self {
        case .commit, .fetch, .pull, .push, .pushSettingUpstream, .pushToUpstream, .deleteRemoteBranch,
             .pushTag:
            true
        default: false
        }
    }

    /// The positional ref, branch, tag, remote and commit values the command line carries
    /// where git would read an option: none of them follows `--`, so each must be checked.
    /// Paths (after `--`) and messages (after `-m`) are not operands.
    public var operands: [String] {
        switch self {
        case .stage, .stageAll, .unstage, .unstageAll, .discard, .removeUntracked, .commit, .pull, .push,
             .stashSave, .stashApply, .stashPop, .stashDrop, .applyToIndex, .applyToWorktree:
            []
        case .fetch(let remote): remote.map { [$0] } ?? []
        case let .pushSettingUpstream(remote, branch): [remote, branch]
        case let .pushToUpstream(remote, branch, upstreamBranch): [remote, branch, upstreamBranch]
        case let .createBranch(name, startPoint, _): [name] + (startPoint.map { [$0] } ?? [])
        case .checkout(let branch): [branch]
        case .checkoutTracking(let remoteBranch): [remoteBranch]
        case .checkoutDetached(let commit): [commit]
        case let .renameBranch(oldName, newName): [oldName, newName]
        case .deleteBranch(let name, _): [name]
        case let .deleteRemoteBranch(remote, name): [remote, name]
        case let .createTag(name, commit, _): [name, commit]
        case .deleteTag(let name): [name]
        case let .pushTag(name, remote): [name, remote]
        case .cherryPick(let commit, _), .revert(let commit, _), .reset(let commit, _): [commit]
        }
    }

    /// The first operand git could misread — empty, or starting with `-` (`--delete`, `-f`) —
    /// or nil when every operand is safe. `GitClient.perform` refuses an action that has one.
    public var invalidOperand: String? {
        operands.first { $0.isEmpty || $0.hasPrefix("-") }
    }

    /// Whether the action takes a path list and was given none. `GitClient.perform` refuses
    /// it: `clean -f -d --` with no path deletes every untracked file, `reset -q --` unstages
    /// everything. The `*All` cases are how a caller asks for everything.
    public var hasEmptyPathList: Bool {
        switch self {
        case .stage(let paths), .unstage(let paths), .discard(let paths), .removeUntracked(let paths):
            paths.isEmpty
        default: false
        }
    }

    /// What git reads on standard input: the patch, UTF-8, for the two apply cases; nil
    /// otherwise. It is never part of `arguments`, so it never reaches `GitCommandLog`.
    public var standardInput: Data? {
        switch self {
        case .applyToIndex(let patch, _), .applyToWorktree(let patch, _): Data(patch.utf8)
        default: nil
        }
    }

    /// Whether the action applies a patch and was given an empty one. `GitClient.perform`
    /// refuses it: git reads empty input as "No valid patches in input".
    public var hasEmptyPatch: Bool {
        switch self {
        case .applyToIndex(let patch, _), .applyToWorktree(let patch, _): patch.isEmpty
        default: false
        }
    }

    /// The pathspec prefix every write path carries: top-level-relative, no glob magic.
    public static let literalPathspecPrefix = ":(top,literal)"

    private static func literal(_ paths: [String]) -> [String] {
        paths.map { literalPathspecPrefix + $0 }
    }

    /// `--whitespace=nowarn` so a line with trailing whitespace applies as it is, without a
    /// warning; `-` reads the patch from standard input.
    private static func applyArguments(reverse: Bool) -> [String] {
        ["--whitespace=nowarn"] + (reverse ? ["--reverse"] : []) + ["-"]
    }

    private static func mainlineArguments(_ mainline: Int?) -> [String] {
        mainline.map { ["-m", String($0)] } ?? []
    }
}
