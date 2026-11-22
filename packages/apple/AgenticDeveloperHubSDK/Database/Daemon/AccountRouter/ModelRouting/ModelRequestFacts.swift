#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import CryptoKit
import Foundation

/// Why a request is not a routing candidate.
enum ModelPassReason: String, Error, Sendable {
    case notMessages = "not a messages request"
    case tooLarge = "body too large"
    case notJSON = "body is not JSON"
    case noModel = "no claude model"
}

/// What the policy needs to know about one request. Never holds the body; the
/// two texts below are kept only for a template's "contains" conditions and
/// are never logged, recorded or shown.
struct ModelRequestFacts: Equatable, Sendable {
    static let maxBodyBytes = 32 * 1024 * 1024
    private static let writeTools: Set<String> = ["Edit", "MultiEdit", "Write", "NotebookEdit"]
    private static let commandTool = "Bash"
    /// Only the main thread can start agents, so a request offering one of these is the main thread.
    private static let agentTools: Set<String> = ["Agent", "Task"]
    /// The identity line older Claude Code main threads carried.
    private static let mainMarker = "You are Claude Code, Anthropic's official CLI"
    /// Claude Code's billing line. Read only for its subagent flag; never logged, recorded or shown.
    private static let billingPrefix = "x-anthropic-billing-header:"
    private static let subagentFlag = "cc_is_subagent=true"

    let requestedModel: String
    let family: Sessions.ModelFamily
    let thread: Sessions.ModelThreadKind
    let writes: Bool
    /// Its tools include Bash.
    let commands: Bool
    let estimatedInputTokens: Int
    let maxTokens: Int?
    let threadKey: String
    /// The system prompt without the billing line, at most `maxTextCharacters`.
    var systemText = ""
    /// The latest user message's text, at most `maxTextCharacters`.
    var messageText = ""
    static let maxTextCharacters = 64 * 1024

    static func extract(
        head: RouterRequestHead, body: Data
    ) -> Result<(ModelRequestFacts, [String: Any]), ModelPassReason> {
        guard head.method == "POST", head.path == "/v1/messages" else { return .failure(.notMessages) }
        guard body.count <= maxBodyBytes else { return .failure(.tooLarge) }
        guard let object = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] else {
            return .failure(.notJSON)
        }
        guard let model = object["model"] as? String, model.hasPrefix("claude-") else { return .failure(.noModel) }

        let lines = systemLines(object["system"])
        let tools = object["tools"] as? [Any] ?? []
        let toolNames = Set(tools.compactMap { ($0 as? [String: Any])?["name"] as? String })
        let messages = object["messages"] as? [Any] ?? []
        var facts = ModelRequestFacts(
            requestedModel: model, family: family(of: model),
            thread: thread(lines: lines, hasTools: !tools.isEmpty, toolNames: toolNames),
            writes: !toolNames.isDisjoint(with: writeTools),
            commands: toolNames.contains(commandTool),
            estimatedInputTokens: body.count / 4, maxTokens: (object["max_tokens"] as? Int).map { max(0, $0) },
            threadKey: threadKey(lines: lines, first: messages.first))
        facts.systemText = String(
            (lines ?? []).filter { !isBillingLine($0) }.joined(separator: "\n").prefix(maxTextCharacters))
        facts.messageText = String(latestUserText(messages).prefix(maxTextCharacters))
        return .success((facts, object))
    }

    static func family(of model: String) -> Sessions.ModelFamily {
        let lower = model.lowercased()
        for family in [Sessions.ModelFamily.haiku, .sonnet, .opus] where lower.contains(family.rawValue) {
            return family
        }
        return .other
    }

    /// Claude Code's billing line names a subagent with `cc_is_subagent=true`;
    /// without it the request is the main thread or, with no tools, a side call.
    /// With no billing line, the old marker or an agent tool means the main
    /// thread: when unsure, a request is treated as your conversation.
    private static func thread(lines: [String]?, hasTools: Bool, toolNames: Set<String>) -> Sessions.ModelThreadKind {
        guard let lines else { return .other }
        if let billing = lines.first(where: isBillingLine) {
            if billing.contains(subagentFlag) { return hasTools ? .subagent : .side }
            return hasTools ? .main : .side
        }
        if lines.contains(where: { $0.contains(mainMarker) }) || !toolNames.isDisjoint(with: agentTools) {
            return .main
        }
        return hasTools ? .subagent : .side
    }

    private static func isBillingLine(_ line: String) -> Bool {
        line.drop(while: { $0.isWhitespace }).hasPrefix(billingPrefix)
    }

    /// The system prompt's lines (every block's text), nil when it has none.
    private static func systemLines(_ value: Any?) -> [String]? {
        let text: String
        if let string = value as? String {
            text = string
        } else if let blocks = value as? [Any] {
            text = blocks.compactMap { ($0 as? [String: Any])?["text"] as? String }.joined(separator: "\n")
        } else {
            return nil
        }
        return text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    /// The text of the last user message: a string, or its text blocks joined.
    private static func latestUserText(_ messages: [Any]) -> String {
        guard let last = messages.last(where: { ($0 as? [String: Any])?["role"] as? String == "user" })
                as? [String: Any] else { return "" }
        if let text = last["content"] as? String { return text }
        let blocks = last["content"] as? [Any] ?? []
        return blocks.compactMap { ($0 as? [String: Any])?["text"] as? String }.joined(separator: "\n")
    }

    /// System prompt (without the billing line, which can differ request to
    /// request) plus the first message.
    private static func threadKey(lines: [String]?, first: Any?) -> String {
        var hasher = SHA256()
        let system = (lines ?? []).filter { !isBillingLine($0) }.joined(separator: "\n")
        hasher.update(data: Data(system.utf8))
        if let first, JSONSerialization.isValidJSONObject(first),
           let data = try? JSONSerialization.data(withJSONObject: first, options: [.sortedKeys]) {
            hasher.update(data: Data([0]))
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
#endif
