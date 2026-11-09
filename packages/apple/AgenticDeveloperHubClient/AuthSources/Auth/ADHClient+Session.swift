import HTTPTypes
import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public enum SignInOutcome: Sendable {
    case signedIn(Components.Schemas.User)
    case mfaRequired(HubMfaChallenge)
}

/// The second-factor challenge `POST /v1/auth/sessions` answers with (202) when
/// the password was right but the account needs a second factor.
///
/// Hand-written rather than generated: the /v1 document lists only the 200 for
/// that operation, so the generator emits no type for the 202 body the backend
/// really sends. Its wire shape is the /v1 one, snake_case.
public struct HubMfaChallenge: Codable, Hashable, Sendable {
    public enum Method: String, Codable, Hashable, Sendable, CaseIterable {
        case sms
        case totp
        case webauthn
        case recovery
    }

    /// Short-lived MFA pending token, sent back with the second factor.
    public var token: String
    /// The second factors the user can satisfy.
    public var methods: [Method]

    public init(token: String, methods: [Method]) {
        self.token = token
        self.methods = methods
    }

    enum CodingKeys: String, CodingKey {
        case token
        case methods
    }
}

public enum HubMfaMethod: String, Sendable, CaseIterable {
    case sms
    case totp
    case recovery

    var codePayload: Operations.PostV1AuthSessions.Input.Body.JsonPayload.Value1Payload.Case2Payload.MethodPayload {
        switch self {
        case .sms: .sms
        case .totp: .totp
        case .recovery: .recovery
        }
    }

    var sessionMethod: Operations.PostV1AuthSessions.Input.Body.JsonPayload.Value2Payload.MethodPayload {
        switch self {
        case .sms: .sms
        case .totp: .totp
        case .recovery: .recovery
        }
    }
}

public enum SessionError: Error, Sendable, Equatable {
    /// 401 from a sign-in route: wrong password, bad/expired code, rejected assertion.
    case invalidCredentials
    /// The client was built with `init(transport:credentials:)`; session wrappers need a `SessionStore`.
    case notASessionClient
    /// A documented-but-unexpected response (400/409/422/429 on a sign-in route); the payload is the backend's error message.
    case unexpectedResponse(String)
}

/// What `POST /v1/auth/passkey_challenges` returns (for `method=passkey` and
/// `method=mfa_passkey`): the challenge token to send back with the assertion
/// (for MFA the backend may rotate the pending token) and the raw WebAuthn
/// `PublicKeyCredentialRequestOptionsJSON`.
public struct PasskeyOptions: Sendable {
    public let token: String
    public let options: OpenAPIObjectContainer

    public init(token: String, options: OpenAPIObjectContainer) {
        self.token = token
        self.options = options
    }
}

/// Sign-in flows for session clients, over the /v1 API's
/// `POST /v1/auth/sessions` (one route, the `method` field picks the flow).
/// Every success path stores `Session(credentials: jwt, refreshToken:)`;
/// every 401 becomes `SessionError.invalidCredentials`; other documented
/// errors become `.unexpectedResponse` carrying the backend's message.
extension ADHClient {

    private typealias SessionBody = Operations.PostV1AuthSessions.Input.Body.JsonPayload

    private func sessionStore() throws -> any SessionStore {
        guard let session else { throw SessionError.notASessionClient }
        return session
    }

    private func adopt(_ auth: Components.Schemas.AuthResult, into store: any SessionStore) -> Components.Schemas.User {
        store.save(HubSession(
            credentials: Credentials(token: auth.token, kind: .jwt),
            refreshToken: auth.refreshToken
        ))
        return auth.user
    }

    /// The /v1 error envelope `{error: {type, code, message, param}}`: `message`
    /// is required, so it is what the user sees.
    private static func message(_ error: Components.Schemas.StripeError) -> String {
        error.error.message.isEmpty ? (error.error.code ?? "unknown error") : error.error.message
    }

    /// One `POST /v1/auth/sessions` and its outcome. A 202 is the MFA challenge
    /// (undocumented in the /v1 document, see ``HubMfaChallenge``).
    private func createSession(_ body: SessionBody, store: any SessionStore) async throws -> SignInOutcome {
        let output = try await authAPI.postV1AuthSessions(body: .json(body))
        switch output {
        case .ok(let ok):
            return .signedIn(adopt(try ok.body.json.value2, into: store))
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .conflict(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(202, let payload):
            let data: Data = if let body = payload.body {
                try await Data(collecting: body, upTo: ADHBodyLimit.maxBuffered)
            } else {
                Data()
            }
            do {
                return .mfaRequired(try JSONDecoder.adhDefault.decode(HubMfaChallenge.self, from: data))
            } catch {
                throw SessionError.unexpectedResponse("HTTP 202 without an MFA challenge")
            }
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// A step that must end signed in: a 202 here is a protocol violation.
    private func createSignedInSession(_ body: SessionBody, store: any SessionStore) async throws -> Components.Schemas.User {
        switch try await createSession(body, store: store) {
        case .signedIn(let user):
            return user
        case .mfaRequired:
            throw SessionError.unexpectedResponse("HTTP 202")
        }
    }

    /// `email` is whatever the user typed — an email, user id or phone — and
    /// goes out as `identifier`, which the backend classifies. The `email` key
    /// would pin the lookup to email only.
    public func signIn(email: String, password: String) async throws -> SignInOutcome {
        let store = try sessionStore()
        return try await createSession(
            .init(value1: .case1(.init(identifier: email, password: password)), value2: .init(method: .password)),
            store: store
        )
    }

    public func completeMfa(challengeToken: String, method: HubMfaMethod, code: String) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        return try await createSignedInSession(
            .init(
                value1: .case2(.init(token: challengeToken, method: method.codePayload, code: code)),
                value2: .init(method: method.sessionMethod)
            ),
            store: store
        )
    }

    public func sendMfaSms(challengeToken: String) async throws {
        _ = try sessionStore()
        let output = try await authAPI.postV1AuthSmsCodes(body: .json(.init(token: challengeToken)))
        switch output {
        case .accepted:
            return
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .conflict(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .unprocessableContent(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .tooManyRequests(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    private typealias ChallengeBody = Operations.PostV1AuthPasskeyChallenges.Input.Body.JsonPayload

    private func passkeyChallenge(_ body: ChallengeBody) async throws -> PasskeyOptions {
        _ = try sessionStore()
        let output = try await authAPI.postV1AuthPasskeyChallenges(body: .json(body))
        switch output {
        case .ok(let ok):
            let payload = try ok.body.json
            return PasskeyOptions(token: payload.token, options: payload.options.additionalProperties)
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .unprocessableContent(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }

    /// Starts a passkey sign-in: the challenge token to send to `completePasskey`
    /// plus the WebAuthn `PublicKeyCredentialRequestOptions` the platform
    /// authenticator (`ASAuthorizationPlatformPublicKeyCredentialProvider`)
    /// consumes; the options are returned raw because their shape is the
    /// WebAuthn standard's, not the hub's.
    public func passkeyOptions(identifier: String) async throws -> PasskeyOptions {
        try await passkeyChallenge(.init(value1: .case2(.init(identifier: identifier)), value2: .init(method: .passkey)))
    }

    /// `response` is the serialized `PublicKeyCredential` assertion
    /// (`id`, `rawId`, `type`, `response.{clientDataJSON,authenticatorData,signature,userHandle}` base64url).
    public func completePasskey(challengeToken: String, response: OpenAPIObjectContainer) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        return try await createSignedInSession(
            .init(
                value1: .case3(.init(token: challengeToken, response: .init(additionalProperties: response))),
                value2: .init(method: .passkey)
            ),
            store: store
        )
    }

    /// MFA step for the `webauthn` method: fetches the assertion options for
    /// the pending challenge. Send `result.token` (not the original challenge
    /// token) to `completeMfaPasskey`.
    public func mfaPasskeyOptions(challengeToken: String) async throws -> PasskeyOptions {
        try await passkeyChallenge(.init(value1: .case1(.init(token: challengeToken)), value2: .init(method: .mfaPasskey)))
    }

    /// Completes MFA with a platform-authenticator assertion (same `response`
    /// shape as `completePasskey`).
    public func completeMfaPasskey(challengeToken: String, response: OpenAPIObjectContainer) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        return try await createSignedInSession(
            .init(
                value1: .case3(.init(token: challengeToken, response: .init(additionalProperties: response))),
                value2: .init(method: .mfaPasskey)
            ),
            store: store
        )
    }

    /// `POST /oauth/signin/exchange` — named here so the raw path below and
    /// the refresh middleware's exemption describe the same request.
    static let oauthExchangeMethod: HTTPRequest.Method = .post
    static let oauthExchangePath = "/oauth/signin/exchange"
    static let oauthExchangeRawOperationID = rawOperationID(method: oauthExchangeMethod, path: oauthExchangePath)

    /// The exchange's answer. `/oauth/signin/*` is served unversioned (the
    /// sign-in cookie is scoped to that path) and is not in the /v1 document,
    /// so its body keeps the legacy camelCase shape and is decoded here, then
    /// lifted into the generated /v1 types the rest of the session layer uses.
    private struct ExchangeResult: Decodable {
        struct User: Decodable {
            let id: String
            let email: String
            let name: String
            let avatarUrl: String
            let slug: String?
            let publicProfileEnabled: Bool
            let profileVisibility: Components.Schemas.User.ProfileVisibilityPayload
            let capabilities: [String]
        }

        let token: String
        let refreshToken: String
        let user: User

        var authResult: Components.Schemas.AuthResult {
            .init(
                token: token,
                refreshToken: refreshToken,
                user: .init(
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    avatarUrl: user.avatarUrl,
                    slug: user.slug,
                    publicProfileEnabled: user.publicProfileEnabled,
                    profileVisibility: user.profileVisibility,
                    capabilities: user.capabilities
                )
            )
        }
    }

    /// Redeems a browser sign-in's exchange code for a session.
    ///
    /// `userAgent` is what makes this usable from a native app. The backend's
    /// exchange store binds each code to the `User-Agent` of the client that
    /// received it (`entry.userAgent !== userAgent` → the code is consumed and
    /// refused), and the client that received it is the *browser*, not this
    /// process. A web caller redeems from that same browser and wants `nil`; a
    /// native caller captures the browser's header — the loopback sign-in flow
    /// reads it off the capture page's own request — and passes it here.
    /// Without it every native redemption 401s with a code already burned, so
    /// the retry cannot help either.
    ///
    /// The route is not in the /v1 document (see ``ExchangeResult``), so it
    /// always goes through ``rawJSON(method:path:query:body:headers:)``.
    public func exchangeOAuthCode(_ code: String, userAgent: String? = nil) async throws -> Components.Schemas.User {
        let store = try sessionStore()
        do {
            let response = try await rawJSON(
                method: Self.oauthExchangeMethod,
                path: Self.oauthExchangePath,
                body: try JSONEncoder().encode(["code": code]),
                headers: userAgent.map { ["User-Agent": $0] } ?? [:]
            )
            return adopt(try response.decode(ExchangeResult.self).authResult, into: store)
        } catch let error as RawRequestError {
            throw Self.sessionError(for: error)
        }
    }

    /// The `RawRequestError` → ``SessionError`` mapping the raw exchange needs,
    /// kept identical to the typed paths': 401 is a rejected code, anything
    /// else carries the backend's own message. The unversioned route answers
    /// errors in the legacy `{error: {message}}` or flat `{error: "…"}` shape.
    private static func sessionError(for error: RawRequestError) -> SessionError {
        switch error {
        case .invalidPath(let path):
            return .unexpectedResponse("invalid path \(path)")
        case .http(401, _):
            return .invalidCredentials
        case .http(let status, let body):
            return .unexpectedResponse(errorMessage(in: body) ?? "HTTP \(status)")
        }
    }

    private static func errorMessage(in body: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return nil }
        if let nested = object["error"] as? [String: Any] {
            return (nested["message"] as? String) ?? (nested["code"] as? String)
        }
        return (object["error"] as? String) ?? (object["message"] as? String)
    }

    /// Revokes the refresh token (best effort — a dead backend must not keep
    /// the user signed in locally) and clears the store.
    ///
    /// The revoke goes through ``rawJSON(method:path:query:body:)`` rather
    /// than the generated `postV1AuthSessionsRevoke`: the backend requires a
    /// `{"refreshToken": …}` body, but the /v1 document describes
    /// `POST /v1/auth/sessions/revoke` as bodiless, so the generated
    /// operation cannot express the real request. (The gateway passes the
    /// undeclared key through to the route unrenamed.) It is exempt from
    /// refresh-and-retry (``SessionRefreshMiddleware/exemptOperationIDs``
    /// derives that exemption from ``ADHClient/revokeRawOperationID``):
    /// signing out with an already-expired access token 401s, and rotating
    /// the refresh token mid-revoke would leave the body carrying a consumed
    /// token the server can no longer match — a silent failure to revoke.
    public func signOut() async {
        guard let session else { return }
        if let refreshToken = session.currentSession()?.refreshToken,
           let body = try? JSONEncoder().encode(["refreshToken": refreshToken]) {
            _ = try? await rawJSON(method: Self.revokeMethod, path: Self.revokePath, body: body)
        }
        session.clear()
    }

    public func currentUser() async throws -> Components.Schemas.User {
        let output = try await authAPI.getV1Account()
        switch output {
        case .ok(let ok):
            return try ok.body.json.value1.value2
        case .unauthorized:
            throw SessionError.invalidCredentials
        case .badRequest(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .notFound(let r):
            throw SessionError.unexpectedResponse(Self.message(try r.body.json))
        case .undocumented(let status, _):
            throw SessionError.unexpectedResponse("HTTP \(status)")
        }
    }
}
