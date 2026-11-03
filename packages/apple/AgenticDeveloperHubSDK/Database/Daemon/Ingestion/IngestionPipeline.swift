#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

/// The capture-to-database path of a session daemon, composed once: quarantine,
/// ingestor, spool drain, the `capture` closure both live capture paths feed, and
/// the hook socket.
///
/// Nothing here touches the main database until ``startDraining()``, which is the
/// requirement: all of it can exist, and ``startAcceptingCaptures()`` can be
/// running, before the database is migrated. A capture then goes into the spool
/// (a lock and an INSERT, with no main-DB schema, lock or transaction involved),
/// and the drain empties the spool into the database once it is ready.
///
/// The spool is opened by the caller and passed in, because opening it is one of
/// the awaits a daemon traces at startup.
public final class IngestionPipeline: @unchecked Sendable {

    /// Where the pipeline reads and writes on disk.
    public struct Paths: Sendable {
        /// Where hook drop files land; also the fallback when the spool refuses a write.
        public var dropDirectory: URL
        /// Where quarantined events are moved; each gets a `.meta.json` sidecar.
        public var errorsDirectory: URL
        /// The Unix socket a hook script connects to.
        public var socketPath: String

        public init(dropDirectory: URL, errorsDirectory: URL, socketPath: String) {
            self.dropDirectory = dropDirectory
            self.errorsDirectory = errorsDirectory
            self.socketPath = socketPath
        }
    }

    public let ingestor: EventIngestor
    public let quarantine: QuarantineService
    public let spool: IngestSpool
    /// The one way a live event enters the daemon, shared by both capture paths (the
    /// socket and an HTTP hook route). It writes to the spool and pokes the drain.
    /// If the spool itself is unwritable it falls back to a drop file, which the
    /// directory watcher owns from then on.
    public let capture: @Sendable (ParsedEvent) throws -> Void
    /// Ingests one event straight into the database, bypassing the spool: what the
    /// quarantine retry feeds. It runs well after the migration, and routing an
    /// already-quarantined file back through the queue would only make it harder
    /// to follow. Strong capture of the ingestor on purpose: a nil (optional-chained)
    /// ingestor would return without throwing, so a retry would count the event
    /// "recovered" and delete the file WITHOUT ingesting it.
    public let retryIngest: @Sendable (ParsedEvent) throws -> Void

    /// Whether the legacy writers run: no Claude pipeline at init and the fallback
    /// allowed. Fixed for the run: a pipeline that opens later never takes over
    /// from running legacy writers (the runtime only retries the open when the
    /// fallback is off).
    public let legacyWriters: Bool

    /// The Claude pipeline, read at call time by `capture`, `retryIngest`, the
    /// quarantine's preserve and the transcript tailer, so one that opens mid-run
    /// takes over all four.
    public let claude: ClaudePipelineSlot

    private let drainer: IngestDrainer
    private let socketHandler: IngestSocketHandler

    /// - Parameters:
    ///   - queueLabel: maps a short name to a full label; labels the quarantine
    ///     queue, the tailer queue and the drain thread so a daemon can put them
    ///     under its own subsystem.
    ///   - decode: turns the bytes of one socket connection into an event, throwing
    ///     ``SocketDecodeFailure`` when they are malformed or untrackable.
    ///   - summarizeOnStop: called with the session id after `Stop` / `SessionEnd`.
    ///   - footprintSuffix: appended to the ingestor's backfill log lines.
    ///   - claude: the Claude provider pipeline, as a slot that may be filled
    ///     later. While it holds one, a capture and a quarantine retry go to its
    ///     spool, and the transcript tailer feeds its transcript source, instead of
    ///     the legacy spool and writers, and a quarantined file is preserved in its
    ///     raw archive before the service deletes it. Empty at init keeps the
    ///     legacy path, subject to `legacyWriterFallback`.
    ///   - legacyWriterFallback: whether, with no Claude pipeline at init, the
    ///     legacy writers (`ingestEvent`, `JSONLImporter`) take over. True for a
    ///     daemon that still writes the legacy tables. False for one whose events
    ///     live in the Claude pipeline only: there, until the slot is filled, a
    ///     capture stays in the legacy spool (adopted when the pipeline opens), a
    ///     quarantine retry and a quarantine preserve are held
    ///     (`QuarantineRetryHeld`, so the file is kept), the transcript tailer
    ///     reads nothing (the lines stay on disk behind the transcript source's
    ///     cursor) and ``startDraining()`` does nothing.
    public init(
        paths: Paths,
        spool: IngestSpool,
        database: DaemonDatabase,
        sink: any SessionEventSink,
        queueLabel: @Sendable (String) -> String,
        decode: @escaping @Sendable (Data) throws -> ParsedEvent,
        summarizeOnStop: (@Sendable (String) async -> Void)? = nil,
        footprintSuffix: @escaping @Sendable () -> String = { "" },
        claude: ClaudePipelineSlot = ClaudePipelineSlot(),
        legacyWriterFallback: Bool = true
    ) {
        let legacyWriters = claude.current == nil && legacyWriterFallback
        let quarantine = QuarantineService(
            errorsDirectory: paths.errorsDirectory,
            database: database,
            queueLabel: queueLabel("quarantine-retry"),
            preserveRaw: Self.preserveRaw(claude, legacyWriters: legacyWriters)
        )
        let ingestor = EventIngestor(
            dropDirectory: paths.dropDirectory,
            database: database,
            sink: sink,
            quarantine: quarantine,
            tailerQueueLabel: queueLabel("transcript-tailer"),
            summarizeOnStop: summarizeOnStop,
            footprintSuffix: footprintSuffix,
            transcriptPoll: Self.transcriptPoll(claude, legacyWriters: legacyWriters)
        )
        let drainer = IngestDrainer(
            spool: spool,
            quarantine: quarantine,
            errorsDirectory: paths.errorsDirectory,
            ingestBatch: { [ingestor] in try ingestor.ingestBatch($0) },
            ingestOne: { [ingestor] in try ingestor.ingest($0) },
            threadName: queueLabel("ingest-drain")
        )
        let dropDirectory = paths.dropDirectory
        let capture: @Sendable (ParsedEvent) throws -> Void = { [drainer] incoming in
            // Stamped once, here, before routing: an event held in the legacy
            // spool while the pipeline is closed carries the fingerprint of its
            // file at event time too (a later stamp would measure a later file).
            let event = ClaudeFileFingerprint.stamped(incoming)
            do {
                // Appends to the Claude spool and wakes its drainer when the
                // pipeline is open. Otherwise the legacy spool takes it, under the
                // slot's lock, so a pipeline opening now adopts it.
                let captured = try claude.route(
                    open: { pipeline in try pipeline.capture(event); return true },
                    held: { try spool.enqueue(event); return false })
                if captured { return }
            } catch {
                // The spool file itself is unwritable — a full volume, most
                // likely, which is also the one condition under which an
                // undrainable spool grows until it causes exactly this. Both
                // callers fail open (a hook delivery must never surface an error
                // to Claude), so a throw from here is an event deleted. Fall back
                // to the drop directory, the capture path that predates the spool
                // and is still watched: one more small file may well fit where a
                // SQLite page did not, and if it doesn't, the throw is at least
                // now the *second* thing that failed rather than the first.
                Self.logger.error("""
                    Spool enqueue failed (\(error.localizedDescription, privacy: .public)); \
                    falling back to a drop file
                    """)
                try Self.writeDropFile(event, into: dropDirectory)
                return  // The directory watcher owns it now; nothing to wake.
            }
            drainer.wake()
        }
        self.quarantine = quarantine
        self.ingestor = ingestor
        self.spool = spool
        self.drainer = drainer
        self.capture = capture
        if legacyWriters {
            self.retryIngest = { [ingestor] in try ingestor.ingest($0) }
        } else {
            // A retried event is captured afresh: the Claude spool takes it and the
            // drainer writes it, so nothing re-enters the legacy writer. With the
            // pipeline not open there is nowhere to write it: the file stays
            // quarantined, its retry count untouched, for a retry once it opens.
            self.retryIngest = { event in
                guard let pipeline = claude.current else {
                    throw QuarantineRetryHeld("Claude pipeline unavailable")
                }
                try pipeline.capture(event)
            }
        }
        self.legacyWriters = legacyWriters
        self.claude = claude
        self.socketHandler = IngestSocketHandler(
            socketPath: paths.socketPath, capture: capture, decode: decode
        )
    }

    // MARK: - Lifecycle

    /// Binds the hook socket. Needs no main-database schema, so it can run before
    /// the migration. Throws on a bind failure.
    public func startAcceptingCaptures() throws {
        try socketHandler.start()
    }

    /// Starts emptying the spool into the database. Call only once the database is
    /// migrated — this is the writer the migration protects the schema for.
    /// Does nothing when the legacy writers are off (a Claude pipeline is
    /// attached, or `legacyWriterFallback` is false): the legacy spool is then
    /// only a holding area the Claude pipeline adopts.
    public func startDraining() {
        guard legacyWriters else { return }
        drainer.start()
    }

    /// Stops the drain (waiting for the pass in flight, so a batch already running
    /// finishes against the database rather than being abandoned mid-transaction)
    /// and then the socket. Anything still spooled stays spooled and drains on
    /// the next launch — that is what the file is for.
    public func stop() async {
        drainer.stop()
        socketHandler.stop()
    }

    /// The tailer's per-file read into the Claude pipeline; nil for the legacy
    /// import. While the pipeline is not open it reads nothing (the lines wait on
    /// disk behind the transcript source's cursor).
    private static func transcriptPoll(
        _ claude: ClaudePipelineSlot, legacyWriters: Bool
    ) -> (@Sendable (URL) throws -> Void)? {
        if legacyWriters { return nil }
        return { url in
            guard let pipeline = claude.current else { return }
            _ = try pipeline.pollTranscript(file: url)
        }
    }

    /// Hands a quarantined file to the Claude pipeline before the quarantine
    /// deletes it; nil (delete outright) for legacy writers. While the pipeline is
    /// not open the preserve is held, so the quarantine keeps the file.
    private static func preserveRaw(
        _ claude: ClaudePipelineSlot, legacyWriters: Bool
    ) -> (@Sendable (URL) throws -> Void)? {
        if legacyWriters { return nil }
        return { url in
            guard let pipeline = claude.current else {
                throw QuarantineRetryHeld("Claude pipeline unavailable")
            }
            try pipeline.preserveQuarantinedFile(url)
        }
    }

    // MARK: - Drop file fallback

    /// Last-resort capture when the spool refuses a write: the same envelope, in
    /// the same format, in the directory ``EventIngestor`` already watches. The
    /// name sorts by arrival and must not start with `error-`, which that scan
    /// skips.
    static func writeDropFile(_ event: ParsedEvent, into directory: URL) throws {
        let envelope = try event.envelopeJSON()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "spill-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString).json"
        // Atomic: a plain write creates the file and fills it in two steps, so a
        // daemon killed in between (an install restart, say) leaves a 0-byte drop
        // that the ingestor can only read as a lost event.
        try envelope.write(to: directory.appendingPathComponent(name), options: .atomic)
    }
}

extension IngestionPipeline: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
