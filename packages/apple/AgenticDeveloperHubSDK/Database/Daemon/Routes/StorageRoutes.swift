#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// `GET /storage` and `POST /storage/trim`: the history window, each database
/// file's size, the last trim's report, and a way to start a trim pass.
public enum StorageRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /storage",
        "POST /storage/trim"
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
            }
        ])
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
