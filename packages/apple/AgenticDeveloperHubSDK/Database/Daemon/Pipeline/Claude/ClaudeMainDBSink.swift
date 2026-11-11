#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB

/// Keeps a session database's derived state current from the Claude pipeline,
/// so the sessions list, titles, subagent dispatches and per-session metrics
/// read the same as they did when every event went through `ingestEvent` and
/// the JSONL importer. The events themselves live in the event store; this
/// writes none of `event_log`, the per-type tables or `transcript_turns`.
///
/// - Hook records (`hook`, `hook-legacy`): the envelope is re-parsed and handed to
///   `DaemonDatabase.applySessionState`, the session half of `ingestEvent`.
/// - Transcript records: a session the daemon never saw gets a stub row (as the
///   importer makes one), and a later batch's newer lines advance its
///   `last_activity_at`, model and branch (`advanceSession`), as the importer's
///   whole-file fold would have; dispatches are upserted, and each touched session's
///   title and `session_metrics` are recomputed from the event store, so the
///   result does not depend on which batch a line arrived in.
///
/// Idempotent, as a `PipelineSink` must be: every write is an upsert, a
/// first-wins insert or a recompute from the store, and a StatusLine already
/// recorded for its session is not handed to `statusLineIngest` again. The whole
/// batch is one transaction, so a throw leaves nothing half-applied.
public final class ClaudeMainDBSink: PipelineSink {
    private let database: DaemonDatabase
    private let eventReads: EventStore

    public init(database: DaemonDatabase, eventReads: EventStore) {
        self.database = database
        self.eventReads = eventReads
    }

    public func write(_ batch: NormalizedBatch, records: [ArchivedRecord], provider: String) throws {
        guard provider == ClaudeProvider.name else { return }
        let hooks = hookEvents(records)
        var transcripts = TranscriptFold()
        for archived in records where archived.record.sourceKind == ClaudeProvider.transcriptKind {
            transcripts.add(archived)
        }
        for turn in batch.turns {
            transcripts.metricSessions.insert(turn.sessionID)
        }
        // Resolved before the writer is taken: `currentAccountEmail` may stat and
        // parse `~/.claude.json`. Only needed for a session nothing has stamped.
        let fallbackAccount = transcripts.isEmpty ? "" : database.currentAccountEmail
        // Read from the event store before the writer is taken too, so the batch
        // never holds the session database's writer while it waits on another
        // database. (Reentrancy is per database, so a nested read would reach the
        // event store's own connection; it is ordering, not routing, that this
        // protects.)
        let derived = try derive(transcripts)
        let lastTools = try newestTools(hooks)
        let earliest = Self.earliestTimes(batch)

        try database.transaction {
            for hook in hooks {
                try apply(hook)
            }
            for (sessionId, tool) in lastTools.sorted(by: { $0.key < $1.key }) {
                try database.execute(
                    "UPDATE sessions SET last_tool = ? WHERE session_id = ?", params: [tool, sessionId])
            }
            try applyTranscripts(transcripts, derived: derived, fallbackAccount: fallbackAccount)
            try lowerStartedAt(earliest)
        }
    }

    // MARK: - Session start

    /// Each session's earliest event or turn time in the batch, epoch seconds.
    /// A time before `claudeEarliestKnownEventTime` is "time unknown" and never
    /// counts.
    static func earliestTimes(_ batch: NormalizedBatch) -> [String: Double] {
        var earliest: [String: Double] = [:]
        func see(_ sessionId: String, _ time: Date) {
            let seconds = time.timeIntervalSince1970
            guard !sessionId.isEmpty, seconds >= DaemonDatabase.claudeEarliestKnownEventTime else { return }
            earliest[sessionId] = min(earliest[sessionId] ?? seconds, seconds)
        }
        for event in batch.events { see(event.sessionID, event.time) }
        for turn in batch.turns { see(turn.sessionID, turn.time) }
        return earliest
    }

    /// `sessions.started_at` is the earliest event or turn time seen for the
    /// session, not the wall clock when its first record was ingested (the
    /// column default a hook-created row takes): `MIN(started_at, batch)`, both
    /// compared in `datetime` text form (whole seconds). The stored value is read
    /// through `datetime()`, so a transcript stub's ISO-8601 stamp compares
    /// correctly and is kept when it is already the earliest second (as the
    /// JSONL importer leaves it); a later one is lowered and written in
    /// `datetime` form, and one that does not parse is replaced. Must run inside
    /// the batch's transaction, after the rows are created.
    private func lowerStartedAt(_ earliest: [String: Double]) throws {
        for (sessionId, time) in earliest.sorted(by: { $0.key < $1.key }) {
            try database.execute("""
                UPDATE sessions SET started_at = datetime(?, 'unixepoch')
                WHERE session_id = ?
                  AND (datetime(started_at) IS NULL OR datetime(started_at) > datetime(?, 'unixepoch'))
                """, params: [time, sessionId, time])
        }
    }

    // MARK: - Hooks

    private struct HookEvent {
        let event: ParsedEvent
        let account: (email: String, authMethod: String)
    }

    /// The batch's hook envelopes, parsed, with each one's account resolved
    /// (outside the writer, like `ingestEvent`). Envelopes that parse to nothing
    /// to ingest are dropped, as the normalizer drops them.
    private func hookEvents(_ records: [ArchivedRecord]) -> [HookEvent] {
        records.compactMap { archived in
            let raw = archived.record
            guard raw.sourceKind == ClaudeProvider.hookKind || raw.sourceKind == ClaudeProvider.legacyHookKind,
                  let text = String(data: raw.payload, encoding: .utf8),
                  case .event(let parsed) = ParseResult.parse(envelopeJSON: text) else { return nil }
            let account = database.resolveIngestAccount(
                accountEmail: parsed.accountEmail, oauthAccountEmail: parsed.oauthAccountEmail)
            return HookEvent(event: parsed, account: account)
        }
    }

    /// For each session with a tool hook in the batch, the tool of its newest
    /// stored tool hook. `applySessionState` orders `last_tool` against
    /// `last_activity_at`, which a transcript stub also sets, so a hook backlog
    /// drained after the stub was made would never set it; read back from the
    /// event store, it is the newest tool hook's whatever the arrival order. Only
    /// hook events carry a `tool_name` there. A session with none stored (its
    /// hooks already trimmed) keeps what `applySessionState` wrote. Must run
    /// outside the session database's writer.
    private func newestTools(_ hooks: [HookEvent]) throws -> [String: String] {
        var sessions: Set<String> = []
        for hook in hooks {
            let data = hook.event.hookData
            guard let sessionId = data["session_id"] as? String, !sessionId.isEmpty,
                  let tool = data["tool_name"] as? String, !tool.isEmpty else { continue }
            sessions.insert(sessionId)
        }
        guard !sessions.isEmpty else { return [:] }
        return try eventReads.read { conn -> [String: String] in
            var tools: [String: String] = [:]
            for sessionId in sessions {
                tools[sessionId] = try String.fetchOne(conn, sql: """
                    SELECT tool_name FROM events
                    WHERE provider = ? AND session_id = ? AND tool_name IS NOT NULL AND tool_name <> ''
                    ORDER BY time DESC, id DESC LIMIT 1
                    """, arguments: [ClaudeProvider.name, sessionId])
            }
            return tools
        }
    }

    private func apply(_ hook: HookEvent) throws {
        let event = hook.event
        let routesStatusLine = event.eventType == "StatusLine"
            ? try !statusLineRecorded(event)
            : true
        _ = try database.applySessionState(
            eventType: event.eventType, timestamp: event.timestamp, hookData: event.hookData,
            account: hook.account, routesStatusLine: routesStatusLine, ordersByTime: true)
    }

    /// True when the session's `rate_limit_snapshots` already holds a row stamped
    /// with exactly this StatusLine's timestamp (`statusLineIngest` stores it
    /// verbatim): the record is a redelivery, and its whole routing — snapshot,
    /// `claude_versions`, the `session_metrics` extended columns — was applied with
    /// it. Any other StatusLine, older ones included, is routed as `ingestEvent`
    /// routes it.
    ///
    /// Not exact in two cases, both left to `statusLineIngest`'s own dedup: a
    /// first delivery whose values matched the session's latest row wrote no
    /// snapshot, so its redelivery is routed again; and two distinct StatusLines
    /// with the same timestamp string count as one.
    private func statusLineRecorded(_ event: ParsedEvent) throws -> Bool {
        let sessionId = event.hookData["session_id"] as? String ?? ""
        var found = false
        try database.query("""
            SELECT 1 FROM rate_limit_snapshots
            WHERE session_id = ? AND timestamp = ?
            LIMIT 1
            """, params: [sessionId, event.timestamp]) { _ in found = true }
        return found
    }

    // MARK: - Transcripts

    /// What a batch's transcript lines say about their sessions, gathered as the
    /// JSONL importer gathers it.
    private struct TranscriptFold {
        struct Bucket {
            var turns = 0
            var model = ""
            var firstTs = ""
            var lastTs = ""
            var cwd = ""
            var gitBranch = ""
        }

        var buckets: [String: Bucket] = [:]
        var dispatches: [JSONLScanner.AgentDispatch] = []
        /// Sessions whose title is recomputed: any with a title or a turn line here.
        var titleSessions: Set<String> = []
        /// Sessions whose `session_metrics` is recomputed: any with a turn here.
        var metricSessions: Set<String> = []

        var isEmpty: Bool { buckets.isEmpty && dispatches.isEmpty && titleSessions.isEmpty && metricSessions.isEmpty }

        mutating func add(_ archived: ArchivedRecord) {
            guard let payload = try? ClaudeTranscriptPayload.decode(archived.record.payload) else { return }
            let extras = JSONLScanner.parseExtras(payload.line)
            if let title = extras.title {
                titleSessions.insert(title.sessionId)
                return
            }
            if let dispatch = extras.dispatch {
                dispatches.append(dispatch)
            }
            guard let turn = JSONLScanner.parse(payload.line, isSubagentFile: payload.subagentFile),
                  !turn.sessionId.isEmpty else { return }
            var bucket = buckets[turn.sessionId] ?? Bucket()
            bucket.turns += 1
            if !turn.model.isEmpty { bucket.model = turn.model }
            if !turn.cwd.isEmpty { bucket.cwd = turn.cwd }
            if !turn.gitBranch.isEmpty { bucket.gitBranch = turn.gitBranch }
            if bucket.firstTs.isEmpty || (turn.timestamp < bucket.firstTs && !turn.timestamp.isEmpty) {
                bucket.firstTs = turn.timestamp
            }
            if !turn.timestamp.isEmpty, turn.timestamp > bucket.lastTs {
                bucket.lastTs = turn.timestamp
            }
            buckets[turn.sessionId] = bucket
            titleSessions.insert(turn.sessionId)
            metricSessions.insert(turn.sessionId)
        }
    }

    /// What the event store says about the batch's sessions: their newest titles
    /// and their metrics, recomputed over every stored turn.
    private struct Derived {
        var titles: [String: [String: String]] = [:]
        var metrics: [String: SessionMetricsDTO] = [:]
    }

    /// Must run outside the session database's writer.
    private func derive(_ fold: TranscriptFold) throws -> Derived {
        var derived = Derived()
        for sessionId in fold.titleSessions where !sessionId.isEmpty {
            derived.titles[sessionId] = try newestTitles(sessionId: sessionId)
        }
        for sessionId in fold.metricSessions where !sessionId.isEmpty {
            derived.metrics[sessionId] = try database.sessionMetricsFromTurns(sessionId: sessionId, reads: eventReads)
        }
        return derived
    }

    /// Must run inside the batch's transaction.
    private func applyTranscripts(_ fold: TranscriptFold, derived: Derived, fallbackAccount: String) throws {
        var accounts: [String: String] = [:]
        func account(_ sessionId: String) -> String {
            if let cached = accounts[sessionId] { return cached }
            let stamped = database.accountEmailForSession(sessionId)
            let resolved = stamped.isEmpty ? fallbackAccount : stamped
            accounts[sessionId] = resolved
            return resolved
        }

        for (sessionId, bucket) in fold.buckets.sorted(by: { $0.key < $1.key }) where bucket.turns > 0 {
            // Import-only sessions the live daemon never saw, attributed as the
            // importer attributes them: best effort, tagged `unknown`, healed by
            // the next token hook.
            try database.createSessionStubIfMissing(
                sessionId: sessionId, cwd: bucket.cwd, model: bucket.model,
                startedAt: bucket.firstTs, lastActivityAt: bucket.lastTs, gitBranch: bucket.gitBranch,
                accountEmail: account(sessionId), authMethod: "unknown")
            try advanceSession(sessionId, bucket: bucket)
        }
        for dispatch in fold.dispatches {
            try database.upsertAgentDispatch(
                agentId: dispatch.agentId, sessionId: dispatch.sessionId, agentType: dispatch.agentType,
                startedAt: dispatch.timestamp, status: dispatch.status, totalTokens: dispatch.totalTokens,
                totalDurationMs: dispatch.totalDurationMs, totalToolUseCount: dispatch.totalToolUseCount)
        }
        for (sessionId, latest) in derived.titles.sorted(by: { $0.key < $1.key }) {
            try applyTitles(latest, sessionId: sessionId)
        }
        for (sessionId, metrics) in derived.metrics.sorted(by: { $0.key < $1.key }) {
            try database.upsertSessionMetrics(metrics, accountEmail: account(sessionId))
        }
    }

    /// A stub keeps what the batch that created it knew, and a drain batch holds
    /// at most a few hundred records, so a long transcript-only session would
    /// otherwise keep its first batch's last activity, model and branch. This
    /// raises `last_activity_at` to the batch's newest line time when that is later
    /// than the stored one (both compared in `datetime` form, written in it), and
    /// takes the batch's model and branch with it when it has them; an empty
    /// model, branch or cwd is filled from the batch either way. Older lines move
    /// nothing, so the outcome does not depend on which batch a line arrived in.
    /// Must run inside the batch's transaction, after the row exists.
    private func advanceSession(_ sessionId: String, bucket: TranscriptFold.Bucket) throws {
        if !bucket.lastTs.isEmpty {
            try database.execute("""
                UPDATE sessions SET
                    last_activity_at = datetime(?),
                    model = CASE WHEN ? <> '' THEN ? ELSE model END,
                    git_branch = CASE WHEN ? <> '' THEN ? ELSE git_branch END
                WHERE session_id = ? AND datetime(?) IS NOT NULL
                  AND (datetime(last_activity_at) IS NULL OR datetime(last_activity_at) < datetime(?))
                """, params: [bucket.lastTs, bucket.model, bucket.model, bucket.gitBranch, bucket.gitBranch,
                              sessionId, bucket.lastTs, bucket.lastTs])
        }
        try database.execute("""
            UPDATE sessions SET
                model = CASE WHEN model = '' THEN ? ELSE model END,
                git_branch = CASE WHEN git_branch = '' THEN ? ELSE git_branch END,
                cwd = CASE WHEN cwd = '' THEN ? ELSE cwd END
            WHERE session_id = ? AND (model = '' OR git_branch = '' OR cwd = '')
            """, params: [bucket.model, bucket.gitBranch, bucket.cwd, sessionId])
    }

    /// The session's newest ai title and its newest custom title, read from
    /// the event store. Reading them back rather than applying the batch's own
    /// makes the outcome independent of arrival order: a custom title beats an ai
    /// title whichever came first, and a title whose line arrived before the
    /// session had a row lands once a later batch creates the row.
    private func newestTitles(sessionId: String) throws -> [String: String] {
        try eventReads.read { conn -> [String: String] in
            let rows = try Row.fetchAll(conn, sql: """
                SELECT provider_type, json_extract(attrs, '$.title')
                FROM events
                WHERE provider = ? AND session_id = ? AND provider_type IN ('custom-title', 'ai-title')
                ORDER BY time DESC, id DESC
                """, arguments: [ClaudeProvider.name, sessionId])
            var newest: [String: String] = [:]
            for row in rows {
                let type: String = row[0]
                guard newest[type] == nil, let title = row[1] as String?, !title.isEmpty else { continue }
                newest[type] = title
            }
            return newest
        }
    }

    /// Applies `newestTitles`' result: ai first, so a custom title always wins.
    private func applyTitles(_ latest: [String: String], sessionId: String) throws {
        if let title = latest["ai-title"] {
            try database.updateSessionTranscriptTitle(sessionId: sessionId, title: title, source: "ai")
        }
        if let title = latest["custom-title"] {
            try database.updateSessionTranscriptTitle(sessionId: sessionId, title: title, source: "custom")
        }
    }
}
#endif
