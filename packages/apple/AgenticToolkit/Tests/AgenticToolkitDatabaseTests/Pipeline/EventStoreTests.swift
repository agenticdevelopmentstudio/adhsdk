import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

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
            uuid: "u1", sessionID: "s1", role: "user", time: date(3), text: "hi", rawRef: 9)]
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
        XCTAssertTrue(dump.contains("\"started_at\":\(date(4).timeIntervalSince1970)"), dump)
        XCTAssertTrue(dump.contains("\"ended_at\":\(date(5).timeIntervalSince1970)"), dump)
        XCTAssertTrue(dump.contains("\"as_of\":\(date(6).timeIntervalSince1970)"), dump)
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

    func testEventsFromTwoProvidersWithSameKeyCoexist() throws {
        let store = try makeStore()
        try store.write(sampleBatch(), provider: "mock")
        try store.write(sampleBatch(), provider: "other")
        XCTAssertEqual(try store.counts(), EventStoreCounts(sessions: 2, events: 2, turns: 2, messages: 2))
    }

    private let indexNames = ["events_session_time", "events_time", "turns_time", "turns_session",
                              "messages_session_time"]

    private func presentIndexes(_ path: String) throws -> Set<String> {
        let queue = try DatabaseQueue(path: path)
        return try queue.read { conn in
            Set(try String.fetchAll(conn, sql: "SELECT name FROM sqlite_master WHERE type = 'index'"))
        }
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

    func testAutoVacuumIsIncremental() throws {
        _ = try makeStore()
        let queue = try DatabaseQueue(path: tmpDir.appendingPathComponent(EventStore.fileName).path)
        let mode = try queue.read { conn in try Int.fetchOne(conn, sql: "PRAGMA auto_vacuum") }
        XCTAssertEqual(mode, 2)
    }

    func testJSONValueRoundTrip() throws {
        let value = JSONValue.object([
            "n": .null, "b": .bool(true), "d": .number(1.5), "i": .number(3),
            "s": .string("x"), "a": .array([.number(1), .string("y"), .null])
        ])
        let text = try value.canonicalString()
        let decoded = try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
        XCTAssertEqual(decoded, value)
        XCTAssertEqual(try decoded.canonicalString(), text)
    }
}
