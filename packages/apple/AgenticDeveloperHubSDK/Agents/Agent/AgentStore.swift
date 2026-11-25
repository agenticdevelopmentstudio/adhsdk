import Foundation
import AgenticDeveloperHubSDKDatabase
import AIPluginKit
import GRDB

/// The agent host's tables, on a database the host is handed (roosterd passes
/// its `events.sqlite`). Its migrator's identifiers all start `agents-`, so it
/// sits beside the owner's own migrator without colliding.
final class AgentStore: Sendable {

    private let database: BoundedDatabase

    init(database: BoundedDatabase) throws {
        self.database = database
        try Self.migrator().migrate(database.writer)
    }

    // MARK: - Definitions

    /// Inserts each definition whose id is absent, so a user's edit to a
    /// default survives the next launch.
    func insertDefaults(_ definitions: [AgentDefinition]) throws {
        let rows = try definitions.map { ($0.id, try AgentsJSON.encodeString($0)) }
        let now = Date().timeIntervalSince1970
        try database.write { conn in
            for (id, json) in rows {
                try conn.execute(
                    sql: "INSERT OR IGNORE INTO agent_definitions (id, json, updated_at) VALUES (?, ?, ?)",
                    arguments: [id, json, now])
            }
        }
    }

    func agents() throws -> [AgentDefinition] {
        let rows = try database.read { conn in
            try String.fetchAll(conn, sql: "SELECT json FROM agent_definitions ORDER BY id")
        }
        return try rows.map { try AgentsJSON.decode(AgentDefinition.self, from: $0) }
    }

    func agent(_ id: String) throws -> AgentDefinition? {
        let row = try database.read { conn in
            try String.fetchOne(conn, sql: "SELECT json FROM agent_definitions WHERE id = ?", arguments: [id])
        }
        return try row.map { try AgentsJSON.decode(AgentDefinition.self, from: $0) }
    }

    func save(_ agent: AgentDefinition) throws {
        let json = try AgentsJSON.encodeString(agent)
        try database.write { conn in
            try conn.execute(
                sql: """
                    INSERT INTO agent_definitions (id, json, updated_at) VALUES (?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET json = excluded.json, updated_at = excluded.updated_at
                    """,
                arguments: [agent.id, json, Date().timeIntervalSince1970])
        }
    }

    // MARK: - Sessions

    func createSession(agentId: String, title: String?) throws -> AgentSessionInfo {
        let now = Date()
        let info = AgentSessionInfo(id: UUID(), agentId: agentId, title: title, createdAt: now, updatedAt: now)
        try database.write { conn in
            try conn.execute(
                sql: """
                    INSERT INTO agent_sessions (id, agent_id, title, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [
                    info.id.uuidString, agentId, title,
                    now.timeIntervalSince1970, now.timeIntervalSince1970
                ])
        }
        return info
    }

    /// Sessions, most recently active first; every agent's when `agentId` is nil.
    func sessions(agentId: String?) throws -> [AgentSessionInfo] {
        try database.read { conn in
            let rows: [Row]
            if let agentId {
                rows = try Row.fetchAll(
                    conn, sql: "SELECT * FROM agent_sessions WHERE agent_id = ? ORDER BY updated_at DESC",
                    arguments: [agentId])
            } else {
                rows = try Row.fetchAll(conn, sql: "SELECT * FROM agent_sessions ORDER BY updated_at DESC")
            }
            return rows.compactMap(Self.sessionInfo)
        }
    }

    func session(_ id: UUID) throws -> AgentSessionInfo? {
        try database.read { conn in
            try Row.fetchOne(conn, sql: "SELECT * FROM agent_sessions WHERE id = ?", arguments: [id.uuidString])
                .flatMap(Self.sessionInfo)
        }
    }

    func deleteSession(_ id: UUID) throws {
        try database.write { conn in
            try conn.execute(sql: "DELETE FROM agent_messages WHERE session_id = ?", arguments: [id.uuidString])
            try conn.execute(sql: "DELETE FROM agent_sessions WHERE id = ?", arguments: [id.uuidString])
        }
    }

    // MARK: - Messages

    /// The session's messages, oldest first.
    func messages(_ sessionId: UUID) throws -> [AgentMessage] {
        let rows = try database.read { conn in
            try String.fetchAll(
                conn, sql: "SELECT json FROM agent_messages WHERE session_id = ? ORDER BY seq",
                arguments: [sessionId.uuidString])
        }
        return try rows.map { try AgentsJSON.decode(AgentMessage.self, from: $0) }
    }

    /// Appends `message` as the session's next one and marks the session active.
    @discardableResult
    func append(_ message: AIChatMessage, to sessionId: UUID) throws -> AgentMessage {
        try database.write { conn in
            let next = try Int.fetchOne(
                conn, sql: "SELECT COALESCE(MAX(seq) + 1, 0) FROM agent_messages WHERE session_id = ?",
                arguments: [sessionId.uuidString]) ?? 0
            let stored = AgentMessage(seq: next, message: message)
            let json = try AgentsJSON.encodeString(stored)
            let now = stored.createdAt.timeIntervalSince1970
            try conn.execute(
                sql: "INSERT INTO agent_messages (session_id, seq, json, created_at) VALUES (?, ?, ?, ?)",
                arguments: [sessionId.uuidString, next, json, now])
            try conn.execute(
                sql: "UPDATE agent_sessions SET updated_at = ? WHERE id = ?",
                arguments: [now, sessionId.uuidString])
            return stored
        }
    }

    // MARK: - Schema

    private static func sessionInfo(_ row: Row) -> AgentSessionInfo? {
        guard let idString: String = row["id"], let id = UUID(uuidString: idString) else { return nil }
        let created: Double = row["created_at"]
        let updated: Double = row["updated_at"]
        return AgentSessionInfo(
            id: id,
            agentId: row["agent_id"],
            title: row["title"],
            createdAt: Date(timeIntervalSince1970: created),
            updatedAt: Date(timeIntervalSince1970: updated))
    }

    static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("agents-v1") { conn in
            try conn.execute(sql: """
                CREATE TABLE agent_definitions (
                    id TEXT PRIMARY KEY NOT NULL,
                    json TEXT NOT NULL,
                    updated_at REAL NOT NULL
                );
                CREATE TABLE agent_sessions (
                    id TEXT PRIMARY KEY NOT NULL,
                    agent_id TEXT NOT NULL,
                    title TEXT,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL
                );
                CREATE INDEX agent_sessions_agent ON agent_sessions (agent_id, updated_at);
                CREATE TABLE agent_messages (
                    session_id TEXT NOT NULL,
                    seq INTEGER NOT NULL,
                    json TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    PRIMARY KEY (session_id, seq)
                );
                """)
        }
        return migrator
    }
}
