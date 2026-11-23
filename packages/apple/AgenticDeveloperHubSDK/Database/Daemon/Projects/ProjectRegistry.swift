#if canImport(AgenticDeveloperHubSDKCore)

import Foundation

/// What happened to one project in a registry.
///
/// Carries the row, not just its id, so a reader that keeps its own copy —
/// an app's local `Projects.db` (`LocalProjectMirror`), a coordinator's list —
/// can apply it without asking again.
public enum ProjectRegistryChange: Sendable, Equatable {
    /// The project was inserted, or one of its columns changed (a rename, a
    /// move, an open). The value is the whole row as it now is.
    case upserted(GitRepo)
    /// The project is gone.
    case deleted(UUID)

    /// The project this change is about.
    public var id: UUID {
        switch self {
        case .upserted(let repo): return repo.id
        case .deleted(let id): return id
        }
    }
}

/// The list of projects — `git_repo` rows of kind `project` — and the
/// repo-state cache kept beside each one.
///
/// Two implementations: `ProjectDatabase`, for an app that keeps its own
/// registry, and adhd's client, for the apps that share one through the
/// daemon (apps suite Phase 4, Decision 4). Window state — layout, panes,
/// standalone-window rows, browser jars — is not here: it stays in each app's
/// own `ProjectDatabase`, keyed by the same ids.
///
/// **Kind `project` only.** `insert(_:)` refuses any other kind, and no read
/// returns one; a File Browser, Document or Git window row is window state.
public protocol ProjectRegistry: Sendable {

    /// Every project, ordered by name, case-insensitively.
    func projects() async throws -> [GitRepo]

    func project(id: UUID) async throws -> GitRepo?

    /// The project whose directory is exactly `path`.
    func project(path: String) async throws -> GitRepo?

    /// Adds a project, keeping its id. Throws for a row of any other kind.
    func insert(_ project: GitRepo) async throws

    /// Writes every mutable column of the project with this id.
    func update(_ project: GitRepo) async throws

    /// Records that a project window was opened, which is what "recent" sorts by.
    func markOpened(id: UUID, at date: Date) async throws

    /// Deletes the project, and with it everything this registry keeps for it.
    func delete(id: UUID) async throws

    /// The project's last known checkouts and branches, or `nil`.
    func repoState(id: UUID) async throws -> RepoStateSnapshot?

    func saveRepoState(_ state: RepoStateSnapshot, id: UUID) async throws

    /// Every change made through this registry from now on, by anyone. Each
    /// read returns a new stream with its own subscription, ended when the
    /// reader stops iterating it.
    var changes: AsyncStream<ProjectRegistryChange> { get }
}

extension ProjectRegistry {
    /// Stamps the project as opened now.
    public func markOpened(id: UUID) async throws {
        try await markOpened(id: id, at: Date())
    }
}

#endif
