import AgenticDeveloperHubSDKCore
import AppKit
import Testing
@testable import AgenticDeveloperHubSDKCoreMacOS

/// Only the paths that never enter `runModal` — a unit test cannot sit in a
/// modal loop: a session held back by a prompt already up, and a session
/// ended before its run loop pass came round.
@Suite("AppModalWindowSession", .serialized)
@MainActor
struct AppModalWindowSessionTests {

    private func window() -> NSWindow {
        NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
                 styleMask: [.titled], backing: .buffered, defer: true)
    }

    /// Run loop blocks run in the order they were added, so this resumes
    /// after any pass a session scheduled before it.
    private func nextPass() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            performOnNextRunLoopPass { continuation.resume() }
        }
    }

    @Test func aPromptAlreadyUpHoldsTheSessionBack() async {
        SystemAuthenticationPrompt.begin()
        let session = AppModalWindowSession(window: window())
        session.start()
        await nextPass()
        #expect(!session.isRunning, "the prompt would be behind the modal window")
        #expect(NSApp.modalWindow == nil)
        session.end()
        SystemAuthenticationPrompt.end()
        await nextPass()
        #expect(!session.isRunning, "an ended session never starts")
    }

    @Test func endingBeforeThePassMeansItNeverRuns() async {
        let session = AppModalWindowSession(window: window())
        session.start()
        session.end()
        await nextPass()
        #expect(!session.isRunning)
        #expect(NSApp.modalWindow == nil)
    }
}
