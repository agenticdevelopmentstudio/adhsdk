#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation
import GRDB
import OSLog

/// What one trim pass did, as `TrimService.run` returns it and as the setting
/// `storage_last_trim` keeps it (JSON).
public struct TrimReport: Sendable, Codable, Equatable {
    public var startedAt: Double
    public var finishedAt: Double
    /// Rows older than this (epoch seconds, a UTC midnight) were eligible; nil
    /// when nothing was (see `waitingFor`).
    public var cutoff: Double?
    /// Why part or all of the pass did nothing: "rollups" when a rollup
    /// watermark is missing, "events.db unavailable" when there is no event
    /// store, "skipped: bulk load" while one runs, or a `TrimHold`'s reason
    /// ("billing") when it held the cutoff back. Not an error.
    public var waitingFor: String?
    public var events: Int
    public var messages: Int
    public var turns: Int
    /// `events.db` sessions rows deleted (never main-db sessions rows).
    public var sessions: Int
    public var rateLimitSnapshots: Int
    public var reclaimedBytes: Int64
    /// "incremental", "full main", "incremental, full main", "skipped" or
    /// "unavailable (auto_vacuum=none)".
    public var vacuum: String
    /// False when rows may still be due: the pass stopped on its deadline, a
    /// stage failed, or a bulk load kept it out of `events.db`. The caller
    /// retries soon rather than a day later. True when it waited for rollups or
    /// had no event store (nothing to retry until they change).
    public var finished: Bool
    /// A stage that failed, with the counts above still what was deleted.
    public var error: String?

    public init(
        startedAt: Double, finishedAt: Double, cutoff: Double? = nil, waitingFor: String? = nil,
        events: Int = 0, messages: Int = 0, turns: Int = 0, sessions: Int = 0, rateLimitSnapshots: Int = 0,
        reclaimedBytes: Int64 = 0, vacuum: String = TrimService.vacuumSkipped, finished: Bool = true,
        error: String? = nil
    ) {
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.cutoff = cutoff
        self.waitingFor = waitingFor
        self.events = events
        self.messages = messages
        self.turns = turns
        self.sessions = sessions
        self.rateLimitSnapshots = rateLimitSnapshots
        self.reclaimedBytes = reclaimedBytes
        self.vacuum = vacuum
        self.finished = finished
        self.error = error
    }
}

/// A last `yyyy-MM-dd` UTC day a trim may reach, besides the rollups', and why.
public struct TrimHold: Sendable, Equatable {
    public var day: String
    /// What the report's `waitingFor` says when this hold lowers the cutoff.
    public var reason: String

    public init(day: String, reason: String) {
        self.day = day
        self.reason = reason
    }
}

/// One storage trim pass over a daemon database and its optional event store.
///
/// **What it deletes.** `events.db` events, messages and turns older than the
/// cutoff (and that file's ended, empty `sessions` rows, by `EventStore.trim`),
/// old `rate_limit_snapshots` rows except the newest per account, and whatever
/// the injected `extraMainTrims` delete. Nothing else: never a main-db
/// `sessions` row, never a raw archive, spool, rollup or summary table.
///
/// **The cutoff** is a UTC midnight: the earlier of `now - historyDays`
/// (at least 7) floored to midnight, and the day after `coveredThroughDay()`,
/// the last day every rollup has frozen. With no covered day the pass deletes
/// nothing and reports `waitingFor: "rollups"`. A `hold` (the daemon's billing,
/// for one) can hold the cutoff back further; when it does, the pass still
/// trims up to the held cutoff and reports the hold's reason in `waitingFor`.
///
/// **Bounded.** Deletes are batches of 500, one transaction each. The pass stops
/// at `deadline` with `finished = false`; a rerun continues from the same cutoff.
/// `events.db` is then vacuumed incrementally for up to 60 s, and the main
/// database gets a full `VACUUM` only when ``shouldVacuumMain`` allows it.
public final class TrimService: Sendable {
    /// The setting the last report is kept in, as JSON.
    public static let lastTrimKey = "storage_last_trim"
    /// The setting holding when the main database was last fully vacuumed (epoch seconds).
    public static let lastMainVacuumKey = "storage_last_main_vacuum"

    public static let minimumHistoryDays = 7
    public static let batchSize = 500
    /// How long the incremental vacuum of `events.db` may run.
    public static let incrementalVacuumSeconds: Double = 60
    /// The main-db full-vacuum gate: below this size only.
    public static let mainVacuumMaxBytes: Int64 = 1 << 30
    /// ... with more than this share of its pages free ...
    public static let mainVacuumFreelistShare = 0.25
    /// ... and at least this long since the last one.
    public static let mainVacuumInterval: Double = 7 * 86400

    public static let vacuumSkipped = "skipped"
    public static let vacuumIncremental = "incremental"
    public static let vacuumFullMain = "full main"
    public static let vacuumUnavailable = "unavailable (auto_vacuum=none)"
    public static let waitingForRollups = "rollups"
    public static let waitingForEventStore = "events.db unavailable"
    public static let waitingForBulkLoad = "skipped: bulk load"
    /// The reason a billing hold reports: sessions billing has not derived yet.
    public static let waitingForBilling = "billing"

    private let database: DaemonDatabase
    private let eventStore: EventStore?
    private let historyDays: Int
    private let coveredThroughDay: @Sendable () -> String?
    private let snapshotsReadThrough: (@Sendable () -> Int?)?
    private let hold: (@Sendable () -> TrimHold?)?
    private let extraMainTrims: [@Sendable (_ cutoff: Double, _ deadline: Date) throws -> Int]
    private let now: @Sendable () -> Date

    /// - Parameters:
    ///   - coveredThroughDay: the last `yyyy-MM-dd` UTC day every rollup has
    ///     frozen (the earlier of the watermarks); nil while any is missing.
    ///   - hold: a last day the trim may reach for another reason, and that
    ///     reason; nil (or a nil hold) holds nothing back.
    ///   - snapshotsReadThrough: when given, the highest `rate_limit_snapshots.id`
    ///     the daemon's own readers have consumed; rows above it are never
    ///     deleted, and nil from it deletes no snapshot.
    ///   - extraMainTrims: the daemon's own main-db trims, each returning rows deleted.
    public init(
        database: DaemonDatabase, eventStore: EventStore?, historyDays: Int,
        coveredThroughDay: @escaping @Sendable () -> String?,
        snapshotsReadThrough: (@Sendable () -> Int?)? = nil,
        hold: (@Sendable () -> TrimHold?)? = nil,
        extraMainTrims: [@Sendable (_ cutoff: Double, _ deadline: Date) throws -> Int] = [],
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.database = database
        self.eventStore = eventStore
        self.historyDays = max(Self.minimumHistoryDays, historyDays)
        self.coveredThroughDay = coveredThroughDay
        self.snapshotsReadThrough = snapshotsReadThrough
        self.hold = hold
        self.extraMainTrims = extraMainTrims
        self.now = now
    }

    // MARK: - Cutoff

    /// The epoch seconds of a `yyyy-MM-dd` UTC day's midnight.
    static func dayStart(_ day: String) -> Double? {
        UTCTimestamp.epochSeconds("\(day)T00:00:00Z").map(Double.init)
    }

    /// The cutoff for `historyDays` (at least 7) at `now` and the covered day,
    /// or nil when there is no usable covered day.
    public static func cutoff(now: Date, historyDays: Int, coveredThroughDay: String?) -> Double? {
        guard let covered = coveredThroughDay, !covered.isEmpty,
              let coveredLimit = dayStart(UTCDay.dayAfter(covered)),
              dayStart(covered) != nil else { return nil }
        let days = max(minimumHistoryDays, historyDays)
        guard let window = dayStart(UTCDay.string(from: now.addingTimeInterval(-Double(days) * 86400))) else {
            return nil
        }
        return min(window, coveredLimit)
    }

    // MARK: - Main vacuum gate

    /// The main database is fully vacuumed only when it is under 1 GiB, more
    /// than a quarter of its pages are free, and the last full vacuum was at
    /// least 7 days ago (or never). A large file is never vacuumed here: the
    /// copy would need its size again in free disk and hold the writer for minutes.
    public static func shouldVacuumMain(
        bytes: Int64, pageCount: Int, freelistCount: Int, lastVacuum: Double?, now: Date
    ) -> Bool {
        guard bytes < mainVacuumMaxBytes, pageCount > 0 else { return false }
        guard Double(freelistCount) > Double(pageCount) * mainVacuumFreelistShare else { return false }
        if let lastVacuum, now.timeIntervalSince1970 - lastVacuum < mainVacuumInterval { return false }
        return true
    }

    // MARK: - Report

    /// The report the last pass stored, if any.
    public static func lastReport(_ database: DaemonDatabase) -> TrimReport? {
        guard let raw = (try? database.setting(for: lastTrimKey)) ?? nil, let data = raw.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(TrimReport.self, from: data)
    }

    private func store(_ report: TrimReport) {
        do {
            let data = try JSONEncoder().encode(report)
            guard let json = String(bytes: data, encoding: .utf8) else { return }
            try database.setSetting(Self.lastTrimKey, json)
        } catch {
            logger.error("Could not store the trim report: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Pass

    /// One pass. Each stage records its own failure in `error` and the later
    /// stages still run; the report is stored before it is returned.
    public func run(deadline: Date) throws -> TrimReport {
        let started = now()
        var report = TrimReport(startedAt: started.timeIntervalSince1970, finishedAt: started.timeIntervalSince1970)
        let covered = coveredThroughDay()
        guard let unheld = Self.cutoff(now: started, historyDays: historyDays, coveredThroughDay: covered),
              let covered else {
            report.waitingFor = Self.waitingForRollups
            report.finishedAt = now().timeIntervalSince1970
            logger.info("Trim deleted nothing: waiting for the rollups to cover a day")
            store(report)
            return report
        }
        var cutoff = unheld
        if let held = hold?(), held.day < covered,
           let heldCutoff = Self.cutoff(now: started, historyDays: historyDays, coveredThroughDay: held.day),
           heldCutoff < unheld {
            cutoff = heldCutoff
            report.waitingFor = held.reason
            logger.info("Trim held back to \(held.day, privacy: .public): \(held.reason, privacy: .public)")
        }
        report.cutoff = cutoff
        let bytesBefore = totalBytes()
        var errors: [String] = []
        var vacuum = Self.vacuumSkipped

        // 1. rate_limit_snapshots, the newest row per account always kept.
        // Account backfill (`recoverAccountFromSiblings`) also reads snapshots;
        // trimming weakens it only before `account_backfill_done` is set.
        do {
            let (deleted, done) = try trimSnapshots(before: cutoff, deadline: deadline)
            report.rateLimitSnapshots = deleted
            if !done { report.finished = false }
        } catch {
            errors.append("rate_limit_snapshots: \(error.localizedDescription)")
        }

        // 2. The daemon's own main-db trims.
        for trim in extraMainTrims where report.finished {
            do {
                _ = try trim(cutoff, deadline)
            } catch {
                errors.append("main trim: \(error.localizedDescription)")
            }
        }

        // 3. events.db rows, then its incremental vacuum.
        if let eventStore {
            do {
                let result = try eventStore.trim(olderThan: cutoff, batch: Self.batchSize, deadline: deadline)
                report.events = result.events
                report.messages = result.messages
                report.turns = result.turns
                report.sessions = result.sessions
                if !result.finished {
                    report.finished = false
                } else {
                    vacuum = try vacuumEvents(eventStore, deadline: deadline)
                }
            } catch let failure as EventStoreTrimFailure {
                report.events = failure.partial.events
                report.messages = failure.partial.messages
                report.turns = failure.partial.turns
                report.sessions = failure.partial.sessions
                report.finished = false
                errors.append("events.db: \(failure.underlying.localizedDescription)")
            } catch EventStoreError.bulkLoadInProgress {
                report.waitingFor = Self.waitingForBulkLoad
                report.finished = false
            } catch {
                report.finished = false
                errors.append("events.db: \(error.localizedDescription)")
            }
        } else {
            report.waitingFor = Self.waitingForEventStore
        }

        // 4. The main database, only under the gate.
        if report.finished, Date() < deadline {
            do {
                if try vacuumMainIfDue() {
                    vacuum = vacuum == Self.vacuumSkipped ? Self.vacuumFullMain : "\(vacuum), \(Self.vacuumFullMain)"
                }
            } catch {
                errors.append("main vacuum: \(error.localizedDescription)")
            }
        }

        report.vacuum = vacuum
        report.reclaimedBytes = max(0, bytesBefore - totalBytes())
        report.error = errors.isEmpty ? nil : errors.joined(separator: "; ")
        // A failed stage left rows behind: not finished, so the caller retries soon.
        if report.error != nil { report.finished = false }
        report.finishedAt = now().timeIntervalSince1970
        logger.info("""
            Trim: \(report.events) events, \(report.messages) messages, \(report.turns) turns, \
            \(report.sessions) sessions, \(report.rateLimitSnapshots) snapshots; \
            vacuum \(report.vacuum, privacy: .public); finished \(report.finished)
            """)
        if let error = report.error {
            logger.error("Trim stage failed: \(error, privacy: .public)")
        }
        store(report)
        return report
    }

    /// The main database plus `events.db`, as they are on disk.
    private func totalBytes() -> Int64 {
        var bytes = StoreFileStats.diskBytes(path: database.path)
        if let eventStore { bytes += StoreFileStats.diskBytes(path: eventStore.path) }
        return bytes
    }

    /// Deletes snapshots stamped before the cutoff's UTC day, oldest first, in
    /// batches; never the newest row of any `account_email` (NULL included), and
    /// never one above `snapshotsReadThrough`. Returns the rows deleted and
    /// whether it finished before the deadline.
    private func trimSnapshots(before cutoff: Double, deadline: Date) throws -> (Int, Bool) {
        guard database.tableExists("rate_limit_snapshots") else { return (0, true) }
        var ceiling = Int64.max
        if let snapshotsReadThrough {
            guard let readThrough = snapshotsReadThrough() else { return (0, true) }
            ceiling = Int64(readThrough)
        }
        let hasAccount = database.tableHasColumn("rate_limit_snapshots", "account_email")
        let newest = hasAccount
            ? "SELECT MAX(id) FROM rate_limit_snapshots GROUP BY account_email"
            : "SELECT MAX(id) FROM rate_limit_snapshots"
        // ISO-8601 TEXT sorts by day first, so "< yyyy-MM-dd" is "before that midnight".
        let day = UTCDay.string(from: Date(timeIntervalSince1970: cutoff))
        var total = 0
        var first = true
        while true {
            if !first && Date() >= deadline { return (total, false) }
            first = false
            let deleted = try database.write { conn -> Int in
                try conn.execute(sql: """
                    DELETE FROM rate_limit_snapshots WHERE id IN (
                        SELECT id FROM rate_limit_snapshots
                        WHERE timestamp < ? AND id <= ? AND id NOT IN (\(newest))
                        ORDER BY timestamp LIMIT ?)
                    """, arguments: [day, ceiling, Self.batchSize])
                return conn.changesCount
            }
            total += deleted
            if deleted < Self.batchSize { return (total, true) }
        }
    }

    private func vacuumEvents(_ store: EventStore, deadline: Date) throws -> String {
        guard Date() < deadline else { return Self.vacuumSkipped }
        let until = min(deadline, Date().addingTimeInterval(Self.incrementalVacuumSeconds))
        do {
            guard try store.incrementalVacuum(deadline: until) != nil else { return Self.vacuumUnavailable }
            return Self.vacuumIncremental
        } catch EventStoreError.bulkLoadInProgress {
            return Self.vacuumSkipped
        }
    }

    /// Runs a full `VACUUM` of the main database when ``shouldVacuumMain`` allows
    /// it, and records when. Returns whether it ran.
    private func vacuumMainIfDue() throws -> Bool {
        let (pageCount, freelist) = try database.read { conn in
            (try Int.fetchOne(conn, sql: "PRAGMA page_count") ?? 0,
             try Int.fetchOne(conn, sql: "PRAGMA freelist_count") ?? 0)
        }
        let last = ((try? database.setting(for: Self.lastMainVacuumKey)) ?? nil).flatMap(Double.init)
        let current = now()
        guard Self.shouldVacuumMain(
            bytes: StoreFileStats.diskBytes(path: database.path), pageCount: pageCount,
            freelistCount: freelist, lastVacuum: last, now: current) else { return false }
        try database.writeWithoutTransaction(deadline: DaemonDatabase.migrationWriteDeadline) { conn in
            try conn.execute(sql: "VACUUM")
        }
        try database.setSetting(Self.lastMainVacuumKey, String(current.timeIntervalSince1970))
        return true
    }
}

extension TrimService: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension TrimReportDTO {
    /// The wire form of `report`.
    public init(_ report: TrimReport) {
        self.init(
            startedAt: report.startedAt, finishedAt: report.finishedAt, cutoff: report.cutoff,
            waitingFor: report.waitingFor, events: report.events, messages: report.messages, turns: report.turns,
            sessions: report.sessions, rateLimitSnapshots: report.rateLimitSnapshots,
            reclaimedBytes: report.reclaimedBytes, vacuum: report.vacuum, finished: report.finished,
            error: report.error)
    }
}

#endif
