#if canImport(AgenticToolkitCore)
import Foundation

/// The Claude pipeline's three files in one directory, opened (or created) with
/// the pragmas the daemon uses: `claude-ingest.db`, `claude-raw.db` and
/// `events.db`, which gets `auto_vacuum = INCREMENTAL` when it is new.
///
/// Opening `events.db` finishes a bulk load an earlier replay left behind (killed,
/// crashed): its indexes are rebuilt before `init` returns, and
/// `store.recoveredBulkLoad` says so.
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

/// What one ``ClaudeArchiveReplay/run(files:chunk:clock:shouldContinue:progress:)`` did.
///
/// `records`, `replayed`, `skipped` and `failedThisRun` cover this run only. `failed`
/// and `failures` cover every run since the replay started from id 0: they are read
/// back from the store's `replay_failures`, so a run resumed after a crash, an
/// interrupt or a store error still reports what the earlier runs failed.
public struct ClaudeArchiveReplayResult: Sendable, Equatable {
    /// Records read from the archive this run.
    public var records = 0
    /// Records that normalized into at least one row, this run.
    public var replayed = 0
    /// Records that normalized, without error, into nothing (see `ReplayReport.skipped`), this run.
    public var skipped = 0
    /// The first `Replayer.maxReportedFailures` skipped archive ids, this run.
    public var skippedIDs: [Int64] = []
    /// Records that failed to normalize or could not be decoded, over every run.
    public var failed = 0
    /// Of `failed`, the ones this run found.
    public var failedThisRun = 0
    /// The first `Replayer.maxReportedFailures` failures over every run, by ascending archive id.
    public var failures: [Failure] = []
    /// The highest archive id committed; what `replay_last_raw_id` holds.
    public var lastRawID: Int64 = 0
    /// True when the run stopped before the archive's end (`shouldContinue`, or an error).
    public var interrupted = false
    /// True when opening `events.db` found an earlier run's bulk load and rebuilt its indexes.
    public var recoveredBulkLoad = false
    public var seconds: Double = 0

    public struct Failure: Sendable, Equatable {
        public let rawID: Int64
        public let error: String

        public init(rawID: Int64, error: String) {
            self.rawID = rawID
            self.error = error
        }
    }

    public init() {}

    /// The report as one line of sorted-key JSON:
    /// `{"failed", "failed_this_run", "failures": [{"error", "raw_id"}], "interrupted",
    /// "last_raw_id", "records", "recovered_bulk_load", "replayed", "seconds",
    /// "skipped", "skipped_ids"}`.
    public func jsonData() throws -> Data {
        let object: [String: Any] = [
            "records": records,
            "replayed": replayed,
            "skipped": skipped,
            "skipped_ids": skippedIDs,
            "failed": failed,
            "failed_this_run": failedThisRun,
            "failures": failures.map { ["raw_id": $0.rawID, "error": $0.error] as [String: Any] },
            "last_raw_id": lastRawID,
            "interrupted": interrupted,
            "recovered_bulk_load": recoveredBulkLoad,
            "seconds": seconds
        ]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
    }
}

/// A replay that stopped on a store or archive error. `partial` is what was
/// committed before it (the cursor and every failure come from the store).
public struct ClaudeArchiveReplayStopped: Error, Sendable {
    public let partial: ClaudeArchiveReplayResult
    public let cause: String
}

/// Rebuilds `events.db` from `claude-raw.db` outside a running daemon (`stenographerd
/// --replay`), resumable. Each chunk commits, in the same transaction as its rows,
/// the highest archive id it covered (`store_meta` key ``lastRawIDKey``) and the
/// records it failed (`replay_failures`); the next run starts after that id.
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

    /// Replays every archive record after ``lastRawID(in:)``. A replay starting from
    /// id 0 first forgets the failures of any earlier start.
    ///
    /// - `shouldContinue` is asked before each chunk; false stops the run there,
    ///   with the indexes rebuilt, and the result says `interrupted`.
    /// - `progress` gets the running report after each committed chunk.
    /// - A record that fails is recorded and skipped. A store or archive error
    ///   throws ``ClaudeArchiveReplayStopped`` with what was committed before it.
    public static func run(
        files: ClaudePipelineFiles, chunk: Int = defaultChunk,
        clock: @escaping @Sendable () -> Date = Date.init,
        shouldContinue: (@Sendable () -> Bool)? = nil,
        progress: (@Sendable (ReplayReport) -> Void)? = nil
    ) throws -> ClaudeArchiveReplayResult {
        let started = clock()
        let store = files.store
        let provider = ClaudeProvider.name
        let latest = LatestReport()
        let after: Int64
        do {
            after = try lastRawID(in: store)
            if after == 0 { try store.clearReplayFailures(provider: provider) }
        } catch {
            throw ClaudeArchiveReplayStopped(partial: ClaudeArchiveReplayResult(), cause: String(describing: error))
        }
        do {
            let report = try Replayer.replay(
                archive: files.archive, normalizer: ClaudeNormalizer(), into: store, after: after, chunk: chunk,
                checkpointKey: lastRawIDKey, shouldContinue: shouldContinue,
                progress: { report in
                    latest.set(report)
                    progress?(report)
                })
            // A run that read nothing still records where it stands.
            try store.commit(ReplayCheckpoint(metaKey: lastRawIDKey, lastID: report.lastID), provider: provider)
            return try result(report, store: store, seconds: clock().timeIntervalSince(started))
        } catch {
            var report = latest.value ?? ReplayReport()
            if latest.value == nil { report.lastID = after }
            report.stopped = true
            var partial = (try? result(report, store: store, seconds: clock().timeIntervalSince(started)))
                ?? fallback(report, store: store)
            partial.interrupted = true
            throw ClaudeArchiveReplayStopped(partial: partial, cause: String(describing: error))
        }
    }

    private static func result(_ report: ReplayReport, store: EventStore,
                               seconds: Double) throws -> ClaudeArchiveReplayResult {
        var result = fallback(report, store: store)
        result.lastRawID = try lastRawID(in: store)
        result.failed = try store.replayFailureCount(provider: ClaudeProvider.name)
        result.failures = try store.replayFailures(provider: ClaudeProvider.name, limit: Replayer.maxReportedFailures)
            .map { ClaudeArchiveReplayResult.Failure(rawID: $0.rawID, error: $0.error) }
        result.seconds = seconds
        return result
    }

    /// The run's own counts, for when the store cannot be read back.
    private static func fallback(_ report: ReplayReport, store: EventStore) -> ClaudeArchiveReplayResult {
        var result = ClaudeArchiveReplayResult()
        result.records = report.records
        result.skipped = report.skipped
        result.skippedIDs = report.skippedIDs
        result.replayed = report.normalized - report.skipped
        result.failedThisRun = report.failed
        result.failed = report.failed
        result.failures = report.failures.sorted { $0.key < $1.key }
            .map { ClaudeArchiveReplayResult.Failure(rawID: $0.key, error: $0.value) }
        result.lastRawID = report.lastID
        result.interrupted = report.stopped
        result.recoveredBulkLoad = store.recoveredBulkLoad
        return result
    }
}

/// The last report a progress callback saw.
private final class LatestReport: @unchecked Sendable {
    private let lock = NSLock()
    private var report: ReplayReport?

    func set(_ report: ReplayReport) { lock.withLock { self.report = report } }
    var value: ReplayReport? { lock.withLock { report } }
}
#endif
