import HTTPTypes
import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Result of one refresh attempt. Only `.rejected` ends the session —
/// `.unavailable` (5xx, transport error) is the backend being unreachable,
/// which must never sign the user out.
public enum SessionRefreshOutcome: Sendable, Equatable {
    case refreshed(HubSession)
    case rejected
    case unavailable
}

/// Attaches the session's bearer to every request and, when a JWT session
/// gets a 401, rotates it through `POST /v1/auth/sessions/refresh` and retries the
/// original request once. Replaces `AuthenticationMiddleware` for callers
/// that hold a `SessionStore`.
///
/// Decision table:
/// - no session → forward unchanged;
/// - non-401 → returned as-is;
/// - 401 on an exempt operation (the sign-in family, refresh itself, and the
///   raw exchange and revoke), an API-token session, or a session with no
///   refresh token → returned as-is;
/// - 401 otherwise → refresh; `.refreshed` retries once with the new bearer,
///   `.rejected` clears the store and calls `onSessionExpired`, `.unavailable`
///   keeps the store; the last two return the original 401.
///
/// Refreshes are serialized process-wide by `RefreshCoordinator.shared`, not
/// per middleware: the single-use refresh token lives in the `SessionStore`,
/// which several `ADHClient`s routinely share, so a per-instance coordinator
/// would let two clients over one store both lead a refresh and have the
/// loser's replay rejected — clearing the session the winner just saved. A
/// request that lost the race finds the store already rotated and simply
/// retries.
public struct SessionRefreshMiddleware: ClientMiddleware {

    /// Operations that answer 401 as a normal outcome (wrong password, bad
    /// code, rejected assertion, already-revoked token) — never a reason to
    /// rotate the session.
    ///
    /// Every entry is the generated `Operations.X.id`, never a hand-written
    /// literal: the runtime hands `intercept` exactly that string, and the
    /// generator emits it as the /v1 `operationId` (`"postV1AuthSessions"`), so literals
    /// silently rot into dead entries. Deriving them from the generated
    /// constants makes a drift impossible — a renamed or removed operation
    /// fails to compile.
    ///
    /// `signOut`'s revoke and the OAuth exchange ride
    /// ``ADHClient/rawJSON(method:path:query:body:headers:)`` rather than a
    /// generated operation (see their call sites), so their exemptions are
    /// derived from the same helper that builds their `operationID`.
    public static let exemptOperationIDs: Set<String> = [
        Operations.PostV1AuthSessions.id,
        Operations.PostV1AuthSmsCodes.id,
        Operations.PostV1AuthPasskeyChallenges.id,
        Operations.PostV1AuthSessionsRefresh.id,
        ADHClient.oauthExchangeRawOperationID,
        ADHClient.revokeRawOperationID,
    ]

    private let session: any SessionStore
    private let onSessionExpired: @Sendable () -> Void

    public init(session: any SessionStore, onSessionExpired: @escaping @Sendable () -> Void = {}) {
        self.session = session
        self.onSessionExpired = onSessionExpired
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let current = session.currentSession()
        let bufferedBody: Data? = if let body {
            try await Data(collecting: body, upTo: ADHBodyLimit.maxBuffered)
        } else {
            nil
        }

        var first = request
        if let token = current?.credentials.token {
            first.headerFields[.authorization] = "Bearer \(token)"
        }
        let (response, responseBody) = try await next(first, bufferedBody.map { HTTPBody($0) }, baseURL)

        guard response.status == .unauthorized,
              !Self.exemptOperationIDs.contains(operationID),
              let current,
              current.credentials.kind == .jwt,
              let refreshToken = current.refreshToken
        else {
            return (response, responseBody)
        }

        let outcome = await RefreshCoordinator.shared.refresh(
            previousToken: current.credentials.token,
            currentSession: { session.currentSession() },
            perform: { await Self.performRefresh(refreshToken: refreshToken, baseURL: baseURL, next: next) },
            save: { session.save($0) }
        )

        switch outcome {
        case .refreshed(let rotated):
            var retry = request
            retry.headerFields[.authorization] = "Bearer \(rotated.credentials.token)"
            return try await next(retry, bufferedBody.map { HTTPBody($0) }, baseURL)
        case .rejected:
            session.clear()
            onSessionExpired()
            return (response, responseBody)
        case .unavailable:
            return (response, responseBody)
        }
    }

    private struct RefreshRequestBody: Encodable {
        let refreshToken: String
    }

    /// `POST /v1/auth/sessions/refresh`. Its request body is undeclared in the
    /// /v1 document, so the gateway hands the `refreshToken` key to the route
    /// unrenamed; the answer is the /v1 `RefreshResult`, snake_case.
    static let refreshPath = "/v1/auth/sessions/refresh"

    /// One `POST /v1/auth/sessions/refresh` round-trip through `next` (so it
    /// rides the same transport the failing request used — daemon or direct).
    /// It is sent by hand, not through the generated operation, because the
    /// middleware sits below the generated client and only has `next`.
    static func performRefresh(
        refreshToken: String,
        baseURL: URL,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async -> SessionRefreshOutcome {
        var request = HTTPRequest(method: .post, scheme: nil, authority: nil, path: refreshPath)
        request.headerFields[.contentType] = "application/json"
        request.headerFields[.accept] = "application/json"
        let body: Data
        do {
            body = try JSONEncoder().encode(RefreshRequestBody(refreshToken: refreshToken))
        } catch {
            return .unavailable
        }
        do {
            let (response, responseBody) = try await next(request, HTTPBody(body), baseURL)
            switch response.status.code {
            case 200:
                let data = try await Data(collecting: responseBody ?? HTTPBody(), upTo: ADHBodyLimit.maxBuffered)
                let decoded = try JSONDecoder().decode(Components.Schemas.RefreshResult.self, from: data)
                return .refreshed(HubSession(
                    credentials: Credentials(token: decoded.token, kind: .jwt),
                    refreshToken: decoded.refreshToken
                ))
            case 401, 403:
                return .rejected
            default:
                return .unavailable
            }
        } catch {
            return .unavailable
        }
    }
}

/// Serializes refreshes across every `SessionRefreshMiddleware` in the
/// process. The first caller for a given expired token — the leader — runs
/// `perform` directly, within this actor's own isolation; later callers that
/// arrive while it is in flight — followers — queue on a continuation. A
/// follower whose `previousToken` matches the leader's is refreshing the same
/// session, so it receives the leader's outcome instead of spending the
/// (single-use) refresh token a second time. A follower holding a *different*
/// token belongs to another session (another `SessionStore`, or one already
/// rotated) and must not inherit the leader's outcome: it is resumed with
/// `nil` and re-evaluates from the top, either finding its own store already
/// rotated or leading its own refresh. A caller that arrives *after* a refresh
/// has completed, holding a token the store no longer has, is handed
/// `.refreshed` with the store's current session directly.
///
/// `perform`, `currentSession`, and `save` are deliberately non-escaping:
/// `perform` closes over the middleware's `next`, which
/// `ClientMiddleware.intercept` hands out non-escaping, so the leader must
/// call it in place (`await perform()`) rather than handing it to a
/// `Task { ... }`, which would require it to escape. Running the leader's
/// work as a plain `await` inside this actor method still gives one
/// refresh per wave: Swift only interleaves other calls to this actor at
/// the leader's suspension points, and by its first `await` the leader has
/// already recorded `leaderToken`, so every follower that reaches this
/// method afterward sees it and queues instead of racing to lead.
///
/// The leader saves the rotated session itself (via `save`) *before*
/// resuming any follower's continuation, so a follower released from
/// `await` here always finds the store already rotated.
actor RefreshCoordinator {

    /// The one coordinator every middleware serializes through. Refreshes are
    /// rare and short, and the "already rotated, just retry" early return
    /// means an unrelated store waits at most one refresh round-trip.
    static let shared = RefreshCoordinator()

    private struct Waiter {
        let token: String
        let continuation: CheckedContinuation<SessionRefreshOutcome?, Never>
    }

    /// The access token the in-flight refresh is replacing, or `nil` when idle.
    private var leaderToken: String?
    private var waiters: [Waiter] = []

    func refresh(
        previousToken: String,
        currentSession: @Sendable () -> HubSession?,
        perform: @Sendable () async -> SessionRefreshOutcome,
        save: @Sendable (HubSession) -> Void
    ) async -> SessionRefreshOutcome {
        while leaderToken != nil {
            let shared: SessionRefreshOutcome? = await withCheckedContinuation { continuation in
                waiters.append(Waiter(token: previousToken, continuation: continuation))
            }
            if let shared { return shared }
        }
        if let current = currentSession(), current.credentials.token != previousToken {
            return .refreshed(current)
        }
        leaderToken = previousToken
        let outcome = await perform()
        if case .refreshed(let rotated) = outcome {
            save(rotated)
        }
        leaderToken = nil
        let pending = waiters
        waiters = []
        for waiter in pending {
            waiter.continuation.resume(returning: waiter.token == previousToken ? outcome : nil)
        }
        return outcome
    }
}
