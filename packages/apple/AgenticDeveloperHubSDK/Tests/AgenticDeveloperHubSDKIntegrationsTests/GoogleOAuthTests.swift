import Foundation
import Testing
import AIPluginKit
@testable import AgenticDeveloperHubSDKIntegrations

private actor FakeEndpoint: GoogleTokenEndpoint {
    private(set) var calls = 0
    /// The refresh tokens `revoke` was called with, in order.
    private(set) var revoked: [String] = []
    private let result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>
    private let revokeError: IntegrationError?

    init(result: Result<(accessToken: String, expiresIn: TimeInterval), IntegrationError>,
         revokeError: IntegrationError? = nil) {
        self.result = result
        self.revokeError = revokeError
    }

    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        calls += 1
        return try result.get()
    }

    func revoke(token: String) async throws {
        revoked.append(token)
        if let revokeError { throw revokeError }
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

    func revoke(token: String) async throws {}
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
        try await provider.forget(connectionId: "c")
        #expect(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")) == nil)
    }

    @Test func forgetThrowsWhenTheKeychainDeleteFails() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let provider = GoogleTokenProvider(secrets: FailingSecretStore(deleteSucceeds: false), endpoint: endpoint,
                                           now: { epoch })
        await #expect(throws: IntegrationError.keychain("Could not remove the Google credential")) {
            try await provider.forget(connectionId: "c")
        }
    }

    @Test func aKeychainReadErrorIsNotReportedAsRevoked() async {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let provider = GoogleTokenProvider(secrets: UnreadableSecretStore(), endpoint: endpoint, now: { epoch })
        await #expect(throws: IntegrationError.keychain("Could not read the Google credential: locked")) {
            try await provider.accessToken(connectionId: "c", config: config)
        }
        #expect(await endpoint.calls == 0)
    }

    @Test func aFailedRefreshIsNotReusedByTheNextCall() async throws {
        let endpoint = FakeEndpoint(result: .failure(.tokenRefresh("500 backend_error")))
        let (provider, _) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                                  expiresAt: epoch), connectionId: "c")
        for _ in 0..<2 {
            await #expect(throws: IntegrationError.tokenRefresh("500 backend_error")) {
                try await provider.accessToken(connectionId: "c", config: config)
            }
        }
        #expect(await endpoint.calls == 2)
    }

    @Test func revokeSendsTheRefreshTokenAndIgnoresFailure() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)), revokeError: .tokenRefresh("400 invalid_token"))
        let (provider, secrets) = makeProvider(endpoint)
        try await provider.store(GoogleCredential(accessToken: "a", refreshToken: "r1",
                                                  expiresAt: epoch), connectionId: "c")
        await provider.revoke(connectionId: "c")
        await provider.revoke(connectionId: "missing")
        #expect(await endpoint.revoked == ["r1"])
        #expect(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")) != nil, "revoke does not forget")
    }

    @Test func signInFallbackExpiryUsesTheInjectedClock() throws {
        let credential = try AppAuthGoogleSignIn.credential(
            accessToken: "a", refreshToken: "r", expiresAt: nil, now: epoch)
        #expect(credential == GoogleCredential(accessToken: "a", refreshToken: "r",
                                               expiresAt: epoch.addingTimeInterval(3600)))
        #expect(throws: IntegrationError.signInFailed("Google returned no refresh token")) {
            try AppAuthGoogleSignIn.credential(accessToken: "a", refreshToken: "", expiresAt: nil, now: epoch)
        }
        #expect(throws: IntegrationError.signInFailed("Google returned no access token")) {
            try AppAuthGoogleSignIn.credential(accessToken: nil, refreshToken: "r", expiresAt: nil, now: epoch)
        }
    }

    @Test func tokenEndpointMapsInvalidGrantToRevoked() async {
        let body = Data(#"{"error":"invalid_grant","error_description":"Token revoked"}"#.utf8)
        let stub = StubURLProtocol.stub(status: 400, body: body)
        defer { stub.unregister() }
        let session = stub.session
        let endpoint = URLSessionGoogleTokenEndpoint(session: session)
        await #expect(throws: IntegrationError.revoked) {
            try await endpoint.refresh(refreshToken: "r", config: config)
        }
    }

    @Test func tokenEndpointParsesSuccess() async throws {
        let body = Data(#"{"access_token":"tok","expires_in":3599,"token_type":"Bearer"}"#.utf8)
        let stub = StubURLProtocol.stub(status: 200, body: body)
        defer { stub.unregister() }
        let session = stub.session
        let endpoint = URLSessionGoogleTokenEndpoint(session: session)
        let result = try await endpoint.refresh(refreshToken: "r", config: config)
        #expect(result.accessToken == "tok")
        #expect(result.expiresIn == 3599)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://oauth2.googleapis.com/token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
        let sent = StubURLProtocol.body(of: request).flatMap { String(data: $0, encoding: .utf8) }
        #expect(sent == "grant_type=refresh_token&refresh_token=r&client_id=id&client_secret=secret")
    }

    @Test func tokenEndpointPercentEncodesPlusAndReservedCharacters() async throws {
        let body = Data(#"{"access_token":"tok","expires_in":3599}"#.utf8)
        let stub = StubURLProtocol.stub(status: 200, body: body)
        defer { stub.unregister() }
        let endpoint = URLSessionGoogleTokenEndpoint(session: stub.session)
        _ = try await endpoint.refresh(
            refreshToken: "1//a+b/c=d&e", config: GoogleOAuthClientConfig(clientId: "id", clientSecret: "s+t ~"))
        let request = try #require(stub.requests.first)
        let sent = StubURLProtocol.body(of: request).flatMap { String(data: $0, encoding: .utf8) }
        #expect(sent == "grant_type=refresh_token&refresh_token=1%2F%2Fa%2Bb%2Fc%3Dd%26e"
                    + "&client_id=id&client_secret=s%2Bt%20~")
    }

    @Test func tokenEndpointReportsOtherFailuresAsRefreshErrors() async {
        let stub = StubURLProtocol.stub(status: 500, body: Data(#"{"error":"backend_error"}"#.utf8))
        defer { stub.unregister() }
        let endpoint = URLSessionGoogleTokenEndpoint(session: stub.session)
        await #expect(throws: IntegrationError.tokenRefresh("500 backend_error")) {
            try await endpoint.refresh(refreshToken: "r", config: config)
        }
    }

    @Test func tokenEndpointRevokePostsTheTokenToGoogle() async throws {
        let stub = StubURLProtocol.stub(status: 200, body: Data())
        defer { stub.unregister() }
        let endpoint = URLSessionGoogleTokenEndpoint(session: stub.session)
        try await endpoint.revoke(token: "1//r+t")
        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://oauth2.googleapis.com/revoke")
        let sent = StubURLProtocol.body(of: request).flatMap { String(data: $0, encoding: .utf8) }
        #expect(sent == "token=1%2F%2Fr%2Bt")
    }

    @Test func tokenEndpointRevokeFailureThrows() async {
        let stub = StubURLProtocol.stub(status: 400, body: Data(#"{"error":"invalid_token"}"#.utf8))
        defer { stub.unregister() }
        let endpoint = URLSessionGoogleTokenEndpoint(session: stub.session)
        await #expect(throws: IntegrationError.tokenRefresh("revoke failed: 400 invalid_token")) {
            try await endpoint.revoke(token: "r")
        }
    }

    @Test func forgetDuringRefreshKeepsCredentialRemoved() async throws {
        let endpoint = GatedEndpoint(result: .success(("new", 3600)))
        let secrets = InMemorySecretStore()
        let provider = GoogleTokenProvider(secrets: secrets, endpoint: endpoint, now: { epoch })
        try await provider.store(GoogleCredential(accessToken: "old", refreshToken: "r",
                                                  expiresAt: epoch), connectionId: "c")
        let pending = Task { try await provider.accessToken(connectionId: "c", config: config) }
        await endpoint.waitUntilEntered()
        try await provider.forget(connectionId: "c")
        await endpoint.release()
        await #expect(throws: IntegrationError.revoked) { try await pending.value }
        #expect(secrets.get(forKey: GoogleTokenProvider.key(connectionId: "c")) == nil)
    }

    @Test func storeDuringRefreshSurvivesStaleRefresh() async throws {
        let endpoint = GatedEndpoint(result: .success(("stale", 3600)))
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

    @Test func aRefreshThatCouldNotBeSavedIsStillUsedByLaterCalls() async throws {
        let endpoint = FakeEndpoint(result: .success(("new", 3600)))
        let seed = GoogleCredential(accessToken: "old", refreshToken: "r", expiresAt: epoch)
        let provider = GoogleTokenProvider(secrets: FailingSecretStore(seed: seed), endpoint: endpoint,
                                           now: { epoch })
        _ = try? await provider.accessToken(connectionId: "c", config: config)
        #expect(try await provider.accessToken(connectionId: "c", config: config) == "new")
        #expect(try await provider.accessToken(connectionId: "c", config: config) == "new")
        #expect(await endpoint.calls == 1)
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

    @Test(.timeLimit(.minutes(1)))
    func deadlineCancellationMapsToSignInCancelled() async throws {
        let flow = HangingFlow()
        let task = Task {
            try await withSignInDeadline(timeout: .seconds(60), cancel: { flow.cancel() },
                                         operation: { try await flow.run() })
        }
        await flow.waitUntilRunning()
        task.cancel()
        await #expect(throws: IntegrationError.signInCancelled) { try await task.value }
        await flow.waitUntilCancelled()
    }

    @Test(.timeLimit(.minutes(1)))
    func deadlineIsPromptEvenWhenTheOperationIgnoresCancellation() async throws {
        let started = ContinuousClock.now
        await #expect(throws: IntegrationError.signInFailed("Sign-in timed out")) {
            try await withSignInDeadline(timeout: .milliseconds(100), cancel: {},
                                         operation: { await Self.ignoreCancellation(); return 1 })
        }
        #expect(ContinuousClock.now - started < .seconds(5))

        let task = Task {
            try await withSignInDeadline(timeout: .seconds(60), cancel: {},
                                         operation: { await Self.ignoreCancellation(); return 1 })
        }
        task.cancel()
        await #expect(throws: IntegrationError.signInCancelled) { try await task.value }
    }

    /// Stands in for a code exchange that does not react to cancellation: it never returns.
    private static func ignoreCancellation() async {
        await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
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
    private var running = false
    private var runningWaiters: [CheckedContinuation<Void, Never>] = []
    private var cancelWaiters: [CheckedContinuation<Void, Never>] = []

    var wasCancelled: Bool { lock.withLock { cancelled } }

    func run() async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            let (alreadyCancelled, waiters) = lock.withLock { () -> (Bool, [CheckedContinuation<Void, Never>]) in
                if !cancelled { self.continuation = continuation }
                running = true
                defer { runningWaiters = [] }
                return (cancelled, runningWaiters)
            }
            waiters.forEach { $0.resume() }
            if alreadyCancelled { continuation.resume(throwing: IntegrationError.signInCancelled) }
        }
    }

    func cancel() {
        let (pending, waiters) = lock.withLock {
            () -> (CheckedContinuation<Int, Error>?, [CheckedContinuation<Void, Never>]) in
            cancelled = true
            defer {
                continuation = nil
                cancelWaiters = []
            }
            return (continuation, cancelWaiters)
        }
        pending?.resume(throwing: IntegrationError.signInCancelled)
        waiters.forEach { $0.resume() }
    }

    /// Returns once `run` has started.
    func waitUntilRunning() async {
        await withCheckedContinuation { waiter in
            let now = lock.withLock { () -> Bool in
                if !running { runningWaiters.append(waiter) }
                return running
            }
            if now { waiter.resume() }
        }
    }

    /// Returns once `cancel` has been called.
    func waitUntilCancelled() async {
        await withCheckedContinuation { waiter in
            let now = lock.withLock { () -> Bool in
                if !cancelled { cancelWaiters.append(waiter) }
                return cancelled
            }
            if now { waiter.resume() }
        }
    }
}

/// A SecretStoring whose writes always fail; optionally seeded with a readable credential.
private final class FailingSecretStore: SecretStoring, @unchecked Sendable {
    private let seed: String?
    private let deleteSucceeds: Bool

    init(seed: GoogleCredential? = nil, deleteSucceeds: Bool = true) {
        self.seed = seed.flatMap { try? JSONEncoder().encode($0) }.flatMap { String(data: $0, encoding: .utf8) }
        self.deleteSucceeds = deleteSucceeds
    }

    func get(forKey key: String) -> String? { seed }
    func set(_ value: String, forKey key: String) -> Bool { false }
    func delete(forKey key: String) -> Bool { deleteSucceeds }
    func deleteLegacy(forKey key: String) -> Bool { true }
}

/// A SecretStoring whose reads fail the way a locked or denied Keychain does.
private final class UnreadableSecretStore: SecretStoring, @unchecked Sendable {
    struct Locked: Error, LocalizedError {
        var errorDescription: String? { "locked" }
    }

    func get(forKey key: String) -> String? { nil }
    func read(forKey key: String) throws -> String? { throw Locked() }
    func set(_ value: String, forKey key: String) -> Bool { true }
    func delete(forKey key: String) -> Bool { true }
    func deleteLegacy(forKey key: String) -> Bool { true }
}
