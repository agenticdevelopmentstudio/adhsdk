import Foundation

/// A request as shared routes see it: no transport, no framework.
///
/// A daemon's HTTP layer converts its own request type into this one, so a route
/// written once against `RouteRequest` can be mounted by any daemon.
public struct RouteRequest: Sendable, Equatable {
    public let method: String
    public let path: String
    /// Every value of every query key, in wire order.
    public let queryValues: [String: [String]]
    public let headers: [String: String]
    public let body: Data

    public init(
        method: String,
        path: String,
        queryValues: [String: [String]] = [:],
        headers: [String: String] = [:],
        body: Data = Data()
    ) {
        self.method = method
        self.path = path
        self.queryValues = queryValues
        self.headers = headers
        self.body = body
    }

    /// The path split on `/`, empty segments dropped.
    public var pathComponents: [String] {
        path.split(separator: "/").map(String.init)
    }

    /// The last value of `key`, or nil when absent.
    public func query(_ key: String) -> String? {
        queryValues[key]?.last
    }

    /// Every value of `key`, in wire order.
    public func queryAll(_ key: String) -> [String] {
        queryValues[key] ?? []
    }

    /// `key` as an `Int`, or `def` when absent or not a number.
    public func queryInt(_ key: String, default def: Int = 0) -> Int {
        Int(query(key) ?? "") ?? def
    }

    // MARK: - Paging bounds

    /// A `?limit=` that is safe to hand to SQL: always within `1...max`.
    ///
    /// **`min(limit, max)` is not a clamp**, and every `limit` in a router used
    /// to be written that way. SQLite reads a negative `LIMIT` as *no limit*, so
    /// `?limit=-1` slipped past `min(-1, 500)` and turned a bounded page into the
    /// whole table — one request materialising every matching row as DTOs and then
    /// again as JSON. Measured live before the fix: `/sessions/:id/events?limit=500`
    /// returned 500 rows, `?limit=-1` returned 2,300; on the unscoped `/events` the
    /// ceiling is the size of `event_log`. Four handlers had no `min` at all, so any
    /// large value went straight through.
    ///
    /// Clamping is deliberately silent rather than a 400: these are read-only paging
    /// params on a localhost API, and a caller asking for more than the page ceiling
    /// wants as much as it can get, not an error.
    public func boundedLimit(default def: Int, max ceiling: Int) -> Int {
        Swift.min(Swift.max(queryInt("limit", default: def), 1), ceiling)
    }

    /// A `?offset=` that is safe to hand to SQL: never negative.
    public func boundedOffset() -> Int {
        Swift.max(queryInt("offset", default: 0), 0)
    }

    // MARK: - Timestamps

    /// Parse an ISO8601 query parameter and re-emit it in the exact shape the
    /// `timestamp` columns are stored in.
    ///
    /// Unlike `boundedLimit`, this one **is** a 400 rather than a silent clamp,
    /// because there is no safe interpretation to fall back to. Every window
    /// filter in this API is a lexicographic `timestamp >= ?` against an
    /// ISO8601 string, so a malformed bound does not fail — it quietly selects
    /// the wrong rows and returns HTTP 200. `?since=yesterday` sorts above every
    /// real timestamp (`'y' > '2'`) and reports a confidently empty result;
    /// `?since=2026` sorts below all of them and silently means "everything".
    ///
    /// Normalising matters as much as validating. Timestamps are written with
    /// fractional seconds, and `"…T12:00:00Z" > "…T12:00:00.123Z"` bytewise
    /// (`'Z' > '.'`), so an un-normalised whole-second bound skips the first
    /// sub-second of its own range. Re-emitting through the fractional-seconds
    /// formatter makes the string comparison agree with the instant it names.
    ///
    /// Returns `.success(nil)` when the parameter is absent or empty — an
    /// unbounded window is the documented default, not a bad request.
    public func validatedTimestamp(_ name: String) -> Result<String?, InvalidTimestamp> {
        guard let raw = query(name), !raw.isEmpty else { return .success(nil) }
        return Self.normalizedTimestamp(raw, name: name).map { Optional($0) }
    }

    /// A bound on a column that holds UTC days (`YYYY-MM-DD`): the day as
    /// given, or the UTC day of a full ISO8601 timestamp. A day compared as
    /// text against a malformed bound fails the same quiet way a timestamp
    /// does (`11/01/2026` sorts below every day), so it is a 400 too. Returns
    /// `.success(nil)` when the parameter is absent or empty.
    public func validatedDay(_ name: String) -> Result<String?, InvalidTimestamp> {
        guard let raw = query(name), !raw.isEmpty else { return .success(nil) }
        guard Self.isISODayOrTimestamp(raw) else {
            return .failure(InvalidTimestamp(
                message: "`\(name)` must be a day (YYYY-MM-DD) or an ISO8601 timestamp; got \"\(raw)\""
            ))
        }
        guard raw.count > 10, let instant = TimestampParsing.parseISO8601(raw) else { return .success(raw) }
        return .success(String(UTCTimestamp.string(from: instant).prefix(10)))
    }

    /// Accepts `2026-09-01` and `2026-09-01T12:00:00Z` alike, taking the day
    /// from either: the whole string, so `2026-09-01garbage` is refused. A
    /// timestamp is what ``TimestampParsing/parseISO8601(_:)`` accepts.
    /// Anything else, a day no calendar has included, is a typo the caller
    /// should hear about.
    public static func isISODayOrTimestamp(_ value: String) -> Bool {
        guard isISODay(String(value.prefix(10))) else { return false }
        return value.count == 10 || TimestampParsing.parseISO8601(value) != nil
    }

    /// Exactly `YYYY-MM-DD`, ASCII digits, a day some calendar month has.
    private static func isISODay(_ day: String) -> Bool {
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

    /// The parse-and-canonicalise step behind `validatedTimestamp`, for the
    /// fractional-seconds `timestamp` columns. Not the activity parser: a column
    /// that stores whole seconds reads its `since` through
    /// ``activitySince(_:)``.
    public static func normalizedTimestamp(_ raw: String, name: String) -> Result<String, InvalidTimestamp> {
        parseISO8601(raw, name: name).map { date in
            let canonical = ISO8601DateFormatter()
            canonical.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return canonical.string(from: date)
        }
    }

    /// A `since` for a table whose columns hold whole-second `UTCTimestamp`
    /// strings. The fractional form `normalizedTimestamp` emits would compare
    /// wrongly byte for byte (`.` sorts before `Z`), so this truncates to the
    /// stored shape. Absent or empty means no bound (`""`). The parameter is
    /// always named `since` in a refusal.
    public static func activitySince(_ raw: String?) -> Result<String, InvalidTimestamp> {
        guard let raw, !raw.isEmpty else { return .success("") }
        return parseISO8601(raw, name: "since").map(UTCTimestamp.string(from:))
    }

    /// Core's shared ISO-8601 validator, so the CLI that checks a flag and the
    /// daemon that reads it accept exactly the same strings.
    private static func parseISO8601(_ raw: String, name: String) -> Result<Date, InvalidTimestamp> {
        if let date = TimestampParsing.parseISO8601(raw) { return .success(date) }
        return .failure(InvalidTimestamp(
            message: "`\(name)` must be an ISO8601 timestamp (e.g. 2026-01-31T00:00:00Z); got \"\(raw)\""
        ))
    }
}
