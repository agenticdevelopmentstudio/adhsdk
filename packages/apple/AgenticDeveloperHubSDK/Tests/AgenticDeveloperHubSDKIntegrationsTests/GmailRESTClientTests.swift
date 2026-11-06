import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

/// URLProtocol stub. State is a lock-protected registry keyed by a per-test id carried in a
/// session header, so tests running in parallel never see each other's handlers or requests.
class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable {
        var status: Int
        var body: Data
    }

    nonisolated(unsafe) private static var replies: [String: Reply] = [:]
    nonisolated(unsafe) private static var seen: [String: [URLRequest]] = [:]
    private static let lock = NSLock()
    static let headerName = "X-Stub-Id"

    static func session(status: Int, body: Data) -> (URLSession, String) {
        let id = UUID().uuidString
        lock.withLock { replies[id] = Reply(status: status, body: body) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = [headerName: id]
        return (URLSession(configuration: config), id)
    }

    static func requests(_ id: String) -> [URLRequest] { lock.withLock { seen[id] ?? [] } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let id = request.value(forHTTPHeaderField: Self.headerName) ?? ""
        let reply = Self.lock.withLock { () -> Reply? in
            Self.seen[id, default: []].append(request)
            return Self.replies[id]
        }
        guard let reply, let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite struct GmailRESTClientTests {
    private func client(status: Int = 200, body: Data, token: String = "tok") -> (GmailRESTClient, String) {
        let (session, id) = StubURLProtocol.session(status: status, body: body)
        return (GmailRESTClient(session: session, accessToken: { token }), id)
    }

    @Test func historyNotFoundThrowsCursorExpired() async throws {
        let (api, _) = client(status: 404, body: Data(#"{"error":{"code":404,"message":"Not Found"}}"#.utf8))
        await #expect(throws: GmailCursorExpired.self) {
            _ = try await api.history(startHistoryId: "1", pageToken: nil)
        }
    }

    @Test func errorBodyMessageSurfaces() async throws {
        let body = #"{"error":{"code":403,"message":"Insufficient Permission","status":"PERMISSION_DENIED"}}"#
        let (api, _) = client(status: 403, body: Data(body.utf8))
        await #expect(throws: IntegrationError.gmail(status: 403, message: "Insufficient Permission")) {
            _ = try await api.profile()
        }
    }

    @Test func historyPageCollectsChangedAndDeleted() async throws {
        let (api, id) = client(body: try GmailFixture.data("history"))
        let page = try await api.history(startHistoryId: "100", pageToken: "p1")
        #expect(page.changedIds == ["a", "b"])
        #expect(page.deletedIds == ["c"])
        #expect(page.historyId == "950")
        #expect(page.nextPageToken == "p2")
        let url = try #require(StubURLProtocol.requests(id).first?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "historyTypes" }.compactMap(\.value)
            == ["messageAdded", "messageDeleted", "labelAdded", "labelRemoved"])
        #expect(items.contains { $0.name == "startHistoryId" && $0.value == "100" })
        #expect(items.contains { $0.name == "pageToken" && $0.value == "p1" })
        #expect(url.path == "/gmail/v1/users/me/history")
    }

    @Test func sendsBearerToken() async throws {
        let (api, id) = client(body: Data(#"{"emailAddress":"me@x.com","historyId":"7"}"#.utf8), token: "secret")
        let profile = try await api.profile()
        #expect(profile.emailAddress == "me@x.com")
        #expect(StubURLProtocol.requests(id).first?.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }

    @Test func listMessageIdsDedupesAndToleratesEmpty() async throws {
        let (api, _) = client(body: Data(#"{"messages":[{"id":"x"},{"id":"y"},{"id":"x"}],"nextPageToken":"n"}"#.utf8))
        let page = try await api.listMessageIds(query: "q", includeSpamTrash: true, pageToken: nil)
        #expect(page.ids == ["x", "y"])
        #expect(page.nextPageToken == "n")
        let (empty, _) = client(body: Data("{}".utf8))
        #expect(try await empty.listMessageIds(query: "q", includeSpamTrash: false, pageToken: nil).ids.isEmpty)
    }

    @Test func batchModifyPostsBody() async throws {
        let (api, id) = client(body: Data())
        try await api.batchModify(ids: ["a"], add: ["STARRED"], remove: ["INBOX"])
        let request = try #require(StubURLProtocol.requests(id).first)
        #expect(request.httpMethod == "POST")
        let bodyData = try #require(request.httpBody ?? request.httpBodyStream.map(Self.drain))
        let json = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: [String]])
        #expect(json == ["ids": ["a"], "addLabelIds": ["STARRED"], "removeLabelIds": ["INBOX"]])
    }

    private static func drain(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
