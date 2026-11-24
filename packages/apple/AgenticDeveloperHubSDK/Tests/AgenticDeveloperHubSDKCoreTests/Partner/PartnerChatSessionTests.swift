import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PartnerChatSession") struct PartnerChatSessionTests {
    private func session(_ initial: [ChatMessage] = []) -> PartnerChatSession {
        PartnerChatSession(initial: initial, send: { _ in }, interrupt: {})
    }
    private func assistant(_ blocks: [ClaudeStreamMessage.Block]) -> ClaudeStreamMessage {
        .init(kind: .assistant, subtype: nil, sessionID: "s", blocks: blocks, isError: false, resultText: nil)
    }

    @Test func assistantTextBecomesAStreamedMessage() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        let persisted = chat.apply(assistant([.init(kind: .text, text: "hello", name: nil, id: nil, toolUseID: nil)]))
        for await event in stream.prefix(4) { events.append(event) }
        #expect(persisted.count == 1 && persisted[0].role == .assistant && persisted[0].text == "hello")
        #expect(events.contains { if case .responseDelta(_, let text) = $0 { return text == "hello" }; return false })
    }

    @Test func toolUseThenToolResultEmitStartedAndCompleted() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "n", id: "t1")]))
        _ = chat.apply(.init(kind: .user, blocks: [.init(kind: .toolResult, toolUseID: "t1")]))
        for await event in stream.prefix(3) { events.append(event) }
        #expect(events.contains { if case .toolCall(_, "n", .started) = $0 { return true }; return false })
        #expect(events.contains { if case .toolCall(_, "n", .completed) = $0 { return true }; return false })
    }

    @Test func errorResultEmitsTurnFailedAndReadyState() async {
        let chat = session()
        var events: [ChatEvent] = []
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, subtype: "error_max_turns", isError: true, resultText: "boom"))
        for await event in stream.prefix(3) { events.append(event) }
        #expect(events[1] == .turnFailed(ChatError(message: "boom", isRetryable: true)))
        #expect(events[2] == .stateChanged(.ready))
    }

    @Test func initialTranscriptIsReplayedOnSubscribe() async {
        let note = ChatMessage(role: .user, text: "earlier")
        var first: ChatEvent?
        for await event in session([note]).events() { first = event; break }
        #expect(first == .transcriptLoaded([note]))
    }

    @Test func ownerEchoProducesNothingAndUserNoteEmits() async {
        let chat = session()
        let stream = chat.events()
        #expect(chat.apply(.init(kind: .user, blocks: [.init(kind: .text, text: "hi")])).isEmpty)
        let note = ChatMessage(role: .user, text: "hi")
        chat.noteUserMessage(note)
        var events: [ChatEvent] = []
        for await event in stream.prefix(2) { events.append(event) }
        #expect(events[1] == .userMessage(note))
    }

    // MARK: - Conformance vectors 006 to 025

    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var sentLines: [String] = []
        private var interruptCount = 0
        var sent: [String] { lock.lock(); defer { lock.unlock() }; return sentLines }
        var interrupts: Int { lock.lock(); defer { lock.unlock() }; return interruptCount }
        func recordSend(_ text: String) { lock.lock(); sentLines.append(text); lock.unlock() }
        func recordInterrupt() { lock.lock(); interruptCount += 1; lock.unlock() }
    }

    private func recordingSession(_ recorder: Recorder) -> PartnerChatSession {
        PartnerChatSession(initial: [], send: { recorder.recordSend($0) }, interrupt: { recorder.recordInterrupt() })
    }

    /// Everything the stream delivered so far after its leading `.transcriptLoaded` (kept when `keepLeading`),
    /// found by sending a sentinel state change and reading up to it.
    private func drain(_ stream: AsyncStream<ChatEvent>, _ chat: PartnerChatSession,
                       keepLeading: Bool = false) async -> [ChatEvent] {
        chat.setState(.connecting)
        var events: [ChatEvent] = []
        for await event in stream {
            if event == .stateChanged(.connecting) { break }
            events.append(event)
        }
        return keepLeading ? events : Array(events.dropFirst())
    }

    private func firstEvent(_ stream: AsyncStream<ChatEvent>) async -> ChatEvent? {
        for await event in stream { return event }
        return nil
    }

    private func textBlock(_ text: String?) -> ClaudeStreamMessage.Block { .init(kind: .text, text: text) }

    private func toolIDs(_ events: [ChatEvent]) -> [String] {
        events.compactMap { event in
            if case .toolCall(let id, _, _) = event { return id }
            return nil
        }
    }

    @Test("partner-chat-session-006: send forwards once and changes nothing locally")
    func sendForwardsOnly() async {
        let recorder = Recorder()
        let chat = recordingSession(recorder)
        let stream = chat.events()
        chat.send("go")
        #expect(recorder.sent == ["go"])
        #expect(await drain(stream, chat).isEmpty)
        #expect(await firstEvent(chat.events()) == .transcriptLoaded([]))
    }

    @Test("partner-chat-session-007: interrupt forwards once and emits nothing")
    func interruptForwardsOnly() async {
        let recorder = Recorder()
        let chat = recordingSession(recorder)
        let stream = chat.events()
        chat.interrupt()
        #expect(recorder.interrupts == 1)
        #expect(await drain(stream, chat).isEmpty)
    }

    @Test("partner-chat-session-008: close signals closed, detaches and keeps the transcript")
    func closeSignalsClosedAndDetaches() async throws {
        let chat = session()
        let stream = chat.events()
        chat.close()
        let reply = chat.apply(assistant([textBlock("late")]))
        var events: [ChatEvent] = []
        for await event in stream { events.append(event) }
        #expect(events == [.transcriptLoaded([]), .stateChanged(.closed)])
        let kept = try #require(reply.first)
        #expect(await firstEvent(chat.events()) == .transcriptLoaded([kept]))
    }

    @Test("partner-chat-session-009: a second close emits nothing and does not fail")
    func secondCloseIsSilent() async {
        let chat = session()
        let stream = chat.events()
        chat.close()
        chat.close()
        var events: [ChatEvent] = []
        for await event in stream { events.append(event) }
        #expect(events == [.transcriptLoaded([]), .stateChanged(.closed)])
        let fresh = chat.events()
        #expect(await drain(fresh, chat).isEmpty)
    }

    @Test("partner-chat-session-010: only the newest stream receives later events")
    func onlyNewestStreamReceives() async {
        let chat = session()
        let older = chat.events()
        let newer = chat.events()
        let note = ChatMessage(role: .user, text: "hi")
        chat.noteUserMessage(note)
        var olderEvents: [ChatEvent] = []
        for await event in older { olderEvents.append(event) }
        #expect(olderEvents == [.transcriptLoaded([])])
        #expect(await drain(newer, chat) == [.userMessage(note)])
    }

    @Test("partner-chat-session-011: no buffering and no state replay without a subscriber")
    func noBufferWithoutSubscriber() async {
        let chat = session()
        let note = ChatMessage(role: .user, text: "hi")
        chat.setState(.responding)
        chat.noteUserMessage(note)
        let stream = chat.events()
        #expect(await drain(stream, chat, keepLeading: true) == [.transcriptLoaded([note])])
    }

    @Test("partner-chat-session-012: empty or nil assistant text is skipped")
    func emptyAssistantTextSkipped() async {
        let chat = session()
        let stream = chat.events()
        #expect(chat.apply(assistant([textBlock(""), textBlock(nil)])).isEmpty)
        #expect(await drain(stream, chat).isEmpty)
        #expect(await firstEvent(chat.events()) == .transcriptLoaded([]))
    }

    @Test("partner-chat-session-013: two text blocks give two messages in order")
    func twoTextBlocksGiveTwoMessages() async {
        let chat = session()
        let stream = chat.events()
        let persisted = chat.apply(assistant([textBlock("a"), textBlock("b")]))
        #expect(persisted.map(\.text) == ["a", "b"])
        let events = await drain(stream, chat)
        #expect(events.count == 6)
        let first = persisted[0].id
        let second = persisted[1].id
        #expect(Array(events.prefix(3)) == [
            .responseStarted(messageID: first),
            .responseDelta(messageID: first, text: "a"),
            .responseFinished(messageID: first, stopReason: nil)
        ])
        #expect(Array(events.suffix(3)) == [
            .responseStarted(messageID: second),
            .responseDelta(messageID: second, text: "b"),
            .responseFinished(messageID: second, stopReason: nil)
        ])
        #expect(await firstEvent(chat.events()) == .transcriptLoaded(persisted))
    }

    @Test("partner-chat-session-014: an unknown or nil tool id completes as tool")
    func unknownToolResultCompletesAsTool() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(.init(kind: .user, blocks: [.init(kind: .toolResult, toolUseID: "never")]))
        _ = chat.apply(.init(kind: .user, blocks: [.init(kind: .toolResult)]))
        let events = await drain(stream, chat)
        #expect(events.count == 2)
        for event in events {
            #expect({ if case .toolCall(_, "tool", .completed) = event { return true }; return false }())
        }
    }

    @Test("partner-chat-session-015: a tool use without an id is not remembered")
    func toolUseWithoutIDNotRemembered() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "n")]))
        _ = chat.apply(.init(kind: .user, blocks: [.init(kind: .toolResult, toolUseID: "t1")]))
        let events = await drain(stream, chat)
        #expect(events.count == 2)
        #expect({ if case .toolCall(_, "n", .started) = events[0] { return true }; return false }())
        #expect({ if case .toolCall(_, "tool", .completed) = events[1] { return true }; return false }())
    }

    @Test("partner-chat-session-016: a minted id is reused within a turn and replaced after a result")
    func mintedIDReusedUntilResult() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "one", id: "a")]))
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "two", id: "b")]))
        _ = chat.apply(.init(kind: .result))
        _ = chat.apply(assistant([.init(kind: .toolUse, name: "three", id: "c")]))
        let events = await drain(stream, chat)
        let ids = toolIDs(events)
        #expect(ids.count == 3)
        #expect(ids[0] == ids[1] && ids[1] != ids[2])
        #expect(ids.allSatisfy { UUID(uuidString: $0) != nil })
        #expect(!events.contains { if case .responseStarted = $0 { return true }; return false })
    }

    @Test("partner-chat-session-017: failure text falls back to subtype then error")
    func failureTextFallsBack() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, subtype: "error_max_turns", isError: true))
        _ = chat.apply(.init(kind: .result, isError: true))
        let events = await drain(stream, chat)
        #expect(events == [
            .turnFailed(ChatError(message: "error_max_turns", isRetryable: true)),
            .stateChanged(.ready),
            .turnFailed(ChatError(message: "error", isRetryable: true)),
            .stateChanged(.ready)
        ])
    }

    @Test("partner-chat-session-018: a success result only emits ready")
    func successResultEmitsReady() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, isError: false))
        #expect(await drain(stream, chat) == [.stateChanged(.ready)])
    }

    @Test("partner-chat-session-019: system init, other and thinking-only messages are ignored")
    func ignoredMessagesEmitNothing() async {
        let chat = session()
        let stream = chat.events()
        #expect(chat.apply(.init(kind: .systemInit)).isEmpty)
        #expect(chat.apply(.init(kind: .other("x"))).isEmpty)
        #expect(chat.apply(assistant([.init(kind: .thinking, text: "hmm")])).isEmpty)
        #expect(await drain(stream, chat).isEmpty)
    }

    @Test("partner-chat-session-020: clear leaves the transcript alone")
    func clearKeepsTranscript() async {
        let chat = session()
        let note = ChatMessage(role: .user, text: "keep")
        chat.noteUserMessage(note)
        chat.clear()
        #expect(await firstEvent(chat.events()) == .transcriptLoaded([note]))
    }

    @Test("partner-chat-session-021: setState emits stateChanged")
    func setStateEmits() async {
        let chat = session()
        let stream = chat.events()
        chat.setState(.responding)
        #expect(await drain(stream, chat) == [.stateChanged(.responding)])
    }

    @Test("partner-chat-session-022: concurrent noteUserMessage is race-free",
          .disabled("needs a Thread Sanitizer run, which a unit test cannot detect; the lock is one NSLock"))
    func concurrentNotesAreRaceFree() {}

    @Test("partner-chat-session-023: errors do not supply the failure text")
    func errorsDoNotSupplyFailureText() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, isError: true, errors: ["x"]))
        #expect(await drain(stream, chat).first == .turnFailed(ChatError(message: "error", isRetryable: true)))
    }

    @Test("partner-chat-session-024: a failed turn keeps the stream open")
    func failedTurnKeepsStreamOpen() async {
        let chat = session()
        let stream = chat.events()
        _ = chat.apply(.init(kind: .result, subtype: "error_max_turns", isError: true, resultText: "boom"))
        let note = ChatMessage(role: .user, text: "again")
        chat.noteUserMessage(note)
        let events = await drain(stream, chat)
        #expect(events.last == .userMessage(note))
        #expect(events.contains(.turnFailed(ChatError(message: "boom", isRetryable: true))))
    }

    @Test("partner-chat-session-025: the transcript holds owner and assistant lines in call order")
    func transcriptGrowsInCallOrder() async throws {
        let chat = session()
        let note = ChatMessage(role: .user, text: "hi")
        chat.noteUserMessage(note)
        let reply = try #require(chat.apply(assistant([textBlock("hello")])).first)
        #expect(await firstEvent(chat.events()) == .transcriptLoaded([note, reply]))
    }
}
