import Foundation

public struct ReplayReport: Sendable, Equatable {
    public var records = 0
    public var normalized = 0
    public var failed = 0
    /// Archive id to error description. Only the first `Replayer.maxReportedFailures` are kept.
    public var failures: [Int64: String] = [:]

    public init() {}
}

/// Rebuilds an `EventStore` from the raw archive, which is what makes the
/// archive a working backup. Read-only against the archive.
public enum Replayer {
    public static let maxReportedFailures = 1000

    /// Reads `archive` in id order, `chunk` records at a time; normalizes; writes in bulk mode.
    /// Never modifies the archive. A record that fails to normalize, or that the archive
    /// cannot decode (corrupt payload), is reported by archive id and skipped, never fatal.
    /// A store error or an unexpected archive error throws; secondary indexes are rebuilt either way.
    public static func replay(archive: RawArchive, normalizer: any Normalizer, into store: EventStore,
                              chunk: Int = 5_000, progress: (@Sendable (Int) -> Void)? = nil) throws -> ReplayReport {
        let size = max(1, chunk)
        var report = ReplayReport()
        var replayError: Error?
        do {
            try store.beginBulkLoad()
            var cursor: Int64 = 0
            while true {
                let (page, next) = try readChunk(archive: archive, after: cursor, size: size, report: &report)
                guard let next else { break }
                cursor = next
                var combined = NormalizedBatch()
                for archived in page {
                    report.records += 1
                    do {
                        combined.append(try normalizer.normalize(archived))
                        report.normalized += 1
                    } catch {
                        fail(&report, id: archived.id, error)
                    }
                }
                try store.write(combined, provider: archive.provider)
                progress?(report.records)
            }
        } catch {
            replayError = error
        }
        // Rebuild indexes even when the replay threw; the replay error wins.
        do { try store.endBulkLoad() } catch { if replayError == nil { replayError = error } }
        if let replayError { throw replayError }
        return report
    }

    private static func fail(_ report: inout ReplayReport, id: Int64, _ error: Error) {
        report.failed += 1
        if report.failures.count < maxReportedFailures { report.failures[id] = String(describing: error) }
    }

    /// The next chunk and the id to continue after; `nil` when the archive is exhausted.
    /// When the page read throws `corruptPayload`, falls back to one read per id across
    /// the chunk's id range so only the bad rows are lost. Other errors propagate.
    private static func readChunk(archive: RawArchive, after cursor: Int64, size: Int,
                                  report: inout ReplayReport) throws -> ([ArchivedRecord], Int64?) {
        do {
            let page = try archive.records(after: cursor, limit: size)
            return (page, page.last?.id)
        } catch RawArchiveError.corruptPayload {
            let (sum, overflow) = cursor.addingReportingOverflow(Int64(size))
            let high = min(overflow ? Int64.max : sum, try archive.maxID())
            guard high > cursor else { return ([], nil) }
            var page: [ArchivedRecord] = []
            for id in (cursor + 1)...high {
                do {
                    if let archived = try archive.record(id: id) { page.append(archived) }
                } catch RawArchiveError.corruptPayload {
                    report.records += 1
                    fail(&report, id: id, RawArchiveError.corruptPayload(id: id))
                }
            }
            return (page, high)
        }
    }
}
