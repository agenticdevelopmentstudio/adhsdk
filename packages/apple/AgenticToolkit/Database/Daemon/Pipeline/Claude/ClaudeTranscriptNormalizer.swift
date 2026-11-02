#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Normalizes one Claude Code transcript line (a ``ClaudeTranscriptPayload``)
/// into turns, messages, a session upsert and the few events a transcript
/// genuinely carries.
///
/// Pure: it reads only the record. Parsing reuses ``JSONLScanner`` so the
/// pipeline and the legacy importer read a line the same way.
///
/// - Turn (Ruling 5): one per user/assistant line ``JSONLScanner/parse(_:isSubagentFile:)``
///   accepts, keyed by `message.id`. A streamed assistant message repeats its
///   id on several lines with growing usage; `as_of` is the line's time plus
///   `line_no` microseconds, so the store's latest-wins merge keeps the last
///   (largest) line whichever order they arrive in. A zero-usage line of a
///   message with an id emits no turn, so it can never overwrite real counts.
/// - Message (Ruling 6): one per user/assistant line and per queued prompt,
///   keyed by the record's dedup key, with `content` kept verbatim in
///   `attrs.blocks` and its text blocks flattened into `text`.
/// - Events (Ruling 7): only title lines and Agent-dispatch results. Nothing
///   is synthesized for prompts or tool calls; the hooks own those.
/// - Session: the line's cwd, branch and time; the model and transcript path
///   only from a main-session line, so a subagent's file never stands in for
///   the parent's.
///
/// A line with no timestamp sits at the epoch: its `as_of` is
/// `0 + line_no * 1e-6`, so any timestamped observation outranks it, and it
/// never claims a session start.
public struct ClaudeTranscriptNormalizer: Normalizer {
    public let provider = ClaudeProvider.name

    /// Suffix of an Agent-dispatch event's key: the same line's message already
    /// holds the record's dedup key, and event and message keys must not collide.
    public static let dispatchKeySuffix = "#agent-dispatch"

    public init() {}

    public func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        let raw = record.record
        guard let payload = try? ClaudeTranscriptPayload.decode(raw.payload),
              let lineData = payload.line.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
            throw ClaudeNormalizerError.unparseable(raw.dedupKey)
        }
        let line = Line(payload: payload, root: root, record: record)
        var batch = NormalizedBatch()

        if let title = JSONLScanner.parseExtras(payload.line).title {
            line.appendTitle(title, to: &batch)
            return batch
        }
        line.appendTurnAndMessage(to: &batch)
        line.appendDispatch(to: &batch)
        line.appendSession(to: &batch)
        return batch
    }
}

/// One decoded transcript line and the facts every row drawn from it shares.
private struct Line {
    let payload: ClaudeTranscriptPayload
    let root: [String: Any]
    let recordID: Int64
    let dedupKey: String
    let raw: JSONLScanner.RawTranscriptLine
    let turn: JSONLScanner.ParsedTurn?
    /// The line's own session id; empty when the line carries none.
    let ownSessionID: String
    /// The line's parsed timestamp, nil when absent or unreadable.
    let parsedTime: Date?
    /// `parsedTime`, or the epoch.
    let time: Date
    let asOf: Date

    init(payload: ClaudeTranscriptPayload, root: [String: Any], record: ArchivedRecord) {
        self.payload = payload
        self.root = root
        recordID = record.id
        dedupKey = record.record.dedupKey
        raw = JSONLScanner.parseRawLine(
            payload.line, lineNo: payload.lineNo, fileStem: ClaudeTranscriptPayload.fileStem(payload.file))
        turn = JSONLScanner.parse(payload.line, isSubagentFile: payload.subagentFile)
        ownSessionID = root["sessionId"] as? String ?? ""
        parsedTime = TimestampParsing.parse(raw.timestamp)
        time = parsedTime ?? Date(timeIntervalSince1970: 0)
        asOf = Date(timeIntervalSince1970: time.timeIntervalSince1970 + Double(payload.lineNo) * 1e-6)
    }

    private var cwd: String? { Self.nonEmpty(root["cwd"] as? String) }
    private var gitBranch: String? { Self.nonEmpty(root["gitBranch"] as? String) }
    private var isSubagentLine: Bool { payload.subagentFile || raw.isSidechain || (turn?.isSubagent ?? false) }

    // MARK: - Rows

    func appendTitle(_ title: JSONLScanner.ParsedTitle, to batch: inout NormalizedBatch) {
        let eventTime = parsedTime ?? asOf
        batch.events.append(NormalizedEvent(
            dedupKey: dedupKey, sessionID: title.sessionId, kind: .other, providerType: raw.entryType,
            time: eventTime, cwd: cwd, summary: title.title,
            attrs: ["title": .string(title.title), "title_source": .string(title.source.rawValue)],
            rawRef: recordID))
        batch.sessions.append(SessionUpsert(sessionID: title.sessionId, asOf: asOf, title: title.title))
    }

    func appendTurnAndMessage(to batch: inout NormalizedBatch) {
        if let turn, let row = turnRow(turn) {
            batch.turns.append(row)
        }
        let queuedPrompt = QueuedPrompt.queuedPrompt(root)
        guard raw.entryType == "user" || raw.entryType == "assistant" || queuedPrompt != nil else { return }

        let content: Any?
        var attrs: [String: NormalizedValue] = [:]
        let role: String
        if let queuedPrompt {
            content = queuedPrompt
            role = "user"
            attrs["queued_prompt"] = .bool(true)
        } else {
            content = (root["message"] as? [String: Any])?["content"]
            role = raw.role.isEmpty ? raw.entryType : raw.role
        }
        if let blocks = content as? [Any] {
            attrs["blocks"] = ClaudeHookNormalizer.value(blocks)
        }
        batch.messages.append(MessageRow(
            dedupKey: dedupKey, uuid: raw.entryUuid.isEmpty ? dedupKey : raw.entryUuid,
            parentUUID: Self.nonEmpty(raw.parentUuid), sessionID: raw.sessionId, role: role, time: time,
            isSidechain: raw.isSidechain, text: Self.text(content), attrs: attrs, rawRef: recordID))
    }

    func appendDispatch(to batch: inout NormalizedBatch) {
        guard let dispatch = JSONLScanner.parseExtras(payload.line).dispatch else { return }
        var attrs: [String: NormalizedValue] = [
            "agent_id": .string(dispatch.agentId),
            "agent_type": .string(dispatch.agentType),
            "total_tokens": .number(Double(dispatch.totalTokens)),
            "total_duration_ms": .number(Double(dispatch.totalDurationMs)),
            "total_tool_use_count": .number(Double(dispatch.totalToolUseCount))
        ]
        if !dispatch.status.isEmpty { attrs["status"] = .string(dispatch.status) }
        batch.events.append(NormalizedEvent(
            dedupKey: dedupKey + ClaudeTranscriptNormalizer.dispatchKeySuffix, sessionID: dispatch.sessionId,
            kind: .subagentStop, providerType: "agent-dispatch", time: time, cwd: cwd,
            summary: dispatch.agentType, attrs: attrs, rawRef: recordID))
    }

    /// A session upsert for a line that names its own session and either says
    /// when (a timestamp) or produced a row. A line without either says nothing
    /// about the session worth recording.
    func appendSession(to batch: inout NormalizedBatch) {
        guard !ownSessionID.isEmpty,
              parsedTime != nil || !batch.turns.isEmpty || !batch.messages.isEmpty else { return }
        var attrs: [String: NormalizedValue] = [:]
        attrs["git_branch"] = gitBranch.map(NormalizedValue.string)
        var model: String?
        if !isSubagentLine {
            attrs["transcript_path"] = .string(payload.file)
            model = Self.nonEmpty(turn?.model)
        }
        batch.sessions.append(SessionUpsert(
            sessionID: ownSessionID, asOf: asOf, cwd: cwd, model: model, startedAt: parsedTime, attrs: attrs))
    }

    /// The turn for `turn`, or nil for a zero-usage line of a message that has
    /// an id: a streamed message can repeat its id on a later line with empty
    /// usage, and since the store merges latest-wins, that line would wipe the
    /// real token counts (the legacy importer's guard, TranscriptStore+Turns).
    /// Id-less lines keep their turn: their fallback key is theirs alone.
    private func turnRow(_ turn: JSONLScanner.ParsedTurn) -> TurnRow? {
        let usage = turn.inputTokens + turn.outputTokens + turn.cacheReadTokens + turn.cacheCreationTokens
        if !turn.messageId.isEmpty && usage == 0 { return nil }
        let key: String
        if !turn.messageId.isEmpty {
            key = turn.messageId
        } else if turn.kind == .user {
            key = "user:\(turn.sessionId):\(turn.timestamp)"
        } else {
            key = "asst:\(turn.sessionId):\(turn.timestamp):\(turn.toolName)"
        }
        var attrs: [String: NormalizedValue] = [
            "kind": .string(turn.kind.rawValue),
            "cache_creation_1h_tokens": .number(Double(turn.cacheCreation1hTokens)),
            "is_subagent": .bool(turn.isSubagent)
        ]
        attrs["message_id"] = Self.nonEmpty(turn.messageId).map(NormalizedValue.string)
        attrs["cwd"] = Self.nonEmpty(turn.cwd).map(NormalizedValue.string)
        attrs["git_branch"] = Self.nonEmpty(turn.gitBranch).map(NormalizedValue.string)
        return TurnRow(
            dedupKey: key, sessionID: turn.sessionId, time: time, asOf: asOf,
            model: Self.nonEmpty(turn.model), account: nil, agent: Self.nonEmpty(turn.agentId),
            toolName: Self.nonEmpty(turn.toolName), inputTokens: turn.inputTokens,
            outputTokens: turn.outputTokens, cacheReadTokens: turn.cacheReadTokens,
            cacheWriteTokens: turn.cacheCreationTokens, attrs: attrs, rawRef: recordID)
    }

    // MARK: - Helpers

    /// String content as is; an array's `text` blocks joined with no separator.
    private static func text(_ content: Any?) -> String {
        if let string = content as? String { return string }
        guard let blocks = content as? [Any] else { return "" }
        return blocks.compactMap { block -> String? in
            guard let block = block as? [String: Any], block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }.joined()
    }

    private static func nonEmpty(_ string: String?) -> String? {
        guard let string, !string.isEmpty else { return nil }
        return string
    }
}
#endif
