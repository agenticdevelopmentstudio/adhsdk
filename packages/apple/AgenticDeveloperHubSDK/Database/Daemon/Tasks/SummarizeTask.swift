#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import OSLog
import Foundation

/// Autonomously generates AI summaries for ended sessions that don't have one yet —
/// so a running history of what sessions were doing accrues even when the app isn't
/// running. Only fills *empty* summaries, so it never clobbers a Claude Code
/// custom-title set by `SessionEnricher`. Gated on `ai_summaries_enabled` (default on).
public struct SummarizeTask: SessionDaemonTask {
    public static let taskName = "summarize"
    public let name = Self.taskName
    let database: DaemonDatabase
    /// Built by the runtime, so the summaries default has one source: the configuration.
    let summarizer: DaemonSessionSummarizer
    /// Overrides for tests; `nil` = read the user's setting live.
    private let intervalOverride: TimeInterval?
    private let maxPerRunOverride: Int?

    /// Caches the interval read so `schedule` stays cheap — see `intervalCache`.
    private let intervalCache = IntervalCache()

    /// Computed, not stored: `Scheduler` re-reads the interval when it reschedules,
    /// so a change in Settings → AI Summaries is honored once the currently armed
    /// interval elapses — no daemon restart, but no earlier than that either.
    ///
    /// `Scheduler` and `TimingStrategy` touch this from inside the scheduler actor,
    /// and `/health` (polled every 5s by the app) reads `enabled` through
    /// `snapshot()`, so the settings read is cached: blocking SQLite inside the
    /// actor would serialize every other task's scheduling behind it.
    public var schedule: SessionTaskSchedule {
        SessionTaskSchedule(
            intervalSeconds: intervalOverride
                ?? intervalCache.value { SummaryPrefs.intervalSeconds(database.db) },
            enabled: true,
            timeout: 120,
            backoffOnFailure: true
        )
    }

    var maxPerRun: Int { maxPerRunOverride ?? SummaryPrefs.maxPerRun(database.db) }

    public init(
        database: DaemonDatabase,
        summarizer: DaemonSessionSummarizer,
        intervalSeconds: TimeInterval? = nil,
        maxPerRun: Int? = nil
    ) {
        self.database = database
        self.summarizer = summarizer
        self.intervalOverride = intervalSeconds
        self.maxPerRunOverride = maxPerRun
    }

    /// Memoizes the interval for `ttl` seconds. A `SessionDaemonTask` is a value type the
    /// scheduler copies freely, so the cache is a reference the copies share.
    /// The TTL bounds how stale a reschedule's interval can be; it is far shorter
    /// than the shortest selectable interval (1 minute).
    final class IntervalCache: @unchecked Sendable {
        private static let ttl: TimeInterval = 15
        private let lock = NSLock()
        private var cached: TimeInterval?
        private var readAt = Date.distantPast

        func value(_ read: () -> TimeInterval) -> TimeInterval {
            lock.lock()
            if let cached, Date().timeIntervalSince(readAt) < Self.ttl {
                lock.unlock()
                return cached
            }
            lock.unlock()

            // Read outside the lock: it touches SQLite, and a duplicate read under
            // contention is cheaper than holding a lock across I/O.
            let fresh = read()

            lock.lock()
            cached = fresh
            readAt = Date()
            lock.unlock()
            return fresh
        }
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        guard summarizer.isEnabled(database.db) else { return .empty }

        // One snapshot for the whole pass: the knobs are global, and re-reading them
        // per session (around an `await`) let one pass prompt with one word count
        // and truncate the reply to another.
        let settings = SummaryPrefs.snapshot(database.db)
        let limit = maxPerRunOverride ?? settings.maxPerRun
        let needing = (try? database.fetchSessionIdsNeedingSummary(limit: limit)) ?? []
        guard !needing.isEmpty else { return .empty }

        var done = 0
        for sessionId in needing {
            // A pass can legitimately run 50 sessions × a 600s timeout. Without this,
            // shutdown (`Scheduler.drain()` awaits in-flight tasks) would block until
            // launchd loses patience and SIGKILLs the daemon mid-write.
            if Task.isCancelled {
                logger.notice("Summarize cancelled after \(done, privacy: .public) session(s)")
                break
            }
            do {
                try await DaemonSessionSummarizer.summarizeAndStore(
                    sessionId: sessionId, database: database.db, settings: settings
                )
                done += 1
            } catch let error as AIGuardError {
                // The guard refused local inference (model over budget / memory
                // pressure). Every remaining session hits the same wall this tick —
                // halt instead of writing one refusal row per session.
                logger.notice("Summarize halted by guard: \(error.localizedDescription, privacy: .public)")
                break
            } catch {
                logger.debug("Summarize skipped: \(error.localizedDescription, privacy: .public)")
            }
        }
        if done > 0 { logger.info("Autonomously summarized \(done) session(s)") }
        // Drain gently — at most maxPerRun per interval — so a backlog of un-summarized
        // sessions never bursts a pile of model calls at once.
        return .empty
    }
}

extension SummarizeTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
