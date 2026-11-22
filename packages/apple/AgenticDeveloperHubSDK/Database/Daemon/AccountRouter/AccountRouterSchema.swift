// `db` is the one name for the shared DaemonDatabase, as in the rest of the tier.
// swiftlint:disable identifier_name
#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

/// The account router's table, `account_router_exchange`: shared migrations 1005
/// (the table, Stenographer's 049) and 1006 (the model-routing columns, its 050),
/// and the retention prune `RouterHistoryRetentionTask` runs. The router itself,
/// which writes the rows, is its own module beside this file.
extension DaemonDatabase {

    /// The timestamp format of `account_router_exchange.started_at`.
    static func routerTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    /// 1005 (Stenographer's 049): the router's request log. `IF NOT EXISTS`
    /// throughout, so a re-run is a no-op.
    static func migration1005(_ db: DaemonDatabase) throws {
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS account_router_exchange (
                id                    INTEGER PRIMARY KEY,
                started_at            TEXT NOT NULL,
                duration_ms           INTEGER NOT NULL,
                session_id            TEXT,
                method                TEXT NOT NULL,
                path                  TEXT NOT NULL,
                status                INTEGER,
                account               TEXT,
                routing_rule          TEXT,
                five_hour_utilization REAL,
                seven_day_utilization REAL,
                five_hour_status      TEXT,
                seven_day_status      TEXT,
                organization_id       TEXT,
                error                 TEXT
            )
            """)
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_account_router_exchange_started
            ON account_router_exchange(started_at)
            """)
    }

    /// The model-routing columns migration 1006 adds, in INSERT/SELECT order.
    static let routerModelColumns: [(name: String, type: String)] = [
        ("requested_model", "TEXT"), ("routed_model", "TEXT"), ("served_model", "TEXT"), ("model_rule", "TEXT"),
        ("provider", "TEXT"), ("thread_kind", "TEXT"), ("writes", "INTEGER"), ("input_tokens", "INTEGER"),
        ("output_tokens", "INTEGER"), ("cache_read_tokens", "INTEGER"), ("cache_creation_tokens", "INTEGER"),
        ("stop_reason", "TEXT")
    ]

    /// `routerModelColumns`' names, comma-separated. Fixed SQL, never caller input.
    static var routerModelColumnList: String { routerModelColumns.map(\.name).joined(separator: ", ") }

    /// 1006 (Stenographer's 050): the model-routing columns. Safe to re-run: a
    /// column already there is skipped, and so is a missing table.
    static func migration1006(_ db: DaemonDatabase) throws {
        guard try db.tableExists("account_router_exchange") else { return }
        for column in routerModelColumns
        where try !db.tableHasColumn("account_router_exchange", column.name) {
            try db.migrationExecute("ALTER TABLE account_router_exchange ADD COLUMN \(column.name) \(column.type)")
        }
    }

    /// How many rows one prune deletes; `RouterHistoryRetentionTask` reruns while a batch comes back full.
    public static let routerPruneBatch = 500

    /// Deletes up to `batchSize` rows older than `days`, oldest first, in one
    /// short statement, so a large first prune never holds the write lock for
    /// long. Returns how many went; `batchSize` back means there may be more.
    @discardableResult
    public func deleteOldRouterExchanges(
        olderThanDays days: Int, batchSize: Int = DaemonDatabase.routerPruneBatch, now: Date = Date()
    ) throws -> Int {
        let cutoff = Self.routerTimestamp(now.addingTimeInterval(-Double(days) * 86400))
        return try transaction {
            try execute("""
                DELETE FROM account_router_exchange WHERE id IN (
                    SELECT id FROM account_router_exchange WHERE started_at < ? ORDER BY started_at LIMIT ?
                )
                """, params: [cutoff, max(1, batchSize)])
            var deleted = 0
            try query("SELECT changes()") { row in deleted = row[0] ?? 0 }
            return deleted
        }
    }
}
#endif
// swiftlint:enable identifier_name
