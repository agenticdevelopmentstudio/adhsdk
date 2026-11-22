#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Self-healing retry of quarantined ingestion failures.
///
/// Periodically re-feeds quarantined events (those `IngestionHandler` couldn't
/// ingest) back through the ingest path. Each pass retries a small bounded batch
/// of the **non-exhausted** files (least-recently-attempted first) so it never
/// holds up live or concurrent ingestion. Every failed retry bumps the file's
/// `retryCount`; once it reaches the configured max the file is left alone (and
/// the menubar badge lights) until a user-driven "Retry All".
///
/// Because the scheduler seeds every task with `nextRun = now`, the first batch
/// also runs promptly at launch — satisfying "retry on launch" — and then every
/// `checkInterval` thereafter. No `backoffOnFailure`: the work is intentionally
/// gentle and idempotent, so a slow interval is the throttle, not exponential
/// backoff.
public struct IngestionRetryTask: SessionDaemonTask {
    public let name = "ingestion-retry"
    public let schedule: SessionTaskSchedule
    let quarantine: QuarantineService
    let parse: @Sendable (String) -> ParseResult
    let ingest: @Sendable (ParsedEvent) throws -> Void
    let batchSize: Int

    public init(
        quarantine: QuarantineService,
        parse: @escaping @Sendable (String) -> ParseResult,
        ingest: @escaping @Sendable (ParsedEvent) throws -> Void,
        checkInterval: TimeInterval = 300,
        batchSize: Int = 25
    ) {
        self.quarantine = quarantine
        self.parse = parse
        self.ingest = ingest
        self.batchSize = batchSize
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 120,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        let outcome = quarantine.retryDueBatch(limit: batchSize, parse: parse, ingest: ingest)
        if outcome.recovered > 0 || outcome.stillFailing > 0 {
            logger.info("""
                ingestion-retry: recovered=\(outcome.recovered, privacy: .public) \
                stillFailing=\(outcome.stillFailing, privacy: .public) \
                remaining=\(outcome.remaining, privacy: .public)
                """)
        }
        return .empty
    }
}

extension IngestionRetryTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
