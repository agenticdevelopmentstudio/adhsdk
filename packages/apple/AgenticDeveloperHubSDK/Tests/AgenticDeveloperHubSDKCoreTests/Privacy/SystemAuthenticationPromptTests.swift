import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Prompts can overlap (a terminal shown while the words editor asks), so
/// the announcement is a count: it goes up with the first and down with the
/// last, and a stray `end()` never drives it below none.
@Suite("SystemAuthenticationPrompt", .serialized)
@MainActor
struct SystemAuthenticationPromptTests {

    @Test func overlappingPromptsAnnounceOnlyTheFirstBeginAndTheLastEnd() {
        var changes: [Bool] = []
        let observer = NotificationCenter.default.addObserver(
            forName: SystemAuthenticationPrompt.didChangeNotification, object: nil, queue: nil
        ) { _ in MainActor.assumeIsolated { changes.append(SystemAuthenticationPrompt.isShowing) } }
        defer { NotificationCenter.default.removeObserver(observer) }

        #expect(!SystemAuthenticationPrompt.isShowing)
        SystemAuthenticationPrompt.begin()
        SystemAuthenticationPrompt.begin()
        #expect(SystemAuthenticationPrompt.isShowing)
        SystemAuthenticationPrompt.end()
        #expect(SystemAuthenticationPrompt.isShowing, "one prompt is still up")
        SystemAuthenticationPrompt.end()
        #expect(!SystemAuthenticationPrompt.isShowing)
        #expect(changes == [true, false])
    }

    @Test func aStrayEndChangesNothing() {
        SystemAuthenticationPrompt.end()
        #expect(!SystemAuthenticationPrompt.isShowing)
        SystemAuthenticationPrompt.begin()
        #expect(SystemAuthenticationPrompt.isShowing)
        SystemAuthenticationPrompt.end()
        #expect(!SystemAuthenticationPrompt.isShowing)
    }
}
