import AgenticDeveloperHubSDKCore

public extension GitRefsDataSource {
    /// No pull requests, for a source that does not load them: the section is absent.
    var pullRequests: [GitPullRequest]? { nil }
    /// No pull request for the checked-out branch.
    var headPullRequest: GitPullRequest? { nil }
}
