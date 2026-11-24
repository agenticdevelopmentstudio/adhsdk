import Foundation

/// What Undo would act on (recipe `foundation/git/git-client`, "Undo state"): the ref
/// whose reflog it reads, that ref's current tip and its newest reflog entries.
///
/// On a branch the ref is the branch itself (`refs/heads/<name>`), so checking out or
/// creating a branch never makes Undo move the new branch onto the old one's tip; only a
/// detached HEAD reads HEAD's reflog.
public struct GitUndoState: Sendable, Equatable {
    /// `refs/heads/<name>`, or `HEAD` when HEAD is detached.
    public let ref: String
    /// The commit `ref` points at; nil on an unborn branch.
    public let tip: String?
    /// `ref`'s reflog, newest first.
    public let entries: [GitReflogEntry]

    public init(ref: String, tip: String?, entries: [GitReflogEntry]) {
        self.ref = ref
        self.tip = tip
        self.entries = entries
    }

    /// The state before anything has loaded: nothing to undo.
    public static let empty = GitUndoState(ref: "HEAD", tip: nil, entries: [])

    /// The newest entry. It is not always what Undo undoes: see `undoneEntry`.
    public var last: GitReflogEntry? { entries.first }

    /// The step Undo takes back: the entry just before `target`, which moved the ref from
    /// the target to the tip. Nil when there is no target, or when the newest entry is
    /// already not the tip (the reflog lags the ref: `update-ref` without a log, or a tool
    /// that writes none), since then no logged step is the one being undone.
    public var undoneEntry: GitReflogEntry? {
        guard let tip, let index = entries.firstIndex(where: { $0.sha != tip }), index > 0 else { return nil }
        return entries[index - 1]
    }

    /// Where Undo moves the ref back to: the first entry whose commit differs from the tip,
    /// so a step that left the tip where it was (`@{1}` equal to `@{0}`) is skipped. Nil
    /// when there is no tip or no such entry.
    public var target: GitReflogEntry? {
        guard let tip else { return nil }
        return entries.first { $0.sha != tip }
    }
}

/// The state Undo decides on at the moment it is pressed, read fresh from git.
public struct GitUndoPreflight: Sendable, Equatable {
    public let state: GitUndoState
    public let operation: GitOperationState
    /// Whether the index or the working tree has any change, untracked files included.
    public let isDirty: Bool
    /// Whether the index differs from HEAD: anything is staged.
    public let hasStagedChanges: Bool
    /// Whether any path is unmerged. A reset rewrites the index and would drop the
    /// unmerged stages, so Undo has no target while there are any.
    public let hasConflicts: Bool

    public init(state: GitUndoState, operation: GitOperationState, isDirty: Bool,
                hasStagedChanges: Bool = false, hasConflicts: Bool = false) {
        self.state = state
        self.operation = operation
        self.isDirty = isDirty || hasStagedChanges
        self.hasStagedChanges = hasStagedChanges
        self.hasConflicts = hasConflicts
    }

    /// How Undo resets: `.soft` while anything is staged, so the index, with what was
    /// staged apart from the working tree, is kept and the undone commit's changes join
    /// it; `.mixed` otherwise, which leaves the undone changes unstaged in the working
    /// copy. A mixed reset over a staged index would replace it with the target's tree
    /// and lose a staged version that differs from the working copy.
    public var resetMode: GitResetMode {
        hasStagedChanges ? .soft : .mixed
    }

    /// `state.target`, or nil while a merge, rebase, cherry-pick or revert is in progress or
    /// any path is unmerged.
    public var target: GitReflogEntry? {
        operation == .none && !hasConflicts ? state.target : nil
    }
}

extension GitClient {

    /// The undo state of the working tree containing `directory`: `symbolic-ref -q HEAD`
    /// names the checked-out branch (exit 1 means detached, so the ref is `HEAD`), the tip
    /// comes from `resolveCommit`, and the entries from `reflog(ref:limit:)`.
    public func undoState(limit: Int = 20, in directory: URL,
                          caller: GitCaller = GitCaller()) async throws -> GitUndoState {
        let ref: String
        do {
            let output = try await run("symbolic-ref", ["-q", "HEAD"], in: directory, caller: caller)
            let name = output.trimmingCharacters(in: .whitespacesAndNewlines)
            ref = name.isEmpty ? "HEAD" : name
        } catch let error as GitClientError {
            guard case .commandFailed(_, 1, _) = error else { throw error }
            ref = "HEAD"
        }
        let tip = try await resolveCommit(ref, in: directory, caller: caller)
        let entries = try await reflog(ref: ref, limit: limit, in: directory, caller: caller)
        return GitUndoState(ref: ref, tip: tip, entries: entries)
    }

    /// `undoState` together with the operation in progress, whether the tree is dirty and
    /// whether anything is staged, for Undo to decide on at the moment it is pressed.
    public func undoPreflight(in directory: URL, caller: GitCaller = GitCaller()) async throws
        -> GitUndoPreflight {
        let state = try await undoState(in: directory, caller: caller)
        let operation = try await operationState(in: directory, caller: caller)
        let changes = try await status(in: directory, caller: caller)
        let hasStaged = !changes.stagedFiles.isEmpty
        return GitUndoPreflight(state: state, operation: operation,
                                isDirty: hasStaged || !changes.unstagedFiles.isEmpty, hasStagedChanges: hasStaged,
                                hasConflicts: !changes.conflicts.isEmpty)
    }
}
