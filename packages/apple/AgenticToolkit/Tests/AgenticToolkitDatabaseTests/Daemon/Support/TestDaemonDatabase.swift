// swiftlint:disable identifier_name
import XCTest
@testable import AgenticToolkitDatabase

/// A throwaway session database for tests that need the real schema (the
/// `ingestion_errors` table, for one). Every test that opens one removes it
/// again with `remove(path:)`.
enum TestDaemonDatabase {

    private static let directoryPrefix = "daemontest-"

    /// A database path inside its own new temp directory, so the -wal and -shm
    /// files SQLite makes beside it go when `remove(path:)` removes the directory.
    static func makeDatabasePath() throws -> String {
        let directory = NSTemporaryDirectory() + directoryPrefix + UUID().uuidString
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        return directory + "/session.db"
    }

    /// Opens a fresh `SessionSchema` database at a unique temp path.
    static func makeSessionDatabase(
        path explicitPath: String? = nil,
        accountResolver: AccountResolver = AccountResolver(),
        statusLineIngest: DaemonDatabase.StatusLineIngest? = nil,
        sessionUpsertHook: DaemonDatabase.SessionUpsertHook? = nil,
        file: StaticString = #filePath, line: UInt = #line
    ) throws -> (db: DaemonDatabase, path: String) {
        let path = try explicitPath ?? makeDatabasePath()
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

    /// Removes the database and its WAL siblings, along with the directory
    /// `makeDatabasePath()` made for it. A path the caller chose keeps its directory.
    static func remove(path: String) {
        let directory = (path as NSString).deletingLastPathComponent
        if (directory as NSString).lastPathComponent.hasPrefix(directoryPrefix) {
            try? FileManager.default.removeItem(atPath: directory)
            return
        }
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path + suffix)
        }
    }
}
// swiftlint:enable identifier_name
