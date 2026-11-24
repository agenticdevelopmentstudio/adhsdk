import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// The one door every feature adapter uses to reach the backend: JSON in, JSON out, `HubError` on failure.
/// Built on `ADHClient.rawJSON` so the same middleware chain (auth header, refresh-on-401, daemon routing)
/// applies to every request.
///
/// The adapters speak the Stripe-style `/v1` API. Its wire is snake_case with a unix-seconds
/// `created`/`updated` on every resource; ``decoder`` and ``normalizeTimestamps(_:)`` turn that into the
/// camelCase, ISO-string domain models (`createdAt`/`updatedAt`) the Hub layer keeps. Request bodies stay
/// camelCase: the gateway maps declared field names in either case, recursively. Lists arrive in the
/// `{object:"list", data, has_more}` envelope and are drained by ``list(_:query:as:)``.
@MainActor
public struct HubAPI {
    private let environment: HubEnvironment

    public init(environment: HubEnvironment) {
        self.environment = environment
    }

    /// Request-body encoder: ISO-8601 dates, stable key order so tests can compare bodies.
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// Response decoder: snake_case keys onto the camelCase models (string-keyed maps such as
    /// `metadata` keep their keys), and dates as unix seconds or ISO-8601.
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = JSONDecoder.adhDefault.dateDecodingStrategy
        return decoder
    }()

    /// The largest page `/v1` serves; ``list(_:query:as:)`` asks for it and follows `starting_after`.
    public static let pageLimit = 100

    /// Builds a query dictionary from optional values, dropping the nils.
    public static func query(_ pairs: [String: String?]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in pairs {
            if let value { result[key] = value }
        }
        return result
    }

    /// `base`'s fields plus `extra`: how a `/v1` POST carries an input the old route took in its path
    /// (`ecosystem`, `bucket`) beside the domain body.
    public static func body<B: Encodable>(_ base: B, adding extra: [String: String]) -> some Encodable {
        Extended(base: base, extra: extra)
    }

    private struct Extended<B: Encodable>: Encodable {
        let base: B
        let extra: [String: String]

        struct Key: CodingKey {
            let stringValue: String
            var intValue: Int? { nil }
            init(stringValue: String) { self.stringValue = stringValue }
            init?(intValue _: Int) { nil }
        }

        func encode(to encoder: any Encoder) throws {
            try base.encode(to: encoder)
            var container = encoder.container(keyedBy: Key.self)
            for (key, value) in extra {
                try container.encode(value, forKey: Key(stringValue: key))
            }
        }
    }

    public func get<T: Decodable>(_ path: String, query: [String: String] = [:], as type: T.Type) async throws -> T {
        let response = try await perform(.get, path, query: query, body: nil)
        return try decode(type, from: response, method: .get, path: path)
    }

    /// Every row of a `/v1` list, page after page: `limit=100`, then `starting_after=<last row's id>`
    /// while `has_more`. A list whose rows carry no `id` (feature flags, server bags) cannot be paged
    /// past its first page; a second page there throws rather than silently truncating.
    public func list<T: Decodable>(_ path: String, query: [String: String] = [:], as type: T.Type) async throws -> [T] {
        var rows: [T] = []
        var cursor: String?
        while true {
            var pageQuery = query
            pageQuery["limit"] = String(Self.pageLimit)
            if let cursor { pageQuery["starting_after"] = cursor }
            let response = try await perform(.get, path, query: pageQuery, body: nil)
            let page = try decode(ListPage<T>.self, from: response, method: .get, path: path)
            rows.append(contentsOf: page.data)
            guard page.hasMore else { return rows }
            guard let next = Self.lastID(in: response.body) else {
                throw HubError.unexpected("GET \(path) has more than \(Self.pageLimit) rows and no id to page by")
            }
            cursor = next
        }
    }

    /// The `/v1` list envelope.
    public struct ListPage<Row: Decodable>: Decodable {
        public let data: [Row]
        public let hasMore: Bool
    }

    public func send<T: Decodable>(
        _ method: HTTPRequest.Method, _ path: String, query: [String: String] = [:], as type: T.Type
    ) async throws -> T {
        let response = try await perform(method, path, query: query, body: nil)
        return try decode(type, from: response, method: method, path: path)
    }

    public func send<B: Encodable, T: Decodable>(
        _ method: HTTPRequest.Method, _ path: String, query: [String: String] = [:], body: B, as type: T.Type
    ) async throws -> T {
        let data = try encode(body, method: method, path: path)
        let response = try await perform(method, path, query: query, body: data)
        return try decode(type, from: response, method: method, path: path)
    }

    public func send<B: Encodable>(
        _ method: HTTPRequest.Method, _ path: String, query: [String: String] = [:], body: B
    ) async throws {
        let data = try encode(body, method: method, path: path)
        _ = try await perform(method, path, query: query, body: data)
    }

    public func send(_ method: HTTPRequest.Method, _ path: String, query: [String: String] = [:]) async throws {
        _ = try await perform(method, path, query: query, body: nil)
    }

    // MARK: - Internals

    private func perform(
        _ method: HTTPRequest.Method, _ path: String, query: [String: String], body: Data?
    ) async throws -> RawResponse {
        do {
            return try await environment.client.rawJSON(method: method, path: path, query: query, body: body)
        } catch {
            throw HubError.from(error)
        }
    }

    private func encode<B: Encodable>(_ body: B, method: HTTPRequest.Method, path: String) throws -> Data {
        do {
            return try Self.encoder.encode(body)
        } catch {
            throw HubError.unexpected("Unencodable request for \(method.rawValue) \(path): \(error)")
        }
    }

    private func decode<T: Decodable>(
        _ type: T.Type, from response: RawResponse, method: HTTPRequest.Method, path: String
    ) throws -> T {
        do {
            return try Self.decode(type, from: response.body)
        } catch {
            throw HubError.unexpected("Unreadable response for \(method.rawValue) \(path): \(error)")
        }
    }

    /// Decodes a `/v1` body onto a domain model, timestamps normalized first.
    public static func decode<T: Decodable>(_ type: T.Type, from body: Data) throws -> T {
        try decoder.decode(type, from: normalizeTimestamps(body))
    }

    /// Rewrites every `/v1` resource's unix-seconds `created`/`updated` (on an object carrying a string
    /// `object` or an `id`) to the ISO-8601 `createdAt`/`updatedAt` the domain models hold. Anything
    /// else, such as a user-defined map that happens to hold a `created` key, passes through untouched.
    public static func normalizeTimestamps(_ body: Data) -> Data {
        guard !body.isEmpty,
              let root = try? JSONSerialization.jsonObject(with: body, options: [.fragmentsAllowed])
        else { return body }
        var changed = false
        let rewritten = rewrite(root, changed: &changed)
        guard changed,
              let data = try? JSONSerialization.data(withJSONObject: rewritten, options: [.fragmentsAllowed])
        else { return body }
        return data
    }

    private static func rewrite(_ value: Any, changed: inout Bool) -> Any {
        if let array = value as? [Any] {
            return array.map { rewrite($0, changed: &changed) }
        }
        guard var object = value as? [String: Any] else { return value }
        // A resource names its `object`; a sub-row embedded in one (an access group's members) at least
        // carries an `id`. A user-defined map is neither, so its keys are left alone.
        let isResource = object["object"] is String || object["id"] != nil
        for (key, child) in object {
            object[key] = rewrite(child, changed: &changed)
        }
        guard isResource else { return object }
        for (wire, model) in [("created", "createdAt"), ("updated", "updatedAt")] {
            guard let number = object[wire] as? NSNumber, !isBool(number), object[model] == nil else { continue }
            object[model] = HubDates.iso(Date(timeIntervalSince1970: number.doubleValue))
            object[wire] = nil
            changed = true
        }
        return object
    }

    private static func isBool(_ number: NSNumber) -> Bool {
        CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    /// The last row's `id` in a list body, as a string (some ids are numbers).
    private static func lastID(in body: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let rows = object["data"] as? [[String: Any]], let last = rows.last
        else { return nil }
        if let id = last["id"] as? String { return id }
        if let id = last["id"] as? NSNumber, !isBool(id) { return id.stringValue }
        return nil
    }
}

extension HubError {
    /// A generated `/v1` operation's documented error: the envelope's message, mapped by status like
    /// ``HubError/fromStatus(_:body:)``.
    static func v1(_ status: Int, _ error: Components.Schemas.StripeError) -> HubError {
        fromStatus(status, body: (try? JSONEncoder().encode(error)) ?? Data())
    }
}
