// Tests/AgenticDeveloperHubSDKAgentsTests/AgentEventTests.swift
import Testing
import Foundation
import AIPluginKit
@testable import AgenticDeveloperHubSDKAgents

@Suite("AgentEvent JSON")
struct AgentEventTests {

    private static let activity = ActivityEntry(
        id: UUID(), occurredAt: Date(timeIntervalSince1970: 1_700_000_000), agentId: "helper",
        sessionId: UUID(), tool: "bump", argumentsJSON: #"{"reason":"r"}"#, reason: "r", summary: "Bumped")

    static let events: [AgentEvent] = [
        .textDelta("Hello"),
        .thinkingDelta("Hmm"),
        .toolStarted(callId: "c1", tool: "echo", argumentsJSON: #"{"text":"x"}"#),
        .toolFinished(callId: "c1", tool: "echo", summary: "Echoed", error: nil),
        .toolFinished(callId: "c2", tool: "broken", summary: "broken failed", error: "boom"),
        .activity(activity),
        .usage(AIUsage(inputTokens: 1, outputTokens: 2, cacheReadTokens: 3, cacheWriteTokens: 4)),
        .turnFinished(stopReason: "end_turn"),
        .turnFinished(stopReason: nil),
        .turnFailed(message: "No model")
    ]

    @Test("every event round-trips", arguments: events)
    func roundTrips(_ event: AgentEvent) throws {
        let data = try AgentsJSON.encode(event)
        #expect(try AgentsJSON.decode(AgentEvent.self, from: data) == event)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? String == event.type)
    }

    @Test("the wire is flat snake_case")
    func wireKeys() throws {
        let started = try object(.toolStarted(callId: "c1", tool: "echo", argumentsJSON: "{}"))
        #expect(Set(started.keys) == ["type", "call_id", "tool", "arguments"])
        #expect(started["type"] as? String == "tool_started")

        let usage = try object(.usage(AIUsage(inputTokens: 5)))
        #expect(usage["input_tokens"] as? Int == 5)
        #expect(usage["cache_write_tokens"] as? Int == 0)

        let finished = try object(.turnFinished(stopReason: "end_turn"))
        #expect(finished["stop_reason"] as? String == "end_turn")

        let activity = try object(.activity(Self.activity))
        #expect(activity["agent_id"] as? String == "helper")
        #expect(activity["at"] != nil)
        #expect(activity["session_id"] != nil)
    }

    @Test("only turn_finished and turn_failed are terminal")
    func terminal() {
        #expect(AgentEvent.turnFinished(stopReason: nil).isTerminal)
        #expect(AgentEvent.turnFailed(message: "x").isTerminal)
        #expect(!AgentEvent.textDelta("x").isTerminal)
    }

    @Test("an unknown type does not decode")
    func unknownType() {
        #expect(throws: DecodingError.self) {
            try AgentsJSON.decode(AgentEvent.self, from: #"{"type":"mystery"}"#)
        }
    }

    @Test("the envelope carries session_id, seq and the event")
    func envelope() throws {
        let envelope = AgentEnvelope(sessionId: UUID(), seq: 7, event: .textDelta("x"))
        let data = try AgentsJSON.encode(envelope)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["session_id", "seq", "event"])
        #expect(try AgentsJSON.decode(AgentEnvelope.self, from: data) == envelope)
    }

    @Test("text deltas of one session merge, keeping the later seq")
    func mergesDeltas() {
        let session = UUID()
        let first = AgentEnvelope(sessionId: session, seq: 1, event: .textDelta("Hel"))
        let second = AgentEnvelope(sessionId: session, seq: 2, event: .textDelta("lo"))
        #expect(AgentEnvelope.merging(first, second)
            == AgentEnvelope(sessionId: session, seq: 2, event: .textDelta("Hello")))
        let thinkA = AgentEnvelope(sessionId: session, seq: 3, event: .thinkingDelta("a"))
        let thinkB = AgentEnvelope(sessionId: session, seq: 4, event: .thinkingDelta("b"))
        #expect(AgentEnvelope.merging(thinkA, thinkB)?.event == .thinkingDelta("ab"))
    }

    @Test("mixed kinds, other events and other sessions never merge")
    func refusesOtherMerges() {
        let session = UUID()
        let text = AgentEnvelope(sessionId: session, seq: 1, event: .textDelta("a"))
        let thinking = AgentEnvelope(sessionId: session, seq: 2, event: .thinkingDelta("b"))
        let done = AgentEnvelope(sessionId: session, seq: 3, event: .turnFinished(stopReason: nil))
        let elsewhere = AgentEnvelope(sessionId: UUID(), seq: 2, event: .textDelta("b"))
        #expect(AgentEnvelope.merging(text, thinking) == nil)
        #expect(AgentEnvelope.merging(text, done) == nil)
        #expect(AgentEnvelope.merging(text, elsewhere) == nil)
    }

    private func object(_ event: AgentEvent) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: AgentsJSON.encode(event)) as? [String: Any])
    }
}
