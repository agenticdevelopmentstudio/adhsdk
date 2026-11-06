import Foundation

/// `GmailAPI` over URLSession. Holds no mutable state; the token closure supplies a fresh
/// access token per request.
///
/// A 429, a 5xx or a transient network error (timed out, connection lost, offline, host
/// unreachable) is retried up to `maxRetries` times with exponential backoff — 1 s, doubling,
/// capped at 32 s — or after the server's `Retry-After` seconds when it sends one (also capped).
/// Anything else, and the last failure once the retries are spent, is thrown.
public final class GmailRESTClient: GmailAPI {
    private static let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/"
    /// Gmail's own limit on ids per `messages/batchModify` call.
    public static let batchModifyLimit = 1000
    static let maxRetries = 4
    private static let baseDelay: Duration = .seconds(1)
    private static let maxDelay: Duration = .seconds(32)
    private static let transientCodes: Set<URLError.Code> = [
        .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost
    ]

    private let session: URLSession
    private let sleep: @Sendable (Duration) async throws -> Void
    private let accessToken: @Sendable () async throws -> String

    /// - Parameter sleep: waits out a backoff. Injected so tests record delays instead of sleeping.
    public init(session: URLSession = .shared,
                sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
                accessToken: @escaping @Sendable () async throws -> String) {
        self.session = session
        self.sleep = sleep
        self.accessToken = accessToken
    }

    public func profile() async throws -> GmailProfile {
        try await get("profile", [], GmailProfile.self)
    }

    public func listMessageIds(query: String, includeSpamTrash: Bool, pageToken: String?) async throws -> GmailIdPage {
        struct Wire: Decodable {
            struct Item: Decodable { let id: String }
            let messages: [Item]?
            let nextPageToken: String?
        }
        var items = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "maxResults", value: "500")]
        if includeSpamTrash { items.append(URLQueryItem(name: "includeSpamTrash", value: "true")) }
        if let pageToken { items.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        let wire = try await get("messages", items, Wire.self)
        return GmailIdPage(ids: Self.unique((wire.messages ?? []).map(\.id)), nextPageToken: wire.nextPageToken)
    }

    public func message(id: String) async throws -> GmailMessageDTO {
        try await get("messages/\(id)", [URLQueryItem(name: "format", value: "full")], GmailMessageDTO.self)
    }

    public func history(startHistoryId: String, pageToken: String?) async throws -> GmailHistoryPage {
        struct Ref: Decodable {
            struct Msg: Decodable { let id: String }
            let message: Msg
        }
        struct Entry: Decodable {
            let messagesAdded: [Ref]?
            let messagesDeleted: [Ref]?
            let labelsAdded: [Ref]?
            let labelsRemoved: [Ref]?
        }
        struct Wire: Decodable {
            let history: [Entry]?
            let historyId: String
            let nextPageToken: String?
        }
        var items = [URLQueryItem(name: "startHistoryId", value: startHistoryId)]
        for type in ["messageAdded", "messageDeleted", "labelAdded", "labelRemoved"] {
            items.append(URLQueryItem(name: "historyTypes", value: type))
        }
        if let pageToken { items.append(URLQueryItem(name: "pageToken", value: pageToken)) }
        let wire: Wire
        do {
            wire = try await get("history", items, Wire.self)
        } catch IntegrationError.gmail(status: 404, message: _) {
            throw GmailCursorExpired()
        }
        var changed: [String] = []
        var deleted: [String] = []
        for entry in wire.history ?? [] {
            changed += ((entry.messagesAdded ?? []) + (entry.labelsAdded ?? []) + (entry.labelsRemoved ?? []))
                .map(\.message.id)
            deleted += (entry.messagesDeleted ?? []).map(\.message.id)
        }
        let deletedIds = Self.unique(deleted)
        let deletedSet = Set(deletedIds)
        return GmailHistoryPage(
            changedIds: Self.unique(changed).filter { !deletedSet.contains($0) },
            deletedIds: deletedIds, historyId: wire.historyId, nextPageToken: wire.nextPageToken
        )
    }

    public func labels() async throws -> [GmailLabelDTO] {
        struct Wire: Decodable { let labels: [GmailLabelDTO]? }
        return try await get("labels", [], Wire.self).labels ?? []
    }

    public func batchModify(ids: [String], add: [String], remove: [String]) async throws {
        struct Body: Encodable {
            let ids: [String]
            let addLabelIds: [String]
            let removeLabelIds: [String]
        }
        // The caller chunks; an empty or oversized list is a caller bug, not a Gmail call.
        guard (1...Self.batchModifyLimit).contains(ids.count) else {
            throw IntegrationError.gmail(
                status: 0, message: "batchModify takes 1–\(Self.batchModifyLimit) ids, got \(ids.count)")
        }
        var request = try await makeRequest("messages/batchModify", [])
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(ids: ids, addLabelIds: add, removeLabelIds: remove))
        _ = try await send(request)
    }

    // MARK: - Plumbing

    private static func unique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    private func makeRequest(_ path: String, _ query: [URLQueryItem]) async throws -> URLRequest {
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw IntegrationError.gmail(status: 0, message: "Invalid URL for \(path)")
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else {
            throw IntegrationError.gmail(status: 0, message: "Invalid URL for \(path)")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
        return request
    }

    private func get<T: Decodable>(_ path: String, _ query: [URLQueryItem], _ type: T.Type) async throws -> T {
        let data = try await send(try await makeRequest(path, query))
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        var retry = 0
        while true {
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let error as URLError where Self.transientCodes.contains(error.code) && retry < Self.maxRetries {
                try await sleep(Self.backoff(retry: retry, retryAfter: nil))
                retry += 1
                continue
            }
            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            if (200..<300).contains(status) { return data }
            guard Self.isRetryable(status), retry < Self.maxRetries else {
                throw IntegrationError.gmail(status: status, message: Self.errorMessage(data, status: status))
            }
            let retryAfter = http?.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            try await sleep(Self.backoff(retry: retry, retryAfter: retryAfter))
            retry += 1
        }
    }

    private static func isRetryable(_ status: Int) -> Bool { status == 429 || (500..<600).contains(status) }

    /// The wait before retry number `retry` (0-based): the server's `Retry-After` seconds when
    /// given, else 1 s doubled per retry; either way no more than 32 s.
    static func backoff(retry: Int, retryAfter: Int?) -> Duration {
        let wanted: Duration
        if let retryAfter {
            wanted = .seconds(max(retryAfter, 0))
        } else {
            wanted = baseDelay * (1 << min(retry, 6))
        }
        return min(wanted, maxDelay)
    }

    private static func errorMessage(_ data: Data, status: Int) -> String {
        struct Envelope: Decodable {
            struct Detail: Decodable { let message: String? }
            let error: Detail?
        }
        if let message = (try? JSONDecoder().decode(Envelope.self, from: data))?.error?.message { return message }
        return HTTPURLResponse.localizedString(forStatusCode: status)
    }
}
