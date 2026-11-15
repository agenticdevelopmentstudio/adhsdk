import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct ParseResultConformanceTests {

    private func event(_ result: ParseResult) -> ParsedEvent? {
        if case .event(let parsed) = result { return parsed }
        return nil
    }

    private func isLost(_ result: ParseResult) -> Bool {
        if case .lostEvent = result { return true }
        return false
    }

    private func isUnparseable(_ result: ParseResult) -> Bool {
        if case .unparseable = result { return true }
        return false
    }

    private func skipReason(_ result: ParseResult) -> String? {
        if case .skip(let reason) = result { return reason }
        return nil
    }

    @Test("parse-result-001: empty string is a lost event")
    func emptyIsLost() {
        #expect(isLost(ParseResult.parse(envelopeJSON: "")))
    }

    @Test("parse-result-002: whitespace only is a lost event")
    func whitespaceIsLost() {
        #expect(isLost(ParseResult.parse(envelopeJSON: "  \n\t ")))
    }

    @Test("parse-result-003: malformed JSON is unparseable")
    func malformedIsUnparseable() {
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: "{not json")))
    }

    @Test("parse-result-004: a non-object top level is unparseable")
    func nonObjectIsUnparseable() {
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: "[]")))
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: "null")))
    }

    @Test("parse-result-005: a missing event is unparseable")
    func missingEventIsUnparseable() {
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: #"{"hook_data":{"session_id":"s1"}}"#)))
    }

    @Test("parse-result-006: an empty event is unparseable")
    func emptyEventIsUnparseable() {
        let json = #"{"event":"","hook_data":{"session_id":"s-u"}}"#
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: json)))
    }

    @Test("parse-result-007: a non-string event is unparseable")
    func numericEventIsUnparseable() {
        let json = #"{"event":5,"hook_data":{"session_id":"s1"}}"#
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: json)))
    }

    @Test("parse-result-008: no session_id is a skip")
    func missingSessionIsSkip() {
        let json = #"{"event":"StatusLine","hook_data":{"term_session_id":"t1"}}"#
        #expect(skipReason(ParseResult.parse(envelopeJSON: json))
                == "no session_id — not a trackable session event")
    }

    @Test("parse-result-009: non-object hook_data falls back to a skip")
    func hookDataFallbackIsSkip() {
        let json = #"{"event":"Stop","hook_data":[]}"#
        #expect(skipReason(ParseResult.parse(envelopeJSON: json)) != nil)
    }

    @Test("parse-result-010: the event check comes before the session check")
    func eventCheckComesFirst() {
        let result = ParseResult.parse(envelopeJSON: #"{"hook_data":{}}"#)
        #expect(isUnparseable(result))
        #expect(skipReason(result) == nil)
    }

    @Test("parse-result-011: a minimal envelope gets defaults")
    func minimalEnvelopeDefaults() throws {
        let json = #"{"event":"PreToolUse","hook_data":{"session_id":"s1"}}"#
        let parsed = try #require(event(ParseResult.parse(envelopeJSON: json)))
        #expect(parsed.eventType == "PreToolUse")
        #expect(parsed.timestamp == "")
        #expect(parsed.accountEmail == "")
        #expect(parsed.context == nil)
        #expect(parsed.oauthAccountEmail == nil)
        #expect(parsed.hookData as? [String: String] == ["session_id": "s1"])
    }

    @Test("parse-result-012: an envelope round trips through the parser")
    func envelopeRoundTrips() throws {
        let original = ParsedEvent(
            eventType: "PreToolUse",
            timestamp: "2026-01-01T00:00:00Z",
            hookData: ["session_id": "s-rt", "tool_name": "Bash"],
            context: ["cwd": "/tmp/p"],
            accountEmail: "a@b.c")
        let data = try original.envelopeJSON()
        let text = try #require(String(data: data, encoding: .utf8))
        let parsed = try #require(event(ParseResult.parse(envelopeJSON: text)))
        #expect(parsed.eventType == "PreToolUse")
        #expect(parsed.timestamp == "2026-01-01T00:00:00Z")
        #expect(parsed.sessionId == "s-rt")
        #expect(parsed.accountEmail == "a@b.c")
        #expect(parsed.context?["cwd"] as? String == "/tmp/p")
    }

    @Test("parse-result-013: a quarantined file is read by the parser",
          .disabled("Covered by IngestDrainerTests in the Database target; needs the drainer"))
    func quarantinedFileIsReadable() {}

    @Test("parse-result-014: oauth_account_email keeps empty, value and absent apart")
    func oauthEmailVariants() throws {
        func oauth(_ field: String) throws -> String? {
            let json = #"{"event":"Stop",\#(field)"hook_data":{"session_id":"s1"}}"#
            return try #require(event(ParseResult.parse(envelopeJSON: json))).oauthAccountEmail
        }
        #expect(try oauth(#""oauth_account_email":"","#) == "")
        #expect(try oauth(#""oauth_account_email":"me@x.y","#) == "me@x.y")
        #expect(try oauth("") == nil)
        #expect(try oauth(#""oauth_account_email":null,"#) == nil)
    }

    @Test("parse-result-015: a non-object context is dropped")
    func stringContextIsNil() throws {
        let json = #"{"event":"Stop","context":"text","hook_data":{"session_id":"s1"}}"#
        let parsed = try #require(event(ParseResult.parse(envelopeJSON: json)))
        #expect(parsed.context == nil)
    }

    @Test("parse-result-016: unknown keys are ignored")
    func extraKeysIgnored() throws {
        let json = #"{"event":"PreToolUse","unknown":1,"hook_data":{"session_id":"s1"}}"#
        let parsed = try #require(event(ParseResult.parse(envelopeJSON: json)))
        #expect(parsed.eventType == "PreToolUse")
        #expect(parsed.timestamp == "")
        #expect(parsed.accountEmail == "")
        #expect(parsed.context == nil)
        #expect(parsed.oauthAccountEmail == nil)
        #expect(parsed.sessionId == "s1")
    }

    @Test("parse-result-017: trailing text after the object is unparseable")
    func trailingTextIsUnparseable() {
        let json = #"{"event":"Stop","hook_data":{"session_id":"s1"}} trailing"#
        #expect(isUnparseable(ParseResult.parse(envelopeJSON: json)))
    }

    @Test("parse-result-018: JSON null fields read as absent")
    func nullFieldsAreAbsent() throws {
        let json = #"{"event":"Stop","timestamp":null,"account_email":null,"hook_data":{"session_id":"s1"}}"#
        let parsed = try #require(event(ParseResult.parse(envelopeJSON: json)))
        #expect(parsed.timestamp == "")
        #expect(parsed.accountEmail == "")
    }
}
