#if canImport(AgenticDeveloperHubSDKCore)
//
//  BrowserHistoryStore.swift
//  AgenticDeveloperHubSDK
//

import Foundation
import GRDB

/// One page the browser was on.
public struct BrowserVisit: Equatable, Sendable, Identifiable {
    public let id: Int64
    public let url: URL
    public let title: String
    public let visitedAt: Date

    public init(id: Int64, url: URL, title: String, visitedAt: Date) {
        self.id = id
        self.url = url
        self.title = title
        self.visitedAt = visitedAt
    }
}

/// Where the browser remembers the pages it has shown: one row per visit, in
/// its own SQLite file beside the project database.
///
/// Its own file rather than a table in `Projects.db` because history is the
/// one store here that a user clears wholesale, often, and a file that is
/// *only* history can be deleted without a migration touching anything else
/// (`design-for-deletion`). The file is opened through `BoundedDatabase`, the
/// same pool every other store in the toolkit sits on: WAL with one writer
/// and pooled readers, a deadline on every statement so a wedged file cannot
/// hang the pane, and GRDB's binding and row reading in place of hand-rolled
/// `sqlite3_*` calls (`open-source-preference`, `dry`).
///
/// Every method here runs on the caller's thread and returns when the file
/// has answered. The pane and the panel are on the main actor, and a WAL
/// commit waits on the disk, so they go through ``perform(_:)``, or through
/// ``BrowserHistoryStoring``, whose async methods wrap it. Consumers above
/// this tier hold the protocol, so the daemon's adapter can stand in.
public final class BrowserHistoryStore: @unchecked Sendable {

    public static let fileName = "BrowserHistory.db"

    /// Posted, with the store as its object, after every write that
    /// succeeded, on the thread that made it. A list showing the history
    /// rereads on it, so a visit recorded while it is open appears.
    /// The same name every ``BrowserHistoryStoring`` posts.
    public static let didChangeNotification = Notification.Name.browserHistoryDidChange

    private func changed() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    /// `~/.<app token>/BrowserHistory.db`, with the home directory explicit so
    /// a test run can point it anywhere.
    public static func defaultPath(
        inHome home: URL = FileManager.default.homeDirectoryForCurrentUser,
        token: String = AppStorageLocation.token
    ) -> String {
        AppStorageLocation.directory(inHome: home, token: token).appendingPathComponent(fileName).path
    }

    public let databasePath: String
    private let database: BoundedDatabase

    public init(path: String) throws {
        databasePath = path
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        database = try BoundedDatabase(path: path)
        try database.write { connection in
            try connection.execute(sql: """
                CREATE TABLE IF NOT EXISTS visit (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT NOT NULL,
                    title TEXT NOT NULL DEFAULT '',
                    visited_at REAL NOT NULL
                )
            """)
            try connection.execute(sql: "CREATE INDEX IF NOT EXISTS visit_visited_at ON visit (visited_at DESC)")
        }
    }

    /// Runs `work` against the store off the caller's thread, for a caller
    /// on the main actor. Every method here reads or writes the file, and a
    /// write's commit waits on the disk; neither belongs on the thread that
    /// draws the pane.
    public func perform<T: Sendable>(_ work: @escaping @Sendable (BrowserHistoryStore) throws -> T) async throws -> T {
        let store = self
        return try await Task.detached(priority: .utility) { try work(store) }.value
    }

    // MARK: - Writing

    /// Records a visit and returns its id, so a title that arrives after the
    /// load can be filed against the right row.
    @discardableResult
    public func record(_ url: URL, title: String, at date: Date = Date()) throws -> Int64 {
        let id = try database.write { connection in
            try connection.execute(
                sql: "INSERT INTO visit (url, title, visited_at) VALUES (?, ?, ?)",
                arguments: [url.absoluteString, title, date.timeIntervalSince1970]
            )
            return connection.lastInsertedRowID
        }
        changed()
        return id
    }

    /// Copies `visits` from another history store, in one transaction, and
    /// returns the ones inserted with the ids they were given.
    ///
    /// A visit is the same visit when its address and time match a row here,
    /// and that one is skipped, so a second import of the same source adds
    /// nothing. A new visit keeps its id when no row here holds it; otherwise
    /// it takes the next free id rather than being dropped, since an id in
    /// another file says nothing about the rows of this one.
    ///
    /// `dryRun` runs the same inserts and rolls them back, so what it returns
    /// is what a real run would insert, and nothing changes.
    @discardableResult
    public func importIfAbsent(_ visits: [BrowserVisit], dryRun: Bool = false) throws -> [BrowserVisit] {
        guard !visits.isEmpty else { return [] }
        var inserted: [BrowserVisit] = []
        do {
            try database.write { connection in
                try insertAbsent(visits, into: &inserted, in: connection)
                if dryRun { throw ImportRollback() }
            }
        } catch is ImportRollback {
            return inserted
        }
        if !inserted.isEmpty { changed() }
        return inserted
    }

    private func insertAbsent(_ visits: [BrowserVisit], into inserted: inout [BrowserVisit],
                              in connection: Database) throws {
        for visit in visits {
            let time = visit.visitedAt.timeIntervalSince1970
            let present = try Bool.fetchOne(
                connection, sql: "SELECT EXISTS (SELECT 1 FROM visit WHERE url = ? AND visited_at = ?)",
                arguments: [visit.url.absoluteString, time]) ?? false
            if present { continue }
            let idTaken = try Bool.fetchOne(
                connection, sql: "SELECT EXISTS (SELECT 1 FROM visit WHERE id = ?)",
                arguments: [visit.id]) ?? false
            if idTaken {
                try connection.execute(
                    sql: "INSERT INTO visit (url, title, visited_at) VALUES (?, ?, ?)",
                    arguments: [visit.url.absoluteString, visit.title, time])
            } else {
                try connection.execute(
                    sql: "INSERT INTO visit (id, url, title, visited_at) VALUES (?, ?, ?, ?)",
                    arguments: [visit.id, visit.url.absoluteString, visit.title, time])
            }
            inserted.append(BrowserVisit(
                id: connection.lastInsertedRowID, url: visit.url, title: visit.title,
                visitedAt: visit.visitedAt))
        }
    }

    /// Thrown out of an import's write to roll a dry run back.
    private struct ImportRollback: Error {}

    public func updateTitle(ofVisit id: Int64, to title: String) throws {
        try database.write { connection in
            try connection.execute(sql: "UPDATE visit SET title = ? WHERE id = ?", arguments: [title, id])
        }
        changed()
    }

    public func remove(visit id: Int64) throws {
        try database.write { connection in
            try connection.execute(sql: "DELETE FROM visit WHERE id = ?", arguments: [id])
        }
        changed()
    }

    /// Forgets every visit before `cutoff`.
    public func removeVisits(before cutoff: Date) throws {
        try database.write { connection in
            try connection.execute(
                sql: "DELETE FROM visit WHERE visited_at < ?", arguments: [cutoff.timeIntervalSince1970])
        }
        changed()
    }

    public func removeAll() throws {
        try database.write { connection in
            try connection.execute(sql: "DELETE FROM visit")
        }
        changed()
    }

    // MARK: - Reading

    /// The latest visits, newest first. `excludingLocalFiles` leaves out
    /// `file:` visits before the limit is applied, so a list for the agent
    /// still holds `limit` visits it may see (`BrowserAutomation.isDrivable`).
    /// `before`, when given, starts the page after that visit in the same
    /// order (keyset paging), so a caller can walk the whole history a page
    /// at a time without a visit recorded meanwhile shifting the pages.
    public func recent(
        limit: Int = 200, before: BrowserVisit? = nil, excludingLocalFiles: Bool = false
    ) throws -> [BrowserVisit] {
        var conditions: [String] = []
        var arguments: StatementArguments = []
        if let before {
            conditions.append("(visited_at < ? OR (visited_at = ? AND id < ?))")
            let time = before.visitedAt.timeIntervalSince1970
            arguments += [time, time, before.id]
        }
        if excludingLocalFiles { conditions.append(Self.notLocalFile) }
        let filter = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
        arguments += [limit]
        return try database.read { connection in
            try Row.fetchAll(connection, sql: """
                SELECT id, url, title, visited_at FROM visit \(filter)
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """, arguments: arguments).compactMap(Self.visit(from:))
        }
    }

    /// Visits whose address or title contains `text`, newest first;
    /// `excludingLocalFiles` as for `recent`.
    public func search(_ text: String, limit: Int = 200, excludingLocalFiles: Bool = false) throws -> [BrowserVisit] {
        let pattern = "%" + Self.escapedForLike(text) + "%"
        let filter = excludingLocalFiles ? "AND \(Self.notLocalFile)" : ""
        return try database.read { connection in
            try Row.fetchAll(connection, sql: """
                SELECT id, url, title, visited_at FROM visit
                WHERE (url LIKE ? ESCAPE '\\' OR title LIKE ? ESCAPE '\\') \(filter)
                ORDER BY visited_at DESC, id DESC LIMIT ?
            """, arguments: [pattern, pattern, limit]).compactMap(Self.visit(from:))
        }
    }

    /// SQL that keeps a row whose address is not a local file. LIKE ignores
    /// ASCII case, so `FILE:` is caught as `BrowserAutomation.isDrivable` does.
    private static let notLocalFile = "url NOT LIKE 'file:%'"

    public func count() throws -> Int {
        try database.read { connection in
            try Int.fetchOne(connection, sql: "SELECT COUNT(*) FROM visit") ?? 0
        }
    }

    /// `%` and `_` are LIKE's wildcards, so a search for either must escape
    /// it or match everything; `\` is the escape the query names.
    static func escapedForLike(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    /// A row that no longer parses as an address is skipped, not fatal: the
    /// rest of the history is still worth showing.
    private static func visit(from row: Row) -> BrowserVisit? {
        guard let url = URL(string: row["url"]) else { return nil }
        return BrowserVisit(
            id: row["id"],
            url: url,
            title: row["title"],
            visitedAt: Date(timeIntervalSince1970: row["visited_at"])
        )
    }
}

extension BrowserHistoryStore: BrowserHistoryStoring {
    @discardableResult
    public func record(_ url: URL, title: String, at date: Date) async throws -> Int64 {
        try await perform { try $0.record(url, title: title, at: date) }
    }

    public func updateTitle(ofVisit id: Int64, to title: String) async throws {
        try await perform { try $0.updateTitle(ofVisit: id, to: title) }
    }

    public func remove(visit id: Int64) async throws {
        try await perform { try $0.remove(visit: id) }
    }

    public func removeVisits(before cutoff: Date) async throws {
        try await perform { try $0.removeVisits(before: cutoff) }
    }

    public func removeAll() async throws {
        try await perform { try $0.removeAll() }
    }

    public func recent(limit: Int, before: BrowserVisit?, excludingLocalFiles: Bool) async throws -> [BrowserVisit] {
        try await perform { try $0.recent(limit: limit, before: before, excludingLocalFiles: excludingLocalFiles) }
    }

    public func search(_ text: String, limit: Int, excludingLocalFiles: Bool) async throws -> [BrowserVisit] {
        try await perform { try $0.search(text, limit: limit, excludingLocalFiles: excludingLocalFiles) }
    }

    public func count() async throws -> Int {
        try await perform { try $0.count() }
    }
}
#endif
