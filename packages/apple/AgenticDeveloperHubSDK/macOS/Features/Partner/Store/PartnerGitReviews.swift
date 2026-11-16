import Combine
import Foundation
import os
import AgenticDeveloperHubSDKCore

/// The Partner store's reviews as the Git window reads them (recipe
/// `workspace/git/git-views`, "Reviews"): `GitReviewsProviding` over a `PartnerStore`.
/// Read-only: it never writes the store. A read that fails is logged and answers no
/// reviews, so the window shows none rather than an error.
public final class PartnerGitReviews: GitReviewsProviding {
    private let store: PartnerStore

    public init(store: PartnerStore) {
        self.store = store
    }

    public func reviews(repoPath: String, shas: [String]) async -> [String: GitCommitReview] {
        let store = store
        return await Task.detached(priority: .utility) {
            do {
                return try store.reviews(repoPath: repoPath, shas: shas).mapValues(Self.gitReview)
            } catch {
                Self.logger.error("Reading reviews for the Git window failed: \(error.localizedDescription)")
                return [:]
            }
        }.value
    }

    /// A tick on the main queue after each write the store reports as `.reviews`.
    public func changes() -> AsyncStream<Void> {
        let subject = store.changes
        return AsyncStream { continuation in
            let subscription = subject
                .filter { $0 == .reviews }
                .receive(on: DispatchQueue.main)
                .sink { _ in continuation.yield() }
            nonisolated(unsafe) let held = subscription
            continuation.onTermination = { _ in held.cancel() }
        }
    }

    static func gitReview(_ review: PartnerReview) -> GitCommitReview {
        GitCommitReview(sha: review.sha, state: state(review.state), summary: review.summary,
                        skipReason: review.skipReason, reviewID: review.id)
    }

    private static func state(_ state: PartnerReviewState) -> GitCommitReview.State {
        switch state {
        case .queued: return .queued
        case .running: return .running
        case .done: return .done
        case .failed: return .failed
        case .skipped: return .skipped
        }
    }
}

extension PartnerGitReviews: Loggable {
    public static let logger = makeLogger()
}
