import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class WorkspacesAdapterTests: XCTestCase {
    private static let workspacesJSON = #"""
    {"object":"workspace","slug":"ada","name":"Ada","type":"individual"},
    {"object":"workspace","slug":"acme","name":"Acme Inc","type":"organization"},
    {"object":"workspace","slug":"acme-core","name":"Core","type":"team"}
    """#

    private static func account(prefs: String) -> String {
        #"""
        {"object":"account","id":"u1","email":"a@b.c","name":"Ada","avatar_url":"","slug":"ada",
        "public_profile_enabled":false,"profile_visibility":"public","capabilities":[],
        "workspace_prefs":{"prefs":\#(prefs)}}
        """#
    }

    private func makeAdapter() -> (WorkspacesAdapter, StubClientTransport) {
        let stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r"))
        let environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        return (WorkspacesAdapter(environment: environment), stub)
    }

    func testListMapsTypes() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/workspaces", json: StubClientTransport.list([Self.workspacesJSON]))
        let list = try await adapter.listWorkspaces()
        XCTAssertEqual(list, [
            HubWorkspace(slug: "ada", name: "Ada", type: .individual),
            HubWorkspace(slug: "acme", name: "Acme Inc", type: .organization),
            HubWorkspace(slug: "acme-core", name: "Core", type: .team)
        ])
    }

    func testListUnauthorizedIsHubError() async {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/workspaces", status: 401, json: StubClientTransport.error("expired"))
        stub.on(.post, "/v1/auth/sessions/refresh", status: 503, json: "")
        do {
            _ = try await adapter.listWorkspaces()
            XCTFail("expected unauthorized")
        } catch {
            XCTAssertEqual(error as? HubError, .unauthorized)
        }
    }

    func testPreferredSlugReadsPrefsEnvelope() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/account", json: Self.account(prefs: #"{"slug":"acme"}"#))
        let slug = try await adapter.preferredSlug()
        XCTAssertEqual(slug, "acme")
        stub.on(.get, "/v1/account", json: Self.account(prefs: "{}"))
        let none = try await adapter.preferredSlug()
        XCTAssertNil(none)
    }

    func testSetPreferredSlugPostsTheSlug() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/account", json: Self.account(prefs: #"{"slug":"acme"}"#))
        try await adapter.setPreferredSlug("acme")
        let prefs = stub.lastBody(.post, "/v1/account")?["workspace_prefs"] as? [String: Any]
        XCTAssertEqual(prefs?["slug"] as? String, "acme")
        XCTAssertEqual(stub.lastRequest(.post, "/v1/account")?.headerFields[.authorization], "Bearer jwt")
    }
}
