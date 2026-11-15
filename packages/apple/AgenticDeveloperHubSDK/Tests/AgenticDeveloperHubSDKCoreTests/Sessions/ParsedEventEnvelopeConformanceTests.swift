import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct ParsedEventEnvelopeConformanceTests {

    private func makeEvent(
        type: String = "PreToolUse",
        timestamp: String = "2026-01-01T00:00:00Z",
        hookData: [String: Any] = ["session_id": "s-rt", "tool_name": "Bash"],
        context: [String: Any]? = nil,
        account: String = "a@b.c",
        oauth: String? = nil
    ) -> ParsedEvent {
        ParsedEvent(eventType: type, timestamp: timestamp, hookData: hookData,
                    context: context, accountEmail: account, oauthAccountEmail: oauth)
    }

    private func object(_ event: ParsedEvent) throws -> [String: Any] {
        let data = try event.envelopeJSON()
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func parse(_ event: ParsedEvent) throws -> ParseResult {
        let data = try event.envelopeJSON()
        let text = try #require(String(bytes: data, encoding: .utf8))
        return ParseResult.parse(envelopeJSON: text)
    }

    @Test("V1: sessionId reads session_id")
    func testV1_sessionIdReadsSessionId() {
        #expect(makeEvent(hookData: ["session_id": "s-rt"]).sessionId == "s-rt")
    }

    @Test("V2: sessionId is empty when missing or not a string")
    func testV2_sessionIdEmptyWhenMissingOrNotString() {
        #expect(makeEvent(hookData: [:]).sessionId == "")
        #expect(makeEvent(hookData: ["session_id": 5]).sessionId == "")
    }

    @Test("V3: required keys only when context and oauth are nil")
    func testV3_requiredKeysOnly() throws {
        let json = try object(makeEvent())
        #expect(Set(json.keys) == ["event", "timestamp", "hook_data", "account_email"])
    }

    @Test("V4: context is written when present")
    func testV4_contextWrittenWhenPresent() throws {
        let json = try object(makeEvent(context: ["cwd": "/tmp/p"]))
        let context = try #require(json["context"] as? [String: String])
        #expect(context == ["cwd": "/tmp/p"])
    }

    @Test("V5: oauth_account_email written when empty, absent when nil")
    func testV5_oauthWrittenWhenEmptyAbsentWhenNil() throws {
        let empty = try object(makeEvent(oauth: ""))
        #expect(empty["oauth_account_email"] as? String == "")
        let none = try object(makeEvent(oauth: nil))
        #expect(none["oauth_account_email"] == nil)
    }

    @Test("V6: round trip through the drop-file parser")
    func testV6_roundTripThroughParser() throws {
        let event = makeEvent(context: ["cwd": "/tmp/p"])
        guard case .event(let parsed) = try parse(event) else {
            Issue.record("expected .event")
            return
        }
        #expect(parsed.eventType == "PreToolUse")
        #expect(parsed.timestamp == "2026-01-01T00:00:00Z")
        #expect(parsed.sessionId == "s-rt")
        #expect(parsed.accountEmail == "a@b.c")
        #expect(parsed.context?["cwd"] as? String == "/tmp/p")
    }

    @Test("V7: an envelope for a quarantined event is readable by the parser")
    func testV7_quarantinedEnvelopeReadable() throws {
        let event = makeEvent(type: "doomed", hookData: ["session_id": "s-q"])
        guard case .event(let parsed) = try parse(event) else {
            Issue.record("expected .event")
            return
        }
        #expect(parsed.sessionId == "s-q")
    }

    @Test("V8: oauthAccountEmail round-trips nil, empty and a value")
    func testV8_oauthRoundTrips() throws {
        for value in [nil, "", "me@x.y"] as [String?] {
            guard case .event(let parsed) = try parse(makeEvent(oauth: value)) else {
                Issue.record("expected .event")
                return
            }
            #expect(parsed.oauthAccountEmail == value)
        }
    }

    @Test("V9: an empty event type encodes and parses as unparseable")
    func testV9_emptyEventTypeUnparseable() throws {
        let event = makeEvent(type: "", hookData: ["session_id": "s-u"])
        guard case .unparseable = try parse(event) else {
            Issue.record("expected .unparseable")
            return
        }
    }

    @Test("V10: an empty session id encodes and parses as skip")
    func testV10_emptySessionIdSkips() throws {
        let event = makeEvent(type: "StatusLine", hookData: ["session_id": ""])
        guard case .skip = try parse(event) else {
            Issue.record("expected .skip")
            return
        }
    }

    @Test("V11: a Date in hookData throws notSerializable")
    func testV11_dateInHookDataThrows() {
        let event = makeEvent(hookData: ["session_id": "s", "when": Date()])
        do {
            _ = try event.envelopeJSON()
            Issue.record("expected throw")
        } catch EnvelopeEncodingError.notSerializable(let type) {
            #expect(type == "PreToolUse")
        } catch {
            Issue.record("wrong error \(error)")
        }
    }

    @Test("V12: NaN in hookData throws notSerializable")
    func testV12_nanThrows() {
        let event = makeEvent(hookData: ["session_id": "s", "num": Double.nan])
        #expect(throws: EnvelopeEncodingError.self) { try event.envelopeJSON() }
    }

    @Test("V13: error description names the event type")
    func testV13_errorDescription() {
        #expect(EnvelopeEncodingError.notSerializable("Stop").errorDescription
                == "Stop payload is not JSON-serializable")
    }

    @Test("V14: a bad value in context only still throws")
    func testV14_badContextThrows() {
        let event = makeEvent(context: ["when": Date()])
        #expect(throws: EnvelopeEncodingError.self) { try event.envelopeJSON() }
    }

    @Test("V15: error description keeps the leading space for an empty type")
    func testV15_emptyTypeDescription() {
        #expect(EnvelopeEncodingError.notSerializable("").errorDescription
                == " payload is not JSON-serializable")
    }

    @Test("V16: timestamp and account_email are JSON strings")
    func testV16_timestampAndAccountAreStrings() throws {
        let json = try object(makeEvent(timestamp: "x", account: ""))
        #expect(json["timestamp"] as? String == "x")
        #expect(json["account_email"] as? String == "")
    }
}
