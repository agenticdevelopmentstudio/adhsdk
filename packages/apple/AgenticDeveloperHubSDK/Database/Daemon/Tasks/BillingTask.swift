#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

/// Turns session activity into billable time, on a timer.
///
/// One pass is: derive segments for every session whose activity has moved
/// since last time, then roll every closed, assigned segment into entries.
/// Both halves are idempotent, so a crash mid-pass costs nothing but a repeat.
///
/// Chunked like `RollupTask`: at most `sessionsPerRun` sessions per `execute()`,
/// returning `.rerunImmediately` while there is more — the write queue is
/// serial and shared with ingestion, and a first run over months of history
/// must not hold it for a minute.
public struct BillingTask: SessionDaemonTask {
    /// Sessions derived per `execute()` before yielding the queue.
    public static let defaultSessionsPerRun = 50
    /// The spec's interval. Derived time lags real time by up to this much,
    /// and a run only becomes billable once a pass has seen it close.
    public static let defaultCheckInterval: TimeInterval = 60
    /// Consecutive failures before a session's watermark is stamped anyway.
    static let maxDerivationAttempts = 3

    /// Derives one session. Injectable so a test can make a session fail.
    public typealias Derive = @Sendable (
        _ session: BillingSessionRow, _ prefs: BillingPrefs.Snapshot, _ now: String, _ database: DaemonDatabase
    ) throws -> Int

    /// Derives one app-activity span. Injectable so a test can make a span fail.
    public typealias DeriveApp = @Sendable (
        _ span: BillingAppSpanRow, _ prefs: BillingPrefs.Snapshot, _ now: String, _ database: DaemonDatabase
    ) throws -> Int

    /// Deletes activity ended before the given timestamp; returns rows removed.
    public typealias Prune = @Sendable (_ before: String, _ database: DaemonDatabase) throws -> Int

    /// Why Claude sessions must not be derived now, or nil when they may.
    /// Injectable so a test can hold them without a pending backfill.
    public typealias ClaudeHold = @Sendable (_ database: DaemonDatabase) -> String?

    /// Claude time is derived from `events.db`. With no store attached (the
    /// pipeline did not open) or while a history backfill is still replaying,
    /// a session's events can be missing rather than gone; deriving from that
    /// would delete its segments and stamp it done, so the next replay never
    /// re-selects it. `claudeHistoryBackfillPending` is also true without a
    /// store, and when the backfill status cannot be read.
    static let defaultClaudeHold: ClaudeHold = { database in
        if database.eventReads == nil { return "Claude pipeline unavailable" }
        return database.claudeHistoryBackfillPending() ? "history backfill" : nil
    }

    /// Activity retention needs no tighter clock than this.
    public static let defaultPruneInterval: TimeInterval = 3600

    public let name = "billing"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    let sessionsPerRun: Int
    let failures: FailureLedger
    /// Live sessions' parsed activity, so a pass reads only new events.
    let activity: BillingActivityCache
    /// Whether this daemon has run its one full recompute yet.
    let firstPass: FirstPass
    private let derive: Derive
    private let deriveApp: DeriveApp
    private let prune: Prune
    private let claudeHold: ClaudeHold
    let pruneThrottle: PruneThrottle

    public init(
        database: DaemonDatabase,
        checkInterval: TimeInterval = BillingTask.defaultCheckInterval,
        sessionsPerRun: Int = BillingTask.defaultSessionsPerRun,
        failures: FailureLedger = FailureLedger(),
        activity: BillingActivityCache = BillingActivityCache(),
        firstPass: FirstPass = FirstPass(),
        derive: Derive? = nil,
        deriveApp: DeriveApp? = nil,
        prune: Prune? = nil,
        pruneInterval: TimeInterval = BillingTask.defaultPruneInterval,
        pruneThrottle: PruneThrottle? = nil,
        claudeHold: ClaudeHold? = nil
    ) {
        self.database = database
        self.sessionsPerRun = max(1, sessionsPerRun)
        self.failures = failures
        self.activity = activity
        self.firstPass = firstPass
        self.derive = derive ?? Self.deriveSegments(activity: activity)
        self.deriveApp = deriveApp ?? Self.deriveAppSegments
        self.prune = prune ?? { before, database in try database.pruneActivity(endedBefore: before) }
        self.claudeHold = claudeHold ?? Self.defaultClaudeHold
        self.pruneThrottle = pruneThrottle ?? PruneThrottle(interval: pruneInterval)
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 120,
            backoffOnFailure: true
        )
    }

    static func deriveSegments(activity: BillingActivityCache) -> Derive {
        { session, prefs, now, database in
            try BillingStore.deriveSegments(
                for: session,
                cutoffSeconds: prefs.idleCutoffSeconds,
                trackUnassigned: prefs.trackUnassigned,
                now: now,
                database: database,
                activity: activity
            )
        }
    }

    static let deriveAppSegments: DeriveApp = { span, prefs, now, database in
        try BillingStore.deriveAppSegments(
            for: span, defaultCutoffSeconds: prefs.idleCutoffSeconds,
            trackUnassigned: prefs.trackUnassigned, now: now, database: database)
    }

    /// How many of the given closed spans now have their watermark at their end.
    private func settledCount(of ids: [String]) throws -> Int {
        guard !ids.isEmpty else { return 0 }
        var count = 0
        let marks = Array(repeating: "?", count: ids.count).joined(separator: ",")
        try database.query("""
            SELECT COUNT(*) AS n FROM activity_span
            WHERE id IN (\(marks)) AND ended_at <> '' AND billing_derived_at = ended_at
        """, params: ids) { row in count = row["n"] ?? 0 }
        return count
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        // `TimeZone.current` is cached for the life of the process. A laptop
        // that crossed zones would otherwise stamp new time with the zone the
        // daemon launched in, and bucket it onto the wrong local day.
        NSTimeZone.resetSystemTimeZone()

        let prefs = try stage("prefs") { try BillingPrefs.snapshot(database) }
        let now = UTCTimestamp.now()

        // Held, Claude sessions keep their segments and watermarks untouched
        // until the store is whole; app spans still derive.
        let held = claudeHold(database)
        if let held { logger.debug("billing: Claude sessions held: \(held, privacy: .public)") }
        let sessions = held != nil ? [] : try stage("session selection") {
            try database.sessionsNeedingBillingDerivation(limit: sessionsPerRun, excluding: failures.abandoned)
        }
        // The entries this chunk's derivation can reshape: whatever its
        // sessions' segments point at now. Read before deriving, since
        // derivation is what detaches them.
        var touched = try stage("session entries") {
            try database.billingEntryIds(forSessions: sessions.map(\.sessionId))
        }
        var derived = 0
        for session in sessions {
            // One session's bad data must not stop the pass: the watermark for
            // the others still advances, and the next run retries this one —
            // up to `maxDerivationAttempts` times. After that its watermark is
            // stamped anyway: a session that fails every time would otherwise
            // be re-selected forever, and fifty of them fill every chunk, so
            // the pass spins on `.rerunImmediately` and no other session is
            // ever derived.
            do {
                derived += try derive(session, prefs, now, database)
                failures.succeeded(session.sessionId)
                // An ended session gets no more events; its final derivation
                // is done, so its history need not stay in memory.
                if !session.isActive { activity.forget(sessionId: session.sessionId) }
            } catch {
                logger.error("billing derivation failed for \(session.sessionId, privacy: .public): \(error)")
                if failures.failed(session.sessionId, maxAttempts: Self.maxDerivationAttempts) {
                    try database.markBillingDerived(sessionId: session.sessionId, at: session.lastActivityAt)
                    let attempts = Self.maxDerivationAttempts
                    logger.error(
                        "billing: gave up on \(session.sessionId, privacy: .public) after \(attempts) attempts"
                    )
                }
            }
        }

        // App activity: each pending span through the same segment machinery,
        // keyed `app:<span id>`. Read the entries its segments point at before
        // deriving, for the same reason as the sessions above.
        //
        // An open span is re-selected on every pass by design, and stamping a
        // failing one at its `endedAt` ("") does not stop that. So an abandoned
        // OPEN span is skipped here, the way `excluding:` keeps abandoned
        // sessions out of the query above. Over-fetch by the abandoned count so
        // skipped spans cannot starve the rest of the chunk. Once the span
        // closes it earns a fresh set of attempts (and a closed span's stamp
        // keeps it out of the query on its own).
        let abandonedApps = failures.abandoned.filter { ActivitySpanSession.spanId(sessionId: $0) != nil }
        let fetched = try stage("app span selection") {
            try database.billingAppSpansNeedingDerivation(limit: sessionsPerRun + abandonedApps.count)
        }
        let spans = Array(fetched.filter { !($0.endedAt.isEmpty && abandonedApps.contains($0.sessionId)) }
            .prefix(sessionsPerRun))
        let appTouched = try stage("app span entries") {
            try database.billingEntryIds(forSessions: spans.map(\.sessionId))
        }
        touched.formUnion(appTouched)
        for span in spans {
            do {
                derived += try deriveApp(span, prefs, now, database)
                failures.succeeded(span.sessionId)
            } catch {
                logger.error("billing derivation failed for \(span.sessionId, privacy: .public): \(error)")
                if failures.failed(span.sessionId, maxAttempts: Self.maxDerivationAttempts) {
                    try database.markAppSpanBillingDerived(spanId: span.id, at: span.endedAt)
                    // A closed span's stamp keeps it out of re-selection on its
                    // own; leaving it abandoned would only leak ledger entries
                    // and inflate the over-fetch. An open span's stamp is "",
                    // so it stays abandoned until it closes.
                    if !span.endedAt.isEmpty { failures.succeeded(span.sessionId) }
                    let attempts = Self.maxDerivationAttempts
                    logger.error(
                        "billing: gave up on \(span.sessionId, privacy: .public) after \(attempts) attempts"
                    )
                }
            }
        }

        // Counted before the prune below, which could otherwise delete a settled
        // span first. Open spans are re-selected every pass by design, so only
        // closed ones can count toward "there is more waiting".
        let settledSpans = try stage("settled count") {
            try settledCount(of: spans.filter { !$0.endedAt.isEmpty }.map(\.id))
        }

        // Only those entries are recomputed — the roll computes the ones it
        // adds to itself — except on the daemon's first pass, which checks
        // every owned entry once, for whatever changed while it was down.
        let scope: Set<String>? = firstPass.take() ? nil : touched
        let rolled = try stage(scope == nil ? "rollup (first pass)" : "rollup") {
            try BillingRollup.run(options: prefs.rollupOptions, database: database, recomputing: scope)
        }
        if derived > 0 || rolled > 0 {
            logger.info("billing pass: \(derived) segments, \(rolled) entries")
        }

        // A forgotten timer is only visible if something looks. Nothing else in
        // the daemon runs on a clock the user is not watching.
        let runaways = try stage("runaway timers") {
            try BillingTimer.flagRunaways(capSeconds: prefs.manualTimerCapSeconds, now: now, database: database)
        }
        if runaways > 0 { logger.notice("billing: \(runaways) timer(s) past the cap") }

        // Retention is housekeeping: hourly, after the work that matters, and
        // a failure here must not cost the pass its rollup.
        if pruneThrottle.take() {
            let retention = (try? WorkTrackingPrefs.load(database).retentionDays)
                ?? WorkTrackingPreferences.defaultRetentionDays
            do {
                let pruned = try prune(UTCTimestamp.string(daysAgo: retention), database)
                if pruned > 0 { logger.info("activity: pruned \(pruned) rows past \(retention) days") }
            } catch {
                logger.error("activity: prune failed: \(error)")
            }
        }

        // A full chunk means there is probably more waiting. Yield, then come
        // straight back — the same shape `RollupTask` uses for backfill.
        // Open spans are re-selected every pass by design, so only closed ones
        // count toward "there is more waiting".
        // And only those this pass settled (stamp now equals a non-empty end):
        // a closed span held pending by an open idle stamps "" and would
        // otherwise spin the rerun without progress.
        return sessions.count >= sessionsPerRun || settledSpans >= sessionsPerRun
            ? .rerunImmediately : .empty
    }
}

extension BillingTask {

    /// True exactly once per daemon. Shared by every copy of the task value.
    public final class FirstPass: @unchecked Sendable {
        private let lock = NSLock()
        private var pending = true

        public init() {}

        /// Whether this is the first pass; every later call answers false.
        func take() -> Bool {
            lock.lock(); defer { lock.unlock() }
            defer { pending = false }
            return pending
        }
    }

    /// When activity was last pruned: the first pass after daemon start always
    /// prunes, then at most once per `interval`. Shared by every copy of the task.
    public final class PruneThrottle: @unchecked Sendable {
        private let lock = NSLock()
        private let interval: TimeInterval
        private var last: Date?

        public init(interval: TimeInterval = BillingTask.defaultPruneInterval) { self.interval = interval }

        func take(now: Date = Date()) -> Bool {
            lock.lock(); defer { lock.unlock() }
            if let last, now.timeIntervalSince(last) < interval { return false }
            last = now
            return true
        }
    }

    /// Per-session derivation failures, held in memory for the daemon's
    /// lifetime and shared by every copy of the task value (the scheduler may
    /// copy it). The counting — give up at `maxAttempts`, then keep the
    /// session out of re-selection until it succeeds — is the ledger's.
    public typealias FailureLedger = SessionItemFailureLedger<String>
}

extension BillingTask {

    /// Runs one stage of the pass and, if it throws, logs the stage's name and
    /// how long it ran before rethrowing the error unchanged. The scheduler's
    /// own line names only the task, so a deadline anywhere in the pass would
    /// otherwise be impossible to place.
    func stage<T>(_ name: String, _ body: () throws -> T) throws -> T {
        let started = ContinuousClock.now
        do {
            return try body()
        } catch {
            let elapsed = started.duration(to: .now)
            let millis = Int(elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000)
            logger.error(
                "billing: stage \(name, privacy: .public) failed after \(millis, privacy: .public) ms: \(error)"
            )
            throw error
        }
    }
}

extension BillingTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
