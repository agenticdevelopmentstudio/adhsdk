import Foundation
import AgenticDeveloperHubSDKCore

extension PartnerStore {

    private static let reviewColumns = """
        id, repo_id, repo_path, repo_name, sha, parent, branch, subject, author, committed_at, state,
        session_id, started_at, finished_at, summary, skip_reason, superseded_json
    """

    public func insertReview(_ entry: PartnerReview) throws {
        let superseded = try Self.json(entry.supersededBy)
        try write(.reviews) {
            try run("""
                INSERT INTO review (\(Self.reviewColumns))
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, Self.reviewBinds(entry, superseded: superseded))
        }
    }

    /// Inserts `entry` unless a review of the same repo and commit (or the same id) is already stored; returns
    /// whether it was inserted. Two crawls racing on the same commit (two Debug copies) both get an answer
    /// instead of a constraint error.
    @discardableResult
    public func insertReviewIfNew(_ entry: PartnerReview) throws -> Bool {
        let superseded = try Self.json(entry.supersededBy)
        return try write(.reviews) {
            try run("""
                INSERT OR IGNORE INTO review (\(Self.reviewColumns))
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, Self.reviewBinds(entry, superseded: superseded)) == 1
        }
    }

    /// Replaces every column of the row `entry.id`. Throws when no such review exists.
    public func updateReview(_ entry: PartnerReview) throws {
        let superseded = try Self.json(entry.supersededBy)
        try write(.reviews) {
            let changed = try run("""
                UPDATE review SET repo_id = ?, repo_path = ?, repo_name = ?, sha = ?, parent = ?, branch = ?,
                    subject = ?, author = ?, committed_at = ?, state = ?, session_id = ?, started_at = ?,
                    finished_at = ?, summary = ?, skip_reason = ?, superseded_json = ?
                WHERE id = ?
            """, Array(Self.reviewBinds(entry, superseded: superseded).dropFirst()) + [.text(entry.id)])
            guard changed == 1 else { throw PartnerStoreError.invalidData("no review \(entry.id)") }
        }
    }

    public func review(id: String) throws -> PartnerReview? {
        try locked {
            try runQuery("SELECT \(Self.reviewColumns) FROM review WHERE id = ?", [.text(id)], Self.review).first
        }
    }

    /// Queued reviews come oldest commit first; other views list the newest first.
    public func reviews(state: PartnerReviewState?) throws -> [PartnerReview] {
        try locked {
            switch state {
            case .some(.queued):
                return try runQuery("""
                    SELECT \(Self.reviewColumns) FROM review WHERE state = 'queued' ORDER BY committed_at, id
                """, [], Self.review)
            case .some(let state):
                return try runQuery("""
                    SELECT \(Self.reviewColumns) FROM review WHERE state = ? ORDER BY committed_at DESC, id
                """, [.text(state.rawValue)], Self.review)
            case .none:
                return try runQuery("""
                    SELECT \(Self.reviewColumns) FROM review ORDER BY committed_at DESC, id
                """, [], Self.review)
            }
        }
    }

    /// The reviews of `shas` in the repository at exactly `repoPath`, by sha, for the Git
    /// window (recipe `workspace/git/git-views`, "Reviews"). A sha with no review is absent.
    /// Every row counts, superseded included: `supersededBy` lists the later commits the
    /// reviewer was told about, not a replacement. When a sha has more than one row (one per
    /// repo id sharing the path), the latest wins: the one finished, else started, else
    /// committed last, and on a tie the one inserted last. Read-only; the shas are asked for
    /// in chunks of 500, under SQLite's bind limit, through `idx_review_path_sha`.
    public func reviews(repoPath: String, shas: [String]) throws -> [String: PartnerReview] {
        let wanted = Array(Set(shas))
        guard !wanted.isEmpty else { return [:] }
        return try locked {
            var found: [String: PartnerReview] = [:]
            for start in stride(from: 0, to: wanted.count, by: 500) {
                let chunk = wanted[start..<min(start + 500, wanted.count)]
                let marks = Array(repeating: "?", count: chunk.count).joined(separator: ", ")
                let rows = try runQuery("""
                    SELECT \(Self.reviewColumns) FROM review WHERE repo_path = ? AND sha IN (\(marks))
                    ORDER BY COALESCE(finished_at, started_at, committed_at), rowid
                """, [.text(repoPath)] + chunk.map { .text($0) }, Self.review)
                for row in rows { found[row.sha] = row }
            }
            return found
        }
    }

    public func reviewExists(repoID: String, sha: String) throws -> Bool {
        try locked {
            try runQuery("SELECT 1 FROM review WHERE repo_id = ? AND sha = ?",
                         [.text(repoID), .text(sha)]) { $0.int(0) }.isEmpty == false
        }
    }

    public func reviewCounts() throws -> (queued: Int, running: Int, done: Int, failed: Int, skipped: Int) {
        let byState: [String: Int] = try locked {
            Dictionary(uniqueKeysWithValues: try runQuery("SELECT state, COUNT(*) FROM review GROUP BY state", []) {
                ($0.text(0), Int($0.int(1)))
            })
        }
        return (byState["queued"] ?? 0, byState["running"] ?? 0, byState["done"] ?? 0,
                byState["failed"] ?? 0, byState["skipped"] ?? 0)
    }

    public func reviewSetting(repoID: String, key: String) throws -> String? {
        try locked {
            try runQuery("SELECT value FROM review_setting WHERE repo_id = ? AND key = ?",
                         [.text(repoID), .text(key)]) { $0.text(0) }.first
        }
    }

    /// A nil `value` deletes the setting.
    public func setReviewSetting(repoID: String, key: String, value: String?) throws {
        try write(.reviews) {
            if let value {
                try run("INSERT OR REPLACE INTO review_setting (repo_id, key, value) VALUES (?, ?, ?)",
                        [.text(repoID), .text(key), .text(value)])
            } else {
                try run("DELETE FROM review_setting WHERE repo_id = ? AND key = ?", [.text(repoID), .text(key)])
            }
        }
    }

    private static func reviewBinds(_ entry: PartnerReview, superseded: String) -> [Value] {
        [.text(entry.id), .text(entry.repoID), .text(entry.repoPath), .text(entry.repoName), .text(entry.sha),
         .text(entry.parent), .text(entry.branch), .text(entry.subject), .text(entry.author),
         .date(entry.committedAt), .text(entry.state.rawValue), .optText(entry.sessionID),
         .optDate(entry.startedAt), .optDate(entry.finishedAt), .optText(entry.summary),
         .optText(entry.skipReason), .text(superseded)]
    }

    private static func review(_ row: Row) throws -> PartnerReview {
        guard let state = PartnerReviewState(rawValue: row.text(10)) else {
            throw PartnerStoreError.invalidData("bad review state \(row.text(10))")
        }
        let superseded = try JSONDecoder().decode([String].self, from: Data(row.text(16).utf8))
        return PartnerReview(
            id: row.text(0), repoID: row.text(1), repoPath: row.text(2), repoName: row.text(3), sha: row.text(4),
            parent: row.text(5), branch: row.text(6), subject: row.text(7), author: row.text(8),
            committedAt: try row.date(9), state: state, sessionID: row.optText(11), startedAt: try row.optDate(12),
            finishedAt: try row.optDate(13), summary: row.optText(14), skipReason: row.optText(15),
            supersededBy: superseded)
    }
}
