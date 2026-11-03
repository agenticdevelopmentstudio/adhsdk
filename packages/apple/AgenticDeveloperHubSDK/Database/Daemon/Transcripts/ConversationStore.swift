#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// The newest-first conversation feed, read from the event store's messages.
///
/// Holds the database it reads and the cache of parsed lines, so a poll
/// re-parses only what is new — see ``ConversationExtractCache``. Value-typed
/// and cheap to copy: both properties are shared references.
public struct ConversationStore: Sendable {
    public let database: DaemonDatabase
    public let extractCache: ConversationExtractCache

    public init(database: DaemonDatabase, extractCache: ConversationExtractCache = ConversationExtractCache()) {
        self.database = database
        self.extractCache = extractCache
    }

    // MARK: - Conversations feed

    /// The newest conversation lines across every observed session, newest first.
    ///
    /// Read from `events.db`'s `messages` (the Claude provider's user and
    /// assistant messages, sidechains left out); each is classified by
    /// ``ConversationExtractor`` at read time rather than materialised into a
    /// table of its own, which keeps the classification rules in one place and
    /// disposable: changing what counts as a reply is an edit to the extractor,
    /// not a migration. The session labels come from the session database in a
    /// second read, joined here — the two files are never attached.
    ///
    /// The cost of classifying at read time is that the *kind* filter can only
    /// be applied after parsing, so a `limit` of showable entries needs more
    /// than `limit` messages scanned. `scanMultiplier` covers the shortfall:
    /// most scanned messages are tool calls and tool results, which yield no
    /// line at all whatever the options say. `maxScan` is the backstop for a
    /// stretch of transcript that is all tool traffic; hitting it returns a
    /// short page rather than walking the whole table, and the caller pages on
    /// with `before`.
    ///
    /// A prompt typed mid-turn is a user message flagged `queued_prompt`, so it
    /// arrives in the same scan, in its place in time.
    ///
    /// ## Timestamps
    ///
    /// Each entry's `timestamp` is the message time as ISO-8601 UTC with
    /// milliseconds (`2026-09-01T10:00:00.000Z`), and that is the paging
    /// cursor, so a page never splits a millisecond: once a page holds `limit`
    /// lines it still takes the rest of its last millisecond, and the next
    /// page's `before` then excludes exactly what was shown. A message whose
    /// line carried no timestamp is not on the timeline and is left out, as
    /// the transcript-line feed left out an empty timestamp.
    ///
    /// Without an event store attached, and over one that holds nothing, the
    /// feed is empty.
    ///
    /// - Parameters:
    ///   - limit: how many entries to return.
    ///   - includeWorkOutput: include the two kinds that are the agent talking
    ///     about its own work — `progress` and `thinking`. Off, the feed is the
    ///     conversation only: what the human typed and what the agent said back.
    ///   - before: return only entries strictly older than this ISO-8601
    ///     timestamp — the paging cursor, taken from the oldest entry of the
    ///     previous page. One that does not parse returns nothing.
    ///   - sessionId: narrow to one session. Not a filter over the merged
    ///     result: that result is a *page* — the newest few hundred lines across
    ///     every session, of which one session's share may be two — so a
    ///     conversation sieved out of it has holes in it.
    public func conversationEntries(
        limit: Int,
        includeWorkOutput: Bool,
        before: String?,
        sessionId: String? = nil
    ) throws -> [ConversationEntryDTO] {
        // Measured, not guessed: with work output off, a merged read of 200
        // entries at a multiplier of 6 came back with 42. Most scanned rows
        // yield nothing at all — a tool call, a tool result, a hook's notice —
        // and turning work output off throws away most of what is left.
        let scanMultiplier = includeWorkOutput ? 3 : 12
        let maxScan = 20_000
        let scanLimit = min(max(limit, 1) * scanMultiplier, maxScan)

        // The cursor is a rendered timestamp, rounded to the millisecond, so a
        // message is "older" when it falls below that millisecond: the entry
        // the cursor came from (and anything that renders the same) is out.
        var beforeTime: Double?
        if let before, !before.isEmpty {
            guard let date = TimestampParsing.parse(before) else { return [] }
            beforeTime = date.timeIntervalSince1970 - 0.0005
        }
        let scoped = (sessionId?.isEmpty == false) ? sessionId : nil

        let messages = try database.claudeConversationMessages(
            sessionId: scoped, before: beforeTime, limit: scanLimit)
        guard !messages.isEmpty else { return [] }
        let labels = try sessionLabels(Set(messages.map(\.sessionId)))

        var entries: [ConversationEntryDTO] = []
        // Set once the page holds `limit` lines: from then on only the rest of
        // the last entry's millisecond may follow.
        var full = false
        var consumedEveryMessage = true
        for message in messages {
            let timestamp = message.timestamp
            if full, timestamp != entries.last?.timestamp {
                consumedEveryMessage = false
                break
            }
            let lines = extractCache.lines(
                messageId: message.id, role: message.role, text: message.text, attrsJSON: message.attrs)
            guard !lines.isEmpty else { continue }
            let label = labels[message.sessionId] ?? SessionLabel()

            // One message can hold several blocks (a thinking block and the
            // text that followed it), so ids are suffixed to stay unique — the
            // window keys its rows on them.
            //
            // The index is taken BEFORE the work-output filter, so a block's id
            // is a property of the transcript rather than of the caller's
            // options: filtering first renumbered every line whenever the
            // window's "show work output" toggle moved.
            //
            // The cap is on the OFFSET, taken before the filter: an entry whose
            // thousandth block is one this caller wants would otherwise keep an
            // offset of 1000+ and collide with the next message's ids.
            //
            // Emitted in reverse document order, because this whole result is
            // newest-first and the reader flips it to render oldest-at-top.
            let shown = Array(
                lines
                    .enumerated()
                    .prefix(Self.maxLinesPerConversationEntry)
                    .filter { includeWorkOutput || !$0.element.kind.isWorkOutput }
                    .reversed()
            )
            guard !shown.isEmpty else { continue }

            // Whole millisecond groups only. Pages are cut on the rendered
            // timestamp, and every block of one message — and every message
            // of one millisecond — carries the SAME one, so a page that
            // stopped inside a group would lose the rest: the next page asks
            // for older than that timestamp. A group that does not fit is
            // left for the next page; one that has already begun is finished
            // here, overshooting `limit`, as is an entry bigger than `limit`
            // by itself, because otherwise paging would wedge at that point.
            if !entries.isEmpty, entries.count + shown.count > limit, timestamp != entries.last?.timestamp {
                consumedEveryMessage = false
                break
            }
            for (offset, line) in shown {
                entries.append(ConversationEntryDTO(
                    id: Int(message.id) * Self.maxLinesPerConversationEntry + offset,
                    sessionId: message.sessionId,
                    kind: line.kind.rawValue,
                    text: line.text,
                    timestamp: timestamp,
                    projectName: label.projectName,
                    gitBranch: label.gitBranch,
                    sessionName: label.title,
                    termProgram: label.termProgram
                ))
            }
            if entries.count >= limit { full = true }
        }
        // A scan that came back full may have stopped inside its last
        // millisecond, with more of that group beyond it. Leave that group to
        // the next page, whose cursor then reaches all of it — unless it is
        // everything this page has, when a partial group beats a page that
        // can never move on.
        if consumedEveryMessage, messages.count >= scanLimit,
           let tail = messages.last?.timestamp, entries.last?.timestamp == tail {
            let complete = entries.filter { $0.timestamp != tail }
            if !complete.isEmpty { entries = complete }
        }
        return entries
    }

    /// What the feed labels a session's lines with, from the session database.
    private struct SessionLabel {
        var projectName = ""
        var gitBranch = ""
        /// The title only. `summary` is the summarizer's running line about
        /// what the session is *doing*, and headed as a name it reads as one
        /// the session was given — an unnamed session stays unnamed here.
        var title = ""
        var termProgram = ""
    }

    /// The labels of `sessionIds` that have a session row; one without is absent.
    private func sessionLabels(_ sessionIds: Set<String>) throws -> [String: SessionLabel] {
        let ids = Array(sessionIds)
        var labels: [String: SessionLabel] = [:]
        let chunk = DaemonDatabase.claudeReadChunk
        for start in stride(from: 0, to: ids.count, by: chunk) {
            let part = Array(ids[start..<min(start + chunk, ids.count)])
            let marks = part.map { _ in "?" }.joined(separator: ",")
            try database.query("""
                SELECT session_id, project_root, cwd, git_branch, transcript_title, term_program
                FROM sessions WHERE session_id IN (\(marks))
                """, params: part) { row in
                // `project_root` is the enriched value and can still be empty on
                // a session the enricher hasn't reached; `cwd` is written at
                // session start and always there.
                let projectRoot = database.string(row, 1)
                let projectPath = projectRoot.isEmpty ? database.string(row, 2) : projectRoot
                labels[database.string(row, 0)] = SessionLabel(
                    projectName: projectPath.isEmpty ? "" : (projectPath as NSString).lastPathComponent,
                    gitBranch: database.string(row, 3),
                    title: database.string(row, 4),
                    termProgram: database.string(row, 5))
            }
        }
        return labels
    }

    // MARK: - One conversation, oldest first

    /// A range of one session's conversation, oldest first, paged by message id.
    ///
    /// The reader's cursor is the last message id it holds, so the range is
    /// cut on the message's *position*, not on a timestamp — two entries that
    /// share a timestamp would otherwise be one page's tail and lost to the next.
    /// The position is `(timestamp, line id)`: time order across the files of a
    /// resumed session (whose line ids and `line_no`s both interleave), with the
    /// line id breaking ties so the order is total and the same on every read.
    ///
    /// The cursors are placed by a keyed read of their own lines, and the page's
    /// line ids are then read `limit + 1` at a time from the first position on
    /// (``LineWindow``) — two small columns off `idx_transcript_lines_session` —
    /// so a page never reads the whole session's order. Only the lines inside
    /// the page are read whole, one primary-key read each, because `raw_json`
    /// runs to tens of KB a line.
    ///
    /// - Parameters:
    ///   - afterId: return only messages after this one (exclusive); nil starts
    ///     at the first message.
    ///   - throughId: stop at this message (inclusive); nil runs to the newest.
    ///   - limit: at most this many messages, whole transcript entries only —
    ///     an entry bigger than `limit` by itself is returned whole.
    ///   - includeWorkOutput: include `progress` and `thinking` lines, the
    ///     session's subagents' own transcripts (`subagents/agent-*.jsonl`),
    ///     woven in by time with each message's ``ConversationMessageDTO/agentId``
    ///     set. A headless `claude -p` that hands its task to an agent writes
    ///     little else. Its own script-driven prompt and reply are shown either
    ///     way: they are this session's conversation, not side work.
    /// - Throws: ``ConversationRangeError/unknownMessageId(_:)`` for a cursor
    ///   that names no line of the session.
    public func conversationMessages(
        sessionId: String,
        afterId: Int?,
        throughId: Int?,
        limit: Int,
        includeWorkOutput: Bool
    ) throws -> ConversationMessagesPageDTO {
        let stride = Self.maxLinesPerConversationEntry
        let limit = max(limit, 1)
        return try database.read { _ in
            let sidechains = includeWorkOutput
            let first = try afterId.map { try self.position(of: $0, sessionId: sessionId, sidechains: sidechains) }
            let last = try throughId.map { try self.position(of: $0, sessionId: sessionId, sidechains: sidechains) }
            // The cursors cut inside their own entries only: every other line
            // between them is wholly inside the range, whatever its ids.
            func inRange(_ messageId: Int) -> Bool {
                let line = messageId / stride
                if let afterId, line == afterId / stride, messageId <= afterId { return false }
                if let throughId, line == throughId / stride, messageId > throughId { return false }
                return true
            }

            // The range's lines in order, read a chunk at a time from where the
            // previous chunk stopped — a seek, never the whole session's order.
            var lines = LineWindow(chunk: limit + 1, lower: first, upper: last) { after, through, count in
                try self.lines(of: sessionId, after: after, through: through, count: count, sidechains: sidechains)
            }
            var messages: [ConversationMessageDTO] = []
            var reachedEnd = true
            while let lineId = try lines.next() {
                var rawJSON = ""
                var timestamp = ""
                var filePath = ""
                try database.query(
                    "SELECT raw_json, timestamp, file_path FROM transcript_lines WHERE id = ?", params: [lineId]
                ) { row in
                    rawJSON = self.database.string(row, 0)
                    timestamp = self.database.string(row, 1)
                    filePath = self.database.string(row, 2)
                }
                let agentId = JSONLScanner.subagentId(ofPath: filePath)
                // Offsets are taken before any filter, as the feed takes
                // them, so a message's id never depends on what was asked.
                // A scripted line is this session's own conversation (a headless
                // `claude -p` writes nothing else), so it is always kept; only a
                // sub-agent's sidechain waits for the work output.
                let shown = self.extractCache.lines(
                    lineId: lineId, rawJSON: rawJSON,
                    includeSidechains: includeWorkOutput, includeScripted: true)
                    .enumerated()
                    .prefix(stride)
                    .filter { includeWorkOutput || !$0.element.kind.isWorkOutput }
                    .map { (id: lineId * stride + $0.offset, line: $0.element) }
                    .filter { inRange($0.id) }
                guard !shown.isEmpty else { continue }
                if !messages.isEmpty, messages.count + shown.count > limit {
                    reachedEnd = false
                    break
                }
                messages += shown.map {
                    let kind = $0.line.kind.rawValue
                    return ConversationMessageDTO(
                        id: $0.id, type: ConversationMessageDTO.type(forKind: kind), kind: kind,
                        content: $0.line.text, time: timestamp, agentId: agentId)
                }
                if messages.count >= limit, try lines.hasNext() {
                    reachedEnd = false
                    break
                }
            }
            return ConversationMessagesPageDTO(
                sessionId: sessionId,
                messages: messages,
                nextAfterId: messages.last?.id ?? afterId,
                isComplete: reachedEnd
            )
        }
    }

    /// A line's place in a conversation's order: `(timestamp, line id)` — time
    /// order across the files of a resumed session, the id making it total.
    struct LinePosition: Equatable {
        let timestamp: String
        let lineId: Int
    }

    /// One session's conversation lines as `(line_id, ts)` — the same two
    /// sources the feed weaves together: the user/assistant lines (terms
    /// verbatim from migration038, as in the feed's scoped read) and the
    /// prompts queued mid-turn, which are attachment rows the first never
    /// reaches. Parameters: the session id, then (`oneLine`) a line id, for
    /// each source in turn. `sidechains` adds the subagents' lines, which are
    /// stored under the dispatching session's id.
    private static func conversationLinesSQL(oneLine: Bool, sidechains: Bool) -> String {
        """
        SELECT id AS line_id, timestamp AS ts
        FROM transcript_lines INDEXED BY idx_transcript_lines_session
        WHERE session_id = ?\(sidechains ? "" : " AND is_sidechain = 0")
          AND (entry_type = 'user' OR entry_type = 'assistant')
          AND timestamp != ''\(oneLine ? " AND id = ?" : "")
        UNION
        SELECT q.line_id, q.timestamp
        FROM conversation_queued_prompts q
        JOIN transcript_lines t ON t.id = q.line_id
        WHERE q.session_id = ? AND q.timestamp != ''\(sidechains ? "" : " AND t.is_sidechain = 0")\(
            oneLine ? " AND q.line_id = ?" : "")
        """
    }

    /// Where the line holding `messageId` sits in the session's order, by a
    /// keyed read of that one line rather than a walk of the session.
    /// - Throws: ``ConversationRangeError/unknownMessageId(_:)`` when no
    ///   conversation line of the session holds it.
    private func position(of messageId: Int, sessionId: String, sidechains: Bool) throws -> LinePosition {
        let line = messageId / Self.maxLinesPerConversationEntry
        var positions: [LinePosition] = []
        let sql = Self.conversationLinesSQL(oneLine: true, sidechains: sidechains)
        try database.query(sql, params: [sessionId, line, sessionId, line]) {
            positions.append(LinePosition(timestamp: self.database.string($0, 1), lineId: self.database.int($0, 0)))
        }
        // A line both sources list sits at the earlier of its two places.
        guard let earliest = positions.min(by: { ($0.timestamp, $0.lineId) < ($1.timestamp, $1.lineId) }) else {
            throw ConversationRangeError.unknownMessageId(messageId)
        }
        return earliest
    }

    /// Up to `count` of the session's lines in order, after `lower` (or from it,
    /// when it is not exclusive) through `upper` (inclusive).
    private func lines(
        of sessionId: String, after lower: LineWindow.Bound?, through upper: LinePosition?, count: Int,
        sidechains: Bool
    ) throws -> [LinePosition] {
        var conditions: [String] = []
        var params: [any Sendable] = [sessionId, sessionId]
        if let lower {
            conditions.append(lower.exclusive ? "(ts, line_id) > (?, ?)" : "(ts, line_id) >= (?, ?)")
            params += [lower.position.timestamp, lower.position.lineId]
        }
        if let upper {
            conditions.append("(ts, line_id) <= (?, ?)")
            params += [upper.timestamp, upper.lineId]
        }
        params.append(count)
        let window = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        var rows: [LinePosition] = []
        try database.query(
            "SELECT line_id, ts FROM (\(Self.conversationLinesSQL(oneLine: false, sidechains: sidechains))) \(window) "
                + "ORDER BY ts, line_id LIMIT ?",
            params: params
        ) {
            rows.append(LinePosition(timestamp: self.database.string($0, 1), lineId: self.database.int($0, 0)))
        }
        return rows
    }

    /// A conversation's lines between two positions, read `chunk` at a time,
    /// each read seeking on from the last line the one before it returned —
    /// so a page costs its own lines, not the whole session's order.
    struct LineWindow {
        struct Bound {
            let position: LinePosition
            let exclusive: Bool
        }

        typealias Read = (_ after: Bound?, _ through: LinePosition?, _ count: Int) throws -> [LinePosition]

        private let chunk: Int
        private let upper: LinePosition?
        private let read: Read
        private var lower: Bound?
        private var buffered: [LinePosition] = []
        private var exhausted = false

        /// - Parameters:
        ///   - lower: the first position wanted (inclusive); nil starts at the first line.
        ///   - upper: the last position wanted (inclusive); nil runs to the newest.
        init(chunk: Int, lower: LinePosition?, upper: LinePosition?, read: @escaping Read) {
            self.chunk = max(chunk, 1)
            self.upper = upper
            self.read = read
            self.lower = lower.map { Bound(position: $0, exclusive: false) }
        }

        /// The next line id in order, or nil past the window's end.
        mutating func next() throws -> Int? {
            guard try fill() else { return nil }
            let line = buffered.removeFirst()
            lower = Bound(position: line, exclusive: true)
            return line.lineId
        }

        /// Whether ``next()`` has another line to give.
        mutating func hasNext() throws -> Bool {
            try fill()
        }

        private mutating func fill() throws -> Bool {
            if buffered.isEmpty, !exhausted {
                buffered = try read(lower, upper, chunk)
                exhausted = buffered.count < chunk
            }
            return !buffered.isEmpty
        }
    }

    /// One row of the Conversations feed's scans, read out of the shared column
    /// list both of them select.
    private struct FeedRow {
        let id: Int
        let sessionId: String
        let timestamp: String
        let rawJSON: String
        let projectRoot: String
        let cwd: String
        let gitBranch: String
        let title: String
        let termProgram: String

        init(row: Row, reader: DaemonDatabase) {
            id = reader.int(row, 0)
            sessionId = reader.string(row, 1)
            timestamp = reader.string(row, 2)
            rawJSON = reader.string(row, 3)
            projectRoot = reader.string(row, 4)
            cwd = reader.string(row, 5)
            gitBranch = reader.string(row, 6)
            title = reader.string(row, 7)
            termProgram = reader.string(row, 8)
        }
    }

    /// The id stride between two messages, and therefore the cap on how many
    /// lines one message may contribute.
    ///
    /// `id = messages.id * stride + blockIndex` only stays unique while
    /// `blockIndex < stride`; at the old stride of 100, an entry with 100 blocks
    /// produced ids that collided with the next entry's. A thousand is far past
    /// anything a real message holds, and lines beyond it are dropped rather
    /// than allowed to collide — a silently missing line is recoverable, two
    /// rows fighting over one identity in the window is not.
    private static let maxLinesPerConversationEntry = 1000
}
#endif
