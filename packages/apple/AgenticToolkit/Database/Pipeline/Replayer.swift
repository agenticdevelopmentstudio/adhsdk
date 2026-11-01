import Foundation

public struct ReplayReport: Sendable, Equatable {
    /// The archive's provider.
    public var provider = ""
    public var records = 0
    public var normalized = 0
    public var failed = 0
    /// Archive id to error description. Only the first `Replayer.maxReportedFailures` are kept.
    public var failures: [Int64: String] = [:]
    /// The highest archive id this replay has written (or skipped as failed). Pass it
    /// back as `after:` to resume an interrupted replay; the starting `after` when
    /// nothing was read.
    public var lastID: Int64 = 0

    public init() {}
}

/// One archive to replay, with its normalizer and the id to resume after.
public struct ReplaySource: Sendable {
    public let archive: RawArchive
    public let normalizer: any Normalizer
    public let after: Int64

    public init(archive: RawArchive, normalizer: any Normalizer, after: Int64 = 0) {
        self.archive = archive
        self.normalizer = normalizer
        self.after = after
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
/// is idempotent, so overlapping a chunk is harmless.
public enum Replayer {
    public static let maxReportedFailures = 1000

    /// Reads `archive` in id order after `after`, in chunks of at most `chunk`
    /// records and `maxBytes` of payload (always at least one record); normalizes;
    /// writes in bulk mode. Never modifies the archive. A record that fails to
    /// normalize, or that the archive cannot decode (corrupt payload), is reported by
    /// archive id and skipped, never fatal. A store error or an unexpected archive
    /// error throws; secondary indexes are rebuilt either way. `progress` gets the
    /// running report after every chunk.
    public static func replay(archive: RawArchive, normalizer: any Normalizer, into store: EventStore,
                              after: Int64 = 0, chunk: Int = 5_000,
                              maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                              progress: (@Sendable (ReplayReport) -> Void)? = nil) throws -> ReplayReport {
        let reports = try replay(
            sources: [ReplaySource(archive: archive, normalizer: normalizer, after: after)],
            into: store, chunk: chunk, maxBytes: maxBytes, progress: progress)
        return reports[0]
    }

    /// Replays several archives, one per provider, inside a single bulk-load
    /// window. Returns one report per source, in order. Throws
    /// `PipelineError.duplicateProvider` or `.normalizerMismatch` before touching
    /// the store.
    public static func replay(sources: [ReplaySource], into store: EventStore, chunk: Int = 5_000,
                              maxBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                              progress: (@Sendable (ReplayReport) -> Void)? = nil) throws -> [ReplayReport] {
        var seen = Set<String>()
        for source in sources {
            guard source.archive.provider == source.normalizer.provider else {
                throw PipelineError.normalizerMismatch(
                    archive: source.archive.provider, normalizer: source.normalizer.provider)
            }
            guard seen.insert(source.archive.provider).inserted else {
                throw PipelineError.duplicateProvider(source.archive.provider)
            }
        }
        let size = max(1, chunk)
        var reports: [ReplayReport] = []
        try store.beginBulkLoad()
        var replayError: Error?
        do {
            for source in sources {
                var report = ReplayReport()
                report.provider = source.archive.provider
                report.lastID = source.after
                defer { reports.append(report) }
                try replay(source, into: store, size: size, maxBytes: maxBytes, report: &report, progress: progress)
            }
        } catch {
            replayError = error
        }
        // Rebuild indexes even when the replay threw; the replay error wins.
        do { try store.endBulkLoad() } catch { if replayError == nil { replayError = error } }
        if let replayError { throw replayError }
        return reports
    }

    private static func replay(_ source: ReplaySource, into store: EventStore, size: Int, maxBytes: Int,
                               report: inout ReplayReport,
                               progress: (@Sendable (ReplayReport) -> Void)?) throws {
        var cursor = source.after
        while true {
            let ids = try source.archive.ids(after: cursor, limit: size, maxBytes: maxBytes)
            guard let last = ids.last else { break }
            let page = try readChunk(archive: source.archive, ids: ids, report: &report)
            var combined = NormalizedBatch()
            for archived in page {
                report.records += 1
                do {
                    combined.append(try source.normalizer.normalize(archived))
                    report.normalized += 1
                } catch {
                    fail(&report, id: archived.id, error)
                }
            }
            try store.write(combined, provider: source.archive.provider, deadline: EventStore.bulkDeadline)
            cursor = last
            report.lastID = last
            progress?(report)
        }
    }

    private static func fail(_ report: inout ReplayReport, id: Int64, _ error: Error) {
        report.failed += 1
        if report.failures.count < maxReportedFailures { report.failures[id] = String(describing: error) }
    }

    /// The records with `ids`. When the chunk read throws `corruptPayload`, falls back
    /// to one read per id so only the bad rows are lost. Other errors propagate.
    private static func readChunk(archive: RawArchive, ids: [Int64],
                                  report: inout ReplayReport) throws -> [ArchivedRecord] {
        do {
            return try archive.records(ids: ids)
        } catch RawArchiveError.corruptPayload {
            var page: [ArchivedRecord] = []
            for id in ids {
                do {
                    if let archived = try archive.record(id: id) { page.append(archived) }
                } catch RawArchiveError.corruptPayload {
                    report.records += 1
                    fail(&report, id: id, RawArchiveError.corruptPayload(id: id))
                }
            }
            return page
        }
    }
}
