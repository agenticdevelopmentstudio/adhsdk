import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `SessionDTO`, `SessionEventDTO`, `SessionDetailDTO` and `HealthDTO`.
final class SessionDTOsConformanceTests: XCTestCase {

    private var requiredKeys: [String: Any] { [
        "session_id": "s1", "cwd": "/x", "model": "m", "started_at": "2026-11-14 09:30:00",
        "last_activity_at": "2026-11-14 09:31:00", "last_tool": "Bash", "status": "active",
        "git_branch": "main", "summary": "sum", "pid": 7, "term_program": "iTerm.app", "event_count": 3
    ] }

    private func body(adding extra: [String: Any] = [:], removing removed: [String] = []) throws -> Data {
        var object = requiredKeys
        for (key, value) in extra { object[key] = value }
        for key in removed { object.removeValue(forKey: key) }
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func minimalSession() -> SessionDTO {
        SessionDTO(
            sessionId: "s1", cwd: "/x", model: "m", startedAt: "a", lastActivityAt: "b", lastTool: "t",
            status: "active", gitBranch: "main", summary: "sum", pid: 7, termProgram: "iTerm.app", eventCount: 3)
    }

    private func assertMissingKey(_ data: Data, _ name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try StenographerWire.decoder().decode(SessionDTO.self, from: data),
                             file: file, line: line) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)", file: file, line: line)
            }
            XCTAssertEqual(key.stringValue, name, file: file, line: line)
        }
    }

    func testSessionDtos001_optionalKeysDefault() throws {
        let session = try StenographerWire.decoder().decode(SessionDTO.self, from: body())
        XCTAssertEqual(session.sessionId, "s1")
        XCTAssertEqual(session.projectRoot, "")
        XCTAssertEqual(session.termSessionId, "")
        XCTAssertEqual(session.transcriptTitle, "")
        XCTAssertEqual(session.lastOutput, "")
        XCTAssertEqual(session.lastEventType, "")
        XCTAssertEqual(session.summaryAt, "")
        XCTAssertEqual(session.turnStateAt, "")
        XCTAssertFalse(session.subagentWorking)
    }

    func testSessionDtos002_requiredKeysThrow() throws {
        assertMissingKey(try body(removing: ["event_count"]), "eventCount")
        assertMissingKey(try body(removing: ["git_branch"]), "gitBranch")
    }

    func testSessionDtos004_encodeWritesAllTwentyKeys() throws {
        let data = try StenographerWire.encoder().encode(minimalSession())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let expected: Set<String> = [
            "session_id", "cwd", "model", "started_at", "last_activity_at", "last_tool", "status", "git_branch",
            "summary", "pid", "term_program", "project_root", "term_session_id", "transcript_title",
            "last_output", "last_event_type", "summary_at", "event_count", "subagent_working", "turn_state_at"
        ]
        XCTAssertEqual(Set(object.keys), expected)
        XCTAssertEqual(expected.count, 20)
        XCTAssertEqual(object["project_root"] as? String, "")
        XCTAssertEqual(object["subagent_working"] as? Bool, false)
    }

    func testSessionDtos005_nullOptionalDecodesAsDefault() throws {
        let data = try body(adding: ["project_root": NSNull()])
        let session = try StenographerWire.decoder().decode(SessionDTO.self, from: data)
        XCTAssertEqual(session.projectRoot, "")
    }

    func testSessionDtos006_initDefaults() {
        let session = minimalSession()
        XCTAssertEqual(session.projectRoot, "")
        XCTAssertEqual(session.termSessionId, "")
        XCTAssertEqual(session.transcriptTitle, "")
        XCTAssertEqual(session.lastOutput, "")
        XCTAssertEqual(session.lastEventType, "")
        XCTAssertEqual(session.summaryAt, "")
        XCTAssertEqual(session.turnStateAt, "")
        XCTAssertFalse(session.subagentWorking)
    }

    func testSessionDtos007_eventDecodeIsStrict() throws {
        let object: [String: Any] = [
            "id": 1, "session_id": "s1", "event_type": "Stop", "timestamp": "t", "cwd": "/x", "detail": "d"
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try StenographerWire.decoder().decode(SessionEventDTO.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "gitBranch")
        }
        XCTAssertEqual(
            SessionEventDTO(id: 1, sessionId: "s1", eventType: "Stop", timestamp: "t", cwd: "/x", detail: "d")
                .gitBranch, "")
    }

    func testSessionDtos008_eventRoundTripsWithWireKeys() throws {
        let event = SessionEventDTO(
            id: 9, sessionId: "s1", eventType: "Stop", timestamp: "2026-11-14 09:30:00", cwd: "/x",
            detail: "d", gitBranch: "main")
        let data = try StenographerWire.encoder().encode(event)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(
            Set(object.keys), ["id", "session_id", "event_type", "timestamp", "cwd", "detail", "git_branch"])
        let decoded = try StenographerWire.decoder().decode(SessionEventDTO.self, from: data)
        XCTAssertEqual(decoded.id, 9)
        XCTAssertEqual(decoded.sessionId, "s1")
        XCTAssertEqual(decoded.eventType, "Stop")
        XCTAssertEqual(decoded.timestamp, "2026-11-14 09:30:00")
        XCTAssertEqual(decoded.cwd, "/x")
        XCTAssertEqual(decoded.detail, "d")
        XCTAssertEqual(decoded.gitBranch, "main")
    }

    func testSessionDtos009_detailDecodeRequiresRecentEvents() throws {
        let session = try XCTUnwrap(JSONSerialization.jsonObject(with: try body()))
        let full = try JSONSerialization.data(withJSONObject: ["session": session, "recent_events": []])
        let detail = try StenographerWire.decoder().decode(SessionDetailDTO.self, from: full)
        XCTAssertTrue(detail.recentEvents.isEmpty)
        XCTAssertEqual(detail.session.sessionId, "s1")
        let partial = try JSONSerialization.data(withJSONObject: ["session": session])
        XCTAssertThrowsError(try StenographerWire.decoder().decode(SessionDetailDTO.self, from: partial))
    }

    func testSessionDtos010_healthInitDefaults() {
        let health = HealthDTO(status: "ok", uptime: 1, version: "test")
        XCTAssertNil(health.activeSessionCount)
        XCTAssertNil(health.totalEventCount)
        XCTAssertNil(health.startupDurationMs)
        XCTAssertNil(health.memoryFootprintMb)
        XCTAssertNil(health.memoryPeakMb)
        XCTAssertNil(health.statusLineError)
    }

    func testSessionDtos011_healthMemoryCasing() throws {
        let json = #"{"status":"ok","uptime":5,"version":"1","memory_footprint_mb":812,"memory_peak_mb":900}"#
        let health = try StenographerWire.decoder().decode(HealthDTO.self, from: Data(json.utf8))
        XCTAssertEqual(health.memoryFootprintMb, 812)
        XCTAssertEqual(health.memoryPeakMb, 900)
    }

    func testSessionDtos012_healthDecodeRequiresVersion() {
        let json = #"{"status":"ok","uptime":5}"#
        XCTAssertThrowsError(try StenographerWire.decoder().decode(HealthDTO.self, from: Data(json.utf8))) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "version")
        }
    }

    func testSessionDtos014_lastEventTypeAndSubagentWorking() throws {
        let data = try body(adding: ["last_event_type": "PreToolUse", "subagent_working": true])
        let session = try StenographerWire.decoder().decode(SessionDTO.self, from: data)
        XCTAssertEqual(session.lastEventType, "PreToolUse")
        XCTAssertTrue(session.subagentWorking)
    }

    func testSessionDtos015_statusLineErrorAbsentIsNil() throws {
        let json = #"{"status":"ok","uptime":5,"version":"1"}"#
        let health = try StenographerWire.decoder().decode(HealthDTO.self, from: Data(json.utf8))
        XCTAssertNil(health.statusLineError)
    }

    func testSessionDtos016_conformances() {
        func requireCodableSendable<T: Codable & Sendable>(_ value: T) -> T { value }
        let session = requireCodableSendable(minimalSession())
        let event = requireCodableSendable(
            SessionEventDTO(id: 1, sessionId: "s", eventType: "e", timestamp: "t", cwd: "c", detail: "d"))
        let detail = requireCodableSendable(SessionDetailDTO(session: session, recentEvents: [event]))
        let health = requireCodableSendable(HealthDTO(status: "ok", uptime: 1, version: "v"))
        XCTAssertEqual(detail.recentEvents.count, 1)
        XCTAssertEqual(health.status, "ok")
        XCTAssertFalse((session as Any) is any Equatable)
        XCTAssertFalse((event as Any) is any Hashable)
        XCTAssertFalse((detail as Any) is any Identifiable)
        XCTAssertFalse((health as Any) is any Equatable)
    }

    func testSessionDtos017_timestampsAreOpaqueStrings() throws {
        let session = try StenographerWire.decoder().decode(SessionDTO.self, from: body())
        XCTAssertEqual(session.startedAt, "2026-11-14 09:30:00")
    }

    func testSessionDtos018_sessionFieldSet() {
        let session = SessionDTO(
            sessionId: "s1", cwd: "/c", model: "m", startedAt: "sa", lastActivityAt: "la", lastTool: "lt",
            status: "st", gitBranch: "gb", summary: "su", pid: 11, termProgram: "tp", projectRoot: "pr",
            termSessionId: "ts", transcriptTitle: "tt", lastOutput: "lo", lastEventType: "le", summaryAt: "sat",
            eventCount: 12, subagentWorking: true, turnStateAt: "tsa")
        XCTAssertEqual(session.sessionId, "s1")
        XCTAssertEqual(session.cwd, "/c")
        XCTAssertEqual(session.model, "m")
        XCTAssertEqual(session.startedAt, "sa")
        XCTAssertEqual(session.lastActivityAt, "la")
        XCTAssertEqual(session.lastTool, "lt")
        XCTAssertEqual(session.status, "st")
        XCTAssertEqual(session.gitBranch, "gb")
        XCTAssertEqual(session.summary, "su")
        XCTAssertEqual(session.pid, 11)
        XCTAssertEqual(session.termProgram, "tp")
        XCTAssertEqual(session.projectRoot, "pr")
        XCTAssertEqual(session.termSessionId, "ts")
        XCTAssertEqual(session.transcriptTitle, "tt")
        XCTAssertEqual(session.lastOutput, "lo")
        XCTAssertEqual(session.lastEventType, "le")
        XCTAssertEqual(session.summaryAt, "sat")
        XCTAssertEqual(session.eventCount, 12)
        XCTAssertTrue(session.subagentWorking)
        XCTAssertEqual(session.turnStateAt, "tsa")
    }

    func testSessionDtos019_eventInitDefault() {
        let event = SessionEventDTO(id: 1, sessionId: "s", eventType: "e", timestamp: "t", cwd: "c", detail: "d")
        XCTAssertEqual(event.gitBranch, "")
    }

    func testSessionDtos020_healthFieldSet() {
        let health = HealthDTO(
            status: "migrating", uptime: 12.5, version: "1.2", activeSessionCount: 1, totalEventCount: 2,
            startupDurationMs: 3, memoryFootprintMb: 4, memoryPeakMb: 5, statusLineError: "boom")
        XCTAssertEqual(health.status, "migrating")
        XCTAssertEqual(health.uptime, 12.5)
        XCTAssertEqual(health.version, "1.2")
        XCTAssertEqual(health.activeSessionCount, 1)
        XCTAssertEqual(health.totalEventCount, 2)
        XCTAssertEqual(health.startupDurationMs, 3)
        XCTAssertEqual(health.memoryFootprintMb, 4)
        XCTAssertEqual(health.memoryPeakMb, 5)
        XCTAssertEqual(health.statusLineError, "boom")
    }

    func testSessionDtos021_detailKeepsEventOrder() throws {
        func event(_ identifier: Int) -> [String: Any] {
            ["id": identifier, "session_id": "s1", "event_type": "e", "timestamp": "t", "cwd": "/x",
             "detail": "d", "git_branch": "main"]
        }
        let session = try XCTUnwrap(JSONSerialization.jsonObject(with: try body()))
        let data = try JSONSerialization.data(
            withJSONObject: ["session": session, "recent_events": [event(3), event(1), event(2)]])
        let detail = try StenographerWire.decoder().decode(SessionDetailDTO.self, from: data)
        XCTAssertEqual(detail.recentEvents.map(\.id), [3, 1, 2])
    }
}
