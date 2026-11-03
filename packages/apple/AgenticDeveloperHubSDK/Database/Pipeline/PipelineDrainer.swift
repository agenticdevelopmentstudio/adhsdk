import Foundation

/// The points in a drain pass where a test can inject a failure.
public enum DrainStep: String, Sendable, CaseIterable {
    case afterRead, afterArchive, afterNormalize, afterStore, afterSinks, afterComplete
}

public enum PipelineError: Error, Equatable {
    /// The spool, the archive and the normalizer must all name the same provider.
    case providerMismatch(spool: String, archive: String, normalizer: String)
    /// A replay source's normalizer names another provider than its archive.
    case normalizerMismatch(archive: String, normalizer: String)
    /// Two replay sources name the same provider.
    case duplicateProvider(String)
}

public struct DrainOutcome: Sendable, Equatable {
    public var read = 0
    public var archived = 0
    public var stored = 0
    public var quarantined = 0
    /// Records whose key the archive already held with other bytes: their bytes
    /// were kept as a conflict copy (``RawRecord/conflictCopy(sha256:)``) and the
    /// record then completed as a duplicate of the first.
    public var conflictCopies = 0
    public var completed = 0
    /// True when the pass stopped early on an error.
    public var failed = false
    /// Why the pass stopped early (the thrown error's description); nil unless `failed`.
    public var failureReason: String?
    /// True when `drainOnce` was called from inside this drainer's own pass (from a
    /// normalizer, a sink or a fault injector) and so did nothing.
    public var skippedReentrant = false

    public init() {}
}

public protocol PipelineObserver: AnyObject, Sendable {
    /// Called after a pass that completed records, outside every lock and
    /// transaction, with the normalized batch as written for exactly those records:
    /// every row they produced, including rows the store already held (a retry after
    /// a sink or `complete` failure, a redelivered record). Never called with an
    /// empty batch, and never for records the pass did not complete.
    ///
    /// Delivery is at-least-once on errors (a record whose pass failed after its
    /// store write is reported by the pass that finally completes it, and a
    /// redelivery is reported again) and at-most-once on crashes (a crash between
    /// `complete` and the notification loses it). Observers must be idempotent, and
    /// one that must never miss a row should resync from the store.
    func pipelineDidStore(_ batch: NormalizedBatch, provider: String)
}

/// A second destination the drainer writes to on every pass (the "write to both"
/// backup during cutover). Sinks run after the events.db commit and before the
/// spool rows are completed, with the pass's full normalized batch and the archived
/// records it came from, so a sink sees every record at least once. A sink that
/// throws fails the pass: the spool rows stay, each is charged one failed attempt,
/// and it is retried on the next pass (a record that reaches
/// `ProviderSpool.maxAttempts` is quarantined, bytes kept). Sinks must therefore be
/// idempotent.
///
/// A sink outage therefore quarantines records: `maxAttempts` failed passes (which
/// can be seconds when sources keep waking the drainer) move the whole batch to
/// quarantine. Those records are already archived and in events.db; once the sink
/// is back, `ProviderSpool.requeueQuarantined` sends them through again, and the
/// pass reads only their archive rows (`RawArchive.records(ids:)`).
public protocol PipelineSink: Sendable {
    func write(_ batch: NormalizedBatch, records: [ArchivedRecord], provider: String) throws
}

/// The live path: spool -> raw archive -> normalize -> events.db -> sinks -> complete.
/// A spool row is only completed after its record is in the archive and its
/// normalized rows are committed, so a crash at any step loses nothing and the
/// next pass converges (every write is idempotent).
///
/// **Durability ordering.** The archive, events.db and the spool all run
/// `synchronous=FULL`, so each commit is on disk before the next step starts:
/// the archive commit precedes normalization, the events.db commit precedes the
/// sinks, and those precede `complete`. A power loss can therefore only lose the
/// steps after the last durable commit, and every one of those is redone by the
/// next pass, because the spool row is still there. There is no window in which a
/// completed record is missing from events.db, so no watermark or catch-up scan is
/// needed.
///
/// Normalization reads the **archived** copy, never the spool copy, so events.db
/// always derives from the bytes a replay will see. A record whose key is already
/// archived with different bytes (`ArchiveAppendOutcome.conflict`) is quarantined
/// with its payload, never completed, unless `Normalizer.isEquivalent` says it is
/// the same record, in which case it is completed as an ordinary duplicate.
///
/// **Reentrancy.** `drainOnce` called on the thread that is running this
/// drainer's pass (from a normalizer, a sink or a fault injector) does not wait
/// for the pass it is inside; it returns at once with `skippedReentrant` set.
/// Observers run after the pass has released its lock, so an observer may call
/// `drainOnce` or `drainUntilEmpty` freely.
///
/// **Failure accounting.** A record that fails to normalize, a record whose store
/// write fails, and every record of a pass whose sink fails is charged one attempt,
/// and quarantined (bytes kept) at `ProviderSpool.maxAttempts`. When a batch's store
/// write fails, the drainer writes its records one at a time and charges only the
/// ones that still fail, so one unstorable record cannot block the spool or take
/// the rest of its batch with it. An archive or spool error is not charged: the
/// pass fails and is retried as is.
///
/// Observers hear, after each pass that completes records, the batch as written
/// for those records: at-least-once on errors, at-most-once on crashes
/// (`PipelineObserver`). They must be idempotent.
///
/// The drainer registers with the store as a live writer for its lifetime, so
/// a replay cannot start a bulk load under it.
public final class PipelineDrainer: @unchecked Sendable {
    private struct StepFailure: Error, CustomStringConvertible {
        let description: String
    }

    /// Prefix of a quarantine reason written when a sink failed.
    public static let sinkFailurePrefix = "sink "
    /// Prefix of a quarantine reason written when the events.db write failed.
    public static let storeFailurePrefix = "store write failed: "
    /// Quarantine reasons that name a destination outage rather than the record
    /// itself (invalid JSON, an archive conflict): those records are already in the
    /// archive and worth sending through again once the destination is back.
    public static let transientFailurePrefixes = [sinkFailurePrefix, storeFailurePrefix]

    private final class WeakObserver {
        weak var observer: (any PipelineObserver)?
        init(_ observer: any PipelineObserver) { self.observer = observer }
    }

    private let spool: ProviderSpool
    private let archive: RawArchive
    private let normalizer: any Normalizer
    private let store: EventStore
    private let batchSize: Int
    private let maxBatchBytes: Int
    private let sinks: [any PipelineSink]
    private let faultInjector: (@Sendable (DrainStep) throws -> Void)?

    private let lock = NSLock()
    private var observers: [WeakObserver] = []
    private var thread: Thread?
    private var stopRequested = false
    private var finished: DispatchSemaphore?
    private let wakeSignal = DispatchSemaphore(value: 0)
    /// Serializes passes so a manual drain never interleaves with the thread's.
    private let passLock = NSLock()
    /// The thread running a pass right now (guarded by `lock`).
    private var passOwner: Thread?

    /// Throws `PipelineError.providerMismatch` unless the spool, the archive and the
    /// normalizer name the same provider, and `EventStoreError.bulkLoadInProgress`
    /// while a replay holds the store.
    public init(spool: ProviderSpool, archive: RawArchive, normalizer: any Normalizer,
                store: EventStore, batchSize: Int = 200,
                maxBatchBytes: Int = PipelineLimits.defaultMaxBatchBytes,
                sinks: [any PipelineSink] = [],
                faultInjector: (@Sendable (DrainStep) throws -> Void)? = nil) throws {
        guard spool.provider == archive.provider, archive.provider == normalizer.provider else {
            throw PipelineError.providerMismatch(
                spool: spool.provider, archive: archive.provider, normalizer: normalizer.provider)
        }
        try store.attachLiveWriter()
        self.spool = spool
        self.archive = archive
        self.normalizer = normalizer
        self.store = store
        self.batchSize = batchSize
        self.maxBatchBytes = maxBatchBytes
        self.sinks = sinks
        self.faultInjector = faultInjector
    }

    /// Held weakly.
    public func addObserver(_ observer: any PipelineObserver) {
        lock.lock(); defer { lock.unlock() }
        observers.removeAll { $0.observer == nil }
        observers.append(WeakObserver(observer))
    }

    /// One pass. Never throws: errors leave the spool rows in place and set `failed`.
    /// Called from inside this drainer's own pass it does nothing and returns an
    /// outcome with `skippedReentrant` set.
    @discardableResult
    public func drainOnce() -> DrainOutcome {
        lock.lock()
        let reentrant = passOwner === Thread.current
        lock.unlock()
        if reentrant {
            var skipped = DrainOutcome()
            skipped.skippedReentrant = true
            return skipped
        }

        var outcome = DrainOutcome()
        var written = NormalizedBatch()
        passLock.lock()
        lock.lock(); passOwner = Thread.current; lock.unlock()
        do {
            written = try pass(&outcome)
        } catch {
            outcome.failed = true
            outcome.failureReason = String(describing: error)
        }
        lock.lock(); passOwner = nil; lock.unlock()
        passLock.unlock()

        if !written.isEmpty {
            lock.lock()
            observers.removeAll { $0.observer == nil }
            let live = observers.compactMap(\.observer)
            lock.unlock()
            for observer in live { observer.pipelineDidStore(written, provider: normalizer.provider) }
        }
        return outcome
    }

    /// Drains until the spool is empty, a pass fails, or a pass makes no progress
    /// (nothing completed and nothing quarantined). The last rule stops a record
    /// that keeps failing from burning all its attempts in one call; it is retried
    /// on the next call or wake instead.
    @discardableResult
    public func drainUntilEmpty() -> DrainOutcome {
        var total = DrainOutcome()
        while true {
            let one = drainOnce()
            total.read += one.read
            total.archived += one.archived
            total.stored += one.stored
            total.quarantined += one.quarantined
            total.conflictCopies += one.conflictCopies
            total.completed += one.completed
            if one.skippedReentrant { total.skippedReentrant = true }
            if one.failed {
                total.failed = true
                total.failureReason = one.failureReason
                return total
            }
            if one.read == 0 || (one.completed == 0 && one.quarantined == 0) { return total }
        }
    }

    private func inject(_ step: DrainStep) throws {
        do { try faultInjector?(step) } catch {
            throw StepFailure(description: "fault injected \(step.rawValue): \(error)")
        }
    }

    /// Charges one failed attempt; quarantines the record when attempts run out.
    private func charge(_ spooled: SpooledRecord, reason: String, _ outcome: inout DrainOutcome) throws {
        if try spool.recordFailure(id: spooled.id, reason: reason) {
            try spool.quarantine(id: spooled.id, reason: reason)
            outcome.quarantined += 1
        }
    }

    /// Asks the normalizer whether `incoming` is the same record as archive row `id`.
    /// A row that cannot be read (corrupt or missing) is not equivalent, so the
    /// incoming bytes are quarantined rather than dropped.
    private func isEquivalentToArchived(_ id: Int64, _ incoming: RawRecord) throws -> Bool {
        let archived: ArchivedRecord?
        do {
            archived = try archive.record(id: id)
        } catch is RawArchiveError {
            return false
        }
        guard let archived else { return false }
        return normalizer.isEquivalent(archived: archived.record, incoming: incoming)
    }

    /// The archived copies, by id. A corrupt row is missing from the result (its
    /// spool record is charged a failure by the caller).
    private func readArchived(_ ids: [Int64]) throws -> [Int64: Result<ArchivedRecord, Error>] {
        var result: [Int64: Result<ArchivedRecord, Error>] = [:]
        do {
            for archived in try archive.records(ids: ids) { result[archived.id] = .success(archived) }
        } catch RawArchiveError.corruptPayload {
            for id in ids {
                do {
                    if let archived = try archive.record(id: id) { result[id] = .success(archived) }
                } catch let error as RawArchiveError {
                    result[id] = .failure(error)
                }
            }
        }
        return result
    }

    /// Returns the normalized batch for the records this pass completed, for the
    /// observers (empty when it completed nothing).
    private func pass(_ outcome: inout DrainOutcome) throws -> NormalizedBatch {
        let pending = try spool.pendingBatch(limit: batchSize, maxBytes: maxBatchBytes)
        guard !pending.isEmpty else { return NormalizedBatch() }
        outcome.read = pending.count
        try inject(.afterRead)

        // Nothing is ever completed before it is in the archive.
        let appended = try archive.append(pending.map(\.record))
        guard appended.outcomes.count == pending.count else {
            throw StepFailure(
                description: "archive returned \(appended.outcomes.count) outcomes for \(pending.count) records")
        }
        var accepted: [(spooled: SpooledRecord, archiveID: Int64)] = []
        for (spooled, result) in zip(pending, appended.outcomes) {
            switch result {
            case .inserted(let id), .duplicate(let id):
                accepted.append((spooled, id))
            case .conflict(let existingID, let archivedSHA, let incomingSHA):
                // The provider may define these bytes as the same record (e.g. a
                // transcript line that moved): then it is an ordinary duplicate and
                // the archived first record stands.
                if try isEquivalentToArchived(existingID, spooled.record) {
                    accepted.append((spooled, existingID))
                    continue
                }
                // The archive keeps the first bytes under the key. These differ:
                // keep them too, as a conflict copy under `<key>-<sha>`, then treat
                // the record as a duplicate of the first, so no byte is lost and
                // nothing stays stuck in quarantine. Only if even that key holds
                // other bytes (a sha collision) is it quarantined.
                let copy = try archive.append([spooled.record.conflictCopy(sha256: incomingSHA)])
                if case .conflict? = copy.outcomes.first {
                    try spool.quarantine(
                        id: spooled.id,
                        reason: "dedup-key conflict: archived sha \(archivedSHA) vs incoming sha \(incomingSHA)")
                    outcome.quarantined += 1
                    continue
                }
                outcome.conflictCopies += 1
                accepted.append((spooled, existingID))
            }
        }
        outcome.archived = accepted.count
        try inject(.afterArchive)

        // Normalize the archived copy: events.db derives from the bytes replay sees.
        let archivedCopies = try readArchived(accepted.map(\.archiveID))
        var merged = NormalizedBatch()
        var normalizedIDs: [Int64] = []
        var normalizedRecords: [ArchivedRecord] = []
        var normalizedSpooled: [SpooledRecord] = []
        var normalizedBatches: [NormalizedBatch] = []
        for (spooled, archiveID) in accepted {
            do {
                guard let copy = archivedCopies[archiveID] else {
                    throw StepFailure(description: "archive row \(archiveID) missing after append")
                }
                let archived = try copy.get()
                let batch = try normalizer.normalize(archived)
                merged.append(batch)
                normalizedIDs.append(spooled.id)
                normalizedRecords.append(archived)
                normalizedSpooled.append(spooled)
                normalizedBatches.append(batch)
            } catch {
                try charge(spooled, reason: String(describing: error), &outcome)
            }
        }
        try inject(.afterNormalize)

        do {
            _ = try store.write(merged, provider: normalizer.provider)
        } catch {
            let kept = try isolateStoreFailure(
                error, Array(zip(normalizedSpooled, zip(normalizedRecords, normalizedBatches))), &outcome)
            normalizedSpooled = kept.map(\.spooled)
            normalizedRecords = kept.map(\.archived)
            normalizedIDs = normalizedSpooled.map(\.id)
            merged = NormalizedBatch()
            for item in kept { merged.append(item.batch) }
        }
        outcome.stored = normalizedIDs.count
        try inject(.afterStore)

        for sink in sinks {
            do {
                try sink.write(merged, records: normalizedRecords, provider: normalizer.provider)
            } catch {
                let reason = "\(Self.sinkFailurePrefix)\(type(of: sink)) failed: \(error)"
                for spooled in normalizedSpooled { try charge(spooled, reason: reason, &outcome) }
                throw StepFailure(description: reason)
            }
        }
        try inject(.afterSinks)

        try spool.complete(ids: normalizedIDs)
        outcome.completed = normalizedIDs.count
        try inject(.afterComplete)
        return merged
    }

    /// After a failed batch write: writes each record's rows on its own, charges the
    /// records that still fail, and returns the ones that are now stored. Throws the
    /// original failure when nothing could be stored.
    private func isolateStoreFailure(
        _ batchError: Error, _ items: [(SpooledRecord, (ArchivedRecord, NormalizedBatch))],
        _ outcome: inout DrainOutcome
    ) throws -> [(spooled: SpooledRecord, archived: ArchivedRecord, batch: NormalizedBatch)] {
        var kept: [(spooled: SpooledRecord, archived: ArchivedRecord, batch: NormalizedBatch)] = []
        for (item, (archived, batch)) in items {
            do {
                _ = try store.write(batch, provider: normalizer.provider)
                kept.append((item, archived, batch))
            } catch {
                try charge(item, reason: "\(Self.storeFailurePrefix)\(error)", &outcome)
            }
        }
        if kept.isEmpty { throw StepFailure(description: "store write failed: \(batchError)") }
        return kept
    }

    // MARK: - Background thread

    /// Starts the worker. Returns false, starting nothing, if a previous worker is
    /// still alive (running, or asked to stop but not yet exited): a second worker
    /// is never spawned.
    @discardableResult
    public func start(idlePoll: TimeInterval = 5) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard thread == nil else { return false }
        stopRequested = false
        let done = DispatchSemaphore(value: 0)
        finished = done
        let signal = wakeSignal
        let worker = Thread { [weak self] in
            // Hold self only for the duration of a pass, so a dropped drainer can deallocate.
            while Self.passIfRunning(self) {
                _ = signal.wait(timeout: .now() + idlePoll)
            }
            self?.workerDidExit()
            done.signal()
        }
        worker.name = "PipelineDrainer.\(normalizer.provider)"
        worker.qualityOfService = .utility
        thread = worker
        worker.start()
        return true
    }

    public func wake() {
        wakeSignal.signal()
    }

    /// Asks the worker to stop and waits up to 5 s for it to exit. Called from the
    /// worker thread itself (for example inside an observer) it only requests the
    /// stop and returns. If the wait times out the worker is still alive and
    /// `start()` refuses until it has exited.
    public func stop() {
        lock.lock()
        guard let worker = thread else { lock.unlock(); return }
        stopRequested = true
        let done = finished
        let onWorker = Thread.current === worker
        lock.unlock()
        wakeSignal.signal()
        if !onWorker { _ = done?.wait(timeout: .now() + 5) }
    }

    deinit {
        // The worker holds no strong reference; make it exit promptly.
        lock.lock(); stopRequested = true; lock.unlock()
        wakeSignal.signal()
        store.detachLiveWriter()
    }

    private func shouldStop() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return stopRequested
    }

    private func workerDidExit() {
        lock.lock(); defer { lock.unlock() }
        if thread === Thread.current {
            thread = nil
            finished = nil
        }
    }

    /// One drain-until-empty if the drainer is alive and not asked to stop.
    private static func passIfRunning(_ drainer: PipelineDrainer?) -> Bool {
        guard let drainer, !drainer.shouldStop() else { return false }
        drainer.drainUntilEmpty()
        return !drainer.shouldStop()
    }
}
