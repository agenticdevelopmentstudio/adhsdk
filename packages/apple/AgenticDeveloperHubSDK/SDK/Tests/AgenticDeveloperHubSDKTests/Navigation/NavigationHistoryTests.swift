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
    }
}
