import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `session_summary` + `usage_bursts` (migration 051): the rollup keeps them,
/// Usage's weekly and hours rows read them, and the history they hold
/// survives trimming events.db's turns.
final class UsageSummaryTests: XCTestCase {

    private var tmpPath: String!
    private var database: DaemonDatabase!
    private var harness: ClaudePipelineTestHarness!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "usage-summary-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/usage-summary.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        harness = try ClaudePipelineTestHarness(besideDatabaseAt: tmpPath, database: database)
    }

    override func tearDownWithError() throws {
        harness = nil
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Fixture

    private static func stamp(_ epoch: Double) -> String {
        Date(timeIntervalSince1970: epoch).formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    /// Now, to the second (the fixture's arithmetic stays exact).
    private let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down))

    /// The quota week started 63 h ago: an instant nowhere near a UTC midnight
    /// in general, as Anthropic's reset is.
    private var weekStart: Double { now.timeIntervalSince1970 - 63 * 3600 }

    /// Minutes into a session at which it takes a turn: gaps of 25 and 20
    /// minutes split it into three bursts at the 15-minute idle gap.
    private static let turnMinutes: [Double] = [0, 5, 10, 15, 40, 45, 50, 70, 75, 80, 85, 90, 95, 100, 110, 120]

    /// About three weeks of sessions, one every 7 h from `weekStart − 479.5 h`
    /// (so they cross UTC midnights at shifting hours), each 2 h long, two
    /// models alternating; every third has a parallel session (the wall-clock
    /// figure differs from the session-hours one) and every fifth a lone turn
    /// an hour after it (a zero-length burst). No session crosses a window
    /// edge (`weekStart` − 336 h, − 168 h, − 105 h (now − 7 d), 0 h). A
    /// snapshot records the week's reset instant, as the status line does,
    /// so the summary cuts its rows there.
    private func seedHistory() throws {
        try recordReset()
        for index in 0..<78 {
            let start = weekStart + (-479.5 + 7 * Double(index)) * 3600
            let session = String(format: "s-%03d", index)
            let model = index.isMultiple(of: 2) ? "claude-opus-5" : "claude-sonnet-5"
            try harness.seed(sessionId: session, type: "SessionStart", timestamp: Self.stamp(start))
            for (step, minute) in Self.turnMinutes.enumerated() {
                try harness.seedTurn(
                    sessionId: session, timestamp: Self.stamp(start + minute * 60), model: model,
                    input: 100 + step, output: 1000 + index, cacheRead: 5000, cacheCreation: 200 + step)
            }
            if index.isMultiple(of: 3) {
                let parallel = "p-\(session)"
                for minute in [30.0, 40, 50, 60] {
                    try harness.seedTurn(
                        sessionId: parallel, timestamp: Self.stamp(start + minute * 60), model: "claude-sonnet-5",
                        input: 50, output: 400, cacheRead: 1000, cacheCreation: 10)
                }
            }
            if index.isMultiple(of: 5) {
                try harness.seedTurn(
                    sessionId: session, timestamp: Self.stamp(start + 3 * 3600), model: model,
                    input: 7, output: 70, cacheRead: 700, cacheCreation: 0)
            }
        }
    }

    /// A rate-limit snapshot whose 7-day reset is the end of this quota week.
    private func recordReset() throws {
        try database.execute(
            "INSERT INTO rate_limit_snapshots(timestamp, session_id, seven_day_resets_at) VALUES (?, ?, ?)",
            params: [Self.stamp(now.timeIntervalSince1970), "quota", Int(weekStart) + 7 * 86400])
    }

    /// A session taking a turn every 5 minutes from 20 minutes before `edge`
    /// to 30 minutes after it.
    private func seedSessionAcross(_ edge: Double, sessionId: String) throws {
        try harness.seed(sessionId: sessionId, type: "SessionStart", timestamp: Self.stamp(edge - 20 * 60))
        for (step, minute) in stride(from: -20.0, through: 30, by: 5).enumerated() {
            try harness.seedTurn(
                sessionId: sessionId, timestamp: Self.stamp(edge + minute * 60), model: "claude-opus-5",
                input: 10 + step, output: 100, cacheRead: 1000, cacheCreation: 20)
        }
    }

    /// The turn times `seedSessionAcross(edge)` writes.
    private func turnsAcross(_ edge: Double) -> [Double] {
        stride(from: -20.0, through: 30, by: 5).map { edge + $0 * 60 }
    }

    /// How many rows `turns` make when cut at `cuts`: one per run of turns
    /// between two cuts. A cut with no turn before the next one makes no row,
    /// so a cut that lands on another cut, or a few minutes after it, before
    /// the next turn, adds nothing.
    private func rowCount(_ turns: [Double], cutAt cuts: Set<Double>) -> Int {
        Set(turns.map { turn in cuts.filter { $0 <= turn }.count }).count
    }

    /// The UTC midnights inside `seedSessionAcross(edge)`'s session (rows are
    /// per UTC day, and `now` is the wall clock, so an edge can fall within
    /// half an hour of midnight, or on it).
    private func midnightsAcross(_ edge: Double) -> Set<Double> {
        let turns = turnsAcross(edge)
        return Set(turns.map { ($0 / 86400).rounded(.down) * 86400 }.filter { $0 > turns[0] })
    }

    /// `seedSessionAcross(edge)`'s rows once it is cut at the edge as well as
    /// at its midnights; and the row that starts at the edge,
    /// `"<edge>|<turns from the edge to the next cut>"`.
    private func expectedSegmentsAcross(_ edge: Double) -> (count: Int, atEdge: String) {
        let turns = turnsAcross(edge)
        let cuts = midnightsAcross(edge).union([edge])
        let next = cuts.filter { $0 > edge }.min() ?? .infinity
        let atEdge = turns.filter { $0 >= edge && $0 < next }.count
        return (rowCount(turns, cutAt: cuts), "\(edge)|\(atEdge)")
    }

    /// The UTC midnight a 7-day trim cuts at (Task 3's cutoff is day-aligned).
    private var sevenDayTrimCutoff: Double {
        ((now.timeIntervalSince1970 - 7 * 86400) / 86400).rounded(.down) * 86400
    }

    private func runRollupUntilSettled() async throws {
        let task = RollupTask(database: database, finalizeAfterDays: 2)
        for _ in 0..<20 {
            let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
            if try await task.execute(context: ctx).nextRunSeconds == nil { return }
        }
        XCTFail("the rollup never settled")
    }

    /// The weekly and hours rows as JSON, keys sorted: the bytes a client renders.
    private func rows(
        _ source: UsageHistorySource, weekStart: Double? = nil
    ) throws -> (week: String, hours: String) {
        try encode(try database.usageHistoryRows(weekStart: weekStart ?? self.weekStart, now: now, source: source))
    }

    /// The same rows from a second `DaemonDatabase` on the same files: the
    /// summary path memoizes past weeks per instance, so a comparison after
    /// a trim or a late turn has to read without that memo.
    private func freshRows(
        _ source: UsageHistorySource, weekStart: Double? = nil
    ) throws -> (week: String, hours: String) {
        let fresh = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        fresh.attachEventReads(harness.store, archive: harness.archive)
        return try encode(try fresh.usageHistoryRows(
            weekStart: weekStart ?? self.weekStart, now: now, source: source))
    }

    /// `session_summary` rows of `sessionId`.
    private func segmentCount(_ sessionId: String) throws -> Int {
        var count = 0
        try database.query("SELECT COUNT(*) FROM session_summary WHERE session_id = ?", params: [sessionId]) { row in
            count = self.database.int(row, 0)
        }
        return count
    }

    /// A snapshot recording `resetsAt` as `account`'s 7-day reset.
    private func recordReset(at resetsAt: Double, account: String) throws {
        try database.execute("""
            INSERT INTO rate_limit_snapshots(timestamp, session_id, account_email, seven_day_resets_at)
            VALUES (?, ?, ?, ?)
            """, params: [Self.stamp(now.timeIntervalSince1970), "quota-\(account)", account, Int(resetsAt)])
    }

    private func encode<Week: Encodable, Hours: Encodable>(
        _ rows: (weekRows: Week, hoursRows: Hours)
    ) throws -> (week: String, hours: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (String(bytes: try encoder.encode(rows.weekRows), encoding: .utf8) ?? "",
                String(bytes: try encoder.encode(rows.hoursRows), encoding: .utf8) ?? "")
    }

    /// Every row of `table`, `updated_at` left out.
    private func dump(_ table: String) throws -> [String] {
        var out: [String] = []
        let columns = table == "session_summary"
            ? "provider, session_id, day, segment_start, project, account, first_time, last_time, "
                + "turn_count, event_count, input_tokens, output_tokens, "
                + "cache_read_tokens, cache_write_tokens, cost_usd"
            : "provider, session_id, account, start, end, day"
        try database.query("SELECT \(columns) FROM \(table) ORDER BY 1, 2, 3, 4") { row in
            out.append(row.databaseValues.map(\.description).joined(separator: "|"))
        }
        return out
    }

    private func utcDay(_ epoch: Double) -> String {
        UTCDay.string(from: Date(timeIntervalSince1970: epoch))
    }

    /// Noon UTC on the day `days` before `now`. A late turn's three minutes
    /// then always fall on one day; `now` minus whole days put them across
    /// midnight whenever the suite ran in the ten minutes before 00:00 UTC.
    ///
    /// Moved on an hour at a time while a reset instant the fixtures record
    /// (`weekStart` a whole number of weeks off, or three hours after one)
    /// falls within its ten minutes: the summary cuts a day's rows at each
    /// reset, so a run starting just after 03:00 UTC put the noon turns ten
    /// days back into two segment rows.
    private func noon(daysAgo days: Double) -> Double {
        let week = 7.0 * 86400
        var time = ((now.timeIntervalSince1970 / 86400).rounded(.down) - days) * 86400 + 12 * 3600
        func crossesAReset(_ start: Double) -> Bool {
            [weekStart, weekStart + 3 * 3600].contains { reset in
                let ahead = ((reset - start).truncatingRemainder(dividingBy: week) + week)
                    .truncatingRemainder(dividingBy: week)
                return ahead > 0 && ahead <= 10 * 60
            }
        }
        while crossesAReset(time) { time += 3600 }
        return time
    }

    // MARK: - Same rows from the summary as from live turns

    /// A new reset phase is saved in the same commit as the backfill restart,
    /// so no failure between the two can leave the phase saved and the held
    /// days un-recut.
    func testANewResetPhaseRestartsTheBackfillWithTheSameScan() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        XCTAssertNotNil(try database.usageSummaryBackfilledThrough())

        try database.execute(
            "INSERT INTO rate_limit_snapshots(timestamp, session_id, seven_day_resets_at) VALUES (?, ?, ?)",
            params: [Self.stamp(now.timeIntervalSince1970), "quota", Int(weekStart) + 7 * 86400 + 3 * 3600])
        XCTAssertTrue(try database.scanUsageResetPhases())
        XCTAssertNil(try database.usageSummaryBackfilledThrough(), "the scan itself restarted the walk")
        XCTAssertFalse(try database.scanUsageResetPhases(), "nothing new the second time")
    }

    /// A pricing revision the stored rows were not priced at restarts the
    /// walk, so held days are priced again; the revision is saved with it.
    func testANewPricingRevisionRestartsTheBackfill() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        XCTAssertNotNil(try database.usageSummaryBackfilledThrough())
        XCTAssertEqual(
            try database.setting(for: DaemonDatabase.usageSummaryPricingRevisionKey),
            String(TranscriptPricing.revision), "the first run records the revision")

        try database.setSetting(DaemonDatabase.usageSummaryPricingRevisionKey, "0")
        XCTAssertTrue(try database.restartUsageSummaryForPricingIfNeeded())
        XCTAssertNil(try database.usageSummaryBackfilledThrough(), "the walk restarted")
        XCTAssertEqual(
            try database.setting(for: DaemonDatabase.usageSummaryPricingRevisionKey),
            String(TranscriptPricing.revision))
        XCTAssertFalse(try database.restartUsageSummaryForPricingIfNeeded(), "nothing new the second time")
    }

    func testSummaryPathGivesTheLiveTurnsRowsOverThreeWeeks() async throws {
        try seedHistory()
        // The old path first, before the summary exists.
        let live = try rows(.liveTurns)

        try await runRollupUntilSettled()
        let finalized = try XCTUnwrap(try database.rollupFinalizedThrough())
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), finalized)
        XCTAssertEqual(try database.usageSummaryBackfilledThrough(), finalized)
        XCTAssertFalse(try dump("session_summary").isEmpty)
        XCTAssertFalse(try dump("usage_bursts").isEmpty)

        // Last week really comes from the summary: whole summarised days.
        let lastWeek = try database.usageWindowParts(since: weekStart - 7 * 86400, until: weekStart)
        XCTAssertTrue(lastWeek.contains { if case .summaryDays = $0 { return true } else { return false } })
        // Rows are cut at the week's reset instant.
        XCTAssertEqual(try database.usageResetPhases(), [Int(weekStart) % (7 * 86400)])

        let summary = try rows(.summary)
        XCTAssertEqual(summary.week, live.week)
        XCTAssertEqual(summary.hours, live.hours)
        XCTAssertTrue(live.hours.contains("hrs last week"), live.hours)
        XCTAssertTrue(live.week.contains("last week"), live.week)
    }

    // MARK: - Trimming

    func testHistorySurvivesTrimmingEventStoreTurns() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let before = try rows(.summary)
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")
        let liveBefore = try rows(.liveTurns)

        let cutoff = sevenDayTrimCutoff
        let trimmed = try harness.store.trim(olderThan: cutoff, deadline: Date().addingTimeInterval(60))
        XCTAssertTrue(trimmed.finished)
        XCTAssertGreaterThan(trimmed.turns, 0)

        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        // A refresh of a day trimming emptied leaves its rows alone.
        let emptied = utcDay(cutoff - 3 * 86400)
        try database.refreshUsageSummary(forDay: emptied)
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        let after = try freshRows(.summary)
        XCTAssertEqual(after.hours, before.hours)
        XCTAssertEqual(after.week, before.week)
        // Without the summary the trimmed history would be gone.
        XCTAssertNotEqual(try rows(.liveTurns).hours, liveBefore.hours)
    }

    /// Review Focus 3 through the daemon's real pass (`StorageController.runPass`,
    /// the trim `TrimTask` and "Trim Now" run) at a 7-day history: the weekly
    /// and hours rows are the same before and after, and the same as live turns.
    func testWeeklyAndHoursRowsSurviveAFullSevenDayStoragePass() async throws {
        try seedHistory()
        let live = try rows(.liveTurns)
        try await runRollupUntilSettled()
        let before = try rows(.summary)
        XCTAssertEqual(before.week, live.week)
        XCTAssertEqual(before.hours, live.hours)

        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")
        try database.setSetting(StorageSettings.key, "7")
        let fixedNow = now
        let report = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: { fixedNow })
        XCTAssertNil(report.error)
        XCTAssertTrue(report.finished)
        XCTAssertNotNil(report.cutoff)
        XCTAssertGreaterThan(report.turns, 0, "the pass really trimmed turns")

        try await runRollupUntilSettled()
        let after = try freshRows(.summary)
        XCTAssertEqual(after.week, before.week)
        XCTAssertEqual(after.hours, before.hours)
    }

    /// Sessions running across last week's and the week before's starts (the
    /// reset instants) keep exact hours, tokens and cost after a 7-day trim:
    /// their rows are cut at the instant, so the window reads whole segments.
    func testSessionsAcrossResetInstantsStayExactAfterTrimming() async throws {
        try seedHistory()
        let lastStart = weekStart - 7 * 86400
        let prevStart = weekStart - 14 * 86400
        try seedSessionAcross(lastStart, sessionId: "edge-last")
        try seedSessionAcross(prevStart, sessionId: "edge-prev")
        let live = try rows(.liveTurns)

        try await runRollupUntilSettled()
        let untrimmed = try rows(.summary)
        XCTAssertEqual(untrimmed.week, live.week)
        XCTAssertEqual(untrimmed.hours, live.hours)
        for (session, edge) in [("edge-last", lastStart), ("edge-prev", prevStart)] {
            var segments: [String] = []
            try database.query("""
                SELECT segment_start, turn_count FROM session_summary WHERE session_id = ? ORDER BY segment_start
                """, params: [session]) { row in
                segments.append(row.databaseValues.map(\.description).joined(separator: "|"))
            }
            let expected = expectedSegmentsAcross(edge)
            XCTAssertEqual(segments.count, expected.count, session)
            XCTAssertTrue(segments.contains(expected.atEdge), "\(session): \(segments)")
        }
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")

        let trimmed = try harness.store.trim(olderThan: sevenDayTrimCutoff, deadline: Date().addingTimeInterval(60))
        XCTAssertTrue(trimmed.finished)
        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        // Both edge days are gone from events.db, so their partial windows
        // come from the summary's segments. An instant that is itself a UTC
        // midnight (`now` is the wall clock) leaves no partial day: the
        // window is whole summarised days.
        let lastWeek = try database.usageWindowParts(since: lastStart, until: weekStart)
        if lastStart.truncatingRemainder(dividingBy: 86400) == 0 {
            guard case .summaryDays(let first, _)? = lastWeek.first else {
                return XCTFail("whole days are read from the summary: \(lastWeek)")
            }
            XCTAssertEqual(first, utcDay(lastStart))
        } else {
            XCTAssertTrue(lastWeek.contains { if case .summarySegments = $0 { return true } else { return false } },
                          "\(lastWeek)")
        }
        let after = try freshRows(.summary)
        XCTAssertEqual(after.week, untrimmed.week)
        XCTAssertEqual(after.hours, untrimmed.hours)
    }

    /// A window cut inside a trimmed day's stored segment (a day kept whole,
    /// or a reset phase found after the trim) splits that segment's figures
    /// by time instead of giving all of them to the side its start is on.
    func testACutInsideAStoredSegmentSplitsItsFiguresByTime() throws {
        let dayStart = ((now.timeIntervalSince1970 - 20 * 86400) / 86400).rounded(.down) * 86400
        let day = utcDay(dayStart)
        try database.setSetting(DaemonDatabase.usageSummaryFinalizedKey, utcDay(dayStart + 86400))
        // One whole-day row whose turns run 10:00–14:00, and one burst over the same span.
        try database.execute("""
            INSERT INTO session_summary(
                provider, session_id, day, segment_start, project, account, first_time, last_time,
                turn_count, event_count, input_tokens, output_tokens,
                cache_read_tokens, cache_write_tokens, cost_usd, updated_at)
            VALUES ('claude', 'whole', ?, ?, NULL, NULL, ?, ?, 4, 0, 1000, 0, 0, 0, 4.0, 0)
            """, params: [day, dayStart, dayStart + 10 * 3600, dayStart + 14 * 3600])
        try database.execute("""
            INSERT INTO usage_bursts(provider, session_id, account, start, end, day)
            VALUES ('claude', 'whole', NULL, ?, ?, ?)
            """, params: [dayStart + 10 * 3600, dayStart + 14 * 3600, day])
        let cut = dayStart + 13 * 3600
        let before = try database.usageWindowParts(since: dayStart - 86400, until: cut)
        XCTAssertTrue(before.contains { if case .summarySegments = $0 { return true } else { return false } })

        let early = try database.usageSummaryTotals(since: Self.stamp(dayStart), until: Self.stamp(cut))
        let late = try database.usageSummaryTotals(since: Self.stamp(cut), until: Self.stamp(dayStart + 86400 - 1))
        XCTAssertEqual(early.tokens, 750)
        XCTAssertEqual(early.cost, 3.0, accuracy: 1e-9)
        XCTAssertEqual(late.tokens, 250)
        XCTAssertEqual(late.cost, 1.0, accuracy: 1e-9)

        let earlyHours = try database.usageSummaryHours(since: Self.stamp(dayStart), until: Self.stamp(cut))
        let lateHours = try database.usageSummaryHours(since: Self.stamp(cut), until: Self.stamp(dayStart + 86400 - 1))
        XCTAssertEqual(earlyHours.active, 3 * 3600, accuracy: 1e-6)
        XCTAssertEqual(lateHours.active, 3600, accuracy: 1e-6)
    }

    // MARK: - Late turns

    /// Turns that land on a day after it was finalized (an import) are
    /// counted on the next rollup.
    func testTurnsArrivingAfterADayIsFinalizedAreCounted() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let lateTime = noon(daysAgo: 4)
        let lateDay = utcDay(lateTime)
        XCTAssertLessThanOrEqual(lateDay, try XCTUnwrap(try database.usageSummaryFinalizedThrough()))

        for minute in [0.0, 5, 10] {
            try harness.seedTurn(
                sessionId: "late-import", timestamp: Self.stamp(lateTime + minute * 60), model: "claude-opus-5",
                input: 30, output: 300, cacheRead: 3000, cacheCreation: 30)
        }
        XCTAssertFalse(try dump("session_summary").contains { $0.contains("late-import") })

        try await runRollupUntilSettled()
        let lateRows = try dump("session_summary").filter { $0.contains("late-import") }
        XCTAssertEqual(lateRows.count, 1)
        XCTAssertTrue(lateRows.first?.contains("|3|0|90|900|9000|90|") ?? false, lateRows.first ?? "")
        let summary = try freshRows(.summary)
        let live = try rows(.liveTurns)
        XCTAssertEqual(summary.week, live.week)
        XCTAssertEqual(summary.hours, live.hours)
    }

    /// A late turn on a finalized day whose stored rows count more than
    /// events.db holds (part of it trimmed, or not yet replayed) cannot be
    /// counted by rebuilding the day, which keeps its rows; it is added to
    /// them instead of being passed over.
    func testALateTurnOnADayKeptAsStoredIsAdded() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let lateTime = noon(daysAgo: 4)
        let lateDay = utcDay(lateTime)
        try database.execute(
            "UPDATE session_summary SET turn_count = turn_count + 100 WHERE day = ?", params: [lateDay])
        let before = try dump("session_summary")

        for minute in [0.0, 5, 10] {
            try harness.seedTurn(
                sessionId: "late-kept", timestamp: Self.stamp(lateTime + minute * 60), model: "claude-opus-5",
                input: 30, output: 300, cacheRead: 3000, cacheCreation: 30)
        }
        try await runRollupUntilSettled()
        try await runRollupUntilSettled()

        let after = try dump("session_summary")
        let lateRows = after.filter { $0.contains("late-kept") }
        XCTAssertEqual(lateRows.count, 1, lateRows.joined(separator: "\n"))
        XCTAssertTrue(lateRows.first?.contains("|3|0|90|900|9000|90|") ?? false, lateRows.first ?? "")
        XCTAssertEqual(after.filter { !$0.contains("late-kept") }, before, "the kept rows stay as they were")
    }

    /// A recount pass that rebuilt a day with its late turns and stopped
    /// before moving its cursor (a crash) leaves a record of the day. The
    /// retry, finding the day trimmed meanwhile, adds none of those turns
    /// again, and clears the record when its cursor moves.
    func testARetriedRecountNeverAddsTurnsADayWasRebuiltWith() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let lateTime = noon(daysAgo: 4)
        let lateDay = utcDay(lateTime)
        for minute in [0.0, 5, 10] {
            try harness.seedTurn(
                sessionId: "late-crash", timestamp: Self.stamp(lateTime + minute * 60), model: "claude-opus-5",
                input: 30, output: 300, cacheRead: 3000, cacheCreation: 30)
        }
        let saved = try XCTUnwrap(try database.usageSummaryTurnCursor())
        let through = try database.turnsHighWaterId()
        let record = DaemonDatabase.RecountRebuilt(from: saved, days: [lateDay: through])
        let outcome = try database.refreshUsageSummary(forDay: lateDay, throughTurnId: through) {
            try self.database.setSetting(
                DaemonDatabase.usageSummaryRecountRebuiltKey, DaemonDatabase.encodeRecountRebuilt(record))
        }
        XCTAssertEqual(outcome, .wrote)
        XCTAssertEqual(try database.recountRebuilt(), record)
        // The trim reaches the day before the retry runs.
        let dayEnd = try XCTUnwrap(DaemonDatabase.utcDayStart(lateDay)) + 86400
        try database.setSetting(DaemonDatabase.usageSummaryTrimmedBeforeKey, String(dayEnd))

        XCTAssertTrue(try database.recountLateUsageTurns())
        let lateRows = try dump("session_summary").filter { $0.contains("late-crash") }
        XCTAssertEqual(lateRows.count, 1, lateRows.joined(separator: "\n"))
        XCTAssertTrue(lateRows.first?.contains("|3|0|90|900|9000|90|") ?? false, lateRows.first ?? "")
        XCTAssertNil(try database.recountRebuilt())
        XCTAssertEqual(try database.usageSummaryTurnCursor(), through)
    }

    /// Seeds history, settles the rollup, then runs the daemon's real 7-day
    /// storage pass, which records `usage_summary_trimmed_before`.
    private func settleAndTrimSevenDays() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        try database.execute("UPDATE sessions SET billing_derived_at = last_activity_at")
        try database.setSetting(StorageSettings.key, "7")
        let fixedNow = now
        let report = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: { fixedNow })
        XCTAssertNil(report.error)
        XCTAssertGreaterThan(report.turns, 0, "the pass really trimmed turns")
        XCTAssertEqual(try database.usageSummaryTrimmedBefore(), report.cutoff)
    }

    /// Three late turns ten days back, on a day the trim has reached.
    private func seedLateTurnsOnATrimmedDay(sessionId: String) throws -> String {
        let lateTime = noon(daysAgo: 10)
        XCTAssertLessThan(lateTime, try XCTUnwrap(try database.usageSummaryTrimmedBefore()))
        for minute in [0.0, 5, 10] {
            try harness.seedTurn(
                sessionId: sessionId, timestamp: Self.stamp(lateTime + minute * 60), model: "claude-opus-5",
                input: 30, output: 300, cacheRead: 3000, cacheCreation: 30)
        }
        return utcDay(lateTime)
    }

    /// A live turn landing on a day the trim has reached cannot be counted by
    /// rebuilding the day, so the recount adds it to the stored rows: once,
    /// however many rollups and storage passes run after it.
    func testALateTurnOnATrimmedDayIsAddedOnce() async throws {
        try await settleAndTrimSevenDays()
        let before = try dump("session_summary")
        let day = try seedLateTurnsOnATrimmedDay(sessionId: "late-trimmed")

        try await runRollupUntilSettled()
        try await runRollupUntilSettled()
        let fixedNow = now
        _ = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: { fixedNow })
        try await runRollupUntilSettled()

        let after = try dump("session_summary")
        let lateRows = after.filter { $0.contains("late-trimmed") }
        XCTAssertEqual(lateRows.count, 1, lateRows.joined(separator: "\n"))
        XCTAssertTrue(lateRows.first?.contains("|\"\(day)\"|") ?? false, lateRows.first ?? "")
        // Three turns, no events, the turns' tokens.
        XCTAssertTrue(lateRows.first?.contains("|3|0|90|900|9000|90|") ?? false, lateRows.first ?? "")
        XCTAssertEqual(after.filter { !$0.contains("late-trimmed") }, before)
        var bursts = 0
        try database.query("SELECT COUNT(*) FROM usage_bursts WHERE session_id = 'late-trimmed'") { row in
            bursts = self.database.int(row, 0)
        }
        XCTAssertEqual(bursts, 1, "turns 5 minutes apart make one burst")
    }

    /// Late turns on a trimmed day hold the newest ids; once counted, the
    /// next pass trims them, which leaves the largest held id below the
    /// recount cursor. Turns stored after that must still get ids above the
    /// cursor, or the recount skips them and the trim deletes them uncounted.
    func testALateTurnAfterTheNewestIdsWereTrimmedIsCounted() async throws {
        try await settleAndTrimSevenDays()
        _ = try seedLateTurnsOnATrimmedDay(sessionId: "late-first")
        try await runRollupUntilSettled()
        let cursor = try XCTUnwrap(try database.usageSummaryTurnCursor())
        let fixedNow = now
        let report = StorageController.runPass(
            database: database, eventStore: harness.store,
            deadline: Date().addingTimeInterval(StorageController.passSeconds), now: { fixedNow })
        XCTAssertNil(report.error)
        XCTAssertLessThan(try database.turnsMaxId(), cursor, "the pass trimmed the newest-id turns")

        let day = try seedLateTurnsOnATrimmedDay(sessionId: "late-second")
        XCTAssertGreaterThan(try database.turnsMaxId(), cursor, "a freed id is never handed out again")
        try await runRollupUntilSettled()
        let lateRows = try dump("session_summary").filter { $0.contains("late-second") }
        XCTAssertEqual(lateRows.count, 1, lateRows.joined(separator: "\n"))
        XCTAssertTrue(lateRows.first?.contains("|\"\(day)\"|") ?? false, lateRows.first ?? "")
        XCTAssertTrue(lateRows.first?.contains("|3|0|90|900|9000|90|") ?? false, lateRows.first ?? "")
    }

    /// A turn a history backfill replayed onto a trimmed day is already in the
    /// converted summary, so the recount does not add it again.
    func testAHistoryReplayTurnOnATrimmedDayIsSkipped() async throws {
        try await settleAndTrimSevenDays()
        let before = try dump("session_summary")
        _ = try seedLateTurnsOnATrimmedDay(sessionId: "replayed")
        // Every record seeded so far is at or below the replay target.
        try harness.store.setMetaValue("1000000", forKey: ClaudeArchiveReplay.backfillTargetKey)

        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary"), before)
    }

    /// A replayed turn on a finalized day the trim has not reached is skipped
    /// too: the converted summary counts it, and re-reading its day on every
    /// recount while the backfill fills that day is what kept the recount
    /// behind the backfill and the trim waiting.
    func testAHistoryReplayTurnOnAnUntrimmedFinalizedDayIsSkipped() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let before = try dump("session_summary")
        let lateTime = noon(daysAgo: 4)
        XCTAssertLessThanOrEqual(utcDay(lateTime), try XCTUnwrap(try database.usageSummaryFinalizedThrough()))
        XCTAssertNil(try database.usageSummaryTrimmedBefore())
        for minute in [0.0, 5, 10] {
            try harness.seedTurn(
                sessionId: "replayed-untrimmed", timestamp: Self.stamp(lateTime + minute * 60),
                model: "claude-opus-5", input: 30, output: 300, cacheRead: 3000, cacheCreation: 30)
        }
        try harness.store.setMetaValue("1000000", forKey: ClaudeArchiveReplay.backfillTargetKey)

        XCTAssertTrue(try database.recountLateUsageTurns())
        XCTAssertEqual(try database.usageSummaryTurnCursor(), try database.turnsMaxId())
        XCTAssertEqual(try dump("session_summary"), before)
    }

    /// A day before the trimmed-before mark is never rebuilt from events.db,
    /// and the mark never moves back.
    func testARefreshRefusesADayTheTrimHasReached() async throws {
        try await settleAndTrimSevenDays()
        let mark = try XCTUnwrap(try database.usageSummaryTrimmedBefore())
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")

        let trimmedDay = utcDay(mark - 86400)
        XCTAssertEqual(try database.refreshUsageSummary(forDay: trimmedDay, throughTurnId: nil), .trimmed)
        XCTAssertFalse(try database.refreshUsageSummary(forDay: trimmedDay))
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        try database.raiseUsageSummaryTrimmedBefore(mark - 5 * 86400)
        XCTAssertEqual(try database.usageSummaryTrimmedBefore(), mark)
    }

    /// The storage trim keeps a timed turn the recount has not read yet, so it
    /// is never deleted uncounted.
    func testTheTrimKeepsTurnsAboveTheRecountCursor() async throws {
        try await settleAndTrimSevenDays()
        let cursor = try XCTUnwrap(try database.usageSummaryTurnCursor())
        _ = try seedLateTurnsOnATrimmedDay(sessionId: "unread")

        // The trim alone, as a pass would run it if a turn landed after its
        // recount: bounded by the cursor read before the turn arrived.
        let cutoff = try XCTUnwrap(try database.usageSummaryTrimmedBefore())
        _ = try harness.store.trim(olderThan: cutoff, maxTurnId: cursor, deadline: Date().addingTimeInterval(60))
        let times = try database.claudeTurnTimes(
            since: cutoff - 30 * 86400, until: cutoff, sessionIds: ["unread"])
        XCTAssertEqual(times.count, 3)
        XCTAssertEqual(try database.claudeTurnTimes(
            since: cutoff - 30 * 86400, until: cutoff, sessionIds: ["unread"], throughTurnId: cursor).count, 0,
            "a read bounded by the cursor does not see turns above it")

        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary").filter { $0.contains("unread") }.count, 1)
    }

    // MARK: - Chunked backfill

    /// More than 30 days of history: the walk takes 30 days a run, resumes
    /// where it stopped and ends at the rollup's watermark with every day
    /// summarised.
    func testBackfillResumesAcrossChunksOverFortyDays() async throws {
        let firstDay = (now.timeIntervalSince1970 / 86400).rounded(.down) * 86400 - 45 * 86400
        var days: [String] = []
        for offset in 0..<40 {
            let time = firstDay + Double(offset) * 86400 + 12 * 3600
            let session = "day-\(offset)"
            try harness.seed(sessionId: session, type: "SessionStart", timestamp: Self.stamp(time))
            try harness.seedTurn(
                sessionId: session, timestamp: Self.stamp(time + 60), model: "claude-sonnet-5",
                input: 10, output: 100, cacheRead: 1000, cacheCreation: 10)
            days.append(utcDay(time))
        }

        let task = RollupTask(database: database, finalizeAfterDays: 2)
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        // Run 1 freezes 30 days of daily_metric; run 2 the rest, then the
        // summary's first 30 days.
        let first = try await task.execute(context: ctx)
        XCTAssertNotNil(first.nextRunSeconds)
        let second = try await task.execute(context: ctx)
        XCTAssertNotNil(second.nextRunSeconds)
        XCTAssertEqual(try database.usageSummaryBackfilledThrough(), days[29])
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), days[29])

        try await runRollupUntilSettled()
        let finalized = try XCTUnwrap(try database.rollupFinalizedThrough())
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), finalized)
        var summarised: [String] = []
        try database.query("SELECT DISTINCT day FROM session_summary ORDER BY day") { row in
            summarised.append(self.database.string(row, 0))
        }
        XCTAssertEqual(summarised, days)
    }

    // MARK: - Per-day rows

    func testSessionSpanningUTCMidnightGetsTwoRows() throws {
        let midnight = (now.timeIntervalSince1970 / 86400).rounded(.down) * 86400 - 5 * 86400
        for minutes in [-10.0, -5, 5, 10] {
            try harness.seedTurn(
                sessionId: "night", timestamp: Self.stamp(midnight + minutes * 60), model: "claude-opus-5",
                input: 10, output: 100)
        }
        try harness.seed(sessionId: "night", type: "Stop", timestamp: Self.stamp(midnight + 11 * 60))
        let before = utcDay(midnight - 1)
        let after = utcDay(midnight)
        try database.refreshUsageSummary(forDay: before)
        try database.refreshUsageSummary(forDay: after)

        var summary: [String] = []
        try database.query("""
            SELECT day, turn_count, event_count, input_tokens, first_time, last_time
            FROM session_summary WHERE session_id = 'night' ORDER BY day
            """) { row in summary.append(row.databaseValues.map(\.description).joined(separator: "|")) }
        XCTAssertEqual(summary, [
            "\"\(before)\"|2|0|20|\(midnight - 600)|\(midnight - 300)",
            "\"\(after)\"|2|1|20|\(midnight + 300)|\(midnight + 660)"
        ])
        XCTAssertEqual(try dump("usage_bursts").count, 2)

        // Read back across the midnight, the two halves are one 20-minute burst,
        // as the live walk counts it.
        try database.setSetting(DaemonDatabase.usageSummaryFinalizedKey, after)
        let since = Self.stamp(midnight - 3600)
        let until = Self.stamp(midnight + 3600)
        let summaryHours = try database.usageSummaryHours(since: since, until: until)
        let liveHours = try database.hoursMetrics(since: since, until: until)
        XCTAssertEqual(summaryHours.active, 1200)
        XCTAssertEqual(summaryHours.active, liveHours.active)
        XCTAssertEqual(summaryHours.wallClock, liveHours.wallClock)
    }

    // MARK: - Reset instants

    /// Two accounts with different 7-day resets. The second account's
    /// snapshot lands after the first's and carries the earlier reset: it is
    /// still read, the new phase re-cuts the held days, and that account's
    /// week edges stay exact after a 7-day trim.
    func testASecondAccountsEarlierResetIsCutAndStaysExactAfterTrimming() async throws {
        try seedHistory()   // account A's reset: weekStart + 7 d
        let weekStartB = weekStart - 30 * 3600
        try seedSessionAcross(weekStartB - 7 * 86400, sessionId: "b-last")
        try seedSessionAcross(weekStartB - 14 * 86400, sessionId: "b-prev")
        try await runRollupUntilSettled()
        let uncutLast = try segmentCount("b-last")
        let uncutPrev = try segmentCount("b-prev")

        try recordReset(at: weekStartB + 7 * 86400, account: "b@example.com")
        try await runRollupUntilSettled()
        let week = 7 * 86400
        XCTAssertEqual(Set(try database.usageResetPhases()), [Int(weekStart) % week, Int(weekStartB) % week])
        // The new phase restarted the walk: both held days are cut at B's instant.
        // That adds a row unless the instant is a midnight already cut, or no
        // turn lies between the midnight just before it and the instant.
        for (session, edge, uncut) in [("b-last", weekStartB - 7 * 86400, uncutLast),
                                       ("b-prev", weekStartB - 14 * 86400, uncutPrev)] {
            XCTAssertEqual(uncut, rowCount(turnsAcross(edge), cutAt: midnightsAcross(edge)), session)
            XCTAssertEqual(try segmentCount(session), expectedSegmentsAcross(edge).count, session)
        }

        let live = try rows(.liveTurns, weekStart: weekStartB)
        let untrimmed = try freshRows(.summary, weekStart: weekStartB)
        XCTAssertEqual(untrimmed.week, live.week)
        XCTAssertEqual(untrimmed.hours, live.hours)
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")

        let trimmed = try harness.store.trim(olderThan: sevenDayTrimCutoff, deadline: Date().addingTimeInterval(60))
        XCTAssertTrue(trimmed.finished)
        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)
        let after = try freshRows(.summary, weekStart: weekStartB)
        XCTAssertEqual(after.week, untrimmed.week)
        XCTAssertEqual(after.hours, untrimmed.hours)
    }

    /// A day is finalized only once a recorded reset lies at or after its
    /// end; when snapshots stop, the walk waits there and resumes once a
    /// later reset is recorded.
    func testTheWalkWaitsUntilADaysResetInstantsAreKnown() async throws {
        let today = (now.timeIntervalSince1970 / 86400).rounded(.down) * 86400
        for offset in 1...12 {
            let time = today - Double(offset) * 86400 + 12 * 3600
            try harness.seed(sessionId: "d-\(offset)", type: "SessionStart", timestamp: Self.stamp(time))
            try harness.seedTurn(
                sessionId: "d-\(offset)", timestamp: Self.stamp(time + 60), model: "claude-sonnet-5",
                input: 10, output: 100)
        }
        // The last reset recorded falls at 18:00 seven days ago.
        try recordReset(at: today - 7 * 86400 + 18 * 3600, account: "a@example.com")
        try await runRollupUntilSettled()
        let rollup = try XCTUnwrap(try database.rollupFinalizedThrough())
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), utcDay(today - 8 * 86400))
        XCTAssertLessThan(try XCTUnwrap(try database.usageSummaryFinalizedThrough()), rollup)
        XCTAssertTrue(try database.usageSummaryWaitsForResetInstants(now: now))

        try recordReset(at: now.timeIntervalSince1970 + 3 * 86400, account: "a@example.com")
        try await runRollupUntilSettled()
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), rollup)
    }

    /// No snapshot for `usageResetWaitLimit` after a day ends: the walk stops
    /// waiting and finalizes it with the resets it knows, so the summary (and
    /// the trim behind it) never freezes for good.
    func testTheWalkStopsWaitingForResetInstantsAfterTheLimit() async throws {
        let today = (now.timeIntervalSince1970 / 86400).rounded(.down) * 86400
        for offset in 1...12 {
            let time = today - Double(offset) * 86400 + 12 * 3600
            try harness.seed(sessionId: "d-\(offset)", type: "SessionStart", timestamp: Self.stamp(time))
            try harness.seedTurn(
                sessionId: "d-\(offset)", timestamp: Self.stamp(time + 60), model: "claude-sonnet-5",
                input: 10, output: 100)
        }
        try recordReset(at: today - 7 * 86400 + 18 * 3600, account: "a@example.com")
        try await runRollupUntilSettled()
        let rollup = try XCTUnwrap(try database.rollupFinalizedThrough())
        XCTAssertLessThan(try XCTUnwrap(try database.usageSummaryFinalizedThrough()), rollup)

        let later = now.addingTimeInterval(DaemonDatabase.usageResetWaitLimit + 86400)
        XCTAssertFalse(try database.usageSummaryWaitsForResetInstants(now: later))
        XCTAssertTrue(try database.backfillUsageSummary(through: rollup, limit: 100, now: later))
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), rollup)
    }

    // MARK: - Never lower

    /// A finalized day trimming has taken part of keeps its stored rows, and
    /// the watermark never moves back.
    func testARefreshNeverLowersAPartlyTrimmedDay() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let finalized = try XCTUnwrap(try database.usageSummaryFinalizedThrough())
        let dayStart = ((weekStart - 10 * 86400) / 86400).rounded(.down) * 86400
        let day = utcDay(dayStart)
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")

        // Half the day's turns go, as a trim partway through it would take them.
        let queue = try DatabaseQueue(path: harness.directory.appendingPathComponent(EventStore.fileName).path)
        let deleted = try await queue.write { conn -> Int in
            try conn.execute(sql: "DELETE FROM turns WHERE time >= ? AND time < ?",
                             arguments: [dayStart, dayStart + 43200])
            return conn.changesCount
        }
        XCTAssertGreaterThan(deleted, 0)

        XCTAssertFalse(try database.refreshUsageSummary(forDay: day))
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        try database.advanceUsageSummaryWatermark(to: utcDay(dayStart - 5 * 86400))
        XCTAssertEqual(try database.usageSummaryFinalizedThrough(), finalized)
    }

    /// A turn the store moves to another session (its message id seen again
    /// under a new one) leaves its first session with fewer turns. With no
    /// history backfill pending, the day's totals decide, so the day is
    /// rebuilt rather than kept as stored for good.
    func testATurnMovedToAnotherSessionStillRebuildsTheDay() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let dayStart = ((weekStart - 10 * 86400) / 86400).rounded(.down) * 86400
        let day = utcDay(dayStart)

        let queue = try DatabaseQueue(path: harness.directory.appendingPathComponent(EventStore.fileName).path)
        let moved = try await queue.write { conn -> Int in
            try conn.execute(sql: """
                UPDATE turns SET session_id = 'moved-session'
                WHERE id = (SELECT MIN(id) FROM turns WHERE time >= ? AND time < ?)
                """, arguments: [dayStart, dayStart + 86400])
            return conn.changesCount
        }
        XCTAssertEqual(moved, 1)

        XCTAssertTrue(try database.refreshUsageSummary(forDay: day))
        var count = 0
        try database.query(
            "SELECT COUNT(*) FROM session_summary WHERE day = ? AND session_id = 'moved-session'",
            params: [day]) { row in count = self.database.int(row, 0) }
        XCTAssertEqual(count, 1)
    }

    /// A `cutover --backfill`: the slim database keeps the legacy summary
    /// but every `usage_summary_*` setting is reset, and `events.db` holds
    /// only part of the old days so far. The walk that starts over must keep
    /// every stored day whose rows hold more than `events.db` does, though no
    /// watermark covers it, and catch it up once the rest is replayed.
    func testAWalkWithNoWatermarkNeverLowersAStoredDay() async throws {
        try seedHistory()
        try await runRollupUntilSettled()
        let summaryBefore = try dump("session_summary")
        let burstsBefore = try dump("usage_bursts")
        let liveBefore = try rows(.liveTurns)

        // The cutover's reset, and events.db missing half of two old days.
        try database.execute("DELETE FROM settings WHERE key LIKE 'usage\\_summary\\_%' ESCAPE '\\'")
        XCTAssertNil(try database.usageSummaryFinalizedThrough())
        // The cutover records the replay target: every record seeded so far
        // is at or below it, and the converted summary already counts them.
        try harness.store.setMetaValue("1000000", forKey: ClaudeArchiveReplay.backfillTargetKey)
        let queue = try DatabaseQueue(path: harness.directory.appendingPathComponent(EventStore.fileName).path)
        // Each removed turn as (column, value) pairs without its id: Row is not Sendable.
        var removed: [[(String, DatabaseValue)]] = []
        for daysBack in [10.0, 12] {
            let dayStart = ((weekStart - daysBack * 86400) / 86400).rounded(.down) * 86400
            removed += try await queue.write { conn -> [[(String, DatabaseValue)]] in
                let rows = try Row.fetchAll(
                    conn, sql: "SELECT * FROM turns WHERE time >= ? AND time < ?",
                    arguments: [dayStart, dayStart + 43200])
                try conn.execute(sql: "DELETE FROM turns WHERE time >= ? AND time < ?",
                                 arguments: [dayStart, dayStart + 43200])
                return rows.map { row in
                    row.columnNames.filter { $0 != "id" }.map { ($0, row[$0] as DatabaseValue) }
                }
            }
        }
        XCTAssertFalse(removed.isEmpty)
        let saved = removed

        try await runRollupUntilSettled()
        XCTAssertNotNil(try database.usageSummaryFinalizedThrough())
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        XCTAssertEqual(try dump("usage_bursts"), burstsBefore)

        // The backfill brings the rest back, as new rows. events.db now holds
        // exactly what is stored, so the days stay as stored and a fresh walk
        // matches the rows from before the reset.
        try await queue.write { conn in
            for row in saved {
                let columns = row.map(\.0).joined(separator: ", ")
                let marks = row.map { _ in "?" }.joined(separator: ", ")
                try conn.execute(
                    sql: "INSERT INTO turns (\(columns)) VALUES (\(marks))",
                    arguments: StatementArguments(row.map(\.1)))
            }
        }
        try await runRollupUntilSettled()
        XCTAssertEqual(try dump("session_summary"), summaryBefore)
        let after = try freshRows(.summary)
        XCTAssertEqual(after.week, liveBefore.week)
        XCTAssertEqual(after.hours, liveBefore.hours)
    }

    // MARK: - Deadline

    func testUsageSummaryInterruptionsAreDeadlinesAndBusy() {
        XCTAssertTrue(DaemonDatabase.isUsageSummaryInterruption(
            BoundedDatabaseError.deadlineExceeded(lane: "read", elapsedMs: 5)))
        XCTAssertTrue(DaemonDatabase.isUsageSummaryInterruption(
            DaemonDatabaseError.stepFailed(message: "busy", code: 5)))
        XCTAssertTrue(DaemonDatabase.isUsageSummaryInterruption(
            DaemonDatabaseError.stepFailed(message: "busy snapshot", code: 517)))
        XCTAssertFalse(DaemonDatabase.isUsageSummaryInterruption(
            DaemonDatabaseError.stepFailed(message: "corrupt", code: 11)))
        XCTAssertFalse(DaemonDatabase.isUsageSummaryInterruption(CocoaError(.fileNoSuchFile)))
    }

    /// A read that runs out of time reschedules with a growing delay, then
    /// falls back to the normal cadence; a run that completes clears the
    /// count, and any other error still fails the run.
    func testADeadlineInterruptionBacksOffThenFallsBackToTheNormalCadence() async throws {
        let started = Self.stamp(now.timeIntervalSince1970 - 3 * 86400)
        try harness.seed(sessionId: "s", type: "SessionStart", timestamp: started)
        var task = RollupTask(database: database, finalizeAfterDays: 2)
        let ctx = SessionTaskContext(taskName: task.name, consecutiveFailures: 0, runReason: .scheduled)
        task.usageSummaryUpdateOverride = { throw BoundedDatabaseError.deadlineExceeded(lane: "read", elapsedMs: 1) }
        var delays: [TimeInterval?] = []
        for _ in 0..<5 {
            let result = try await task.execute(context: ctx)
            delays.append(result.nextRunSeconds)
        }
        XCTAssertEqual(delays, [30, 120, 480, nil, 30])

        task.usageSummaryUpdateOverride = { true }
        let settled = try await task.execute(context: ctx)
        XCTAssertNil(settled.nextRunSeconds)
        XCTAssertEqual(try database.setting(for: RollupTask.interruptionCountKey), "")

        task.usageSummaryUpdateOverride = { throw DaemonDatabaseError.stepFailed(message: "corrupt", code: 11) }
        do {
            _ = try await task.execute(context: ctx)
            XCTFail("a non-deadline error must fail the run")
        } catch {}
    }

    // MARK: - Upgrading 1.4.41's table

    /// A `session_summary` of 1.4.41's shape (keyed by day, no
    /// `segment_start`) is upgraded on open: every row is kept as its day's
    /// one segment, and the walk restarts to re-cut the held days.
    func testA1441SessionSummaryIsUpgradedKeepingItsRows() throws {
        try make1441SessionSummary()
        try database.setSetting(DaemonDatabase.usageSummaryBackfillMarkerKey, "2026-10-02")

        let reopened = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertTrue(try reopened.tableHasColumn("session_summary", "segment_start"))
        var kept: [String] = []
        try reopened.query("""
            SELECT session_id, day, segment_start, project, account, first_time, last_time, turn_count,
                   event_count, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, cost_usd
            FROM session_summary ORDER BY session_id
            """) { row in kept.append(row.databaseValues.map(\.description).joined(separator: "|")) }
        XCTAssertEqual(kept, [
            "\"s1\"|\"2026-10-01\"|1790812800.0|NULL|NULL|1790820000.0|1790820600.0|3|1|10|20|30|40|0.5",
            "\"s2\"|\"2026-10-02\"|1790899200.0|\"app\"|\"a@example.com\"|1790900000.0|1790900100.0|2|0|1|2|3|4|0.25"
        ])
        XCTAssertNil(try reopened.usageSummaryBackfilledThrough())

        // The upgraded table takes a second segment of a day, and a second
        // ensure changes nothing.
        try reopened.execute("""
            INSERT INTO session_summary(provider, session_id, day, segment_start, first_time, last_time,
              turn_count, event_count, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens,
              cost_usd, updated_at)
            VALUES ('claude', 's1', '2026-10-01', 1790830000, 1790830000, 1790830000, 1, 0, 0, 0, 0, 0, 0, 1)
            """)
        try DaemonDatabase.ensureUsageSummaryTables(reopened)
        var count = 0
        try reopened.query("SELECT COUNT(*) FROM session_summary") { row in count = reopened.int(row, 0) }
        XCTAssertEqual(count, 3)
    }

    /// The names of `table`'s indexes, sorted.
    private func indexes(on table: String, in database: DaemonDatabase) throws -> [String] {
        var names: [String] = []
        try database.query(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = ? AND sql IS NOT NULL ORDER BY name",
            params: [table]) { row in names.append(database.string(row, 0)) }
        return names
    }

    /// Dropping 1.4.41's table drops its indexes with it; the upgrade must
    /// leave the new table indexed like a fresh one (B-2).
    func testTheUpgradedSessionSummaryHasItsIndexes() throws {
        try make1441SessionSummary()
        XCTAssertEqual(try indexes(on: "session_summary", in: database), [])

        let reopened = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertTrue(try reopened.tableHasColumn("session_summary", "segment_start"))
        XCTAssertEqual(try indexes(on: "session_summary", in: reopened),
                       ["session_summary_day", "session_summary_session"])
    }

    /// A copy whose count disagrees with the old table's rolls the whole
    /// upgrade back: the old table, its rows and the walk's marker stay as
    /// they were, and no half-built table is left behind (B-1).
    func testAnUpgradeWhoseCountsDisagreeRollsBack() throws {
        try make1441SessionSummary()
        try database.setSetting(DaemonDatabase.usageSummaryBackfillMarkerKey, "2026-10-02")

        XCTAssertThrowsError(try database.upgradeSessionSummarySegments(afterCopy: { held in
            try held.execute("DELETE FROM session_summary_segmented WHERE session_id = 's2'")
        }))

        XCTAssertFalse(try database.tableHasColumn("session_summary", "segment_start"))
        XCTAssertFalse(try database.tableExists("session_summary_segmented"))
        var count = 0
        try database.query("SELECT COUNT(*) FROM session_summary") { row in count = self.database.int(row, 0) }
        XCTAssertEqual(count, 2)
        XCTAssertEqual(try database.usageSummaryBackfilledThrough(), "2026-10-02")

        // The next ensure, with nothing in the way, completes it.
        try DaemonDatabase.ensureUsageSummaryTables(database)
        XCTAssertTrue(try database.tableHasColumn("session_summary", "segment_start"))
    }

    /// Replaces `session_summary` with 1.4.41's shape holding two rows.
    private func make1441SessionSummary() throws {
        try database.execute("DROP TABLE session_summary")
        try database.execute("""
            CREATE TABLE session_summary (
              provider TEXT NOT NULL, session_id TEXT NOT NULL, day TEXT NOT NULL,
              project TEXT, account TEXT,
              first_time REAL NOT NULL, last_time REAL NOT NULL,
              turn_count INTEGER NOT NULL, event_count INTEGER NOT NULL,
              input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
              cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
              cost_usd REAL NOT NULL, updated_at REAL NOT NULL,
              PRIMARY KEY (provider, session_id, day)) WITHOUT ROWID
            """)
        try database.execute("""
            INSERT INTO session_summary VALUES
              ('claude', 's1', '2026-10-01', NULL, NULL, 1790820000, 1790820600, 3, 1, 10, 20, 30, 40, 0.5, 1),
              ('claude', 's2', '2026-10-02', 'app', 'a@example.com', 1790900000, 1790900100, 2, 0, 1, 2, 3, 4, 0.25, 1)
            """)
    }

    // MARK: - sessions.started_at

    private func startedAt(_ sessionId: String) throws -> String? {
        var value: String?
        let database = self.database!
        try database.query("SELECT started_at FROM sessions WHERE session_id = ?", params: [sessionId]) { row in
            value = database.optionalString(row, 0)
        }
        return value
    }

    func testAnEarlierBatchLowersStartedAt() throws {
        try harness.ingest(ClaudePipelineTestHarness.event(
            "PreToolUse", sessionId: "late", timestamp: "2026-10-01T10:00:00Z",
            hookData: ["tool_name": "Bash", "tool_input": [String: Any]()]))
        XCTAssertEqual(try startedAt("late"), "2026-10-01 10:00:00")

        try harness.ingest(ClaudePipelineTestHarness.event(
            "UserPromptSubmit", sessionId: "late", timestamp: "2026-09-30T08:15:30Z",
            hookData: ["prompt": "hi"]))
        XCTAssertEqual(try startedAt("late"), "2026-09-30 08:15:30")
    }

    func testATimeZeroRowNeverBecomesStartedAt() throws {
        try harness.ingest(ClaudePipelineTestHarness.event(
            "PreToolUse", sessionId: "zero", timestamp: "2026-10-01T10:00:00Z",
            hookData: ["tool_name": "Bash", "tool_input": [String: Any]()]))
        try harness.ingest(ClaudePipelineTestHarness.event(
            "UserPromptSubmit", sessionId: "zero", timestamp: "1970-01-01T00:00:00Z",
            hookData: ["prompt": "hi"]))
        XCTAssertEqual(try startedAt("zero"), "2026-10-01 10:00:00")
    }
}
