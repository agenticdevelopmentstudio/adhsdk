import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// Semi-hermetic tests for the Daemon path: a typed operation travels over a real
/// loopback socket to ``MockDaemonServer`` (the stand-in for the future `adhd`
/// daemon) and back. This proves ``DaemonContract`` is honored end-to-end — the
/// daemon receives `/api/...` requests verbatim, including the `Authorization`
/// bearer the client forwards, and the generated client decodes the response.
@Suite("Daemon transport (mock server)")
struct DaemonTransportTests {

    @Test("a typed operation round-trips through the daemon over loopback")
    func roundTripsThroughDaemon() async throws {
        let server = MockDaemonServer()
        let port = try server.start()
        #expect(port != 0)
        defer { server.stop() }

        let creds = InMemoryCredentialStore(Credentials(token: "tok-daemon", kind: .jwt))
        let adh = ADHClient(transport: .daemon(port: Int(port)), credentials: creds)

        let output = try await adh.api.getHealth()
        _ = try output.ok  // decoded the daemon's 200
        #expect(adh.transportKind == .daemon)
    }

    @Test("the daemon receives the request verbatim, bearer included")
    func daemonReceivesBearerVerbatim() async throws {
        let server = MockDaemonServer()
        let port = try server.start()
        defer { server.stop() }

        let creds = InMemoryCredentialStore(Credentials(token: "tok-verbatim", kind: .jwt))
        let adh = ADHClient(transport: .daemon(port: Int(port)), credentials: creds)

        _ = try await adh.api.getHealth()

        let received = try #require(server.requests.last)
        #expect(received.method == "GET")
        #expect(received.path == DaemonContract.healthPath)
        #expect(received.headers["authorization"] == "Bearer tok-verbatim")
    }
}
