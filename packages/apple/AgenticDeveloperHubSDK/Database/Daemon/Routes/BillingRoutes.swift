#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import OSLog

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
/// which is written to be shown verbatim in an alert, and only a refusal does:
/// the app treats a 400 as final. A database that was busy answers 503 (try
/// again) and any other failure 500, each with a sentence of its own, never
/// SQLite's text, which goes to the log. A count write that threw answers a
/// 500 or 503, never a count of 0, which would read as "nothing to do".
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
                guard since.isEmpty || RouteRequest.isISODayOrTimestamp(since) else {
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
            return storeFailure(error)
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
                return storeFailure(error)
            }
        case "backfill":
            guard let body = try? decode(BackfillRequest.self, request) else {
                return .error(BillingWireError.undecodable.localizedDescription, status: 400)
            }
            guard let since = backfillSince(body.since) else {
                return .error("Invalid 'since': expected YYYY-MM-DD or an ISO-8601 timestamp", status: 400)
            }
            return counted { try database.resetBillingDerivation(since: since) }
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
    /// A failed write is a 500 (a 503 when the database was busy), so the
    /// app's push is not counted as delivered and is retried. A body that is not one JSON object of scalars writes
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
            return storeFailure(error)
        }
    }

    // MARK: - Replies

    /// One write's reply: the stored value, or ``storeFailure(_:)``.
    private static func stored<T: Encodable>(_ write: () throws -> T) -> RouteResponse {
        do {
            return .json(try write())
        } catch {
            return storeFailure(error)
        }
    }

    /// A delete's reply: 204, or ``storeFailure(_:)``.
    private static func deleted(_ delete: () throws -> Void) -> RouteResponse {
        do {
            try delete()
            return .noContent
        } catch {
            return storeFailure(error)
        }
    }

    /// A count write's reply: `{"count": n}`, or ``storeFailure(_:)``.
    private static func counted(_ write: () throws -> Int) -> RouteResponse {
        do {
            let count = try write()
            return .json(["count": count])
        } catch {
            return storeFailure(error)
        }
    }

    /// The reply to a store write that threw. A store's refusal is a 400 with
    /// its sentence, which the stores write to be shown verbatim; a database
    /// that was busy or locked (a deadline counts) is a 503 the app may retry;
    /// anything else is a 500. Neither carries the database's own text, which
    /// is logged instead: it names files and SQL, and it is no sentence for an
    /// alert.
    static func storeFailure(_ error: Error) -> RouteResponse {
        switch error {
        case is BillingStore.BillingError, is BillingRollup.RollupError, is BillingTimer.TimerError,
             is BillingWireError:
            return .error(error.localizedDescription, status: 400)
        default:
            let busy = isBusy(error)
            logger.error("""
                Billing write failed\(busy ? " (busy)" : "", privacy: .public): \
                \(error.localizedDescription, privacy: .public)
                """)
            return busy ? .error(busyMessage, status: 503) : .error(failedMessage, status: 500)
        }
    }

    static let busyMessage = "The billing database is busy. Try again in a moment."
    static let failedMessage = "The billing database couldn't complete the request."

    /// SQLITE_BUSY or SQLITE_LOCKED, extended forms included, whether it
    /// arrives mapped (`DaemonDatabaseError`, as the write lane throws it, a
    /// deadline included) or raw (`GRDB.DatabaseError`, from a nested write).
    private static func isBusy(_ error: Error) -> Bool {
        let code: Int32?
        switch error {
        case let mapped as DaemonDatabaseError: code = mapped.sqliteCode
        case let raw as GRDB.DatabaseError: code = raw.extendedResultCode.rawValue
        default: code = nil
        }
        guard let code else { return false }
        return [ResultCode.SQLITE_BUSY.rawValue, ResultCode.SQLITE_LOCKED.rawValue].contains(code & 0xFF)
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

    /// A backfill's `since` in the shape `resetBillingDerivation` compares
    /// against: a day as given, a timestamp as a whole-second UTC instant (an
    /// offset is converted, not compared as text). nil for anything else,
    /// the empty string included: the store compares strings, so `""` would
    /// re-derive the whole history and a non-date would quietly match
    /// nothing, each answering 200.
    static func backfillSince(_ value: String) -> String? {
        guard RouteRequest.isISODayOrTimestamp(value) else { return nil }
        guard value.count > 10 else { return value }
        return TimestampParsing.parseISO8601(value).map(UTCTimestamp.string(from:))
    }
}
#endif

// swiftlint:enable multiple_closures_with_trailing_closure

#if canImport(AgenticDeveloperHubSDKCore)
extension BillingRoutes: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
