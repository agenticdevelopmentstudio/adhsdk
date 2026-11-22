#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import os

/// What a request for a trim pass got: the pass it ran, or the start time of
/// the pass already running (which it did not interrupt or duplicate).
public enum TrimNowResult: Sendable, Equatable {
    case started(TrimReport)
    case alreadyRunning(startedAt: Double)
}

/// What ``StorageController/start(done:)`` did: started a pass (not waited
/// for), or found one running.
public enum TrimStartResult: Sendable, Equatable {
    case started(startedAt: Double)
    case alreadyRunning(startedAt: Double)
}

/// The one entry point for a storage trim pass, owned by `DaemonController`.
/// The scheduled `TrimTask` and Task 4's "Trim Now" both come through
/// ``trimNow()``, and an in-process lock lets only one pass run at a time: a
/// request while one runs returns ``TrimNowResult/alreadyRunning(startedAt:)``.
///
/// A pass is the toolkit's `TrimService` over the main database and, when the
/// Claude pipeline is open, its `events.db` (otherwise the report says
/// "events.db unavailable"), followed by the empty-session reaper.
///
/// **The reaper deletes main-db `sessions` rows, so it is the most guarded
/// step.** It runs only after a pass that set a cutoff and finished cleanly (no
/// error, no bulk load, no missing store), only while no Claude capture is
/// waiting in a spool or quarantine (their events.db rows are not written yet),
/// and only for sessions last active before that cutoff. A session with a row in
/// any of ``reaperKeepTables`` is never reaped.
///
/// **Off the cooperative pool.** A pass is minutes of synchronous SQLite and
/// maybe a full `VACUUM`, so it runs on its own serial queue, never on a Swift
/// concurrency thread that HTTP and XPC handlers share.
public final class StorageController: Sendable {
    /// How long one pass may run before it stops and reports `finished = false`.
    static let passSeconds: TimeInterval = 300

    /// Tables whose row for a session keeps the reaper away from it:
    /// - `session_summary`: a trimmed session's frozen usage;
    /// - `session_metrics`: its status-line cost and lines (the delete would
    ///   cascade to it, and it exists nowhere else);
    /// - `transcript_turns`: a legacy session's only turns;
    /// - `event_log`: legacy hook events (the reaper's delete checks it too).
    static let reaperKeepTables = ["session_summary", "session_metrics", "transcript_turns", "event_log"]

    typealias Pass = @Sendable (_ deadline: Date) -> TrimReport

    /// Where every pass runs: one at a time, off the cooperative pool.
    private static let queue = DispatchQueue(label: "SessionDaemon.StorageController.trim", qos: .utility)

    private let running = OSAllocatedUnfairLock<Double?>(initialState: nil)
    private let failures = OSAllocatedUnfairLock<Int>(initialState: 0)
    private let pass: Pass
    private let now: @Sendable () -> Date
    /// The history backfill `HistoryBackfillTask` runs and `/storage` reports;
    /// nil for a test controller.
    public let backfill: HistoryBackfill?

    public init(
        database: DaemonDatabase, claude: ClaudePipelineSlot, legacySpool: IngestSpool? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.now = now
        self.backfill = HistoryBackfill(claude: claude, now: now)
        self.pass = { deadline in
            let pipeline = claude.current
            return Self.runPass(
                database: database, eventStore: pipeline?.store, deadline: deadline, now: now,
                capturesWaiting: { Self.capturesWaiting(pipeline: pipeline, legacySpool: legacySpool) },
                backfillHold: { HistoryBackfill.trimHold(in: pipeline) })
        }
    }

    /// Tests only: `pass` runs in place of the real one.
    init(pass: @escaping Pass, now: @escaping @Sendable () -> Date = Date.init, backfill: HistoryBackfill? = nil) {
        self.pass = pass
        self.now = now
        self.backfill = backfill
    }

    /// When the running pass started (epoch seconds), or nil when none runs.
    public var runningSince: Double? { running.withLock { $0 } }

    /// Passes in a row that ended with a failed stage (an `events.db` error, for
    /// one); a pass a bulk load skipped leaves it as it was, and any other pass
    /// with no error resets it. `TrimTask` backs off by it.
    public var consecutiveFailures: Int { failures.withLock { $0 } }

    /// Runs one pass unless one is already running.
    public func trimNow() async -> TrimNowResult {
        let start = now().timeIntervalSince1970
        if let busySince = claim(start) { return .alreadyRunning(startedAt: busySince) }
        let report = await withCheckedContinuation { (continuation: CheckedContinuation<TrimReport, Never>) in
            execute(start: start) { continuation.resume(returning: $0) }
        }
        return .started(report)
    }

    /// Starts one pass without waiting for it, unless one is already running.
    /// The lock is taken before this returns, so ``runningSince`` is set at
    /// once and a second call reports the first pass. `done` (tests) runs
    /// after the pass, once the lock is released.
    public func start(done: (@Sendable (TrimReport) -> Void)? = nil) -> TrimStartResult {
        let start = now().timeIntervalSince1970
        if let busySince = claim(start) { return .alreadyRunning(startedAt: busySince) }
        execute(start: start) { report in done?(report) }
        return .started(startedAt: start)
    }

    /// Takes the lock for a pass starting at `start`; returns the running
    /// pass's start instead when there is one.
    private func claim(_ start: Double) -> Double? {
        running.withLock { state in
            if let state { return state }
            state = start
            return nil
        }
    }

    /// Runs the pass on ``queue``, records its outcome, releases the lock, then
    /// hands the report to `completion`.
    private func execute(start: Double, completion: @escaping @Sendable (TrimReport) -> Void) {
        let pass = self.pass
        let deadline = Date(timeIntervalSince1970: start).addingTimeInterval(Self.passSeconds)
        Self.queue.async { [self] in
            let report = pass(deadline)
            failures.withLock { $0 = Self.failuresAfter(report, previous: $0) }
            running.withLock { $0 = nil }
            completion(report)
        }
    }

    /// The failures in a row after `report`: one more for a failed stage, the
    /// same for a pass a bulk load skipped (it proved nothing either way, so
    /// the backoff neither grows nor starts over), none after any other.
    static func failuresAfter(_ report: TrimReport, previous: Int) -> Int {
        if report.error != nil { return previous + 1 }
        if report.waitingFor == TrimService.waitingForBulkLoad { return previous }
        return 0
    }

    /// The real pass: the trim, then (only after a clean one) the reaper until
    /// it is done or the deadline.
    static func runPass(
        database: DaemonDatabase, eventStore: EventStore?, deadline: Date, now: @escaping @Sendable () -> Date,
        capturesWaiting: @Sendable () -> Bool = { false },
        backfillHold: @escaping @Sendable () -> TrimHold? = { nil }
    ) -> TrimReport {
        let historyDays: Int
        do {
            historyDays = try StorageSettings.readHistoryDays(database)
        } catch {
            // Fails closed: trimming to the default window could delete days
            // a longer chosen window keeps. Reported, so the task backs off.
            let stamp = now().timeIntervalSince1970
            logger.error("""
                Trim pass skipped: history window unreadable: \(error.localizedDescription, privacy: .public)
                """)
            return TrimReport(startedAt: stamp, finishedAt: stamp, finished: false,
                              error: "history window unreadable: \(error.localizedDescription)")
        }
        let recount = lateTurnRecount(database, deadline: deadline)
        let service = TrimService(
            database: database,
            eventStore: eventStore,
            historyDays: historyDays,
            coveredThroughDay: { recount == .caughtUp ? coveredThroughDay(database) : nil },
            snapshotsReadThrough: {
                ((try? database.setting(for: DaemonDatabase.usageSummaryResetsSnapshotKey)) ?? nil)
                    .flatMap { Int($0) }
            },
            // Timed turns above the recount cursor are in no summary yet; the
            // trim leaves them for the next pass.
            turnsReadThrough: { (try? database.usageSummaryTurnCursor()) ?? nil },
            // Recorded before anything is deleted, so no refresh rebuilds a
            // day this pass may take turns from (it fails the stage if not).
            willTrimEvents: { cutoff in try database.raiseUsageSummaryTrimmedBefore(cutoff) },
            hold: {
                let billing = try billingHoldDay(database).map {
                    TrimHold(day: $0, reason: TrimService.waitingForBilling)
                }
                return earlierHold(billing, backfillHold())
            },
            // Reported only when the covered day, not the window, sets the cutoff.
            coverageWait: {
                ((try? database.usageSummaryWaitsForResetInstants(now: now())) ?? false)
                    ? waitingForResetInstants : nil
            },
            now: now
        )
        var report: TrimReport
        do {
            report = try service.run(deadline: deadline)
        } catch {
            let stamp = now().timeIntervalSince1970
            report = TrimReport(
                startedAt: stamp, finishedAt: stamp, finished: false, error: error.localizedDescription)
            logger.error("Trim pass failed: \(error.localizedDescription, privacy: .public)")
        }
        report = noting(recount, in: report)
        if let cutoff = reapCutoff(report) {
            if capturesWaiting() {
                logger.info("Empty-session reap skipped: Claude captures are still spooled or quarantined")
            } else {
                reap(database: database, before: cutoff, deadline: deadline)
            }
        }
        return report
    }

    /// What a pass reports while the usage summary waits for a day's
    /// rate-limit reset instants (at most `usageResetWaitLimit` after the day
    /// ends), the covered day standing still behind it.
    static let waitingForResetInstants = "usage reset instants"

    /// The cutoff the reaper may use after `report`, or nil when it must not
    /// run: no cutoff (no watermark yet), a failed stage, a bulk load or a
    /// missing store, or a pass that stopped on its deadline. A billing hold
    /// does not stop it: the held cutoff is the day before every session billing
    /// waits for started, so none of them was last active before it. Nor does
    /// the wait for reset instants: it only keeps the cutoff at the covered day.
    static func reapCutoff(_ report: TrimReport) -> Double? {
        guard let cutoff = report.cutoff, report.finished, report.error == nil,
              report.waitingFor == nil || report.waitingFor == TrimService.waitingForBilling
                || report.waitingFor == waitingForResetInstants else {
            return nil
        }
        return cutoff
    }

    /// Whether any Claude capture has not reached `events.db` yet: records in
    /// the provider spool or its quarantine, events in the legacy spool, or a
    /// history backfill still replaying older archive records (their sessions
    /// are in the main database before their events are in `events.db`). No
    /// pipeline, or a count that cannot be read, counts as waiting.
    ///
    /// A quarantined record the normalizer could not parse does not count
    /// (`ClaudeNormalizerError.permanentReasonPrefixes`): it can never become a
    /// row, so waiting for it would keep the reaper off for good. Its bytes are
    /// in `claude-raw.db` and it stays listed under the ingestion errors.
    static func capturesWaiting(pipeline: ClaudePipelineHandles?, legacySpool: IngestSpool?) -> Bool {
        guard let pipeline else { return true }
        if HistoryBackfill.pending(in: pipeline) { return true }
        do {
            let quarantined = try pipeline.spool.quarantinedCount(
                excludingReasonPrefixes: ClaudeNormalizerError.permanentReasonPrefixes)
            if try pipeline.spool.pendingCount() > 0 || quarantined > 0 { return true }
            if let legacySpool, try legacySpool.status().pending > 0 { return true }
            return false
        } catch {
            logger.error("Could not count waiting captures: \(error.localizedDescription, privacy: .public)")
            return true
        }
    }

    /// Whether every turn `events.db` holds has been read by the usage
    /// summary's late-turn recount, catching it up first (at most until a
    /// minute before `deadline`). A turn that lands on an old, finalized day
    /// (an import, captures released after an outage, a history backfill
    /// slice) is in no summary until the recount reads it, so the trim must
    /// not delete it before then. When the recount is still behind or fails,
    /// the pass has no cutoff and deletes nothing (``noting(_:in:)`` says why).
    ///
    /// A turn that arrives between this check and the delete is not trimmed:
    /// the pass deletes no timed turn above the recount cursor
    /// (`turnsReadThrough`), and the next recount adds it to its day's rows.
    static func lateTurnRecount(_ database: DaemonDatabase, deadline: Date) -> LateTurnRecount {
        let stopAt = deadline.addingTimeInterval(-60)
        do {
            while try !database.recountLateUsageTurns() {
                if Date() >= stopAt {
                    logger.info("Trim waits: the late-turn recount is not caught up yet")
                    return .behind
                }
            }
            return .caughtUp
        } catch {
            logger.error("Late-turn recount failed: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
    }

    /// Whether ``lateTurnRecount(_:deadline:)`` caught up.
    static func lateTurnsRecounted(_ database: DaemonDatabase, deadline: Date) -> Bool {
        lateTurnRecount(database, deadline: deadline) == .caughtUp
    }

    /// Where the late-turn recount stood when a pass began.
    enum LateTurnRecount: Equatable {
        case caughtUp
        /// Still reading at the pass's deadline: another pass continues it.
        case behind
        /// It threw; the message is the error's.
        case failed(String)
    }

    /// What a pass reports when the late-turn recount kept its cutoff away:
    /// not the rollups (whose wait the task checks again a day later) but
    /// the recount, which the task retries after `TrimTask.retrySeconds`.
    static let waitingForLateTurns = "late turns"

    /// `report`, saying why a recount that did not catch up left it with no
    /// cutoff: "late turns" in place of the "rollups" wait it caused, and for
    /// a recount that threw, an error, so the task backs off and /storage
    /// shows it.
    static func noting(_ recount: LateTurnRecount, in report: TrimReport) -> TrimReport {
        guard recount != .caughtUp else { return report }
        var report = report
        if report.waitingFor == nil || report.waitingFor == TrimService.waitingForRollups {
            report.waitingFor = waitingForLateTurns
        }
        if case .failed(let message) = recount {
            let failure = "late-turn recount: \(message)"
            report.error = report.error.map { "\($0); \(failure)" } ?? failure
            report.finished = false
        }
        return report
    }

    /// The last day the rollups let the trim reach: the earlier watermark. Nil
    /// while either is missing: then the trim deletes nothing. Billing holds it
    /// back further through the pass's `hold` (``billingHoldDay(_:)``), which
    /// the report names as `waitingFor: "billing"`.
    static func coveredThroughDay(_ database: DaemonDatabase) -> String? {
        guard let stats = (try? database.rollupFinalizedThrough()) ?? nil,
              let usage = (try? database.usageSummaryFinalizedThrough()) ?? nil else { return nil }
        return min(stats, usage)
    }

    /// The day before the earliest start of a session billing has never derived
    /// (or forgot, after a replay of older events): its events must stay until
    /// `BillingTask` turns them into segments. Nil when no session waits. A
    /// failed read throws, and the pass then deletes nothing (it fails closed).
    ///
    /// So does a waiting session whose `started_at` SQLite cannot read as a
    /// date (N2): its start, and so the day to hold back to, is unknown, and a
    /// malformed value would otherwise drop out of `MIN` (or sort after every
    /// real date) and leave its events unprotected.
    /// The billing hold's read. `billing_derived_at <> last_activity_at` is
    /// implied by the two terms before it and adds no row; it is there because
    /// SQLite uses the partial index `idx_sessions_billing_pending` only when
    /// the query repeats the index's `WHERE`. Without it every trim pass walked
    /// every session, and on a slow disk that ran past the 10 s read deadline,
    /// so the pass deleted nothing ("billing unreadable").
    static let billingHoldSQL = """
        SELECT date(MIN(started_at), '-1 day'), COALESCE(SUM(date(started_at) IS NULL), 0) FROM sessions
        WHERE billing_derived_at = '' AND last_activity_at <> '' AND started_at <> ''
          AND billing_derived_at <> last_activity_at
        """

    static func billingHoldDay(_ database: DaemonDatabase) throws -> String? {
        guard try database.tableHasColumn("sessions", "billing_derived_at") else { return nil }
        var day: String?
        var unreadable = 0
        try database.query(billingHoldSQL) { row in
            let value = database.string(row, 0)
            day = value.isEmpty ? nil : value
            unreadable = database.int(row, 1)
        }
        if unreadable > 0 { throw BillingHoldError.unreadableStart(sessions: unreadable) }
        return day
    }

    /// The hold that keeps more: the earlier day (a tie keeps `first`).
    static func earlierHold(_ first: TrimHold?, _ second: TrimHold?) -> TrimHold? {
        guard let first else { return second }
        guard let second else { return first }
        return second.day < first.day ? second : first
    }

    /// Why ``billingHoldDay(_:)`` could not name a day.
    enum BillingHoldError: Error, LocalizedError, Equatable {
        /// Sessions billing waits for whose `started_at` is not a date.
        case unreadableStart(sessions: Int)

        var errorDescription: String? {
            switch self {
            case .unreadableStart(let sessions):
                return "\(sessions) session(s) waiting for billing have a start time that is not a date"
            }
        }
    }

    /// Empty ended sessions last active before `cutoff`, in batches, until none
    /// remain or the deadline.
    private static func reap(database: DaemonDatabase, before cutoff: Double, deadline: Date) {
        let reaper = RetentionService(
            database: database, lastActivityBefore: cutoff, keepSessionTables: reaperKeepTables)
        do {
            // The deadline is checked first, so no batch starts after it.
            while Date() < deadline, try reaper.runOnce() == .rerun {}
        } catch {
            logger.error("Empty-session reap failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension StorageController: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
