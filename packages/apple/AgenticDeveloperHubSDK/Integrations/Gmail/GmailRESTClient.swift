import Foundation

/// `GmailAPI` over URLSession. Holds no mutable state; the token closure supplies a fresh
/// access token per request.
public final class GmailRESTClient: GmailAPI {
    private static let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me/"
    private let session: URLSession
    private let accessToken: @Sendable () async throws -> String

    public init(session: URLSession = .shared, accessToken: @escaping @Sendable () async throws -> String) {
        self.session = session
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
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw IntegrationError.gmail(status: status, message: Self.errorMessage(data, status: status))
        }
        return data
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
