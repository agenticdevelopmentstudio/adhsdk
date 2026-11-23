import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// Reads a repository's current state from disk.
public protocol RepoStateReading: Sendable {
    func readState(at directory: URL) async throws -> RepoStateSnapshot
}

/// Reads it through `GitClient.worktrees` and `GitClient.branches`, run together.
public struct GitRepoStateReader: RepoStateReading {
    private let gitClient: GitClient

    public init(gitClient: GitClient = .shared) {
        self.gitClient = gitClient
    }

    public func readState(at directory: URL) async throws -> RepoStateSnapshot {
        async let worktrees = gitClient.worktrees(in: directory)
        async let branches = gitClient.branches(in: directory)
        return RepoStateSnapshot(worktrees: try await worktrees, branches: try await branches, refreshedAt: Date())
    }
}
