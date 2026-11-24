import Foundation

/// A pull request's checks, rolled up from `gh`'s `statusCheckRollup`: how many
/// passed, failed and have not finished.
public struct GitPullRequestChecks: Sendable, Hashable {
    public let passing: Int
    public let failing: Int
    public let pending: Int

    public init(passing: Int, failing: Int, pending: Int) {
        self.passing = passing
        self.failing = failing
        self.pending = pending
    }

    public var total: Int { passing + failing + pending }

    /// The counts for a `statusCheckRollup` array, or nil when it holds no checks.
    ///
    /// The array mixes two GraphQL types. A `CheckRun` (GitHub Actions and other
    /// check apps) is pending until its `status` is `COMPLETED`, then passing for a
    /// `SUCCESS`, `NEUTRAL` or `SKIPPED` conclusion, pending for `STALE` (a result about an
    /// older head) or none, and failing for any other one. A
    /// `StatusContext` (the older commit status API) carries one `state`: `SUCCESS`
    /// passes, `FAILURE` and `ERROR` fail, `PENDING` and `EXPECTED` are pending.
    /// Anything unrecognised counts as pending, never as passing.
    static func rollUp(_ items: [GitHubStatusCheck]) -> GitPullRequestChecks? {
        guard !items.isEmpty else { return nil }
        var passing = 0
        var failing = 0
        var pending = 0
        for item in items {
            switch item.outcome {
            case .passing: passing += 1
            case .failing: failing += 1
            case .pending: pending += 1
            }
        }
        return GitPullRequestChecks(passing: passing, failing: failing, pending: pending)
    }
}

/// One entry of `gh`'s `statusCheckRollup`: a `CheckRun` or a `StatusContext`.
struct GitHubStatusCheck: Decodable {
    enum Outcome { case passing, failing, pending }

    let typeName: String?
    let status: String?
    let conclusion: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case typeName = "__typename"
        case status, conclusion, state
    }

    var outcome: Outcome {
        if typeName == "StatusContext" || (typeName == nil && state != nil) {
            switch state?.uppercased() {
            case "SUCCESS": return .passing
            case "FAILURE", "ERROR": return .failing
            default: return .pending
            }
        }
        guard status?.uppercased() == "COMPLETED" else { return .pending }
        switch conclusion?.uppercased() {
        case "SUCCESS", "NEUTRAL", "SKIPPED": return .passing
        // GitHub marks a run STALE when it was not re-run on a new head: its result is
        // about an older commit, so it says nothing yet about this one.
        case nil, "", "STALE": return .pending
        default: return .failing
        }
    }
}

/// A GitHub pull request as `gh pr list --json` and `gh pr view --json` describe it.
///
/// Decoded from the fields `GitHubCLI.pullRequestFields` asks for. `author` is the
/// author's login; `reviewDecision` is nil when `gh` reports none (an empty string);
/// `checks` is nil when the pull request has no checks at all.
public struct GitPullRequest: Sendable, Hashable, Identifiable, Decodable {
    public let number: Int
    public let title: String
    /// `OPEN`, `CLOSED` or `MERGED`.
    public let state: String
    public let isDraft: Bool
    public let author: String
    public let headRefName: String
    public let baseRefName: String
    public let url: URL
    public let updatedAt: Date
    /// Rolled up from `statusCheckRollup`: passing, failing and pending counts.
    public let checks: GitPullRequestChecks?
    /// `APPROVED`, `CHANGES_REQUESTED` or `REVIEW_REQUIRED`.
    public let reviewDecision: String?
    /// Whether the head branch is in another repository (a fork), so its name says nothing
    /// about a local branch of the same name.
    public let isCrossRepository: Bool

    public var id: Int { number }

    public init(number: Int, title: String, state: String, isDraft: Bool, author: String,
                headRefName: String, baseRefName: String, url: URL, updatedAt: Date,
                checks: GitPullRequestChecks?, reviewDecision: String?,
                isCrossRepository: Bool = false) {
        self.number = number
        self.title = title
        self.state = state
        self.isDraft = isDraft
        self.author = author
        self.headRefName = headRefName
        self.baseRefName = baseRefName
        self.url = url
        self.updatedAt = updatedAt
        self.checks = checks
        self.reviewDecision = reviewDecision
        self.isCrossRepository = isCrossRepository
    }

    enum CodingKeys: String, CodingKey {
        case number, title, state, isDraft, author, headRefName, baseRefName, url, updatedAt
        case statusCheckRollup, reviewDecision, isCrossRepository
    }

    private struct Author: Decodable {
        let login: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        state = try container.decode(String.self, forKey: .state)
        isDraft = try container.decodeIfPresent(Bool.self, forKey: .isDraft) ?? false
        isCrossRepository = try container.decodeIfPresent(Bool.self, forKey: .isCrossRepository) ?? false
        // A deleted account comes back as `{"login": ""}` or not at all.
        author = (try container.decodeIfPresent(Author.self, forKey: .author))?.login ?? ""
        headRefName = try container.decode(String.self, forKey: .headRefName)
        baseRefName = try container.decode(String.self, forKey: .baseRefName)
        url = try container.decode(URL.self, forKey: .url)
        let updated = try container.decode(String.self, forKey: .updatedAt)
        guard let date = Self.date(fromISO8601: updated) else {
            throw DecodingError.dataCorruptedError(
                forKey: .updatedAt, in: container, debugDescription: "not an ISO 8601 date: \(updated)")
        }
        updatedAt = date
        let rollup = try container.decodeIfPresent([GitHubStatusCheck].self, forKey: .statusCheckRollup) ?? []
        checks = GitPullRequestChecks.rollUp(rollup)
        let decision = try container.decodeIfPresent(String.self, forKey: .reviewDecision) ?? ""
        reviewDecision = decision.isEmpty ? nil : decision
    }

    /// `2026-11-14T09:30:00Z`, with or without fractional seconds.
    static func date(fromISO8601 text: String) -> Date? {
        if let date = try? Date.ISO8601FormatStyle().parse(text) { return date }
        return try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text)
    }
}
