import Foundation
import GRDB

public enum EventStoreMode: Sendable { case live, bulk }

public enum EventStoreError: Error, Equatable {
    /// `beginBulkLoad` was called while a live drainer writes to this store: dropping
    /// the indexes under it would stall every live query.
    case liveWritersAttached(count: Int)
    /// A drainer tried to attach while a bulk load (a replay) holds the store.
    case bulkLoadInProgress
}

public struct EventStoreCounts: Sendable, Equatable {
    public let sessions: Int
    public let events: Int
    public let turns: Int
    public let messages: Int

    public init(sessions: Int, events: Int, turns: Int, messages: Int) {
        self.sessions = sessions
        self.events = events
        self.turns = turns
        self.messages = messages
    }
}

/// The trimmable, queryable store (`events.db`). It is rebuilt from a raw archive
/// by replay, so every write is idempotent and the result never depends on the
/// order records arrive in.
///
/// **One instance per file, shared by every provider.** events.db has a single
/// writer only because every drainer (and any replay) goes through the same
/// `EventStore`. Two instances on one file contend for SQLite's write lock (a 5 s
/// busy timeout, then failed passes), and the live-writer check that keeps a bulk
/// load away from live drainers works per instance.
///
/// Durability: `synchronous=FULL`, so a committed `write` survives power loss
/// before the drainer completes the spool record (see `PipelineDrainer`).
public final class EventStore: @unchecked Sendable {
    public static let fileName = "events.db"

    /// The deadline for operations whose cost grows with the whole file: opening
    /// (which may finish an interrupted index rebuild), `beginBulkLoad`,
    /// `endBulkLoad` and each replay chunk. Effectively none.
    public static let bulkDeadline: Duration = .seconds(24 * 60 * 60)

    /// Internal so the store's extensions in other files (`EventStore+Trim`) reach it.
    let pool: BoundedDatabase

    /// The file this store opened.
    public let path: String

    private let stateLock = NSLock()
    private var liveWriters = 0
    private var bulkActive = false
    private var trimBatchCarry: Int?

    /// The batch size the last trim ended on, after shrinking on the write
    /// deadline or growing back; the next trim starts from it, not its full
    /// batch, so a size the disk could not take is not retried every pass.
    var carriedTrimBatch: Int? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return trimBatchCarry
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            trimBatchCarry = newValue
        }
    }

    private var vacuumStepCarry: Int?

    /// The vacuum step size the last incremental vacuum ended on; the next one
    /// starts from it, so a step the disk could not finish inside the write
    /// deadline is not rolled back again at the start of every pass.
    var carriedVacuumStep: Int? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return vacuumStepCarry
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            vacuumStepCarry = newValue
        }
    }

    private static let indexes: [(name: String, sql: String)] = [
        ("events_session_time", "CREATE INDEX IF NOT EXISTS events_session_time ON events(provider, session_id, time)"),
        ("events_time", "CREATE INDEX IF NOT EXISTS events_time ON events(time)"),
        // The insights and rollup readers: one hook type over a time range.
        ("events_type_time",
         "CREATE INDEX IF NOT EXISTS events_type_time ON events(provider, provider_type, time)"),
        ("turns_time", "CREATE INDEX IF NOT EXISTS turns_time ON turns(time)"),
        ("turns_session", "CREATE INDEX IF NOT EXISTS turns_session ON turns(provider, session_id, time)"),
        ("messages_session_time",
         "CREATE INDEX IF NOT EXISTS messages_session_time ON messages(provider, session_id, time)"),
        // The Conversations feed's merged read: every session's messages newest first.
        ("messages_time", "CREATE INDEX IF NOT EXISTS messages_time ON messages(provider, time)"),
        // The trim's last-seen test (`EventStore.lastSeenBefore`, the same expression
        // word for word): only the sessions last seen before the cutoff are read.
        ("sessions_last_seen",
         "CREATE INDEX IF NOT EXISTS sessions_last_seen ON sessions(MAX(COALESCE(ended_at, as_of), as_of))"),
        // A PostToolUse finding its PreToolUse by tool_use_id. Partial on
        // json_valid(attrs) so the build never fails on a malformed row; a reader
        // must repeat that predicate and the exact expression for the planner to
        // pick it (see `claudeToolDurationMs`).
        ("events_tool_use_id",
         "CREATE INDEX IF NOT EXISTS events_tool_use_id "
            + "ON events(provider, json_extract(attrs,'$.tool_use_id')) WHERE json_valid(attrs)")
    ]

    private static let sessionScalarFields = ["cwd", "project", "account", "model", "title", "status"]
    private static let bulkLoadKey = "bulk_load"

    /// Opening runs only `CREATE ... IF NOT EXISTS`, so on a healthy file it does no
    /// index work. A store left in bulk-load state by a crash (the `bulk_load` flag
    /// in `store_meta`) has its indexes rebuilt here and the flag cleared, under
    /// `bulkDeadline`; ``recoveredBulkLoad`` then reports it.
    public init(path: String) throws {
        self.path = path
        let pool = try BoundedDatabase(
            path: path, readers: 3,
            readDeadline: .seconds(30), writeDeadline: .seconds(60),
            prepare: { conn in
                // Runs before the journal mode is set, so on a new file it lands
                // before page 1 exists; on an existing file it is a no-op. Only the
                // writer may set it: SQLite refuses it on the pool's read-only
                // reader connections ("attempt to write a readonly database").
                if !conn.configuration.readonly {
                    try conn.execute(sql: "PRAGMA auto_vacuum = INCREMENTAL")
                }
                try conn.execute(sql: "PRAGMA synchronous=FULL")
            }
        )
        self.pool = pool
        self.recoveredBulkLoad = try pool.write(deadline: Self.bulkDeadline) { conn in
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS sessions (
                    provider TEXT NOT NULL, session_id TEXT NOT NULL,
                    cwd TEXT, project TEXT, account TEXT, model TEXT, title TEXT, status TEXT,
                    started_at REAL, ended_at REAL, as_of REAL NOT NULL, attrs TEXT NOT NULL DEFAULT '{}',
                    field_as_of TEXT NOT NULL DEFAULT '{}',
                    PRIMARY KEY (provider, session_id)) WITHOUT ROWID
                """)
            // AUTOINCREMENT: an id is never handed out twice, even after the
            // highest rows are trimmed, so a reader's "events after id N"
            // cursor can never skip a row written later.
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, session_id TEXT NOT NULL,
                    kind TEXT NOT NULL, provider_type TEXT NOT NULL, time REAL NOT NULL,
                    cwd TEXT, tool_name TEXT, summary TEXT, attrs TEXT NOT NULL DEFAULT '{}',
                    raw_ref INTEGER NOT NULL,
                    UNIQUE (provider, dedup_key))
                """)
            // AUTOINCREMENT for the same reason as `events`: the usage recount
            // walks "turns after id N" and the trim deletes only turns at or
            // below that cursor, so an id freed by trimming the newest-id rows
            // must never be handed to a later turn.
            try conn.execute(sql: Self.turnsTableSQL("turns"))
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, uuid TEXT NOT NULL, parent_uuid TEXT,
                    session_id TEXT NOT NULL, role TEXT NOT NULL, time REAL NOT NULL, is_sidechain INTEGER NOT NULL,
                    text TEXT NOT NULL, attrs TEXT NOT NULL DEFAULT '{}', raw_ref INTEGER NOT NULL,
                    UNIQUE (provider, session_id, uuid))
                """)
            try conn.execute(sql: "CREATE TABLE IF NOT EXISTS store_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
            // What `trim` deleted from `turns`, kept so a session's totals survive it:
            // per (provider, session, model) sums of the trimmed turns, and the key
            // of every trimmed turn, so a redelivered one is never stored (and so
            // never counted) twice. A key's `folded` is what its turn added to the
            // sums (NULL on a key recorded before it was kept), so a later
            // observation of the turn corrects them. See `EventStore+Trim.swift`.
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS trimmed_turns (
                    provider TEXT NOT NULL, session_id TEXT NOT NULL, model TEXT NOT NULL,
                    turn_count INTEGER NOT NULL, input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
                    cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
                    cache_write_1h_tokens INTEGER NOT NULL, first_time REAL, last_time REAL,
                    PRIMARY KEY (provider, session_id, model)) WITHOUT ROWID
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS trimmed_turn_keys (
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, folded TEXT,
                    PRIMARY KEY (provider, dedup_key)) WITHOUT ROWID
                """)
            let keyColumns = try String.fetchAll(conn, sql: "SELECT name FROM pragma_table_info('trimmed_turn_keys')")
            if !keyColumns.contains("folded") {
                try conn.execute(sql: "ALTER TABLE trimmed_turn_keys ADD COLUMN folded TEXT")
            }
            // After `trimmed_turn_keys` exists: the upgrade seeds its sequence
            // from the keys the trim recorded.
            try Self.upgradeTurnsToAutoincrement(conn)
            // Archive records a checkpointed replay could not normalize, kept with
            // its cursor so a resumed replay still reports them. See `ReplayCheckpoint`.
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS replay_failures (
                    provider TEXT NOT NULL, raw_id INTEGER NOT NULL, error TEXT NOT NULL,
                    PRIMARY KEY (provider, raw_id)) WITHOUT ROWID
                """)
            let leftOver = try String.fetchOne(
                conn, sql: "SELECT value FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey]) != nil
            // On a new file this creates the indexes; on a healthy one it is a
            // no-op; after a crash mid-bulk-load it is the rebuild.
            for index in Self.indexes { try conn.execute(sql: index.sql) }
            try conn.execute(sql: "DELETE FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey])
            return leftOver
        }
    }

    /// True when this open found the file still in bulk load, left by a replay
    /// that was killed or crashed, and rebuilt its indexes before returning.
    public let recoveredBulkLoad: Bool

    /// `turns`' definition under `name`.
    private static func turnsTableSQL(_ name: String) -> String {
        """
        CREATE TABLE IF NOT EXISTS \(name) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            provider TEXT NOT NULL, dedup_key TEXT NOT NULL, session_id TEXT NOT NULL, time REAL NOT NULL,
            model TEXT, account TEXT, agent TEXT, tool_name TEXT,
            input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
            cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
            cost_usd REAL, raw_ref INTEGER NOT NULL,
            as_of REAL NOT NULL, attrs TEXT NOT NULL DEFAULT '{}',
            field_as_of TEXT NOT NULL DEFAULT '{}',
            UNIQUE (provider, dedup_key))
        """
    }

    /// Rebuilds a `turns` table made before it was declared AUTOINCREMENT
    /// (SQLite cannot add it in place), inside the opening transaction: every
    /// row is copied with its id, the copy is counted, and only then does the
    /// old table go. The indexes are recreated by the caller's index loop.
    ///
    /// The old table handed out `MAX(id) + 1`, so ids freed by a trim may
    /// already have been seen by a cursor. The sequence is seeded at the most
    /// any id can have reached: one id per row ever inserted, which is the
    /// rows held plus the rows the trim deleted (each recorded once in
    /// `trimmed_turn_keys`, and a trimmed key is never stored again). Every
    /// later turn gets an id above anything a cursor taken on this file holds.
    static func upgradeTurnsToAutoincrement(_ conn: Database) throws {
        let sql = try String.fetchOne(
            conn, sql: "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'turns'") ?? ""
        guard !sql.uppercased().contains("AUTOINCREMENT") else { return }
        let columns = "id, provider, dedup_key, session_id, time, model, account, agent, tool_name, "
            + "input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, raw_ref, "
            + "as_of, attrs, field_as_of"
        try conn.execute(sql: "DROP TABLE IF EXISTS turns_autoincrement")
        try conn.execute(sql: turnsTableSQL("turns_autoincrement"))
        try conn.execute(sql: "INSERT INTO turns_autoincrement(\(columns)) SELECT \(columns) FROM turns")
        let held = try Int64.fetchOne(conn, sql: "SELECT COUNT(*) FROM turns") ?? 0
        let copied = try Int64.fetchOne(conn, sql: "SELECT COUNT(*) FROM turns_autoincrement") ?? 0
        guard held == copied else {
            throw DatabaseError(message: "turns upgrade copied \(copied) of \(held) rows")
        }
        let maxId = try Int64.fetchOne(conn, sql: "SELECT COALESCE(MAX(id), 0) FROM turns") ?? 0
        let trimmed = try Int64.fetchOne(conn, sql: "SELECT COUNT(*) FROM trimmed_turn_keys") ?? 0
        let seed = max(maxId, held + trimmed)
        try conn.execute(sql: "DROP TABLE turns")
        try conn.execute(sql: "ALTER TABLE turns_autoincrement RENAME TO turns")
        try conn.execute(sql: "DELETE FROM sqlite_sequence WHERE name IN ('turns', 'turns_autoincrement')")
        try conn.execute(sql: "INSERT INTO sqlite_sequence(name, seq) VALUES ('turns', ?)", arguments: [seed])
    }

    // MARK: - Live writers

    /// A drainer registers while it holds the store, so a replay cannot drop the
    /// indexes under it.
    func attachLiveWriter() throws {
        stateLock.lock()
        defer { stateLock.unlock() }
        if bulkActive { throw EventStoreError.bulkLoadInProgress }
        liveWriters += 1
    }

    func detachLiveWriter() {
        stateLock.lock()
        defer { stateLock.unlock() }
        liveWriters = max(0, liveWriters - 1)
    }

    // MARK: - Writing

    /// One transaction; safe to repeat and to apply in any order. Returns what the
    /// write changed: events and messages actually inserted (a redelivery inserts
    /// nothing), and turns and sessions whose stored row changed, as merged.
    ///
    /// `checkpoint`, when given, commits in the same transaction: its cursor goes to
    /// `store_meta` and its failures to `replay_failures`, so a replay's position
    /// and its failed records can never disagree with the rows it wrote.
    @discardableResult
    public func write(_ batch: NormalizedBatch, provider: String, deadline: Duration? = nil,
                      checkpoint: ReplayCheckpoint? = nil) throws -> NormalizedBatch {
        try pool.write(deadline: deadline) { conn in
            if let checkpoint { try Self.commit(checkpoint, provider: provider, conn) }
            var changed = NormalizedBatch()
            changed.events = try batch.events.filter { try Self.insert($0, provider: provider, conn) }
            changed.messages = try batch.messages.filter { try Self.insert($0, provider: provider, conn) }
            for group in Self.grouped(batch.turns, by: \.dedupKey) {
                if let turn = try Self.merge(turns: group, provider: provider, conn) { changed.turns.append(turn) }
            }
            for group in Self.grouped(batch.sessions, by: \.sessionID) {
                if let session = try Self.merge(sessions: group, provider: provider, conn) {
                    changed.sessions.append(session)
                }
            }
            return changed
        }
    }

    /// Bulk mode: set the `bulk_load` flag and drop the secondary indexes in one
    /// transaction, write in large transactions, then call `endBulkLoad`. Refused
    /// while a live drainer is attached.
    public func beginBulkLoad() throws {
        stateLock.lock()
        if liveWriters > 0 {
            let count = liveWriters
            stateLock.unlock()
            throw EventStoreError.liveWritersAttached(count: count)
        }
        bulkActive = true
        stateLock.unlock()
        do {
            try pool.write(deadline: Self.bulkDeadline) { conn in
                try conn.execute(
                    sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES(?, '1')", arguments: [Self.bulkLoadKey])
                for index in Self.indexes { try conn.execute(sql: "DROP INDEX IF EXISTS \(index.name)") }
            }
        } catch {
            setBulkActive(false)
            throw error
        }
    }

    /// Rebuilds the indexes and clears the flag. Safe to call even when
    /// `beginBulkLoad` never ran. Ends the in-process bulk window even when the
    /// rebuild throws, so drainers can attach again; the on-disk flag then stays
    /// set and the next open finishes the rebuild.
    public func endBulkLoad() throws {
        defer { setBulkActive(false) }
        try pool.write(deadline: Self.bulkDeadline) { conn in
            for index in Self.indexes { try conn.execute(sql: index.sql) }
            try conn.execute(sql: "DELETE FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey])
        }
    }

    private func setBulkActive(_ value: Bool) {
        stateLock.lock()
        bulkActive = value
        stateLock.unlock()
    }

    // MARK: - Reading

    /// True while the file carries the `bulk_load` flag.
    public func isInBulkLoad() throws -> Bool {
        try pool.read { conn in
            try String.fetchOne(conn, sql: "SELECT value FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey])
                != nil
        }
    }

    /// The `store_meta` value under `key`, or nil when it is not set. Read on a
    /// short-lived read-only connection of its own, never one of the pool's
    /// readers: maintenance reads can hold all three for minutes, and status
    /// readers (`/storage`, the backfill's progress) must still answer. The
    /// store has this file open, so its `-wal` and `-shm` already exist and the
    /// open creates nothing; it sees every committed write, as a pool read does.
    public func metaValue(forKey key: String) throws -> String? {
        var configuration = Configuration()
        configuration.readonly = true
        let queue = try DatabaseQueue(path: path, configuration: configuration)
        defer { try? queue.close() }
        return try queue.read { conn in
            try String.fetchOne(conn, sql: "SELECT value FROM store_meta WHERE key = ?", arguments: [key])
        }
    }

    /// Sets the `store_meta` value under `key`, in its own transaction.
    public func setMetaValue(_ value: String, forKey key: String) throws {
        try pool.write { conn in
            try conn.execute(
                sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES(?, ?)", arguments: [key, value])
        }
    }

    // MARK: - Replay checkpoints

    private static func commit(_ checkpoint: ReplayCheckpoint, provider: String, _ conn: Database) throws {
        try conn.execute(
            sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES(?, ?)",
            arguments: [checkpoint.metaKey, String(checkpoint.lastID)])
        for (rawID, error) in checkpoint.failures {
            try conn.execute(
                sql: "INSERT OR REPLACE INTO replay_failures(provider, raw_id, error) VALUES(?, ?, ?)",
                arguments: [provider, rawID, error])
        }
    }

    /// Commits a checkpoint with no rows (a replay that wrote nothing, or a fresh start).
    public func commit(_ checkpoint: ReplayCheckpoint, provider: String) throws {
        try pool.write { conn in try Self.commit(checkpoint, provider: provider, conn) }
    }

    /// How many records a checkpointed replay of `provider` has failed, over every run.
    public func replayFailureCount(provider: String) throws -> Int {
        try pool.read { conn in
            try Int.fetchOne(
                conn, sql: "SELECT COUNT(*) FROM replay_failures WHERE provider = ?", arguments: [provider]) ?? 0
        }
    }

    /// The first `limit` failed records of `provider`, by ascending archive id.
    public func replayFailures(provider: String, limit: Int) throws -> [(rawID: Int64, error: String)] {
        try pool.read { conn in
            try Row.fetchAll(
                conn, sql: "SELECT raw_id, error FROM replay_failures WHERE provider = ? ORDER BY raw_id LIMIT ?",
                arguments: [provider, limit]
            ).map { (rawID: $0["raw_id"], error: $0["error"]) }
        }
    }

    /// Forgets every recorded failure of `provider`: a replay starting over from id 0.
    public func clearReplayFailures(provider: String) throws {
        try pool.write { conn in
            try conn.execute(sql: "DELETE FROM replay_failures WHERE provider = ?", arguments: [provider])
        }
    }

    /// The names of the secondary indexes that exist right now.
    public func indexNames() throws -> Set<String> {
        try pool.read { conn in
            Set(try String.fetchAll(
                conn, sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL"))
        }
    }

    public func counts() throws -> EventStoreCounts {
        try pool.read { conn in
            func count(_ table: String) throws -> Int {
                try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
            }
            return EventStoreCounts(
                sessions: try count("sessions"), events: try count("events"),
                turns: try count("turns"), messages: try count("messages"))
        }
    }

    /// Every row of every table as a sorted-keys JSON line, ordered by content key,
    /// without the integer `id`. Equal dumps mean equal content.
    ///
    /// `includingRawRef: false` also drops `raw_ref`, for comparing stores built from
    /// different archives: archive ids follow arrival order, and when several records
    /// feed one turn at the same `as_of`, which of them the row points back to is
    /// arbitrary. Stores replayed from the same archive compare with it included.
    public func canonicalDump(includingRawRef: Bool = true) throws -> [String] {
        let tables: [(name: String, order: String)] = [
            ("sessions", "provider, session_id"),
            ("events", "provider, dedup_key"),
            ("turns", "provider, dedup_key"),
            ("messages", "provider, session_id, uuid")
        ]
        return try pool.read { conn in
            var lines: [String] = []
            for table in tables {
                let rows = try Row.fetchAll(conn, sql: "SELECT * FROM \(table.name) ORDER BY \(table.order)")
                for row in rows {
                    var object: [String: NormalizedValue] = ["table": .string(table.name)]
                    for (column, value) in row where column != "id" && (includingRawRef || column != "raw_ref") {
                        switch value.storage {
                        case .null: object[column] = .null
                        case .int64(let int): object[column] = .number(Double(int))
                        case .double(let double): object[column] = .number(double)
                        case .string(let string): object[column] = .string(string)
                        case .blob(let data): object[column] = .string(data.base64EncodedString())
                        }
                    }
                    lines.append(try NormalizedValue.object(object).canonicalString())
                }
            }
            return lines
        }
    }

    // MARK: - Inserts

    private static func attrsText(_ attrs: [String: NormalizedValue]) throws -> String {
        try NormalizedValue.object(attrs).canonicalString()
    }

    /// Groups by key, keeping first-appearance order so the write order is stable.
    private static func grouped<T>(_ items: [T], by key: (T) -> String) -> [[T]] {
        var order: [String] = []
        var groups: [String: [T]] = [:]
        for item in items {
            let value = key(item)
            if groups[value] == nil { order.append(value) }
            groups[value, default: []].append(item)
        }
        return order.compactMap { groups[$0] }
    }

    /// True when a row was inserted.
    private static func insert(_ event: NormalizedEvent, provider: String, _ conn: Database) throws -> Bool {
        try conn.execute(sql: """
            INSERT INTO events(provider, dedup_key, session_id, kind, provider_type, time,
                               cwd, tool_name, summary, attrs, raw_ref)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, dedup_key) DO NOTHING
            """, arguments: [
                provider, event.dedupKey, event.sessionID, event.kind.rawValue, event.providerType,
                event.time.timeIntervalSince1970, event.cwd, event.toolName, event.summary,
                try attrsText(event.attrs), event.rawRef
            ])
        return conn.changesCount > 0
    }

    /// Messages are immutable: the first copy of `(provider, session_id, uuid)` stays.
    private static func insert(_ message: MessageRow, provider: String, _ conn: Database) throws -> Bool {
        try conn.execute(sql: """
            INSERT INTO messages(provider, dedup_key, uuid, parent_uuid, session_id, role, time, is_sidechain,
                                 text, attrs, raw_ref)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, session_id, uuid) DO NOTHING
            """, arguments: [
                provider, message.dedupKey, message.uuid, message.parentUUID, message.sessionID, message.role,
                message.time.timeIntervalSince1970, message.isSidechain ? 1 : 0, message.text,
                try attrsText(message.attrs), message.rawRef
            ])
        return conn.changesCount > 0
    }

    // MARK: - Per-field merge

    /// Fields that merge independently: each keeps the value offered with the
    /// greatest `as_of`. On an exact tie: two numbers keep the larger (so a token
    /// count of 10 beats 9), two strings the lexically larger UTF-8 text, anything
    /// else the lexically larger canonical JSON (and numerically equal numbers, such
    /// as 0 and -0, fall back to that too). The result is the same whatever order the
    /// offers arrive in. Attrs keys are `attrs.<key>`. Non-finite numbers never reach
    /// here in a conforming provider (`Normalizer`); if one does, it still ties
    /// deterministically, and the write then fails on encoding.
    struct MergedFields: Equatable {
        var values: [String: NormalizedValue] = [:]
        var times: [String: Double] = [:]

        mutating func offer(_ field: String, _ value: NormalizedValue?, asOf: Double) {
            guard let value else { return }
            if let oldAsOf = times[field], let current = values[field] {
                let wins = asOf > oldAsOf || (asOf == oldAsOf && Self.precedes(current, value))
                guard wins else { return }
            }
            times[field] = asOf
            values[field] = value
        }

        static func precedes(_ lhs: NormalizedValue, _ rhs: NormalizedValue) -> Bool {
            if case .string(let left) = lhs, case .string(let right) = rhs {
                return left.utf8.lexicographicallyPrecedes(right.utf8)
            }
            if case .number(let left) = lhs, case .number(let right) = rhs,
               left.isFinite, right.isFinite, left != right {
                return left < right
            }
            let left = tieText(lhs)
            let right = tieText(rhs)
            return left.utf8.lexicographicallyPrecedes(right.utf8)
        }

        /// The canonical JSON, or for a value JSON cannot encode (NaN, infinity) a
        /// stable description, so the tie-break stays a total order.
        private static func tieText(_ value: NormalizedValue) -> String {
            (try? value.canonicalString()) ?? "~" + String(describing: value)
        }

        func string(_ field: String) -> String? {
            if case .string(let value) = values[field] { return value }
            return nil
        }

        func number(_ field: String) -> Double? {
            if case .number(let value) = values[field] { return value }
            return nil
        }

        var attrs: [String: NormalizedValue] {
            var result: [String: NormalizedValue] = [:]
            for (field, value) in values where field.hasPrefix("attrs.") {
                result[String(field.dropFirst("attrs.".count))] = value
            }
            return result
        }

        mutating func offer(attrs: [String: NormalizedValue], asOf: Double) {
            for (key, value) in attrs { offer("attrs.\(key)", value, asOf: asOf) }
        }

        func attrsText() throws -> String { try EventStore.attrsText(attrs) }

        func timesText() throws -> String {
            try NormalizedValue.object(times.mapValues { .number($0) }).canonicalString()
        }

        /// Rebuilds the state of a stored row: `field_as_of` names every field that
        /// was ever set; scalars come from `columns`, attrs keys from `attrsText`.
        static func load(columns: [String: NormalizedValue], attrsText: String, timesText: String) throws -> Self {
            var fields = MergedFields()
            let decoder = JSONDecoder()
            var attrs: [String: NormalizedValue] = [:]
            if case .object(let object) = try decoder.decode(NormalizedValue.self, from: Data(attrsText.utf8)) {
                attrs = object
            }
            if case .object(let object) = try decoder.decode(NormalizedValue.self, from: Data(timesText.utf8)) {
                for (field, time) in object {
                    guard case .number(let asOf) = time else { continue }
                    let value: NormalizedValue? = field.hasPrefix("attrs.")
                        ? attrs[String(field.dropFirst("attrs.".count))]
                        : columns[field]
                    guard let value else { continue }
                    fields.times[field] = asOf
                    fields.values[field] = value
                }
            }
            return fields
        }
    }

    private static func column(_ row: Row, _ name: String) -> NormalizedValue? {
        let value: DatabaseValue = row[name]
        switch value.storage {
        case .null: return nil
        case .int64(let int): return .number(Double(int))
        case .double(let double): return .number(double)
        case .string(let string): return .string(string)
        case .blob(let data): return .string(data.base64EncodedString())
        }
    }

    // MARK: - Session merge

    private struct SessionState: Equatable {
        var fields = MergedFields()
        var startedAt: Double?
        var endedAt: Double?
        var asOf: Double
    }

    /// Folds every upsert of one session in the batch, then reads and writes the row
    /// once; returns the merged session when the row changed.
    private static func merge(sessions upserts: [SessionUpsert], provider: String, _ conn: Database) throws
        -> SessionUpsert? {
        guard let first = upserts.first else { return nil }
        let stored = try loadSession(provider: provider, sessionID: first.sessionID, conn)
        var state = stored ?? SessionState(asOf: first.asOf.timeIntervalSince1970)
        for upsert in upserts {
            let asOf = upsert.asOf.timeIntervalSince1970
            let incoming: [String: String?] = [
                "cwd": upsert.cwd, "project": upsert.project, "account": upsert.account,
                "model": upsert.model, "title": upsert.title, "status": upsert.status
            ]
            for field in sessionScalarFields {
                if let text = incoming[field] ?? nil { state.fields.offer(field, .string(text), asOf: asOf) }
            }
            state.fields.offer(attrs: upsert.attrs, asOf: asOf)
            if let started = upsert.startedAt?.timeIntervalSince1970 {
                state.startedAt = state.startedAt.map { min($0, started) } ?? started
            }
            if let ended = upsert.endedAt?.timeIntervalSince1970 {
                state.endedAt = state.endedAt.map { max($0, ended) } ?? ended
            }
            state.asOf = max(state.asOf, asOf)
        }
        if let stored, stored == state { return nil }

        let fields = state.fields
        try conn.execute(sql: """
            INSERT INTO sessions(provider, session_id, cwd, project, account, model, title, status,
                                 started_at, ended_at, as_of, attrs, field_as_of)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, session_id) DO UPDATE SET
                cwd = excluded.cwd, project = excluded.project, account = excluded.account,
                model = excluded.model, title = excluded.title, status = excluded.status,
                started_at = excluded.started_at, ended_at = excluded.ended_at,
                as_of = excluded.as_of, attrs = excluded.attrs, field_as_of = excluded.field_as_of
            """, arguments: [
                provider, first.sessionID, fields.string("cwd"), fields.string("project"),
                fields.string("account"), fields.string("model"), fields.string("title"),
                fields.string("status"), state.startedAt, state.endedAt, state.asOf,
                try fields.attrsText(), try fields.timesText()
            ])
        return SessionUpsert(
            sessionID: first.sessionID, asOf: Date(timeIntervalSince1970: state.asOf),
            cwd: fields.string("cwd"), project: fields.string("project"), account: fields.string("account"),
            model: fields.string("model"), title: fields.string("title"), status: fields.string("status"),
            startedAt: state.startedAt.map { Date(timeIntervalSince1970: $0) },
            endedAt: state.endedAt.map { Date(timeIntervalSince1970: $0) },
            attrs: fields.attrs)
    }

    private static func loadSession(provider: String, sessionID: String, _ conn: Database) throws -> SessionState? {
        guard let row = try Row.fetchOne(
            conn, sql: "SELECT * FROM sessions WHERE provider = ? AND session_id = ?",
            arguments: [provider, sessionID]
        ) else { return nil }
        var columns: [String: NormalizedValue] = [:]
        for field in sessionScalarFields { columns[field] = column(row, field) }
        var state = SessionState(asOf: row["as_of"])
        state.fields = try MergedFields.load(columns: columns, attrsText: row["attrs"], timesText: row["field_as_of"])
        state.startedAt = row["started_at"]
        state.endedAt = row["ended_at"]
        return state
    }

    // MARK: - Turn merge

    private static let turnFields = [
        "session_id", "time", "model", "account", "agent", "tool_name", "input_tokens", "output_tokens",
        "cache_read_tokens", "cache_write_tokens", "cost_usd", "raw_ref"
    ]

    private struct TurnState: Equatable {
        var fields = MergedFields()
        var asOf: Double
    }

    /// What `trimmed_turn_keys` holds for a turn the trim folded.
    private enum TrimmedTurn {
        /// The fields the fold read (``foldedTurnFields``), with their `as_of`.
        case folded(MergedFields)
        /// Folded before those fields were kept: nothing to correct against.
        case unrecorded
    }

    /// Folds every observation of one turn in the batch, reads and writes the row
    /// once, and returns the merged turn when the row changed.
    private static func merge(turns: [TurnRow], provider: String, _ conn: Database) throws -> TurnRow? {
        guard let first = turns.first else { return nil }
        let stored = try loadTurn(provider: provider, dedupKey: first.dedupKey, conn)
        // A turn the trim already folded into `trimmed_turns` (an old transcript
        // imported again, or a turn's later lines arriving after a trim folded
        // its first) is counted there; storing it again would count it twice.
        // What its new observations change is moved into the sums instead.
        if stored == nil, let trimmed = try trimmedTurn(provider: provider, dedupKey: first.dedupKey, conn) {
            if case .folded(let before) = trimmed {
                try refold(before, with: turns, provider: provider, dedupKey: first.dedupKey, conn)
            }
            return nil
        }
        var state = stored ?? TurnState(asOf: (first.asOf ?? first.time).timeIntervalSince1970)
        offer(turns, into: &state)
        if let stored, stored == state { return nil }

        let fields = state.fields
        func int(_ field: String) -> Int64 { Int64(fields.number(field) ?? 0) }
        try conn.execute(sql: """
            INSERT INTO turns(provider, dedup_key, session_id, time, model, account, agent, tool_name,
                              input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
                              cost_usd, raw_ref, as_of, attrs, field_as_of)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, dedup_key) DO UPDATE SET
                session_id = excluded.session_id, time = excluded.time, model = excluded.model,
                account = excluded.account, agent = excluded.agent, tool_name = excluded.tool_name,
                input_tokens = excluded.input_tokens, output_tokens = excluded.output_tokens,
                cache_read_tokens = excluded.cache_read_tokens, cache_write_tokens = excluded.cache_write_tokens,
                cost_usd = excluded.cost_usd, raw_ref = excluded.raw_ref, as_of = excluded.as_of,
                attrs = excluded.attrs, field_as_of = excluded.field_as_of
            """, arguments: [
                provider, first.dedupKey, fields.string("session_id") ?? first.sessionID,
                fields.number("time") ?? first.time.timeIntervalSince1970,
                fields.string("model"), fields.string("account"), fields.string("agent"), fields.string("tool_name"),
                int("input_tokens"), int("output_tokens"), int("cache_read_tokens"), int("cache_write_tokens"),
                fields.number("cost_usd"), int("raw_ref"), state.asOf,
                try fields.attrsText(), try fields.timesText()
            ])
        return TurnRow(
            dedupKey: first.dedupKey, sessionID: fields.string("session_id") ?? first.sessionID,
            time: Date(timeIntervalSince1970: fields.number("time") ?? first.time.timeIntervalSince1970),
            asOf: Date(timeIntervalSince1970: state.asOf), model: fields.string("model"),
            account: fields.string("account"), agent: fields.string("agent"), toolName: fields.string("tool_name"),
            inputTokens: Int(int("input_tokens")), outputTokens: Int(int("output_tokens")),
            cacheReadTokens: Int(int("cache_read_tokens")), cacheWriteTokens: Int(int("cache_write_tokens")),
            costUSD: fields.number("cost_usd"), attrs: fields.attrs, rawRef: int("raw_ref"))
    }

    /// Offers every observation of one turn to `state`.
    private static func offer(_ turns: [TurnRow], into state: inout TurnState) {
        for turn in turns {
            let asOf = (turn.asOf ?? turn.time).timeIntervalSince1970
            let offered: [(String, NormalizedValue?)] = [
                ("session_id", .string(turn.sessionID)),
                ("time", .number(turn.time.timeIntervalSince1970)),
                ("model", turn.model.map { .string($0) }),
                ("account", turn.account.map { .string($0) }),
                ("agent", turn.agent.map { .string($0) }),
                ("tool_name", turn.toolName.map { .string($0) }),
                ("input_tokens", .number(Double(turn.inputTokens))),
                ("output_tokens", .number(Double(turn.outputTokens))),
                ("cache_read_tokens", .number(Double(turn.cacheReadTokens))),
                ("cache_write_tokens", .number(Double(turn.cacheWriteTokens))),
                ("cost_usd", turn.costUSD.map { .number($0) }),
                ("raw_ref", .number(Double(turn.rawRef)))
            ]
            for (field, value) in offered { state.fields.offer(field, value, asOf: asOf) }
            state.fields.offer(attrs: turn.attrs, asOf: asOf)
            state.asOf = max(state.asOf, asOf)
        }
    }

    /// Offers a trimmed turn's new observations to what the fold read for it.
    /// When the folded fields change, the old contribution comes out of its
    /// (session, model) row of `trimmed_turns` and the new one goes in (so a
    /// changed model moves the turn between rows), and the key keeps the new
    /// fields. `first_time`/`last_time` only ever widen: a moved turn's old
    /// time stays in its old row's range.
    private static func refold(_ before: MergedFields, with turns: [TurnRow], provider: String,
                               dedupKey: String, _ conn: Database) throws {
        var state = TurnState(fields: before, asOf: 0)
        offer(turns, into: &state)
        let after = foldedFields(of: state.fields)
        guard after != before else { return }
        let old = FoldedTurn(before), new = FoldedTurn(after)
        if old != new {
            try add(old, sign: -1, provider: provider, conn)
            try add(new, sign: 1, provider: provider, conn)
        }
        try conn.execute(sql: "UPDATE trimmed_turn_keys SET folded = ? WHERE provider = ? AND dedup_key = ?",
                         arguments: [try foldedText(after), provider, dedupKey])
    }

    private static func trimmedTurn(provider: String, dedupKey: String, _ conn: Database) throws -> TrimmedTurn? {
        guard let row = try Row.fetchOne(conn, sql: """
            SELECT folded FROM trimmed_turn_keys WHERE provider = ? AND dedup_key = ?
            """, arguments: [provider, dedupKey]) else { return nil }
        guard let text: String = row["folded"] else { return .unrecorded }
        return .folded(try foldedFields(text))
    }

    private static func loadTurn(provider: String, dedupKey: String, _ conn: Database) throws -> TurnState? {
        guard let row = try Row.fetchOne(
            conn, sql: "SELECT * FROM turns WHERE provider = ? AND dedup_key = ?", arguments: [provider, dedupKey]
        ) else { return nil }
        var columns: [String: NormalizedValue] = [:]
        for field in turnFields { columns[field] = column(row, field) }
        var state = TurnState(asOf: row["as_of"])
        state.fields = try MergedFields.load(columns: columns, attrsText: row["attrs"], timesText: row["field_as_of"])
        return state
    }
}

// MARK: - Reading

extension EventStore {
    /// Runs `body` on a read-only reader connection, ejected after `deadline`
    /// (nil: the store's 30 s read deadline; a whole-store scan such as
    /// repricing passes a longer one). A write inside `body` throws ("attempt
    /// to write a readonly database"); writes go through
    /// ``write(_:provider:deadline:)``.
    public func read<T>(deadline: Duration? = nil, _ body: (Database) throws -> T) throws -> T {
        try pool.read(deadline: deadline, body)
    }
}
