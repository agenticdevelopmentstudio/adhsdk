import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

/// The generic back/forward trail. The cases worth pinning are the ones where a
/// naive stack misbehaves: stepping back must not itself be recorded,
/// re-visiting the current place must not stack up entries that go nowhere, and
/// a new step after going back must drop the forward trail. Strings and URLs
/// here, since `Int` is what the Settings suite already covers.
@Suite("NavigationHistory")
struct NavigationHistoryTests {

    @Test("a fresh history can go nowhere")
    func emptyHistoryIsInert() {
        var history = NavigationHistory<String>()
        #expect(history.current == nil)
        #expect(!history.canGoBack)
        #expect(!history.canGoForward)
        #expect(history.goBack() == nil)
        #expect(history.goForward() == nil)
    }

    @Test("back and forward walk the recorded trail")
    func backAndForwardWalkTheTrail() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")
        history.record("c")

        #expect(history.goBack() == "b")
        #expect(history.goBack() == "a")
        #expect(!history.canGoBack)
        #expect(history.canGoForward)
        #expect(history.goForward() == "b")
        #expect(history.goForward() == "c")
        #expect(!history.canGoForward)
    }

    @Test("re-visiting the current place is not a step")
    func repeatedVisitIsNotAStep() {
        let first = URL(fileURLWithPath: "/tmp/one.swift")
        let second = URL(fileURLWithPath: "/tmp/two.swift")
        var history = NavigationHistory<URL>()
        history.record(first)
        history.record(second)
        history.record(second)

        #expect(history.goBack() == first)
        #expect(!history.canGoBack)
    }

    @Test("a new step after going back discards the forward trail")
    func recordingAfterGoingBackTruncates() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")
        history.record("c")
        _ = history.goBack()

        history.record("z")

        #expect(history.current == "z")
        #expect(!history.canGoForward)
        #expect(history.goBack() == "b")
    }

    @Test("reset forgets the trail")
    func resetForgetsEverything() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")

        history.reset()

        #expect(history.current == nil)
        #expect(!history.canGoBack)
        #expect(!history.canGoForward)
        #expect(history.entries.isEmpty)
        #expect(history.currentIndex == nil)
    }

    @Test("the trail lists every entry and which one is current")
    func entriesAndCurrentIndex() {
        var history = NavigationHistory<String>()
        #expect(history.currentIndex == nil)
        history.record("a")
        history.record("b")
        history.record("c")
        _ = history.goBack()

        #expect(history.entries == ["a", "b", "c"])
        #expect(history.currentIndex == 1)
    }

    @Test("jumping to an entry moves the cursor and keeps the trail")
    func goToIndexKeepsTheTrail() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")
        history.record("c")

        #expect(history.go(to: 0) == "a")

        #expect(history.entries == ["a", "b", "c"])
        #expect(history.current == "a")
        #expect(!history.canGoBack)
        #expect(history.goForward() == "b")
    }

    @Test("jumping outside the trail goes nowhere")
    func goToIndexOutsideTheTrail() {
        var history = NavigationHistory<String>()
        history.record("a")

        #expect(history.go(to: 3) == nil)
        #expect(history.go(to: -1) == nil)
        #expect(history.current == "a")
    }

    @Test("leaving keeps the trail, makes nothing current, and every entry choosable")
    func leavingKeepsTheTrail() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")
        history.leave()

        #expect(history.current == nil)
        #expect(history.currentIndex == nil)
        #expect(!history.canGoBack)
        #expect(!history.canGoForward)
        #expect(history.entries == ["a", "b"])
        #expect(history.go(to: 1) == "b")
        #expect(history.current == "b")
    }

    @Test("a limited trail drops its oldest entries and keeps walking")
    func limitDropsTheOldest() {
        var history = NavigationHistory<String>(limit: 3)
        for place in ["a", "b", "c", "d", "e"] { history.record(place) }

        #expect(history.entries == ["c", "d", "e"])
        #expect(history.current == "e")
        #expect(history.currentIndex == 2)
        #expect(history.goBack() == "d")
        #expect(history.goBack() == "c")
        #expect(!history.canGoBack)
    }

    @Test("a place recorded after leaving goes on the end of the kept trail")
    func recordAfterLeavingAppends() {
        var history = NavigationHistory<String>()
        history.record("a")
        history.record("b")
        history.leave()
        history.record("c")

        #expect(history.entries == ["a", "b", "c"])
        #expect(history.current == "c")
        #expect(history.goBack() == "b")
    }
}
