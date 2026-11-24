import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `ServerBags` over `/v1/server_bag`, scoped by `ecosystem` (a query key, or a body field on create).
/// Rows are keyed by `key` and carry no `id`, so the list is the one widest page `/v1` serves.
@MainActor
public final class ServerBagsAdapter: ServerBagsDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    /// The workspace query plus the ecosystem the old route took in its path.
    private func query(_ ecosystemID: String) -> [String: String] {
        workspace.query.merging(["ecosystem": ecosystemID]) { _, new in new }
    }

    public func list(ecosystemID: String) async throws -> [ServerBag] {
        try await api.list("/v1/server_bag", query: query(ecosystemID), as: ServerBag.self)
    }

    public func create(ecosystemID: String, _ body: ServerBagCreate) async throws -> ServerBag {
        try await api.send(
            .post, "/v1/server_bag", query: workspace.query,
            body: HubAPI.body(body, adding: ["ecosystem": ecosystemID]), as: ServerBag.self
        )
    }

    public func update(ecosystemID: String, key: String, _ body: ServerBagUpdate) async throws -> ServerBag {
        try await api.send(
            .post, "/v1/server_bag/\(key)", query: workspace.query,
            body: HubAPI.body(body, adding: ["ecosystem": ecosystemID]), as: ServerBag.self
        )
    }

    public func delete(ecosystemID: String, key: String) async throws {
        try await api.send(.delete, "/v1/server_bag/\(key)", query: query(ecosystemID))
    }
}
