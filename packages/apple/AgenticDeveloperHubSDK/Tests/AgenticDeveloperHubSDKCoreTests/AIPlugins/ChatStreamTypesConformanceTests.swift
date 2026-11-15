import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

@Suite("ChatStreamTypes conformance")
struct ChatStreamTypesConformanceTests {

    // MARK: - ChatStreamEvent

    @Test("chat-tool-types-001: the stream event has exactly three cases and is Sendable")
    func testV001_streamEventHasExactlyThreeCasesAndIsSendable() {
        // An exhaustive switch with no `default` compiles only while the case set is exactly these three.
        func label(_ event: ChatStreamEvent) -> String {
            switch event {
            case .textDelta: return "textDelta"
            case .toolUse: return "toolUse"
            case .end: return "end"
            }
        }
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let events: [ChatStreamEvent] = [
            .textDelta("a"), .toolUse(id: "i", name: "n", argumentsJSON: Data()), .end(stopReason: nil)
        ]
        #expect(requireSendable(events).map(label) == ["textDelta", "toolUse", "end"])
    }

    @Test("chat-tool-types-002: a text delta carries just its chunk")
    func testV002_textDeltaPayload() {
        let event = ChatStreamEvent.textDelta("Hello")
        guard case .textDelta(let chunk) = event else {
            Issue.record("expected .textDelta"); return
        }
        #expect(chunk == "Hello")
    }

    @Test("chat-tool-types-003: tool use carries id, name and the raw argument bytes unchanged")
    func testV003_toolUsePayloadKeepsRawBytes() {
        let raw = Data(#"{"q":"cats"}"#.utf8)
        let event = ChatStreamEvent.toolUse(id: "call_1", name: "search", argumentsJSON: raw)
        guard case .toolUse(let id, let name, let args) = event else {
            Issue.record("expected .toolUse"); return
        }
        #expect(id == "call_1")
        #expect(name == "search")
        #expect(args == raw)
        #expect(Array(args) == Array(raw))
    }

    @Test("chat-tool-types-004: an end event with no stop reason reads absent")
    func testV004_endStopReasonOptional() {
        let event = ChatStreamEvent.end(stopReason: nil)
        guard case .end(let reason) = event else {
            Issue.record("expected .end"); return
        }
        #expect(reason == nil)
    }

    // MARK: - ToolDefinition

    @Test("chat-tool-types-007: a tool definition holds its three fields unchanged")
    func testV007_definitionIdentity() {
        let schema = Data("{}".utf8)
        let def = ToolDefinition(name: "search", description: "Search the web", parametersJSONSchema: schema)
        #expect(def.name == "search")
        #expect(def.description == "Search the web")
        #expect(def.parametersJSONSchema == schema)
    }

    @Test("chat-tool-types-008: tool definition equality covers name, description and schema bytes")
    func testV008_definitionEquality() {
        let first = ToolDefinition(
            name: "search", description: "Search the web", parametersJSONSchema: Data("{}".utf8))
        let second = ToolDefinition(
            name: "search", description: "Search the web", parametersJSONSchema: Data("{}".utf8))
        let third = ToolDefinition(
            name: "search", description: "Search the web", parametersJSONSchema: Data("{\"a\":1}".utf8))
        #expect(first == second)
        #expect(first != third)
        #expect(second != third)
    }

    @Test("chat-tool-types-009: tool definition fields are immutable",
          .disabled("compile-time property: fields are `let`, so a reassignment does not compile"))
    func testV009_definitionImmutability() {}

    // MARK: - ToolResult

    @Test("chat-tool-types-011: a tool result holds its three fields unchanged")
    func testV011_resultIdentity() {
        let result = ToolResult(toolUseId: "call_1", content: "42", isError: false)
        #expect(result.toolUseId == "call_1")
        #expect(result.content == "42")
        #expect(result.isError == false)
    }

    @Test("chat-tool-types-012: tool result equality covers id, content and error flag")
    func testV012_resultEquality() {
        let first = ToolResult(toolUseId: "call_1", content: "42", isError: false)
        let second = ToolResult(toolUseId: "call_1", content: "42", isError: false)
        let third = ToolResult(toolUseId: "call_1", content: "42", isError: true)
        #expect(first == second)
        #expect(first != third)
        #expect(second != third)
    }

    @Test("chat-tool-types-013: the error flag and content are independent")
    func testV013_resultErrorFlagIndependence() {
        let errorWithoutContent = ToolResult(toolUseId: "a", content: "", isError: true)
        let okWithContent = ToolResult(toolUseId: "b", content: "ok", isError: false)
        #expect(errorWithoutContent.content == "" && errorWithoutContent.isError)
        #expect(okWithContent.content == "ok" && !okWithContent.isError)
    }

    @Test("chat-tool-types-014: tool result fields are immutable",
          .disabled("compile-time property: fields are `let`, so a reassignment does not compile"))
    func testV014_resultImmutability() {}

    // MARK: - Cross-cutting

    @Test("chat-tool-types-015: values cross a concurrency boundary")
    func testV015_crossDomainSafety() async {
        let defs = [
            ToolDefinition(name: "a", description: "A", parametersJSONSchema: Data("{}".utf8)),
            ToolDefinition(name: "b", description: "B", parametersJSONSchema: Data("{}".utf8))
        ]
        let result = ToolResult(toolUseId: "x", content: "y", isError: false)
        let event = ChatStreamEvent.textDelta("hi")
        let seen = await Task.detached { () -> ([String], ToolResult, ChatStreamEvent) in
            (defs.map(\.name), result, event)
        }.value
        #expect(seen.0 == ["a", "b"])
        #expect(seen.1 == result)
        if case .textDelta(let chunk) = seen.2 { #expect(chunk == "hi") } else { Issue.record("expected .textDelta") }
    }

    @Test("chat-tool-types-016: the three shapes reference no I/O",
          .disabled("source-inspection property: a unit test cannot observe the absence of I/O code"))
    func testV016_noPersistenceNoSideEffects() {}

    @Test("chat-tool-types-017: schema bytes are opaque and never validated")
    func testV017_schemaIsOpaque() {
        let junk = Data("not valid json".utf8)
        let def = ToolDefinition(name: "n", description: "d", parametersJSONSchema: junk)
        #expect(def.parametersJSONSchema == junk)
    }
}
