import Foundation
import AgenticDeveloperHubSDKCore

/// Wires Coding Partner reviews (recipe `workspace/git/git-window`, "Reviews") into the
/// commit detail and keeps them current. The history asks for its own rows; the detail asks
/// for a commit never drawn there without displacing the history's batch. Each change the
/// provider reports marks every review read for reading again and asks for the rows on
/// screen and the commit shown, so a review that finishes while the window is open updates
/// in place. Without a provider nothing is wired. Read-only: the window never writes one.
extension GitWindowSession {
    func configureReviews() {
        guard let provider = model.reviewsProvider else { return }
        detail.reviewLookup = { [weak model] commit in
            guard let model else { return nil }
            if let review = model.review(for: commit.id) { return review }
            model.requestReview(for: commit.id)
            return nil
        }
        let changes = provider.changes()
        reviewChangesTask = Task { [weak self] in
            for await _ in changes {
                guard let self else { return }
                self.reviewsDidChange()
            }
        }
        applyOpenReview()
    }

    /// The provider reported a change: read again what is on screen. Cached reviews stay
    /// shown until their new values land, so nothing blinks out meanwhile.
    func reviewsDidChange() {
        model.invalidateReviews()
        history.requestVisibleReviews()
        if let commit = detail.commit { model.requestReview(for: commit.id) }
    }

    func applyOpenReview() {
        detail.onOpenReview = model.reviewsProvider == nil ? nil : onOpenReview
    }
}
