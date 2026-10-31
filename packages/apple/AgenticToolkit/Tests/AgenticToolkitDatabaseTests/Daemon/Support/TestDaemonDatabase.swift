// swiftlint:disable identifier_name
import XCTest
@testable import AgenticToolkitDatabase

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
