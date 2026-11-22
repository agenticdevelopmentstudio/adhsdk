#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

// The per-session usage summary and its bursts (migration 051), kept in the
// main database so Usage's weekly and hours history outlives the turns
// trimming takes out of events.db.
//
// Rows are cut at every UTC midnight and at every 7-day quota reset instant
// (`rate_limit_snapshots.seven_day_resets_at`, every week back): the weekly
// and hours windows begin and end on those instants, so a window over
// trimmed days sums whole segments and never estimates.
//
// - Writer: `refreshUsageSummary(forDay:)`, driven by `RollupTask`, which keeps
//   `usage_summary_finalized_through` behind `stats_rollup_finalized_through`
//   and walks every older day once (`backfillUsageSummary`), re-cuts held
//   days when a new reset instant appears, and re-reads a finalized day that
//   late turns land on (`recountLateUsageTurns`).
// - Readers: `usageSummaryTotals` (the weekly token and cost rows) and
//   `usageSummaryHours` (the hours rows). A day at or before the summary
//   watermark is read from the summary; every later day, today included, from
//   events.db's live turns, so the newest figures are never a rollup old.
extension DaemonDatabase {

    /// The last UTC day whose summary rows are final: every day up to it was
    /// refreshed after the rollup froze it. The trim guard reads this, so it
    /// never passes a day that has not been summarised. It never moves back.
    static let usageSummaryFinalizedKey = "usage_summary_finalized_through"

    /// The last UTC day the backfill walk has examined. Cleared to re-walk
    /// every held day when a new reset instant appears.
    static let usageSummaryBackfillMarkerKey = "usage_summary_backfilled_through"

    /// The 7-day reset phases (`seven_day_resets_at` mod one week) rows are
    /// cut at, comma-separated seconds.
    static let usageSummaryResetPhasesKey = "usage_summary_reset_phases"

    /// The largest `seven_day_resets_at` read into the phases so far: how far
    /// ahead the reset instants are known (the backfill's hold rule).
    static let usageSummaryResetsScannedKey = "usage_summary_resets_scanned_through"

    /// The last `rate_limit_snapshots.id` read into the phases. Snapshots are
    /// scanned by id, not by reset value: each account has its own reset, and
    /// one recorded after another account's later reset is still read.
    static let usageSummaryResetsSnapshotKey = "usage_summary_resets_snapshot_id"

    /// The last `turns.id` checked for turns arriving on finalized days. Summary
    /// rows count only turns at or below it, and the storage trim deletes no
    /// timed turn above it, so a turn is never trimmed before it is counted.
    static let usageSummaryTurnCursorKey = "usage_summary_turn_cursor"

    /// The days a recount pass has rebuilt but not yet moved the cursor past:
    /// JSON `{"from": <saved cursor>, "days": {"<day>": <counted through id>}}`,
    /// written with each rebuilt day's rows and cleared when the cursor moves
    /// (``addLateUsageTurns(_:cursorFrom:to:)``). A pass that stopped in
    /// between (a crash, a throw) leaves it, and the retry skips the arrivals
    /// those rows already count instead of adding them again.
    static let usageSummaryRecountRebuiltKey = "usage_summary_recount_rebuilt"

    /// ``usageSummaryRecountRebuiltKey`` as written.
    struct RecountRebuilt: Codable, Equatable {
        var from: Int64
        var days: [String: Int64]
    }

    /// The epoch seconds before which the storage trim may have deleted turns:
    /// the largest cutoff any pass has used, recorded before that pass deletes
    /// anything. A day that starts before it is never rebuilt from events.db
    /// again; a late turn on it is added to its rows instead.
    static let usageSummaryTrimmedBeforeKey = "usage_summary_trimmed_before"

    /// The ``TranscriptPricing/revision`` the stored `cost_usd` values were
    /// priced at (``restartUsageSummaryForPricingIfNeeded()``).
    static let usageSummaryPricingRevisionKey = "usage_summary_pricing_revision"

    /// The idle gap `usage_bursts` were cut with: the Usage hours rows' 15 minutes.
    static let usageBurstIdleGap: Double = 15 * 60

    /// One quota week. A reset instant recurs every week at the same phase.
    static let usageWeekSeconds = 7 * 86400

    // MARK: - Migration

    /// `session_summary`'s definition under `name`.
    private static func sessionSummaryTableSQL(_ name: String) -> String {
        """
        CREATE TABLE IF NOT EXISTS \(name) (
          provider TEXT NOT NULL, session_id TEXT NOT NULL, day TEXT NOT NULL,
          segment_start REAL NOT NULL,
          project TEXT, account TEXT,
          first_time REAL NOT NULL, last_time REAL NOT NULL,
          turn_count INTEGER NOT NULL, event_count INTEGER NOT NULL,
          input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
          cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
          cost_usd REAL NOT NULL, updated_at REAL NOT NULL,
          PRIMARY KEY (provider, session_id, day, segment_start)) WITHOUT ROWID
        """
    }

    func migration1007() throws {
        try migrationExecute(Self.sessionSummaryTableSQL("session_summary"))
        try migrationExecute("CREATE INDEX IF NOT EXISTS session_summary_day ON session_summary(day)")
        try migrationExecute("CREATE INDEX IF NOT EXISTS session_summary_session ON session_summary(session_id)")
        try migrationExecute("""
            CREATE TABLE IF NOT EXISTS usage_bursts (
              provider TEXT NOT NULL, session_id TEXT NOT NULL, account TEXT,
              start REAL NOT NULL, end REAL NOT NULL, day TEXT NOT NULL,
              PRIMARY KEY (provider, session_id, start)) WITHOUT ROWID
            """)
        try migrationExecute("CREATE INDEX IF NOT EXISTS usage_bursts_day ON usage_bursts(day)")
        try migrationExecute("CREATE INDEX IF NOT EXISTS usage_bursts_start ON usage_bursts(start)")
    }

    /// Migration 051's body as an ensure step: every statement is
    /// `IF NOT EXISTS`, so it repairs a database that recorded 51 without the
    /// tables and does nothing otherwise. First, a `session_summary` of the
    /// 1.4.41 shape (no `segment_start`) is upgraded in place
    /// (``upgradeSessionSummarySegments()``). A column added later needs its
    /// own ensure with a column check.
    static func ensureUsageSummaryTables(_ database: DaemonDatabase) throws {
        try database.upgradeSessionSummarySegments()
        try database.migration1007()
    }

    /// Upgrades a `session_summary` without `segment_start` (1.4.41's, keyed
    /// by day) to the segmented shape: in one transaction, every row is copied
    /// into the new table as its day's one segment (`segment_start` = the
    /// day's UTC midnight), the copy is counted, and only then does the old
    /// table go. The rows may be the only record of a trimmed day, so they are
    /// never dropped uncopied. The backfill walk then restarts, re-cutting
    /// every day events.db still holds at the reset instants.
    ///
    /// `afterCopy` (tests only) runs inside the transaction between the copy
    /// and the count, so a test can make the two disagree.
    func upgradeSessionSummarySegments(afterCopy: ((DaemonDatabase) throws -> Void)? = nil) throws {
        guard try tableExists("session_summary"),
              try !tableHasColumn("session_summary", "segment_start") else { return }
        let columns = "provider, session_id, day, project, account, first_time, last_time, turn_count, "
            + "event_count, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd, updated_at"
        var copied = 0
        try transaction {
            try execute("DROP TABLE IF EXISTS session_summary_segmented")
            try execute(Self.sessionSummaryTableSQL("session_summary_segmented"))
            try execute("""
                INSERT INTO session_summary_segmented(\(columns), segment_start)
                SELECT \(columns), CAST(strftime('%s', day) AS REAL) FROM session_summary
                """)
            try afterCopy?(self)
            var held = 0
            try query("SELECT COUNT(*) FROM session_summary") { row in held = self.int(row, 0) }
            try query("SELECT COUNT(*) FROM session_summary_segmented") { row in copied = self.int(row, 0) }
            guard held == copied else {
                throw DaemonDatabaseError.stepFailed(
                    message: "session_summary upgrade copied \(copied) of \(held) rows", code: 1)
            }
            try execute("DROP TABLE session_summary")
            try execute("ALTER TABLE session_summary_segmented RENAME TO session_summary")
            try setSetting(Self.usageSummaryBackfillMarkerKey, "")
        }
        Self.logger.info("session_summary upgraded to reset-instant segments: \(copied) row(s) kept")
    }

    // MARK: - The burst rule

    typealias SessionBurst = (sessionId: String, start: Double, end: Double)

    /// The one home of the active-time burst rule. `times` are ordered by
    /// session, then time (as `claudeTurnTimes` returns them). Within a session,
    /// turns whose gap stays within `idleGap` form one burst; a larger gap, or
    /// the next session, closes it (Core's `ActivityRuns.Splitter`). A lone turn
    /// is a zero-length burst. Bursts come out in input order.
    static func sessionBursts(
        _ times: [(sessionId: String, time: Double)], idleGap: Double
    ) -> [SessionBurst] {
        var bursts: [SessionBurst] = []
        var index = 0
        while index < times.count {
            let session = times[index].sessionId
            var splitter = ActivityRuns.Splitter<Double>(idleGap: idleGap)
            while index < times.count && times[index].sessionId == session {
                splitter.add(times[index].time)
                index += 1
            }
            for span in splitter.finish() {
                bursts.append((sessionId: session, start: span.start, end: span.end))
            }
        }
        return bursts
    }

    /// Bursts cut from separate pieces of one window (summary segments, live
    /// slices) joined back into the bursts the rule gives over the whole
    /// window: ordered by session (byte order, as SQLite orders `session_id`)
    /// then start, and a session's next burst that begins within `idleGap` of
    /// the previous one's end continues it — exactly the Splitter's test, so a
    /// burst that crossed a UTC midnight or a reset instant comes back whole.
    static func mergedSessionBursts(_ bursts: [SessionBurst], idleGap: Double) -> [SessionBurst] {
        let sorted = bursts.sorted { lhs, rhs in
            lhs.sessionId != rhs.sessionId
                ? lhs.sessionId.utf8.lexicographicallyPrecedes(rhs.sessionId.utf8)
                : lhs.start < rhs.start
        }
        var merged: [SessionBurst] = []
        for burst in sorted {
            if let last = merged.last, last.sessionId == burst.sessionId, burst.start - last.end <= idleGap {
                merged[merged.count - 1].end = max(last.end, burst.end)
            } else {
                merged.append(burst)
            }
        }
        return merged
    }

    // MARK: - Watermarks

    func usageSummaryFinalizedThrough() throws -> String? {
        try setting(for: Self.usageSummaryFinalizedKey).flatMap { $0.isEmpty ? nil : $0 }
    }

    func usageSummaryBackfilledThrough() throws -> String? {
        try setting(for: Self.usageSummaryBackfillMarkerKey).flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Moves `usage_summary_finalized_through` to `day` unless it already
    /// stands there or later: the watermark never moves back, so a day a
    /// trim may already have reached is never treated as open again.
    func advanceUsageSummaryWatermark(to day: String) throws {
        if let current = try usageSummaryFinalizedThrough(), current >= day { return }
        try setSetting(Self.usageSummaryFinalizedKey, day)
    }

    /// The saved recount cursor (``usageSummaryTurnCursorKey``), or nil before
    /// the first recount.
    func usageSummaryTurnCursor() throws -> Int64? {
        try setting(for: Self.usageSummaryTurnCursorKey).flatMap { Int64($0) }
    }

    /// ``usageSummaryRecountRebuiltKey``, or nil when none is pending (or it
    /// cannot be read: the retry then adds what it finds, as before).
    func recountRebuilt() throws -> RecountRebuilt? {
        try setting(for: Self.usageSummaryRecountRebuiltKey)
            .flatMap { try? JSONDecoder().decode(RecountRebuilt.self, from: Data($0.utf8)) }
    }

    static func encodeRecountRebuilt(_ record: RecountRebuilt) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let text = String(bytes: try encoder.encode(record), encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return text
    }

    /// ``usageSummaryTrimmedBeforeKey``, or nil when no trim has deleted anything.
    func usageSummaryTrimmedBefore() throws -> Double? {
        try setting(for: Self.usageSummaryTrimmedBeforeKey).flatMap { Double($0) }
    }

    /// Raises ``usageSummaryTrimmedBeforeKey`` to `cutoff`; it never moves back.
    /// The storage trim calls it before each pass deletes anything.
    func raiseUsageSummaryTrimmedBefore(_ cutoff: Double) throws {
        try transaction {
            if let current = try usageSummaryTrimmedBefore(), current >= cutoff { return }
            try setSetting(Self.usageSummaryTrimmedBeforeKey, String(cutoff))
        }
    }

    // MARK: - Reset instants

    /// The 7-day reset phases rows are cut at, ascending.
    func usageResetPhases() throws -> [Int] {
        let text = try setting(for: Self.usageSummaryResetPhasesKey) ?? ""
        return text.split(separator: ",").compactMap { Int($0) }.sorted()
    }

    /// The latest reset instant recorded, or nil when no snapshot carries one.
    func usageResetsKnownThrough() throws -> Int? {
        try setting(for: Self.usageSummaryResetsScannedKey).flatMap { Int($0) }
    }

    /// Reads the `seven_day_resets_at` of every snapshot recorded since the
    /// last scan into the phases, 500 snapshots at a time by `id`, so every
    /// account's reset is read whatever its value. The first scan (no saved
    /// id) reads every distinct value over the value index instead, then
    /// starts the id cursor at the newest snapshot that existed before it.
    /// Times before 2000 are "unknown" and skipped. Returns true when a phase
    /// appeared that the rows were not cut at; the backfill walk has then
    /// been restarted in the same transaction that saved the phase.
    @discardableResult
    func scanUsageResetPhases() throws -> Bool {
        guard try tableExists("rate_limit_snapshots") else { return false }
        let before = Set(try usageResetPhases())
        var phases = before
        let floor = Int(Self.claudeEarliestKnownEventTime)
        let startKnown = try usageResetsKnownThrough()
        var known = startKnown
        func see(_ value: Int) {
            guard value > floor else { return }
            phases.insert(value % Self.usageWeekSeconds)
            known = max(known ?? value, value)
        }
        let savedCursor = try setting(for: Self.usageSummaryResetsSnapshotKey).flatMap { Int($0) }
        var cursor = savedCursor ?? 0
        if savedCursor == nil {
            try query("SELECT COALESCE(MAX(id), 0) FROM rate_limit_snapshots") { row in cursor = self.int(row, 0) }
            var last = floor
            while true {
                var values: [Int] = []
                try query("""
                    SELECT DISTINCT seven_day_resets_at FROM rate_limit_snapshots
                    WHERE seven_day_resets_at > ? ORDER BY seven_day_resets_at LIMIT 500
                    """, params: [last]) { row in values.append(self.int(row, 0)) }
                values.forEach(see)
                if let value = values.last { last = value }
                if values.count < 500 { break }
            }
        }
        while true {
            var rows: [(id: Int, resets: Int)] = []
            try query("""
                SELECT id, seven_day_resets_at FROM rate_limit_snapshots WHERE id > ? ORDER BY id LIMIT 500
                """, params: [cursor]) { row in rows.append((self.int(row, 0), self.int(row, 1))) }
            for row in rows { see(row.resets) }
            if let last = rows.last { cursor = last.id }
            if rows.count < 500 { break }
        }
        // One commit: a new phase is saved only together with the backfill
        // restart that re-cuts the held days at it. Saved alone, a throw or
        // a kill before the restart would leave the next scan seeing nothing
        // new, and the held days would never be re-cut.
        try transaction {
            if phases != before {
                try setSetting(
                    Self.usageSummaryResetPhasesKey, phases.sorted().map(String.init).joined(separator: ","))
                try restartUsageSummaryBackfill()
            }
            if let known, known != startKnown {
                try setSetting(Self.usageSummaryResetsScannedKey, String(known))
            }
            if cursor != savedCursor {
                try setSetting(Self.usageSummaryResetsSnapshotKey, String(cursor))
            }
        }
        return phases != before
    }

    /// The starts of a UTC day's segments: the midnight, then every reset
    /// instant of `phases` that falls inside the day, ascending. A phase recurs
    /// weekly, so each adds at most one cut to a day.
    static func usageSegmentStarts(dayStart: Double, phases: [Int]) -> [Double] {
        let start = Int(dayStart)
        var starts: Set<Int> = [start]
        for phase in phases {
            let offset = ((phase - start) % usageWeekSeconds + usageWeekSeconds) % usageWeekSeconds
            if offset > 0 && offset < 86400 { starts.insert(start + offset) }
        }
        return starts.sorted().map(Double.init)
    }

    // MARK: - Writer

    /// Rebuilds one UTC day's `session_summary` and `usage_bursts` rows from
    /// events.db, one segment at a time (``usageSegmentStarts(dayStart:phases:)``):
    /// turn totals and cost from `turns`, event counts from `events`, bursts
    /// by ``sessionBursts(_:idleGap:)`` over the segment's turn times. The
    /// reads come first, from events.db; then one main-db transaction deletes
    /// the day's rows and inserts the new ones, so a rerun is idempotent.
    /// Returns whether it wrote.
    ///
    /// Two cases leave the day as it is. A day events.db holds no turns and no
    /// events for: once trimming has emptied a day, its summary is the only
    /// record. And any day whose new rows would hold fewer turns or tokens
    /// than the stored ones, with or without a watermark: trimming has taken
    /// part of it, or a history backfill has not replayed all of it yet, and
    /// the stored rows are the better record. (A correction that genuinely
    /// lowers a day's totals is kept out too; the raw backup still holds every
    /// line to rebuild from.)
    ///
    /// Only turns at or below the recount cursor (``usageSummaryTurnCursorKey``)
    /// are counted; a newer one is the recount's to add. And a day that starts
    /// before ``usageSummaryTrimmedBeforeKey`` is never rebuilt: the trim may
    /// have taken part of it. Both keep each turn counted exactly once.
    @discardableResult
    func refreshUsageSummary(forDay day: String) throws -> Bool {
        try refreshUsageSummary(forDay: day, throughTurnId: usageSummaryTurnCursor()) == .wrote
    }

    /// What ``refreshUsageSummary(forDay:throughTurnId:)`` did with a day.
    enum UsageSummaryRefresh: Equatable {
        /// The day's rows were rebuilt.
        case wrote
        /// The stored rows stay: events.db holds nothing of the day, or less of it.
        case kept
        /// The day starts before ``usageSummaryTrimmedBeforeKey``.
        case trimmed
    }

    /// ``refreshUsageSummary(forDay:)`` counting only turns with
    /// `id <= throughTurnId` (nil: every turn). `onWrite` runs inside the
    /// transaction that writes the rows, only when they are written.
    func refreshUsageSummary(
        forDay day: String, throughTurnId: Int64?, onWrite: (() throws -> Void)? = nil
    ) throws -> UsageSummaryRefresh {
        guard let dayStart = Self.utcDayStart(day) else { return .kept }
        if let trimmedBefore = try usageSummaryTrimmedBefore(), dayStart < trimmedBefore { return .trimmed }
        let dayEnd = dayStart + 86400
        let deadline = Self.maintenanceReadDeadline
        let starts = Self.usageSegmentStarts(dayStart: dayStart, phases: try usageResetPhases())

        struct Summary {
            var firstTime = Double.infinity
            var lastTime = -Double.infinity
            var turnCount = 0
            var eventCount = 0
            var inputTokens = 0
            var outputTokens = 0
            var cacheReadTokens = 0
            var cacheWriteTokens = 0
            var cost = 0.0
            var cwd = ""

            var tokens: Int { inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens }

            mutating func see(_ time: Double) {
                firstTime = min(firstTime, time)
                lastTime = max(lastTime, time)
            }
        }
        struct Key: Hashable, Comparable {
            let segmentStart: Double
            let sessionId: String
            static func < (lhs: Key, rhs: Key) -> Bool {
                (lhs.segmentStart, lhs.sessionId) < (rhs.segmentStart, rhs.sessionId)
            }
        }
        var summaries: [Key: Summary] = [:]
        var bursts: [SessionBurst] = []
        for (index, segmentStart) in starts.enumerated() {
            let segmentEnd = index + 1 < starts.count ? starts[index + 1] : dayEnd
            let totals = try claudeTurnTotals(
                since: segmentStart, until: segmentEnd, groupBy: .session, throughTurnId: throughTurnId,
                deadline: deadline)
            let times = try claudeTurnTimes(
                since: segmentStart, until: segmentEnd, sessionIds: nil, throughTurnId: throughTurnId,
                deadline: deadline)
            let events = try claudeSessionEventActivity(from: segmentStart, until: segmentEnd, deadline: deadline)
            for row in totals {
                let key = Key(segmentStart: segmentStart, sessionId: row.key)
                var summary = summaries[key] ?? Summary()
                summary.turnCount += row.turnCount
                summary.inputTokens += row.inputTokens
                summary.outputTokens += row.outputTokens
                summary.cacheReadTokens += row.cacheReadTokens
                summary.cacheWriteTokens += row.cacheCreationTokens
                summary.cost += TranscriptPricing.cost(
                    model: row.model, inputTokens: row.inputTokens, outputTokens: row.outputTokens,
                    cacheReadTokens: row.cacheReadTokens, cacheCreationTokens: row.cacheCreationTokens,
                    cacheCreation1hTokens: row.cacheCreation1hTokens)
                summaries[key] = summary
            }
            for turn in times {
                summaries[Key(segmentStart: segmentStart, sessionId: turn.sessionId), default: Summary()].see(turn.time)
            }
            for activity in events {
                let key = Key(segmentStart: segmentStart, sessionId: activity.sessionId)
                var summary = summaries[key] ?? Summary()
                summary.eventCount += activity.eventCount
                summary.see(activity.firstTime)
                summary.see(activity.lastTime)
                if !activity.cwd.isEmpty { summary.cwd = activity.cwd }
                summaries[key] = summary
            }
            bursts += Self.sessionBursts(times, idleGap: Self.usageBurstIdleGap)
        }
        guard !summaries.isEmpty else { return .kept }

        // Stored rows are never replaced by smaller ones, whatever the
        // watermark says: after a trim, or a cutover whose history backfill
        // has replayed only part of a day, events.db holds less of the day
        // than the rows already summarise, and the rows are then the only
        // complete record of it. Summed over the day's segments (legacy rows
        // are one whole-day segment, the walk splits a day at resets).
        //
        // While a history backfill is pending the check is per session, so a
        // session not replayed yet is not hidden by another that gained
        // turns. Otherwise it is the day's totals: a turn the store moved to
        // another session (its id seen again under a new one) must not keep
        // the old rows, and every later refresh of the day, for good.
        let perSession = claudeHistoryBackfillPending(deadline: deadline)
        do {
            var stored: [String: (turns: Int, tokens: Int)] = [:]
            try query("""
                SELECT session_id, COALESCE(SUM(turn_count), 0),
                       COALESCE(SUM(input_tokens + output_tokens + cache_read_tokens + cache_write_tokens), 0)
                FROM session_summary WHERE provider = ? AND day = ? GROUP BY session_id
                """, params: [ClaudeProvider.name, day]) { row in
                stored[self.string(row, 0)] = (self.int(row, 1), self.int(row, 2))
            }
            var held: [String: (turns: Int, tokens: Int)] = [:]
            for (key, summary) in summaries {
                let sum = held[key.sessionId] ?? (0, 0)
                held[key.sessionId] = (sum.turns + summary.turnCount, sum.tokens + summary.tokens)
            }
            if !perSession {
                func total(_ rows: [String: (turns: Int, tokens: Int)]) -> (turns: Int, tokens: Int) {
                    rows.values.reduce((0, 0)) { ($0.0 + $1.turns, $0.1 + $1.tokens) }
                }
                stored = ["": total(stored)]
                held = ["": total(held)]
            }
            for (sessionId, old) in stored {
                let new = held[sessionId] ?? (0, 0)
                if new.turns < old.turns || new.tokens < old.tokens {
                    let scope = sessionId.isEmpty ? "the day" : "session \(sessionId)"
                    Self.logger.info("""
                        Usage summary for \(day, privacy: .public) kept: \
                        \(scope, privacy: .public) holds \(new.turns) turn(s), \(old.turns) stored
                        """)
                    return .kept
                }
            }
        }

        // Main-db facts, second step: the session's account, and its cwd when
        // none of the day's events carried one.
        let ids = Set(summaries.keys.map(\.sessionId)).sorted()
        var accounts: [String: String] = [:]
        var sessionCwds: [String: String] = [:]
        for chunkStart in stride(from: 0, to: ids.count, by: 500) {
            let chunk = Array(ids[chunkStart..<min(chunkStart + 500, ids.count)])
            let marks = chunk.map { _ in "?" }.joined(separator: ",")
            try query("SELECT session_id, account_email, cwd FROM sessions WHERE session_id IN (\(marks))",
                      params: chunk) { row in
                let id = self.string(row, 0)
                accounts[id] = self.string(row, 1)
                sessionCwds[id] = self.string(row, 2)
            }
        }
        func nonEmpty(_ text: String?) -> String? { (text?.isEmpty ?? true) ? nil : text }
        // A session's project is the same in every segment: the last cwd its
        // day's events carried, else the session's own.
        var dayCwds: [String: String] = [:]
        for key in summaries.keys.sorted() {
            if let cwd = nonEmpty(summaries[key]?.cwd) { dayCwds[key.sessionId] = cwd }
        }

        let updatedAt = Date().timeIntervalSince1970
        var outcome = UsageSummaryRefresh.wrote
        try transaction {
            // A trim pass may have started since the check above; its cutoff
            // is recorded before it deletes anything.
            if let trimmedBefore = try usageSummaryTrimmedBefore(), dayStart < trimmedBefore {
                outcome = .trimmed
                return
            }
            try execute("DELETE FROM session_summary WHERE day = ?", params: [day])
            try execute("DELETE FROM usage_bursts WHERE day = ?", params: [day])
            for key in summaries.keys.sorted() {
                guard let summary = summaries[key] else { continue }
                let id = key.sessionId
                let cwd = dayCwds[id] ?? nonEmpty(sessionCwds[id])
                let project = cwd.map(Self.lastPathComponent).flatMap(nonEmpty)
                let first = summary.firstTime.isFinite ? summary.firstTime : key.segmentStart
                let last = summary.lastTime.isFinite ? summary.lastTime : first
                let params: [any Sendable] = [
                    ClaudeProvider.name, id, day, key.segmentStart, project, nonEmpty(accounts[id]),
                    first, last, summary.turnCount, summary.eventCount,
                    summary.inputTokens, summary.outputTokens, summary.cacheReadTokens, summary.cacheWriteTokens,
                    summary.cost, updatedAt
                ]
                try execute("""
                    INSERT INTO session_summary(
                        provider, session_id, day, segment_start, project, account, first_time, last_time,
                        turn_count, event_count, input_tokens, output_tokens,
                        cache_read_tokens, cache_write_tokens, cost_usd, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, params: params)
            }
            for burst in bursts {
                let account = nonEmpty(accounts[burst.sessionId])
                try execute("""
                    INSERT INTO usage_bursts(provider, session_id, account, start, end, day)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, params: [ClaudeProvider.name, burst.sessionId, account, burst.start, burst.end, day])
            }
            try onWrite?()
        }
        return outcome
    }

    /// Distinct UTC days holding an event or a turn in events.db, from `from`
    /// (nil = the beginning) through `through` inclusive, oldest first, at most
    /// `limit`. A transcript import lands turns on days no hook covers, so the
    /// summary walks both.
    func distinctActivityDays(from: String?, through: String, limit: Int? = nil) throws -> [String] {
        guard let last = Self.utcDayStart(through) else { return [] }
        var fromTime: Double?
        if let from {
            guard let start = Self.utcDayStart(from) else { return [] }
            fromTime = start
        }
        let until = last + 86400
        let deadline = Self.maintenanceReadDeadline
        let eventDays = try claudeEventDays(from: fromTime, until: until, limit: limit, deadline: deadline)
        let turnDays = try claudeTurnDays(from: fromTime, until: until, limit: limit, deadline: deadline)
        let union = Set(eventDays).union(turnDays).sorted()
        return limit.map { Array(union.prefix($0)) } ?? union
    }

    /// Summarises every day up to `finalizedDay` not yet walked, oldest first,
    /// moving the backfill marker and `usage_summary_finalized_through` after
    /// each day (crash-safe), and both to `finalizedDay` once the walk reaches
    /// it. At most `limit` days, and no new day once `budget` has passed; each
    /// read is bounded by `maintenanceReadDeadline`. Steady state, this is the
    /// rollup's newly frozen days getting their final refresh. Returns false
    /// when days remain, so `RollupTask` reschedules.
    ///
    /// A day is finalized only once its reset instants are known: when
    /// snapshots record resets but none at or after the day's end yet, a reset
    /// inside the day may still be unseen, so the walk waits there (returning
    /// true; the next run tries again). With no snapshot at all there is no
    /// quota week to cut at. The wait is bounded
    /// (``waitsForResetInstants(day:knownThrough:now:)``): once no snapshot
    /// has come for ``usageResetWaitLimit`` after the day ended, nothing will
    /// say more about it, and it is finalized with the phases known.
    func backfillUsageSummary(
        through finalizedDay: String, limit: Int, budget: Duration = .seconds(120), now: Date = Date()
    ) throws -> Bool {
        let marker = try usageSummaryBackfilledThrough()
        if let marker, marker >= finalizedDay {
            try advanceUsageSummaryWatermark(to: finalizedDay)
            return true
        }
        guard limit > 0 else { return false }
        let knownThrough = try usageResetsKnownThrough()
        let clock = ContinuousClock()
        let started = clock.now
        let days = try distinctActivityDays(
            from: marker.map(UTCDay.dayAfter), through: finalizedDay, limit: limit)
        for day in days {
            if Self.waitsForResetInstants(day: day, knownThrough: knownThrough, now: now) {
                Self.logger.debug("Usage summary waits at \(day, privacy: .public) for its reset instants")
                return true
            }
            try refreshUsageSummary(forDay: day)
            try setSetting(Self.usageSummaryBackfillMarkerKey, day)
            try advanceUsageSummaryWatermark(to: day)
            if clock.now - started > budget && day != days.last { return false }
        }
        if days.count == limit { return false }
        if Self.waitsForResetInstants(day: finalizedDay, knownThrough: knownThrough, now: now) { return true }
        try setSetting(Self.usageSummaryBackfillMarkerKey, finalizedDay)
        try advanceUsageSummaryWatermark(to: finalizedDay)
        return true
    }

    /// How long the walk waits, after a day ends, for a snapshot to say which
    /// resets fell in it. A snapshot reports the next reset of the account's
    /// week, so any snapshot taken in the week after the day settles it; past
    /// that, waiting longer only freezes the summary and, through it, the trim.
    static let usageResetWaitLimit: Double = 8 * 86400

    /// Whether the walk still waits for `day`'s reset instants: snapshots
    /// record resets (`knownThrough`), none at or after the day's end yet,
    /// and the day ended less than ``usageResetWaitLimit`` before `now`.
    static func waitsForResetInstants(day: String, knownThrough: Int?, now: Date) -> Bool {
        guard let knownThrough, let start = utcDayStart(day) else { return false }
        let end = start + 86400
        return Double(knownThrough) < end && now.timeIntervalSince1970 < end + usageResetWaitLimit
    }

    /// Whether the walk is waiting for the reset instants of the day after the
    /// last finalized one; the trim reports it as what it waits for.
    func usageSummaryWaitsForResetInstants(now: Date = Date()) throws -> Bool {
        guard let finalized = try usageSummaryFinalizedThrough() else { return false }
        return Self.waitsForResetInstants(
            day: UTCDay.dayAfter(finalized), knownThrough: try usageResetsKnownThrough(), now: now)
    }

    /// Starts the backfill walk over from the oldest day events.db holds, so
    /// every held day is cut again (a new reset phase appeared). The
    /// watermark stays, and a re-walked day keeps its stored rows whenever
    /// events.db holds less of it (``refreshUsageSummary(forDay:)``).
    func restartUsageSummaryBackfill() throws {
        try setSetting(Self.usageSummaryBackfillMarkerKey, "")
    }

    /// Restarts the backfill walk when ``TranscriptPricing/revision`` is not
    /// the one the stored rows were priced at
    /// (``usageSummaryPricingRevisionKey``), so every day events.db still
    /// holds is priced again at the new rates; the revision is recorded in the
    /// same commit. A day the trim has reached keeps the cost it was stored
    /// with: its rows hold no per-model tokens to price again. Returns whether
    /// it restarted.
    func restartUsageSummaryForPricingIfNeeded() throws -> Bool {
        let current = String(TranscriptPricing.revision)
        guard try setting(for: Self.usageSummaryPricingRevisionKey) != current else { return false }
        try transaction {
            try setSetting(Self.usageSummaryPricingRevisionKey, current)
            try restartUsageSummaryBackfill()
        }
        return true
    }

    /// Serializes ``recountLateUsageTurns(chunks:dayLimit:)``: `RollupTask`
    /// and the storage trim both run it, and two runs reading the same
    /// arrivals would add a trimmed day's late turns twice.
    private static let lateTurnRecountLock = NSLock()

    /// Brings finalized days up to date with turns that arrived after they
    /// were summarised (an import, captures held through a pipeline outage).
    /// Walks `turns.id` from the saved cursor, at most `chunks` reads of 500.
    ///
    /// - A turn a pending or finished history backfill replayed (its `raw_ref`
    ///   at or below `store_meta.replay_target_raw_id`) is skipped, whatever its
    ///   day: the converted summary already counts it. Re-checking its day
    ///   would re-read the whole day from `events.db` on every call while the
    ///   backfill fills it, which is what held the trim behind the backfill.
    /// - A finalized day the trim has not reached whose held turn count (up to
    ///   the new cursor) is above its stored count is refreshed, and the
    ///   rebuilt rows count its late turns.
    /// - Any other day's late turns are added to its rows
    ///   (``addLateUsageTurns(_:cursorFrom:to:)``): a day before
    ///   ``usageSummaryTrimmedBeforeKey`` (read again for each day, as a trim
    ///   pass may reach it meanwhile) cannot be rebuilt, and a day whose
    ///   stored rows count turns events.db no longer holds (part trimmed, or
    ///   not yet replayed) is kept as it is. The late turns are above the
    ///   saved cursor, so no stored row counts them yet.
    ///
    /// The cursor moves only after the refreshes, in the same transaction as
    /// the additions, so a crash re-reads the same arrivals and adds nothing
    /// twice. Returns false when arrivals remain.
    func recountLateUsageTurns(chunks: Int = 20, dayLimit: Int = 30) throws -> Bool {
        Self.lateTurnRecountLock.lock()
        defer { Self.lateTurnRecountLock.unlock() }
        let deadline = Self.maintenanceReadDeadline
        let maxId = try turnsHighWaterId(deadline: deadline)
        guard let saved = try usageSummaryTurnCursor() else {
            // First run: every turn held now is read by the summary walk itself.
            try setSetting(Self.usageSummaryTurnCursorKey, String(maxId))
            return true
        }
        // `maxId` is the largest id ever handed out, not the largest held:
        // `turns` is AUTOINCREMENT, so trimming the newest-id rows frees no
        // id, and every turn stored after the cursor was saved is above it.
        // Only an events.db rebuilt from the raw backup starts its ids again
        // below the cursor; then the walk starts at its current top.
        let start = min(saved, maxId)
        guard let finalized = try usageSummaryFinalizedThrough(),
              let liveFrom = Self.utcDayStart(UTCDay.dayAfter(finalized)) else {
            if maxId != saved { try setSetting(Self.usageSummaryTurnCursorKey, String(maxId)) }
            return true
        }
        let trimmedBefore = try usageSummaryTrimmedBefore()
        let replayTarget = try claudeHistoryBackfillTarget(deadline: deadline)
        // Rows an earlier pass rebuilt from this same cursor already count the
        // arrivals at or below each day's recorded id.
        var rebuilt = try recountRebuilt().flatMap { $0.from == saved ? $0 : nil }
            ?? RecountRebuilt(from: saved, days: [:])
        var cursor = start
        var byDay: [String: [ClaudeTurnArrival]] = [:]
        var late: [ClaudeTurnArrival] = []
        var caughtUp = false
        for _ in 0..<max(1, chunks) {
            let arrivals = try claudeTurnArrivals(afterId: cursor, limit: 500, deadline: deadline)
            for arrival in arrivals {
                guard let time = arrival.time, time < liveFrom else { continue }
                if let replayTarget, let rawRef = arrival.rawRef, rawRef <= replayTarget { continue }
                let dayStart = (time / 86400).rounded(.down) * 86400
                let day = UTCDay.string(from: Date(timeIntervalSince1970: dayStart))
                if let through = rebuilt.days[day], arrival.id <= through { continue }
                if let trimmedBefore, dayStart < trimmedBefore {
                    late.append(arrival)
                } else {
                    byDay[day, default: []].append(arrival)
                }
            }
            if let last = arrivals.last { cursor = last.id }
            if arrivals.count < 500 { caughtUp = true; break }
            if byDay.count >= dayLimit { break }
        }
        for day in byDay.keys.sorted() {
            guard let dayStart = Self.utcDayStart(day), let arrivals = byDay[day] else { continue }
            if let trimmedBefore = try usageSummaryTrimmedBefore(), dayStart < trimmedBefore {
                late += arrivals
                continue
            }
            var stored = 0
            try query("SELECT COALESCE(SUM(turn_count), 0) FROM session_summary WHERE provider = ? AND day = ?",
                      params: [ClaudeProvider.name, day]) { row in stored = self.int(row, 0) }
            let held = try claudeTurnTotals(
                since: dayStart, until: dayStart + 86400, groupBy: .all, throughTurnId: cursor, deadline: deadline)
                .reduce(0) { $0 + $1.turnCount }
            if held > stored {
                Self.logger.info("Usage summary re-reads \(day, privacy: .public): \(held - stored) late turn(s)")
                var record = rebuilt
                record.days[day] = cursor
                let outcome = try refreshUsageSummary(forDay: day, throughTurnId: cursor) {
                    try self.setSetting(Self.usageSummaryRecountRebuiltKey, Self.encodeRecountRebuilt(record))
                }
                if outcome == .wrote {
                    rebuilt = record
                    continue
                }
                Self.logger.info("""
                    Usage summary: \(day, privacy: .public) not rebuilt \
                    (\(String(describing: outcome), privacy: .public)); adding its late turns
                    """)
            }
            late += arrivals
        }
        try addLateUsageTurns(late, cursorFrom: saved, to: cursor)
        return caughtUp
    }

    /// Adds late turns to the rows of days that could not be rebuilt with
    /// them (``recountLateUsageTurns(chunks:dayLimit:)``), and moves
    /// the recount cursor from `saved` to `cursor`, in one transaction. Each
    /// turn goes into its (day, segment, session) row, a new row taking the
    /// session's account and project; its time becomes a burst of the session
    /// (merged into one it touches). `event_count` stays as it was: the
    /// turn's events are not counted.
    func addLateUsageTurns(_ turns: [ClaudeTurnArrival], cursorFrom saved: Int64, to cursor: Int64) throws {
        let phases = turns.isEmpty ? [] : try usageResetPhases()
        var sessions: [String: (account: String?, project: String?)] = [:]
        for sessionId in Set(turns.map(\.sessionId)) {
            try query("SELECT account_email, cwd FROM sessions WHERE session_id = ?", params: [sessionId]) { row in
                let account = self.string(row, 0)
                let project = Self.lastPathComponent(self.string(row, 1))
                sessions[sessionId] = (account.isEmpty ? nil : account, project.isEmpty ? nil : project)
            }
        }
        let updatedAt = Date().timeIntervalSince1970
        try transaction {
            if cursor != saved { try setSetting(Self.usageSummaryTurnCursorKey, String(cursor)) }
            try deleteSetting(Self.usageSummaryRecountRebuiltKey)
            for turn in turns {
                guard let time = turn.time else { continue }
                let dayStart = (time / 86400).rounded(.down) * 86400
                let day = UTCDay.string(from: Date(timeIntervalSince1970: dayStart))
                let segmentStart = Self.usageSegmentStarts(dayStart: dayStart, phases: phases)
                    .last { $0 <= time } ?? dayStart
                let info = sessions[turn.sessionId]
                let cost = TranscriptPricing.cost(
                    model: turn.model, inputTokens: turn.inputTokens, outputTokens: turn.outputTokens,
                    cacheReadTokens: turn.cacheReadTokens, cacheCreationTokens: turn.cacheCreationTokens,
                    cacheCreation1hTokens: turn.cacheCreation1hTokens)
                try execute("""
                    INSERT INTO session_summary(
                        provider, session_id, day, segment_start, project, account, first_time, last_time,
                        turn_count, event_count, input_tokens, output_tokens,
                        cache_read_tokens, cache_write_tokens, cost_usd, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 0, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(provider, session_id, day, segment_start) DO UPDATE SET
                        first_time = MIN(first_time, excluded.first_time),
                        last_time = MAX(last_time, excluded.last_time),
                        turn_count = turn_count + 1,
                        input_tokens = input_tokens + excluded.input_tokens,
                        output_tokens = output_tokens + excluded.output_tokens,
                        cache_read_tokens = cache_read_tokens + excluded.cache_read_tokens,
                        cache_write_tokens = cache_write_tokens + excluded.cache_write_tokens,
                        cost_usd = cost_usd + excluded.cost_usd,
                        updated_at = excluded.updated_at
                    """, params: [
                        ClaudeProvider.name, turn.sessionId, day, segmentStart, info?.project,
                        info?.account, time, time, turn.inputTokens, turn.outputTokens,
                        turn.cacheReadTokens, turn.cacheCreationTokens, cost, updatedAt
                    ])
                try addLateUsageBurst(sessionId: turn.sessionId, account: info?.account, time: time, day: day)
            }
        }
    }

    /// Puts `time` into the session's bursts on `day`: nothing when a burst
    /// already covers it, a burst within ``usageBurstIdleGap`` of it is
    /// stretched to reach it, else a zero-length burst. A stretch can leave
    /// two bursts that the burst rule would have joined; the readers merge
    /// them (``mergedSessionBursts(_:idleGap:)``).
    private func addLateUsageBurst(sessionId: String, account: String?, time: Double, day: String) throws {
        let gap = Self.usageBurstIdleGap
        var nearest: (start: Double, end: Double)?
        try query("""
            SELECT start, end FROM usage_bursts
            WHERE provider = ? AND session_id = ? AND day = ? AND start <= ? AND end >= ?
            ORDER BY MIN(ABS(start - ?), ABS(end - ?)) LIMIT 1
            """, params: [ClaudeProvider.name, sessionId, day, time + gap, time - gap, time, time]) { row in
            nearest = (self.double(row, 0), self.double(row, 1))
        }
        guard let nearest else {
            try execute("""
                INSERT OR IGNORE INTO usage_bursts(provider, session_id, account, start, end, day)
                VALUES (?, ?, ?, ?, ?, ?)
                """, params: [ClaudeProvider.name, sessionId, account, time, time, day])
            return
        }
        if time >= nearest.start && time <= nearest.end { return }
        if time > nearest.end {
            try execute("UPDATE usage_bursts SET end = ? WHERE provider = ? AND session_id = ? AND start = ?",
                        params: [time, ClaudeProvider.name, sessionId, nearest.start])
        } else {
            // The primary key holds `start`; another burst may already start at `time`.
            try execute("""
                UPDATE OR IGNORE usage_bursts SET start = ? WHERE provider = ? AND session_id = ? AND start = ?
                """, params: [time, ClaudeProvider.name, sessionId, nearest.start])
        }
    }

    /// True for a usage-summary read that ran out of time: a read ejected at
    /// its deadline (surfacing raw, or mapped to SQLITE_BUSY at the database
    /// boundary) or one that found the database busy. `RollupTask` retries
    /// those rather than failing the run.
    static func isUsageSummaryInterruption(_ error: Error) -> Bool {
        if error is BoundedDatabaseError { return true }
        if let error = error as? DaemonDatabaseError, let code = error.sqliteCode { return code & 0xFF == 5 }
        return false
    }

    // MARK: - Readers

    /// One piece of a Usage window and where its figures come from.
    enum UsageWindowPart: Equatable {
        /// events.db turns over `[since, until)`.
        case live(since: Double, until: Double)
        /// Whole summarised days, `first...last`.
        case summaryDays(first: String, last: String)
        /// The part of a summarised day in `[since, until)`, read from its
        /// segments when events.db no longer holds the day in full.
        case summarySegments(day: String, since: Double, until: Double)
    }

    /// Splits `[since, until)` at the summary watermark and at UTC midnights.
    /// Whole days at or before the watermark come from the summary. A partial
    /// edge day there is read live while events.db still holds every turn the
    /// summary counted for it, and from the summary's segments once trimming
    /// has taken them. A cut at a segment start divides the segments
    /// exactly. A cut inside one (a day stored whole, or cut before a reset
    /// phase that was found after the trim) splits that segment's rows by how
    /// much of each row's first-to-last span falls on either side, and clips
    /// its bursts at the cut. Everything after the watermark is live.
    func usageWindowParts(since: Double, until: Double) throws -> [UsageWindowPart] {
        guard until > since else { return [] }
        guard let finalized = try usageSummaryFinalizedThrough(),
              let liveFrom = Self.utcDayStart(UTCDay.dayAfter(finalized)) else {
            return [.live(since: since, until: until)]
        }
        var parts: [UsageWindowPart] = []
        let summaryEnd = min(until, liveFrom)
        var whole: (first: String, last: String)?
        func flushWhole() {
            if let run = whole { parts.append(.summaryDays(first: run.first, last: run.last)) }
            whole = nil
        }
        var dayStart = (since / 86400).rounded(.down) * 86400
        while dayStart < summaryEnd {
            let dayEnd = dayStart + 86400
            let low = max(since, dayStart)
            let high = min(summaryEnd, dayEnd)
            let day = UTCDay.string(from: Date(timeIntervalSince1970: dayStart))
            if low == dayStart && high == dayEnd {
                whole = (whole?.first ?? day, day)
            } else {
                flushWhole()
                parts.append(try eventStoreHoldsSummarisedTurns(day: day, start: dayStart)
                    ? .live(since: low, until: high)
                    : .summarySegments(day: day, since: low, until: high))
            }
            dayStart = dayEnd
        }
        flushWhole()
        if until > liveFrom {
            parts.append(.live(since: max(since, liveFrom), until: until))
        }
        return parts
    }

    /// The share of a summary row that falls in `[since, until)`: the part of
    /// its `first_time…last_time` span inside the range, as a fraction of the
    /// span. A row whose turns are one instant is wholly in or wholly out.
    static func usageRowShare(first: Double, last: Double, since: Double, until: Double) -> Double {
        guard last > first else { return first >= since && first < until ? 1 : 0 }
        let overlap = min(last, until) - max(first, since)
        return max(0, min(1, overlap / (last - first)))
    }

    /// True while events.db holds at least as many of `day`'s turns as its
    /// summary counted: nothing has been trimmed from it.
    private func eventStoreHoldsSummarisedTurns(day: String, start: Double) throws -> Bool {
        var summarised = 0
        try query("SELECT COALESCE(SUM(turn_count), 0) FROM session_summary WHERE provider = ? AND day = ?",
                  params: [ClaudeProvider.name, day]) { row in summarised = self.int(row, 0) }
        let held = try claudeTurnTotals(since: start, until: start + 86400, groupBy: .all)
            .reduce(0) { $0 + $1.turnCount }
        return held >= summarised
    }

    /// Tokens (input + output + cache read + cache write) and cost over the
    /// ISO-8601 window `[since, until)`, every account — the weekly rows'
    /// figures. A bound that does not parse covers nothing; an open bound reads
    /// events.db as `turnAggregates` does.
    func usageSummaryTotals(since: String, until: String) throws -> (tokens: Int, cost: Double) {
        guard let range = Self.usageRange(since: since, until: until) else { return (0, 0) }
        guard let low = range.since, let high = range.until else {
            let agg = try turnAggregates(since: since, until: until, groupBy: "all", account: nil, limit: 1).first
            return ((agg?.inputTokens ?? 0) + (agg?.outputTokens ?? 0) + (agg?.cacheReadTokens ?? 0)
                + (agg?.cacheCreationTokens ?? 0), agg?.totalCostUsd ?? 0)
        }
        var tokens = 0
        var cost = 0.0
        let sumSQL = """
            SELECT COALESCE(SUM(input_tokens + output_tokens + cache_read_tokens + cache_write_tokens), 0),
                   COALESCE(SUM(cost_usd), 0)
            FROM session_summary WHERE provider = ?
            """
        for part in try usageWindowParts(since: low, until: high) {
            switch part {
            case .live(let partSince, let partUntil):
                for row in try claudeTurnTotals(since: partSince, until: partUntil, groupBy: .all) {
                    tokens += row.inputTokens + row.outputTokens + row.cacheReadTokens + row.cacheCreationTokens
                    cost += TranscriptPricing.cost(
                        model: row.model, inputTokens: row.inputTokens, outputTokens: row.outputTokens,
                        cacheReadTokens: row.cacheReadTokens, cacheCreationTokens: row.cacheCreationTokens,
                        cacheCreation1hTokens: row.cacheCreation1hTokens)
                }
            case .summaryDays(let first, let last):
                try query(sumSQL + " AND day BETWEEN ? AND ?",
                          params: [ClaudeProvider.name, first, last]) { row in
                    tokens += self.int(row, 0)
                    cost += self.double(row, 1)
                }
            case .summarySegments(let day, let partSince, let partUntil):
                try query("""
                    SELECT input_tokens + output_tokens + cache_read_tokens + cache_write_tokens,
                           cost_usd, first_time, last_time
                    FROM session_summary
                    WHERE provider = ? AND day = ? AND first_time < ? AND last_time >= ?
                    """, params: [ClaudeProvider.name, day, partUntil, partSince]) { row in
                    let share = Self.usageRowShare(
                        first: self.double(row, 2), last: self.double(row, 3), since: partSince, until: partUntil)
                    tokens += Int((Double(self.int(row, 0)) * share).rounded())
                    cost += self.double(row, 1) * share
                }
            }
        }
        return (tokens, cost)
    }

    /// Active seconds two ways over the ISO-8601 window `[since, until)`, every
    /// account — ``hoursMetrics(since:until:account:idleThresholdS:)``'s
    /// figures from the summary: `active` sums each session's bursts,
    /// `wallClock` is their union. Bursts from summary days, segments and live
    /// slices are joined by ``mergedSessionBursts(_:idleGap:)``, so a window
    /// read across the pieces gives the bursts one walk over its turns would.
    func usageSummaryHours(since: String, until: String) throws -> (active: Double, wallClock: Double) {
        guard let range = Self.usageRange(since: since, until: until) else { return (0, 0) }
        guard let low = range.since, let high = range.until else {
            return try hoursMetrics(since: since, until: until, account: nil)
        }
        var bursts: [SessionBurst] = []
        func collect(_ sql: String, _ params: [any Sendable]) throws {
            try query("SELECT session_id, start, end FROM usage_bursts WHERE provider = ? AND " + sql,
                      params: [ClaudeProvider.name] + params) { row in
                bursts.append((
                    sessionId: self.string(row, 0), start: self.double(row, 1), end: self.double(row, 2)))
            }
        }
        for part in try usageWindowParts(since: low, until: high) {
            switch part {
            case .live(let partSince, let partUntil):
                bursts += Self.sessionBursts(
                    try claudeTurnTimes(since: partSince, until: partUntil, sessionIds: nil),
                    idleGap: Self.usageBurstIdleGap)
            case .summaryDays(let first, let last):
                try collect("day BETWEEN ? AND ?", [first, last])
            case .summarySegments(let day, let partSince, let partUntil):
                // A burst never crosses a segment start, but the part's
                // bounds need not be segment starts: clip at them.
                var dayBursts: [SessionBurst] = []
                swap(&bursts, &dayBursts)
                try collect("day = ? AND start < ? AND end >= ?", [day, partUntil, partSince])
                swap(&bursts, &dayBursts)
                bursts += dayBursts.compactMap { burst in
                    let start = max(burst.start, partSince)
                    let end = min(burst.end, partUntil)
                    guard start < partUntil, end >= start else { return nil }
                    return (sessionId: burst.sessionId, start: start, end: end)
                }
            }
        }
        let merged = Self.mergedSessionBursts(bursts, idleGap: Self.usageBurstIdleGap)
        let active = merged.reduce(0.0) { $0 + ($1.end - $1.start) }
        let wallClock = ActivityRuns.unionLength(merged.map { ActivityRuns.Span(start: $0.start, end: $0.end) })
        return (active, wallClock)
    }
}
#endif
