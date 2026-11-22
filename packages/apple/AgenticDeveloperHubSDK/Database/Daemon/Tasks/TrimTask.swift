#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Schedules the daily storage trim through ``StorageController/trimNow()``,
/// the same entry point "Trim Now" uses, so a scheduled pass and a manual one
/// never run at once.
///
/// **Always on.** Unlike the opt-in `RetentionTask` it replaces, the trim keeps
/// `event_history_days` of history (default 30, read fresh on every pass), and
/// it never deletes a day the rollups have not frozen: with a watermark
/// missing it deletes nothing and reports "rollups".
///
/// **Chunked, and never a day late.** A pass stops after 300 s; one that ran
/// out of time returns `.rerunImmediately` and the next continues from the same
/// cutoff, held by billing or not. One that a bulk load left unfinished retries
/// after ``retrySeconds``, as does a finished one billing held back, one whose
/// billing hold could not be read, one the late-turn recount had not caught up
/// for, and a run that found a pass already going (a
/// "Trim Now" that may itself stop on its deadline). One a failed stage cut
/// short backs off: 600 s after the first failure in a row, doubling each time
/// up to ``maxRetrySeconds``, back to normal after a pass with no error (a bulk
/// load skip leaves the count as it was).
///
/// **Stands back during a history backfill.** `HistoryBackfillTask` trims
/// between its slices (every third one), and the older history it replays
/// always leaves this task more to delete, so an immediate rerun never stopped and ran on top of every
/// slice, the two sharing one disk. While a backfill is pending and its last
/// slice did not fail, this task checks back after ``backfillCheckSeconds``
/// instead. After a failed slice it runs, but a pass that ran out of time
/// waits ``retrySeconds`` rather than rerun at once, so the backfill's retry
/// does not meet a trim already going (a slice starved that way read nothing
/// for 339 s). "Trim Now" is unaffected.
public struct TrimTask: SessionDaemonTask {
    /// The wait before retrying a pass a bulk load or a first failure cut
    /// short, or after finding one already running.
    static let retrySeconds: TimeInterval = 600
    /// The longest wait between retries of a pass that keeps failing.
    static let maxRetrySeconds: TimeInterval = 6 * 3600
    /// The wait while a history backfill runs its own trims: short, because
    /// once the backfill finishes the trim it held back has a backlog, and an
    /// hour's wait left it idle that long.
    static let backfillCheckSeconds: TimeInterval = retrySeconds

    public let name = "storage-trim"
    public let schedule: SessionTaskSchedule
    let storage: StorageController

    public init(storage: StorageController, checkInterval: TimeInterval = 86400) {
        self.storage = storage
        // Above the pass's own 300 s bound, which includes the reaper and the vacuums.
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: StorageController.passSeconds + 300,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        let backfill = storage.backfill?.status()
        if Self.defersToBackfill(backfill) {
            logger.info("Storage trim deferred: the history backfill runs its own trims between slices")
            return SessionTaskResult(nextRunSeconds: Self.backfillCheckSeconds)
        }
        switch await storage.trimNow() {
        case .alreadyRunning(let startedAt):
            logger.info("Storage trim deferred: a pass started at \(startedAt) is still running")
            return SessionTaskResult(nextRunSeconds: Self.retrySeconds)
        case .started(let report):
            return Self.paced(
                Self.result(for: report, consecutiveFailures: storage.consecutiveFailures),
                backfill: backfill)
        }
    }

    /// `.empty` for a finished pass; an immediate rerun for one that only ran
    /// out of time, billing hold or not; a short retry for one a bulk load cut
    /// short, one billing held back that finished, one whose hold could not
    /// be read, or one the late-turn recount was behind for; for one a failure
    /// cut short, ``failureRetrySeconds(_:)`` of the failures in a row.
    static func result(for report: TrimReport, consecutiveFailures: Int = 1) -> SessionTaskResult {
        if report.error != nil {
            return SessionTaskResult(nextRunSeconds: failureRetrySeconds(consecutiveFailures))
        }
        switch report.waitingFor ?? "" {
        case TrimService.waitingForBulkLoad, TrimService.waitingForBillingUnreadable,
             StorageController.waitingForLateTurns:
            // Nothing was deleted and there is no cutoff to continue from: retry
            // soon, not a day later and not in a tight loop. (The late-turn
            // recount only needs another slice.)
            return SessionTaskResult(nextRunSeconds: retrySeconds)
        case TrimService.waitingForBilling where report.finished:
            // Trimmed up to the held day: the rest becomes trimmable as soon as
            // `BillingTask` derives the waiting sessions.
            return SessionTaskResult(nextRunSeconds: retrySeconds)
        default:
            // A held pass that ran out of time continues from its cutoff at once,
            // like any other (R3).
            if report.finished {
                // Every row is gone but the vacuum ran out of time with much of
                // events.db still free pages: come back soon to keep vacuuming,
                // rather than reclaiming one pass's worth a day.
                return report.vacuumPending ? SessionTaskResult(nextRunSeconds: retrySeconds) : .empty
            }
            return .rerunImmediately
        }
    }

    /// Whether a pending backfill does the trimming: yes while one is pending
    /// and its last slice ended cleanly; no when none is pending or its slices
    /// are failing, since a failed slice starts no trim.
    static func defersToBackfill(_ backfill: HistoryBackfillDTO?) -> Bool {
        guard let backfill else { return false }
        return backfill.lastError == nil
    }

    /// `result` while a backfill is pending: an immediate rerun waits
    /// ``retrySeconds`` (the two take turns on the disk), and any longer wait,
    /// a finished pass's day included, is cut to ``backfillCheckSeconds``, so
    /// the backlog the backfill leaves is trimmed (and the reaper, off until
    /// it finishes, runs) soon after it ends rather than a day later.
    static func paced(_ result: SessionTaskResult, backfill: HistoryBackfillDTO?) -> SessionTaskResult {
        guard backfill != nil else { return result }
        guard let next = result.nextRunSeconds, next > 0 else {
            return SessionTaskResult(nextRunSeconds: retrySeconds)
        }
        return SessionTaskResult(nextRunSeconds: min(next, backfillCheckSeconds))
    }

    /// 600 s after the first failure in a row, doubling, never above 6 h.
    static func failureRetrySeconds(_ failures: Int) -> TimeInterval {
        let doublings = min(max(failures, 1) - 1, 16)
        return min(retrySeconds * pow(2, Double(doublings)), maxRetrySeconds)
    }
}

extension TrimTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
