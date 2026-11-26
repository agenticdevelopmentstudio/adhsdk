import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A feed that is paused asks its source for nothing. The Conversations window
/// is built at launch so it can be restored, and its feed read the daemon's
/// conversations every five seconds for the life of the app, open or not.
@MainActor
final class FeedChatSessionPauseTests: XCTestCase {

    private final class ReadCount: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        var value: Int { lock.withLock { count } }
        func note() { lock.withLock { count += 1 } }
    }

    private func subscribe(_ session: FeedChatSession) -> Task<Void, Never> {
        Task { for await _ in session.events() {} }
    }

    private func waitUntil(
        _ what: String, timeout: Duration = .seconds(5), _ condition: () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now > deadline { return XCTFail("timed out waiting until \(what)") }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    func testAFeedBuiltPausedReadsNothingUntilUnpaused() async throws {
        let reads = ReadCount()
        let session = FeedChatSession(refreshInterval: .milliseconds(10), paused: true) {
            reads.note(); return []
        }
        let pump = subscribe(session)
        defer { pump.cancel(); session.close() }

        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reads.value, 0, "a paused feed read its source")

        session.isPaused = false
        try await waitUntil("the unpaused feed read") { reads.value > 0 }
    }

    func testPausingStopsTheReadsAndARefreshWhilePausedWaitsForUnpausing() async throws {
        let reads = ReadCount()
        let session = FeedChatSession(refreshInterval: .milliseconds(10)) {
            reads.note(); return []
        }
        let pump = subscribe(session)
        defer { pump.cancel(); session.close() }
        try await waitUntil("the feed read") { reads.value > 1 }

        session.isPaused = true
        try await Task.sleep(for: .milliseconds(50))
        let atPause = reads.value
        session.refresh()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reads.value, atPause, "a paused feed kept reading")

        session.isPaused = false
        try await waitUntil("unpausing read again") { reads.value > atPause }
    }

    func testAClosedFeedNeverStartsReadingAgain() async throws {
        let reads = ReadCount()
        let session = FeedChatSession(refreshInterval: .milliseconds(10), paused: true) {
            reads.note(); return []
        }
        let pump = subscribe(session)
        defer { pump.cancel() }
        try await Task.sleep(for: .milliseconds(50))
        session.close()

        session.isPaused = false
        session.refresh()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(reads.value, 0, "a closed feed started polling again")
    }

    func testTheWindowReadsTheFeedOnlyWhileItIsOnScreen() {
        let feed = ConversationsViewController(watchesFeed: false) { _, _, _ in [] }
        XCTAssertFalse(feed.watchesFeed)
        let split = ConversationsSplitViewController(feed: feed, autosaveName: nil)
        _ = split.view
        split.viewDidAppear()
        XCTAssertTrue(feed.watchesFeed, "the window on screen does not read its feed")
        split.viewWillDisappear()
        XCTAssertFalse(feed.watchesFeed, "the window gone away still reads its feed")
    }
}
