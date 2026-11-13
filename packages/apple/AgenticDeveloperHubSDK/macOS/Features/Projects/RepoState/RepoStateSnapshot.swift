import Foundation
import AgenticDeveloperHubSDKCore

/// What a repository looked like on disk the last time anyone read it: its
/// checkouts (the main one and every worktree) and its local branches.
///
/// Cached per project so a project window can be shown at once from the last
/// known state and corrected when git answers, instead of waiting on git
/// before anything appears.
public struct RepoStateSnapshot: Codable, Equatable, Sendable {

    public struct Checkout: Codable, Equatable, Sendable {
        public let path: String
        public let branch: String?
        public let isMain: Bool

        public init(path: String, branch: String?, isMain: Bool) {
            self.path = path
            self.branch = branch
            self.isMain = isMain
        }
    }

    /// Main checkout first, then the worktrees in git's order.
    public let checkouts: [Checkout]
    /// Local branch names, in git's order.
    public let branches: [String]
    public let refreshedAt: Date

    public init(checkouts: [Checkout], branches: [String], refreshedAt: Date) {
        self.checkouts = checkouts
        self.branches = branches
        self.refreshedAt = refreshedAt
    }

    /// Built from what git answered. Ordered the way `ProjectController`
    /// orders checkouts, so a window seeded from the cache matches the one a
    /// scan would have built.
    public init(worktrees: [GitWorktree], branches: [GitBranch], refreshedAt: Date) {
        let found = ProjectCheckout.checkouts(from: worktrees)
        let ordered = found.filter(\.isMain) + found.filter { !$0.isMain }
        self.init(
            checkouts: ordered.map { Checkout(path: $0.directory.path, branch: $0.branch, isMain: $0.isMain) },
            branches: branches.map(\.name),
            refreshedAt: refreshedAt
        )
    }

    /// The checkouts as a project window uses them.
    public var projectCheckouts: [ProjectCheckout] {
        checkouts.map {
            ProjectCheckout(
                directory: URL(fileURLWithPath: $0.path, isDirectory: true), branch: $0.branch, isMain: $0.isMain)
        }
    }

    /// The branch checked out at `directory`, if the snapshot knows it.
    public func branch(at directory: URL) -> String? {
        let path = directory.resolvingSymlinksInPath().path
        return checkouts.first { $0.path == path }?.branch
    }

    /// Same checkouts and branches, whenever each was read. What decides
    /// whether a refresh is worth a write and a notification.
    public func hasSameState(as other: RepoStateSnapshot) -> Bool {
        checkouts == other.checkouts && branches == other.branches
    }
}

/// Where snapshots are kept, so the cache, the refresher and the window
/// manager can each be tested with an in-memory one (`dependency-injection`).
@MainActor
public protocol RepoStateStore: AnyObject {
    func cachedRepoState(forRepo repoID: UUID) -> RepoStateSnapshot?
    func saveRepoState(_ state: RepoStateSnapshot, forRepo repoID: UUID)
}

/// Reads a repository's current state from disk.
public protocol RepoStateReading: Sendable {
    func readState(at directory: URL) async throws -> RepoStateSnapshot
}

/// Reads it with git: `worktree list` and `for-each-ref refs/heads`, run
/// together.
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
