#if canImport(AgenticDeveloperHubSDKCore)
import Foundation
import GRDB

/// One shared setting as stored: its key, its JSON value and the version the
/// last write gave it.
public struct SharedSetting: Equatable, Sendable {
    public let key: String
    /// One JSON value (a fragment such as `13` or `"Menlo"` included).
    public let value: Data
    /// 1 after the first write, one more after each write since.
    public let version: Int64

    public init(key: String, value: Data, version: Int64) {
        self.key = key
        self.value = value
        self.version = version
    }
}

/// The suite's shared settings (theme, terminal, AI providers): one SQLite
/// table of key, JSON value and version, which adhd opens as
/// `<data dir>/apps/SharedSettings.db` and is the only writer of.
///
/// The version is optimistic concurrency, not history: a writer that read a
/// value at version N passes `expectedVersion: N`, and the write is refused
/// with ``SharedSettingsStoreError/versionConflict(key:expected:actual:)`` if
/// someone else wrote in between. A key with no row is at version 0. A writer
/// that passes no expected version always wins, which is what a settings pane
/// that simply sets a value wants.
///
/// Every method runs on the caller's thread and returns when the file has
/// answered, through `BoundedDatabase` like every other store here.
public final class SharedSettingsStore: @unchecked Sendable {

    public static let fileName = "SharedSettings.db"

    public let databasePath: String
    private let database: BoundedDatabase

    private let lock = NSLock()
    private var subscribers: [UUID: AsyncStream<String>.Continuation] = [:]

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        database = try BoundedDatabase(path: path)
        try database.write { connection in
            try connection.execute(sql: """
                CREATE TABLE IF NOT EXISTS shared_setting (
                    key TEXT PRIMARY KEY NOT NULL,
                    value TEXT NOT NULL,
                    version INTEGER NOT NULL
                )
            """)
        }
    }

    deinit {
        lock.lock()
        let continuations = Array(subscribers.values)
        subscribers.removeAll()
        lock.unlock()
        continuations.forEach { $0.finish() }
    }

    // MARK: - Reading

    /// The stored setting for `key`, or nil when it is not set.
    public func value(forKey key: String) throws -> SharedSetting? {
        try database.read { connection in
            try Row.fetchOne(
                connection,
                sql: "SELECT key, value, version FROM shared_setting WHERE key = ?",
                arguments: [key]
            ).map(Self.setting(from:))
        }
    }

    /// Every stored setting, by key order.
    public func all() throws -> [SharedSetting] {
        try database.read { connection in
            try Row.fetchAll(connection, sql: "SELECT key, value, version FROM shared_setting ORDER BY key")
                .map(Self.setting(from:))
        }
    }

    // MARK: - Writing

    /// Stores `value` (one JSON value) for `key` and returns the stored
    /// setting with its new version.
    ///
    /// - Parameter expectedVersion: the version the writer last read (0 for a
    ///   key it saw unset); nil writes whatever is there.
    @discardableResult
    public func set(_ value: Data, forKey key: String, expectedVersion: Int64? = nil) throws -> SharedSetting {
        let json = try Self.validatedJSON(value, forKey: key)
        let stored = try database.write { connection -> SharedSetting in
            let current = try Self.version(ofKey: key, in: connection)
            try Self.check(key: key, expected: expectedVersion, actual: current)
            let next = current + 1
            try connection.execute(
                sql: """
                    INSERT INTO shared_setting (key, value, version) VALUES (?, ?, ?)
                    ON CONFLICT(key) DO UPDATE SET value = excluded.value, version = excluded.version
                """,
                arguments: [key, json, next]
            )
            return SharedSetting(key: key, value: Data(json.utf8), version: next)
        }
        changed(key)
        return stored
    }

    /// Removes `key`. Removing a key that is not set does nothing and is not
    /// an error, unless `expectedVersion` names a version it is not at.
    public func remove(forKey key: String, expectedVersion: Int64? = nil) throws {
        let removed = try database.write { connection -> Bool in
            let current = try Self.version(ofKey: key, in: connection)
            try Self.check(key: key, expected: expectedVersion, actual: current)
            try connection.execute(sql: "DELETE FROM shared_setting WHERE key = ?", arguments: [key])
            return connection.changesCount > 0
        }
        if removed { changed(key) }
    }

    /// Stores `value` only when `key` has no value yet, and answers whether
    /// it did: the import's write, which never overwrites what the suite
    /// already shares.
    @discardableResult
    public func importIfAbsent(_ value: Data, forKey key: String) throws -> Bool {
        let json = try Self.validatedJSON(value, forKey: key)
        let inserted = try database.write { connection -> Bool in
            try connection.execute(
                sql: "INSERT OR IGNORE INTO shared_setting (key, value, version) VALUES (?, ?, 1)",
                arguments: [key, json]
            )
            return connection.changesCount > 0
        }
        if inserted { changed(key) }
        return inserted
    }

    // MARK: - Changes

    /// The key of every write that changed something, in this process. Each
    /// read is a new stream of its own; it ends when the store goes away.
    public var changes: AsyncStream<String> {
        let (stream, continuation) = AsyncStream<String>.makeStream(bufferingPolicy: .unbounded)
        let id = UUID()
        lock.lock()
        subscribers[id] = continuation
        lock.unlock()
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            self.lock.lock()
            self.subscribers.removeValue(forKey: id)
            self.lock.unlock()
        }
        return stream
    }

    private func changed(_ key: String) {
        lock.lock()
        let continuations = Array(subscribers.values)
        lock.unlock()
        continuations.forEach { $0.yield(key) }
    }

    // MARK: - Helpers

    private static func setting(from row: Row) -> SharedSetting {
        let text: String = row["value"]
        return SharedSetting(key: row["key"], value: Data(text.utf8), version: row["version"])
    }

    private static func version(ofKey key: String, in connection: Database) throws -> Int64 {
        try Int64.fetchOne(
            connection, sql: "SELECT version FROM shared_setting WHERE key = ?", arguments: [key]) ?? 0
    }

    private static func check(key: String, expected: Int64?, actual: Int64) throws {
        if let expected, expected != actual {
            throw SharedSettingsStoreError.versionConflict(key: key, expected: expected, actual: actual)
        }
    }

    /// The value as JSON text, refusing anything that is not one JSON value:
    /// a reader decodes it as the setting's type, so garbage stored here
    /// would read as the default in every app at once.
    private static func validatedJSON(_ value: Data, forKey key: String) throws -> String {
        guard (try? JSONSerialization.jsonObject(with: value, options: .fragmentsAllowed)) != nil,
              let text = String(data: value, encoding: .utf8)
        else {
            throw SharedSettingsStoreError.invalidJSON(key: key)
        }
        return text
    }
}

/// Why a shared-settings write was refused.
public enum SharedSettingsStoreError: Error, Equatable, LocalizedError {
    /// The key was written since the writer read it.
    case versionConflict(key: String, expected: Int64, actual: Int64)
    /// The value is not one JSON value.
    case invalidJSON(key: String)

    public var errorDescription: String? {
        switch self {
        case let .versionConflict(key, expected, actual):
            return "The shared setting \(key) is at version \(actual), not \(expected): it changed since it was read."
        case let .invalidJSON(key):
            return "The value for the shared setting \(key) is not JSON."
        }
    }
}

#endif
