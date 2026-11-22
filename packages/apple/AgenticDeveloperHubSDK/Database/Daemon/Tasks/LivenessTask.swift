#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Schedules the toolkit's ``LivenessService``: session status reconciled against
/// live `claude` processes, every `checkInterval` (default 10s). The reconciliation
/// rules live in the service; this adapter owns the schedule and the broadcast hook.
/// Conforms to `SessionDaemonTask`.
public struct LivenessTask: SessionDaemonTask {
    public typealias LiveClaudeProcess = LivenessService.LiveClaudeProcess

    public let name = "liveness"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    let onStatusChange: @Sendable (String, SessionStatus) -> Void
    /// The running `claude` processes, or `nil` if process enumeration failed.
    /// Injected so tests need no real processes.
    let liveProcesses: @Sendable () -> [LiveClaudeProcess]?

    public init(
        database: DaemonDatabase,
        checkInterval: TimeInterval = 10,
        liveProcesses: @escaping @Sendable () -> [LiveClaudeProcess]? = ProcessLiveness.liveClaudeProcesses,
        onStatusChange: @escaping @Sendable (String, SessionStatus) -> Void
    ) {
        self.database = database
        self.liveProcesses = liveProcesses
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 30,
            backoffOnFailure: false
        )
        self.onStatusChange = onStatusChange
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        LivenessService(
            database: database.db, liveProcesses: liveProcesses, onStatusChange: onStatusChange
        ).reconcile()
        return .empty
    }
}
#endif
