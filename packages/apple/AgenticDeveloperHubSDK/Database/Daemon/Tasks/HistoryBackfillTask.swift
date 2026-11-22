#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import os
import Foundation

/// Runs the history backfill (``HistoryBackfill``) a slice at a time, with a
/// trim pass after a slice at most every ``trimSpacingSeconds``, so the older
/// history it replays into `events.db` is trimmed as it lands instead of
/// piling up first.
///
/// Idle (hourly check) when no backfill is pending: only a cutover sets one,
/// and the daemon is stopped while it does. While one is pending: a slice of
/// ``HistoryBackfill/sliceSeconds``, the trim when one is due, then the next
/// slice after ``pauseSeconds``. A failed slice retries after ``retrySeconds``; what it
/// committed stays, and the next slice resumes after it.
public struct HistoryBackfillTask: SessionDaemonTask {
    /// The wait between slices, so other work gets the databases.
    static let pauseSeconds: TimeInterval = 15
    /// The wait after a failed slice, or while the pipeline is not open.
    static let retrySeconds: TimeInterval = 300
    /// The least time between two trims after progressing slices: every third
    /// slice. A trim after every slice spent up to its 300 s bound (vacuums,
    /// the reaper's scan, the hold's frontier read) on each 600 s of replay and
    /// contended with the replay for the one disk; spacing them leaves more of
    /// the hour to the replay, and each trim still deletes all the replayed
    /// history the hold allows. The slice that finishes always trims.
    static let trimSpacingSeconds: TimeInterval = 1800

    public let name = "history-backfill"
    public let schedule: SessionTaskSchedule
    let storage: StorageController
    /// The cursor the last trim followed, so a slice that replayed nothing
    /// new does not start another pass, and when that trim ran.
    private let lastTrim = OSAllocatedUnfairLock<(cursor: Int64?, at: Date?)>(initialState: (nil, nil))
    private let now: @Sendable () -> Date

    public init(storage: StorageController, checkInterval: TimeInterval = 3600,
                now: @escaping @Sendable () -> Date = Date.init) {
        self.storage = storage
        self.now = now
        // A slice, then a trim pass, each with its own bound.
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: HistoryBackfill.sliceSeconds + StorageController.passSeconds + 300,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        guard let backfill = storage.backfill else { return .empty }
        let outcome = await backfill.runSlice()
        let current = now()
        let trim = lastTrim.withLock { last -> Bool in
            let (trim, next) = Self.trimDecision(
                after: outcome, previous: last.cursor,
                sinceLastTrim: last.at.map { current.timeIntervalSince($0) })
            last.cursor = next
            if trim { last.at = current }
            return trim
        }
        if trim {
            // A trim already running covers it; either way the next slice waits.
            _ = await storage.trimNow()
        }
        return Self.result(for: outcome)
    }

    /// Whether `outcome` calls for a trim pass, and the cursor to remember:
    /// a slice that moved the cursor past `previous` (the one the last trim
    /// followed) does once ``trimSpacingSeconds`` have passed since the last
    /// trim (`sinceLastTrim`, nil before the first), and the slice that
    /// finishes the backfill always does; a slice that replayed nothing new,
    /// or no slice at all, does not. A trim not yet due keeps `previous`, so
    /// the next slice past it still counts as new.
    static func trimDecision(
        after outcome: HistoryBackfill.SliceOutcome, previous: Int64?,
        sinceLastTrim: TimeInterval? = nil
    ) -> (trim: Bool, remember: Int64?) {
        switch outcome {
        case .finished(let id):
            return (true, id)
        case .progressed(let id):
            if let previous, id <= previous { return (false, previous) }
            if let sinceLastTrim, sinceLastTrim < trimSpacingSeconds { return (false, previous) }
            return (true, id)
        case .unavailable, .idle, .busy, .failed:
            return (false, previous)
        }
    }

    static func result(for outcome: HistoryBackfill.SliceOutcome) -> SessionTaskResult {
        switch outcome {
        case .idle, .finished:
            return .empty
        case .progressed, .busy:
            return SessionTaskResult(nextRunSeconds: pauseSeconds)
        case .unavailable, .failed:
            return SessionTaskResult(nextRunSeconds: retrySeconds)
        }
    }
}

extension HistoryBackfillTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
