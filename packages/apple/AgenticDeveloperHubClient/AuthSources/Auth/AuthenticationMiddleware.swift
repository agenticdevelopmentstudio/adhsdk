import HTTPTypes
import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Injects `Authorization: Bearer <token>` on every outgoing request, reading
/// the token from a ``CredentialProvider`` at send time so rotation is picked up
/// without rebuilding the client.
///
/// This is the idiomatic swift-openapi-runtime seam for authentication — a
/// `ClientMiddleware`, not a transport wrapper — which keeps auth orthogonal to
/// transport selection (Direct vs Daemon). The client forwards the bearer on
/// *both* transports; the daemon does not own auth.
public struct AuthenticationMiddleware: ClientMiddleware {

    private let credentials: any CredentialProvider

    public init(credentials: any CredentialProvider) {
        self.credentials = credentials
    }

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        if let token = credentials.currentCredentials()?.token {
            request.headerFields[.authorization] = "Bearer \(token)"
        }
        return try await next(request, body, baseURL)
    }
}
