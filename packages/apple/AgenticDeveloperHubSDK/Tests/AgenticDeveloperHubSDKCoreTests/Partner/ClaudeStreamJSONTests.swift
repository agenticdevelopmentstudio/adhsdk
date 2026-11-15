import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Claude stream-json") struct ClaudeStreamJSONTests {
    @Test func decodesAssistantTextAndToolUse() throws {
        let line = #"{"type":"assistant","session_id":"s","message":{"role":"assistant","content":["# +
            #"{"type":"text","text":"hi"},"# +
            #"{"type":"tool_use","id":"t1","name":"mcp__adkitchen__partner_notify","input":{}}]}}"#
        let msg = try ClaudeStreamMessage.decode(Data(line.utf8))
        let tool = msg.blocks[1].name
        #expect(msg.kind == .assistant && msg.blocks.count == 2 && tool == "mcp__adkitchen__partner_notify")
    }
    @Test func decodesResultError() throws {
        let line = #"{"type":"result","subtype":"error_max_turns","is_error":true,"result":"x","session_id":"s"}"#
        let msg = try ClaudeStreamMessage.decode(Data(line.utf8))
        #expect(msg.kind == .result && msg.isError && msg.subtype == "error_max_turns")
    }
    @Test func decodesClaudesUnknownSessionResult() throws {
        let msg = try ClaudeStreamMessage.decode(ClaudeStreamFixtures.unknownSessionResultLine())
        #expect(msg.kind == .result && msg.isError && msg.subtype == "error_during_execution")
        #expect(msg.numTurns == 0)
        #expect(msg.errors == ["No conversation found with session ID: 11111111-2222-3333-4444-555555555555"])
        #expect(msg.reportsLostSession)
    }
    @Test func anOrdinaryResultDoesNotReportALostSession() throws {
        let success = #"{"type":"result","subtype":"success","is_error":false,"num_turns":1,"result":"x"}"#
        let failedTurn = #"{"type":"result","subtype":"error_max_turns","is_error":true,"num_turns":3}"#
        #expect(try !ClaudeStreamMessage.decode(Data(success.utf8)).reportsLostSession)
        #expect(try !ClaudeStreamMessage.decode(Data(failedTurn.utf8)).reportsLostSession)
        #expect(try ClaudeStreamMessage.decode(Data(success.utf8)).errors.isEmpty)
    }
    @Test func anErrorBeforeAnyTurnIsNotALostSessionUnlessItSaysSo() throws {
        let auth = #"{"type":"result","subtype":"error_during_execution","is_error":true,"num_turns":0,"#
            + #""errors":["Invalid API key"]}"#
        #expect(try !ClaudeStreamMessage.decode(Data(auth.utf8)).reportsLostSession)
    }
    @Test func unknownTypeIsOther() throws {
        let msg = try ClaudeStreamMessage.decode(Data(#"{"type":"stream_event","event":{}}"#.utf8))
        #expect(msg.kind == .other("stream_event"))
    }
    @Test func nonJSONThrows() {
        #expect(throws: DecodingError.self) { try ClaudeStreamMessage.decode(Data("nope".utf8)) }
    }
    @Test func systemInitDecodes() throws {
        let msg = try ClaudeStreamMessage.decode(Data(#"{"type":"system","subtype":"init","session_id":"s"}"#.utf8))
        #expect(msg.kind == .systemInit && msg.sessionID == "s")
    }
    @Test func userMessageLineShape() throws {
        let data = ClaudeStreamInput.userMessage("hello")
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(obj?["type"] as? String == "user")
        let message = obj?["message"] as? [String: Any]
        let content = message?["content"] as? [[String: Any]]
        #expect(message?["role"] as? String == "user" && content?.first?["text"] as? String == "hello")
        #expect(ClaudeStreamInput.userMessage("x").last == 0x0A)
    }

    private func decode(_ json: String) throws -> ClaudeStreamMessage {
        try ClaudeStreamMessage.decode(Data(json.utf8))
    }
    private func contentBlocks(_ element: String) throws -> [ClaudeStreamMessage.Block] {
        try decode(#"{"type":"user","message":{"role":"user","content":["# + element + "]}}").blocks
    }
    @Test("claude-stream-json-010: a non-init system message is other with its subtype")
    func nonInitSystemIsOther() throws {
        let msg = try decode(#"{"type":"system","subtype":"api_retry"}"#)
        #expect(msg.kind == .other("system") && msg.subtype == "api_retry")
    }
    @Test("claude-stream-json-011: an empty object decodes to empty defaults")
    func emptyObjectDecodesToDefaults() throws {
        let msg = try decode("{}")
        #expect(msg.kind == .other("") && msg.blocks.isEmpty && !msg.isError && msg.errors.isEmpty)
    }
    @Test("claude-stream-json-012: a top-level array throws not a JSON object")
    func topLevelArrayThrows() {
        do {
            _ = try ClaudeStreamMessage.decode(Data("[1,2]".utf8))
            Issue.record("expected a throw")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.debugDescription == "not a JSON object")
        } catch {
            Issue.record("wrong error \(error)")
        }
    }
    @Test("claude-stream-json-013: empty data throws not JSON")
    func emptyDataThrows() {
        do {
            _ = try ClaudeStreamMessage.decode(Data())
            Issue.record("expected a throw")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.debugDescription == "not JSON")
        } catch {
            Issue.record("wrong error \(error)")
        }
    }
    @Test("claude-stream-json-014: string content becomes one text block")
    func stringContentBecomesTextBlock() throws {
        let msg = try decode(#"{"type":"user","message":{"role":"user","content":"plain"}}"#)
        #expect(msg.blocks == [ClaudeStreamMessage.Block(kind: .text, text: "plain")])
    }
    @Test("claude-stream-json-015: a thinking block carries its thinking text")
    func thinkingBlock() throws {
        let blocks = try contentBlocks(#"{"type":"thinking","thinking":"hmm"}"#)
        #expect(blocks == [ClaudeStreamMessage.Block(kind: .thinking, text: "hmm")])
    }
    @Test("claude-stream-json-016: a tool_result with string content")
    func toolResultString() throws {
        let blocks = try contentBlocks(#"{"type":"tool_result","tool_use_id":"t1","content":"ok"}"#)
        #expect(blocks == [ClaudeStreamMessage.Block(kind: .toolResult, text: "ok", toolUseID: "t1")])
    }
    @Test("claude-stream-json-017: tool_result parts join their text with newlines")
    func toolResultParts() throws {
        let element = #"{"type":"tool_result","tool_use_id":"t1","content":["#
            + #"{"type":"text","text":"a"},{"type":"image"},{"type":"text","text":"b"}]}"#
        let blocks = try contentBlocks(element)
        #expect(blocks.first?.kind == .toolResult && blocks.first?.text == "a\nb")
    }
    @Test("claude-stream-json-018: a tool_result without content has nil text")
    func toolResultNoContent() throws {
        let blocks = try contentBlocks(#"{"type":"tool_result","tool_use_id":"t1"}"#)
        #expect(blocks.first?.kind == .toolResult && blocks.first?.text == nil)
    }
    @Test("claude-stream-json-019: an unknown block type is other with nil fields")
    func unknownBlockIsOther() throws {
        let blocks = try contentBlocks(#"{"type":"image"}"#)
        #expect(blocks == [ClaudeStreamMessage.Block(kind: .other)])
    }
    @Test("claude-stream-json-020: non-string errors are dropped")
    func nonStringErrorsDropped() throws {
        let msg = try decode(#"{"type":"result","errors":["a",1,"b"]}"#)
        #expect(msg.errors == ["a", "b"])
    }
    @Test("claude-stream-json-021: user message does not escape slashes")
    func userMessageKeepsSlashes() throws {
        let text = String(bytes: ClaudeStreamInput.userMessage("a/b"), encoding: .utf8) ?? ""
        #expect(text.contains("a/b") && !text.contains("a\\/b"))
    }
}
