import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct ParsedEventConformanceTests {

    private func make(
        eventType: String = "PreToolUse",
        hookData: [String: Any] = ["session_id": "s-1", "tool_name": "Bash"],
        context: [String: Any]? = nil,
        accountEmail: String = "a@b.c",
        oauthAccountEmail: String? = nil
    ) -> ParsedEvent {
        ParsedEvent(eventType: eventType, timestamp: "2026-01-01T00:00:00Z", hookData: hookData,
                    context: context, accountEmail: accountEmail, oauthAccountEmail: oauthAccountEmail)
    }

    @Test("parsed-event-001: fields read back as given")
    func fieldsReadBack() {
        let parsed = make()
        #expect(parsed.eventType == "PreToolUse")
        #expect(parsed.timestamp == "2026-01-01T00:00:00Z")
        #expect(parsed.hookData["session_id"] as? String == "s-1")
        #expect(parsed.hookData["tool_name"] as? String == "Bash")
        #expect(parsed.accountEmail == "a@b.c")
        #expect(parsed.context == nil)
    }

    @Test("parsed-event-002: oauthAccountEmail defaults to nil")
    func oauthDefaultsToNil() {
        #expect(make().oauthAccountEmail == nil)
    }

    @Test("parsed-event-003: empty oauthAccountEmail is not nil")
    func oauthEmptyIsNotNil() {
        let parsed = make(oauthAccountEmail: "")
        #expect(parsed.oauthAccountEmail == "")
        #expect(parsed.oauthAccountEmail != nil)
    }

    @Test("parsed-event-004: oauthAccountEmail keeps its value")
    func oauthKeepsValue() {
        #expect(make(oauthAccountEmail: "me@x.y").oauthAccountEmail == "me@x.y")
    }

    @Test("parsed-event-005: context is stored")
    func contextStored() {
        #expect(make(context: ["cwd": "/tmp/p"]).context?["cwd"] as? String == "/tmp/p")
    }

    @Test("parsed-event-006: an empty event type is accepted")
    func emptyEventTypeAccepted() {
        let parsed = make(eventType: "", hookData: ["session_id": "s-u"])
        #expect(parsed.eventType == "")
        #expect(parsed.sessionId == "s-u")
    }

    @Test("parsed-event-007: empty hook data gives an empty session id")
    func emptyHookDataAccepted() {
        let parsed = make(hookData: [:])
        #expect(parsed.hookData.isEmpty)
        #expect(parsed.sessionId == "")
    }

    @Test("parsed-event-008: an empty account email is kept")
    func emptyAccountEmail() {
        #expect(make(accountEmail: "").accountEmail == "")
    }

    @Test("parsed-event-009: sessionId reads hook_data session_id")
    func sessionIdAccessor() {
        #expect(make(hookData: ["session_id": "s-rt"]).sessionId == "s-rt")
    }

    @Test("parsed-event-010: stored properties are immutable",
          .disabled("Static check: every stored property is declared let; not a runtime test"))
    func storedPropertiesAreImmutable() {}
}
