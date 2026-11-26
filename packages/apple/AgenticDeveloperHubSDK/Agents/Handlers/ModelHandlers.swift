import Foundation

/// The model registry's routes, for a server to mount (roosterd at `/models`).
/// No reply ever carries a secret: a `ModelEntry` names its secret fields only.
///
/// | Route | Reply |
/// |---|---|
/// | `GET` | `[ModelEntry]` |
/// | `POST {entry, secrets?}` → 201 | `ModelEntry`; 409 when the id exists |
/// | `GET <id>` · `PUT <id> {entry, secrets?}` · `DELETE <id>` → 204 | `ModelEntry` |
/// | `POST <id>/test` | `ModelTestResult` |
/// | `GET <id>/models` | `[String]` |
/// | `GET plugins` | `[PluginSummary]` |
/// | `GET resolve?role=` | `ModelEntry`; 404 when no enabled entry holds the role |
public struct ModelHandlers: Sendable {

    private let registry: ModelRegistry

    public init(registry: ModelRegistry) {
        self.registry = registry
    }

    /// `{entry, secrets?}`: `secrets` absent leaves an entry's stored secrets alone.
    struct EntryBody: Decodable {
        var entry: ModelEntry
        var secrets: [String: String]?
    }

    public func handle(_ request: HandlerRequest) async -> HandlerResponse {
        do {
            return try await route(request)
        } catch let error as ModelRegistryError {
            return Self.response(for: error)
        } catch let error as DecodingError {
            return HandlerError.badRequest("Malformed body: \(HandlerError.describe(error))")
        } catch {
            return HandlerError.failure(error)
        }
    }

    private func route(_ request: HandlerRequest) async throws -> HandlerResponse {
        let path = request.path
        switch (request.method, path.first, path.count) {
        case ("GET", nil, 0):
            return .encoded(try registry.list())
        case ("POST", nil, 0):
            // The registry's create checks for the id and inserts in one
            // transaction, so concurrent creates answer one 201 and 409s.
            let body = try AgentsJSON.decode(EntryBody.self, from: request.body)
            return .encoded(try registry.create(body.entry, secrets: body.secrets), status: 201)
        case ("GET", "plugins", 1):
            return .encoded(await registry.plugins())
        case ("GET", "resolve", 1):
            guard let role = request.query["role"], !role.isEmpty else {
                return HandlerError.badRequest("`role` is required")
            }
            guard let entry = try registry.resolve(role: role) else {
                return HandlerError.notFound("No enabled model entry has the role '\(role)'")
            }
            return .encoded(entry)
        default:
            return try await entryRoute(request)
        }
    }

    private func entryRoute(_ request: HandlerRequest) async throws -> HandlerResponse {
        let path = request.path
        guard let first = path.first, let id = UUID(uuidString: first) else { return HandlerError.noRoute }
        switch (request.method, path.count > 1 ? path[1] : nil, path.count) {
        case ("GET", nil, 1):
            guard let entry = try registry.get(id) else { throw ModelRegistryError.notFound(id) }
            return .encoded(entry)
        case ("PUT", nil, 1):
            let body = try AgentsJSON.decode(EntryBody.self, from: request.body)
            guard body.entry.id == id else {
                return HandlerError.badRequest("The entry's id does not match the path's \(id.uuidString)")
            }
            guard try registry.get(id) != nil else { throw ModelRegistryError.notFound(id) }
            try registry.upsert(body.entry, secrets: body.secrets)
            return .encoded(try registry.get(id))
        case ("DELETE", nil, 1):
            guard try registry.get(id) != nil else { throw ModelRegistryError.notFound(id) }
            try registry.remove(id)
            return .empty(204)
        case ("POST", "test", 2):
            guard try registry.get(id) != nil else { throw ModelRegistryError.notFound(id) }
            return .encoded(await registry.test(id))
        case ("GET", "models", 2):
            return .encoded(try await registry.listModels(id))
        default:
            return HandlerError.noRoute
        }
    }

    static func response(for error: ModelRegistryError) -> HandlerResponse {
        switch error {
        case .notFound:
            return HandlerError.notFound(error.localizedDescription)
        case .invalidEntry:
            return HandlerError.badRequest(error.localizedDescription)
        case .pluginNotInstalled, .unknownTemplate, .pluginIncompatible:
            return HandlerError.unprocessable(error.localizedDescription)
        case .duplicate:
            return HandlerError.conflict(error.localizedDescription)
        }
    }
}
