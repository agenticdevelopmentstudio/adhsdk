import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class CustomersAdapterTests: XCTestCase {
    private var stub: StubClientTransport!
    private var adapter: CustomersAdapter!

    override func setUp() async throws {
        try await super.setUp()
        stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r")
        )
        let environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
        adapter = CustomersAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
    }

    private let janeJSON = #"""
    {"id":"c-jane","ecosystem_id":"org.acme.shop","email":"jane@example.com","display_name":"Jane Doe",
     "external_id":null,"slug":"jane","avatar_url":null,
     "created":1788220800,"updated":1788220800}
    """#
    private let otherJSON = #"""
    {"id":"c-bob","ecosystem_id":"org.acme.blog","email":"bob@example.com",
     "created":1788220800,"updated":1788220800}
    """#

    func testListFiltersByEcosystem() async throws {
        stub.on(.get, "/v1/customers", json: StubClientTransport.list([janeJSON, otherJSON]))
        let rows = try await adapter.list(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.map(\.id), ["c-jane"])
        XCTAssertEqual(rows.first?.label, "Jane Doe")
        XCTAssertEqual(stub.lastRequest(.get, "/v1/customers")?.path, "/v1/customers?limit=100&workspace=acme")
    }

    func testGet() async throws {
        stub.on(.get, "/v1/customers/c-jane", json: janeJSON)
        let customer = try await adapter.get(id: "c-jane")
        XCTAssertEqual(customer.email, "jane@example.com")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/customers/c-jane")?.path,
            "/v1/customers/c-jane?workspace=acme"
        )
    }

    func testCreatePostsBodyWithoutNilFields() async throws {
        stub.on(.post, "/v1/customers", status: 201, json: janeJSON)
        _ = try await adapter.create(
            CustomerInput(ecosystemId: "org.acme.shop", email: "jane@example.com", displayName: "Jane Doe")
        )
        XCTAssertEqual(stub.lastRequest(.post, "/v1/customers")?.path, "/v1/customers?workspace=acme")
        let sent = stub.lastBody(.post, "/v1/customers")
        XCTAssertEqual(sent?["ecosystemId"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["email"] as? String, "jane@example.com")
        XCTAssertEqual(sent?["displayName"] as? String, "Jane Doe")
        XCTAssertNil(sent?["externalId"] ?? nil)
        XCTAssertNil(sent?["slug"] ?? nil)
    }

    func testUpdatePostsFullInput() async throws {
        stub.on(.post, "/v1/customers/c-jane", json: janeJSON)
        _ = try await adapter.update(
            id: "c-jane",
            CustomerInput(ecosystemId: "org.acme.shop", email: "jane@example.com", displayName: "Jane", slug: "jane")
        )
        let sent = stub.lastBody(.post, "/v1/customers/c-jane")
        XCTAssertEqual(sent?["displayName"] as? String, "Jane")
        XCTAssertEqual(sent?["slug"] as? String, "jane")
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/customers/c-jane")?.path,
            "/v1/customers/c-jane?workspace=acme"
        )
    }

    func testDelete() async throws {
        stub.on(.delete, "/v1/customers/c-jane", status: 204, json: "")
        try await adapter.delete(id: "c-jane")
        XCTAssertEqual(
            stub.lastRequest(.delete, "/v1/customers/c-jane")?.path,
            "/v1/customers/c-jane?workspace=acme"
        )
    }

    func testConflictBecomesHubErrorConflict() async throws {
        stub.on(.post, "/v1/customers", status: 409, json: StubClientTransport.error("email in use"))
        do {
            _ = try await adapter.create(CustomerInput(ecosystemId: "org.acme.shop", email: "jane@example.com"))
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .conflict("email in use"))
        }
        XCTAssertEqual(stub.lastRequest(.post, "/v1/customers")?.path, "/v1/customers?workspace=acme")
    }
}
