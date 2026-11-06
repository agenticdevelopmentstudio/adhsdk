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
        let outcome = try PipelineDrainer(spool: spool, archive: archive, normalizer: ReplayTestNormalizer(),
                                          store: live, batchSize: 7).drainUntilEmpty()
        XCTAssertFalse(outcome.failed)
        // k3 and k10 came again with other bytes: kept as two conflict copies.
        XCTAssertEqual(outcome.conflictCopies, 2)
        XCTAssertEqual(try archive.count(), 50)

        let rebuilt = try makeStore("rebuilt.db")
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(),
                                         into: rebuilt, chunk: 10)
        XCTAssertEqual(report.records, 50)
        XCTAssertEqual(report.failed, 0)
        // The conflict copies replay into nothing: skipped, not failed.
        XCTAssertEqual(report.skipped, 2)
        XCTAssertEqual(report.skippedIDs.count, 2)
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
                                         chunk: 5, progress: { progress.add($0.records) })
        XCTAssertEqual(report.normalized, 12)
        XCTAssertEqual(try store.counts().events, 12)
        XCTAssertEqual(progress.values, [5, 10, 12])
        XCTAssertEqual(report.provider, "mock")
        XCTAssertEqual(report.lastID, try archive.maxID())
    }

    func testReplayChunkRespectsByteBudgetButAlwaysTakesOneRecord() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<3).map { record("k\($0)") })
        let store = try makeStore("e.db")
        let progress = ProgressLog()
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: store,
                                         chunk: 100, maxBytes: 1, progress: { progress.add($0.records) })
        XCTAssertEqual(progress.values, [1, 2, 3])
        XCTAssertEqual(report.normalized, 3)
        XCTAssertEqual(try store.counts().events, 3)
    }

    func testReplayResumesAfterLastID() throws {
        let archive = try makeArchive()
        let ids = try archive.append((0..<10).map { record("k\($0)") }).ids
        let full = try makeStore("full.db")
        _ = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: full, chunk: 3)

        // An interrupted replay got as far as ids[5]; resume from its lastID.
        let interrupted = try makeStore("interrupted.db")
        let firstHalf = try ArchiveSlice.copy(archive, upTo: ids[5], to: path("half.db"))
        let early = try Replayer.replay(archive: firstHalf, normalizer: ReplayTestNormalizer(), into: interrupted)
        XCTAssertEqual(early.lastID, ids[5])
        let rest = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: interrupted,
                                       after: early.lastID, chunk: 2)
        XCTAssertEqual(rest.records, 4)
        XCTAssertEqual(rest.lastID, ids[9])
        XCTAssertEqual(try interrupted.canonicalDump(), try full.canonicalDump())

        // Nothing after the last id: the report keeps the starting point.
        let none = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: interrupted,
                                       after: ids[9])
        XCTAssertEqual(none.records, 0)
        XCTAssertEqual(none.lastID, ids[9])
    }

    func testMultiSourceReplayUsesOneBulkWindowAndReportsPerProvider() throws {
        struct OtherNormalizer: Normalizer {
            let provider = "other"
            func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
                var batch = NormalizedBatch()
                batch.events = [NormalizedEvent(
                    dedupKey: "\(record.record.dedupKey)#0", sessionID: "o", kind: .other, providerType: "O",
                    time: record.record.receivedAt, rawRef: record.id)]
                return batch
            }
        }
        let mock = try makeArchive()
        _ = try mock.append((0..<4).map { record("k\($0)") })
        let other = try RawArchive(path: path("other.db"), provider: "other")
        _ = try other.append((0..<3).map {
            RawRecord(provider: "other", sourceKind: "hook", dedupKey: "o\($0)",
                      receivedAt: Date(timeIntervalSince1970: 1_800_000_000), payload: Data("{}".utf8))
        })
        let store = try makeStore("e.db")
        let bulkSeen = LockedFlags()
        let reports = try Replayer.replay(
            sources: [ReplaySource(archive: mock, normalizer: ReplayTestNormalizer()),
                      ReplaySource(archive: other, normalizer: OtherNormalizer())],
            into: store, chunk: 2,
            progress: { _ in bulkSeen.add((try? store.isInBulkLoad()) ?? false) })
        XCTAssertEqual(reports.map(\.provider), ["mock", "other"])
        XCTAssertEqual(reports.map(\.records), [4, 3])
        XCTAssertEqual(try store.counts().events, 7)
        XCTAssertFalse(bulkSeen.values.isEmpty)
        XCTAssertTrue(bulkSeen.values.allSatisfy { $0 }, "every chunk runs inside the one bulk window")
        XCTAssertFalse(try store.isInBulkLoad())
        let indexes = try store.indexNames()
        XCTAssertTrue(["events_session_time", "events_time"].allSatisfy(indexes.contains), "\(indexes)")
    }

    func testReplayRefusesDuplicateProviderOrMismatchedNormalizerBeforeTouchingTheStore() throws {
        let archive = try makeArchive()
        _ = try archive.append([record("k0")])
        let store = try makeStore("e.db")
        XCTAssertThrowsError(try Replayer.replay(
            sources: [ReplaySource(archive: archive, normalizer: ReplayTestNormalizer()),
                      ReplaySource(archive: archive, normalizer: ReplayTestNormalizer(), after: 5)],
            into: store)) { error in
            XCTAssertEqual(error as? PipelineError, .duplicateProvider("mock"))
        }
        struct OtherNormalizer: Normalizer {
            let provider = "other"
            func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch { NormalizedBatch() }
        }
        XCTAssertThrowsError(
            try Replayer.replay(archive: archive, normalizer: OtherNormalizer(), into: store)) { error in
            XCTAssertEqual(error as? PipelineError, .normalizerMismatch(archive: "mock", normalizer: "other"))
        }
        XCTAssertEqual(try store.counts().events, 0)
        XCTAssertFalse(try store.isInBulkLoad())
    }

    // MARK: - Live replay

    func testLiveReplayKeepsIndexesStopsAtThroughAndResumesFromItsCheckpoint() throws {
        let archive = try makeArchive()
        let ids = try archive.append((0..<10).map { record("k\($0)") }).ids
        let full = try makeStore("full.db")
        _ = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(), into: full)

        let store = try makeStore("e.db")
        let expectedIndexes = try store.indexNames()
        let bulkSeen = LockedFlags()
        let progress = ProgressLog()
        // Chunks of 4 against a bound of ids[5]: the second chunk is cut at the bound.
        let first = try Replayer.replayLive(
            ReplaySource(archive: archive, normalizer: ReplayTestNormalizer(), checkpointKey: "cursor",
                         through: ids[5]),
            into: store, chunk: 4,
            progress: { report in
                bulkSeen.add(((try? store.isInBulkLoad()) ?? true)
                             || ((try? store.indexNames()) ?? []) != expectedIndexes)
                progress.add(report.records)
            })
        XCTAssertEqual(progress.values, [4, 6])
        XCTAssertTrue(bulkSeen.values.allSatisfy { !$0 }, "a live replay never drops the indexes")
        XCTAssertFalse(first.stopped)
        XCTAssertEqual(first.lastID, ids[5])
        XCTAssertEqual(try store.metaValue(forKey: "cursor"), String(ids[5]))
        XCTAssertEqual(try store.counts().events, 6)

        // A bound already reached reads nothing.
        let none = try Replayer.replayLive(
            ReplaySource(archive: archive, normalizer: ReplayTestNormalizer(), after: ids[5], through: ids[5]),
            into: store)
        XCTAssertEqual(none.records, 0)
        XCTAssertEqual(none.lastID, ids[5])

        // Resuming from the checkpoint through the end gives the full replay's rows.
        let after = try XCTUnwrap(try store.metaValue(forKey: "cursor").flatMap { Int64($0) })
        let rest = try Replayer.replayLive(
            ReplaySource(archive: archive, normalizer: ReplayTestNormalizer(), after: after, checkpointKey: "cursor",
                         through: ids[9]),
            into: store, chunk: 3)
        XCTAssertEqual(rest.records, 4)
        XCTAssertEqual(rest.lastID, ids[9])
        XCTAssertEqual(try store.canonicalDump(), try full.canonicalDump())
    }

    func testLiveReplayRefusesABulkLoadWhileItRunsAndStopsWhenAsked() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<6).map { record("k\($0)") })
        let store = try makeStore("e.db")
        let refusals = LockedFlags()
        let chunks = ProgressLog()
        let report = try Replayer.replayLive(
            ReplaySource(archive: archive, normalizer: ReplayTestNormalizer()),
            into: store, chunk: 2,
            shouldContinue: { chunks.values.count < 2 },
            progress: { report in
                chunks.add(report.records)
                do {
                    try store.beginBulkLoad()
                    try? store.endBulkLoad()
                    refusals.add(false)
                } catch {
                    refusals.add((error as? EventStoreError) == .liveWritersAttached(count: 1))
                }
            })
        XCTAssertTrue(report.stopped)
        XCTAssertEqual(report.records, 4)
        XCTAssertEqual(refusals.values, [true, true])
        // Detached once it returns: a bulk load may start again.
        XCTAssertNoThrow(try store.beginBulkLoad())
        XCTAssertNoThrow(try store.endBulkLoad())
    }
}

/// Copies the archive's rows up to an id into a new archive file, preserving ids:
/// an archive as it stood when an interrupted replay stopped.
private enum ArchiveSlice {
    static func copy(_ source: RawArchive, upTo lastID: Int64, to path: String) throws -> RawArchive {
        let slice = try RawArchive(path: path, provider: source.provider)
        let records = try source.records(after: 0, limit: Int.max).filter { $0.id <= lastID }
        _ = try slice.append(records.map(\.record))
        return slice
    }
}

private final class LockedFlags: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [Bool] = []
    func add(_ value: Bool) { lock.lock(); items.append(value); lock.unlock() }
    var values: [Bool] { lock.lock(); defer { lock.unlock() }; return items }
}

private final class ProgressLog: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [Int] = []
    func add(_ value: Int) { lock.lock(); items.append(value); lock.unlock() }
    var values: [Int] { lock.lock(); defer { lock.unlock() }; return items }
}
