import AIPluginKit
import AppKit
import Foundation
import os
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
    private let successURL: URL?
    private let now: @Sendable () -> Date

    /// - Parameter successURL: where the browser is sent once Google redirects back with the
    ///   code — typically the host app's own URL scheme, so the browser hands the person back to
    ///   the app. Without one, the browser shows a plain "Return to the app" page.
    public init(timeout: Duration = .seconds(300), successURL: URL? = nil,
                now: @escaping @Sendable () -> Date = Date.init) {
        self.timeout = timeout
        self.successURL = successURL
        self.now = now
    }

    public func signIn(config: GoogleOAuthClientConfig) async throws -> GoogleCredential {
        let box = SessionBox()
        let now = self.now
        let successURL = self.successURL
        return try await withSignInDeadline(
            timeout: timeout,
            cancel: { await box.cancel() },
            operation: { try await Self.run(config: config, successURL: successURL, box: box, now: now) })
    }

    /// The credential a finished sign-in yields. Google normally reports the access token's
    /// expiry; without one it is taken as an hour from `now`.
    static func credential(
        accessToken: String?, refreshToken: String?, expiresAt: Date?, now: Date
    ) throws -> GoogleCredential {
        guard let accessToken, !accessToken.isEmpty else {
            throw IntegrationError.signInFailed("Google returned no access token")
        }
        guard let refreshToken, !refreshToken.isEmpty else {
            throw IntegrationError.signInFailed("Google returned no refresh token")
        }
        return GoogleCredential(accessToken: accessToken, refreshToken: refreshToken,
                                expiresAt: expiresAt ?? now.addingTimeInterval(3600))
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
    private static func run(
        config: GoogleOAuthClientConfig, successURL: URL?, box: SessionBox, now: @Sendable () -> Date
    ) async throws -> GoogleCredential {
        guard let authURL = URL(string: authorizationEndpoint), let tokenURL = URL(string: tokenEndpoint) else {
            throw IntegrationError.signInFailed("invalid Google endpoints")
        }
        let handler = OIDRedirectHTTPHandler(successURL: successURL)
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
        }
        let tokens = state.lastTokenResponse
        return try credential(accessToken: tokens?.accessToken, refreshToken: tokens?.refreshToken,
                              expiresAt: tokens?.accessTokenExpirationDate, now: now())
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
/// Either returns promptly even if `operation` ignores cancellation: the work, the timer and the
/// caller's cancellation race to settle one result, and the first wins.
func withSignInDeadline<T: Sendable>(
    timeout: Duration,
    cancel: @escaping @Sendable () async -> Void,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let box = RaceBox<T>()
    let work = Task {
        do {
            box.finish(.success(try await operation()))
        } catch is CancellationError {
            box.finish(.failure(IntegrationError.signInCancelled))
        } catch {
            box.finish(.failure(error))
        }
    }
    let timer = Task {
        try await Task.sleep(for: timeout)
        if box.finish(.failure(IntegrationError.signInFailed("Sign-in timed out"))) {
            await cancel()
            work.cancel()
        }
    }
    defer {
        timer.cancel()
        work.cancel()
    }
    return try await withTaskCancellationHandler {
        try await box.value()
    } onCancel: {
        if box.finish(.failure(IntegrationError.signInCancelled)) {
            Task { await cancel() }
        }
        work.cancel()
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

/// Exchanges a refresh token for a new access token, and revokes one.
public protocol GoogleTokenEndpoint: Sendable {
    /// `invalid_grant` (the user revoked access) throws `IntegrationError.revoked`.
    func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval)

    /// Revokes `token` (and, for a refresh token, the grant behind it) at Google.
    func revoke(token: String) async throws
}

/// `GoogleTokenEndpoint` over URLSession. Other non-2xx replies throw
/// `IntegrationError.tokenRefresh("<status> <error>")`.
public struct URLSessionGoogleTokenEndpoint: GoogleTokenEndpoint {
    static let revokeEndpoint = "https://oauth2.googleapis.com/revoke"

    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func refresh(refreshToken: String, config: GoogleOAuthClientConfig) async throws
        -> (accessToken: String, expiresIn: TimeInterval) {
        let (status, object) = try await post(to: AppAuthGoogleSignIn.tokenEndpoint, form: [
            ("grant_type", "refresh_token"),
            ("refresh_token", refreshToken),
            ("client_id", config.clientId),
            ("client_secret", config.clientSecret)
        ])
        guard (200..<300).contains(status) else {
            let code = object?["error"] as? String ?? "unknown"
            if code == "invalid_grant" { throw IntegrationError.revoked }
            throw IntegrationError.tokenRefresh("\(status) \(code)")
        }
        guard let access = object?["access_token"] as? String else {
            throw IntegrationError.tokenRefresh("no access_token in reply")
        }
        let expires = (object?["expires_in"] as? NSNumber)?.doubleValue ?? 3600
        return (access, expires)
    }

    public func revoke(token: String) async throws {
        let (status, object) = try await post(to: Self.revokeEndpoint, form: [("token", token)])
        guard (200..<300).contains(status) else {
            let code = object?["error"] as? String ?? "unknown"
            throw IntegrationError.tokenRefresh("revoke failed: \(status) \(code)")
        }
    }

    private func post(to endpoint: String, form: [(String, String)]) async throws -> (Int, [String: Any]?) {
        guard let url = URL(string: endpoint) else {
            throw IntegrationError.tokenRefresh("invalid endpoint \(endpoint)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(Self.formEncode(form).utf8)
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (status, (try? JSONSerialization.jsonObject(with: data)) as? [String: Any])
    }

    /// `application/x-www-form-urlencoded`, escaping everything but RFC 3986 unreserved
    /// characters. `URLComponents` leaves `+`, `/` and `=` alone, and a server decodes a raw
    /// `+` as a space, which corrupts tokens and secrets that contain one.
    static func formEncode(_ pairs: [(String, String)]) -> String {
        var unreserved = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        unreserved.insert(charactersIn: "-._~")
        func escape(_ text: String) -> String {
            text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? text
        }
        return pairs.map { "\(escape($0.0))=\(escape($0.1))" }.joined(separator: "&")
    }
}

/// Hands out fresh access tokens, refreshing near expiry and coalescing concurrent refreshes
/// per connection. Credentials persist as JSON in `SecretStoring`.
public actor GoogleTokenProvider {
    public static let clientSecretKey = "integrations.gmail.oauth-client-secret"
    private static let refreshMargin: TimeInterval = 60
    private static let logger = Logger(subsystem: "com.agenticdeveloperhub.integrations", category: "GoogleTokens")

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
    /// Refreshed credentials the Keychain refused to save. They are still valid, so later calls
    /// use them rather than re-refreshing (and hammering Google) on every request; a later
    /// successful save, a new sign-in or `forget` clears them.
    private var unsaved: [String: GoogleCredential] = [:]

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
    /// Throws `keychain` if the Keychain would not remove it, so the caller does not report an
    /// account as removed while its refresh token is still stored.
    public func forget(connectionId: String) throws {
        supersede(connectionId: connectionId)
        guard secrets.delete(forKey: Self.key(connectionId: connectionId)) else {
            throw IntegrationError.keychain("Could not remove the Google credential")
        }
    }

    /// Best effort: asks Google to revoke the connection's refresh token, so removing an account
    /// also ends the grant. A missing credential or a failed request is logged and ignored;
    /// the local removal goes ahead regardless.
    public func revoke(connectionId: String) async {
        let credential: GoogleCredential?
        do {
            credential = try load(connectionId: connectionId)
        } catch {
            Self.logger.error("Not revoking \(connectionId, privacy: .public): \(error.localizedDescription)")
            return
        }
        guard let credential else { return }
        do {
            try await endpoint.revoke(token: credential.refreshToken)
        } catch {
            Self.logger.error(
                "Revoking \(connectionId, privacy: .public) at Google failed: \(error.localizedDescription)")
        }
    }

    /// A valid access token; a missing credential means the user must sign in again (`revoked`).
    /// A Keychain that cannot be read throws `keychain`, which is not a revocation.
    public func accessToken(connectionId: String, config: GoogleOAuthClientConfig) async throws -> String {
        guard let credential = try load(connectionId: connectionId) else { throw IntegrationError.revoked }
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
        unsaved[connectionId] = nil
        generations[connectionId, default: 0] += 1
    }

    /// Awaits a refresh. A refresh superseded by a `store` or `forget` that ran meanwhile, whether
    /// it succeeded or failed, is discarded and the current credential re-read: a stale
    /// `invalid_grant` must not report `revoked` after a fresh sign-in. Otherwise the first
    /// caller to settle persists the result and every waiter gets the same outcome. A failed
    /// refresh is dropped from `inFlight` so the next call tries again rather than reusing it.
    private func settle(_ refresh: Refresh, connectionId: String,
                        config: GoogleOAuthClientConfig) async throws -> String {
        let outcome = await refresh.task.result
        guard generations[connectionId, default: 0] == refresh.generation else {
            return try await accessToken(connectionId: connectionId, config: config)
        }
        let owner = inFlight[connectionId]?.id == refresh.id
        if owner { inFlight[connectionId] = nil }
        let refreshed = try outcome.get()
        if owner {
            do {
                try persist(refreshed, connectionId: connectionId)
            } catch {
                unsaved[connectionId] = refreshed
                throw error
            }
        }
        return refreshed.accessToken
    }

    private func persist(_ credential: GoogleCredential, connectionId: String) throws {
        guard let data = try? JSONEncoder().encode(credential),
              let text = String(data: data, encoding: .utf8),
              secrets.set(text, forKey: Self.key(connectionId: connectionId)) else {
            throw IntegrationError.signInFailed("Could not save the Google credential to the Keychain")
        }
        unsaved[connectionId] = nil
    }

    /// The stored credential. Absent, or stored but unreadable as a credential, is nil (sign in
    /// again); a Keychain that could not be read throws.
    private func load(connectionId: String) throws -> GoogleCredential? {
        if let pending = unsaved[connectionId] { return pending }
        let text: String?
        do {
            text = try secrets.read(forKey: Self.key(connectionId: connectionId))
        } catch {
            throw IntegrationError.keychain("Could not read the Google credential: \(error.localizedDescription)")
        }
        guard let text else { return nil }
        return try? JSONDecoder().decode(GoogleCredential.self, from: Data(text.utf8))
    }
}
