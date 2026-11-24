import Foundation

/// A Coding Partner review of one commit, as the Git window shows it beside that commit
/// (recipe `workspace/git/git-views`, "Reviews"). Read-only: the window never writes one.
public struct GitCommitReview: Sendable, Hashable {
    public enum State: String, Sendable {
        case queued, running, done, failed, skipped

        /// The state as a word: "Queued", "Running", "Done", "Failed", "Skipped".
        public var title: String { rawValue.capitalized }
    }

    /// The reviewed commit's full sha.
    public let sha: String
    public let state: State
    /// The reviewer's summary; nil until it has written one.
    public let summary: String?
    /// Why the review was skipped; nil unless `state` is `.skipped`.
    public let skipReason: String?
    /// The review's id in the store it was read from, which the Coding Partner window opens.
    public let reviewID: String

    public init(sha: String, state: State, summary: String? = nil, skipReason: String? = nil, reviewID: String) {
        self.sha = sha
        self.state = state
        self.summary = summary
        self.skipReason = skipReason
        self.reviewID = reviewID
    }

    /// The summary's first line, trimmed; nil when there is no summary or it is blank.
    public var summaryFirstLine: String? {
        guard let summary else { return nil }
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
        guard let line = lines.first else { return nil }
        let text = line.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
}

/// Where the Git window reads Coding Partner reviews from. Read-only: the window asks for
/// the reviews of the commits it draws and listens for changes, and never writes. A nil
/// provider (ADTerminal, tests, no Partner store) leaves every review badge and section absent.
public protocol GitReviewsProviding: AnyObject, Sendable {
    /// The reviews of `shas` in the repository whose top level is `repoPath`, by sha. A sha
    /// with no review is absent from the answer. Does its work off the main thread.
    func reviews(repoPath: String, shas: [String]) async -> [String: GitCommitReview]
    /// A tick whenever any review changes.
    func changes() -> AsyncStream<Void>
}
