import AgenticDeveloperHubSDKCore

public extension GitWorkingCopyDataSource {
    /// No LFS state, for a source that does not load one.
    var lfs: GitLFSState? { nil }
}
