import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `/v1/bucket_access_groups` — access lists, their members and their grants.
@MainActor
public final class BucketAccessAdapter: BucketAccessDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func groups() async throws -> [AccessGroup] {
        try await api.list("/v1/bucket_access_groups", query: workspace.query, as: AccessGroup.self)
    }

    public func detail(id: String) async throws -> AccessGroupDetail {
        try await api.get("/v1/bucket_access_groups/\(id)", query: workspace.query, as: AccessGroupDetail.self)
    }

    public func create(bucketID: String, _ body: AccessGroupCreate) async throws -> AccessGroup {
        try await api.send(
            .post, "/v1/bucket_access_groups", query: workspace.query,
            body: HubAPI.body(body, adding: ["bucket": bucketID]), as: AccessGroup.self
        )
    }

    public func update(id: String, _ body: AccessGroupUpdate) async throws -> AccessGroup {
        try await api.send(
            .post, "/v1/bucket_access_groups/\(id)", query: workspace.query, body: body, as: AccessGroup.self
        )
    }

    public func delete(id: String) async throws {
        try await api.send(.delete, "/v1/bucket_access_groups/\(id)", query: workspace.query)
    }

    public func addMember(groupID: String, _ body: AccessMemberAdd) async throws -> AccessGroupMember {
        try await api.send(
            .post, "/v1/bucket_access_groups/\(groupID)/members",
            query: workspace.query, body: body, as: AccessGroupMember.self
        )
    }

    public func removeMember(groupID: String, memberRowID: String) async throws {
        try await api.send(
            .delete, "/v1/bucket_access_groups/\(groupID)/members/\(memberRowID)", query: workspace.query
        )
    }

    public func upsertGrant(groupID: String, _ body: AccessGrantUpsert) async throws -> AccessGrant {
        try await api.send(
            .post, "/v1/bucket_access_groups/\(groupID)/grants", query: workspace.query,
            body: body, as: AccessGrant.self
        )
    }

    public func removeGrant(groupID: String, grantID: String) async throws {
        try await api.send(
            .delete, "/v1/bucket_access_groups/\(groupID)/grants/\(grantID)", query: workspace.query
        )
    }
}
