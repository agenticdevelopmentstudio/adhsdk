import Foundation

public struct ConformanceFailure: Sendable, Equatable, CustomStringConvertible {
    public let check: String
    public let detail: String

    public init(check: String, detail: String) {
        self.check = check
        self.detail = detail
    }

    public var description: String { "\(check): \(detail)" }
}

/// The checks every provider adapter must pass: it loses nothing, duplicates nothing,
/// and replays to the same store the live drain built. Framework code (no XCTest) so
/// each provider's own test target can call it.
public enum ProviderConformance {
    /// Runs every check against recorded fixture records; returns failures (empty = conforms).
    /// - purity: `normalize(r)` twice gives equal batches (or equal thrown descriptions).
    /// - keys: every event/turn dedupKey is unique across the fixtures and stable across runs.
    /// - rawRef: every emitted row's rawRef equals the input record's archive id.
    /// - liveEqualsReplay: spool and drain all fixtures in seeded, shuffled batch sizes, then replay
    ///   the archive into a fresh store; the canonical dumps are equal.
    /// - idempotentRedelivery: draining the fixtures twice gives the same dump as once.
    public static func check(normalizer: any Normalizer, fixtures: [RawRecord],
                             workDirectory: URL, seed: UInt64 = 1) throws -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        let provider = normalizer.provider
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: workDirectory)

        // Archive the fixtures once so checks see real archive ids (duplicates collapse).
        let probeDir = workDirectory.appendingPathComponent("probe")
        try fileManager.createDirectory(at: probeDir, withIntermediateDirectories: true)
        let archive = try RawArchive(path: probeDir.appendingPathComponent("raw.db").path, provider: provider)
        _ = try archive.append(fixtures)
        let archived = try archive.records(after: 0, limit: max(1, try archive.count()))

        failures += checkPurityAndRefs(normalizer, archived)
        failures += checkKeys(normalizer, archived)

        var rng = SeededGenerator(seed: seed)
        let live = try drainAll(normalizer, fixtures, in: workDirectory.appendingPathComponent("live"),
                                passes: 1, rng: &rng)
        let replayed = try replayDump(normalizer, archive: live.archive,
                                      in: workDirectory.appendingPathComponent("replay"))
        if live.dump != replayed {
            failures.append(ConformanceFailure(
                check: "liveEqualsReplay", detail: describeDiff(live.dump, replayed)))
        }

        let twice = try drainAll(normalizer, fixtures, in: workDirectory.appendingPathComponent("twice"),
                                 passes: 2, rng: &rng)
        if twice.dump != live.dump {
            failures.append(ConformanceFailure(
                check: "idempotentRedelivery", detail: describeDiff(live.dump, twice.dump)))
        }
        return failures
    }

    // MARK: - Checks

    private enum Outcome: Equatable {
        case batch(NormalizedBatch)
        case threw(String)
    }

    private static func run(_ normalizer: any Normalizer, _ record: ArchivedRecord) -> Outcome {
        do { return .batch(try normalizer.normalize(record)) } catch { return .threw(String(describing: error)) }
    }

    private static func checkPurityAndRefs(_ normalizer: any Normalizer,
                                           _ archived: [ArchivedRecord]) -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        for item in archived {
            let first = run(normalizer, item)
            let second = run(normalizer, item)
            if first != second {
                failures.append(ConformanceFailure(
                    check: "purity", detail: "record \(item.record.dedupKey) normalized differently on a second run"))
            }
            guard case .batch(let batch) = first else { continue }
            let refs = batch.events.map(\.rawRef) + batch.turns.map(\.rawRef) + batch.messages.map(\.rawRef)
            if let wrong = refs.first(where: { $0 != item.id }) {
                failures.append(ConformanceFailure(
                    check: "rawRef", detail: "record \(item.record.dedupKey) (id \(item.id)) emitted rawRef \(wrong)"))
            }
        }
        return failures
    }

    private static func keys(_ outcome: Outcome) -> [String] {
        guard case .batch(let batch) = outcome else { return [] }
        return batch.events.map(\.dedupKey) + batch.turns.map(\.dedupKey)
    }

    private static func checkKeys(_ normalizer: any Normalizer,
                                  _ archived: [ArchivedRecord]) -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        var seen: [String: String] = [:]
        for item in archived {
            let first = keys(run(normalizer, item))
            if first != keys(run(normalizer, item)) {
                failures.append(ConformanceFailure(
                    check: "keys", detail: "record \(item.record.dedupKey) gave different dedupKeys on a rerun"))
            }
            for key in first {
                if let owner = seen[key] {
                    failures.append(ConformanceFailure(
                        check: "keys", detail: "dedupKey \(key) from \(item.record.dedupKey) already used by \(owner)"))
                }
                seen[key] = item.record.dedupKey
            }
        }
        return failures
    }

    // MARK: - Pipelines

    /// Feeds `fixtures` (delivered `passes` times) through spool -> drainer in seeded random chunk sizes.
    private static func drainAll(_ normalizer: any Normalizer, _ fixtures: [RawRecord], in directory: URL,
                                 passes: Int,
                                 rng: inout SeededGenerator) throws -> (dump: [String], archive: RawArchive) {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let provider = normalizer.provider
        let spool = try ProviderSpool(path: directory.appendingPathComponent("ingest.db").path, provider: provider)
        let archive = try RawArchive(path: directory.appendingPathComponent("raw.db").path, provider: provider)
        let store = try EventStore(path: directory.appendingPathComponent("events.db").path)
        let drainer = PipelineDrainer(spool: spool, archive: archive, normalizer: normalizer, store: store,
                                      batchSize: Int.random(in: 1...64, using: &rng))
        for _ in 0..<passes {
            var index = 0
            while index < fixtures.count {
                let size = Int.random(in: 1...37, using: &rng)
                let end = min(fixtures.count, index + size)
                try spool.append(Array(fixtures[index..<end]))
                index = end
                drainer.drainUntilEmpty()
            }
        }
        // A record that fails is retried one attempt per call until quarantined.
        for _ in 0...(ProviderSpool.maxAttempts + 1) {
            if try spool.pendingCount() == 0 { break }
            drainer.drainUntilEmpty()
        }
        return (try store.canonicalDump(), archive)
    }

    private static func replayDump(_ normalizer: any Normalizer, archive: RawArchive,
                                   in directory: URL) throws -> [String] {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try EventStore(path: directory.appendingPathComponent("events.db").path)
        _ = try Replayer.replay(archive: archive, normalizer: normalizer, into: store, chunk: 50)
        return try store.canonicalDump()
    }

    private static func describeDiff(_ left: [String], _ right: [String]) -> String {
        let onlyLeft = Set(left).subtracting(right)
        let onlyRight = Set(right).subtracting(left)
        let sample = (onlyLeft.sorted().first ?? "-", onlyRight.sorted().first ?? "-")
        return "\(left.count) vs \(right.count) rows; \(onlyLeft.count) only in first (e.g. \(sample.0.prefix(200))), "
            + "\(onlyRight.count) only in second (e.g. \(sample.1.prefix(200)))"
    }
}

/// SplitMix64: deterministic, so a seed reproduces a run.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
