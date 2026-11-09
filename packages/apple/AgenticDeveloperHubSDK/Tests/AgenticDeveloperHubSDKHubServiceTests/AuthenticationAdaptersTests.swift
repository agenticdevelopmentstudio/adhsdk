import AgenticDeveloperHubClient
import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes
import XCTest
@testable import AgenticDeveloperHubSDKHubAuth
@testable import AgenticDeveloperHubSDKHubService

@MainActor
final class AuthenticationAdaptersTests: XCTestCase {
    private var stub: StubClientTransport!
    private var environment: HubEnvironment!
    private let workspace = HubWorkspace(slug: "acme", name: "Acme", type: .organization)

    override func setUp() async throws {
        try await super.setUp()
        stub = StubClientTransport()
        let store = InMemorySessionStore(
            HubSession(credentials: Credentials(token: "jwt", kind: .jwt), refreshToken: "r"))
        environment = HubEnvironment(
            sessionStore: store,
            transportSource: StaticTransportSource(.direct(transport: stub)),
            initialTransport: .direct(transport: stub)
        )
    }

    // MARK: - API tokens

    func testListTokensDecodesListEnvelope() async throws {
        stub.on(
            .get, "/v1/api_keys",
            json: StubClientTransport.list([#"""
            {"object":"api_key","id":"api-1","name":"research-agent","prefix":"tmp_ab12",
             "created":1788220800,"scope":["research"]}
            """#])
        )
        let tokens = try await ApiTokensAdapter(environment: environment, workspace: workspace).list()
        XCTAssertEqual(tokens.map(\.name), ["research-agent"])
        XCTAssertEqual(tokens[0].scope, ["research"])
        XCTAssertEqual(tokens[0].createdAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(stub.lastRequest(.get, "/v1/api_keys")?.path, "/v1/api_keys?limit=100&workspace=acme")
    }

    func testScopesUnwrapsPrefixes() async throws {
        stub.on(.get, "/v1/api_keys/scopes", json: #"{"prefixes":["research","notebook"]}"#)
        let scopes = try await ApiTokensAdapter(environment: environment, workspace: workspace).scopes()
        XCTAssertEqual(scopes, ["research", "notebook"])
        XCTAssertEqual(stub.lastRequest(.get, "/v1/api_keys/scopes")?.path, "/v1/api_keys/scopes?workspace=acme")
    }

    func testCreateTokenPostsBodyAndDecodesSecret() async throws {
        stub.on(
            .post, "/v1/api_keys", status: 201,
            json: #"""
            {"object":"api_key","id":"api-9","name":"nightly","prefix":"tmp_zz99","created":1788480000,
             "scope":["research:read"],"token":"tmp_zz99secret"}
            """#
        )
        let created = try await ApiTokensAdapter(environment: environment, workspace: workspace)
            .create(ApiTokenCreate(name: "nightly", scope: ["research:read"]))
        XCTAssertEqual(created.token, "tmp_zz99secret")
        let sent = try XCTUnwrap(stub.lastBody(.post, "/v1/api_keys"))
        XCTAssertEqual(sent["name"] as? String, "nightly")
        XCTAssertEqual(sent["scope"] as? [String], ["research:read"])
        XCTAssertNil(sent["expiresAt"])
        XCTAssertEqual(stub.lastRequest(.post, "/v1/api_keys")?.path, "/v1/api_keys?workspace=acme")
    }

    func testRevokeTokenDeletes() async throws {
        stub.on(.delete, "/v1/api_keys/api-1", status: 204, json: "")
        try await ApiTokensAdapter(environment: environment, workspace: workspace).revoke(id: "api-1")
        XCTAssertEqual(stub.lastRequest(.delete, "/v1/api_keys/api-1")?.path, "/v1/api_keys/api-1?workspace=acme")
    }

    // MARK: - Bucket access

    private let groupsPath = "/v1/bucket_access_groups"

    func testGroupsDrainsListEnvelope() async throws {
        stub.on(
            .get, groupsPath,
            json: StubClientTransport.list([#"""
            {"object":"bucket_access_group","id":"g-1","ecosystem_id":"org.acme.shop","bucket_id":"b-profile",
             "name":"everyone","description":"","kind":"everyone"}
            """#])
        )
        let groups = try await BucketAccessAdapter(environment: environment, workspace: workspace).groups()
        XCTAssertEqual(groups.map(\.id), ["g-1"])
        XCTAssertEqual(groups[0].bucketId, "b-profile")
        XCTAssertTrue(groups[0].isEveryone)
        XCTAssertEqual(stub.lastRequest(.get, groupsPath)?.path, "\(groupsPath)?limit=100&workspace=acme")
    }

    func testDetailDecodesMembersAndGrants() async throws {
        stub.on(.get, "\(groupsPath)/g-1", json: #"""
        {"object":"bucket_access_group","id":"g-1","ecosystem_id":"org.acme.shop","bucket_id":"b-profile",
         "name":"Editors","description":"","kind":"custom","created":1788220800,
         "members":[{"id":"m-1","ecosystem_id":"org.acme.shop","access_group_id":"g-1",
                     "member_type":"user","member_id":"user.ada","created":1788220800}],
         "grants":[{"id":"gr-1","ecosystem_id":"org.acme.shop","access_group_id":"g-1",
                    "target_type":"bucket","target_id":"b-profile","crud":"R"}]}
        """#)
        let detail = try await BucketAccessAdapter(environment: environment, workspace: workspace).detail(id: "g-1")
        XCTAssertEqual(detail.group.name, "Editors")
        XCTAssertEqual(detail.createdAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(detail.members.map(\.memberId), ["user.ada"])
        XCTAssertEqual(detail.members.first?.createdAt, "2026-09-01T00:00:00.000Z")
        XCTAssertEqual(detail.grants.map(\.crud), ["R"])
        XCTAssertEqual(stub.lastRequest(.get, "\(groupsPath)/g-1")?.path, "\(groupsPath)/g-1?workspace=acme")
    }

    func testCreateUpdateDeleteGroup() async throws {
        let adapter = BucketAccessAdapter(environment: environment, workspace: workspace)
        stub.on(
            .post, groupsPath, status: 201,
            json: #"""
            {"object":"bucket_access_group","id":"g-2","ecosystem_id":"org.acme.shop","bucket_id":"b-profile",
             "name":"Editors","description":"","kind":"custom"}
            """#
        )
        let created = try await adapter.create(
            bucketID: "b-profile", AccessGroupCreate(name: "Editors", description: "Can edit")
        )
        XCTAssertEqual(created.id, "g-2")
        // The bucket the old route took in its path rides in the body.
        let sent = try XCTUnwrap(stub.lastBody(.post, groupsPath))
        XCTAssertEqual(sent["bucket"] as? String, "b-profile")
        XCTAssertEqual(sent["name"] as? String, "Editors")
        XCTAssertEqual(sent["description"] as? String, "Can edit")
        XCTAssertEqual(stub.lastRequest(.post, groupsPath)?.path, "\(groupsPath)?workspace=acme")

        stub.on(
            .post, "\(groupsPath)/g-2",
            json: #"""
            {"object":"bucket_access_group","id":"g-2","ecosystem_id":"org.acme.shop","bucket_id":"b-profile",
             "name":"Reviewers","description":"","kind":"custom"}
            """#
        )
        let updated = try await adapter.update(id: "g-2", AccessGroupUpdate(name: "Reviewers"))
        XCTAssertEqual(updated.name, "Reviewers")
        let patch = try XCTUnwrap(stub.lastBody(.post, "\(groupsPath)/g-2"))
        XCTAssertEqual(patch["name"] as? String, "Reviewers")
        XCTAssertNil(patch["description"])
        XCTAssertEqual(stub.lastRequest(.post, "\(groupsPath)/g-2")?.path, "\(groupsPath)/g-2?workspace=acme")

        stub.on(.delete, "\(groupsPath)/g-2", status: 204, json: "")
        try await adapter.delete(id: "g-2")
        XCTAssertEqual(stub.lastRequest(.delete, "\(groupsPath)/g-2")?.path, "\(groupsPath)/g-2?workspace=acme")
    }

    func testMembersAddAndRemove() async throws {
        let adapter = BucketAccessAdapter(environment: environment, workspace: workspace)
        stub.on(
            .post, "\(groupsPath)/g-1/members", status: 201,
            json: #"""
            {"id":"m-2","ecosystem_id":"org.acme.shop","access_group_id":"g-1",
             "member_type":"persona","member_id":"persona.me.ada"}
            """#
        )
        let member = try await adapter.addMember(
            groupID: "g-1", AccessMemberAdd(memberType: .persona, memberId: "persona.me.ada")
        )
        XCTAssertEqual(member.type, .persona)
        let sent = try XCTUnwrap(stub.lastBody(.post, "\(groupsPath)/g-1/members"))
        XCTAssertEqual(sent["memberType"] as? String, "persona")
        XCTAssertEqual(sent["memberId"] as? String, "persona.me.ada")
        XCTAssertEqual(
            stub.lastRequest(.post, "\(groupsPath)/g-1/members")?.path, "\(groupsPath)/g-1/members?workspace=acme"
        )

        stub.on(.delete, "\(groupsPath)/g-1/members/m-2", status: 204, json: "")
        try await adapter.removeMember(groupID: "g-1", memberRowID: "m-2")
        XCTAssertEqual(
            stub.lastRequest(.delete, "\(groupsPath)/g-1/members/m-2")?.path,
            "\(groupsPath)/g-1/members/m-2?workspace=acme"
        )
    }

    func testGrantsUpsertAndRemove() async throws {
        let adapter = BucketAccessAdapter(environment: environment, workspace: workspace)
        stub.on(
            .post, "\(groupsPath)/g-1/grants",
            json: #"""
            {"id":"gr-2","ecosystem_id":"org.acme.shop","access_group_id":"g-1",
             "target_type":"bucket_type","target_id":"t-1","crud":"C,R"}
            """#
        )
        let grant = try await adapter.upsertGrant(
            groupID: "g-1", AccessGrantUpsert(targetType: .bucketType, targetId: "t-1", crud: "C,R")
        )
        XCTAssertEqual(grant.target, .bucketType)
        let sent = try XCTUnwrap(stub.lastBody(.post, "\(groupsPath)/g-1/grants"))
        XCTAssertEqual(sent["targetType"] as? String, "bucket_type")
        XCTAssertEqual(sent["crud"] as? String, "C,R")
        XCTAssertEqual(
            stub.lastRequest(.post, "\(groupsPath)/g-1/grants")?.path, "\(groupsPath)/g-1/grants?workspace=acme"
        )

        stub.on(.delete, "\(groupsPath)/g-1/grants/gr-2", status: 204, json: "")
        try await adapter.removeGrant(groupID: "g-1", grantID: "gr-2")
        XCTAssertEqual(
            stub.lastRequest(.delete, "\(groupsPath)/g-1/grants/gr-2")?.path,
            "\(groupsPath)/g-1/grants/gr-2?workspace=acme"
        )
    }

    func testConflictBecomesHubConflict() async throws {
        stub.on(.post, "\(groupsPath)/g-1/members", status: 409, json: StubClientTransport.error("already a member"))
        do {
            _ = try await BucketAccessAdapter(environment: environment, workspace: workspace)
                .addMember(groupID: "g-1", AccessMemberAdd(memberType: .user, memberId: "user.ada"))
            XCTFail("expected conflict")
        } catch HubError.conflict(let message) {
            XCTAssertEqual(message, "already a member")
        }
        XCTAssertEqual(
            stub.lastRequest(.post, "\(groupsPath)/g-1/members")?.path, "\(groupsPath)/g-1/members?workspace=acme"
        )
    }
}
