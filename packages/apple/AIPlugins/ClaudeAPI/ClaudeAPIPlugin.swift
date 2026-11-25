import Foundation
import AIPluginKit

/// LLM plugin for the Anthropic Messages API with SSE streaming.
///
/// Foundation-only: it *describes* the HTTP request and *decodes* the SSE
/// response. The host owns the transport, the settings UI (generated from
/// `descriptor.json`), and the API key (injected through `AIChatContext.config`).
///
/// Tools are native: the context's tools go out as `tools`, tool calls and
/// results travel as `tool_use` / `tool_result` content blocks, and a thinking
/// budget turns on extended thinking.
public final class ClaudeAPIPlugin: NSObject, AIPlugin, @unchecked Sendable {

    public override init() { super.init() }

    public func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        guard let apiKey = context.config.apiKey, !apiKey.isEmpty else {
            throw PluginError.missingAPIKey
        }
        let base = context.config.baseURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = (base?.isEmpty == false) ? base! : "https://api.anthropic.com/v1"
        guard let url = URL(string: baseURL)?.appendingPathComponent("messages") else {
            throw PluginError.invalidURL
        }

        let model = context.model.isEmpty ? "claude-haiku-4-5-20251001" : context.model
        var body: [String: Any] = [
            "model": model,
            "max_tokens": context.maxTokens,
            "messages": ClaudeAPIMessages.apiMessages(from: context.messages),
            "stream": true
        ]
        if let systemPrompt = context.systemPrompt, !systemPrompt.isEmpty {
            body["system"] = systemPrompt
        }
        if !context.tools.isEmpty {
            body["tools"] = try context.tools.map(ClaudeAPIMessages.apiTool)
        }
        if let thinking = ClaudeAPIThinking.parameter(
            model: model,
            budgetTokens: context.thinkingBudgetTokens,
            messages: context.messages
        ) {
            body["thinking"] = thinking.parameter
            body["max_tokens"] = thinking.maxTokens(forRequested: context.maxTokens)
        }

        var headers = [
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        ]
        if context.config["authMode"] == "bearer-oauth" {
            // A `claude setup-token` subscription credential, authenticated like
            // the official client for OAuth calls (cf. scripts/claude-account).
            headers["Authorization"] = "Bearer \(apiKey)"
            headers["anthropic-beta"] = "oauth-2025-04-20"
        } else {
            headers["x-api-key"] = apiKey
        }

        return .http(
            method: .post,
            url: url,
            headers: headers,
            body: try JSONSerialization.data(withJSONObject: body)
        )
    }

    public func makeDecoder() -> any AIStreamDecoder { ClaudeSSEDecoder() }

    public func describeError(status: Int, body: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    enum PluginError: Error, LocalizedError {
        case missingAPIKey
        case invalidURL
        case invalidToolSchema(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "An Anthropic API key is required."
            case .invalidURL: return "The Anthropic API URL is invalid."
            case .invalidToolSchema(let name):
                return "The tool \"\(name)\" has a parameter schema that is not a JSON object."
            }
        }
    }
}

/// Turns the host's conversation into Messages API `messages` and `tools`.
enum ClaudeAPIMessages {

    /// One API message per run of same-role messages: a tool call joins the
    /// assistant turn it belongs to, and a tool result joins the user turn
    /// that answers it, which is the alternation the API requires. A turn that
    /// is a single piece of text keeps the plain string form.
    static func apiMessages(from messages: [AIChatMessage]) -> [[String: Any]] {
        var turns: [(role: String, blocks: [[String: Any]])] = []
        for message in messages {
            guard let entry = roleAndBlock(for: message) else { continue }
            let (role, block) = entry
            if let last = turns.last, last.role == role {
                turns[turns.count - 1].blocks.append(block)
            } else {
                turns.append((role, [block]))
            }
        }
        return turns.map { turn in
            if turn.blocks.count == 1, turn.blocks[0]["type"] as? String == "text",
               let text = turn.blocks[0]["text"] as? String {
                return ["role": turn.role, "content": text]
            }
            return ["role": turn.role, "content": turn.blocks]
        }
    }

    private static func roleAndBlock(for message: AIChatMessage) -> (String, [String: Any])? {
        switch message.role {
        case .system:
            // The system prompt travels in `system`, never as a message.
            return nil
        case .user:
            return ("user", ["type": "text", "text": message.content])
        case .assistant:
            return ("assistant", ["type": "text", "text": message.content])
        case .toolUse:
            let input = message.toolArgumentsJSON
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            return ("assistant", [
                "type": "tool_use",
                "id": message.toolUseId ?? "",
                "name": message.toolName ?? "",
                "input": input
            ])
        case .toolResult:
            var block: [String: Any] = [
                "type": "tool_result",
                "tool_use_id": message.toolUseId ?? "",
                "content": message.content
            ]
            if message.toolIsError == true { block["is_error"] = true }
            return ("user", block)
        }
    }

    static func apiTool(_ tool: AIToolSpec) throws -> [String: Any] {
        let object = try? JSONSerialization.jsonObject(with: tool.parametersJSONSchema)
        guard let schema = object as? [String: Any] else {
            throw ClaudeAPIPlugin.PluginError.invalidToolSchema(tool.name)
        }
        return ["name": tool.name, "description": tool.description, "input_schema": schema]
    }
}

/// The `thinking` request parameter for a thinking budget.
struct ClaudeAPIThinking {

    /// The smallest budget the API accepts.
    static let minimumBudget = 1024

    let parameter: [String: Any]
    let budgetTokens: Int

    /// `max_tokens` covers the thinking as well as the answer, so a budget at
    /// or above the requested ceiling raises it to leave the answer its room.
    func maxTokens(forRequested requested: Int) -> Int {
        requested > budgetTokens ? requested : budgetTokens + requested
    }

    /// `nil` when no thinking is asked for, and when the request continues a
    /// tool loop: the API wants the earlier turn's signed thinking block back
    /// in that case, and the host's conversation does not carry it, so the
    /// continuation goes out without thinking rather than being refused.
    ///
    /// Models before the 4.6 generation take a fixed budget; later ones refuse
    /// it and think adaptively, with the summary asked for so text streams.
    static func parameter(model: String, budgetTokens: Int?, messages: [AIChatMessage]) -> Self? {
        guard let requested = budgetTokens, requested > 0 else { return nil }
        if messages.last(where: { $0.role != .system })?.role == .toolResult { return nil }
        let budget = max(requested, minimumBudget)
        if takesFixedBudget(model) {
            return Self(parameter: ["type": "enabled", "budget_tokens": budget], budgetTokens: budget)
        }
        return Self(parameter: ["type": "adaptive", "display": "summarized"], budgetTokens: budget)
    }

    /// Claude 3 models, and the 4, 4.1 and 4.5 generations, with or without a
    /// date suffix or a provider prefix.
    static func takesFixedBudget(_ model: String) -> Bool {
        let pattern = #"claude-3|claude-(opus|sonnet|haiku)-4(-[015])?(-\d{8})?(?![-.]?\d)"#
        return model.lowercased().range(of: pattern, options: .regularExpression) != nil
    }
}

/// Decodes the Anthropic Messages API server-sent-event stream. Each `data:`
/// line carries a JSON event:
///
/// - `message_start` and `message_delta` carry usage, emitted as a running total;
/// - `content_block_start` opens a text, thinking or tool-use block at an index;
/// - `content_block_delta` streams text (`text_delta`), reasoning
///   (`thinking_delta`) or a tool's arguments (`input_json_delta`, gathered per
///   block until `content_block_stop` emits the whole `toolUse`);
/// - `message_delta`'s `stop_reason` ends the response; `message_stop` and
///   `[DONE]` end it when no reason came first. The decoder ends a response once.
final class ClaudeSSEDecoder: AIStreamDecoder {

    private struct ToolBlock {
        let toolUseId: String
        let name: String
        var argumentsJSON: String
    }

    private var buffer = Data()
    private var toolBlocks: [Int: ToolBlock] = [:]
    private var usage = AIUsage()
    private var ended = false

    func consume(_ data: Data) -> [AIStreamEvent] {
        buffer.append(data)
        return drainLines(flushRemainder: false)
    }

    func finish() -> [AIStreamEvent] {
        drainLines(flushRemainder: true)
    }

    private func drainLines(flushRemainder: Bool) -> [AIStreamEvent] {
        var events: [AIStreamEvent] = []
        while let newline = buffer.firstIndex(of: 0x0A) {
            let lineData = Data(buffer[buffer.startIndex..<newline])
            buffer.removeSubrange(buffer.startIndex...newline)
            events += parse(lineData)
        }
        if flushRemainder, !buffer.isEmpty {
            events += parse(buffer)
            buffer.removeAll()
        }
        return events
    }

    private func parse(_ lineData: Data) -> [AIStreamEvent] {
        guard let line = String(data: lineData, encoding: .utf8) else { return [] }
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("data:") else { return [] }

        let payload = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
        if payload == "[DONE]" { return end(stopReason: nil) }

        guard let json = try? JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any],
              let eventType = json["type"] as? String else {
            return []
        }

        switch eventType {
        case "message_start":
            let message = json["message"] as? [String: Any]
            return applyUsage(message?["usage"] as? [String: Any])
        case "content_block_start":
            return startBlock(json)
        case "content_block_delta":
            return delta(json)
        case "content_block_stop":
            return stopBlock(json)
        case "message_delta":
            var events = applyUsage(json["usage"] as? [String: Any])
            if let delta = json["delta"] as? [String: Any], let reason = delta["stop_reason"] as? String {
                events += end(stopReason: reason)
            }
            return events
        case "message_stop":
            return end(stopReason: nil)
        default:
            return []
        }
    }

    private func startBlock(_ json: [String: Any]) -> [AIStreamEvent] {
        guard let index = json["index"] as? Int,
              let block = json["content_block"] as? [String: Any] else { return [] }
        switch block["type"] as? String {
        case "tool_use":
            toolBlocks[index] = ToolBlock(
                toolUseId: block["id"] as? String ?? "",
                name: block["name"] as? String ?? "",
                argumentsJSON: ""
            )
            return []
        case "text":
            let text = block["text"] as? String ?? ""
            return text.isEmpty ? [] : [.textDelta(text)]
        case "thinking":
            let thinking = block["thinking"] as? String ?? ""
            return thinking.isEmpty ? [] : [.thinkingDelta(thinking)]
        default:
            return []
        }
    }

    private func delta(_ json: [String: Any]) -> [AIStreamEvent] {
        guard let delta = json["delta"] as? [String: Any] else { return [] }
        switch delta["type"] as? String {
        case "thinking_delta":
            guard let thinking = delta["thinking"] as? String, !thinking.isEmpty else { return [] }
            return [.thinkingDelta(thinking)]
        case "input_json_delta":
            guard let index = json["index"] as? Int,
                  let partial = delta["partial_json"] as? String else { return [] }
            toolBlocks[index]?.argumentsJSON += partial
            return []
        case "text_delta", nil:
            // A delta without a type is read as text, as earlier streams sent it.
            guard let text = delta["text"] as? String else { return [] }
            return [.textDelta(text)]
        default:
            // `signature_delta` and anything newer carry nothing to show.
            return []
        }
    }

    private func stopBlock(_ json: [String: Any]) -> [AIStreamEvent] {
        guard let index = json["index"] as? Int, let tool = toolBlocks.removeValue(forKey: index) else {
            return []
        }
        let arguments = tool.argumentsJSON.isEmpty ? "{}" : tool.argumentsJSON
        return [.toolUse(id: tool.toolUseId, name: tool.name, argumentsJSON: Data(arguments.utf8))]
    }

    /// Folds a usage object into the running total. `message_start` reports
    /// the input side, and each `message_delta` the output so far; a count a
    /// frame leaves out keeps its earlier value.
    private func applyUsage(_ object: [String: Any]?) -> [AIStreamEvent] {
        guard let object else { return [] }
        if let value = object["input_tokens"] as? Int { usage.inputTokens = value }
        if let value = object["output_tokens"] as? Int { usage.outputTokens = value }
        if let value = object["cache_read_input_tokens"] as? Int { usage.cacheReadTokens = value }
        if let value = object["cache_creation_input_tokens"] as? Int { usage.cacheWriteTokens = value }
        return [.usage(usage)]
    }

    private func end(stopReason: String?) -> [AIStreamEvent] {
        guard !ended else { return [] }
        ended = true
        return [.end(stopReason: stopReason)]
    }
}
