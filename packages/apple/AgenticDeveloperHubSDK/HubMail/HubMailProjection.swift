import Foundation
import GRDB
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKSyncGRDB

/// Keeps the hub's two Gmail tables in typed local tables, one column per
/// backend column, so `HubMailStore` can read by connection, label, thread and
/// date through indexes rather than JSON expressions.
///
/// It follows the projection contract: an upsert replaces the row and clears
/// `deleted_at`, a delete keeps a tombstone and takes the delete's version when
/// it has one, and a change naming a column the projection does not know is
/// ignored, so a new backend column never breaks an old client.
public struct HubMailProjection: SyncMirrorProjection {

    enum Kind: Sendable { case text, json, integer, boolean }

    struct Column: Sendable {
        let name: String
        let kind: Kind
    }

    struct Table: Sendable {
        let name: String
        let columns: [Column]
        let indexes: [String]

        var columnNames: [String] { columns.map(\.name) }
    }

    static let messages = Table(
        name: "hub_email_messages",
        columns: [
            Column(name: "ecosystem_id", kind: .text),
            Column(name: "connection_id", kind: .text),
            Column(name: "provider", kind: .text),
            Column(name: "external_id", kind: .text),
            Column(name: "thread_id", kind: .text),
            Column(name: "from_address", kind: .text),
            Column(name: "to_addresses", kind: .json),
            Column(name: "cc_addresses", kind: .json),
            Column(name: "subject", kind: .text),
            Column(name: "snippet", kind: .text),
            Column(name: "body_text", kind: .text),
            Column(name: "body_html", kind: .text),
            Column(name: "label_ids", kind: .json),
            Column(name: "internal_date", kind: .text),
            Column(name: "attachments", kind: .json),
            Column(name: "history_id", kind: .text),
            Column(name: "is_deleted", kind: .boolean),
            Column(name: "created_at", kind: .text),
            Column(name: "updated_at", kind: .text)
        ],
        indexes: [
            "CREATE INDEX IF NOT EXISTS hub_email_messages_connection ON hub_email_messages(connection_id)",
            "CREATE INDEX IF NOT EXISTS hub_email_messages_date ON hub_email_messages(internal_date, id)",
            "CREATE INDEX IF NOT EXISTS hub_email_messages_thread ON hub_email_messages(connection_id, thread_id)"
        ]
    )

    static let labels = Table(
        name: "hub_email_labels",
        columns: [
            Column(name: "connection_id", kind: .text),
            Column(name: "external_id", kind: .text),
            Column(name: "source_provider", kind: .text),
            Column(name: "name", kind: .text),
            Column(name: "parent_name", kind: .text),
            Column(name: "type", kind: .text),
            Column(name: "color", kind: .json),
            Column(name: "messages_total", kind: .integer),
            Column(name: "messages_unread", kind: .integer),
            Column(name: "is_deleted", kind: .boolean),
            Column(name: "created_at", kind: .text),
            Column(name: "updated_at", kind: .text)
        ],
        indexes: [
            "CREATE INDEX IF NOT EXISTS hub_email_labels_connection ON hub_email_labels(connection_id)"
        ]
    )

    public init() {}

    public var resources: Set<String> { HubMailResource.all }

    static func table(for resource: String) -> Table? {
        switch resource {
        case HubMailResource.messages: return messages
        case HubMailResource.labels: return labels
        default: return nil
        }
    }

    private static func requireTable(_ resource: String) throws -> Table {
        guard let table = table(for: resource) else { throw HubMailProjectionError.unknownResource(resource) }
        return table
    }

    public func createTables(in conn: Database) throws {
        for table in [Self.messages, Self.labels] {
            let columns = table.columns.map { column -> String in
                switch column.kind {
                case .text, .json: return "\(column.name) TEXT"
                case .integer: return "\(column.name) INTEGER"
                case .boolean: return "\(column.name) INTEGER NOT NULL DEFAULT 0"
                }
            }
            try conn.execute(sql: """
                CREATE TABLE IF NOT EXISTS \(table.name) (
                    id TEXT PRIMARY KEY NOT NULL,
                    \(columns.joined(separator: ",\n    ")),
                    sync_version INTEGER NOT NULL DEFAULT 0,
                    deleted_at TEXT)
                """)
            for index in table.indexes { try conn.execute(sql: index) }
        }
    }

    public func upsert(resource: String, id: String, syncVersion: Int,
                       data: [String: JSONValue], in conn: Database) throws {
        try upsert(resource: resource, id: id, syncVersion: syncVersion, data: data, isFullRow: true, in: conn)
    }

    /// A full row (a pull) replaces every column, so a column the change leaves
    /// out becomes NULL. A partial patch touches only the columns it names.
    public func upsert(resource: String, id: String, syncVersion: Int,
                       data: [String: JSONValue], isFullRow: Bool, in conn: Database) throws {
        let table = try Self.requireTable(resource)
        let columns = isFullRow ? table.columns : table.columns.filter { data[$0.name] != nil }
        let names = ["id"] + columns.map(\.name) + ["sync_version", "deleted_at"]
        let placeholders = Array(repeating: "?", count: names.count - 1) + ["NULL"]
        var values: [(any DatabaseValueConvertible)?] = [id]
        values += columns.map { Self.bind(data[$0.name], as: $0.kind) }
        values.append(syncVersion)
        let updates = (columns.map(\.name) + ["sync_version"]).map { "\($0) = excluded.\($0)" } + ["deleted_at = NULL"]
        try conn.execute(
            sql: """
                INSERT INTO \(table.name) (\(names.joined(separator: ", ")))
                VALUES (\(placeholders.joined(separator: ", ")))
                ON CONFLICT(id) DO UPDATE SET \(updates.joined(separator: ", "))
                """,
            arguments: StatementArguments(values))
    }

    public func markDeleted(resource: String, id: String, syncVersion: Int?, in conn: Database) throws {
        let table = try Self.requireTable(resource)
        try conn.execute(
            sql: """
                UPDATE \(table.name) SET deleted_at = datetime('now'),
                    sync_version = COALESCE(?, sync_version) WHERE id = ?
                """,
            arguments: [syncVersion, id])
    }

    public func setSyncVersion(_ version: Int, resource: String, id: String, in conn: Database) throws {
        let table = try Self.requireTable(resource)
        try conn.execute(sql: "UPDATE \(table.name) SET sync_version = ? WHERE id = ?", arguments: [version, id])
    }

    public func syncVersion(resource: String, id: String, in conn: Database) throws -> Int? {
        let table = try Self.requireTable(resource)
        return try Int.fetchOne(conn, sql: "SELECT sync_version FROM \(table.name) WHERE id = ?", arguments: [id])
    }

    public func truncate(resources: [String], in conn: Database) throws {
        for resource in resources {
            guard let table = Self.table(for: resource) else { continue }
            try conn.execute(sql: "DELETE FROM \(table.name)")
        }
    }

    public func rows(resource: String, limit: Int, offset: Int, in conn: Database) throws -> [[String: JSONValue]] {
        let table = try Self.requireTable(resource)
        return try Row.fetchAll(
            conn,
            sql: """
                SELECT * FROM \(table.name) WHERE \(Self.live)
                ORDER BY id LIMIT ? OFFSET ?
                """,
            arguments: [limit, offset]
        ).map { Self.json(from: $0, table: table) }
    }

    public func row(resource: String, id: String, in conn: Database) throws -> [String: JSONValue]? {
        let table = try Self.requireTable(resource)
        return try Row.fetchOne(
            conn,
            sql: "SELECT * FROM \(table.name) WHERE id = ? AND \(Self.live)",
            arguments: [id]
        ).map { Self.json(from: $0, table: table) }
    }

    /// The predicate every read uses: not tombstoned locally, and not marked
    /// removed by the hub's worker.
    static let live = "deleted_at IS NULL AND is_deleted = 0"

    // MARK: - Coding

    static func bind(_ value: JSONValue?, as kind: Kind) -> (any DatabaseValueConvertible)? {
        guard let value, !value.isNull else {
            return kind == .boolean ? false : nil
        }
        switch kind {
        case .text:
            switch value {
            case .string(let text): return text
            case .number(let number): return number.rounded() == number ? String(Int64(number)) : String(number)
            case .bool(let flag): return flag ? "true" : "false"
            default: return encode(value)
            }
        case .json:
            // A column that arrives already encoded is kept as that text.
            if case .string(let text) = value { return text }
            return encode(value)
        case .integer:
            switch value {
            case .number(let number): return Int64(number)
            case .string(let text): return Int64(text)
            case .bool(let flag): return flag ? 1 : 0
            default: return nil
            }
        case .boolean:
            switch value {
            case .bool(let flag): return flag
            case .number(let number): return number != 0
            case .string(let text): return text == "true" || text == "1"
            default: return false
            }
        }
    }

    static func encode(_ value: JSONValue) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decodeJSON(_ text: String) -> JSONValue {
        guard let data = text.data(using: .utf8),
              let value = try? JSONDecoder().decode(JSONValue.self, from: data) else { return .string(text) }
        return value
    }

    static func json(from row: Row, table: Table) -> [String: JSONValue] {
        var out: [String: JSONValue] = ["id": .string(row["id"])]
        for column in table.columns {
            let raw: DatabaseValue = row[column.name]
            if raw.isNull { out[column.name] = .null; continue }
            switch column.kind {
            case .text: out[column.name] = .string(row[column.name])
            case .json: out[column.name] = decodeJSON(row[column.name])
            case .integer: out[column.name] = .number(Double(row[column.name] as Int64))
            case .boolean: out[column.name] = .bool(row[column.name])
            }
        }
        return out
    }
}

public enum HubMailProjectionError: Error, Equatable {
    case unknownResource(String)
}
