#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import CoreFoundation
import Foundation

/// Normalizes one Claude Code hook envelope into one event and one session upsert.
///
/// Pure: it reads only the record. The event time is the envelope's timestamp
/// (falling back to the record's `receivedAt`, never the clock), and the account
/// is whatever the envelope captured — never resolved from `~/.claude.json` or a
/// database here (Design Ruling 4).
public struct ClaudeHookNormalizer: Normalizer {
    public let provider = ClaudeProvider.name

    public init() {}

    public func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        let raw = record.record
        guard let text = String(data: raw.payload, encoding: .utf8) else {
            throw ClaudeNormalizerError.unparseable(raw.dedupKey)
        }
        let parsed: ParsedEvent
        switch ParseResult.parse(envelopeJSON: text) {
        case .event(let event): parsed = event
        case .skip, .lostEvent: return NormalizedBatch()
        case .unparseable: throw ClaudeNormalizerError.unparseable(raw.dedupKey)
        }
        // `.event` guarantees a non-empty session_id.
        let hookData = parsed.hookData
        let sessionID = hookData["session_id"] as? String ?? ""
        let time = TimestampParsing.parse(parsed.timestamp) ?? raw.receivedAt
        let cwd = Self.nonEmptyString(hookData["cwd"])
        let (account, authMethod) = Self.authAttribution(
            accountEmail: parsed.accountEmail, oauthEmail: parsed.oauthAccountEmail)

        var attrs = Self.commonAttrs(hookData)
        attrs["account_email"] = Self.nonEmptyString(parsed.accountEmail).map(NormalizedValue.string)
        attrs["oauth_account_email"] = Self.nonEmptyString(parsed.oauthAccountEmail).map(NormalizedValue.string)
        attrs["auth_method"] = authMethod.map(NormalizedValue.string)
        if let context = parsed.context, !context.isEmpty {
            attrs["context_json"] = Self.value(context)
        }
        if parsed.eventType == "StatusLine" {
            attrs.merge(Self.statusLineAttrs(hookData)) { _, new in new }
        }

        var batch = NormalizedBatch()
        batch.events.append(NormalizedEvent(
            dedupKey: raw.dedupKey, sessionID: sessionID, kind: Self.kind(for: parsed.eventType),
            providerType: parsed.eventType, time: time, cwd: cwd,
            toolName: Self.nonEmptyString(hookData["tool_name"]),
            summary: computeDetail(eventType: parsed.eventType, hookData: hookData),
            attrs: attrs, rawRef: record.id))

        var sessionAttrs: [String: NormalizedValue] = [:]
        sessionAttrs["auth_method"] = authMethod.map(NormalizedValue.string)
        for key in ["pid", "term_program", "term_session_id", "transcript_path", "git_branch"] {
            sessionAttrs[key] = attrs[key]
        }
        var session = SessionUpsert(
            sessionID: sessionID, asOf: time, cwd: cwd, account: account,
            model: Self.nonEmptyString(hookData["model"]), attrs: sessionAttrs)
        switch parsed.eventType {
        case "SessionStart":
            session.status = "active"
            session.startedAt = time
        case "SessionEnd":
            session.status = "ended"
            session.endedAt = time
        default:
            break
        }
        batch.sessions.append(session)
        return batch
    }

    /// Design Ruling 4: the token's account when one was fingerprinted, else the
    /// oauth login captured with the event, else nothing.
    public static func authAttribution(accountEmail: String, oauthEmail: String?)
        -> (account: String?, authMethod: String?) {
        if !accountEmail.isEmpty { return (accountEmail, "token") }
        if let oauthEmail, !oauthEmail.isEmpty { return (oauthEmail, "oauth") }
        return (nil, nil)
    }

    // MARK: - Mapping

    /// Design Ruling 8's kind table; any hook not named maps to `.other`.
    static func kind(for eventType: String) -> EventKind {
        switch eventType {
        case "SessionStart": return .sessionStart
        case "SessionEnd": return .sessionEnd
        case "UserPromptSubmit": return .prompt
        case "PreToolUse": return .toolCall
        case "PostToolUse", "PostToolUseFailure": return .toolResult
        case "Stop": return .stop
        case "PreCompact", "PostCompact": return .compaction
        case "SubagentStart": return .subagentStart
        case "SubagentStop": return .subagentStop
        case "Notification": return .notification
        case "PermissionRequest": return .permission
        default: return .other
        }
    }

    /// hook_data keys copied verbatim into attrs when present (Ruling 8a).
    private static let passthroughKeys = [
        "tool_use_id", "agent_type", "agent_id", "notification_type", "trigger", "transcript_path",
        "term_program", "term_session_id", "pid", "permission_mode", "source", "reason",
        // Stamped at capture (`ClaudeFileFingerprint`) for ConfigChange / InstructionsLoaded.
        "file_size_bytes", "file_sha256"
    ]

    private static func commonAttrs(_ hookData: [String: Any]) -> [String: NormalizedValue] {
        var attrs: [String: NormalizedValue] = [:]
        for key in passthroughKeys {
            attrs[key] = topLevelValue(hookData[key])
        }
        // StatusLine's `model` is an object; it is reported as `model_id` instead.
        attrs["model"] = nonEmptyString(hookData["model"]).map(NormalizedValue.string)
        let git = hookData["stenographer_git"] as? [String: Any]
        attrs["git_branch"] = (nonEmptyString(hookData["git_branch"]) ?? nonEmptyString(git?["branch"]))
            .map(NormalizedValue.string)
        return attrs
    }

    /// The status-line keys the daemon stores today (`StatusLineIngest`), named as Ruling 8a names them.
    private static func statusLineAttrs(_ hookData: [String: Any]) -> [String: NormalizedValue] {
        let leaves = DaemonDatabase.flattenLeaves(hookData)
        var attrs: [String: NormalizedValue] = [:]
        let renamed: [(attr: String, leaf: String)] = [
            ("prompt_cache_misses", "prompt_cache_misses"),
            ("prompt_cache_requests", "prompt_cache_requests"),
            ("prompt_cache_miss_recache_tokens", "prompt_cache_miss_recache_tokens"),
            ("model_id", "model_id"),
            ("prompt_cache_ttl", "prompt_cache_ttl"),
            ("context_window_size", "context_window_context_window_size"),
            ("project_dir", "workspace_project_dir"),
            ("claude_version", "version")
        ]
        for (attr, leaf) in renamed {
            attrs[attr] = topLevelValue(leaves[leaf])
        }
        if let remaining = (leaves["context_window_remaining_percentage"] as? NSNumber)?.doubleValue,
           remaining.isFinite {
            let clamped = max(0, min(100, remaining.rounded()))
            attrs["context_used_pct"] = .number(100 - clamped)
        }
        // The cause maps stay whole objects, never flattened (their keys are unbounded).
        let cache = hookData["prompt_cache"] as? [String: Any]
        for (attr, key) in [("prompt_cache_miss_causes", "miss_causes"),
                            ("prompt_cache_last_miss_cause", "last_miss_cause")] {
            if let object = cache?[key] as? [String: Any] { attrs[attr] = value(object) }
        }
        return attrs
    }

    // MARK: - Values

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return string
    }

    /// An attrs value: absent, null and empty strings are omitted, never stored as null.
    private static func topLevelValue(_ value: Any?) -> NormalizedValue? {
        guard let value, !(value is NSNull) else { return nil }
        if let string = value as? String, string.isEmpty { return nil }
        let converted = Self.value(value)
        return converted == .null ? nil : converted
    }

    /// JSONSerialization output as a NormalizedValue. Non-finite numbers and
    /// anything unrecognised become `.null`, so every emitted number is finite.
    static func value(_ any: Any) -> NormalizedValue {
        switch any {
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return .bool(number.boolValue) }
            let double = number.doubleValue
            return double.isFinite ? .number(double) : .null
        case let array as [Any]:
            return .array(array.map { value($0) })
        case let dict as [String: Any]:
            return .object(dict.mapValues { value($0) })
        default:
            return .null
        }
    }
}
#endif
