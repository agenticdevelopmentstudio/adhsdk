import Combine
import Foundation
import SQLite3
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

public enum NotationsStoreError: LocalizedError, Equatable {
    case openFailed(String)
    case prepareFailed(String)
    case executionFailed(String)
    case invalidData(String)
    case invalidSchema(String)
    /// The file was written by a newer build than this one understands.
    case newerSchema(found: Int, supported: Int)
    /// A delete asked of a notation that is still active: only archived
    /// notations may be deleted.
    case notArchived(UUID)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let detail): "Notations.db could not be opened: \(detail)"
        case .prepareFailed(let detail): "a Notations.db statement could not be prepared: \(detail)"
        case .executionFailed(let detail): "a Notations.db statement failed: \(detail)"
        case .invalidData(let detail): "Notations.db holds a row this build cannot read: \(detail)"
        case .invalidSchema(let detail): "Notations.db's schema is not one this build knows: \(detail)"
        case .newerSchema(let found, let supported):
            "Notations.db is at schema \(found), written by a newer build; this one supports up to \(supported)"
        case .notArchived(let id): "notation \(id.uuidString) is active; only archived notations can be deleted"
        }
    }
}

/// `Notations.db`: every branch's notation, active and archived.
///
/// Raw sqlite3 with a numbered migration chain, in `PartnerStore`'s shape:
/// WAL, owner-only file modes, one lock around every public call, and
/// `changes` sent after the lock is released so a subscriber may read the
/// store from its sink. Debug builds run several app copies against this one
/// file, so every check-then-write is one `BEGIN IMMEDIATE` transaction.
///
/// "At most one active notation per `(project_id, branch, fork_point)`" is a
/// partial unique index, so it holds against every writer, not only this
/// class.
public final class NotationsStore: @unchecked Sendable {

    public static let currentSchemaVersion = 1

    /// Sent after each committed write, on the calling thread.
    public let changes = PassthroughSubject<Void, Never>()

    let databasePath: String
    private var database: OpaquePointer?
    private let lock = NSLock()

    /// `~/.<token>/Notations.db`, beside `Projects.db`.
    public static func defaultPath(
        inHome home: URL = FileManager.default.homeDirectoryForCurrentUser,
        token: String = AppStorageLocation.token
    ) -> String {
        AppStorageLocation.directory(inHome: home, token: token)
            .appendingPathComponent("Notations.db")
            .path
    }

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        try openDatabase()
        try runMigrations()
        restrictPermissions()
    }

    deinit {
        if let database { sqlite3_close(database) }
    }

    // MARK: - Reads

    /// Every notation, or every one in `state`, by project then branch.
    public func all(state: Notation.State? = nil) throws -> [Notation] {
        try locked {
            if let state {
                return try runQuery(Self.select + " WHERE state = ? ORDER BY project_name, branch, created_at",
                                    [.text(state.rawValue)], Self.notation)
            }
            return try runQuery(Self.select + " ORDER BY project_name, branch, created_at", [], Self.notation)
        }
    }

    public func notation(id: UUID) throws -> Notation? {
        try locked { try readNotation(id: id) }
    }

    /// The active notations of one branch of one project, newest first.
    /// Usually zero or one; more only when the branch was rebased past the
    /// fork point an earlier notation was keyed by.
    public func activeNotations(projectID: UUID, branch: String) throws -> [Notation] {
        try locked {
            try runQuery(Self.select + " WHERE project_id = ? AND branch = ? AND state = 'active' "
                            + "ORDER BY created_at DESC",
                         [.text(projectID.uuidString), .text(branch)], Self.notation)
        }
    }

    public func activeNotation(for key: NotationKey) throws -> Notation? {
        try locked { try readActive(key) }
    }

    // MARK: - Writes

    /// Writes `content` to the notation `id` names when it is still active,
    /// otherwise to the active notation of `key`, creating it if there is
    /// none. Returns the row as stored.
    ///
    /// Two quick edits before the first save's id has come back both arrive
    /// with `id == nil`; the second finds the row the first created through
    /// the key, so neither duplicates nor fails the unique index.
    @discardableResult
    public func save(id: UUID?, key: NotationKey, content: String, at now: Date = Date()) throws -> Notation {
        try write {
            try transaction {
                if let id,
                   try run("UPDATE notations SET content = ?, modified_at = ?, project_name = ?, project_path = ? "
                            + "WHERE id = ? AND state = 'active'",
                           [.text(content), .date(now), .text(key.projectName), .text(key.projectPath),
                            .text(id.uuidString)]) > 0,
                   let stored = try readNotation(id: id) {
                    return stored
                }
                if let existing = try readActive(key) {
                    try run("UPDATE notations SET content = ?, modified_at = ?, project_name = ?, project_path = ? "
                            + "WHERE id = ?",
                            [.text(content), .date(now), .text(key.projectName), .text(key.projectPath),
                             .text(existing.id.uuidString)])
                    guard let stored = try readNotation(id: existing.id) else {
                        throw NotationsStoreError.invalidData("notation \(existing.id) vanished mid-transaction")
                    }
                    return stored
                }
                let created = Notation(
                    projectID: key.projectID, projectName: key.projectName, projectPath: key.projectPath,
                    branch: key.branch, forkPoint: key.forkPoint, content: content,
                    createdAt: now, modifiedAt: now)
                try insert(created)
                return created
            }
        }
    }

    /// Replaces the content of the notation `id`, active or archived.
    /// False when there is no such notation.
    @discardableResult
    public func updateContent(id: UUID, content: String, at now: Date = Date()) throws -> Bool {
        try write {
            try run("UPDATE notations SET content = ?, modified_at = ? WHERE id = ?",
                    [.text(content), .date(now), .text(id.uuidString)]) > 0
        }
    }

    /// Records the branch tip a reconcile saw. Not a user edit, so
    /// `modified_at` stays as it was.
    public func recordTip(id: UUID, tip: String?) throws {
        try write {
            try run("UPDATE notations SET last_tip = ? WHERE id = ?", [.optText(tip), .text(id.uuidString)])
        }
    }

    /// Archives the notation `id`. False when it is not active (already
    /// archived, or gone).
    @discardableResult
    public func archive(id: UUID, at now: Date = Date()) throws -> Bool {
        try write {
            try run("UPDATE notations SET state = 'archived', archived_at = ? WHERE id = ? AND state = 'active'",
                    [.date(now), .text(id.uuidString)]) > 0
        }
    }

    /// Deletes the archived notation `id`. Throws `.notArchived` for an
    /// active one; false when there is no such notation.
    @discardableResult
    public func deleteArchived(id: UUID) throws -> Bool {
        try write {
            try transaction {
                guard let existing = try readNotation(id: id) else { return false }
                guard existing.state == .archived else { throw NotationsStoreError.notArchived(id) }
                return try run("DELETE FROM notations WHERE id = ?", [.text(id.uuidString)]) > 0
            }
        }
    }

    // MARK: - Schema

    private func openDatabase() throws {
        let result = sqlite3_open_v2(
            databasePath, &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil)
        guard result == SQLITE_OK else { throw NotationsStoreError.openFailed(lastErrorMessage) }
        try execute("PRAGMA journal_mode=WAL")
        sqlite3_busy_timeout(database, 5_000)
    }

    /// One transaction around the whole chain, so a crash cannot leave the
    /// schema changed with the version row still behind it.
    private func runMigrations() throws {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            try execute("""
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version INTEGER PRIMARY KEY,
                    applied_at TEXT NOT NULL DEFAULT (datetime('now'))
                )
            """)
            let stored = try schemaVersion()
            guard stored <= Self.currentSchemaVersion else {
                throw NotationsStoreError.newerSchema(found: stored, supported: Self.currentSchemaVersion)
            }
            if stored < 1 {
                try migration001_createSchema()
            }
            let migrated = try schemaVersion()
            guard migrated == Self.currentSchemaVersion else {
                throw NotationsStoreError.invalidSchema(
                    "schema version \(migrated) after migrating, expected \(Self.currentSchemaVersion)")
            }
            try execute("COMMIT")
        } catch {
            _ = try? execute("ROLLBACK")
            throw error
        }
    }

    /// Notes can hold anything the owner writes, so the file and its WAL
    /// files are owner-only. Called after the migration chain, once the WAL
    /// files exist.
    private func restrictPermissions() {
        for suffix in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: databasePath + suffix) {
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: databasePath + suffix)
        }
    }

    func schemaVersion() throws -> Int {
        let rows = try runQuery("SELECT COALESCE(MAX(version), 0) FROM schema_migrations", []) { Int($0.int(0)) }
        return rows.first ?? 0
    }

    private func migration001_createSchema() throws {
        let statements = [
            """
            CREATE TABLE IF NOT EXISTS notations (
                id TEXT PRIMARY KEY,
                project_id TEXT NOT NULL,
                project_name TEXT NOT NULL,
                project_path TEXT NOT NULL,
                branch TEXT NOT NULL,
                fork_point TEXT NOT NULL,
                last_tip TEXT,
                content TEXT NOT NULL,
                state TEXT NOT NULL CHECK (state IN ('active', 'archived')),
                created_at TEXT NOT NULL,
                modified_at TEXT NOT NULL,
                archived_at TEXT
            )
            """,
            """
            CREATE UNIQUE INDEX IF NOT EXISTS idx_notations_one_active
                ON notations(project_id, branch, fork_point) WHERE state = 'active'
            """,
            "CREATE INDEX IF NOT EXISTS idx_notations_state ON notations(state, project_name, branch)",
            "INSERT INTO schema_migrations (version) VALUES (1)"
        ]
        for sql in statements { try execute(sql) }
    }

    // MARK: - Rows

    private static let select = """
        SELECT id, project_id, project_name, project_path, branch, fork_point, last_tip, content, state,
               created_at, modified_at, archived_at FROM notations
        """

    private static func notation(_ row: Row) throws -> Notation {
        guard let id = UUID(uuidString: row.text(0)) else { throw NotationsStoreError.invalidData("bad id") }
        guard let projectID = UUID(uuidString: row.text(1)) else {
            throw NotationsStoreError.invalidData("bad project id for \(id)")
        }
        guard let state = Notation.State(rawValue: row.text(8)) else {
            throw NotationsStoreError.invalidData("bad state for \(id)")
        }
        return Notation(
            id: id, projectID: projectID, projectName: row.text(2), projectPath: row.text(3),
            branch: row.text(4), forkPoint: row.text(5), lastTip: row.optText(6), content: row.text(7),
            state: state, createdAt: try row.date(9), modifiedAt: try row.date(10),
            archivedAt: try row.optDate(11))
    }

    /// Caller holds the lock.
    private func readNotation(id: UUID) throws -> Notation? {
        try runQuery(Self.select + " WHERE id = ?", [.text(id.uuidString)], Self.notation).first
    }

    /// Caller holds the lock.
    private func readActive(_ key: NotationKey) throws -> Notation? {
        try runQuery(Self.select + " WHERE project_id = ? AND branch = ? AND fork_point = ? AND state = 'active'",
                     [.text(key.projectID.uuidString), .text(key.branch), .text(key.forkPoint)],
                     Self.notation).first
    }

    /// Caller holds the lock.
    private func insert(_ notation: Notation) throws {
        try run("""
            INSERT INTO notations (id, project_id, project_name, project_path, branch, fork_point, last_tip,
                                   content, state, created_at, modified_at, archived_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [.text(notation.id.uuidString), .text(notation.projectID.uuidString), .text(notation.projectName),
             .text(notation.projectPath), .text(notation.branch), .text(notation.forkPoint),
             .optText(notation.lastTip), .text(notation.content), .text(notation.state.rawValue),
             .date(notation.createdAt), .date(notation.modifiedAt), .optDate(notation.archivedAt)])
    }

    // MARK: - Dates

    // ISO8601DateFormatter is documented thread-safe.
    nonisolated(unsafe) private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func date(from string: String) throws -> Date {
        guard let date = formatter.date(from: string) else {
            throw NotationsStoreError.invalidData("bad date \(string)")
        }
        return date
    }

    // MARK: - SQLite plumbing

    enum Value {
        case text(String)
        case int(Int64)
        case null

        static func optText(_ value: String?) -> Value { value.map { .text($0) } ?? .null }
        static func optDate(_ value: Date?) -> Value { value.map { .date($0) } ?? .null }
        static func date(_ value: Date) -> Value { .text(NotationsStore.string(from: value)) }
    }

    struct Row {
        let stmt: OpaquePointer?

        func text(_ index: Int32) -> String { optText(index) ?? "" }
        func optText(_ index: Int32) -> String? { sqlite3_column_text(stmt, index).map { String(cString: $0) } }
        func int(_ index: Int32) -> Int64 { sqlite3_column_int64(stmt, index) }
        func date(_ index: Int32) throws -> Date { try NotationsStore.date(from: text(index)) }
        func optDate(_ index: Int32) throws -> Date? { try optText(index).map { try NotationsStore.date(from: $0) } }
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var lastErrorMessage: String {
        database.map { String(cString: sqlite3_errmsg($0)) } ?? "Database not open"
    }

    @discardableResult
    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    /// Runs `body` under the lock, then announces the change once the lock is
    /// released — whether or not `body` changed a row, since a subscriber
    /// re-reads rather than trusting a count.
    @discardableResult
    private func write<T>(_ body: () throws -> T) throws -> T {
        let result = try locked(body)
        changes.send()
        return result
    }

    /// One `BEGIN IMMEDIATE` transaction, rolled back if `body` throws.
    /// Caller holds the lock; transactions do not nest.
    private func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE TRANSACTION")
        do {
            let result = try body()
            try execute("COMMIT")
            return result
        } catch {
            _ = try? execute("ROLLBACK")
            throw error
        }
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw NotationsStoreError.executionFailed(message)
        }
    }

    private func prepare(_ sql: String, _ binds: [Value]) throws -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            sqlite3_finalize(stmt)
            throw NotationsStoreError.prepareFailed(lastErrorMessage)
        }
        for (offset, bind) in binds.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch bind {
            case .text(let value): result = sqlite3_bind_text(stmt, index, value, -1, Self.transient)
            case .int(let value): result = sqlite3_bind_int64(stmt, index, value)
            case .null: result = sqlite3_bind_null(stmt, index)
            }
            guard result == SQLITE_OK else {
                let message = lastErrorMessage
                sqlite3_finalize(stmt)
                throw NotationsStoreError.prepareFailed(message)
            }
        }
        return stmt
    }

    /// Executes one statement and returns the number of rows it changed.
    /// Caller holds the lock.
    @discardableResult
    private func run(_ sql: String, _ binds: [Value]) throws -> Int {
        let stmt = try prepare(sql, binds)
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw NotationsStoreError.executionFailed(lastErrorMessage)
        }
        return Int(sqlite3_changes(database))
    }

    /// Maps every result row of `sql`. Caller holds the lock.
    private func runQuery<T>(_ sql: String, _ binds: [Value], _ map: (Row) throws -> T) throws -> [T] {
        let stmt = try prepare(sql, binds)
        defer { sqlite3_finalize(stmt) }
        var results: [T] = []
        while true {
            let status = sqlite3_step(stmt)
            if status == SQLITE_DONE { return results }
            guard status == SQLITE_ROW else { throw NotationsStoreError.executionFailed(lastErrorMessage) }
            results.append(try map(Row(stmt: stmt)))
        }
    }
}
