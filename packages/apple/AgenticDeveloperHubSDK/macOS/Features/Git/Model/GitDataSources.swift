import Foundation
import AgenticDeveloperHubSDKCore

/// The repository's refs and the lists beside them — what a sidebar shows.
@MainActor public protocol GitRefsDataSource: AnyObject {
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

/// Content read on demand: diffs, file bytes, blame and a file's history.
@MainActor public protocol GitContentSource: AnyObject {
    func diff(_ target: GitDiffTarget, options: GitDiffOptions) async throws -> GitDiff
    func contents(path: String, at revision: String?) async throws -> Data?
    func blame(path: String, at revision: String?) async throws -> GitBlame
    func fileHistory(path: String) async throws -> [GitCommit]
    func commit(_ id: String) -> GitCommit?
}
