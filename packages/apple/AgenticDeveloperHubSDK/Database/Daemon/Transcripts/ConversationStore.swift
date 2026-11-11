#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// The newest-first conversation feed, read from stored transcript lines.
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
    /// Rows are classified by ``ConversationExtractor`` at read time rather than
    /// materialised into a table of their own. The alternative — a
    /// `conversation_entries` table filled on ingest — would need a 4.4M-row
    /// backfill and a second copy of every prompt and reply, to serve a window
    /// that reads a few hundred rows at a time. Parsing at query time keeps the
    /// classification rules in one place and disposable: changing what counts as
    /// a reply is an edit to the extractor, not a migration.
    ///
    /// The cost of that choice is that the *kind* filter can only be applied
    /// after parsing, so a `limit` of showable entries needs more than `limit`
    /// rows scanned. `scanMultiplier` covers the shortfall: most scanned rows
    /// are tool calls and tool results, which yield no line at all whatever the
    /// options say, so the shortfall is large either way. `maxScan` is the
    /// backstop for a stretch of transcript that is all tool traffic; hitting it
    /// returns a short page rather than walking the whole table, and the caller
    /// pages on with `before`.
    ///
    /// - Parameters:
    ///   - limit: how many entries to return.
    ///   - includeWorkOutput: include the two kinds that are the agent talking
    ///     about its own work — `progress` and `thinking`. Off, the feed is the
    ///     conversation only: what the human typed and what the agent said back.
    ///   - before: return only entries strictly older than this ISO-8601
    ///     timestamp — the paging cursor, taken from the oldest entry of the
    ///     previous page.
    ///   - sessionId: narrow to one session. Not a filter over the merged
    ///     result: that result is a *page* — the newest few hundred lines across
    ///     every session, of which one session's share may be two — so a
    ///     conversation sieved out of it has holes in it. Scoped, the query
    ///     takes a different index and a different order; see below.
    public func conversationEntries(
        limit: Int,
        includeWorkOutput: Bool,
        before: String?,
        sessionId: String? = nil
    ) throws -> [ConversationEntryDTO] {
        // Measured, not guessed: with work output off, a merged read of 200
        // entries at a multiplier of 6 came back with 42. Most scanned rows
        // yield nothing at all — a tool call, a tool result, a hook's notice —
        // and turning work output off throws away most of what is left, so the
        // shortfall is worst exactly where the window spends its time. Twelve
        // is what it was before it was halved, and the scan is index-ordered,
        // so the extra rows are read in `LIMIT` order rather than sorted.
        let scanMultiplier = includeWorkOutput ? 3 : 12
        let maxScan = 20_000
        let scanLimit = min(max(limit, 1) * scanMultiplier, maxScan)

        // `timestamp != ''` because not every captured entry type carries one,
        // and an empty string sorts below every real timestamp — it would
        // otherwise fill the oldest page. The `is_sidechain` / `entry_type`
        // terms are repeated verbatim from migration038's partial index; see
        // that migration for why the shape matters.
        //
        // `INDEXED BY` because repeating those terms is what makes the partial
        // index *usable*, not what makes it *chosen*. Left to its own costing —
        // and there is no `sqlite_stat1` here, so costing is guesswork — the
        // planner preferred `idx_transcript_lines_type (entry_type=?)`, which
        // answers `ORDER BY timestamp DESC LIMIT n` by reading every user and
        // assistant row in the table, seeking out each one's `raw_json`, and
        // sorting the lot in a temp b-tree to keep the newest few thousand. On a
        // 4.7M-row `transcript_lines` whose `raw_json` is 16.8 GB that is minutes
        // per call, and the Conversations window asks on a timer: one reader lane
        // pinned at 100% for as long as the window is open. Named outright, the
        // partial index supplies the DESC order itself, so `LIMIT` stops the scan
        // — measured 2400 rows in 0.11s. The name is a hard dependency on
        // migration038 on purpose: if that index ever goes, this fails loudly
        // instead of silently falling back to the plan that wedged the daemon.
        //
        // Scoped to one session, the index changes but the ORDER BY must not.
        // `idx_transcript_lines_session (session_id, line_no)` answers
        // `session_id = ?` with its rows already in `line_no` order, which is
        // free to walk — but `line_no` is a position within a transcript
        // *file*, and a session that was resumed has more than one (326 of
        // them in the live database). Ordered by `line_no DESC`, two files'
        // lines interleave, so the newest-first page is not in time order and
        // the `before` cursor — which cuts on `timestamp` — skips whatever sits
        // on the wrong side of the shuffle. Those rows are then unreachable:
        // the next page asks for older still.
        //
        // So the scoped read sorts on `timestamp` too, and keeps the cheap
        // index by doing it in two steps: an inner pick that takes the session's
        // ids in time order (the index supplies the rows; the sort carries two
        // small columns, not 3 KB of `raw_json` each), and the outer join that
        // fetches the page those ids name.
        let scoped = (sessionId?.isEmpty == false) ? sessionId : nil
        var params: [any Sendable] = []
        let columns = """
            t.id, t.session_id, t.timestamp, t.raw_json,
                   s.project_root, s.cwd, s.git_branch, s.transcript_title,
                   s.term_program
            """
        let sql: String
        if let scoped {
            params.append(scoped)
            var pick = """
                SELECT id FROM transcript_lines INDEXED BY idx_transcript_lines_session
                WHERE session_id = ?
                  AND is_sidechain = 0
                  AND (entry_type = 'user' OR entry_type = 'assistant')
                  AND timestamp != ''
                """
            if let before, !before.isEmpty {
                pick += "\n  AND timestamp < ?"
                params.append(before)
            }
            pick += "\nORDER BY timestamp DESC\nLIMIT ?"
            params.append(scanLimit)
            sql = """
                SELECT \(columns)
                FROM transcript_lines t
                JOIN (\(pick)) AS pick ON pick.id = t.id
                LEFT JOIN sessions s ON s.session_id = t.session_id
                ORDER BY t.timestamp DESC
                """
        } else {
            var merged = """
                SELECT \(columns)
                FROM transcript_lines t INDEXED BY idx_transcript_lines_conversation
                LEFT JOIN sessions s ON s.session_id = t.session_id
                WHERE t.is_sidechain = 0
                  AND (t.entry_type = 'user' OR t.entry_type = 'assistant')
                  AND t.timestamp != ''
                """
            if let before, !before.isEmpty {
                merged += "\n  AND t.timestamp < ?"
                params.append(before)
            }
            merged += "\nORDER BY t.timestamp DESC\nLIMIT ?"
            params.append(scanLimit)
            sql = merged
        }

        // Prompts typed mid-turn are attachment rows, which the scans above
        // never reach (see migration044), so they come from their own table and
        // are woven into the timeline below. `limit` of them is as many as a
        // page can hold, since each yields at least one entry.
        //
        // Only their ids and times are read up front: most of them are older
        // than the page the scan fills and are never shown, and a line's
        // `raw_json` runs to tens of KB. The few that are woven in are fetched
        // whole, one primary-key read each, when they are reached.
        var queuedParams: [any Sendable] = []
        var queuedSQL = """
            SELECT q.line_id, q.timestamp
            FROM conversation_queued_prompts q
            JOIN transcript_lines t ON t.id = q.line_id
            WHERE q.timestamp != '' AND t.is_sidechain = 0
            """
        if let scoped {
            queuedSQL += "\n  AND q.session_id = ?"
            queuedParams.append(scoped)
        }
        if let before, !before.isEmpty {
            queuedSQL += "\n  AND q.timestamp < ?"
            queuedParams.append(before)
        }
        queuedSQL += "\nORDER BY q.timestamp DESC\nLIMIT ?"
        queuedParams.append(max(limit, 1))

        return try database.read { _ in
            var queued: [(lineId: Int, timestamp: String)] = []
            try database.query(queuedSQL, params: queuedParams) { row in
                queued.append((lineId: self.database.int(row, 0), timestamp: self.database.string(row, 1)))
            }

            var entries: [ConversationEntryDTO] = []
            var done = false
            func consume(_ feedRow: FeedRow) {
                guard !done else { return }
                let lines = self.extractCache.lines(
                    lineId: feedRow.id, rawJSON: feedRow.rawJSON
                )
                guard !lines.isEmpty else { return }

                let sessionId = feedRow.sessionId
                let timestamp = feedRow.timestamp
                // `project_root` is the enriched value and can still be empty on
                // a session the enricher hasn't reached; `cwd` is written at
                // session start and always there.
                let projectPath = feedRow.projectRoot.isEmpty ? feedRow.cwd : feedRow.projectRoot
                let projectName = projectPath.isEmpty
                    ? ""
                    : (projectPath as NSString).lastPathComponent
                // The title only. `summary` is the summarizer's running line
                // about what the session is *doing* ("writing
                // test_status_cmd.py"), and headed as a name it reads as one the
                // session was given — an unnamed session stays unnamed here.
                let sessionName = feedRow.title
                // One transcript entry can hold several blocks (a thinking block
                // and the text that followed it), so ids are suffixed to stay
                // unique — the window keys its rows on them.
                //
                // The index is taken BEFORE the work-output filter, so a block's
                // id is a property of the transcript rather than of the caller's
                // options: filtering first renumbered every line whenever the
                // window's "show work output" toggle moved, and the window saw
                // that as a feed full of brand-new rows.
                //
                // Emitted in reverse document order, because this whole result
                // is newest-first and the reader flips it to render oldest-at-
                // top: two reversals leave the blocks of one entry in the order
                // the model produced them.
                // The cap is on the OFFSET, so it is taken before the filter and
                // not after it. `prefix` after `filter` counts kept lines, and
                // the id is built from the offset: an entry whose thousandth
                // block is the fiftieth one this caller wants would keep an
                // offset of 1000+ and collide with the next entry's ids — the
                // exact collision the stride exists to prevent.
                let shown = Array(
                    lines
                        .enumerated()
                        .prefix(Self.maxLinesPerConversationEntry)
                        .filter { includeWorkOutput || !$0.element.kind.isWorkOutput }
                        .reversed()
                )
                guard !shown.isEmpty else { return }

                // Whole entries only. Pages are cut on `timestamp`, and every
                // block of one transcript entry carries the SAME timestamp — so
                // a page that stopped mid-entry didn't defer the rest, it lost
                // it: the next page asks for `timestamp < thatTimestamp`, which
                // excludes the entry it half-rendered. The one exception is an
                // entry bigger than `limit` all by itself, which is emitted
                // whole (a short overshoot) because otherwise it would wedge
                // paging at that point forever.
                if !entries.isEmpty, entries.count + shown.count > limit {
                    done = true
                    return
                }
                for (offset, line) in shown {
                    entries.append(ConversationEntryDTO(
                        id: feedRow.id * Self.maxLinesPerConversationEntry + offset,
                        sessionId: sessionId,
                        kind: line.kind.rawValue,
                        text: line.text,
                        timestamp: timestamp,
                        projectName: projectName,
                        gitBranch: feedRow.gitBranch,
                        sessionName: sessionName,
                        termProgram: feedRow.termProgram
                    ))
                }
                if entries.count >= limit { done = true }
            }
            func consumeQueued(_ lineId: Int) throws {
                guard !done else { return }
                try database.query("""
                    SELECT \(columns)
                    FROM transcript_lines t
                    LEFT JOIN sessions s ON s.session_id = t.session_id
                    WHERE t.id = ?
                    """, params: [lineId]) { row in
                    consume(FeedRow(row: row, reader: self.database))
                }
            }

            // Both lists are newest first, so the queued prompts newer than each
            // scanned row go in ahead of it. A scan that came back full stops
            // short of the older history, so the queued prompts older than its
            // last row wait for the next page, which starts from there. A scan
            // that came back short reached the start, so they all belong here.
            var next = 0
            var scanned = 0
            try database.query(sql, params: params) { row in
                guard !done else { return }
                scanned += 1
                let feedRow = FeedRow(row: row, reader: self.database)
                while next < queued.count, queued[next].timestamp > feedRow.timestamp {
                    try consumeQueued(queued[next].lineId)
                    next += 1
                }
                consume(feedRow)
            }
            if scanned < scanLimit {
                while next < queued.count, !done {
                    try consumeQueued(queued[next].lineId)
                    next += 1
                }
            }
            return entries
        }
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
    ///     set, and a script-driven session's lines (the extractor's
    ///     `includeMachinery`). A headless `claude -p` that hands its task to an
    ///     agent writes almost nothing else, so without them it reads as empty.
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
                let shown = self.extractCache.lines(
                    lineId: lineId, rawJSON: rawJSON, includeMachinery: includeWorkOutput)
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

    /// The id stride between two transcript entries, and therefore the cap on
    /// how many lines one entry may contribute.
    ///
    /// `id = transcript_lines.id * stride + blockIndex` only stays unique while
    /// `blockIndex < stride`; at the old stride of 100, an entry with 100 blocks
    /// produced ids that collided with the next entry's. A thousand is far past
    /// anything a real message holds, and lines beyond it are dropped rather
    /// than allowed to collide — a silently missing line is recoverable, two
    /// rows fighting over one identity in the window is not.
    private static let maxLinesPerConversationEntry = 1000
}
#endif
