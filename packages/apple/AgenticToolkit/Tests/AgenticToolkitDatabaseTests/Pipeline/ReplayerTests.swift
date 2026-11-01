import Foundation
import XCTest
@testable import AgenticToolkitDatabase

private struct ReplayTestNormalizer: Normalizer {
    let provider = "mock"
    struct Bad: Error {}
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        if record.record.payload == Data("BAD".utf8) { throw Bad() }
        let object = try JSONSerialization.jsonObject(with: record.record.payload) as? [String: Any]
        let session = object?["session"] as? String ?? "s"
        var batch = NormalizedBatch()
        batch.events = [NormalizedEvent(
            dedupKey: "\(record.record.dedupKey)#0", sessionID: session, kind: .other,
            providerType: "T", time: record.record.receivedAt, rawRef: record.id)]
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
            records.append(record("k\(idx)", time: time, payload: "{\"session\":\"s\(idx % 3)\"}"))
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

    func testReplayLeavesArchiveUnmodified() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<15).map { record("k\($0)") } + [record("bad", payload: "BAD")])
        let before = try snapshot(archive)
        let report = try Replayer.replay(archive: archive, normalizer: ReplayTestNormalizer(),
                                         into: try makeStore("e.db"), chunk: 4)
        XCTAssertEqual(report.records, 16)
        let after = try snapshot(archive)
        XCTAssertEqual(after.records, before.records)
        XCTAssertEqual(after.count, before.count)
        XCTAssertEqual(after.maxID, before.maxID)
        XCTAssertEqual(before.count, 16)
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
