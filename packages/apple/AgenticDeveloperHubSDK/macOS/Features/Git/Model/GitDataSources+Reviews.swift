import AgenticDeveloperHubSDKCore

public extension GitHistoryDataSource {
    /// No reviews, for a source that does not read them.
    func review(for sha: String) -> GitCommitReview? { nil }

    /// Nothing to read, for a source that does not read reviews.
    func requestReviews(for shas: [String]) {}
}
