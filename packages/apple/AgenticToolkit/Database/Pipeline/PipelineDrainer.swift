import Foundation

/// The points in a drain pass where a test can inject a failure.
public enum DrainStep: String, Sendable, CaseIterable {
    case afterRead, afterArchive, afterNormalize, afterStore, afterComplete
}

public struct DrainOutcome: Sendable, Equatable {
    public var read = 0
    public var archived = 0
    public var stored = 0
    public var quarantined = 0
    public var completed = 0
    /// True when the pass stopped early on an error.
    public var failed = false

    public init() {}
}

public protocol PipelineObserver: AnyObject, Sendable {
    /// Called after the store commit, with what this pass wrote. Never inside a transaction.
    func pipelineDidStore(_ batch: NormalizedBatch, provider: String)
}

/// The live path: spool -> raw archive -> normalize -> events.db -> complete.
/// A spool row is only completed after its record is in the archive and its
/// normalized rows are committed, so a crash at any step loses nothing and the
/// next pass converges (every write is idempotent).
public final class PipelineDrainer: @unchecked Sendable {
    private struct StepFailure: Error {}

    private final class WeakObserver {
        weak var observer: (any PipelineObserver)?
        init(_ observer: any PipelineObserver) { self.observer = observer }
    }

    private let spool: ProviderSpool
    private let archive: RawArchive
    private let normalizer: any Normalizer
    private let store: EventStore
    private let batchSize: Int
    private let faultInjector: (@Sendable (DrainStep) throws -> Void)?

    private let lock = NSLock()
    private var observers: [WeakObserver] = []
    private var thread: Thread?
    private var stopRequested = false
    private var wakeRequested = false
    private var finished: DispatchSemaphore?
    private let wakeSignal = DispatchSemaphore(value: 0)
    /// Serializes passes so a manual drain never interleaves with the thread's.
    private let passLock = NSLock()

    public init(spool: ProviderSpool, archive: RawArchive, normalizer: any Normalizer,
                store: EventStore, batchSize: Int = 200,
                faultInjector: (@Sendable (DrainStep) throws -> Void)? = nil) {
        self.spool = spool
        self.archive = archive
        self.normalizer = normalizer
        self.store = store
        self.batchSize = batchSize
        self.faultInjector = faultInjector
    }

    /// Held weakly.
    public func addObserver(_ observer: any PipelineObserver) {
        lock.lock(); defer { lock.unlock() }
        observers.removeAll { $0.observer == nil }
        observers.append(WeakObserver(observer))
    }

    /// One pass. Never throws: errors leave the spool rows in place and set `failed`.
    @discardableResult
    public func drainOnce() -> DrainOutcome {
        passLock.lock(); defer { passLock.unlock() }
        var outcome = DrainOutcome()
        do {
            try pass(&outcome)
        } catch {
            outcome.failed = true
        }
        return outcome
    }

    /// Drains until the spool is empty or a pass fails.
    @discardableResult
    public func drainUntilEmpty() -> DrainOutcome {
        var total = DrainOutcome()
        while true {
            let one = drainOnce()
            total.read += one.read
            total.archived += one.archived
            total.stored += one.stored
            total.quarantined += one.quarantined
            total.completed += one.completed
            if one.failed { total.failed = true; return total }
            if one.read == 0 { return total }
        }
    }

    private func inject(_ step: DrainStep) throws {
        do { try faultInjector?(step) } catch { throw StepFailure() }
    }

    private func pass(_ outcome: inout DrainOutcome) throws {
        let pending = try spool.pendingBatch(limit: batchSize)
        guard !pending.isEmpty else { return }
        outcome.read = pending.count
        try inject(.afterRead)

        // Nothing is ever completed before it is in the archive.
        let appended = try archive.append(pending.map(\.record))
        guard appended.ids.count == pending.count else { throw StepFailure() }
        outcome.archived = pending.count
        try inject(.afterArchive)

        var merged = NormalizedBatch()
        var normalizedIDs: [Int64] = []
        for (spooled, archivedID) in zip(pending, appended.ids) {
            do {
                let batch = try normalizer.normalize(ArchivedRecord(id: archivedID, record: spooled.record))
                merged.append(batch)
                normalizedIDs.append(spooled.id)
            } catch {
                let reason = String(describing: error)
                let exhausted = try spool.recordFailure(id: spooled.id, reason: reason)
                if exhausted {
                    try spool.quarantine(id: spooled.id, reason: reason)
                    outcome.quarantined += 1
                }
            }
        }
        try inject(.afterNormalize)

        try store.write(merged, provider: normalizer.provider)
        outcome.stored = normalizedIDs.count
        try inject(.afterStore)

        try spool.complete(ids: normalizedIDs)
        outcome.completed = normalizedIDs.count
        try inject(.afterComplete)

        lock.lock()
        observers.removeAll { $0.observer == nil }
        let live = observers.compactMap(\.observer)
        lock.unlock()
        for observer in live { observer.pipelineDidStore(merged, provider: normalizer.provider) }
    }

    // MARK: - Background thread

    public func start(idlePoll: TimeInterval = 5) {
        lock.lock(); defer { lock.unlock() }
        guard thread == nil else { return }
        stopRequested = false
        let done = DispatchSemaphore(value: 0)
        finished = done
        let worker = Thread { [weak self] in
            self?.run(idlePoll: idlePoll)
            done.signal()
        }
        worker.name = "PipelineDrainer.\(normalizer.provider)"
        worker.qualityOfService = .utility
        thread = worker
        worker.start()
    }

    public func wake() {
        lock.lock()
        wakeRequested = true
        lock.unlock()
        wakeSignal.signal()
    }

    /// Joins the thread, waiting up to 5 s.
    public func stop() {
        lock.lock()
        guard thread != nil else { lock.unlock(); return }
        stopRequested = true
        let done = finished
        lock.unlock()
        wakeSignal.signal()
        _ = done?.wait(timeout: .now() + 5)
        lock.lock()
        thread = nil
        finished = nil
        lock.unlock()
    }

    private func shouldStop() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return stopRequested
    }

    private func run(idlePoll: TimeInterval) {
        while !shouldStop() {
            let outcome = drainUntilEmpty()
            if shouldStop() { return }
            // After a failed pass, back off to the poll interval rather than spin.
            _ = outcome
            _ = wakeSignal.wait(timeout: .now() + idlePoll)
        }
    }
}
