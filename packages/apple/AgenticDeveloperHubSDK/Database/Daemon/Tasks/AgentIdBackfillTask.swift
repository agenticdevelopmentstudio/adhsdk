#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Gives the subagent messages stored before the normalizer kept
/// `attrs.agent_id` their agent id, read back from `claude-raw.db`
/// (`ClaudePipelineHandles.backfillSubagentAgentIds`). Without it the
/// conversation view's work lines cannot say which agent wrote an older line.
///
/// Walks the messages in chunks behind a cursor in `events.db`'s `store_meta`,
/// within a budget per pass; out of budget it runs again at once. Once the walk
/// finishes it marks itself done there, and every later pass returns at once.
/// Without a Claude pipeline a pass does nothing and waits for it to open.
public struct AgentIdBackfillTask: SessionDaemonTask {
    public static let taskName = "agent-id-backfill"
    public let name = Self.taskName
    public let schedule: SessionTaskSchedule
    let claude: ClaudePipelineSlot

    /// How long one pass works before handing back to the scheduler.
    static let budget: Duration = .seconds(120)

    public init(claude: ClaudePipelineSlot, checkInterval: TimeInterval = 3600) {
        self.claude = claude
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 180,
            backoffOnFailure: true
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        guard let claude = claude.current else { return .empty }
        return try backfill(claude, budget: Self.budget)
    }

    func backfill(_ claude: ClaudePipelineHandles, budget: Duration) throws -> SessionTaskResult {
        let deadline = ContinuousClock.now.advanced(by: budget)
        var looked = 0
        while try !claude.agentIdBackfillDone() {
            looked += try claude.backfillSubagentAgentIds()
            if ContinuousClock.now >= deadline, try !claude.agentIdBackfillDone() {
                logger.info("Agent id backfill out of budget — messages=\(looked); rescheduling")
                return .rerunImmediately
            }
        }
        if looked > 0 { logger.info("Agent id backfill finished — messages=\(looked)") }
        return .empty
    }
}

extension AgentIdBackfillTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
