#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Fills `conversation_queued_prompts` for the transcript lines stored before
/// migration044, so the Conversations feed shows the prompts typed mid-turn in
/// old conversations too, not only in new ones.
///
/// A task rather than a migration because finding those prompts means reading
/// the attachments' `raw_json`, measured at 98s over the whole table, and a
/// migration holds up the daemon's start. Here it runs in batches after the
/// daemon is serving. The scheduler starts it at launch and `.rerunImmediately`
/// keeps it going until the history is covered, after which each run returns
/// at once. See ``DaemonDatabase/backfillQueuedPromptsBatch(idSpan:)``.
public struct QueuedPromptBackfillTask: SessionDaemonTask {
    public let name = "queued-prompt-backfill"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase

    public init(database: DaemonDatabase, checkInterval: TimeInterval = 3600) {
        self.database = database
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 120,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        database.backfillQueuedPromptsBatch() ? .rerunImmediately : .empty
    }
}

extension QueuedPromptBackfillTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
