import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `backfillSubagentAgentIds` gives a subagent message stored before the
/// normalizer kept `attrs.agent_id` the id its `subagents/agent-<id>.jsonl`
/// path names, and leaves the session's own messages alone.
final class ClaudeAgentIdBackfillTests: XCTestCase {
    private var root: URL!
    private var harness: ClaudePipelineTestHarness!
    private let session = "9b2f0c1e-3d4a-4b5c-8d6e-7f8091a2b3c4"

    override func setUpWithError() throws {
        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("agent-id-backfill-\(UUID().uuidString.prefix(8))")
        harness = try ClaudePipelineTestHarness(directory: root)
    }

    override func tearDownWithError() throws {
        harness = nil
        try? FileManager.default.removeItem(at: root)
    }

    private func line(uuid: String, sidechain: Bool, text: String, second: Int) -> String {
        """
        {"cwd":"/Users/dev/work/myapp","isSidechain":\(sidechain),"message":{"content":"\(text)","role":"user"},\
        "sessionId":"\(session)","timestamp":"\(String(format: "2026-10-30T12:00:%02d.000Z", second))",\
        "type":"user","uuid":"\(uuid)"}
        """
    }

    private func agentIds() throws -> [String: String?] {
        try harness.store.read { conn in
            var result: [String: String?] = [:]
            for row in try Row.fetchAll(conn, sql: "SELECT uuid, json_extract(attrs, '$.agent_id') FROM messages") {
                result[row[0]] = row[1] as String?
            }
            return result
        }
    }

    func testAMessageStoredWithoutItsAgentIdGetsTheOneItsPathNames() throws {
        let main = harness.transcriptFile(sessionId: session)
        try harness.ingestTranscript(
            lines: [line(uuid: "m-1", sidechain: false, text: "hello", second: 1)], file: main)
        let agentFile = main.deletingPathExtension().appendingPathComponent("subagents/agent-a7f3.jsonl")
        try harness.ingestTranscript(lines: [
            line(uuid: "s-1", sidechain: true, text: "look", second: 2),
            line(uuid: "s-2", sidechain: true, text: "found", second: 3)
        ], file: agentFile)
        XCTAssertEqual(try agentIds()["s-1"], "a7f3")

        // As a message normalized before the id was kept was stored.
        try harness.store.pool.write { conn in
            try conn.execute(sql: "UPDATE messages SET attrs = json_remove(attrs, '$.agent_id')")
        }
        XCTAssertEqual(try agentIds()["s-1"], .some(nil))

        // A chunk of one: the cursor carries it across calls.
        XCTAssertEqual(try harness.handles.backfillSubagentAgentIds(limit: 1), 1)
        XCTAssertFalse(try harness.handles.agentIdBackfillDone())
        XCTAssertEqual(try harness.handles.backfillSubagentAgentIds(limit: 1), 1)
        XCTAssertEqual(try harness.handles.backfillSubagentAgentIds(limit: 1), 0)
        XCTAssertTrue(try harness.handles.agentIdBackfillDone())

        let ids = try agentIds()
        XCTAssertEqual(ids["s-1"], "a7f3")
        XCTAssertEqual(ids["s-2"], "a7f3")
        XCTAssertEqual(ids["m-1"], .some(nil))

        // Done stays done: a later call reads nothing.
        XCTAssertEqual(try harness.handles.backfillSubagentAgentIds(), 0)
    }
}
