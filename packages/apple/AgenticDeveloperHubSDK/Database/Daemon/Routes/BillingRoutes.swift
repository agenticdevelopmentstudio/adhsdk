#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

// swiftlint:disable multiple_closures_with_trailing_closure

/// The billing ledger over HTTP: every read and write an app's billing windows
/// make, relative to the daemon's session mount (`/billing/...`).
///
/// Reads and writes both, on purpose (apps suite Phase 3, Decision 16). This
/// set was read-only while the app kept a second door into the ledger: a write
/// here would have been a change the app's billing model never learned about.
/// Now the daemon that serves these routes is the ledger's only owner, and the
/// apps reach billing through nothing else, so a write here is the one way a
/// write happens. The rules stay in `BillingStore`, `BillingRollup`,
/// `BillingTimer` and `BillingPrefs`; every handler is a forward to them, so a
/// decision made here would be one no store test covers.
///
/// Writes are `POST`s: `POST /billing/<things>` saves (an empty id inserts),
/// `POST /billing/<things>/:id/delete` deletes, and the rest name their verb.
/// Bodies are snake_case JSON. A store's refusal answers 400 with its sentence,
/// which is written to be shown verbatim in an alert; a count write that
/// threw answers 500, never a count of 0, which would read as "nothing to do".
/// A daemon must mount these behind its client token, never on an
/// unauthenticated path. Any method but `GET` and `POST` is a 405.
public enum BillingRoutes {

    /// The endpoint-index lines this set serves, for a daemon's `GET /`.
    public static let endpoints: [String] = [
        "GET /billing/clients",
        "POST /billing/clients",
        "POST /billing/clients/:id/delete",
        "GET /billing/projects",
        "POST /billing/projects",
        "POST /billing/projects/:id/delete",
        "GET /billing/repos",
        "POST /billing/repos",
        "POST /billing/repos/:id/delete",
        "GET /billing/entries",
        "POST /billing/entries",
        "GET /billing/entries/:id/audit",
        "POST /billing/entries/:id/status",
        "POST /billing/entries/:id/description",
        "POST /billing/entries/:id/delete",
        "GET /billing/segments",
        "POST /billing/segments/assign",
        "POST /billing/segments/promote",
        "POST /billing/segments/assign-repository",
        "GET /billing/timers",
        "POST /billing/timers",
        "POST /billing/timers/:id/stop",
        "POST /billing/app-names",
        "POST /billing/backfill",
        "POST /billing/preferences",
        "GET /billing/overview"
    ]

    /// Most ids one `POST /billing/app-names` reads; the caller sends only the
    /// distinct app ones on screen, and the rest are ignored.
    public static let maxAppNameIds = 500

    /// Most rows one `GET /billing/entries/:id/audit` returns.
    public static let auditLimit = 200

    /// Every billing route, answered from `database`.
    public static func table(database: DaemonDatabase) -> RouteTable {
        RouteTable([
            RouteTable.route("GET", where: { $0.first == "billing" }) { request, components in
                read(Array(components.dropFirst()), request: request, database: database)
            },
            RouteTable.route("POST", where: { $0.first == "billing" }) { request, components in
                write(Array(components.dropFirst()), request: request, database: database)
            },
            { request in
                guard request.pathComponents.first == "billing" else { return nil }
                return .error("Method not allowed", status: 405)
            }
        ])
    }

    // MARK: - Reads

    private static func read(_ path: [String], request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        do {
            if path.count == 3, path[0] == "entries", path[2] == "audit" {
                return .json(try database.billingEntryAudit(entryId: path[1], limit: auditLimit))
            }
            guard path.count == 1 else { return unknown(path) }
            switch path[0] {
            case "clients":
                return .json(try database.billingClients(includeArchived: includeArchived(request)))
            case "projects":
                return .json(try database.billingProjects(includeArchived: includeArchived(request)))
            case "repos":
                return .json(try database.billingRepos(projectId: request.query("project_id")))
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
            case "timers":
                return .json(try BillingTimer.running(database: database))
            case "overview":
                return .json(try BillingRollup.overview(database: database))
            default:
                return unknown(path)
            }
        } catch {
            return .failure(error)
        }
    }

    /// `?include_archived=true` (or `1`) lists archived rows too, as the app's
    /// windows do; omitted, archived rows are left out.
    private static func includeArchived(_ request: RouteRequest) -> Bool {
        ["true", "1"].contains(request.query("include_archived")?.lowercased() ?? "")
    }

    // MARK: - Writes

    private static func write(_ path: [String], request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        switch path.count {
        case 1:
            return writeCollection(path[0], request: request, database: database)
        case 2 where path[0] == "segments":
            return writeSegments(path[1], request: request, database: database)
        case 3:
            return writeItem(kind: path[0], id: path[1], verb: path[2], request: request, database: database)
        default:
            return unknown(path)
        }
    }

    /// `POST /billing/<collection>`: a save, a timer start, or one of the
    /// collection-wide writes.
    private static func writeCollection(
        _ collection: String, request: RouteRequest, database: DaemonDatabase
    ) -> RouteResponse {
        switch collection {
        case "clients":
            return stored {
                try BillingStore.saveClient(try decode(BillingClientDTO.self, request), database: database)
            }
        case "projects":
            return stored {
                try BillingStore.saveProject(try decode(BillingProjectDTO.self, request), database: database)
            }
        case "repos":
            return stored { try BillingStore.saveRepo(try decode(BillingRepoDTO.self, request), database: database) }
        case "entries":
            return stored { try BillingRollup.saveEntry(try decode(BillingEntryDTO.self, request), database: database) }
        case "timers":
            return stored { try BillingTimer.start(try decode(BillingTimerStartDTO.self, request), database: database) }
        case "app-names":
            // A read with a body: the id list can run to `maxAppNameIds`.
            guard let body = try? decode(AppNamesRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            do {
                return .json(try database.billingAppNames(sessionIds: Array(body.sessionIds.prefix(maxAppNameIds))))
            } catch {
                return .failure(error)
            }
        case "backfill":
            guard let body = try? decode(BackfillRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            return counted { try database.resetBillingDerivation(since: body.since) }
        case "preferences":
            return preferences(request, database: database)
        default:
            return unknown([collection])
        }
    }

    /// `POST /billing/segments/{assign,promote,assign-repository}`, each
    /// answering `{"count": n}`.
    private static func writeSegments(
        _ verb: String, request: RouteRequest, database: DaemonDatabase
    ) -> RouteResponse {
        switch verb {
        case "assign":
            guard let body = try? decode(AssignSegmentsRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            return counted {
                try BillingRollup.assignSegments(ids: body.ids, projectId: body.projectId, database: database)
            }
        case "promote":
            guard let body = try? decode(PromoteSegmentsRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            return counted {
                let options = try BillingPrefs.snapshot(database).rollupOptions
                return try BillingRollup.promoteSegments(ids: body.ids, options: options, database: database)
            }
        case "assign-repository":
            guard let body = try? decode(AssignRepositoryRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            return counted {
                let options = try BillingPrefs.snapshot(database).rollupOptions
                return try BillingRollup.assignRepository(
                    projectRoot: body.projectRoot, projectId: body.projectId, options: options, database: database
                )
            }
        default:
            return unknown(["segments", verb])
        }
    }

    /// `POST /billing/<kind>/:id/<verb>`.
    private static func writeItem(
        kind: String, id: String, verb: String, request: RouteRequest, database: DaemonDatabase
    ) -> RouteResponse {
        switch (kind, verb) {
        case ("clients", "delete"):
            return deleted { try BillingStore.deleteClient(id: id, database: database) }
        case ("projects", "delete"):
            return deleted { try BillingStore.deleteProject(id: id, database: database) }
        case ("repos", "delete"):
            return deleted { try BillingStore.deleteRepo(id: id, database: database) }
        case ("entries", "delete"):
            return deleted { try BillingRollup.deleteEntry(id: id, database: database) }
        case ("entries", "status"):
            return stored {
                let body = try decode(EntryStatusRequest.self, request)
                guard let status = BillingStatus(rawValue: body.status) else {
                    throw BillingWireError.unknownStatus(body.status)
                }
                return try BillingRollup.setStatus(entryId: id, to: status, source: "user", database: database)
            }
        case ("entries", "description"):
            return stored {
                let body = try decode(EntryDescriptionRequest.self, request)
                return try BillingRollup.setDescription(entryId: id, description: body.description, database: database)
            }
        case ("timers", "stop"):
            return stored { try BillingTimer.stop(id: id, database: database) }
        default:
            return unknown([kind, id, verb])
        }
    }

    /// Writes whichever billing knobs the body carries, then answers the
    /// snapshot now in force (`BillingPreferencesDTO`). `BillingPrefs.apply`
    /// owns the rules: one transaction, clamp on read, re-derive on a cutoff
    /// change.
    ///
    /// A failed write is a 500, so the app's push is not counted as delivered
    /// and is retried. A body that is not one JSON object of scalars writes
    /// nothing and is a 400, never a 200 with the old snapshot, which would
    /// read as a delivered save. An empty body writes nothing and answers the
    /// snapshot.
    private static func preferences(_ request: RouteRequest, database: DaemonDatabase) -> RouteResponse {
        let fields: [String: String]
        if request.body.isEmpty {
            fields = [:]
        } else {
            guard let values = try? JSONDecoder().decode([String: PreferenceValue].self, from: request.body) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            fields = values.mapValues(\.settingText)
        }
        do {
            return .json(try BillingPrefs.apply(fields, database: database).wireForm)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Replies

    /// One write's reply: the stored value, or 400 with the sentence that
    /// refused it. The stores' errors are `LocalizedError`s written to be shown
    /// verbatim.
    private static func stored<T: Encodable>(_ write: () throws -> T) -> RouteResponse {
        do {
            return .json(try write())
        } catch {
            return .error(error.localizedDescription, status: 400)
        }
    }

    /// A delete's reply: 204, or 400 with the refusal.
    private static func deleted(_ delete: () throws -> Void) -> RouteResponse {
        do {
            try delete()
            return .noContent
        } catch {
            return .error(error.localizedDescription, status: 400)
        }
    }

    /// A count write's reply: `{"count": n}`, or a 500 when it threw.
    private static func counted(_ write: () throws -> Int) -> RouteResponse {
        do {
            let count = try write()
            return .json(["count": count])
        } catch {
            return .failure(error)
        }
    }

    private static func unknown(_ path: [String]) -> RouteResponse {
        .notFound("Unknown billing endpoint: /billing/\(path.joined(separator: "/"))")
    }

    // MARK: - Bodies

    private struct AppNamesRequest: Decodable { let sessionIds: [String] }
    private struct BackfillRequest: Decodable { let since: String }
    private struct AssignSegmentsRequest: Decodable { let ids: [String]; let projectId: String? }
    private struct PromoteSegmentsRequest: Decodable { let ids: [String] }
    private struct AssignRepositoryRequest: Decodable { let projectRoot: String; let projectId: String }
    private struct EntryStatusRequest: Decodable { let status: String }
    private struct EntryDescriptionRequest: Decodable { let description: String }

    /// One `POST /billing/preferences` value: a string, number or bool, kept as
    /// the text the settings table stores (`RawSetting` reads it back). `null`,
    /// an array or an object fails the decode, so the body is refused whole.
    struct PreferenceValue: Decodable, Equatable {
        let settingText: String

        init(settingText: String) { self.settingText = settingText }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            // Bool before the numbers: JSONDecoder never reads a number as a
            // Bool or a Bool as a number, so the order only names the cases.
            if let flag = try? container.decode(Bool.self) {
                settingText = flag ? "true" : "false"
            } else if let whole = try? container.decode(Int.self) {
                settingText = String(whole)
            } else if let real = try? container.decode(Double.self) {
                settingText = String(real)
            } else {
                settingText = try container.decode(String.self)
            }
        }
    }

    /// The body as `type`, snake_case keys and ISO-8601 dates, or the
    /// version-mismatch refusal.
    private static func decode<T: Decodable>(_ type: T.Type, _ request: RouteRequest) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: request.body)
        } catch {
            throw BillingWireError.undecodable
        }
    }

    /// Refusals that happen at the wire rather than in a store: a body the
    /// daemon can't read, or a status name it doesn't know. Worded for the
    /// same alert as the stores' own.
    enum BillingWireError: LocalizedError {
        case undecodable
        case unknownStatus(String)

        var errorDescription: String? {
            switch self {
            case .undecodable:
                return "The daemon couldn't read the request. The app and daemon may be different versions."
            case .unknownStatus(let status):
                return "“\(status)” isn't a billing status."
            }
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
