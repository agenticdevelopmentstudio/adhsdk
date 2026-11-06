import Foundation

public struct ReplayReport: Sendable, Equatable {
    /// The archive's provider.
    public var provider = ""
    public var records = 0
    public var normalized = 0
    public var failed = 0
    /// Records that normalized without error into nothing: a hook envelope with no
    /// session id, an archive-only kind, a conflict copy, a transcript line that
    /// carries no turn, message, event or session. Counted in `normalized` too.
    public var skipped = 0
    /// The first `Replayer.maxReportedFailures` skipped archive ids, in replay order.
    public var skippedIDs: [Int64] = []
    /// Archive id to error description. Only the first `Replayer.maxReportedFailures` are kept.
    public var failures: [Int64: String] = [:]
    /// The highest archive id this replay has written (or skipped as failed). Pass it
    /// back as `after:` to resume an interrupted replay; the starting `after` when
    /// nothing was read.
    public var lastID: Int64 = 0
    /// True when `shouldContinue` stopped the replay before the archive's end.
    /// Every chunk up to `lastID` was written; the rest was not read.
    public var stopped = false

    public init() {}
}

/// What a checkpointed replay commits in each chunk's own transaction: the highest
/// archive id written, under `metaKey` in `store_meta`, and the records the chunk
/// failed, in `replay_failures`. See `EventStore.write(_:provider:deadline:checkpoint:)`.
public struct ReplayCheckpoint: Sendable, Equatable {
    public let metaKey: String
    public var lastID: Int64
    /// Archive id to error description: every failure of the chunk, uncapped.
    public var failures: [Int64: String]

    public init(metaKey: String, lastID: Int64, failures: [Int64: String] = [:]) {
        self.metaKey = metaKey
        self.lastID = lastID
        self.failures = failures
    }
}

/// One archive to replay, with its normalizer and the id to resume after.
public struct ReplaySource: Sendable {
    public let archive: RawArchive
    public let normalizer: any Normalizer
    public let after: Int64
    /// When set, every chunk commits a `ReplayCheckpoint` under this `store_meta`
    /// key in the same transaction as its rows.
    public let checkpointKey: String?
    /// When set, the replay ends after this id: records the archive gained
    /// later (a live drain writes them itself) are never read.
    public let through: Int64?

    public init(archive: RawArchive, normalizer: any Normalizer, after: Int64 = 0, checkpointKey: String? = nil,
                through: Int64? = nil) {
        self.archive = archive
        self.normalizer = normalizer
        self.after = after
        self.checkpointKey = checkpointKey
        self.through = through
    }
}

/// Rebuilds an `EventStore` from the raw archive, which is what makes the
/// archive a working backup. Read-only against the archive.
///
/// "Rebuild events.db" is: delete it, then replay every provider's archive in one
/// call (`replay(sources:into:)`), so the indexes are dropped and rebuilt once.
/// The store refuses the bulk load while a live drainer is attached to it.
/// Chunk writes and the index rebuild run under `EventStore.bulkDeadline`.
/// A crash mid-replay leaves the store's `bulk_load` flag set; the next
/// `EventStore` open rebuilds the indexes, and replaying again with
/// `after: report.lastID` (from the last progress callback) resumes; every write
/// is idempotent, so overlapping a chunk is harmless. A source with a
/// `checkpointKey` commits its cursor and failures in each chunk's transaction, so
/// it never overlaps one. A host that can be interrupted should pass
/// `shouldContinue` so the replay ends its bulk load itself instead.
///
/// Cost of that recovery: the open that finds the flag rebuilds **every** index
/// before returning, which on a large migrated store can take hours, and the
/// resumed replay then drops them again at once in its own `beginBulkLoad`. A host
/// that is about to resume should expect that open to be slow (it runs under
/// `EventStore.bulkDeadline`), and should not treat it as hung.
public enum Replayer {
    public static let maxReportedFailures = 1000

    /// Reads `archive` in id order after `after`, in chunks of at most `chunk`
    /// records and `maxBytes` of payload (always at least one record); normalizes;
    /// writes in bulk mode. Never modifies the archive. A record that fails to
    /// normalize, or that the archive cannot decode (corrupt payload), is reported by
    /// archive id and skipped, never fatal. A store error or an unexpected archive
    /// error throws; secondary indexes are rebuilt either way. `progress` gets the
    /// running report after every chunk.
    ///
    /// `shouldContinue` is asked before every chunk; when it answers false the
    /// replay stops there (`ReplayReport.stopped`), ends the bulk load and returns
    /// normally, so an interrupted host never leaves the store without indexes.
    /// `checkpointKey`: see `ReplaySource.checkpointKey`.
    public static func replay(archive: RawArchive, normalizer: any Normalizer, into store: EventStore,
                              after: Int64 = 0, chunk: Int = 5_000,
                              maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                              checkpointKey: String? = nil,
                              shouldContinue: (@Sendable () -> Bool)? = nil,
                              progress: (@Sendable (ReplayReport) -> Void)? = nil) throws -> ReplayReport {
        let reports = try replay(
            sources: [ReplaySource(archive: archive, normalizer: normalizer, after: after,
                                   checkpointKey: checkpointKey)],
            into: store, chunk: chunk, maxBytes: maxBytes, shouldContinue: shouldContinue, progress: progress)
        return reports[0]
    }

    /// Replays several archives, one per provider, inside a single bulk-load
    /// window. Returns one report per source, in order; once `shouldContinue`
    /// stops it, the sources not reached report `stopped` with nothing read. Throws
    /// `PipelineError.duplicateProvider` or `.normalizerMismatch` before touching
    /// the store.
    public static func replay(sources: [ReplaySource], into store: EventStore, chunk: Int = 5_000,
                              maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                              shouldContinue: (@Sendable () -> Bool)? = nil,
                              progress: (@Sendable (ReplayReport) -> Void)? = nil) throws -> [ReplayReport] {
        var seen = Set<String>()
        for source in sources {
            try checkNormalizer(source)
            guard seen.insert(source.archive.provider).inserted else {
                throw PipelineError.duplicateProvider(source.archive.provider)
            }
        }
        let size = max(1, chunk)
        var reports: [ReplayReport] = []
        try store.beginBulkLoad()
        var replayError: Error?
        do {
            var stopped = false
            for source in sources {
                var report = ReplayReport()
                report.provider = source.archive.provider
                report.lastID = source.after
                report.stopped = stopped
                defer { reports.append(report) }
                if stopped { continue }
                try replay(source, into: store, size: size, maxBytes: maxBytes, deadline: EventStore.bulkDeadline,
                           report: &report, shouldContinue: shouldContinue, progress: progress)
                stopped = report.stopped
            }
        } catch {
            replayError = error
        }
        // Rebuild indexes even when the replay threw; the replay error wins.
        do { try store.endBulkLoad() } catch { if replayError == nil { replayError = error } }
        if let replayError { throw replayError }
        return reports
    }

    /// The default chunk of a live replay: small, so each write transaction is
    /// short next to a live drainer's.
    public static let liveChunk = 1_000
    /// What each read and write of a live replay may wait: far above a small
    /// chunk's cost, far below the bulk budget, so a stuck store surfaces.
    public static let liveDeadline: Duration = .seconds(120)

    /// Replays one source into a store that stays live: no bulk load, so the
    /// indexes stay and a drainer may write beside it (the store's writes are
    /// idempotent and order-independent, so the two never disagree). The replay
    /// registers as a live writer, so no bulk load can start under it. Stops at
    /// `source.through` when set, and before any chunk `shouldContinue` refuses
    /// (`ReplayReport.stopped`). Failures and the checkpoint behave as in
    /// `replay(sources:into:)`.
    public static func replayLive(_ source: ReplaySource, into store: EventStore, chunk: Int = liveChunk,
                                  maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                                  deadline: Duration = liveDeadline,
                                  shouldContinue: (@Sendable () -> Bool)? = nil,
                                  progress: (@Sendable (ReplayReport) -> Void)? = nil) throws -> ReplayReport {
        try checkNormalizer(source)
        try store.attachLiveWriter()
        defer { store.detachLiveWriter() }
        var report = ReplayReport()
        report.provider = source.archive.provider
        report.lastID = source.after
        try replay(source, into: store, size: max(1, chunk), maxBytes: maxBytes, deadline: deadline,
                   report: &report, shouldContinue: shouldContinue, progress: progress)
        return report
    }

    private static func checkNormalizer(_ source: ReplaySource) throws {
        guard source.archive.provider == source.normalizer.provider else {
            throw PipelineError.normalizerMismatch(
                archive: source.archive.provider, normalizer: source.normalizer.provider)
        }
    }

    private static func replay(_ source: ReplaySource, into store: EventStore, size: Int, maxBytes: Int,
                               deadline: Duration, report: inout ReplayReport,
                               shouldContinue: (@Sendable () -> Bool)?,
                               progress: (@Sendable (ReplayReport) -> Void)?) throws {
        var cursor = source.after
        if let through = source.through, cursor >= through { return }
        while true {
            if let shouldContinue, !shouldContinue() {
                report.stopped = true
                break
            }
            // A bulk replay's reads get the bulk budget too: the archive's 30 s
            // read deadline stopped a dev replay of a 78 GB archive after 474,124
            // records.
            var ids = try source.archive.ids(after: cursor, limit: size, maxBytes: maxBytes, deadline: deadline)
            var reachedEnd = false
            if let through = source.through, let over = ids.firstIndex(where: { $0 > through }) {
                ids = Array(ids[..<over])
                reachedEnd = true
            }
            guard let last = ids.last else { break }
            var chunkFailures: [Int64: String] = [:]
            let page = try readChunk(archive: source.archive, ids: ids, deadline: deadline, report: &report,
                                     chunkFailures: &chunkFailures)
            var combined = NormalizedBatch()
            for archived in page {
                report.records += 1
                // A conflict copy is kept bytes only; the live drain derives
                // nothing from it either.
                if archived.record.isConflictCopy {
                    report.normalized += 1
                    skip(&report, id: archived.id)
                    continue
                }
                do {
                    let batch = try source.normalizer.normalize(archived)
                    report.normalized += 1
                    if batch.isEmpty {
                        skip(&report, id: archived.id)
                    } else {
                        combined.append(batch)
                    }
                } catch {
                    fail(&report, &chunkFailures, id: archived.id, error)
                }
            }
            let checkpoint = source.checkpointKey.map {
                ReplayCheckpoint(metaKey: $0, lastID: last, failures: chunkFailures)
            }
            try store.write(combined, provider: source.archive.provider, deadline: deadline, checkpoint: checkpoint)
            cursor = last
            report.lastID = last
            progress?(report)
            if reachedEnd || source.through == last { break }
        }
    }

    private static func skip(_ report: inout ReplayReport, id: Int64) {
        report.skipped += 1
        if report.skippedIDs.count < maxReportedFailures { report.skippedIDs.append(id) }
    }

    private static func fail(_ report: inout ReplayReport, _ chunkFailures: inout [Int64: String],
                             id: Int64, _ error: Error) {
        let description = String(describing: error)
        report.failed += 1
        chunkFailures[id] = description
        if report.failures.count < maxReportedFailures { report.failures[id] = description }
    }

    /// The records with `ids`. When the chunk read throws `corruptPayload`, falls back
    /// to one read per id so only the bad rows are lost. Other errors propagate.
    private static func readChunk(archive: RawArchive, ids: [Int64], deadline: Duration,
                                  report: inout ReplayReport,
                                  chunkFailures: inout [Int64: String]) throws -> [ArchivedRecord] {
        do {
            return try archive.records(ids: ids, deadline: deadline)
        } catch RawArchiveError.corruptPayload {
            var page: [ArchivedRecord] = []
            for id in ids {
                do {
                    if let archived = try archive.record(id: id, deadline: deadline) {
                        page.append(archived)
                    }
                } catch RawArchiveError.corruptPayload {
                    report.records += 1
                    fail(&report, &chunkFailures, id: id, RawArchiveError.corruptPayload(id: id))
                }
            }
            return page
        }
    }
}
