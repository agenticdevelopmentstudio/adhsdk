import Foundation

/// The four operations git can stop in the middle of, each run by the verb of the same name.
public enum GitOperationKind: String, Sendable, Hashable, CaseIterable {
    case merge, rebase, cherryPick, revert

    /// The git subcommand that runs it and takes its steps.
    public var verb: String {
        switch self {
        case .merge: "merge"
        case .rebase: "rebase"
        case .cherryPick: "cherry-pick"
        case .revert: "revert"
        }
    }
}

/// What a stopped operation can be told to do next. A merge has no skip.
public enum GitOperationStep: String, Sendable, Hashable {
    case `continue`, abort, skip

    /// The flag the operation's verb takes for this step.
    public var flag: String { "--\(rawValue)" }
}

/// The operation a working tree is in the middle of, read from the files git keeps for it.
public enum GitOperationState: Sendable, Hashable {
    case none
    /// `head` is `MERGE_HEAD`'s (first) commit.
    case merging(head: String?)
    /// `branch` is the branch being rebased (`refs/heads/` stripped), `onto` the commit it is
    /// replayed onto, `step` of `total` the commit it stopped at, counting from 1.
    case rebasing(branch: String?, onto: String?, step: Int?, total: Int?, interactive: Bool)
    case cherryPicking(commit: String?)
    case reverting(commit: String?)

    public var kind: GitOperationKind? {
        switch self {
        case .none: nil
        case .merging: .merge
        case .rebasing: .rebase
        case .cherryPicking: .cherryPick
        case .reverting: .revert
        }
    }

    /// Whether the operation takes `--skip`: a rebase, cherry-pick or revert does; a merge does not.
    public var allowsSkip: Bool {
        switch self {
        case .rebasing, .cherryPicking, .reverting: true
        case .none, .merging: false
        }
    }

    /// The names `GitClient.operationState` asks `rev-parse --git-path` for, in `Files` order.
    public static let gitPathNames = ["rebase-merge", "rebase-apply", "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD"]

    /// Where git keeps each operation's files for one working tree. A linked worktree keeps
    /// them under the common directory's `worktrees/<name>/`, so they come from
    /// `rev-parse --git-path`, never from joining `.git/` by hand.
    public struct Files: Sendable, Hashable {
        public var rebaseMerge: URL
        public var rebaseApply: URL
        public var mergeHead: URL
        public var cherryPickHead: URL
        public var revertHead: URL

        public init(rebaseMerge: URL, rebaseApply: URL, mergeHead: URL, cherryPickHead: URL, revertHead: URL) {
            self.rebaseMerge = rebaseMerge
            self.rebaseApply = rebaseApply
            self.mergeHead = mergeHead
            self.cherryPickHead = cherryPickHead
            self.revertHead = revertHead
        }

        /// `urls` in `gitPathNames` order; nil unless there is exactly one per name.
        public init?(_ urls: [URL]) {
            guard urls.count == GitOperationState.gitPathNames.count else { return nil }
            self.init(rebaseMerge: urls[0], rebaseApply: urls[1], mergeHead: urls[2], cherryPickHead: urls[3],
                      revertHead: urls[4])
        }
    }

    /// The state `files` describe, the first present winning: `rebase-merge/`, `rebase-apply/`,
    /// `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, else none. A missing, empty or
    /// unreadable file, or a count that is not a number, gives a nil field; nothing throws.
    ///
    /// Since git 2.26 every merge-backend rebase writes `rebase-merge/interactive`, `rebase -i`
    /// or not, and git records nothing else that says which. What differs under default
    /// options is `drop_redundant_commits`: a plain rebase's `--empty=drop` writes it, and
    /// `rebase -i` (which stops on or keeps an emptied commit) does not. So a rebase is
    /// interactive when `interactive` exists and `drop_redundant_commits` does not; a plain
    /// rebase given `--empty=keep` or `--empty=stop` reads as interactive, and
    /// `rebase -i --empty=drop` as not.
    public static func read(_ files: Files) -> GitOperationState {
        if exists(files.rebaseMerge) {
            let directory = files.rebaseMerge
            return .rebasing(
                branch: branchName(text(directory.appendingPathComponent("head-name"))),
                onto: text(directory.appendingPathComponent("onto")),
                step: number(directory.appendingPathComponent("msgnum")),
                total: number(directory.appendingPathComponent("end")),
                interactive: exists(directory.appendingPathComponent("interactive"))
                    && !exists(directory.appendingPathComponent("drop_redundant_commits"))
            )
        }
        if exists(files.rebaseApply) {
            let directory = files.rebaseApply
            return .rebasing(
                branch: branchName(text(directory.appendingPathComponent("head-name"))),
                onto: text(directory.appendingPathComponent("onto")),
                step: number(directory.appendingPathComponent("next")),
                total: number(directory.appendingPathComponent("last")),
                interactive: false
            )
        }
        if exists(files.mergeHead) {
            let first = text(files.mergeHead)?.split(whereSeparator: \.isNewline).first.map(String.init)
            return .merging(head: first)
        }
        if exists(files.cherryPickHead) {
            return .cherryPicking(commit: text(files.cherryPickHead))
        }
        if exists(files.revertHead) {
            return .reverting(commit: text(files.revertHead))
        }
        return .none
    }

    private static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// The file's text trimmed of whitespace, or nil when it is missing, unreadable or blank.
    private static func text(_ url: URL) -> String? {
        guard let data = FileManager.default.contents(atPath: url.path) else { return nil }
        let trimmed = GitOutputDecoding.string(data).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func number(_ url: URL) -> Int? {
        text(url).flatMap { Int($0) }
    }

    private static func branchName(_ headName: String?) -> String? {
        guard let headName else { return nil }
        let prefix = "refs/heads/"
        return headName.hasPrefix(prefix) ? String(headName.dropFirst(prefix.count)) : headName
    }
}
