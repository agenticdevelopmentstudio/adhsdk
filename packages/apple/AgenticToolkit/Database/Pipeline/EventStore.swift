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

    private let pool: BoundedDatabase

    private let stateLock = NSLock()
    private var liveWriters = 0
    private var bulkActive = false

    private static let indexes: [(name: String, sql: String)] = [
        ("events_session_time", "CREATE INDEX IF NOT EXISTS events_session_time ON events(provider, session_id, time)"),
        ("events_time", "CREATE INDEX IF NOT EXISTS events_time ON events(time)"),
        ("turns_time", "CREATE INDEX IF NOT EXISTS turns_time ON turns(time)"),
        ("turns_session", "CREATE INDEX IF NOT EXISTS turns_session ON turns(provider, session_id, time)"),
        ("messages_session_time",
         "CREATE INDEX IF NOT EXISTS messages_session_time ON messages(provider, session_id, time)")
    ]

    private static let sessionScalarFields = ["cwd", "project", "account", "model", "title", "status"]
    private static let bulkLoadKey = "bulk_load"

    /// Opening runs only `CREATE ... IF NOT EXISTS`, so on a healthy file it does no
    /// index work. A store left in bulk-load state by a crash (the `bulk_load` flag
    /// in `store_meta`) has its indexes rebuilt here and the flag cleared, under
    /// `bulkDeadline`.
    public init(path: String) throws {
        self.pool = try BoundedDatabase(
            path: path, readers: 3,
            readDeadline: .seconds(30), writeDeadline: .seconds(60),
            prepare: { conn in
                // Runs before the journal mode is set, so on a new file it lands
                // before page 1 exists; on an existing file it is a no-op.
                try conn.execute(sql: "PRAGMA auto_vacuum = INCREMENTAL")
                try conn.execute(sql: "PRAGMA synchronous=FULL")
            }
        )
        try pool.write(deadline: Self.bulkDeadline) { conn in
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS sessions (
                    provider TEXT NOT NULL, session_id TEXT NOT NULL,
                    cwd TEXT, project TEXT, account TEXT, model TEXT, title TEXT, status TEXT,
                    started_at REAL, ended_at REAL, as_of REAL NOT NULL, attrs TEXT NOT NULL DEFAULT '{}',
                    field_as_of TEXT NOT NULL DEFAULT '{}',
                    PRIMARY KEY (provider, session_id)) WITHOUT ROWID
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS events (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, session_id TEXT NOT NULL,
                    kind TEXT NOT NULL, provider_type TEXT NOT NULL, time REAL NOT NULL,
                    cwd TEXT, tool_name TEXT, summary TEXT, attrs TEXT NOT NULL DEFAULT '{}',
                    raw_ref INTEGER NOT NULL,
                    UNIQUE (provider, dedup_key))
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS turns (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, session_id TEXT NOT NULL, time REAL NOT NULL,
                    model TEXT, account TEXT, agent TEXT, tool_name TEXT,
                    input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
                    cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
                    cost_usd REAL, raw_ref INTEGER NOT NULL,
                    as_of REAL NOT NULL, attrs TEXT NOT NULL DEFAULT '{}',
                    field_as_of TEXT NOT NULL DEFAULT '{}',
                    UNIQUE (provider, dedup_key))
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, uuid TEXT NOT NULL, parent_uuid TEXT,
                    session_id TEXT NOT NULL, role TEXT NOT NULL, time REAL NOT NULL, is_sidechain INTEGER NOT NULL,
                    text TEXT NOT NULL, attrs TEXT NOT NULL DEFAULT '{}', raw_ref INTEGER NOT NULL,
                    UNIQUE (provider, session_id, uuid))
                """)
            try conn.execute(sql: "CREATE TABLE IF NOT EXISTS store_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
            // On a new file this creates the indexes; on a healthy one it is a
            // no-op; after a crash mid-bulk-load it is the rebuild.
            for index in Self.indexes { try conn.execute(sql: index.sql) }
            try conn.execute(sql: "DELETE FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey])
        }
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
    @discardableResult
    public func write(_ batch: NormalizedBatch, provider: String, deadline: Duration? = nil) throws -> NormalizedBatch {
        try pool.write(deadline: deadline) { conn in
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
    /// `beginBulkLoad` never ran.
    public func endBulkLoad() throws {
        try pool.write(deadline: Self.bulkDeadline) { conn in
            for index in Self.indexes { try conn.execute(sql: index.sql) }
            try conn.execute(sql: "DELETE FROM store_meta WHERE key = ?", arguments: [Self.bulkLoadKey])
        }
        setBulkActive(false)
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
    public func canonicalDump() throws -> [String] {
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
                    for (column, value) in row where column != "id" {
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
    /// greatest `as_of`; on an exact tie the lexically larger UTF-8 value wins
    /// (strings compare as text, anything else by its canonical JSON). The result is
    /// the same whatever order the offers arrive in. Attrs keys are `attrs.<key>`.
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
            let left = (try? lhs.canonicalString()) ?? ""
            let right = (try? rhs.canonicalString()) ?? ""
            return left.utf8.lexicographicallyPrecedes(right.utf8)
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

    /// Folds every observation of one turn in the batch, reads and writes the row
    /// once, and returns the merged turn when the row changed.
    private static func merge(turns: [TurnRow], provider: String, _ conn: Database) throws -> TurnRow? {
        guard let first = turns.first else { return nil }
        let stored = try loadTurn(provider: provider, dedupKey: first.dedupKey, conn)
        var state = stored ?? TurnState(asOf: (first.asOf ?? first.time).timeIntervalSince1970)
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
