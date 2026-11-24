import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The commit detail's "Review" section (recipe `workspace/git/git-views`, "Reviews"),
/// below "Agent Sessions" (ruling R2): a caption, the history's review badge symbol and the
/// review's state, the summary (or why it was skipped) as selectable wrapping text, and an
/// "Open in Coding Partner" button. Hidden while the commit has no review; the button is
/// hidden while `onOpen` is nil. Read-only: nothing here writes a review.
@MainActor
final class GitCommitReviewView: NSStackView {
    let caption = ThemedLabel(string: "Review", role: .secondaryText, textRole: .caption)
    let symbolView = ThemedSymbolImageView(symbolName: nil, role: .secondaryText)
    let stateLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let summaryLabel = ThemedLabel.wrapping("", width: 400, role: .primaryText, textRole: .body)
    let openButton = NSButton()
    /// The review shown; nil while the section is hidden.
    private(set) var review: GitCommitReview?

    /// Opens a review by id in the Coding Partner window; nil hides the button.
    var onOpen: ((String) -> Void)? {
        didSet { openButton.isHidden = onOpen == nil }
    }

    init() {
        super.init(frame: .zero)
        accessibilityID("git.commit.review")
        orientation = .vertical
        alignment = .leading
        spacing = 4
        caption.accessibilityID("git.commit.review.caption")
        symbolView.accessibilityID("git.commit.review.symbol")
        stateLabel.accessibilityID("git.commit.review.state")
        summaryLabel.accessibilityID("git.commit.review.summary")
        summaryLabel.isSelectable = true
        openButton.title = "Open in Coding Partner"
        openButton.bezelStyle = .push
        openButton.controlSize = .small
        openButton.target = self
        openButton.action = #selector(open(_:))
        openButton.accessibilityID("git.commit.review.open")
        openButton.isHidden = true
        let stateRow = NSStackView(views: [symbolView, stateLabel])
        stateRow.orientation = .horizontal
        stateRow.alignment = .centerY
        stateRow.spacing = 6
        stateRow.accessibilityID("git.commit.review.stateRow")
        for view in [caption, stateRow, summaryLabel, openButton] { addArrangedSubview(view) }
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows `review`, or hides the section for nil.
    func show(_ review: GitCommitReview?) {
        guard review != self.review else { return }
        self.review = review
        isHidden = review == nil
        guard let review else { return }
        // The history badge's symbol; a skipped review has no badge, so it gets its own.
        let badge = GitHistoryReviewBadge(review)
        symbolView.symbolName = badge?.symbolName ?? "minus.circle"
        symbolView.role = badge?.role ?? .secondaryText
        stateLabel.stringValue = review.state.title
        let text = (review.state == .skipped ? review.skipReason : review.summary)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        summaryLabel.stringValue = text
        summaryLabel.isHidden = text.isEmpty
        setAccessibilityLabel("Review: \(review.state.title)")
    }

    @objc private func open(_ sender: NSButton) {
        guard let onOpen, let review else { return }
        onOpen(review.reviewID)
    }
}

extension GitCommitDetailViewController {
    /// Reads the shown commit's review again: after `show(commit:)`, and when the owner
    /// hears that reviews landed or changed. Nil from the lookup, or no lookup, hides it.
    public func reloadReview() {
        guard let commit, let reviewLookup else {
            reviewView.show(nil)
            return
        }
        reviewView.show(reviewLookup(commit))
    }
}
