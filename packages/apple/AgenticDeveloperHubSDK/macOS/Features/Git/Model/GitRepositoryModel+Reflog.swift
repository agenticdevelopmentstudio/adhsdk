import AgenticDeveloperHubSDKCore

extension GitRepositoryModel {

    /// Where Undo moves HEAD back to (recipe `workspace/git/git-window`, "Undo"): HEAD@{1}'s
    /// entry when HEAD@{0} exists and no merge, rebase, cherry-pick or revert is in
    /// progress; nil otherwise, which disables Undo rather than hiding it.
    public var undoTarget: GitReflogEntry? {
        guard operationState == .none, headReflog.count >= 2 else { return nil }
        return headReflog[1]
    }

    /// HEAD@{0}: what Undo would undo, whose action and message make its tooltip.
    public var lastReflogEntry: GitReflogEntry? {
        headReflog.first
    }
}
