import Testing
@testable import AgenticDeveloperHubSDK

/// Collects events off the actor's stream so a test can look at what has
/// arrived *so far* — the whole point of `scriptWaitsForTheFirstSend`, which
/// has to prove the script had not started yet. Draining into a local `var`
/// from a detached `Task` cannot show that: the array is only readable once
/// the loop ends, by which time the stream has finished either way.
private actor EventBox {
    private(set) var events: [InboundEvent] = []
    func append(_ event: InboundEvent) { events.append(event) }

    /// Waits until at least `count` events have arrived, or gives up.
    ///
    /// Conversation mode never finishes its stream — a conversation has no
    /// last turn — so `await drained.value` is not available to these tests
    /// the way it is to the fixed-script ones above. Polling is the honest
    /// alternative: a fixed sleep long enough for the slowest machine is
    /// either flaky or slow, and this is neither.
    func waitFor(count: Int, timeout: Duration = .seconds(2)) async -> [InboundEvent] {
        let deadline = ContinuousClock.now + timeout
        while events.count < count, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
        return events
    }
}

/// The `participantID`/`text` of a `.draftUpdated`, which is what the
/// conversation-mode tests below script: two strings per event, readable
/// without a `Message` conformer.
private func draftPairs(_ events: [InboundEvent]) -> [String] {
    events.compactMap { event in
        guard case .draftUpdated(let participantID, let text, _) = event else { return nil }
        return "\(participantID)-\(text)"
    }
}

@Suite("Scripted backend")
struct ScriptedBackendTests {

    private static func twoStatusEvents() -> [InboundEvent] {
        [
            .statusChanged(participantID: "p", status: ChatStatus(kind: .think)),
            .statusChanged(participantID: "p", status: nil),
        ]
    }

    @Test(".immediately replays with nothing sent, and finishes the stream")
    func immediatelyReplaysWithoutASend() async {
        let backend = ScriptedBackend(script: Self.twoStatusEvents(), start: .immediately)

        var count = 0
        for await _ in backend.inboundEvents { count += 1 }

        #expect(count == 2)
        let sent = await backend.sent
        #expect(sent.isEmpty)
    }

    /// The regression guard for a real defect: `ScriptedBackend.olyloDemo` is
    /// built when the chat surface is built — at app launch — so a script that
    /// replays from `init` makes the persona think and post a canned reply
    /// with nothing typed, and then stay silent forever because the script is
    /// spent. `.onFirstSend` is what makes the demo behave like a turn.
    @Test(".onFirstSend stays silent until something is sent, then replays")
    func scriptWaitsForTheFirstSend() async throws {
        let backend = ScriptedBackend(script: Self.twoStatusEvents(), start: .onFirstSend)
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }

        // Far longer than `.immediately` needs: with `delayBetweenEvents`
        // defaulted to `.zero`, that mode yields the whole script and finishes
        // on the next run loop turn, so anything arriving here is the bug.
        try await Task.sleep(for: .milliseconds(100))
        let beforeSend = await box.events
        #expect(beforeSend.isEmpty)

        _ = try await backend.send(text: "hi", attachments: [])
        await drained.value

        let afterSend = await box.events
        #expect(afterSend.count == 2)
    }

    @Test("a second send does not replay the script")
    func scriptPlaysOnlyOnce() async throws {
        let backend = ScriptedBackend(script: Self.twoStatusEvents(), start: .onFirstSend)
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }

        _ = try await backend.send(text: "first", attachments: [])
        _ = try await backend.send(text: "second", attachments: [])
        await drained.value

        let events = await box.events
        #expect(events.count == 2)
        let sent = await backend.sent
        #expect(sent.map(\.text) == ["first", "second"])
        #expect(sent.map(\.localID) == ["local-1", "local-2"])
    }

    @Test("setLocalTyping is recorded but does not start the script")
    func typingDoesNotStartTheScript() async throws {
        let backend = ScriptedBackend(script: Self.twoStatusEvents(), start: .onFirstSend)
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }

        try await backend.setLocalTyping(true)
        try await Task.sleep(for: .milliseconds(100))
        let beforeSend = await box.events
        #expect(beforeSend.isEmpty)

        let typingCalls = await backend.typingCalls
        #expect(typingCalls == [true])

        _ = try await backend.send(text: "hi", attachments: [])
        await drained.value
        let afterSend = await box.events
        #expect(afterSend.count == 2)
    }

    // MARK: Conversation mode

    @Test("an opening replays with nothing sent, and does not finish the stream")
    func openingReplaysWithoutASend() async throws {
        let backend = ScriptedBackend(
            opening: [
                ScriptedBackend.Beat(.draftUpdated(participantID: "p", text: "hello", attachments: [])),
                ScriptedBackend.Beat(.draftCleared(participantID: "p"), after: .milliseconds(10)),
            ],
            turn: { text, _ in
                [ScriptedBackend.Beat(.draftUpdated(participantID: text, text: "reply", attachments: []))]
            }
        )
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }
        defer { drained.cancel() }

        let opened = await box.waitFor(count: 2)
        #expect(draftPairs(opened) == ["p-hello"])
        let sent = await backend.sent
        #expect(sent.isEmpty)

        // And the stream is still open afterwards: a fixed script finishes its
        // continuation once replayed, and a conversation that cannot take a
        // turn after its welcome is not a conversation.
        _ = try await backend.send(text: "q", attachments: [])
        let afterSend = await box.waitFor(count: 3)
        #expect(draftPairs(afterSend) == ["p-hello", "q-reply"])
    }

    @Test("each send replays that turn's beats, with the submitted text and index")
    func eachSendReplaysATurn() async throws {
        let backend = ScriptedBackend(turn: { text, index in
            [ScriptedBackend.Beat(.draftUpdated(participantID: text, text: "\(index)", attachments: []))]
        })
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }
        defer { drained.cancel() }

        _ = try await backend.send(text: "first", attachments: [])
        _ = try await backend.send(text: "second", attachments: [])

        let events = await box.waitFor(count: 2)
        #expect(draftPairs(events) == ["first-1", "second-2"])
    }

    /// Two sends in quick succession must produce two turns in order, not two
    /// interleaved ones — a reply's tokens landing inside another reply's is
    /// the one way a scripted transcript can end up incoherent. The delay on
    /// each turn's *first* beat is what makes an unchained implementation
    /// fail: the second turn's task would wake during the first turn's pause.
    @Test("two quick sends do not interleave their turns")
    func turnsDoNotInterleave() async throws {
        let backend = ScriptedBackend(turn: { text, _ in
            [
                ScriptedBackend.Beat(
                    .draftUpdated(participantID: text, text: "a", attachments: []),
                    after: .milliseconds(40)),
                ScriptedBackend.Beat(.draftUpdated(participantID: text, text: "b", attachments: [])),
            ]
        })
        let box = EventBox()
        let drained = Task {
            for await event in backend.inboundEvents { await box.append(event) }
        }
        defer { drained.cancel() }

        _ = try await backend.send(text: "one", attachments: [])
        _ = try await backend.send(text: "two", attachments: [])

        let events = await box.waitFor(count: 4)
        #expect(draftPairs(events) == ["one-a", "one-b", "two-a", "two-b"])
    }
}
