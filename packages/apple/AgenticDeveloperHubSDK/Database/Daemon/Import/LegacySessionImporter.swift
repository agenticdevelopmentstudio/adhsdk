#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// Copies a retired session daemon's stores into a running session runtime's.
///
/// The source is a directory of *copies* of stenographerd's or adkd's files: the
/// main database (`stenographer.db` or `adkd.db`), the hook spool (`ingest.db`),
/// the event store (`events.db`) and the Claude raw archive (`claude-raw.db`). A
/// file that is not there is reported as missing, never an error. The importer
/// only reads the source, and writes only through the target's main database
/// connection (its write lane), with the target's other three files attached
/// to it, so the app that owns the target is still the one writing it.
///
/// Every table the source and the target share is copied, with its common
/// columns; a source-only table (a daemon's own migrations) is reported as
/// skipped. A re-run inserts nothing it inserted before:
/// - rows with a natural key (`sessions` by `session_id`, billing rows by id,
///   the event store's rows by their dedup keys, the raw archive by
///   `dedup_key`) are `INSERT OR IGNORE`d;
/// - rows that have only a row id (`event_log`, its per-type and tool tables,
///   `transcript_turns`, the spool) are recorded in `legacy_import_rows` by
///   source tag (``SourceKind``), table and source row id, and a recorded row is
///   never copied again;
/// - `rate_limit_snapshots` is keyed by `timestamp` and `account_email`.
///
/// Row ids are never copied. A child of `event_log` gets the id its parent was
/// given in the target, and an event-store row gets the id its raw record has
/// in the target's archive; a row whose parent was not copied (because the
/// target already held it) is not copied either.
///
/// Settings are not copied, except the billing knobs: a source's billing keys
/// (``SourceKind/billingSettingsKeyPrefix``) are rewritten to the target's
/// prefix (``DaemonDatabase/billingSettingsKeyPrefix``). Every other setting
/// (`ingestion_enabled`, the provider registry, the summaries switch) belongs to
/// the daemon that wrote it and would switch the target's features silently.
///
/// The main database is copied in one transaction (its foreign keys are
/// checked at its commit). The raw archive, the event store and the spool are
/// then copied in batches of at most ``batchRows`` source rows, each batch its
/// own transaction: SQLite holds a write lock on every attached file a
/// transaction has written until it commits, and those files are the ones the
/// runtime's hook ingestion writes through its own connections, so one
/// transaction over the whole copy locked live ingestion out for as long as
/// the import ran. A runtime writer now waits for one batch at most.
///
/// So an import that fails part way leaves the batches before the failure
/// committed, and a re-run (which inserts nothing it inserted before) copies
/// the rest. That failure is thrown as ``LegacyImportFailure``, whose report
/// says what did commit: every store finished before it, and the failed store
/// (status ``LegacyImportReport/Status/failed``) with the rows its committed
/// batches inserted (none for the main database, whose one transaction rolls
/// back). A batch commits atomically within each WAL-mode file but not
/// across them: a spool row recorded in the main database's map whose spool
/// insert was lost to a crash is the only window, and the spool is a queue of
/// not-yet-drained hook events.
public final class LegacySessionImporter: @unchecked Sendable {

    /// Which daemon wrote the source directory. Its raw value is the source tag
    /// recorded in `legacy_import_rows`.
    public enum SourceKind: String, Codable, Sendable, CaseIterable {
        case stenographerd
        case adkd

        /// The main database's file name.
        public var mainDatabaseFileName: String {
            switch self {
            case .stenographerd: return "stenographer.db"
            case .adkd: return "adkd.db"
            }
        }

        /// The prefix this daemon kept its billing settings under.
        public var billingSettingsKeyPrefix: String {
            switch self {
            case .stenographerd: return Sessions.StenographerBilling.settingsKeyPrefix
            case .adkd: return DaemonDatabase.defaultBillingSettingsKeyPrefix
            }
        }
    }

    /// Where the rows go. `database` is the runtime's main database; the other
    /// three are the paths of files the runtime has open, and nil (or a file
    /// that does not exist) leaves that store out.
    public struct Target: Sendable {
        public let database: DaemonDatabase
        public let spoolPath: String?
        public let eventStorePath: String?
        public let rawArchivePath: String?

        public init(database: DaemonDatabase, spoolPath: String?, eventStorePath: String?, rawArchivePath: String?) {
            self.database = database
            self.spoolPath = spoolPath
            self.eventStorePath = eventStorePath
            self.rawArchivePath = rawArchivePath
        }

        /// The runtime's four files. The runtime must be open.
        public init(runtime: SessionDaemonRuntime) {
            self.init(
                database: runtime.database,
                spoolPath: runtime.configuration.spoolPath,
                eventStorePath: runtime.configuration.eventStorePath,
                rawArchivePath: runtime.configuration.claudeArchivePath
            )
        }
    }

    /// The table that remembers which source rows were copied.
    public static let mapTable = "legacy_import_rows"

    /// The longest one import may hold the main database's write lane. A real
    /// store is millions of rows; the serving deadline would eject it.
    static let writeDeadline: Duration = .seconds(6 * 60 * 60)

    /// The default for ``batchRows``: small enough that a batch commits in well
    /// under the runtime's busy timeout, large enough that a store of millions
    /// of rows is not millions of commits.
    public static let defaultBatchRows = 2_000

    /// Main-database tables never copied, with why.
    static let excludedMainTables: [String: String] = [
        "schema_migrations": "the target's own migration ledger",
        mapTable: "the importer's own ledger",
        "ingestion_errors": "names quarantine files in the source's errors directory",
        "conversation_queued_prompts": "keyed by the source's transcript line ids",
        "events": "superseded by event_log"
    ]

    /// Event-store and archive tables never copied, with why.
    static let excludedStoreTables: [String: String] = [
        "store_meta": "the store's own cursors and flags",
        "replay_failures": "keyed by the source archive's row ids",
        "archive_meta": "the archive's provider stamp",
        "source_state": "the spool's own cursors",
        "spool_meta": "the spool's provider stamp"
    ]

    public let target: Target

    /// Most source rows one transaction copies into an attached store.
    public let batchRows: Int

    /// Called after each committed batch with the attached store's schema
    /// (`dst_raw`, `dst_events` or `dst_spool`), while the import still holds
    /// the main database's write lane. Tests use it to write those stores
    /// between batches.
    var batchCommitted: (String) throws -> Void = { _ in }

    public init(target: Target, batchRows: Int = LegacySessionImporter.defaultBatchRows) {
        self.target = target
        self.batchRows = max(1, batchRows)
    }

    /// Copies every store found in `directory` into the target and reports what
    /// each table gained. Throws only when a file that is there cannot be read
    /// or written; the transaction that failed is then rolled back, and what
    /// committed before it stays (a re-run copies the rest). The error is then
    /// a ``LegacyImportFailure`` carrying the report of what committed.
    public func importStores(kind: SourceKind, directory: URL) throws -> LegacyImportReport {
        var report = LegacyImportReport(source: kind, directory: directory.path)
        do {
            try copy(kind: kind, directory: directory, into: &report)
        } catch {
            throw LegacyImportFailure(report: report, underlying: error)
        }
        return report
    }

    private func copy(kind: SourceKind, directory: URL, into report: inout LegacyImportReport) throws {
        let files = SourceFiles(kind: kind, directory: directory)
        let targetFiles = TargetFiles(target: target)

        try target.database.writeWithoutTransaction(deadline: Self.writeDeadline) { conn in
            var attached: [String] = []
            defer {
                for schema in attached.reversed() {
                    try? conn.execute(sql: "DETACH DATABASE \(quoted(schema))")
                }
            }
            func attach(_ path: String?, as schema: String) throws -> Bool {
                guard let path, FileManager.default.fileExists(atPath: path) else { return false }
                try conn.execute(sql: "ATTACH DATABASE ? AS \(quoted(schema))", arguments: [path])
                attached.append(schema)
                return true
            }

            let hasMain = try attach(files.main, as: "src_main")
            let hasSpool = try attach(files.spool, as: "src_spool")
            let hasEvents = try attach(files.events, as: "src_events")
            let hasRaw = try attach(files.raw, as: "src_raw")
            let hasTargetSpool = try attach(targetFiles.spool, as: "dst_spool")
            let hasTargetEvents = try attach(targetFiles.events, as: "dst_events")
            let hasTargetRaw = try attach(targetFiles.raw, as: "dst_raw")

            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS main.\(Self.mapTable) (
                    source TEXT NOT NULL, table_name TEXT NOT NULL,
                    source_id INTEGER NOT NULL, target_id INTEGER,
                    PRIMARY KEY (source, table_name, source_id)) WITHOUT ROWID
                """)

            let copier = TableCopier(
                conn: conn, tag: kind.rawValue, batchRows: batchRows, batchCommitted: batchCommitted)
            try conn.inTransaction {
                // Checked at commit, so the copy order never trips a reference.
                try conn.execute(sql: "PRAGMA defer_foreign_keys = ON")
                try Self.store(
                    file: kind.mainDatabaseFileName, present: hasMain, targetPresent: true,
                    into: &report, rollsBackOnFailure: true
                ) { store in
                    try copier.copyMain(
                        into: &store,
                        sourcePrefix: kind.billingSettingsKeyPrefix,
                        targetPrefix: target.database.billingSettingsKeyPrefix
                    )
                }
                return .commit
            }

            // The attached stores, each in batches that commit as they go.
            // The archive before the event store: an event row's raw_ref is
            // resolved through the target archive's copy of its raw record.
            try Self.store(
                file: SourceFiles.rawName, present: hasRaw, targetPresent: hasTargetRaw, into: &report
            ) { store in
                try copier.copyStore(from: "src_raw", to: "dst_raw", into: &store, rawRemap: false)
            }
            try Self.store(
                file: EventStore.fileName, present: hasEvents, targetPresent: hasTargetEvents, into: &report
            ) { store in
                guard hasRaw, hasTargetRaw else {
                    store.status = .notImported
                    store.note = "needs both raw archives to resolve raw_ref"
                    return
                }
                try copier.copyStore(from: "src_events", to: "dst_events", into: &store, rawRemap: true)
            }
            try Self.store(
                file: IngestSpool.defaultDBName, present: hasSpool, targetPresent: hasTargetSpool, into: &report
            ) { store in
                try copier.copySpool(into: &store)
            }
        }
    }

    /// Copies one store and appends its report to `report`, even when `body`
    /// throws: the store is then ``LegacyImportReport/Status/failed`` with the
    /// counts its committed batches reached, or none when `rollsBackOnFailure`
    /// (the store was copied in one transaction the failure rolls back).
    private static func store(
        file: String, present: Bool, targetPresent: Bool,
        into report: inout LegacyImportReport, rollsBackOnFailure: Bool = false,
        _ body: (inout LegacyImportReport.Store) throws -> Void
    ) throws {
        var store = LegacyImportReport.Store(file: file)
        guard present else {
            store.status = .missing
            report.stores.append(store)
            return
        }
        guard targetPresent else {
            store.status = .notImported
            store.note = "the target has no such store"
            report.stores.append(store)
            return
        }
        store.status = .imported
        do {
            try body(&store)
        } catch {
            store.status = .failed
            store.note = error.localizedDescription
            if rollsBackOnFailure { store.inserted = [:] }
            report.stores.append(store)
            throw error
        }
        report.stores.append(store)
    }
}

/// An import that failed part way: `report` holds what committed before the
/// failure (see ``LegacySessionImporter/importStores(kind:directory:)``), and
/// the description is the underlying error's.
public struct LegacyImportFailure: Error, LocalizedError, CustomStringConvertible {
    public let report: LegacyImportReport
    public let underlying: Error

    public init(report: LegacyImportReport, underlying: Error) {
        self.report = report
        self.underlying = underlying
    }

    public var errorDescription: String? { underlying.localizedDescription }
    public var description: String { "\(underlying)" }
}

// MARK: - Files

private struct SourceFiles {
    static let rawName = RawArchive.fileName(provider: ClaudeProvider.name)

    let main: String
    let spool: String
    let events: String
    let raw: String

    init(kind: LegacySessionImporter.SourceKind, directory: URL) {
        main = directory.appendingPathComponent(kind.mainDatabaseFileName).path
        spool = directory.appendingPathComponent(IngestSpool.defaultDBName).path
        events = directory.appendingPathComponent(EventStore.fileName).path
        raw = directory.appendingPathComponent(Self.rawName).path
    }
}

private struct TargetFiles {
    let spool: String?
    let events: String?
    let raw: String?

    init(target: LegacySessionImporter.Target) {
        spool = target.spoolPath
        events = target.eventStorePath
        raw = target.rawArchivePath
    }
}

// MARK: - Copying

/// One column as `PRAGMA table_info` describes it.
private struct ColumnInfo {
    let name: String
    let type: String
    let primaryKeyIndex: Int
}

/// The SQL behind the copy. Runs on the target's write connection with the
/// source and target files attached: the main database inside the caller's
/// transaction, the attached stores in batches that open their own.
private struct TableCopier {
    let conn: Database
    let tag: String
    let batchRows: Int
    let batchCommitted: (String) throws -> Void

    private var map: String { "main.\(LegacySessionImporter.mapTable)" }

    // MARK: Main database

    func copyMain(into store: inout LegacyImportReport.Store, sourcePrefix: String, targetPrefix: String) throws {
        let sourceTables = try tables(in: "src_main")
        let targetTables = Set(try tables(in: "main"))
        // Parents first, for readability of the counts; foreign keys are deferred.
        let ordered = sourceTables.sorted { lhs, rhs in
            let rank = ["sessions": 0, "event_log": 1]
            return (rank[lhs] ?? 2, lhs) < (rank[rhs] ?? 2, rhs)
        }
        for table in ordered {
            if table == "settings" {
                store.inserted["settings"] = try copyBillingSettings(from: sourcePrefix, to: targetPrefix)
                continue
            }
            if let reason = LegacySessionImporter.excludedMainTables[table] {
                store.skippedTables[table] = reason
                continue
            }
            guard targetTables.contains(table) else {
                store.skippedTables[table] = "not in the target's schema"
                continue
            }
            let plan = try columnPlan(table: table, source: "src_main", target: "main")
            if !plan.sourceOnly.isEmpty { store.columnsNotCopied[table] = plan.sourceOnly }
            let count: Int
            switch table {
            case "sessions":
                count = try insertOrIgnore(table, from: "src_main", to: "main", plan: plan)
            case "event_log":
                count = try copyEventLog(plan: plan)
            case "rate_limit_snapshots":
                count = try copySnapshots(plan: plan)
            default:
                if plan.rowIdColumn != nil {
                    count = try copyByRowMap(
                        table, from: "src_main", to: "main", mapName: table, plan: plan, limit: nil
                    ).inserted
                } else {
                    count = try insertOrIgnore(table, from: "src_main", to: "main", plan: plan)
                }
            }
            store.inserted[table] = count
        }
    }

    /// Row by row, because each row's target id is what its children need.
    private func copyEventLog(plan: ColumnPlan) throws -> Int {
        let ids = try Int64.fetchAll(conn, sql: """
            SELECT s.id FROM src_main.event_log s
            WHERE \(notMapped("event_log", sourceId: "s.id")) ORDER BY s.id
            """)
        let columns = plan.copied.map(quoted).joined(separator: ", ")
        let insert = try conn.makeStatement(sql: """
            INSERT OR IGNORE INTO main.event_log (\(columns))
            SELECT \(columns) FROM src_main.event_log WHERE id = ?
            """)
        let record = try conn.makeStatement(sql: """
            INSERT INTO \(map) (source, table_name, source_id, target_id) VALUES (?, 'event_log', ?, ?)
            """)
        var inserted = 0
        for id in ids {
            try insert.execute(arguments: [id])
            // Ignored means the target already held this event (its message id):
            // recorded with no target id, so its children are not copied either.
            let targetId: Int64? = conn.changesCount > 0 ? conn.lastInsertedRowID : nil
            if targetId != nil { inserted += 1 }
            try record.execute(arguments: [tag, id, targetId])
        }
        return inserted
    }

    /// Keyed by `timestamp` and `account_email`, the snapshot's identity.
    private func copySnapshots(plan: ColumnPlan) throws -> Int {
        let account = plan.sourceColumns.contains("account_email") ? "s.account_email" : "''"
        let columns = plan.copied.map(quoted).joined(separator: ", ")
        let values = plan.copied.map { "s.\(quoted($0))" }.joined(separator: ", ")
        try conn.execute(sql: """
            INSERT INTO main.rate_limit_snapshots (\(columns))
            SELECT \(values) FROM src_main.rate_limit_snapshots s
            WHERE NOT EXISTS (
                SELECT 1 FROM main.rate_limit_snapshots t
                WHERE t.timestamp = s.timestamp AND t.account_email IS \(account))
            ORDER BY s.id
            """)
        return conn.changesCount
    }

    private func copyBillingSettings(from sourcePrefix: String, to targetPrefix: String) throws -> Int {
        let length = sourcePrefix.count
        try conn.execute(sql: """
            INSERT OR IGNORE INTO main.settings (key, value)
            SELECT ? || substr(key, ?), value FROM src_main.settings
            WHERE substr(key, 1, ?) = ?
            """, arguments: [targetPrefix, length + 1, length, sourcePrefix])
        return conn.changesCount
    }

    // MARK: Event store and archive

    /// Every shared table, `INSERT OR IGNORE` on its natural key, in batches;
    /// with `rawRemap`, `raw_ref` is rewritten to the target archive's row id.
    func copyStore(from source: String, to target: String, into store: inout LegacyImportReport.Store,
                   rawRemap: Bool) throws {
        let targetTables = Set(try tables(in: target))
        for table in try tables(in: source) {
            if let reason = LegacySessionImporter.excludedStoreTables[table] {
                store.skippedTables[table] = reason
                continue
            }
            guard targetTables.contains(table) else {
                store.skippedTables[table] = "not in the target's schema"
                continue
            }
            let plan = try columnPlan(table: table, source: source, target: target)
            if !plan.sourceOnly.isEmpty { store.columnsNotCopied[table] = plan.sourceOnly }
            // Counted as each batch commits, so a failure part way reports
            // what the committed batches inserted.
            store.inserted[table] = 0
            try insertOrIgnoreInBatches(
                table, from: source, to: target, plan: plan, rawRemap: rawRemap && plan.copied.contains("raw_ref"),
                inserted: &store.inserted[table, default: 0])
        }
    }

    /// `insertOrIgnore` over the source's rowid ranges of at most `batchRows`
    /// rows, each range its own committed transaction. A table without a rowid
    /// is copied in one. `inserted` grows by each batch's rows once that batch
    /// has committed, never before.
    private func insertOrIgnoreInBatches(_ table: String, from source: String, to target: String,
                                         plan: ColumnPlan, rawRemap: Bool, inserted: inout Int) throws {
        guard try hasRowId(table, in: source) else {
            var count = 0
            try conn.inTransaction {
                count = try insertOrIgnore(table, from: source, to: target, plan: plan, rawRemap: rawRemap)
                return .commit
            }
            inserted += count
            try batchCommitted(target)
            return
        }
        var after = Int64.min
        while true {
            var upper: Int64?
            var count = 0
            try conn.inTransaction {
                upper = try Int64.fetchOne(conn, sql: """
                    SELECT MAX(rowid) FROM (
                        SELECT rowid FROM \(quoted(source)).\(quoted(table)) WHERE rowid > ? ORDER BY rowid LIMIT ?)
                    """, arguments: [after, batchRows])
                if let upper {
                    count = try insertOrIgnore(
                        table, from: source, to: target, plan: plan, rawRemap: rawRemap, rowIds: (after, upper))
                }
                return .commit
            }
            guard let upper else { return }
            inserted += count
            try batchCommitted(target)
            after = upper
        }
    }

    // MARK: Spool

    /// The spool's rows have only a row id, so they are tracked in the map
    /// under `ingest.db/spooled_event`.
    func copySpool(into store: inout LegacyImportReport.Store) throws {
        let table = "spooled_event"
        guard try tables(in: "src_spool").contains(table) else { return }
        guard try tables(in: "dst_spool").contains(table) else {
            store.skippedTables[table] = "not in the target's schema"
            return
        }
        let plan = try columnPlan(table: table, source: "src_spool", target: "dst_spool")
        if !plan.sourceOnly.isEmpty { store.columnsNotCopied[table] = plan.sourceOnly }
        // Batches of not-yet-recorded rows, each copied and recorded in its
        // own transaction, until a pass finds none.
        // Counted as each batch commits, so a failure part way reports what
        // the committed batches inserted.
        store.inserted[table] = 0
        while true {
            var selected = 0
            var inserted = 0
            try conn.inTransaction {
                let pass = try copyByRowMap(
                    table, from: "src_spool", to: "dst_spool", mapName: "\(IngestSpool.defaultDBName)/\(table)",
                    plan: plan, limit: batchRows)
                inserted = pass.inserted
                selected = pass.selected
                return .commit
            }
            guard selected > 0 else { break }
            store.inserted[table, default: 0] += inserted
            try batchCommitted("dst_spool")
        }
    }

    // MARK: Strategies

    /// Rows with a natural key: the target's unique constraints decide. With
    /// `rowIds`, only source rows whose rowid is above the first and at most
    /// the second.
    private func insertOrIgnore(_ table: String, from source: String, to target: String, plan: ColumnPlan,
                                rawRemap: Bool = false, rowIds: (after: Int64, through: Int64)? = nil) throws -> Int {
        let columns = plan.copied.map(quoted).joined(separator: ", ")
        var values: [String] = []
        var filters: [String] = []
        for column in plan.copied {
            if rawRemap && column == "raw_ref" {
                let expr = rawRefExpression(source: source)
                values.append(expr)
                filters.append("\(expr) IS NOT NULL")
            } else {
                values.append("s.\(quoted(column))")
            }
        }
        if let rowIds {
            filters.append("s.rowid > \(rowIds.after) AND s.rowid <= \(rowIds.through)")
        }
        let order = plan.rowIdColumn.map { " ORDER BY s.\(quoted($0))" } ?? ""
        let whereClause = filters.isEmpty ? "" : " WHERE " + filters.joined(separator: " AND ")
        try conn.execute(sql: """
            INSERT OR IGNORE INTO \(quoted(target)).\(quoted(table)) (\(columns))
            SELECT \(values.joined(separator: ", ")) FROM \(quoted(source)).\(quoted(table)) s\(whereClause)\(order)
            """)
        return conn.changesCount
    }

    /// Rows with only a row id: copied once per source tag, recorded in the
    /// map. An `event_log_id` is rewritten to its parent's target id, and a row
    /// whose parent was not copied is left out (and left unrecorded, so it is
    /// looked at again if its parent ever is). With `limit`, one pass takes at
    /// most that many rows, lowest row ids first; `selected` is how many it
    /// took, so a caller repeats until a pass takes none.
    private func copyByRowMap(_ table: String, from source: String, to target: String, mapName: String,
                              plan: ColumnPlan, limit: Int?) throws -> (inserted: Int, selected: Int) {
        guard let rowId = plan.rowIdColumn else { return (0, 0) }
        let columns = plan.copied.map(quoted).joined(separator: ", ")
        var values: [String] = []
        var filters = [notMapped(mapName, sourceId: "s.\(quoted(rowId))")]
        for column in plan.copied {
            if column == "event_log_id" {
                let expr = eventLogExpression()
                values.append(expr)
                filters.append("(s.event_log_id IS NULL OR \(expr) IS NOT NULL)")
            } else {
                values.append("s.\(quoted(column))")
            }
        }
        let selection = "FROM \(quoted(source)).\(quoted(table)) s WHERE " + filters.joined(separator: " AND ")
        // The rows this pass takes, chosen once: copied, then recorded.
        try conn.execute(sql: "CREATE TEMP TABLE IF NOT EXISTS legacy_import_pending (source_id INTEGER PRIMARY KEY)")
        try conn.execute(sql: "DELETE FROM temp.legacy_import_pending")
        let bound = limit.map { " ORDER BY s.\(quoted(rowId)) LIMIT \($0)" } ?? ""
        try conn.execute(
            sql: "INSERT INTO temp.legacy_import_pending (source_id) SELECT s.\(quoted(rowId)) \(selection)\(bound)")
        let selected = conn.changesCount
        try conn.execute(sql: """
            INSERT OR IGNORE INTO \(quoted(target)).\(quoted(table)) (\(columns))
            SELECT \(values.joined(separator: ", ")) FROM \(quoted(source)).\(quoted(table)) s
            WHERE s.\(quoted(rowId)) IN (SELECT source_id FROM temp.legacy_import_pending)
            ORDER BY s.\(quoted(rowId))
            """)
        let inserted = conn.changesCount
        try conn.execute(sql: """
            INSERT INTO \(map) (source, table_name, source_id, target_id)
            SELECT ?, ?, source_id, NULL FROM temp.legacy_import_pending
            """, arguments: [tag, mapName])
        try conn.execute(sql: "DELETE FROM temp.legacy_import_pending")
        return (inserted, selected)
    }

    // MARK: SQL pieces

    private func notMapped(_ mapName: String, sourceId: String) -> String {
        "NOT EXISTS (SELECT 1 FROM \(map) m WHERE m.source = \(literal(tag)) "
            + "AND m.table_name = \(literal(mapName)) AND m.source_id = \(sourceId))"
    }

    private func eventLogExpression() -> String {
        "(SELECT m.target_id FROM \(map) m WHERE m.source = \(literal(tag)) "
            + "AND m.table_name = 'event_log' AND m.source_id = s.event_log_id)"
    }

    private func rawRefExpression(source: String) -> String {
        "(SELECT t.id FROM dst_raw.raw_record t WHERE t.dedup_key = "
            + "(SELECT r.dedup_key FROM src_raw.raw_record r WHERE r.id = s.raw_ref))"
    }

    // MARK: Schema

    private func tables(in schema: String) throws -> [String] {
        try String.fetchAll(conn, sql: """
            SELECT name FROM \(quoted(schema)).sqlite_master
            WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name
            """)
    }

    /// False for a `WITHOUT ROWID` table, which has no rowid to batch by.
    private func hasRowId(_ table: String, in schema: String) throws -> Bool {
        let sql = try String.fetchOne(conn, sql: """
            SELECT sql FROM \(quoted(schema)).sqlite_master WHERE type = 'table' AND name = ?
            """, arguments: [table]) ?? ""
        return !sql.uppercased().contains("WITHOUT ROWID")
    }

    private func columns(of table: String, in schema: String) throws -> [ColumnInfo] {
        try Row.fetchAll(conn, sql: "PRAGMA \(quoted(schema)).table_info(\(quoted(table)))").map { row in
            ColumnInfo(name: row["name"], type: (row["type"] as String? ?? "").uppercased(), primaryKeyIndex: row["pk"])
        }
    }

    /// The columns both sides have, minus a row-id primary key (never copied).
    private func columnPlan(table: String, source: String, target: String) throws -> ColumnPlan {
        let sourceColumns = try columns(of: table, in: source)
        let targetColumns = try columns(of: table, in: target)
        let targetNames = Set(targetColumns.map(\.name))
        let keys = targetColumns.filter { $0.primaryKeyIndex > 0 }
        let rowId = keys.count == 1 && keys[0].type == "INTEGER" ? keys[0].name : nil
        let shared = sourceColumns.map(\.name).filter { targetNames.contains($0) && $0 != rowId }
        return ColumnPlan(
            copied: shared,
            sourceColumns: Set(sourceColumns.map(\.name)),
            sourceOnly: sourceColumns.map(\.name).filter { !targetNames.contains($0) },
            rowIdColumn: rowId
        )
    }
}

private struct ColumnPlan {
    /// Copied in this order.
    let copied: [String]
    let sourceColumns: Set<String>
    /// The source has them and the target does not; their values are dropped.
    let sourceOnly: [String]
    /// The target's `INTEGER PRIMARY KEY`, when it has one.
    let rowIdColumn: String?
}

private func quoted(_ identifier: String) -> String {
    "\"" + identifier.replacingOccurrences(of: "\"", with: "\"\"") + "\""
}

private func literal(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "''") + "'"
}

// MARK: - Report

/// What one import inserted, per store and per table. `description` is the
/// JSON `adhd import-legacy` prints.
public struct LegacyImportReport: Codable, Sendable, Equatable, CustomStringConvertible {

    public enum Status: String, Codable, Sendable {
        /// Read and copied.
        case imported
        /// Not in the source directory.
        case missing
        /// In the source directory, but not copied (see `note`).
        case notImported = "not_imported"
        /// Copying it failed (`note` says why); `inserted` is what its
        /// committed batches inserted before the failure.
        case failed
    }

    public struct Store: Codable, Sendable, Equatable {
        /// The file's name in the source directory.
        public let file: String
        public var status: Status = .missing
        public var note: String?
        /// Rows inserted, by table. A table copied with nothing new is 0.
        public var inserted: [String: Int] = [:]
        /// Tables left out, with why.
        public var skippedTables: [String: String] = [:]
        /// Source columns the target does not have, by table.
        public var columnsNotCopied: [String: [String]] = [:]

        public init(file: String) {
            self.file = file
        }

        public var totalInserted: Int { inserted.values.reduce(0, +) }
    }

    public let source: LegacySessionImporter.SourceKind
    public let directory: String
    public var stores: [Store] = []

    public init(source: LegacySessionImporter.SourceKind, directory: String) {
        self.source = source
        self.directory = directory
    }

    /// Every row inserted, across the stores.
    public var totalInserted: Int { stores.map(\.totalInserted).reduce(0, +) }

    /// The store named `file`, if the import looked at it.
    public func store(_ file: String) -> Store? {
        stores.first { $0.file == file }
    }

    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(self), let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }
}
#endif
