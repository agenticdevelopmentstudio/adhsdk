import AgenticDeveloperHubSDKHub
import Foundation
import HTTPTypes

@MainActor
public final class ApplicationsAdapter: ApplicationsDataSource {
    private struct RenameBody: Encodable { let rdid: String }
    private struct TokenCreateBody: Encodable { let name: String }

    // MARK: Schema-grant wire shape
    //
    // The API speaks `{schemaId, crud, tables: [{tableId, crud}]}` — `crud`, not `permissions`, and
    // `tables` an ARRAY keyed by the table's id. The domain type (`SchemaGrant`) keeps the dictionary
    // the UI wants; the conversion lives here, mirroring the web client's `getGrants`/`putGrants`.

    private struct TableGrantWire: Codable {
        var tableId: String
        var crud: String
    }

    private struct SchemaGrantWire: Codable {
        var schemaId: String
        var crud: String
        var tables: [TableGrantWire]
    }

    private struct GrantsEnvelope: Codable { var grants: [SchemaGrantWire] }

    /// The application with its `schema_grants` sub-resource (`?include[]=schema_grants`).
    private struct WithGrants: Decodable { var schemaGrants: GrantsEnvelope? }

    /// A POST whose only key names the `schema_grants` include updates that sub-resource alone.
    private struct GrantsUpdate: Encodable {
        var schemaGrants: GrantsEnvelope
        enum CodingKeys: String, CodingKey { case schemaGrants = "schema_grants" }
    }

    private static func domain(_ wire: SchemaGrantWire) -> SchemaGrant {
        var tables: [String: TableGrant] = [:]
        for table in wire.tables {
            tables[table.tableId] = TableGrant(level: "table", permissions: table.crud)
        }
        return SchemaGrant(schemaId: wire.schemaId, permissions: wire.crud, tables: tables)
    }

    /// `level` is UI-only and is not sent. Tables with no permissions carry no grant row, as the web does.
    private static func wire(_ grant: SchemaGrant) -> SchemaGrantWire {
        let tables = grant.tables
            .map { TableGrantWire(tableId: $0.key, crud: $0.value.permissions) }
            .filter { !$0.crud.isEmpty }
            .sorted { $0.tableId < $1.tableId }
        return SchemaGrantWire(schemaId: grant.schemaId, crud: grant.permissions, tables: tables)
    }

    private let api: HubAPI
    private let workspace: HubWorkspace

    public init(environment: HubEnvironment, workspace: HubWorkspace) {
        self.api = HubAPI(environment: environment)
        self.workspace = workspace
    }

    public func list(ecosystemID: String) async throws -> [Application] {
        try await api.list("/v1/applications", query: workspace.query, as: Application.self)
            .filter { $0.ecosystemId == ecosystemID }
    }

    public func get(id: String) async throws -> Application {
        try await api.get("/v1/applications/\(id)", query: workspace.query, as: Application.self)
    }

    public func create(_ input: ApplicationCreate) async throws -> Application {
        try await api.send(.post, "/v1/applications", query: workspace.query, body: input, as: Application.self)
    }

    public func update(id: String, _ input: ApplicationUpdate) async throws -> Application {
        try await api.send(
            .post, "/v1/applications/\(id)", query: workspace.query, body: input, as: Application.self
        )
    }

    public func delete(id: String) async throws {
        try await api.send(.delete, "/v1/applications/\(id)", query: workspace.query)
    }

    public func renameIdentifier(_ identifier: String, to next: String) async throws {
        try await api.send(.post, "/v1/identifiers/\(identifier)", query: [:], body: RenameBody(rdid: next))
    }

    public func schemaGrants(applicationID: String) async throws -> [SchemaGrant] {
        var query = workspace.query
        query["include[]"] = "schema_grants"
        let application = try await api.get("/v1/applications/\(applicationID)", query: query, as: WithGrants.self)
        guard let envelope = application.schemaGrants else {
            throw HubError.unexpected("GET /v1/applications/\(applicationID) did not include schema_grants")
        }
        return envelope.grants.map(Self.domain)
    }

    public func setSchemaGrants(applicationID: String, _ grants: [SchemaGrant]) async throws {
        try await api.send(
            .post, "/v1/applications/\(applicationID)",
            query: workspace.query, body: GrantsUpdate(schemaGrants: GrantsEnvelope(grants: grants.map(Self.wire)))
        )
    }

    public func tokens(applicationID: String) async throws -> [ApplicationToken] {
        try await api.list(
            "/v1/applications/\(applicationID)/tokens", query: workspace.query, as: ApplicationToken.self
        )
    }

    public func createToken(applicationID: String, name: String) async throws -> ApplicationTokenCreated {
        try await api.send(
            .post, "/v1/applications/\(applicationID)/tokens",
            query: workspace.query, body: TokenCreateBody(name: name), as: ApplicationTokenCreated.self
        )
    }

    public func revokeToken(applicationID: String, tokenID: String) async throws {
        try await api.send(
            .delete, "/v1/applications/\(applicationID)/tokens/\(tokenID)", query: workspace.query
        )
    }
}
