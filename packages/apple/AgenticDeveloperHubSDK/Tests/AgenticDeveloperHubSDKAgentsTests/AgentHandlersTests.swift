// Tests/AgenticDeveloperHubSDKAgentsTests/AgentHandlersTests.swift
import Testing
import Foundation
import AIPluginKit
@testable import AgenticDeveloperHubSDKAgents

/// The JSON body of a reply, or a recorded issue when the reply is a stream.
func body(_ response: HandlerResponse) -> Data {
    guard case .json(_, let data) = response else {
        Issue.record("Expected a JSON reply, got an event stream")
        return Data()
    }
    return data
}

func errorCode(_ response: HandlerResponse) -> String? {
    (try? AgentsJSON.decode(HandlerError.self, from: body(response)))?.error
}

func jsonBody(_ object: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: object)
}

@Suite("HandlerRequest")
struct HandlerRequestTests {

    @Test("a string path splits into percent-decoded segments")
    func segments() {
        let request = HandlerRequest(method: "get", path: "/tools//my%20tool/")
        #expect(request.method == "GET")
        #expect(request.path == ["tools", "my tool"])
    }

    @Test("an error reply carries the code and the message")
    func errorBody() throws {
        let response = HandlerResponse.error(409, HandlerError.conflictCode, "Busy")
        #expect(response.status == 409)
        let decoded = try AgentsJSON.decode(HandlerError.self, from: body(response))
        #expect(decoded == HandlerError(error: "conflict", message: "Busy"))
    }
}

@Suite("AgentHandlers")
struct AgentHandlersTests {

    private func makeHandlers(script: ScriptedRuntime = ScriptedRuntime()) throws -> (AgentHandlers, AgentHost) {
        let host = try makeHost(script: script)
        return (AgentHandlers(host: host), host)
    }

    @Test("lists and fetches agents")
    func agents() async throws {
        let (handlers, _) = try makeHandlers()
        let list = await handlers.handle(HandlerRequest(method: "GET", path: "agents"))
        #expect(list.status == 200)
        #expect(try AgentsJSON.decode([AgentDefinition].self, from: body(list)).map(\.id) == ["helper"])
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "agents/helper")).status == 200)
        let missing = await handlers.handle(HandlerRequest(method: "GET", path: "agents/ghost"))
        #expect(missing.status == 404)
        #expect(errorCode(missing) == "not_found")
    }

    @Test("PUT takes the id from the path and refuses a different one in the body")
    func putAgent() async throws {
        let (handlers, host) = try makeHandlers()
        let saved = await handlers.handle(HandlerRequest(
            method: "PUT", path: "agents/writer",
            body: try jsonBody(["name": "Writer", "prompt": "Write.", "model": ["type": "role", "role": "smart"]])))
        #expect(saved.status == 200)
        #expect(try await host.agent("writer")?.name == "Writer")

        let mismatch = await handlers.handle(HandlerRequest(
            method: "PUT", path: "agents/writer",
            body: try jsonBody(["id": "other", "name": "W", "prompt": "", "model": ["type": "role", "role": "x"]])))
        #expect(mismatch.status == 400)

        let malformed = await handlers.handle(HandlerRequest(
            method: "PUT", path: "agents/writer", body: try jsonBody(["name": "W"])))
        #expect(malformed.status == 400)
    }

    @Test("creates, reads and deletes a session")
    func sessionLifecycle() async throws {
        let (handlers, _) = try makeHandlers()
        let created = await handlers.handle(HandlerRequest(
            method: "POST", path: "sessions", body: try jsonBody(["agent": "helper", "title": "T"])))
        #expect(created.status == 201)
        let info = try AgentsJSON.decode(AgentSessionInfo.self, from: body(created))
        #expect(info.title == "T")

        let listed = await handlers.handle(HandlerRequest(method: "GET", path: "sessions", query: ["agent": "helper"]))
        #expect(try AgentsJSON.decode([AgentSessionInfo].self, from: body(listed)).map(\.id) == [info.id])

        let detail = await handlers.handle(HandlerRequest(method: "GET", path: "sessions/\(info.id.uuidString)"))
        #expect(try AgentsJSON.decode(AgentSessionDetail.self, from: body(detail)).info.id == info.id)

        let deleted = await handlers.handle(HandlerRequest(method: "DELETE", path: "sessions/\(info.id.uuidString)"))
        #expect(deleted.status == 204)
        let again = await handlers.handle(HandlerRequest(method: "DELETE", path: "sessions/\(info.id.uuidString)"))
        #expect(again.status == 404)
    }

    @Test("session errors: unknown agent, unknown or malformed id, empty message")
    func sessionErrors() async throws {
        let (handlers, host) = try makeHandlers()
        let ghost = await handlers.handle(HandlerRequest(
            method: "POST", path: "sessions", body: try jsonBody(["agent": "ghost"])))
        #expect(ghost.status == 404)
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "sessions/not-a-uuid")).status == 404)
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "sessions/\(UUID().uuidString)")).status
            == 404)

        let session = try await host.createSession(agentId: "helper", title: nil)
        let empty = await handlers.handle(HandlerRequest(
            method: "POST", path: "sessions/\(session.id.uuidString)/messages", body: try jsonBody(["text": "  "])))
        #expect(empty.status == 400)
        let noText = await handlers.handle(HandlerRequest(
            method: "POST", path: "sessions/\(session.id.uuidString)/messages", body: try jsonBody([:])))
        #expect(noText.status == 400)
    }

    @Test("a message answers with the turn's event stream")
    func messageStreams() async throws {
        let script = ScriptedRuntime(rounds: [[.textDelta("Hi"), .end(stopReason: "end_turn")]])
        let (handlers, host) = try makeHandlers(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let response = await handlers.handle(HandlerRequest(
            method: "POST", path: "sessions/\(session.id.uuidString)/messages", body: try jsonBody(["text": "Hello"])))
        guard case .events(let stream) = response else {
            Issue.record("Expected an event stream")
            return
        }
        #expect(await collect(stream).map(\.event) == [.textDelta("Hi"), .turnFinished(stopReason: "end_turn")])
    }

    @Test("interrupt answers 202; a busy session answers 409")
    func interruptAndConflict() async throws {
        let script = ScriptedRuntime(hang: true)
        let (handlers, host) = try makeHandlers(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let path = "sessions/\(session.id.uuidString)"
        let first = await handlers.handle(HandlerRequest(
            method: "POST", path: "\(path)/messages", body: try jsonBody(["text": "Hello"])))
        let busy = await handlers.handle(HandlerRequest(
            method: "POST", path: "\(path)/messages", body: try jsonBody(["text": "Again"])))
        #expect(busy.status == 409)
        #expect(await handlers.handle(HandlerRequest(method: "POST", path: "\(path)/interrupt")).status == 202)
        if case .events(let stream) = first {
            #expect(await collect(stream).last?.event == .turnFinished(stopReason: "interrupted"))
        }
    }

    @Test("lists tools with their schema as an object")
    func listsTools() async throws {
        let (handlers, _) = try makeHandlers()
        let response = await handlers.handle(HandlerRequest(method: "GET", path: "tools"))
        let list = try #require(try JSONSerialization.jsonObject(with: body(response)) as? [[String: Any]])
        #expect(list.compactMap { $0["name"] as? String } == ["echo", "bump", "broken"])
        #expect(list[0]["input_schema"] is [String: Any])
        #expect(list[1]["mutating"] as? Bool == true)
        #expect(list[1]["permission"] as? String == "ask")
    }

    @Test("runs a tool: object or string arguments, the caller passed on")
    func runsTool() async throws {
        let (handlers, _) = try makeHandlers()
        let byObject = await handlers.handle(HandlerRequest(
            method: "POST", path: "tools/echo", body: try jsonBody(["arguments": ["text": "x"], "caller": "cli"])))
        let outcome = try AgentsJSON.decode(ToolOutcome.self, from: body(byObject))
        #expect(outcome.resultJSON.contains(#""caller":"cli""#))
        #expect(outcome.resultJSON.contains(#""text":"x""#))

        let byString = await handlers.handle(HandlerRequest(
            method: "POST", path: "tools/echo", body: try jsonBody(["arguments": #"{"text":"y"}"#])))
        let fromString = try AgentsJSON.decode(ToolOutcome.self, from: body(byString))
        #expect(fromString.resultJSON.contains(#""caller":"external""#))

        let bad = await handlers.handle(HandlerRequest(
            method: "POST", path: "tools/echo", body: try jsonBody(["arguments": "not json"])))
        #expect(bad.status == 400)
    }

    @Test("an unknown tool is 404; a thrown tool error is 422")
    func toolErrors() async throws {
        let (handlers, _) = try makeHandlers()
        #expect(await handlers.handle(HandlerRequest(method: "POST", path: "tools/nope")).status == 404)
        let broken = await handlers.handle(HandlerRequest(method: "POST", path: "tools/broken"))
        #expect(broken.status == 422)
        #expect(errorCode(broken) == "unprocessable")
    }

    @Test("an unknown route is 404")
    func noRoute() async throws {
        let (handlers, _) = try makeHandlers()
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "nowhere")).status == 404)
        #expect(await handlers.handle(HandlerRequest(method: "PATCH", path: "agents")).status == 404)
    }
}

@Suite("ModelHandlers")
struct ModelHandlersTests {

    private func entryBody(_ entry: ModelEntry, secrets: [String: String]? = nil) throws -> Data {
        var object: [String: Any] = [
            "entry": try JSONSerialization.jsonObject(with: AgentsJSON.encode(entry))
        ]
        if let secrets { object["secrets"] = secrets }
        return try jsonBody(object)
    }

    @Test("POST creates an entry (201) and refuses an existing id (409)")
    func create() async throws {
        let secrets = FakeModelSecrets()
        let handlers = ModelHandlers(registry: try makeRegistry(secrets: secrets))
        let entry = makeEntry(roles: ["fast"])
        let created = await handlers.handle(HandlerRequest(
            method: "POST", path: "", body: try entryBody(entry, secrets: ["apiKey": "sk-secret"])))
        #expect(created.status == 201)
        let json = String(bytes: body(created), encoding: .utf8) ?? ""
        #expect(!json.contains("sk-secret"))
        #expect(json.contains("apiKey"))
        #expect(secrets.value(for: entry.id, field: "apiKey") == "sk-secret")

        let duplicate = await handlers.handle(HandlerRequest(method: "POST", path: "", body: try entryBody(entry)))
        #expect(duplicate.status == 409)

        let list = await handlers.handle(HandlerRequest(method: "GET", path: ""))
        #expect(try AgentsJSON.decode([ModelEntry].self, from: body(list)).map(\.id) == [entry.id])
    }

    @Test("concurrent POSTs of one id answer one 201 and the rest 409")
    func concurrentModelCreates() async throws {
        let handlers = ModelHandlers(registry: try makeRegistry())
        let payload = try entryBody(makeEntry())

        let statuses = await withTaskGroup(of: Int.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    await handlers.handle(HandlerRequest(method: "POST", path: "", body: payload)).status
                }
            }
            return await group.reduce(into: [Int]()) { $0.append($1) }
        }

        #expect(statuses.sorted() == [201] + Array(repeating: 409, count: 7))
    }

    @Test("a refused plugin is 422 with its load error")
    func refusedPluginIsUnprocessable() async throws {
        var runtime = ScriptedRuntime().runtime
        runtime.discover = { _ in [] }
        runtime.refused = { _ in
            [PluginLoadFailure(identifier: FakePluginConstants.identifier, displayName: "Fake", message: "rebuild it")]
        }
        let registry = try makeRegistry(runtime: runtime)
        let entry = makeEntry()
        try registry.upsert(entry, secrets: nil)
        let handlers = ModelHandlers(registry: registry)

        let response = await handlers.handle(HandlerRequest(method: "GET", path: "\(entry.id.uuidString)/models"))

        #expect(response.status == 422)
        let decoded = try AgentsJSON.decode(HandlerError.self, from: body(response))
        #expect(decoded.message == "rebuild it")
    }

    @Test("an invalid entry is 400")
    func invalid() async throws {
        let handlers = ModelHandlers(registry: try makeRegistry())
        let response = await handlers.handle(HandlerRequest(
            method: "POST", path: "", body: try entryBody(makeEntry(name: ""))))
        #expect(response.status == 400)
        let malformed = await handlers.handle(HandlerRequest(method: "POST", path: "", body: Data("{}".utf8)))
        #expect(malformed.status == 400)
    }

    @Test("GET, PUT and DELETE one entry")
    func entryRoutes() async throws {
        let registry = try makeRegistry()
        let handlers = ModelHandlers(registry: registry)
        var entry = makeEntry()
        try registry.upsert(entry, secrets: nil)
        let path = entry.id.uuidString

        #expect(await handlers.handle(HandlerRequest(method: "GET", path: path)).status == 200)
        entry.configuration.name = "Renamed"
        let put = await handlers.handle(HandlerRequest(method: "PUT", path: path, body: try entryBody(entry)))
        #expect(put.status == 200)
        #expect(try registry.get(entry.id)?.configuration.name == "Renamed")

        let wrongPath = await handlers.handle(HandlerRequest(
            method: "PUT", path: UUID().uuidString, body: try entryBody(entry)))
        #expect(wrongPath.status == 400)
        let absent = makeEntry()
        let putAbsent = await handlers.handle(HandlerRequest(
            method: "PUT", path: absent.id.uuidString, body: try entryBody(absent)))
        #expect(putAbsent.status == 404)

        #expect(await handlers.handle(HandlerRequest(method: "DELETE", path: path)).status == 204)
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: path)).status == 404)
        #expect(await handlers.handle(HandlerRequest(method: "DELETE", path: path)).status == 404)
    }

    @Test("resolve needs a role and answers 404 when no entry holds it")
    func resolve() async throws {
        let registry = try makeRegistry()
        let handlers = ModelHandlers(registry: registry)
        let entry = makeEntry(roles: ["smart"])
        try registry.upsert(entry, secrets: nil)
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "resolve")).status == 400)
        #expect(await handlers.handle(HandlerRequest(method: "GET", path: "resolve", query: ["role": "fast"])).status
            == 404)
        let found = await handlers.handle(HandlerRequest(method: "GET", path: "resolve", query: ["role": "smart"]))
        #expect(try AgentsJSON.decode(ModelEntry.self, from: body(found)).id == entry.id)
    }

    @Test("plugins and test")
    func pluginsAndTest() async throws {
        let script = ScriptedRuntime(rounds: [[.textDelta("OK"), .end(stopReason: "end_turn")]])
        let registry = try makeRegistry(runtime: script.runtime)
        let handlers = ModelHandlers(registry: registry)
        let plugins = await handlers.handle(HandlerRequest(method: "GET", path: "plugins"))
        #expect(try AgentsJSON.decode([PluginSummary].self, from: body(plugins)).count == 1)

        let entry = makeEntry()
        try registry.upsert(entry, secrets: nil)
        let tested = await handlers.handle(HandlerRequest(method: "POST", path: "\(entry.id.uuidString)/test"))
        #expect(try AgentsJSON.decode(ModelTestResult.self, from: body(tested)).isOK)
        #expect(await handlers.handle(HandlerRequest(method: "POST", path: "\(UUID().uuidString)/test")).status
            == 404)
    }
}
