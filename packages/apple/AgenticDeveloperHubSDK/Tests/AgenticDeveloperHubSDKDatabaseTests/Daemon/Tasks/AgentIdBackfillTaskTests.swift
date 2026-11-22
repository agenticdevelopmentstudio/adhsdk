import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The agent-id backfill pass: a subagent line stored without `attrs.agent_id`
/// gets the id its file names, and the pass marks itself done.
final class AgentIdBackfillTaskTests: XCTestCase {

    var tmp: URL!
    var database: DaemonDatabase!
    var pipeline: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("agent-id-task-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmp.appendingPathComponent("test.db").path)
        pipeline = try ClaudePipelineTestHarness(
            directory: tmp.appendingPathComponent("pipeline"), database: database.db)
    }

    override func tearDownWithError() throws {
        pipeline = nil
        database = nil
        try? FileManager.default.removeItem(at: tmp)
    }

    private func agentId(_ uuid: String) throws -> String? {
        try pipeline.store.read { conn in
            try String.fetchOne(
                conn, sql: "SELECT json_extract(attrs, '$.agent_id') FROM messages WHERE uuid = ?",
                arguments: [uuid])
        }
    }

    func testAPassRestoresAMissingAgentIdAndFinishes() async throws {
        let session = "5c1d2e3f-4a5b-4c6d-8e7f-90a1b2c3d4e5"
        let agents = pipeline.handles.transcriptSource.projectsDirectory
            .appendingPathComponent("-work/\(session)/subagents")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        let line = """
        {"type":"user","sessionId":"\(session)","uuid":"s-1","isSidechain":true,\
        "timestamp":"2026-10-30T12:00:02.000Z","cwd":"/work","message":{"role":"user","content":"look"}}

        """
        try line.write(to: agents.appendingPathComponent("agent-b9.jsonl"), atomically: true, encoding: .utf8)
        _ = try pipeline.handles.pollTranscripts()
        try pipeline.drain()
        XCTAssertEqual(try agentId("s-1"), "b9")

        // As a line normalized before the id was kept was stored.
        let queue = try DatabaseQueue(path: pipeline.directory.appendingPathComponent(EventStore.fileName).path)
        try await queue.write { try $0.execute(sql: "UPDATE messages SET attrs = json_remove(attrs, '$.agent_id')") }
        try queue.close()
        XCTAssertNil(try agentId("s-1"))

        let task = AgentIdBackfillTask(claude: ClaudePipelineSlot(pipeline.handles))
        let result = try await task.execute(
            context: SessionTaskContext(
                taskName: AgentIdBackfillTask.taskName, consecutiveFailures: 0, runReason: .scheduled))
        XCTAssertNil(result.nextRunSeconds, "a finished pass waits for its interval")
        XCTAssertEqual(try agentId("s-1"), "b9")
        XCTAssertTrue(try pipeline.handles.agentIdBackfillDone())
    }
}
