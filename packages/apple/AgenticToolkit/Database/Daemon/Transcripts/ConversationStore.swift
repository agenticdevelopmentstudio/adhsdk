#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
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
    /// milliseconds (`2026-09-01T10:00:00.000Z`). A message whose line carried
    /// no timestamp is stored at the epoch and is shown, not dropped: it sorts
    /// to the oldest end of the feed, in file order, stamped
    /// `1970-01-01T00:00:00.000Z`. Nothing is older than that, so a `before`
    /// cursor taken from such an entry returns nothing more; the untimed
    /// entries a page did not reach are not paged to.
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
        for message in messages {
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

            // Whole entries only. Pages are cut on the timestamp, and every
            // block of one message carries the SAME one — so a page that
            // stopped mid-entry would lose the rest: the next page asks for
            // older than that timestamp. The one exception is an entry bigger
            // than `limit` all by itself, emitted whole (a short overshoot)
            // because otherwise it would wedge paging at that point forever.
            if !entries.isEmpty, entries.count + shown.count > limit { break }
            let timestamp = message.timestamp
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
            if entries.count >= limit { break }
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
