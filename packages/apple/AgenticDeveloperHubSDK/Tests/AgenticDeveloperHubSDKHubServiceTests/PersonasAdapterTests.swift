import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class PersonasAdapterTests: XCTestCase {
    private func makeAdapter() -> (PersonasAdapter, StubClientTransport) {
        let stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r"))
        let environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        let adapter = PersonasAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
        return (adapter, stub)
    }

    private static let personaJSON = #"""
    {"id":"persona.acme.ada","user_id":"u1","owner_kind":"organization","owner_id":"o1","slug":"ada","name":"Ada",
     "description":null,"visibility":"private","model":null,"service_id":null,"app_id":null,
     "avatar_attachment_id":null,"model_prompt":"You are Ada.","voice":null,"character":null,"examples":null,
     "created":1788220800,"updated":1788220800}
    """#

    func testListSendsWorkspaceQuery() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/personas", json: StubClientTransport.list([Self.personaJSON]))
        let rows = try await adapter.list()
        XCTAssertEqual(rows.map(\.id), ["persona.acme.ada"])
        XCTAssertEqual(stub.lastRequest(.get, "/v1/personas")?.path, "/v1/personas?limit=100&workspace=acme")
        XCTAssertEqual(stub.lastRequest(.get, "/v1/personas")?.headerFields[.authorization], "Bearer jwt")
    }

    func testGet() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/personas/persona.acme.ada", json: Self.personaJSON)
        let persona = try await adapter.get(id: "persona.acme.ada")
        XCTAssertEqual(persona.name, "Ada")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/personas/persona.acme.ada")?.path,
            "/v1/personas/persona.acme.ada?workspace=acme"
        )
    }

    func testCreatePostsBody() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/personas", status: 201, json: Self.personaJSON)
        let body = PersonaBody(
            slug: "ada", name: "Ada", description: nil, modelPrompt: "You are Ada.", model: "", visibility: "private"
        )
        _ = try await adapter.create(body)
        let sent = stub.lastBody(.post, "/v1/personas")
        XCTAssertEqual(sent?["slug"] as? String, "ada")
        XCTAssertEqual(sent?["name"] as? String, "Ada")
        XCTAssertEqual(sent?["model"] as? String, "")
        XCTAssertEqual(sent?["visibility"] as? String, "private")
        XCTAssertNil(sent?["description"] ?? nil, "nil optionals are omitted, not sent as null")
        XCTAssertEqual(stub.lastRequest(.post, "/v1/personas")?.path, "/v1/personas?workspace=acme")
    }

    func testUpdatePosts() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/personas/persona.acme.ada", json: Self.personaJSON)
        var body = PersonaBody(slug: "ada", name: "Ada L", modelPrompt: "p", visibility: "hub")
        body.cannedChat = .object(["mode": .string("script")])
        _ = try await adapter.update(id: "persona.acme.ada", body)
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/personas/persona.acme.ada")?.path,
            "/v1/personas/persona.acme.ada?workspace=acme"
        )
        let sent = stub.lastBody(.post, "/v1/personas/persona.acme.ada")
        XCTAssertEqual(sent?["name"] as? String, "Ada L")
        XCTAssertEqual((sent?["cannedChat"] as? [String: Any])?["mode"] as? String, "script")
    }

    func testDelete() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.delete, "/v1/personas/persona.acme.ada", status: 204, json: "")
        try await adapter.delete(id: "persona.acme.ada")
        XCTAssertEqual(
            stub.lastRequest(.delete, "/v1/personas/persona.acme.ada")?.path,
            "/v1/personas/persona.acme.ada?workspace=acme"
        )
    }

    func testListServices() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ai_services", json: StubClientTransport.list([#"""
        {"id":"svc1","template_id":null,"provider_kind":"openai","name":"OpenAI",
          "base_url":"https://api.openai.com","has_api_key":true,
          "connect_status":"connected","connect_error":null,"last_connected_at":null,"documentation_url":null,
          "status_url":null,
          "models":[{"id":"gpt-x","display_name":"GPT X","context_window":128000}],"models_fetched_at":null}
        """#]))
        let services = try await adapter.listServices()
        XCTAssertEqual(services.map(\.name), ["OpenAI"])
        XCTAssertEqual(services[0].models.map(\.id), ["gpt-x"])
        XCTAssertEqual(stub.lastRequest(.get, "/v1/ai_services")?.path, "/v1/ai_services?limit=100")
    }

    func testUnauthorizedMapsToHubError() async {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/personas", status: 401, json: "{}")
        stub.on(.post, "/v1/auth/sessions/refresh", status: 503, json: "")
        do {
            _ = try await adapter.list()
            XCTFail("expected unauthorized error")
        } catch {
            XCTAssertEqual(error as? HubError, .unauthorized)
        }
        XCTAssertEqual(stub.lastRequest(.get, "/v1/personas")?.path, "/v1/personas?limit=100&workspace=acme")
    }
}
