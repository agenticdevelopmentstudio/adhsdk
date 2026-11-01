import HTTPTypes
import OpenAPIRuntime
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// Hermetic tests for the `ADHClient` façade: the generated typed client routes
/// through the chosen ``APITransport``, the ``AuthenticationMiddleware`` injects
/// the bearer, and a typed operation round-trips. No network — a
/// ``MockClientTransport`` stands in for the wire.
@Suite("ADHClient wiring")
struct ADHClientWiringTests {

    private func client(
        kind: TransportKind = .direct,
        serverURL: URL = DaemonContract.backendURL,
        token: String? = "tok-abc",
        transport: MockClientTransport
    ) -> ADHClient {
        let creds = InMemoryCredentialStore(token.map { Credentials(token: $0, kind: .jwt) })
        return ADHClient(
            transport: APITransport(kind: kind, serverURL: serverURL, transport: transport),
            credentials: creds
        )
    }

    @Test("direct factory targets the backend over HTTPS")
    func directFactoryTargetsBackend() {
        let t = APITransport.direct()
        #expect(t.kind == .direct)
        #expect(t.serverURL == DaemonContract.backendURL)
    }

    @Test("daemon factory targets loopback on the contract port")
    func daemonFactoryTargetsLoopback() {
        let t = APITransport.daemon()
        #expect(t.kind == .daemon)
        #expect(t.serverURL == DaemonContract.daemonURL())
        #expect(t.serverURL.absoluteString == "http://127.0.0.1:\(DaemonContract.port)")
    }

    @Test("a typed operation routes through the transport and decodes")
    func typedOperationRoundTrips() async throws {
        let mock = MockClientTransport()
        let adh = client(transport: mock)

        let output = try await adh.api.getHealth()

        // Decoded the 200 (the spec documents no response body for /health).
        _ = try output.ok

        // The generated client produced the right request and handed it to our transport.
        let recorded = try #require(mock.recorded.last)
        #expect(recorded.request.method == .get)
        #expect(recorded.request.path == "/health")
        #expect(recorded.operationID == "get/health")
        #expect(recorded.baseURL == DaemonContract.backendURL)
    }

    @Test("auth middleware injects the bearer on outgoing requests")
    func authHeaderInjected() async throws {
        let mock = MockClientTransport()
        let adh = client(token: "tok-abc", transport: mock)

        _ = try await adh.api.getHealth()

        let request = try #require(mock.lastRequest)
        #expect(request.headerFields[.authorization] == "Bearer tok-abc")
    }

    @Test("no Authorization header when there is no credential")
    func noAuthHeaderWhenUnauthenticated() async throws {
        let mock = MockClientTransport()
        let adh = client(token: nil, transport: mock)

        _ = try await adh.api.getHealth()

        let request = try #require(mock.lastRequest)
        #expect(request.headerFields[.authorization] == nil)
    }

    @Test("Direct and Daemon differ only by base URL — same auth, same request")
    func transportsDifferOnlyByBaseURL() async throws {
        let directMock = MockClientTransport()
        let daemonMock = MockClientTransport()

        let direct = client(kind: .direct, serverURL: DaemonContract.backendURL, token: "tok-xyz", transport: directMock)
        let daemon = client(kind: .daemon, serverURL: DaemonContract.daemonURL(), token: "tok-xyz", transport: daemonMock)

        _ = try await direct.api.getHealth()
        _ = try await daemon.api.getHealth()

        let directReq = try #require(directMock.lastRequest)
        let daemonReq = try #require(daemonMock.lastRequest)

        // Identical request shape and identical auth on both transports …
        #expect(directReq.method == daemonReq.method)
        #expect(directReq.path == daemonReq.path)
        #expect(directReq.headerFields[.authorization] == daemonReq.headerFields[.authorization])
        #expect(directReq.headerFields[.authorization] == "Bearer tok-xyz")

        // … only the base URL the transport receives differs.
        #expect(directMock.lastBaseURL == DaemonContract.backendURL)
        #expect(daemonMock.lastBaseURL == DaemonContract.daemonURL())
        #expect(directMock.lastBaseURL != daemonMock.lastBaseURL)
    }

    @Test("transportKind is carried through from the transport")
    func transportKindCarried() {
        #expect(ADHClient(transport: .direct(transport: MockClientTransport())).transportKind == .direct)
        #expect(ADHClient(transport: .daemon(transport: MockClientTransport())).transportKind == .daemon)
    }

    @Test("session init installs SessionRefreshMiddleware and stores the transport")
    func sessionInitWiresRefresh() async throws {
        // A unique access token per test: refreshes serialize through the
        // process-wide `RefreshCoordinator.shared`, which identifies a refresh
        // wave by the expired access token (real tokens never collide).
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-wiring", kind: .jwt), refreshToken: "r-wiring"))
        let calls = Box<[HTTPRequest]>([])
        let mock = MockClientTransport { request in
            calls.set(calls.get + [request])
            if request.path == "/auth/refresh" {
                var response = HTTPResponse(status: .ok)
                response.headerFields[.contentType] = "application/json"
                return (response, HTTPBody(Data(#"{"token":"jwt-2","refreshToken":"r-2"}"#.utf8)))
            }
            if request.headerFields[.authorization] == "Bearer jwt-wiring" {
                return (HTTPResponse(status: .unauthorized), nil)
            }
            return MockClientTransport.healthOK()
        }
        let adh = ADHClient(transport: .direct(transport: mock), session: store)

        _ = try await adh.api.getHealth()

        #expect(adh.transport.kind == .direct)
        #expect(calls.get.map { $0.path ?? "" } == ["/health", "/auth/refresh", "/health"])
        #expect(store.currentSession()?.credentials.token == "jwt-2")
    }

    @Test("session expiry callback fires when refresh is rejected")
    func sessionExpiryCallback() async throws {
        // A unique access token per test: refreshes serialize through the
        // process-wide `RefreshCoordinator.shared`, which identifies a refresh
        // wave by the expired access token (real tokens never collide).
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-expiry", kind: .jwt), refreshToken: "r-expiry"))
        let expired = Box(false)
        let mock = MockClientTransport { _ in (HTTPResponse(status: .unauthorized), nil) }
        let adh = ADHClient(transport: .direct(transport: mock), session: store, onSessionExpired: { expired.set(true) })

        let output = try await adh.api.getHealth()

        #expect(throws: (any Error).self) { try output.ok }
        #expect(expired.get == true)
        #expect(store.currentSession() == nil)
    }
}
