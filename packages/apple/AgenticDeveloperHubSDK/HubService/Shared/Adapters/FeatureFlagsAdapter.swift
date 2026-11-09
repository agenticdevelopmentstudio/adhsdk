import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `FeatureFlags` over `/v1/feature_flags`, scoped by `ecosystem` (a query key, or a body field on create).
/// Rows are keyed by `key` and carry no `id`, so the list is the one widest page `/v1` serves.
@MainActor
public final class FeatureFlagsAdapter: FeatureFlagsDataSource {
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

    public func list(ecosystemID: String) async throws -> [FeatureFlag] {
        try await api.list("/v1/feature_flags", query: query(ecosystemID), as: FeatureFlag.self)
    }

    public func create(ecosystemID: String, _ body: FeatureFlagCreate) async throws -> FeatureFlag {
        try await api.send(
            .post, "/v1/feature_flags", query: workspace.query,
            body: HubAPI.body(body, adding: ["ecosystem": ecosystemID]), as: FeatureFlag.self
        )
    }

    public func update(ecosystemID: String, key: String, _ body: FeatureFlagUpdate) async throws -> FeatureFlag {
        try await api.send(
            .post, "/v1/feature_flags/\(key)", query: workspace.query,
            body: HubAPI.body(body, adding: ["ecosystem": ecosystemID]), as: FeatureFlag.self
        )
    }

    public func delete(ecosystemID: String, key: String) async throws {
        try await api.send(.delete, "/v1/feature_flags/\(key)", query: query(ecosystemID))
    }
}
