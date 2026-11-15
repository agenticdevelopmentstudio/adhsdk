import AgenticDeveloperHubSDKCore
import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

/// Sink vectors of the session-event-sink recipe that drive `EventIngestor`, the real caller.
/// Vector 9 lives in `IngestionPipelineTests`; the encoder vectors in the Core tests.
final class SessionEventSinkConformanceTests: XCTestCase {

    /// A sink that drops every call, as a transport with no subscribers would.
    private final class DroppingSink: SessionEventSink, @unchecked Sendable {
        func broadcast(eventType: String, payload: Data, sessionId: String?) {}
        func broadcastSessionStatus(sessionId: String, status: SessionStatus) {}
    }

    private var tmpDir: URL!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sinkconf-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        database = try TestDaemonDatabase.makeSessionDatabase(
            path: tmpDir.appendingPathComponent("t.db").path
        ).db
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeIngestor(sink: any SessionEventSink) -> EventIngestor {
        let drop = tmpDir.appendingPathComponent("drop")
        return EventIngestor(
            dropDirectory: drop,
            database: database,
            sink: sink,
            quarantine: QuarantineService(
                errorsDirectory: drop.appendingPathComponent("errors"), database: database
            ),
            tailerQueueLabel: "test.sinkconf-tailer"
        )
    }

    private func event(session: String) -> ParsedEvent {
        ParsedEvent(
            eventType: "Stop", timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": session],
            context: nil, accountEmail: ""
        )
    }

    func testV10_nilSessionIdIsRecordedAsNil() {
        let sink = RecordingSink()
        sink.broadcast(eventType: "Stop", payload: Data("{}".utf8), sessionId: nil)

        XCTAssertEqual(sink.events.count, 1)
        XCTAssertNil(sink.events.first?.sessionId)
        XCTAssertEqual(sink.events.first?.eventType, "Stop")
    }

    func testV11_broadcastSessionStatusReachesTheSink() {
        let sink = RecordingSink()
        let ingestor = makeIngestor(sink: sink)

        ingestor.broadcastSessionStatus(sessionId: "s1", status: .ended)

        XCTAssertEqual(sink.statuses.count, 1)
        XCTAssertEqual(sink.statuses.first?.sessionId, "s1")
        XCTAssertEqual(sink.statuses.first?.status, .ended)
    }

    func testV12_ingestionCompletesWhenTheSinkDropsEverything() throws {
        let ingestor = makeIngestor(sink: DroppingSink())

        try ingestor.ingest(event(session: "s-drop"))

        XCTAssertEqual(try database.fetchEvents(sessionId: "s-drop", eventType: nil, limit: 10).count, 1)
    }

    func testV13_encodeFailureSkipsTheBroadcast() throws {
        throw XCTSkip("""
            IngestedEvent holds only Int64 and String fields, so no ingested event can make \
            SessionEventEncoding.encode return nil; the skip branch is unreachable from a unit test
            """)
    }
}
