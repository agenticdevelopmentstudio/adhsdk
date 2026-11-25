#if canImport(AgenticDeveloperHubSDKCore)
import Foundation
import AgenticDeveloperHubSDKCore
import GRDB

// `db` is the one name for the shared DaemonDatabase, as in the toolkit.
// swiftlint:disable identifier_name

/// Billing storage: schema 46 and the SQL over it.
///
/// Lives in its own file, as the rest of the database features do; the
/// low-level `execute` / `query` / `migrationExecute`
/// helpers are public on `DaemonDatabase` for exactly this reason.
extension DaemonDatabase {

    // MARK: - Schema

    /// `billing_entry.description_edited`: a hand-written description on an
    /// entry the rollup still recomputes. Separate from `origin` because
    /// editing the words must not freeze the figures (see
    /// `BillingRollup.saveEntry`).
    ///
    /// Shared by `migration1002` and the post-runner self-heal in
    /// `runMigrations`. It has to run outside the version gate: a database
    /// that installed an earlier build of this branch already records version
    /// 46 without the column, so `migration1002` never runs there again, and
    /// every rollup would fail on "no such column". Idempotent, and a no-op
    /// before `billing_entry` exists.
    static func ensureBillingEntryDescriptionEditedColumn(_ db: DaemonDatabase) throws {
        guard try db.tableExists("billing_entry"),
              try !db.tableHasColumn("billing_entry", "description_edited") else { return }
        try db.migrationExecute(
            "ALTER TABLE billing_entry ADD COLUMN description_edited INTEGER NOT NULL DEFAULT 0"
        )
    }

    /// `billing_entry.billed_ranges`: the intervals of wall-clock time an
    /// entry bills, as `start-end` epoch-second pairs joined by `;` (`NULL` =
    /// never recorded). The rollup writes it on every create and recompute,
    /// so a frozen entry owns exactly what it recorded and every other entry
    /// on its day bills around it (`BillingRollup.settleDay`).
    ///
    /// Outside the version gate like `ensureBillingEntryDescriptionEditedColumn`,
    /// for the same reason. Idempotent, and a no-op before the table exists.
    /// (An earlier build of this branch kept `billed_ranges` and
    /// `rollup_settled` on `billing_segment`; nothing reads them now, and a
    /// leftover column is harmless.)
    static func ensureBillingEntryBilledRangesColumn(_ db: DaemonDatabase) throws {
        guard try db.tableExists("billing_entry"),
              try !db.tableHasColumn("billing_entry", "billed_ranges") else { return }
        try db.migrationExecute("ALTER TABLE billing_entry ADD COLUMN billed_ranges TEXT")
    }

    /// The two lookups every rollup pass makes by a foreign id: a segment by
    /// the entry it is attached to (`billingSegmentsForEntry`, once per unbilled
    /// entry per pass, and `deleteEmptyBillingEntry`'s `NOT EXISTS`), and a
    /// supplement by the entry it supplements (`billingOpenSupplement`,
    /// `deleteBillingEntry`). Without them each is a scan of a table that only
    /// grows. Outside the version gate for the same reason as
    /// `ensureBillingEntryDescriptionEditedColumn`; idempotent, and a no-op
    /// before the tables exist.
    static func ensureBillingIndexes(_ db: DaemonDatabase) throws {
        if try db.tableExists("billing_segment") {
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_billing_segment_entry ON billing_segment(entry_id)"
            )
            // `billingEntriesOverlapping` reads one project's segments by
            // start; `idx_billing_segment_started` alone ranges over every
            // project's.
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_segment_project_started
                ON billing_segment(project_id, started_at)
            """)
            // The longest segment of a project bounds how far before a window
            // `billingEntriesOverlapping` must look; read off this index's
            // end in one step rather than by a scan.
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_segment_project_length
                ON billing_segment(project_id, \(Self.lengthSQL))
            """)
        }
        if try db.tableExists("billing_entry") {
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_entry_supplements
                ON billing_entry(supplements_entry_id, created_at) WHERE supplements_entry_id IS NOT NULL
            """)
            // Settling a day reads every entry of the project on it, whatever
            // its status (the unique index is partial, so it cannot serve),
            // and every entry overlapping its window by start
            // (`billingEntriesOverlapping`).
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_billing_entry_project_day_all ON billing_entry(project_id, day)"
            )
            try db.migrationExecute(
                "CREATE INDEX IF NOT EXISTS idx_billing_entry_project_started ON billing_entry(project_id, started_at)"
            )
            // The same bound for entries. The entries whose shown times were
            // blanked by a move (`started_at = ''`) are an equality seek of
            // `idx_billing_entry_project_started`, so need no index of their own.
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_entry_project_length
                ON billing_entry(project_id, \(Self.lengthSQL))
            """)
            // A frozen entry owns its recorded ranges wherever its shown times
            // now lie (moved, then a Start or End typed on the new day), so
            // `billingEntriesOverlapping` also finds frozen entries by where
            // their ranges lie: a start range bounded below by the longest
            // frozen span, read off the second index's end — the same bound
            // `idx_billing_entry_project_length` gives timed entries. The
            // first form, by range end alone, read every later frozen entry
            // of the project to settle an old day; it is dropped.
            try db.migrationExecute("DROP INDEX IF EXISTS idx_billing_entry_project_billed_end")
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_entry_project_billed_start
                ON billing_entry(project_id, \(Self.billedStartSQL)) WHERE \(Self.frozenWithRangesSQL)
            """)
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_billing_entry_project_billed_span
                ON billing_entry(project_id, \(Self.billedSpanSQL)) WHERE \(Self.frozenWithRangesSQL)
            """)
        }
        if try db.tableExists("activity_presence") {
            // `billingIdleIntervals` bounds a closed idle row's start from
            // below by the longest closed row, read off this index's end; an
            // open row (any length) is found by its own partial index.
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_activity_presence_length
                ON activity_presence(\(Self.idleLengthSQL)) WHERE idle_until <> ''
            """)
            try db.migrationExecute("""
                CREATE INDEX IF NOT EXISTS idx_activity_presence_open
                ON activity_presence(idle_from) WHERE idle_until = ''
            """)
        }
    }

    /// A row's length in seconds from its `started_at` and `ended_at`; NULL
    /// when either does not parse (an open row's `ended_at` is ""). Written
    /// once, because an index on an expression serves only a query spelling
    /// it the same way, unqualified.
    static let lengthSQL =
        "CAST(strftime('%s', ended_at) AS INTEGER) - CAST(strftime('%s', started_at) AS INTEGER)"

    /// The end of a row's last recorded range and the start of its first, in
    /// epoch seconds (ranges are stored normalized, so in order). Spelled
    /// once and unqualified for the same reason as `lengthSQL`.
    static let billedEndSQL = "json_extract(\(billedRangesJSON("billed_ranges")), '$[#-1][1]')"
    static let billedStartSQL = "json_extract(\(billedRangesJSON("billed_ranges")), '$[0][0]')"
    /// From the start of a row's first range to the end of its last.
    static let billedSpanSQL = "\(billedEndSQL) - \(billedStartSQL)"

    /// A frozen entry with recorded ranges: the partial index's condition,
    /// spelled once so the query using it implies it.
    static let frozenWithRangesSQL = "billed_ranges IS NOT NULL AND (locked = 1 OR origin = 'user')"

    /// A closed idle row's length in seconds (see `lengthSQL`).
    static let idleLengthSQL =
        "CAST(strftime('%s', idle_until) AS INTEGER) - CAST(strftime('%s', idle_from) AS INTEGER)"

    /// `billed_ranges` (`start-end;start-end`) as a JSON array of pairs, for
    /// `json_each`: `[]` when the column is NULL or does not parse.
    static func billedRangesJSON(_ column: String) -> String {
        let json = "'[[' || replace(replace(\(column), ';', '],['), '-', ',') || ']]'"
        return "CASE WHEN \(column) IS NOT NULL AND json_valid(\(json)) THEN \(json) ELSE '[]' END"
    }

    /// True for an entry the user sees: every one but an auto entry the
    /// rollup left owning nothing, which is kept (a later recompute may fill
    /// it again) but never shown as a $0 line or counted. One whose
    /// description the user wrote stays listed: those words are theirs to
    /// find, edit or delete. `alias` qualifies the columns (`"sup."`).
    static func visibleEntry(alias: String) -> String {
        "NOT (\(alias)locked = 0 AND \(alias)origin = 'auto' AND \(alias)raw_seconds = 0"
            + " AND \(alias)description_edited = 0)"
    }

    static let visibleEntry = visibleEntry(alias: "")

    /// The sessions a billing pass has not consumed yet, and nothing else.
    /// `sessionsNeedingBillingDerivation` asks exactly this index's `WHERE`,
    /// so its pending arm reads a handful of index entries instead of walking
    /// every session. Small (tens of thousands of rows at most) and outside
    /// the version gate like the other billing ensure steps.
    static func ensureBillingDerivationPendingIndex(_ db: DaemonDatabase) throws {
        guard try db.tableExists("sessions"), try db.tableHasColumn("sessions", "billing_derived_at"),
              try db.tableHasColumn("sessions", "last_activity_at") else { return }
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_sessions_billing_pending
            ON sessions(last_activity_at) WHERE billing_derived_at <> last_activity_at
        """)
    }

    /// `billing_entry.locked` is `status <> 'unbilled'` by definition
    /// (`BillingStatus.locksTheEntry`), and everything that protects billed
    /// time reads `locked`. Four writers keep the two in step by convention;
    /// these triggers make the database keep them in step whoever writes, so a
    /// direct status change can never leave a billed row unprotected. The
    /// heal repairs any row already out of step. Idempotent.
    static func ensureBillingEntryLockedTriggers(_ db: DaemonDatabase) throws {
        guard try db.tableExists("billing_entry") else { return }
        let mismatch = "NEW.locked <> (NEW.status <> 'unbilled')"
        let fix = "UPDATE billing_entry SET locked = (NEW.status <> 'unbilled') WHERE id = NEW.id;"
        try db.migrationExecute("""
            CREATE TRIGGER IF NOT EXISTS billing_entry_locked_on_insert
            AFTER INSERT ON billing_entry WHEN \(mismatch)
            BEGIN \(fix) END
        """)
        try db.migrationExecute("""
            CREATE TRIGGER IF NOT EXISTS billing_entry_locked_on_update
            AFTER UPDATE OF status, locked ON billing_entry WHEN \(mismatch)
            BEGIN \(fix) END
        """)
        try db.migrationExecute("""
            UPDATE billing_entry SET locked = (status <> 'unbilled')
            WHERE locked <> (status <> 'unbilled')
        """)
    }

    /// 047: a project's own idle cutoff (minutes; NULL = the global setting).
    static func migration1003(_ db: DaemonDatabase) throws {
        guard try db.tableExists("billing_project"),
              try !db.tableHasColumn("billing_project", "idle_cutoff_minutes") else { return }
        try db.migrationExecute("ALTER TABLE billing_project ADD COLUMN idle_cutoff_minutes INTEGER")
    }

    /// Six tables plus one column on `sessions`.
    ///
    /// Every `ALTER TABLE … ADD COLUMN` is guarded by `tableHasColumn`. This is
    /// not belt-and-braces: branch divergence has made an unguarded ALTER re-run
    /// on an already-migrated DB, throw, and exit the daemon 0 with nothing in
    /// the log. `CREATE TABLE IF NOT EXISTS` gives the tables the same property.
    static func migration1002(_ db: DaemonDatabase) throws {
        logger.info("migration1002: creating the billing schema…")

        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_client (
                id           TEXT PRIMARY KEY,
                name         TEXT NOT NULL,
                contact_name TEXT NOT NULL DEFAULT '',
                email        TEXT NOT NULL DEFAULT '',
                phone        TEXT NOT NULL DEFAULT '',
                url          TEXT NOT NULL DEFAULT '',
                notes        TEXT NOT NULL DEFAULT '',
                currency     TEXT NOT NULL DEFAULT 'USD',
                archived     INTEGER NOT NULL DEFAULT 0,
                created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                updated_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
            )
        """)

        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_project (
                id                 TEXT PRIMARY KEY,
                client_id          TEXT,
                name               TEXT NOT NULL,
                notes              TEXT NOT NULL DEFAULT '',
                default_rate_cents INTEGER,
                rounding_minutes   INTEGER NOT NULL DEFAULT 15,
                rounding_mode      TEXT NOT NULL DEFAULT 'up'
                                   CHECK (rounding_mode IN ('up','nearest')),
                billing_enabled    INTEGER NOT NULL DEFAULT 1,
                archived           INTEGER NOT NULL DEFAULT 0,
                created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_project_client ON billing_project(client_id)"
        )

        // UNIQUE(project_root, branch) is the invariant that makes rate
        // resolution deterministic: a repo-and-branch pair belongs to exactly
        // one project. '' in `branch` means "any branch on this repo".
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_repo (
                id              TEXT PRIMARY KEY,
                project_id      TEXT NOT NULL,
                project_root    TEXT NOT NULL,
                branch          TEXT NOT NULL DEFAULT '',
                rate_cents      INTEGER,
                billing_enabled INTEGER NOT NULL DEFAULT 1,
                created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                UNIQUE(project_root, branch)
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_repo_project ON billing_repo(project_id)"
        )

        // `ended_at = ''` means running. A partial index over exactly those rows
        // makes "is a timer going?" a lookup rather than a scan.
        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_segment (
                id           TEXT PRIMARY KEY,
                session_id   TEXT NOT NULL DEFAULT '',
                origin       TEXT NOT NULL CHECK (origin IN ('auto','manual')),
                project_id   TEXT,
                repo_id      TEXT,
                project_root TEXT NOT NULL DEFAULT '',
                branch       TEXT NOT NULL DEFAULT '',
                started_at   TEXT NOT NULL,
                ended_at     TEXT NOT NULL DEFAULT '',
                tz           TEXT NOT NULL DEFAULT '',
                seconds      INTEGER NOT NULL DEFAULT 0,
                note         TEXT NOT NULL DEFAULT '',
                entry_id     TEXT,
                flags        TEXT NOT NULL DEFAULT '',
                created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                updated_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_segment_session ON billing_segment(session_id)"
        )
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_segment_started ON billing_segment(started_at)"
        )
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_billing_segment_unrolled
            ON billing_segment(project_id, started_at) WHERE entry_id IS NULL AND ended_at <> ''
        """)
        try db.migrationExecute("""
            CREATE INDEX IF NOT EXISTS idx_billing_segment_running
            ON billing_segment(origin) WHERE ended_at = ''
        """)
        // A derived run is identified by its session and start instant, so
        // re-deriving the same window updates rather than duplicating.
        try db.migrationExecute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_segment_auto_identity
            ON billing_segment(session_id, started_at) WHERE origin = 'auto'
        """)

        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_entry (
                id                   TEXT PRIMARY KEY,
                project_id           TEXT NOT NULL,
                client_id            TEXT,
                day                  TEXT NOT NULL,
                group_key            TEXT NOT NULL DEFAULT '',
                started_at           TEXT NOT NULL DEFAULT '',
                ended_at             TEXT NOT NULL DEFAULT '',
                raw_seconds          INTEGER NOT NULL DEFAULT 0,
                billed_seconds       INTEGER NOT NULL DEFAULT 0,
                rate_cents           INTEGER NOT NULL DEFAULT 0,
                currency             TEXT NOT NULL DEFAULT 'USD',
                amount_cents         INTEGER NOT NULL DEFAULT 0,
                rounding_minutes     INTEGER NOT NULL DEFAULT 15,
                rounding_mode        TEXT NOT NULL DEFAULT 'up'
                                     CHECK (rounding_mode IN ('up','nearest')),
                status               TEXT NOT NULL DEFAULT 'unbilled'
                                     CHECK (status IN ('unbilled','billed','paid')),
                description          TEXT NOT NULL DEFAULT '',
                origin               TEXT NOT NULL DEFAULT 'auto',
                locked               INTEGER NOT NULL DEFAULT 0,
                supplements_entry_id TEXT,
                description_edited   INTEGER NOT NULL DEFAULT 0,
                billed_ranges        TEXT,
                created_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                updated_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
            )
        """)
        try Self.ensureBillingEntryDescriptionEditedColumn(db)
        try Self.ensureBillingEntryBilledRangesColumn(db)
        try Self.ensureBillingIndexes(db)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_entry_status ON billing_entry(status, day)"
        )
        // The rollup target: one entry per project per local day per group.
        // `group_key` is '' (or `rate:<cents>` for a repo billing at its own
        // rate) at day granularity and the run's identity at run granularity —
        // without it, switching to itemised billing would collide on the
        // second run of the same day. A supplemental entry is
        // deliberately excluded so it can share the day with the frozen entry
        // it supplements.
        try db.migrationExecute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_entry_project_day
            ON billing_entry(project_id, day, group_key) WHERE supplements_entry_id IS NULL
        """)

        try db.migrationExecute("""
            CREATE TABLE IF NOT EXISTS billing_entry_audit (
                id        INTEGER PRIMARY KEY AUTOINCREMENT,
                entry_id  TEXT NOT NULL,
                at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
                field     TEXT NOT NULL,
                old_value TEXT NOT NULL DEFAULT '',
                new_value TEXT NOT NULL DEFAULT '',
                source    TEXT NOT NULL DEFAULT 'user' CHECK (source IN ('auto','user'))
            )
        """)
        try db.migrationExecute(
            "CREATE INDEX IF NOT EXISTS idx_billing_entry_audit_entry ON billing_entry_audit(entry_id, at)"
        )

        // The derivation watermark: how far billing has consumed this session's
        // activity. Guarded — see the doc comment. `tableExists` first because a
        // synthetic legacy-migration fixture (see `DatabaseManagerTests`) may
        // have no `sessions` table at all, mirroring `migration025`'s and
        // `ensureSessionsAuthMethodColumn`'s defensive checks.
        if try db.tableExists("sessions"), try !db.tableHasColumn("sessions", "billing_derived_at") {
            // One transaction: the guard above keys on the column, so an ALTER
            // committed without its backfill (the UPDATE failing on a full
            // disk, or the process dying in between) would make every re-run
            // skip the backfill and leave all history queued for derivation.
            try db.migrationTransaction {
                try db.migrationExecute(
                    "ALTER TABLE sessions ADD COLUMN billing_derived_at TEXT NOT NULL DEFAULT ''"
                )
                // Every session that exists at upgrade time counts as already
                // consumed. Backfill is a deliberate act (the Activity window's
                // "Derive History…", Task 22), not something the first pass does
                // to months of sessions the user never meant to bill. Inside the
                // guard, so a re-run cannot stamp over a watermark a later
                // backfill reset. Only when `last_activity_at` itself exists — a
                // minimal synthetic `sessions` stub may lack it too.
                if try db.tableHasColumn("sessions", "last_activity_at") {
                    try db.migrationExecute("UPDATE sessions SET billing_derived_at = last_activity_at")
                }
            }
        }

        logger.info("migration1002: billing schema ready")
    }

}

/// The billing tables' SQL, over the low-level `execute` / `query` /
/// `transaction` helpers `DaemonDatabase` exposes.
extension DaemonDatabase {

    // MARK: - Clients

    public func billingClients(includeArchived: Bool) throws -> [BillingClientDTO] {
        var rows: [BillingClientDTO] = []
        let filter = includeArchived ? "" : "WHERE archived = 0"
        try query("SELECT * FROM billing_client \(filter) ORDER BY name COLLATE NOCASE") { row in
            rows.append(Self.billingClient(from: row))
        }
        return rows
    }

    public func billingClient(id: String) throws -> BillingClientDTO? {
        var found: BillingClientDTO?
        try query("SELECT * FROM billing_client WHERE id = ?", params: [id]) { row in
            found = Self.billingClient(from: row)
        }
        return found
    }

    /// Insert-or-update by primary key. `updated_at` is supplied by the caller
    /// (`BillingStore`) so the store owns every clock read.
    public func upsertBillingClient(_ dto: BillingClientDTO) throws {
        try execute("""
            INSERT INTO billing_client
                (id, name, contact_name, email, phone, url, notes, currency, archived, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name, contact_name = excluded.contact_name,
                email = excluded.email, phone = excluded.phone, url = excluded.url,
                notes = excluded.notes, currency = excluded.currency,
                archived = excluded.archived, updated_at = excluded.updated_at
        """, params: [
            dto.id, dto.name, dto.contactName, dto.email, dto.phone, dto.url,
            dto.notes, dto.currency, dto.archived ? 1 : 0, dto.createdAt, dto.updatedAt
        ])
    }

    /// Detaching the projects is deliberate: a project outlives the client
    /// record, and a dangling `client_id` would make every later join lie.
    ///
    /// Only unbilled entries are detached. A billed or paid entry's
    /// `client_id` records who it was billed to and is frozen like the rest
    /// of it; `BillingStore.deleteClient` refuses before it gets here.
    public func deleteBillingClient(id: String) throws {
        try transaction {
            try execute("UPDATE billing_project SET client_id = NULL WHERE client_id = ?", params: [id])
            try execute(
                "UPDATE billing_entry SET client_id = NULL WHERE client_id = ? AND locked = 0", params: [id]
            )
            try execute("DELETE FROM billing_client WHERE id = ?", params: [id])
        }
    }

    /// How many billed or paid entries were billed to this client.
    public func billingLockedEntryCount(clientId: String) throws -> Int {
        var count = 0
        try query(
            "SELECT COUNT(*) AS n FROM billing_entry WHERE client_id = ? AND locked = 1", params: [clientId]
        ) { row in count = row["n"] ?? 0 }
        return count
    }

    // MARK: - Projects

    public func billingProjects(includeArchived: Bool) throws -> [BillingProjectDTO] {
        var rows: [BillingProjectDTO] = []
        let filter = includeArchived ? "" : "WHERE archived = 0"
        try query("SELECT * FROM billing_project \(filter) ORDER BY name COLLATE NOCASE") { row in
            rows.append(Self.billingProject(from: row))
        }
        return rows
    }

    public func billingProject(id: String) throws -> BillingProjectDTO? {
        var found: BillingProjectDTO?
        try query("SELECT * FROM billing_project WHERE id = ?", params: [id]) { row in
            found = Self.billingProject(from: row)
        }
        return found
    }

    public func upsertBillingProject(_ dto: BillingProjectDTO) throws {
        try execute("""
            INSERT INTO billing_project
                (id, client_id, name, notes, default_rate_cents, rounding_minutes,
                 rounding_mode, billing_enabled, archived, created_at, updated_at,
                 idle_cutoff_minutes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                client_id = excluded.client_id, name = excluded.name, notes = excluded.notes,
                default_rate_cents = excluded.default_rate_cents,
                rounding_minutes = excluded.rounding_minutes, rounding_mode = excluded.rounding_mode,
                billing_enabled = excluded.billing_enabled, archived = excluded.archived,
                updated_at = excluded.updated_at,
                idle_cutoff_minutes = excluded.idle_cutoff_minutes
        """, params: [
            dto.id, dto.clientId, dto.name, dto.notes, dto.defaultRateCents,
            dto.roundingMinutes, dto.roundingMode, dto.billingEnabled ? 1 : 0,
            dto.archived ? 1 : 0, dto.createdAt, dto.updatedAt, dto.idleCutoffMinutes
        ])
    }

    /// A project's entry the user never sees and that no entry they see
    /// points at: one `visibleEntry` is false for, with no visible supplement
    /// rooted on it (a hidden one goes with it). It holds no time, no figure
    /// and no words of the user's, so it neither blocks deleting its project
    /// nor survives it.
    private static let disposableEntry = """
        NOT (\(visibleEntry))
        AND NOT EXISTS (
            SELECT 1 FROM billing_entry sup
            WHERE sup.supplements_entry_id = billing_entry.id AND \(visibleEntry(alias: "sup."))
        )
    """

    /// Count of the `billing_entry` rows referencing this project, regardless
    /// of status, that the user can see — exactly the rows the Projects
    /// window lists (`visibleEntry`), so the window and the delete guard
    /// agree on whether a project has entries. `project_id` is `NOT NULL`
    /// there, so unlike a segment these rows cannot be detached and left
    /// dangling — `BillingStore.deleteProject` uses this to refuse the delete
    /// instead. With none visible, every row left is disposable.
    public func billingEntryCount(projectId: String) throws -> Int {
        var count = 0
        try query(
            "SELECT COUNT(*) FROM billing_entry WHERE project_id = ? AND \(Self.visibleEntry)",
            params: [projectId]
        ) { row in count = row[0] ?? 0 }
        return count
    }

    /// Repos are meaningless without their project, so they go. Segments keep
    /// their recorded time and fall back to unassigned. `BillingStore.deleteProject`
    /// refuses the delete whenever an entry it counts exists, so the only
    /// entries left by the time this runs are disposable ones
    /// (`disposableEntry`): they go with the project, their segments detached
    /// first — `project_id` on `billing_entry` is `NOT NULL` and has no
    /// "unassigned" to fall back to.
    public func deleteBillingProject(id: String) throws {
        try transaction {
            try execute("DELETE FROM billing_repo WHERE project_id = ?", params: [id])
            try execute("""
                UPDATE billing_segment SET entry_id = NULL WHERE entry_id IN (
                    SELECT id FROM billing_entry WHERE project_id = ? AND \(Self.disposableEntry)
                )
            """, params: [id])
            try execute(
                "DELETE FROM billing_entry WHERE project_id = ? AND \(Self.disposableEntry)", params: [id]
            )
            try execute("""
                UPDATE billing_segment SET project_id = NULL, repo_id = NULL WHERE project_id = ?
            """, params: [id])
            try execute("DELETE FROM billing_project WHERE id = ?", params: [id])
        }
    }

    // MARK: - Repos

    /// `projectId == nil` returns every repo — that is what rate resolution and
    /// the unassigned view both want.
    public func billingRepos(projectId: String?) throws -> [BillingRepoDTO] {
        var rows: [BillingRepoDTO] = []
        let sql = projectId == nil
            ? "SELECT * FROM billing_repo ORDER BY project_root, branch"
            : "SELECT * FROM billing_repo WHERE project_id = ? ORDER BY project_root, branch"
        try query(sql, params: projectId.map { [$0] } ?? []) { row in
            rows.append(Self.billingRepo(from: row))
        }
        return rows
    }

    public func billingRepo(id: String) throws -> BillingRepoDTO? {
        var found: BillingRepoDTO?
        try query("SELECT * FROM billing_repo WHERE id = ?", params: [id]) { row in
            found = Self.billingRepo(from: row)
        }
        return found
    }

    public func upsertBillingRepo(_ dto: BillingRepoDTO) throws {
        try execute("""
            INSERT INTO billing_repo
                (id, project_id, project_root, branch, rate_cents, billing_enabled, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                project_id = excluded.project_id, project_root = excluded.project_root,
                branch = excluded.branch, rate_cents = excluded.rate_cents,
                billing_enabled = excluded.billing_enabled, updated_at = excluded.updated_at
        """, params: [
            dto.id, dto.projectId, dto.projectRoot, dto.branch, dto.rateCents,
            dto.billingEnabled ? 1 : 0, dto.createdAt, dto.updatedAt
        ])
    }

    public func deleteBillingRepo(id: String) throws {
        try transaction {
            try execute("UPDATE billing_segment SET repo_id = NULL WHERE repo_id = ?", params: [id])
            try execute("DELETE FROM billing_repo WHERE id = ?", params: [id])
        }
    }

    // MARK: - Row mapping

    private static func billingClient(from row: Row) -> BillingClientDTO {
        BillingClientDTO(
            id: row["id"] ?? "", name: row["name"] ?? "",
            contactName: row["contact_name"] ?? "", email: row["email"] ?? "",
            phone: row["phone"] ?? "", url: row["url"] ?? "", notes: row["notes"] ?? "",
            currency: row["currency"] ?? "USD", archived: (row["archived"] ?? 0) != 0,
            createdAt: row["created_at"] ?? "", updatedAt: row["updated_at"] ?? ""
        )
    }

    private static func billingProject(from row: Row) -> BillingProjectDTO {
        BillingProjectDTO(
            id: row["id"] ?? "", clientId: row["client_id"], name: row["name"] ?? "",
            notes: row["notes"] ?? "", defaultRateCents: row["default_rate_cents"],
            roundingMinutes: row["rounding_minutes"] ?? 15,
            roundingMode: row["rounding_mode"] ?? "up",
            billingEnabled: (row["billing_enabled"] ?? 1) != 0,
            archived: (row["archived"] ?? 0) != 0,
            createdAt: row["created_at"] ?? "", updatedAt: row["updated_at"] ?? "",
            idleCutoffMinutes: row["idle_cutoff_minutes"]
        )
    }

    private static func billingRepo(from row: Row) -> BillingRepoDTO {
        BillingRepoDTO(
            id: row["id"] ?? "", projectId: row["project_id"] ?? "",
            projectRoot: row["project_root"] ?? "", branch: row["branch"] ?? "",
            rateCents: row["rate_cents"], billingEnabled: (row["billing_enabled"] ?? 1) != 0,
            createdAt: row["created_at"] ?? "", updatedAt: row["updated_at"] ?? ""
        )
    }

    static func billingSegment(from row: Row) -> BillingSegmentDTO {
        BillingSegmentDTO(
            id: row["id"] ?? "", sessionId: row["session_id"] ?? "",
            origin: row["origin"] ?? BillingSegmentDTO.autoOrigin, projectId: row["project_id"],
            repoId: row["repo_id"], projectRoot: row["project_root"] ?? "",
            branch: row["branch"] ?? "", startedAt: row["started_at"] ?? "",
            endedAt: row["ended_at"] ?? "", tz: row["tz"] ?? "",
            seconds: row["seconds"] ?? 0, note: row["note"] ?? "",
            entryId: row["entry_id"], flags: row["flags"] ?? "",
            createdAt: row["created_at"] ?? "", updatedAt: row["updated_at"] ?? ""
        )
    }
}

extension DaemonDatabase {

    // MARK: - Segments

    /// `since` empty means "everything". Newest first, because every caller is
    /// a list the user scrolls from the top.
    func billingSegments(since: String, limit: Int) throws -> [BillingSegmentDTO] {
        var rows: [BillingSegmentDTO] = []
        let filter = since.isEmpty ? "" : "WHERE started_at >= ?"
        let params: [any Sendable] = since.isEmpty ? [max(1, limit)] : [since, max(1, limit)]
        try query("""
            SELECT * FROM billing_segment \(filter) ORDER BY started_at DESC LIMIT ?
        """, params: params) { row in
            rows.append(Self.billingSegment(from: row))
        }
        return rows
    }

    public func billingSegment(id: String) throws -> BillingSegmentDTO? {
        var found: BillingSegmentDTO?
        try query("SELECT * FROM billing_segment WHERE id = ?", params: [id]) { row in
            found = Self.billingSegment(from: row)
        }
        return found
    }

    /// Backed by `idx_billing_segment_running`, so "is anything running?" stays
    /// a lookup no matter how many segments accumulate. `origin` nil means both
    /// kinds — the Activity window shows manual timers and derived runs in one
    /// list, because to the person reading it they are the same thing. Newest
    /// first.
    public func runningBillingSegments(origin: String? = nil) throws -> [BillingSegmentDTO] {
        var sql = "SELECT * FROM billing_segment WHERE ended_at = ''"
        var params: [any Sendable] = []
        if let origin { sql += " AND origin = ?"; params.append(origin) }
        sql += " ORDER BY started_at DESC"

        var rows: [BillingSegmentDTO] = []
        try query(sql, params: params) { row in rows.append(Self.billingSegment(from: row)) }
        return rows
    }

    /// Closes a running segment. The `ended_at = ''` guard is what makes
    /// stopping twice a no-op at the SQL level rather than a race.
    @discardableResult
    public func closeBillingSegment(id: String, endedAt: String, seconds: Int) throws -> Bool {
        var closed = false
        try transaction {
            try execute("""
                UPDATE billing_segment
                SET ended_at = ?, seconds = ?, updated_at = ?
                WHERE id = ? AND ended_at = ''
            """, params: [endedAt, seconds, UTCTimestamp.now(), id])
            try query("""
                SELECT COUNT(*) AS n FROM billing_segment WHERE id = ? AND ended_at = ?
            """, params: [id, endedAt]) { row in closed = (row["n"] ?? 0) > 0 }
        }
        return closed
    }

    /// Adds a marker to the comma-separated `flags`, once. Returns whether it
    /// was new — the caller counts only real changes, so a scheduled pass over
    /// an already-flagged timer stays silent.
    @discardableResult
    public func addBillingSegmentFlag(id: String, flag: String) throws -> Bool {
        guard let segment = try billingSegment(id: id) else { return false }
        var flags = segment.flags.split(separator: ",").map(String.init)
        guard !flags.contains(flag) else { return false }
        flags.append(flag)
        try execute("UPDATE billing_segment SET flags = ?, updated_at = ? WHERE id = ?",
                    params: [flags.joined(separator: ","), UTCTimestamp.now(), id])
        return true
    }

    public func upsertBillingSegment(_ dto: BillingSegmentDTO) throws {
        try execute("""
            INSERT INTO billing_segment
                (id, session_id, origin, project_id, repo_id, project_root, branch,
                 started_at, ended_at, tz, seconds, note, entry_id, flags, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                project_id = excluded.project_id, repo_id = excluded.repo_id,
                project_root = excluded.project_root, branch = excluded.branch,
                started_at = excluded.started_at, ended_at = excluded.ended_at,
                tz = excluded.tz, seconds = excluded.seconds, note = excluded.note,
                entry_id = excluded.entry_id, flags = excluded.flags,
                updated_at = excluded.updated_at
        """, params: [
            dto.id, dto.sessionId, dto.origin, dto.projectId, dto.repoId,
            dto.projectRoot, dto.branch, dto.startedAt, dto.endedAt, dto.tz,
            dto.seconds, dto.note, dto.entryId, dto.flags, dto.createdAt, dto.updatedAt
        ])
    }

    func deleteBillingSegment(id: String) throws {
        try execute("DELETE FROM billing_segment WHERE id = ?", params: [id])
    }

    // MARK: - Derivation

    /// Sessions whose activity has moved since billing last consumed them.
    ///
    /// The comparison is `billing_derived_at <> last_activity_at`, not a `>`
    /// on timestamps. `sessions.last_activity_at` can carry either an ISO-8601
    /// string (from a hook) or SQLite's `datetime('now')` space-separated form
    /// (from a default), and ordering those two against each other is wrong in
    /// ways that are invisible until a day goes unbilled. Equality of the exact
    /// stored value is format-agnostic and exactly the question being asked:
    /// *has anything changed since we looked?*
    ///
    /// The second clause is what closes a run nobody is watching. A session
    /// that goes quiet and is later marked `ended` never touches
    /// `last_activity_at`, so the watermark alone would leave its open segment
    /// open forever. Re-examining any session that still holds a running
    /// segment costs one extra row per live session and makes the close
    /// inevitable rather than dependent on one more event arriving.
    ///
    /// `excluding` names sessions the caller has given up on (see
    /// `BillingTask`'s failure ledger). Their watermark is already stamped, so
    /// only the open-segment clause could bring them back — and it would, every
    /// pass, forever. The exclusion applies to that clause alone: new activity
    /// moves the watermark and earns the session a fresh set of attempts.
    func sessionsNeedingBillingDerivation(
        limit: Int, excluding: Set<String> = []
    ) throws -> [BillingSessionRow] {
        var rows: [BillingSessionRow] = []
        let skipped = excluding.sorted()
        try query(
            Self.sessionsNeedingBillingDerivationSQL(excluding: skipped.count),
            params: skipped + [max(1, limit)]
        ) { row in
            // A non-git session has no project_root; its cwd is still the best
            // available identity, and tracking it unassigned beats dropping it.
            let root: String = row["project_root"] ?? ""
            rows.append(BillingSessionRow(
                sessionId: row["session_id"] ?? "",
                projectRoot: root.isEmpty ? (row["cwd"] ?? "") : root,
                branch: row["git_branch"] ?? "",
                startedAt: row["started_at"] ?? "",
                lastActivityAt: row["last_activity_at"] ?? "",
                isActive: (row["status"] ?? "") == "active"
            ))
        }
        return rows
    }

    /// Two arms joined by `UNION` rather than one `WHERE … OR …`: an `OR`
    /// across them can use no index, so every pass walked every session. The
    /// pending arm is exactly `idx_sessions_billing_pending`'s `WHERE`; the
    /// open-segment arm is one lookup per running segment. `UNION` also drops
    /// a session both arms find.
    static func sessionsNeedingBillingDerivationSQL(excluding count: Int) -> String {
        let columns = "session_id, project_root, cwd, git_branch, started_at, last_activity_at, status"
        let exclusion = count == 0
            ? ""
            : "AND session_id NOT IN (\(Array(repeating: "?", count: count).joined(separator: ", ")))"
        return """
            SELECT \(columns) FROM sessions
            WHERE billing_derived_at <> last_activity_at
            UNION
            SELECT \(columns) FROM sessions
            WHERE session_id IN (
                SELECT session_id FROM billing_segment WHERE origin = 'auto' AND ended_at = ''
                  AND session_id NOT LIKE '\(ActivitySpanSession.prefix)%'
            ) \(exclusion)
            ORDER BY last_activity_at
            LIMIT ?
        """
    }

    /// Where this session's surviving event history begins, when that is later
    /// than the session's own start — that is, when the trim has taken its
    /// early events. nil means the history is whole (or there is no event
    /// store to say otherwise).
    ///
    /// The earliest event time, found by one seek on the event store's
    /// `(provider, session_id, time)` index, to the whole second. Returned in
    /// the segments' ISO-8601 form.
    ///
    /// A session with no surviving event at all, in a store that exists, has
    /// had every event trimmed (or never had one, and then has no segments):
    /// its history starts now, so every closed segment it has is kept.
    public func billingHistoryStart(sessionId: String, sessionStartedAt: String) throws -> String? {
        guard let first = try claudeFirstEventTime(sessionId: sessionId) else {
            // A store that has held events lost this session's to the trim; one
            // that never held any (high water 0, or no store) has no history yet.
            return try (eventIdHighWater() ?? 0) > 0 ? UTCTimestamp.now() : nil
        }
        let earliest = Int(first.rounded(.down))
        guard let started = UTCTimestamp.epochSeconds(sessionStartedAt), earliest > started else { return nil }
        return UTCTimestamp.string(epochSeconds: earliest)
    }

    /// The entries holding any of these sessions' segments: what re-deriving
    /// them can change, so what the pass that derives them must recompute.
    func billingEntryIds(forSessions sessionIds: [String]) throws -> Set<String> {
        guard !sessionIds.isEmpty else { return [] }
        var ids: Set<String> = []
        try query("""
            SELECT DISTINCT entry_id FROM billing_segment
            WHERE session_id IN (\(sessionIds.map { _ in "?" }.joined(separator: ", "))) AND entry_id IS NOT NULL
        """, params: sessionIds) { row in
            if let id: String = row["entry_id"] { ids.insert(id) }
        }
        return ids
    }

    /// This session's billable activity instants, newer than `afterId`.
    ///
    /// The ambient-type exclusion is derived from `HookEventType.isActivity`, so
    /// there is exactly one definition of what counts as work — and an event
    /// type this build has never heard of is not in `allCases`, so it is not
    /// excluded, which is the spec's "unknown types count as activity".
    ///
    /// Returned as whole epoch seconds (order not guaranteed) together with the
    /// highest event-store `events.id` seen. Only rows with `id > afterId` are
    /// read, so a caller holding the previous cursor touches only the rows
    /// that are new. Reading a long session in full every pass for every live
    /// session is what once pinned the daemon's CPU. No `ORDER BY`: the caller
    /// sorts, and asking SQLite to would add a temp B-tree for nothing.
    ///
    /// `events.id` is an `AUTOINCREMENT` key and the drainer is the store's
    /// only writer, so anything committed after a read has a larger id than
    /// everything that read could see, and a trim never frees an id for reuse:
    /// a cursor never skips a row. A store replaced under the cursor (rebuilt
    /// from the raw archive, renumbered) shows as an id high-water mark
    /// (`eventIdHighWater`, never lowered by a trim) below `afterId`; the
    /// session is then read again from the start and the
    /// returned `lastId` is below `afterId`, which tells `BillingActivityCache`
    /// to replace what it holds rather than merge into it. Rows without a
    /// known time (`claudeEarliestKnownEventTime`) are never activity.
    /// Empty, cursor unmoved, without a store.
    ///
    /// **Hook-captured sessions only.** Activity is the session's hook events.
    /// A transcript yields events only for title lines and Agent dispatches
    /// (Design Ruling 7: prompts and tool calls belong to the hooks), so a
    /// session known only from its transcript (a JSONL import of a session the
    /// hooks never saw) derives no billable time; add it with a manual entry.
    public func billingActivitySeconds(
        sessionId: String, afterId: Int64 = 0
    ) throws -> (seconds: [Int], lastId: Int64) {
        guard let highWater = try eventIdHighWater() else { return ([], afterId) }
        let from = highWater < afterId ? 0 : afterId

        // Ambient rows are filtered here rather than in SQL, so the cursor
        // moves past them — otherwise a session whose recent rows are all
        // `StatusLine` renders would re-read them every pass.
        let ambient = Set(HookEventType.allCases.map(\.rawValue).filter { !HookEventType.isActivity($0) })

        var seconds: [Int] = []
        var lastId = from
        for event in try claudeEventTimes(sessionId: sessionId, afterId: from) {
            lastId = max(lastId, event.id)
            if !ambient.contains(event.providerType) {
                seconds.append(Int(event.time.rounded(.down)))
            }
        }
        return (seconds, lastId)
    }

    /// Stamps the watermark. Passing `""` forces the session to be re-derived —
    /// which is what a cutoff change does to every session at once.
    public func markBillingDerived(sessionId: String, at value: String) throws {
        try execute(
            "UPDATE sessions SET billing_derived_at = ? WHERE session_id = ?",
            params: [value, sessionId]
        )
    }

    /// Backfill: forgets the watermark of every session active on or after
    /// `since` (an ISO-8601 instant), so the next `BillingTask` passes derive
    /// them, and of every app span open or ended since then, in one
    /// transaction. Replies how many sessions plus spans were queued. Derivation is idempotent,
    /// so a backfill over sessions already derived costs time, not correctness.
    ///
    /// Both sides are normalised to SQLite's space-separated form before the
    /// `>=`. `last_activity_at` is usually `datetime('now')`'s
    /// `2026-09-22 10:00:00`, and a raw comparison against the ISO
    /// `2026-09-22T00:00:00Z` put every session of that first day *before*
    /// `since` (a space sorts before `T`) — so a backfill silently skipped the
    /// day it was asked to start on.
    @discardableResult
    func resetBillingDerivation(since: String) throws -> Int {
        let matches = """
            replace(replace(last_activity_at, 'T', ' '), 'Z', '') >= replace(replace(?, 'T', ' '), 'Z', '')
        """
        // App spans are sessions' counterpart and backfill with them: every
        // span still open, or ended on or after `since`. Skipping them left a
        // backfill re-deriving Claude time while app time stayed as it was.
        let spanMatches = """
            ended_at = '' OR replace(replace(ended_at, 'T', ' '), 'Z', '') >= replace(replace(?, 'T', ' '), 'Z', '')
        """
        var count = 0
        try transaction {
            try execute(
                "UPDATE sessions SET billing_derived_at = '' WHERE \(matches)",
                params: [since]
            )
            try query("SELECT changes() AS n") { row in count = row["n"] ?? 0 }
            try execute(
                "UPDATE activity_span SET billing_derived_at = '' WHERE \(spanMatches)",
                params: [since]
            )
            try query("SELECT changes() AS n") { row in count += row["n"] ?? 0 }
        }
        return count
    }

    /// Forgets the watermark of every session that has derived time, so the
    /// next passes re-split all of it — what an idle-cutoff change must do, or
    /// history ends up cut at two different cutoffs. App spans are their own
    /// sessions' counterpart: every span's watermark is forgotten too, so a
    /// cutoff or mapping change re-derives app time as well. Returns sessions
    /// plus spans reset.
    @discardableResult
    public func resetBillingDerivationOfDerivedSessions() throws -> Int {
        var count = 0
        try transaction {
            try execute("""
                UPDATE sessions SET billing_derived_at = ''
                WHERE billing_derived_at <> ''
                  AND session_id IN (SELECT DISTINCT session_id FROM billing_segment WHERE origin = 'auto')
            """)
            try query("SELECT changes() AS n") { row in count = row["n"] ?? 0 }
            try execute("UPDATE activity_span SET billing_derived_at = '' WHERE billing_derived_at <> ''")
            try query("SELECT changes() AS n") { row in count += row["n"] ?? 0 }
        }
        return count
    }

    /// Forgets the watermark of every derived session and app span whose
    /// time `projectId` may claim — the ones that read its idle cutoff: those
    /// in a repo one of its repo rows names (any branch: a superset is only
    /// extra work), and those holding a derived segment of it. Spans and
    /// sessions of other projects keep their watermarks, so a per-project
    /// cutoff change re-derives that project alone. Returns sessions plus
    /// spans reset.
    @discardableResult
    public func resetBillingDerivation(projectId: String) throws -> Int {
        let prefix = ActivitySpanSession.prefix
        var count = 0
        try transaction {
            try execute("""
                UPDATE sessions SET billing_derived_at = ''
                WHERE billing_derived_at <> '' AND (
                    COALESCE(NULLIF(project_root, ''), cwd)
                        IN (SELECT project_root FROM billing_repo WHERE project_id = ?)
                    OR session_id IN (
                        SELECT session_id FROM billing_segment WHERE origin = 'auto' AND project_id = ?
                    )
                )
            """, params: [projectId, projectId])
            try query("SELECT changes() AS n") { row in count = row["n"] ?? 0 }
            try execute("""
                UPDATE activity_span SET billing_derived_at = ''
                WHERE billing_derived_at <> '' AND (
                    repo_root IN (SELECT project_root FROM billing_repo WHERE project_id = ?)
                    OR id IN (
                        SELECT substr(session_id, \(prefix.count + 1)) FROM billing_segment
                        WHERE origin = 'auto' AND project_id = ? AND session_id LIKE '\(prefix)%'
                    )
                )
            """, params: [projectId, projectId])
            try query("SELECT changes() AS n") { row in count += row["n"] ?? 0 }
        }
        return count
    }

    // MARK: - App-span derivation

    /// The pending-span query. One string, used by the production read and by
    /// the `EXPLAIN QUERY PLAN` test that pins it to `idx_activity_span_pending`.
    static let pendingAppSpansSQL = """
        SELECT id, bundle_id, app_name, window_title, working_path, repo_root, branch,
               started_at, ended_at, tz
        FROM activity_span
        WHERE billing_derived_at <> ended_at OR ended_at = ''
        ORDER BY started_at
        LIMIT ?
    """

    /// Spans a billing pass has not consumed: every open span (re-derived each
    /// pass while it grows) and every closed span whose watermark is not its
    /// end (an open idle keeps a closed span pending by stamping ""). The
    /// `WHERE` is written exactly as `idx_activity_span_pending`'s — SQLite
    /// matches a partial index's clause structurally, so a reordered `OR`
    /// would scan the whole table. Oldest first.
    public func billingAppSpansNeedingDerivation(limit: Int) throws -> [BillingAppSpanRow] {
        var rows: [BillingAppSpanRow] = []
        try query(Self.pendingAppSpansSQL, params: [max(1, limit)]) { row in
            rows.append(BillingAppSpanRow(
                id: row["id"] ?? "", bundleId: row["bundle_id"] ?? "", appName: row["app_name"] ?? "",
                windowTitle: row["window_title"] ?? "", workingPath: row["working_path"] ?? "",
                repoRoot: row["repo_root"] ?? "", branch: row["branch"] ?? "",
                startedAt: row["started_at"] ?? "", endedAt: row["ended_at"] ?? "", tz: row["tz"] ?? ""
            ))
        }
        return rows
    }

    /// The longest closed idle row, in seconds (0 with none), read off the
    /// end of `idx_activity_presence_length`.
    static let longestIdleSQL = """
        SELECT \(idleLengthSQL) AS n FROM activity_presence
        WHERE idle_until <> '' ORDER BY \(idleLengthSQL) DESC LIMIT 1
    """

    /// The idle-row query: open rows (any start before `end`) through
    /// `idx_activity_presence_open`, then closed rows ending after `start`
    /// whose start lies in `[start - longest, end)` — a range bounded on both
    /// sides, so `idx_activity_presence_from` reads only rows near the span
    /// instead of every older one. Parameters: end, start, earliest, end.
    static let idleIntervalsSQL = """
        SELECT idle_from, idle_until FROM activity_presence
        WHERE idle_until = '' AND idle_from < ?
        UNION ALL
        SELECT idle_from, idle_until FROM activity_presence
        WHERE idle_until <> '' AND idle_until > ? AND idle_from >= ? AND idle_from < ?
        ORDER BY idle_from
    """

    /// Idle intervals overlapping `[start, end]`: still open, or ending after
    /// `start`; and starting before `end` unless `end` is "" (an open span).
    public func billingIdleIntervals(from start: String, to end: String) throws -> [BillingIdleInterval] {
        var longest = 0
        try query(Self.longestIdleSQL) { row in longest = max(0, row["n"] ?? 0) }
        // A start that does not parse cannot be bounded: every row before it.
        let earliest = UTCTimestamp.epochSeconds(start).map { UTCTimestamp.string(epochSeconds: $0 - longest) } ?? ""
        // "" sorts before every stamp; an open-ended span takes every start.
        let upper = end.isEmpty ? "\u{10FFFF}" : end
        var intervals: [BillingIdleInterval] = []
        try query(Self.idleIntervalsSQL, params: [upper, start, earliest, upper]) { row in
            intervals.append(BillingIdleInterval(idleFrom: row["idle_from"] ?? "", idleUntil: row["idle_until"] ?? ""))
        }
        return intervals
    }

    /// Stamps the span's watermark with its `ended_at` as read at selection,
    /// so a span closed during the pass is picked up by the next one.
    public func markAppSpanBillingDerived(spanId: String, at value: String) throws {
        try execute("UPDATE activity_span SET billing_derived_at = ? WHERE id = ?", params: [value, spanId])
    }

    /// Replaces this session's derived segments with `runs`, in one transaction.
    ///
    /// Two rules, and both matter. **Segments on a locked entry are
    /// untouchable** — once time has been billed or paid it is history, and no
    /// amount of re-derivation may edit or delete it. A run is identified by
    /// its start instant, but a cutoff change can move that instant: raising
    /// the cutoff can merge a locked run with a later unlocked one under the
    /// locked run's own start, and lowering it can split a locked run into
    /// pieces that no longer start where the lock is recorded. Matching on
    /// `startedAt` alone would either drop the later run's time (the merge
    /// case) or double-bill the split-off piece (the split case). Instead,
    /// every derived run has every protected `[started_at, ended_at)`
    /// interval that overlaps it *subtracted* from it, and each non-empty
    /// remainder becomes its own auto segment — so a locked interval is never
    /// re-covered, and time outside it is never lost. **Everything else is
    /// replaced, not merged**, because the derivation is authoritative:
    /// merging would preserve segments from a cutoff setting the user has
    /// since changed.
    ///
    /// A protected segment can itself be zero-length (`started_at ==
    /// ended_at`, e.g. a single-event run that got locked): subtracting
    /// `[t, t)` removes nothing, so a remainder can still start at exactly
    /// `t` and collide with the protected row on `idx_billing_segment_auto_
    /// identity` (`UNIQUE(session_id, started_at) WHERE origin = 'auto'`).
    /// Any remainder whose start coincides with a protected segment's start —
    /// zero-length or not — is nudged one second later before it is written,
    /// which can lose at most one second of billed time; the piece is
    /// dropped only if that second consumes it entirely. Protected rows
    /// themselves are never touched by this.
    ///
    /// "Locked" here means *frozen against the rollup*: an entry that is
    /// billed or paid, **or** one whose figures the user wrote by hand
    /// (`origin = 'user'`). Both are history the derivation may not rewrite;
    /// later work on the same day reaches them only as a supplement.
    ///
    /// Every other segment is rewritten, but not anonymously. A piece that
    /// starts where an old row started **keeps that row's id** (and its
    /// `created_at`): `(session_id, started_at)` is a derived run's identity,
    /// and a fresh UUID every pass made the run look new each time — at run
    /// granularity that minted a new billable per pass.
    ///
    /// A closed piece also **keeps its heir's unbilled entry** when the time
    /// is still that entry's: same project and repo, same local day, and —
    /// for an entry that is one run rather than a day — the same start. The
    /// entry is then recomputed from what the segment now says, at the rate,
    /// rounding and currency it snapshotted. Dropping `entry_id` instead sent
    /// the time back through the rollup at the *live* rate, so re-deriving
    /// history after a rate change repriced every unbilled day it touched.
    /// Any other piece is left unattached for the rollup to place.
    ///
    /// Two more things survive a rewrite, both matched by the same start or,
    /// failing that, by overlap with an old row:
    ///
    /// - **`tz`** — the zone the work happened in is a fact about the work.
    ///   Re-stamping it with the host's current zone moved a Lisbon morning
    ///   onto a New York day after the laptop flew.
    /// - **a hand assignment** (`flags` contains `assigned`, set by
    ///   `assignSegments`) — its `project_id` and `repo_id` win over the
    ///   context's. Without this, "Assign to Project" reverted on the next
    ///   pass.
    /// - **`untracked`** — time first derived while its project or repo had
    ///   Track Time off (`context.tracked == false`) is flagged, and the flag
    ///   rides on the heir like `tz`, so turning tracking back on does not
    ///   bill the off-period. Time already rolled into an entry is never
    ///   flagged, and a hand assignment clears it.
    ///
    /// **Retention.** `runs` come from `events.db`, which the trim cuts to
    /// the history window. `historyStartsAt` (see `billingHistoryStart`) is where the
    /// surviving history begins when it has been trimmed: a closed segment
    /// that starts before it can no longer be re-derived, so it is kept as it
    /// is — not deleted, and treated like a protected interval, so the runs
    /// derived from what is left never re-cover it.
    ///
    /// Only rows that change are written. A row the derivation would leave
    /// exactly as it is keeps its `entry_id`, so a run closing late in a
    /// session no longer rewrites (and detaches) every earlier run.
    ///
    /// An `app:<span id>` session whose span no longer exists writes nothing.
    @discardableResult
    public func replaceDerivedSegments(
        sessionId: String,
        runs: [BillingRun],
        context: BillingSegmentContext,
        historyStartsAt: String? = nil
    ) throws -> Int {
        var written = 0
        try transaction {
            // An app span read before this write can be gone by now: the
            // recorder deletes one closed under a second, with its segments.
            // Writing for it would leave an open app: segment nothing ever
            // closes (re-review N7). Checked here, on the write lane, so the
            // delete cannot land between the check and the write.
            if let spanId = ActivitySpanSession.spanId(sessionId: sessionId) {
                var exists = false
                try query("SELECT 1 FROM activity_span WHERE id = ?", params: [spanId]) { _ in exists = true }
                guard exists else { return }
            }

            var protected: [(start: String, end: String)] = []
            try query("""
                SELECT started_at, ended_at FROM billing_segment
                WHERE session_id = ? AND origin = 'auto'
                  AND entry_id IN (\(Self.frozenEntryIds))
            """, params: [sessionId]) { row in
                protected.append((start: row["started_at"] ?? "", end: row["ended_at"] ?? ""))
            }

            var previous: [BillingSegmentDTO] = []
            var owners: [String: (day: String, groupKey: String)] = [:]
            try query("""
                SELECT s.*, e.day AS owner_day, e.group_key AS owner_group
                FROM billing_segment s LEFT JOIN billing_entry e ON e.id = s.entry_id
                WHERE s.session_id = ? AND s.origin = 'auto'
                  AND (s.entry_id IS NULL OR s.entry_id NOT IN (\(Self.frozenEntryIds)))
                ORDER BY s.started_at
            """, params: [sessionId]) { row in
                let segment = Self.billingSegment(from: row)
                previous.append(segment)
                if let entryId = segment.entryId, let day: String = row["owner_day"] {
                    owners[entryId] = (day: day, groupKey: row["owner_group"] ?? "")
                }
            }

            // Closed time from before the surviving history: kept, and
            // protected from being re-covered by what is left.
            if let historyStartsAt {
                let retained = previous.filter { !$0.endedAt.isEmpty && $0.startedAt < historyStartsAt }
                protected += retained.map { (start: $0.startedAt, end: $0.endedAt) }
                let retainedIds = Set(retained.map(\.id))
                previous.removeAll { retainedIds.contains($0.id) }
            }

            let now = UTCTimestamp.now()
            var planned: [BillingSegmentDTO] = []
            for run in runs {
                for piece in Self.subtractingProtected(protected, from: run) {
                    let sameStart = previous.first { $0.startedAt == piece.startedAt }
                    let overlapping = previous.first { Self.overlaps($0, piece) }
                    let heir = sameStart ?? overlapping
                    let assigned = [sameStart, overlapping].compactMap { $0 }.first {
                        Self.hasFlag($0.flags, Self.assignedFlag)
                    }
                    let projectId = assigned != nil ? assigned?.projectId : context.projectId
                    let repoId = assigned != nil ? assigned?.repoId : context.repoId
                    let zone = heir.map(\.tz).flatMap { $0.isEmpty ? nil : $0 } ?? context.tz
                    let entryId = heir.flatMap { heir -> String? in
                        guard !piece.isOpen, let entryId = heir.entryId, let owner = owners[entryId],
                              heir.projectId == projectId, heir.repoId == repoId,
                              BillingClock.localDay(utc: piece.startedAt, tz: zone) == owner.day else { return nil }
                        let dayKeyed = owner.groupKey.isEmpty || owner.groupKey.hasPrefix("rate:")
                        return dayKeyed || heir.id == sameStart?.id ? entryId : nil
                    }
                    let untracked = assigned == nil && entryId == nil
                        && (heir.map { Self.hasFlag($0.flags, Self.untrackedFlag) } ?? false
                            || (!context.tracked && heir?.entryId == nil))
                    let flags = assigned != nil ? Self.assignedFlag : (untracked ? Self.untrackedFlag : "")
                    planned.append(BillingSegmentDTO(
                        id: sameStart?.id ?? UUID().uuidString,
                        sessionId: sessionId,
                        origin: BillingSegmentDTO.autoOrigin,
                        projectId: projectId,
                        repoId: repoId,
                        projectRoot: context.projectRoot,
                        branch: context.branch,
                        startedAt: piece.startedAt,
                        endedAt: piece.endedAt,
                        tz: zone,
                        seconds: piece.seconds,
                        entryId: entryId,
                        flags: flags,
                        createdAt: sameStart?.createdAt ?? now,
                        updatedAt: now
                    ))
                }
            }

            // Most passes change nothing: a live session's closed runs are
            // settled, and its open run is still open. Only the rows that
            // differ are touched — stale ones deleted first, so a moved start
            // never meets the old row on the identity index — and a row the
            // derivation leaves as it is keeps its `entry_id` rather than
            // being detached for the rollup to re-link.
            let plannedIds = Set(planned.map(\.id))
            for stale in previous where !plannedIds.contains(stale.id) {
                try deleteBillingSegment(id: stale.id)
            }
            let before = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for segment in planned {
                if let old = before[segment.id], Self.sameSegment(segment, old) { continue }
                try upsertBillingSegment(segment)
                written += 1
            }
        }
        return written
    }

    /// Whether writing `planned` over `previous` would change a field the
    /// derivation decides. `entry_id`, `note` and the timestamps are not the
    /// derivation's to decide, so they don't count.
    private static func sameSegment(_ planned: BillingSegmentDTO, _ previous: BillingSegmentDTO) -> Bool {
        let key = { (segment: BillingSegmentDTO) in
            [segment.id, segment.projectId ?? "\u{0}", segment.repoId ?? "\u{0}", segment.projectRoot,
             segment.branch, segment.startedAt, segment.endedAt, segment.tz, String(segment.seconds), segment.flags]
        }
        return key(planned) == key(previous)
    }

    /// Entries the derivation and the rollup must not change: billed or paid,
    /// or hand-edited figures. Used as a subquery.
    private static let frozenEntryIds =
        "SELECT id FROM billing_entry WHERE locked = 1 OR origin = 'user'"

    /// Marks a segment whose project the user chose by hand.
    static let assignedFlag = "assigned"

    /// Marks a segment first derived while its project or repo had Track
    /// Time off. The rollup never takes one.
    static let untrackedFlag = "untracked"

    private static func hasFlag(_ flags: String, _ flag: String) -> Bool {
        flags.split(separator: ",").contains { $0 == flag }
    }

    /// Whether an old segment and a new piece share any time. Open ends are
    /// unbounded; an instant-long segment overlaps a piece that contains it.
    private static func overlaps(_ old: BillingSegmentDTO, _ piece: BillingRun) -> Bool {
        let oldEnd = old.endedAt.isEmpty ? farFutureSentinel : old.endedAt
        let pieceEnd = piece.isOpen ? farFutureSentinel : piece.endedAt
        return old.startedAt <= pieceEnd && piece.startedAt <= oldEnd
    }

    /// A sentinel that sorts after every real ISO-8601 UTC timestamp this
    /// codebase produces, standing in for an open run's unbounded end while
    /// intervals are clipped and compared as plain strings (safe because they
    /// are all the same fixed-width format, so lexical order is chronological
    /// order).
    private static let farFutureSentinel = "9999-12-31T23:59:59Z"

    /// `run` minus every interval in `protected` that overlaps it, as the
    /// pieces still open to being (re)written. A run entirely inside a
    /// protected interval yields no pieces at all — not an empty one — so
    /// nothing is ever inserted for time that is already locked.
    ///
    /// A gap between two protected intervals never gets closed early: the only
    /// way a remainder piece's end differs from `run`'s own end is that a
    /// protected interval started there. The final piece keeps `run`'s open
    /// end (`endedAt == ""`) only when nothing protected reaches all the way
    /// to it.
    ///
    /// The result is passed through `avoidingProtectedStarts` before it is
    /// returned — a zero-length protected interval clips nothing, so a piece
    /// can still start exactly on one, and that must not reach the caller.
    private static func subtractingProtected(
        _ protected: [(start: String, end: String)],
        from run: BillingRun
    ) -> [BillingRun] {
        let runEnd = run.isOpen ? farFutureSentinel : run.endedAt
        let protectedStarts = Set(protected.map(\.start))

        // Clip each candidate to the run's own bounds; anything left with a
        // non-positive width didn't actually overlap this run. A zero-length
        // protected interval (`start == end`) never survives this — `start <
        // end` is false — which is exactly why its start still needs guarding
        // against below.
        let clipped: [(start: String, end: String)] = protected.compactMap { interval in
            let intervalEnd = interval.end.isEmpty ? farFutureSentinel : interval.end
            let start = max(interval.start, run.startedAt)
            let end = min(intervalEnd, runEnd)
            return start < end ? (start, end) : nil
        }
        guard !clipped.isEmpty else {
            return avoidingProtectedStarts([run], protectedStarts: protectedStarts)
        }

        // Merge so overlapping or touching protected pieces are walked once —
        // defensive, since locked segments aren't expected to overlap each
        // other, but a walk that assumed it would silently miscount if they do.
        let merged = ActivityRuns.union(clipped.map { ActivityRuns.Span(start: $0.start, end: $0.end) })

        var pieces: [BillingRun] = []
        var cursor = run.startedAt
        for interval in merged {
            if cursor < interval.start {
                pieces.append(piece(from: cursor, to: interval.start, runEnd: runEnd, run: run))
            }
            cursor = max(cursor, interval.end)
        }
        if cursor < runEnd {
            pieces.append(piece(from: cursor, to: runEnd, runEnd: runEnd, run: run))
        }
        return avoidingProtectedStarts(pieces, protectedStarts: protectedStarts)
    }

    /// Nudges any piece whose start coincides with a protected segment's
    /// start one second later, and drops it if that second consumes it
    /// entirely. An open piece (`endedAt == ""`) is never empty — it has no
    /// fixed end for the nudge to reach — so only a closed piece can vanish
    /// this way, and only when it was already exactly one second long.
    private static func avoidingProtectedStarts(
        _ pieces: [BillingRun], protectedStarts: Set<String>
    ) -> [BillingRun] {
        pieces.compactMap { piece in
            guard protectedStarts.contains(piece.startedAt),
                  let nudged = UTCTimestamp.adding(1, to: piece.startedAt) else { return piece }
            if piece.isOpen {
                return BillingRun(startedAt: nudged, endedAt: "", seconds: 0)
            }
            guard nudged < piece.endedAt else { return nil }
            return BillingRun(
                startedAt: nudged, endedAt: piece.endedAt,
                seconds: UTCTimestamp.seconds(from: nudged, to: piece.endedAt)
            )
        }
    }

    /// One remainder piece. Only the piece that reaches `run`'s own end can
    /// inherit its open-endedness; every other piece was closed by a protected
    /// interval starting right after it, so it gets a real `endedAt`.
    private static func piece(from start: String, to end: String, runEnd: String, run: BillingRun) -> BillingRun {
        guard run.isOpen, end == runEnd else {
            return BillingRun(startedAt: start, endedAt: end, seconds: UTCTimestamp.seconds(from: start, to: end))
        }
        return BillingRun(startedAt: start, endedAt: "", seconds: 0)
    }
}

extension DaemonDatabase {

    // MARK: - Entries

    /// `projectId` / `status` nil mean "any"; `since` empty means "all time".
    /// Newest day first — every caller is a list read from the top.
    public func billingEntries(projectId: String?, status: String?, since: String) throws -> [BillingEntryDTO] {
        var clauses: [String] = []
        var params: [any Sendable] = []
        if let projectId { clauses.append("project_id = ?"); params.append(projectId) }
        if let status { clauses.append("status = ?"); params.append(status) }
        if !since.isEmpty { clauses.append("day >= ?"); params.append(since) }
        clauses.append(Self.visibleEntry)
        let filter = "WHERE " + clauses.joined(separator: " AND ")

        var rows: [BillingEntryDTO] = []
        try query("""
            SELECT * FROM billing_entry \(filter) ORDER BY day DESC, created_at DESC
        """, params: params) { row in
            rows.append(Self.billingEntry(from: row))
        }
        return rows
    }

    public func billingEntry(id: String) throws -> BillingEntryDTO? {
        var found: BillingEntryDTO?
        try query("SELECT * FROM billing_entry WHERE id = ?", params: [id]) { row in
            found = Self.billingEntry(from: row)
        }
        return found
    }

    /// Returns whether a row was written — false only when `overwrite` refused
    /// an existing row.
    @discardableResult
    public func upsertBillingEntry(_ dto: BillingEntryDTO, overwrite: BillingEntryOverwrite = .any) throws -> Bool {
        var written = false
        // One transaction so `changes()` is read on the connection that wrote.
        try transaction {
            try execute(Self.upsertBillingEntrySQL + overwrite.condition, params: [
                dto.id, dto.projectId, dto.clientId, dto.day, dto.groupKey,
                dto.startedAt, dto.endedAt, dto.rawSeconds, dto.billedSeconds,
                dto.rateCents, dto.currency, dto.amountCents, dto.roundingMinutes,
                dto.roundingMode, dto.status, dto.description, dto.origin,
                dto.locked ? 1 : 0, dto.supplementsEntryId, dto.createdAt, dto.updatedAt
            ])
            try query("SELECT changes() AS n") { row in written = (row["n"] ?? 0) > 0 }
        }
        return written
    }

    private static let upsertBillingEntrySQL = """
            INSERT INTO billing_entry
                (id, project_id, client_id, day, group_key, started_at, ended_at,
                 raw_seconds, billed_seconds, rate_cents, currency, amount_cents,
                 rounding_minutes, rounding_mode, status, description, origin,
                 locked, supplements_entry_id, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                project_id = excluded.project_id, client_id = excluded.client_id,
                day = excluded.day, group_key = excluded.group_key,
                started_at = excluded.started_at, ended_at = excluded.ended_at,
                raw_seconds = excluded.raw_seconds, billed_seconds = excluded.billed_seconds,
                rate_cents = excluded.rate_cents, currency = excluded.currency,
                amount_cents = excluded.amount_cents,
                rounding_minutes = excluded.rounding_minutes,
                rounding_mode = excluded.rounding_mode, status = excluded.status,
                description = excluded.description, origin = excluded.origin,
                locked = excluded.locked,
                supplements_entry_id = excluded.supplements_entry_id,
                updated_at = excluded.updated_at

        """

    /// The segments are released, not deleted: an entry is a grouping of time,
    /// and deleting the grouping must never delete the time.
    public func deleteBillingEntry(id: String) throws {
        try transaction {
            // Release segments belonging to the entry itself AND to any
            // supplement of it — a supplement is deleted below too, and a
            // segment left pointing at a row that no longer exists is
            // invisible to billingRollupCandidates (which requires
            // entry_id IS NULL), so its time would silently vanish instead
            // of being re-rolled.
            try execute("""
                UPDATE billing_segment SET entry_id = NULL
                WHERE entry_id IN (
                    SELECT id FROM billing_entry WHERE id = ? OR supplements_entry_id = ?
                )
            """, params: [id, id])
            try execute("DELETE FROM billing_entry WHERE supplements_entry_id = ?", params: [id])
            try execute("DELETE FROM billing_entry WHERE id = ?", params: [id])
        }
    }

    /// How many of this entry's supplements are billed, paid or hand edited —
    /// history that deleting the entry would take with it.
    public func billingFrozenSupplementCount(of entryId: String) throws -> Int {
        var count = 0
        try query("""
            SELECT COUNT(*) AS n FROM billing_entry
            WHERE supplements_entry_id = ? AND (locked = 1 OR origin = 'user')
        """, params: [entryId]) { row in count = row["n"] ?? 0 }
        return count
    }

    /// The entry that already owns a (project, day, group) slot, if any.
    public func billingEntryForSlot(projectId: String, day: String, groupKey: String) throws -> StoredBillingEntry? {
        var found: StoredBillingEntry?
        try query("""
            SELECT * FROM billing_entry
            WHERE project_id = ? AND day = ? AND group_key = ? AND supplements_entry_id IS NULL
        """, params: [projectId, day, groupKey]) { row in
            found = StoredBillingEntry(row: row)
        }
        return found
    }

    /// The open supplement for a frozen entry, if one is already collecting.
    public func billingOpenSupplement(of entryId: String) throws -> StoredBillingEntry? {
        var found: StoredBillingEntry?
        try query("""
            SELECT * FROM billing_entry
            WHERE supplements_entry_id = ? AND locked = 0 AND origin = 'auto'
            ORDER BY created_at LIMIT 1
        """, params: [entryId]) { row in
            found = StoredBillingEntry(row: row)
        }
        return found
    }

    public func billingEntriesOnDay(projectId: String, day: String) throws -> [StoredBillingEntry] {
        var rows: [StoredBillingEntry] = []
        try query("""
            SELECT * FROM billing_entry WHERE project_id = ? AND day = ? ORDER BY created_at, id
        """, params: [projectId, day]) { row in
            rows.append(StoredBillingEntry(row: row))
        }
        return rows
    }

    /// Every entry of the project whose time may fall in `[from, until)`: one
    /// whose shown times overlap it, one whose shown times a move blanked but
    /// whose recorded ranges overlap it, a frozen one whose recorded ranges
    /// overlap it wherever its shown times now lie (moved, then a Start or End
    /// typed on the new day — re-review F5), one holding a segment that does,
    /// and those entries' supplements. Ordered as `billingEntriesOnDay` is,
    /// day first.
    ///
    /// No fixed lookback: a segment or entry may run for days (a runaway
    /// timer is flagged, never truncated), so the earliest start that can
    /// still reach `from` is `from` minus the project's longest segment or
    /// entry, each read off the end of its length index. Both start ranges
    /// stay bounded on both sides.
    ///
    /// A UNION of indexed selects, not one `OR`: SQLite cannot serve an
    /// `OR` whose arms are `IN` subqueries from an index, and fell back to
    /// reading every entry of the project on every settle. Each arm here has
    /// its own — `idx_billing_entry_project_started` (a range for timed
    /// entries, an equality on `''` for untimed ones),
    /// `idx_billing_entry_project_billed_start` (frozen entries whose ranges
    /// start in the window or up to the longest frozen span before it), the
    /// primary key and
    /// `idx_billing_entry_supplements` — and `holding` reads one project's
    /// segments through `idx_billing_segment_project_started`. `CROSS JOIN`
    /// keeps the small `holding` set outside (SQLite never reorders one), and
    /// the `IS NOT NULL` lets the partial supplements index serve; the unary
    /// `+` stops the planner seeking those arms by project instead, which it
    /// does on an un-ANALYZEd database. The untimed arm names its index
    /// (`INDEXED BY`): left to itself, the planner on some machines served
    /// it from `idx_billing_entry_project_day_all (project_id=?)`, a read of
    /// every entry of the project. Parameters: project, segment
    /// lookback, until, from (segments); project, entry lookback, until, from
    /// (entries); project, until epoch, from epoch (untimed); project, from
    /// epoch, until epoch, until epoch, from epoch (frozen; the first bound
    /// is the frozen lookback); project twice more.
    static let billingEntriesOverlappingSQL = """
        WITH holding AS (
            SELECT DISTINCT s.entry_id AS id FROM billing_segment s
            WHERE s.project_id = ? AND s.started_at >= ? AND s.started_at < ?
              AND s.ended_at > ? AND s.entry_id IS NOT NULL
        )
        SELECT e.* FROM billing_entry e
        WHERE e.project_id = ? AND e.started_at >= ? AND e.started_at < ?
          AND e.started_at <> '' AND e.ended_at > ?
        UNION
        SELECT e.* FROM billing_entry e INDEXED BY idx_billing_entry_project_started
        WHERE e.project_id = ? AND e.started_at = ''
          AND EXISTS (
            SELECT 1 FROM json_each(\(billedRangesJSON("e.billed_ranges"))) r
            WHERE json_extract(r.value, '$[0]') < ? AND json_extract(r.value, '$[1]') > ?
          )
        UNION
        SELECT * FROM billing_entry
        WHERE project_id = ? AND \(frozenWithRangesSQL) AND \(billedStartSQL) >= ? AND \(billedStartSQL) < ?
          AND EXISTS (
            SELECT 1 FROM json_each(\(billedRangesJSON("billed_ranges"))) r
            WHERE json_extract(r.value, '$[0]') < ? AND json_extract(r.value, '$[1]') > ?
          )
        UNION
        SELECT e.* FROM holding h CROSS JOIN billing_entry e ON e.id = h.id
        WHERE +e.project_id = ?
        UNION
        SELECT e.* FROM holding h CROSS JOIN billing_entry e ON e.supplements_entry_id = h.id
        WHERE e.supplements_entry_id IS NOT NULL AND +e.project_id = ?
        ORDER BY day, created_at, id
    """

    /// The longest row of `table` for one project, in seconds (0 with none).
    static func longestSQL(_ table: String) -> String {
        """
        SELECT \(lengthSQL) AS n FROM \(table)
        WHERE project_id = ? ORDER BY \(lengthSQL) DESC LIMIT 1
        """
    }

    /// The longest frozen entry's recorded span for one project, in seconds
    /// (0 with none), read off `idx_billing_entry_project_billed_span`.
    static let longestFrozenSpanSQL = """
        SELECT \(billedSpanSQL) AS n FROM billing_entry
        WHERE project_id = ? AND \(frozenWithRangesSQL) ORDER BY \(billedSpanSQL) DESC LIMIT 1
        """

    public func billingEntriesOverlapping(
        projectId: String, from: String, until: String
    ) throws -> [StoredBillingEntry] {
        guard let start = UTCTimestamp.epochSeconds(from), let end = UTCTimestamp.epochSeconds(until) else {
            return []
        }
        func longest(_ table: String) throws -> Int {
            var seconds = 0
            try query(Self.longestSQL(table), params: [projectId]) { row in seconds = max(0, row["n"] ?? 0) }
            return seconds
        }
        let segmentsFrom = UTCTimestamp.string(epochSeconds: start - (try longest("billing_segment")))
        let entriesFrom = UTCTimestamp.string(epochSeconds: start - (try longest("billing_entry")))
        var frozenSpan = 0
        try query(Self.longestFrozenSpanSQL, params: [projectId]) { row in frozenSpan = max(0, row["n"] ?? 0) }
        var rows: [StoredBillingEntry] = []
        try query(Self.billingEntriesOverlappingSQL, params: [
            projectId, segmentsFrom, until, from,
            projectId, entriesFrom, until, from,
            projectId, end, start,
            projectId, start - frozenSpan, end, end, start,
            projectId, projectId
        ]) { row in
            rows.append(StoredBillingEntry(row: row))
        }
        return rows
    }

    public func billingEntryDays() throws -> [BillingProjectDay] {
        var days: [BillingProjectDay] = []
        try query("SELECT DISTINCT project_id, day FROM billing_entry ORDER BY day, project_id") { row in
            days.append(BillingProjectDay(projectId: row["project_id"] ?? "", day: row["day"] ?? ""))
        }
        return days
    }

    /// The project days a settle could still change — see
    /// `BillingPersistence.billingUnsettledDays`. A frozen entry owns exactly
    /// its recorded ranges (its segments' intervals when it recorded none),
    /// so it orphans time only through a placeable segment of positive
    /// length that no one of its ranges covers; ranges are stored
    /// normalized, so one range covers a segment or none does.
    static let billingUnsettledDaysSQL = """
        SELECT project_id, day FROM billing_entry
        WHERE locked = 0 AND origin <> 'user'
        UNION
        SELECT e.project_id, e.day FROM billing_entry e
        JOIN billing_segment s ON s.entry_id = e.id
        WHERE (e.locked = 1 OR e.origin = 'user') AND e.billed_ranges IS NOT NULL
          AND s.seconds > 0 AND strftime('%s', s.started_at) IS NOT NULL
          AND NOT EXISTS (
            SELECT 1 FROM json_each(\(billedRangesJSON("e.billed_ranges"))) r
            WHERE json_extract(r.value, '$[0]') <= CAST(strftime('%s', s.started_at) AS INTEGER)
              AND json_extract(r.value, '$[1]') >= CAST(strftime('%s', s.started_at) AS INTEGER) + s.seconds
          )
        ORDER BY day, project_id
    """

    public func billingUnsettledDays() throws -> [BillingProjectDay] {
        var days: [BillingProjectDay] = []
        try query(Self.billingUnsettledDaysSQL) { row in
            days.append(BillingProjectDay(projectId: row["project_id"] ?? "", day: row["day"] ?? ""))
        }
        return days
    }

    public func setBillingEntryBilledRanges(id: String, ranges: String) throws {
        try execute(
            "UPDATE billing_entry SET billed_ranges = ? WHERE id = ? AND billed_ranges IS NOT ?",
            params: [ranges, id, ranges]
        )
    }

    /// Deletes an entry only if it is still unlocked, auto, holds no segment
    /// and no supplement points at it — re-checked in SQL so a segment
    /// attached in between is never stranded, and a supplement (billed ones
    /// especially) never points at a row that is gone. An entry whose
    /// description was written by hand is never removed this way: the words
    /// are the user's. Returns whether a row went.
    @discardableResult
    public func deleteEmptyBillingEntry(id: String) throws -> Bool {
        var deleted = false
        try transaction {
            try execute("""
                DELETE FROM billing_entry
                WHERE id = ? AND locked = 0 AND origin = 'auto' AND description_edited = 0
                  AND NOT EXISTS (SELECT 1 FROM billing_segment WHERE entry_id = ?)
                  AND NOT EXISTS (SELECT 1 FROM billing_entry WHERE supplements_entry_id = ?)
            """, params: [id, id, id])
            try query("SELECT COUNT(*) AS n FROM billing_entry WHERE id = ?", params: [id]) { row in
                deleted = (row["n"] ?? 1) == 0
            }
        }
        return deleted
    }

    public func markBillingEntryDescriptionEdited(id: String) throws {
        try execute("UPDATE billing_entry SET description_edited = 1 WHERE id = ?", params: [id])
    }

    /// Writes the description alone — no figure column is touched — and
    /// marks it hand-written. `locked = 0` is re-checked in SQL so an entry
    /// billed in between is left alone. Returns whether the row was written.
    @discardableResult
    public func setBillingEntryDescription(id: String, description: String, at now: String) throws -> Bool {
        var written = false
        try transaction {
            try execute("""
                UPDATE billing_entry SET description = ?, description_edited = 1, updated_at = ?
                WHERE id = ? AND locked = 0
            """, params: [description, now, id])
            try query("SELECT changes() AS n") { row in written = (row["n"] ?? 0) > 0 }
        }
        return written
    }

    // MARK: - Rollup inputs

    /// Closed, assigned, billable segments not yet attached to an entry.
    ///
    /// `billing_enabled = 0` at project or repo level removes the segment here
    /// rather than later: the time stays recorded, no entry is ever written for
    /// it, and that is deliberately different from a zero rate — a zero rate
    /// produces a $0 row you can see. The live flags only say whether the
    /// project bills *now*; time derived while it did not carries the
    /// `untracked` flag and is left out for good, so turning Track Time back
    /// on does not bill the time it was off.
    ///
    /// The query starts from the billing projects (`CROSS JOIN` fixes that
    /// order) and reads each one's segments by `project_id`. Started from the
    /// segments, SQLite walked every unrolled row through
    /// `idx_billing_segment_entry` even with no project billing, and on a busy
    /// disk that read ran past its deadline and failed the rollup stage.
    static let billingRollupCandidatesSQL = """
        SELECT s.* FROM billing_project p
        CROSS JOIN billing_segment s ON s.project_id = p.id
        LEFT JOIN billing_repo r ON r.id = s.repo_id
        WHERE s.ended_at <> '' AND s.entry_id IS NULL
          AND p.billing_enabled = 1
          AND (s.repo_id IS NULL OR r.billing_enabled = 1)
          AND ',' || s.flags || ',' NOT LIKE '%,\(untrackedFlag),%'
    """

    public func billingRollupCandidates(ids: [String]? = nil) throws -> [BillingSegmentDTO] {
        var sql = Self.billingRollupCandidatesSQL
        var params: [any Sendable] = []
        if let ids, !ids.isEmpty {
            sql += " AND s.id IN (\(ids.map { _ in "?" }.joined(separator: ", ")))"
            params = ids
        }
        sql += " ORDER BY s.started_at"

        var rows: [BillingSegmentDTO] = []
        try query(sql, params: params) { row in rows.append(Self.billingSegment(from: row)) }
        return rows
    }

    public func billingSegmentsForEntry(id: String) throws -> [BillingSegmentDTO] {
        var rows: [BillingSegmentDTO] = []
        try query("SELECT * FROM billing_segment WHERE entry_id = ? ORDER BY started_at",
                  params: [id]) { row in
            rows.append(Self.billingSegment(from: row))
        }
        return rows
    }

    public func attachSegments(ids: [String], toEntry entryId: String) throws {
        guard !ids.isEmpty else { return }
        let placeholders = ids.map { _ in "?" }.joined(separator: ", ")
        try execute(
            "UPDATE billing_segment SET entry_id = ? WHERE id IN (\(placeholders))",
            params: [entryId] + ids
        )
    }

    /// Every segment from `projectRoot` that no project holds and no entry
    /// has billed, oldest first: what "Assign Repository" moves.
    public func unassignedSegmentIDs(projectRoot: String) throws -> [String] {
        var ids: [String] = []
        try query("""
            SELECT id FROM billing_segment
            WHERE project_root = ? AND project_id IS NULL AND entry_id IS NULL
            ORDER BY started_at
        """, params: [projectRoot]) { row in
            if let id: String = row["id"] { ids.append(id) }
        }
        return ids
    }

    /// Moves segments to a project the user chose. The segment is flagged
    /// `assigned` so `replaceDerivedSegments` carries the choice onto the
    /// re-derived run instead of reverting it to whatever the repo mapping
    /// says. A repo row that belongs to a different project is dropped — its
    /// rate is that other project's business — so the time bills at the
    /// chosen project's own rate.
    public func assignSegments(ids: [String], toProject projectId: String?) throws -> Int {
        guard !ids.isEmpty else { return 0 }
        let placeholders = ids.map { _ in "?" }.joined(separator: ", ")
        var changed = 0
        let flag = Self.assignedFlag
        // A hand assignment is the user choosing to track this time, so it
        // drops `untracked` along the way.
        let kept = "trim(replace(',' || flags || ',', ',\(Self.untrackedFlag),', ','), ',')"
        try transaction {
            // Only unattached segments may be reassigned; one already rolled
            // into an entry is that entry's, and moving it would silently
            // change a total somewhere else.
            try execute("""
                UPDATE billing_segment
                SET project_id = ?,
                    repo_id = CASE WHEN repo_id IN (SELECT id FROM billing_repo WHERE project_id = ?)
                                   THEN repo_id ELSE NULL END,
                    flags = CASE
                        WHEN \(kept) = '' THEN '\(flag)'
                        WHEN ',' || \(kept) || ',' LIKE '%,\(flag),%' THEN \(kept)
                        ELSE \(kept) || ',\(flag)' END,
                    updated_at = ?
                WHERE id IN (\(placeholders)) AND entry_id IS NULL
            """, params: [projectId, projectId, UTCTimestamp.now()] + ids)
            try query("""
                SELECT COUNT(*) AS n FROM billing_segment
                WHERE id IN (\(placeholders)) AND entry_id IS NULL
            """, params: ids) { row in changed = row["n"] ?? 0 }
        }
        return changed
    }

    /// Distinct human titles for these sessions, newest session first, and
    /// the ids nothing titles any more. The title is what makes an entry
    /// defensible months later, so the summary is used when a session was
    /// never titled.
    ///
    /// Ordered by when each title's sessions *started*, which never moves:
    /// `last_activity_at` does, so a past entry's description reshuffled
    /// every time one of its still-open sessions became the most recent, and
    /// every reshuffle was a rewrite. A title shared by several sessions sorts
    /// by its newest one, and the title breaks ties, so the order is total.
    ///
    /// An app segment's session (`app:` + span id) is titled by its span's app
    /// name alone — never its window title. A description goes on a client's
    /// invoice, and a window title is whatever the window showed: another
    /// client's document, a private chat, a search. Names are deduplicated,
    /// and the spans' repos follow as one "in repo, repo" part. Window titles
    /// stay in `activity_span` for the spans endpoint. Both kinds share one
    /// ordering; start times are compared in SQLite's space-separated form
    /// because `sessions.started_at` usually is, and a raw ISO `T` would sort
    /// every span after every session of its day.
    ///
    /// The ids are split by source once, and each source is read once:
    /// `sessions` for Claude ids, `activity_span` for app ids (name, start and
    /// repo together). Only rows that no longer exist are `missing`: a row
    /// that is there but has no title yet has nothing to lose, and counting
    /// it froze the description for good the moment one untitled session
    /// joined.
    public func billingSessionTitles(sessionIds: [String]) throws -> BillingSessionTitles {
        let ids = sessionIds.filter { !$0.isEmpty }
        guard !ids.isEmpty else { return BillingSessionTitles(titles: [], missing: []) }
        var claude: [String] = []
        var spans: [String] = []
        for id in Set(ids) {
            if let span = ActivitySpanSession.spanId(sessionId: id) { spans.append(span) } else { claude.append(id) }
        }
        let started = "replace(replace(started_at, 'T', ' '), 'Z', '')"
        var newest: [String: String] = [:]
        var found: Set<String> = []
        func note(_ title: String, _ start: String) {
            guard !title.isEmpty else { return }
            if let seen = newest[title], seen.utf8.lexicographicallyPrecedes(start.utf8) == false { return }
            newest[title] = start
        }
        if !claude.isEmpty {
            try query("""
                SELECT session_id, COALESCE(NULLIF(transcript_title, ''), summary) AS title,
                       \(started) AS started
                FROM sessions WHERE session_id IN (\(claude.map { _ in "?" }.joined(separator: ", ")))
            """, params: claude) { row in
                found.insert(row["session_id"] ?? "")
                note(row["title"] ?? "", row["started"] ?? "")
            }
        }
        var repos: Set<String> = []
        if !spans.isEmpty {
            try query("""
                SELECT id, app_name, repo_root, \(started) AS started
                FROM activity_span WHERE id IN (\(spans.map { _ in "?" }.joined(separator: ", ")))
            """, params: spans) { row in
                found.insert(ActivitySpanSession.sessionId(spanId: row["id"] ?? ""))
                note(row["app_name"] ?? "", row["started"] ?? "")
                let root: String = row["repo_root"] ?? ""
                let name = (root as NSString).lastPathComponent
                if !root.isEmpty, !name.isEmpty { repos.insert(name) }
            }
        }
        var titles = newest.sorted { lhs, rhs in
            lhs.value == rhs.value
                ? lhs.key.utf8.lexicographicallyPrecedes(rhs.key.utf8)
                : rhs.value.utf8.lexicographicallyPrecedes(lhs.value.utf8)
        }.map(\.key)
        if !repos.isEmpty { titles.append("in \(repos.sorted().joined(separator: ", "))") }
        return BillingSessionTitles(titles: titles, missing: Set(ids).subtracting(found))
    }

    /// The app name of each `app:` session id, one row per span found. Only
    /// the name: a window title is for an entry's description, not a row label.
    func billingAppNames(sessionIds: [String]) throws -> [BillingAppNameDTO] {
        let spanIds = sessionIds.compactMap { ActivitySpanSession.spanId(sessionId: $0) }
        guard !spanIds.isEmpty else { return [] }
        var rows: [BillingAppNameDTO] = []
        try query("""
            SELECT id, app_name FROM activity_span
            WHERE id IN (\(spanIds.map { _ in "?" }.joined(separator: ", ")))
        """, params: spanIds) { row in
            let id: String = row["id"] ?? ""
            rows.append(BillingAppNameDTO(sessionId: ActivitySpanSession.sessionId(spanId: id),
                                          appName: row["app_name"] ?? ""))
        }
        return rows
    }

    // MARK: - Audit

    /// Append-only. Nothing in this file ever updates or deletes an audit row.
    public func appendBillingAudit(
        entryId: String, field: String, oldValue: String, newValue: String, source: String
    ) throws {
        try execute("""
            INSERT INTO billing_entry_audit (entry_id, at, field, old_value, new_value, source)
            VALUES (?, ?, ?, ?, ?, ?)
        """, params: [entryId, UTCTimestamp.now(), field, oldValue, newValue, source])
    }

    func billingEntryAudit(entryId: String, limit: Int) throws -> [BillingAuditDTO] {
        var rows: [BillingAuditDTO] = []
        try query("""
            SELECT * FROM billing_entry_audit WHERE entry_id = ? ORDER BY at, id LIMIT ?
        """, params: [entryId, max(1, limit)]) { row in
            rows.append(BillingAuditDTO(
                entryId: row["entry_id"] ?? "", at: row["at"] ?? "",
                field: row["field"] ?? "", oldValue: row["old_value"] ?? "",
                newValue: row["new_value"] ?? "", source: row["source"] ?? "user"
            ))
        }
        return rows
    }

    // MARK: - Overview

    /// `currency → status → (seconds, amount, count)`, with the currencies in
    /// the order of how many entries use them (most first, then by code, so
    /// the order is stable). Aggregated in SQL because the overview is read on
    /// every window open and the entry table only grows. Grouped by currency
    /// because amounts in two currencies cannot be added: there is no
    /// conversion anywhere.
    public func billingOverviewBuckets() throws -> [(currency: String, buckets: [String: BillingOverviewBucketDTO])] {
        var byCurrency: [String: [String: BillingOverviewBucketDTO]] = [:]
        var counts: [String: Int] = [:]
        try query("""
            SELECT currency, status,
                   SUM(billed_seconds) AS seconds,
                   SUM(amount_cents)   AS amount,
                   COUNT(*)            AS entries
            FROM billing_entry WHERE \(Self.visibleEntry) GROUP BY currency, status
        """) { row in
            let currency: String = row["currency"] ?? ""
            let key = currency.isEmpty ? "USD" : currency
            let entries: Int = row["entries"] ?? 0
            let bucket = BillingOverviewBucketDTO(
                seconds: row["seconds"] ?? 0,
                amountCents: row["amount"] ?? 0,
                entryCount: entries
            )
            let status: String = row["status"] ?? ""
            if let existing = byCurrency[key]?[status] {
                // '' and 'USD' fold together; add rather than overwrite.
                byCurrency[key, default: [:]][status] = BillingOverviewBucketDTO(
                    seconds: existing.seconds + bucket.seconds,
                    amountCents: existing.amountCents + bucket.amountCents,
                    entryCount: existing.entryCount + bucket.entryCount
                )
            } else {
                byCurrency[key, default: [:]][status] = bucket
            }
            counts[key, default: 0] += entries
        }
        return byCurrency.keys
            .sorted { (counts[$0] ?? 0, $1) > (counts[$1] ?? 0, $0) }
            .map { (currency: $0, buckets: byCurrency[$0] ?? [:]) }
    }

    static func billingEntry(from row: Row) -> BillingEntryDTO {
        BillingEntryDTO(
            id: row["id"] ?? "", projectId: row["project_id"] ?? "",
            clientId: row["client_id"], day: row["day"] ?? "",
            groupKey: row["group_key"] ?? "",
            startedAt: row["started_at"] ?? "", endedAt: row["ended_at"] ?? "",
            rawSeconds: row["raw_seconds"] ?? 0, billedSeconds: row["billed_seconds"] ?? 0,
            rateCents: row["rate_cents"] ?? 0, currency: row["currency"] ?? "USD",
            amountCents: row["amount_cents"] ?? 0,
            roundingMinutes: row["rounding_minutes"] ?? 15,
            roundingMode: row["rounding_mode"] ?? "up",
            status: row["status"] ?? BillingStatus.unbilled.rawValue,
            description: row["description"] ?? "", origin: row["origin"] ?? "auto",
            locked: (row["locked"] ?? 0) != 0,
            supplementsEntryId: row["supplements_entry_id"],
            createdAt: row["created_at"] ?? "", updatedAt: row["updated_at"] ?? ""
        )
    }
}

/// The daemon's SQLite database is the storage the shared billing logic runs
/// against; every rule is `AgenticDeveloperHubSDKCore`'s.
extension DaemonDatabase: BillingPersistence {
    /// The billing knobs live in the settings table under
    /// ``billingSettingsKeyPrefix``.
    public var billingSettingsKeys: BillingSettingsKeys {
        BillingSettingsKeys(prefix: billingSettingsKeyPrefix)
    }
}

extension BillingEntryOverwrite {
    /// The `ON CONFLICT … DO UPDATE` guard, checked in SQL against the row as
    /// it is *now*.
    fileprivate var condition: String {
        switch self {
        case .any: return ""
        case .unlocked: return "WHERE billing_entry.locked = 0"
        case .rollupOwned: return "WHERE billing_entry.locked = 0 AND billing_entry.origin = 'auto'"
        }
    }
}

extension StoredBillingEntry {
    /// `description_edited` is read in the same `SELECT *` as the entry
    /// rather than by a second query.
    fileprivate init(row: Row) {
        self.init(
            entry: DaemonDatabase.billingEntry(from: row),
            descriptionEdited: (row["description_edited"] ?? 0) != 0,
            billedRanges: row["billed_ranges"]
        )
    }
}

// swiftlint:enable identifier_name
#endif
