import AIPluginKit
import AppKit
import Foundation
@preconcurrency import AppAuth

/// Tokens for one connected Google account.
public struct GoogleCredential: Codable, Sendable, Equatable {
    public var accessToken: String
    public var refreshToken: String
    public var expiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

/// Runs the interactive Google sign-in.
public protocol GoogleSignInFlow: Sendable {
    func signIn(config: GoogleOAuthClientConfig) async throws -> GoogleCredential
}

/// AppAuth loopback sign-in: opens the default browser, receives the redirect on 127.0.0.1.
/// Verified manually (no unit test); the browser round trip cannot run headless.
public struct AppAuthGoogleSignIn: GoogleSignInFlow {
    static let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
    static let scopes = ["openid", "email", "https://www.googleapis.com/auth/gmail.modify"]

    private let timeout: Duration

    public init(timeout: Duration = .seconds(300)) { self.timeout = timeout }

    public func signIn(config: GoogleOAuthClientConfig) async throws -> GoogleCredential {
        let box = SessionBox()
        return try await withSignInDeadline(
            timeout: timeout,
            cancel: { await box.cancel() },
            operation: { try await Self.run(config: config, box: box) })
    }

    /// Main-actor handle on the live AppAuth flow so a timeout or cancellation can tear it down.
    @MainActor
    private final class SessionBox: @unchecked Sendable {
        nonisolated init() {}
        var flow: (any OIDExternalUserAgentSession)?
        var handler: OIDRedirectHTTPHandler?
        private(set) var cancelled = false

        func cancel() {
            cancelled = true
            flow?.cancel()
            handler?.cancelHTTPListener()
        }
    }

    @MainActor
    private static func run(config: GoogleOAuthClientConfig, box: SessionBox) async throws -> GoogleCredential {
        guard let authURL = URL(string: authorizationEndpoint), let tokenURL = URL(string: tokenEndpoint) else {
            throw IntegrationError.signInFailed("invalid Google endpoints")
        }
        let handler = OIDRedirectHTTPHandler(successURL: nil)
        box.handler = handler
        // startHTTPListener returns nil on a bind failure, but Swift imports it as non-null and
        // would trap. Calling it through the runtime (a nil error out-parameter is tolerated)
        // yields an optional we can check.
        let raw = handler.perform(NSSelectorFromString("startHTTPListener:"), with: nil)
        guard let redirect = raw?.takeUnretainedValue() as? URL else {
            throw IntegrationError.signInFailed("Could not start the local sign-in listener")
        }
        defer { handler.cancelHTTPListener() }

        let request = OIDAuthorizationRequest(
            configuration: OIDServiceConfiguration(authorizationEndpoint: authURL, tokenEndpoint: tokenURL),
            clientId: config.clientId, clientSecret: config.clientSecret, scopes: scopes,
            redirectURL: redirect, responseType: OIDResponseTypeCode,
            additionalParameters: ["access_type": "offline", "prompt": "consent"])

        // The deadline helper cancels via `box` (main actor), so no browser opens once cancelled and
        // a cancel after presenting resumes the continuation through AppAuth's callback.
        if box.cancelled { throw IntegrationError.signInCancelled }
        let state: OIDAuthState = try await withCheckedThrowingContinuation { continuation in
            box.flow = OIDAuthState.authState(
                byPresenting: request, externalUserAgent: DefaultBrowserUserAgent()
            ) { authState, error in
                if let authState {
                    continuation.resume(returning: authState)
                } else {
                    continuation.resume(throwing: Self.map(error))
                }
            }
            handler.currentAuthorizationFlow = box.flow
            if box.cancelled { box.cancel() }
        }
        let tokens = state.lastTokenResponse
        guard let access = tokens?.accessToken else {
            throw IntegrationError.signInFailed("Google returned no access token")
        }
        guard let refresh = tokens?.refreshToken, !refresh.isEmpty else {
            throw IntegrationError.signInFailed("Google returned no refresh token")
        }
        return GoogleCredential(accessToken: access, refreshToken: refresh,
                                expiresAt: tokens?.accessTokenExpirationDate ?? Date().addingTimeInterval(3600))
    }

    private static func map(_ error: (any Error)?) -> IntegrationError {
        guard let error = error as NSError? else { return .signInFailed("unknown error") }
        if error.domain == OIDGeneralErrorDomain,
           error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
            || error.code == OIDErrorCode.programCanceledAuthorizationFlow.rawValue {
            return .signInCancelled
        }
        return .signInFailed(error.localizedDescription)
    }
}

/// Runs `operation` under a deadline. `cancel` must make a suspended `operation` finish (for
/// AppAuth: cancel the flow, which fires its callback). Deadline expiry throws
/// `signInFailed("Sign-in timed out")`; cancelling the calling task throws `signInCancelled`.
func withSignInDeadline<T: Sendable>(
    timeout: Duration,
    cancel: @escaping @Sendable () async -> Void,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let timedOut = OneShotFlag()
    do {
        return try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: T?.self) { group in
                group.addTask { try await operation() }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    timedOut.set()
                    await cancel()
                    return nil
                }
                defer { group.cancelAll() }
                while let result = try await group.next() {
                    if let result { return result }
                }
                throw IntegrationError.signInCancelled
            }
        } onCancel: {
            Task { await cancel() }
        }
    } catch {
        if timedOut.isSet { throw IntegrationError.signInFailed("Sign-in timed out") }
        if error is CancellationError || Task.isCancelled { throw IntegrationError.signInCancelled }
        throw error
    }
}

private final class OneShotFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func set() { lock.withLock { value = true } }
    var isSet: Bool { lock.withLock { value } }
}

/// Opens the authorization URL in the default browser. AppAuth's own macOS agent only does this
/// through a deprecated initializer; otherwise it wants a window for ASWebAuthenticationSession.
private final class DefaultBrowserUserAgent: NSObject, OIDExternalUserAgent {
    func present(_ request: any OIDExternalUserAgentRequest, session: any OIDExternalUserAgentSession) -> Bool {
        NSWorkspace.shared.open(request.externalUserAgentRequestURL())
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void) { completion() }
}

/// Exchanges a refresh token for a new access token.
public protocol GoogleTokenEndpoint: Sendable {
    /// `invalid_grant` (the user revoked access) throws `IntegrationError.revoked`.
    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval)
}

/// `GoogleTokenEndpoint` over URLSession. Other non-2xx replies throw
/// `IntegrationError.signInFailed("token refresh failed: <status> <error>")`.
public struct URLSessionGoogleTokenEndpoint: GoogleTokenEndpoint {
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        guard let url = URL(string: AppAuthGoogleSignIn.tokenEndpoint) else {
            throw IntegrationError.signInFailed("invalid token endpoint")
        }
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "client_secret", value: config.clientSecret)
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data((form.percentEncodedQuery ?? "").utf8)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (200..<300).contains(status) else {
            let code = object?["error"] as? String ?? "unknown"
            if code == "invalid_grant" { throw IntegrationError.revoked }
            throw IntegrationError.signInFailed("token refresh failed: \(status) \(code)")
        }
        guard let access = object?["access_token"] as? String else {
            throw IntegrationError.signInFailed("token refresh failed: no access_token in reply")
        }
        let expires = (object?["expires_in"] as? NSNumber)?.doubleValue ?? 3600
        return (access, expires)
    }
}

/// Hands out fresh access tokens, refreshing near expiry and coalescing concurrent refreshes
/// per connection. Credentials persist as JSON in `SecretStoring`.
public actor GoogleTokenProvider {
    public static let clientSecretKey = "integrations.gmail.oauth-client-secret"
    private static let refreshMargin: TimeInterval = 60

    public static func key(connectionId: String) -> String {
        "integrations.gmail.\(connectionId).credential"
    }

    private let secrets: any SecretStoring
    private let endpoint: any GoogleTokenEndpoint
    private let now: @Sendable () -> Date
    private struct Refresh {
        let id: UUID
        /// The connection's generation when the refresh started; `store`/`forget` bump it.
        let generation: Int
        let task: Task<GoogleCredential, Error>
    }

    private var inFlight: [String: Refresh] = [:]
    private var generations: [String: Int] = [:]

    public init(secrets: any SecretStoring, endpoint: any GoogleTokenEndpoint,
                now: @escaping @Sendable () -> Date = Date.init) {
        self.secrets = secrets
        self.endpoint = endpoint
        self.now = now
    }

    /// Saves a credential (a fresh sign-in). Supersedes any refresh in progress for the connection:
    /// that refresh's result is discarded rather than overwriting this credential.
    public func store(_ credential: GoogleCredential, connectionId: String) throws {
        supersede(connectionId: connectionId)
        try persist(credential, connectionId: connectionId)
    }

    /// Removes the credential. A refresh in progress is superseded and its result discarded.
    public func forget(connectionId: String) {
        supersede(connectionId: connectionId)
        secrets.delete(forKey: Self.key(connectionId: connectionId))
    }

    /// A valid access token; a missing credential means the user must sign in again (`revoked`).
    public func accessToken(connectionId: String, config: GoogleOAuthClientConfig) async throws -> String {
        guard let credential = load(connectionId: connectionId) else { throw IntegrationError.revoked }
        if credential.expiresAt.timeIntervalSince(now()) >= Self.refreshMargin {
            return credential.accessToken
        }
        if let running = inFlight[connectionId] {
            return try await settle(running, connectionId: connectionId, config: config)
        }

        let endpoint = self.endpoint
        let now = self.now
        let task = Task<GoogleCredential, Error> {
            let reply = try await endpoint.refresh(refreshToken: credential.refreshToken, config: config)
            return GoogleCredential(accessToken: reply.accessToken, refreshToken: credential.refreshToken,
                                    expiresAt: now().addingTimeInterval(reply.expiresIn))
        }
        let refresh = Refresh(id: UUID(), generation: generations[connectionId, default: 0], task: task)
        inFlight[connectionId] = refresh
        return try await settle(refresh, connectionId: connectionId, config: config)
    }

    private func supersede(connectionId: String) {
        inFlight[connectionId] = nil
        generations[connectionId, default: 0] += 1
    }

    /// Awaits a refresh. A refresh superseded by a `store` or `forget` that ran meanwhile, whether
    /// it succeeded or failed, is discarded and the current credential re-read: a stale
    /// `invalid_grant` must not report `revoked` after a fresh sign-in. Otherwise the first
    /// caller to settle persists the result and every waiter gets the same outcome.
    private func settle(_ refresh: Refresh, connectionId: String,
                        config: GoogleOAuthClientConfig) async throws -> String {
        let outcome = await refresh.task.result
        guard generations[connectionId, default: 0] == refresh.generation else {
            return try await accessToken(connectionId: connectionId, config: config)
        }
        let owner = inFlight[connectionId]?.id == refresh.id
        if owner { inFlight[connectionId] = nil }
        let refreshed = try outcome.get()
        if owner { try persist(refreshed, connectionId: connectionId) }
        return refreshed.accessToken
    }

    private func persist(_ credential: GoogleCredential, connectionId: String) throws {
        guard let data = try? JSONEncoder().encode(credential),
              let text = String(data: data, encoding: .utf8),
              secrets.set(text, forKey: Self.key(connectionId: connectionId)) else {
            throw IntegrationError.signInFailed("Could not save the Google credential to the Keychain")
        }
    }

    private func load(connectionId: String) -> GoogleCredential? {
        guard let text = secrets.get(forKey: Self.key(connectionId: connectionId)) else { return nil }
        return try? JSONDecoder().decode(GoogleCredential.self, from: Data(text.utf8))
    }
}
