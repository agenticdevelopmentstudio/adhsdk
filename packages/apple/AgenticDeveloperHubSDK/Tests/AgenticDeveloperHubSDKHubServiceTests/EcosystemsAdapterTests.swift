import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class EcosystemsAdapterTests: XCTestCase {
    private func makeAdapter() -> (EcosystemsAdapter, StubClientTransport) {
        let stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r"))
        let environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        let adapter = EcosystemsAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
        return (adapter, stub)
    }

    private let shopJSON = #"""
    {"id":"org.acme.shop","slug":"shop","name":"Shop","description":"Storefront","region":null,"primary_domain":null,
     "created":1788220800,"updated":1788220800,"is_default":false,"parent_id":null}
    """#
    private let infraJSON = #"""
    {"id":"org.acme","slug":"acme","name":"Acme","created":1788220800,
     "updated":1788220800,"is_default":true,"is_infrastructure":true}
    """#

    func testListSendsWorkspaceQuery() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ecosystems", json: StubClientTransport.list([shopJSON]))
        let rows = try await adapter.list()
        XCTAssertEqual(rows.map(\.id), ["org.acme.shop"])
        XCTAssertEqual(stub.lastRequest(.get, "/v1/ecosystems")?.path, "/v1/ecosystems?limit=100&workspace=acme")
        XCTAssertEqual(stub.lastRequest(.get, "/v1/ecosystems")?.headerFields[.authorization], "Bearer jwt")
    }

    /// `parent=` alone, as the web sends it. Adding `workspace=` AND'd the two scopes and the child
    /// list read empty for a product that has children.
    func testChildrenSendsParentAloneWithoutWorkspace() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ecosystems", json: StubClientTransport.list([]))
        let rows = try await adapter.children(of: "org.acme.shop")
        XCTAssertTrue(rows.isEmpty)
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/ecosystems")?.path,
            "/v1/ecosystems?limit=100&parent=org.acme.shop"
        )
    }

    func testGet() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ecosystems/org.acme.shop", json: shopJSON)
        let ecosystem = try await adapter.get(id: "org.acme.shop")
        XCTAssertEqual(ecosystem.name, "Shop")
        XCTAssertFalse(ecosystem.isDefault)
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/ecosystems/org.acme.shop")?.path,
            "/v1/ecosystems/org.acme.shop?workspace=acme"
        )
    }

    func testInfrastructureIDIsFirstRow() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ecosystems", json: StubClientTransport.list([infraJSON]))
        let id = try await adapter.infrastructureID()
        XCTAssertEqual(id, "org.acme")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/ecosystems")?.path,
            "/v1/ecosystems?infrastructure=true&limit=100&workspace=acme"
        )
    }

    func testInfrastructureIDThrowsWhenMissing() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/v1/ecosystems", json: StubClientTransport.list([]))
        do {
            _ = try await adapter.infrastructureID()
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .unexpected("No infrastructure ecosystem for workspace acme"))
        }
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/ecosystems")?.path,
            "/v1/ecosystems?infrastructure=true&limit=100&workspace=acme"
        )
    }

    func testIdentifierExists() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.get, "/registry/identifiers/org.acme.shop/exists", json: #"{"exists":true}"#)
        let exists = try await adapter.identifierExists("org.acme.shop")
        XCTAssertTrue(exists)
        XCTAssertEqual(
            stub.lastRequest(.get, "/registry/identifiers/org.acme.shop/exists")?.path,
            "/registry/identifiers/org.acme.shop/exists"
        )
    }

    func testCreatePostsBodyWithParent() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/ecosystems", status: 201, json: shopJSON)
        let input = EcosystemCreate(id: "org.acme.shop", slug: "shop", name: "Shop", description: "Storefront")
        _ = try await adapter.create(input, parentID: "org.acme")
        let sent = stub.lastBody(.post, "/v1/ecosystems")
        XCTAssertEqual(sent?["id"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["slug"] as? String, "shop")
        XCTAssertEqual(sent?["name"] as? String, "Shop")
        XCTAssertEqual(sent?["description"] as? String, "Storefront")
        XCTAssertEqual(sent?["region"] as? String, "")
        XCTAssertEqual(sent?["primaryDomain"] as? String, "")
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/ecosystems")?.path,
            "/v1/ecosystems?parent=org.acme&workspace=acme"
        )
    }

    func testCreateWithoutParentOmitsParentQuery() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/ecosystems", status: 201, json: shopJSON)
        let input = EcosystemCreate(id: "org.acme.shop", slug: "shop", name: "Shop", description: "")
        _ = try await adapter.create(input, parentID: nil)
        XCTAssertEqual(stub.lastRequest(.post, "/v1/ecosystems")?.path, "/v1/ecosystems?workspace=acme")
    }

    func testUpdatePostsOnlyProvidedFields() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/ecosystems/org.acme.shop", json: shopJSON)
        _ = try await adapter.update(id: "org.acme.shop", EcosystemUpdate(slug: "shop", name: "Web Shop"))
        let sent = stub.lastBody(.post, "/v1/ecosystems/org.acme.shop")
        XCTAssertEqual(sent?["slug"] as? String, "shop")
        XCTAssertEqual(sent?["name"] as? String, "Web Shop")
        XCTAssertNil(sent?["description"] ?? nil)
        XCTAssertNil(sent?["region"] ?? nil)
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/ecosystems/org.acme.shop")?.path,
            "/v1/ecosystems/org.acme.shop?workspace=acme"
        )
    }

    func testDelete() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.delete, "/v1/ecosystems/org.acme.shop", status: 204, json: "")
        try await adapter.delete(id: "org.acme.shop")
        XCTAssertEqual(stub.requestCount(.delete, "/v1/ecosystems/org.acme.shop"), 1)
        XCTAssertEqual(
            stub.lastRequest(.delete, "/v1/ecosystems/org.acme.shop")?.path,
            "/v1/ecosystems/org.acme.shop?workspace=acme"
        )
    }

    func testConflictBecomesHubErrorConflict() async throws {
        let (adapter, stub) = makeAdapter()
        stub.on(.post, "/v1/ecosystems", status: 409, json: StubClientTransport.error("duplicate identifier"))
        let input = EcosystemCreate(id: "org.acme.shop", slug: "shop", name: "Shop", description: "")
        do {
            _ = try await adapter.create(input, parentID: nil)
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .conflict("duplicate identifier"))
        }
        XCTAssertEqual(stub.lastRequest(.post, "/v1/ecosystems")?.path, "/v1/ecosystems?workspace=acme")
    }
}
