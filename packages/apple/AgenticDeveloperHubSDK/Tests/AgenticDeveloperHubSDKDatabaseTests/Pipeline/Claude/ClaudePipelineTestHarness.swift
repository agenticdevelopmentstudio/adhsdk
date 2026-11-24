import AgenticDeveloperHubSDKCore
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

/// The Claude pipeline as the runtime assembles it, on temp files: a session
/// database with the event store and raw archive attached for its readers, and
/// the real sources, drainer and main-db sink feeding them. Tests put hook
/// events and transcript lines in through the sources and read the results
/// back through the session database's readers.
///
/// Every file lives under `directory`; the session database too, unless the
/// caller hands one in. The caller removes the directory.
final class ClaudePipelineTestHarness {

    /// Raised by `drain()` when a pass stops early.
    struct DrainFailure: Error, CustomStringConvertible {
        let reason: String
        var description: String { "drain failed: \(reason)" }
    }

    let directory: URL
    let database: DaemonDatabase
    let spool: ProviderSpool
    let archive: RawArchive
    let store: EventStore
    let handles: ClaudePipelineHandles

    /// The totals of every `drain()` so far.
    private(set) var drained = DrainOutcome()

    var dropDirectory: URL { directory.appendingPathComponent("drop") }
    var projectsDirectory: URL { directory.appendingPathComponent("projects") }

    /// A harness over a fresh session database at `directory/session.db`.
    convenience init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let resolver = AccountResolver(claudeJSONPath: directory.appendingPathComponent("no-claude.json").path)
        let database = try DaemonDatabase(
            path: directory.appendingPathComponent("session.db").path,
            accountResolver: resolver,
            migrations: SessionSchema.migrations,
            postMigration: SessionSchema.postMigration)
        try self.init(directory: directory, database: database)
    }

    /// A harness feeding `database`, which it attaches the store and archive to.
    /// The pipeline's own files go under `directory`.
    init(directory: URL, database: DaemonDatabase,
         drainerFaultInjector: (@Sendable (DrainStep) throws -> Void)? = nil) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.directory = directory
        self.database = database
        spool = try ProviderSpool(
            path: directory.appendingPathComponent(ProviderSpool.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        archive = try RawArchive(
            path: directory.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        store = try EventStore(path: directory.appendingPathComponent(EventStore.fileName).path)
        database.attachEventReads(store, archive: archive)
        handles = try ClaudePipelineHandles(
            spool: spool, archive: archive, store: store, database: database,
            dropDirectory: directory.appendingPathComponent("drop"),
            projectsDirectory: directory.appendingPathComponent("projects"),
            drainerFaultInjector: drainerFaultInjector)
    }

    // MARK: - Input

    /// Captures one hook event as the HTTP and socket routes do, then drains.
    func ingest(_ event: ParsedEvent) throws {
        try handles.capture(event)
        try drain()
    }

    /// Captures each hook event in order, then drains once.
    func ingest(_ events: [ParsedEvent]) throws {
        for event in events {
            try handles.capture(event)
        }
        try drain()
    }

    /// Appends `lines` to the transcript `file` (creating it and its folder),
    /// reads it from its cursor as the tailer's wake does, then drains.
    func ingestTranscript(lines: [String], file: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let text = lines.map { $0 + "\n" }.joined()
        if fileManager.fileExists(atPath: file.path) {
            let handle = try FileHandle(forWritingTo: file)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(text.utf8))
        } else {
            try Data(text.utf8).write(to: file)
        }
        try handles.pollTranscript(file: file)
        try drain()
    }

    /// The transcript file a session in `project` (a projects-folder name such as
    /// `-Users-dev-work-myapp`) writes, under this harness's projects directory.
    func transcriptFile(sessionId: String, project: String = "-Users-dev-work-myapp") -> URL {
        projectsDirectory.appendingPathComponent(project).appendingPathComponent("\(sessionId).jsonl")
    }

    /// Drains the spool until it is empty; throws when a pass stops early.
    func drain() throws {
        let outcome = handles.drainer.drainUntilEmpty()
        drained.read += outcome.read
        drained.archived += outcome.archived
        drained.stored += outcome.stored
        drained.quarantined += outcome.quarantined
        drained.completed += outcome.completed
        if outcome.failed {
            throw DrainFailure(reason: outcome.failureReason ?? "unknown")
        }
    }

    // MARK: - Building events

    /// A hook event as the hook helper delivers it. `timestamp` is ISO-8601;
    /// `hookData` gets `session_id` (and `cwd`, when given) filled in.
    static func event(
        _ eventType: String,
        sessionId: String,
        timestamp: String,
        cwd: String = "/Users/dev/work/myapp",
        hookData extra: [String: Any] = [:],
        accountEmail: String = ""
    ) -> ParsedEvent {
        var hookData = extra
        hookData["session_id"] = sessionId
        hookData["hook_event_name"] = hookData["hook_event_name"] ?? eventType
        if !cwd.isEmpty { hookData["cwd"] = cwd }
        return ParsedEvent(
            eventType: eventType, timestamp: timestamp, hookData: hookData,
            context: nil, accountEmail: accountEmail)
    }
}
