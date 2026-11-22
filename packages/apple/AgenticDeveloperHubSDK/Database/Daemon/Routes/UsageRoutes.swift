#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The usage surface Stenographer's daemon served, as a route set any session
/// daemon can mount: the `/insights/*` family (the status line reads
/// `/insights/usage-rows` every two seconds), `/turns`, `/rate-limits`,
/// `/rate-limits/latest`, `/claude-versions` and `/visualization/graph`.
///
/// Read-only. Every bound is validated: an unparseable `since`/`until` is a 400,
/// never a page that silently compares a stray string against the timestamps.
public enum UsageRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /insights/summary",
        "GET /insights/events-per-day",
        "GET /insights/tools",
        "GET /insights/projects",
        "GET /insights/sessions-per-day",
        "GET /insights/cache-misses",
        "GET /insights/active-hours",
        "GET /insights/usage-rows",
        "GET /insights/daily-metrics",
        "GET /turns",
        "GET /rate-limits",
        "GET /rate-limits/latest",
        "GET /claude-versions",
        "GET /visualization/graph"
    ]

    /// Every usage route, answered from `database`.
    public static func table(database: DaemonDatabase) -> RouteTable {
        RouteTable([
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "insights" }) { request, components in
                insights(sub: components[1], request: request, database: database)
            },
            RouteTable.route("GET", where: { $0 == ["turns"] }) { request, _ in
                turns(request, database: database)
            },
            RouteTable.route("GET", where: { $0 == ["rate-limits"] }) { request, _ in
                rateLimits(request, database: database)
            },
            RouteTable.route("GET", where: { $0 == ["rate-limits", "latest"] }) { request, _ in
                do {
                    guard let snapshot = try database.latestRateLimitSnapshot(
                        sessionId: request.query("session_id"),
                        account: request.query("account")
                    ) else {
                        return .notFound("No rate-limit snapshots recorded")
                    }
                    return .json(snapshot)
                } catch {
                    return .failure(error)
                }
            },
            RouteTable.route("GET", where: { $0 == ["claude-versions"] }) { request, _ in
                do {
                    return .json(try database.claudeVersions(
                        version: request.query("version"),
                        newerThan: request.query("newer_than")
                    ))
                } catch {
                    return .failure(error)
                }
            },
            RouteTable.route("GET", where: { $0 == ["visualization", "graph"] }) { request, _ in
                do {
                    return .json(try database.graphSnapshot(limit: request.boundedLimit(default: 100, max: 1000)))
                } catch {
                    return .failure(error)
                }
            }
        ])
    }

    // MARK: - Insights

    private static func insights(sub: String, request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let since: String?
        switch request.validatedTimestamp("since") {
        case .success(let value): since = value
        case .failure(let invalid): return .error(invalid.message, status: 400)
        }
        let limit = request.boundedLimit(default: 20, max: 100)
        do {
            switch sub {
            case "summary":
                return .json(try database.insightsSummary(since: since))
            case "events-per-day":
                return .json(try database.eventsPerDay(since: since))
            case "tools":
                return .json(try database.toolUsage(since: since, limit: limit))
            case "projects":
                return .json(try database.projectActivity(since: since, limit: limit))
            case "sessions-per-day":
                return .json(try database.sessionsPerDay(since: since))
            case "cache-misses":
                return .json(try database.cacheMisses(since: since, limit: limit))
            case "active-hours":
                return activeHours(request, database: database)
            case "usage-rows":
                // Cached and served off the database queue, so the status line's
                // two-second render never waits behind ingestion.
                return .json(database.statusLineUsageRows())
            case "daily-metrics":
                return .json(try database.dailyMetrics(
                    metric: request.query("metric"),
                    dimension: request.query("dimension"),
                    from: request.query("from"),
                    to: request.query("to"),
                    // Its own bound: these are small pre-aggregated rows, so this
                    // endpoint pages far coarser than the rest of `/insights`.
                    limit: request.boundedLimit(default: 1000, max: 10_000)
                ))
            default:
                return .notFound("Unknown insights endpoint: /insights/\(sub)")
            }
        } catch {
            return .failure(error)
        }
    }

    /// `since` and `until` are both required here: the burst walk has no
    /// sensible open-ended window.
    private static func activeHours(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let since: String, until: String
        switch (request.validatedTimestamp("since"), request.validatedTimestamp("until")) {
        case (.failure(let invalid), _), (_, .failure(let invalid)):
            return .error(invalid.message, status: 400)
        case (.success(let lower), .success(let upper)):
            guard let lower, let upper else {
                return .error("`since` and `until` are required ISO8601 timestamps", status: 400)
            }
            since = lower
            until = upper
        }
        do {
            return .json(try database.activeHours(
                since: since,
                until: until,
                account: request.query("account"),
                idleThresholdS: request.queryInt("idle_threshold_s", default: 15 * 60)
            ))
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Turns and rate limits

    private static func turns(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let since: String?, until: String?
        switch (request.validatedTimestamp("since"), request.validatedTimestamp("until")) {
        case (.failure(let invalid), _), (_, .failure(let invalid)):
            return .error(invalid.message, status: 400)
        case (.success(let lower), .success(let upper)):
            since = lower
            until = upper
        }
        do {
            return .json(try database.turnAggregates(
                since: since,
                until: until,
                groupBy: request.query("group_by") ?? "all",
                toolName: request.query("tool_name"),
                project: request.query("project"),
                account: request.query("account"),
                limit: request.boundedLimit(default: 100, max: 1000)
            ))
        } catch {
            return .failure(error)
        }
    }

    private static func rateLimits(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let since: String?, until: String?
        switch (request.validatedTimestamp("since"), request.validatedTimestamp("until")) {
        case (.failure(let invalid), _), (_, .failure(let invalid)):
            return .error(invalid.message, status: 400)
        case (.success(let lower), .success(let upper)):
            since = lower
            until = upper
        }
        do {
            return .json(try database.rateLimitSeries(
                since: since,
                until: until,
                sessionId: request.query("session_id"),
                // Newest-N, not a page: see `rateLimitSeries`. Generous, because a
                // caller charting this wants a long window and one snapshot is small.
                limit: request.boundedLimit(default: 5000, max: 50_000)
            ))
        } catch {
            return .failure(error)
        }
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
