#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// Spools the hook envelopes the hook binary leaves in the drop directory
/// (`HookDropWriter`: `<ms>-<8hex>.json`, written as `.json.tmp` and renamed).
///
/// Each `*.json` file not prefixed `error-`, at least `minimumAge` old by its
/// mtime, becomes one record (Design Ruling 2): sourceKind `"hook"`, dedupKey = the
/// file's stem, receivedAt = its mtime, payload = its bytes, verbatim. Files go in
/// name order — the millisecond prefix makes that arrival order — in appends of at
/// most `batchSize`, and a file is deleted only after the append holding it has
/// committed. A crash between the two leaves the file to be spooled again under the
/// same key, which the archive collapses as a duplicate.
///
/// What reaches the spool is not judged here: an empty file, an envelope with no
/// session and invalid JSON are all appended, so the raw archive keeps them, and
/// the normalizer decides (invalid JSON is quarantined in the spool with its
/// bytes). Only a file that cannot be read at all has no bytes to keep; it moves to
/// `<drop>/errors/error-<name>`, the name `EventIngestor` gives a quarantined drop.
public final class ClaudeHookDropSource: IngestSource {
    public static let batchSize = 200

    public let provider = ClaudeProvider.name
    public let dropDirectory: URL
    public let minimumAge: TimeInterval
    private let faultInjector: (@Sendable (SourceStep) throws -> Void)?

    /// `faultInjector` is for tests: it fires around each batch's append (see `SourceStep`).
    public init(dropDirectory: URL, minimumAge: TimeInterval = 0.1,
                faultInjector: (@Sendable (SourceStep) throws -> Void)? = nil) {
        self.dropDirectory = dropDirectory
        self.minimumAge = minimumAge
        self.faultInjector = faultInjector
    }

    public var errorsDirectory: URL { dropDirectory.appendingPathComponent("errors") }

    /// Appends every ready drop file and returns how many it appended. An append
    /// that throws ends the poll and is rethrown, with that batch's files (and every
    /// later one) left in place.
    public func poll(into spool: ProviderSpool) throws -> Int {
        try pollCountingDeferred(into: spool).appended
    }

    /// `poll(into:)`, also reporting how many drop files it left for being younger
    /// than `minimumAge`, so the caller can look again once they are old enough.
    public func pollCountingDeferred(into spool: ProviderSpool) throws -> (appended: Int, deferred: Int) {
        let (ready, deferred) = readyFiles()
        var appended = 0
        var start = 0
        while start < ready.count {
            let batch = ready[start..<min(start + Self.batchSize, ready.count)]
            start = batch.endIndex
            var records: [RawRecord] = []
            var appendedFiles: [URL] = []
            for (url, modified) in batch {
                autoreleasepool {
                    guard let data = try? Data(contentsOf: url) else {
                        moveToErrors(url)
                        return
                    }
                    records.append(RawRecord(
                        provider: provider, sourceKind: ClaudeProvider.hookKind,
                        dedupKey: url.deletingPathExtension().lastPathComponent,
                        receivedAt: modified, payload: data))
                    appendedFiles.append(url)
                }
            }
            guard !records.isEmpty else { continue }
            try faultInjector?(.beforeAppend)
            try spool.append(records)
            try faultInjector?(.afterAppend)
            appended += records.count
            for url in appendedFiles { try? FileManager.default.removeItem(at: url) }
        }
        return (appended, deferred)
    }

    /// Drop files old enough to be whole, in name order, with their mtimes, and how
    /// many were skipped for being too young.
    private func readyFiles() -> (ready: [(url: URL, modified: Date)], deferred: Int) {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: dropDirectory, includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return ([], 0) }
        let now = Date()
        var ready: [(url: URL, modified: Date)] = []
        var deferred = 0
        let candidates = entries
            .filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasPrefix("error-") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for url in candidates {
            autoreleasepool {
                guard let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate else { return }
                if now.timeIntervalSince(modified) >= minimumAge {
                    ready.append((url, modified))
                } else {
                    deferred += 1
                }
            }
        }
        return (ready, deferred)
    }

    /// Moves an unreadable drop file out of the drop directory, so it is not retried
    /// on every poll. If the move fails too the file stays and the next poll tries
    /// again; nothing is deleted.
    private func moveToErrors(_ url: URL) {
        let fileManager = FileManager.default
        var destination = errorsDirectory.appendingPathComponent("error-\(url.lastPathComponent)")
        if fileManager.fileExists(atPath: destination.path) {
            let stem = url.deletingPathExtension().lastPathComponent
            destination = errorsDirectory.appendingPathComponent("error-\(stem)-\(UUID().uuidString).json")
        }
        try? fileManager.createDirectory(at: errorsDirectory, withIntermediateDirectories: true)
        try? fileManager.moveItem(at: url, to: destination)
    }
}
#endif
