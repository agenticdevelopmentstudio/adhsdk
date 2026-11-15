import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("SessionEventEncoding conformance")
struct SessionEventEncodingConformanceTests {

    private struct SnakePayload: Encodable {
        let lastEventType: String
    }

    private struct DatePayload: Encodable {
        let when: Date
    }

    private struct OrderPayload: Encodable {
        let zeta: Int
        let alpha: Int
    }

    private struct PathPayload: Encodable {
        let path: String
    }

    private struct ThrowingPayload: Encodable {
        struct Failure: Error {}
        func encode(to encoder: Encoder) throws { throw Failure() }
    }

    private struct DoublePayload: Encodable {
        let value: Double
    }

    private func text(_ data: Data?) throws -> String {
        let bytes = try #require(data)
        return try #require(String(data: bytes, encoding: .utf8))
    }

    @Test("session-event-sink-001: active status bytes")
    func activeStatusBytes() {
        let data = SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .active)
        #expect(data == Data(#"{"session_id":"s1","status":"active"}"#.utf8))
    }

    @Test("session-event-sink-002: ended status string")
    func endedStatus() throws {
        let json = try text(SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .ended))
        #expect(json == #"{"session_id":"s1","status":"ended"}"#)
    }

    @Test("session-event-sink-003: stale status string")
    func staleStatus() throws {
        let json = try text(SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .stale))
        #expect(json == #"{"session_id":"s1","status":"stale"}"#)
    }

    @Test("session-event-sink-004: keys are snake_case")
    func snakeCaseKeys() throws {
        let json = try text(SessionEventEncoding.encode(SnakePayload(lastEventType: "Stop")))
        #expect(json == #"{"last_event_type":"Stop"}"#)
    }

    @Test("session-event-sink-005: dates are ISO-8601")
    func iso8601Dates() throws {
        let date = Date(timeIntervalSince1970: 1_767_225_600)
        let json = try text(SessionEventEncoding.encode(DatePayload(when: date)))
        #expect(json == #"{"when":"2026-01-01T00:00:00Z"}"#)
    }

    @Test("session-event-sink-006: keys are sorted")
    func sortedKeys() throws {
        let json = try text(SessionEventEncoding.encode(OrderPayload(zeta: 1, alpha: 2)))
        let alpha = try #require(json.range(of: "alpha"))
        let zeta = try #require(json.range(of: "zeta"))
        #expect(alpha.lowerBound < zeta.lowerBound)
    }

    @Test("session-event-sink-007: equal values give equal bytes, also across tasks")
    func statelessAndDeterministic() async throws {
        let value = OrderPayload(zeta: 1, alpha: 2)
        let first = try #require(SessionEventEncoding.encode(value))
        let second = try #require(SessionEventEncoding.encode(value))
        #expect(first == second)
        let results = await withTaskGroup(of: Data?.self) { group in
            for _ in 0..<16 {
                group.addTask { SessionEventEncoding.encode(OrderPayload(zeta: 1, alpha: 2)) }
            }
            var collected: [Data?] = []
            for await item in group { collected.append(item) }
            return collected
        }
        #expect(results.count == 16)
        #expect(results.allSatisfy { $0 == first })
    }

    @Test("session-event-sink-008: a failed encode returns nil")
    func failedEncodeIsNil() {
        #expect(SessionEventEncoding.encode(ThrowingPayload()) == nil)
        #expect(SessionEventEncoding.encode(DoublePayload(value: .infinity)) == nil)
        #expect(SessionEventEncoding.encode(DoublePayload(value: .nan)) == nil)
    }

    @Test("session-event-sink-014: slash is escaped")
    func slashEscaping() throws {
        let json = try text(SessionEventEncoding.encode(PathPayload(path: "a/b")))
        #expect(json.contains(#"a\/b"#))
    }
}
