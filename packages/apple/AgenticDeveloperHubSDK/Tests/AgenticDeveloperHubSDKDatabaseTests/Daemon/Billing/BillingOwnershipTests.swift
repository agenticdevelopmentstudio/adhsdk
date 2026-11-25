import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

// swiftlint:disable type_body_length file_length
/// The one ownership rule (Rulings 18 and 20): every second of a project's
/// union time bills exactly once, whatever the order of arrival, freeze,
/// unfreeze, edit, move, delete, re-derivation or backfill, and whichever
/// day each entry sits on. The scenario tests pin the cases reviews found by
/// hand; the seeded test walks hundreds of random orders through the real
/// derivation and rollup and checks the rule, minute by minute, after every
/// roll.
final class BillingOwnershipTests: XCTestCase {

    var tmpPath: String!
    var database: DaemonDatabase!

    override func setUpWithError() throws {
        let dir = NSTemporaryDirectory() + "billing-ownership-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        tmpPath = dir + "/billing-ownership.db"
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: (tmpPath as NSString).deletingLastPathComponent)
    }

    // MARK: - Helpers

    private static let day = "2026-09-22"
    private static let nextDay = "2026-09-23"
    private static let base = UTCTimestamp.epochSeconds("2026-09-22T09:00:00Z") ?? 0
    private let perRun = BillingRollupOptions(granularity: .run, defaultRateCents: 0, currency: "USD")
    private let perDay = BillingRollupOptions(granularity: .day, defaultRateCents: 0, currency: "USD")

    private func makeProject(rateCents: Int = 10_000) throws -> BillingProjectDTO {
        try BillingStore.saveProject(
            BillingProjectDTO(id: "", name: "P", defaultRateCents: rateCents), database: database
        )
    }

    /// A repo of `project` billing at its own rate.
    private func makeRepo(_ project: BillingProjectDTO, rateCents: Int) throws -> BillingRepoDTO {
        try BillingStore.saveRepo(
            BillingRepoDTO(id: "", projectId: project.id, projectRoot: "/src/fast", rateCents: rateCents),
            database: database
        )
    }

    /// Derives `sessionId` as `runs` (minutes from `base`, half-open) through
    /// the production path, returning the entries that held its segments
    /// before — what `BillingTask` would put in the recompute scope.
    @discardableResult
    private func derive(
        _ sessionId: String, runs: [(start: Int, end: Int)], project: BillingProjectDTO,
        repoId: String? = nil, base: Int = BillingOwnershipTests.base
    ) throws -> Set<String> {
        let touched = try database.billingEntryIds(forSessions: [sessionId])
        // An `app:` session derives from its span, and a session whose span
        // is gone writes nothing (re-review N7), so the span exists first.
        if let spanId = ActivitySpanSession.spanId(sessionId: sessionId) {
            try database.execute("""
                INSERT OR IGNORE INTO activity_span (id, bundle_id, app_name, started_at, tz)
                VALUES (?, 'com.apple.dt.Xcode', 'Xcode', ?, 'UTC')
            """, params: [spanId, UTCTimestamp.string(epochSeconds: base)])
        }
        try database.replaceDerivedSegments(
            sessionId: sessionId,
            runs: runs.map { run in
                BillingRun(
                    startedAt: UTCTimestamp.string(epochSeconds: base + run.start * 60),
                    endedAt: UTCTimestamp.string(epochSeconds: base + run.end * 60),
                    seconds: (run.end - run.start) * 60
                )
            },
            context: BillingSegmentContext(
                projectId: project.id, repoId: repoId, projectRoot: repoId == nil ? "/src/app" : "/src/fast",
                branch: "main", tz: "UTC", tracked: true
            ),
            historyStartsAt: nil
        )
        return touched
    }

    private static func app(_ span: String) -> String { ActivitySpanSession.sessionId(spanId: span) }

    /// Every entry row, the hidden zero-second ones included.
    private func entries() throws -> [BillingEntryDTO] {
        var ids: [String] = []
        try database.query("SELECT id FROM billing_entry ORDER BY day, created_at, id") { row in
            ids.append(row["id"] ?? "")
        }
        return try ids.compactMap { try database.billingEntry(id: $0) }
    }

    private func appEntry(day: String = BillingOwnershipTests.day) throws -> BillingEntryDTO? {
        try entries().first {
            BillingRollup.isAppGroupKey($0.groupKey) && $0.supplementsEntryId == nil && $0.day == day
        }
    }

    private func claudeEntry(_ sessionId: String) throws -> BillingEntryDTO? {
        try entries().first { $0.groupKey.hasPrefix(sessionId + "|") }
    }

    /// Entries made within one second tie on `created_at` and fall back to
    /// their random ids; a test that depends on which came first says so.
    private func backdate(_ entryId: String, to stamp: String) throws {
        try database.execute("UPDATE billing_entry SET created_at = ? WHERE id = ?", params: [stamp, entryId])
    }

    private func insertSession(_ sessionId: String, title: String, minute: Int) throws {
        let stamp = UTCTimestamp.string(epochSeconds: Self.base + minute * 60)
        try database.execute("""
            INSERT INTO sessions (session_id, cwd, started_at, last_activity_at, status, git_branch,
                                  project_root, summary)
            VALUES (?, '/src/app', ?, ?, 'ended', 'main', '/src/app', ?)
        """, params: [sessionId, stamp, stamp, title])
    }

    // MARK: - The per-minute oracle

    /// One entry as the oracle reads it: straight from the row, never through
    /// the production range helpers.
    private struct LedgerRow {
        let id: String
        let raw: Int
        let ranges: String?
        let frozen: Bool
        /// The entry a new supplement or heir would follow: the one this row
        /// supplements, else itself.
        let root: String
    }

    private func ledgerRows(projectId: String) throws -> [LedgerRow] {
        var rows: [LedgerRow] = []
        try database.query("""
            SELECT id, raw_seconds, billed_ranges, locked, origin, supplements_entry_id
            FROM billing_entry WHERE project_id = ?
        """, params: [projectId]) { row in
            let locked: Int = row["locked"] ?? 0
            let origin: String = row["origin"] ?? ""
            let id: String = row["id"] ?? ""
            let supplements: String? = row["supplements_entry_id"]
            rows.append(LedgerRow(
                id: id, raw: row["raw_seconds"] ?? 0, ranges: row["billed_ranges"],
                frozen: locked != 0 || origin == "user", root: supplements ?? id
            ))
        }
        return rows
    }

    /// For every minute a Claude-side (not app-focus) segment covers, the
    /// entries holding such a segment there. Read straight from the rows; a
    /// session is app time when it names a span.
    private func claudeHolders(projectId: String) throws -> [Int: Set<String>] {
        var holders: [Int: Set<String>] = [:]
        try database.query("""
            SELECT entry_id, session_id, started_at, seconds FROM billing_segment
            WHERE project_id = ? AND ended_at <> '' AND entry_id IS NOT NULL
        """, params: [projectId]) { row in
            let session: String = row["session_id"] ?? ""
            guard ActivitySpanSession.spanId(sessionId: session) == nil,
                  let epoch = UTCTimestamp.epochSeconds(row["started_at"] ?? "") else { return }
            let seconds: Int = row["seconds"] ?? 0
            let entry: String = row["entry_id"] ?? ""
            for minute in stride(from: epoch / 60, to: (epoch + seconds) / 60, by: 1) {
                holders[minute, default: []].insert(entry)
            }
        }
        return holders
    }

    /// `start-end;start-end` epoch pairs, parsed by hand.
    private static func pairs(_ text: String) -> [(start: Int, end: Int)]? {
        var result: [(start: Int, end: Int)] = []
        for pair in text.split(separator: ";") {
            let bounds = pair.split(separator: "-")
            guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]), end > start
            else { return nil }
            result.append((start, end))
        }
        return result
    }

    /// The minutes the project's closed segments cover, by absolute minute.
    private func unionMinutes(projectId: String) throws -> Set<Int> {
        var minutes: Set<Int> = []
        try database.query("""
            SELECT started_at, seconds FROM billing_segment WHERE project_id = ? AND ended_at <> ''
        """, params: [projectId]) { row in
            let start: String = row["started_at"] ?? ""
            let seconds: Int = row["seconds"] ?? 0
            guard let epoch = UTCTimestamp.epochSeconds(start) else { return }
            for minute in stride(from: epoch / 60, to: (epoch + seconds) / 60, by: 1) { minutes.insert(minute) }
        }
        return minutes
    }

    /// The rule, minute by minute: every minute of the union has exactly one
    /// owner, every other minute none, and each entry's `raw_seconds` is the
    /// measure of its own ranges, so the entries' raw seconds add up to the
    /// union. Every test minute is whole, so a minute is owned or not.
    ///
    /// **Ruling 19** — a frozen entry is invoiced history and is never
    /// rewritten. When the time it billed is later re-derived away (a frozen
    /// heir that inherited a reopened entry's overlap, say), it keeps billing
    /// it: phantom time, owned outside the union. That is accepted, and only
    /// that: a phantom minute must belong to exactly one frozen entry. The
    /// count is returned so a caller can see the case was reached.
    ///
    /// **Kind (Ruling 18)** — app time is the residual: a minute an unfrozen
    /// entry's Claude-side segment covers is never owned by an unfrozen entry
    /// with no Claude-side claim on it. An entry has a claim on a minute when
    /// it holds a Claude-side segment there, or shares its root with a frozen
    /// entry that does (it is that entry's heir or supplement).
    ///
    /// **Ruling 22** — the one exception: Claude-side time a *frozen* entry
    /// holds but gave away when it froze, now orphaned, goes to an open entry
    /// whose app span already covers it rather than to a new supplement. Such
    /// minutes are counted in `appOverOrphan`, as phantom minutes are.
    private func oracle(projectId: String) throws -> OracleResult {
        let rows = try ledgerRows(projectId: projectId)
        let union = try unionMinutes(projectId: projectId)
        let holders = try claudeHolders(projectId: projectId)
        let byId = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var owners: [Int: [LedgerRow]] = [:]
        for row in rows {
            guard let text = row.ranges else { return OracleResult(failure: "entry \(row.id) recorded no ranges") }
            guard let pairs = Self.pairs(text) else {
                return OracleResult(failure: "entry \(row.id) has bad ranges \(text)")
            }
            var seconds = 0
            for pair in pairs {
                guard pair.start % 60 == 0, pair.end % 60 == 0 else {
                    return OracleResult(failure: "entry \(row.id) owns a part minute: \(text)")
                }
                seconds += pair.end - pair.start
                for minute in (pair.start / 60)..<(pair.end / 60) { owners[minute, default: []].append(row) }
            }
            if row.raw != seconds {
                return OracleResult(failure: "entry \(row.id) raw_seconds \(row.raw) != its ranges' \(seconds)")
            }
        }
        var result = OracleResult()
        for minute in Set(owners.keys).union(union).sorted() {
            let owning = owners[minute] ?? []
            let stamp = UTCTimestamp.string(epochSeconds: minute * 60)
            if union.contains(minute) {
                guard owning.count == 1 else {
                    result.failure = "\(stamp) has \(owning.count) owners"
                    return result
                }
                let owner = owning[0]
                let holding = (holders[minute] ?? []).compactMap { byId[$0] }
                let claims = holding.contains { $0.id == owner.id || ($0.frozen && $0.root == owner.root) }
                guard !owner.frozen, !claims, !holding.isEmpty else { continue }
                if holding.contains(where: { !$0.frozen }) {
                    result.failure = "\(stamp) is Claude time of an open entry, owned by \(owner.id) with no claim"
                    return result
                }
                result.appOverOrphan += 1
                result.ruling22Minutes.insert(minute)
            } else if !owning.isEmpty {
                guard owning.count == 1, owning[0].frozen else {
                    result.failure = "\(stamp) is in no segment yet owned by \(owning.count), not one frozen entry"
                    return result
                }
                result.phantom += 1
            }
        }
        let total = rows.reduce(0) { $0 + $1.raw }
        if total != (union.count + result.phantom) * 60 {
            result.failure = "raw seconds total \(total) != union \(union.count * 60) + phantom \(result.phantom * 60)"
        }
        return result
    }

    private struct OracleResult {
        var failure: String?
        /// Minutes a frozen entry owns outside every segment (Ruling 19).
        var phantom = 0
        /// Orphaned Claude-side minutes an open app claim owns (Ruling 22).
        var appOverOrphan = 0
        /// The minutes counted in `appOverOrphan`.
        var ruling22Minutes: Set<Int> = []
    }

    private func assertBilledOnce(
        _ project: BillingProjectDTO, appOverOrphan: Int = 0, file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let result = try oracle(projectId: project.id)
        XCTAssertNil(result.failure, file: file, line: line)
        XCTAssertEqual(result.phantom, 0, "no phantom time", file: file, line: line)
        XCTAssertEqual(result.appOverOrphan, appOverOrphan, "Ruling 22 minutes", file: file, line: line)
    }

    // MARK: - Scenarios

    /// I1: A billed 09:15–09:45; a Claude run 09:00–09:30 arrives and bills
    /// only 09:00–09:15; the run is billed, then A reopened. A owns its whole
    /// segment again — the 15 minutes C never billed must not fall through.
    func testReopeningAnAppEntryAfterTheClaudeRunFroze() throws {
        let project = try makeProject()
        try derive(Self.app("x"), runs: [(15, 45)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(appEntry())
        _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)

        try derive("claude", runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let claude = try XCTUnwrap(claudeEntry("claude"))
        XCTAssertEqual(claude.rawSeconds, 900)
        _ = try BillingRollup.setStatus(entryId: claude.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: app.id, to: .unbilled, source: "user", database: database)

        XCTAssertEqual(try database.billingEntry(id: app.id)?.rawSeconds, 1800)
        XCTAssertEqual(try entries().map(\.rawSeconds).reduce(0, +), 2700)
        // 09:15–09:30: the frozen run covers it but never owned it (Ruling 22).
        try assertBilledOnce(project, appOverOrphan: 15)
    }

    /// I2: A billed only 09:30–09:45, giving 09:15–09:30 to a Claude run that
    /// then moves to 09:00–09:10. The orphaned quarter hour goes to a
    /// supplement of A, because A itself is history.
    func testTimeAFrozenAppEntryGaveAwayComesBackWhenTheRunMoves() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        try derive(Self.app("x"), runs: [(15, 45)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(appEntry())
        XCTAssertEqual(app.rawSeconds, 900)
        _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)

        let touched = try derive("claude", runs: [(0, 10)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)

        XCTAssertEqual(try database.billingEntry(id: app.id)?.rawSeconds, 900, "billed: never touched")
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == app.id })
        XCTAssertEqual(supplement.rawSeconds, 900, "09:15–09:30")
        XCTAssertEqual(supplement.startedAt, "2026-09-22T09:15:00Z")
        XCTAssertEqual(supplement.endedAt, "2026-09-22T09:30:00Z")
        XCTAssertEqual(try entries().map(\.rawSeconds).reduce(0, +), 2400, "09:00–09:10 and 09:15–09:45")
        try assertBilledOnce(project)
    }

    /// M1: a pass whose Claude re-derivation leaves the run exactly as it was
    /// still settles the day, so app time the same pass uncovered reaches the
    /// app entry.
    func testAnUnchangedClaudeRecomputeStillLetsUncoveredAppTimeBill() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        try derive(Self.app("x"), runs: [(10, 20)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try appEntry()?.rawSeconds, 0)
        let claude = try XCTUnwrap(claudeEntry("claude"))

        var touched = try derive("claude", runs: [(0, 30)], project: project)
        touched.formUnion(try derive(Self.app("x"), runs: [(10, 20), (40, 50)], project: project))
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)

        XCTAssertEqual(try database.billingEntry(id: claude.id)?.rawSeconds, 1800, "unchanged")
        XCTAssertEqual(try appEntry()?.rawSeconds, 600, "09:40–09:50, which no run covers")
        try assertBilledOnce(project)
    }

    /// M2: an entry whose description the user wrote is never removed, and
    /// keeps the words, even once it owns no time and holds no segment.
    func testAnEntryWithAHandWrittenDescriptionSurvivesLosingAllItsTime() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let claude = try XCTUnwrap(claudeEntry("claude"))
        _ = try BillingRollup.setDescription(entryId: claude.id, description: "Kickoff call", database: database)

        let touched = try derive("claude", runs: [], project: project)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)

        let kept = try XCTUnwrap(database.billingEntry(id: claude.id))
        XCTAssertEqual(kept.description, "Kickoff call")
        XCTAssertEqual(kept.rawSeconds, 0)
        // Review 5, item 3: kept *and listed* — words the user cannot find
        // are words they cannot edit or delete.
        let listed = try database.billingEntries(projectId: nil, status: nil, since: "")
        XCTAssertTrue(listed.contains { $0.id == claude.id }, "the hand-described entry is listed")
    }

    /// Without the hand-written words the same entry goes.
    func testAnEmptyEntryWithoutEditedWordsIsRemoved() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let claude = try XCTUnwrap(claudeEntry("claude"))

        let touched = try derive("claude", runs: [], project: project)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)
        XCTAssertNil(try database.billingEntry(id: claude.id))
    }

    /// Deleting a hand-edited entry frees what it owned for the entries
    /// beside it, and its segments re-roll.
    func testDeletingAUserEditedAppEntryHandsItsTimeBack() throws {
        let project = try makeProject()
        try derive(Self.app("x"), runs: [(15, 45)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(appEntry())
        _ = try BillingRollup.saveEntry(edited(app), database: database)

        try derive("claude", runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 900, "the edited entry keeps 09:15–09:45")

        try BillingRollup.deleteEntry(id: app.id, database: database)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 1800)
        XCTAssertEqual(try appEntry()?.rawSeconds, 900)
        try assertBilledOnce(project)
    }

    /// Review 4, item 1: a run moved to another day by hand is frozen there
    /// with the time it owned, and its first day must still count that time
    /// as taken — the day column says where an entry is listed, not when its
    /// time happened.
    func testMovingARunToAnotherDayDoesNotFreeItsTimeOnTheFirstDay() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 60)], project: project)
        try derive(Self.app("x"), runs: [(30, 90)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try appEntry()?.rawSeconds, 1800, "10:00–10:30")
        let claude = try XCTUnwrap(claudeEntry("claude"))

        _ = try BillingRollup.saveEntry(moved(claude, to: Self.nextDay), database: database)
        _ = try BillingRollup.run(options: perRun, database: database)

        XCTAssertEqual(try database.billingEntry(id: claude.id)?.day, Self.nextDay)
        XCTAssertEqual(try appEntry()?.rawSeconds, 1800, "09:30–10:00 is still the moved run's")
        try assertBilledOnce(project)
    }

    /// Review 4, item 2: at day granularity Claude and app time share an
    /// entry per rate, and the app half of every entry is still the residual —
    /// Slack at 150 rolled before a Claude run at 200 gives the overlap up.
    func testAtDayGranularityAppTimeYieldsToClaudeTimeAtAnotherRate() throws {
        let project = try makeProject(rateCents: 15_000)
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive(Self.app("slack"), runs: [(0, 60)], project: project)
        _ = try BillingRollup.run(options: perDay, database: database)
        try backdate(try XCTUnwrap(entries().first).id, to: "2026-09-22T10:00:00Z")
        try derive("claude", runs: [(30, 90)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perDay, database: database)

        let all = try entries()
        XCTAssertEqual(all.first { $0.rateCents == 20_000 }?.rawSeconds, 3600, "the Claude run, whole")
        XCTAssertEqual(all.first { $0.rateCents == 15_000 }?.rawSeconds, 1800, "09:00–09:30 only")
        try assertBilledOnce(project)
    }

    /// Review 4, item 3: a run that starts before midnight belongs to its
    /// first day, and the app time it covers after midnight on the next day
    /// is not billed again — whichever of the two rolled first.
    func testARunAcrossMidnightIsNotBilledAgainByTheNextDaysAppTime() throws {
        for claudeFirst in [true, false] {
            database = nil
            try? FileManager.default.removeItem(atPath: tmpPath)
            database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
            let project = try makeProject()
            // 23:30–00:30 and 00:10–00:20, in minutes from 09:00.
            let derivations: [() throws -> Void] = [
                { try self.derive("claude", runs: [(870, 930)], project: project) },
                { try self.derive(Self.app("x"), runs: [(910, 920)], project: project) }
            ]
            for derivation in claudeFirst ? derivations : derivations.reversed() {
                try derivation()
                _ = try BillingRollup.run(options: perRun, database: database)
            }
            XCTAssertEqual(try claudeEntry("claude")?.day, Self.day)
            XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 3600)
            XCTAssertEqual(try appEntry(day: Self.nextDay)?.rawSeconds, 0, "claude first: \(claudeFirst)")
            try assertBilledOnce(project)
        }
    }

    /// Review 4, item 5: an auto entry left owning nothing is kept (it may be
    /// what a later recompute fills again) but is not a $0 row in the list
    /// or a count in the overview.
    func testAZeroSecondAutoEntryIsKeptButNotListed() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        try derive(Self.app("x"), runs: [(10, 20)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let app = try XCTUnwrap(appEntry())
        XCTAssertEqual(app.rawSeconds, 0)

        let listed = try database.billingEntries(projectId: nil, status: nil, since: "")
        XCTAssertEqual(listed.map(\.id), [try XCTUnwrap(claudeEntry("claude")).id])
        XCTAssertEqual(try BillingRollup.overview(database: database).unbilled.entryCount, 1)
        XCTAssertNotNil(try database.billingEntry(id: app.id), "the row is kept")
    }

    /// Review 4, item 8: an heir that inherits a frozen supplement's orphaned
    /// time spans that time, and describes only the segment it came from —
    /// not every segment of the frozen entry.
    func testAnHeirSpansAndDescribesOnlyTheOrphanedTime() throws {
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        try insertSession("x", title: "Title X", minute: 0)
        try insertSession("y", title: "Title Y", minute: 60)
        try insertSession("z", title: "Title Z", minute: 80)
        try insertSession("w", title: "Title W", minute: 55)

        try derive("x", runs: [(0, 10)], project: project)
        _ = try BillingRollup.run(options: perDay, database: database)
        let root = try XCTUnwrap(entries().first)
        try backdate(root.id, to: "2026-09-22T10:00:00Z")
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)

        try derive("w", runs: [(55, 65)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perDay, database: database)
        try backdate(try XCTUnwrap(entries().first { $0.rateCents == 20_000 }).id, to: "2026-09-22T11:00:00Z")
        try derive("y", runs: [(60, 70)], project: project)
        try derive("z", runs: [(80, 90)], project: project)
        _ = try BillingRollup.run(options: perDay, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id })
        XCTAssertEqual(supplement.rawSeconds, 900, "10:05–10:10 and 10:20–10:30")
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: root.id, to: .unbilled, source: "user", database: database)

        let touched = try derive("w", runs: [], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perDay, database: database, recomputing: touched)

        let heir = try XCTUnwrap(database.billingEntry(id: root.id))
        XCTAssertEqual(heir.rawSeconds, 900, "09:00–09:10 and the orphaned 10:00–10:05")
        XCTAssertEqual(heir.startedAt, "2026-09-22T09:00:00Z")
        XCTAssertEqual(heir.endedAt, "2026-09-22T10:05:00Z", "the orphan time it owns")
        XCTAssertTrue(heir.description.contains("Title Y"), heir.description)
        XCTAssertFalse(heir.description.contains("Title Z"), heir.description)
        try assertBilledOnce(project)
    }

    /// A clean database for each variant of a looping scenario.
    private func freshDatabase() throws {
        database = nil
        try? FileManager.default.removeItem(atPath: tmpPath)
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    /// Review 5, item 1 (Ruling 21): app claims come last across days too. An
    /// app span 23:50–00:10 belongs to the first day's app entry, and still
    /// gives 00:00–00:10 to the next day's Claude run — at either
    /// granularity, whichever rolled first, or both in one pass.
    func testAnAppSpanBeforeMidnightYieldsToTheNextDaysClaudeRun() throws {
        for options in [perRun, perDay] {
            for order in ["app first", "claude first", "one pass"] {
                try freshDatabase()
                let project = try makeProject()
                let fast = try makeRepo(project, rateCents: 20_000)
                // 23:50–00:10 and 00:00–00:30, in minutes from 09:00.
                let app: () throws -> Void = {
                    _ = try self.derive(Self.app("x"), runs: [(890, 910)], project: project)
                }
                let claude: () throws -> Void = {
                    _ = try self.derive("claude", runs: [(900, 930)], project: project, repoId: fast.id)
                }
                switch order {
                case "app first":
                    try app()
                    _ = try BillingRollup.run(options: options, database: database)
                    try claude()
                case "claude first":
                    try claude()
                    _ = try BillingRollup.run(options: options, database: database)
                    try app()
                default:
                    try app()
                    try claude()
                }
                _ = try BillingRollup.run(options: options, database: database)

                let all = try entries()
                let label = "\(options.granularity), \(order)"
                XCTAssertEqual(all.first { $0.rateCents == 20_000 }?.day, Self.nextDay, label)
                XCTAssertEqual(all.first { $0.rateCents == 20_000 }?.rawSeconds, 1800, "the run, whole: \(label)")
                XCTAssertEqual(
                    all.first { $0.rateCents == 10_000 && $0.day == Self.day }?.rawSeconds, 600,
                    "23:50–00:00 only: \(label)"
                )
                try assertBilledOnce(project)
            }
        }
    }

    /// Round 7, found by `orphanMaker` (seed 141): new time in a frozen
    /// entry's slot goes to its open supplement, which can be listed on
    /// another day — its root was moved off the supplement's day. The roll
    /// settles that day, not only the slot's, or the time is billed by no one.
    func testTimeForAMovedRootGoesToItsSupplementOnTheDayItIsListed() throws {
        for options in [perRun, perDay] {
            try freshDatabase()
            let project = try makeProject()
            let label = "\(options.granularity)"
            try derive(Self.app("a"), runs: [(830, 840)], project: project)
            _ = try BillingRollup.run(options: options, database: database)
            let root = try XCTUnwrap(
                entries().first { $0.day == Self.day && $0.supplementsEntryId == nil }, label
            )
            _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)
            try derive(Self.app("b"), runs: [(850, 860)], project: project)
            _ = try BillingRollup.run(options: options, database: database)
            let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id }, label)
            XCTAssertEqual(supplement.day, Self.day, label)
            _ = try BillingRollup.setStatus(entryId: root.id, to: .unbilled, source: "user", database: database)
            let reopened = try XCTUnwrap(database.billingEntry(id: root.id), label)
            _ = try BillingRollup.saveEntry(moved(reopened, to: Self.nextDay), database: database)

            // 00:40–00:50 on the next day, the moved root's slot.
            try derive(Self.app("c"), runs: [(940, 950)], project: project)
            _ = try BillingRollup.run(options: options, database: database, recomputing: [])
            XCTAssertEqual(try database.billingEntry(id: supplement.id)?.rawSeconds, 1200, label)
            try assertBilledOnce(project)
        }
    }

    /// Review 6, N1: app time the first day yielded to the next day's run
    /// comes back when that run goes away — though the app entry that
    /// yielded it is billed by then (no open entry is left on that day to
    /// send it back), and again when the open heir it went to yields it.
    func testYieldedAppTimeComesBackToABilledEarlierDayWhenTheRunGoesAway() throws {
        for options in [perRun, perDay] {
            try freshDatabase()
            let project = try makeProject()
            let fast = try makeRepo(project, rateCents: 20_000)
            let label = "\(options.granularity)"
            try derive(Self.app("x"), runs: [(890, 910)], project: project)
            try derive("claude", runs: [(900, 930)], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database)
            let app = try XCTUnwrap(
                entries().first { $0.rateCents == 10_000 && $0.day == Self.day && $0.supplementsEntryId == nil }, label
            )
            XCTAssertEqual(app.rawSeconds, 600, label)
            _ = try BillingRollup.setStatus(entryId: app.id, to: .billed, source: "user", database: database)
            let heirSeconds: () throws -> Int = {
                try self.entries().filter { $0.supplementsEntryId == app.id }.map(\.rawSeconds).reduce(0, +)
            }

            // The run goes away: 00:00–00:10 is the billed entry's orphan.
            var touched = try derive("claude", runs: [], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database, recomputing: touched)
            XCTAssertEqual(try heirSeconds(), 600, "00:00–00:10 back on the first day: \(label)")
            XCTAssertEqual(try entries().filter { $0.supplementsEntryId == app.id }.first?.day, Self.day, label)
            try assertBilledOnce(project)
            // Settle every day, so the heir is there for the next step even
            // where the step above failed.
            _ = try BillingRollup.run(options: options, database: database)
            XCTAssertEqual(try heirSeconds(), 600, label)

            // The run comes back: the open heir yields to it ...
            touched = try derive("claude", runs: [(900, 930)], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database, recomputing: touched)
            XCTAssertEqual(try heirSeconds(), 0, label)
            XCTAssertEqual(try entries().first { $0.rateCents == 20_000 }?.rawSeconds, 1800, label)
            try assertBilledOnce(project)

            // ... and takes it back when the run goes away again.
            touched = try derive("claude", runs: [], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database, recomputing: touched)
            XCTAssertEqual(try heirSeconds(), 600, "taken back again: \(label)")
            try assertBilledOnce(project)
        }
    }

    /// Review 5, item 5 — **Ruling 22**: Claude-side time a billed entry gave
    /// away when it froze, orphaned once the run it went to is re-derived
    /// away, goes to an open entry whose app span already covers it, not to
    /// a new supplement of the billed entry. The orphan was given away; the
    /// open claim is granted before it (this is what lets I1's reopened app
    /// entry take its whole segment back).
    func testRuling22OrphanedClaudeTimeGoesToAnOpenAppClaimBeforeANewSupplement() throws {
        for options in [perRun, perDay] {
            try freshDatabase()
            let project = try makeProject(rateCents: 15_000)
            let fast = try makeRepo(project, rateCents: 20_000)
            try derive("r", runs: [(30, 60)], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database)
            let fastEntry = try XCTUnwrap(entries().first)
            try backdate(fastEntry.id, to: "2026-09-22T08:00:00Z")
            try derive("f", runs: [(0, 60)], project: project)
            _ = try BillingRollup.run(options: options, database: database)
            let root = try XCTUnwrap(entries().first { $0.rateCents == 15_000 })
            XCTAssertEqual(root.rawSeconds, 1800, "09:00–09:30; the run at 200 owns the rest")
            _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)

            try derive(Self.app("x"), runs: [(30, 60)], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database)
            let touched = try derive("r", runs: [], project: project, repoId: fast.id)
            _ = try BillingRollup.run(options: options, database: database, recomputing: touched)

            // Per day the span joins the run's entry; per run it has its own.
            let holder = try XCTUnwrap(database.billingEntryIds(forSessions: [Self.app("x")]).first)
            if options.granularity == perDay.granularity { XCTAssertEqual(holder, fastEntry.id) }
            XCTAssertEqual(
                try database.billingEntry(id: holder)?.rawSeconds, 1800,
                "the app span owns 09:30–10:00, \(options.granularity)"
            )
            XCTAssertNil(try entries().first { $0.supplementsEntryId == root.id }, "no supplement of the billed root")
            try assertBilledOnce(project, appOverOrphan: 30)
        }
    }

    /// Review 5, item 7: a run re-derived to reach two days on settles the
    /// third day in the same pass — through the `later` set alone when the
    /// day between holds nothing, and through it as well when it does.
    func testARunReachingTwoDaysOnSettlesTheThirdDayInOnePass() throws {
        for middle in [false, true] {
            try freshDatabase()
            let project = try makeProject()
            // D+2 00:00–01:00; D 23:00–00:30; D+1 12:00–13:00.
            try derive("late", runs: [(2340, 2400)], project: project)
            try derive("long", runs: [(840, 930)], project: project)
            if middle { try derive(Self.app("x"), runs: [(1620, 1680)], project: project) }
            _ = try BillingRollup.run(options: perRun, database: database)
            XCTAssertEqual(try claudeEntry("late")?.rawSeconds, 3600)

            // The same run, now on until D+2 00:30.
            let touched = try derive("long", runs: [(840, 2370)], project: project)
            _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)

            XCTAssertEqual(try claudeEntry("long")?.day, Self.day)
            XCTAssertEqual(try claudeEntry("long")?.rawSeconds, (2370 - 840) * 60)
            XCTAssertEqual(try claudeEntry("late")?.rawSeconds, 1800, "00:30–01:00, middle: \(middle)")
            if middle { XCTAssertEqual(try appEntry(day: Self.nextDay)?.rawSeconds, 0) }
            try assertBilledOnce(project)
        }
    }

    /// Review 5, item 7: the overlap lookback. A run from D 23:00 to D+6
    /// 00:30 starts six days before the day it ends on, and that day still
    /// finds it — whichever rolled first, and when its own entry reopens.
    func testARunSixDaysLongIsFoundByTheDayItEndsOn() throws {
        for lateFirst in [true, false] {
            try freshDatabase()
            let project = try makeProject()
            // D+6 00:00–01:00, and D 23:00 to D+6 00:30.
            let derivations: [() throws -> Void] = [
                { _ = try self.derive("late", runs: [(8100, 8160)], project: project) },
                { _ = try self.derive("long", runs: [(840, 8130)], project: project) }
            ]
            for derivation in lateFirst ? derivations : derivations.reversed() {
                try derivation()
                _ = try BillingRollup.run(options: perRun, database: database)
            }
            let late = try XCTUnwrap(claudeEntry("late"))
            XCTAssertEqual(late.rawSeconds, 1800, "late first: \(lateFirst)")
            _ = try BillingRollup.setStatus(entryId: late.id, to: .billed, source: "user", database: database)
            _ = try BillingRollup.setStatus(entryId: late.id, to: .unbilled, source: "user", database: database)
            XCTAssertEqual(try database.billingEntry(id: late.id)?.rawSeconds, 1800, "reopened: \(lateFirst)")
            try assertBilledOnce(project)
        }
    }

    /// Review 5, item 7: the daemon's first pass (`recomputing: nil`) settles
    /// every project day; a recompute pass settles only the days it names.
    func testTheFirstPassSettlesEveryDay() throws {
        let project = try makeProject()
        try derive("claude", runs: [(0, 30)], project: project)
        try derive(Self.app("x"), runs: [(10, 40)], project: project)
        try derive("next", runs: [(1440, 1470)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try appEntry()?.rawSeconds, 600)

        try database.execute("""
            UPDATE billing_entry SET raw_seconds = 0, billed_seconds = 0, amount_cents = 0, billed_ranges = ''
        """)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: [])
        XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 0, "a recompute pass settles only what it names")

        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 1800)
        XCTAssertEqual(try appEntry()?.rawSeconds, 600, "09:30–09:40")
        XCTAssertEqual(try claudeEntry("next")?.rawSeconds, 1800, "the next day too")
        try assertBilledOnce(project)
    }

    /// A root at 150 billed for 09:00–09:30 and 10:00–10:30 — a run "r" at 200
    /// owns 09:30–10:00 — and an open app claim at 200 over 09:30–09:45. Once
    /// "r" goes, 09:30–10:00 is the billed root's orphan.
    private func billedRootAboutToOrphan(
        _ options: BillingRollupOptions
    ) throws -> (project: BillingProjectDTO, fast: String, root: BillingEntryDTO) {
        let project = try makeProject(rateCents: 15_000)
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive("r", runs: [(30, 60)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: options, database: database)
        try backdate(try XCTUnwrap(entries().first).id, to: "2026-09-22T08:00:00Z")
        try derive("f", runs: [(0, 90)], project: project)
        _ = try BillingRollup.run(options: options, database: database)
        let root = try XCTUnwrap(entries().first { $0.rateCents == 15_000 })
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)
        try derive(Self.app("x"), runs: [(30, 45)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: options, database: database)
        return (project, fast.id, root)
    }

    /// Review F17: a supplement minted for an orphan is priced like any new
    /// entry — the project's current client, currency and rounding — at the
    /// root's rate, not with the terms copied off the frozen root.
    func testAMintedSupplementTakesTheProjectsCurrentTerms() throws {
        let (project, fast, root) = try billedRootAboutToOrphan(perRun)
        let client = try BillingStore.saveClient(BillingClientDTO(id: "", name: "C", currency: "EUR"),
                                                 database: database)
        _ = try BillingStore.saveProject(
            BillingProjectDTO(id: project.id, clientId: client.id, name: "P", defaultRateCents: 15_000,
                              roundingMinutes: 30, roundingMode: "nearest"),
            database: database
        )
        let touched = try derive("r", runs: [], project: project, repoId: fast)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id })
        XCTAssertEqual(supplement.clientId, client.id)
        XCTAssertEqual(supplement.currency, "EUR")
        XCTAssertEqual(supplement.roundingMinutes, 30)
        XCTAssertEqual(supplement.roundingMode, "nearest")
        XCTAssertEqual(supplement.rateCents, 15_000, "the root's rate")
        XCTAssertEqual(root.currency, "USD")
    }

    /// Review F3: settling is idempotent. A billed root's orphan split between
    /// an open app claim (Ruling 22) and a new supplement stays split that way
    /// when every day is settled again: the supplement is not taken for the
    /// heir on the second pass and handed the app claim's time.
    func testSettlingASplitOrphanAgainChangesNothing() throws {
        for options in [perRun, perDay] {
            try freshDatabase()
            let label = "\(options.granularity)"
            let (project, fast, root) = try billedRootAboutToOrphan(options)
            XCTAssertEqual(root.rawSeconds, 3600, label)
            let touched = try derive("r", runs: [], project: project, repoId: fast)
            _ = try BillingRollup.run(options: options, database: database, recomputing: touched)
            XCTAssertEqual(try entries().filter { $0.supplementsEntryId == root.id }.map(\.rawSeconds), [900],
                           "09:45–10:00 to a supplement, \(label)")
            try assertBilledOnce(project, appOverOrphan: 15)

            let settled = try ledgerSnapshot(projectId: project.id)
            XCTAssertEqual(try BillingRollup.recomputeOwnedEntries(database: database), 0, label)
            XCTAssertEqual(try ledgerSnapshot(projectId: project.id), settled, label)
            _ = try BillingRollup.run(options: options, database: database)
            XCTAssertEqual(try ledgerSnapshot(projectId: project.id), settled, label)
        }
    }

    /// Review F6: a frozen supplement whose root was moved to another day
    /// still names that root. Its orphaned time goes to the root (or the
    /// root's supplement), never to a supplement of the supplement.
    func testAnOrphanOfASupplementWhoseRootMovedFollowsTheRoot() throws {
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive(Self.app("a"), runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let root = try XCTUnwrap(appEntry())
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)
        try derive("r", runs: [(60, 75)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database)
        try derive(Self.app("b"), runs: [(60, 90)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id })
        XCTAssertEqual(supplement.rawSeconds, 900, "10:15–10:30; the run owns 10:00–10:15")
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: root.id, to: .unbilled, source: "user", database: database)
        let reopened = try XCTUnwrap(database.billingEntry(id: root.id))
        _ = try BillingRollup.saveEntry(moved(reopened, to: Self.nextDay), database: database)
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)

        let touched = try derive("r", runs: [], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)
        XCTAssertNil(try entries().first { $0.supplementsEntryId == supplement.id }, "no supplement of a supplement")
        let heir = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id && $0.id != supplement.id })
        XCTAssertEqual(heir.rawSeconds, 900, "10:00–10:15")
        XCTAssertEqual(heir.day, Self.day)
        try assertBilledOnce(project)
    }

    /// Review F16: the roll commits one project day at a time. A later day
    /// failing must not strand the follow-ups of a day already committed —
    /// here the first day's app entry, which still holds 00:00–00:10 that the
    /// committed day's run took.
    func testALaterDayFailingStillSettlesTheFollowUpsOfCommittedDays() throws {
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive(Self.app("x"), runs: [(890, 910)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try appEntry()?.rawSeconds, 1200)
        try derive("claude", runs: [(900, 930)], project: project, repoId: fast.id)
        try derive("later", runs: [(2400, 2430)], project: project, repoId: fast.id)
        try database.execute("""
            CREATE TEMP TRIGGER fail_later BEFORE INSERT ON billing_entry WHEN NEW.day = '2026-09-24'
            BEGIN SELECT RAISE(ABORT, 'later day failed'); END
        """)
        XCTAssertThrowsError(try BillingRollup.run(options: perRun, database: database, recomputing: []))
        XCTAssertEqual(try claudeEntry("claude")?.rawSeconds, 1800, "the committed day")
        XCTAssertEqual(try appEntry()?.rawSeconds, 600, "its follow-up settled: 23:50–00:00 only")
        try database.execute("DROP TRIGGER fail_later")
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try claudeEntry("later")?.rawSeconds, 1800)
        try assertBilledOnce(project)
    }

    /// Review F4: the overlap lookback is the longest row, not seven days. A
    /// run from D 23:00 to D+9 00:30 is found by the day it ends on.
    func testARunNineDaysLongIsFoundByTheDayItEndsOn() throws {
        let project = try makeProject()
        let nine = 900 + 8 * 1440
        try derive("late", runs: [(nine, nine + 60)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        try derive("long", runs: [(840, nine + 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let late = try XCTUnwrap(claudeEntry("late"))
        XCTAssertEqual(late.rawSeconds, 1800)
        _ = try BillingRollup.setStatus(entryId: late.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: late.id, to: .unbilled, source: "user", database: database)
        XCTAssertEqual(try database.billingEntry(id: late.id)?.rawSeconds, 1800, "reopened")
        try assertBilledOnce(project)
    }

    /// Review F5: an entry moved with its times blanked (as the Billables
    /// editor moves one) is still found by the day its recorded ranges lie
    /// on — here a range it inherited, which none of its segments covers.
    func testAMovedEntryWithBlankTimesStillOwnsItsInheritedRange() throws {
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive(Self.app("a"), runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let root = try XCTUnwrap(appEntry())
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)
        try derive("r", runs: [(60, 75)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database)
        try derive(Self.app("b"), runs: [(60, 90)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id })
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: root.id, to: .unbilled, source: "user", database: database)
        // The run goes away: 10:00–10:15, the billed supplement's orphan, is
        // inherited by its reopened root.
        let touched = try derive("r", runs: [], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)
        XCTAssertEqual(try database.billingEntry(id: root.id)?.rawSeconds, 2700, "09:00–09:30 and 10:00–10:15")
        let reopened = try XCTUnwrap(database.billingEntry(id: root.id))
        _ = try BillingRollup.saveEntry(moved(reopened, to: Self.nextDay, blank: true), database: database)

        // New app time over the inherited range, on the day the range lies on.
        try derive(Self.app("c"), runs: [(60, 75)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try database.billingEntry(id: root.id)?.rawSeconds, 2700, "the moved entry keeps it")
        let holders = try database.billingEntryIds(forSessions: [Self.app("c")])
        XCTAssertEqual(try holders.compactMap { try database.billingEntry(id: $0)?.rawSeconds }.reduce(0, +), 0,
                       "10:00–10:15 is billed once")
        try assertBilledOnce(project)
    }

    /// Re-review F5: after the move the user types a Start, or a Start and an
    /// End, on the new day. The shown times no longer reach the old day, but
    /// the frozen entry still owns the range it recorded there.
    func testAMovedEntryWithATypedStartStillOwnsItsInheritedRange() throws {
        try assertMovedEntryKeepsItsInheritedRange(typing: ("2026-09-23T09:00:00Z", ""))
    }

    func testAMovedEntryWithTypedTimesStillOwnsItsInheritedRange() throws {
        try assertMovedEntryKeepsItsInheritedRange(typing: ("2026-09-23T09:00:00Z", "2026-09-23T09:45:00Z"))
    }

    private func assertMovedEntryKeepsItsInheritedRange(typing times: (String, String)) throws {
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        try derive(Self.app("a"), runs: [(0, 30)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let root = try XCTUnwrap(appEntry())
        _ = try BillingRollup.setStatus(entryId: root.id, to: .billed, source: "user", database: database)
        try derive("r", runs: [(60, 75)], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database)
        try derive(Self.app("b"), runs: [(60, 90)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        let supplement = try XCTUnwrap(entries().first { $0.supplementsEntryId == root.id })
        _ = try BillingRollup.setStatus(entryId: supplement.id, to: .billed, source: "user", database: database)
        _ = try BillingRollup.setStatus(entryId: root.id, to: .unbilled, source: "user", database: database)
        let touched = try derive("r", runs: [], project: project, repoId: fast.id)
        _ = try BillingRollup.run(options: perRun, database: database, recomputing: touched)
        let reopened = try XCTUnwrap(database.billingEntry(id: root.id))
        _ = try BillingRollup.saveEntry(moved(reopened, to: Self.nextDay, blank: true), database: database)
        let blanked = try XCTUnwrap(database.billingEntry(id: root.id))
        _ = try BillingRollup.saveEntry(typed(blanked, start: times.0, end: times.1), database: database)

        try derive(Self.app("c"), runs: [(60, 75)], project: project)
        _ = try BillingRollup.run(options: perRun, database: database)
        XCTAssertEqual(try database.billingEntry(id: root.id)?.rawSeconds, 2700, "typed \(times): kept")
        let holders = try database.billingEntryIds(forSessions: [Self.app("c")])
        XCTAssertEqual(try holders.compactMap { try database.billingEntry(id: $0)?.rawSeconds }.reduce(0, +), 0,
                       "typed \(times): 10:00–10:15 is billed once")
        try assertBilledOnce(project)
    }

    // MARK: - Seeded random orders

    /// SplitMix64: small, fast, and the same sequence on every machine.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = state
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
            return mixed ^ (mixed >> 31)
        }
    }

    static let sequences = 1500
    static let maxOperations = 24

    /// How often each operation is drawn. The ones that act on an entry are
    /// weighted up: each needs a roll (and unfreeze a freeze) before it, so
    /// drawn evenly they run too rarely to meet `minimumRuns`. Claude runs
    /// and re-derived spans are too: an orphan needs a frozen entry whose
    /// overlap went to time that has since moved.
    private static let draws: [Operation] = Operation.allCases.flatMap { operation -> [Operation] in
        switch operation {
        case .unfreeze: return Array(repeating: operation, count: 4)
        case .roll, .freeze, .orphanMaker: return Array(repeating: operation, count: 3)
        case .userEdit, .moveDay, .moveBlank, .delete, .claudeRun, .reDeriveSpan, .appSpan:
            return Array(repeating: operation, count: 2)
        default: return [operation]
        }
    }

    /// The random test's clock: two nights of 180 minutes, 22:00 to 01:00,
    /// from the 22nd into the 23rd and from the 23rd into the 24th, so runs
    /// cross midnight and three days settle against each other. Each draw of
    /// runs falls in one night, chosen at random.
    private static let nightBase = UTCTimestamp.epochSeconds("2026-09-22T22:00:00Z") ?? 0
    private static let slots = 180
    private static let nights = 2
    /// The days an entry can sit on; a move goes to the next, cyclically.
    private static let days = ["2026-09-22", "2026-09-23", "2026-09-24"]

    private static func dayAfterInCycle(_ day: String) -> String {
        let index = days.firstIndex(of: day) ?? 0
        return days[(index + 1) % days.count]
    }

    private enum Operation: Int, CaseIterable {
        case appSpan, reDeriveSpan, claudeRun, midnightRun, roll, freeze, unfreeze
        case userEdit, moveDay, delete, backfill, switchGranularity
        /// A move as the Billables editor makes it: the shown times blanked,
        /// the recorded ranges kept (review F5).
        case moveBlank
        /// One run reaching more than seven days back into the night — a
        /// runaway timer, flagged but never truncated (review F4).
        case longTimer
        /// An app span and a Claude run that overlap, rolled; the app entry
        /// that yielded the overlap frozen; the run re-derived shorter or
        /// away, orphaning what the frozen entry gave it; rolled again. Half
        /// the time the frozen loser is a Claude entry instead (Ruling 22).
        case orphanMaker
    }

    /// How many times each kind of operation must have *run* — not been
    /// drawn, not been refused — across all seeds, so a regression that
    /// makes one unreachable fails here rather than passing vacuously.
    /// "orphan supplement" counts distinct supplements that billed orphaned
    /// time, not checks that saw one; "Ruling 22 minutes" the distinct orphaned
    /// Claude-side minutes open app claims took instead, in each seed — the
    /// `orphanMaker`'s Claude-loser half makes them, thirty a time, so the
    /// floor is high: with Ruling 22 broken the orphans go to supplements,
    /// which the oracle accepts, and only this count falls; "cross-day orphan" the
    /// `orphanMaker`s whose overlap straddled midnight and formed an orphan
    /// — the frozen app entry had yielded it, and another entry owns it
    /// after the run let it go; "shrink" the Claude
    /// runs re-derived to part of what they were; "Claude-loser orphan maker"
    /// and "cross-day Claude loser" the Claude-loser `orphanMaker`s whose
    /// orphan formed and was asserted to go to the cover; "second night"
    /// counts draws of runs in the night from the 23rd into the 24th; "move
    /// blank" the moves that blanked an entry's times; "long timer" the runs
    /// reaching over seven days back.
    private static let minimumRuns: [String: Int] = [
        "move blank": 150, "long timer": 150,
        "unfreeze": 150, "user edit": 150, "delete": 150, "move day": 150,
        "orphan supplement": 100, "Ruling 22 minutes": 5000, "cross-day orphan": 50,
        "midnight run": 200, "switch granularity": 200, "second night": 500, "first pass": 200,
        "shrink": 50, "Claude-loser orphan maker": 200, "cross-day Claude loser": 50
    ]

    /// For each seed: a fresh database, up to twenty-three operations that ran
    /// over one project and three days, then a final roll. After every roll
    /// the oracle must hold and every frozen entry's figures and ranges must
    /// be as they were when it froze. A failure prints the seed and the
    /// steps, which replay deterministically: `TEST_RUNNER_BILLING_SEED=<n>`
    /// on the `xcodebuild` line runs that seed alone and dumps its rows.
    ///
    /// The seeds are independent, so they run on one worker per core, each
    /// worker its own instance of this class with its own database file: one
    /// after another they took eight minutes. Every seed still runs and the
    /// tally is summed across workers before the floors are checked.
    func testEverySecondBillsOnceInAnyOrder() throws {
        var failures: [String] = []
        var tally: [String: Int] = [:]
        if let only = ProcessInfo.processInfo.environment["BILLING_SEED"].flatMap({ Int($0) }) {
            if let failure = try runSeed(only, tally: &tally) {
                failures.append(failure)
                try debugDump()
            }
            XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n\n"))
            return
        }
        let results = SeedResults()
        let workers = max(1, ProcessInfo.processInfo.activeProcessorCount)
        DispatchQueue.concurrentPerform(iterations: workers) { worker in
            let runner = BillingOwnershipTests()
            var workerTally: [String: Int] = [:]
            do {
                try runner.setUpWithError()
                defer { try? runner.tearDownWithError() }
                for seed in stride(from: worker + 1, through: Self.sequences, by: workers) {
                    guard !results.enoughFailures else { break }
                    if let failure = try runner.runSeed(seed, tally: &workerTally) {
                        results.fail(seed: seed, failure)
                    }
                }
            } catch {
                results.fail(seed: 0, "worker \(worker) threw: \(error)")
            }
            results.add(workerTally)
        }
        failures = results.failures
        tally = results.tally
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n\n"))
        guard failures.isEmpty else { return }
        print("billing ownership tally:", tally.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" })
        for (operation, minimum) in Self.minimumRuns.sorted(by: { $0.key < $1.key }) {
            XCTAssertGreaterThanOrEqual(
                tally[operation, default: 0], minimum, "\(operation) ran \(tally[operation, default: 0]) times"
            )
        }
    }

    /// One seed on a fresh database at this instance's path.
    private func runSeed(_ seed: Int, tally: inout [String: Int]) throws -> String? {
        database = nil
        try? FileManager.default.removeItem(atPath: tmpPath)
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        return try runSequence(seed: UInt64(seed), tally: &tally)
    }

    /// What the concurrent workers found, gathered under a lock. Failures
    /// come back ordered by seed, so the message does not depend on which
    /// worker finished first.
    private final class SeedResults: @unchecked Sendable {
        private let lock = NSLock()
        private var found: [(seed: Int, failure: String)] = []
        private var summed: [String: Int] = [:]

        /// Five failing seeds are enough to report; the workers stop there.
        var enoughFailures: Bool { lock.withLock { found.count >= 5 } }
        var failures: [String] { lock.withLock { found.sorted { $0.seed < $1.seed }.map(\.failure) } }
        var tally: [String: Int] { lock.withLock { summed } }

        func fail(seed: Int, _ failure: String) { lock.withLock { found.append((seed, failure)) } }
        func add(_ tally: [String: Int]) {
            lock.withLock { summed.merge(tally, uniquingKeysWith: +) }
        }
    }

    private struct Frozen: Equatable {
        let raw: Int
        let billed: Int
        let ranges: String
    }

    /// What one drawn operation did.
    private enum Outcome {
        /// Nothing to act on; another operation is drawn in its place.
        case skipped
        /// Attempted and refused by the rollup; it uses its slot.
        case refused
        case ran
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func runSequence(seed: UInt64, tally: inout [String: Int]) throws -> String? {
        var rng = SeededGenerator(state: seed)
        var options = seed % 2 == 0 ? perRun : perDay
        let project = try makeProject()
        let fast = try makeRepo(project, rateCents: 20_000)
        var steps: [String] = ["granularity \(options.granularity)"]
        var touched: Set<String> = []
        var spans = 0
        var orphanMakers = 0
        /// Each session bills at one rate for good: its repo is fixed.
        var repoOf: [String: String?] = ["c0": nil, "c1": nil, "c2": fast.id, "n0": nil, "n1": fast.id]
        var frozen: [String: Frozen] = [:]
        /// Supplements already counted as having billed orphaned time.
        var orphanSupplements: Set<String> = []
        /// Minutes already counted under Ruling 22.
        var ruling22Seen: Set<Int> = []

        func derive(_ session: String, _ runs: [(start: Int, end: Int)]) throws {
            touched.formUnion(try self.derive(
                session, runs: runs, project: project, repoId: repoOf[session] ?? nil, base: Self.nightBase
            ))
        }
        /// The minute offset of a randomly chosen night.
        func randomNight() -> Int {
            let night = Int.random(in: 0..<Self.nights, using: &rng)
            if night > 0 { tally["second night", default: 0] += 1 }
            return night * 1440
        }
        func randomRuns() -> [(start: Int, end: Int)] {
            let count = Int.random(in: 0...2, using: &rng)
            let night = randomNight()
            var runs: [(start: Int, end: Int)] = []
            var cursor = 0
            for _ in 0..<count {
                let start = cursor + 5 * Int.random(in: 0...16, using: &rng)
                let end = start + 5 * Int.random(in: 1...8, using: &rng)
                guard end <= Self.slots else { break }
                runs.append((night + start, night + end))
                cursor = end + 5
            }
            return runs
        }
        func describe(_ runs: [(start: Int, end: Int)]) -> String {
            runs.map { "\($0.start)-\($0.end)" }.joined(separator: ",")
        }
        func pick(_ choices: [BillingEntryDTO]) throws -> BillingEntryDTO? {
            let keyed = try choices.map { (key: try stableKey($0), entry: $0) }
            let ordered = keyed.sorted { $0.key < $1.key }.map(\.entry)
            return ordered.isEmpty ? nil : ordered[Int.random(in: 0..<ordered.count, using: &rng)]
        }
        func snapshot(_ id: String) throws -> Frozen? {
            var found: Frozen?
            try database.query("""
                SELECT raw_seconds, billed_seconds, billed_ranges FROM billing_entry WHERE id = ?
            """, params: [id]) { row in
                found = Frozen(raw: row["raw_seconds"] ?? 0, billed: row["billed_seconds"] ?? 0,
                               ranges: row["billed_ranges"] ?? "<nil>")
            }
            return found
        }
        func remember(_ id: String) throws {
            guard let entry = try database.billingEntry(id: id) else { return }
            frozen[id] = BillingRollup.isFrozen(entry) ? try snapshot(id) : nil
        }
        func check() throws -> String? {
            let result = try oracle(projectId: project.id)
            if let failure = result.failure { return failure }
            // Each formed minute once, not once per check that sees it.
            let fresh = result.ruling22Minutes.subtracting(ruling22Seen)
            ruling22Seen.formUnion(fresh)
            tally["Ruling 22 minutes", default: 0] += fresh.count
            for (id, was) in frozen {
                guard let entry = try database.billingEntry(id: id), BillingRollup.isFrozen(entry) else {
                    frozen[id] = nil
                    continue
                }
                if try snapshot(id) != was { return "frozen entry \(id) moved" }
            }
            for entry in try entries() where entry.supplementsEntryId != nil && entry.rawSeconds > 0
                && !orphanSupplements.contains(entry.id) {
                guard try database.billingSegmentsForEntry(id: entry.id).isEmpty else { continue }
                orphanSupplements.insert(entry.id)
                tally["orphan supplement", default: 0] += 1
            }
            return nil
        }
        func roll(full: Bool) throws -> String? {
            _ = try BillingRollup.run(options: options, database: database, recomputing: full ? nil : touched)
            touched = []
            return try check()
        }

        // swiftlint:disable:next closure_body_length
        func perform(_ operation: Operation, _ all: [BillingEntryDTO]) throws -> (Outcome, String?) {
            switch operation {
            case .appSpan:
                spans += 1
                let session = Self.app("a\(spans)")
                repoOf[session] = Bool.random(using: &rng) ? fast.id : nil
                let runs = randomRuns()
                steps.append("app span a\(spans)\(repoOf[session] ?? nil == nil ? "" : " @fast") \(describe(runs))")
                try derive(session, runs)
            case .reDeriveSpan:
                guard spans > 0 else { return (.skipped, nil) }
                let span = Int.random(in: 1...spans, using: &rng)
                let runs = randomRuns()
                steps.append("re-derive span a\(span) \(describe(runs))")
                try derive(Self.app("a\(span)"), runs)
            case .claudeRun:
                let session = "c\(Int.random(in: 0...2, using: &rng))"
                var runs = randomRuns()
                let current = try currentRuns(session)
                if !current.isEmpty, Int.random(in: 0..<3, using: &rng) == 0 {
                    // Shrink: one of its runs, cut to a sub-range or dropped.
                    runs = current
                    let index = Int.random(in: 0..<runs.count, using: &rng)
                    let run = runs[index]
                    let start = run.start + 5 * Int.random(in: 0...((run.end - run.start) / 5), using: &rng)
                    let end = start + 5 * Int.random(in: 0...((run.end - start) / 5), using: &rng)
                    if end > start, (start, end) != run { runs[index] = (start, end) } else { runs.remove(at: index) }
                    steps.append("shrink claude \(session) \(describe(runs))")
                    tally["shrink", default: 0] += 1
                } else {
                    steps.append("claude \(session) \(describe(runs))")
                }
                try derive(session, runs)
            case .midnightRun:
                let session = "n\(Int.random(in: 0...1, using: &rng))"
                let night = randomNight()
                let start = night + 5 * Int.random(in: 18...23, using: &rng)
                let end = night + 5 * Int.random(in: 25...30, using: &rng)
                steps.append("midnight run \(session) \(start)-\(end)")
                try derive(session, [(start, end)])
                tally["midnight run", default: 0] += 1
            case .roll:
                let full = Int.random(in: 0..<5, using: &rng) == 0
                steps.append(full ? "roll (first pass)" : "roll")
                if full { tally["first pass", default: 0] += 1 }
                if let failure = try roll(full: full) { return (.ran, failure) }
            case .freeze:
                guard let entry = try pick(all.filter { !BillingRollup.isFrozen($0) }) else { return (.skipped, nil) }
                steps.append("freeze \(label(entry))")
                do {
                    _ = try BillingRollup.setStatus(entryId: entry.id, to: .billed, source: "user", database: database)
                    try remember(entry.id)
                } catch BillingRollup.RollupError.unknownEntry {
                    steps.append("  (refused: settling removed it)")
                    return (.refused, nil)
                }
            case .unfreeze:
                guard let entry = try pick(all.filter(\.locked)) else { return (.skipped, nil) }
                steps.append("unfreeze \(label(entry))")
                _ = try BillingRollup.setStatus(entryId: entry.id, to: .unbilled, source: "user", database: database)
                try remember(entry.id)
                tally["unfreeze", default: 0] += 1
            case .longTimer:
                let night = randomNight()
                let start = night - 7 * 1440 - 5 * Int.random(in: 1...24, using: &rng)
                let end = night + 5 * Int.random(in: 1...36, using: &rng)
                steps.append("long timer t0 \(start)-\(end)")
                try derive("t0", [(start, end)])
                tally["long timer", default: 0] += 1
            case .userEdit, .moveDay, .moveBlank:
                let moving = operation != .userEdit
                let blank = operation == .moveBlank
                // A root entry moves only to a day where its slot is free:
                // the slot index refuses the other case outright. Moves go
                // to the next of the three days, cyclically.
                let movable = all.filter { entry in
                    let target = Self.dayAfterInCycle(entry.day)
                    return entry.supplementsEntryId != nil || !all.contains {
                        $0.supplementsEntryId == nil && $0.day == target && $0.groupKey == entry.groupKey
                    }
                }
                guard let entry = try pick((moving ? movable : all).filter { !$0.locked }) else {
                    return (.skipped, nil)
                }
                let change: (BillingEntryDTO) -> BillingEntryDTO = { entry in
                    moving
                        ? self.moved(entry, to: Self.dayAfterInCycle(entry.day), blank: blank)
                        : self.edited(entry)
                }
                steps.append("\(blank ? "move blank" : moving ? "move day" : "user-edit") \(label(entry))")
                do {
                    let saved: BillingEntryDTO
                    do {
                        saved = try BillingRollup.saveEntry(change(entry), database: database)
                    } catch BillingRollup.RollupError.entryChanged {
                        // The editor reloads the fresh row and saves again.
                        steps.append("  (stale: reloaded)")
                        guard let fresh = try database.billingEntry(id: entry.id) else { return (.refused, nil) }
                        saved = try BillingRollup.saveEntry(change(fresh), database: database)
                    }
                    try remember(saved.id)
                    tally[blank ? "move blank" : moving ? "move day" : "user edit", default: 0] += 1
                } catch BillingRollup.RollupError.unknownEntry {
                    steps.append("  (refused: settling removed it)")
                    return (.refused, nil)
                }
            case .delete:
                guard let entry = try pick(all.filter { !$0.locked }) else { return (.skipped, nil) }
                steps.append("delete \(label(entry))")
                do {
                    try BillingRollup.deleteEntry(id: entry.id, database: database)
                    tally["delete", default: 0] += 1
                } catch BillingRollup.RollupError.entryHasFrozenSupplements {
                    steps.append("  (refused: frozen supplements)")
                    return (.refused, nil)
                }
            case .backfill:
                steps.append("backfill reset")
                _ = try database.resetBillingDerivation(since: "")
                for session in try sessionIds(project) { try derive(session, try currentRuns(session)) }
            case .switchGranularity:
                options = options.granularity == .run ? perDay : perRun
                steps.append("granularity \(options.granularity)")
                tally["switch granularity", default: 0] += 1
            case .orphanMaker:
                orphanMakers += 1
                return try makeOrphan(orphanMakers)
            }
            return (.ran, nil)
        }

        // `Operation.orphanMaker`. Midnight is minute 120 of a night.
        // swiftlint:disable:next function_body_length
        func makeOrphan(_ number: Int) throws -> (Outcome, String?) {
            let night = randomNight()
            let crossDay = Bool.random(using: &rng)
            let asSupplement = Bool.random(using: &rng)
            let covered = Bool.random(using: &rng)
            let claudeLoser = Bool.random(using: &rng)
            let app: (start: Int, end: Int)
            let run: (start: Int, end: Int)
            if crossDay {
                // App span before midnight into it, the run from midnight.
                let start = night + 5 * Int.random(in: 20...23, using: &rng)
                app = (start, night + 5 * Int.random(in: 25...27, using: &rng))
                run = (night + 120, night + 5 * Int.random(in: 26...30, using: &rng))
            } else {
                let start = night + 5 * Int.random(in: 8...16, using: &rng)
                app = (start, start + 5 * Int.random(in: 4...6, using: &rng))
                let runStart = start + 5 * Int.random(in: 1...3, using: &rng)
                run = (runStart, runStart + 5 * Int.random(in: 2...4, using: &rng))
            }
            let overlapEnd = min(app.end, run.end)
            let appSession = Self.app("o\(number)")
            let claude = "m\(number)"
            repoOf[appSession] = .some(nil)
            repoOf[claude] = Bool.random(using: &rng) ? fast.id : nil
            var holderId: String?
            func freezeHolder(_ session: String) throws -> (Outcome, String?)? {
                let holders = try database.billingEntryIds(forSessions: [session]).sorted()
                guard let holder = try holders.compactMap({ try database.billingEntry(id: $0) }).first else {
                    steps.append("  (nothing holds \(session))")
                    return (.refused, nil)
                }
                holderId = holder.id
                guard !BillingRollup.isFrozen(holder) else { return nil }
                steps.append("  freeze \(label(holder))")
                do {
                    _ = try BillingRollup.setStatus(entryId: holder.id, to: .billed, source: "user", database: database)
                    try remember(holder.id)
                } catch BillingRollup.RollupError.unknownEntry {
                    steps.append("  (refused: settling removed it)")
                    return (.refused, nil)
                }
                return nil
            }
            if claudeLoser {
                return try makeClaudeOrphan(number, night: night, crossDay: crossDay, freeze: freezeHolder)
            }
            steps.append(
                "orphan maker \(number): app \(describe([app])), claude \(claude)"
                    + "\(repoOf[claude] ?? nil == nil ? "" : " @fast") \(describe([run]))"
                    + "\(asSupplement ? ", as supplement" : "")\(covered ? ", covered" : "")"
            )
            if asSupplement {
                // An earlier app span on the same day, its root frozen, so
                // the overlapping span's time goes to a supplement.
                let lead = Self.app("o\(number)l")
                repoOf[lead] = .some(nil)
                let start = night + 5 * Int.random(in: 0...3, using: &rng)
                try derive(lead, [(start, start + 10)])
                steps.append("  roll")
                if let failure = try roll(full: false) { return (.ran, failure) }
                if let outcome = try freezeHolder(lead) { return outcome }
            }
            try derive(appSession, [app])
            try derive(claude, [run])
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            // The entry holding the app span gave the overlap to the run.
            if let outcome = try freezeHolder(appSession) { return outcome }
            // What it gave this run: the overlap its segments hold but its
            // frozen ranges do not, owned by the run's entry. Empty when it
            // never yielded to the run — then no orphan of this run forms.
            let overlap = [BillingRange(start: Self.nightBase + run.start * 60, end: Self.nightBase + overlapEnd * 60)]
            var runOwns: [BillingRange] = []
            for id in try database.billingEntryIds(forSessions: [claude]) {
                runOwns = BillingRange.union(runOwns, try ownedRanges(id))
            }
            let yielded = try holderId.map { id in
                BillingRange.intersect(
                    BillingRange.subtract(
                        BillingRange.intervals(of: try database.billingSegmentsForEntry(id: id)), try ownedRanges(id)
                    ),
                    BillingRange.intersect(overlap, runOwns)
                )
            } ?? []
            if covered {
                // An open app claim over the orphan-to-be. At the frozen
                // entry's rate it joins that root as its heir; at another
                // rate it is another root's, ranked ahead of a new
                // supplement. The orphan is app time, so this is not
                // Ruling 22 — `makeClaudeOrphan` is.
                let cover = Self.app("o\(number)c")
                repoOf[cover] = Bool.random(using: &rng) ? fast.id : nil
                let fastCover = repoOf[cover] ?? nil != nil
                steps.append("  cover \(describe([(run.start - 5, overlapEnd)]))\(fastCover ? " @fast" : "")")
                try derive(cover, [(run.start - 5, overlapEnd)])
                steps.append("  roll")
                if let failure = try roll(full: false) { return (.ran, failure) }
            }
            // Shorter: the run now starts inside the overlap or at its end,
            // so it keeps part of what it was given, or none of it.
            let shorter = Bool.random(using: &rng)
            let cut = run.start + 5 * Int.random(in: 1...((overlapEnd - run.start) / 5), using: &rng)
            let remaining = shorter && cut < run.end ? [(start: cut, end: run.end)] : []
            steps.append("  claude \(claude) \(describe(remaining))")
            try derive(claude, remaining)
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            tally["orphan maker", default: 0] += 1
            // Counted only once formed: the yielded time the run let go is
            // owned now, by an entry other than the frozen one that gave it.
            let kept = remaining.map {
                BillingRange(start: Self.nightBase + $0.start * 60, end: Self.nightBase + $0.end * 60)
            }
            let orphan = BillingRange.subtract(yielded, kept)
            var others: [BillingRange] = []
            for entry in try entries() where entry.id != holderId {
                others = BillingRange.union(others, try ownedRanges(entry.id))
            }
            if crossDay, !orphan.isEmpty, BillingRange.subtract(orphan, others).isEmpty {
                tally["cross-day orphan", default: 0] += 1
            }
            return (.ran, nil)
        }

        // `orphanMaker`'s other half, after `testRuling22…`: the frozen
        // loser is a Claude entry. An older run takes part of a newer run's
        // time; the newer run's entry freezes; an open app span covers the
        // overlap; the older run is re-derived away. The orphan is Claude
        // time a frozen entry gave away, and the open app claim takes it
        // ahead of a new supplement — Ruling 22, by construction.
        func makeClaudeOrphan(
            _ number: Int, night: Int, crossDay: Bool, freeze: (String) throws -> (Outcome, String?)?
        ) throws -> (Outcome, String?) {
            let older = "m\(number)o"
            let newer = "m\(number)"
            let cover = Self.app("o\(number)c")
            repoOf[older] = fast.id
            repoOf[newer] = .some(nil)
            repoOf[cover] = fast.id
            // Across midnight both runs sit on the next day — Claude against
            // Claude across days, the earlier day would win (Ruling 20) — and
            // the cover's app span starts the day before.
            let start = night + 5 * Int.random(in: crossDay ? 24...26 : 0...12, using: &rng)
            let taken = (start: start + 30, end: start + 60)
            let coverStart = crossDay ? night + 5 * Int.random(in: 20...23, using: &rng) : taken.start
            let coverRun = (start: coverStart, end: taken.end)
            steps.append("orphan maker \(number): older \(older) @fast \(describe([taken])), newer \(newer) "
                + "\(describe([(start, start + 60)])), Claude loser")
            try derive(older, [taken])
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            for id in try database.billingEntryIds(forSessions: [older]) {
                steps.append("  backdate \(id)")
                try backdate(id, to: "2026-09-01T00:00:00Z")
            }
            try derive(newer, [(start, start + 60)])
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            if let outcome = try freeze(newer) { return outcome }
            // The orphan-to-be: what the frozen newer entry holds but gave
            // the older run. Empty when it gave nothing — no orphan forms.
            let lost = [BillingRange(start: Self.nightBase + taken.start * 60, end: Self.nightBase + taken.end * 60)]
            guard let frozenId = try database.billingEntryIds(forSessions: [newer]).sorted().first,
                  let frozenEntry = try database.billingEntry(id: frozenId) else { return (.ran, nil) }
            var olderOwns: [BillingRange] = []
            for id in try database.billingEntryIds(forSessions: [older]) {
                olderOwns = BillingRange.union(olderOwns, try ownedRanges(id))
            }
            let orphan = BillingRange.intersect(
                BillingRange.subtract(
                    BillingRange.intervals(of: try database.billingSegmentsForEntry(id: frozenId)),
                    try ownedRanges(frozenId)
                ),
                BillingRange.intersect(lost, olderOwns)
            )
            steps.append("  cover \(describe([coverRun])) @fast")
            try derive(cover, [coverRun])
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            // Ruling 22 applies with no heir: no open member of the frozen
            // entry's root family to claim the orphan in the Claude pass.
            // Read before the last roll, which may add the very supplement
            // Ruling 22 must not.
            let root = frozenEntry.supplementsEntryId ?? frozenId
            let heirless = try entries().filter { $0.id == root || $0.supplementsEntryId == root }
                .allSatisfy(BillingRollup.isFrozen)
            steps.append("  claude \(older)")
            try derive(older, [])
            steps.append("  roll")
            if let failure = try roll(full: false) { return (.ran, failure) }
            guard !orphan.isEmpty, heirless else { return (.ran, nil) }
            let all = try entries()
            // Minutes another entry's Claude run holds go to that run first.
            let holders = try claudeHolders(projectId: project.id)
            let contested = holders.filter { !$0.value.subtracting([frozenId]).isEmpty }.keys
                .map { BillingRange(start: $0 * 60, end: $0 * 60 + 60) }
            let expected = BillingRange.subtract(orphan, BillingRange.normalized(Array(contested)))
            // The cover spans it all, so open app claims own it — the cover's,
            // an older open entry's whose app span covers it too, or one an
            // open entry inherits as heir of a frozen relative's app span.
            var appOwns: [BillingRange] = []
            for entry in all where !BillingRollup.isFrozen(entry) {
                let familyRoot = entry.supplementsEntryId ?? entry.id
                let relatives = all.filter {
                    $0.id == entry.id || (BillingRollup.isFrozen($0)
                        && ($0.id == familyRoot || $0.supplementsEntryId == familyRoot))
                }
                let app = try relatives.flatMap { try database.billingSegmentsForEntry(id: $0.id) }
                    .filter { ActivitySpanSession.spanId(sessionId: $0.sessionId) != nil }
                appOwns = BillingRange.union(
                    appOwns, BillingRange.intersect(BillingRange.intervals(of: app), try ownedRanges(entry.id))
                )
            }
            let missing = BillingRange.subtract(expected, appOwns)
            if !missing.isEmpty {
                return (.ran, "Ruling 22 (\(options.granularity)): open app claims do not own "
                    + "\(BillingRange.measure(missing)) s of the orphan of frozen \(frozenId)")
            }
            for supplement in all where supplement.supplementsEntryId == root {
                let owned = BillingRange.intersect(orphan, try ownedRanges(supplement.id))
                if !owned.isEmpty {
                    return (.ran, "Ruling 22 (\(options.granularity)): supplement \(supplement.id) "
                        + "of frozen \(frozenId) owns \(BillingRange.measure(owned)) s of its orphan, "
                        + "not an open app claim")
                }
            }
            tally["orphan maker", default: 0] += 1
            tally["Claude-loser orphan maker", default: 0] += 1
            if crossDay { tally["cross-day Claude loser", default: 0] += 1 }
            return (.ran, nil)
        }

        let target = Int.random(in: 1...(Self.maxOperations - 1), using: &rng)
        var done = 0
        var draws = 0
        while done < target, draws < target * 50 {
            draws += 1
            let operation = Self.draws[Int.random(in: 0..<Self.draws.count, using: &rng)]
            let (outcome, failure) = try perform(operation, try entries())
            if let failure { return report(seed, steps, failure) }
            if case .skipped = outcome { continue }
            done += 1
        }
        steps.append("roll (final)")
        if let failure = try roll(full: false) { return report(seed, steps, failure) }
        // Review F3: settling is idempotent. Every day settled again, with no
        // input changed, must leave every row exactly as it was.
        steps.append("settle every day again")
        let settled = try ledgerSnapshot(projectId: project.id)
        let changed = try BillingRollup.recomputeOwnedEntries(database: database)
        let again = try ledgerSnapshot(projectId: project.id)
        if changed != 0 || again != settled {
            let moved = again.filter { settled[$0.key] != $0.value }.map(\.key)
                + settled.keys.filter { again[$0] == nil }
            return report(seed, steps, "settling again changed \(changed) entries: \(moved.sorted())")
        }
        return nil
    }

    /// Every entry of the project as the bill reads it, by id.
    private func ledgerSnapshot(projectId: String) throws -> [String: String] {
        let keys = ["day", "raw_seconds", "billed_seconds", "amount_cents", "billed_ranges", "status", "locked",
                    "origin", "supplements_entry_id", "description", "started_at", "ended_at", "client_id",
                    "currency", "rate_cents"]
        var rows: [String: String] = [:]
        try database.query("""
            SELECT id, \(keys.joined(separator: ", ")) FROM billing_entry WHERE project_id = ?
        """, params: [projectId]) { row in
            rows[row["id"] ?? ""] = keys.map { key -> String in
                let value: String? = row[key]
                return value ?? "<nil>"
            }.joined(separator: "|")
        }
        return rows
    }

    /// What an entry is, independent of its random id and creation instant,
    /// so a seed's picks replay the same way on every run. Two entries can
    /// agree on every figure (two empty supplements, say), so the key also
    /// carries what the entry holds and owns — its segments' identities and
    /// its recorded ranges — and, for a supplement, its root's key.
    private func stableKey(_ entry: BillingEntryDTO, depth: Int = 0) throws -> String {
        var ranges = "<nil>"
        try database.query("SELECT billed_ranges FROM billing_entry WHERE id = ?", params: [entry.id]) { row in
            ranges = row["billed_ranges"] ?? "<nil>"
        }
        let segments = try database.billingSegmentsForEntry(id: entry.id)
            .map { "\($0.sessionId)|\($0.startedAt)" }.sorted().joined(separator: ",")
        var root = "root"
        if let rootId = entry.supplementsEntryId {
            root = "supplement of "
            if depth == 0, let parent = try database.billingEntry(id: rootId) {
                root += try stableKey(parent, depth: 1)
            }
        }
        return [entry.day, entry.groupKey, root, entry.startedAt, entry.endedAt, String(entry.rateCents),
                String(entry.rawSeconds), entry.status, entry.origin, ranges, segments]
            .joined(separator: "|")
    }

    private func label(_ entry: BillingEntryDTO) -> String {
        let kind = entry.supplementsEntryId != nil ? "supplement" : entry.groupKey
        return "[\(entry.day) \(kind) \(entry.startedAt)–\(entry.endedAt) \(entry.rawSeconds)s]"
    }

    private func edited(_ entry: BillingEntryDTO) -> BillingEntryDTO {
        copy(entry, day: entry.day, billedSeconds: entry.billedSeconds + 60)
    }

    /// `blank` moves as the Billables editor does, clearing the shown times.
    private func moved(_ entry: BillingEntryDTO, to day: String, blank: Bool = false) -> BillingEntryDTO {
        copy(entry, day: day, billedSeconds: entry.billedSeconds, blank: blank)
    }

    /// The shown times typed into `entry` in the Billables editor.
    private func typed(_ entry: BillingEntryDTO, start: String, end: String) -> BillingEntryDTO {
        copy(entry, day: entry.day, billedSeconds: entry.billedSeconds, times: (start, end))
    }

    private func copy(
        _ entry: BillingEntryDTO, day: String, billedSeconds: Int, blank: Bool = false,
        times: (String, String)? = nil
    ) -> BillingEntryDTO {
        BillingEntryDTO(
            id: entry.id, projectId: entry.projectId, clientId: entry.clientId, day: day,
            groupKey: entry.groupKey,
            startedAt: times?.0 ?? (blank ? "" : entry.startedAt), endedAt: times?.1 ?? (blank ? "" : entry.endedAt),
            rawSeconds: entry.rawSeconds, billedSeconds: billedSeconds, rateCents: entry.rateCents,
            currency: entry.currency, amountCents: entry.amountCents, roundingMinutes: entry.roundingMinutes,
            roundingMode: entry.roundingMode, status: entry.status, description: entry.description,
            origin: entry.origin, locked: entry.locked, supplementsEntryId: entry.supplementsEntryId,
            createdAt: entry.createdAt, updatedAt: entry.updatedAt
        )
    }

    private func sessionIds(_ project: BillingProjectDTO) throws -> [String] {
        var ids: [String] = []
        try database.query("""
            SELECT DISTINCT session_id FROM billing_segment WHERE project_id = ? ORDER BY session_id
        """, params: [project.id]) { row in ids.append(row["session_id"] ?? "") }
        return ids
    }

    /// A session's derived runs as they stand, frozen ones included — a
    /// backfill derives the same activity again.
    private func currentRuns(_ sessionId: String) throws -> [(start: Int, end: Int)] {
        var runs: [(start: Int, end: Int)] = []
        try database.query("""
            SELECT started_at, seconds FROM billing_segment
            WHERE session_id = ? AND ended_at <> '' ORDER BY started_at
        """, params: [sessionId]) { row in
            let start: String = row["started_at"] ?? ""
            let seconds: Int = row["seconds"] ?? 0
            if let epoch = UTCTimestamp.epochSeconds(start) {
                let minute = (epoch - Self.nightBase) / 60
                runs.append((minute, minute + seconds / 60))
            }
        }
        return runs
    }

    /// What an entry owns: its recorded ranges, or, recorded never, its
    /// segments' intervals.
    private func ownedRanges(_ entryId: String) throws -> [BillingRange] {
        var recorded: String?
        try database.query("SELECT billed_ranges FROM billing_entry WHERE id = ?", params: [entryId]) { row in
            recorded = row["billed_ranges"]
        }
        if let recorded { return BillingRange.decode(recorded) }
        return BillingRange.intervals(of: try database.billingSegmentsForEntry(id: entryId))
    }

    /// Every entry and segment row, printed for a single-seed replay.
    private func debugDump() throws {
        try database.query("""
            SELECT id, day, group_key, supplements_entry_id, raw_seconds, status, locked, billed_ranges,
                   started_at, ended_at, created_at FROM billing_entry ORDER BY day, created_at
        """) { row in
            let fields: [String] = ["id", "day", "group_key", "supplements_entry_id", "raw_seconds", "status",
                                    "locked", "billed_ranges", "started_at", "ended_at", "created_at"].map { key in
                let value: String? = row[key]
                return "\(key)=\(value ?? "nil")"
            }
            print("DUMP entry", fields.joined(separator: " "))
        }
        try database.query("""
            SELECT session_id, entry_id, started_at, ended_at, seconds FROM billing_segment ORDER BY started_at
        """) { row in
            let fields: [String] = ["session_id", "entry_id", "started_at", "ended_at", "seconds"].map { key in
                let value: String? = row[key]
                return "\(key)=\(value ?? "nil")"
            }
            print("DUMP segment", fields.joined(separator: " "))
        }
    }

    private func report(_ seed: UInt64, _ steps: [String], _ failure: String) -> String {
        "seed \(seed): \(failure)\n  " + steps.joined(separator: "\n  ")
    }
}
// swiftlint:enable type_body_length file_length
