#if canImport(AgenticDeveloperHubSDKCore)
import Foundation
import AgenticDeveloperHubSDKCore

/// The work-tracking recorder writes through this. Calls arrive on the
/// recorder's serial queue; `DaemonDatabase` is already safe for concurrent
/// use, so each method goes straight to `execute`/`query`.
extension DaemonDatabase: ActivityPersistence {

    public func openActivitySpan(_ span: ActivitySpanDTO) throws {
        try execute("""
            INSERT INTO activity_span (id, bundle_id, app_name, window_title, working_path,
                                       repo_root, branch, started_at, ended_at, tz, last_seen_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, params: [span.id, span.bundleId, span.appName, span.windowTitle, span.workingPath,
                      span.repoRoot, span.branch, span.startedAt, span.endedAt, span.tz, span.lastSeenAt])
    }

    /// A span shorter than one second is deleted rather than closed.
    public func closeActivitySpan(id: String, endedAt: String) throws {
        try transaction { _ = try closeSpan(id: id, endedAt: endedAt) }
    }

    /// Caller is inside a transaction. Only an open span is closed. A span
    /// deleted for being under a second takes with it the open, unbilled
    /// `app:<id>` segment billing already derived from it — nothing else
    /// would ever close that segment, so it would read Running forever (review F7).
    private func closeSpan(id: String, endedAt: String) throws -> ActivitySpanClose {
        var startedAt: String?
        try query("SELECT started_at FROM activity_span WHERE id = ? AND ended_at = ''", params: [id]) { row in
            startedAt = row["started_at"]
        }
        guard let startedAt else { return .none }
        guard UTCTimestamp.seconds(from: startedAt, to: endedAt) >= 1 else {
            try execute("DELETE FROM activity_span WHERE id = ?", params: [id])
            try execute("DELETE FROM billing_segment WHERE session_id = ? AND entry_id IS NULL",
                        params: [ActivitySpanSession.sessionId(spanId: id)])
            return .deleted
        }
        try execute("UPDATE activity_span SET ended_at = ? WHERE id = ? AND ended_at = ''", params: [endedAt, id])
        return .closed
    }

    public func retitleActivitySpan(id: String, title: String) throws {
        try execute("UPDATE activity_span SET window_title = ? WHERE id = ?", params: [title, id])
    }

    public func touchActivitySpan(id: String, at seenAt: String) throws {
        try execute("UPDATE activity_span SET last_seen_at = ? WHERE id = ?", params: [seenAt, id])
    }

    public func openIdleInterval(from: String) throws {
        try execute("""
            INSERT INTO activity_presence (id, idle_from)
            SELECT ?, ? WHERE NOT EXISTS (SELECT 1 FROM activity_presence WHERE idle_until = '')
        """, params: [UUID().uuidString, from])
    }

    public func closeIdleInterval(until: String) throws {
        try execute("UPDATE activity_presence SET idle_until = ? WHERE idle_until = ''", params: [until])
    }

    /// One transaction: every open span ends per `ActivityRecovery` (never at
    /// `now`, so downtime is not billed) and every open idle interval ends at
    /// `now`, which bounds how long a closed span can overlap an idle one.
    /// Returns the spans closed; one deleted for being under a second is not counted.
    @discardableResult
    public func recoverActivity(now: String) throws -> Int {
        var count = 0
        try transaction {
            var openIdleFrom: [String] = []
            try query("SELECT idle_from FROM activity_presence WHERE idle_until = ''") { row in
                openIdleFrom.append(row["idle_from"] ?? "")
            }
            for span in try openActivitySpans() {
                let end = ActivityRecovery.recoveredEnd(startedAt: span.startedAt, lastSeenAt: span.lastSeenAt,
                                                        openIdleFrom: openIdleFrom)
                // A deleted (sub-second) span is not a recovered one (review F31).
                switch try closeSpan(id: span.id, endedAt: end) {
                case .closed: count += 1
                case .deleted: Self.logger.info("recovery deleted sub-second span \(span.id, privacy: .public)")
                case .none: break
                }
            }
            try closeIdleInterval(until: now)
        }
        return count
    }

    /// Deletes spans billing has already derived (`billing_derived_at = ended_at`)
    /// that ended before `before`, and idle intervals that ended before it and
    /// overlap no span still kept. A span billing has not seen is kept however
    /// old, and so is the idle time inside it. Returns rows deleted.
    @discardableResult
    public func pruneActivity(endedBefore before: String) throws -> Int {
        var count = 0
        try transaction {
            try execute("""
                DELETE FROM activity_span
                WHERE billing_derived_at = ended_at AND ended_at <> '' AND ended_at < ?
            """, params: [before])
            try query("SELECT changes() AS n") { row in count += row["n"] ?? 0 }
            // An idle interval goes only once no span left overlaps it: a span
            // billing has not derived yet (or a backfill re-derives) is split
            // by its idle time, and losing that time would bill the idle.
            try execute("""
                DELETE FROM activity_presence
                WHERE idle_until <> '' AND idle_until < ?
                  AND NOT EXISTS (
                      SELECT 1 FROM activity_span s
                      WHERE s.started_at < activity_presence.idle_until
                        AND (s.ended_at = '' OR s.ended_at > activity_presence.idle_from)
                  )
            """, params: [before])
            try query("SELECT changes() AS n") { row in count += row["n"] ?? 0 }
        }
        return count
    }

    public func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO] {
        try fetchActivitySpans(where: "ended_at = '' OR ended_at >= ?", params: [since],
                               order: "ORDER BY started_at DESC LIMIT \(max(0, limit))")
    }

    public func openActivitySpans() throws -> [ActivitySpanDTO] {
        try fetchActivitySpans(where: "ended_at = ''", params: [], order: "")
    }

    private func fetchActivitySpans(where clause: String, params: [any Sendable],
                                    order: String) throws -> [ActivitySpanDTO] {
        var spans: [ActivitySpanDTO] = []
        try query("""
            SELECT id, bundle_id, app_name, window_title, working_path, repo_root, branch,
                   started_at, ended_at, tz, last_seen_at
            FROM activity_span WHERE \(clause) \(order)
        """, params: params) { row in
            spans.append(ActivitySpanDTO(
                id: row["id"] ?? "", bundleId: row["bundle_id"] ?? "", appName: row["app_name"] ?? "",
                windowTitle: row["window_title"] ?? "", workingPath: row["working_path"] ?? "",
                repoRoot: row["repo_root"] ?? "", branch: row["branch"] ?? "",
                startedAt: row["started_at"] ?? "", endedAt: row["ended_at"] ?? "",
                tz: row["tz"] ?? "", lastSeenAt: row["last_seen_at"] ?? ""))
        }
        return spans
    }
}

/// The work-tracking controller's storage: the activity tables above, the
/// `settings` table (already `BillingPersistence`'s), and the roots below.
/// Every rule is the toolkit's `WorkTrackingController` (review F14).
extension DaemonDatabase: WorkTrackingPersistence {

    /// `billing_repo` roots plus distinct `sessions.project_root` active at
    /// or after `cutoff`. `last_activity_at` is stored in SQLite's space
    /// format (`YYYY-MM-DD HH:MM:SS`), so the ISO cutoff goes through
    /// `datetime(?)`; compared raw, the `T` would sort after the space and
    /// drop the whole cutoff day. `UNION` dedupes.
    public func knownRepoRoots(activeSince cutoff: String) throws -> [String] {
        var roots: [String] = []
        try query("""
            SELECT project_root FROM billing_repo
            UNION
            SELECT project_root FROM sessions
            WHERE project_root <> '' AND last_activity_at >= datetime(?)
        """, params: [cutoff]) { row in
            if let root: String = row["project_root"], !root.isEmpty { roots.append(root) }
        }
        return roots
    }
}
#endif
