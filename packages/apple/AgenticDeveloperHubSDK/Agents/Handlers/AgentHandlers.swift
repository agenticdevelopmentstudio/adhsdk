import Foundation

/// The agent host's routes, for a server to mount (roosterd at `/agent`):
///
/// | Route | Reply |
/// |---|---|
/// | `GET agents` · `GET agents/<id>` · `PUT agents/<id>` | `AgentDefinition` (list, one, saved) |
/// | `GET sessions[?agent=]` · `POST sessions {agent, title?}` → 201 | `AgentSessionInfo` |
/// | `GET sessions/<id>` · `DELETE sessions/<id>` → 204 | `AgentSessionDetail` |
/// | `POST sessions/<id>/messages {text}` | `.events` for the turn |
/// | `GET sessions/<id>/events` | `.events`, live tail |
/// | `POST sessions/<id>/interrupt` → 202 | |
/// | `GET tools` | `[{name, description, input_schema, permission, mutating}]` |
/// | `POST tools/<name> {arguments, caller}` | `ToolOutcome`; 404 unknown tool, 422 a thrown tool error |
public struct AgentHandlers: Sendable {

    /// The caller a tool sees when a `POST tools/<name>` names none.
    public static let defaultToolCaller = "external"

    private let host: AgentHost

    public init(host: AgentHost) {
        self.host = host
    }

    public func handle(_ request: HandlerRequest) async -> HandlerResponse {
        do {
            return try await route(request)
        } catch let error as AgentHostError {
            return Self.response(for: error)
        } catch let error as DecodingError {
            return HandlerError.badRequest("Malformed body: \(HandlerError.describe(error))")
        } catch {
            return HandlerError.failure(error)
        }
    }

    private func route(_ request: HandlerRequest) async throws -> HandlerResponse {
        switch (request.method, request.path.first) {
        case (_, "agents"): return try await agents(request)
        case (_, "sessions"): return try await sessions(request)
        case (_, "tools"): return try await tools(request)
        default: return HandlerError.noRoute
        }
    }

    // MARK: - agents

    private func agents(_ request: HandlerRequest) async throws -> HandlerResponse {
        let path = request.path
        switch (request.method, path.count) {
        case ("GET", 1):
            return .encoded(try await host.agents())
        case ("GET", 2):
            guard let agent = try await host.agent(path[1]) else {
                return HandlerError.notFound("No agent with id '\(path[1])'")
            }
            return .encoded(agent)
        case ("PUT", 2):
            guard var object = request.jsonObject() else { return HandlerError.badRequest("Expected a JSON object") }
            if let bodyId = object["id"] as? String, bodyId != path[1] {
                return HandlerError.badRequest("The body's id '\(bodyId)' does not match the path's '\(path[1])'")
            }
            object["id"] = path[1]
            let data = try JSONSerialization.data(withJSONObject: object)
            let agent = try AgentsJSON.decode(AgentDefinition.self, from: data)
            try await host.save(agent)
            return .encoded(agent)
        default:
            return HandlerError.noRoute
        }
    }

    // MARK: - sessions

    private struct NewSession: Decodable {
        var agent: String
        var title: String?
    }

    private struct NewMessage: Decodable {
        var text: String
    }

    private func sessions(_ request: HandlerRequest) async throws -> HandlerResponse {
        let path = request.path
        if path.count == 1 {
            switch request.method {
            case "GET":
                return .encoded(try await host.sessions(agentId: request.query["agent"]))
            case "POST":
                let body = try AgentsJSON.decode(NewSession.self, from: request.body)
                return .encoded(try await host.createSession(agentId: body.agent, title: body.title), status: 201)
            default:
                return HandlerError.noRoute
            }
        }
        guard let id = UUID(uuidString: path[1]) else {
            return HandlerError.notFound("No session with id '\(path[1])'")
        }
        switch (request.method, path.count > 2 ? path[2] : nil) {
        case ("GET", nil):
            guard let detail = try await host.session(id) else { throw AgentHostError.sessionNotFound(id) }
            return .encoded(detail)
        case ("DELETE", nil):
            guard try await host.session(id) != nil else { throw AgentHostError.sessionNotFound(id) }
            try await host.deleteSession(id)
            return .empty(204)
        case ("POST", "messages"):
            let body = try AgentsJSON.decode(NewMessage.self, from: request.body)
            guard !body.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return HandlerError.badRequest("The message text is empty")
            }
            return .events(try await host.send(body.text, to: id))
        case ("GET", "events"):
            guard try await host.session(id) != nil else { throw AgentHostError.sessionNotFound(id) }
            return .events(await host.events(id))
        case ("POST", "interrupt"):
            guard try await host.session(id) != nil else { throw AgentHostError.sessionNotFound(id) }
            await host.interrupt(id)
            return .empty(202)
        default:
            return HandlerError.noRoute
        }
    }

    // MARK: - tools

    private func tools(_ request: HandlerRequest) async throws -> HandlerResponse {
        let path = request.path
        switch (request.method, path.count) {
        case ("GET", 1):
            let list = host.tools.map(Self.toolInfo)
            let data = try JSONSerialization.data(withJSONObject: list, options: [.sortedKeys, .withoutEscapingSlashes])
            return .json(status: 200, body: data)
        case ("POST", 2):
            let name = path[1]
            guard host.tools.contains(where: { $0.name == name }) else {
                return HandlerError.notFound("Unknown tool '\(name)'")
            }
            guard let object = request.jsonObject() else { return HandlerError.badRequest("Expected a JSON object") }
            guard let arguments = Self.argumentsJSON(object["arguments"]) else {
                return HandlerError.badRequest("`arguments` must be a JSON object or a string holding one")
            }
            let caller = (object["caller"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? Self.defaultToolCaller
            do {
                let context = ToolCallContext(caller: caller)
                let outcome = try await host.runTool(name, argumentsJSON: arguments, context: context)
                return .encoded(outcome)
            } catch let error as AgentToolError {
                if case .invalidArguments = error { return HandlerError.badRequest(error.localizedDescription) }
                return HandlerError.notFound(error.localizedDescription)
            } catch {
                return HandlerError.unprocessable(error.localizedDescription)
            }
        default:
            return HandlerError.noRoute
        }
    }

    /// `{name, description, input_schema, permission, mutating}`, the schema as
    /// a JSON object (an empty object when the tool's is not valid JSON).
    static func toolInfo(_ tool: any AgentTool) -> [String: Any] {
        let schema = (try? JSONSerialization.jsonObject(with: Data(tool.inputSchemaJSON.utf8))) ?? [String: Any]()
        return [
            "name": tool.name,
            "description": tool.description,
            "input_schema": schema,
            "permission": tool.permissionDefault.rawValue,
            "mutating": tool.isMutating
        ]
    }

    /// A tool's arguments from a request body: an object (re-encoded), a string
    /// holding JSON, or absent (`{}`).
    static func argumentsJSON(_ value: Any?) -> String? {
        switch value {
        case nil, is NSNull:
            return "{}"
        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (try? JSONSerialization.jsonObject(with: Data(trimmed.utf8))) is [String: Any] else { return nil }
            return trimmed
        case let object as [String: Any]:
            guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
                return nil
            }
            return String(bytes: data, encoding: .utf8)
        default:
            return nil
        }
    }

    // MARK: - Errors

    static func response(for error: AgentHostError) -> HandlerResponse {
        switch error {
        case .agentNotFound, .sessionNotFound:
            return HandlerError.notFound(error.localizedDescription)
        case .agentDisabled, .turnInProgress:
            return HandlerError.conflict(error.localizedDescription)
        case .invalidAgent:
            return HandlerError.badRequest(error.localizedDescription)
        }
    }
}
