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
        let session = SessionBox()
        return try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: GoogleCredential.self) { group in
                group.addTask { try await Self.run(config: config, box: session) }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw IntegrationError.signInCancelled
                }
                defer { group.cancelAll() }
                guard let first = try await group.next() else { throw IntegrationError.signInCancelled }
                return first
            }
        } onCancel: {
            Task { @MainActor in session.cancel() }
        }
    }

    @MainActor
    private final class SessionBox: @unchecked Sendable {
        nonisolated init() {}
        var flow: (any OIDExternalUserAgentSession)?
        var handler: OIDRedirectHTTPHandler?
        func cancel() {
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
        var listenerError: NSError?
        let listenerURL: URL? = handler.startHTTPListener(&listenerError)
        guard let redirect = listenerURL else {
            throw IntegrationError.signInFailed(
                "could not start the local redirect listener: \(listenerError?.localizedDescription ?? "unknown")")
        }
        defer { handler.cancelHTTPListener() }

        let request = OIDAuthorizationRequest(
            configuration: OIDServiceConfiguration(authorizationEndpoint: authURL, tokenEndpoint: tokenURL),
            clientId: config.clientId, clientSecret: config.clientSecret, scopes: scopes,
            redirectURL: redirect, responseType: OIDResponseTypeCode,
            additionalParameters: ["access_type": "offline", "prompt": "consent"])

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
    private var inFlight: [String: Task<GoogleCredential, Error>] = [:]

    public init(secrets: any SecretStoring, endpoint: any GoogleTokenEndpoint,
                now: @escaping @Sendable () -> Date = Date.init) {
        self.secrets = secrets
        self.endpoint = endpoint
        self.now = now
    }

    public func store(_ credential: GoogleCredential, connectionId: String) {
        guard let data = try? JSONEncoder().encode(credential),
              let text = String(data: data, encoding: .utf8) else { return }
        secrets.set(text, forKey: Self.key(connectionId: connectionId))
    }

    public func forget(connectionId: String) {
        secrets.delete(forKey: Self.key(connectionId: connectionId))
    }

    /// A valid access token; a missing credential means the user must sign in again (`revoked`).
    public func accessToken(connectionId: String, config: GoogleOAuthClientConfig) async throws -> String {
        guard let credential = load(connectionId: connectionId) else { throw IntegrationError.revoked }
        if credential.expiresAt.timeIntervalSince(now()) >= Self.refreshMargin {
            return credential.accessToken
        }
        if let running = inFlight[connectionId] { return try await running.value.accessToken }

        let endpoint = self.endpoint
        let now = self.now
        let task = Task<GoogleCredential, Error> {
            let reply = try await endpoint.refresh(refreshToken: credential.refreshToken, config: config)
            return GoogleCredential(accessToken: reply.accessToken, refreshToken: credential.refreshToken,
                                    expiresAt: now().addingTimeInterval(reply.expiresIn))
        }
        inFlight[connectionId] = task
        defer { inFlight[connectionId] = nil }
        let refreshed = try await task.value
        store(refreshed, connectionId: connectionId)
        return refreshed.accessToken
    }

    private func load(connectionId: String) -> GoogleCredential? {
        guard let text = secrets.get(forKey: Self.key(connectionId: connectionId)) else { return nil }
        return try? JSONDecoder().decode(GoogleCredential.self, from: Data(text.utf8))
    }
}
