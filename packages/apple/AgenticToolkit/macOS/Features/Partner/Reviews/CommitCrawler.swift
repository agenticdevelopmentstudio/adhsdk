import Foundation
import AgenticToolkitCore

public struct CrawledCommit: Sendable, Equatable {
    public var sha: String
    public var parent: String
    public var subject: String
    public var author: String
    public var authorEmail: String
    public var committedAt: Date
    /// The values of the commit's `Reviewed-Commit:` trailers: the shas a review's fix commit answers. Not
    /// empty marks one of the partner's own fixes, wherever it has since been merged.
    public var reviewedCommits: [String]

    public init(sha: String, parent: String, subject: String, author: String, authorEmail: String = "",
                committedAt: Date, reviewedCommits: [String] = []) {
        self.sha = sha
        self.parent = parent
        self.subject = subject
        self.author = author
        self.authorEmail = authorEmail
        self.committedAt = committedAt
        self.reviewedCommits = reviewedCommits
    }
}

public enum CommitCrawlerError: LocalizedError, Equatable {
    case noOwnerIdentity(repo: String)

    public var errorDescription: String? {
        switch self {
        case .noOwnerIdentity(let repo):
            "\(repo) has no git user.email, so none of its commits can be told apart as the owner's; "
                + "set one to have its commits reviewed"
        }
    }
}

/// Finds recent commits per repo and queues a review for each one not yet seen.
public struct CommitCrawler: Sendable {
    /// The trailer the review job's fix step writes on every fix commit (``PartnerJobDefaults``).
    public static let reviewedCommitTrailer = "Reviewed-Commit"

    private let git: ReviewGit

    /// `PartnerStore` is a `@unchecked Sendable` class with its own lock, not main-actor, so `crawl` runs
    /// wherever its caller does.
    public init(git: ReviewGit = ReviewGit()) {
        self.git = git
    }

    /// Non-merge commits on `branch` since `since`, oldest first. A root commit's parent is git's empty tree.
    /// The branch is named as `refs/heads/<branch>` before `--`, so neither a top-level path nor a tag of the
    /// same name can stand in for it. Each commit's `Reviewed-Commit:` trailer values come back with it.
    public func commits(in repo: URL, branch: String, since: Date) async throws -> [CrawledCommit] {
        var arguments = ["log", "--no-merges"]
        if since.timeIntervalSince1970 > 0 {
            arguments.append("--since=\(ISO8601DateFormatter().string(from: since))")
        }
        arguments += ["--format=%H%x1f%P%x1f%s%x1f%an%x1f%cI%x1f%ae%x1f"
                        + "%(trailers:key=\(Self.reviewedCommitTrailer),valueonly,separator=%x20)%x1e",
                      "refs/heads/\(branch)", "--"]
        let formatter = ISO8601DateFormatter()
        let output = try await git.run(arguments, in: repo)
        // Records end in RS, not newline: a trailer value may run onto a continuation line.
        let found: [CrawledCommit] = output.split(separator: "\u{1e}").compactMap { record in
            let line = record.trimmingCharacters(in: .newlines)
            let fields = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 7, let date = formatter.date(from: fields[4]) else { return nil }
            let parent = fields[1].split(separator: " ").first.map(String.init) ?? ReviewGit.emptyTree
            return CrawledCommit(sha: fields[0], parent: parent, subject: fields[2], author: fields[3],
                                 authorEmail: fields[5], committedAt: date,
                                 reviewedCommits: fields[6].split(whereSeparator: \.isWhitespace).map(String.init))
        }
        return found.reversed()
    }

    /// Queues a review (id `<repoID>:<sha>`) for every commit on each branch not already in the store, authored
    /// by the repo's own `user.email`. Returns how many were inserted.
    ///
    /// Only commits whose author email is the owner's, so a contributor's ordinary commit pulled onto a crawled
    /// branch is not reviewed. This is a scope filter, not a security boundary: the author email is whatever
    /// the committer typed, so a commit written with `--author` set to the owner's address passes it, whether it
    /// arrived by a merged pull request or a local `gh pr checkout` with other branches crawled. A review runs
    /// Claude Code with permissions bypassed over the diff, so a crawled repo must be one whose commits the owner
    /// would let steer that agent. A repo with no `user.email` throws rather than reviewing everything.
    ///
    /// Never the partner's own fixes (a ``reviewedCommitTrailer`` trailer), on any branch: merged into a crawled
    /// branch they would be reviewed again, and their reviews' fixes after them.
    public func crawl(repos: [(id: String, path: String, name: String)], branches: (URL) async throws -> [String],
                      since: Date, store: PartnerStore) async throws -> Int {
        var inserted = 0
        for repo in repos {
            let url = URL(fileURLWithPath: repo.path)
            let owner = try await ownerEmail(in: url, name: repo.name)
            for branch in try await branches(url) {
                for commit in try await commits(in: url, branch: branch, since: since)
                where try commit.authorEmail.caseInsensitiveCompare(owner) == .orderedSame
                    && commit.reviewedCommits.isEmpty
                    && !store.reviewExists(repoID: repo.id, sha: commit.sha) {
                    // OR IGNORE: another crawl (a second Debug copy) may have queued it since the check.
                    let isNew = try store.insertReviewIfNew(PartnerReview(
                        id: "\(repo.id):\(commit.sha)", repoID: repo.id, repoPath: repo.path, repoName: repo.name,
                        sha: commit.sha, parent: commit.parent, branch: branch, subject: commit.subject,
                        author: commit.author, committedAt: commit.committedAt, state: .queued, supersededBy: []))
                    if isNew { inserted += 1 }
                }
            }
        }
        return inserted
    }

    /// `git config user.email` as the repo sees it (its own, else the global one); `git config --get` exits 1
    /// when it is unset.
    private func ownerEmail(in repo: URL, name: String) async throws -> String {
        let email = (try? await git.run(["config", "--get", "user.email"], in: repo))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !email.isEmpty else { throw CommitCrawlerError.noOwnerIdentity(repo: name) }
        return email
    }
}
