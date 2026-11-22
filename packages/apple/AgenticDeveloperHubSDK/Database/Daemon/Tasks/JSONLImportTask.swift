#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Periodically sweeps Claude Code's JSONL transcripts (`~/.claude/projects/`)
/// into the Claude pipeline's spool and wakes its drainer, which writes the raw
/// archive (claude-raw.db) and the event store (events.db).
///
/// The transcript source owns the per-file cursors and the sweep watermark, so a
/// pass only reads what is new; a file that fails holds the watermark and is
/// offered again on the next sweep. The legacy `JSONLImporter` (event_log,
/// transcript_turns) no longer runs here.
///
/// Without a Claude pipeline (its files failed to open and the runtime is
/// retrying) a pass reads nothing: the lines stay on disk behind the source's
/// cursors until the pipeline opens.
///
/// Default interval is 5 minutes: short enough that a live session's turns show
/// up promptly between the tailer's per-file wakes, long enough to be invisible
/// cost-wise on a quiet machine.
public struct JSONLImportTask: SessionDaemonTask {
    public static let taskName = "jsonl-import"
    public let name = Self.taskName
    public let schedule: SessionTaskSchedule
    /// The Claude provider pipeline the sweep feeds, read on every pass.
    let claude: ClaudePipelineSlot

    /// How long one pass sweeps before handing back to the scheduler.
    static let sweepBudget: Duration = .seconds(600)

    public init(claude: ClaudePipelineSlot, checkInterval: TimeInterval = 300) {
        self.claude = claude
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            // Above the sweep budget, so a pass that spends all of it ends on its
            // own terms rather than being cut off by the scheduler.
            timeout: 660,
            backoffOnFailure: true
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        guard let claude = claude.current else {
            if self.claude.shouldReportUnavailable() {
                logger.error("Claude pipeline not open; transcripts wait on disk until it opens")
            }
            return .empty
        }
        return try sweep(claude, budget: Self.sweepBudget)
    }

    /// Sweeps the transcripts into the Claude spool until a sweep finds nothing new
    /// or the budget is spent. Each sweep that appended wakes the drainer, so the
    /// drain runs alongside rather than after. Out of budget with work left, the
    /// task asks to run again at once.
    func sweep(_ claude: ClaudePipelineHandles, budget: Duration) throws -> SessionTaskResult {
        let deadline = ContinuousClock.now.advanced(by: budget)
        var appended = 0
        while true {
            let count = try claude.pollTranscripts()
            appended += count
            if count == 0 { break }
            if ContinuousClock.now >= deadline {
                logger.info("Transcript sweep out of budget — lines=\(appended); rescheduling")
                return .rerunImmediately
            }
        }
        if appended > 0 {
            logger.debug("Transcript sweep done — lines=\(appended)")
        }
        return .empty
    }
}

extension JSONLImportTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
