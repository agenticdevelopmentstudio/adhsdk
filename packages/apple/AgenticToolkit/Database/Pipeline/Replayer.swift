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
    /// Never modifies the archive. A record that fails to normalize is reported, never fatal.
    /// A store or archive read error throws; secondary indexes are rebuilt either way.
    public static func replay(archive: RawArchive, normalizer: any Normalizer, into store: EventStore,
                              chunk: Int = 5_000, progress: (@Sendable (Int) -> Void)? = nil) throws -> ReplayReport {
        let size = max(1, chunk)
        var report = ReplayReport()
        try store.beginBulkLoad()
        var replayError: Error?
        do {
            var cursor: Int64 = 0
            while true {
                let page = try archive.records(after: cursor, limit: size)
                guard let last = page.last else { break }
                var combined = NormalizedBatch()
                for archived in page {
                    report.records += 1
                    do {
                        combined.append(try normalizer.normalize(archived))
                        report.normalized += 1
                    } catch {
                        report.failed += 1
                        if report.failures.count < maxReportedFailures {
                            report.failures[archived.id] = String(describing: error)
                        }
                    }
                }
                try store.write(combined, provider: archive.provider)
                cursor = last.id
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
}
