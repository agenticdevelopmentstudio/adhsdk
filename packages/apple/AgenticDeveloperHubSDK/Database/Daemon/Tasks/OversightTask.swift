#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Drives session oversight on a schedule: each run is one `OversightService.tick`,
/// which snapshots the live fleet, runs every enabled `SessionObserver` over it and
/// reconciles their findings into the `oversight_findings` store. The engine lives in
/// `AgenticDeveloperHubSDKDatabase`; this is only the DaemonKit schedule around it.
///
/// Gated on `oversight_enabled` (default off) inside the tick.
public struct OversightTask: SessionDaemonTask {
    public static let taskName = "oversight"
    public let name = Self.taskName
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    /// Builds the tick's observers — one per enabled stored script, sharing a fresh
    /// LLM budget. Injectable so tests substitute canned observers.
    let makeObservers: @Sendable (DaemonDatabase) -> [any SessionObserver]

    public init(
        database: DaemonDatabase,
        intervalSeconds: TimeInterval = 120,
        makeObservers: (@Sendable (DaemonDatabase) -> [any SessionObserver])? = nil
    ) {
        self.database = database
        self.makeObservers = makeObservers ?? { daemonDatabase in
            OversightService.defaultObservers(database: daemonDatabase, analyzer: .live)
        }
        self.schedule = SessionTaskSchedule(
            intervalSeconds: intervalSeconds,
            enabled: true,
            timeout: 120,
            backoffOnFailure: true
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        await OversightService.tick(database: database.db, makeObservers: makeObservers)
        return .empty
    }
}
#endif
