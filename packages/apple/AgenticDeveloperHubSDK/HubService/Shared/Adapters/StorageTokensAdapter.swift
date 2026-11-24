import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `StorageTokensDataSource` over `/tokens`. `ecosystemId` is sent as a query key (and mirrored into the
/// create body) only when the caller scopes to an ecosystem.
///
/// List and create stay on the unversioned `/tokens`. Its `/v1` home is `/v1/api_keys`, which it shares
/// with the personal API tokens (`/auth/tokens`): both variants rank equally and the personal one is
/// listed first, so the gateway serves every `GET`/`POST /v1/api_keys` from `/auth/tokens`, and a
/// storage token can be neither listed nor minted through `/v1`. Revoke does move: `DELETE
/// /v1/api_keys/{id}` tries `/auth/tokens/{id}` first, which answers 404 for an id that is not a personal
/// token, and the gateway then falls through to `/tokens/{id}`.
@MainActor
public final class StorageTokensAdapter: StorageTokensDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    private func query(_ ecosystemID: String?) -> [String: String] {
        workspace.query.merging(HubAPI.query(["ecosystemId": ecosystemID])) { _, new in new }
    }

    public func list(ecosystemID: String?) async throws -> [StorageToken] {
        try await api.get("/tokens", query: query(ecosystemID), as: [StorageToken].self)
    }

    public func create(ecosystemID: String?, _ body: StorageTokenCreate) async throws -> StorageTokenCreated {
        var body = body
        body.ecosystemId = ecosystemID ?? body.ecosystemId
        return try await api.send(.post, "/tokens", query: query(ecosystemID), body: body, as: StorageTokenCreated.self)
    }

    /// Workspace only. `ecosystemId` is a LIST filter — it selects which tokens come back — and the
    /// token id in the path already identifies exactly one row. Sending it on a DELETE asked the server
    /// to filter a single-row delete, which either does nothing or, if the server validates it, rejects
    /// the revoke when the caller is standing in a different ecosystem than the token was minted in.
    public func revoke(ecosystemID _: String?, id: String) async throws {
        try await api.send(.delete, "/v1/api_keys/\(id)", query: workspace.query)
    }
}
