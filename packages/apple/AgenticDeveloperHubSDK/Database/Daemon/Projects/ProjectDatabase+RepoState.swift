#if canImport(AgenticDeveloperHubSDKCore)

import Foundation

/// Snapshots live in `project_setting`, one JSON row per repository: a cache
/// that is rewritten whole on every change and read whole on every switch has
/// no use for columns, and the row goes when the repository does (the table's
/// `ON DELETE CASCADE`).
///
/// These are the synchronous reads a window makes while it is being built;
/// the registry's `repoState(id:)` and `saveRepoState(_:id:)` are the same
/// row through `ProjectRegistry`.
extension ProjectDatabase {

    public static let repoStateKey = "cache.repo-state"

    /// The cached snapshot, or `nil` when there is none or it does not decode
    /// (a cache that cannot be read is a cache miss, never an error).
    public func cachedRepoState(forRepo repoID: UUID) -> RepoStateSnapshot? {
        guard let json = try? setting(repoID: repoID, key: Self.repoStateKey),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(RepoStateSnapshot.self, from: data)
    }

    /// Writes the snapshot, throwing what the write threw.
    public func storeRepoState(_ state: RepoStateSnapshot, forRepo repoID: UUID) throws {
        let data = try JSONEncoder().encode(state)
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw ProjectDatabaseError.executionFailed("a repo state snapshot did not encode as UTF-8")
        }
        try setSetting(repoID: repoID, key: Self.repoStateKey, value: json)
    }
}

#endif
