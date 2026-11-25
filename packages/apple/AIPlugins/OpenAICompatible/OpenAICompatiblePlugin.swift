import Foundation
import AIPluginKit

/// LLM plugin for OpenAI-compatible endpoints (LM Studio, self-hosted, etc.).
///
/// Foundation-only and self-contained: it reads the user-supplied base URL and
/// API key from `AIChatContext.config`, describes the Chat Completions request,
/// and decodes the JSON reply. Kept independent of the official OpenAI plugin so
/// each `.aiplugin` bundle stands alone. Tools are native: the context's tools go
/// out as `tools`, and the reply's `tool_calls` come back as `toolUse` events.
public final class OpenAICompatiblePlugin: NSObject, AIPlugin, @unchecked Sendable {

    public override init() { super.init() }

    public func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        guard let baseURL = context.config.baseURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !baseURL.isEmpty else {
            throw PluginError.missingBaseURL
        }
        // Templates ship a versioned base URL (e.g. .../v1). Tolerate a base URL that
        // ISN'T versioned too — earlier builds appended "v1/chat/completions" to a
        // bare host, so a migrated/hand-entered base URL may lack the version segment;
        // append it here rather than 404ing on `.../chat/completions`.
        let endpoint = Self.isVersioned(baseURL) ? "chat/completions" : "v1/chat/completions"
        guard let url = URL(string: baseURL)?.appendingPathComponent(endpoint) else {
            throw PluginError.invalidURL
        }

        var body: [String: Any] = [
            "max_tokens": context.maxTokens,
            "messages": OpenAICompatibleChatBody.apiMessages(
                systemPrompt: context.systemPrompt,
                messages: context.messages
            )
        ]
        if !context.model.isEmpty { body["model"] = context.model }
        if !context.tools.isEmpty { body["tools"] = try context.tools.map(OpenAICompatibleChatBody.apiTool) }

        var headers = ["content-type": "application/json"]
        // A present `apiKey` (even empty) means the template ships an apiKey field, so
        // a key is expected — fail fast if it's blank rather than firing an
        // unauthenticated request that just 401s. Keyless templates (Ollama) omit the
        // apiKey field entirely, so `apiKey` is nil and no Authorization is sent.
        if let apiKey = context.config.apiKey {
            guard !apiKey.isEmpty else { throw PluginError.missingAPIKey }
            headers["Authorization"] = "Bearer \(apiKey)"
        }

        return .http(
            method: .post,
            url: url,
            headers: headers,
            body: try JSONSerialization.data(withJSONObject: body)
        )
    }

    /// Whether the base URL's last path segment looks like an API version (e.g.
    /// "v1", "v1beta") — a `v` followed by a digit — so the caller knows not to
    /// append its own version segment.
    static func isVersioned(_ baseURL: String) -> Bool {
        let trimmed = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        guard let last = trimmed.split(separator: "/").last, last.first == "v" else { return false }
        return last.dropFirst().first?.isNumber == true
    }

    public func makeDecoder() -> any AIStreamDecoder { OpenAICompatibleReplyDecoder() }

    public func describeError(status: Int, body: Data) -> String? {
        OpenAICompatibleReplyDecoder.parseErrorMessage(from: body)
    }

    enum PluginError: Error, LocalizedError {
        case missingAPIKey
        case missingBaseURL
        case invalidURL
        case invalidToolSchema(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "An API key is required."
            case .missingBaseURL: return "A base URL is required for custom endpoints."
            case .invalidURL: return "The base URL is invalid."
            case .invalidToolSchema(let name):
                return "The tool \"\(name)\" has a parameter schema that is not a JSON object."
            }
        }
    }
}

/// Builds the Chat Completions `messages` and `tools` for this plugin.
enum OpenAICompatibleChatBody {

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
            throw OpenAICompatiblePlugin.PluginError.invalidToolSchema(tool.name)
        }
        return [
            "type": "function",
            "function": ["name": tool.name, "description": tool.description, "parameters": schema]
        ]
    }
}

/// Buffers a full Chat Completions JSON response and emits it on `finish()`:
/// reasoning as `thinkingDelta` (`reasoning_content`, or `reasoning` as some
/// local servers name it), the answer as `textDelta`, each of `tool_calls` as
/// `toolUse`, `usage`, and `end` with the `finish_reason`.
final class OpenAICompatibleReplyDecoder: AIStreamDecoder {

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
        let reasoning = message["reasoning_content"] as? String ?? message["reasoning"] as? String
        if let reasoning, !reasoning.isEmpty {
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

    /// Arguments arrive as a JSON string, though some local servers send the
    /// object itself; an empty or missing value is no arguments.
    static func argumentsJSON(_ value: Any?) -> Data {
        if let text = value as? String, !text.isEmpty { return Data(text.utf8) }
        if let object = value as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: object) {
            return data
        }
        return Data("{}".utf8)
    }

    /// `prompt_tokens` counts cached tokens too, so the cached share is moved
    /// to `cacheReadTokens` and `inputTokens` keeps the uncached rest.
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
