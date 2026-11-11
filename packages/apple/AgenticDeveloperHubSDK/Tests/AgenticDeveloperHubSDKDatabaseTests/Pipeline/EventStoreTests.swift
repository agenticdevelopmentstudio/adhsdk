import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class EventStoreTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-events-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeStore(_ name: String = EventStore.fileName) throws -> EventStore {
        try EventStore(path: tmpDir.appendingPathComponent(name).path)
    }

    private func date(_ seconds: Double) -> Date { Date(timeIntervalSince1970: 1_800_000_000 + seconds) }

    private func batch(_ upsert: SessionUpsert) -> NormalizedBatch {
        var batch = NormalizedBatch()
        batch.sessions = [upsert]
        return batch
    }

    private func sampleBatch() -> NormalizedBatch {
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "k#0", sessionID: "s1", kind: .toolCall, providerType: "PreToolUse",
            time: date(1), cwd: "/a", toolName: "Bash", summary: "ls",
            attrs: ["x": .number(1)], rawRef: 7)]
        batch.turns = [TurnRow(
            dedupKey: "t#0", sessionID: "s1", time: date(2), model: "m", inputTokens: 3,
            outputTokens: 4, costUSD: 0.5, rawRef: 8)]
        batch.messages = [MessageRow(
            dedupKey: "m#msg", uuid: "u1", sessionID: "s1", role: "user", time: date(3), text: "hi", rawRef: 9)]
        batch.sessions = [SessionUpsert(sessionID: "s1", asOf: date(1), cwd: "/a", startedAt: date(1))]
        return batch
    }

    func testWriteIsIdempotent() throws {
        let store = try makeStore()
        try store.write(sampleBatch(), provider: "mock")
        let counts = try store.counts()
        let dump = try store.canonicalDump()
        try store.write(sampleBatch(), provider: "mock")
        XCTAssertEqual(try store.counts(), counts)
        XCTAssertEqual(counts, EventStoreCounts(sessions: 1, events: 1, turns: 1, messages: 1))
        XCTAssertEqual(try store.canonicalDump(), dump)
    }

    func testWriteReturnsOnlyWhatChanged() throws {
        let store = try makeStore()
        let first = try store.write(sampleBatch(), provider: "mock")
        XCTAssertEqual(first.events.count, 1)
        XCTAssertEqual(first.turns.count, 1)
        XCTAssertEqual(first.messages.count, 1)
        XCTAssertEqual(first.sessions.count, 1)
        XCTAssertTrue(try store.write(sampleBatch(), provider: "mock").isEmpty)
        // A newer observation of the session changes only the session.
        var newer = NormalizedBatch()
        newer.sessions = [SessionUpsert(sessionID: "s1", asOf: date(9), title: "later")]
        let changed = try store.write(newer, provider: "mock")
        XCTAssertEqual(changed.sessions.map(\.sessionID), ["s1"])
        XCTAssertTrue(changed.events.isEmpty && changed.turns.isEmpty && changed.messages.isEmpty)
    }

    func testTurnMergeIsOrderIndependent() throws {
        // One turn seen by three records: different as_of, overlapping attrs, and a tie.
        let rows = [
            TurnRow(dedupKey: "turn-1", sessionID: "s", time: date(1), asOf: date(1), model: "m1",
                    inputTokens: 10, outputTokens: 1, costUSD: 0.1,
                    attrs: ["kind": .string("first"), "a": .number(1)], rawRef: 1),
            TurnRow(dedupKey: "turn-1", sessionID: "s", time: date(1), asOf: date(3), model: "m3",
                    account: "acct", inputTokens: 30, outputTokens: 3,
                    attrs: ["kind": .string("third"), "cache_creation_1h_tokens": .number(7)], rawRef: 3),
            TurnRow(dedupKey: "turn-1", sessionID: "s", time: date(1), asOf: date(3), model: "m3b",
                    inputTokens: 20, outputTokens: 2, costUSD: 0.2,
                    attrs: ["kind": .string("tie"), "a": .number(2)], rawRef: 2)
        ]
        var dumps: Set<[String]> = []
        for (index, order) in permutations(rows).enumerated() {
            let store = try makeStore("turn-perm-\(index).db")
            for row in order {
                var batch = NormalizedBatch()
                batch.turns = [row]
                try store.write(batch, provider: "mock")
            }
            XCTAssertEqual(try store.counts().turns, 1)
            dumps.insert(try store.canonicalDump())
            // All three in one batch, in this order, gives the same row.
            let together = try makeStore("turn-batch-\(index).db")
            var batch = NormalizedBatch()
            batch.turns = order
            try together.write(batch, provider: "mock")
            dumps.insert(try together.canonicalDump())
        }
        XCTAssertEqual(dumps.count, 1, "\(dumps)")
        let dump = try XCTUnwrap(dumps.first?.first(where: { $0.contains("\"table\":\"turns\"") }))
        XCTAssertTrue(dump.contains("\"account\":\"acct\""), dump)
        // Canonical JSON writes a whole number without a fraction (1800000003, not 1800000003.0).
        XCTAssertTrue(dump.contains("\"as_of\":\(Int(date(3).timeIntervalSince1970))"), dump)
    }

    func testSameMessageUUIDInTwoSessionsIsTwoRowsAndFirstCopyWinsWithinOne() throws {
        let store = try makeStore()
        func message(_ key: String, session: String, text: String) -> NormalizedBatch {
            var batch = NormalizedBatch()
            batch.messages = [MessageRow(dedupKey: key, uuid: "shared-uuid", sessionID: session, role: "user",
                                         time: date(1), text: text, rawRef: 1)]
            return batch
        }
        try store.write(message("a#msg", session: "original", text: "one"), provider: "mock")
        try store.write(message("b#msg", session: "resumed", text: "two"), provider: "mock")
        XCTAssertEqual(try store.counts().messages, 2)
        let again = try store.write(message("c#msg", session: "original", text: "three"), provider: "mock")
        XCTAssertTrue(again.messages.isEmpty)
        XCTAssertEqual(try store.counts().messages, 2)
        let original = try XCTUnwrap(try store.canonicalDump().first { $0.contains("\"session_id\":\"original\"") })
        XCTAssertTrue(original.contains("\"text\":\"one\"") && original.contains("\"dedup_key\":\"a#msg\""),
                      original)
    }

    private func permutations<T>(_ items: [T]) -> [[T]] {
        guard items.count > 1 else { return [items] }
        var result: [[T]] = []
        for (index, item) in items.enumerated() {
            var rest = items
            rest.remove(at: index)
            for tail in permutations(rest) { result.append([item] + tail) }
        }
        return result
    }

    func testSessionMergeIsOrderIndependent() throws {
        // A at t=1 sets cwd=a; B at t=3 sets cwd=nil; C at t=2 sets cwd=c.
        // Titles tie on as_of; attrs overlap with a tie.
        let upserts = [
            SessionUpsert(sessionID: "s", asOf: date(1), cwd: "a", model: "m1", title: "alpha",
                          status: "active", startedAt: date(1), attrs: ["k": .string("one"), "t": .string("x")]),
            SessionUpsert(sessionID: "s", asOf: date(3), cwd: nil, model: "m3", title: "beta",
                          status: "ended", endedAt: date(3), attrs: ["k": .string("three")]),
            SessionUpsert(sessionID: "s", asOf: date(2), cwd: "c", project: "p", title: "gamma",
                          startedAt: date(0), attrs: ["k": .string("two"), "t": .string("y")]),
            SessionUpsert(sessionID: "s", asOf: date(3), title: "zeta", attrs: ["k": .string("tie")])
        ]
        var dumps: Set<[String]> = []
        for (index, order) in permutations(Array(upserts.prefix(3))).enumerated() {
            let store = try makeStore("perm-\(index).db")
            for upsert in order { try store.write(batch(upsert), provider: "mock") }
            dumps.insert(try store.canonicalDump())
        }
        XCTAssertEqual(dumps.count, 1)
        let dump = try XCTUnwrap(dumps.first?.first)
        XCTAssertTrue(dump.contains("\"cwd\":\"c\""), dump)

        // With the as_of tie included, all 24 orders still agree.
        var tieDumps: Set<[String]> = []
        for (index, order) in permutations(upserts).enumerated() {
            let store = try makeStore("tie-\(index).db")
            for upsert in order { try store.write(batch(upsert), provider: "mock") }
            tieDumps.insert(try store.canonicalDump())
        }
        XCTAssertEqual(tieDumps.count, 1)
        let tieDump = try XCTUnwrap(tieDumps.first?.first)
        XCTAssertTrue(tieDump.contains("\"title\":\"zeta\""), tieDump)
    }

    func testStartedAtMinEndedAtMaxIgnoresNil() throws {
        let store = try makeStore()
        try store.write(batch(SessionUpsert(sessionID: "s", asOf: date(5), startedAt: date(5), endedAt: date(5))),
                        provider: "mock")
        try store.write(batch(SessionUpsert(sessionID: "s", asOf: date(6))), provider: "mock")
        try store.write(batch(SessionUpsert(sessionID: "s", asOf: date(4), startedAt: date(4), endedAt: date(4))),
                        provider: "mock")
        let dump = try XCTUnwrap(try store.canonicalDump().first)
        let row = try JSONDecoder().decode([String: NormalizedValue].self, from: Data(dump.utf8))
        XCTAssertEqual(row["started_at"], .number(date(4).timeIntervalSince1970))
        XCTAssertEqual(row["ended_at"], .number(date(5).timeIntervalSince1970))
        XCTAssertEqual(row["as_of"], .number(date(6).timeIntervalSince1970))
    }

    func testAttrsMergePerKeyByAsOf() throws {
        let store = try makeStore()
        try store.write(batch(SessionUpsert(sessionID: "s", asOf: date(2), attrs: ["a": .string("new")])),
                        provider: "mock")
        try store.write(batch(SessionUpsert(
            sessionID: "s", asOf: date(1), attrs: ["a": .string("old"), "b": .string("only")])), provider: "mock")
        let dump = try XCTUnwrap(try store.canonicalDump().first)
        XCTAssertTrue(dump.contains("{\\\"a\\\":\\\"new\\\",\\\"b\\\":\\\"only\\\"}"), dump)
    }

    func testNumericTieKeepsTheLargerNumberInEitherOrder() throws {
        for order in [[9.0, 10.0], [10.0, 9.0]] {
            var fields = EventStore.MergedFields()
            for value in order { fields.offer("attrs.tokens", .number(value), asOf: 1) }
            XCTAssertEqual(fields.values["attrs.tokens"], .number(10), "\(order)")
        }
    }

    func testTieBreakIsTotalEvenForValuesJSONCannotEncode() throws {
        // NaN and infinity never reach a conforming store, but the tie-break must not
        // depend on arrival order even if one does.
        let offers: [NormalizedValue] = [.number(.nan), .number(1), .number(.infinity), .string("x"), .bool(true)]
        var winners: Set<String> = []
        for order in permutations(offers) {
            var fields = EventStore.MergedFields()
            for value in order { fields.offer("attrs.v", value, asOf: 1) }
            winners.insert(String(describing: fields.values["attrs.v"]))
        }
        XCTAssertEqual(winners.count, 1, "\(winners)")
    }

    func testNonFiniteFieldsNamesEveryNaNOrInfinity() throws {
        var batch = sampleBatch()
        XCTAssertEqual(batch.nonFiniteFields, [])
        batch.turns = [TurnRow(dedupKey: "t", sessionID: "s", time: date(1), costUSD: .infinity,
                               attrs: ["deep": .array([.object(["x": .number(.nan)])])], rawRef: 1)]
        XCTAssertEqual(batch.nonFiniteFields, ["t.attrs.deep", "t.costUSD"])
        XCTAssertFalse(NormalizedValue.object(["a": .array([.number(-.infinity)])]).isFinite)
        XCTAssertTrue(NormalizedValue.object(["a": .array([.number(1), .string("nan")])]).isFinite)
    }

    func testEventsFromTwoProvidersWithSameKeyCoexist() throws {
        let store = try makeStore()
        try store.write(sampleBatch(), provider: "mock")
        try store.write(sampleBatch(), provider: "other")
        XCTAssertEqual(try store.counts(), EventStoreCounts(sessions: 2, events: 2, turns: 2, messages: 2))
    }

    private let indexNames = ["events_session_time", "events_time", "events_type_time", "turns_time",
                              "turns_session", "messages_session_time", "messages_time"]

    private func presentIndexes(_ path: String) throws -> Set<String> {
        let queue = try DatabaseQueue(path: path)
        return try queue.read { conn in
            Set(try String.fetchAll(conn, sql: "SELECT name FROM sqlite_master WHERE type = 'index'"))
        }
    }

    /// A store file made before `events_type_time` existed gets it on the next
    /// open: the insights and cache-miss reads filter on (provider, provider_type, time).
    func testOpeningAnExistingStoreAddsTheTypeTimeIndex() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        do {
            let store = try makeStore()
            try store.write(sampleBatch(), provider: "mock")
        }
        let queue = try DatabaseQueue(path: path)
        try queue.write { try $0.execute(sql: "DROP INDEX events_type_time") }
        XCTAssertFalse(try presentIndexes(path).contains("events_type_time"))
        let reopened = try makeStore()
        XCTAssertTrue(try presentIndexes(path).contains("events_type_time"))
        XCTAssertEqual(try reopened.counts().events, 1)
    }

    func testBulkLoadDropsAndRebuildsIndexes() throws {
        let store = try makeStore()
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        XCTAssertTrue(Set(indexNames).isSubset(of: try presentIndexes(path)))
        try store.beginBulkLoad()
        XCTAssertTrue(Set(indexNames).isDisjoint(with: try presentIndexes(path)))
        try store.write(sampleBatch(), provider: "mock")
        try store.endBulkLoad()
        XCTAssertTrue(Set(indexNames).isSubset(of: try presentIndexes(path)))
        try store.endBulkLoad()
    }

    func testBulkLoadFlagIsSetWhileLoadingAndClearedAtEnd() throws {
        let store = try makeStore()
        XCTAssertFalse(try store.isInBulkLoad())
        try store.beginBulkLoad()
        XCTAssertTrue(try store.isInBulkLoad())
        try store.endBulkLoad()
        XCTAssertFalse(try store.isInBulkLoad())
        XCTAssertEqual(try store.indexNames().intersection(indexNames), Set(indexNames))
    }

    func testFailedIndexRebuildStillEndsTheBulkWindowAndLeavesTheFlagForRepair() throws {
        let store = try makeStore()
        try store.beginBulkLoad()
        // Hide a table the indexes need, so the rebuild throws.
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        let saboteur = try DatabaseQueue(path: path)
        try saboteur.write { try $0.execute(sql: "ALTER TABLE events RENAME TO events_hidden") }
        XCTAssertThrowsError(try store.endBulkLoad())
        // The in-process window is closed: a live writer may attach again.
        XCTAssertNoThrow(try store.attachLiveWriter())
        store.detachLiveWriter()
        // The on-disk flag is still set, so the next open finishes the rebuild.
        XCTAssertTrue(try store.isInBulkLoad())
        try saboteur.write { try $0.execute(sql: "ALTER TABLE events_hidden RENAME TO events") }
        let reopened = try EventStore(path: path)
        XCTAssertFalse(try reopened.isInBulkLoad())
        XCTAssertEqual(try reopened.indexNames().intersection(indexNames), Set(indexNames))
    }

    func testOpeningAfterACrashMidBulkLoadRebuildsIndexesAndClearsFlag() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        do {
            let crashed = try makeStore()
            try crashed.beginBulkLoad()
            try crashed.write(sampleBatch(), provider: "mock")
            XCTAssertTrue(Set(indexNames).isDisjoint(with: try presentIndexes(path)))
            // The process dies here: endBulkLoad never runs.
        }
        let reopened = try makeStore()
        XCTAssertFalse(try reopened.isInBulkLoad())
        XCTAssertTrue(Set(indexNames).isSubset(of: try presentIndexes(path)))
        XCTAssertEqual(try reopened.counts().events, 1)
        // And a fresh bulk load is allowed again.
        try reopened.beginBulkLoad()
        try reopened.endBulkLoad()
    }

    func testReadHonoursItsDeadline() throws {
        let store = try makeStore()
        // An unbounded counting CTE: reads nothing, writes nothing, runs for
        // far longer than any deadline here unless the deadline ejects it.
        let start = Date()
        XCTAssertThrowsError(
            try store.read(deadline: .milliseconds(200)) { conn in
                try Int.fetchOne(conn, sql: """
                    WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 10000000000)
                    SELECT count(*) FROM seq
                    """)
            }
        ) { error in
            guard case BoundedDatabaseError.deadlineExceeded(let lane, _) = error else {
                return XCTFail("expected deadlineExceeded, got \(error)")
            }
            XCTAssertEqual(lane, "read")
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 3, "ejected near its own deadline")
        // Without a deadline the store's default applies and a short read completes.
        XCTAssertEqual(try store.read { conn in try Int.fetchOne(conn, sql: "SELECT 1") }, 1)
    }

    private func turnBatch(_ keys: [String]) -> NormalizedBatch {
        var batch = NormalizedBatch()
        batch.turns = keys.map {
            TurnRow(dedupKey: $0, sessionID: "s1", time: date(2), model: "m", inputTokens: 1,
                    outputTokens: 1, costUSD: nil, rawRef: 1)
        }
        return batch
    }

    private func turnIds(_ path: String) throws -> [String: Int64] {
        let queue = try DatabaseQueue(path: path)
        return try queue.read { conn in
            var ids: [String: Int64] = [:]
            for row in try Row.fetchAll(conn, sql: "SELECT dedup_key, id FROM turns") { ids[row[0]] = row[1] }
            return ids
        }
    }

    /// The usage recount walks "turns after id N" and the trim deletes only
    /// turns at or below N, so an id freed by deleting the newest-id turns
    /// must never be handed out again.
    func testTurnIdsAreNeverReusedAfterTheNewestRowsGo() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        let store = try makeStore()
        try store.write(turnBatch(["a", "b", "c"]), provider: "mock")
        let queue = try DatabaseQueue(path: path)
        try queue.write { try $0.execute(sql: "DELETE FROM turns WHERE dedup_key IN ('b', 'c')") }
        try store.write(turnBatch(["d"]), provider: "mock")
        let ids = try turnIds(path)
        XCTAssertEqual(ids["d"], 4)
    }

    /// A store made when `turns` had no AUTOINCREMENT is rebuilt on open:
    /// every row keeps its id, and the sequence starts above every id the old
    /// table could have handed out (rows held plus rows trimmed).
    func testOpeningAStoreWithoutTurnAutoincrementRebuildsItKeepingIds() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        do {
            let store = try makeStore()
            try store.write(turnBatch(["a", "b", "c"]), provider: "mock")
        }
        let queue = try DatabaseQueue(path: path)
        try queue.write { conn in
            try conn.execute(sql: """
                CREATE TABLE turns_old (
                    id INTEGER PRIMARY KEY,
                    provider TEXT NOT NULL, dedup_key TEXT NOT NULL, session_id TEXT NOT NULL, time REAL NOT NULL,
                    model TEXT, account TEXT, agent TEXT, tool_name TEXT,
                    input_tokens INTEGER NOT NULL, output_tokens INTEGER NOT NULL,
                    cache_read_tokens INTEGER NOT NULL, cache_write_tokens INTEGER NOT NULL,
                    cost_usd REAL, raw_ref INTEGER NOT NULL,
                    as_of REAL NOT NULL, attrs TEXT NOT NULL DEFAULT '{}',
                    field_as_of TEXT NOT NULL DEFAULT '{}',
                    UNIQUE (provider, dedup_key))
                """)
            try conn.execute(sql: "INSERT INTO turns_old SELECT * FROM turns")
            try conn.execute(sql: "DROP TABLE turns")
            try conn.execute(sql: "ALTER TABLE turns_old RENAME TO turns")
            try conn.execute(sql: "DELETE FROM sqlite_sequence WHERE name = 'turns'")
            // The newest turn was trimmed, and an older store's trim had
            // already freed two more ids that a cursor may have passed.
            try conn.execute(sql: "DELETE FROM turns WHERE dedup_key = 'c'")
            try conn.execute(sql: """
                INSERT INTO trimmed_turn_keys(provider, dedup_key) VALUES ('mock', 'c'), ('mock', 'x'), ('mock', 'y')
                """)
        }
        let before = try turnIds(path)
        let reopened = try makeStore()
        let sql = try queue.read { conn in
            try String.fetchOne(conn, sql: "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'turns'")
        }
        XCTAssertTrue(sql?.contains("AUTOINCREMENT") ?? false)
        XCTAssertEqual(try turnIds(path), before)
        XCTAssertTrue(try presentIndexes(path).isSuperset(of: ["turns_time", "turns_session"]))
        try reopened.write(turnBatch(["d"]), provider: "mock")
        // Two held plus three trimmed: no id at or below 5 is handed out again.
        XCTAssertEqual(try turnIds(path)["d"], 6)
    }

    /// A store whose `trimmed_turn_keys` predates `folded` gets the column; its
    /// keys stay, with no fields to correct against.
    func testOpeningAStoreWhoseTrimmedKeysLackFoldedAddsTheColumn() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        do { _ = try makeStore() }
        let queue = try DatabaseQueue(path: path)
        try queue.write { conn in
            try conn.execute(sql: "DROP TABLE trimmed_turn_keys")
            try conn.execute(sql: """
                CREATE TABLE trimmed_turn_keys (provider TEXT NOT NULL, dedup_key TEXT NOT NULL,
                    PRIMARY KEY (provider, dedup_key)) WITHOUT ROWID
                """)
            try conn.execute(sql: "INSERT INTO trimmed_turn_keys VALUES ('mock', 'old')")
        }
        _ = try makeStore()
        let rows = try queue.read { conn in
            try Row.fetchAll(conn, sql: "SELECT dedup_key, folded FROM trimmed_turn_keys")
        }
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?["dedup_key"] as String?, "old")
        XCTAssertNil(rows.first?["folded"] as String?)
    }

    /// A store older than the trim has no `trimmed_turn_keys` either; the
    /// upgrade still opens it, seeding the sequence from the rows held.
    func testOpeningAPreTrimStoreWithoutTurnAutoincrementOpens() throws {
        let path = tmpDir.appendingPathComponent(EventStore.fileName).path
        do {
            let store = try makeStore()
            try store.write(turnBatch(["a", "b"]), provider: "mock")
        }
        let queue = try DatabaseQueue(path: path)
        try queue.write { conn in
            try conn.execute(sql: "CREATE TABLE turns_old AS SELECT * FROM turns")
            try conn.execute(sql: "DROP TABLE turns")
            try conn.execute(sql: "ALTER TABLE turns_old RENAME TO turns")
            try conn.execute(sql: "DELETE FROM sqlite_sequence WHERE name = 'turns'")
            try conn.execute(sql: "DROP TABLE trimmed_turn_keys")
        }
        let before = try turnIds(path)
        let reopened = try makeStore()
        XCTAssertEqual(try turnIds(path), before)
        try reopened.write(turnBatch(["c"]), provider: "mock")
        XCTAssertEqual(try turnIds(path)["c"], 3)
    }

    func testAutoVacuumIsIncremental() throws {
        _ = try makeStore()
        let queue = try DatabaseQueue(path: tmpDir.appendingPathComponent(EventStore.fileName).path)
        let mode = try queue.read { conn in try Int.fetchOne(conn, sql: "PRAGMA auto_vacuum") }
        XCTAssertEqual(mode, 2)
    }

    func testNormalizedValueRoundTrip() throws {
        let value = NormalizedValue.object([
            "n": .null, "b": .bool(true), "d": .number(1.5), "i": .number(3),
            "s": .string("x"), "a": .array([.number(1), .string("y"), .null])
        ])
        let text = try value.canonicalString()
        let decoded = try JSONDecoder().decode(NormalizedValue.self, from: Data(text.utf8))
        XCTAssertEqual(decoded, value)
        XCTAssertEqual(try decoded.canonicalString(), text)
    }
}
