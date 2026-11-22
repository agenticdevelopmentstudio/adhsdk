#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

// `db` is the one name for the shared DaemonDatabase, as in the toolkit.
// swiftlint:disable identifier_name

/// App-activity storage: schema 48.
///
/// Spans (one per stretch of an allowed app being frontmost, attributed to a
/// repo root + branch) and idle intervals live in the session daemon's database beside the
/// billing tables, so billing derivation reads them and writes the resulting
/// segments over one connection. Recording them is `ActivityPersistence`
/// (`DaemonDatabase+ActivityPersistence.swift`); the billing reads over them are in
/// `DaemonDatabase+Billing.swift`.
extension DaemonDatabase {

    /// 048: `activity_span` and `activity_presence`, with their indexes.
    ///
    /// Every statement is `IF NOT EXISTS`, so a database that already has them
    /// — a re-run after branch divergence — is left as it is rather than
    /// failing startup.
    static func migration1004(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS activity_span (
                id                 TEXT PRIMARY KEY,
                bundle_id          TEXT NOT NULL,
                app_name           TEXT NOT NULL,
                window_title       TEXT NOT NULL DEFAULT '',
                working_path       TEXT NOT NULL DEFAULT '',
                repo_root          TEXT NOT NULL DEFAULT '',
                branch             TEXT NOT NULL DEFAULT '',
                started_at         TEXT NOT NULL,
                ended_at           TEXT NOT NULL DEFAULT '',
                tz                 TEXT NOT NULL,
                last_seen_at       TEXT NOT NULL DEFAULT '',
                billing_derived_at TEXT NOT NULL DEFAULT ''
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_activity_span_started ON activity_span(started_at)"
        )
        // `billingAppSpansNeedingDerivation` writes this `WHERE` verbatim —
        // SQLite matches a partial index's clause structurally — so a pass
        // reads the pending spans and nothing else.
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_activity_span_pending
            ON activity_span(started_at) WHERE billing_derived_at <> ended_at OR ended_at = ''
        """)
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS activity_presence (
                id         TEXT PRIMARY KEY,
                idle_from  TEXT NOT NULL,
                idle_until TEXT NOT NULL DEFAULT ''
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_activity_presence_from ON activity_presence(idle_from)"
        )
        logger.info("migration1004: activity schema ready")
    }
}

// swiftlint:enable identifier_name
#endif
