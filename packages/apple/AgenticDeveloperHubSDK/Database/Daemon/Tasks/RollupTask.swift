#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Aggregates the event store's Claude events (every hook type, and the
/// per-type counts the legacy tables used to hold) into the permanent
/// `daily_metric` rollup so analytics survive the storage trim. Runs daily.
///
/// Finalization model — the core correctness contract:
/// - A day is **finalized** (frozen) once it's older than `finalizeAfterDays`.
///   Finalized days (`<= stats_rollup_finalized_through`) are NEVER recomputed,
///   so when the trim later deletes their source rows the rolled-up history is
///   untouched. `finalizeAfterDays` is clamped strictly inside the
///   `event_history_days` window, and the trim never deletes a day past the
///   watermark, so a day is always frozen before its source goes.
/// - The **mutable tail** (days after the watermark, up to today) still receives
///   live events and late JSONL-import events, so it's recomputed every run.
///   Recompute is DELETE-day + re-INSERT in one transaction → idempotent.
///
/// Chunked backfill: the one-time historical pass freezes up to `daysPerRun`
/// days per `execute()`, advancing the watermark per-day (crash-safe resume),
/// and returns `.rerunImmediately` until caught up — mirroring `TrimTask`
/// / `JSONLImportTask` so the serial DB queue is yielded between chunks.
///
/// Known limitation: a JSONL import that lands events on an already-finalized
/// day is not reflected (the day stays frozen). Acceptable for this phase; a
/// future manual rebuild can recompute days that still have source rows.
public struct RollupTask: SessionDaemonTask {
    /// Finalizable days processed per `execute()` before yielding the queue.
    static let daysPerRun = 30

    /// Days of frozen `project`-metric history backfilled per `execute()`. Smaller
    /// than `daysPerRun` because each day reads its `cwd` rows into memory to
    /// compute the project (last path component) in Swift.
    static let projectBackfillDaysPerRun = 10

    /// Days the usage-summary backfill refreshes per `execute()`. Each reads
    /// one day of turns and events (two-step, bounded by the maintenance read
    /// deadline) and writes that day in one main-db transaction.
    static let usageSummaryDaysPerRun = 30

    /// Delays before the next run after a usage-summary read runs out of
    /// time, by how many runs in a row it has. Past the last, the task drops
    /// back to its normal cadence and the count starts over.
    static let interruptionBackoff: [TimeInterval] = [30, 120, 480]

    /// Usage-summary interruptions in a row (a main-db setting, so the count
    /// survives a restart).
    static let interruptionCountKey = "usage_summary_interruptions"

    public let name = "rollup"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    let finalizeAfterDays: Int

    /// Tests only: runs in place of the usage-summary update.
    var usageSummaryUpdateOverride: (@Sendable () throws -> Bool)?

    public init(database: DaemonDatabase, checkInterval: TimeInterval = 86400, finalizeAfterDays: Int = 2) {
        self.database = database
        self.finalizeAfterDays = max(0, finalizeAfterDays)
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 300,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        guard let minDay = try database.minEventDay() else {
            return .empty   // empty (or absent) event store — nothing to roll up
        }
        let today = Self.utcDay(Date())

        // Freeze boundary: a day is finalizable once it's older than
        // finalizeAfterDays, but never beyond the event history window (so it's
        // frozen before the trim could delete its source; the trim also waits
        // for the watermark). `min(..., historyDays-1)` degrades safely for the
        // shortest window (7 days).
        // `max(1, …)` keeps maxFinalizable ≤ yesterday: never finalize today (an
        // incomplete UTC day) — otherwise today's later events would be frozen
        // out (the steady-state tail only covers days > the watermark).
        let historyDays = StorageSettings.historyDays(database)
        let effectiveFinalize = max(1, min(finalizeAfterDays, historyDays - 1))
        let maxFinalizable = Self.utcDay(Date().addingTimeInterval(-Double(effectiveFinalize) * 86400))

        // Resolve the per-type rollup sources once per run, not per day.
        let sources = database.availableRollupSources()
        var finalized = try database.rollupFinalizedThrough()

        // --- Backfill: freeze days up to maxFinalizable, oldest-first, chunked ---
        let backfillStart = finalized.map(Self.dayAfter) ?? minDay
        if backfillStart <= maxFinalizable {
            let days = try database.distinctEventDays(
                from: backfillStart, to: maxFinalizable, limit: Self.daysPerRun
            )
            for day in days {
                try database.recomputeDailyMetrics(forDay: day, sources: sources)
                try database.setRollupFinalizedThrough(day)   // advance per-day: crash-safe
                finalized = day
            }
            // A full chunk means there are likely more finalizable days — yield
            // and resume next tick (one extra benign tick at the exact boundary).
            if days.count == Self.daysPerRun {
                logger.debug("Rollup backfill froze \(days.count) day(s) through \(days.last ?? "?"); rescheduling")
                return .rerunImmediately
            }
            // Caught up: finalize through the boundary so empty calendar gaps
            // (days with no events) aren't rescanned on every future run. Log the
            // jump when the last day with events is behind the boundary — those
            // gap days are now frozen, so a late import onto one of them won't be
            // rolled up (documented limitation; safe re-finalize needs the
            // retention deletion-floor that lands with the retention phase).
            if (finalized ?? "") < maxFinalizable {
                logger.info("Rollup watermark jumping over an empty gap (\(finalized ?? "nil") → \(maxFinalizable))")
            }
            try database.setRollupFinalizedThrough(maxFinalizable)
            finalized = maxFinalizable
            logger.info("Rollup backfill complete — finalized through \(maxFinalizable)")
        }

        // --- Steady state: recompute the mutable tail (after the frozen region) ---
        let tailStart = finalized.map(Self.dayAfter) ?? minDay
        if tailStart <= today {
            let tail = try database.distinctEventDays(from: tailStart, to: today)
            for day in tail {
                try database.recomputeDailyMetrics(forDay: day, sources: sources)
            }
            if !tail.isEmpty {
                logger.debug("Rollup recomputed \(tail.count) mutable tail day(s) \(tailStart)…\(today)")
            }
        }

        // --- One-time `project`-metric backfill of frozen days that predate it ---
        // recomputeDailyMetrics emits `project` for the tail + future finalizations;
        // this catches up days finalized by an older daemon. Additive, source-gated
        // and chunked, so it can't disturb other frozen metrics and yields the queue
        // between bursts. Only runs once the finalize watermark exists. It runs
        // before the usage summary, and a full chunk only asks for a rerun, so
        // neither backfill can hold the other up.
        var rerun = false
        if let finalized {
            let done = try database.backfillProjectMetric(
                through: finalized, limit: Self.projectBackfillDaysPerRun
            )
            if done == Self.projectBackfillDaysPerRun {
                logger.debug("Rollup project backfill froze \(done) day(s); rescheduling")
                rerun = true
            }
        }

        // --- Usage summary (`session_summary` + `usage_bursts`) ---
        // A read that runs out of time (the maintenance read deadline) is
        // logged and retried with a backoff instead of failing this run.
        do {
            let caughtUp = try usageSummaryUpdateOverride?() ?? updateUsageSummary(finalized: finalized, today: today)
            if !caughtUp { rerun = true }
        } catch where DaemonDatabase.isUsageSummaryInterruption(error) {
            return interrupted(by: error)
        }
        if let count = try? database.setting(for: Self.interruptionCountKey), !count.isEmpty {
            try? database.setSetting(Self.interruptionCountKey, "")
        }
        return rerun ? .rerunImmediately : .empty
    }

    /// The result after a usage-summary read ran out of time: the next run
    /// after `interruptionBackoff`'s delay for this many interruptions in a
    /// row, then, past the last, the normal cadence with the count reset.
    private func interrupted(by error: Error) -> SessionTaskResult {
        let text = (try? database.setting(for: Self.interruptionCountKey)) ?? nil
        let count = (text.flatMap { Int($0) } ?? 0) + 1
        let reason = error.localizedDescription
        guard count <= Self.interruptionBackoff.count else {
            try? database.setSetting(Self.interruptionCountKey, "")
            logger.error("Usage summary interrupted \(count) times in a row (\(reason)); waiting for the next run")
            return .empty
        }
        try? database.setSetting(Self.interruptionCountKey, String(count))
        let delay = Self.interruptionBackoff[count - 1]
        logger.warning("Usage summary read interrupted (\(reason)); retry \(count) in \(Int(delay)) s")
        return SessionTaskResult(nextRunSeconds: delay)
    }

    /// Brings `session_summary` and `usage_bursts` up to date. Returns false
    /// when work remains.
    ///
    /// 1. New 7-day reset instants: a new phase restarts the backfill walk so
    ///    every day events.db holds is cut at it. A new pricing revision
    ///    restarts it too, so those days are priced again.
    /// 2. Late turns: a finalized day that turns arrived on is re-read.
    /// 3. Every day up to the rollup watermark gets its final refresh once,
    ///    oldest first: on the first run after migration 051 that is all of
    ///    events.db's history, afterwards only the days frozen since the last
    ///    run. `usage_summary_finalized_through` follows the rollup watermark
    ///    day by day, never passes a day that was not summarised, and never
    ///    moves back.
    /// 4. The mutable tail, refreshed like `daily_metric`'s (event and turn days).
    private func updateUsageSummary(finalized: String?, today: String) throws -> Bool {
        if try database.scanUsageResetPhases() {
            logger.info("Usage summary: a new 7-day reset instant; re-cutting held days")
        }
        if try database.restartUsageSummaryForPricingIfNeeded() {
            logger.info("Usage summary: a new pricing revision; repricing held days")
        }
        if try !database.recountLateUsageTurns() {
            logger.debug("Usage summary late-turn recount not caught up; rescheduling")
            return false
        }
        if let finalized {
            let caughtUp = try database.backfillUsageSummary(
                through: finalized, limit: Self.usageSummaryDaysPerRun)
            if !caughtUp {
                logger.debug("Usage summary backfill not caught up to \(finalized); rescheduling")
                return false
            }
        }
        let summaryTailStart = try database.usageSummaryFinalizedThrough().map(Self.dayAfter)
        if (summaryTailStart ?? "") <= today {
            for day in try database.distinctActivityDays(from: summaryTailStart, through: today) {
                try database.refreshUsageSummary(forDay: day)
            }
        }
        return true
    }

    // MARK: - UTC day helpers (thin forwarders to the shared UTCDay utility)

    static func utcDay(_ date: Date) -> String { UTCDay.string(from: date) }
    static func dayAfter(_ day: String) -> String { UTCDay.dayAfter(day) }
}

extension RollupTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
