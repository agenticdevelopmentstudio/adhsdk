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
    /// - unstoredFixture: after the live drain the store holds a row for every well-formed fixture:
    ///   an event or message whose `dedup_key` is `<dedupKey>` or `<dedupKey>#<suffix>`, or a turn row
    ///   under a turn key the fixture emits (turns merge across records, so their key need not carry
    ///   the record's).
    /// - purity: `normalize(r)` twice gives equal batches (or equal thrown descriptions).
    /// - keys: every event and message dedup key is unique across the fixtures; turn keys may repeat
    ///   (records that describe one turn merge into it) but never reuse an event or message key; all
    ///   keys are stable across runs.
    /// - keyCollision: no two fixtures share a dedup key with payloads the normalizer does not call
    ///   equivalent (`Normalizer.isEquivalent`; the archive would keep the first and the drainer would
    ///   quarantine the other).
    /// - rawRef: every emitted row's rawRef equals the input record's archive id.
    /// - nonFiniteNumber: no emitted row holds NaN or an infinity (`NormalizedBatch.nonFiniteFields`);
    ///   the store cannot write one. When this fails the store-based checks below are skipped, since
    ///   every one of them would fail on the same unstorable rows.
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

        failures += checkCollisions(fixtures, check: "keyCollision", equivalent: normalizer.isEquivalent)
        failures += checkNoLoss(normalizer, archived, fixtures: fixtures, malformedKeys: malformedKeys)
        failures += checkPurityAndRefs(normalizer, archived)
        failures += checkKeys(normalizer, archived)
        let nonFinite = checkFinite(normalizer, archived)
        failures += nonFinite
        if !nonFinite.isEmpty { return failures }

        var rng = SeededGenerator(seed: seed)
        let live = try drainAll(normalizer, fixtures, in: root.appendingPathComponent("live"),
                                passes: 1, crashAt: nil, rng: &rng)
        failures += try checkPipelineLoss(live, fixtures: fixtures, malformedKeys: malformedKeys)
        failures += checkStored(live.dump, fixtures: fixtures, malformedKeys: malformedKeys,
                                turnKeys: turnKeys(normalizer, archived))

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
        if twice.content != live.content {
            failures.append(ConformanceFailure(
                check: "idempotentRedelivery", detail: describeDiff(live.content, twice.content)))
        }

        for step in DrainStep.allCases {
            let crashed = try drainAll(normalizer, fixtures, in: root.appendingPathComponent("crash-\(step.rawValue)"),
                                       passes: 1, crashAt: step, rng: &rng)
            if crashed.faultFired == false {
                failures.append(ConformanceFailure(
                    check: "crashRecovery",
                    detail: "the fault at \(step.rawValue) never fired; the pass proves nothing"))
            }
            if crashed.content != live.content {
                failures.append(ConformanceFailure(
                    check: "crashRecovery",
                    detail: "crash at \(step.rawValue): " + describeDiff(live.content, crashed.content)))
            }
        }
        return failures
    }

    /// Runs the source-contract checks against an `IngestSource` over its prepared input; returns
    /// failures (empty = conforms). `makeSource` builds a fresh source (modelling a restarted
    /// process) whose `poll` calls the injector at each `SourceStep`; when given nil it must not
    /// inject. Every source it builds reads the same input.
    /// - sourceEmpty: an uninterrupted run (poll until it returns 0) spools nothing.
    /// - sourceDuplicated: an uninterrupted run spools some dedup key more than once.
    /// - keyCollision: the run spools one dedup key for different payloads.
    /// - sourceCrash: for every `SourceStep`, crash once there, then poll to the end with a fresh
    ///   source; the spooled (key, payload) multiset equals the uninterrupted run's. Also fails when
    ///   the fault never fired.
    /// - sourceRunaway: a run did not reach a 0-record poll within `maxPolls`.
    /// Works in a fresh subdirectory of `workDirectory`, which is the only thing removed.
    public static func checkSource(
        provider: String, workDirectory: URL, maxPolls: Int = 10_000,
        makeSource: (_ faultInjector: (@Sendable (SourceStep) throws -> Void)?) throws -> any IngestSource
    ) throws -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        let fileManager = FileManager.default
        let root = workDirectory.appendingPathComponent("source-conformance-\(UUID().uuidString)")
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        func spool(_ name: String) throws -> ProviderSpool {
            try ProviderSpool(path: root.appendingPathComponent("\(name)-ingest.db").path, provider: provider)
        }
        /// Polls until a poll returns 0; false when `maxPolls` ran out first.
        func pollToEnd(_ source: any IngestSource, into spool: ProviderSpool) throws -> Bool {
            var polls = 0
            while polls < max(1, maxPolls) {
                polls += 1
                if try source.poll(into: spool) == 0 { return true }
            }
            return false
        }
        func spooled(_ spool: ProviderSpool) throws -> [RawRecord] {
            let count = try spool.pendingCount()
            return try spool.pendingBatch(limit: max(1, count), maxBytes: Int.max).map(\.record)
        }
        func multiset(_ records: [RawRecord]) -> [String] {
            records.map { "\($0.dedupKey)\u{0}\(RawArchive.hex($0.payload))" }.sorted()
        }

        let baselineSpool = try spool("baseline")
        if try !pollToEnd(try makeSource(nil), into: baselineSpool) {
            failures.append(ConformanceFailure(
                check: "sourceRunaway", detail: "uninterrupted run still appending after \(maxPolls) polls"))
        }
        let baseline = try spooled(baselineSpool)
        if baseline.isEmpty {
            failures.append(ConformanceFailure(check: "sourceEmpty", detail: "an uninterrupted run spooled nothing"))
        }
        var counts: [String: Int] = [:]
        for record in baseline { counts[record.dedupKey, default: 0] += 1 }
        for (key, count) in counts.sorted(by: { $0.key < $1.key }) where count > 1 {
            failures.append(ConformanceFailure(
                check: "sourceDuplicated", detail: "\(key) spooled \(count) times in one uninterrupted run"))
        }
        failures += checkCollisions(baseline, check: "keyCollision")
        let expected = multiset(baseline)

        for step in SourceStep.allCases {
            let crashSpool = try spool("crash-\(step.rawValue)")
            let fault = OneShotFault(step)
            let crashing = try makeSource { current in try fault.inject(current) }
            do {
                _ = try pollToEnd(crashing, into: crashSpool)
            } catch is OneShotFault<SourceStep>.Crash {
                // The crash ends the "process"; recovery follows.
            }
            if !fault.didFire {
                failures.append(ConformanceFailure(
                    check: "sourceCrash", detail: "the fault at \(step.rawValue) never fired; the run proves nothing"))
            }
            if try !pollToEnd(try makeSource(nil), into: crashSpool) {
                failures.append(ConformanceFailure(
                    check: "sourceRunaway",
                    detail: "recovery after \(step.rawValue) still appending after \(maxPolls) polls"))
            }
            let recovered = multiset(try spooled(crashSpool))
            if recovered != expected {
                failures.append(ConformanceFailure(
                    check: "sourceCrash", detail: "crash at \(step.rawValue): " + describeDiff(expected, recovered)))
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

    /// Every well-formed fixture must have a stored event or message whose dedup key is the fixture's
    /// dedup key or that key followed by "#suffix", or a stored turn under a key it emits.
    private static func checkStored(_ dump: [String], fixtures: [RawRecord], malformedKeys: Set<String>,
                                    turnKeys: [String: Set<String>]) -> [ConformanceFailure] {
        var roots = Set<String>()
        var storedTurns = Set<String>()
        for line in dump {
            guard let data = line.data(using: .utf8),
                  let object = try? JSONDecoder().decode([String: NormalizedValue].self, from: data),
                  case .string(let table)? = object["table"], table != "sessions",
                  case .string(let key)? = object["dedup_key"] else { continue }
            if table == "turns" {
                storedTurns.insert(key)
                continue
            }
            roots.insert(key)
            for (offset, character) in key.enumerated() where character == "#" {
                roots.insert(String(key.prefix(offset)))
            }
        }
        var failures: [ConformanceFailure] = []
        var reported = Set<String>()
        for fixture in fixtures where !malformedKeys.contains(fixture.dedupKey) && !roots.contains(fixture.dedupKey) {
            if let emitted = turnKeys[fixture.dedupKey], !emitted.isDisjoint(with: storedTurns) { continue }
            if reported.insert(fixture.dedupKey).inserted {
                failures.append(ConformanceFailure(
                    check: "unstoredFixture",
                    detail: "no event, turn or message in the store is keyed by \(fixture.dedupKey)"))
            }
        }
        return failures
    }

    /// The turn keys each record emits, by record dedup key.
    private static func turnKeys(_ normalizer: any Normalizer, _ archived: [ArchivedRecord]) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]
        for item in archived {
            guard case .batch(let batch) = run(normalizer, item) else { continue }
            result[item.record.dedupKey, default: []].formUnion(batch.turns.map(\.dedupKey))
        }
        return result
    }

    /// Fails for every dedup key that arrives with a payload not equivalent to the
    /// first one under that key — exactly the records the drainer would quarantine.
    /// `equivalent` defaults to byte equality; `check` passes the normalizer's
    /// `isEquivalent`, so a provider-defined duplicate is not reported.
    static func checkCollisions(
        _ records: [RawRecord], check: String,
        equivalent: (_ archived: RawRecord, _ incoming: RawRecord) -> Bool = { $0.payload == $1.payload }
    ) -> [ConformanceFailure] {
        var first: [String: RawRecord] = [:]
        var reported = Set<String>()
        var failures: [ConformanceFailure] = []
        for record in records {
            if let existing = first[record.dedupKey] {
                if !equivalent(existing, record) && reported.insert(record.dedupKey).inserted {
                    failures.append(ConformanceFailure(
                        check: check,
                        detail: "dedup key \(record.dedupKey) is used for different payloads "
                            + "(sha \(RawArchive.hex(existing.payload)) vs \(RawArchive.hex(record.payload)))"))
                }
            } else {
                first[record.dedupKey] = record
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

    private static func checkFinite(_ normalizer: any Normalizer,
                                    _ archived: [ArchivedRecord]) -> [ConformanceFailure] {
        archived.compactMap { item in
            guard case .batch(let batch) = run(normalizer, item) else { return nil }
            let fields = batch.nonFiniteFields
            guard !fields.isEmpty else { return nil }
            return ConformanceFailure(
                check: "nonFiniteNumber",
                detail: "record \(item.record.dedupKey) emitted NaN or infinity at \(fields.joined(separator: ", "))")
        }
    }

    private static func keys(_ outcome: Outcome) -> (unique: [String], turns: [String]) {
        guard case .batch(let batch) = outcome else { return ([], []) }
        return (batch.events.map(\.dedupKey) + batch.messages.map(\.dedupKey), batch.turns.map(\.dedupKey))
    }

    private static func checkKeys(_ normalizer: any Normalizer,
                                  _ archived: [ArchivedRecord]) -> [ConformanceFailure] {
        var failures: [ConformanceFailure] = []
        var seen: [String: String] = [:]
        var turnOwners: [String: String] = [:]
        for item in archived {
            let first = keys(run(normalizer, item))
            let second = keys(run(normalizer, item))
            if first.unique != second.unique || first.turns != second.turns {
                failures.append(ConformanceFailure(
                    check: "keys", detail: "record \(item.record.dedupKey) gave different dedupKeys on a rerun"))
            }
            for key in first.unique {
                if let owner = seen[key] ?? turnOwners[key] {
                    failures.append(ConformanceFailure(
                        check: "keys", detail: "dedupKey \(key) from \(item.record.dedupKey) already used by \(owner)"))
                }
                seen[key] = item.record.dedupKey
            }
            for key in first.turns {
                if let owner = seen[key] {
                    failures.append(ConformanceFailure(
                        check: "keys",
                        detail: "turn key \(key) from \(item.record.dedupKey) is an event or message key of \(owner)"))
                }
                if turnOwners[key] == nil { turnOwners[key] = item.record.dedupKey }
            }
        }
        return failures
    }

    // MARK: - Pipelines

    private struct DrainResult {
        let dump: [String]
        /// The dump without `raw_ref`: archive ids follow arrival order, so two runs that
        /// archive in different orders are compared on this (the `rawRef` check proves the
        /// references themselves).
        let content: [String]
        let archive: RawArchive
        let quarantinedKeys: Set<String>
        let pending: Int
        /// Nil unless a crash was injected; then whether it actually fired.
        var faultFired: Bool?
    }

    /// Fires its fault once, at one step.
    private final class OneShotFault<Step: Equatable>: @unchecked Sendable {
        struct Crash: Error {}
        private let lock = NSLock()
        private let step: Step
        private var fired = false
        var didFire: Bool { lock.lock(); defer { lock.unlock() }; return fired }
        init(_ step: Step) { self.step = step }
        func inject(_ current: Step) throws {
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
        func makeDrainer(_ fault: OneShotFault<DrainStep>? = nil) throws -> PipelineDrainer {
            var injector: (@Sendable (DrainStep) throws -> Void)?
            if let fault { injector = { step in try fault.inject(step) } }
            return try PipelineDrainer(spool: spool, archive: archive, normalizer: normalizer, store: store,
                                       batchSize: batchSize, faultInjector: injector)
        }
        var drainer = try makeDrainer()
        var fired: Bool?
        if let crashAt {
            try spool.append(fixtures)
            // A fresh drainer models the restarted process.
            let fault = OneShotFault(crashAt)
            _ = try makeDrainer(fault).drainOnce()
            fired = fault.didFire
            drainer = try makeDrainer()
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
        return DrainResult(dump: try store.canonicalDump(),
                           content: try store.canonicalDump(includingRawRef: false), archive: archive,
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
        return "\(left.count) vs \(right.count) rows; \(onlyLeft.count) only in first (e.g. \(sample.0.prefix(2000))), "
            + "\(onlyRight.count) only in second (e.g. \(sample.1.prefix(2000)))"
    }

    // MARK: - Seeded randomness

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
}
