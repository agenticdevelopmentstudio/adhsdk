#if canImport(AgenticDeveloperHubSDKCore)

import Foundation
import SQLite3

/// Keeps an app's own `Projects.db` holding a `git_repo` row for every
/// project in a shared registry, under the registry's id.
///
/// The app's window state — layout, panes, tabs, browser jars — references
/// `git_repo(id)` with `ON DELETE CASCADE`, so the row has to exist locally
/// before a window for the project can save anything, and has to keep its id
/// for that state to survive a restart. The registry (adhd) is the source of
/// truth for which projects exist; this mirror only follows it.
///
/// Every write is by id and safe to repeat (`idempotency`): an upsert of a
/// row already here updates its columns and keeps everything that references
/// it; a delete of a row already gone does nothing. Writes through the
/// mirror never appear on the database's `changes` — they are the echo of a
/// change that already happened elsewhere.
public struct LocalProjectMirror: Sendable {

    public let database: ProjectDatabase

    public init(database: ProjectDatabase) {
        self.database = database
    }

    /// Applies one registry change to the local file.
    public func apply(_ change: ProjectRegistryChange) throws {
        switch change {
        case .upserted(let project): try upsert(project)
        case .deleted(let id): try delete(id: id)
        }
    }

    /// Upserts every project. Never deletes a local row the list lacks: a
    /// list read while a scan is half applied would otherwise cascade away
    /// the layout of a project that is about to come back. Deletes arrive as
    /// `.deleted` changes.
    public func sync(_ projects: [GitRepo]) throws {
        for project in projects { try upsert(project) }
    }

    /// Inserts the project or, when its id is already here, rewrites its
    /// columns in place — an `UPDATE`, so nothing referencing the row is
    /// cascaded away.
    ///
    /// A local project row at the same path under a different id is deleted
    /// first: `(path, kind)` is unique, and that row's layout is keyed by an
    /// id the registry will never send, so nothing could ever reach it again.
    public func upsert(_ project: GitRepo) throws {
        try ProjectDatabase.requireProject(project)
        try database.locked {
            try database.executeBound(
                "DELETE FROM git_repo WHERE path = ? AND kind = 'project' AND id <> ?"
            ) { stmt in
                database.bindText(stmt, 1, project.path)
                database.bindText(stmt, 2, project.id.uuidString)
            }
            try database.executeBound("""
                INSERT INTO git_repo (\(ProjectDatabase.repoColumns))
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    path = excluded.path,
                    name = excluded.name,
                    remote = excluded.remote,
                    first_seen = excluded.first_seen,
                    last_seen = excluded.last_seen,
                    last_opened = excluded.last_opened
            """) { stmt in
                database.bindText(stmt, 1, project.id.uuidString)
                database.bindText(stmt, 2, project.path)
                database.bindText(stmt, 3, project.name)
                database.bindOptionalText(stmt, 4, project.remote)
                sqlite3_bind_double(stmt, 5, project.firstSeen.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 6, project.lastSeen.timeIntervalSince1970)
                database.bindOptionalDate(stmt, 7, project.lastOpened)
                database.bindText(stmt, 8, project.kind.rawValue)
            }
        }
    }

    /// Deletes the project's local row and, by cascade, its window state.
    /// Only a `project` row: a File Browser or Git window row that happens to
    /// share nothing with the registry is never touched.
    public func delete(id: UUID) throws {
        try database.locked {
            try database.executeBound("DELETE FROM git_repo WHERE id = ? AND kind = 'project'") { stmt in
                database.bindText(stmt, 1, id.uuidString)
            }
        }
    }
}

#endif
