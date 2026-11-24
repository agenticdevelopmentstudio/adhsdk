import AgenticDeveloperHubSDKCore

/// A history row's Coding Partner review badge (recipe `workspace/git/git-views`,
/// "Reviews"): an SF Symbol for the review's state, with the summary's first line (or the
/// state) as its tooltip and accessibility label. A commit with no review, or a skipped
/// one, has none.
public struct GitHistoryReviewBadge: Equatable, Sendable {
    public let review: GitCommitReview

    /// Nil for a commit with no review (or none read yet) and for a skipped review.
    public init?(_ review: GitCommitReview?) {
        guard let review, review.state != .skipped else { return nil }
        self.review = review
    }

    public var symbolName: String {
        switch review.state {
        case .done: return "text.magnifyingglass"
        case .queued, .running: return "hourglass"
        case .failed: return "xmark.octagon"
        case .skipped: return "minus.circle" // Never shown: a skipped review has no badge.
        }
    }

    /// The accent colour for a finished review, the danger colour for a failed one.
    public var role: ThemeRole {
        switch review.state {
        case .done: return .accent
        case .failed: return .danger
        case .queued, .running, .skipped: return .secondaryText
        }
    }

    /// The tooltip and the accessibility label: the summary's first line, or the state.
    public var text: String { review.summaryFirstLine ?? review.state.title }
}
