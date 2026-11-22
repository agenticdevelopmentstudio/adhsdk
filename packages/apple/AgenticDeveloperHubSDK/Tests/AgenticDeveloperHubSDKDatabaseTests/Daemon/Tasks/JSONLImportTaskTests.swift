import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The periodic transcript pass: it sweeps the transcripts into the Claude
/// pipeline's spool (the transcript source owns the cursors), never into the
/// legacy `JSONLImporter` tables, and hands back to the scheduler when its
/// budget is spent with work left.
final class JSONLImportTaskTests: XCTestCase {

    var tmp: URL!
    var database: DaemonDatabase!
    var pipeline: ClaudePipelineTestHarness!
    var projects: URL!

    override func setUpWithError() throws {
        tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("import-task-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmp.appendingPathComponent("test.db").path)
        pipeline = try ClaudePipelineTestHarness(
            directory: tmp.appendingPathComponent("pipeline"), database: database.db)
        projects = pipeline.handles.transcriptSource.projectsDirectory.appendingPathComponent("-work")
        try FileManager.default.createDirectory(at: projects, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        pipeline = nil
        database = nil
        try? FileManager.default.removeItem(at: tmp)
    }

    // MARK: - Helpers

    private func writeTranscript(_ name: String) throws {
        let line = """
        {"type":"assistant","sessionId":"\(name)","uuid":"u-\(name)","timestamp":"2026-04-14T10:00:00Z",\
        "cwd":"/work","message":{"id":"m-\(name)","model":"claude-sonnet-4-6",\
        "usage":{"input_tokens":10,"output_tokens":5},\
        "content":[{"type":"tool_use","name":"Edit","input":{}}]}}

        """
        try line.write(to: projects.appendingPathComponent("\(name).jsonl"), atomically: true, encoding: .utf8)
    }

    private func execute(_ task: JSONLImportTask) async throws -> SessionTaskResult {
        try await task.execute(
            context: SessionTaskContext(taskName: "jsonl-import", consecutiveFailures: 0, runReason: .scheduled))
    }

    private func legacyRowCount() throws -> Int {
        try database.db.read { conn in
            try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM event_log") ?? 0
        }
    }

    // MARK: - Tests

    /// A pass spools every transcript line, the drainer archives it, and the
    /// legacy tables stay untouched.
    func testPassSpoolsTranscriptsIntoTheClaudePipeline() async throws {
        try writeTranscript("a")
        try writeTranscript("b")

        let result = try await execute(JSONLImportTask(claude: ClaudePipelineSlot(pipeline.handles)))
        XCTAssertEqual(result.nextRunSeconds, nil, "a pass that read everything waits for its interval")
        XCTAssertEqual(try pipeline.spool.pendingCount(), 2, "one spooled record per transcript line")

        try pipeline.drain()
        XCTAssertEqual(try pipeline.archive.count(), 2, "every line reaches the raw archive")
        XCTAssertEqual(try legacyRowCount(), 0, "JSONLImporter no longer runs")

        // The cursors hold: a second pass finds nothing new.
        _ = try await execute(JSONLImportTask(claude: ClaudePipelineSlot(pipeline.handles)))
        XCTAssertEqual(try pipeline.spool.pendingCount(), 0)
    }

    /// Out of budget with lines still coming, the task asks to run again at once.
    func testSweepOutOfBudgetReschedulesImmediately() throws {
        try writeTranscript("a")
        let result = try JSONLImportTask(claude: ClaudePipelineSlot(pipeline.handles))
            .sweep(pipeline.handles, budget: .zero)
        XCTAssertEqual(result.nextRunSeconds, 0)
    }

    /// With no pipeline the pass reads nothing: the lines wait on disk.
    func testPassWithoutAPipelineReadsNothing() async throws {
        try writeTranscript("a")
        let result = try await execute(JSONLImportTask(claude: ClaudePipelineSlot()))
        XCTAssertEqual(result.nextRunSeconds, nil)
        XCTAssertEqual(try pipeline.spool.pendingCount(), 0)
        XCTAssertEqual(try legacyRowCount(), 0)
    }
}
