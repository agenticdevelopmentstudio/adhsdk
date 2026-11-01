import OpenAPIURLSession
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// End-to-end proof for the Direct path: a *real* `URLSessionTransport` carries a
/// typed operation across `URLSession`, intercepted by ``StubURLProtocol`` so no
/// packets leave the machine. This is the one test that exercises the actual
/// transport implementation (the wiring suite uses a mock); it confirms the
/// request URL, the injected bearer, and response decoding all survive the round
/// trip through Foundation's networking stack.
///
/// Nested under ``StubURLProtocolSuites`` — see that type's doc comment for why.
extension StubURLProtocolSuites {
    @Suite("Direct transport (URLProtocol)")
    struct DirectTransportTests {

        private func makeURLSessionTransport() -> URLSessionTransport {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            return URLSessionTransport(
                configuration: .init(session: URLSession(configuration: configuration))
            )
        }

        @Test("real URLSessionTransport reaches the backend URL with the bearer and decodes 200")
        func directRoundTripThroughURLSession() async throws {
            StubURLProtocol.install { _ in
                StubURLProtocol.Stub()  // 200 application/json {"status":"ok"}
            }
            defer { StubURLProtocol.reset() }

            let creds = InMemoryCredentialStore(Credentials(token: "tok-direct", kind: .jwt))
            let adh = ADHClient(
                transport: .direct(transport: makeURLSessionTransport()),
                credentials: creds
            )

            let output = try await adh.api.getHealth()
            _ = try output.ok  // decoded the live 200 (the spec documents no body)

            let request = try #require(StubURLProtocol.capturedRequests.last)
            #expect(request.url?.absoluteString == "https://api.agenticdeveloperhub.com/health")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer tok-direct")
        }
    }
}
