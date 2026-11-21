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

/// Tests for the `login` / `createAPIToken` / `adopt` / `logout` convenience
/// wrappers. A path-routed ``MockClientTransport`` returns canned auth payloads,
/// so these assert the credential-store side effects without a network.
@Suite("Auth convenience wrappers")
struct AuthWrappersTests {

    private static let loginJSON = #"{"object":"auth.session","token":"jwt-xyz","refresh_token":"r","user":{"id":"u1","email":"a@b.c","name":"A","avatar_url":"","slug":null,"public_profile_enabled":false,"profile_visibility":"private","capabilities":[]}}"#
    private static let tokenJSON = #"{"object":"api_key","id":"t1","name":"ci","prefix":"adh_","created":1767225600,"expires_at":null,"last_used_at":null,"token":"tok-secret"}"#

    private func makeClient(store: any CredentialStore) -> ADHClient {
        let mock = MockClientTransport { request in
            let path = request.path ?? ""
            let (status, json): (HTTPResponse.Status, String)
            if path == "/v1/auth/sessions" {
                (status, json) = (.ok, Self.loginJSON)
            } else if path == "/v1/api_keys" {
                (status, json) = (.created, Self.tokenJSON)
            } else {
                (status, json) = (.notFound, #"{"error":{"type":"invalid_request_error","message":"no route"}}"#)
            }
            var response = HTTPResponse(status: status)
            response.headerFields[.contentType] = "application/json"
            return (response, HTTPBody(Data(json.utf8)))
        }
        return ADHClient(transport: .direct(transport: mock), credentials: store)
    }

    @Test("login persists the returned JWT")
    func loginPersistsJWT() async throws {
        let store = InMemoryCredentialStore()
        let adh = makeClient(store: store)

        let auth = try await adh.login(email: "a@b.c", password: "pw")

        #expect(auth.token == "jwt-xyz")
        #expect(store.currentCredentials() == Credentials(token: "jwt-xyz", kind: .jwt))
    }

    @Test("createAPIToken returns the secret but leaves the active credential untouched")
    func createAPITokenDoesNotPersist() async throws {
        let store = InMemoryCredentialStore(Credentials(token: "jwt-existing", kind: .jwt))
        let adh = makeClient(store: store)

        let created = try await adh.createAPIToken(name: "ci")

        #expect(created.value2.token == "tok-secret")
        #expect(store.currentCredentials()?.token == "jwt-existing")
    }

    @Test("adopt switches the client to a credential; logout clears it")
    func adoptAndLogout() async {
        let store = InMemoryCredentialStore()
        let adh = makeClient(store: store)

        adh.adopt(Credentials(token: "tok-secret", kind: .apiToken))
        #expect(store.currentCredentials() == Credentials(token: "tok-secret", kind: .apiToken))

        adh.logout()
        #expect(store.currentCredentials() == nil)
    }
}
