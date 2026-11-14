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
}

/// The commit list, its graph rows, and the query that selects it.
@MainActor public protocol GitHistoryDataSource: AnyObject {
    var commits: [GitCommit] { get }
    var graphRows: [CommitGraphLayout<String>.Row] { get }
    var query: GitLogQuery { get }
    func setQuery(_ query: GitLogQuery) async
    func loadMore() async
    func refs(at commitID: String) -> [GitRef]
}

/// The working copy split into its staged and unstaged columns.
@MainActor public protocol GitWorkingCopyDataSource: AnyObject {
    var staged: [GitFileChange] { get }
    var unstaged: [GitFileChange] { get }
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
