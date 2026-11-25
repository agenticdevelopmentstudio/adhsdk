import Foundation
import AIPluginKit

/// LLM plugin for the OpenAI Chat Completions API.
///
/// Foundation-only: it describes the HTTP request and decodes the JSON reply.
/// The host owns transport, settings UI, and the API key. Tools are native:
/// the context's tools go out as `tools`, and the reply's `tool_calls` come
/// back as `toolUse` events.
public final class OpenAIPlugin: NSObject, AIPlugin, @unchecked Sendable {

    public override init() { super.init() }

    public func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        guard let apiKey = context.config.apiKey, !apiKey.isEmpty else {
            throw PluginError.missingAPIKey
        }
        let model = context.model.isEmpty ? "gpt-4.1-nano" : context.model
        return try OpenAIChatRequest.make(
            baseURL: "https://api.openai.com",
            apiKey: apiKey,
            model: model,
            context: context
        )
    }

    public func makeDecoder() -> any AIStreamDecoder { OpenAIReplyDecoder() }

    public func describeError(status: Int, body: Data) -> String? {
        OpenAIReplyDecoder.parseErrorMessage(from: body)
    }

    enum PluginError: Error, LocalizedError {
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "An OpenAI API key is required."
            }
        }
    }
}

/// Builds an OpenAI Chat Completions request.
enum OpenAIChatRequest {

    static func make(
        baseURL: String,
        apiKey: String,
        model: String,
        context: AIChatContext
    ) throws -> AIRequestSpec {
        guard let url = URL(string: baseURL)?.appendingPathComponent("v1/chat/completions") else {
            throw RequestError.invalidURL
        }

        var body: [String: Any] = [
            "max_tokens": context.maxTokens,
            "messages": apiMessages(systemPrompt: context.systemPrompt, messages: context.messages)
        ]
        if !model.isEmpty { body["model"] = model }
        if !context.tools.isEmpty { body["tools"] = try context.tools.map(apiTool) }

        return .http(
            method: .post,
            url: url,
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "content-type": "application/json"
            ],
            body: try JSONSerialization.data(withJSONObject: body)
        )
    }

    /// The conversation as Chat Completions messages. A tool call joins the
    /// assistant message just before it as one of its `tool_calls` (or opens
    /// an assistant message of its own), and a tool result becomes a `tool`
    /// message answering its call id.
    static func apiMessages(systemPrompt: String?, messages: [AIChatMessage]) -> [[String: Any]] {
        var out: [[String: Any]] = []
        if let systemPrompt, !systemPrompt.isEmpty {
            out.append(["role": "system", "content": systemPrompt])
        }
        for message in messages {
            switch message.role {
            case .system:
                continue
            case .user:
                out.append(["role": "user", "content": message.content])
            case .assistant:
                out.append(["role": "assistant", "content": message.content])
            case .toolUse:
                let arguments = message.toolArgumentsJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                let call: [String: Any] = [
                    "id": message.toolUseId ?? "",
                    "type": "function",
                    "function": ["name": message.toolName ?? "", "arguments": arguments]
                ]
                if var last = out.last, last["role"] as? String == "assistant" {
                    last["tool_calls"] = (last["tool_calls"] as? [[String: Any]] ?? []) + [call]
                    out[out.count - 1] = last
                } else {
                    out.append(["role": "assistant", "content": NSNull(), "tool_calls": [call]])
                }
            case .toolResult:
                out.append([
                    "role": "tool",
                    "tool_call_id": message.toolUseId ?? "",
                    "content": message.content
                ])
            }
        }
        return out
    }

    static func apiTool(_ tool: AIToolSpec) throws -> [String: Any] {
        let object = try? JSONSerialization.jsonObject(with: tool.parametersJSONSchema)
        guard let schema = object as? [String: Any] else {
            throw RequestError.invalidToolSchema(tool.name)
        }
        return [
            "type": "function",
            "function": ["name": tool.name, "description": tool.description, "parameters": schema]
        ]
    }

    enum RequestError: Error, LocalizedError {
        case invalidURL
        case invalidToolSchema(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "The endpoint URL is invalid."
            case .invalidToolSchema(let name):
                return "The tool \"\(name)\" has a parameter schema that is not a JSON object."
            }
        }
    }
}

/// Buffers a full OpenAI Chat Completions JSON response, then emits it on
/// `finish()`: reasoning (`reasoning_content`) as `thinkingDelta`, the answer
/// as `textDelta`, each of `tool_calls` as `toolUse`, `usage`, and `end` with
/// the `finish_reason`. OpenAI's non-streaming responses arrive as one JSON
/// object, so the decoder accumulates everything and parses on `finish()`.
final class OpenAIReplyDecoder: AIStreamDecoder {

    private var buffer = Data()

    func consume(_ data: Data) -> [AIStreamEvent] {
        buffer.append(data)
        return []
    }

    func finish() -> [AIStreamEvent] {
        Self.events(from: buffer)
    }

    static func events(from data: Data) -> [AIStreamEvent] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            return [.textDelta("(Unable to parse response)"), .end(stopReason: nil)]
        }
        var events: [AIStreamEvent] = []
        if let reasoning = message["reasoning_content"] as? String, !reasoning.isEmpty {
            events.append(.thinkingDelta(reasoning))
        }
        if let content = message["content"] as? String, !content.isEmpty {
            events.append(.textDelta(content))
        }
        let calls = message["tool_calls"] as? [[String: Any]] ?? []
        for (offset, call) in calls.enumerated() {
            guard let function = call["function"] as? [String: Any],
                  let name = function["name"] as? String else { continue }
            events.append(.toolUse(
                id: call["id"] as? String ?? "call_\(offset)",
                name: name,
                argumentsJSON: argumentsJSON(function["arguments"])
            ))
        }
        if let usage = usage(from: json["usage"] as? [String: Any]) {
            events.append(.usage(usage))
        }
        events.append(.end(stopReason: first["finish_reason"] as? String))
        return events
    }

    /// Arguments arrive as a JSON string; an empty or missing one is no arguments.
    static func argumentsJSON(_ value: Any?) -> Data {
        if let text = value as? String, !text.isEmpty { return Data(text.utf8) }
        if let object = value as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: object) {
            return data
        }
        return Data("{}".utf8)
    }

    /// `prompt_tokens` counts cached tokens too, so the cached share is moved
    /// to `cacheReadTokens` and `inputTokens` keeps the uncached rest, the same
    /// split the other providers report.
    static func usage(from object: [String: Any]?) -> AIUsage? {
        guard let object else { return nil }
        let prompt = object["prompt_tokens"] as? Int ?? 0
        let details = object["prompt_tokens_details"] as? [String: Any]
        let cached = details?["cached_tokens"] as? Int ?? 0
        return AIUsage(
            inputTokens: max(prompt - cached, 0),
            outputTokens: object["completion_tokens"] as? Int ?? 0,
            cacheReadTokens: cached
        )
    }

    static func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        return json["message"] as? String
    }
}
