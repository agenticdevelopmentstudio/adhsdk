import CryptoKit
import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

private struct ReplayTestNormalizer: Normalizer {
    let provider = "mock"
    struct Bad: Error {}
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        if record.record.payload == Data("BAD".utf8) { throw Bad() }
        if record.record.payload == Data("NAN".utf8) {
            var batch = NormalizedBatch()
            batch.events = [NormalizedEvent(
                dedupKey: "\(record.record.dedupKey)#0", sessionID: "s", kind: .other, providerType: "T",
                time: record.record.receivedAt, attrs: ["x": .number(.nan)], rawRef: record.id)]
            return batch
        }
        let object = try JSONSerialization.jsonObject(with: record.record.payload) as? [String: Any]
        let session = object?["session"] as? String ?? "s"
        let asOf = (object?["asof"] as? Double).map { Date(timeIntervalSince1970: 1_800_000_000 + $0) }
            ?? record.record.receivedAt
        let seq = object?["n"] as? Double ?? 0
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "\(record.record.dedupKey)#0", sessionID: session, kind: .other,
            providerType: "T", time: record.record.receivedAt, rawRef: record.id)]
        // Fields and as_of vary per record, with ties, so the merge result depends on the rules,
        // not on how records are grouped into batches.
        batch.sessions = [SessionUpsert(
            sessionID: session, asOf: asOf,
            model: seq.truncatingRemainder(dividingBy: 2) == 0 ? "m-a" : "m-b",
            title: "title-\(Int(seq))", status: seq > 40 ? "ended" : "active",
            startedAt: asOf, endedAt: asOf,
            attrs: ["last": .number(seq), "tag\(Int(seq) % 4)": .string("v\(Int(seq))")])]
        return batch
    }
}

final class ReplayerTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-replay-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func path(_ name: String) -> String { tmpDir.appendingPathComponent(name).path }

    private func makeArchive() throws -> RawArchive {
        try RawArchive(path: path("a.db"), provider: "mock")
    }

    private func makeStore(_ name: String) throws -> EventStore {
        try EventStore(path: path(name))
    }

    private func record(_ key: String, time: Double = 1_800_000_000, payload: String? = nil) -> RawRecord {
        RawRecord(provider: "mock", sourceKind: "hook", dedupKey: key,
                  receivedAt: Date(timeIntervalSince1970: time),
                  payload: Data((payload ?? "{\"session\":\"s1\",\"k\":\"\(key)\"}").utf8))
    }

    private func snapshot(_ archive: RawArchive) throws -> (records: [ArchivedRecord], count: Int, maxID: Int64) {
        (try archive.records(after: 0, limit: Int.max), try archive.count(), try archive.maxID())
    }

    func testReplayBuildsSameContentAsLiveDrain() throws {
        let archive = try makeArchive()
        let spool = try ProviderSpool(path: path("s.db"), provider: "mock")
        let live = try makeStore("live.db")
        var records: [RawRecord] = []
        for idx in 0..<48 {
            // Out-of-order times and a couple of sessions.
            let time = 1_800_000_000 + Double((idx * 37) % 48)
            let body = "{\"session\":\"s\(idx % 3)\",\"asof\":\((idx * 37) % 24),\"n\":\(idx)}"
            records.append(record("k\(idx)", time: time, payload: body))
        }
        records.append(record("k3"))
        records.append(record("k10"))
        XCTAssertEqual(records.count, 50)
        try spool.append(records)
        let outcome = PipelineDrainer(spool: spool, archive: archive, normalizer: ReplayTestNormalizer(),
                                      store: live, batchSize: 7).drainUntilEmpty()
        XCTAssertFalse(outcome.failed)
        XCTAssertEqual(try archive.count(), 48)

        let rebuilt = try makeStore("rebuilt.db")
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(),
                                         into: rebuilt, chunk: 10)
        XCTAssertEqual(report.records, 48)
        XCTAssertEqual(report.failed, 0)
        XCTAssertEqual(try rebuilt.canonicalDump(), try live.canonicalDump())
        XCTAssertFalse(try live.canonicalDump().isEmpty)
        XCTAssertEqual(try rebuilt.counts().sessions, 3)
    }

    func testReplayIsIdempotent() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<20).map { record("k\($0)") })
        let store = try makeStore("e.db")
        _ = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store, chunk: 6)
        let first = try store.canonicalDump()
        _ = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store, chunk: 6)
        XCTAssertEqual(try store.canonicalDump(), first)
        XCTAssertEqual(try store.counts().events, 20)
    }

    private func fileSHA256(_ path: String) throws -> String {
        // Fold the WAL into the main file first so it cannot skew the hash.
        let queue = try DatabaseQueue(path: path)
        try queue.writeWithoutTransaction { conn in try conn.execute(sql: "PRAGMA wal_checkpoint(TRUNCATE)") }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func testReplayLeavesArchiveUnmodified() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<15).map { record("k\($0)") } + [record("bad", payload: "BAD")])
        let before = try snapshot(archive)
        let hashBefore = try fileSHA256(path("a.db"))
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(),
                                         into: try makeStore("e.db"), chunk: 4)
        XCTAssertEqual(report.records, 16)
        let after = try snapshot(archive)
        XCTAssertEqual(after.records, before.records)
        XCTAssertEqual(after.count, before.count)
        XCTAssertEqual(after.maxID, before.maxID)
        XCTAssertEqual(before.count, 16)
        XCTAssertEqual(try fileSHA256(path("a.db")), hashBefore)
    }

    func testCorruptArchiveRecordIsReportedAndReplayContinues() throws {
        let archive = try makeArchive()
        let ids = try archive.append((0..<10).map { record("k\($0)") }).ids
        let queue = try DatabaseQueue(path: path("a.db"))
        try queue.write { conn in
            try conn.execute(sql: "UPDATE raw_record SET payload = ?, compression = 'none' WHERE id = ?",
                             arguments: [Data("garbage".utf8), ids[3]])
        }
        let store = try makeStore("e.db")
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store, chunk: 4)
        XCTAssertEqual(report.records, 10)
        XCTAssertEqual(report.normalized, 9)
        XCTAssertEqual(report.failed, 1)
        XCTAssertEqual(Set(report.failures.keys), [ids[3]])
        XCTAssertTrue(try XCTUnwrap(report.failures[ids[3]]).contains("corruptPayload"))
        XCTAssertEqual(try store.counts().events, 9)
    }

    func testIndexesAreRestoredWhenReplayThrows() throws {
        let archive = try makeArchive()
        _ = try archive.append([record("k0"), record("k1", payload: "NAN"), record("k2")])
        let store = try makeStore("e.db")
        XCTAssertThrowsError(try Replayer.replay(
            archive: archive, normalizer: ReplayTestNormalizer(), into: store, chunk: 1))
        XCTAssertEqual(try store.counts().events, 1)
        let indexes = try DatabaseQueue(path: path("e.db")).read { conn in
            Set(try String.fetchAll(conn, sql: "SELECT name FROM sqlite_master WHERE type = 'index'"))
        }
        XCTAssertTrue(["events_session_time", "events_time", "turns_time", "turns_session",
                       "messages_session_time"].allSatisfy(indexes.contains))
    }

    func testReplayReportsFailuresAndContinues() throws {
        let archive = try makeArchive()
        var records = (0..<9).map { record("k\($0)") }
        records.insert(record("bad1", payload: "BAD"), at: 2)
        records.insert(record("bad2", payload: "BAD"), at: 7)
        let ids = try archive.append(records).ids
        let store = try makeStore("e.db")
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store, chunk: 3)
        XCTAssertEqual(report.records, 11)
        XCTAssertEqual(report.normalized, 9)
        XCTAssertEqual(report.failed, 2)
        XCTAssertEqual(Set(report.failures.keys), [ids[2], ids[7]])
        XCTAssertEqual(try store.counts().events, 9)
    }

    func testReplayChunksAcrossBoundaries() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<12).map { record("k\($0)") })
        let store = try makeStore("e.db")
        let progress = ProgressLog()
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store,
                                         chunk: 5, progress: { progress.add($0) })
        XCTAssertEqual(report.normalized, 12)
        XCTAssertEqual(try store.counts().events, 12)
        XCTAssertEqual(progress.values, [5, 10, 12])
    }
}

private final class ProgressLog: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [Int] = []
    func add(_ value: Int) { lock.lock(); items.append(value); lock.unlock() }
    var values: [Int] { lock.lock(); defer { lock.unlock() }; return items }
}
