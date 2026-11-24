import Foundation
import AgenticDeveloperHubSDKDatabase
import GRDB

/// Which messages of one connection to list. `since`/`until` are inclusive ISO-8601 strings.
public struct MessageQuery: Codable, Sendable, Equatable {
    public var connectionId: String
    public var since: String?
    public var until: String?
    /// AND: a message must carry every one.
    public var labelIds: [String]
    /// OR: when not empty, a message must carry at least one.
    public var anyLabelIds: [String]
    public var limit: Int
    public var offset: Int
    /// Only rows after this one in the query's newest-first order. A page that resumes from
    /// the last row it was given cannot skip or repeat rows when rows ahead of it change.
    public var after: MessageKey?

    public init(
        connectionId: String, since: String? = nil, until: String? = nil, labelIds: [String] = [],
        anyLabelIds: [String] = [], limit: Int = 50, offset: Int = 0, after: MessageKey? = nil
    ) {
        self.connectionId = connectionId
        self.since = since
        self.until = until
        self.labelIds = labelIds
        self.anyLabelIds = anyLabelIds
        self.limit = limit
        self.offset = offset
        self.after = after
    }
}

/// A message's place in the newest-first order: `internal_date DESC, id`.
public struct MessageKey: Codable, Sendable, Equatable {
    public var internalDate: String
    public var id: String

    public init(internalDate: String, id: String) {
        self.internalDate = internalDate
        self.id = id
    }
}

/// The local mirror of the hub's integration tables. "Live" means not tombstoned:
/// `deleted_at IS NULL` for connections and configs, `is_deleted = 0` for messages and labels.
public final class IntegrationsStore: Sendable {
    /// Ids bound per `IN (…)` statement; well under SQLite's 32766-variable limit.
    static let inListChunkSize = 500

    private let database: BoundedDatabase

    public init(database: BoundedDatabase) throws {
        self.database = database
        try IntegrationsSchema.migrate(database)
    }

    // MARK: - Provider configs

    public func providerConfig(providerId: String) throws -> ProviderConfig? {
        try database.read { conn in
            try ProviderConfig
                .filter(Column("provider_id") == providerId && Column("deleted_at") == nil)
                .fetchOne(conn)
        }
    }

    public func upsertProviderConfig(_ config: ProviderConfig) throws {
        try database.write { conn in
            var record = config
            let existing = try ProviderConfig
                .filter(Column("provider_id") == config.providerId && Column("deleted_at") == nil)
                .fetchOne(conn)
            if let existing {
                record.id = existing.id
                record.createdAt = existing.createdAt
            }
            record.updatedAt = IntegrationClock.now()
            record.deletedAt = nil
            try record.save(conn)
        }
    }

    public func deleteProviderConfig(providerId: String) throws {
        let now = IntegrationClock.now()
        try database.write { conn in
            try conn.execute(
                sql: """
                    UPDATE integration_provider_configs SET deleted_at = ?, updated_at = ?
                    WHERE provider_id = ? AND deleted_at IS NULL
                    """,
                arguments: [now, now, providerId])
        }
    }

    // MARK: - Connections

    public func connections(provider: String) throws -> [IntegrationConnection] {
        try database.read { conn in
            try IntegrationConnection
                .filter(Column("provider") == provider && Column("deleted_at") == nil)
                .order(Column("external_account_id"))
                .fetchAll(conn)
        }
    }

    /// Email addresses match without regard to case: Gmail addresses are case-insensitive.
    public func connection(idOrEmail: String) throws -> IntegrationConnection? {
        try database.read { conn in
            try IntegrationConnection
                .filter(
                    (Column("id") == idOrEmail
                        || Column("external_account_id").collating(.nocase) == idOrEmail)
                        && Column("deleted_at") == nil)
                .order(Column("created_at"))
                .fetchOne(conn)
        }
    }

    /// Keyed by `(provider, externalAccountId)` among live rows, the address compared without
    /// regard to case: signing in again with the same account updates the existing row and keeps its id.
    public func upsertConnection(_ connection: IntegrationConnection) throws {
        try database.write { conn in
            var record = connection
            let existing = try IntegrationConnection
                .filter(
                    Column("provider") == connection.provider
                        && Column("external_account_id").collating(.nocase) == connection.externalAccountId
                        && Column("deleted_at") == nil)
                .fetchOne(conn)
            if let existing {
                record.id = existing.id
                record.createdAt = existing.createdAt
            }
            record.updatedAt = IntegrationClock.now()
            record.deletedAt = nil
            try record.save(conn)
        }
    }

    /// Soft delete; the connection's messages and labels are tombstoned with it.
    public func deleteConnection(id: String) throws {
        let now = IntegrationClock.now()
        try database.write { conn in
            try conn.execute(
                sql: """
                    UPDATE integration_connections SET deleted_at = ?, updated_at = ?
                    WHERE id = ? AND deleted_at IS NULL
                    """,
                arguments: [now, now, id])
            for table in ["integration_email_messages", "integration_email_labels"] {
                try conn.execute(
                    sql: """
                        UPDATE \(table) SET is_deleted = 1, deleted_at = ?, updated_at = ?
                        WHERE connection_id = ? AND is_deleted = 0
                        """,
                    arguments: [now, now, id])
            }
        }
    }

    /// Throws `IntegrationError.unknownAccount` when no live connection has `id`.
    public func updateSyncState(
        id: String, cursor: String?, lastSyncAt: String?, status: ConnectionStatus, lastError: String?
    ) throws {
        let changed = try database.write { conn -> Int in
            try conn.execute(
                sql: """
                    UPDATE integration_connections
                    SET sync_cursor = ?, last_sync_at = ?, status = ?, last_error = ?, updated_at = ?
                    WHERE id = ? AND deleted_at IS NULL
                    """,
                arguments: [cursor, lastSyncAt, status.rawValue, lastError, IntegrationClock.now(), id])
            return conn.changesCount
        }
        guard changed > 0 else { throw IntegrationError.unknownAccount(id) }
    }

    // MARK: - Messages

    /// Deduped on `(connection_id, external_id)`; a tombstoned row is revived.
    public func upsertMessages(_ messages: [EmailMessage]) throws {
        try database.write { conn in
            for message in messages {
                var record = message
                let existing = try EmailMessage
                    .filter(Column("connection_id") == message.connectionId
                        && Column("external_id") == message.externalId)
                    .fetchOne(conn)
                if let existing {
                    record.id = existing.id
                    record.createdAt = existing.createdAt
                }
                record.updatedAt = IntegrationClock.now()
                record.isDeleted = false
                record.deletedAt = nil
                try record.save(conn)
            }
        }
    }

    /// Tombstones the live rows among `externalIds`, binding at most `inListChunkSize` ids per
    /// statement, all in one transaction. Returns how many rows it tombstoned.
    @discardableResult
    public func tombstoneMessages(connectionId: String, externalIds: [String]) throws -> Int {
        let unique = Array(Set(externalIds))
        guard !unique.isEmpty else { return 0 }
        let now = IntegrationClock.now()
        return try database.write { conn in
            var removed = 0
            for start in stride(from: 0, to: unique.count, by: Self.inListChunkSize) {
                let chunk = Array(unique[start..<min(start + Self.inListChunkSize, unique.count)])
                try conn.execute(
                    sql: """
                        UPDATE integration_email_messages SET is_deleted = 1, deleted_at = ?, updated_at = ?
                        WHERE connection_id = ? AND is_deleted = 0
                            AND external_id IN (\(Self.placeholders(chunk.count)))
                        """,
                    arguments: StatementArguments([now, now, connectionId] + chunk))
                removed += conn.changesCount
            }
            return removed
        }
    }

    /// Returns how many rows it tombstoned.
    @discardableResult
    public func tombstoneMessages(connectionId: String, classes: Set<MailClass>) throws -> Int {
        guard !classes.isEmpty else { return 0 }
        let now = IntegrationClock.now()
        let names = classes.map(\.rawValue).sorted()
        return try database.write { conn in
            try conn.execute(
                sql: """
                    UPDATE integration_email_messages SET is_deleted = 1, deleted_at = ?, updated_at = ?
                    WHERE connection_id = ? AND is_deleted = 0
                        AND mail_class IN (\(Self.placeholders(names.count)))
                    """,
                arguments: StatementArguments([now, now, connectionId] + names))
            return conn.changesCount
        }
    }

    /// Tombstones the live rows dated before `cutoff` (an ISO-8601 string, exclusive) — the rows
    /// that have fallen out of a shrunken sync window. Returns how many it tombstoned.
    @discardableResult
    public func tombstoneMessages(connectionId: String, olderThan cutoff: String) throws -> Int {
        let now = IntegrationClock.now()
        return try database.write { conn in
            try conn.execute(
                sql: """
                    UPDATE integration_email_messages SET is_deleted = 1, deleted_at = ?, updated_at = ?
                    WHERE connection_id = ? AND is_deleted = 0 AND internal_date < ?
                    """,
                arguments: [now, now, connectionId, cutoff])
            return conn.changesCount
        }
    }

    public func liveExternalIds(connectionId: String, since: String) throws -> Set<String> {
        try database.read { conn in
            Set(try String.fetchAll(
                conn,
                sql: """
                    SELECT external_id FROM integration_email_messages
                    WHERE connection_id = ? AND is_deleted = 0 AND internal_date >= ?
                    """,
                arguments: [connectionId, since]))
        }
    }

    /// The live message whose id or Gmail id is `idOrExternalId`; with `includingDeleted`, a
    /// tombstoned one too (a live row wins).
    public func message(
        connectionId: String, idOrExternalId: String, includingDeleted: Bool = false
    ) throws -> EmailMessage? {
        try database.read { conn in
            var request = EmailMessage.filter(Column("connection_id") == connectionId
                && (Column("id") == idOrExternalId || Column("external_id") == idOrExternalId))
            if !includingDeleted { request = request.filter(Column("is_deleted") == false) }
            return try request.order(Column("is_deleted")).fetchOne(conn)
        }
    }

    public func messages(_ query: MessageQuery) throws -> [EmailMessage] {
        var clauses = ["connection_id = ?", "is_deleted = 0"]
        var arguments: [any DatabaseValueConvertible] = [query.connectionId]
        if let since = query.since {
            clauses.append("internal_date >= ?")
            arguments.append(since)
        }
        if let until = query.until {
            clauses.append("internal_date <= ?")
            arguments.append(until)
        }
        for label in query.labelIds {
            clauses.append("EXISTS (SELECT 1 FROM json_each(label_ids) WHERE value = ?)")
            arguments.append(label)
        }
        if !query.anyLabelIds.isEmpty {
            let marks = Array(repeating: "?", count: query.anyLabelIds.count).joined(separator: ", ")
            clauses.append("EXISTS (SELECT 1 FROM json_each(label_ids) WHERE value IN (\(marks)))")
            arguments.append(contentsOf: query.anyLabelIds)
        }
        if let after = query.after {
            clauses.append("(internal_date < ? OR (internal_date = ? AND id > ?))")
            arguments.append(contentsOf: [after.internalDate, after.internalDate, after.id])
        }
        arguments.append(max(query.limit, 0))
        arguments.append(max(query.offset, 0))
        let sql = """
            SELECT * FROM integration_email_messages WHERE \(clauses.joined(separator: " AND "))
            ORDER BY internal_date DESC, id LIMIT ? OFFSET ?
            """
        return try database.read { conn in
            try EmailMessage.fetchAll(conn, sql: sql, arguments: StatementArguments(arguments))
        }
    }

    // MARK: - Labels

    /// Upserts the given labels and tombstones every live label not among them.
    public func replaceLabels(connectionId: String, with labels: [EmailLabel]) throws {
        let now = IntegrationClock.now()
        try database.write { conn in
            for label in labels {
                var record = label
                record.connectionId = connectionId
                let existing = try EmailLabel
                    .filter(Column("connection_id") == connectionId
                        && Column("external_id") == label.externalId)
                    .fetchOne(conn)
                if let existing {
                    record.id = existing.id
                    record.createdAt = existing.createdAt
                }
                record.updatedAt = now
                record.isDeleted = false
                record.deletedAt = nil
                try record.save(conn)
            }
            let keep = labels.map(\.externalId)
            let notIn = keep.isEmpty ? "" : "AND external_id NOT IN (\(Self.placeholders(keep.count)))"
            try conn.execute(
                sql: """
                    UPDATE integration_email_labels SET is_deleted = 1, deleted_at = ?, updated_at = ?
                    WHERE connection_id = ? AND is_deleted = 0 \(notIn)
                    """,
                arguments: StatementArguments([now, now, connectionId] + keep))
        }
    }

    public func labels(connectionId: String) throws -> [EmailLabel] {
        try database.read { conn in
            try EmailLabel
                .filter(Column("connection_id") == connectionId && Column("is_deleted") == false)
                .order(Column("name"), Column("id"))
                .fetchAll(conn)
        }
    }

    // MARK: - Action log

    public func insertActionLog(_ log: ActionLog) throws {
        try database.write { try log.insert($0) }
    }

    public func finishActionLog(id: String, status: String, result: String?, error: String?) throws {
        try database.write { conn in
            try conn.execute(
                sql: """
                    UPDATE integration_action_logs SET status = ?, result = ?, error = ?, updated_at = ?
                    WHERE id = ?
                    """,
                arguments: [status, result, error, IntegrationClock.now(), id])
        }
    }

    private static func placeholders(_ count: Int) -> String {
        Array(repeating: "?", count: count).joined(separator: ",")
    }
}
