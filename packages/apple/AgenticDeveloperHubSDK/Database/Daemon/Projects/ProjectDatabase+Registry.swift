#if canImport(AgenticDeveloperHubSDKCore)

import Foundation
import SQLite3

/// The local registry: this file's `project` rows through `ProjectRegistry`.
///
/// Synchronous methods witness the protocol's `async` requirements, so a
/// caller holding the concrete type keeps calling them synchronously, and one
/// holding `any ProjectRegistry` awaits them. Every one runs under `lock` and
/// announces what it changed on `changes` after the lock is released, so a
/// reader woken by the change may read straight back.
extension ProjectDatabase: ProjectRegistry {

    public func projects() throws -> [GitRepo] {
        try locked { try allRepos() }
    }

    public func project(id: UUID) throws -> GitRepo? {
        try locked { try projectRow(id: id) }
    }

    public func project(path: String) throws -> GitRepo? {
        try locked { try repo(path: path, kind: .project) }
    }

    public func insert(_ project: GitRepo) throws {
        try Self.requireProject(project)
        try locked { try insertRow(project) }
        announce(.upserted(project))
    }

    public func update(_ project: GitRepo) throws {
        try Self.requireProject(project)
        let updated: GitRepo? = try locked {
            try executeBound("""
                UPDATE git_repo
                SET path = ?, name = ?, remote = ?, first_seen = ?, last_seen = ?,
                    last_opened = ?
                WHERE id = ? AND kind = 'project'
            """) { stmt in
                bindText(stmt, 1, project.path)
                bindText(stmt, 2, project.name)
                bindOptionalText(stmt, 3, project.remote)
                sqlite3_bind_double(stmt, 4, project.firstSeen.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 5, project.lastSeen.timeIntervalSince1970)
                bindOptionalDate(stmt, 6, project.lastOpened)
                bindText(stmt, 7, project.id.uuidString)
            }
            return sqlite3_changes(database) > 0 ? try projectRow(id: project.id) : nil
        }
        if let updated { announce(.upserted(updated)) }
    }

    public func markOpened(id: UUID, at date: Date) throws {
        let opened: GitRepo? = try locked {
            try executeBound("UPDATE git_repo SET last_opened = ? WHERE id = ? AND kind = 'project'") { stmt in
                sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)
                bindText(stmt, 2, id.uuidString)
            }
            return sqlite3_changes(database) > 0 ? try projectRow(id: id) : nil
        }
        if let opened { announce(.upserted(opened)) }
    }

    /// Deletes the project and, by cascade, its settings, tabs and layout.
    public func delete(id: UUID) throws {
        let deleted: Bool = try locked {
            try executeBound("DELETE FROM git_repo WHERE id = ? AND kind = 'project'") { stmt in
                bindText(stmt, 1, id.uuidString)
            }
            return sqlite3_changes(database) > 0
        }
        if deleted { announce(.deleted(id)) }
    }

    /// The cached snapshot. A read that fails throws; a snapshot that no
    /// longer decodes is a miss, as it is for `cachedRepoState(forRepo:)`.
    public func repoState(id: UUID) throws -> RepoStateSnapshot? {
        guard let json = try locked({ try setting(repoID: id, key: Self.repoStateKey) }),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(RepoStateSnapshot.self, from: data)
    }

    public func saveRepoState(_ state: RepoStateSnapshot, id: UUID) throws {
        try locked { try storeRepoState(state, forRepo: id) }
    }

    public var changes: AsyncStream<ProjectRegistryChange> {
        let (stream, continuation) = AsyncStream<ProjectRegistryChange>.makeStream(
            bufferingPolicy: .unbounded)
        let key = UUID()
        observerLock.withLock { observers[key] = continuation }
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            _ = self.observerLock.withLock { self.observers.removeValue(forKey: key) }
        }
        return stream
    }

    // MARK: - Helpers

    /// The `project` row with this id; a row of another kind is not one.
    func projectRow(id: UUID) throws -> GitRepo? {
        try queryRepos(
            "SELECT \(Self.repoColumns) FROM git_repo WHERE id = ? AND kind = 'project'"
        ) { stmt in
            self.bindText(stmt, 1, id.uuidString)
        }.first
    }

    static func requireProject(_ repo: GitRepo) throws {
        guard repo.kind == .project else { throw ProjectDatabaseError.notAProject(repo.kind) }
    }

    func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    func announce(_ change: ProjectRegistryChange) {
        let current = observerLock.withLock { Array(observers.values) }
        for continuation in current { continuation.yield(change) }
    }
}

#endif
