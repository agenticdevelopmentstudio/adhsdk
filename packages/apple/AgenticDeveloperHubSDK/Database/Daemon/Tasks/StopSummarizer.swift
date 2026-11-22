#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

/// Summarizes the session that has just stopped speaking, if it needs one.
///
/// `Stop` is the moment the transcript is complete for this turn, which is the
/// answer to "isn't the transcript available?": it is, and waiting for the next
/// `SummarizeTask` pass to notice was the whole delay. That pass runs every
/// `summary_interval_minutes` and takes `maxPerRun` sessions at a time, so a
/// session's first summary arrived an interval or more after the work it
/// describes — and behind a backlog of ~1,300 historical sessions sharing the
/// same slots.
///
/// This does not replace the batch: it front-runs it for the sessions the user is
/// actually watching, and whatever it declines to do the batch still sweeps up.
public final class StopSummarizer: Sendable {
    private let database: DaemonDatabase
    /// Built by the runtime, so the summaries default has one source: the configuration.
    private let summarizer: DaemonSessionSummarizer

    /// The single slot the `Stop`-hook summary path runs in.
    ///
    /// It refuses rather than queues. A fleet of sessions all stopping at once would
    /// otherwise start a model call per session — and local inference runs serially
    /// regardless, so the queue would only buy memory pressure and a pile of calls
    /// describing state that has since moved on. A refusal costs at most one
    /// `SummarizeTask` interval, because that pass sweeps exactly what this skips.
    private actor SummaryGate {
        private var busy = false
        func acquire() -> Bool {
            if busy { return false }
            busy = true
            return true
        }
        func release() { busy = false }
    }

    private static let summaryGate = SummaryGate()

    public init(database: DaemonDatabase, summarizer: DaemonSessionSummarizer) {
        self.database = database
        self.summarizer = summarizer
    }

    public func summarizeIfNeeded(sessionId: String) async {
        guard summarizer.isEnabled(database.db),
              (try? database.sessionNeedsSummary(sessionId: sessionId)) == true,
              await Self.summaryGate.acquire() else { return }
        defer { Task { await Self.summaryGate.release() } }
        do {
            try await DaemonSessionSummarizer.summarizeAndStore(
                sessionId: sessionId, database: database.db
            )
        } catch {
            // Never fatal, and never retried here — the scheduled pass owns retries.
            Self.logger.debug("Prompt summarize skipped: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension StopSummarizer: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
