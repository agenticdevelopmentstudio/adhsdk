#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import GRDB
import OSLog
import Foundation

// `db` is the one name for the shared DaemonDatabase, as in the toolkit.
// swiftlint:disable identifier_name

// Rate-limit snapshot reads and the Claude version history.
extension DaemonDatabase {

    /// `latestRateLimitSnapshot(account:)` wants an account's newest snapshot by
    /// `id`, and `(account_email, timestamp)` cannot give rows in `id` order: SQLite
    /// gathered every snapshot the account ever had and sorted them in a temp
    /// B-tree — 58k rows and ~250 ms for one account, on every Usage recompute and
    /// for each account section. `(account_email, id)` makes it one index seek with
    /// the same answer.
    ///
    /// An ensure step rather than a numbered migration: an index is idempotent to
    /// create, and a number chosen here could collide with one main takes first.
    static func ensureRateLimitSnapshotAccountIdIndex(_ db: DaemonDatabase) throws {
        guard try db.tableExists("rate_limit_snapshots") else { return }
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_rate_limit_snapshots_account_id "
            + "ON rate_limit_snapshots(account_email, id)"
        )
    }

    /// Most recent `rate_limit_snapshots` row, optionally scoped to a
    /// session. Returns nil when the table is empty.
    func latestRateLimitSnapshot(
        sessionId: String? = nil,
        account: String? = nil
    ) throws -> Sessions.RateLimitSnapshotDTO? {
        var clauses: [String] = []
        var params: [any Sendable] = []
        if let sessionId { clauses.append("session_id = ?"); params.append(sessionId) }
        appendAccountFilter(account, column: "account_email", clauses: &clauses, params: &params)
        let whereSQL = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = """
            SELECT id, timestamp, session_id, week_start, elapsed_hours,
                   elapsed_day, weekly_pct, daily_avg_pct, five_hour_pct,
                   five_hour_resets_at, seven_day_resets_at, projected_pct,
                   account_email, spend_pct, spend_resets_at
            FROM rate_limit_snapshots
            \(whereSQL)
            ORDER BY id DESC
            LIMIT 1
            """

        var result: Sessions.RateLimitSnapshotDTO?
        try query(sql, params: params) { row in
            result = self.rateLimitRow(from: row)
        }
        return result
    }

    /// Most recent still-future `five_hour_resets_at` across all snapshots in
    /// `(now, maxReset]` — the fallback the 5h countdown needs when the latest
    /// snapshot's own reset has gone stale (Anthropic occasionally ships a
    /// past/zero 5h reset). Mirrors CSL's retired `MAX(five_hour_resets_at)
    /// WHERE ... > now` query. Returns nil when no snapshot qualifies.
    func latestFutureFiveHourReset(now: Int, maxReset: Int, account: String? = nil) throws -> Int? {
        var clauses: [String] = ["five_hour_resets_at > ?", "five_hour_resets_at <= ?"]
        var params: [any Sendable] = [now, maxReset]
        appendAccountFilter(account, column: "account_email", clauses: &clauses, params: &params)
        let whereSQL = "WHERE " + clauses.joined(separator: " AND ")
        let sql = "SELECT MAX(five_hour_resets_at) FROM rate_limit_snapshots \(whereSQL)"
        var result: Int?
        try query(sql, params: params) { row in
            if let value = optionalInt(row, 0) { result = value }
        }
        return result
    }

    /// Series of `rate_limit_snapshots` rows in chronological order,
    /// optionally bounded by `since` / `until` and / or scoped to a session.
    /// Rate-limit snapshots oldest-first, for charting.
    ///
    /// - Parameter limit: how many snapshots to return. Every filter here is
    ///   optional, so an unlimited series is the *default* request: on one real
    ///   install `GET /rate-limits` answered with 75,275 rows / 33.7 MB of JSON,
    ///   materialised once as DTOs and again as the response body, and this table
    ///   gains a row per snapshot forever. The window is taken from the **newest**
    ///   end and then re-sorted ascending — truncating a time series at the recent
    ///   end would silently hand a chart the wrong picture, which is worse than
    ///   handing it a shorter one.
    func rateLimitSeries(
        since: String? = nil,
        until: String? = nil,
        sessionId: String? = nil,
        limit: Int
    ) throws -> [Sessions.RateLimitSnapshotDTO] {
        var clauses: [String] = []
        var params: [any Sendable] = []
        if let since { clauses.append("timestamp >= ?"); params.append(since) }
        if let until { clauses.append("timestamp < ?");  params.append(until) }
        if let sessionId { clauses.append("session_id = ?"); params.append(sessionId) }
        let whereSQL = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        params.append(limit)
        let sql = """
            SELECT * FROM (
                SELECT id, timestamp, session_id, week_start, elapsed_hours,
                       elapsed_day, weekly_pct, daily_avg_pct, five_hour_pct,
                       five_hour_resets_at, seven_day_resets_at, projected_pct,
                       account_email, spend_pct, spend_resets_at
                FROM rate_limit_snapshots
                \(whereSQL)
                ORDER BY id DESC
                LIMIT ?
            )
            ORDER BY id ASC
            """

        var rows: [Sessions.RateLimitSnapshotDTO] = []
        try query(sql, params: params) { row in
            rows.append(self.rateLimitRow(from: row))
        }
        return rows
    }

    private func rateLimitRow(from row: Row) -> Sessions.RateLimitSnapshotDTO {
        Sessions.RateLimitSnapshotDTO(
            id: int64(row, 0),
            timestamp: string(row, 1),
            sessionId: string(row, 2),
            weekStart: string(row, 3),
            elapsedHours: int(row, 4),
            elapsedDay: double(row, 5),
            weeklyPct: double(row, 6),
            dailyAvgPct: double(row, 7),
            fiveHourPct: double(row, 8),
            fiveHourResetsAt: int(row, 9),
            sevenDayResetsAt: int(row, 10),
            projectedPct: double(row, 11),
            accountEmail: string(row, 12),
            spendPct: double(row, 13),
            spendResetsAt: int(row, 14)
        )
    }

    /// Read rows from `claude_versions`. `version` returns exactly one
    /// row (or empty); `newerThan` returns versions strictly newer than
    /// the given version string, comparing dotted components numerically
    /// ("2.1.98" < "2.1.117") — filtered in Swift, since SQL string
    /// comparison mis-orders versions. With neither filter set, returns
    /// every version newest-first.
    func claudeVersions(
        version: String? = nil,
        newerThan: String? = nil
    ) throws -> [Sessions.ClaudeVersionDTO] {
        var clauses: [String] = []
        var params: [any Sendable] = []
        if let version { clauses.append("claude_version = ?"); params.append(version) }
        let whereSQL = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = """
            SELECT claude_version, fields, fields_count, first_seen, field_paths
            FROM claude_versions
            \(whereSQL)
            ORDER BY first_seen DESC
            """

        var rows: [Sessions.ClaudeVersionDTO] = []
        try query(sql, params: params) { row in
            let pathsJSON = string(row, 4)
            let paths: [String]
            if let data = pathsJSON.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
                paths = arr
            } else {
                paths = []
            }
            rows.append(Sessions.ClaudeVersionDTO(
                claudeVersion: string(row, 0),
                fieldsJson: string(row, 1),
                fieldsCount: Int(int64(row, 2)),
                firstSeen: string(row, 3),
                fieldPaths: paths
            ))
        }
        if let newerThan {
            let baseline = Self.versionKey(newerThan)
            rows = rows.filter { baseline.lexicographicallyPrecedes(Self.versionKey($0.claudeVersion)) }
        }
        return rows
    }

    /// Numeric sort key for a dotted version string ("2.1.98" → [2, 1, 98]);
    /// non-numeric components count as 0 so a malformed capture never throws.
    private static func versionKey(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }
}

// swiftlint:enable identifier_name
#endif
