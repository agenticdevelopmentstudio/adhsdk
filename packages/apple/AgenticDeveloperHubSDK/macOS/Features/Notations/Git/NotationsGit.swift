import Foundation
import AgenticDeveloperHubSDKCore

/// The git questions Notations asks, over `GitClient` (through `ReviewGit`'s
/// verbs), with a short timeout: these run on every HEAD change and every
/// reconcile, and none of them writes.
public struct NotationsGit: Sendable {

    public static let timeoutSeconds: TimeInterval = 30

    public static let client = GitClient(configuration: {
        var configuration = await GitClientConfiguration.fromSettings()
        configuration.timeout = timeoutSeconds
        return configuration
    })

    private let client: GitClient
    private let git: ReviewGit

    public init(client: GitClient = NotationsGit.client) {
        self.client = client
        self.git = ReviewGit(client: client)
    }

    /// The checked-out branch in `directory`; `nil` on a detached HEAD.
    public func currentBranch(in directory: URL) async throws -> String? {
        try await client.currentBranch(in: directory)
    }

    public func defaultBranch(in directory: URL) async throws -> String {
        try await git.defaultBranch(in: directory)
    }

    /// The commit `refs/heads/<branch>` names, or `nil` when the ref is gone.
    public func tip(of branch: String, in directory: URL) async throws -> String? {
        try await git.resolveCommit("refs/heads/\(branch)", in: directory)
    }

    /// `git merge-base <default> <branch>`: where the branch left the default
    /// branch. For the default branch itself that is its own tip.
    public func forkPoint(of branch: String, defaultBranch: String, in directory: URL) async throws -> String {
        try await git.run(["merge-base", "refs/heads/\(defaultBranch)", "refs/heads/\(branch)"], in: directory)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func isAncestor(_ sha: String, of ref: String, in directory: URL) async throws -> Bool {
        try await git.isAncestor(sha, of: ref, in: directory)
    }

    /// Whether `origin` has a head named `branch`, asked read-only with
    /// `ls-remote` (never a fetch). `nil` when it could not be asked: no
    /// origin, no network, a timeout.
    public func remoteHeadExists(_ branch: String, in directory: URL) async -> Bool? {
        do {
            let output = try await git.run(["ls-remote", "--heads", "origin", "refs/heads/\(branch)"], in: directory)
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return nil
        }
    }

    /// Where HEAD lives for the checkout at `directory`; a linked worktree's
    /// HEAD is in its own git directory, not the main one.
    public func headPath(in directory: URL) async throws -> URL {
        try await client.gitPath("HEAD", in: directory)
    }
}

/// What a pane is looking at: the branch its working directory has checked
/// out and the notation that belongs to it, if one has been written yet.
public enum NotationResolution: Sendable, Equatable {
    /// A branch is checked out. `notation` is `nil` until the first edit.
    case branch(key: NotationKey, notation: Notation?)
    /// HEAD is detached: there is no branch to keep notes for.
    case detached
    /// The directory is not a git checkout, or git failed.
    case unavailable(String)
}

/// Resolves a working directory to its branch's notation.
public struct NotationResolver: Sendable {

    private let git: NotationsGit
    private let store: NotationsStore

    public init(git: NotationsGit = NotationsGit(), store: NotationsStore) {
        self.git = git
        self.store = store
    }

    /// `projectPath` is the project's own directory, recorded on the row;
    /// `workingDirectory` is the checkout the pane runs in (the project, or
    /// one of its worktrees), whose HEAD decides the branch.
    public func resolve(
        projectID: UUID,
        projectName: String,
        projectPath: String,
        workingDirectory: URL
    ) async -> NotationResolution {
        do {
            guard let branch = try await git.currentBranch(in: workingDirectory) else { return .detached }
            let (key, notation) = try await resolve(
                branch: branch, projectID: projectID, projectName: projectName, projectPath: projectPath,
                workingDirectory: workingDirectory)
            return .branch(key: key, notation: notation)
        } catch {
            return .unavailable(error.localizedDescription)
        }
    }

    /// The key `branch` has now and the active notation that belongs to it,
    /// checked out or not (`notations_write` names a branch outright). A row
    /// whose fork point is an ancestor of the tip still belongs to the branch
    /// after a rebase moved its merge-base (`NotationLifecycle.resolve`).
    public func resolve(
        branch: String,
        projectID: UUID,
        projectName: String,
        projectPath: String,
        workingDirectory: URL
    ) async throws -> (key: NotationKey, notation: Notation?) {
        let defaultBranch = try await git.defaultBranch(in: workingDirectory)
        let forkPoint = try await git.forkPoint(of: branch, defaultBranch: defaultBranch, in: workingDirectory)
        let key = NotationKey(projectID: projectID, projectName: projectName, projectPath: projectPath,
                              branch: branch, forkPoint: forkPoint)
        let candidates = try store.activeNotations(projectID: projectID, branch: branch)
        var ancestry: [String: Bool] = [:]
        for candidate in candidates where candidate.forkPoint != forkPoint {
            ancestry[candidate.forkPoint] = (try? await git.isAncestor(
                candidate.forkPoint, of: "refs/heads/\(branch)", in: workingDirectory)) ?? false
        }
        let notation = NotationLifecycle.resolve(
            candidates: candidates, currentForkPoint: forkPoint,
            isAncestorOfTip: { ancestry[$0] ?? false })
        return (key, notation)
    }
}
