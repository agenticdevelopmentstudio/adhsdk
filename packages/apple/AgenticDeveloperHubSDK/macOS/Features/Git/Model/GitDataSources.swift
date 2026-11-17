import Foundation
import AgenticDeveloperHubSDKCore

/// The repository's refs and the lists beside them — what a sidebar shows.
@MainActor public protocol GitRefsDataSource: AnyObject {
    /// The working tree the lists belong to; submodule paths are relative to it.
    var root: URL { get }
    var refs: [GitRef] { get }
    var stashes: [GitStash] { get }
    var submodules: [GitSubmodule] { get }
    var worktrees: [GitWorktree] { get }
    /// The operation in progress; while there is one, nothing offers to merge or rebase.
    var operationState: GitOperationState { get }
    /// The open pull requests (GitDataSources+PullRequests.swift): nil when `gh` is
    /// unavailable, which leaves the Pull Requests section absent; empty when none is open.
    var pullRequests: [GitPullRequest]? { get }
    /// The checked-out branch's own open pull request, never a fork's; nil when it has
    /// none. It bolds that row and hides the section's Create item.
    var headPullRequest: GitPullRequest? { get }
}

/// The commit list, its graph rows, and the query that selects it.
@MainActor public protocol GitHistoryDataSource: AnyObject {
    var commits: [GitCommit] { get }
    var graphRows: [CommitGraphLayout<String>.Row] { get }
    var query: GitLogQuery { get }
    /// The commit HEAD resolves to; nil on an unborn HEAD.
    var headCommit: String? { get }
    /// The operation in progress; while there is one, nothing offers to start a rebase.
    var operationState: GitOperationState { get }
    func setQuery(_ query: GitLogQuery) async
    func loadMore() async
    func refs(at commitID: String) -> [GitRef]
    /// A commit's signature, cached; nil when it has not been checked yet. Defaults to nil
    /// (GitDataSources+Signatures.swift).
    func signature(for sha: String) -> GitSignature?
    /// Asks for the signatures of the rows on screen: coalesced and debounced, and the
    /// owner hears `.annotations` when results land. Defaults to doing nothing.
    func requestSignatures(for shas: [String])
    /// A commit's Coding Partner review, cached; nil when it has none or it has not been
    /// read yet. Defaults to nil (GitDataSources+Reviews.swift).
    func review(for sha: String) -> GitCommitReview?
    /// Asks for the reviews of the rows on screen, like `requestSignatures(for:)`. Defaults
    /// to doing nothing.
    func requestReviews(for shas: [String])
}

/// The working copy split into its staged and unstaged columns.
@MainActor public protocol GitWorkingCopyDataSource: AnyObject {
    var staged: [GitFileChange] { get }
    var unstaged: [GitFileChange] { get }
    /// The unmerged paths, each with how it is unmerged; each is also in `unstaged`.
    var conflicts: [String: GitConflictKind] { get }
    /// Whether and how the repository uses Git LFS; nil until known. Defaults to nil.
    var lfs: GitLFSState? { get }
}

/// Content read on demand: diffs, a commit's file list, file bytes, blame and a file's history.
@MainActor public protocol GitContentSource: AnyObject {
    func diff(_ target: GitDiffTarget, options: GitDiffOptions) async throws -> GitDiff
    /// The files `commit` changed, without their patch.
    func changedFiles(commit: String) async throws -> [GitFileListItem]
    /// The bytes of `path` at `revision` (nil: the working file); nil when it is not a file
    /// there, or is larger than `maximumBytes`, which is checked before anything is read.
    func contents(path: String, at revision: String?, maximumBytes: Int?) async throws -> Data?
    func blame(path: String, at revision: String?) async throws -> GitBlame
    func fileHistory(path: String) async throws -> [GitFileHistoryEntry]
    func commit(_ id: String) -> GitCommit?
}
