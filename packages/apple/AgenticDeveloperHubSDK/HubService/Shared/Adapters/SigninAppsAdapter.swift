import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

/// `SigninAppsDataSource` over `/v1/ecosystems/{id}/signin_apps`.
@MainActor
public final class SigninAppsAdapter: SigninAppsDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    private func path(_ ecosystemID: String, _ id: String? = nil) -> String {
        id.map { "/v1/ecosystems/\(ecosystemID)/signin_apps/\($0)" } ?? "/v1/ecosystems/\(ecosystemID)/signin_apps"
    }

    public func list(ecosystemID: String) async throws -> [SigninApp] {
        try await api.list(path(ecosystemID), query: workspace.query, as: SigninApp.self)
    }

    public func create(ecosystemID: String, _ body: SigninAppCreate) async throws -> SigninApp {
        try await api.send(.post, path(ecosystemID), query: workspace.query, body: body, as: SigninApp.self)
    }

    public func update(ecosystemID: String, id: String, _ body: SigninAppUpdate) async throws -> SigninApp {
        try await api.send(.post, path(ecosystemID, id), query: workspace.query, body: body, as: SigninApp.self)
    }

    public func delete(ecosystemID: String, id: String) async throws {
        try await api.send(.delete, path(ecosystemID, id), query: workspace.query)
    }
}
