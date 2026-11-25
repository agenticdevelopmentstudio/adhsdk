// Tests/AgenticDeveloperHubSDKAgentsTests/AgentStoreTests.swift
import Testing
import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKDatabase
@testable import AgenticDeveloperHubSDKAgents

@Suite("AgentStore")
struct AgentStoreTests {

    private func makeStore() throws -> AgentStore {
        try AgentStore(database: try BoundedDatabase(path: ":memory:"))
    }

    @Test("defaults are inserted once and never overwrite an edit")
    func defaultsKeepEdits() throws {
        let store = try makeStore()
        try store.insertDefaults([makeAgent(id: "a"), makeAgent(id: "b")])
        var edited = makeAgent(id: "a")
        edited.prompt = "Edited."
        try store.save(edited)
        try store.insertDefaults([makeAgent(id: "a"), makeAgent(id: "c")])
        #expect(try store.agents().map(\.id).sorted() == ["a", "b", "c"])
        #expect(try store.agent("a")?.prompt == "Edited.")
    }

    @Test("save round-trips every field")
    func saveRoundTrips() throws {
        let store = try makeStore()
        let agent = AgentDefinition(
            id: "full", name: "Full", prompt: "p", model: .config(id: UUID(), model: "m"),
            toolPermissions: ["bump": .ask], arrival: .off, deadlineSeconds: 12,
            thinkingBudgetTokens: 2048, enabled: false)
        try store.save(agent)
        #expect(try store.agent("full") == agent)
        #expect(try store.agent("absent") == nil)
    }

    @Test("sessions list most recently updated first, filtered by agent")
    func sessionsOrder() throws {
        let store = try makeStore()
        let first = try store.createSession(agentId: "a", title: "one")
        let second = try store.createSession(agentId: "a", title: nil)
        let other = try store.createSession(agentId: "b", title: nil)
        _ = try store.append(AIChatMessage(role: .user, content: "hi"), to: first.id)

        #expect(try store.sessions(agentId: "a").map(\.id) == [first.id, second.id])
        #expect(try store.sessions(agentId: nil).count == 3)
        #expect(try store.session(other.id)?.agentId == "b")
        #expect(try store.session(first.id)?.title == "one")
    }

    @Test("messages get consecutive sequence numbers and keep tool fields")
    func appendSequences() throws {
        let store = try makeStore()
        let session = try store.createSession(agentId: "a", title: nil)
        let user = try store.append(AIChatMessage(role: .user, content: "hi"), to: session.id)
        let use = try store.append(
            AIChatMessage(role: .toolUse, content: "", toolUseId: "c1", toolName: "echo",
                          toolArgumentsJSON: Data(#"{"text":"x"}"#.utf8)),
            to: session.id)
        let result = try store.append(
            AIChatMessage(role: .toolResult, content: "{}", toolUseId: "c1", toolIsError: true), to: session.id)
        #expect(user.seq == 0)
        #expect(use.seq == 1)
        #expect(result.seq == 2)

        let messages = try store.messages(session.id)
        #expect(messages.map(\.role) == ["user", "tool_use", "tool_result"])
        #expect(messages[1].toolArgumentsJSON == #"{"text":"x"}"#)
        #expect(messages[1].chatMessage?.toolName == "echo")
        #expect(messages[2].toolIsError == true)
    }

    @Test("deleting a session deletes its messages")
    func deleteSession() throws {
        let store = try makeStore()
        let session = try store.createSession(agentId: "a", title: nil)
        _ = try store.append(AIChatMessage(role: .user, content: "hi"), to: session.id)
        try store.deleteSession(session.id)
        #expect(try store.session(session.id) == nil)
        #expect(try store.messages(session.id).isEmpty)
    }

    @Test("an agent decodes from id, name, prompt and model alone")
    func minimalAgentDecodes() throws {
        let agent = try AgentsJSON.decode(
            AgentDefinition.self,
            from: #"{"id":"x","name":"X","prompt":"p","model":{"type":"role","role":"fast"}}"#)
        #expect(agent.enabled)
        #expect(agent.arrival == .off)
        #expect(agent.deadlineSeconds == AgentDefinition.defaultDeadlineSeconds)
        #expect(agent.toolPermissions.isEmpty)
    }
}
