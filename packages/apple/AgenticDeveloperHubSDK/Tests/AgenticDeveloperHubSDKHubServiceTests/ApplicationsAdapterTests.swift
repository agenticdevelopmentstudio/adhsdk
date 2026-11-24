import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class ApplicationsAdapterTests: XCTestCase {
    private var stub: StubClientTransport!
    private var adapter: ApplicationsAdapter!

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
        adapter = ApplicationsAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
    }

    private let webJSON = #"""
    {"object":"application","id":"app.acme.shop.web","ecosystem_id":"org.acme.shop","slug":"web",
     "display_name":"Web Storefront","consumer_kind":"customer","created":1788220800,"updated":1788220800}
    """#
    private let otherJSON = #"""
    {"object":"application","id":"app.acme.blog.cms","ecosystem_id":"org.acme.blog","slug":"cms",
     "display_name":"CMS","consumer_kind":"staff","created":1788220800,"updated":1788220800}
    """#
    /// The contract's shape: `crud`, not `permissions`, and `tables` an ARRAY of `{table_id, crud}`,
    /// inside the application's `schema_grants` sub-resource.
    private var grantsJSON: String {
        #"""
        {"object":"application","id":"app.acme.shop.web","ecosystem_id":"org.acme.shop",
         "schema_grants":{"grants":[{"schema_id":"b-profile","crud":"R,U",
         "tables":[{"table_id":"t-contacts","crud":"R"}]}]}}
        """#
    }

    private let appPath = "/v1/applications/app.acme.shop.web"

    func testListFiltersByEcosystemAndDrainsPage() async throws {
        stub.on(.get, "/v1/applications", json: StubClientTransport.list([webJSON, otherJSON]))
        let rows = try await adapter.list(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.map(\.id), ["app.acme.shop.web"])
        XCTAssertEqual(rows.first?.consumerKind, .customer)
        XCTAssertEqual(rows.first?.ecosystemId, "org.acme.shop")
        XCTAssertEqual(rows.first?.createdAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(stub.lastRequest(.get, "/v1/applications")?.path, "/v1/applications?limit=100&workspace=acme")
    }

    func testGet() async throws {
        stub.on(.get, appPath, json: webJSON)
        let app = try await adapter.get(id: "app.acme.shop.web")
        XCTAssertEqual(app.displayName, "Web Storefront")
        XCTAssertEqual(stub.lastRequest(.get, appPath)?.path, "\(appPath)?workspace=acme")
    }

    func testCreatePostsBody() async throws {
        stub.on(.post, "/v1/applications", status: 201, json: webJSON)
        _ = try await adapter.create(
            ApplicationCreate(
                ecosystemId: "org.acme.shop", slug: "web", displayName: "Web Storefront", consumerKind: .customer
            )
        )
        XCTAssertEqual(stub.lastRequest(.post, "/v1/applications")?.path, "/v1/applications?workspace=acme")
        let sent = stub.lastBody(.post, "/v1/applications")
        XCTAssertEqual(sent?["ecosystemId"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["slug"] as? String, "web")
        XCTAssertEqual(sent?["displayName"] as? String, "Web Storefront")
        XCTAssertEqual(sent?["consumerKind"] as? String, "customer")
    }

    func testUpdatePostsOnlyProvidedFields() async throws {
        stub.on(.post, appPath, json: webJSON)
        _ = try await adapter.update(id: "app.acme.shop.web", ApplicationUpdate(displayName: "Storefront"))
        XCTAssertEqual(stub.lastRequest(.post, appPath)?.path, "\(appPath)?workspace=acme")
        let sent = stub.lastBody(.post, appPath)
        XCTAssertEqual(sent?["displayName"] as? String, "Storefront")
        XCTAssertNil(sent?["slug"] ?? nil)
        XCTAssertNil(sent?["consumerKind"] ?? nil)
    }

    func testDelete() async throws {
        stub.on(.delete, appPath, status: 204, json: "")
        try await adapter.delete(id: "app.acme.shop.web")
        XCTAssertEqual(stub.lastRequest(.delete, appPath)?.path, "\(appPath)?workspace=acme")
    }

    func testRenameIdentifierPostsToV1Identifiers() async throws {
        stub.on(.post, "/v1/identifiers/app.acme.shop.web", json: #"{"rdid":"app.acme.shop.store"}"#)
        try await adapter.renameIdentifier("app.acme.shop.web", to: "app.acme.shop.store")
        XCTAssertEqual(
            stub.lastBody(.post, "/v1/identifiers/app.acme.shop.web")?["rdid"] as? String, "app.acme.shop.store"
        )
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/identifiers/app.acme.shop.web")?.path, "/v1/identifiers/app.acme.shop.web"
        )
    }

    func testRenameConflictBecomesHubErrorConflict() async throws {
        stub.on(
            .post, "/v1/identifiers/app.acme.shop.web", status: 409,
            json: StubClientTransport.error("identifier taken")
        )
        do {
            try await adapter.renameIdentifier("app.acme.shop.web", to: "app.acme.shop.store")
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .conflict("identifier taken"))
        }
        // The registry is workspace-agnostic: the identifier is globally unique, so no query at all.
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/identifiers/app.acme.shop.web")?.path, "/v1/identifiers/app.acme.shop.web"
        )
    }

    func testSchemaGrantsReadsIncludedSubResource() async throws {
        stub.on(.get, appPath, json: grantsJSON)
        let grants = try await adapter.schemaGrants(applicationID: "app.acme.shop.web")
        XCTAssertEqual(grants.count, 1)
        XCTAssertEqual(grants.first?.schemaId, "b-profile")
        XCTAssertEqual(grants.first?.permissions, "R,U")
        // Keyed by the table's ID, which is what every lookup in `ApplicationsTopic` has.
        XCTAssertEqual(grants.first?.tables["t-contacts"]?.permissions, "R")
        XCTAssertEqual(grants.first?.tables["t-contacts"]?.level, "table")
        XCTAssertEqual(
            stub.lastRequest(.get, appPath)?.path, "\(appPath)?include%5B%5D=schema_grants&workspace=acme"
        )
    }

    func testSchemaGrantsWithoutSubResourceThrows() async throws {
        stub.on(.get, appPath, json: webJSON)
        do {
            _ = try await adapter.schemaGrants(applicationID: "app.acme.shop.web")
            XCTFail("expected throw")
        } catch let error as HubError {
            guard case .unexpected(let message) = error else { return XCTFail("wrong error \(error)") }
            XCTAssertTrue(message.contains("did not include schema_grants"), message)
        }
    }

    func testSetSchemaGrantsPostsOnlyTheSubResource() async throws {
        stub.on(.post, appPath, json: grantsJSON)
        let grant = SchemaGrant(
            schemaId: "b-profile", permissions: "R",
            tables: [
                "t-contacts": TableGrant(level: "table", permissions: "R"),
                "t-empty": TableGrant(level: "table", permissions: "")
            ]
        )
        try await adapter.setSchemaGrants(applicationID: "app.acme.shop.web", [grant])
        XCTAssertEqual(stub.lastRequest(.post, appPath)?.path, "\(appPath)?workspace=acme")
        let sent = stub.lastBody(.post, appPath)
        // The body's only key names the sub-resource, which is what makes `/v1` update it alone.
        XCTAssertEqual(sent.map { Set($0.keys) }, ["schema_grants"])
        let envelope = sent?["schema_grants"] as? [String: Any]
        let grants = envelope?["grants"] as? [[String: Any]]
        XCTAssertEqual(grants?.count, 1)
        XCTAssertEqual(grants?.first?["schemaId"] as? String, "b-profile")
        XCTAssertEqual(grants?.first?["crud"] as? String, "R")
        XCTAssertNil(grants?.first?["permissions"] ?? nil)
        // An array of `{tableId, crud}`; `level` is UI-only, and a table with no permissions
        // carries no row at all — exactly what the web client sends.
        let tables = grants?.first?["tables"] as? [[String: Any]]
        XCTAssertEqual(tables?.count, 1)
        XCTAssertEqual(tables?.first?["tableId"] as? String, "t-contacts")
        XCTAssertEqual(tables?.first?["crud"] as? String, "R")
        XCTAssertNil(tables?.first?["level"] ?? nil)
    }

    func testTokensListAndCreateAndRevoke() async throws {
        let tokensPath = "\(appPath)/tokens"
        stub.on(
            .get, tokensPath,
            json: StubClientTransport.list(
                [#"{"object":"application_token","id":"tok-1","name":"CI","prefix":"apk_ab12","created":1788220800}"#]
            )
        )
        stub.on(
            .post, tokensPath, status: 201,
            json: #"""
            {"object":"application_token","id":"tok-2","name":"Deploy","prefix":"apk_cd34",
             "token":"apk_cd34ef56gh78","created":1788307200}
            """#
        )
        stub.on(.delete, "\(tokensPath)/tok-1", status: 204, json: "")

        let tokens = try await adapter.tokens(applicationID: "app.acme.shop.web")
        XCTAssertEqual(tokens.map(\.name), ["CI"])
        XCTAssertEqual(tokens.first?.createdAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(stub.lastRequest(.get, tokensPath)?.path, "\(tokensPath)?limit=100&workspace=acme")

        let created = try await adapter.createToken(applicationID: "app.acme.shop.web", name: "Deploy")
        XCTAssertEqual(created.token, "apk_cd34ef56gh78")
        XCTAssertEqual(created.createdAt, "2026-09-02T00:00:00.000Z")
        XCTAssertEqual(stub.lastBody(.post, tokensPath)?["name"] as? String, "Deploy")
        XCTAssertEqual(stub.lastRequest(.post, tokensPath)?.path, "\(tokensPath)?workspace=acme")

        try await adapter.revokeToken(applicationID: "app.acme.shop.web", tokenID: "tok-1")
        XCTAssertEqual(stub.requestCount(.delete, "\(tokensPath)/tok-1"), 1)
        XCTAssertEqual(stub.lastRequest(.delete, "\(tokensPath)/tok-1")?.path, "\(tokensPath)/tok-1?workspace=acme")
    }
}
