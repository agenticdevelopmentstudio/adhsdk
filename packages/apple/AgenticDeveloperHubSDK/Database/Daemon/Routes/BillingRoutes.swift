#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The billing ledger as `curl` sees it: `/billing/{clients,projects,entries,
/// segments,overview}`.
///
/// Read-only on purpose: a write here would be a change the app's billing model
/// never learns about, and the two views of the ledger would drift apart with
/// nothing to notice. Any other method on `/billing/*` is a 405.
public enum BillingRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /billing/clients",
        "GET /billing/projects",
        "GET /billing/entries",
        "GET /billing/segments",
        "GET /billing/overview"
    ]

    /// Every billing route, answered from `database`.
    public static func table(database: DaemonDatabase) -> RouteTable {
        RouteTable([
            RouteTable.route("GET", where: { $0.count == 2 && $0[0] == "billing" }) { request, components in
                billing(sub: components[1], request: request, database: database)
            },
            { request in
                guard request.method != "GET", request.pathComponents.first == "billing" else { return nil }
                return .error("Method not allowed", status: 405)
            }
        ])
    }

    private static func billing(sub: String, request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        do {
            switch sub {
            case "clients":
                return .json(try database.billingClients(includeArchived: false))
            case "projects":
                return .json(try database.billingProjects(includeArchived: false))
            case "entries":
                // `since` here is a day, not an instant: entries are filed by
                // local day, so an ISO timestamp would compare against a
                // ten-character column and quietly match nothing.
                let since = request.query("since") ?? ""
                guard since.isEmpty || isISODayOrTimestamp(since) else {
                    return .error("Invalid 'since': expected YYYY-MM-DD", status: 400)
                }
                return .json(try database.billingEntries(
                    projectId: request.query("project_id"),
                    status: request.query("status"),
                    since: String(since.prefix(10))
                ))
            case "segments":
                let since: String?
                switch request.validatedTimestamp("since") {
                case .success(let value): since = value
                case .failure(let invalid): return .error(invalid.message, status: 400)
                }
                return .json(try database.billingSegments(
                    since: since ?? "",
                    limit: request.boundedLimit(default: 200, max: 2000)
                ))
            case "overview":
                return .json(try BillingRollup.overview(database: database))
            default:
                return .notFound("Unknown billing endpoint: /billing/\(sub)")
            }
        } catch {
            return .failure(error)
        }
    }

    /// Accepts `2026-09-01` and `2026-09-01T12:00:00Z` alike, taking the day
    /// from either. Anything else, a day no calendar has included, is a typo
    /// the caller should hear about.
    static func isISODayOrTimestamp(_ value: String) -> Bool {
        let day = String(value.prefix(10))
        guard day.count == 10 else { return false }
        let parts = day.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2 else {
            return false
        }
        // ASCII digits only (`isNumber` also accepts other scripts' digits and
        // fractions), and a real calendar day, so `2026-13-01` is refused.
        guard parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isWholeNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let dayOfMonth = Int(parts[2]),
              (1...12).contains(month) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let days = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return false }
        return days.contains(dayOfMonth)
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure
