import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

@MainActor
public final class PersonasAdapter: PersonasDataSource {
    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func list() async throws -> [Persona] {
        try await api.list("/v1/personas", query: workspace.query, as: Persona.self)
    }

    public func get(id: String) async throws -> Persona {
        try await api.get("/v1/personas/\(id)", query: workspace.query, as: Persona.self)
    }

    public func create(_ body: PersonaBody) async throws -> Persona {
        try await api.send(.post, "/v1/personas", query: workspace.query, body: body, as: Persona.self)
    }

    public func update(id: String, _ body: PersonaBody) async throws -> Persona {
        try await api.send(.post, "/v1/personas/\(id)", query: workspace.query, body: body, as: Persona.self)
    }

    public func delete(id: String) async throws {
        try await api.send(.delete, "/v1/personas/\(id)", query: workspace.query)
    }

    public func listServices() async throws -> [PersonaService] {
        try await api.list("/v1/ai_services", as: PersonaService.self)
    }
}
