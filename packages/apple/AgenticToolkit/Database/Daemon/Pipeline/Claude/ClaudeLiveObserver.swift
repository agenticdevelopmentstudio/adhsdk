#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB

/// What a daemon does for a session after one of its hook events is stored, off
/// the ingestion path: tail its transcript, enrich it at `SessionStart`, refresh
/// its title and last output at `Stop` / `SessionEnd`, and heal a missing
/// project root once per session. One value serves both ingestion paths
/// (`EventIngestor` and `ClaudeLiveObserver`), so the logic exists once.
///
/// Each step is a closure so a test can record the calls; `live` builds the
/// daemon's real ones.
public struct ClaudeEnrichmentHooks: Sendable {
    /// A hook fired for `sessionId`, so its transcript at `path` just grew.
    public var noteTranscriptActivity: @Sendable (_ path: String, _ sessionId: String) -> Void
    /// `SessionStart`: full enrichment (project root, branch, title).
    public var enrichOnStart: @Sendable (_ sessionId: String, _ cwd: String, _ transcriptPath: String?) -> Void
    /// `Stop` / `SessionEnd`: title and last output, then the stop summary.
    public var onStopOrEnd: @Sendable (_ sessionId: String, _ transcriptPath: String?) -> Void
    /// Any event: give the session its project root if it has none yet.
    public var healProjectRoot: @Sendable (_ sessionId: String) -> Void

    public init(
        noteTranscriptActivity: @escaping @Sendable (_ path: String, _ sessionId: String) -> Void,
        enrichOnStart: @escaping @Sendable (_ sessionId: String, _ cwd: String, _ transcriptPath: String?) -> Void,
        onStopOrEnd: @escaping @Sendable (_ sessionId: String, _ transcriptPath: String?) -> Void,
        healProjectRoot: @escaping @Sendable (_ sessionId: String) -> Void
    ) {
        self.noteTranscriptActivity = noteTranscriptActivity
        self.enrichOnStart = enrichOnStart
        self.onStopOrEnd = onStopOrEnd
        self.healProjectRoot = healProjectRoot
    }

    /// Runs the steps one stored hook event calls for. Every event heals the
    /// project root and, when it names its transcript, notes activity on it;
    /// `SessionStart` enriches, and `Stop` / `SessionEnd` refresh.
    public func run(eventType: String, sessionId: String, cwd: String, transcriptPath: String?) {
        healProjectRoot(sessionId)
        // A hook firing means the session just wrote to its transcript, and the
        // payload says which file. That is the whole signal the five-minute sweep
        // re-walks the tree to reconstruct, so hand it straight to the tailer:
        // every event type, because every one of them is a line being written,
        // and the tailer is what decides how often a given file is worth reading.
        if let transcriptPath {
            noteTranscriptActivity(transcriptPath, sessionId)
        }
        switch eventType {
        case "SessionStart":
            enrichOnStart(sessionId, cwd, transcriptPath)
        case "Stop", "SessionEnd":
            onStopOrEnd(sessionId, transcriptPath)
        default:
            break
        }
    }

    /// The daemon's enrichment: each step is scheduled off the calling thread, so
    /// ingestion is never blocked on git, a subprocess or a file read.
    ///
    /// - Parameter summarizeOnStop: called with the session id after `Stop` /
    ///   `SessionEnd`, once its title and last output are refreshed.
    public static func live(
        database: DaemonDatabase,
        transcriptTailer: TranscriptTailer,
        summarizeOnStop: (@Sendable (String) async -> Void)?
    ) -> ClaudeEnrichmentHooks {
        // Resumes each transcript's title scan where the last Stop left it.
        let titleScanner = TranscriptTitleScanner()
        let probes = ProbedSessions()
        return ClaudeEnrichmentHooks(
            noteTranscriptActivity: { path, sessionId in
                Task { await transcriptTailer.noteActivity(transcriptPath: path, sessionId: sessionId) }
            },
            enrichOnStart: { sessionId, cwd, transcriptPath in
                Task.detached {
                    SessionEnricher.enrich(
                        sessionId: sessionId,
                        cwd: cwd,
                        // Force a fresh project_root at session start (cwd is authoritative
                        // then); it's a single session, so the recompute cost is trivial.
                        projectRootVersion: 0,
                        // The hook fired for this session just now, so the file is the
                        // only source that can be current — the importer may not have
                        // reached it yet. One session, so the scan cost is trivial.
                        titleSource: .transcriptFile(path: transcriptPath),
                        database: database
                    )
                }
            },
            onStopOrEnd: { sessionId, transcriptPath in
                Task.detached {
                    let path = transcriptPath ?? SessionEnricher.findTranscriptPath(sessionId: sessionId)
                    guard let path else { return }
                    if let title = titleScanner.title(path: path), !title.isEmpty {
                        try? database.updateSessionTranscriptTitle(
                            sessionId: sessionId, title: title, source: "custom"
                        )
                    }
                    // Stop fires the instant the agent finishes speaking, which is the
                    // only moment its last reply is knowable: no hook payload carries
                    // the text, and the JSONL importer is five minutes behind.
                    SessionEnricher.refreshLastOutput(
                        sessionId: sessionId, transcriptPath: path, database: database
                    )
                    await summarizeOnStop?(sessionId)
                }
            },
            healProjectRoot: { sessionId in
                healProjectRootIfNeeded(sessionId: sessionId, database: database, probes: probes)
            }
        )
    }

    /// Gives a session its `project_root` as soon as any event arrives for it, rather
    /// than only at `SessionStart`.
    ///
    /// A session whose `SessionStart` this daemon never saw — it was already running
    /// when the daemon started, or the hooks were installed mid-session — stays at
    /// `project_root_version = 0` with no root, and the only thing that ever filled
    /// one in was the *startup* backfill. So a live session could sit in the Sessions
    /// window for its whole life labelled with its `cwd`'s last path component and
    /// grouped alone: two worktrees of one project showed up as two projects, each
    /// named after the worktree directory rather than the project.
    ///
    /// Bounded by `probes`: one DB read per session per daemon lifetime, not one per
    /// event. A session that comes back `.undetermined` (git wouldn't answer) is not
    /// retried until the next launch — the same terms as every other enrichment
    /// retry, and the alternative is re-running `git` for every event of a session
    /// whose repository is simply unhealthy.
    ///
    /// Takes no `cwd`: the directory to repair from is the session's own, and that is
    /// read back from the row alongside the version.
    private static func healProjectRootIfNeeded(
        sessionId: String, database: DaemonDatabase, probes: ProbedSessions
    ) {
        guard probes.claim(sessionId) else { return }
        Task.detached {
            // No row (or an unreadable DB) means the probe learned nothing, so re-open
            // it rather than spending the session's one chance on a non-answer.
            // `try?` flattens the throw and the missing row into one nil, and both
            // mean the same thing here: nothing was learned.
            guard let stored = try? database.sessionProjectRootProbe(sessionId: sessionId) else {
                probes.reopen(sessionId)
                return
            }
            guard stored.version < SessionEnricher.projectRootAlgoVersion,
                  !stored.cwd.isEmpty else { return }
            SessionEnricher.enrich(
                sessionId: sessionId,
                // The session's OWN cwd, read back from the row — never the `cwd` of
                // the hook that triggered this. The session cwd is frozen on purpose;
                // the hook's is wherever the agent's shell happens to be standing, and
                // `enrich` derives `git_branch` from what it is handed. Passing the
                // hook's meant one `cd ../sibling-repo` stamped that repo's branch onto
                // this session — permanently, since the write is unguarded and this
                // probe never runs twice.
                cwd: stored.cwd,
                projectRootVersion: stored.version,
                // The importer has this session's lines or it doesn't; either way this
                // is a repair pass, not a live-title refresh, so it must not burn a
                // full transcript scan.
                titleSource: .importedLines,
                database: database
            )
        }
    }

    /// Sessions the project-root probe has already looked up. Guarded by a lock
    /// because ingestion reaches it from several paths (drop-directory scan, spool
    /// drain, quarantine retry, pipeline observer).
    private final class ProbedSessions: @unchecked Sendable {
        private var probed: Set<String> = []
        private let lock = NSLock()

        /// True the first time a session is claimed (it should be probed).
        func claim(_ sessionId: String) -> Bool {
            lock.withLock { probed.insert(sessionId).inserted }
        }

        /// Lets a later event probe `sessionId` again.
        func reopen(_ sessionId: String) {
            _ = lock.withLock { probed.remove(sessionId) }
        }
    }
}

/// Publishes each hook event the Claude pipeline stores, and runs its enrichment,
/// as `EventIngestor` does for an event it ingests itself.
///
/// The payload is the same `IngestedEvent` encoding `EventIngestor` broadcasts,
/// with `id` the event's row id in the event store. Transcript-derived events
/// (titles, agent dispatches) are not hook events and are not published.
///
/// Observers hear a batch at least once (`PipelineObserver`): a redelivered event
/// is published again with the same id, and its enrichment is idempotent.
public final class ClaudeLiveObserver: PipelineObserver {
    private let eventReads: EventStore
    private let sink: any SessionEventSink
    private let enrichment: ClaudeEnrichmentHooks

    /// Provider types the transcript normalizer gives the events it emits.
    static let transcriptEventTypes: Set<String> = ["custom-title", "ai-title", "agent-dispatch"]

    public init(eventReads: EventStore, sink: any SessionEventSink, enrichment: ClaudeEnrichmentHooks) {
        self.eventReads = eventReads
        self.sink = sink
        self.enrichment = enrichment
    }

    public func pipelineDidStore(_ batch: NormalizedBatch, provider: String) {
        guard provider == ClaudeProvider.name else { return }
        let hookEvents = batch.events.filter { event in
            !Self.transcriptEventTypes.contains(event.providerType)
                && !event.dedupKey.hasSuffix(ClaudeTranscriptNormalizer.dispatchKeySuffix)
                && !event.sessionID.isEmpty
        }
        guard !hookEvents.isEmpty else { return }
        let ids = (try? storedIDs(hookEvents.map(\.dedupKey))) ?? [:]
        for event in hookEvents {
            guard let id = ids[event.dedupKey] else { continue }
            publish(event, id: id)
            enrichment.run(
                eventType: event.providerType, sessionId: event.sessionID, cwd: event.cwd ?? "",
                transcriptPath: Self.string(event.attrs["transcript_path"]))
        }
    }

    /// The event store's row id for each key, read in one pass.
    private func storedIDs(_ keys: [String]) throws -> [String: Int64] {
        try eventReads.read { conn in
            var ids: [String: Int64] = [:]
            for key in keys {
                if let id = try Int64.fetchOne(conn, sql: """
                    SELECT id FROM events WHERE provider = ? AND dedup_key = ?
                    """, arguments: [ClaudeProvider.name, key]) {
                    ids[key] = id
                }
            }
            return ids
        }
    }

    private func publish(_ event: NormalizedEvent, id: Int64) {
        let ingested = IngestedEvent(
            id: id,
            event: event.providerType,
            sessionId: event.sessionID,
            timestamp: DaemonDatabase.transcriptTimestamp(
                event.time.timeIntervalSince1970, omitZeroMilliseconds: true),
            cwd: event.cwd ?? "",
            detail: event.summary ?? "",
            toolName: event.toolName ?? "",
            model: Self.string(event.attrs["model"]) ?? "",
            source: Self.string(event.attrs["source"]) ?? "")
        guard let payload = SessionEventEncoding.encode(ingested) else { return }
        sink.broadcast(eventType: ingested.event, payload: payload, sessionId: ingested.sessionId)
    }

    private static func string(_ value: NormalizedValue?) -> String? {
        guard case .string(let text)? = value else { return nil }
        return text
    }
}
#endif
