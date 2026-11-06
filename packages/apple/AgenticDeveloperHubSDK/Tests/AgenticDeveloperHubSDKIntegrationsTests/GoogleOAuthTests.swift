import Foundation
import Testing
import AIPluginKit
@testable import AgenticDeveloperHubSDKIntegrations

private actor FakeEndpoint: GoogleTokenEndpoint {
    private(set) var calls = 0
    private let result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>

    init(result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>) {
        self.result = result
    }

    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        calls += 1
        try await Task.sleep(for: .milliseconds(50))
        return try result.get()
    }
}

private let config = GoogleOAuthClientConfig(clientId: "id", clientSecret: "secret")
private let epoch = Date(timeIntervalSince1970: 1_000_000)

private func makeProvider(
    _ endpoint: FakeEndpoint, secrets: InMemorySecretStore = InMemorySecretStore()
) -> (GoogleTokenProvider, InMemorySecretStore) {
    (GoogleTokenProvider(secrets: secrets, endpoint: endpoint, now: { epoch }), secrets)
}

@Suite struct GoogleOAuthTests {
    @Test func parsesInstalledClientJSON() throws {
        let json = Data(#"{"installed":{"client_id":"abc","client_secret":"xyz","auth_uri":"u"}}"#.utf8)
        let parsed = try GoogleOAuthClientConfig.parse(json: json)
        #expect(parsed == GoogleOAuthClientConfig(clientId: "abc", clientSecret: "xyz"))
    }

    @Test func rejectsWebClientJSON() {
        let json = Data(#"{"web":{"client_id":"abc","client_secret":"xyz"}}"#.utf8)
        #expect(throws: IntegrationError.self) { try GoogleOAuthClientConfig.parse(json: json) }
    }

    @Test func rejectsMissingKeys() {
        let json = Data(#"{"installed":{"client_id":"abc"}}"#.utf8)
        #expect(throws: IntegrationError.self) { try GoogleOAuthClientConfig.parse(json: json) }
    }

    @Test func returnsCachedTokenWhenFresh() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, _) = makeProvider(endpoint)
        await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch.addingTimeInterval(300)), connectionId: "c")
        let token = try await provider.accessToken(connectionId: "c", config: config)
        #expect(token == "old")
        #expect(await endpoint.calls == 0)
    }

    @Test func refreshesWhenWithin60Seconds() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, secrets) = makeProvider(endpoint)
        await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch.addingTimeInterval(30)), connectionId: "c")
        let token = try await provider.accessToken(connectionId: "c", config: config)
        #expect(token == "new")
        let raw = try #require(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")))
        let stored = try JSONDecoder().decode(GoogleCredential.self, from: Data(raw.utf8))
        #expect(stored.accessToken == "new")
        #expect(stored.refreshToken == "r")
        #expect(stored.expiresAt == epoch.addingTimeInterval(3600))
    }

    @Test func concurrentCallersShareOneRefresh() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, _) = makeProvider(endpoint)
        await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch), connectionId: "c")
        let tokens = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<10 { group.addTask { try await provider.accessToken(connectionId: "c", config: config) } }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        #expect(tokens == Array(repeating: "new", count: 10))
        #expect(await endpoint.calls == 1)
    }

    @Test func invalidGrantThrowsRevoked() async {
        let endpoint = FakeEndpoint(result: .failure(.revoked))
        let (provider, _) = makeProvider(endpoint)
        await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch), connectionId: "c")
        await #expect(throws: IntegrationError.revoked) {
            try await provider.accessToken(connectionId: "c", config: config)
        }
    }

    @Test func missingCredentialThrowsRevoked() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, _) = makeProvider(endpoint)
        await #expect(throws: IntegrationError.revoked) {
            try await provider.accessToken(connectionId: "nope", config: config)
        }
    }

    @Test func forgetRemovesCredential() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, secrets) = makeProvider(endpoint)
        await provider.store(GoogleCredential(accessToken: "a", refreshToken: "r",
                                              expiresAt: epoch), connectionId: "c")
        await provider.forget(connectionId: "c")
        #expect(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")) == nil)
    }

    @Test func tokenEndpointMapsInvalidGrantToRevoked() async {
        let body = Data(#"{"error":"invalid_grant","error_description":"Token revoked"}"#.utf8)
        let (session, _) = StubURLProtocol.session(status: 400, body: body)
        let endpoint = URLSessionGoogleTokenEndpoint(session: session)
        await #expect(throws: IntegrationError.revoked) {
            try await endpoint.refresh(refreshToken: "r", config: config)
        }
    }

    @Test func tokenEndpointParsesSuccess() async throws {
        let body = Data(#"{"access_token":"tok","expires_in":3599,"token_type":"Bearer"}"#.utf8)
        let (session, _) = StubURLProtocol.session(status: 200, body: body)
        let endpoint = URLSessionGoogleTokenEndpoint(session: session)
        let result = try await endpoint.refresh(refreshToken: "r", config: config)
        #expect(result.accessToken == "tok")
        #expect(result.expiresIn == 3599)
    }
}
