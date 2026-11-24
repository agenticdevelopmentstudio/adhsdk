import AgenticDeveloperHubSDKCore

extension GitRepositoryModel {

    /// The open pull requests `pullRequestList` last read; nil without one, or while `gh`
    /// is missing, logged out or failing, which leaves the sidebar's section absent.
    public var pullRequests: [GitPullRequest]? {
        pullRequestList?.pullRequests
    }

    /// The checked-out branch's own open pull request, as `pullRequestList` last read it.
    public var headPullRequest: GitPullRequest? {
        pullRequestList?.headPullRequest
    }
}
