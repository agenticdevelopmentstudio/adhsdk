import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Thin convenience wrappers over the generated auth operations. They are just
/// ergonomics — the same calls are available on ``ADHClient/authAPI`` directly — but
/// they save callers from spelling out the long generated request/response type
/// names and wire the result into the credential store.
extension ADHClient {

    /// The backend's auth payload returned by ``login(email:password:)``
    /// (`token`, `refresh_token` and `user` on the /v1 wire).
    public typealias AuthResponse = Components.Schemas.AuthResult

    /// A freshly minted API token returned by ``createAPIToken(name:expiresAt:)``.
    /// The spec models it as an `allOf` of the stored token metadata (`value1`)
    /// and the one-time secret, so the raw token is at `value2.token` — the only
    /// time it is ever exposed.
    public typealias CreatedAPIToken = Components.Schemas.ApiTokenCreated

    /// Email / password login (`POST /v1/auth/sessions`, `method=password`).
    /// On success the returned JWT is persisted through the credential store,
    /// so every subsequent call on this client is authenticated. An account
    /// that needs a second factor answers 202, which this bearer-only path
    /// cannot complete and surfaces as `ClientError`; native apps use
    /// ``signIn(email:password:)`` on a session client instead.
    @discardableResult
    public func login(email: String, password: String) async throws -> AuthResponse {
        let output = try await authAPI.postV1AuthSessions(body: .json(.init(
            value1: .case1(.init(email: email, password: password)),
            value2: .init(method: .password)
        )))
        let auth = try output.ok.body.json.value2
        credentials.save(Credentials(token: auth.token, kind: .jwt))
        return auth
    }

    /// Create a long-lived API token (`POST /v1/api_keys`). Requires the
    /// client to already be authenticated (the middleware forwards the current
    /// credential).
    ///
    /// The raw token (`value2.token` on the result) is returned for the caller to
    /// store wherever it belongs (e.g. handed to the daemon or a CI secret). It is
    /// deliberately **not** persisted here — minting a token must not silently
    /// replace the active session credential. Call ``adopt(_:)`` to switch this
    /// client to it.
    @discardableResult
    public func createAPIToken(name: String, expiresAt: Date? = nil) async throws -> CreatedAPIToken {
        let output = try await authAPI.postV1ApiKeys(body: .json(.case1(.init(name: name, expiresAt: expiresAt))))
        return try output.created.body.json.value2
    }

    /// Persist a credential through the store, switching this client to it.
    public func adopt(_ credentials: Credentials) {
        self.credentials.save(credentials)
    }

    /// Forget the persisted credential (sign out). Subsequent calls are
    /// unauthenticated until the next ``login(email:password:)``.
    public func logout() {
        credentials.clear()
    }
}
