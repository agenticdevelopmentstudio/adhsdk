#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// The running Claude provider pipeline: its spool, archive, event store, drainer
/// and the two sources that feed it. The runtime builds one when it opens and the
/// daemon's tasks drive the sources through it.
///
/// Every input path ends the same way: append to the spool, then wake the drainer
/// (`IngestSource`'s waking contract). Transcript polls are serialized, so the
/// periodic sweep and the tailer's per-file wake never read one file's cursor at
/// the same time.
public struct ClaudePipelineHandles: Sendable {
    public let spool: ProviderSpool
    public let archive: RawArchive
    public let store: EventStore
    public let drainer: PipelineDrainer
    public let hookSource: ClaudeHookDropSource
    public let transcriptSource: ClaudeTranscriptSource

    private let transcriptLock = TranscriptPollLock()

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
        self.hookSource = ClaudeHookDropSource(dropDirectory: dropDirectory)
        self.transcriptSource = ClaudeTranscriptSource(projectsDirectory: projectsDirectory)
        self.drainer = try PipelineDrainer(
            spool: spool, archive: archive, normalizer: ClaudeNormalizer(), store: store,
            sinks: [ClaudeMainDBSink(database: database, eventReads: store)],
            faultInjector: drainerFaultInjector)
    }

    /// Spools every ready drop file, waking the drainer when any was appended.
    @discardableResult
    public func pollHookDrops() throws -> Int {
        let appended = try hookSource.poll(into: spool)
        if appended > 0 { drainer.wake() }
        return appended
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

    /// Records the spool has quarantined; 0 when the spool cannot be read.
    public func quarantinedCount() -> Int {
        (try? spool.quarantinedCount()) ?? 0
    }
}

/// Serializes transcript polls.
private final class TranscriptPollLock: @unchecked Sendable {
    private let lock = NSLock()

    func run<Value>(_ body: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try body()
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
