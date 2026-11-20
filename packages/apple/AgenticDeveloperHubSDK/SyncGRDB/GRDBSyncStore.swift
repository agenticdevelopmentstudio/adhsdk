import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync

/// Snapshot of local sync bookkeeping, consumed by hosts (e.g. Plan 4's
/// `/adhd/sync/status` daemon endpoint).
public struct GRDBSyncStoreStatus: Codable, Sendable {
    public let cursor: String?
    public let outboxDepth: Int
    public let quarantinedDepth: Int
    public let conflictCount: Int
}

/// `SyncStore` on `BoundedDatabase` (WAL pool): JSON-payload mirror tables, an
/// outbox, and a conflicts audit. The mirror is fed only by apply()/stage();
/// it is NEVER deleted as a recovery path (resetForResync truncates tables,
/// preserving the outbox and the file), and nothing in it is deleted when the
/// signed-in identity changes: a store is *bound* to one account
/// (`bind(account:)`), and once a host declares who is signed in
/// (`signIn(account:)`, `signOut()`) the store itself refuses to push or pull
/// for anyone else — the bound account's queued ops wait for it instead of
/// being purged or sent under another account's credentials.
///
/// Provenance: every generic mirror table carries `origin` (`'local'` for a
/// row this device wrote, `'account:<principalId>'` for one pulled from an
/// account) and `reached_accounts` (a JSON array of the principal ids the row
/// is known to have reached). Projections keep their own tables and are not
/// given these columns.
///
/// `@unchecked Sendable` because `SyncStore` is a `Sendable` protocol and this
/// type is shared across tasks. The property it asserts is established, not
/// assumed: every stored property is a `let`, and each is either itself
/// `Sendable` (`DispatchQueue`, `Set<String>`, the projections) or serialises
/// its own concurrent use (`BoundedDatabase`'s WAL pool). It used to hold two
/// more — a shared `JSONEncoder` and `JSONDecoder`. Neither publishes any
/// thread-safety guarantee, and both were reachable from `read`, which runs on
/// a *pool*: two readers could be inside one decoder at the same instant. They
/// are built per call now, at the four sites that need them, which costs
/// nothing next to the disk access each one is part of.
public final class GRDBSyncStore: SyncStore, @unchecked Sendable {

    private let boundedDatabase: BoundedDatabase
    private let queue = DispatchQueue(label: "GRDBSyncStore")
    /// Resources this host may pull but never push. `stage(_:)` refuses them
    /// up front with `SyncStoreFailure.pullOnlyResource` (twin of
    /// `InMemorySyncStore.pullOnlyResources`).
    private let pullOnlyResources: Set<String>
    /// Typed storage for a subset of resources, each claimed by exactly one
    /// projection. Empty — the default — is the historical all-JSON behaviour.
    /// The store routes to them itself rather than through a forwarding
    /// projection: a forwarder compiles any requirement later added to
    /// `SyncMirrorProjection` with an extension default as that default, so the
    /// new call would silently never reach the projections behind it.
    private let mirrorProjections: [any SyncMirrorProjection]
    /// Told after a commit that may have appended to `_change_log`.
    private let changeSignal = ChangeCommitSignal()

    public init(
        database: BoundedDatabase,
        pullOnlyResources: Set<String> = [],
        projections: [any SyncMirrorProjection] = []
    ) {
        var claimed: Set<String> = []
        for projection in projections {
            precondition(claimed.isDisjoint(with: projection.resources),
                         "two mirror projections claim \(claimed.intersection(projection.resources).sorted())")
            claimed.formUnion(projection.resources)
        }
        self.boundedDatabase = database
        self.pullOnlyResources = pullOnlyResources
        self.mirrorProjections = projections
    }

    /// A store with one projection.
    public convenience init(
        database: BoundedDatabase,
        pullOnlyResources: Set<String> = [],
        projection: any SyncMirrorProjection
    ) {
        self.init(database: database, pullOnlyResources: pullOnlyResources, projections: [projection])
    }

    public var database: BoundedDatabase { boundedDatabase }

    /// Whether this host may only pull `resource`, never write it locally —
    /// the set `stage(_:in:)` refuses with `SyncStoreFailure.pullOnlyResource`.
    /// Lets a host refuse a write up front, before it is queued anywhere.
    public func isPullOnly(_ resource: String) -> Bool {
        pullOnlyResources.contains(resource)
    }

    /// Whether `resource` takes local versioned writes: a registered generic
    /// mirror resource that is neither projection-owned nor pull-only.
    public func acceptsLocalWrites(resource: String) throws -> Bool {
        guard !isPullOnly(resource) else { return false }
        return try boundedDatabase.read { conn in
            do {
                _ = try self.genericTable(for: resource, in: conn)
                return true
            } catch SyncStoreFailure.unknownResource {
                return false
            }
        }
    }

    /// The projection that claims this resource, if any.
    private func projection(for resource: String) -> (any SyncMirrorProjection)? {
        mirrorProjections.first { $0.resources.contains(resource) }
    }

    /// Resource strings are interpolated directly into SQL as identifiers
    /// (SQLite has no bind-parameter syntax for identifiers), so this is the
    /// one chokepoint every caller below routes through — reject anything
    /// outside `[a-z0-9_.]` before it ever reaches a query string (sync
    /// fix-wave item p2l).
    public static func mirrorTableName(for resource: String) throws -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789_.")
        guard !resource.isEmpty, resource.allSatisfy({ allowed.contains($0) }) else {
            throw SyncStoreFailure.unknownResource(resource)
        }
        return resource.replacingOccurrences(of: ".", with: "_")
    }

    /// Deletes the mirror rows of the REGISTERED subset of `resources` — each
    /// one filtered against `_sync_resources` first, so an unregistered resource
    /// (no mirror table was ever created for it) is silently skipped rather than
    /// throwing "no such table". This is the shared body of the three per-resource
    /// mirror-truncation sites (`resetForResync`, `purgeResources`) — one
    /// place that "empty a mirror table" lives, so
    /// purging an unregistered resource is a no-op in every path (twin parity with
    /// `InMemorySyncStore.purgeResources`, which already no-ops the unknown key).
    private func deleteMirrorRows(for resources: [String], in conn: Database) throws {
        var registered: [String] = []
        for resource in resources {
            let isRegistered = try Bool.fetchOne(
                conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
                arguments: [resource]
            ) ?? false
            if isRegistered { registered.append(resource) }
        }

        // Each projection is handed every one of its resources in this purge in
        // ONE call, not one call per resource, and only its own. A projection
        // whose tables have foreign keys between *each other* can only
        // distinguish a whole-family purge (legal — the children go too) from a
        // partial one that would orphan rows (not legal) by seeing the whole
        // batch; called a singleton at a time it would see what looks like a
        // partial purge every time, including during `resetForResync`, where
        // the rest of the family is emptied by the very next call.
        for mirrorProjection in mirrorProjections {
            let own = registered.filter { mirrorProjection.resources.contains($0) }
            if !own.isEmpty { try mirrorProjection.truncate(resources: own, in: conn) }
        }
        for resource in registered where projection(for: resource) == nil {
            try conn.execute(sql: "DELETE FROM \"\(try Self.mirrorTableName(for: resource))\"")
        }
    }

    private func onQueue<T: Sendable>(_ body: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try body() })
            }
        }
    }

    // MARK: - SyncStore

    /// The bookkeeping tables (as opposed to per-resource mirror tables).
    /// Idempotent (`CREATE TABLE IF NOT EXISTS`) so it's safe to run from
    /// both `prepare(resources:)` and `cursor()` — the engine's pull loop
    /// calls `cursor()` before it has a manifest to hand `prepare`, so on a
    /// truly cold store (no prior `prepare` call ever made) `cursor()` would
    /// otherwise throw "no such table: _sync_state" on the very first sync.
    private static let bookkeepingSchema = """
        CREATE TABLE IF NOT EXISTS _sync_state (
            id INTEGER PRIMARY KEY CHECK (id = 1), cursor TEXT, bound_account TEXT);
        CREATE TABLE IF NOT EXISTS _sync_resources (
            resource TEXT PRIMARY KEY, schema_version INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS _sync_outbox (
            op_id TEXT PRIMARY KEY, resource TEXT NOT NULL, row_id TEXT NOT NULL,
            type TEXT NOT NULL, base_version TEXT, payload TEXT,
            status TEXT NOT NULL DEFAULT 'pending', attempts INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS _sync_conflicts (
            id INTEGER PRIMARY KEY AUTOINCREMENT, op_id TEXT, resource TEXT,
            row_id TEXT, reason TEXT, resolved_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS _change_log (
            seq INTEGER PRIMARY KEY AUTOINCREMENT, resource TEXT NOT NULL,
            row_id TEXT NOT NULL, kind TEXT NOT NULL, version INTEGER NOT NULL,
            at TEXT NOT NULL);
        """

    public func prepare(resources: [SyncResource]) async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.prepare(resources: resources, in: conn)
            }
        }
    }

    /// The body of `prepare(resources:)`, for a caller that already holds a
    /// write transaction. Taking the connection rather than opening one is what
    /// lets a store built on top of this one register its resources and create
    /// its own tables in a single transaction.
    public func prepare(resources: [SyncResource], in conn: Database) throws {
        try Self.ensureBookkeeping(in: conn)
        for mirrorProjection in mirrorProjections { try mirrorProjection.createTables(in: conn) }
        for resource in resources {
            if projection(for: resource.resource) == nil {
                let table = try Self.mirrorTableName(for: resource.resource)
                try conn.execute(sql: """
                    CREATE TABLE IF NOT EXISTS "\(table)" (
                        id TEXT PRIMARY KEY NOT NULL,
                        sync_version INTEGER NOT NULL DEFAULT 0,
                        deleted_at TEXT,
                        data TEXT NOT NULL DEFAULT '{}',
                        origin TEXT NOT NULL DEFAULT 'local',
                        reached_accounts TEXT NOT NULL DEFAULT '[]',
                        local_version INTEGER NOT NULL DEFAULT 0);
                    """)
            }
            try conn.execute(
                sql: """
                    INSERT INTO _sync_resources (resource, schema_version) VALUES (?, ?)
                    ON CONFLICT(resource) DO UPDATE SET schema_version = excluded.schema_version
                    """,
                arguments: [resource.resource, resource.schemaVersion]
            )
        }
        try migrateProvenanceColumns(in: conn)
    }

    /// The bookkeeping tables, plus the one column added to `_sync_state`
    /// after databases already existed (`bound_account`). `CREATE TABLE IF NOT
    /// EXISTS` never alters an existing table, so an old `_sync_state` gains
    /// the column here, in place, keeping its cursor.
    private static func ensureBookkeeping(in conn: Database) throws {
        try conn.execute(sql: bookkeepingSchema)
        try addColumnIfMissing("bound_account", definition: "TEXT", to: "_sync_state", in: conn)
    }

    /// `ensureBookkeeping` plus the additive mirror-column upgrade. Every
    /// entry point that reads or writes `origin`, `reached_accounts` or
    /// `local_version` runs this first: the engine skips `prepare` when its
    /// registrations already cover the manifest, so an existing database
    /// upgraded in place would otherwise never gain the columns and every
    /// pull and local write would fail on them. Both halves are idempotent
    /// and cheap (one `PRAGMA table_info` per registered generic table).
    private func ensureSchema(in conn: Database) throws {
        try Self.ensureBookkeeping(in: conn)
        try migrateProvenanceColumns(in: conn)
    }

    private static func addColumnIfMissing(
        _ column: String, definition: String, to table: String, in conn: Database
    ) throws {
        let existing = try conn.columns(in: table).map(\.name)
        guard !existing.contains(column) else { return }
        try conn.execute(sql: "ALTER TABLE \"\(table)\" ADD COLUMN \(column) \(definition)")
    }

    /// Additive, in-place upgrade of every registered generic mirror table
    /// written before provenance existed: `origin` and `reached_accounts` are
    /// added with their defaults when missing, so the rows already there stay
    /// and read as `'local'` with no known account. Projection-owned resources
    /// are skipped — their tables are the projection's. Idempotent; `prepare`,
    /// `cursor`, `registrations`, `stage` and `resetForResync` run it too, so a
    /// host never has to call this itself.
    public func migrateProvenanceColumns() async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
            }
        }
    }

    private func migrateProvenanceColumns(in conn: Database) throws {
        let resources = try String.fetchAll(conn, sql: "SELECT resource FROM _sync_resources")
        for resource in resources where projection(for: resource) == nil {
            let table = try Self.mirrorTableName(for: resource)
            guard try conn.tableExists(table) else { continue }
            try Self.addColumnIfMissing(
                "origin", definition: "TEXT NOT NULL DEFAULT 'local'", to: table, in: conn)
            try Self.addColumnIfMissing(
                "reached_accounts", definition: "TEXT NOT NULL DEFAULT '[]'", to: table, in: conn)
            try Self.addColumnIfMissing(
                "local_version", definition: "INTEGER NOT NULL DEFAULT 0", to: table, in: conn)
        }
    }

    // MARK: - Local versions and the change feed

    /// Called after every committed transaction that may have appended to
    /// `_change_log` (a pull, a staged write, a `writeLocal` body). Observers
    /// read the feed from their own last-seen `seq`; the call carries nothing.
    public func observeCommittedChanges(_ observer: @escaping @Sendable () -> Void) {
        changeSignal.add(observer)
    }

    /// Runs `body` in one write transaction and, once it has committed, tells
    /// the change observers. For a host composing its own local write
    /// (a version check, then `stage(_:in:)`) that must land atomically.
    public func writeLocal<T>(_ body: (Database) throws -> T) throws -> T {
        let result = try boundedDatabase.write(body)
        changeSignal.fire()
        return result
    }

    /// The row's `local_version` and whether it is a tombstone, or `nil` when
    /// no row with that id was ever written. Throws
    /// `SyncStoreFailure.unknownResource` for an unregistered resource and for
    /// a projection-owned one (projections keep no local version).
    public func localVersion(
        resource: String, id: String, in conn: Database
    ) throws -> (version: Int64, isDeleted: Bool)? {
        let table = try genericTable(for: resource, in: conn)
        return try Row.fetchOne(
            conn, sql: "SELECT local_version, deleted_at FROM \"\(table)\" WHERE id = ?",
            arguments: [id]
        ).map { row in (row["local_version"], (row["deleted_at"] as String?) != nil) }
    }

    /// A live row's stored JSON object and `local_version`; `nil` for a
    /// missing or deleted row. Same resource contract as `localVersion`.
    public func localRecord(resource: String, id: String) throws -> (data: Data, version: Int64)? {
        try boundedDatabase.read { conn in
            let table = try self.genericTable(for: resource, in: conn)
            return try Row.fetchOne(
                conn,
                sql: "SELECT data, local_version FROM \"\(table)\" WHERE id = ? AND deleted_at IS NULL",
                arguments: [id]
            ).map { row in (Data((row["data"] as String).utf8), row["local_version"]) }
        }
    }

    /// Feed entries with `seq > since`, oldest first, at most `limit`. Empty
    /// — never an error — for `since` at or above the head and on a store
    /// that has never logged anything.
    public func changes(since: Int64, limit: Int) throws -> [RecordChange] {
        guard limit > 0 else { return [] }
        return try boundedDatabase.read { conn in
            guard try conn.tableExists("_change_log") else { return [] }
            return try Row.fetchAll(
                conn,
                sql: """
                    SELECT seq, resource, row_id, kind, version FROM _change_log
                    WHERE seq > ? ORDER BY seq LIMIT ?
                    """,
                arguments: [since, limit]
            ).compactMap { row in
                guard let kind = RecordChange.Kind(rawValue: row["kind"]) else { return nil }
                return RecordChange(
                    seq: row["seq"], resource: row["resource"], id: row["row_id"],
                    kind: kind, version: row["version"])
            }
        }
    }

    /// The highest `seq` in the feed, `0` when it is empty.
    public func changeHead() throws -> Int64 {
        try boundedDatabase.read { conn in
            guard try conn.tableExists("_change_log") else { return 0 }
            return try Int64.fetchOne(conn, sql: "SELECT MAX(seq) FROM _change_log") ?? 0
        }
    }

    private func genericTable(for resource: String, in conn: Database) throws -> String {
        let isKnown = try Bool.fetchOne(
            conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
            arguments: [resource]
        ) ?? false
        guard isKnown, projection(for: resource) == nil else {
            throw SyncStoreFailure.unknownResource(resource)
        }
        return try Self.mirrorTableName(for: resource)
    }

    /// Appends the row's current `local_version` to the feed. Inside the
    /// caller's transaction, so the feed and the row cannot disagree.
    private static func logChange(
        resource: String, table: String, id: String, kind: RecordChange.Kind, in conn: Database
    ) throws {
        guard let version = try Int64.fetchOne(
            conn, sql: "SELECT local_version FROM \"\(table)\" WHERE id = ?", arguments: [id])
        else { return }
        try conn.execute(
            sql: """
                INSERT INTO _change_log (resource, row_id, kind, version, at)
                VALUES (?, ?, ?, ?, datetime('now'))
                """,
            arguments: [resource, id, kind.rawValue, version])
    }

    // MARK: - Account binding

    /// The account this store's rows, outbox and cursor belong to, or `nil`
    /// before the first sign-in ever bound one. Survives sign-out and
    /// `resetForResync` — it is what lets a host recognise the same account
    /// coming back and refuse a different one.
    public func boundAccount() async throws -> String? {
        let boundedDatabase = self.boundedDatabase
        return try await onQueue {
            try boundedDatabase.write { conn in
                try Self.ensureBookkeeping(in: conn)
                return try Self.boundAccount(in: conn)
            }
        }
    }

    /// Binds the store to `account` (a principal id) and records it as the
    /// signed-in account. Keeps the cursor. This is the explicit bind: it
    /// overrides whatever the store was bound to, so a host calls it only
    /// when it has decided the data belongs to `account`.
    public func bind(account: String) async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
                try store.writeBinding(account, in: conn)
            }
            store.signedIn.set(.account(account))
        }
    }

    private func writeBinding(_ account: String, in conn: Database) throws {
        try conn.execute(
            sql: """
                INSERT INTO _sync_state (id, bound_account) VALUES (1, ?)
                ON CONFLICT(id) DO UPDATE SET bound_account = excluded.bound_account
                """,
            arguments: [account])
    }

    private static func boundAccount(in conn: Database) throws -> String? {
        try String.fetchOne(conn, sql: "SELECT bound_account FROM _sync_state WHERE id = 1")
    }

    /// Who the host says is signed in. In memory only: a host declares it
    /// on every launch and every identity change.
    public enum SignedInAccount: Sendable, Equatable {
        /// The host never said. The store does not guard — the host owns
        /// the decision (the behaviour of every host written before this).
        case undeclared
        case signedOut
        case account(String)
    }

    /// What `signIn(account:)` decided.
    public enum AccountBinding: Sendable, Equatable {
        /// `account` is the bound account (it was already, or the store was
        /// empty and unbound and is bound now). Push and pull run.
        case bound(String)
        /// The store belongs to another account. Push and pull refuse with
        /// `SyncStoreFailure.accountMismatch` until that account signs back
        /// in or the host explicitly calls `discardAccountState(rebindingTo:)`.
        case mismatch(bound: String, signedIn: String)
    }

    private let signedIn = SignedInState()

    /// Declares `account` signed in and enforces the binding from now on:
    /// the same account (or an empty unbound store, which binds) syncs;
    /// anyone else is refused at `cursor`, `apply` and `pendingOps`, so no
    /// queued op of the bound account is ever pushed under another account's
    /// credentials and nothing of another account is pulled over its rows.
    /// Nothing is deleted either way.
    public func signIn(account: String) async throws -> AccountBinding {
        let store = self
        return try await onQueue {
            let outcome = try store.boundedDatabase.write { conn -> AccountBinding in
                try store.ensureSchema(in: conn)
                if let bound = try Self.boundAccount(in: conn) {
                    return bound == account ? .bound(account) : .mismatch(bound: bound, signedIn: account)
                }
                try store.writeBinding(account, in: conn)
                return .bound(account)
            }
            store.signedIn.set(.account(account))
            return outcome
        }
    }

    /// Declares that nobody is signed in: push and pull refuse until a
    /// sign-in. Local data, the outbox and the cursor are all kept.
    public func signOut() {
        signedIn.set(.signedOut)
    }

    /// What the host last declared.
    public var signedInAccount: SignedInAccount { signedIn.value }

    /// Explicitly gives the store to `account`: discards the previous
    /// account's queued work — every `_sync_outbox` op and each projection's
    /// `discardLocalState` (e.g. Markdown's `_markdown_outbox`,
    /// `_markdown_remote_id`, `_markdown_frontmatter_owner`) — clears the
    /// cursor so `account` pulls from scratch, and binds. Mirror rows are
    /// kept with their provenance. The only path that drops queued work;
    /// a host calls it only on the user's explicit say-so.
    public func discardAccountState(rebindingTo account: String) async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
                try conn.execute(sql: "DELETE FROM _sync_outbox")
                for projection in store.mirrorProjections { try projection.discardLocalState(in: conn) }
                try conn.execute(sql: "UPDATE _sync_state SET cursor = NULL")
                try store.writeBinding(account, in: conn)
            }
            store.signedIn.set(.account(account))
        }
    }

    /// Throws `SyncStoreFailure.accountMismatch` when the declared signed-in
    /// account may not sync this store. For work outside the store that acts
    /// for the bound account (`MarkdownStore.drainRemoteQueue`).
    public func checkAccountGuard() throws {
        guard signedIn.value != .undeclared else { return }
        try boundedDatabase.read { conn in try self.checkAccountGuard(in: conn) }
    }

    private func checkAccountGuard(in conn: Database) throws {
        let bound = try Self.readableBoundAccount(in: conn)
        switch signedIn.value {
        case .undeclared:
            return
        case .signedOut:
            throw SyncStoreFailure.accountMismatch(bound: bound, signedIn: nil)
        case .account(let account):
            if bound == account { return }
            if bound == nil { return }
            throw SyncStoreFailure.accountMismatch(bound: bound, signedIn: account)
        }
    }

    /// `bound_account` on any schema, `nil` where the table or column does
    /// not exist yet (a read transaction cannot add them).
    private static func readableBoundAccount(in conn: Database) throws -> String? {
        guard try conn.tableExists("_sync_state"),
              try conn.columns(in: "_sync_state").contains(where: { $0.name == "bound_account" })
        else { return nil }
        return try boundAccount(in: conn)
    }

    /// Whether the store holds anything an account could own: a generic
    /// mirror row or a queued op.
    private func holdsData(in conn: Database) throws -> Bool {
        if try conn.tableExists("_sync_outbox"),
           try Bool.fetchOne(conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_outbox)") == true {
            return true
        }
        guard try conn.tableExists("_sync_resources") else { return false }
        for resource in try String.fetchAll(conn, sql: "SELECT resource FROM _sync_resources")
        where projection(for: resource) == nil {
            let table = try Self.mirrorTableName(for: resource)
            guard try conn.tableExists(table) else { continue }
            if try Bool.fetchOne(conn, sql: "SELECT EXISTS(SELECT 1 FROM \"\(table)\")") == true { return true }
        }
        return false
    }

    /// `'account:<principalId>'`, the `origin` of a row pulled from that
    /// account; `'local'` when the store is bound to none.
    public static func origin(forAccount account: String?) -> String {
        account.map { "account:\($0)" } ?? "local"
    }

    /// `reached_accounts` with `account` added (a JSON array, sorted, no
    /// duplicates). An unreadable value is replaced rather than failing the
    /// write it rides in.
    static func adding(_ account: String, toReached json: String?) -> String {
        let existing = json.flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
        let merged = Array(Set(existing + [account])).sorted()
        let data = (try? JSONEncoder().encode(merged)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func reachedJSON(for account: String?) -> String {
        account.map { adding($0, toReached: nil) } ?? "[]"
    }

    private static func markReached(_ account: String, table: String, id: String, in conn: Database) throws {
        guard let current = try String.fetchOne(
            conn, sql: "SELECT reached_accounts FROM \"\(table)\" WHERE id = ?", arguments: [id])
        else { return }
        try conn.execute(
            sql: "UPDATE \"\(table)\" SET reached_accounts = ? WHERE id = ?",
            arguments: [adding(account, toReached: current), id])
    }

    public func cursor() async throws -> SyncCursor? {
        let store = self
        return try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
                // The pull loop's first call: refusing here means no fetch
                // is ever made under an account the store does not belong to.
                try store.checkAccountGuard(in: conn)
                return try String.fetchOne(conn, sql: "SELECT cursor FROM _sync_state WHERE id = 1")
            }.map(SyncCursor.init(rawValue:))
        }
    }

    public func apply(_ batch: [SyncChange], advancingTo cursor: SyncCursor?) async throws {
        let store = self
        // Built here, not held. See the note on this type's `@unchecked
        // Sendable` conformance.
        let encoder = JSONEncoder()
        try await onQueue {
            try store.boundedDatabase.write { conn in
                // A host may call apply first on an older database: the
                // bound_account column and _change_log must exist.
                try store.ensureSchema(in: conn)
                try store.checkAccountGuard(in: conn)
                let bound = try Self.boundAccount(in: conn)
                let origin = Self.origin(forAccount: bound)
                for change in batch {
                    let isKnown = try Bool.fetchOne(
                        conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
                        arguments: [change.resource]
                    ) ?? false
                    guard isKnown else {
                        throw SyncStoreFailure.unknownResource(change.resource)
                    }
                    // Strict: reject an unparseable syncVersion rather than
                    // silently coercing to 0 and corrupting the mirror's version
                    // ordering. Two distinct sources feed this guard, and only one
                    // is wire-validated: a *pulled* change's syncVersion is
                    // guaranteed `/^\d+$/` by the wire schema (adh src/sync/wire.ts),
                    // but a change synthesized from a conflict's `current` blob is
                    // NOT — that blob is unvalidated on the wire. The engine
                    // pre-screens conflict adoptions numerically (SyncEngine
                    // `adoptedVersion`, quarantining a non-numeric current before it
                    // ever reaches apply), so by the time we get here the value is
                    // either wire-guaranteed (pull) or engine-guaranteed (adoption);
                    // a failure here therefore means something upstream is genuinely
                    // broken, hence the loud throw.
                    guard let version = Int(change.syncVersion) else {
                        throw SyncStoreFailure.invalidChange("unparseable syncVersion: \(change.syncVersion)")
                    }
                    if let projection = store.projection(for: change.resource) {
                        if change.op == .delete {
                            try projection.markDeleted(
                                resource: change.resource, id: change.id,
                                syncVersion: version, in: conn)
                        } else {
                            // A pulled change is adh's whole current row, not a
                            // partial patch — `isFullRow: true` is what lets a
                            // projection force-bind a delete-state column here
                            // that it must leave alone on `stage`'s partial-patch
                            // path below.
                            try projection.upsert(
                                resource: change.resource, id: change.id, syncVersion: version,
                                data: change.data ?? [:], isFullRow: true, in: conn)
                        }
                        continue
                    }
                    let table = try Self.mirrorTableName(for: change.resource)
                    if change.op == .delete {
                        try conn.execute(
                            sql: """
                                INSERT INTO "\(table)"
                                    (id, sync_version, deleted_at, data, origin, reached_accounts, local_version)
                                VALUES (?, ?, datetime('now'), '{}', ?, ?, 1)
                                ON CONFLICT(id) DO UPDATE SET
                                    sync_version = excluded.sync_version, deleted_at = excluded.deleted_at, data = '{}',
                                    local_version = local_version + 1
                                """,
                            arguments: [change.id, version, origin, Self.reachedJSON(for: bound)]
                        )
                        try Self.logChange(
                            resource: change.resource, table: table, id: change.id, kind: .delete, in: conn)
                    } else {
                        let payload = String(data: try encoder.encode(change.data ?? [:]), encoding: .utf8) ?? "{}"
                        try conn.execute(
                            sql: """
                                INSERT INTO "\(table)"
                                    (id, sync_version, deleted_at, data, origin, reached_accounts, local_version)
                                VALUES (?, ?, NULL, ?, ?, ?, 1)
                                ON CONFLICT(id) DO UPDATE SET
                                    sync_version = excluded.sync_version, deleted_at = NULL, data = excluded.data,
                                    local_version = local_version + 1
                                """,
                            arguments: [change.id, version, payload, origin, Self.reachedJSON(for: bound)]
                        )
                        // A row already here (written locally, or pulled
                        // before) keeps its origin; it has now reached the
                        // bound account too.
                        if let bound {
                            try Self.markReached(bound, table: table, id: change.id, in: conn)
                        }
                        try Self.logChange(
                            resource: change.resource, table: table, id: change.id, kind: .upsert, in: conn)
                    }
                }
                // Every projection, not only those the batch reached: one may
                // derive from a resource it does not own (a title kept in the
                // generic mirror).
                for projection in store.mirrorProjections { try projection.finishBatch(in: conn) }
                if let cursor {
                    try conn.execute(
                        sql: """
                            INSERT INTO _sync_state (id, cursor) VALUES (1, ?)
                            ON CONFLICT(id) DO UPDATE SET cursor = excluded.cursor
                            """,
                        arguments: [cursor.rawValue]
                    )
                }
            }
            store.changeSignal.fire()
        }
    }

    /// Local mutation: optimistic mirror write + outbox op, atomic. If a
    /// `pending` (not yet `inflight`/`quarantined`) outbox op already exists
    /// for this (resource, rowId), it is coalesced in place — same opId,
    /// same original `baseVersion` (the version the user's edits started
    /// from) — rather than minting a second op with a now-stale baseVersion
    /// that would conflict against the first on push. See sync fix-wave
    /// item p2a: two ops with the same baseVersion → server applies the
    /// first and stale-conflicts the second, silently dropping the newer
    /// edit.
    ///
    /// The resource must already be registered via `prepare(resources:)` —
    /// staging offline for an unprepared resource throws
    /// `SyncStoreFailure.unknownResource` rather than a raw SQL error
    /// against a mirror table that was never created (sync fix-wave item
    /// p2o).
    public func stage(_ mutation: LocalMutation) async throws {
        // Pull-only guard first, before any DB work — twin-identical ordering
        // to InMemorySyncStore.stage (pull-only refusal precedes the
        // unknown-resource check).
        guard !pullOnlyResources.contains(mutation.resource) else {
            throw SyncStoreFailure.pullOnlyResource(mutation.resource)
        }
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.stage(mutation, in: conn)
            }
            store.changeSignal.fire()
        }
    }

    /// The body of `stage(_:)`, for a caller that already holds a write
    /// transaction — the mirror write and the outbox op must land together,
    /// and `stage(_:)`'s queue hop would lose the caller's transaction and
    /// deadlock the pool's writer.
    public func stage(_ mutation: LocalMutation, in conn: Database) throws {
        guard !pullOnlyResources.contains(mutation.resource) else {
            throw SyncStoreFailure.pullOnlyResource(mutation.resource)
        }
        let isKnown = try Bool.fetchOne(
            conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
            arguments: [mutation.resource]
        ) ?? false
        guard isKnown else {
            throw SyncStoreFailure.unknownResource(mutation.resource)
        }
        try ensureSchema(in: conn)
        // Built here, not held. See the note on this type's `@unchecked
        // Sendable` conformance.
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let base: Int?
        if let projection = projection(for: mutation.resource) {
            base = try projection.syncVersion(resource: mutation.resource, id: mutation.rowId, in: conn)
            if mutation.type == .delete {
                try projection.markDeleted(
                    resource: mutation.resource, id: mutation.rowId, syncVersion: nil, in: conn)
            } else {
                // A staged local mutation is a deliberate partial patch, not
                // adh's whole row — `isFullRow: false` is what stops a
                // projection from force-binding a delete-state column here
                // the way it does on the pull path above, which would
                // otherwise silently clear a tombstone the patch never meant
                // to touch.
                try projection.upsert(
                    resource: mutation.resource, id: mutation.rowId, syncVersion: base ?? 0,
                    data: mutation.data ?? [:], isFullRow: false, in: conn)
            }
            try projection.finishBatch(in: conn)
        } else {
            let table = try Self.mirrorTableName(for: mutation.resource)
            base = try Int.fetchOne(
                conn, sql: "SELECT sync_version FROM \"\(table)\" WHERE id = ?", arguments: [mutation.rowId]
            )
            if mutation.type == .delete {
                try conn.execute(
                    sql: """
                        UPDATE "\(table)" SET deleted_at = datetime('now'), local_version = local_version + 1
                        WHERE id = ?
                        """,
                    arguments: [mutation.rowId]
                )
                if conn.changesCount > 0 {
                    try Self.logChange(
                        resource: mutation.resource, table: table, id: mutation.rowId, kind: .delete, in: conn)
                }
            } else {
                let payload = String(data: try encoder.encode(mutation.data ?? [:]), encoding: .utf8) ?? "{}"
                try conn.execute(
                    sql: """
                        INSERT INTO "\(table)" (id, sync_version, deleted_at, data, local_version)
                        VALUES (?, ?, NULL, ?, 1)
                        ON CONFLICT(id) DO UPDATE SET
                            deleted_at = NULL, data = excluded.data, local_version = local_version + 1
                        """,
                    arguments: [mutation.rowId, base ?? 0, payload]
                )
                try Self.logChange(
                    resource: mutation.resource, table: table, id: mutation.rowId, kind: .upsert, in: conn)
            }
        }

        let existing = try Row.fetchOne(
            conn,
            sql: """
                SELECT op_id, payload FROM _sync_outbox
                WHERE resource = ? AND row_id = ? AND status = 'pending' LIMIT 1
                """,
            arguments: [mutation.resource, mutation.rowId]
        )
        if let existing {
            let opId: String = existing["op_id"]
            let mergedPayload: [String: JSONValue]
            switch mutation.type {
            case .upsert:
                let existingPayload: [String: JSONValue] = try (existing["payload"] as String?)
                    .flatMap { $0.data(using: .utf8) }
                    .map { try decoder.decode([String: JSONValue].self, from: $0) } ?? [:]
                mergedPayload = existingPayload.merging(mutation.data ?? [:]) { _, new in new }
            case .delete:
                mergedPayload = [:]
            }
            let mergedPayloadString = String(data: try encoder.encode(mergedPayload), encoding: .utf8) ?? "{}"
            try conn.execute(
                sql: "UPDATE _sync_outbox SET type = ?, payload = ? WHERE op_id = ?",
                arguments: [mutation.type.rawValue, mergedPayloadString, opId]
            )
        } else {
            let opPayload = String(data: try encoder.encode(mutation.data ?? [:]), encoding: .utf8) ?? "{}"
            try conn.execute(
                sql: """
                    INSERT INTO _sync_outbox
                        (op_id, resource, row_id, type, base_version, payload, status, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, 'pending', datetime('now'))
                    """,
                arguments: [SyncID.uuidV7(), mutation.resource, mutation.rowId, mutation.type.rawValue,
                            base.map(String.init), opPayload]
            )
        }
    }

    /// Returns up to `limit` outbox ops in insertion order (`rowid` — the
    /// FIFO order the ops were created in), and marks every returned op
    /// `inflight` in the same transaction. Ops already `inflight` (from a
    /// prior call whose push never completed — a crash, or a server
    /// round-trip still outstanding) are included again: replaying the same
    /// opIds on retry is the server contract's idempotency guarantee.
    public func pendingOps(limit: Int) async throws -> [SyncPushOp] {
        let store = self
        // Built here, not held. See the note on this type's `@unchecked
        // Sendable` conformance.
        let decoder = JSONDecoder()
        return try await onQueue {
            try store.boundedDatabase.write { conn in
                // Before anything is claimed: the bound account's queued ops
                // are never handed out while another account is signed in.
                try store.checkAccountGuard(in: conn)
                let rows = try Row.fetchAll(
                    conn,
                    sql: """
                        SELECT op_id, resource, row_id, type, base_version, payload FROM _sync_outbox
                        WHERE status IN ('pending', 'inflight') ORDER BY rowid LIMIT ?
                        """,
                    arguments: [limit]
                )
                let opIds: [String] = rows.map { $0["op_id"] }
                if !opIds.isEmpty {
                    let placeholders = Array(repeating: "?", count: opIds.count).joined(separator: ", ")
                    try conn.execute(
                        sql: "UPDATE _sync_outbox SET status = 'inflight' WHERE op_id IN (\(placeholders))",
                        arguments: StatementArguments(opIds)
                    )
                }
                return try rows.map { row in
                    let payload: [String: JSONValue] = try (row["payload"] as String?)
                        .flatMap { $0.data(using: .utf8) }
                        .map { try decoder.decode([String: JSONValue].self, from: $0) } ?? [:]
                    let typeColumn: String = row["type"]
                    // Strict: a corrupt/unrecognized `type` column means the
                    // outbox row can't be trusted — silently defaulting to
                    // `.upsert` could push a mutation the caller never made
                    // (e.g. resurrect a row that was actually staged as a
                    // delete). Fail loudly instead.
                    guard let type = SyncChangeOp(rawValue: typeColumn) else {
                        throw SyncStoreFailure.invalidChange("corrupt outbox type column: \(typeColumn)")
                    }
                    return SyncPushOp(
                        opId: row["op_id"],
                        resource: row["resource"],
                        rowId: row["row_id"],
                        type: type,
                        baseVersion: row["base_version"],
                        data: payload.isEmpty ? nil : payload
                    )
                }
            }
        }
    }

    public func complete(_ results: [SyncPushResult]) async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                // Before reading bound_account: failing here would roll back
                // a completion the server has already applied.
                try store.ensureSchema(in: conn)
                for result in results {
                    switch result.status {
                    case .applied, .conflict:
                        let meta = try Row.fetchOne(
                            conn, sql: "SELECT resource, row_id FROM _sync_outbox WHERE op_id = ?",
                            arguments: [result.opId]
                        )
                        if result.status == .conflict {
                            try conn.execute(
                                sql: """
                                    INSERT INTO _sync_conflicts (op_id, resource, row_id, reason, resolved_at)
                                    VALUES (?, ?, ?, ?, datetime('now'))
                                    """,
                                arguments: [
                                    result.opId, meta?["resource"] as String?, meta?["row_id"] as String?,
                                    result.reason
                                ]
                            )
                        } else if let newVersion = result.newVersion,
                                  let resource = meta?["resource"] as String?,
                                  let rowId = meta?["row_id"] as String? {
                            // Adopt the server's post-apply sync_version onto the mirror
                            // row BEFORE deleting the outbox row, in the same
                            // transaction, so a stage() call racing this completion
                            // (or arriving right after it) snapshots the correct
                            // baseVersion — closing the stage-during-push
                            // self-conflict race (adh sync.md §3).
                            //
                            // Strict, same rationale as item (g): `Int(newVersion) ?? 0`
                            // would silently stamp sync_version = 0 on an unparseable
                            // value, corrupting the mirror row's ordering. But unlike
                            // apply()'s invalidChange throw, this runs inside the push
                            // completion transaction — throwing here would abort the
                            // whole transaction, leave the outbox row in place, and
                            // wedge on replay even though the server already applied the
                            // op. So: skip adoption (treat as absent) rather than throw;
                            // the outbox row is still deleted below.
                            if let intVersion = Int(newVersion) {
                                if let projection = store.projection(for: resource) {
                                    try projection.setSyncVersion(
                                        intVersion, resource: resource, id: rowId, in: conn)
                                } else {
                                    let table = try Self.mirrorTableName(for: resource)
                                    try conn.execute(
                                        sql: "UPDATE \"\(table)\" SET sync_version = ? WHERE id = ?",
                                        arguments: [intVersion, rowId]
                                    )
                                }
                            }
                        }
                        // An applied push has reached the bound account.
                        if result.status == .applied,
                           let bound = try Self.boundAccount(in: conn),
                           let resource = meta?["resource"] as String?,
                           let rowId = meta?["row_id"] as String?,
                           store.projection(for: resource) == nil {
                            try Self.markReached(
                                bound, table: try Self.mirrorTableName(for: resource), id: rowId, in: conn)
                        }
                        try conn.execute(sql: "DELETE FROM _sync_outbox WHERE op_id = ?", arguments: [result.opId])
                    case .rejected:
                        try conn.execute(
                            sql: """
                                UPDATE _sync_outbox SET status = 'quarantined', attempts = attempts + 1
                                WHERE op_id = ?
                                """,
                            arguments: [result.opId]
                        )
                    }
                }
            }
        }
    }

    /// Clears the cursor, never the binding: a resync re-fetches data for the
    /// same account.
    public func resetForResync() async throws {
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
                let tables = try String.fetchAll(conn, sql: "SELECT resource FROM _sync_resources")
                try store.deleteMirrorRows(for: tables, in: conn)
                try conn.execute(sql: "UPDATE _sync_state SET cursor = NULL")
            }
        }
    }

    /// resource -> registered schema_version, the twin of
    /// `InMemorySyncStore.registrations()`. Bootstraps the bookkeeping schema
    /// first (same cold-start rationale as `cursor()`): on a never-prepared
    /// store this returns `[:]` rather than throwing "no such table:
    /// _sync_resources".
    public func registrations() async throws -> [String: Int] {
        let store = self
        return try await onQueue {
            try store.boundedDatabase.write { conn in
                try store.ensureSchema(in: conn)
                var out: [String: Int] = [:]
                let rows = try Row.fetchAll(
                    conn, sql: "SELECT resource, schema_version FROM _sync_resources")
                for row in rows { out[row["resource"]] = row["schema_version"] }
                return out
            }
        }
    }

    /// Enrollment-disable transition (twin of
    /// `InMemorySyncStore.purgeResources`): for each named resource, empty its
    /// mirror table, move its `pending`/`inflight` outbox ops to
    /// `quarantined` (never dropped — a fixed retry must re-`stage` for a
    /// fresh opId; already-`quarantined`/completed rows untouched), and remove
    /// its registration. The cursor (`_sync_state`) is deliberately left
    /// untouched. Like the other recovery paths this only ever `DELETE`s rows
    /// — it never drops a table or touches the database file.
    public func purgeResources(_ resources: [String]) async throws {
        guard !resources.isEmpty else { return }
        let store = self
        try await onQueue {
            try store.boundedDatabase.write { conn in
                // Empty the mirror rows of the registered subset only — an
                // unregistered resource has no mirror table, so its purge is a
                // silent no-op (twin of InMemorySyncStore.purgeResources) rather
                // than a "no such table" throw.
                try store.deleteMirrorRows(for: resources, in: conn)
                for resource in resources {
                    try conn.execute(
                        sql: """
                            UPDATE _sync_outbox SET status = 'quarantined'
                            WHERE resource = ? AND status IN ('pending', 'inflight')
                            """,
                        arguments: [resource])
                    try conn.execute(
                        sql: "DELETE FROM _sync_resources WHERE resource = ?",
                        arguments: [resource])
                }
            }
        }
    }

    // MARK: - Read helpers (hosts: daemon serving + UI observation)

    /// The resource must already be registered via `prepare(resources:)`;
    /// an unregistered resource throws `SyncStoreFailure.unknownResource`
    /// (checked against `_sync_resources` before the mirror table is even
    /// named — sync fix-wave item p2o).
    ///
    /// Offset pagination here is contract-bound, not a free design choice:
    /// the mirror deliberately shadows the backend's own offset/limit REST
    /// paging contract, because the daemon is a transparent proxy — it
    /// cannot invent a different paging API for its offline fallback.
    /// `O(offset)` is therefore accepted rather than eliminated: callers cap
    /// `limit` (`MirrorServer`'s `listLimit`, currently 200), which bounds
    /// how deep a page scan can go. `ORDER BY id` rides the mirror table's
    /// primary-key index for free; access beyond `id` would go through the
    /// JSON1 expressions over the `data` blob by design — the mirror stores
    /// arbitrary resource fields schema-evolution-free, without a typed
    /// column per field, so there is nowhere else for non-PK access to live.
    public func liveRows(resource: String, limit: Int = 100, offset: Int = 0) throws -> [[String: JSONValue]] {
        try boundedDatabase.read { conn in
            let isKnown = try Bool.fetchOne(
                conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
                arguments: [resource]
            ) ?? false
            guard isKnown else {
                throw SyncStoreFailure.unknownResource(resource)
            }
            if let projection = self.projection(for: resource) {
                return try projection.rows(resource: resource, limit: limit, offset: offset, in: conn)
            }
            let table = try Self.mirrorTableName(for: resource)
            let rows = try Row.fetchAll(
                conn,
                sql: "SELECT id, data FROM \"\(table)\" WHERE deleted_at IS NULL ORDER BY id LIMIT ? OFFSET ?",
                arguments: [limit, offset]
            )
            return try rows.map { try self.materialize($0) }
        }
    }

    /// Same unregistered-resource contract as `liveRows` above.
    public func liveRow(resource: String, id: String) throws -> [String: JSONValue]? {
        try boundedDatabase.read { conn in
            let isKnown = try Bool.fetchOne(
                conn, sql: "SELECT EXISTS(SELECT 1 FROM _sync_resources WHERE resource = ?)",
                arguments: [resource]
            ) ?? false
            guard isKnown else {
                throw SyncStoreFailure.unknownResource(resource)
            }
            if let projection = self.projection(for: resource) {
                return try projection.row(resource: resource, id: id, in: conn)
            }
            let table = try Self.mirrorTableName(for: resource)
            return try Row.fetchOne(
                conn,
                sql: "SELECT id, data FROM \"\(table)\" WHERE id = ? AND deleted_at IS NULL",
                arguments: [id]
            ).map { try self.materialize($0) }
        }
    }

    private func materialize(_ row: Row) throws -> [String: JSONValue] {
        // Built here, not held. See the note on this type's `@unchecked
        // Sendable` conformance.
        let decoder = JSONDecoder()
        var object = try ((row["data"] as String?)?.data(using: .utf8))
            .map { try decoder.decode([String: JSONValue].self, from: $0) } ?? [:]
        object["id"] = .string(row["id"])
        return object
    }

    public func registeredResources() throws -> Set<String> {
        try boundedDatabase.read { conn in
            Set(try String.fetchAll(conn, sql: "SELECT resource FROM _sync_resources"))
        }
    }

    public func status() throws -> GRDBSyncStoreStatus {
        try boundedDatabase.read { conn in
            // pending + inflight: both are unresolved ops still owed to the
            // server (inflight just means a push round-trip is outstanding).
            let outboxDepth = try Int.fetchOne(
                conn, sql: "SELECT COUNT(*) FROM _sync_outbox WHERE status IN ('pending', 'inflight')"
            ) ?? 0
            let quarantinedDepth = try Int.fetchOne(
                conn, sql: "SELECT COUNT(*) FROM _sync_outbox WHERE status = 'quarantined'"
            ) ?? 0
            return GRDBSyncStoreStatus(
                cursor: try String.fetchOne(conn, sql: "SELECT cursor FROM _sync_state WHERE id = 1"),
                outboxDepth: outboxDepth,
                quarantinedDepth: quarantinedDepth,
                conflictCount: try Int.fetchOne(conn, sql: "SELECT COUNT(*) FROM _sync_conflicts") ?? 0
            )
        }
    }
}

/// The declared signed-in account, lock-protected so the store holding it
/// stays honestly `Sendable` (its property is a `let`).
final class SignedInState: @unchecked Sendable {
    private let lock = NSLock()
    private var current: GRDBSyncStore.SignedInAccount = .undeclared

    var value: GRDBSyncStore.SignedInAccount { lock.withLock { current } }

    func set(_ value: GRDBSyncStore.SignedInAccount) {
        lock.withLock { current = value }
    }
}
