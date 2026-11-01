import Foundation
import Testing

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// Nested under ``StubURLProtocolSuites`` — see that type's doc comment for why.
extension StubURLProtocolSuites {
    @Suite("ADHSyncAPI (URLProtocol)")
    struct ADHSyncAPITests {

        private func makeSession() -> URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            return URLSession(configuration: configuration)
        }

        private func makeAPI(session: URLSession) -> ADHSyncAPI {
            ADHSyncAPI(
                credentials: InMemoryCredentialStore(Credentials(token: "tok-sync", kind: .jwt)),
                session: session
            )
        }

        private func fixture(_ name: String) throws -> Data {
            let bundle = Bundle(for: StubURLProtocol.self)
            let url = try #require(bundle.url(forResource: name, withExtension: "json"))
            return try Data(contentsOf: url)
        }

        @Test("pull hits /sync/pull with cursor, limit, and bearer; returns raw body")
        func pullRequestShape() async throws {
            let body = try fixture("pull-response")
            StubURLProtocol.install { _ in StubURLProtocol.Stub(statusCode: 200, body: body) }
            defer { StubURLProtocol.reset() }
            let data = try await makeAPI(session: makeSession()).pull(cursor: "abc123", limit: 250)
            #expect(data == body)
            let request = try #require(StubURLProtocol.capturedRequests.last)
            let requestURL = try #require(request.url)
            let components = try #require(URLComponents(url: requestURL, resolvingAgainstBaseURL: false))
            #expect(components.path == "/sync/pull")
            #expect(components.queryItems?.contains(URLQueryItem(name: "cursor", value: "abc123")) == true)
            #expect(components.queryItems?.contains(URLQueryItem(name: "limit", value: "250")) == true)
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok-sync")
        }

        @Test("pull without a cursor omits the parameter")
        func pullFirstSync() async throws {
            StubURLProtocol.install { _ in StubURLProtocol.Stub() }
            defer { StubURLProtocol.reset() }
            _ = try await makeAPI(session: makeSession()).pull(cursor: nil, limit: 500)
            let request = try #require(StubURLProtocol.capturedRequests.last)
            let requestURL = try #require(request.url)
            let components = try #require(URLComponents(url: requestURL, resolvingAgainstBaseURL: false))
            #expect(components.queryItems?.contains(where: { $0.name == "cursor" }) != true)
        }

        @Test("push POSTs the body as JSON and returns the raw response")
        func pushRoundTrip() async throws {
            let requestBody = try fixture("push-request")
            let responseBody = try fixture("push-response")
            StubURLProtocol.install { _ in StubURLProtocol.Stub(statusCode: 200, body: responseBody) }
            defer { StubURLProtocol.reset() }
            let data = try await makeAPI(session: makeSession()).push(body: requestBody)
            #expect(data == responseBody)
            let request = try #require(StubURLProtocol.capturedRequests.last)
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path == "/sync/push")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }

        @Test("401 → .unauthorized, 410 → .resyncRequired, 503 → .http(503)")
        func errorMapping() async throws {
            for (status, expected) in [(401, ADHSyncAPI.Failure.unauthorized), (410, .resyncRequired), (503, .http(503))] {
                StubURLProtocol.install { _ in StubURLProtocol.Stub(statusCode: status, body: Data(#"{"error":{"message":"x"}}"#.utf8)) }
                defer { StubURLProtocol.reset() }
                await #expect(throws: expected) {
                    _ = try await makeAPI(session: makeSession()).pull(cursor: nil, limit: 1)
                }
            }
        }

        @Test("URLSession transport failure surfaces as .transport")
        func transportFailureMapping() async throws {
            StubURLProtocol.install { _ in
                StubURLProtocol.Stub(error: URLError(.notConnectedToInternet))
            }
            defer { StubURLProtocol.reset() }
            await #expect {
                _ = try await makeAPI(session: makeSession()).pull(cursor: nil, limit: 1)
            } throws: { error in
                guard let failure = error as? ADHSyncAPI.Failure else { return false }
                if case .transport = failure { return true }
                return false
            }
        }
    }
}
