// Tests/AgenticDeveloperHubSDKAgentsTests/AgentHostTests.swift
import Testing
import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKAgents

@Suite("AgentHost")
struct AgentHostTests {

    private func toolUse(_ id: String, _ name: String, _ arguments: String) -> AIStreamEvent {
        .toolUse(id: id, name: name, argumentsJSON: Data(arguments.utf8))
    }

    @Test("a plain answer streams its text, its usage and turn_finished, and is stored")
    func plainTurn() async throws {
        let usage = AIUsage(inputTokens: 10, outputTokens: 2)
        let script = ScriptedRuntime(rounds: [[
            .thinkingDelta("hmm"), .textDelta("Hel"), .textDelta("lo"),
            .usage(AIUsage(inputTokens: 10)), .usage(usage), .end(stopReason: "end_turn")
        ]])
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)

        let envelopes = await collect(try await host.send("Hi", to: session.id))
        #expect(envelopes.map(\.event) == [
            .thinkingDelta("hmm"), .textDelta("Hel"), .textDelta("lo"), .usage(usage),
            .turnFinished(stopReason: "end_turn")
        ])
        #expect(envelopes.map(\.seq) == Array(0..<5))
        #expect(envelopes.allSatisfy { $0.sessionId == session.id })

        let detail = try #require(try await host.session(session.id))
        #expect(detail.messages.map(\.role) == ["user", "assistant"])
        #expect(detail.messages.last?.content == "Hello")
    }

    @Test("the context carries the prompt, history, tools, thinking budget and resolved config")
    func buildsContext() async throws {
        let script = ScriptedRuntime()
        let host = try makeHost(script: script, agents: [makeAgent(thinking: 1024)])
        let session = try await host.createSession(agentId: "helper", title: nil)
        _ = await collect(try await host.send("Hi", to: session.id))

        let context = try #require(script.plugin.builtContexts.last)
        #expect(context.systemPrompt == "You help.")
        #expect(context.messages.map(\.content) == ["Hi"])
        #expect(context.tools.map(\.name) == ["echo", "bump", "broken"])
        #expect(context.thinkingBudgetTokens == 1024)
        #expect(context.maxTokens == AgentHost.maxTokens(thinking: 1024))
        #expect(context.model == FakePluginConstants.nativeModel)
        #expect(context.config.apiKey == "test-key")
    }

    @Test("a tool round runs the tool, stores the call and result, and asks the model again")
    func toolRound() async throws {
        let script = ScriptedRuntime(rounds: [
            [toolUse("c1", "echo", #"{"text":"x"}"#), .end(stopReason: "tool_use")],
            [.textDelta("Done."), .end(stopReason: "end_turn")]
        ])
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)

        let events = await collect(try await host.send("Echo x", to: session.id)).map(\.event)
        #expect(events == [
            .toolStarted(callId: "c1", tool: "echo", argumentsJSON: #"{"text":"x"}"#),
            .toolFinished(callId: "c1", tool: "echo", summary: "Echoed", error: nil),
            .textDelta("Done."),
            .turnFinished(stopReason: "end_turn")
        ])
        #expect(script.roundsStarted == 2)

        let messages = try #require(try await host.session(session.id)).messages
        #expect(messages.map(\.role) == ["user", "tool_use", "tool_result", "assistant"])
        #expect(messages[1].toolName == "echo")
        #expect(messages[2].toolUseId == "c1")
        #expect(messages[2].content.contains(#""caller":"agent""#))
        #expect(messages[2].toolIsError == false)
    }

    @Test("a mutating tool reports its activity")
    func mutatingToolActivity() async throws {
        let script = ScriptedRuntime(rounds: [
            [toolUse("c1", "bump", #"{"reason":"testing"}"#), .end(stopReason: "tool_use")]
        ])
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)

        let events = await collect(try await host.send("Bump", to: session.id)).map(\.event)
        let activity = try #require(events.compactMap { event -> ActivityEntry? in
            if case .activity(let entry) = event { return entry }
            return nil
        }.first)
        #expect(activity.tool == "bump")
        #expect(activity.agentId == "helper")
        #expect(activity.sessionId == session.id)
        #expect(activity.reason == "testing")
        #expect(activity.summary == "Bumped the counter")
    }

    @Test("a failing or unknown tool goes back to the model as an error result")
    func toolErrors() async throws {
        let script = ScriptedRuntime(rounds: [
            [toolUse("c1", "broken", "{}"), toolUse("c2", "missing", "{}"), .end(stopReason: "tool_use")]
        ])
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)

        let events = await collect(try await host.send("Break", to: session.id)).map(\.event)
        #expect(events.contains(.toolFinished(callId: "c1", tool: "broken", summary: "broken failed",
                                              error: "The tool broke")))
        #expect(events.contains(.toolFinished(callId: "c2", tool: "missing", summary: "missing failed",
                                              error: "Unknown tool 'missing'")))
        #expect(events.last == .turnFinished(stopReason: "end_turn"))

        let results = try #require(try await host.session(session.id)).messages.filter { $0.role == "tool_result" }
        #expect(results.map(\.toolIsError) == [true, true])
        #expect(results[0].content.contains("The tool broke"))
    }

    @Test("a turn that keeps calling tools fails after maxToolRounds")
    func roundLimit() async throws {
        let rounds = (0..<3).map { index in
            [toolUse("c\(index)", "echo", "{}"), AIStreamEvent.end(stopReason: "tool_use")]
        }
        let script = ScriptedRuntime(rounds: rounds)
        let host = try makeHost(script: script, maxToolRounds: 2)
        let session = try await host.createSession(agentId: "helper", title: nil)

        let events = await collect(try await host.send("Loop", to: session.id)).map(\.event)
        guard case .turnFailed = events.last else {
            Issue.record("Expected turn_failed, got \(String(describing: events.last))")
            return
        }
        #expect(script.roundsStarted == 2)
    }

    @Test("a role no entry holds falls back to the first enabled entry")
    func roleFallback() async throws {
        let script = ScriptedRuntime()
        let host = try makeHost(script: script, agents: [makeAgent(model: .role("nobody-has-this"))])
        let session = try await host.createSession(agentId: "helper", title: nil)
        let events = await collect(try await host.send("Hi", to: session.id)).map(\.event)
        #expect(events.last == .turnFinished(stopReason: "end_turn"))
    }

    @Test("an agent naming an absent model entry fails its turn")
    func noModel() async throws {
        let script = ScriptedRuntime()
        let host = try makeHost(script: script, agents: [makeAgent(model: .config(id: UUID(), model: nil))])
        let session = try await host.createSession(agentId: "helper", title: nil)
        let events = await collect(try await host.send("Hi", to: session.id)).map(\.event)
        guard case .turnFailed = events.last else {
            Issue.record("Expected turn_failed, got \(String(describing: events.last))")
            return
        }
        #expect(script.roundsStarted == 0)
    }

    @Test("send refuses an unknown session, a disabled agent and a second turn")
    func sendRefusals() async throws {
        let script = ScriptedRuntime(hang: true)
        let host = try makeHost(script: script, agents: [makeAgent(), makeAgent(id: "off", enabled: false)])
        let unknown = UUID()
        await #expect(throws: AgentHostError.sessionNotFound(unknown)) {
            _ = try await host.send("Hi", to: unknown)
        }
        let disabled = try await host.createSession(agentId: "off", title: nil)
        await #expect(throws: AgentHostError.agentDisabled("off")) {
            _ = try await host.send("Hi", to: disabled.id)
        }

        let session = try await host.createSession(agentId: "helper", title: nil)
        let stream = try await host.send("Hi", to: session.id)
        await #expect(throws: AgentHostError.turnInProgress(session.id)) {
            _ = try await host.send("Again", to: session.id)
        }
        await host.interrupt(session.id)
        let events = await collect(stream).map(\.event)
        #expect(events.last == .turnFinished(stopReason: "interrupted"))
    }

    @Test("interrupting a running turn ends it with stop reason interrupted")
    func interrupts() async throws {
        let script = ScriptedRuntime(hang: true)
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let stream = try await host.send("Hi", to: session.id)
        await host.interrupt(session.id)
        #expect(await collect(stream).map(\.event) == [.turnFinished(stopReason: "interrupted")])

        let next = try await host.send("Again", to: session.id)
        await host.interrupt(session.id)
        #expect(await collect(next).last?.event == .turnFinished(stopReason: "interrupted"))
    }

    @Test("deleting a session with a running turn ends its streams and the turn emits nothing more")
    func deleteRunningSession() async throws {
        let script = ScriptedRuntime(hang: true)
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let tail = await host.events(session.id)
        let stream = try await host.send("Hi", to: session.id)
        try await host.deleteSession(session.id)

        #expect(await collect(stream).isEmpty)
        #expect(await collect(tail).isEmpty)
        #expect(try await host.session(session.id) == nil)
    }

    @Test("a maxToolRounds below 1 is taken as 1")
    func roundLimitFloor() async throws {
        let script = ScriptedRuntime(rounds: [[toolUse("c0", "echo", "{}"), .end(stopReason: "tool_use")]])
        let host = try makeHost(script: script, maxToolRounds: 0)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let events = await collect(try await host.send("Loop", to: session.id)).map(\.event)
        guard case .turnFailed = events.last else {
            Issue.record("Expected turn_failed, got \(String(describing: events.last))")
            return
        }
        #expect(script.roundsStarted == 1)
    }

    @Test("the live tail sees every turn's events, numbered on from the last")
    func liveTail() async throws {
        let script = ScriptedRuntime(rounds: [
            [.textDelta("one"), .end(stopReason: "end_turn")],
            [.textDelta("two"), .end(stopReason: "end_turn")]
        ])
        let host = try makeHost(script: script)
        let session = try await host.createSession(agentId: "helper", title: nil)
        let tail = await host.events(session.id)

        _ = await collect(try await host.send("1", to: session.id))
        let second = await collect(try await host.send("2", to: session.id))
        #expect(second.map(\.seq) == [2, 3])

        try await host.deleteSession(session.id)
        let seen = await collect(tail)
        #expect(seen.map(\.event) == [
            .textDelta("one"), .turnFinished(stopReason: "end_turn"),
            .textDelta("two"), .turnFinished(stopReason: "end_turn")
        ])
    }

    @Test("runTool runs a tool outside a turn and reports activity only in a session")
    func runToolDirectly() async throws {
        let script = ScriptedRuntime()
        let host = try makeHost(script: script)
        let outcome = try await host.runTool(
            "echo", argumentsJSON: "{}", context: ToolCallContext(caller: "external"))
        #expect(outcome.resultJSON.contains(#""caller":"external""#))
        await #expect(throws: AgentToolError.unknownTool("nope")) {
            _ = try await host.runTool("nope", argumentsJSON: "{}", context: ToolCallContext(caller: "x"))
        }

        let session = try await host.createSession(agentId: "helper", title: nil)
        let tail = await host.events(session.id)
        let bumped = try await host.runTool(
            "bump", argumentsJSON: #"{"reason":"cli"}"#,
            context: ToolCallContext(caller: "cli", sessionId: session.id))
        #expect(bumped.inverse?.tool == "unbump")
        try await host.deleteSession(session.id)
        let events = await collect(tail).map(\.event)
        #expect(events.count == 1)
        guard case .activity(let entry) = events.first else {
            Issue.record("Expected an activity event")
            return
        }
        #expect(entry.reason == "cli")
    }

    @Test("save validates the agent; createSession needs a known agent")
    func agentManagement() async throws {
        let host = try makeHost(script: ScriptedRuntime())
        await #expect(throws: AgentHostError.self) {
            try await host.save(AgentDefinition(id: "", name: "x", prompt: "", model: .role("fast")))
        }
        await #expect(throws: AgentHostError.self) {
            try await host.save(AgentDefinition(id: "x", name: " ", prompt: "", model: .role("fast")))
        }
        await #expect(throws: AgentHostError.invalidAgent("An agent needs an id")) {
            try await host.save(AgentDefinition(id: "\n\t", name: "x", prompt: "", model: .role("fast")))
        }
        await #expect(throws: AgentHostError.invalidAgent("An agent needs a name")) {
            try await host.save(AgentDefinition(id: "x", name: "\n", prompt: "", model: .role("fast")))
        }
        await #expect(throws: AgentHostError.agentNotFound("ghost")) {
            _ = try await host.createSession(agentId: "ghost", title: nil)
        }
        try await host.save(makeAgent(id: "new"))
        #expect(try await host.agents().map(\.id).sorted() == ["helper", "new"])
    }

    @Test("native tools go straight to an HTTP plugin; anything else is prompted")
    func choosesPlugin() throws {
        let plugin = FakePlugin()
        let descriptor = fakeDescriptor()
        let tool = AIToolSpec(name: "echo", description: "", parametersJSONSchema: Data("{}".utf8))
        let withTools = AIChatContext(messages: [], model: "m", tools: [tool], config: AIPluginConfig([:]))
        let noTools = AIChatContext(messages: [], model: "m", config: AIPluginConfig([:]))
        let templateId = FakePluginConstants.templateId

        let native = try AgentHost.choosePlugin(
            plugin, descriptor: descriptor, model: FakePluginConstants.nativeModel, templateId: templateId,
            context: withTools)
        #expect(native === plugin)

        let prompted = try AgentHost.choosePlugin(
            plugin, descriptor: descriptor, model: FakePluginConstants.promptedModel, templateId: templateId,
            context: withTools)
        #expect(prompted is PromptedToolCallingPlugin)

        let bare = try AgentHost.choosePlugin(
            plugin, descriptor: descriptor, model: FakePluginConstants.promptedModel, templateId: templateId,
            context: noTools)
        #expect(bare === plugin)

        let command = FakePlugin()
        command.useCommand = true
        let subprocess = try AgentHost.choosePlugin(
            command, descriptor: descriptor, model: FakePluginConstants.nativeModel, templateId: templateId,
            context: withTools)
        #expect(subprocess is PromptedToolCallingPlugin)
    }

    @Test("maxTokens leaves room for the answer on top of the thinking budget")
    func maxTokens() {
        #expect(AgentHost.maxTokens(thinking: nil) == 4096)
        #expect(AgentHost.maxTokens(thinking: 2048) == 6144)
    }
}
