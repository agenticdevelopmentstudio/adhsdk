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

    private static let loginJSON = #"{"refreshToken":"r","token":"jwt-xyz","user":{"avatarUrl":"","capabilities":[],"email":"a@b.c","id":"u1","name":"A","profileVisibility":"private","publicProfileEnabled":false,"slug":null}}"#
    private static let tokenJSON = #"{"createdAt":"2026-01-01","id":"t1","name":"ci","prefix":"adh_","token":"tok-secret"}"#

    private func makeClient(store: any CredentialStore) -> ADHClient {
        let mock = MockClientTransport { request in
            let path = request.path ?? ""
            let (status, json): (HTTPResponse.Status, String)
            if path.hasSuffix("/auth/login") {
                (status, json) = (.ok, Self.loginJSON)
            } else if path.hasSuffix("/auth/tokens") {
                (status, json) = (.created, Self.tokenJSON)
            } else {
                (status, json) = (.ok, #"{"status":"ok"}"#)
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
