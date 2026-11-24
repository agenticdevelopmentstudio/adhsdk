import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A provider that answers `answer` and records every request's roots and `since`.
private final class RecordingProvider: GitSessionsProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [(roots: [String], since: Date)] = []
    let answer: [GitAgentSession]

    init(answer: [GitAgentSession]) { self.answer = answer }

    var requests: [(roots: [String], since: Date)] { lock.withLock { recorded } }

    func sessions(under roots: [String], since: Date) async -> [GitAgentSession] {
        lock.withLock { recorded.append((roots, since)) }
        return answer
    }
}

@MainActor
@Suite("GitAgentSessionCache")
struct GitAgentSessionCacheTests {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    private static let found = [
        GitAgentSession(id: "s1", title: nil, cwd: "/repo", branch: nil, startedAt: start, lastActivityAt: start)
    ]

    @Test("reads 90 days back over the roots, at most once a minute, and reports the change")
    func refreshes() async {
        let provider = RecordingProvider(answer: Self.found)
        var now = Self.start
        let cache = GitAgentSessionCache(provider: provider, roots: { ["/repo", "/wt"] }, now: { now })
        var changes = 0
        cache.onChange = { changes += 1 }

        cache.refreshIfStale()
        await cache.fetchTask?.value
        #expect(cache.sessions == Self.found)
        #expect(changes == 1)
        #expect(provider.requests.count == 1)
        #expect(provider.requests.first?.roots == ["/repo", "/wt"])
        #expect(provider.requests.first?.since == Self.start.addingTimeInterval(-GitAgentSessionCache.window))

        now = Self.start.addingTimeInterval(59)
        cache.refreshIfStale()
        #expect(provider.requests.count == 1)

        now = Self.start.addingTimeInterval(60)
        cache.refreshIfStale()
        await cache.fetchTask?.value
        #expect(provider.requests.count == 2)
        #expect(changes == 1)
    }
}
