import Foundation
import Testing
import AIPluginKit
@testable import AgenticDeveloperHubSDKIntegrations

private actor FakeEndpoint: GoogleTokenEndpoint {
    private(set) var calls = 0
    private let result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>

    private let delay: Duration

    init(result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>,
         delay: Duration = .milliseconds(50)) {
        self.result = result
        self.delay = delay
    }

    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        calls += 1
        try await Task.sleep(for: delay)
        return try result.get()
    }
}

/// A token endpoint that holds every refresh until `release()`, so a test can act while one is
/// in progress without sleeping.
private actor GatedEndpoint: GoogleTokenEndpoint {
    private(set) var calls = 0
    private let result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>
    private var entered: [CheckedContinuation<Void, Never>] = []
    private var gates: [CheckedContinuation<Void, Never>] = []

    init(result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>) {
        self.result = result
    }

    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        calls += 1
        entered.forEach { $0.resume() }
        entered = []
        await withCheckedContinuation { gates.append($0) }
        return try result.get()
    }

    /// Returns once a refresh is waiting at the gate.
    func waitUntilEntered() async {
        if calls > 0 { return }
        await withCheckedContinuation { entered.append($0) }
    }

    func release() {
        gates.forEach { $0.resume() }
        gates = []
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
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch.addingTimeInterval(300)), connectionId: "c")
        let token = try await provider.accessToken(connectionId: "c", config: config)
        #expect(token == "old")
        #expect(await endpoint.calls == 0)
    }

    @Test func refreshesWhenWithin60Seconds() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, secrets) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
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
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                              expiresAt: epoch), connectionId: "c")
        let tokens = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<10 { group.addTask { try await provider.accessToken(connectionId: "c", config: config) } }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        #expect(tokens == Array(repeating: "new", count: 10))
        #expect(await endpoint.calls == 1)
    }

    @Test func invalidGrantThrowsRevoked() async throws {
        let endpoint = FakeEndpoint(result: .failure(.revoked))
        let (provider, _) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
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

    @Test func forgetRemovesCredential() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let (provider, secrets) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "a", refreshToken: "r",
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

    @Test func forgetDuringRefreshKeepsCredentialRemoved() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)), delay: .milliseconds(300))
        let (provider, secrets) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                                  expiresAt: epoch), connectionId: "c")
        let pending = Task { try await provider.accessToken(connectionId: "c", config: config) }
        try await Task.sleep(for: .milliseconds(50))
        await provider.forget(connectionId: "c")
        await #expect(throws: IntegrationError.revoked) { try await pending.value }
        #expect(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")) == nil)
    }

    @Test func storeDuringRefreshSurvivesStaleRefresh() async throws {
        let endpoint = FakeEndpoint(result: .success(("stale", 3600)), delay: .milliseconds(300))
        let (provider, secrets) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r1",
                                                  expiresAt: epoch), connectionId: "c")
        let pending = Task { try await provider.accessToken(connectionId: "c", config: config) }
        try await Task.sleep(for: .milliseconds(50))
        let fresh = GoogleCredential(accessToken: "signed-in", refreshToken: "r2",
                                     expiresAt: epoch.addingTimeInterval(3600))
        try await provider.store(fresh, connectionId: "c")
        #expect(try await pending.value == "signed-in")
        let raw = try #require(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")))
        #expect(try JSONDecoder().decode(GoogleCredential.self, from: Data(raw.utf8)) == fresh)
    }

    @Test func storeDuringFailingRefreshReturnsNewCredential() async throws {
        let endpoint = GatedEndpoint(result: .failure(.revoked))
        let secrets = InMemorySecretStore()
        let provider = GoogleTokenProvider(secrets: secrets, endpoint: endpoint, now: { epoch })
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r1",
                                                  expiresAt: epoch), connectionId: "c")
        let pending = Task { try await provider.accessToken(connectionId: "c", config: config) }
        await endpoint.waitUntilEntered()
        let fresh = GoogleCredential(accessToken: "signed-in", refreshToken: "r2",
                                     expiresAt: epoch.addingTimeInterval(3600))
        try await provider.store(fresh, connectionId: "c")
        await endpoint.release()
        #expect(try await pending.value == "signed-in")
        #expect(await endpoint.calls == 1)
        let raw = try #require(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")))
        #expect(try JSONDecoder().decode(GoogleCredential.self, from: Data(raw.utf8)) == fresh)
    }

    @Test func storeThrowsWhenKeychainWriteFails() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let provider = GoogleTokenProvider(secrets: FailingSecretStore(), endpoint: endpoint, now: { epoch })
        let credential = GoogleCredential(accessToken: "a", refreshToken: "r", expiresAt: epoch)
        await #expect(throws: IntegrationError.signInFailed("Could not save the Google credential to the Keychain")) {
            try await provider.store(credential, connectionId: "c")
        }
    }

    @Test func refreshPersistFailureSurfaces() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let seed = GoogleCredential(accessToken: "old", refreshToken: "r", expiresAt: epoch)
        let provider = GoogleTokenProvider(secrets: FailingSecretStore(seed: seed), endpoint: endpoint,
                                           now: { epoch })
        await #expect(throws: IntegrationError.signInFailed("Could not save the Google credential to the Keychain")) {
            try await provider.accessToken(connectionId: "c", config: config)
        }
    }

    @Test func deadlineTimesOutPromptlyAndCancelsFlow() async {
        let flow = HangingFlow()
        let started = ContinuousClock.now
        await #expect(throws: IntegrationError.signInFailed("Sign-in timed out")) {
            try await withSignInDeadline(timeout: .milliseconds(100), cancel: { flow.cancel() },
                                         operation: { try await flow.run() })
        }
        #expect(ContinuousClock.now - started < .seconds(5))
        #expect(flow.wasCancelled)
    }

    @Test func deadlineCancellationMapsToSignInCancelled() async throws {
        let flow = HangingFlow()
        let task = Task {
            try await withSignInDeadline(timeout: .seconds(60), cancel: { flow.cancel() },
                                         operation: { try await flow.run() })
        }
        try await Task.sleep(for: .milliseconds(50))
        task.cancel()
        await #expect(throws: IntegrationError.signInCancelled) { try await task.value }
        #expect(flow.wasCancelled)
    }

    @Test func deadlineReturnsOperationResult() async throws {
        let value = try await withSignInDeadline(timeout: .seconds(60), cancel: {}, operation: { 42 })
        #expect(value == 42)
    }
}

/// Stands in for AppAuth: `run` suspends until `cancel` resumes it with `signInCancelled`.
private final class HangingFlow: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Int, Error>?
    private var cancelled = false

    var wasCancelled: Bool { lock.withLock { cancelled } }

    func run() async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            let alreadyCancelled = lock.withLock { () -> Bool in
                if !cancelled { self.continuation = continuation }
                return cancelled
            }
            if alreadyCancelled { continuation.resume(throwing: IntegrationError.signInCancelled) }
        }
    }

    func cancel() {
        let pending = lock.withLock { () -> CheckedContinuation<Int, Error>? in
            cancelled = true
            defer { continuation = nil }
            return continuation
        }
        pending?.resume(throwing: IntegrationError.signInCancelled)
    }
}

/// A SecretStoring whose writes always fail; optionally seeded with a readable credential.
private final class FailingSecretStore: SecretStoring, @unchecked Sendable {
    private let seed: String?

    init(seed: GoogleCredential? = nil) {
        self.seed = seed.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) }
    }

    func get(forKey key: String) -> String? { seed }
    func set(_ value: String, forKey key: String) -> Bool { false }
    func delete(forKey key: String) -> Bool { true }
    func deleteLegacy(forKey key: String) -> Bool { true }
}
