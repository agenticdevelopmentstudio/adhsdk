#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// App-activity tracking: its state (`GET /activity/status`), its controls
/// (`POST /activity/preferences`, `POST /activity/recheck`) and what it recorded
/// (`GET /activity/spans`), plus the single-instance app registry
/// (`POST /app/register`, `POST /app/unregister`).
///
/// The two `POST /activity/*` routes change what the machine records, so a
/// daemon mounts this set behind its client token, as it does every write.
public enum ActivityRoutes {

    /// The work tracker a daemon runs, as this set drives it. Closures rather
    /// than the controller itself, because the controller lives in the
    /// Activity tier above this one.
    public struct WorkTrackingControl: Sendable {
        /// The tracker's last known state. Must never ask the system for
        /// Accessibility: that check can freeze the machine.
        public let status: @Sendable () async -> WorkTrackingStatus
        /// Applies new preferences and answers the state they produced.
        /// Turning tracking on checks Accessibility once.
        public let apply: @Sendable (WorkTrackingPreferences) async throws -> WorkTrackingStatus
        /// Asks the system for Accessibility again, at the user's request: the
        /// only path that checks it on demand.
        public let recheck: @Sendable () async -> WorkTrackingStatus

        public init(
            status: @escaping @Sendable () async -> WorkTrackingStatus,
            apply: @escaping @Sendable (WorkTrackingPreferences) async throws -> WorkTrackingStatus,
            recheck: @escaping @Sendable () async -> WorkTrackingStatus
        ) {
            self.status = status
            self.apply = apply
            self.recheck = recheck
        }
    }

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /activity/status",
        "POST /activity/preferences",
        "POST /activity/recheck",
        "GET /activity/spans",
        "POST /app/register",
        "POST /app/unregister"
    ]

    /// `POST /app/register` and `/app/unregister`'s reply.
    public struct AppRegistryResponse: Codable, Sendable, Equatable {
        public let ownerPid: Int32?
        public let registered: Bool

        public init(ownerPid: Int32?, registered: Bool) {
            self.ownerPid = ownerPid
            self.registered = registered
        }
    }

    private struct AppRegistryRequest: Decodable, Sendable {
        let pid: Int32
    }

    /// - Parameters:
    ///   - database: where the spans are read.
    ///   - workTracking: the tracker this daemon runs. Nil when it runs none,
    ///     which makes `/activity/status` and both `POST /activity/*` a 503.
    ///   - appRegistry: the single-instance registry; nil leaves `/app/*` to the
    ///     daemon.
    public static func table(
        database: DaemonDatabase,
        workTracking: WorkTrackingControl?,
        appRegistry: SessionAppRegistry?
    ) -> RouteTable {
        var handlers: [RouteTable.Handler] = [
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "activity" }) { request, components in
                switch components[1] {
                case "status":
                    guard let workTracking else { return notRunning }
                    return .json(await workTracking.status())
                case "spans":
                    let since: String
                    switch RouteRequest.activitySince(request.query("since")) {
                    case .success(let value): since = value
                    case .failure(let invalid): return .error(invalid.message, status: 400)
                    }
                    do {
                        return .json(try database.activitySpans(
                            since: since,
                            limit: request.boundedLimit(default: 100, max: 1000)
                        ))
                    } catch {
                        return .failure(error)
                    }
                default:
                    return .notFound("Unknown activity endpoint: /activity/\(components[1])")
                }
            },
            // Applies a whole `WorkTrackingPreferences` (snake_case) and answers
            // the status it produced. An unreadable body changes nothing.
            RouteTable.route("POST", where: { $0 == ["activity", "preferences"] }) { request, _ in
                guard let workTracking else { return notRunning }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let prefs = try? decoder.decode(WorkTrackingPreferences.self, from: request.body) else {
                    return .error("Invalid body: expected work-tracking preferences", status: 400)
                }
                do {
                    return .json(try await workTracking.apply(prefs))
                } catch {
                    return .failure(error)
                }
            },
            // The user's "check again" after granting Accessibility.
            RouteTable.route("POST", where: { $0 == ["activity", "recheck"] }) { _, _ in
                guard let workTracking else { return notRunning }
                return .json(await workTracking.recheck())
            }
        ]
        if let appRegistry {
            handlers.append(contentsOf: registryHandlers(appRegistry))
        }
        return RouteTable(handlers)
    }

    private static let notRunning = RouteResponse.error("Work tracking is not running", status: 503)

    private static func registryHandlers(_ registry: SessionAppRegistry) -> [RouteTable.Handler] {
        let missingBody = "Missing body: expected {\"pid\": Int}"
        return [
            // 200 on success; 409 with the live owner's pid when one holds it.
            RouteTable.route("POST", where: { $0 == ["app", "register"] }) { request, _ in
                guard let pid = decodePid(request) else { return .error(missingBody, status: 400) }
                switch await registry.register(pid: pid) {
                case .registered:
                    return .json(AppRegistryResponse(ownerPid: pid, registered: true))
                case .alreadyRegistered(let ownerPid):
                    return .json(AppRegistryResponse(ownerPid: ownerPid, registered: false), status: 409)
                }
            },
            // Idempotent: releases the slot only if the caller owns it. Always 200.
            RouteTable.route("POST", where: { $0 == ["app", "unregister"] }) { request, _ in
                guard let pid = decodePid(request) else { return .error(missingBody, status: 400) }
                let released = await registry.unregister(pid: pid)
                return .json(AppRegistryResponse(ownerPid: nil, registered: !released))
            }
        ]
    }

    private static func decodePid(_ request: RouteRequest) -> Int32? {
        guard !request.body.isEmpty else { return nil }
        return (try? JSONDecoder().decode(AppRegistryRequest.self, from: request.body))?.pid
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
