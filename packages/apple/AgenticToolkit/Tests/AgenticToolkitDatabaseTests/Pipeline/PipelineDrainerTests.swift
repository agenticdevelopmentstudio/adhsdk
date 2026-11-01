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

    private func drainer(_ rig: Rig, batchSize: Int = 200,
                         inject: (@Sendable (DrainStep) throws -> Void)? = nil) -> PipelineDrainer {
        PipelineDrainer(spool: rig.spool, archive: rig.archive, normalizer: TestNormalizer(),
                        store: rig.store, batchSize: batchSize, faultInjector: inject)
    }

    private func record(_ key: String, payload: String? = nil) -> RawRecord {
        RawRecord(provider: "mock", sourceKind: "hook", dedupKey: key,
                  receivedAt: Date(timeIntervalSince1970: 1_800_000_000),
                  payload: Data((payload ?? "{\"session\":\"s1\",\"t\":1}").utf8))
    }

    func testDrainArchivesStoresAndCompletes() throws {
        let rig = try makeRig()
        try rig.spool.append((0..<10).map { record("k\($0)") })
        let outcome = drainer(rig).drainUntilEmpty()
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
            let crashing = drainer(rig) { current in
                if current == step, once.shouldFire() { throw Boom() }
            }
            XCTAssertTrue(crashing.drainOnce().failed, "step \(step)")

            let clean = drainer(rig).drainUntilEmpty()
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
        let pipe = drainer(rig)
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
        let outcome = drainer(rig).drainOnce()
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(try rig.store.counts().events, 5)
        XCTAssertEqual(try rig.spool.pendingCount(), 1)
    }

    func testRedeliveredRecordIsCollapsed() throws {
        let rig = try makeRig()
        try rig.spool.append([record("dup")])
        try rig.spool.append([record("dup")])
        drainer(rig).drainUntilEmpty()
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
        let pipe = drainer(rig)
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

        let failed = drainer(rig).drainOnce()
        XCTAssertTrue(failed.failed)
        XCTAssertNotNil(failed.failureReason)
        XCTAssertEqual(failed.completed, 0)
        XCTAssertEqual(try rig.spool.pendingCount(), 6)
        XCTAssertEqual(try rig.archive.count(), 6)

        try saboteur.write { try $0.execute(sql: "ALTER TABLE events_hidden RENAME TO events") }
        let recovered = drainer(rig).drainUntilEmpty()
        XCTAssertFalse(recovered.failed)
        XCTAssertEqual(try rig.store.counts().events, 6)
        XCTAssertEqual(try rig.spool.pendingCount(), 0)
        XCTAssertEqual(try rig.archive.count(), 6)
    }

    func testDrainUntilEmptyStopsWithoutProgressAndDoesNotBurnAttempts() throws {
        let rig = try makeRig()
        try rig.spool.append([record("flaky")])
        let pipe = PipelineDrainer(spool: rig.spool, archive: rig.archive,
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
        let pipe = drainer(rig)
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
        let pipe = drainer(rig)
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
        let pipe = drainer(rig)
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
