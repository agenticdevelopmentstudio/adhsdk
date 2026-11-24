import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `/v1/api_keys` — the caller's personal API tokens.
@MainActor
public final class ApiTokensAdapter: ApiTokensDataSource {
    private struct ScopeCatalogue: Decodable { let prefixes: [String] }

    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func list() async throws -> [ApiToken] {
        try await api.list("/v1/api_keys", query: workspace.query, as: ApiToken.self)
    }

    public func scopes() async throws -> [String] {
        try await api.get("/v1/api_keys/scopes", query: workspace.query, as: ScopeCatalogue.self).prefixes
    }

    public func create(_ body: ApiTokenCreate) async throws -> ApiTokenCreated {
        try await api.send(.post, "/v1/api_keys", query: workspace.query, body: body, as: ApiTokenCreated.self)
    }

    public func revoke(id: String) async throws {
        try await api.send(.delete, "/v1/api_keys/\(id)", query: workspace.query)
    }
}
