import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `AuthSettingsDataSource` over the ecosystem's `auth_settings` sub-resource:
/// `GET /v1/ecosystems/{id}?include[]=auth_settings`, and a `POST /v1/ecosystems/{id}` whose only
/// key is `auth_settings` (which updates that sub-resource alone).
@MainActor
public final class AuthSettingsAdapter: AuthSettingsDataSource {
    private struct WithAuthSettings: Decodable { let authSettings: AuthSettings? }

    private struct Update: Encodable {
        let authSettings: AuthSettingsUpdate
        enum CodingKeys: String, CodingKey { case authSettings = "auth_settings" }
    }

    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func get(ecosystemID: String) async throws -> AuthSettings {
        var query = workspace.query
        query["include[]"] = "auth_settings"
        return try Self.settings(
            in: try await api.get("/v1/ecosystems/\(ecosystemID)", query: query, as: WithAuthSettings.self),
            ecosystemID: ecosystemID
        )
    }

    public func update(ecosystemID: String, _ patch: AuthSettingsUpdate) async throws -> AuthSettings {
        try Self.settings(
            in: try await api.send(
                .post, "/v1/ecosystems/\(ecosystemID)", query: workspace.query,
                body: Update(authSettings: patch), as: WithAuthSettings.self
            ),
            ecosystemID: ecosystemID
        )
    }

    private static func settings(in ecosystem: WithAuthSettings, ecosystemID: String) throws -> AuthSettings {
        guard let settings = ecosystem.authSettings else {
            throw HubError.unexpected("/v1/ecosystems/\(ecosystemID) did not include auth_settings")
        }
        return settings
    }
}
