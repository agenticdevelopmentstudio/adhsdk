// swiftlint:disable identifier_name
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// A throwaway session database for tests that need the real schema (the
/// `ingestion_errors` table, for one). Every test that opens one removes it
/// again with `remove(path:)`.
enum TestDaemonDatabase {

    /// The extension of the directory `uniquePath` makes, so `remove` knows a
    /// parent it may delete from one it must not (an explicit path's).
    static let directoryExtension = "testdb"

    /// A database path inside its own new temp directory, so the database's
    /// -wal and -shm (and any journal) go away with that directory.
    static func uniquePath(prefix: String = "daemontest", file name: String = "session.db") -> String {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString).\(directoryExtension)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(name).path
    }

    /// `uniquePath()` under the name main's callers use.
    static func makeDatabasePath() throws -> String {
        uniquePath()
    }

    /// Opens a fresh `SessionSchema` database at a unique temp path.
    static func makeSessionDatabase(
        path explicitPath: String? = nil,
        accountResolver: AccountResolver = AccountResolver(),
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        file: StaticString = #filePath, line: UInt = #line
    ) throws -> (db: DaemonDatabase, path: String) {
        let path = explicitPath ?? uniquePath()
        do {
            let db = try DaemonDatabase(
                path: path,
                accountResolver: accountResolver,
                migrations: SessionSchema.migrations,
                postMigration: SessionSchema.postMigration,
                statusLineIngest: statusLineIngest,
                sessionUpsertHook: sessionUpsertHook
            )
            return (db, path)
        } catch {
            remove(path: path)
            XCTFail("could not open a session database: \(error)", file: file, line: line)
            throw error
        }
    }

    /// Opens a session database at `path` as a session daemon does: the shared
    /// schema plus the feature hooks (``DaemonDatabase/sessionStatusLineIngest``,
    /// ``DaemonDatabase/sessionUpsertHook``). The feature tests' stand-in for
    /// Stenographer's `DatabaseManager(path:)`; the caller owns the path.
    static func openFeatureDatabase(
        path: String,
        accountResolver: AccountResolver = AccountResolver(),
        deferMigrations: Bool = false
    ) throws -> DaemonDatabase {
        try DaemonDatabase(
            path: path,
            accountResolver: accountResolver,
            deferMigrations: deferMigrations,
            migrations: SessionSchema.migrations,
            postMigration: SessionSchema.postMigration,
            statusLineIngest: DaemonDatabase.sessionStatusLineIngest,
            sessionUpsertHook: DaemonDatabase.sessionUpsertHook
        )
    }

    /// A closed, fully migrated, empty feature database at a unique path, for
    /// tests that open many fresh databases: copying it with
    /// `copyDatabase(from:to:)` gives a database that opens without running a
    /// migration. Remove it with `remove(path:)`.
    static func migratedTemplate(prefix: String = "daemontemplate") throws -> String {
        let path = uniquePath(prefix: prefix)
        // Opened and released here, so SQLite's last close checkpoints the WAL
        // into the main file before anyone copies it.
        _ = try openFeatureDatabase(path: path)
        return path
    }

    /// Copies a closed database (its main file, and its WAL if one survived
    /// the close) to `destination`, which must not exist.
    static func copyDatabase(from source: String, to destination: String) throws {
        try FileManager.default.copyItem(atPath: source, toPath: destination)
        if FileManager.default.fileExists(atPath: source + "-wal") {
            try FileManager.default.copyItem(atPath: source + "-wal", toPath: destination + "-wal")
        }
    }

    /// Removes the database file and its WAL siblings, leaving its directory.
    static func removeFiles(path: String) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }

    /// Removes the database file and its WAL siblings, and the directory
    /// `uniquePath` made for it.
    static func remove(path: String) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
        let directory = URL(fileURLWithPath: path).deletingLastPathComponent()
        if directory.pathExtension == directoryExtension {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
// swiftlint:enable identifier_name
