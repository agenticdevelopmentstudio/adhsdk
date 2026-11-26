import Foundation
import AIPluginKit

/// What happens during an agent's turn, in order.
///
/// Wire JSON is flat and snake-cased, with the case in `type` (also the SSE
/// event name):
///
/// ```
/// {"type":"text_delta","text":"…"}
/// {"type":"thinking_delta","text":"…"}
/// {"type":"tool_started","call_id":"…","tool":"…","arguments":"{…}"}
/// {"type":"tool_finished","call_id":"…","tool":"…","summary":"…","error":"…"}
/// {"type":"activity","id":"…","at":"…","agent_id":"…","session_id":"…","tool":"…",
///  "arguments":"{…}","reason":"…","summary":"…"}
/// {"type":"usage","input_tokens":1,"output_tokens":2,"cache_read_tokens":0,"cache_write_tokens":0}
/// {"type":"turn_finished","stop_reason":"end_turn"}
/// {"type":"turn_failed","message":"…"}
/// ```
///
/// `arguments` is the tool's arguments as a JSON string. Optional values are
/// omitted when nil.
public enum AgentEvent: Codable, Sendable, Equatable {
    case textDelta(String)
    case thinkingDelta(String)
    case toolStarted(callId: String, tool: String, argumentsJSON: String)
    case toolFinished(callId: String, tool: String, summary: String, error: String?)
    /// A mutating tool ran.
    case activity(ActivityEntry)
    case usage(AIUsage)
    case turnFinished(stopReason: String?)
    case turnFailed(message: String)

    /// The wire `type`, which is also the SSE event name.
    public var type: String {
        switch self {
        case .textDelta: return "text_delta"
        case .thinkingDelta: return "thinking_delta"
        case .toolStarted: return "tool_started"
        case .toolFinished: return "tool_finished"
        case .activity: return "activity"
        case .usage: return "usage"
        case .turnFinished: return "turn_finished"
        case .turnFailed: return "turn_failed"
        }
    }

    /// Whether the event ends a turn.
    public var isTerminal: Bool {
        switch self {
        case .turnFinished, .turnFailed: return true
        default: return false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type, text, tool, summary, error, reason, message, arguments, id
        case occurredAt = "at"
        case callId = "call_id"
        case agentId = "agent_id"
        case sessionId = "session_id"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case cacheWriteTokens = "cache_write_tokens"
        case stopReason = "stop_reason"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text_delta":
            self = .textDelta(try container.decode(String.self, forKey: .text))
        case "thinking_delta":
            self = .thinkingDelta(try container.decode(String.self, forKey: .text))
        case "tool_started":
            self = .toolStarted(
                callId: try container.decode(String.self, forKey: .callId),
                tool: try container.decode(String.self, forKey: .tool),
                argumentsJSON: try container.decode(String.self, forKey: .arguments))
        case "tool_finished":
            self = .toolFinished(
                callId: try container.decode(String.self, forKey: .callId),
                tool: try container.decode(String.self, forKey: .tool),
                summary: try container.decode(String.self, forKey: .summary),
                error: try container.decodeIfPresent(String.self, forKey: .error))
        case "activity":
            self = .activity(ActivityEntry(
                id: try container.decode(UUID.self, forKey: .id),
                occurredAt: try container.decode(Date.self, forKey: .occurredAt),
                agentId: try container.decode(String.self, forKey: .agentId),
                sessionId: try container.decodeIfPresent(UUID.self, forKey: .sessionId),
                tool: try container.decode(String.self, forKey: .tool),
                argumentsJSON: try container.decode(String.self, forKey: .arguments),
                reason: try container.decodeIfPresent(String.self, forKey: .reason),
                summary: try container.decode(String.self, forKey: .summary)))
        case "usage":
            self = .usage(AIUsage(
                inputTokens: try container.decodeIfPresent(Int.self, forKey: .inputTokens) ?? 0,
                outputTokens: try container.decodeIfPresent(Int.self, forKey: .outputTokens) ?? 0,
                cacheReadTokens: try container.decodeIfPresent(Int.self, forKey: .cacheReadTokens) ?? 0,
                cacheWriteTokens: try container.decodeIfPresent(Int.self, forKey: .cacheWriteTokens) ?? 0))
        case "turn_finished":
            self = .turnFinished(stopReason: try container.decodeIfPresent(String.self, forKey: .stopReason))
        case "turn_failed":
            self = .turnFailed(message: try container.decode(String.self, forKey: .message))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown agent event type '\(type)'")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch self {
        case .textDelta(let text), .thinkingDelta(let text):
            try container.encode(text, forKey: .text)
        case let .toolStarted(callId, tool, argumentsJSON):
            try container.encode(callId, forKey: .callId)
            try container.encode(tool, forKey: .tool)
            try container.encode(argumentsJSON, forKey: .arguments)
        case let .toolFinished(callId, tool, summary, error):
            try container.encode(callId, forKey: .callId)
            try container.encode(tool, forKey: .tool)
            try container.encode(summary, forKey: .summary)
            try container.encodeIfPresent(error, forKey: .error)
        case .activity(let entry):
            try container.encode(entry.id, forKey: .id)
            try container.encode(entry.occurredAt, forKey: .occurredAt)
            try container.encode(entry.agentId, forKey: .agentId)
            try container.encodeIfPresent(entry.sessionId, forKey: .sessionId)
            try container.encode(entry.tool, forKey: .tool)
            try container.encode(entry.argumentsJSON, forKey: .arguments)
            try container.encodeIfPresent(entry.reason, forKey: .reason)
            try container.encode(entry.summary, forKey: .summary)
        case .usage(let usage):
            try container.encode(usage.inputTokens, forKey: .inputTokens)
            try container.encode(usage.outputTokens, forKey: .outputTokens)
            try container.encode(usage.cacheReadTokens, forKey: .cacheReadTokens)
            try container.encode(usage.cacheWriteTokens, forKey: .cacheWriteTokens)
        case .turnFinished(let stopReason):
            try container.encodeIfPresent(stopReason, forKey: .stopReason)
        case .turnFailed(let message):
            try container.encode(message, forKey: .message)
        }
    }
}

/// An event in its session, numbered so a client can tell a gap or a repeat.
/// Wire JSON: `{"session_id":"…","seq":3,"event":{"type":…}}`.
public struct AgentEnvelope: Codable, Sendable, Equatable {
    public var sessionId: UUID
    /// Increases by one per event within the host process's life of the session.
    public var seq: Int
    public var event: AgentEvent

    public init(sessionId: UUID, seq: Int, event: AgentEvent) {
        self.sessionId = sessionId
        self.seq = seq
        self.event = event
    }

    private enum CodingKeys: String, CodingKey {
        case seq, event
        case sessionId = "session_id"
    }
}

extension AgentEnvelope {
    /// `next` folded into `last` when both are text deltas, or both thinking
    /// deltas, of one session: the texts joined in order, with `next`'s `seq`.
    /// Nil for anything else, so a tool call, usage or turn end is never
    /// merged. A relay that batches a turn's events (an XPC push through a
    /// coalescing publisher) passes this as its merge, so a burst of tokens
    /// crosses as one event.
    public static func merging(_ last: AgentEnvelope, _ next: AgentEnvelope) -> AgentEnvelope? {
        guard last.sessionId == next.sessionId else { return nil }
        switch (last.event, next.event) {
        case let (.textDelta(first), .textDelta(second)):
            return AgentEnvelope(sessionId: next.sessionId, seq: next.seq, event: .textDelta(first + second))
        case let (.thinkingDelta(first), .thinkingDelta(second)):
            return AgentEnvelope(sessionId: next.sessionId, seq: next.seq, event: .thinkingDelta(first + second))
        default:
            return nil
        }
    }
}
