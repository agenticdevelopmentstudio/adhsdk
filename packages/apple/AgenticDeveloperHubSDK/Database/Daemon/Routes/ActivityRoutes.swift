#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// App-activity tracking, read-only: `GET /activity/status` and
/// `GET /activity/spans`, plus the single-instance app registry
/// (`POST /app/register`, `POST /app/unregister`).
public enum ActivityRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /activity/status",
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
    ///   - workTrackingStatus: the tracker's last known state. It must never ask
    ///     the system for Accessibility (that check can freeze the machine). Nil
    ///     when this daemon runs no tracker, which makes `/activity/status` a 503.
    ///   - appRegistry: the single-instance registry; nil leaves `/app/*` to the
    ///     daemon.
    public static func table(
        database: DaemonDatabase,
        workTrackingStatus: (@Sendable () async -> WorkTrackingStatus)?,
        appRegistry: SessionAppRegistry?
    ) -> RouteTable {
        var handlers: [RouteTable.Handler] = [
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "activity" }) { request, components in
                switch components[1] {
                case "status":
                    guard let workTrackingStatus else {
                        return .error("Work tracking is not running", status: 503)
                    }
                    return .json(await workTrackingStatus())
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
            }
        ]
        if let appRegistry {
            handlers.append(contentsOf: registryHandlers(appRegistry))
        }
        return RouteTable(handlers)
    }

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
