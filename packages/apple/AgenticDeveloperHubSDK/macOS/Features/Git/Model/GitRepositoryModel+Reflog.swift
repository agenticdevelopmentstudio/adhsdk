import AgenticDeveloperHubSDKCore

extension GitRepositoryModel {

    /// Where Undo moves the checked-out branch (or a detached HEAD) back to (recipe
    /// `workspace/git/git-window`, "Undo"): the first entry of that ref's reflog whose
    /// commit differs from its tip, while no merge, rebase, cherry-pick or revert is in
    /// progress; nil otherwise, which disables Undo rather than hiding it.
    public var undoTarget: GitReflogEntry? {
        guard operationState == .none else { return nil }
        return undoState.target
    }

    /// The ref's newest reflog entry: what Undo would undo, whose action and message make
    /// its tooltip.
    public var lastReflogEntry: GitReflogEntry? {
        undoState.last
    }
}
