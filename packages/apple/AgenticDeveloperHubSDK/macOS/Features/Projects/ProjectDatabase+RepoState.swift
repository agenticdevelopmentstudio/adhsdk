import Foundation

/// Snapshots live in `project_setting`, one JSON row per repository: a cache
/// that is rewritten whole on every change and read whole on every switch has
/// no use for columns, and the row goes when the repository does (the table's
/// `ON DELETE CASCADE`).
extension ProjectDatabase: RepoStateStore {

    static let repoStateKey = "cache.repo-state"

    public func cachedRepoState(forRepo repoID: UUID) -> RepoStateSnapshot? {
        guard let json = try? setting(repoID: repoID, key: Self.repoStateKey),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(RepoStateSnapshot.self, from: data)
    }

    public func saveRepoState(_ state: RepoStateSnapshot, forRepo repoID: UUID) {
        guard let data = try? JSONEncoder().encode(state),
              let json = String(bytes: data, encoding: .utf8) else { return }
        try? setSetting(repoID: repoID, key: Self.repoStateKey, value: json)
    }
}
