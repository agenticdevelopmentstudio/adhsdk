import Testing
@testable import AgenticDeveloperHubSDK

@Suite("Chat status")
struct ChatStatusTests {

    @Test("the toolkit ships only the kinds it produces")
    func producedKinds() {
        #expect(ChatStatusKind.think.rawValue == "think")
        #expect(ChatStatusKind.respond.rawValue == "respond")
        #expect(ChatStatusKind.retry.rawValue == "retry")
    }

    @Test("a consumer can name a kind the toolkit has never heard of")
    func consumerDefinedKind() {
        let search = ChatStatusKind("search")
        #expect(search.rawValue == "search")
        #expect(search != .think)
        #expect(ChatStatusKind("search") == search)
    }

    @Test("a turn status maps onto a status kind")
    func turnStatusMaps() {
        #expect(ChatStatusKind(TurnStatus.thinking) == .think)
        #expect(ChatStatusKind(TurnStatus.responding) == .respond)
        #expect(ChatStatusKind(TurnStatus.retrying) == .retry)
    }

    @Test("both tenses are authored — neither is derived from the other")
    func wordPairCarriesBothTenses() {
        let pair = ChatStatusWordPair(present: "zeeping", past: "zeeped")
        #expect(pair.present == "zeeping")
        #expect(pair.past == "zeeped")
    }

    // NOTE: this is a DELIBERATE STRENGTHENING of the web bag, not parity with
    // it. `packages/web/packages/chat/src/backends/ShuffleBag.ts` reshuffles
    // when the bag empties and can therefore draw the same element twice across
    // the seam between passes. At a 1.8s rotation that reads as a stuck
    // spinner. Swift closes the seam; see the doc comment on `ShuffleBag`.
    @Test("the shuffle bag never repeats back to back, including across a refill")
    func bagDoesNotRepeat() {
        var bag = ShuffleBag(["a", "b", "c", "d"])
        var previous: String?
        for _ in 0..<200 {
            let next = bag.next()
            #expect(next != previous)
            previous = next
        }
    }

    @Test("the shuffle bag exhausts every element before repeating one")
    func bagExhaustsFirst() {
        var bag = ShuffleBag(["a", "b", "c", "d"])
        let drawn = (0..<4).map { _ in bag.next() }
        #expect(Set(drawn).count == 4)
    }

    @Test("a single-element bag degrades rather than looping forever")
    func singleElementBag() {
        var bag = ShuffleBag(["only"])
        #expect(bag.next() == "only")
        #expect(bag.next() == "only")
    }

    @Test("a status event never becomes a message")
    func statusStaysOutOfTranscript() async {
        let backend = ScriptedBackend(script: [
            .statusChanged(participantID: "p", status: ChatStatus(kind: .think)),
            .statusChanged(participantID: "p", status: nil),
        ])
        var messages: [any Message] = []
        for await event in backend.inboundEvents {
            if case .messageReceived(let m) = event { messages.append(m) }
        }
        #expect(messages.isEmpty)
    }
}
