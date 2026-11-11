#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

/// The running Claude provider pipeline: its spool, archive, event store, drainer
/// and the two sources that feed it. The runtime builds one when it opens and the
/// daemon's tasks drive the sources through it.
///
/// Every input path ends the same way: append to the spool, then wake the drainer
/// (`IngestSource`'s waking contract). Transcript polls are serialized, so the
/// periodic sweep and the tailer's per-file wake never read one file's cursor at
/// the same time; hook-drop polls are serialized the same way.
public struct ClaudePipelineHandles: Sendable {
    public let spool: ProviderSpool
    public let archive: RawArchive
    public let store: EventStore
    public let drainer: PipelineDrainer
    public let hookSource: ClaudeHookDropSource
    public let transcriptSource: ClaudeTranscriptSource

    private let transcriptLock = PollLock()
    private let hookLock = PollLock()
    private let rewake = RewakeGate()

    /// Rows moved from the legacy spool per transaction.
    static let legacyBatchSize = 200
    /// Added to the hook source's `minimumAge` before a deferred drop file is
    /// looked at again, so it is old enough by then.
    static let rewakeMargin: TimeInterval = 0.05

    /// Builds the sources, the main-db sink and the drainer. Throws what
    /// `PipelineDrainer.init` throws. `drainerFaultInjector` is for tests.
    public init(
        spool: ProviderSpool,
        archive: RawArchive,
        store: EventStore,
        database: DaemonDatabase,
        dropDirectory: URL,
        projectsDirectory: URL,
        drainerFaultInjector: (@Sendable (DrainStep) throws -> Void)? = nil
    ) throws {
        self.spool = spool
        self.archive = archive
        self.store = store
        let unreadableDrops = QuarantineService(
            errorsDirectory: dropDirectory.appendingPathComponent("errors"), database: database)
        self.hookSource = ClaudeHookDropSource(dropDirectory: dropDirectory) { moved, reason in
            unreadableDrops.recordInitialQuarantine(eventURL: moved, reason: reason, code: nil, parsed: nil)
        }
        self.transcriptSource = ClaudeTranscriptSource(projectsDirectory: projectsDirectory)
        self.drainer = try PipelineDrainer(
            spool: spool, archive: archive, normalizer: ClaudeNormalizer(), store: store,
            sinks: [ClaudeMainDBSink(database: database, eventReads: store)],
            faultInjector: drainerFaultInjector)
    }

    // MARK: - Sources

    /// Spools every ready drop file, waking the drainer when any was appended. A
    /// drop file still younger than the source's `minimumAge` is looked at once
    /// more, on its own, after that age: the directory watcher already fired for it
    /// and may not fire again.
    @discardableResult
    public func pollHookDrops() throws -> Int {
        try pollHookDrops(rewakeDeferred: true)
    }

    @discardableResult
    private func pollHookDrops(rewakeDeferred: Bool) throws -> Int {
        let result = try hookLock.run { try hookSource.pollCountingDeferred(into: spool) }
        if result.appended > 0 { drainer.wake() }
        if rewakeDeferred, result.deferred > 0, rewake.claim() {
            let handles = self
            let delay = hookSource.minimumAge + Self.rewakeMargin
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                handles.rewake.release()
                do {
                    // One look only: a file that is still young now (an mtime in the
                    // future) waits for the next watcher trigger or restart.
                    try handles.pollHookDrops(rewakeDeferred: false)
                } catch {
                    Self.logger.error(
                        "Deferred drop-file poll failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        return result.appended
    }

    /// One transcript sweep, waking the drainer when it appended anything.
    @discardableResult
    public func pollTranscripts() throws -> Int {
        let appended = try transcriptLock.run { try transcriptSource.poll(into: spool) }
        if appended > 0 { drainer.wake() }
        return appended
    }

    /// Reads one transcript from its cursor (the tailer's wake), waking the drainer
    /// when it appended anything.
    @discardableResult
    public func pollTranscript(file: URL) throws -> Int {
        let appended = try transcriptLock.run { try transcriptSource.poll(file: file, into: spool) }
        if appended > 0 { drainer.wake() }
        return appended
    }

    /// Spools a hook event delivered over HTTP or the socket and wakes the drainer.
    public func capture(_ event: ParsedEvent, now: Date = Date()) throws {
        try spool.append([ClaudeCapture.record(for: event, now: now)])
        drainer.wake()
    }

    /// `steno import`: reads every transcript under the request's directory (the
    /// daemon's projects directory when it names none) from its cursor into the
    /// spool and wakes the drainer, which writes the archive and the event store.
    /// `since` limits it to files modified at or after that instant. A dry run
    /// only counts the files it would read.
    ///
    /// `linesSeen` and `linesInserted` are both the lines spooled: the drainer
    /// writes them after this returns, and a line already read through its cursor
    /// is never spooled twice. A file that fails is named in `errors` and the rest
    /// are still read.
    public func importTranscripts(_ request: ImportRequestDTO) -> ImportSummary {
        let root = request.sourceDirectory.map {
            URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath)
        } ?? transcriptSource.projectsDirectory
        let files = JSONLScanner.discoverFilesWithModificationDates(under: root)
            .filter { entry in request.since.map { entry.modified >= $0 } ?? true }
            .sorted { ($0.modified, $0.url.path) < ($1.modified, $1.url.path) }
        if request.dryRun ?? false { return ImportSummary(filesScanned: files.count) }
        var lines = 0
        var errors: [String] = []
        for entry in files {
            do {
                lines += try pollTranscript(file: entry.url)
            } catch {
                errors.append("\(entry.url.path): \(error.localizedDescription)")
            }
        }
        return ImportSummary(filesScanned: files.count, linesSeen: lines, linesInserted: lines, errors: errors)
    }

    /// Archives a quarantined drop file's bytes verbatim, straight into the raw
    /// archive (never the spool), as an archive-only record
    /// (`ClaudeProvider.quarantineKind`) keyed `quarantine-<file name>` and stamped
    /// with the file's modification time. Nothing normalizes or applies it, so
    /// preserving a file adds no event and touches no session; the archive simply
    /// holds the bytes. It returns only once the archive has committed them.
    ///
    /// The key comes from the file alone, so preserving the same file twice (a
    /// crash before its delete, a retry and then a clear) collapses into one row.
    /// Should that key already hold other bytes (a file name reused), the record
    /// goes under the key with its sha256 appended instead; if even that is taken
    /// by other bytes it throws, and the caller keeps the file. An empty file has
    /// nothing to keep and appends nothing.
    public func preserveQuarantinedFile(_ file: URL) throws {
        // A file whose bytes cannot be read (an unreadable drop file) has nothing
        // to preserve, and holding it would keep it in quarantine forever.
        guard let data = try? Data(contentsOf: file), !data.isEmpty else { return }
        let modified = (try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate]) as? Date
        func record(_ key: String) -> RawRecord {
            RawRecord(
                provider: ClaudeProvider.name, sourceKind: ClaudeProvider.quarantineKind,
                dedupKey: key, receivedAt: modified ?? Date(), payload: data)
        }
        let first = try archive.append([record(Self.quarantineDedupKey(file))])
        guard case .conflict(_, _, let sha256)? = first.outcomes.first else { return }
        let fallback = try archive.append([record("\(Self.quarantineDedupKey(file))-\(sha256)")])
        if case .conflict? = fallback.outcomes.first {
            throw QuarantinePreserveConflict(file: file.lastPathComponent)
        }
    }

    /// The dedup key a quarantined file is preserved under.
    public static func quarantineDedupKey(_ file: URL) -> String {
        "quarantine-\(file.lastPathComponent)"
    }

    // MARK: - Legacy spool

    /// The dedup key a legacy spool row is adopted under. Derived from the row
    /// alone, so adopting the same row twice gives the same key.
    public static func legacyDedupKey(_ event: SpooledEvent) -> String {
        "cap-legacy-\(event.id)-\(Int64((event.receivedAt.timeIntervalSince1970 * 1000).rounded()))"
    }

    /// Moves every pending row of the legacy capture spool into this spool, a batch
    /// at a time: append here first, then delete there. A crash in between leaves
    /// the rows in both; the next adoption appends them again under the same keys
    /// and the archive collapses the duplicates. Returns how many rows moved.
    /// `afterAppend` is for tests: it fires between the two writes.
    @discardableResult
    public func adoptLegacySpool(
        _ legacy: IngestSpool, afterAppend: (() throws -> Void)? = nil
    ) throws -> Int {
        var moved = 0
        while true {
            let batch = try legacy.pendingBatch(limit: Self.legacyBatchSize)
            guard !batch.isEmpty else { break }
            let records = batch.map { event in
                RawRecord(
                    provider: ClaudeProvider.name, sourceKind: ClaudeProvider.legacyHookKind,
                    dedupKey: Self.legacyDedupKey(event), receivedAt: event.receivedAt, payload: event.envelope)
            }
            try spool.append(records)
            try afterAppend?()
            try legacy.complete(ids: batch.map(\.id))
            moved += batch.count
        }
        if moved > 0 { drainer.wake() }
        return moved
    }

    // MARK: - Quarantine

    /// Sends back through the pipeline the quarantined records whose failure was a
    /// destination outage (a sink or the events.db write), which are already in the
    /// archive; records refused for themselves (invalid JSON, an archive conflict)
    /// stay. Returns how many were requeued.
    @discardableResult
    public func requeueTransientQuarantine() throws -> Int {
        let requeued = try spool.requeueQuarantined(reasonPrefixes: PipelineDrainer.transientFailurePrefixes)
        if requeued > 0 { drainer.wake() }
        return requeued
    }
}

extension ClaudePipelineHandles: PipelineQuarantineControl {
    /// Records the spool has quarantined; 0 when the spool cannot be read.
    public func quarantinedCount() -> Int {
        (try? spool.quarantinedCount()) ?? 0
    }

    @discardableResult
    public func requeueAllQuarantined() -> Int {
        do {
            let requeued = try spool.requeueQuarantined(reasonPrefixes: nil)
            if requeued > 0 { drainer.wake() }
            return requeued
        } catch {
            Self.logger.error("Quarantine requeue failed: \(error.localizedDescription, privacy: .public)")
            return 0
        }
    }

    /// A record quarantined by a destination outage (a sink, or the events.db
    /// write) is never deleted here, even though its bytes are archived: its
    /// `events` row and session state exist nowhere until it is applied. It is
    /// requeued instead, so the clear empties the list and the drainer applies it
    /// (or parks it again if the outage persists).
    @discardableResult
    public func clearArchivedQuarantine() -> Int {
        var cleared = 0
        var afterID: Int64 = 0
        do {
            while true {
                let page = try spool.quarantined(limit: 200, afterID: afterID)
                guard let last = page.last else { break }
                afterID = last.id
                let archived = try page
                    .filter { !Self.isTransientFailure($0.reason) }
                    .filter(isArchivedVerbatim).map(\.id)
                try spool.deleteQuarantined(ids: archived)
                cleared += archived.count
            }
            try requeueTransientQuarantine()
        } catch {
            Self.logger.error("Quarantine clear stopped: \(error.localizedDescription, privacy: .public)")
        }
        return cleared
    }

    /// Whether a quarantine reason marks a destination outage rather than a record
    /// refused for itself.
    static func isTransientFailure(_ reason: String) -> Bool {
        PipelineDrainer.transientFailurePrefixes.contains { reason.hasPrefix($0) }
    }

    /// Whether the archive holds this record's key with exactly these bytes. An
    /// unreadable archive row counts as not held.
    private func isArchivedVerbatim(_ quarantined: QuarantinedRecord) throws -> Bool {
        guard let id = try archive.id(forDedupKey: quarantined.record.dedupKey) else { return false }
        guard let archived = try? archive.record(id: id) else { return false }
        return archived.record.payload == quarantined.record.payload
    }
}

extension ClaudePipelineHandles: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// A quarantined file whose key, and its sha256 fallback key, both already hold
/// other bytes in the raw archive: the file could not be preserved and is kept.
public struct QuarantinePreserveConflict: Error, LocalizedError, Sendable {
    public let file: String
    public var errorDescription: String? {
        "the raw archive already holds different bytes under \(file)'s keys"
    }
}

/// Serializes one kind of poll.
private final class PollLock: @unchecked Sendable {
    private let lock = NSLock()

    func run<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// At most one deferred drop-file poll scheduled at a time.
private final class RewakeGate: @unchecked Sendable {
    private let lock = NSLock()
    private var scheduled = false

    func claim() -> Bool {
        lock.withLock {
            guard !scheduled else { return false }
            scheduled = true
            return true
        }
    }

    func release() {
        lock.withLock { scheduled = false }
    }
}

public extension SessionDaemonConfiguration {
    /// The Claude spool, beside the database.
    var claudeSpoolPath: String {
        supportDirectory.appendingPathComponent(ProviderSpool.fileName(provider: ClaudeProvider.name)).path
    }

    /// The Claude raw archive, beside the database.
    var claudeArchivePath: String {
        supportDirectory.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path
    }

    /// The event store, beside the database.
    var eventStorePath: String {
        supportDirectory.appendingPathComponent(EventStore.fileName).path
    }
}
#endif
