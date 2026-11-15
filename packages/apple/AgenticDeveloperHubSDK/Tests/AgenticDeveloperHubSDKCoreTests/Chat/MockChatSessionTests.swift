// Tests/AgenticDeveloperHubSDKCoreTests/Chat/MockChatSessionTests.swift
import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Collects ChatEvents in isolation-safe storage for async tests.
private actor EventCollector {
    private(set) var events: [ChatEvent] = []
    func append(_ event: ChatEvent) { events.append(event) }
}

/// A live subscription to a session: records every event and whether the stream ended.
private actor MockSessionRecorder {
    private(set) var events: [ChatEvent] = []
    private(set) var ended = false
    func append(_ event: ChatEvent) { events.append(event) }
    func markEnded() { ended = true }
}

private func mockSubscribe(_ stream: AsyncStream<ChatEvent>, into rec: MockSessionRecorder) -> Task<Void, Never> {
    Task {
        for await event in stream { await rec.append(event) }
        await rec.markEnded()
    }
}

/// Polls up to ~3 s for a condition on the recorded events.
private func mockWait(_ rec: MockSessionRecorder, _ cond: @Sendable ([ChatEvent]) -> Bool) async -> Bool {
    for _ in 0..<300 {
        if cond(await rec.events) { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return false
}

private func mockIsReady(_ event: ChatEvent) -> Bool {
    if case .stateChanged(.ready) = event { return true } else { return false }
}
private func mockIsDelta(_ event: ChatEvent) -> Bool {
    if case .responseDelta = event { return true } else { return false }
}
private func mockIsStarted(_ event: ChatEvent) -> Bool {
    if case .responseStarted = event { return true } else { return false }
}
private func mockIsFinishedEndTurn(_ event: ChatEvent) -> Bool {
    if case .responseFinished(_, let reason) = event { return reason == "end_turn" } else { return false }
}
private func mockReadyCount(_ events: [ChatEvent]) -> Int { events.filter(mockIsReady).count }

@Suite("MockChatSession conformance")
struct MockChatSessionConformanceTests {

    @Test("dev-chat-model-001: the first event on subscribe is .stateChanged(.ready)")
    func testV001_readyOnSubscribe() async {
        let session = MockChatSession()
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        _ = await mockWait(rec) { !$0.isEmpty }
        session.close()
        await task.value
        #expect(await rec.events.first == .stateChanged(.ready))
    }

    @Test("dev-chat-model-002: a turn runs ready, user message, responding, started, deltas, finished, ready")
    func testV002_fullTurnSequence() async {
        let session = MockChatSession(reply: "Hi there", chunkSize: 3)
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("hello")
        _ = await mockWait(rec) { mockReadyCount($0) >= 2 }
        session.close()
        await task.value
        let events = await rec.events
        var shape: [String] = []
        var text = ""
        for event in events {
            switch event {
            case .stateChanged(.ready): shape.append("ready")
            case .stateChanged(.responding): shape.append("responding")
            case .userMessage(let message): shape.append("user:\(message.text)")
            case .responseStarted: shape.append("started")
            case .responseDelta(_, let chunk): if shape.last != "delta" { shape.append("delta") }; text += chunk
            case .responseFinished(_, let reason): shape.append("finished:\(reason ?? "nil")")
            default: shape.append("other")
            }
        }
        #expect(shape == ["ready", "user:hello", "responding", "started", "delta", "finished:end_turn", "ready"])
        #expect(text == "Hi there")
    }

    @Test("dev-chat-model-003: an empty reply has no deltas between started and finished")
    func testV003_emptyReplyNoChunks() async {
        let session = MockChatSession(reply: "", chunkSize: 3)
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("x")
        _ = await mockWait(rec) { mockReadyCount($0) >= 2 }
        session.close()
        await task.value
        let events = await rec.events
        guard let started = events.firstIndex(where: mockIsStarted) else { Issue.record("no responseStarted"); return }
        #expect(events.filter(mockIsDelta).isEmpty)
        #expect(mockIsFinishedEndTurn(events[started + 1]))
    }

    @Test("dev-chat-model-004: a non-positive chunk size yields the whole reply as one delta")
    func testV004_nonPositiveChunkSizeSingleChunk() async {
        let session = MockChatSession(reply: "Hi", chunkSize: 0)
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("x")
        _ = await mockWait(rec) { mockReadyCount($0) >= 2 }
        session.close()
        await task.value
        let deltas = await rec.events.compactMap { event -> String? in
            if case .responseDelta(_, let chunk) = event { return chunk } else { return nil }
        }
        #expect(deltas == ["Hi"])
    }

    @Test("dev-chat-model-005: send before any subscription produces nothing")
    func testV005_sendWithoutSubscriptionIsSilent() async {
        let session = MockChatSession(reply: "Hi", chunkSize: 3)
        session.send("hello")
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        try? await Task.sleep(for: .milliseconds(150))
        session.close()
        await task.value
        // Only the .ready seeded by the later subscription; nothing from the earlier send.
        #expect(await rec.events == [.stateChanged(.ready)])
    }

    @Test("dev-chat-model-006: interrupt with no turn in flight yields no event")
    func testV006_interruptWithNoTurnIsNoOp() async {
        let session = MockChatSession()
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        _ = await mockWait(rec) { !$0.isEmpty }
        session.interrupt()
        try? await Task.sleep(for: .milliseconds(100))
        session.close()
        await task.value
        #expect(await rec.events == [.stateChanged(.ready)])
    }

    @Test("dev-chat-model-007: interrupt stops remaining chunks but the turn still finishes and returns to ready")
    func testV007_interruptStopsChunksTurnStillEnds() async {
        let session = MockChatSession(reply: "abcdefghi", chunkSize: 1, interChunkDelay: .seconds(5))
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("x")
        _ = await mockWait(rec) { $0.contains(where: mockIsDelta) }
        session.interrupt()
        let done = await mockWait(rec) { mockReadyCount($0) >= 2 }
        session.close()
        await task.value
        let events = await rec.events
        #expect(done)
        #expect(events.filter(mockIsDelta).count <= 1)
        #expect(events.contains(where: mockIsFinishedEndTurn))
        #expect(mockReadyCount(events) == 2)
    }

    @Test("dev-chat-model-008: close ends the event stream mid-turn")
    func testV008_closeFinishesStream() async {
        let session = MockChatSession(reply: "abcdefghi", chunkSize: 1, interChunkDelay: .seconds(5))
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("x")
        _ = await mockWait(rec) { $0.contains(where: mockIsDelta) }
        session.close()
        var ended = false
        for _ in 0..<300 {
            if await rec.ended { ended = true; break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(ended)
        let countAtEnd = await rec.events.count
        try? await Task.sleep(for: .milliseconds(100))
        #expect(await rec.events.count == countAtEnd)
        task.cancel()
    }

    @Test("dev-chat-model-009: clear is inert and a later send behaves normally")
    func testV009_clearIsInert() async {
        let session = MockChatSession(reply: "Hi", chunkSize: 3)
        let rec = MockSessionRecorder()
        let task = mockSubscribe(session.events(), into: rec)
        session.send("first")
        _ = await mockWait(rec) { mockReadyCount($0) >= 2 }
        let before = await rec.events.count
        session.clear()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(await rec.events.count == before)
        session.send("next")
        _ = await mockWait(rec) { mockReadyCount($0) >= 3 }
        session.close()
        await task.value
        let after = Array(await rec.events.dropFirst(before))
        let users = after.compactMap { event -> String? in
            if case .userMessage(let message) = event { return message.text } else { return nil }
        }
        #expect(users == ["next"])
        #expect(after.contains(where: mockIsStarted))
        #expect(after.contains(where: mockIsFinishedEndTurn))
        #expect(mockReadyCount(after) == 1)
    }

    @Test("dev-chat-model-010: a second subscription supersedes the first without ending it")
    func testV010_secondSubscriptionSupersedesFirst() async {
        let session = MockChatSession(reply: "Hi", chunkSize: 3)
        let recA = MockSessionRecorder(), recB = MockSessionRecorder()
        let taskA = mockSubscribe(session.events(), into: recA)
        let taskB = mockSubscribe(session.events(), into: recB)
        _ = await mockWait(recA) { !$0.isEmpty }
        _ = await mockWait(recB) { !$0.isEmpty }
        session.send("hi")
        _ = await mockWait(recB) { mockReadyCount($0) >= 2 }
        try? await Task.sleep(for: .milliseconds(50))
        let recordedB = await recB.events
        #expect(recordedB.contains(where: mockIsStarted))
        #expect(recordedB.contains(where: mockIsFinishedEndTurn))
        #expect(mockReadyCount(recordedB) == 2)
        #expect(await recA.events == [.stateChanged(.ready)])
        #expect(await recA.ended == false)
        session.close()
        await taskB.value
        taskA.cancel()
    }
}

@Suite("MockChatSession")
struct MockChatSessionTests {

    @Test("emits ready on subscribe, then echoes a user turn and streams a reply")
    func streamsScriptedReply() async {
        let session = MockChatSession(reply: "Hi there", chunkSize: 3)
        let collector = EventCollector()

        let collectorTask = Task {
            for await event in session.events() {
                await collector.append(event)
                if case .responseFinished = event { break }
            }
        }
        // give the subscription a tick to seed .ready
        try? await Task.sleep(for: .milliseconds(20))
        session.send("hello")
        await collectorTask.value
        session.close()

        let received = await collector.events

        #expect(received.first == .stateChanged(.ready))
        #expect(received.contains {
            if case .userMessage(let msg) = $0 { return msg.text == "hello" } else { return false }
        })
        let deltas = received.compactMap { event -> String? in
            if case .responseDelta(_, let txt) = event { return txt } else { return nil }
        }
        #expect(deltas.joined() == "Hi there")
        #expect(received.contains { if case .responseStarted = $0 { return true } else { return false } })
        #expect(received.last.map { if case .responseFinished = $0 { return true } else { return false } } == true)
    }
}
