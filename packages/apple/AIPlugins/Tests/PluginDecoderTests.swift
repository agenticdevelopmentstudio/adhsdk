import Foundation
import Testing
import AIPluginKit

/// Tests each plugin's stream decoder: how it turns provider bytes into
/// `AIStreamEvent`s. Covers the two distinct shapes — Anthropic's incremental
/// SSE stream (with partial frames split across reads) and the buffered
/// whole-response JSON decoders shared by the OpenAI/Google/compatible plugins —
/// plus the plain-text passthrough used by the local CLI plugin.
@Suite("AI plugin stream decoding")
struct PluginDecoderTests {

    private func textDeltas(_ events: [AIStreamEvent]) -> String {
        events.reduce(into: "") { result, event in
            if case let .textDelta(text) = event { result += text }
        }
    }

    private func containsEnd(_ events: [AIStreamEvent]) -> Bool {
        events.contains { event in
            if case .end = event { return true }
            return false
        }
    }

    @Test("ClaudeSSEDecoder assembles a content delta split across two reads")
    func claudeSSEDecoderBuffersFrames() {
        let decoder = ClaudeSSEDecoder()
        let frameStart = "data: {\"type\":\"content_block_delta\",\"delta\":{\"text\":\"Hel"
        // First read stops mid-frame (no newline yet): nothing decodable.
        #expect(decoder.consume(Data(frameStart.utf8)).isEmpty)
        // Second read completes the line and yields the buffered text.
        let events = decoder.consume(Data("lo\"}}\n".utf8))
        #expect(textDeltas(events) == "Hello")
    }

    @Test("ClaudeSSEDecoder ends the stream on message_stop and on [DONE]")
    func claudeSSEDecoderEnds() {
        #expect(containsEnd(ClaudeSSEDecoder().consume(Data("data: {\"type\":\"message_stop\"}\n".utf8))))
        #expect(containsEnd(ClaudeSSEDecoder().consume(Data("data: [DONE]\n".utf8))))
    }

    @Test("OpenAIReplyDecoder buffers the JSON body and emits content on finish")
    func openAIReplyDecoder() {
        let body = "{\"choices\":[{\"message\":{\"role\":\"assistant\",\"content\":\"Hi there\"}}]}"
        let split = body.index(body.startIndex, offsetBy: 25)
        let decoder = OpenAIReplyDecoder()
        // Buffered decoders emit nothing until the stream closes.
        #expect(decoder.consume(Data(body[..<split].utf8)).isEmpty)
        #expect(decoder.consume(Data(body[split...].utf8)).isEmpty)
        let final = decoder.finish()
        #expect(textDeltas(final) == "Hi there")
        #expect(containsEnd(final))
    }

    @Test("GeminiReplyDecoder extracts the candidate text on finish")
    func geminiReplyDecoder() {
        let body = "{\"candidates\":[{\"content\":{\"parts\":[{\"text\":\"Hey\"}]}}]}"
        let decoder = GeminiReplyDecoder()
        #expect(decoder.consume(Data(body.utf8)).isEmpty)
        let final = decoder.finish()
        #expect(textDeltas(final) == "Hey")
        #expect(containsEnd(final))
    }

    @Test("PlainTextDecoder passes stdout chunks through and ignores empty chunks")
    func plainTextDecoder() {
        let decoder = PlainTextDecoder()
        #expect(textDeltas(decoder.consume(Data("partial answer".utf8))) == "partial answer")
        #expect(decoder.consume(Data()).isEmpty)
        #expect(containsEnd(decoder.finish()))
    }

    // MARK: - Thinking, native tools, usage

    private func sse(_ objects: [String]) -> Data {
        Data(objects.map { "event: x\ndata: \($0)\n\n" }.joined().utf8)
    }

    private func thinking(_ events: [AIStreamEvent]) -> String {
        events.reduce(into: "") { result, event in
            if case let .thinkingDelta(text) = event { result += text }
        }
    }

    private func toolUses(_ events: [AIStreamEvent]) -> [(id: String, name: String, arguments: String)] {
        events.compactMap { event in
            guard case let .toolUse(id, name, arguments) = event else { return nil }
            return (id, name, String(bytes: arguments, encoding: .utf8) ?? "")
        }
    }

    private func usages(_ events: [AIStreamEvent]) -> [AIUsage] {
        events.compactMap { event in
            guard case let .usage(usage) = event else { return nil }
            return usage
        }
    }

    private func endReasons(_ events: [AIStreamEvent]) -> [String?] {
        events.compactMap { event in
            guard case let .end(reason) = event else { return nil }
            return .some(reason)
        }
    }

    @Test("ClaudeSSEDecoder reports usage as a running total (ai-stream-event-018)")
    func claudeSSEDecoderUsageIsCumulative() {
        let events = ClaudeSSEDecoder().consume(sse([
            #"{"type":"message_start","message":{"usage":{"input_tokens":10}}}"#,
            #"{"type":"message_delta","delta":{},"usage":{"output_tokens":7}}"#
        ]))
        #expect(usages(events) == [AIUsage(inputTokens: 10), AIUsage(inputTokens: 10, outputTokens: 7)])
    }

    @Test("ClaudeSSEDecoder reads cache counts from message_start")
    func claudeSSEDecoderCacheUsage() {
        let events = ClaudeSSEDecoder().consume(sse([
            #"{"type":"message_start","message":{"usage":{"input_tokens":3,"output_tokens":1,"#
                + #""cache_read_input_tokens":40,"cache_creation_input_tokens":5}}}"#
        ]))
        #expect(usages(events) == [
            AIUsage(inputTokens: 3, outputTokens: 1, cacheReadTokens: 40, cacheWriteTokens: 5)
        ])
    }

    @Test("ClaudeSSEDecoder separates thinking from text")
    func claudeSSEDecoderThinking() {
        let events = ClaudeSSEDecoder().consume(sse([
            #"{"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}"#,
            #"{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Let me "}}"#,
            #"{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"check"}}"#,
            #"{"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"abc"}}"#,
            #"{"type":"content_block_stop","index":0}"#,
            #"{"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}"#,
            #"{"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Done"}}"#,
            #"{"type":"content_block_stop","index":1}"#
        ]))
        #expect(thinking(events) == "Let me check")
        #expect(textDeltas(events) == "Done")
    }

    @Test("ClaudeSSEDecoder gathers a tool's arguments per block and emits the call at block stop")
    func claudeSSEDecoderToolUse() {
        let decoder = ClaudeSSEDecoder()
        let opening = decoder.consume(sse([
            #"{"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","#
                + #""name":"list_notices","input":{}}}"#,
            #"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"lim"}}"#,
            #"{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"it\":5}"}}"#
        ]))
        // Nothing is emitted until the block closes.
        #expect(toolUses(opening).isEmpty)
        let closing = decoder.consume(sse([#"{"type":"content_block_stop","index":1}"#]))
        let calls = toolUses(closing)
        #expect(calls.count == 1)
        #expect(calls.first?.id == "toolu_1")
        #expect(calls.first?.name == "list_notices")
        #expect(calls.first?.arguments == #"{"limit":5}"#)
    }

    @Test("ClaudeSSEDecoder sends a tool call with no argument deltas as an empty object")
    func claudeSSEDecoderToolUseNoArguments() {
        let events = ClaudeSSEDecoder().consume(sse([
            #"{"type":"content_block_start","index":0,"content_block":{"type":"tool_use","id":"t","name":"now"}}"#,
            #"{"type":"content_block_stop","index":0}"#
        ]))
        #expect(toolUses(events).first?.arguments == "{}")
    }

    @Test("ClaudeSSEDecoder ends once, with message_delta's stop_reason")
    func claudeSSEDecoderStopReason() {
        let events = ClaudeSSEDecoder().consume(sse([
            #"{"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":9}}"#,
            #"{"type":"message_stop"}"#
        ]))
        #expect(endReasons(events) == ["tool_use"])
        #expect(usages(events).last?.outputTokens == 9)
    }

    @Test("OpenAIReplyDecoder emits reasoning, tool calls, usage and the finish reason")
    func openAIReplyDecoderToolCalls() {
        let body = #"{"choices":[{"finish_reason":"tool_calls","message":{"role":"assistant","content":null,"#
            + #""reasoning_content":"Need the list","tool_calls":[{"id":"call_1","type":"function","#
            + #""function":{"name":"list_notices","arguments":"{\"limit\":5}"}}]}}],"#
            + #""usage":{"prompt_tokens":100,"completion_tokens":20,"prompt_tokens_details":{"cached_tokens":60}}}"#
        let decoder = OpenAIReplyDecoder()
        #expect(decoder.consume(Data(body.utf8)).isEmpty)
        let events = decoder.finish()
        #expect(thinking(events) == "Need the list")
        #expect(textDeltas(events).isEmpty)
        let calls = toolUses(events)
        #expect(calls.count == 1)
        #expect(calls.first?.id == "call_1")
        #expect(calls.first?.name == "list_notices")
        #expect(calls.first?.arguments == #"{"limit":5}"#)
        #expect(usages(events) == [AIUsage(inputTokens: 40, outputTokens: 20, cacheReadTokens: 60)])
        #expect(endReasons(events) == ["tool_calls"])
    }

    @Test("OpenAICompatibleReplyDecoder reads `reasoning`, object arguments and usage")
    func openAICompatibleReplyDecoderToolCalls() {
        let body = #"{"choices":[{"finish_reason":"tool_calls","message":{"role":"assistant","content":"","#
            + #""reasoning":"Thinking","tool_calls":[{"id":"c9","function":{"name":"archive","#
            + #""arguments":{"id":"n1"}}}]}}],"usage":{"prompt_tokens":12,"completion_tokens":3}}"#
        let decoder = OpenAICompatibleReplyDecoder()
        #expect(decoder.consume(Data(body.utf8)).isEmpty)
        let events = decoder.finish()
        #expect(thinking(events) == "Thinking")
        #expect(textDeltas(events).isEmpty)
        let calls = toolUses(events)
        #expect(calls.first?.name == "archive")
        #expect(calls.first?.arguments == #"{"id":"n1"}"#)
        #expect(usages(events) == [AIUsage(inputTokens: 12, outputTokens: 3)])
        #expect(endReasons(events) == ["tool_calls"])
    }

    @Test("OpenAICompatibleReplyDecoder keeps a plain reply a single text event")
    func openAICompatibleReplyDecoderText() {
        let body = #"{"choices":[{"finish_reason":"stop","message":{"role":"assistant","content":"Hi"}}]}"#
        let decoder = OpenAICompatibleReplyDecoder()
        _ = decoder.consume(Data(body.utf8))
        let events = decoder.finish()
        #expect(textDeltas(events) == "Hi")
        #expect(usages(events).isEmpty)
        #expect(endReasons(events) == ["stop"])
    }
}
