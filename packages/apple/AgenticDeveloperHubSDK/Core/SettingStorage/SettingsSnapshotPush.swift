import Foundation
import OSLog

/// Mirrors a group of settings into another process: on any change, at
/// startup, and on every reconnect, the whole idempotent snapshot is sent.
///
/// A full snapshot rather than a delta, so a receiver that was down for one of
/// the changes is corrected by the next push rather than staying
/// half-configured. A newer push supersedes one still retrying, so a stale body
/// can never land after a fresh one. The reconnect handler is registered once
/// per instance, and is inert while the push is stopped.
///
/// **A reconnect never restarts a push in flight, and backs off after
/// failures.** While the receiver's service is missing, every failed attempt
/// drops the connection and the next attempt's new connection fires the
/// reconnect handler; restarting the push there would cancel the bounded retry
/// before it gives up, forever (review F11). So a reconnect while a push is
/// running is ignored — that push already carries the current snapshot — and a
/// reconnect after consecutive failed pushes waits ``reconnectDelay``, which
/// grows with each failure. A change still pushes at once: the user asked.
///
/// **An undelivered push re-tries itself.** A bounded push that gives up while
/// observing schedules its own re-push after ``reconnectDelay`` (review N3),
/// rather than waiting for some other call to open a new connection — a
/// connection the app may not touch for a long time, leaving a change made
/// while the receiver was down unapplied. A newer push or ``stop()`` cancels
/// it; a reconnect while it waits is ignored, since it is already coming.
///
/// **Seeding before the first push.** A push whose local store is new to the
/// receiver (a fresh app taking over settings the receiver already holds) would
/// overwrite the receiver's values with compile-time defaults. A caller may
/// therefore pass a `seed` step: it runs before the observers are installed and
/// before the first push, and returns true once the local store holds the
/// receiver's current values (or needs no seeding), false when the receiver
/// could not be reached. On false nothing is observed or pushed; the next
/// reconnect retries the seed and then completes the start. Observers are
/// installed only after seeding, so writing the seeded values pushes nothing.
///
/// **A failed seed retries itself.** A receiver that is down at launch never
/// reports a "reconnect" (its connection was never up), so waiting for one would
/// leave the start incomplete indefinitely. A failed seed therefore schedules its
/// own retry after ``reconnectDelay``, which grows with each consecutive failure
/// up to its cap; ``stop()`` cancels it. A reconnect while a seed is waiting to
/// retry retries it at once; a reconnect while a seed is in flight is dropped,
/// because that seed's own failure branch schedules the retry. ``push()`` does
/// nothing until the seed completes (completing it always pushes the then-current
/// snapshot), so no caller can send local values ahead of the receiver's.
///
/// **When the receiver owns the values (`pull`).** Some settings can be
/// changed at the receiver by other means (a CLI, an HTTP call), so pushing
/// the local copy at startup or on a reconnect would undo those changes. A
/// caller that passes `pull` declares the receiver the source of truth: the
/// start, every reconnect and every ``refresh()`` read the receiver's values
/// into the local store instead of pushing, and only a local change pushes.
/// The observers are installed at once, before the first read, so a change
/// the user makes before the receiver has ever been reached is pushed (and
/// retried until it lands) like any other. The local store is written only
/// while no local change is still on its way (in flight, waiting to retry,
/// or made while the read was out, the first read included), so a choice the
/// user made while the receiver was down still lands. A local value equal to
/// what the receiver was last known to hold is not sent.
///
/// **A refused change is not the receiver's value.** A `deliver` step can
/// tell a refusal (the receiver answered and kept its own values) from a
/// delivery that did not arrive: a refusal is not retried, is not recorded as
/// what the receiver holds, and in receiver-owned mode is followed by a read,
/// so the local store goes back to the receiver's values.
///
/// What the snapshot holds, how it is encoded and how it travels are the
/// caller's; the engine — observe, snapshot, supersede, bounded retry,
/// re-push on reconnect — is this one copy.
@MainActor
public final class SettingsSnapshotPush {

    /// Builds the body to send, or nil when it can't be built (logged, not sent).
    public typealias Snapshot = @MainActor () -> Data?
    /// Sends one body; true when the receiver took it.
    public typealias Send = @Sendable (Data) async -> Bool
    /// What became of one attempt to send a body.
    public enum Delivery: Sendable, Equatable {
        /// The receiver took it.
        case taken
        /// The receiver answered and kept its own values: not retried.
        case refused
        /// It did not arrive: retried.
        case unreached
    }
    /// Sends one body and says what became of it.
    public typealias Deliver = @Sendable (Data) async -> Delivery
    /// Brings the local store up to the receiver's current values before the
    /// first push; true when done (or not needed), false when the receiver
    /// could not be reached.
    public typealias Seed = @MainActor () async -> Bool
    /// Registers a handler to run on every reconnect.
    public typealias RegisterReconnect = (@escaping @Sendable () -> Void) -> Void
    /// Nanoseconds a reconnect waits before pushing, given how many pushes in a
    /// row have failed (always at least 1 when asked).
    public typealias ReconnectDelay = @Sendable (_ consecutiveFailures: Int) -> UInt64
    /// Reads the receiver's current values. Returns the step that writes them
    /// into the local store, or nil when the receiver could not be reached.
    public typealias Pull = @MainActor () async -> (@MainActor () -> Void)?

    private let label: String
    private let logger: Logger
    private let snapshot: Snapshot
    private let sendBody: Deliver
    private let registerReconnect: RegisterReconnect
    private let backoffs: [UInt64]
    private let reconnectDelay: ReconnectDelay
    private let seed: Seed?
    private let pull: Pull?
    /// The body the receiver was last known to hold (receiver-owned mode).
    private var receiverBody: Data?
    private var refreshTask: Task<Void, Never>?

    private var observers: [AnyObject] = []
    private var observing = false
    private var reconnectInstalled = false
    private var pushTask: Task<Void, Never>?
    /// Bumped by every push, so a superseded push's ending is ignored.
    private var generation = 0
    private var inFlight = false
    private var failures = 0
    private var delayedReconnect: Task<Void, Never>?
    /// Builds the observers; held back, unbuilt, until the seed succeeds.
    private var pendingObservers: (@MainActor () -> [AnyObject])?
    private var seedTask: Task<Void, Never>?
    /// Bumped by every seed attempt and by ``stop()``, so a stale seed's ending is ignored.
    private var seedGeneration = 0
    /// Consecutive failed seeds, which sets how long the next retry waits.
    private var seedFailures = 0
    /// Receiver-owned mode: the first read of the receiver has not succeeded yet.
    private var awaitingFirstPull = false
    /// The wait before a failed seed's own retry.
    private var seedRetry: Task<Void, Never>?

    /// - Parameters:
    ///   - label: names the channel in log lines ("Billing prefs").
    ///   - backoffs: nanoseconds to wait before each attempt; the default
    ///     tries at once, then after 0.5 s and 1.5 s.
    ///   - reconnectDelay: how long a reconnect after failed pushes waits; the
    ///     default doubles from 1 s to a 30 s cap.
    ///   - seed: optional step run before the first push (see the type's
    ///     "Seeding" note); nil starts pushing at once.
    ///   - pull: makes the receiver the owner of the values (see the type's
    ///     "When the receiver owns the values" note); replaces `seed`.
    public convenience init(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = BoundedPush.defaultBackoffs,
        reconnectDelay: @escaping ReconnectDelay = SettingsSnapshotPush.defaultReconnectDelay,
        snapshot: @escaping Snapshot,
        send: @escaping Send,
        registerReconnect: @escaping RegisterReconnect,
        seed: Seed? = nil,
        pull: Pull? = nil
    ) {
        self.init(
            label: label, logger: logger, backoffs: backoffs, reconnectDelay: reconnectDelay,
            snapshot: snapshot, deliver: { await send($0) ? .taken : .unreached },
            registerReconnect: registerReconnect, seed: seed, pull: pull)
    }

    /// The same, with a `deliver` step that can report a refusal (see the
    /// type's "A refused change" note).
    public init(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = BoundedPush.defaultBackoffs,
        reconnectDelay: @escaping ReconnectDelay = SettingsSnapshotPush.defaultReconnectDelay,
        snapshot: @escaping Snapshot,
        deliver: @escaping Deliver,
        registerReconnect: @escaping RegisterReconnect,
        seed: Seed? = nil,
        pull: Pull? = nil
    ) {
        precondition(seed == nil || pull == nil, "pass seed or pull, not both")
        self.label = label
        self.logger = logger
        self.backoffs = backoffs
        self.reconnectDelay = reconnectDelay
        self.snapshot = snapshot
        self.sendBody = deliver
        self.registerReconnect = registerReconnect
        self.pull = pull
        self.seed = seed
    }

    /// Whether the receiver owns the values (a `pull` was given).
    private var receiverOwns: Bool { pull != nil }

    /// 1 s after one failed push, doubling per further failure, capped at 30 s.
    public static let defaultReconnectDelay: ReconnectDelay = { failures in
        let seconds = min(30, 1 << min(max(failures - 1, 0), 5))
        return UInt64(seconds) * 1_000_000_000
    }

    /// Pushes in a row that ended without the receiver taking the body.
    public var consecutiveFailures: Int { failures }

    /// Whether the push is observing its settings.
    public var isObserving: Bool { observing }

    /// Observes `settings`, pushes the snapshot now, and re-pushes it on every
    /// reconnect. A repeat call while observing is ignored.
    public func start<Value: Codable & Sendable>(observing settings: [UserSetting<Value>]) {
        start(observers: { [weak self] in
            settings.map { setting in
                UserSettingObserver(setting) { _ in self?.push() }
            }
        })
    }

    /// ``start(observing:)`` for settings of mixed types: `makeObservers` is
    /// handed the change handler and returns whatever observers it built,
    /// which this push keeps alive until ``stop()``.
    public func start(makeObservers: @escaping (_ onChange: @escaping @MainActor () -> Void) -> [AnyObject]) {
        start(observers: { [weak self] in makeObservers { self?.push() } })
    }

    private func start(observers build: @escaping @MainActor () -> [AnyObject]) {
        guard !observing else {
            logger.warning("\(self.label, privacy: .public) push started more than once; ignoring the repeat")
            return
        }
        observing = true
        if receiverOwns {
            // Observed at once: a change made before the first read is the
            // user's and newer than anything the read could bring (R2).
            observers = build()
            awaitingFirstPull = true
            installReconnect()
            attemptSeed()
            return
        }
        guard seed != nil else {
            activate(build())
            return
        }
        // Observers wait for the seed, so writing the seeded values pushes nothing.
        pendingObservers = build
        installReconnect()
        attemptSeed()
    }

    private func activate(_ built: [AnyObject]) {
        pendingObservers = nil
        observers = built
        // Observers fire only on change, and the receiver may have restarted.
        push()
        installReconnect()
    }

    private func installReconnect() {
        guard !reconnectInstalled else { return }
        reconnectInstalled = true
        registerReconnect { [weak self] in
            Task { @MainActor in self?.reconnected() }
        }
    }

    /// Runs the seed (receiver-owned mode: the first read) unless one is
    /// already in flight; on success completes the start.
    private func attemptSeed() {
        if let pull {
            attemptFirstPull(pull)
            return
        }
        guard let seed, seedTask == nil else { return }
        seedRetry?.cancel()
        seedRetry = nil
        seedGeneration += 1
        let mine = seedGeneration
        seedTask = Task { @MainActor [weak self] in
            let seeded = await seed()
            guard let self, self.seedGeneration == mine else { return }
            self.seedTask = nil
            guard self.observing, let build = self.pendingObservers else { return }
            if seeded {
                self.seedFailures = 0
                self.activate(build())
            } else {
                self.seedFailures += 1
                self.scheduleSeedRetry()
            }
        }
    }

    /// Receiver-owned mode's first read, retried like a seed until it reaches
    /// the receiver. Its values are written only when no local change was made
    /// since it started and none is still on its way: that change is newer.
    private func attemptFirstPull(_ pull: @escaping Pull) {
        guard awaitingFirstPull, seedTask == nil else { return }
        seedRetry?.cancel()
        seedRetry = nil
        seedGeneration += 1
        let mine = seedGeneration
        let startedAt = generation
        let localAtStart = snapshot()
        seedTask = Task { @MainActor [weak self] in
            let apply = await pull()
            guard let self, self.seedGeneration == mine else { return }
            self.seedTask = nil
            guard self.observing else { return }
            guard let apply else {
                self.seedFailures += 1
                self.scheduleSeedRetry()
                return
            }
            self.seedFailures = 0
            self.awaitingFirstPull = false
            guard self.generation == startedAt, !self.localChangePending else { return }
            self.applyPull(apply, localAtStart: localAtStart)
        }
    }

    /// Writes a pulled value in, unless the local values changed while the read
    /// was out. An observer reports a change one main-queue hop after it is
    /// made, so a read can come back before ``push()`` has heard of it; that
    /// change is newer than what was read, so it is sent instead of overwritten.
    private func applyPull(_ apply: @MainActor () -> Void, localAtStart: Data?) {
        guard snapshot() == localAtStart else {
            push()
            return
        }
        apply()
        receiverBody = snapshot()
    }

    /// Retries a failed seed after ``reconnectDelay`` for the seed failure count,
    /// unless ``stop()`` or a reconnect (which retries at once) gets there first.
    private func scheduleSeedRetry() {
        let delay = reconnectDelay(seedFailures)
        let (name, failed, waitMs) = (label, seedFailures, delay / 1_000_000)
        logger.warning(
            "\(name, privacy: .public) seed failed \(failed) time(s); retrying in \(waitMs) ms or on reconnect"
        )
        seedRetry = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else { return }
            self.seedRetry = nil
            self.attemptSeed()
            await self.seedTask?.value
        }
    }

    /// Stops observing and cancels a push still retrying. The reconnect
    /// handler stays registered but does nothing until the next ``start``.
    public func stop() {
        observing = false
        observers = []
        pendingObservers = nil
        seedTask?.cancel()
        seedTask = nil
        seedRetry?.cancel()
        seedRetry = nil
        seedFailures = 0
        seedGeneration += 1
        awaitingFirstPull = false
        refreshTask?.cancel()
        refreshTask = nil
        receiverBody = nil
        cancelPending()
    }

    /// Receiver-owned mode: reads the receiver's values into the local store,
    /// unless a local change is still on its way (it is newer, and lands
    /// instead). Does nothing before the start completes, while a read is
    /// already out, or without a `pull`. Before the first read has reached the
    /// receiver it retries that read instead.
    public func refresh() {
        guard let pull, observing, pendingObservers == nil, refreshTask == nil,
              !localChangePending else { return }
        if awaitingFirstPull {
            attemptFirstPull(pull)
            return
        }
        let startedAt = generation
        let localAtStart = snapshot()
        refreshTask = Task { @MainActor [weak self] in
            let apply = await pull()
            guard let self else { return }
            self.refreshTask = nil
            // A change made while the read was out is newer than what it read.
            guard let apply, self.observing, self.generation == startedAt,
                  !self.localChangePending else { return }
            self.applyPull(apply, localAtStart: localAtStart)
        }
    }

    /// A push in flight or waiting to retry.
    private var localChangePending: Bool { inFlight || delayedReconnect != nil }

    /// Sends the current snapshot, superseding any push still retrying.
    public func push() {
        // Until the seed completes the local values are not the receiver's;
        // completing the seed pushes the then-current snapshot itself.
        guard pendingObservers == nil else { return }
        guard let body = snapshot() else {
            logger.error("Failed to build the \(self.label, privacy: .public) snapshot")
            return
        }
        // The receiver already holds it (or this is the echo of a pulled
        // value): drop any older change still waiting, send nothing.
        if receiverOwns, body == receiverBody, !inFlight {
            cancelPending()
            failures = 0
            return
        }
        cancelPending()
        generation += 1
        let mine = generation
        inFlight = true
        let label = label, logger = logger, backoffs = backoffs, send = sendBody
        pushTask = Task { [weak self] in
            let delivery = await BoundedPush.deliver(label: label, logger: logger, backoffs: backoffs) {
                await send(body)
            }
            self?.finished(generation: mine, delivery: delivery, body: body)
        }
    }

    /// Awaits the most recent push, including one a reconnect is waiting to
    /// make — for tests.
    public func awaitPendingPush() async {
        await seedTask?.value
        await seedRetry?.value
        await refreshTask?.value
        await delayedReconnect?.value
        await pushTask?.value
    }

    // MARK: - Reconnect policy

    private func reconnected() {
        guard observing else { return }
        // Not started yet: the seed failed, so the reconnect retries it.
        if pendingObservers != nil {
            attemptSeed()
            return
        }
        // The running push carries the current snapshot; restarting it would
        // cancel its bounded retry before it can give up (review F11).
        guard !inFlight, delayedReconnect == nil else { return }
        // The receiver may have been changed while it was away: read it.
        if receiverOwns {
            refresh()
            return
        }
        guard failures > 0 else {
            push()
            return
        }
        scheduleDelayedPush(reason: "reconnect")
    }

    /// Re-pushes after ``reconnectDelay`` for the current failure count,
    /// unless a newer push or ``stop()`` cancels it first.
    private func scheduleDelayedPush(reason: String) {
        let delay = reconnectDelay(failures)
        let (name, failed, waitMs) = (label, failures, delay / 1_000_000)
        logger.info(
            "\(name, privacy: .public) push: \(reason, privacy: .public) after \(failed) failure(s), in \(waitMs) ms"
        )
        delayedReconnect = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else { return }
            self.delayedReconnect = nil
            guard self.observing else { return }
            self.push()
        }
    }

    private func finished(generation finishedGeneration: Int, delivery: Delivery, body: Data) {
        // A superseded push says nothing about the receiver's current state.
        guard finishedGeneration == generation else { return }
        inFlight = false
        switch delivery {
        case .taken:
            failures = 0
            if receiverOwns { receiverBody = body }
        case .refused:
            // The receiver kept its own values: the body is not what it holds
            // (R1). Read them back, so the local store shows them.
            failures = 0
            if receiverOwns { refresh() }
        case .unreached:
            failures += 1
            // Nothing else may open a connection soon, so an undelivered
            // snapshot schedules its own next attempt (review N3).
            if observing, delayedReconnect == nil { scheduleDelayedPush(reason: "retry") }
        }
    }

    private func cancelPending() {
        pushTask?.cancel()
        pushTask = nil
        inFlight = false
        delayedReconnect?.cancel()
        delayedReconnect = nil
    }

    /// `values` as sorted-key JSON, the byte-stable form a snapshot is sent in.
    public static func encodeSorted(_ values: some Encodable) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(values)
    }
}

/// A push retried a bounded number of times: try, then back off and retry,
/// stopping at once if a newer push cancelled this one. A dropped push leaves
/// the receiver on its last-known state until the next change re-pushes, so the
/// retry is deliberately bounded rather than infinite.
public enum BoundedPush {

    /// At once, then after 0.5 s, then after 1.5 s.
    public static let defaultBackoffs: [UInt64] = [0, 500_000_000, 1_500_000_000]

    /// - Parameters:
    ///   - label: names the channel in log lines.
    ///   - call: performs one push; true on success, false on a transport failure.
    /// - Returns: true when an attempt landed; false when every attempt failed
    ///   or a newer push cancelled this one.
    @discardableResult
    public static func send(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = defaultBackoffs,
        call: @Sendable () async -> Bool
    ) async -> Bool {
        let outcome = await deliver(label: label, logger: logger, backoffs: backoffs) {
            await call() ? .taken : .unreached
        }
        return outcome == .taken
    }

    /// ``send(label:logger:backoffs:call:)`` for a call that can report a
    /// refusal: a refusal ends the retries at once, as a delivery does.
    /// - Returns: the last attempt's outcome; `.unreached` when every attempt
    ///   failed or a newer push cancelled this one.
    public static func deliver(
        label: String,
        logger: Logger,
        backoffs: [UInt64] = defaultBackoffs,
        call: @Sendable () async -> SettingsSnapshotPush.Delivery
    ) async -> SettingsSnapshotPush.Delivery {
        for (attempt, delay) in backoffs.enumerated() {
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
            // Superseded: the stale body must not land after the newer one.
            if Task.isCancelled { return .unreached }
            let outcome = await call()
            if outcome == .taken { return outcome }
            if outcome == .refused {
                logger.warning("\(label, privacy: .public) push refused by the receiver")
                return outcome
            }
            logger.warning("\(label, privacy: .public) push attempt \(attempt + 1) of \(backoffs.count) failed")
        }
        logger.error(
            "\(label, privacy: .public) push failed after \(backoffs.count) attempts; receiver keeps its prior state"
        )
        return .unreached
    }
}
