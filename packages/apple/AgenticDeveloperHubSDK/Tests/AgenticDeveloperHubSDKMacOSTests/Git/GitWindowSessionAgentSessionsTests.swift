import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

private final class QuietWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// Answers every session it was given, whatever the roots.
private struct FixedProvider: GitSessionsProviding {
    let all: [GitAgentSession]
    func sessions(under roots: [String], since: Date) async -> [GitAgentSession] { all }
}

/// The window's agent-session wiring (recipe `workspace/git/git-window`, "Agent sessions").
@Suite("GitWindowSession agent sessions", .serialized)
@MainActor
struct GitWindowSessionAgentSessionsTests {
    private let client = GitClient(configuration: .tests)

    private func window(_ repository: GitTestRepository,
                        sessions: (any GitSessionsProviding)?) async -> GitWindowSession {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: QuietWatcher())
        let session = GitWindowSession(model: model, client: client, coloring: nil, sessions: sessions)
        await session.start()
        return session
    }

    @Test("without a provider nothing is wired")
    func noProvider() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-sessions")
        defer { repository.tearDown() }
        let session = await window(repository, sessions: nil)
        #expect(session.agentSessionCache == nil)
        #expect(session.detail.agentSessionMatches == nil)
        #expect(session.sidebar.agentSessionsOnBranch == nil)
    }

    @Test("with a provider, a branch's sessions under the root reach the sidebar, and open reaches both views")
    func provider() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-sessions")
        defer { repository.tearDown() }
        let now = Date()
        let inside = GitAgentSession(id: "in", title: nil, cwd: repository.root.path, branch: "main",
                                     startedAt: now, lastActivityAt: now)
        let outside = GitAgentSession(id: "out", title: nil, cwd: "/elsewhere", branch: "main",
                                      startedAt: now, lastActivityAt: now)
        let session = await window(repository, sessions: FixedProvider(all: [inside, outside]))
        await session.agentSessionCache?.fetchTask?.value
        #expect(session.agentSessionCache?.sessions.count == 2)
        let branch = GitRef(kind: .localBranch, fullName: "refs/heads/main", name: "main", target: "x",
                            upstream: nil, ahead: 0, behind: 0, isHead: true)
        #expect(session.sidebar.agentSessionsOnBranch?(branch).map(\.id) == ["in"])

        var opened: [String] = []
        session.onOpenAgentSession = { opened.append($0) }
        session.detail.onOpenAgentSession?("a")
        session.sidebar.onOpenAgentSession?("b")
        #expect(opened == ["a", "b"])
    }
}
