#if canImport(AgenticToolkitCore)
import Foundation

/// The Claude pipeline's three files in one directory, opened (or created) with
/// the pragmas the daemon uses: `claude-ingest.db`, `claude-raw.db` and
/// `events.db`, which gets `auto_vacuum = INCREMENTAL` when it is new.
public struct ClaudePipelineFiles: Sendable {
    public let spool: ProviderSpool
    public let archive: RawArchive
    public let store: EventStore

    /// Opens or creates the three files in `directory`, creating the directory
    /// when it is missing.
    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        spool = try ProviderSpool(
            path: directory.appendingPathComponent(ProviderSpool.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        archive = try RawArchive(
            path: directory.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        store = try EventStore(path: directory.appendingPathComponent(EventStore.fileName).path)
    }
}

/// What one ``ClaudeArchiveReplay/run(files:chunk:clock:progress:)`` did.
///
/// The counts cover this run only: a resumed replay starts after
/// `replay_last_raw_id` and counts from there.
public struct ClaudeArchiveReplayResult: Sendable, Equatable {
    /// Records read from the archive this run.
    public var records = 0
    /// Records that normalized into at least one row.
    public var replayed = 0
    /// Records that normalized, without error, into nothing (see `ReplayReport.skipped`).
    public var skipped = 0
    /// The first `Replayer.maxReportedFailures` skipped archive ids.
    public var skippedIDs: [Int64] = []
    /// Records that failed to normalize or could not be decoded.
    public var failed = 0
    /// The first `Replayer.maxReportedFailures` failures, by ascending archive id.
    public var failures: [Failure] = []
    /// The highest archive id replayed; what `replay_last_raw_id` now holds.
    public var lastRawID: Int64 = 0
    public var seconds: Double = 0

    public struct Failure: Sendable, Equatable {
        public let rawID: Int64
        public let error: String
    }

    public init() {}

    init(report: ReplayReport, seconds: Double) {
        records = report.records
        skipped = report.skipped
        skippedIDs = report.skippedIDs
        replayed = report.normalized - report.skipped
        failed = report.failed
        failures = report.failures.sorted { $0.key < $1.key }.map { Failure(rawID: $0.key, error: $0.value) }
        lastRawID = report.lastID
        self.seconds = seconds
    }

    /// The report as one line of sorted-key JSON:
    /// `{"failed", "failures": [{"error", "raw_id"}], "last_raw_id", "records",
    /// "replayed", "seconds", "skipped", "skipped_ids"}`.
    public func jsonData() throws -> Data {
        let object: [String: Any] = [
            "records": records,
            "replayed": replayed,
            "skipped": skipped,
            "skipped_ids": skippedIDs,
            "failed": failed,
            "failures": failures.map { ["raw_id": $0.rawID, "error": $0.error] as [String: Any] },
            "last_raw_id": lastRawID,
            "seconds": seconds
        ]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
    }
}

/// Rebuilds `events.db` from `claude-raw.db` outside a running daemon (`stenographerd
/// --replay`), resumable: the highest archive id replayed is kept in the event
/// store's `store_meta` under ``lastRawIDKey`` after every chunk, and the next run
/// starts after it.
///
/// The caller must hold the daemon's single-instance lock: the replay drops the
/// store's indexes for its whole run (`Replayer`), which a live drainer must never see.
public enum ClaudeArchiveReplay {
    /// The `store_meta` key holding the highest archive id replayed so far.
    public static let lastRawIDKey = "replay_last_raw_id"
    public static let defaultChunk = 5_000

    /// The id the next replay starts after: `replay_last_raw_id`, or 0.
    public static func lastRawID(in store: EventStore) throws -> Int64 {
        try store.metaValue(forKey: lastRawIDKey).flatMap { Int64($0) } ?? 0
    }

    /// Replays every archive record after ``lastRawID(in:)``. `progress` gets the
    /// running report after each chunk, once its `replay_last_raw_id` is stored. A
    /// record that fails is reported and skipped; a store or archive error throws,
    /// leaving `replay_last_raw_id` at the last chunk that committed.
    public static func run(
        files: ClaudePipelineFiles, chunk: Int = defaultChunk,
        clock: @escaping @Sendable () -> Date = Date.init,
        progress: (@Sendable (ReplayReport) -> Void)? = nil
    ) throws -> ClaudeArchiveReplayResult {
        let started = clock()
        let after = try lastRawID(in: files.store)
        let store = files.store
        let metaError = MetaErrorBox()
        let report = try Replayer.replay(
            archive: files.archive, normalizer: ClaudeNormalizer(), into: store, after: after, chunk: chunk,
            progress: { report in
                do {
                    try store.setMetaValue(String(report.lastID), forKey: lastRawIDKey)
                } catch {
                    metaError.record(error)
                }
                progress?(report)
            })
        if let error = metaError.first { throw error }
        // An empty run still records where it stands.
        try store.setMetaValue(String(report.lastID), forKey: lastRawIDKey)
        return ClaudeArchiveReplayResult(report: report, seconds: clock().timeIntervalSince(started))
    }
}

/// The first error a progress callback could not throw.
private final class MetaErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var error: Error?

    func record(_ error: Error) {
        lock.withLock { if self.error == nil { self.error = error } }
    }

    var first: Error? { lock.withLock { error } }
}
#endif
