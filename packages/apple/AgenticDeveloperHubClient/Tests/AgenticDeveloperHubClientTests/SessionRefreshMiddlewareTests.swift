import HTTPTypes
import OpenAPIRuntime
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Only the sign-in tier: importing AgenticDeveloperHubClient too would make
// `Operations` ambiguous between the two generated clients.
@testable import AgenticDeveloperHubAuth

/// Drives `SessionRefreshMiddleware.intercept` directly with a scripted `next`
/// — no transport, no generated client. Each test is one row of the refresh
/// decision table in the middleware's doc comment.
///
/// Refreshes serialize through the process-wide `RefreshCoordinator.shared`,
/// which identifies a refresh wave by the *expired access token*. Real tokens
/// are unique, so each test that actually reaches the coordinator uses its own
/// token — two tests sharing one would look to the coordinator like two
/// requests for the same session and share a single refresh.
@Suite("SessionRefreshMiddleware")
struct SessionRefreshMiddlewareTests {

    private static let baseURL = URL(string: "https://api.example.invalid")!
    private static let refreshJSON = #"{"token":"jwt-2","refreshToken":"r-2"}"#

    private struct Call: Sendable {
        var path: String
        var authorization: String?
        var body: Data?
    }

    /// Records every call to `next`; answers with `script[callIndex]`.
    private final class Script: @unchecked Sendable {
        private let lock = NSLock()
        private var calls: [Call] = []
        private let responses: [(HTTPResponse.Status, String)]
        init(_ responses: [(HTTPResponse.Status, String)]) { self.responses = responses }
        var recorded: [Call] { lock.withLock { calls } }

        func next(_ request: HTTPRequest, _ body: HTTPBody?, _ baseURL: URL) async throws -> (HTTPResponse, HTTPBody?) {
            var data: Data?
            if let body {
                data = try await Data(collecting: body, upTo: 1 << 20)
            }
            let index = lock.withLock { () -> Int in
                calls.append(Call(path: request.path ?? "", authorization: request.headerFields[.authorization], body: data))
                return calls.count - 1
            }
            let (status, json) = responses[min(index, responses.count - 1)]
            var response = HTTPResponse(status: status)
            response.headerFields[.contentType] = "application/json"
            return (response, HTTPBody(Data(json.utf8)))
        }
    }

    private func jwtStore(token: String = "jwt-1", refresh: String? = "r-1") -> InMemorySessionStore {
        InMemorySessionStore(HubSession(credentials: Credentials(token: token, kind: .jwt), refreshToken: refresh))
    }

    private func intercept(
        _ middleware: SessionRefreshMiddleware,
        script: Script,
        operationID: String = Operations.GetAuthMe.id,
        body: Data? = nil
    ) async throws -> HTTPResponse {
        let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/auth/me")
        let (response, _) = try await middleware.intercept(
            request,
            body: body.map { HTTPBody($0) },
            baseURL: Self.baseURL,
            operationID: operationID,
            next: script.next
        )
        return response
    }

    @Test("attaches the session bearer and passes a non-401 response through")
    func attachesBearer() async throws {
        let store = jwtStore()
        let script = Script([(.ok, #"{"id":"u1"}"#)])

        let response = try await intercept(SessionRefreshMiddleware(session: store), script: script)

        #expect(response.status == .ok)
        #expect(script.recorded.count == 1)
        #expect(script.recorded[0].authorization == "Bearer jwt-1")
    }

    @Test("no session → no Authorization header, no refresh attempt on 401")
    func noSession() async throws {
        let script = Script([(.unauthorized, "{}")])

        let response = try await intercept(SessionRefreshMiddleware(session: InMemorySessionStore()), script: script)

        #expect(response.status == .unauthorized)
        #expect(script.recorded.count == 1)
        #expect(script.recorded[0].authorization == nil)
    }

    @Test("401 on a JWT session refreshes, saves the rotated session, and retries once with the new bearer")
    func refreshesAndRetries() async throws {
        let store = jwtStore(token: "jwt-retry", refresh: "r-retry")
        let script = Script([(.unauthorized, "{}"), (.ok, Self.refreshJSON), (.ok, #"{"id":"u1"}"#)])
        let requestBody = Data(#"{"name":"x"}"#.utf8)

        let response = try await intercept(
            SessionRefreshMiddleware(session: store),
            script: script,
            operationID: Operations.PatchAuthMe.id,
            body: requestBody
        )

        #expect(response.status == .ok)
        let calls = script.recorded
        #expect(calls.count == 3)
        #expect(calls[1].path == "/auth/refresh")
        #expect(calls[1].authorization == nil)
        #expect(calls[1].body == Data(#"{"refreshToken":"r-retry"}"#.utf8))
        #expect(calls[2].path == "/auth/me")
        #expect(calls[2].authorization == "Bearer jwt-2")
        #expect(calls[2].body == requestBody)
        #expect(store.currentSession() == HubSession(credentials: Credentials(token: "jwt-2", kind: .jwt), refreshToken: "r-2"))
    }

    @Test("a rejected refresh clears the session and reports expiry; the original 401 is returned")
    func rejectedRefreshClears() async throws {
        let store = jwtStore(token: "jwt-rejected", refresh: "r-rejected")
        let expired = Box(0)
        let script = Script([(.unauthorized, "{}"), (.unauthorized, #"{"error":"invalid or expired refresh token"}"#)])

        let response = try await intercept(
            SessionRefreshMiddleware(session: store, onSessionExpired: { expired.set(expired.get + 1) }),
            script: script
        )

        #expect(response.status == .unauthorized)
        #expect(script.recorded.count == 2)
        #expect(store.currentSession() == nil)
        #expect(expired.get == 1)
    }

    @Test("an unavailable refresh (5xx) keeps the session and returns the original 401")
    func unavailableRefreshKeepsSession() async throws {
        let store = jwtStore(token: "jwt-unavailable", refresh: "r-unavailable")
        let expired = Box(0)
        let script = Script([(.unauthorized, "{}"), (.serviceUnavailable, "{}")])

        let response = try await intercept(
            SessionRefreshMiddleware(session: store, onSessionExpired: { expired.set(expired.get + 1) }),
            script: script
        )

        #expect(response.status == .unauthorized)
        #expect(store.currentSession()?.credentials.token == "jwt-unavailable")
        #expect(expired.get == 0)
    }

    @Test("a transport error during refresh keeps the session and returns the original 401")
    func throwingRefreshKeepsSession() async throws {
        let store = jwtStore(token: "jwt-throwing", refresh: "r-throwing")
        let counter = Box(0)
        let middleware = SessionRefreshMiddleware(session: store)
        let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/auth/me")

        let (response, _) = try await middleware.intercept(request, body: nil, baseURL: Self.baseURL, operationID: Operations.GetAuthMe.id) { req, _, _ in
            counter.set(counter.get + 1)
            if req.path == "/auth/refresh" { throw URLError(.notConnectedToInternet) }
            return (HTTPResponse(status: .unauthorized), nil)
        }

        #expect(response.status == .unauthorized)
        #expect(counter.get == 2)
        #expect(store.currentSession()?.credentials.token == "jwt-throwing")
    }

    /// The generated `Operations.X.id` for every route that answers 401 as a
    /// normal outcome, plus the raw revoke `signOut` sends. Written as the
    /// generated constants — never as the Swift method names
    /// (`postAuthLogin`), which are *not* what the runtime hands `intercept`.
    private static let exemptOperations: [String] = [
        Operations.PostAuthLogin.id,
        Operations.PostAuthLoginMfa.id,
        Operations.PostAuthLoginMfaSmsSend.id,
        Operations.PostAuthLoginMfaWebauthn.id,
        Operations.PostAuthLoginMfaWebauthnOptions.id,
        Operations.PostAuthLoginWebauthn.id,
        Operations.PostAuthLoginWebauthnOptions.id,
        Operations.PostAuthRefresh.id,
        Operations.PostOauthSigninExchange.id,
        ADHClient.revokeRawOperationID,
    ]

    @Test("exempt operations (the login family, refresh itself, and the raw revoke) never trigger a refresh")
    func exemptOperations() async throws {
        for operationID in Self.exemptOperations {
            let store = jwtStore()
            let script = Script([(.unauthorized, "{}")])
            let response = try await intercept(SessionRefreshMiddleware(session: store), script: script, operationID: operationID)
            #expect(response.status == .unauthorized, "\(operationID)")
            #expect(script.recorded.count == 1, "\(operationID)")
            #expect(store.currentSession()?.credentials.token == "jwt-1", "\(operationID)")
        }
    }

    /// Pins the *shape* of the IDs. The behavioral test above iterates the
    /// same constants the middleware does, so it would still pass if every
    /// entry were a dead Swift-method-name literal; this one would not.
    @Test("the exemption set is exactly the generated, path-style operation IDs")
    func exemptionSetIsGeneratedIDs() {
        #expect(SessionRefreshMiddleware.exemptOperationIDs == Set(Self.exemptOperations))
        #expect(SessionRefreshMiddleware.exemptOperationIDs == [
            "post/auth/login",
            "post/auth/login/mfa",
            "post/auth/login/mfa/sms/send",
            "post/auth/login/mfa/webauthn",
            "post/auth/login/mfa/webauthn/options",
            "post/auth/login/webauthn",
            "post/auth/login/webauthn/options",
            "post/auth/refresh",
            "post/oauth/signin/exchange",
            "raw POST /auth/revoke",
        ])
        #expect(!SessionRefreshMiddleware.exemptOperationIDs.contains("postAuthLogin"))
        #expect(!SessionRefreshMiddleware.exemptOperationIDs.contains(Operations.GetAuthMe.id))
    }

    @Test("an API-token session is never refreshed")
    func apiTokenNotRefreshed() async throws {
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "adh_x", kind: .apiToken)))
        let script = Script([(.unauthorized, "{}")])

        let response = try await intercept(SessionRefreshMiddleware(session: store), script: script)

        #expect(response.status == .unauthorized)
        #expect(script.recorded.count == 1)
        #expect(store.currentSession()?.credentials.token == "adh_x")
    }

    @Test("a JWT session without a refresh token is not refreshed")
    func noRefreshTokenNotRefreshed() async throws {
        let store = jwtStore(refresh: nil)
        let script = Script([(.unauthorized, "{}")])

        let response = try await intercept(SessionRefreshMiddleware(session: store), script: script)

        #expect(response.status == .unauthorized)
        #expect(script.recorded.count == 1)
    }

    @Test("concurrent 401s share one refresh")
    func concurrentRefreshesCoalesce() async throws {
        let store = jwtStore(token: "jwt-coalesce", refresh: "r-coalesce")
        let middleware = SessionRefreshMiddleware(session: store)
        let refreshCalls = Box(0)
        let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/auth/me")

        @Sendable func next(_ req: HTTPRequest, _ body: HTTPBody?, _ url: URL) async throws -> (HTTPResponse, HTTPBody?) {
            if req.path == "/auth/refresh" {
                refreshCalls.set(refreshCalls.get + 1)
                try await Task.sleep(for: .milliseconds(50))
                var response = HTTPResponse(status: .ok)
                response.headerFields[.contentType] = "application/json"
                return (response, HTTPBody(Data(Self.refreshJSON.utf8)))
            }
            if req.headerFields[.authorization] == "Bearer jwt-coalesce" {
                return (HTTPResponse(status: .unauthorized), nil)
            }
            return (HTTPResponse(status: .ok), nil)
        }

        async let a = middleware.intercept(request, body: nil, baseURL: Self.baseURL, operationID: Operations.GetAuthMe.id, next: next)
        async let b = middleware.intercept(request, body: nil, baseURL: Self.baseURL, operationID: ADHClient.rawOperationID(method: .get, path: "/workspaces"), next: next)
        let (ra, rb) = try await (a.0, b.0)

        #expect(ra.status == .ok)
        #expect(rb.status == .ok)
        #expect(refreshCalls.get == 1)
        #expect(store.currentSession()?.credentials.token == "jwt-2")
    }

    /// The two-view-model case: two `ADHClient`s built over one `SessionStore`,
    /// each with its own `SessionRefreshMiddleware` instance. The refresh token
    /// is single-use, so a per-middleware coordinator would let both lead,
    /// have the loser's replay rejected, and clear the session the winner just
    /// saved. `next` fails the second spend exactly as the backend would.
    @Test("two clients over one store share a single refresh and neither clears the session")
    func twoClientsOverOneStoreShareOneRefresh() async throws {
        let store = jwtStore(token: "jwt-two-clients", refresh: "r-two-clients")
        let expired = Box(0)
        let refreshCalls = Box(0)
        let first = ADHClient(
            transport: .direct(transport: MockClientTransport()),
            session: store,
            onSessionExpired: { expired.set(expired.get + 1) }
        )
        let second = ADHClient(
            transport: .direct(transport: MockClientTransport()),
            session: store,
            onSessionExpired: { expired.set(expired.get + 1) }
        )
        let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/auth/me")

        @Sendable func next(_ req: HTTPRequest, _ body: HTTPBody?, _ url: URL) async throws -> (HTTPResponse, HTTPBody?) {
            if req.path == "/auth/refresh" {
                let attempt = refreshCalls.get + 1
                refreshCalls.set(attempt)
                try await Task.sleep(for: .milliseconds(50))
                guard attempt == 1 else { return (HTTPResponse(status: .unauthorized), nil) }
                var response = HTTPResponse(status: .ok)
                response.headerFields[.contentType] = "application/json"
                return (response, HTTPBody(Data(Self.refreshJSON.utf8)))
            }
            if req.headerFields[.authorization] == "Bearer jwt-two-clients" {
                return (HTTPResponse(status: .unauthorized), nil)
            }
            return (HTTPResponse(status: .ok), nil)
        }

        let firstMiddleware = try #require(first.middlewares.first)
        let secondMiddleware = try #require(second.middlewares.first)
        async let a = firstMiddleware.intercept(request, body: nil, baseURL: Self.baseURL, operationID: Operations.GetAuthMe.id, next: next)
        async let b = secondMiddleware.intercept(request, body: nil, baseURL: Self.baseURL, operationID: ADHClient.rawOperationID(method: .get, path: "/workspaces"), next: next)
        let (ra, rb) = try await (a.0, b.0)

        #expect(ra.status == .ok)
        #expect(rb.status == .ok)
        #expect(refreshCalls.get == 1)
        #expect(expired.get == 0)
        #expect(store.currentSession() == HubSession(credentials: Credentials(token: "jwt-2", kind: .jwt), refreshToken: "r-2"))
    }

    /// The other half of the shared-coordinator contract: sharing must not
    /// leak one store's rotated session into another's. Two *different* stores
    /// each get their own refresh and their own rotated pair.
    @Test("two middlewares over two different stores each get their own refresh")
    func separateStoresEachRefresh() async throws {
        let first = jwtStore(token: "jwt-separate-a", refresh: "r-separate-a")
        let second = jwtStore(token: "jwt-separate-b", refresh: "r-separate-b")
        let refreshBodies = Box<[String]>([])
        let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/auth/me")

        @Sendable func next(_ req: HTTPRequest, _ body: HTTPBody?, _ url: URL) async throws -> (HTTPResponse, HTTPBody?) {
            if req.path == "/auth/refresh" {
                let sent = String(decoding: try await Data(collecting: body ?? HTTPBody(), upTo: 1 << 20), as: UTF8.self)
                refreshBodies.set(refreshBodies.get + [sent])
                try await Task.sleep(for: .milliseconds(20))
                var response = HTTPResponse(status: .ok)
                response.headerFields[.contentType] = "application/json"
                let rotated = sent.contains("r-separate-b")
                    ? #"{"token":"jwt-separate-b2","refreshToken":"r-separate-b2"}"#
                    : #"{"token":"jwt-separate-a2","refreshToken":"r-separate-a2"}"#
                return (response, HTTPBody(Data(rotated.utf8)))
            }
            let bearer = req.headerFields[.authorization]
            if bearer == "Bearer jwt-separate-a" || bearer == "Bearer jwt-separate-b" {
                return (HTTPResponse(status: .unauthorized), nil)
            }
            return (HTTPResponse(status: .ok), nil)
        }

        let a = SessionRefreshMiddleware(session: first)
        let b = SessionRefreshMiddleware(session: second)
        async let ra = a.intercept(request, body: nil, baseURL: Self.baseURL, operationID: Operations.GetAuthMe.id, next: next)
        async let rb = b.intercept(request, body: nil, baseURL: Self.baseURL, operationID: Operations.GetAuthMe.id, next: next)
        let (responseA, responseB) = try await (ra.0, rb.0)

        #expect(responseA.status == .ok)
        #expect(responseB.status == .ok)
        #expect(refreshBodies.get.count == 2)
        #expect(first.currentSession()?.credentials.token == "jwt-separate-a2")
        #expect(second.currentSession()?.credentials.token == "jwt-separate-b2")
    }
}
