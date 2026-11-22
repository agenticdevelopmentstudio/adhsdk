#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

// MARK: - Billing watermark on replayed events

extension DaemonDatabase {

    /// The session daemon's ``SessionUpsertHook``: the billing half of the
    /// `sessions` upsert. A session daemon passes it to `DaemonDatabase`.
    public static let sessionUpsertHook: SessionUpsertHook = DaemonDatabase.forgetBillingWatermarkOnReplay

    /// The billing half of the `sessions` upsert (``sessionUpsertHook``).
    ///
    /// The same replay, seen from billing: activity OLDER than the session's clock
    /// (a recovered quarantine burst) moves neither `last_activity_at` nor
    /// `status`, so the billing watermark (`billing_derived_at <> last_activity_at`)
    /// would never re-select the session and the recovered work would never be
    /// billed. Forgetting the watermark queues one re-derivation.
    ///
    /// It runs after the upsert, so `last_activity_at` is already `MAX(old, new)`;
    /// `new < MAX(old, new)` holds exactly when `new < old`, which is the test the
    /// upsert used to make against the pre-update row. Gated on the same
    /// activity flag: an ambient event never touches the watermark.
    static func forgetBillingWatermarkOnReplay(
        _ database: DaemonDatabase, _ sessionId: String, _ eventTimestamp: String,
        _ countsAsActivity: Bool
    ) throws {
        guard countsAsActivity else { return }
        try database.execute(
            """
            UPDATE sessions SET billing_derived_at = ''
            WHERE session_id = ?
              AND COALESCE(datetime(?), datetime('now')) < last_activity_at
            """,
            params: [sessionId, eventTimestamp]
        )
    }
}
#endif
