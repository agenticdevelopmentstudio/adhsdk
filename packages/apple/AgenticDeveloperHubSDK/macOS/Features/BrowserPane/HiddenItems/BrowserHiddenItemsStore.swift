//
//  BrowserHiddenItemsStore.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase
import Foundation
import GRDB

public enum BrowserHiddenItemsStoreError: Error, Equatable, Sendable {
    /// An entry whose selector is empty after trimming would make an invalid
    /// rule, so the store refuses it at the boundary.
    case emptySelector
}

/// The user's and the agent's hidden-item lists, and the user list's
/// per-site "Hide distracting items" switch, in one SQLite file of their own
/// (`BrowserHiddenItems.db`).
///
/// One store and one file for both lists, told apart by a `list` column that
/// every query names, so the two cannot drift (`dry`) and an agent entry never
/// answers a user question. A file of its own, like `BrowserHistory.db`, so it
/// can be deleted without a migration touching anything else
/// (`design-for-deletion`). Opened through `BoundedDatabase`: one writer,
/// pooled readers, a deadline on every statement.
///
/// A site switch that has never been set is on; only an explicit row turns it
/// off. The agent list's switch is stored if set but never consulted.
///
/// Every change posts ``didChangeNotification`` (object: the store) after it
/// is committed. Every method runs on the caller's thread; main-actor callers
/// go through ``perform(_:)``.
public final class BrowserHiddenItemsStore: @unchecked Sendable {

    public static let fileName = "BrowserHiddenItems.db"

    /// Posted after every add, enable or disable, remove and site-switch
    /// change, with the store as the object.
    public static let didChangeNotification = Notification.Name("BrowserHiddenItemsStore.didChange")

    /// The one store the browser feature opens at launch
    /// (`WebBrowserWindowsFeature`), shared by every pane; nil before launch
    /// or when the file could not be opened.
    ///
    /// The launch open runs off the main thread (``openShared(at:onFailure:)``).
    /// A read that comes before it has finished waits for it rather than
    /// answering "no store", which would show the agent what its list hides:
    /// privacy fails closed. Setting it (a host, a test) replaces any open in
    /// flight.
    ///
    /// This getter blocks the main thread while the open runs, so it is for
    /// callers after launch (an agent's tool call) only. Anything that can run
    /// while the app is launching (an engine's first read, a toolbar button)
    /// awaits ``sharedStore()`` instead.
    @MainActor public static var shared: BrowserHiddenItemsStore? {
        get {
            if let pendingOpen {
                storedShared = pendingOpen.wait()
                self.pendingOpen = nil
            }
            return storedShared
        }
        set {
            pendingOpen = nil
            storedShared = newValue
        }
    }

    /// ``shared`` without blocking: awaits an open in flight and answers what
    /// it opened, or nil when the file could not be opened (every consumer
    /// takes nil as "no store", never as an empty list it may show past).
    @MainActor public static func sharedStore() async -> BrowserHiddenItemsStore? {
        guard let pending = pendingOpen else { return storedShared }
        let store = await pending.value()
        if pendingOpen === pending {
            storedShared = store
            pendingOpen = nil
            return store
        }
        // A setter or a newer open replaced this one while it ran.
        return await sharedStore()
    }

    /// Whether ``shared`` is set or being opened, without waiting for it.
    @MainActor public static var hasShared: Bool { storedShared != nil || pendingOpen != nil }

    @MainActor private static var storedShared: BrowserHiddenItemsStore?
    @MainActor private static var pendingOpen: PendingOpen?

    /// Opens the store at `url` on a background queue as ``shared``. A file
    /// that cannot be opened leaves ``shared`` nil and reports to
    /// `onFailure`, on that queue.
    @MainActor public static func openShared(
        at url: URL, onFailure: @escaping @Sendable (Error) -> Void = { _ in }
    ) {
        let pending = PendingOpen()
        pendingOpen = pending
        DispatchQueue.global(qos: .userInitiated).async {
            let store: BrowserHiddenItemsStore?
            do {
                store = try open(at: url)
            } catch {
                onFailure(error)
                store = nil
            }
            pending.finish(store)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    // Unless a read already took it, or a setter replaced it.
                    guard pendingOpen === pending else { return }
                    storedShared = store
                    pendingOpen = nil
                }
            }
        }
    }

    /// One background open, which a main-actor read can wait on, blocking
    /// (``shared``) or awaiting (``sharedStore()``).
    private final class PendingOpen: @unchecked Sendable {
        private let condition = NSCondition()
        private var isDone = false
        private var store: BrowserHiddenItemsStore?
        private var waiters: [CheckedContinuation<BrowserHiddenItemsStore?, Never>] = []

        func finish(_ store: BrowserHiddenItemsStore?) {
            condition.lock()
            self.store = store
            isDone = true
            let resumed = waiters
            waiters = []
            condition.broadcast()
            condition.unlock()
            for waiter in resumed { waiter.resume(returning: store) }
        }

        func value() async -> BrowserHiddenItemsStore? {
            await withCheckedContinuation { continuation in
                condition.lock()
                guard isDone else {
                    waiters.append(continuation)
                    condition.unlock()
                    return
                }
                let store = store
                condition.unlock()
                continuation.resume(returning: store)
            }
        }

        func wait() -> BrowserHiddenItemsStore? {
            condition.lock()
            defer { condition.unlock() }
            while !isDone { condition.wait() }
            return store
        }
    }

    /// `<app home>/BrowserHiddenItems.db`, the app home following
    /// `APP_TEST_HOME` when it is set.
    public static var defaultURL: URL {
        defaultURL(environment: ProcessInfo.processInfo.environment)
    }

    /// ``defaultURL`` with its inputs explicit, so a test can check both the
    /// real home and a test home without touching either.
    public static func defaultURL(
        environment: [String: String],
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        token: String = AppStorageLocation.token
    ) -> URL {
        let testHome = environment["APP_TEST_HOME"].flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) }
        return AppStorageLocation.directory(inHome: testHome ?? home, token: token)
            .appendingPathComponent(fileName)
    }

    public static func open(at url: URL) throws -> BrowserHiddenItemsStore {
        try BrowserHiddenItemsStore(url: url)
    }

    public let url: URL
    private let database: BoundedDatabase

    private init(url: URL) throws {
        self.url = url
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        database = try BoundedDatabase(path: url.path)
        try Self.migrator().migrate(database.writer)
    }

    private static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { connection in
            try connection.execute(sql: """
                CREATE TABLE hidden_item (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    list TEXT NOT NULL,
                    site TEXT NOT NULL,
                    selector TEXT NOT NULL,
                    scope TEXT NOT NULL,
                    label TEXT NOT NULL DEFAULT '',
                    enabled INTEGER NOT NULL DEFAULT 1,
                    created REAL NOT NULL
                )
            """)
            try connection.execute(sql: "CREATE INDEX hidden_item_list_site ON hidden_item (list, site)")
            try connection.execute(sql: """
                CREATE TABLE site_switch (
                    list TEXT NOT NULL,
                    site TEXT NOT NULL,
                    "on" INTEGER NOT NULL,
                    PRIMARY KEY (list, site)
                )
            """)
        }
        return migrator
    }

    /// Runs `work` against the store off the caller's thread, for a caller on
    /// the main actor: a WAL commit waits on the disk.
    public func perform<T: Sendable>(
        _ work: @escaping @Sendable (BrowserHiddenItemsStore) throws -> T
    ) async throws -> T {
        let store = self
        return try await Task.detached(priority: .utility) { try work(store) }.value
    }

    // MARK: - Reading

    /// Every entry of `list` whose site matches `url`, enabled and disabled
    /// alike, oldest first. A nil `url` is a place with no address, which
    /// only `*` matches.
    public func items(list: BrowserHiddenItemList, for url: URL?) throws -> [BrowserHiddenItem] {
        try allItems(list: list).filter { PrivacySitePattern.matches($0.site, url: url) }
    }

    /// The selectors of `list`'s enabled entries that match `url`. For the
    /// user list, entries on a site whose switch is off are left out; the
    /// agent list has no switch in effect.
    public func enabledSelectors(list: BrowserHiddenItemList, for url: URL?) throws -> [String] {
        let switchedOff: Set<String> = try list == .user ? sitesSwitchedOff(list: list) : []
        return try items(list: list, for: url)
            .filter { $0.enabled && !switchedOff.contains($0.site) }
            .map(\.selector)
    }

    /// Whether `list`'s switch for `site` is on; on when never set.
    public func isSiteSwitchOn(list: BrowserHiddenItemList, site: String) throws -> Bool {
        try database.read { connection in
            try Bool.fetchOne(
                connection, sql: #"SELECT "on" FROM site_switch WHERE list = ? AND site = ?"#,
                arguments: [list.rawValue, site]) ?? true
        }
    }

    private func allItems(list: BrowserHiddenItemList) throws -> [BrowserHiddenItem] {
        try database.read { connection in
            try Row.fetchAll(connection, sql: """
                SELECT id, list, site, selector, scope, label, enabled, created FROM hidden_item
                WHERE list = ? ORDER BY id
            """, arguments: [list.rawValue]).compactMap(Self.item(from:))
        }
    }

    private func sitesSwitchedOff(list: BrowserHiddenItemList) throws -> Set<String> {
        try database.read { connection in
            let sites = try String.fetchAll(
                connection, sql: #"SELECT site FROM site_switch WHERE list = ? AND "on" = 0"#,
                arguments: [list.rawValue])
            return Set(sites)
        }
    }

    /// A row whose list or scope no longer parses is skipped, not fatal.
    private static func item(from row: Row) -> BrowserHiddenItem? {
        guard let list = BrowserHiddenItemList(rawValue: row["list"]),
              let scope = BrowserHiddenItemScope(rawValue: row["scope"]) else { return nil }
        return BrowserHiddenItem(
            id: row["id"],
            list: list,
            site: row["site"],
            selector: row["selector"],
            scope: scope,
            label: row["label"],
            enabled: row["enabled"],
            // The reference-date interval is what `Date` holds, so it reads
            // back exactly; the 1970 one is a conversion away from it.
            created: Date(timeIntervalSinceReferenceDate: row["created"]))
    }

    // MARK: - Writing

    /// Stores `item` and returns it with its assigned id. Refuses an empty
    /// selector.
    @discardableResult
    public func add(_ item: BrowserHiddenItem) throws -> BrowserHiddenItem {
        guard !item.selector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BrowserHiddenItemsStoreError.emptySelector
        }
        var stored = item
        stored.id = try database.write { connection in
            try connection.execute(sql: """
                INSERT INTO hidden_item (list, site, selector, scope, label, enabled, created)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, arguments: [
                item.list.rawValue, item.site, item.selector, item.scope.rawValue, item.label,
                item.enabled, item.created.timeIntervalSinceReferenceDate
            ])
            return connection.lastInsertedRowID
        }
        postChange()
        return stored
    }

    public func setEnabled(_ id: Int64, _ isOn: Bool) throws {
        try database.write { connection in
            try connection.execute(sql: "UPDATE hidden_item SET enabled = ? WHERE id = ?", arguments: [isOn, id])
        }
        postChange()
    }

    public func remove(_ id: Int64) throws {
        try database.write { connection in
            try connection.execute(sql: "DELETE FROM hidden_item WHERE id = ?", arguments: [id])
        }
        postChange()
    }

    public func setSiteSwitch(list: BrowserHiddenItemList, site: String, on isOn: Bool) throws {
        try database.write { connection in
            try connection.execute(sql: """
                INSERT INTO site_switch (list, site, "on") VALUES (?, ?, ?)
                ON CONFLICT (list, site) DO UPDATE SET "on" = excluded."on"
            """, arguments: [list.rawValue, site, isOn])
        }
        postChange()
    }

    private func postChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
