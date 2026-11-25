import Foundation
import Testing
import AIPluginKit

/// Characterization tests for each shipping plugin's `buildRequest`: the part a
/// third-party plugin author is most likely to get wrong (endpoints, auth
/// headers, body shape, required-config errors). The plugin sources are compiled
/// into this bundle, so the tests exercise the real types directly without
/// loading the `.aiplugin` bundles (the load/cast path is covered separately by
/// the host app's `--verify-plugins` run).
@Suite("AI plugin request building")
struct PluginRequestTests {

    // MARK: - Builders

    private func config(apiKey: String? = "test-key", baseURL: String? = nil) -> AIPluginConfig {
        var values: [String: String] = [:]
        if let apiKey { values["apiKey"] = apiKey }
        if let baseURL { values["baseURL"] = baseURL }
        return AIPluginConfig(values)
    }

    private func context(
        messages: [AIChatMessage] = [AIChatMessage(role: .user, content: "Hello")],
        model: String = "",
        systemPrompt: String? = nil,
        maxTokens: Int = 256,
        config: AIPluginConfig
    ) -> AIChatContext {
        AIChatContext(
            messages: messages,
            model: model,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            config: config
        )
    }

    // MARK: - Transport unwrapping

    private func httpParts(
        _ spec: AIRequestSpec
    ) -> (AIRequestSpec.Method, URL, [String: String], Data?)? {
        guard case let .http(method, url, headers, body) = spec.transport else { return nil }
        return (method, url, headers, body)
    }

    private func commandParts(
        _ spec: AIRequestSpec
    ) -> (URL, [String], Data?, [String: String])? {
        guard case let .command(executableURL, arguments, stdin, environment) = spec.transport else {
            return nil
        }
        return (executableURL, arguments, stdin, environment)
    }

    private func jsonBody(_ body: Data?) throws -> [String: Any] {
        let data = try #require(body, "request carried no body")
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any], "body was not a JSON object")
    }

    // MARK: - ClaudeAPI

    @Test("ClaudeAPI targets the Anthropic messages endpoint with key + version headers")
    func claudeAPIEndpointAndHeaders() throws {
        let spec = try ClaudeAPIPlugin().buildRequest(context(config: config()))
        let (method, url, headers, _) = try #require(httpParts(spec))
        #expect(method == .post)
        #expect(url.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(headers["x-api-key"] == "test-key")
        #expect(headers["anthropic-version"] == "2023-06-01")
        #expect(headers["content-type"] == "application/json")
    }

    @Test("ClaudeAPI defaults the model, streams, and drops system-role messages")
    func claudeAPIBody() throws {
        let messages = [
            AIChatMessage(role: .system, content: "ignored as a message"),
            AIChatMessage(role: .user, content: "Hi"),
            AIChatMessage(role: .assistant, content: "Hello")
        ]
        let spec = try ClaudeAPIPlugin().buildRequest(
            context(messages: messages, systemPrompt: "be terse", config: config())
        )
        let (_, _, _, body) = try #require(httpParts(spec))
        let json = try jsonBody(body)
        #expect(json["model"] as? String == "claude-haiku-4-5-20251001")
        #expect(json["max_tokens"] as? Int == 256)
        #expect(json["stream"] as? Bool == true)
        #expect(json["system"] as? String == "be terse")
        let apiMessages = try #require(json["messages"] as? [[String: String]])
        #expect(apiMessages.count == 2)
        #expect(apiMessages[0]["role"] == "user")
        #expect(apiMessages[1]["role"] == "assistant")
    }

    @Test("ClaudeAPI honors an explicitly selected model")
    func claudeAPIExplicitModel() throws {
        let spec = try ClaudeAPIPlugin().buildRequest(context(model: "claude-opus-4-7", config: config()))
        let (_, _, _, body) = try #require(httpParts(spec))
        #expect(try jsonBody(body)["model"] as? String == "claude-opus-4-7")
    }

    @Test("ClaudeAPI throws when the API key is missing")
    func claudeAPIMissingKey() {
        #expect(throws: ClaudeAPIPlugin.PluginError.self) {
            _ = try ClaudeAPIPlugin().buildRequest(context(config: config(apiKey: nil)))
        }
    }

    @Test("ClaudeAPI uses bearer + oauth-beta when authMode is bearer-oauth")
    func claudeAPIBearerOAuth() throws {
        let values = ["apiKey": "tok-123", "authMode": "bearer-oauth",
                      "baseURL": "https://api.anthropic.com/v1"]
        let spec = try ClaudeAPIPlugin().buildRequest(
            context(config: AIPluginConfig(values))
        )
        let (_, url, headers, _) = try #require(httpParts(spec))
        #expect(url.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(headers["Authorization"] == "Bearer tok-123")
        #expect(headers["anthropic-beta"] == "oauth-2025-04-20")
        #expect(headers["anthropic-version"] == "2023-06-01")
        #expect(headers["x-api-key"] == nil)
    }

    // MARK: - OpenAI

    @Test("OpenAI targets chat completions with bearer auth and a default model")
    func openAIRequest() throws {
        let spec = try OpenAIPlugin().buildRequest(context(systemPrompt: "sys", config: config()))
        let (method, url, headers, body) = try #require(httpParts(spec))
        #expect(method == .post)
        #expect(url.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(headers["Authorization"] == "Bearer test-key")
        let json = try jsonBody(body)
        #expect(json["model"] as? String == "gpt-4.1-nano")
        let messages = try #require(json["messages"] as? [[String: String]])
        #expect(messages.first?["role"] == "system")
        #expect(messages.first?["content"] == "sys")
        #expect(messages.last?["role"] == "user")
    }

    @Test("OpenAI throws when the API key is missing")
    func openAIMissingKey() {
        #expect(throws: OpenAIPlugin.PluginError.self) {
            _ = try OpenAIPlugin().buildRequest(context(config: config(apiKey: nil)))
        }
    }

    // MARK: - Google

    @Test("Google targets gemini generateContent with the key as a query item")
    func googleRequest() throws {
        let spec = try GooglePlugin().buildRequest(context(config: config()))
        let (method, url, headers, body) = try #require(httpParts(spec))
        #expect(method == .post)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "generativelanguage.googleapis.com")
        #expect(components.path == "/v1beta/models/gemini-2.0-flash:generateContent")
        #expect(components.queryItems?.first { $0.name == "key" }?.value == "test-key")
        #expect(headers["content-type"] == "application/json")
        // The key rides in the query string, not an auth header.
        #expect(headers["Authorization"] == nil)
        #expect(try jsonBody(body)["contents"] != nil)
    }

    @Test("Google maps assistant messages to the model role")
    func googleRoleMapping() throws {
        let messages = [
            AIChatMessage(role: .user, content: "hi"),
            AIChatMessage(role: .assistant, content: "yo")
        ]
        let spec = try GooglePlugin().buildRequest(context(messages: messages, config: config()))
        let (_, _, _, body) = try #require(httpParts(spec))
        let contents = try #require(try jsonBody(body)["contents"] as? [[String: Any]])
        #expect(contents.count == 2)
        #expect(contents[0]["role"] as? String == "user")
        #expect(contents[1]["role"] as? String == "model")
    }

    @Test("Google throws when the API key is missing")
    func googleMissingKey() {
        #expect(throws: GooglePlugin.PluginError.self) {
            _ = try GooglePlugin().buildRequest(context(config: config(apiKey: nil)))
        }
    }

    // MARK: - OpenAICompatible

    @Test("OpenAICompatible builds chat completions against the versioned base URL")
    func openAICompatibleRequest() throws {
        let spec = try OpenAICompatiblePlugin().buildRequest(
            context(config: config(apiKey: "k", baseURL: "https://lmstudio.local/v1"))
        )
        let (_, url, headers, _) = try #require(httpParts(spec))
        #expect(url.absoluteString == "https://lmstudio.local/v1/chat/completions")
        #expect(headers["Authorization"] == "Bearer k")
    }

    @Test("OpenAICompatible omits auth when no key is set (e.g. Ollama) but still needs a base URL")
    func openAICompatibleKeyless() throws {
        let spec = try OpenAICompatiblePlugin().buildRequest(
            context(config: config(apiKey: nil, baseURL: "http://localhost:11434/v1"))
        )
        let (_, url, headers, _) = try #require(httpParts(spec))
        #expect(url.absoluteString == "http://localhost:11434/v1/chat/completions")
        #expect(headers["Authorization"] == nil)

        // A missing base URL still throws.
        #expect(throws: OpenAICompatiblePlugin.PluginError.self) {
            _ = try OpenAICompatiblePlugin().buildRequest(context(config: config(apiKey: "k", baseURL: nil)))
        }
    }

    // MARK: - ClaudeLocal

    @Test("ClaudeLocal assembles the claude -p flags without a --max-turns cap")
    func claudeLocalArguments() {
        // Pure argument assembly, asserted directly so the exact flag set is
        // covered on every machine — including CI runners without the `claude`
        // binary, where `buildRequest` throws `.notFound` before building args
        // and the transport test below can only exercise the absent-CLI path.
        let args = ClaudeLocalPlugin.commandArguments(model: "claude-opus-4-7", systemPrompt: "be terse")
        #expect(Array(args.prefix(3)) == ["-p", "--output-format", "text"])
        // `--model`/`--system-prompt` each carry their value in the next slot.
        #expect(zip(args, args.dropFirst()).contains { $0 == "--model" && $1 == "claude-opus-4-7" })
        #expect(zip(args, args.dropFirst()).contains { $0 == "--system-prompt" && $1 == "be terse" })
        // Deliberately omitted: a one-shot `-p` can otherwise exit "Reached max turns".
        #expect(!args.contains("--max-turns"))
        // No model and no system prompt → just the base flags.
        #expect(ClaudeLocalPlugin.commandArguments(model: "", systemPrompt: nil)
                == ["-p", "--output-format", "text"])
        #expect(ClaudeLocalPlugin.commandArguments(model: "", systemPrompt: "") == ["-p", "--output-format", "text"])
        // The host supplying the tools switches the CLI's own off.
        #expect(ClaudeLocalPlugin.commandArguments(model: "", systemPrompt: nil, disableBuiltInTools: true)
                == ["-p", "--output-format", "text", "--tools", ""])
    }

    @Test("ClaudeLocal describes a claude -p subprocess, or reports the CLI is absent")
    func claudeLocalCommand() throws {
        let plugin = ClaudeLocalPlugin()
        let ctx = context(
            messages: [AIChatMessage(role: .user, content: "Hello")],
            model: "claude-opus-4-7",
            config: config(apiKey: nil)
        )
        do {
            let spec = try plugin.buildRequest(ctx)
            let (executableURL, arguments, stdin, environment) = try #require(commandParts(spec))
            #expect(executableURL.lastPathComponent == "claude")
            // buildRequest wires in the pure argument list verbatim (its exact
            // contents are asserted unconditionally in claudeLocalArguments).
            #expect(arguments == ClaudeLocalPlugin.commandArguments(model: "claude-opus-4-7", systemPrompt: nil))
            #expect(stdin == Data("Hello".utf8))
            #expect(environment["PATH"]?.contains("/.local/bin") == true)
        } catch let error as ClaudeLocalPlugin.PluginError {
            // No Claude CLI on this machine — the documented failure path.
            guard case .notFound = error else {
                Issue.record("unexpected ClaudeLocalPlugin.PluginError: \(error)")
                return
            }
        }
    }

    // MARK: - Native tools and thinking

    private let listTool = AIToolSpec(
        name: "list_notices",
        description: "List notices",
        parametersJSONSchema: Data(#"{"type":"object","properties":{"limit":{"type":"integer"}}}"#.utf8)
    )

    /// A tool loop: the user asks, the assistant says something and calls a
    /// tool, and the tool answers.
    private let toolLoop = [
        AIChatMessage(role: .user, content: "What is pending?"),
        AIChatMessage(role: .assistant, content: "Checking."),
        AIChatMessage(
            role: .toolUse,
            content: "",
            toolUseId: "call_1",
            toolName: "list_notices",
            toolArgumentsJSON: Data(#"{"limit":5}"#.utf8)
        ),
        AIChatMessage(role: .toolResult, content: "3 notices", toolUseId: "call_1", toolIsError: false)
    ]

    private func fullContext(
        messages: [AIChatMessage] = [AIChatMessage(role: .user, content: "Hello")],
        model: String = "",
        maxTokens: Int = 256,
        tools: [AIToolSpec] = [],
        thinkingBudgetTokens: Int? = nil,
        config: AIPluginConfig
    ) -> AIChatContext {
        AIChatContext(
            messages: messages,
            model: model,
            maxTokens: maxTokens,
            tools: tools,
            thinkingBudgetTokens: thinkingBudgetTokens,
            config: config
        )
    }

    private func body(_ spec: AIRequestSpec) throws -> [String: Any] {
        let (_, _, _, body) = try #require(httpParts(spec))
        return try jsonBody(body)
    }

    @Test("ClaudeAPI sends tools with their input_schema")
    func claudeAPITools() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(tools: [listTool], config: config())))
        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect(tools.count == 1)
        #expect(tools[0]["name"] as? String == "list_notices")
        #expect(tools[0]["description"] as? String == "List notices")
        let schema = try #require(tools[0]["input_schema"] as? [String: Any])
        #expect(schema["type"] as? String == "object")
    }

    @Test("ClaudeAPI omits tools when the context has none")
    func claudeAPINoTools() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(config: config())))
        #expect(json["tools"] == nil)
        #expect(json["thinking"] == nil)
    }

    @Test("ClaudeAPI refuses a tool whose schema is not a JSON object")
    func claudeAPIBadToolSchema() {
        let bad = AIToolSpec(name: "bad", description: "", parametersJSONSchema: Data("[]".utf8))
        #expect(throws: ClaudeAPIPlugin.PluginError.self) {
            _ = try ClaudeAPIPlugin().buildRequest(fullContext(tools: [bad], config: config()))
        }
    }

    @Test("ClaudeAPI folds a tool call into the assistant turn and its result into a user turn")
    func claudeAPIToolBlocks() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(messages: toolLoop, config: config())))
        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 3)
        #expect(messages[0]["content"] as? String == "What is pending?")

        #expect(messages[1]["role"] as? String == "assistant")
        let assistant = try #require(messages[1]["content"] as? [[String: Any]])
        #expect(assistant.map { $0["type"] as? String } == ["text", "tool_use"])
        #expect(assistant[1]["id"] as? String == "call_1")
        #expect(assistant[1]["name"] as? String == "list_notices")
        #expect((assistant[1]["input"] as? [String: Any])?["limit"] as? Int == 5)

        #expect(messages[2]["role"] as? String == "user")
        let user = try #require(messages[2]["content"] as? [[String: Any]])
        #expect(user[0]["type"] as? String == "tool_result")
        #expect(user[0]["tool_use_id"] as? String == "call_1")
        #expect(user[0]["content"] as? String == "3 notices")
        #expect(user[0]["is_error"] == nil)
    }

    @Test("ClaudeAPI marks a failed tool result as an error")
    func claudeAPIToolError() throws {
        let messages = [
            AIChatMessage(role: .user, content: "Go"),
            AIChatMessage(role: .toolUse, content: "", toolUseId: "t1", toolName: "x"),
            AIChatMessage(role: .toolResult, content: "boom", toolUseId: "t1", toolIsError: true)
        ]
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(messages: messages, config: config())))
        let apiMessages = try #require(json["messages"] as? [[String: Any]])
        let result = try #require((apiMessages.last?["content"] as? [[String: Any]])?.first)
        #expect(result["is_error"] as? Bool == true)
        // A call with no arguments goes out as an empty input object.
        let call = try #require((apiMessages[1]["content"] as? [[String: Any]])?.first)
        #expect((call["input"] as? [String: Any])?.isEmpty == true)
    }

    @Test("ClaudeAPI sends a fixed thinking budget to a 4.5 model and raises max_tokens above it")
    func claudeAPIThinkingBudget() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(
            model: "claude-sonnet-4-5-20250929",
            maxTokens: 1000,
            thinkingBudgetTokens: 2000,
            config: config()
        )))
        let thinking = try #require(json["thinking"] as? [String: Any])
        #expect(thinking["type"] as? String == "enabled")
        #expect(thinking["budget_tokens"] as? Int == 2000)
        #expect(json["max_tokens"] as? Int == 3000)
    }

    @Test("ClaudeAPI raises a budget below the API minimum to 1024")
    func claudeAPIThinkingMinimum() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(
            model: "claude-haiku-4-5",
            maxTokens: 4096,
            thinkingBudgetTokens: 100,
            config: config()
        )))
        let thinking = try #require(json["thinking"] as? [String: Any])
        #expect(thinking["budget_tokens"] as? Int == 1024)
        #expect(json["max_tokens"] as? Int == 4096)
    }

    @Test("ClaudeAPI asks newer models for adaptive, summarized thinking")
    func claudeAPIAdaptiveThinking() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(
            model: "claude-opus-4-7",
            thinkingBudgetTokens: 4000,
            config: config()
        )))
        let thinking = try #require(json["thinking"] as? [String: Any])
        #expect(thinking["type"] as? String == "adaptive")
        #expect(thinking["display"] as? String == "summarized")
        #expect(thinking["budget_tokens"] == nil)
    }

    @Test("ClaudeAPI tells fixed-budget models from adaptive ones")
    func claudeAPIThinkingModelFamilies() {
        for model in ["claude-3-7-sonnet-20250219", "claude-sonnet-4-20250514", "claude-opus-4-1-20250805",
                      "claude-haiku-4-5-20251001", "claude-opus-4-5", "us.anthropic.claude-sonnet-4-5-v1:0"] {
            #expect(ClaudeAPIThinking.takesFixedBudget(model), "\(model)")
        }
        for model in ["claude-opus-4-6", "claude-sonnet-4-6", "claude-opus-4-7", "claude-opus-5-5", "claude-fable-5"] {
            #expect(!ClaudeAPIThinking.takesFixedBudget(model), "\(model)")
        }
    }

    @Test("ClaudeAPI leaves thinking off when continuing a tool loop")
    func claudeAPIThinkingOffInToolLoop() throws {
        let json = try body(ClaudeAPIPlugin().buildRequest(fullContext(
            messages: toolLoop,
            thinkingBudgetTokens: 2000,
            config: config()
        )))
        #expect(json["thinking"] == nil)
        #expect(json["max_tokens"] as? Int == 256)
    }

    @Test("OpenAI sends function tools and maps tool calls and results")
    func openAIToolMessages() throws {
        let json = try body(OpenAIPlugin().buildRequest(fullContext(
            messages: toolLoop,
            tools: [listTool],
            config: config()
        )))
        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect(tools[0]["type"] as? String == "function")
        let function = try #require(tools[0]["function"] as? [String: Any])
        #expect(function["name"] as? String == "list_notices")
        #expect((function["parameters"] as? [String: Any])?["type"] as? String == "object")

        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.map { $0["role"] as? String } == ["user", "assistant", "tool"])
        #expect(messages[1]["content"] as? String == "Checking.")
        let call = try #require((messages[1]["tool_calls"] as? [[String: Any]])?.first)
        #expect(call["id"] as? String == "call_1")
        #expect(call["type"] as? String == "function")
        let callFunction = try #require(call["function"] as? [String: Any])
        #expect(callFunction["name"] as? String == "list_notices")
        #expect(callFunction["arguments"] as? String == #"{"limit":5}"#)
        #expect(messages[2]["tool_call_id"] as? String == "call_1")
        #expect(messages[2]["content"] as? String == "3 notices")
    }

    @Test("OpenAI opens an assistant message for a tool call that follows no assistant text")
    func openAIToolCallAlone() throws {
        let messages = [
            AIChatMessage(role: .user, content: "Go"),
            AIChatMessage(role: .toolUse, content: "", toolUseId: "a", toolName: "x"),
            AIChatMessage(role: .toolUse, content: "", toolUseId: "b", toolName: "y")
        ]
        let json = try body(OpenAIPlugin().buildRequest(fullContext(messages: messages, config: config())))
        let apiMessages = try #require(json["messages"] as? [[String: Any]])
        #expect(apiMessages.count == 2)
        #expect(apiMessages[1]["content"] is NSNull)
        let calls = try #require(apiMessages[1]["tool_calls"] as? [[String: Any]])
        #expect(calls.map { $0["id"] as? String } == ["a", "b"])
        #expect((calls[0]["function"] as? [String: Any])?["arguments"] as? String == "{}")
    }

    @Test("OpenAICompatible sends function tools and maps tool calls and results")
    func openAICompatibleToolMessages() throws {
        let json = try body(OpenAICompatiblePlugin().buildRequest(fullContext(
            messages: toolLoop,
            tools: [listTool],
            config: config(apiKey: nil, baseURL: "http://localhost:11434/v1")
        )))
        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect((tools[0]["function"] as? [String: Any])?["name"] as? String == "list_notices")
        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.map { $0["role"] as? String } == ["user", "assistant", "tool"])
        #expect((messages[1]["tool_calls"] as? [[String: Any]])?.count == 1)
        #expect(messages[2]["tool_call_id"] as? String == "call_1")
    }

    @Test("OpenAI and OpenAICompatible ignore a thinking budget")
    func openAIIgnoresThinking() throws {
        let openAI = try body(OpenAIPlugin().buildRequest(fullContext(thinkingBudgetTokens: 2000, config: config())))
        #expect(openAI["thinking"] == nil)
        #expect(openAI["max_tokens"] as? Int == 256)
        let compatible = try body(OpenAICompatiblePlugin().buildRequest(fullContext(
            thinkingBudgetTokens: 2000,
            config: config(apiKey: nil, baseURL: "http://localhost:11434/v1")
        )))
        #expect(compatible["thinking"] == nil)
    }
}
