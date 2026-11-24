import Foundation
import GRDB
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ProviderSpoolTests: XCTestCase {

    private var tmpDir: URL!
    private var path: String { tmpDir.appendingPathComponent(ProviderSpool.fileName(provider: "mock")).path }

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-spool-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeSpool() throws -> ProviderSpool {
        try ProviderSpool(path: path, provider: "mock")
    }

    private func rec(_ key: String, _ payload: Data, provider: String = "mock") -> RawRecord {
        RawRecord(provider: provider, sourceKind: "hook", dedupKey: key,
                  receivedAt: Date(timeIntervalSince1970: 1_800_000_000.5), payload: payload)
    }

    private func rec(_ key: String, _ text: String = "x") -> RawRecord { rec(key, Data(text.utf8)) }

    func testPendingBatchIsArrivalOrderAndHonoursLimit() throws {
        let spool = try makeSpool()
        try spool.append([rec("a"), rec("b")])
        try spool.append([rec("c")])
        let all = try spool.pendingBatch(limit: 10)
        XCTAssertEqual(all.map(\.record.dedupKey), ["a", "b", "c"])
        XCTAssertEqual(all.map(\.id), all.map(\.id).sorted())
        XCTAssertEqual(try spool.pendingBatch(limit: 2).map(\.record.dedupKey), ["a", "b"])
        XCTAssertEqual(try spool.pendingBatch(limit: 0), [])
        XCTAssertEqual(try spool.pendingBatch(limit: -3), [])
    }

    func testPendingBatchHonoursByteBudgetButAlwaysReturnsOne() throws {
        let spool = try makeSpool()
        let ten = String(repeating: "p", count: 10)
        try spool.append([rec("a", ten), rec("b", ten), rec("c", ten), rec("d", String(repeating: "q", count: 100))])
        XCTAssertEqual(try spool.pendingBatch(limit: 10, maxBytes: 25).map(\.record.dedupKey), ["a", "b"])
        XCTAssertEqual(try spool.pendingBatch(limit: 10, maxBytes: 30).map(\.record.dedupKey), ["a", "b", "c"])
        XCTAssertEqual(try spool.pendingBatch(limit: 2, maxBytes: 1_000).map(\.record.dedupKey), ["a", "b"])
        XCTAssertEqual(try spool.pendingBatch(limit: 10, maxBytes: 1).map(\.record.dedupKey), ["a"])
        let ids = try spool.pendingBatch(limit: 3).map(\.id)
        try spool.complete(ids: ids)
        // Only an oversized record is left: it still comes back, alone.
        XCTAssertEqual(try spool.pendingBatch(limit: 10, maxBytes: 5).map(\.record.dedupKey), ["d"])
    }

    func testCompleteRemovesOnlyNamedIds() throws {
        let spool = try makeSpool()
        try spool.append([rec("a"), rec("b"), rec("c")])
        let ids = try spool.pendingBatch(limit: 10).map(\.id)
        try spool.complete(ids: [ids[0], ids[2]])
        XCTAssertEqual(try spool.pendingBatch(limit: 10).map(\.record.dedupKey), ["b"])
        XCTAssertEqual(try spool.pendingCount(), 1)
    }

    func testRecordFailureCountsAndReportsExhaustion() throws {
        let spool = try makeSpool()
        try spool.append([rec("a")])
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id
        for _ in 0..<(ProviderSpool.maxAttempts - 1) {
            XCTAssertFalse(try spool.recordFailure(id: id, reason: "boom"))
        }
        XCTAssertTrue(try spool.recordFailure(id: id, reason: "boom"))
        XCTAssertEqual(try spool.pendingBatch(limit: 1).first?.attempts, ProviderSpool.maxAttempts)
    }

    func testQuarantineMovesRowAndKeepsPayloadByteExact() throws {
        let spool = try makeSpool()
        let payload = Data([0x00, 0xFF, 0x10, 0x80, 0x7F, 0x00])
        try spool.append([rec("a", payload)])
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id
        try spool.quarantine(id: id, reason: "bad shape")
        XCTAssertEqual(try spool.pendingCount(), 0)
        let held = try spool.quarantined(limit: 10)
        XCTAssertEqual(held.count, 1)
        XCTAssertEqual(held[0].record.payload, payload)
        XCTAssertEqual(held[0].record.dedupKey, "a")
        XCTAssertEqual(held[0].reason, "bad shape")
        XCTAssertEqual(held[0].quarantinedAt.timeIntervalSinceNow, 0, accuracy: 60)
    }

    func testRequeueQuarantinedRestoresWithZeroAttempts() throws {
        let spool = try makeSpool()
        try spool.append([rec("a", "payload")])
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id
        _ = try spool.recordFailure(id: id, reason: "e")
        try spool.quarantine(id: id, reason: "r")
        let qid = try XCTUnwrap(try spool.quarantined(limit: 1).first).id
        try spool.requeueQuarantined(ids: [qid])
        XCTAssertEqual(try spool.quarantined(limit: 10), [])
        let back = try XCTUnwrap(try spool.pendingBatch(limit: 1).first)
        XCTAssertEqual(back.attempts, 0)
        XCTAssertEqual(back.record.payload, Data("payload".utf8))
    }

    func testDuplicateDedupKeysAreBothSpooled() throws {
        let spool = try makeSpool()
        try spool.append([rec("k", "A"), rec("k", "B")])
        XCTAssertEqual(try spool.pendingCount(), 2)
        XCTAssertEqual(try spool.pendingBatch(limit: 10).map(\.record.payload),
                       [Data("A".utf8), Data("B".utf8)])
    }

    func testSourceStateRoundTripsAndOverwrites() throws {
        let spool = try makeSpool()
        XCTAssertNil(try spool.sourceState("cursor"))
        try spool.setSourceState("cursor", Data("1".utf8))
        XCTAssertEqual(try spool.sourceState("cursor"), Data("1".utf8))
        try spool.setSourceState("cursor", Data("2".utf8))
        XCTAssertEqual(try spool.sourceState("cursor"), Data("2".utf8))
    }

    func testAppendWithSourceStateIsAtomic() throws {
        let spool = try makeSpool()
        try spool.setSourceState("cursor", Data("old".utf8))
        XCTAssertThrowsError(
            try spool.append([rec("a"), rec("b", Data(), provider: "other")],
                             settingSourceState: "cursor", to: Data("new".utf8))
        ) { error in
            XCTAssertEqual(error as? ProviderSpoolError, .providerMismatch(expected: "mock", got: "other"))
        }
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try spool.sourceState("cursor"), Data("old".utf8))

        try spool.append([rec("a")], settingSourceState: "cursor", to: Data("new".utf8))
        XCTAssertEqual(try spool.pendingCount(), 1)
        XCTAssertEqual(try spool.sourceState("cursor"), Data("new".utf8))
    }

    func testTenMegabyteAndEmptyPayloadsRoundTrip() throws {
        let spool = try makeSpool()
        var generator = ProviderConformance.SeededGenerator(seed: 42)
        let big = Data((0..<(10 * 1024 * 1024)).map { _ in UInt8.random(in: 0...255, using: &generator) })
        try spool.append([rec("big", big), rec("empty", Data())])
        let got = try spool.pendingBatch(limit: 10)
        XCTAssertEqual(got[0].record.payload, big)
        XCTAssertEqual(got[1].record.payload, Data())
    }

    func testReopenKeepsPendingQuarantineAndState() throws {
        do {
            let spool = try makeSpool()
            try spool.append([rec("a"), rec("b")])
            let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first).id
            try spool.quarantine(id: id, reason: "r")
            try spool.setSourceState("cursor", Data("9".utf8))
        }
        let reopened = try makeSpool()
        XCTAssertEqual(try reopened.pendingBatch(limit: 10).map(\.record.dedupKey), ["b"])
        XCTAssertEqual(try reopened.quarantined(limit: 10).map(\.record.dedupKey), ["a"])
        XCTAssertEqual(try reopened.sourceState("cursor"), Data("9".utf8))
        XCTAssertThrowsError(try ProviderSpool(path: path, provider: "other")) { error in
            XCTAssertEqual(error as? ProviderSpoolError, .providerMismatch(expected: "other", got: "mock"))
        }
    }

    // MARK: - Compaction

    /// The file's page accounting, read on a connection of its own.
    private func stats() throws -> StoreFileStats {
        var config = Configuration()
        config.readonly = true
        return try DatabaseQueue(path: path, configuration: config).read { conn in
            try StoreFileStats.read(path: path, conn)
        }
    }

    /// A file made before the spool set auto-vacuum: mode 0, fixed once a table exists.
    private func makeLegacyFile() throws {
        let queue = try DatabaseQueue(path: path)
        try queue.write { try $0.execute(sql: "CREATE TABLE legacy_marker (x INTEGER)") }
    }

    /// Spools and completes `count` 64 KiB records, leaving their pages on the freelist.
    private func drainBacklog(_ spool: ProviderSpool, count: Int = 64) throws {
        let payload = Data(repeating: 0x5A, count: 64 * 1024)
        try spool.append((0..<count).map { rec("k\($0)", payload) })
        try spool.complete(ids: try spool.pendingBatch(limit: count + 1).map(\.id))
        XCTAssertEqual(try spool.pendingCount(), 0)
    }

    func testNewSpoolUsesIncrementalAutoVacuum() throws {
        _ = try makeSpool()
        XCTAssertEqual(try stats().autoVacuum, 2)
    }

    func testCompactRebuildsALegacyFileToIncrementalAndShrinksIt() throws {
        try makeLegacyFile()
        let spool = try makeSpool()
        try drainBacklog(spool)
        let before = try stats()
        XCTAssertEqual(before.autoVacuum, 0)
        XCTAssertGreaterThan(before.freelistCount, 0)

        let result = try spool.compactIfDue(deadline: Date().addingTimeInterval(30),
                                            minFreeBytes: 1, maxRebuildBytes: 1 << 30)
        guard case .rebuilt(let freed)? = result else {
            return XCTFail("expected a rebuild, got \(String(describing: result))")
        }
        XCTAssertEqual(freed, Int64(before.freelistCount) * Int64(before.pageSize))

        let after = try stats()
        XCTAssertEqual(after.autoVacuum, 2)
        XCTAssertEqual(after.freelistCount, 0)
        XCTAssertLessThan(after.bytes, before.bytes / 4)
        // Still a working spool afterwards.
        try spool.append([rec("after")])
        XCTAssertEqual(try spool.pendingBatch(limit: 10).map(\.record.dedupKey), ["after"])
    }

    func testCompactWaitsWhileTooMuchLiveDataToRebuild() throws {
        try makeLegacyFile()
        let spool = try makeSpool()
        try drainBacklog(spool)
        try spool.append([rec("pending", Data(repeating: 1, count: 8 * 1024))])
        XCTAssertNil(try spool.compactIfDue(deadline: Date().addingTimeInterval(30),
                                            minFreeBytes: 1, maxRebuildBytes: 1024))
        XCTAssertEqual(try stats().autoVacuum, 0)
        XCTAssertEqual(try spool.pendingCount(), 1)
    }

    func testCompactDoesNothingBelowTheFreeSpaceFloor() throws {
        let spool = try makeSpool()
        try drainBacklog(spool)
        let before = try stats().freelistCount
        // 64 × 64 KiB is far under the default 256 MiB floor.
        XCTAssertNil(try spool.compactIfDue(deadline: Date().addingTimeInterval(30)))
        XCTAssertEqual(try stats().freelistCount, before)
    }

    func testCompactReclaimsFreePagesOfAnIncrementalFile() throws {
        let spool = try makeSpool()
        try drainBacklog(spool)
        let before = try stats()
        XCTAssertEqual(before.autoVacuum, 2)
        XCTAssertGreaterThan(before.freelistCount, 0)

        let result = try spool.compactIfDue(deadline: Date().addingTimeInterval(30), minFreeBytes: 1)
        guard case .incremental(let freed)? = result else {
            return XCTFail("expected incremental, got \(String(describing: result))")
        }
        XCTAssertEqual(freed, Int64(before.freelistCount) * Int64(before.pageSize))
        let after = try stats()
        XCTAssertEqual(after.freelistCount, 0)
        XCTAssertLessThan(after.bytes, before.bytes / 4)
    }
}
