import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class BucketsAdapterTests: XCTestCase {
    private var stub: StubClientTransport!
    private var adapter: BucketsAdapter!

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
        adapter = BucketsAdapter(
            environment: environment,
            workspace: HubWorkspace(slug: "acme", name: "Acme", type: .organization)
        )
    }

    private let profileJSON = #"""
    {"id":"b-profile","object":"bucket","ecosystem_id":"org.acme.shop","name":"Profile Basics","kind":"custom",
     "metadata":{"description":"Names and avatars"},
     "created":1788220800,"updated":1788220800}
    """#
    private let otherJSON = #"""
    {"id":"b-other","object":"bucket","ecosystem_id":"org.acme.blog","name":"Posts",
     "created":1788220800,"updated":1788220800}
    """#
    private let contactsJSON = #"""
    {"id":"t-contacts","object":"bucket_type","bucket_id":"b-profile","ecosystem_id":"org.acme.shop",
     "sql_table_name":"contacts","name":"Contacts"}
    """#
    private let postsTableJSON = #"""
    {"id":"t-posts","object":"bucket_type","bucket_id":"b-other","ecosystem_id":"org.acme.blog",
     "sql_table_name":"posts","name":"Posts"}
    """#

    func testListFiltersByEcosystemAndSendsWorkspace() async throws {
        stub.on(.get, "/v1/buckets", json: StubClientTransport.list([profileJSON, otherJSON]))
        let rows = try await adapter.list(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.map(\.id), ["b-profile"])
        XCTAssertEqual(rows.first?.description, "Names and avatars")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/buckets")?.path,
            "/v1/buckets?limit=100&workspace=acme"
        )
    }

    func testMissingKindDecodesAsCustom() async throws {
        stub.on(.get, "/v1/buckets", json: StubClientTransport.list([otherJSON]))
        let rows = try await adapter.list(ecosystemID: "org.acme.blog")
        XCTAssertEqual(rows.first?.kind, "custom")
        XCTAssertFalse(rows.first?.isBuiltIn ?? true)
        XCTAssertEqual(stub.lastRequest(.get, "/v1/buckets")?.path, "/v1/buckets?limit=100&workspace=acme")
    }

    func testGet() async throws {
        stub.on(.get, "/v1/buckets/b-profile", json: profileJSON)
        let bucket = try await adapter.get(id: "b-profile")
        XCTAssertEqual(bucket.name, "Profile Basics")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/buckets/b-profile")?.path,
            "/v1/buckets/b-profile?workspace=acme"
        )
    }

    func testCreatePostsBody() async throws {
        stub.on(.post, "/v1/buckets", status: 201, json: profileJSON)
        _ = try await adapter.create(
            BucketCreate(
                ecosystemId: "org.acme.shop", name: "Profile Basics",
                metadata: BucketMetadata(description: "Names and avatars")
            )
        )
        let sent = stub.lastBody(.post, "/v1/buckets")
        XCTAssertEqual(sent?["ecosystemId"] as? String, "org.acme.shop")
        XCTAssertEqual(sent?["name"] as? String, "Profile Basics")
        XCTAssertEqual((sent?["metadata"] as? [String: Any])?["description"] as? String, "Names and avatars")
        XCTAssertEqual(stub.lastRequest(.post, "/v1/buckets")?.path, "/v1/buckets?workspace=acme")
    }

    func testUpdatePostsOnlyProvidedFields() async throws {
        stub.on(.post, "/v1/buckets/b-profile", json: profileJSON)
        _ = try await adapter.update(id: "b-profile", BucketUpdate(name: "Profiles"))
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/buckets/b-profile")?.path, "/v1/buckets/b-profile?workspace=acme"
        )
        let sent = stub.lastBody(.post, "/v1/buckets/b-profile")
        XCTAssertEqual(sent?["name"] as? String, "Profiles")
        XCTAssertNil(sent?["metadata"] ?? nil)
    }

    func testDelete() async throws {
        stub.on(.delete, "/v1/buckets/b-profile", status: 204, json: "")
        try await adapter.delete(id: "b-profile")
        XCTAssertEqual(
            stub.lastRequest(.delete, "/v1/buckets/b-profile")?.path,
            "/v1/buckets/b-profile?workspace=acme"
        )
    }

    func testTablesFiltersByEcosystem() async throws {
        stub.on(.get, "/v1/bucket_types", json: StubClientTransport.list([contactsJSON, postsTableJSON]))
        let rows = try await adapter.tables(ecosystemID: "org.acme.shop")
        XCTAssertEqual(rows.map(\.id), ["t-contacts"])
        XCTAssertEqual(rows.first?.bucketId, "b-profile")
        XCTAssertEqual(rows.first?.sqlTableName, "contacts")
        XCTAssertEqual(
            stub.lastRequest(.get, "/v1/bucket_types")?.path,
            "/v1/bucket_types?limit=100&workspace=acme"
        )
    }

    func testCreateTablePostsBody() async throws {
        stub.on(.post, "/v1/bucket_types", status: 201, json: contactsJSON)
        let row = try await adapter.createTable(
            BucketTableCreate(
                ecosystemId: "org.acme.shop", bucketId: "b-profile", sqlTableName: "contacts", name: "Contacts"
            )
        )
        XCTAssertEqual(row.id, "t-contacts")
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/bucket_types")?.path, "/v1/bucket_types?workspace=acme"
        )
        let sent = stub.lastBody(.post, "/v1/bucket_types")
        XCTAssertEqual(sent?["bucketId"] as? String, "b-profile")
        XCTAssertEqual(sent?["sqlTableName"] as? String, "contacts")
        XCTAssertEqual(sent?["name"] as? String, "Contacts")
    }

    func testUpdateAndDeleteTable() async throws {
        stub.on(.post, "/v1/bucket_types/t-contacts", json: contactsJSON)
        stub.on(.delete, "/v1/bucket_types/t-contacts", status: 204, json: "")
        _ = try await adapter.updateTable(id: "t-contacts", BucketTableUpdate(name: "People"))
        XCTAssertEqual(stub.lastBody(.post, "/v1/bucket_types/t-contacts")?["name"] as? String, "People")
        XCTAssertEqual(
            stub.lastRequest(.post, "/v1/bucket_types/t-contacts")?.path,
            "/v1/bucket_types/t-contacts?workspace=acme"
        )
        try await adapter.deleteTable(id: "t-contacts")
        XCTAssertEqual(
            stub.lastRequest(.delete, "/v1/bucket_types/t-contacts")?.path,
            "/v1/bucket_types/t-contacts?workspace=acme"
        )
    }

    func testConflictBecomesHubErrorConflict() async throws {
        stub.on(.post, "/v1/buckets", status: 409, json: StubClientTransport.error("duplicate name"))
        do {
            _ = try await adapter.create(
                BucketCreate(ecosystemId: "org.acme.shop", name: "Profile Basics", metadata: BucketMetadata())
            )
            XCTFail("expected throw")
        } catch let error as HubError {
            XCTAssertEqual(error, .conflict("duplicate name"))
        }
        XCTAssertEqual(stub.lastRequest(.post, "/v1/buckets")?.path, "/v1/buckets?workspace=acme")
    }
}
