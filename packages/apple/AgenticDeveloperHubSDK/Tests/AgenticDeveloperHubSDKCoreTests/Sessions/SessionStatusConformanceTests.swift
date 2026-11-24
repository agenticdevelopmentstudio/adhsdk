import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("SessionStatus conformance")
struct SessionStatusConformanceTests {

    @Test("session-status-001: raw values are the lowercase case names")
    func rawValues() {
        #expect(SessionStatus.active.rawValue == "active")
        #expect(SessionStatus.stale.rawValue == "stale")
        #expect(SessionStatus.ended.rawValue == "ended")
    }

    @Test("session-status-002: init from ended")
    func initFromEnded() {
        #expect(SessionStatus(rawValue: "ended") == .ended)
    }

    @Test("session-status-003: init is case-sensitive")
    func initIsCaseSensitive() {
        #expect(SessionStatus(rawValue: "Active") == nil)
    }

    @Test("session-status-004: empty string yields nil")
    func initEmpty() {
        #expect(SessionStatus(rawValue: "") == nil)
    }

    @Test("session-status-005: unknown string yields nil")
    func initUnknown() {
        #expect(SessionStatus(rawValue: "closed") == nil)
    }

    @Test("session-status-006: stored string and enum agree")
    func storedStringAgrees() {
        #expect(SessionStatus(rawValue: "active") == .active)
        #expect(SessionStatus.active.rawValue == "active")
    }

    @Test("session-status-007: exactly three raw strings yield a value")
    func exactlyThreeCases() {
        #expect(SessionStatus(rawValue: "active") == .active)
        #expect(SessionStatus(rawValue: "stale") == .stale)
        #expect(SessionStatus(rawValue: "ended") == .ended)
        for other in ["running", "idle", "ACTIVE", " active", "ended "] {
            #expect(SessionStatus(rawValue: other) == nil)
        }
    }

    @Test("session-status-008: no operation returns a SessionActivity",
          .disabled("an absent API cannot be asserted at runtime; the enum body is three cases and no members"))
    func noActivityOperation() {}

    @Test("session-status-009: stored stale decodes to stale")
    func staleDecodes() {
        #expect(SessionStatus(rawValue: "stale") == .stale)
    }

    @Test("session-status-010: stale is published as its raw string")
    func staleIsPublished() throws {
        let data = try #require(SessionEventEncoding.encodeSessionStatus(sessionId: "s1", status: .stale))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(object["status"] == "stale")
    }

    @Test("session-status-011: a status crosses a task boundary")
    func sendableAcrossTasks() async {
        let status = SessionStatus.stale
        let echoed = await Task { status }.value
        #expect(echoed == .stale)
    }
}
