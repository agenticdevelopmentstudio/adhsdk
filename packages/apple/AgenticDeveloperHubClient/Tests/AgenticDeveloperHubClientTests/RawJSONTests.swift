import HTTPTypes
import OpenAPIRuntime
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

@Suite("rawJSON escape hatch")
struct RawJSONTests {

    @Test("runs through the session middleware: bearer attached, query encoded, body forwarded")
    func goesThroughMiddleware() async throws {
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1"))
        let mock = MockClientTransport { _ in
            var response = HTTPResponse(status: .ok)
            response.headerFields[.contentType] = "application/json"
            return (response, HTTPBody(Data(#"[{"id":"o1"}]"#.utf8)))
        }
        let adh = ADHClient(transport: .direct(transport: mock), session: store)

        let response = try await adh.rawJSON(method: .get, path: "/organization/organizations", query: ["workspace": "a b"])

        #expect(response.status == 200)
        #expect(response.body == Data(#"[{"id":"o1"}]"#.utf8))
        let sent = try #require(mock.lastRequest)
        #expect(sent.path == "/organization/organizations?workspace=a%20b")
        #expect(sent.headerFields[.authorization] == "Bearer jwt-1")
        #expect(mock.lastBaseURL == DaemonContract.backendURL)
        struct Org: Decodable { let id: String }
        #expect(try response.decode([Org].self).first?.id == "o1")
    }

    @Test("a 401 is refreshed and retried like any typed operation")
    func refreshesOn401() async throws {
        // A unique access token per test: refreshes serialize through the
        // process-wide `RefreshCoordinator.shared`, which identifies a refresh
        // wave by the expired access token (real tokens never collide).
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-raw", kind: .jwt), refreshToken: "r-raw"))
        let mock = MockClientTransport { request in
            if request.path == "/auth/refresh" {
                var response = HTTPResponse(status: .ok)
                response.headerFields[.contentType] = "application/json"
                return (response, HTTPBody(Data(#"{"token":"jwt-2","refreshToken":"r-2"}"#.utf8)))
            }
            if request.headerFields[.authorization] == "Bearer jwt-raw" {
                return (HTTPResponse(status: .unauthorized), nil)
            }
            return (HTTPResponse(status: .ok), HTTPBody(Data("{}".utf8)))
        }
        let adh = ADHClient(transport: .direct(transport: mock), session: store)

        let response = try await adh.rawJSON(method: .put, path: "/me/workspace-prefs", body: Data(#"{"x":1}"#.utf8))

        #expect(response.status == 200)
        #expect(mock.recorded.map { $0.request.path ?? "" } == ["/me/workspace-prefs", "/auth/refresh", "/me/workspace-prefs"])
        #expect(mock.recorded.last?.request.headerFields[.contentType] == "application/json")
    }

    @Test("status >= 400 throws RawRequestError.http with the body")
    func throwsOnError() async throws {
        let mock = MockClientTransport { _ in (HTTPResponse(status: .notFound), HTTPBody(Data(#"{"error":"nope"}"#.utf8))) }
        let adh = ADHClient(transport: .direct(transport: mock), session: InMemorySessionStore())

        await #expect(throws: RawRequestError.http(status: 404, body: Data(#"{"error":"nope"}"#.utf8))) {
            try await adh.rawJSON(method: .get, path: "/billing/context")
        }
    }

    @Test("a path without a leading slash is rejected")
    func rejectsRelativePath() async throws {
        let adh = ADHClient(transport: .direct(transport: MockClientTransport()), session: InMemorySessionStore())
        await #expect(throws: RawRequestError.invalidPath("billing/context")) {
            try await adh.rawJSON(method: .get, path: "billing/context")
        }
    }
}
