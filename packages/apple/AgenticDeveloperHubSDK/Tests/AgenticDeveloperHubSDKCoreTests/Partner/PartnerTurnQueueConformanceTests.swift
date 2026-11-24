import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner turn queue conformance") struct PartnerTurnQueueConformanceTests {
    private func tick(_ job: String, summary: String? = nil) -> PartnerInbound {
        .tick(jobID: job, jobName: job.uppercased(), previousTick: nil, summary: summary)
    }

    private func owner(_ text: String) -> PartnerInbound {
        .owner(text: text, attribution: nil)
    }

    @Test("V1: ticks coalesce, owner messages do not")
    func testV1_ticksCoalesceOwnerDoesNot() {
        var queue = PartnerTurnQueue()
        queue.enqueue(tick("a"))
        queue.enqueue(tick("a", summary: "2 queued"))
        queue.enqueue(owner("hi"))
        queue.enqueue(owner("hi"))
        #expect(queue.count == 3)
        #expect(queue.next()?.text.contains("2 queued") == true)
    }

    @Test("V2: idle events coalesce per session and kind")
    func testV2_idleCoalescesPerKind() {
        var queue = PartnerTurnQueue()
        queue.enqueue(.sessionIdle(sessionID: "s1", title: "t"))
        queue.enqueue(.sessionIdle(sessionID: "s1", title: "t"))
        queue.enqueue(.sessionExited(sessionID: "s1", title: "t"))
        #expect(queue.count == 2)
    }

    @Test("V3: enqueueFirst goes ahead of everything")
    func testV3_enqueueFirstAhead() {
        var queue = PartnerTurnQueue()
        queue.enqueue(owner("waiting"))
        queue.enqueueFirst(.lifecycle(.turnTimedOut))
        #expect(queue.count == 2)
        #expect(queue.next() == .lifecycle(.turnTimedOut))
        #expect(queue.next()?.text == "waiting")
    }

    @Test("V4: next on an empty queue returns nil and count stays 0")
    func testV4_nextOnEmpty() {
        var queue = PartnerTurnQueue()
        #expect(queue.next() == nil)
        #expect(queue.count == 0)
    }

    @Test("V5: a coalesced tick keeps its position and takes the newer payload")
    func testV5_coalesceKeepsPosition() {
        var queue = PartnerTurnQueue()
        queue.enqueue(tick("a"))
        queue.enqueue(owner("hi"))
        queue.enqueue(tick("a", summary: "later"))
        #expect(queue.count == 2)
        #expect(queue.next() == tick("a", summary: "later"))
        #expect(queue.next() == owner("hi"))
    }

    @Test("V6: enqueue coalesces into a front-inserted entry")
    func testV6_coalesceTargetsFrontInserted() {
        var queue = PartnerTurnQueue()
        queue.enqueueFirst(tick("a"))
        queue.enqueue(tick("a", summary: "new"))
        #expect(queue.count == 1)
        #expect(queue.next() == tick("a", summary: "new"))
    }

    @Test("V7: enqueueFirst never coalesces")
    func testV7_enqueueFirstNoCoalesce() {
        var queue = PartnerTurnQueue()
        queue.enqueue(tick("a"))
        queue.enqueueFirst(tick("a", summary: "front"))
        #expect(queue.count == 2)
        #expect(queue.next() == tick("a", summary: "front"))
        #expect(queue.next() == tick("a"))
    }

    @Test("V8: repeated enqueueFirst returns the latest first")
    func testV8_enqueueFirstOrder() {
        var queue = PartnerTurnQueue()
        queue.enqueueFirst(owner("one"))
        queue.enqueueFirst(owner("two"))
        #expect(queue.next() == owner("two"))
        #expect(queue.next() == owner("one"))
    }

    @Test("V9: entries with no key always append")
    func testV9_noKeyAppends() {
        var queue = PartnerTurnQueue()
        queue.enqueue(.lifecycle(.guidelinesChanged))
        queue.enqueue(.lifecycle(.guidelinesChanged))
        #expect(queue.count == 2)
    }

    @Test("V10: keys are compared whole, so different jobs do not coalesce")
    func testV10_keyComparedWhole() {
        var queue = PartnerTurnQueue()
        queue.enqueue(tick("a"))
        queue.enqueue(tick("b"))
        #expect(queue.count == 2)
    }

    @Test("V11: coalescing replaces the first match, the front-inserted entry")
    func testV11_coalesceFirstMatch() {
        var queue = PartnerTurnQueue()
        queue.enqueue(tick("a"))
        queue.enqueueFirst(tick("a", summary: "front"))
        queue.enqueue(tick("a", summary: "new"))
        #expect(queue.count == 2)
        #expect(queue.next() == tick("a", summary: "new"))
        #expect(queue.next() == tick("a"))
    }
}
