#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// `GET /storage`, `POST /storage/trim` and `POST /storage/preferences`: the
/// history window, each database file's size, the last trim's report, a way to
/// start a trim pass, and a way to change the window.
public enum StorageRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /storage",
        "POST /storage/trim",
        "POST /storage/preferences"
    ]

    /// - Parameters:
    ///   - database: the main database, whose directory holds the files listed.
    ///   - storage: the trim controller, late-bound because a daemon builds it
    ///     after its migration; nil makes `POST /storage/trim` a 503.
    ///   - claudePipeline: `events.db`'s size and `claude_pipeline`; nil leaves
    ///     both out.
    public static func table(
        database: DaemonDatabase,
        storage: @escaping @Sendable () -> StorageController?,
        claudePipeline: ClaudePipelineSlot?
    ) -> RouteTable {
        RouteTable([
            RouteTable.route("GET", where: { $0 == ["storage"] }) { _, _ in
                .json(StorageStatusReader.status(
                    database: database, storage: storage(), claudePipeline: claudePipeline))
            },
            // Starts a pass and answers at once: 202 and the status when it
            // started one, 409 and the status when one was already running.
            RouteTable.route("POST", where: { $0 == ["storage", "trim"] }) { _, _ in
                guard let controller = storage() else {
                    return .error("Storage trimming is not available", status: 503)
                }
                let started: Bool
                switch controller.start() {
                case .started: started = true
                case .alreadyRunning: started = false
                }
                return .json(
                    StorageStatusReader.status(
                        database: database, storage: controller, claudePipeline: claudePipeline,
                        trimStarted: started),
                    status: started ? 202 : 409
                )
            },
            // Stores the history window (`StoragePreferencesRequestDTO`,
            // snapped to an allowed value) and answers the new status. Zero or
            // fewer days is not a window: 400, never snapped up. The next trim
            // pass reads the window; this does not start one.
            RouteTable.route("POST", where: { $0 == ["storage", "preferences"] }) { request, _ in
                guard let body = try? StenographerWire.decoder()
                    .decode(StoragePreferencesRequestDTO.self, from: request.body)
                else {
                    return .error(#"the body must be {"history_days": <days>}"#, status: 400)
                }
                guard StorageHistoryWindow.accepts(body.historyDays) else {
                    return .error("history_days must be at least 1", status: 400)
                }
                do {
                    try StorageSettings.setHistoryDays(body.historyDays, database)
                } catch {
                    return .error("could not store the history window: \(error.localizedDescription)", status: 500)
                }
                return .json(StorageStatusReader.status(
                    database: database, storage: storage(), claudePipeline: claudePipeline))
            }
        ])
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
