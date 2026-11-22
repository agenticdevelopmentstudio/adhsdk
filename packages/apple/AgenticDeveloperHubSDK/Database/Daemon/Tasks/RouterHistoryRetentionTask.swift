#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Ages out the account router's request history (`account_router_exchange`).
///
/// Always on, like `TrimTask`, but with its own window: `retentionDays`, which
/// the daemon passes in (the router's `account_router_retention_days` setting)
/// and which is read fresh on every run, so a change in the settings panel
/// applies at the next run. 0 keeps everything.
///
/// Chunked like `TrimTask`: a full batch returns `.rerunImmediately`, so a
/// large first prune drains in short steps instead of holding the DB queue.
public struct RouterHistoryRetentionTask: SessionDaemonTask {
    public let name = "router-history-retention"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    let retentionDays: @Sendable (DaemonDatabase) -> Int
    let now: @Sendable () -> Date

    public init(
        database: DaemonDatabase,
        retentionDays: @escaping @Sendable (DaemonDatabase) -> Int,
        checkInterval: TimeInterval = 86400,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.database = database
        self.retentionDays = retentionDays
        self.now = now
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 120,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        let days = retentionDays(database)
        guard days > 0 else { return .empty }
        do {
            let deleted = try database.deleteOldRouterExchanges(olderThanDays: days, now: now())
            if deleted > 0 {
                logger.debug("Router history retention deleted \(deleted) exchange(s)")
            }
            if deleted >= DaemonDatabase.routerPruneBatch {
                return .rerunImmediately
            }
        } catch {
            logger.error("Router history retention failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
        return .empty
    }
}

extension RouterHistoryRetentionTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
