import AgenticDeveloperHubSDKCore

/// The history's Coding Partner reviews (recipe `workspace/git/git-views`, "Reviews"), read
/// through `reviewsProvider` with the batch loader the signatures use (ruling R1). Without
/// a provider every call here is a no-op and every review is nil. Never writes a review.
extension GitRepositoryModel {

    /// The review of `sha`, cached; nil when it has none or it has not been read (yet).
    public func review(for sha: String) -> GitCommitReview? {
        reviewLoader?.value(for: sha)
    }

    /// Reads the reviews of `shas` — the rows the history draws — in one coalesced,
    /// debounced batch off the main thread; a newer call replaces a batch still waiting.
    /// `.annotations` is posted when results land.
    public func requestReviews(for shas: [String]) {
        reviewLoader?.request(shas)
    }

    /// Reads one commit's review, for the commit the detail shows, without displacing the
    /// history's queued batch.
    public func requestReview(for sha: String) {
        reviewLoader?.request([sha], replacingQueued: false)
    }

    /// Marks every review read so far for reading again, after the store reports a change.
    /// What is cached stays shown until the next batch replaces or removes it.
    public func invalidateReviews() {
        reviewLoader?.invalidate()
    }
}
