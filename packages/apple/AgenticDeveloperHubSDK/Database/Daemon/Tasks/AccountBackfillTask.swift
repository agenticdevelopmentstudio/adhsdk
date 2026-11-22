#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// One-shot-then-idle historical account attribution backfill.
///
/// Fills `sessions.account_email` / `auth_method` for rows that predate
/// source-tagged stamping: tags pre-existing token emails `token`, and recovers
/// ENDED empty sessions from sibling tables (`session_metrics` →
/// `rate_limit_snapshots` → `transcript_turns`), tagging them `unknown`. Runs in
/// bounded batches off the startup path (never a migration), so it can't wedge
/// startup; the scheduler seeds `nextRun=now`, so the first batch runs promptly
/// at launch and `.rerunImmediately` drains the backlog in chunks. Idempotent —
/// once drained, each processed row has a non-empty `auth_method` and is never
/// re-scanned. Active sessions are untouched (they self-heal via hooks).
public struct AccountBackfillTask: SessionDaemonTask {
    public let name = "account-backfill"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    let batchSize: Int

    public init(database: DaemonDatabase, checkInterval: TimeInterval = 3600, batchSize: Int = 200) {
        self.database = database
        self.batchSize = batchSize
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 120,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        let processed = database.backfillSessionAuthAttributionBatch(limit: batchSize)
        if processed > 0 {
            logger.info("account-backfill: processed=\(processed, privacy: .public)")
            return .rerunImmediately
        }
        return .empty
    }
}

extension AccountBackfillTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
