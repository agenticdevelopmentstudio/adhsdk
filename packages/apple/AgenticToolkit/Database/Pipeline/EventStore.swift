import Foundation
import GRDB

public enum EventStoreMode: Sendable { case live, bulk }

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
public final class EventStore: @unchecked Sendable {
    public static let fileName = "events.db"

    private let pool: BoundedDatabase

    private static let indexes: [(name: String, sql: String)] = [
        ("events_session_time", "CREATE INDEX IF NOT EXISTS events_session_time ON events(provider, session_id, time)"),
        ("events_time", "CREATE INDEX IF NOT EXISTS events_time ON events(time)"),
        ("turns_time", "CREATE INDEX IF NOT EXISTS turns_time ON turns(time)"),
        ("turns_session", "CREATE INDEX IF NOT EXISTS turns_session ON turns(provider, session_id, time)"),
        ("messages_session_time",
         "CREATE INDEX IF NOT EXISTS messages_session_time ON messages(provider, session_id, time)")
    ]

    private static let scalarFields = ["cwd", "project", "account", "model", "title", "status"]

    public init(path: String) throws {
        self.pool = try BoundedDatabase(
            path: path, readers: 3,
            readDeadline: .seconds(30), writeDeadline: .seconds(60),
            prepare: { conn in
                // Runs before the journal mode is set, so on a new file it lands
                // before page 1 exists; on an existing file it is a no-op.
                try conn.execute(sql: "PRAGMA auto_vacuum = INCREMENTAL")
                try conn.execute(sql: "PRAGMA synchronous=NORMAL")
            }
        )
        try pool.write { conn in
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
                    UNIQUE (provider, dedup_key))
                """)
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS messages (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, uuid TEXT NOT NULL, parent_uuid TEXT, session_id TEXT NOT NULL,
                    role TEXT NOT NULL, time REAL NOT NULL, is_sidechain INTEGER NOT NULL,
                    text TEXT NOT NULL, attrs TEXT NOT NULL DEFAULT '{}', raw_ref INTEGER NOT NULL,
                    UNIQUE (provider, uuid))
                """)
            for index in Self.indexes { try conn.execute(sql: index.sql) }
        }
    }

    // MARK: - Writing

    /// One transaction; safe to repeat and to apply in any order.
    public func write(_ batch: NormalizedBatch, provider: String) throws {
        try pool.write { conn in
            for event in batch.events { try Self.insert(event, provider: provider, conn) }
            for turn in batch.turns { try Self.insert(turn, provider: provider, conn) }
            for message in batch.messages { try Self.insert(message, provider: provider, conn) }
            for upsert in batch.sessions { try Self.merge(upsert, provider: provider, conn) }
        }
    }

    /// Bulk mode: drop the secondary indexes, write in large transactions, then
    /// call `endBulkLoad` to rebuild them.
    public func beginBulkLoad() throws {
        try pool.write { conn in
            for index in Self.indexes { try conn.execute(sql: "DROP INDEX IF EXISTS \(index.name)") }
        }
    }

    /// Safe to call even when `beginBulkLoad` never ran.
    public func endBulkLoad() throws {
        try pool.write { conn in
            for index in Self.indexes { try conn.execute(sql: index.sql) }
        }
    }

    // MARK: - Reading

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
            ("messages", "provider, uuid")
        ]
        return try pool.read { conn in
            var lines: [String] = []
            for table in tables {
                let rows = try Row.fetchAll(conn, sql: "SELECT * FROM \(table.name) ORDER BY \(table.order)")
                for row in rows {
                    var object: [String: JSONValue] = ["table": .string(table.name)]
                    for (column, value) in row where column != "id" {
                        switch value.storage {
                        case .null: object[column] = .null
                        case .int64(let int): object[column] = .number(Double(int))
                        case .double(let double): object[column] = .number(double)
                        case .string(let string): object[column] = .string(string)
                        case .blob(let data): object[column] = .string(data.base64EncodedString())
                        }
                    }
                    lines.append(try JSONValue.object(object).canonicalString())
                }
            }
            return lines
        }
    }

    // MARK: - Inserts

    private static func attrsText(_ attrs: [String: JSONValue]) throws -> String {
        try JSONValue.object(attrs).canonicalString()
    }

    private static func insert(_ event: NormalizedEvent, provider: String, _ conn: Database) throws {
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
    }

    private static func insert(_ turn: TurnRow, provider: String, _ conn: Database) throws {
        try conn.execute(sql: """
            INSERT INTO turns(provider, dedup_key, session_id, time, model, account, agent, tool_name,
                              input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
                              cost_usd, raw_ref)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, dedup_key) DO NOTHING
            """, arguments: [
                provider, turn.dedupKey, turn.sessionID, turn.time.timeIntervalSince1970, turn.model,
                turn.account, turn.agent, turn.toolName, turn.inputTokens, turn.outputTokens,
                turn.cacheReadTokens, turn.cacheWriteTokens, turn.costUSD, turn.rawRef
            ])
    }

    private static func insert(_ message: MessageRow, provider: String, _ conn: Database) throws {
        try conn.execute(sql: """
            INSERT INTO messages(provider, uuid, parent_uuid, session_id, role, time, is_sidechain,
                                 text, attrs, raw_ref)
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(provider, uuid) DO NOTHING
            """, arguments: [
                provider, message.uuid, message.parentUUID, message.sessionID, message.role,
                message.time.timeIntervalSince1970, message.isSidechain ? 1 : 0, message.text,
                try attrsText(message.attrs), message.rawRef
            ])
    }

    // MARK: - Session merge

    /// The merged state of one session row. Every scalar and every attrs key keeps
    /// the `as_of` at which its current value was set, so each merges on its own.
    private struct SessionState {
        var scalars: [String: String] = [:]
        var attrs: [String: JSONValue] = [:]
        var fieldAsOf: [String: Double] = [:]
        var startedAt: Double?
        var endedAt: Double?
        var asOf: Double

        /// Greater `as_of` wins; on an exact tie the lexically larger value wins.
        mutating func offer(field: String, value: JSONValue?, text: String?, asOf newAsOf: Double) {
            guard let text else { return }
            if let oldAsOf = fieldAsOf[field] {
                let oldText = currentText(field)
                let wins = newAsOf > oldAsOf || (newAsOf == oldAsOf && text > oldText)
                guard wins else { return }
            }
            fieldAsOf[field] = newAsOf
            if field.hasPrefix("attrs.") {
                attrs[String(field.dropFirst("attrs.".count))] = value
            } else {
                scalars[field] = text
            }
        }

        private func currentText(_ field: String) -> String {
            if field.hasPrefix("attrs."),
               let current = attrs[String(field.dropFirst("attrs.".count))] {
                return (try? current.canonicalString()) ?? ""
            }
            return scalars[field] ?? ""
        }
    }

    private static func merge(_ upsert: SessionUpsert, provider: String, _ conn: Database) throws {
        let asOf = upsert.asOf.timeIntervalSince1970
        var state = try loadState(provider: provider, sessionID: upsert.sessionID, conn)
            ?? SessionState(asOf: asOf)

        let incoming: [String: String?] = [
            "cwd": upsert.cwd, "project": upsert.project, "account": upsert.account,
            "model": upsert.model, "title": upsert.title, "status": upsert.status
        ]
        for field in scalarFields {
            let text: String? = incoming[field] ?? nil
            state.offer(field: field, value: nil, text: text, asOf: asOf)
        }
        for (key, value) in upsert.attrs {
            state.offer(field: "attrs.\(key)", value: value, text: try value.canonicalString(), asOf: asOf)
        }
        if let started = upsert.startedAt?.timeIntervalSince1970 {
            state.startedAt = state.startedAt.map { min($0, started) } ?? started
        }
        if let ended = upsert.endedAt?.timeIntervalSince1970 {
            state.endedAt = state.endedAt.map { max($0, ended) } ?? ended
        }
        state.asOf = max(state.asOf, asOf)

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
                provider, upsert.sessionID, state.scalars["cwd"], state.scalars["project"],
                state.scalars["account"], state.scalars["model"], state.scalars["title"],
                state.scalars["status"], state.startedAt, state.endedAt, state.asOf,
                try attrsText(state.attrs), try canonicalFieldAsOf(state.fieldAsOf)
            ])
    }

    private static func canonicalFieldAsOf(_ map: [String: Double]) throws -> String {
        try JSONValue.object(map.mapValues { .number($0) }).canonicalString()
    }

    private static func loadState(provider: String, sessionID: String, _ conn: Database) throws -> SessionState? {
        guard let row = try Row.fetchOne(
            conn, sql: "SELECT * FROM sessions WHERE provider = ? AND session_id = ?",
            arguments: [provider, sessionID]
        ) else { return nil }
        var state = SessionState(asOf: row["as_of"])
        for field in scalarFields {
            let value: String? = row[field]
            if let value { state.scalars[field] = value }
        }
        state.startedAt = row["started_at"]
        state.endedAt = row["ended_at"]
        let decoder = JSONDecoder()
        let attrsText: String = row["attrs"]
        if case .object(let object) = try decoder.decode(JSONValue.self, from: Data(attrsText.utf8)) {
            state.attrs = object
        }
        let fieldText: String = row["field_as_of"]
        if case .object(let object) = try decoder.decode(JSONValue.self, from: Data(fieldText.utf8)) {
            for (key, value) in object {
                if case .number(let number) = value { state.fieldAsOf[key] = number }
            }
        }
        return state
    }
}
