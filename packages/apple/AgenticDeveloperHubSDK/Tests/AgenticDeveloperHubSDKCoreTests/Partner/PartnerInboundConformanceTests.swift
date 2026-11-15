import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner inbound conformance") struct PartnerInboundConformanceTests {
    private func tick(previous: Date? = nil, summary: String? = nil, job: String = "a") -> PartnerInbound {
        .tick(jobID: job, jobName: "A", previousTick: previous, summary: summary)
    }

    @Test("V1: exited text names the session and title")
    func testV1_exitedText() {
        let text = PartnerInbound.sessionExited(sessionID: "s1", title: "review abc").text
        #expect(text.contains("s1"))
        #expect(text == "Session s1 (review abc) exited.")
    }

    @Test("V2: will-quit text lists the ending sessions")
    func testV2_willQuitText() {
        let text = PartnerInbound.lifecycle(.willQuit(endingSessions: ["s1"])).text
        #expect(text.contains("quit"))
        #expect(text == "The app is about to quit. These sessions will end: s1")
    }

    @Test("V3: tick keys by job, owner has no key")
    func testV3_tickAndOwnerKeys() {
        #expect(tick().coalescingKey == "tick:a")
        #expect(tick(summary: "2 queued").coalescingKey == "tick:a")
        #expect(PartnerInbound.owner(text: "hi", attribution: nil).coalescingKey == nil)
        #expect(PartnerInbound.owner(text: "hi", attribution: nil).coalescingKey == nil)
    }

    @Test("V4: idle and exited keys differ")
    func testV4_idleAndExitedKeys() {
        #expect(PartnerInbound.sessionIdle(sessionID: "s1", title: "x").coalescingKey == "idle:s1")
        #expect(PartnerInbound.sessionIdle(sessionID: "s1", title: "y").coalescingKey == "idle:s1")
        #expect(PartnerInbound.sessionExited(sessionID: "s1", title: "x").coalescingKey == "exit:s1")
    }

    @Test("V5: bare tick text is one line")
    func testV5_bareTickText() {
        #expect(tick().text == "Timer tick for job A.")
    }

    @Test("V6: tick text with previous tick and summary")
    func testV6_tickTextLines() {
        let previous = Date(timeIntervalSince1970: 1_794_650_400)
        let lines = tick(previous: previous, summary: "2 queued").text.components(separatedBy: "\n")
        #expect(lines == ["Timer tick for job A.", "Previous tick: 2026-11-14T10:00:00Z", "2 queued"])
    }

    @Test("V7: empty summary adds an empty line")
    func testV7_emptySummary() {
        #expect(tick(summary: "").text == "Timer tick for job A.\n")
    }

    @Test("V8: owner text and attribution")
    func testV8_ownerTextAndAttribution() {
        let plain = PartnerInbound.owner(text: "hi", attribution: nil)
        #expect(plain.text == "hi")
        #expect(plain.attribution == nil)
        let given = ChatMessage.Attribution(sourceID: "src", context: ["p"], name: "n", iconSymbol: "star")
        let attributed = PartnerInbound.owner(text: "hi", attribution: given)
        #expect(attributed.text == "hi")
        #expect(attributed.attribution == given)
    }

    @Test("V9: non-owner events carry no attribution")
    func testV9_noAttributionOutsideOwner() {
        #expect(tick().attribution == nil)
        #expect(PartnerInbound.sessionIdle(sessionID: "s", title: "t").attribution == nil)
        #expect(PartnerInbound.sessionExited(sessionID: "s", title: "t").attribution == nil)
        #expect(PartnerInbound.lifecycle(.guidelinesChanged).attribution == nil)
    }

    @Test("V10: started text")
    func testV10_startedText() {
        #expect(PartnerInbound.lifecycle(.started(resumed: true, goneSessions: ["a", "b"])).text
                == "You were started (resumed: true). Sessions gone since last time: a, b")
        #expect(PartnerInbound.lifecycle(.started(resumed: false, goneSessions: [])).text
                == "You were started (resumed: false). Sessions gone since last time: none")
    }

    @Test("V11: guidelines-changed and timed-out text")
    func testV11_fixedSentences() {
        #expect(PartnerInbound.lifecycle(.guidelinesChanged).text
                == "Your guidelines changed and were applied at this restart.")
        #expect(PartnerInbound.lifecycle(.turnTimedOut).text
                == "Your previous turn was terminated after the turn timeout and the session resumed.")
    }

    @Test("V12: will-quit with no sessions says none")
    func testV12_willQuitNone() {
        #expect(PartnerInbound.lifecycle(.willQuit(endingSessions: [])).text
                == "The app is about to quit. These sessions will end: none")
    }

    @Test("V13: owner and lifecycle never coalesce")
    func testV13_noKeyForOwnerOrLifecycle() {
        let cases: [PartnerInbound] = [
            .owner(text: "hi", attribution: nil),
            .lifecycle(.started(resumed: true, goneSessions: [])),
            .lifecycle(.guidelinesChanged),
            .lifecycle(.willQuit(endingSessions: ["s"])),
            .lifecycle(.turnTimedOut)
        ]
        for event in cases { #expect(event.coalescingKey == nil) }
    }

    @Test("V14: the key ignores the payload")
    func testV14_keyIgnoresPayload() {
        #expect(tick(summary: nil).coalescingKey == "tick:a")
        #expect(tick(summary: "x").coalescingKey == "tick:a")
    }

    @Test("V15: values differing in summary are not equal but share a key")
    func testV15_valueSemantics() {
        let plain = tick(summary: nil)
        let summed = tick(summary: "x")
        #expect(plain != summed)
        #expect(plain.coalescingKey == summed.coalescingKey)
    }

    @Test("V16: empty ids and titles are used verbatim")
    func testV16_emptyIdsVerbatim() {
        #expect(PartnerInbound.sessionIdle(sessionID: "", title: "").text == "Session  () went idle.")
    }

    @Test("V17: idle text")
    func testV17_idleText() {
        #expect(PartnerInbound.sessionIdle(sessionID: "s1", title: "t").text == "Session s1 (t) went idle.")
    }
}
