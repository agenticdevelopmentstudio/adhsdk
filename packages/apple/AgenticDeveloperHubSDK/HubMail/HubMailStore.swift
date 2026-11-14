import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync

/// Typed reads over the tables `HubMailProjection` keeps. Every read skips
/// rows tombstoned locally (`deleted_at`) and rows the hub's worker marked
/// removed (`is_deleted`).
public final class HubMailStore: Sendable {

    public static let maxPageSize = 500

    private let database: BoundedDatabase

    /// Creates the mirror tables if they are missing, so every read works
    /// (and returns nothing) before the first pull.
    public init(database: BoundedDatabase) throws {
        self.database = database
        try database.write { conn in try HubMailProjection().createTables(in: conn) }
    }

    private static let messages = HubMailProjection.messages.name
    private static let labels = HubMailProjection.labels.name
    private static let live = HubMailProjection.live

    /// The distinct connection ids that have live messages or labels, sorted.
    public func connections() throws -> [String] {
        try database.read { conn in
            try String.fetchAll(conn, sql: """
                SELECT connection_id FROM \(Self.messages) WHERE \(Self.live) AND connection_id IS NOT NULL
                UNION
                SELECT connection_id FROM \(Self.labels) WHERE \(Self.live) AND connection_id IS NOT NULL
                ORDER BY 1
                """)
        }
    }

    /// One connection's live labels, system labels first, then by name.
    public func labels(connectionId: String) throws -> [HubEmailLabel] {
        try database.read { conn in
            try Row.fetchAll(
                conn,
                sql: """
                    SELECT * FROM \(Self.labels) WHERE connection_id = ? AND \(Self.live)
                    ORDER BY (type = 'system') DESC, name COLLATE NOCASE, id
                    """,
                arguments: [connectionId]
            ).map(Self.label(from:))
        }
    }

    /// A page of live messages, newest first by `internal_date` then by id
    /// descending (a message with no date sorts after every dated one).
    /// `labelId` is a provider label id (`INBOX`) that `label_ids` must contain.
    public func messages(
        connectionId: String? = nil, labelId: String? = nil,
        limit: Int = 50, before cursor: HubMailPageCursor? = nil
    ) throws -> HubEmailMessagePage {
        let pageSize = min(max(limit, 1), Self.maxPageSize)
        var clauses = [Self.live]
        var arguments: [(any DatabaseValueConvertible)?] = []
        if let connectionId {
            clauses.append("connection_id = ?")
            arguments.append(connectionId)
        }
        if let labelId {
            clauses.append("""
                EXISTS (SELECT 1 FROM json_each(CASE WHEN json_valid(label_ids) THEN label_ids ELSE '[]' END)
                        WHERE value = ?)
                """)
            arguments.append(labelId)
        }
        if let cursor {
            if let date = cursor.internalDate {
                clauses.append("""
                    ((internal_date IS NOT NULL AND (internal_date < ? OR (internal_date = ? AND id < ?)))
                     OR internal_date IS NULL)
                    """)
                arguments += [date, date, cursor.id]
            } else {
                clauses.append("(internal_date IS NULL AND id < ?)")
                arguments.append(cursor.id)
            }
        }
        // One extra row tells whether another page follows.
        arguments.append(pageSize + 1)
        let fetched = try database.read { conn in
            try Row.fetchAll(
                conn,
                sql: """
                    SELECT * FROM \(Self.messages) WHERE \(clauses.joined(separator: " AND "))
                    ORDER BY (internal_date IS NULL), internal_date DESC, id DESC
                    LIMIT ?
                    """,
                arguments: StatementArguments(arguments)
            ).map(Self.message(from:))
        }
        let page = Array(fetched.prefix(pageSize))
        let next = fetched.count > pageSize
            ? page.last.map { HubMailPageCursor(internalDate: $0.internalDate, id: $0.id) }
            : nil
        return HubEmailMessagePage(messages: page, next: next)
    }

    /// One live message, or nil.
    public func message(id: String) throws -> HubEmailMessage? {
        try database.read { conn in
            try Row.fetchOne(
                conn,
                sql: "SELECT * FROM \(Self.messages) WHERE id = ? AND \(Self.live)",
                arguments: [id]
            ).map(Self.message(from:))
        }
    }

    /// A thread's live messages, oldest first.
    public func thread(connectionId: String, threadId: String) throws -> [HubEmailMessage] {
        try database.read { conn in
            try Row.fetchAll(
                conn,
                sql: """
                    SELECT * FROM \(Self.messages)
                    WHERE connection_id = ? AND thread_id = ? AND \(Self.live)
                    ORDER BY (internal_date IS NULL), internal_date ASC, id ASC
                    """,
                arguments: [connectionId, threadId]
            ).map(Self.message(from:))
        }
    }

    // MARK: - Decoding

    static func message(from row: Row) -> HubEmailMessage {
        HubEmailMessage(
            id: row["id"],
            connectionId: row["connection_id"] ?? "",
            provider: row["provider"] ?? "",
            externalId: row["external_id"] ?? "",
            threadId: row["thread_id"],
            from: row["from_address"],
            to: strings(row["to_addresses"]),
            cc: strings(row["cc_addresses"]),
            subject: row["subject"],
            snippet: row["snippet"],
            bodyText: row["body_text"],
            bodyHtml: row["body_html"],
            labelIds: strings(row["label_ids"]),
            internalDate: row["internal_date"],
            attachmentsJSON: row["attachments"]
        )
    }

    static func label(from row: Row) -> HubEmailLabel {
        HubEmailLabel(
            id: row["id"],
            connectionId: row["connection_id"] ?? "",
            externalId: row["external_id"] ?? "",
            provider: row["source_provider"] ?? "",
            name: row["name"] ?? "",
            parentName: row["parent_name"],
            type: row["type"] ?? "user",
            messagesTotal: row["messages_total"],
            messagesUnread: row["messages_unread"]
        )
    }

    /// A JSON array column as its string elements; anything else is empty.
    static func strings(_ text: String?) -> [String] {
        guard let text, case .array(let items) = HubMailProjection.decodeJSON(text) else { return [] }
        return items.compactMap(\.stringValue)
    }
}
