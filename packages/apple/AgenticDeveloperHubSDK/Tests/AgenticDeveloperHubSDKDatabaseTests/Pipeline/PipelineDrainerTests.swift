import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

private struct TestNormalizer: Normalizer {
    let provider = "mock"
    struct Bad: Error {}
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        if record.record.payload == Data("BAD".utf8) { throw Bad() }
        let object = try JSONSerialization.jsonObject(with: record.record.payload) as? [String: Any]
        let session = object?["session"] as? String ?? "s"
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "\(record.record.dedupKey)#0", sessionID: session, kind: .other,
            providerType: "T", time: record.record.receivedAt, rawRef: record.id)]
        return batch
    }
}

/// `TestNormalizer`, except a record keyed `poison*` emits a NaN attr, which the
/// store cannot encode, so its write always fails.
private struct PoisonNormalizer: Normalizer {
    let provider = "mock"
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        var batch = try TestNormalizer().normalize(record)
        if record.record.dedupKey.hasPrefix("poison") {
            for index in batch.events.indices { batch.events[index].attrs["bad"] = .number(.nan) }
        }
        return batch
    }
}

/// `TestNormalizer`, except two payloads with the same `"t"` are the same record
/// whatever else differs (a provider-defined identity, like a transcript line that moved).
private struct SameTNormalizer: Normalizer {
    let provider = "mock"
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch { try TestNormalizer().normalize(record) }
    func isEquivalent(archived: RawRecord, incoming: RawRecord) -> Bool {
        func tValue(_ data: Data) -> Int? {
            (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["t"] as? Int
        }
        guard let old = tValue(archived.payload) else { return false }
        return old == tValue(incoming.payload)
    }
}

private struct AlwaysFailingNormalizer: Normalizer {
    let provider = "mock"
    struct Transient: Error {}
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch { throw Transient() }
}

private final class RecordingObserver: PipelineObserver, @unchecked Sendable {
    private let lock = NSLock()
    private var batches: [NormalizedBatch] = []
    private var visible: [(events: Int, pending: Int)] = []
    private let probe: (@Sendable () -> (events: Int, pending: Int))?
    private let onStore: (@Sendable () -> Void)?

    init(probe: (@Sendable () -> (events: Int, pending: Int))? = nil, onStore: (@Sendable () -> Void)? = nil) {
        self.probe = probe
        self.onStore = onStore
    }

    var received: [NormalizedBatch] { lock.lock(); defer { lock.unlock() }; return batches }
    /// Store event count and spool depth as seen from inside each callback.
    var seenInsideCallback: [(events: Int, pending: Int)] { lock.lock(); defer { lock.unlock() }; return visible }

    func pipelineDidStore(_ batch: NormalizedBatch, provider: String) {
        let seen = probe?()
        lock.lock()
        batches.append(batch)
        if let seen { visible.append(seen) }
        lock.unlock()
        onStore?()
    }
}

private final class FireOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false
    func shouldFire() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

final class PipelineDrainerTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-drain-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private struct Rig {
        let spool: ProviderSpool
        let archive: RawArchive
        let store: EventStore
    }

    private func makeRig() throws -> Rig {
        func path(_ name: String) -> String { tmpDir.appendingPathComponent(name).path }
        return Rig(
            spool: try ProviderSpool(path: path(ProviderSpool.fileName(provider: "mock")), provider: "mock"),
            archive: try RawArchive(path: path(RawArchive.fileName(provider: "mock")), provider: "mock"),
            store: try EventStore(path: path(EventStore.fileName)))
    }

    private func drainer(_ rig: Rig, batchSize: Int = 200, maxBatchBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                         sinks: [any PipelineSink] = [],
                         inject: (@Sendable (DrainStep) throws -> Void)? = nil) throws -> PipelineDrainer {
        try PipelineDrainer(spool: rig.spool, archive: rig.archive, normalizer: TestNormalizer(),
                            store: rig.store, batchSize: batchSize, maxBatchBytes: maxBatchBytes, sinks: sinks,
                            faultInjector: inject)
    }

    private func record(_ key: String, payload: String? = nil) -> RawRecord {
        RawRecord(provider: "mock", sourceKind: "hook", dedupKey: key,
                  receivedAt: Date(timeIntervalSince1970: 1_800_000_000),
                  payload: Data((payload ?? "{\"session\":\"s1\",\"t\":1}").utf8))
    }

    func testDrainArchivesStoresAndCompletes() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<10).map { record("k\($0)") })
        let outcome = try drainer(rig).drainUntilEmpty()
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertEqual(try rig.archive.count(), 10)
        XCTAssertEqual(try rig.store.counts().events, 10)
    }

    func testCrashAtEveryStepLosesNothingAndDuplicatesNothing() throws {
        for step in DrainStep.allCases {
            let dir = tmpDir.appendingPathComponent("case-\(step.rawValue)")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let rig = Rig(
                spool: try ProviderSpool(path: dir.appendingPathComponent("s.db").path, provider: "mock"),
                archive: try RawArchive(path: dir.appendingPathComponent("a.db").path, provider: "mock"),
                store: try EventStore(path: dir.appendingPathComponent("e.db").path))
            let keys = (0..<20).map { "k\($0)" }
            try rig.spool.append(keys.map { record($0) })

            struct Boom: Error {}
            let once = FireOnce()
            let crashing = try drainer(rig) { current in
                if current == step, once.shouldFire() { throw Boom() }
            }
            XCTAssertTrue(crashing.drainOnce().failed, "step \(step)")

            let clean = try drainer(rig).drainUntilEmpty()
            XCTAssertFalse(clean.failed, "step \(step)")
            XCTAssertEqual(try rig.archive.count(), 20, "step \(step)")
            XCTAssertEqual(try rig.store.counts().events, 20, "step \(step)")
            XCTAssertEqual(try rig.spool.pendingCount(), 0, "step \(step)")
            for key in keys {
                XCTAssertNotNil(try rig.archive.id(forDedupKey: key), "step \(step) key \(key)")
            }
        }
    }

    func testMalformedRecordIsArchivedThenQuarantinedAfterMaxAttempts() throws {
        let rig = try makeRig()
        var records = (0..<4).map { record("g\($0)") }
        records.insert(record("bad", payload: "BAD"), at: 2)
        try rig.spool.append(records)
        let pipe = try drainer(rig)
        for _ in 0..<ProviderSpool.maxAttempts { pipe.drainOnce() }
        let quarantined = try rig.spool.quarantined(limit: 10)
        XCTAssertEqual(quarantined.count, 1)
        XCTAssertEqual(quarantined.first?.record.dedupKey, "bad")
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        let id = try XCTUnwrap(try rig.archive.id(forDedupKey: "bad"))
        XCTAssertEqual(try rig.archive.record(id: id)?.record.payload, Data("BAD".utf8))
        XCTAssertEqual(try rig.store.counts().events, 4)
    }

    func testMalformedRecordNeverBlocksItsBatch() throws {
        let rig = try makeRig()
        var records = (0..<5).map { record("g\($0)") }
        records.insert(record("bad", payload: "BAD"), at: 0)
        try rig.spool.append(records)
        let outcome = try drainer(rig).drainOnce()
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(try rig.store.counts().events, 5)
        XCTAssertEqual(try rig.spool.pendingCount(), 1)
    }

    func testRedeliveredRecordIsCollapsed() throws {
        let rig = try makeRig()
        try rig.spool.append([record("dup")])
        try rig.spool.append([record("dup")])
        try drainer(rig).drainUntilEmpty()
        XCTAssertEqual(try rig.archive.count(), 1)
        XCTAssertEqual(try rig.store.counts().events, 1)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
    }

    func testObserverCalledAfterCommitWithWrittenBatch() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<3).map { record("k\($0)") })
        let observer = RecordingObserver(probe: {
            ((try? rig.store.counts().events) ?? -1, (try? rig.spool.pendingCount()) ?? -1)
        })
        let pipe = try drainer(rig)
        pipe.addObserver(observer)
        pipe.drainUntilEmpty()
        XCTAssertEqual(observer.received.count, 1)
        XCTAssertEqual(observer.received.first?.events.count, 3)
        // Inside the callback the events are already committed and the rows completed.
        XCTAssertEqual(observer.seenInsideCallback.count, 1)
        XCTAssertEqual(observer.seenInsideCallback.first?.events, 3)
        XCTAssertEqual(observer.seenInsideCallback.first?.pending, 0)
    }

    func testStoreWriteFailureLeavesSpoolIntactAndLaterDrainRecovers() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<6).map { record("k\($0)") })
        // Hide the events table from a second connection so store.write really throws.
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        let saboteur = try DatabaseQueue(path: path)
        try saboteur.write { try $0.execute(sql: "ALTER TABLE events RENAME TO events_hidden") }

        let failed = try drainer(rig).drainOnce()
        XCTAssertTrue(failed.failed)
        XCTAssertNotNil(failed.failureReason)
        XCTAssertEqual(failed.completed, 0)
        XCTAssertEqual(try rig.spool.pendingCount(), 6)
        XCTAssertEqual(try rig.archive.count(), 6)
        // A store failure is charged like any other, one attempt per record.
        XCTAssertEqual(try rig.spool.pendingBatch(limit: 10).map(\.attempts), Array(repeating: 1, count: 6))

        try saboteur.write { try $0.execute(sql: "ALTER TABLE events_hidden RENAME TO events") }
        let recovered = try drainer(rig).drainUntilEmpty()
        XCTAssertFalse(recovered.failed)
        XCTAssertEqual(try rig.store.counts().events, 6)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertEqual(try rig.archive.count(), 6)
    }

    func testUnstorableRecordIsIsolatedChargedAndQuarantinedWithoutBlockingItsBatch() throws {
        let rig = try makeRig()
        try rig.spool.append([record("k0"), record("poison"), record("k1")])
        let pipe = try PipelineDrainer(spool: rig.spool, archive: rig.archive,
                                       normalizer: PoisonNormalizer(), store: rig.store)
        let first = pipe.drainOnce()
        XCTAssertFalse(first.failed, first.failureReason ?? "")
        XCTAssertEqual(first.completed, 2)
        XCTAssertEqual(try rig.store.counts().events, 2)
        let left = try rig.spool.pendingBatch(limit: 10)
        XCTAssertEqual(left.map(\.record.dedupKey), ["poison"])
        XCTAssertEqual(left.map(\.attempts), [1])
        // Alone in its batch it keeps failing, and is quarantined at maxAttempts, bytes kept.
        for _ in 1..<ProviderSpool.maxAttempts { pipe.drainOnce() }
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        let quarantined = try rig.spool.quarantined(limit: 10)
        XCTAssertEqual(quarantined.map(\.record.dedupKey), ["poison"])
        XCTAssertTrue(quarantined.first?.reason.hasPrefix("store write failed") ?? false,
                      quarantined.first?.reason ?? "")
        XCTAssertEqual(quarantined.first?.record.payload, record("poison").payload)
    }

    func testDrainUntilEmptyStopsWithoutProgressAndDoesNotBurnAttempts() throws {
        let rig = try makeRig()
        try rig.spool.append([record("flaky")])
        let pipe = try PipelineDrainer(spool: rig.spool, archive: rig.archive,
                                   normalizer: AlwaysFailingNormalizer(), store: rig.store)
        let outcome = pipe.drainUntilEmpty()
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(outcome.quarantined, 0)
        let pending = try rig.spool.pendingBatch(limit: 10)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.attempts, 1)
        XCTAssertTrue(try rig.spool.quarantined(limit: 10).isEmpty)
    }

    func testStartWakeStop() throws {
        let rig = try makeRig()
        let pipe = try drainer(rig)
        XCTAssertTrue(pipe.start(idlePoll: 0.05))
        try rig.spool.append((0..<5).map { record("k\($0)") })
        pipe.wake()
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, try rig.store.counts().events < 5 {
            Thread.sleep(forTimeInterval: 0.02)
        }
        let began = Date()
        pipe.stop()
        XCTAssertLessThan(Date().timeIntervalSince(began), 2)
        XCTAssertEqual(try rig.store.counts().events, 5)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertTrue(pipe.start(idlePoll: 0.05), "restart after a clean stop is allowed")
        pipe.stop()
    }

    func testStartRefusesWhileWorkerIsAlive() throws {
        let rig = try makeRig()
        let pipe = try drainer(rig)
        XCTAssertTrue(pipe.start(idlePoll: 0.05))
        XCTAssertFalse(pipe.start(idlePoll: 0.05))
        pipe.stop()
    }

    func testStopFromWorkerThreadReturnsWithoutWaiting() throws {
        let rig = try makeRig()
        try rig.spool.append([record("k0")])
        let elapsed = ElapsedBox()
        let holder = DrainerBox()
        let observer = RecordingObserver(onStore: {
            let began = Date()
            holder.drainer?.stop()
            elapsed.set(Date().timeIntervalSince(began))
        })
        let pipe = try drainer(rig)
        holder.drainer = pipe
        pipe.addObserver(observer)
        XCTAssertTrue(pipe.start(idlePoll: 0.05))
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, elapsed.value == nil { Thread.sleep(forTimeInterval: 0.02) }
        let seconds = try XCTUnwrap(elapsed.value)
        XCTAssertLessThan(seconds, 1)
        // The worker exits on its own; start() is accepted again once it has.
        var restarted = false
        while Date() < deadline, !restarted {
            restarted = pipe.start(idlePoll: 0.05)
            if !restarted { Thread.sleep(forTimeInterval: 0.02) }
        }
        XCTAssertTrue(restarted)
        pipe.stop()
        holder.drainer = nil
    }

    // MARK: - Archive conflicts and budgets

    /// A redelivery whose bytes differ keeps the first bytes under the key and its
    /// own under `<key>-<sha>` as a conflict copy, then completes as a duplicate:
    /// every byte is archived and nothing stays stuck in quarantine.
    func testConflictingRedeliveryIsKeptAsACopyAndArchiveKeepsFirstBytes() throws {
        let rig = try makeRig()
        let first = "{\"session\":\"s1\",\"t\":1}"
        let second = "{\"session\":\"s2\",\"t\":2}"
        try rig.spool.append([record("k", payload: first)])
        try drainer(rig).drainUntilEmpty()
        try rig.spool.append([record("k", payload: second)])
        let outcome = try drainer(rig).drainOnce()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.quarantined, 0)
        XCTAssertEqual(outcome.conflictCopies, 1)
        XCTAssertEqual(outcome.completed, 1)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertTrue(try rig.spool.quarantined(limit: 10).isEmpty)
        let id = try XCTUnwrap(try rig.archive.id(forDedupKey: "k"))
        XCTAssertEqual(try rig.archive.record(id: id)?.record.payload, Data(first.utf8))
        let sha = RawArchive.hex(Data(second.utf8))
        let copyID = try XCTUnwrap(try rig.archive.id(forDedupKey: "k-\(sha)"))
        let copy = try XCTUnwrap(try rig.archive.record(id: copyID)?.record)
        XCTAssertEqual(copy.payload, Data(second.utf8))
        XCTAssertTrue(copy.isConflictCopy)
        XCTAssertEqual(copy.sourceKind, RawRecord.conflictKindPrefix + record("k").sourceKind)
        XCTAssertEqual(try rig.archive.count(), 2)
        XCTAssertEqual(try rig.store.counts().events, 1)

        // The same conflicting bytes again: a duplicate of the copy, no new row.
        try rig.spool.append([record("k", payload: second)])
        XCTAssertEqual(try drainer(rig).drainOnce().completed, 1)
        XCTAssertEqual(try rig.archive.count(), 2)
        // The live store still derives from the archived bytes: a replay rebuilds it exactly.
        let rebuilt = try EventStore(path: tmpDir.appendingPathComponent("replayed.db").path)
        let report = try Replayer.replay(archive: rig.archive, normalizer: TestNormalizer(), into: rebuilt)
        XCTAssertEqual(report.failed, 0)
        XCTAssertEqual(try rebuilt.canonicalDump(), try rig.store.canonicalDump())
    }

    func testEquivalentRedeliveryIsADuplicateNotAConflict() throws {
        let rig = try makeRig()
        let first = "{\"session\":\"s1\",\"t\":1}"
        let pipe = try PipelineDrainer(spool: rig.spool, archive: rig.archive, normalizer: SameTNormalizer(),
                                       store: rig.store)
        try rig.spool.append([record("k", payload: first)])
        pipe.drainUntilEmpty()
        let before = try rig.store.canonicalDump()
        // Same "t", different bytes: the normalizer calls it the same record.
        try rig.spool.append([record("k", payload: "{\"session\":\"s1\",\"t\":1,\"moved\":true}")])
        let outcome = pipe.drainOnce()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.quarantined, 0)
        XCTAssertEqual(outcome.completed, 1)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertTrue(try rig.spool.quarantined(limit: 10).isEmpty)
        XCTAssertEqual(try rig.archive.count(), 1)
        let id = try XCTUnwrap(try rig.archive.id(forDedupKey: "k"))
        XCTAssertEqual(try rig.archive.record(id: id)?.record.payload, Data(first.utf8))
        XCTAssertEqual(try rig.store.canonicalDump(), before)

        // A different "t" under the same key is still a conflict for this normalizer:
        // its bytes are kept as a conflict copy.
        try rig.spool.append([record("k", payload: "{\"session\":\"s1\",\"t\":2}")])
        let conflicted = pipe.drainOnce()
        XCTAssertEqual(conflicted.quarantined, 0)
        XCTAssertEqual(conflicted.conflictCopies, 1)
        XCTAssertEqual(try rig.archive.count(), 2)
        XCTAssertEqual(try rig.store.canonicalDump(), before)
    }

    func testDefaultEquivalenceIsByteEquality() {
        let normalizer = TestNormalizer()
        let base = record("k", payload: "{\"session\":\"s1\",\"t\":1}")
        XCTAssertTrue(normalizer.isEquivalent(archived: base, incoming: base))
        XCTAssertFalse(normalizer.isEquivalent(
            archived: base, incoming: record("k", payload: "{\"session\":\"s1\",\"t\":1,\"moved\":true}")))
    }

    func testRequeuedOldRecordBesideNewOnesReadsOnlyThoseArchiveRows() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<50).map { record("old\($0)") })
        try drainer(rig).drainUntilEmpty()
        let oldID = try XCTUnwrap(try rig.archive.id(forDedupKey: "old0"))
        // The oldest key again (same bytes), next to two new ones.
        try rig.spool.append([record("old0"), record("new0"), record("new1")])
        let seen = LockedBox<[Int64]>([])
        let sink = ClosureSink { _, records in seen.update { $0 += records.map(\.id) } }
        let outcome = try drainer(rig, sinks: [sink]).drainOnce()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.completed, 3)
        let newIDs = try ["new0", "new1"].map { try XCTUnwrap(try rig.archive.id(forDedupKey: $0)) }
        XCTAssertEqual(seen.value, [oldID] + newIDs)
        XCTAssertEqual(try rig.archive.count(), 52)
        XCTAssertEqual(try rig.store.counts().events, 52)
    }

    func testPassRespectsByteBudgetButAlwaysTakesOneRecord() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<4).map { record("k\($0)") })
        let pipe = try drainer(rig, maxBatchBytes: 1)
        let outcome = pipe.drainOnce()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.read, 1)
        XCTAssertEqual(outcome.completed, 1)
        XCTAssertEqual(try rig.spool.pendingCount(), 3)
        pipe.drainUntilEmpty()
        XCTAssertEqual(try rig.store.counts().events, 4)
    }

    // MARK: - Sinks

    func testSinksRunAfterTheStoreCommitAndBeforeCompletion() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<3).map { record("k\($0)") })
        let seen = LockedBox<[(events: Int, pending: Int, records: Int, batchEvents: Int)]>([])
        let sink = ClosureSink { batch, records in
            let events = (try? rig.store.counts().events) ?? -1
            let pending = (try? rig.spool.pendingCount()) ?? -1
            seen.update { $0.append((events, pending, records.count, batch.events.count)) }
        }
        let outcome = try drainer(rig, sinks: [sink]).drainUntilEmpty()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        let calls = seen.value
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.events, 3, "the store write is committed before sinks run")
        XCTAssertEqual(calls.first?.pending, 3, "spool rows are completed only after sinks")
        XCTAssertEqual(calls.first?.records, 3)
        XCTAssertEqual(calls.first?.batchEvents, 3)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
    }

    func testSinkFailureFailsThePassChargesEachRecordAndQuarantinesAtMaxAttempts() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<2).map { record("k\($0)") })
        struct SinkDown: Error {}
        let pipe = try drainer(rig, sinks: [ClosureSink { _, _ in throw SinkDown() }])
        let first = pipe.drainOnce()
        XCTAssertTrue(first.failed)
        XCTAssertTrue(first.failureReason?.contains("SinkDown") ?? false, first.failureReason ?? "")
        XCTAssertEqual(first.completed, 0)
        XCTAssertEqual(try rig.spool.pendingCount(), 2)
        XCTAssertEqual(try rig.spool.pendingBatch(limit: 10).map(\.attempts), [1, 1])
        // The store write already committed and is idempotent; redelivery adds nothing.
        XCTAssertEqual(try rig.store.counts().events, 2)
        for _ in 1..<ProviderSpool.maxAttempts { pipe.drainOnce() }
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        let quarantined = try rig.spool.quarantined(limit: 10)
        XCTAssertEqual(Set(quarantined.map(\.record.dedupKey)), ["k0", "k1"])
        XCTAssertTrue(quarantined.allSatisfy { $0.reason.contains("sink") }, "\(quarantined.map(\.reason))")
        XCTAssertEqual(try rig.store.counts().events, 2)
    }

    func testAfterSinksCrashRedeliversAndConverges() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<5).map { record("k\($0)") })
        let calls = LockedBox(0)
        let sink = ClosureSink { _, records in calls.update { $0 += records.count } }
        struct Boom: Error {}
        let once = FireOnce()
        let crashing = try drainer(rig, sinks: [sink]) { step in
            if step == .afterSinks, once.shouldFire() { throw Boom() }
        }
        XCTAssertTrue(crashing.drainOnce().failed)
        XCTAssertEqual(try rig.spool.pendingCount(), 5)
        XCTAssertFalse(try drainer(rig, sinks: [sink]).drainUntilEmpty().failed)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertEqual(try rig.store.counts().events, 5)
        // At-least-once: the sink saw the batch before the crash and again after it.
        XCTAssertEqual(calls.value, 10)
    }

    // MARK: - Reentrancy and observers

    func testDrainFromInsideOwnPassIsSkipped() throws {
        let rig = try makeRig()
        try rig.spool.append([record("k0")])
        let holder = DrainerBox()
        let inner = LockedBox<DrainOutcome?>(nil)
        let sink = ClosureSink { _, _ in
            let outcome = holder.drainer?.drainOnce()
            inner.update { $0 = outcome }
        }
        let pipe = try drainer(rig, sinks: [sink])
        holder.drainer = pipe
        let outcome = pipe.drainOnce()
        holder.drainer = nil
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.completed, 1)
        let nested = try XCTUnwrap(inner.value)
        XCTAssertTrue(nested.skippedReentrant)
        XCTAssertEqual(nested.read, 0)
    }

    func testObserversRunOutsideThePassAndMayDrainAgain() throws {
        let rig = try makeRig()
        try rig.spool.append([record("k0")])
        let holder = DrainerBox()
        let inner = LockedBox<DrainOutcome?>(nil)
        let second = record("k1")
        let once = FireOnce()
        let observer = RecordingObserver(onStore: {
            // A second record arrives while the observer runs; draining here must neither
            // deadlock nor be treated as reentrant.
            guard once.shouldFire() else { return }
            try? rig.spool.append([second])
            let outcome = holder.drainer?.drainOnce()
            inner.update { $0 = outcome }
        })
        let pipe = try drainer(rig)
        holder.drainer = pipe
        pipe.addObserver(observer)
        pipe.drainOnce()
        holder.drainer = nil
        let nested = try XCTUnwrap(inner.value)
        XCTAssertFalse(nested.skippedReentrant)
        XCTAssertEqual(nested.completed, 1)
        XCTAssertEqual(try rig.store.counts().events, 2)
    }

    func testObserverHearsTheCompletedBatchAsWrittenAndNeverAnEmptyBatch() throws {
        let rig = try makeRig()
        let observer = RecordingObserver()
        let pipe = try drainer(rig)
        pipe.addObserver(observer)
        try rig.spool.append([record("dup")])
        pipe.drainUntilEmpty()
        // The same bytes again: archived as a duplicate and a store no-op, but completed,
        // so observers hear its rows again (at-least-once; they must be idempotent).
        try rig.spool.append([record("dup")])
        let outcome = pipe.drainUntilEmpty()
        XCTAssertEqual(outcome.completed, 1)
        try rig.spool.append([record("dup"), record("new")])
        pipe.drainUntilEmpty()
        // A conflict completes as a duplicate of the first record: observers hear
        // the first record's rows again, never the conflicting bytes'.
        try rig.spool.append([record("dup", payload: "{\"session\":\"s9\",\"t\":9}")])
        let conflicted = pipe.drainUntilEmpty()
        XCTAssertEqual(conflicted.conflictCopies, 1)
        XCTAssertEqual(observer.received.map { $0.events.map(\.dedupKey) },
                       [["dup#0"], ["dup#0"], ["dup#0", "new#0"], ["dup#0"]])
        // A pass that completes nothing notifies no one.
        XCTAssertEqual(pipe.drainUntilEmpty().completed, 0)
        XCTAssertEqual(observer.received.count, 4)
    }

    func testObserverHearsRowsCommittedBeforeASinkFailureWhenTheRetryCompletes() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<2).map { record("k\($0)") })
        struct SinkDown: Error {}
        let once = FireOnce()
        let sink = ClosureSink { _, _ in if once.shouldFire() { throw SinkDown() } }
        let observer = RecordingObserver()
        let pipe = try drainer(rig, sinks: [sink])
        pipe.addObserver(observer)

        let failed = pipe.drainOnce()
        XCTAssertTrue(failed.failed)
        // The rows are committed, but nothing is completed, so nobody has been told yet.
        XCTAssertEqual(try rig.store.counts().events, 2)
        XCTAssertTrue(observer.received.isEmpty)

        let retried = pipe.drainOnce()
        XCTAssertFalse(retried.failed, retried.failureReason ?? "")
        XCTAssertEqual(retried.completed, 2)
        // The retry's store write changed nothing, yet observers hear every row once.
        XCTAssertEqual(observer.received.map { $0.events.map(\.dedupKey) }, [["k0#0", "k1#0"]])
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
    }

    // MARK: - Wiring checks

    func testProviderMismatchIsRefusedAtInit() throws {
        let rig = try makeRig()
        struct OtherNormalizer: Normalizer {
            let provider = "other"
            func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch { NormalizedBatch() }
        }
        XCTAssertThrowsError(try PipelineDrainer(
            spool: rig.spool, archive: rig.archive, normalizer: OtherNormalizer(), store: rig.store)) { error in
            XCTAssertEqual(error as? PipelineError,
                           .providerMismatch(spool: "mock", archive: "mock", normalizer: "other"))
        }
        let otherArchive = try RawArchive(path: tmpDir.appendingPathComponent("other-raw.db").path, provider: "other")
        XCTAssertThrowsError(try PipelineDrainer(
            spool: rig.spool, archive: otherArchive, normalizer: TestNormalizer(), store: rig.store)) { error in
            XCTAssertEqual(error as? PipelineError,
                           .providerMismatch(spool: "mock", archive: "other", normalizer: "mock"))
        }
    }

    func testLiveDrainerBlocksBulkLoadUntilReleased() throws {
        let rig = try makeRig()
        var pipe: PipelineDrainer? = try drainer(rig)
        XCTAssertNotNil(pipe)
        XCTAssertThrowsError(try rig.store.beginBulkLoad()) { error in
            XCTAssertEqual(error as? EventStoreError, .liveWritersAttached(count: 1))
        }
        XCTAssertThrowsError(try Replayer.replay(archive: rig.archive, normalizer: TestNormalizer(), into: rig.store))
        XCTAssertFalse(try rig.store.isInBulkLoad())
        pipe = nil
        try rig.store.beginBulkLoad()
        XCTAssertThrowsError(try drainer(rig)) { error in
            XCTAssertEqual(error as? EventStoreError, .bulkLoadInProgress)
        }
        try rig.store.endBulkLoad()
        XCTAssertNoThrow(try drainer(rig))
    }
}

private struct ClosureSink: PipelineSink {
    let body: @Sendable (NormalizedBatch, [ArchivedRecord]) throws -> Void
    init(_ body: @escaping @Sendable (NormalizedBatch, [ArchivedRecord]) throws -> Void) { self.body = body }
    func write(_ batch: NormalizedBatch, records: [ArchivedRecord], provider: String) throws {
        try body(batch, records)
    }
}

private final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value
    init(_ value: Value) { stored = value }
    var value: Value { lock.lock(); defer { lock.unlock() }; return stored }
    func update(_ change: (inout Value) -> Void) { lock.lock(); change(&stored); lock.unlock() }
}

private final class ElapsedBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Double?
    var value: Double? { lock.lock(); defer { lock.unlock() }; return stored }
    func set(_ seconds: Double) { lock.lock(); stored = seconds; lock.unlock() }
}

private final class DrainerBox: @unchecked Sendable {
    private let lock = NSLock()
    private var held: PipelineDrainer?
    var drainer: PipelineDrainer? {
        get { lock.lock(); defer { lock.unlock() }; return held }
        set { lock.lock(); held = newValue; lock.unlock() }
    }
}
