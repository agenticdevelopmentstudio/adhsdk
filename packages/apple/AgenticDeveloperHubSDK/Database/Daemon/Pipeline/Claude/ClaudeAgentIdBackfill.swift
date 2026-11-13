#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// Gives `attrs.agent_id` to the subagent messages stored before the normalizer
/// kept it. Messages are immutable once stored (the first copy stays), so neither
/// a redelivery nor a replay into the same `events.db` adds it; this reads each
/// such message's archive record back, takes the agent from its
/// `subagents/agent-<id>.jsonl` path as the normalizer does, and sets it.
///
/// It walks the sidechain messages by id behind a cursor in `store_meta`, a
/// chunk per call, and marks itself done once a chunk comes up short. Messages
/// stored after that were normalized with the id, so it never runs again.
public extension ClaudePipelineHandles {
    /// `store_meta` key: the last message id the backfill has looked at.
    static let agentIdBackfillCursorKey = "claude_agent_id_backfill_after"
    /// `store_meta` key: set to `1` once every stored subagent message has been looked at.
    static let agentIdBackfillDoneKey = "claude_agent_id_backfill_done"

    /// Whether the backfill has finished.
    func agentIdBackfillDone() throws -> Bool {
        try store.metaValue(forKey: Self.agentIdBackfillDoneKey) == "1"
    }

    /// Looks at up to `limit` sidechain messages past the cursor and gives each
    /// subagent-file one without an agent id its id. Returns how many messages
    /// it looked at: 0 once the backfill is done.
    @discardableResult
    func backfillSubagentAgentIds(limit: Int = 2000) throws -> Int {
        guard try !agentIdBackfillDone() else { return 0 }
        let after = Int64(try store.metaValue(forKey: Self.agentIdBackfillCursorKey) ?? "") ?? 0
        let rows = try store.read { conn in
            try Row.fetchAll(conn, sql: """
                SELECT id, raw_ref, json_extract(attrs, '$.agent_id') IS NULL FROM messages
                WHERE provider = ? AND is_sidechain = 1 AND id > ?
                ORDER BY id LIMIT ?
                """, arguments: [ClaudeProvider.name, after, max(limit, 1)])
        }
        let missing = rows.filter { ($0[2] as Bool?) ?? false }
        let records = try archive.records(ids: missing.map { $0[1] as Int64 })
        var agentByRaw: [Int64: String] = [:]
        for archived in records where archived.record.sourceKind == ClaudeProvider.transcriptKind {
            guard let payload = try? ClaudeTranscriptPayload.decode(archived.record.payload),
                  payload.subagentFile,
                  let agentId = JSONLScanner.subagentId(ofPath: payload.file) else { continue }
            agentByRaw[archived.id] = agentId
        }
        let last: Int64? = rows.last?[0]
        let done = rows.count < max(limit, 1)
        try store.pool.write { conn in
            for row in missing {
                let id: Int64 = row[0]
                let rawRef: Int64 = row[1]
                guard let agentId = agentByRaw[rawRef] else { continue }
                try conn.execute(sql: """
                    UPDATE messages SET attrs = json_set(attrs, '$.agent_id', ?)
                    WHERE id = ? AND json_extract(attrs, '$.agent_id') IS NULL
                    """, arguments: [agentId, id])
            }
            if let last {
                try conn.execute(
                    sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES(?, ?)",
                    arguments: [Self.agentIdBackfillCursorKey, String(last)])
            }
            if done {
                try conn.execute(
                    sql: "INSERT OR REPLACE INTO store_meta(key, value) VALUES(?, '1')",
                    arguments: [Self.agentIdBackfillDoneKey])
            }
        }
        return rows.count
    }
}
#endif
