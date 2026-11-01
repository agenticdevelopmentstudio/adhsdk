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
    /// `malformedKeys` are the dedup keys of fixtures the adapter declares malformed: they must be
    /// archived, fail to normalize, end up quarantined, and be the only replay failures. Every other
    /// fixture must normalize to a non-empty batch. Supply fixtures of every `sourceKind` the
    /// adapter handles (for Claude: hook payloads and transcript lines).
    /// - notArchived, normalizerThrew, emptyBatch, malformedAccepted, undrained, quarantineMismatch,
    ///   replayMismatch: nothing is lost. Every fixture is archived; no well-formed fixture throws or
    ///   yields an empty batch; the quarantined set and the replay failures equal `malformedKeys` exactly.
    /// - unstoredFixture: after the live drain the store holds an event, turn or message row for every
    ///   well-formed fixture, keyed `<dedupKey>` or `<dedupKey>#<suffix>`.
    /// - purity: `normalize(r)` twice gives equal batches (or equal thrown descriptions).
    /// - keys: every event/turn/message key is unique across the fixtures and stable across runs.
    /// - rawRef: every emitted row's rawRef equals the input record's archive id.
    /// - liveEqualsReplay: spool and drain all fixtures in seeded, shuffled batch sizes, then replay
    ///   the archive into a fresh store; the canonical dumps are equal.
    /// - idempotentRedelivery: draining the fixtures twice gives the same dump as once.
    /// - crashRecovery: for every `DrainStep`, crash once there, re-drain with a fresh drainer; the
    ///   dump equals the uncrashed baseline.
    /// Works in a fresh subdirectory of `workDirectory`, which is the only thing removed.
    public static func check(normalizer: any Normalizer, fixtures: [RawRecord], malformedKeys: Set<String> = [],
                             workDirectory: URL, seed: UInt64 = 1) throws -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        let provider = normalizer.provider
        let fileManager = FileManager.default
        let root = workDirectory.appendingPathComponent("conformance-\(UUID().uuidString)")
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        for fixture in fixtures where fixture.provider != provider {
            failures.append(ConformanceFailure(
                check: "fixtures",
                detail: "\(fixture.dedupKey) has provider \(fixture.provider), expected \(provider)"))
        }

        // Archive the fixtures once so checks see real archive ids (duplicates collapse).
        let probeDir = root.appendingPathComponent("probe")
        try fileManager.createDirectory(at: probeDir, withIntermediateDirectories: true)
        let archive = try RawArchive(path: probeDir.appendingPathComponent("raw.db").path, provider: provider)
        _ = try archive.append(fixtures)
        let archived = try archive.records(after: 0, limit: max(1, try archive.count()))

        failures += checkNoLoss(normalizer, archived, fixtures: fixtures, malformedKeys: malformedKeys)
        failures += checkPurityAndRefs(normalizer, archived)
        failures += checkKeys(normalizer, archived)

        var rng = SeededGenerator(seed: seed)
        let live = try drainAll(normalizer, fixtures, in: root.appendingPathComponent("live"),
                                passes: 1, crashAt: nil, rng: &rng)
        failures += try checkPipelineLoss(live, fixtures: fixtures, malformedKeys: malformedKeys)
        failures += checkStored(live.dump, fixtures: fixtures, malformedKeys: malformedKeys)

        let replayed = try replayDump(normalizer, archive: live.archive, in: root.appendingPathComponent("replay"))
        if live.dump != replayed.dump {
            failures.append(ConformanceFailure(
                check: "liveEqualsReplay", detail: describeDiff(live.dump, replayed.dump)))
        }
        let replayKeys = Set(replayed.report.failures.keys.compactMap {
            (try? live.archive.record(id: $0))?.record.dedupKey
        })
        if replayKeys != malformedKeys || replayed.report.failed != malformedKeys.count {
            let ids = replayed.report.failures.keys.sorted()
            failures.append(ConformanceFailure(
                check: "replayMismatch", detail: "replay failed ids \(ids) (keys \(replayKeys.sorted())); "
                    + "expected exactly \(malformedKeys.sorted())"))
        }

        let twice = try drainAll(normalizer, fixtures, in: root.appendingPathComponent("twice"),
                                 passes: 2, crashAt: nil, rng: &rng)
        if twice.dump != live.dump {
            failures.append(ConformanceFailure(
                check: "idempotentRedelivery", detail: describeDiff(live.dump, twice.dump)))
        }

        for step in DrainStep.allCases {
            let crashed = try drainAll(normalizer, fixtures, in: root.appendingPathComponent("crash-\(step.rawValue)"),
                                       passes: 1, crashAt: step, rng: &rng)
            if crashed.faultFired == false {
                failures.append(ConformanceFailure(
                    check: "crashRecovery",
                    detail: "the fault at \(step.rawValue) never fired; the pass proves nothing"))
            }
            if crashed.dump != live.dump {
                failures.append(ConformanceFailure(
                    check: "crashRecovery",
                    detail: "crash at \(step.rawValue): " + describeDiff(live.dump, crashed.dump)))
            }
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

    private static func checkNoLoss(_ normalizer: any Normalizer, _ archived: [ArchivedRecord],
                                    fixtures: [RawRecord], malformedKeys: Set<String>) -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        let archivedKeys = Set(archived.map(\.record.dedupKey))
        for fixture in fixtures where !archivedKeys.contains(fixture.dedupKey) {
            failures.append(ConformanceFailure(check: "notArchived", detail: "\(fixture.dedupKey) is not archived"))
        }
        for item in archived where !malformedKeys.contains(item.record.dedupKey) {
            switch run(normalizer, item) {
            case .threw(let reason):
                failures.append(ConformanceFailure(
                    check: "normalizerThrew",
                    detail: "well-formed \(item.record.dedupKey) (id \(item.id)) threw: \(reason)"))
            case .batch(let batch):
                if batch == NormalizedBatch() {
                    failures.append(ConformanceFailure(
                        check: "emptyBatch",
                        detail: "well-formed \(item.record.dedupKey) (id \(item.id)) yielded no rows"))
                }
            }
        }
        for item in archived where malformedKeys.contains(item.record.dedupKey) {
            if case .batch = run(normalizer, item) {
                failures.append(ConformanceFailure(
                    check: "malformedAccepted",
                    detail: "declared-malformed \(item.record.dedupKey) normalized without error"))
            }
        }
        return failures
    }

    /// Every well-formed fixture must have a stored event/turn/message whose key is the fixture's
    /// dedup key or that key followed by "#suffix".
    private static func checkStored(_ dump: [String], fixtures: [RawRecord],
                                    malformedKeys: Set<String>) -> [ConformanceFailure] {
        var roots = Set<String>()
        for line in dump {
            guard let data = line.data(using: .utf8),
                  let object = try? JSONDecoder().decode([String: JSONValue].self, from: data),
                  case .string(let table)? = object["table"], table != "sessions" else { continue }
            guard case .string(let key)? = object[table == "messages" ? "uuid" : "dedup_key"] else { continue }
            roots.insert(key)
            for (offset, character) in key.enumerated() where character == "#" {
                roots.insert(String(key.prefix(offset)))
            }
        }
        var failures: [ConformanceFailure] = []
        var reported = Set<String>()
        for fixture in fixtures where !malformedKeys.contains(fixture.dedupKey) && !roots.contains(fixture.dedupKey) {
            if reported.insert(fixture.dedupKey).inserted {
                failures.append(ConformanceFailure(
                    check: "unstoredFixture",
                    detail: "no event, turn or message in the store is keyed by \(fixture.dedupKey)"))
            }
        }
        return failures
    }

    private static func checkPipelineLoss(_ live: DrainResult, fixtures: [RawRecord],
                                          malformedKeys: Set<String>) throws -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        if live.pending != 0 {
            failures.append(ConformanceFailure(check: "undrained", detail: "\(live.pending) records never drained"))
        }
        if live.quarantinedKeys != malformedKeys {
            failures.append(ConformanceFailure(
                check: "quarantineMismatch", detail: "quarantined \(live.quarantinedKeys.sorted()); "
                    + "expected exactly \(malformedKeys.sorted())"))
        }
        for fixture in fixtures where try live.archive.id(forDedupKey: fixture.dedupKey) == nil {
            failures.append(ConformanceFailure(
                check: "notArchived", detail: "\(fixture.dedupKey) missing from the live archive"))
        }
        return failures
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
        return batch.events.map(\.dedupKey) + batch.turns.map(\.dedupKey) + batch.messages.map(\.uuid)
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

    private struct DrainResult {
        let dump: [String]
        let archive: RawArchive
        let quarantinedKeys: Set<String>
        let pending: Int
        /// Nil unless a crash was injected; then whether it actually fired.
        var faultFired: Bool?
    }

    /// Fires its fault once, at one step.
    private final class OneShotFault: @unchecked Sendable {
        struct Crash: Error {}
        private let lock = NSLock()
        private let step: DrainStep
        private var fired = false
        var didFire: Bool { lock.lock(); defer { lock.unlock() }; return fired }
        init(_ step: DrainStep) { self.step = step }
        func inject(_ current: DrainStep) throws {
            lock.lock()
            let fire = current == step && !fired
            if fire { fired = true }
            lock.unlock()
            if fire { throw Crash() }
        }
    }

    /// Feeds `fixtures` (delivered `passes` times) through spool -> drainer. Without `crashAt`, in seeded
    /// random chunk sizes. With it, spooled at once, crashed once at that step, then recovered by a
    /// fresh drainer.
    private static func drainAll(_ normalizer: any Normalizer, _ fixtures: [RawRecord], in directory: URL,
                                 passes: Int, crashAt: DrainStep?,
                                 rng: inout SeededGenerator) throws -> DrainResult {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let provider = normalizer.provider
        let spool = try ProviderSpool(path: directory.appendingPathComponent("ingest.db").path, provider: provider)
        let archive = try RawArchive(path: directory.appendingPathComponent("raw.db").path, provider: provider)
        let store = try EventStore(path: directory.appendingPathComponent("events.db").path)
        let batchSize = Int.random(in: 1...64, using: &rng)
        func makeDrainer(_ fault: OneShotFault? = nil) -> PipelineDrainer {
            var injector: (@Sendable (DrainStep) throws -> Void)?
            if let fault { injector = { step in try fault.inject(step) } }
            return PipelineDrainer(spool: spool, archive: archive, normalizer: normalizer, store: store,
                                   batchSize: batchSize, faultInjector: injector)
        }
        var drainer = makeDrainer()
        var fired: Bool?
        if let crashAt {
            try spool.append(fixtures)
            // A fresh drainer models the restarted process.
            let fault = OneShotFault(crashAt)
            _ = makeDrainer(fault).drainOnce()
            fired = fault.didFire
            drainer = makeDrainer()
        } else {
            for _ in 0..<passes {
                var index = 0
                while index < fixtures.count {
                    let end = min(fixtures.count, index + Int.random(in: 1...37, using: &rng))
                    try spool.append(Array(fixtures[index..<end]))
                    index = end
                    drainer.drainUntilEmpty()
                }
            }
        }
        // A record that fails is retried one attempt per call until quarantined.
        for _ in 0...(ProviderSpool.maxAttempts + 1) {
            if try spool.pendingCount() == 0 { break }
            drainer.drainUntilEmpty()
        }
        let quarantined = try spool.quarantined(limit: max(1, fixtures.count))
        return DrainResult(dump: try store.canonicalDump(), archive: archive,
                           quarantinedKeys: Set(quarantined.map(\.record.dedupKey)),
                           pending: try spool.pendingCount(), faultFired: fired)
    }

    private static func replayDump(_ normalizer: any Normalizer, archive: RawArchive,
                                   in directory: URL) throws -> (dump: [String], report: ReplayReport) {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try EventStore(path: directory.appendingPathComponent("events.db").path)
        let report = try Replayer.replay(archive: archive, normalizer: normalizer, into: store, chunk: 50)
        return (try store.canonicalDump(), report)
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
