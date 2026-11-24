import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

@MainActor
public final class CustomersAdapter: CustomersDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func list(ecosystemID: String) async throws -> [Customer] {
        try await api.list("/v1/customers", query: workspace.query, as: Customer.self)
            .filter { $0.ecosystemId == ecosystemID }
    }

    public func get(id: String) async throws -> Customer {
        try await api.get("/v1/customers/\(id)", query: workspace.query, as: Customer.self)
    }

    public func create(_ input: CustomerInput) async throws -> Customer {
        try await api.send(.post, "/v1/customers", query: workspace.query, body: input, as: Customer.self)
    }

    public func update(id: String, _ input: CustomerInput) async throws -> Customer {
        try await api.send(.post, "/v1/customers/\(id)", query: workspace.query, body: input, as: Customer.self)
    }

    public func delete(id: String) async throws {
        try await api.send(.delete, "/v1/customers/\(id)", query: workspace.query)
    }
}
