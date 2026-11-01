import Foundation
import GRDB
import XCTest
@testable import AgenticToolkitDatabase

final class RawArchiveTests: XCTestCase {

    private var tmpDir: URL!
    private var path: String { tmpDir.appendingPathComponent(RawArchive.fileName(provider: "mock")).path }

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-raw-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func makeArchive() throws -> RawArchive {
        try RawArchive(path: path, provider: "mock")
    }

    private func rec(_ key: String, _ payload: Data, provider: String = "mock",
                     at date: Date = Date(timeIntervalSince1970: 1_800_000_000.123)) -> RawRecord {
        RawRecord(provider: provider, sourceKind: "hook", dedupKey: key, receivedAt: date, payload: payload)
    }

    private func rec(_ key: String, _ text: String) -> RawRecord { rec(key, Data(text.utf8)) }

    func testAppendThenReadReturnsIdenticalRecord() throws {
        let archive = try makeArchive()
        let original = rec("k1", "hello")
        let result = try archive.append([original])
        let got = try XCTUnwrap(try archive.record(id: result.ids[0]))
        XCTAssertEqual(got.record.provider, "mock")
        XCTAssertEqual(got.record.sourceKind, original.sourceKind)
        XCTAssertEqual(got.record.dedupKey, original.dedupKey)
        XCTAssertEqual(got.record.payload, original.payload)
        XCTAssertEqual(got.record.receivedAt.timeIntervalSince1970,
                       original.receivedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testIdsAreAscendingInAppendOrder() throws {
        let archive = try makeArchive()
        let ids = try archive.append([rec("a", "1"), rec("b", "2"), rec("c", "3")]).ids
        XCTAssertEqual(ids, ids.sorted())
        XCTAssertEqual(Set(ids).count, 3)
        let listed = try archive.records(after: 0, limit: 10)
        XCTAssertEqual(listed.map(\.id), ids)
        XCTAssertEqual(listed.map(\.record.dedupKey), ["a", "b", "c"])
    }

    func testDuplicateDedupKeyKeepsFirstPayloadAndReturnsExistingId() throws {
        let archive = try makeArchive()
        let first = try archive.append([rec("k", "A")])
        let second = try archive.append([rec("k", "B")])
        XCTAssertEqual(second.ids, first.ids)
        XCTAssertEqual(second.insertedCount, 0)
        guard case .conflict(let existing, let archivedSHA, let incomingSHA) = second.outcomes[0] else {
            return XCTFail("expected a conflict, got \(second.outcomes)")
        }
        XCTAssertEqual(existing, first.ids[0])
        XCTAssertEqual(archivedSHA, RawArchive.hex(Data("A".utf8)))
        XCTAssertEqual(incomingSHA, RawArchive.hex(Data("B".utf8)))
        XCTAssertEqual(try archive.append([rec("k", "A")]).outcomes, [.duplicate(first.ids[0])])
        XCTAssertEqual(try archive.record(id: first.ids[0])?.record.payload, Data("A".utf8))
        XCTAssertEqual(try archive.count(), 1)
    }

    func testDuplicateWithinOneBatch() throws {
        let archive = try makeArchive()
        let result = try archive.append([rec("k", "A"), rec("k", "B")])
        XCTAssertEqual(result.ids.count, 2)
        XCTAssertEqual(result.ids[0], result.ids[1])
        XCTAssertEqual(result.insertedCount, 1)
        XCTAssertEqual(result.outcomes[0], .inserted(result.ids[0]))
        XCTAssertEqual(result.outcomes[1], .conflict(existingID: result.ids[0],
                                                     archivedSHA256: RawArchive.hex(Data("A".utf8)),
                                                     incomingSHA256: RawArchive.hex(Data("B".utf8))))
        XCTAssertEqual(try archive.record(id: result.ids[0])?.record.payload, Data("A".utf8))
        let same = try archive.append([rec("j", "C"), rec("j", "C")])
        XCTAssertEqual(same.outcomes, [.inserted(same.ids[0]), .duplicate(same.ids[0])])
    }

    func testEmptyPayloadRoundTrips() throws {
        let archive = try makeArchive()
        let id = try archive.append([rec("e", Data())]).ids[0]
        XCTAssertEqual(try archive.record(id: id)?.record.payload, Data())
    }

    func testTenMegabytePayloadRoundTripsByteExact() throws {
        var generator = ProviderConformance.SeededGenerator(seed: 42)
        let count = 10 * 1024 * 1024
        var bytes = [UInt8](repeating: 0, count: count)
        for index in stride(from: 0, to: count, by: 8) {
            var word = generator.next()
            for offset in 0..<8 where index + offset < count {
                bytes[index + offset] = UInt8(truncatingIfNeeded: word)
                word >>= 8
            }
        }
        let payload = Data(bytes)
        let archive = try makeArchive()
        let id = try archive.append([rec("big", payload)]).ids[0]
        XCTAssertEqual(try archive.record(id: id)?.record.payload, payload)
        let compression = try DatabaseQueue(path: path).read { conn in
            try String.fetchOne(conn, sql: "SELECT compression FROM raw_record WHERE id = ?", arguments: [id])
        }
        XCTAssertEqual(compression, "none")
    }

    func testCompressiblePayloadIsStoredCompressed() throws {
        let line = "{\"event\":\"PreToolUse\",\"tool\":\"Bash\",\"n\":1}\n"
        let payload = Data(String(repeating: line, count: 1_048_576 / line.utf8.count + 1).utf8)
        let archive = try makeArchive()
        let id = try archive.append([rec("c", payload)]).ids[0]
        let queue = try DatabaseQueue(path: path)
        let row = try queue.read { conn in
            try Row.fetchOne(conn, sql: "SELECT compression, length(payload) AS n FROM raw_record WHERE id = ?",
                             arguments: [id])
        }
        XCTAssertEqual(row?["compression"] as String?, "lzfse")
        XCTAssertLessThan(try XCTUnwrap(row?["n"] as Int?), payload.count)
        XCTAssertEqual(try archive.record(id: id)?.record.payload, payload)
    }

    func testCorruptedBlobThrowsCorruptPayload() throws {
        let archive = try makeArchive()
        let compressible = Data(String(repeating: "abcdef", count: 10_000).utf8)
        let ids = try archive.append([rec("x", compressible), rec("y", "plain")]).ids
        let queue = try DatabaseQueue(path: path)
        try queue.write { conn in
            try conn.execute(sql: "UPDATE raw_record SET payload = ? WHERE id = ?",
                           arguments: [Data("garbage-not-lzfse".utf8), ids[0]])
            // Same-size garbage in an uncompressed row: only the sha256 can catch it.
            try conn.execute(sql: "UPDATE raw_record SET payload = ? WHERE id = ?",
                           arguments: [Data("PLAIN".utf8), ids[1]])
        }
        XCTAssertThrowsError(try archive.record(id: ids[0])) {
            XCTAssertEqual($0 as? RawArchiveError, .corruptPayload(id: ids[0]))
        }
        XCTAssertThrowsError(try archive.record(id: ids[1])) {
            XCTAssertEqual($0 as? RawArchiveError, .corruptPayload(id: ids[1]))
        }
    }

    func testReopenKeepsEverything() throws {
        var archive: RawArchive? = try makeArchive()
        let records = (0..<100).map { rec("k\($0)", "payload-\($0)") }
        let ids = try XCTUnwrap(archive).append(records).ids
        archive = nil

        let reopened = try makeArchive()
        XCTAssertEqual(try reopened.count(), 100)
        XCTAssertEqual(try reopened.maxID(), ids.max())
        for (index, id) in ids.enumerated() {
            XCTAssertEqual(try reopened.record(id: id)?.record.payload, Data("payload-\(index)".utf8))
        }
    }

    func testOpeningWithDifferentProviderThrows() throws {
        _ = try makeArchive()
        XCTAssertThrowsError(try RawArchive(path: path, provider: "claude")) {
            XCTAssertEqual($0 as? RawArchiveError, .providerMismatch(expected: "claude", got: "mock"))
        }
    }

    func testAppendRejectsForeignProviderAndWritesNothing() throws {
        let archive = try makeArchive()
        XCTAssertThrowsError(try archive.append([rec("ok", "1"), rec("bad", Data("2".utf8), provider: "claude")])) {
            XCTAssertEqual($0 as? RawArchiveError, .providerMismatch(expected: "mock", got: "claude"))
        }
        XCTAssertEqual(try archive.count(), 0)
    }

    func testRecordsAfterPaginates() throws {
        let archive = try makeArchive()
        _ = try archive.append((0..<25).map { rec("k\($0)", "p\($0)") })
        var seen: [Int64] = []
        var cursor: Int64 = 0
        var sizes: [Int] = []
        while true {
            let page = try archive.records(after: cursor, limit: 10)
            if page.isEmpty { break }
            sizes.append(page.count)
            seen += page.map(\.id)
            cursor = try XCTUnwrap(page.last).id
        }
        XCTAssertEqual(sizes, [10, 10, 5])
        XCTAssertEqual(seen, seen.sorted())
        XCTAssertEqual(Set(seen).count, 25)
    }

    func testIdsAfterHonoursLimitAndByteBudgetButAlwaysTakesOne() throws {
        let archive = try makeArchive()
        let ids = try archive.append((0..<6).map { rec("k\($0)", String(repeating: "p", count: 10)) }).ids
        XCTAssertEqual(try archive.ids(after: 0, limit: 4), Array(ids.prefix(4)))
        XCTAssertEqual(try archive.ids(after: ids[1], limit: 10, maxBytes: 25), [ids[2], ids[3]])
        XCTAssertEqual(try archive.ids(after: 0, limit: 10, maxBytes: 1), [ids[0]])
        XCTAssertEqual(try archive.ids(after: ids[5], limit: 10), [])
        XCTAssertEqual(try archive.ids(after: 0, limit: 0), [])
    }

    func testRecordsByIdsReturnsExactlyThoseInOrder() throws {
        let archive = try makeArchive()
        let ids = try archive.append((0..<5).map { rec("k\($0)", "p\($0)") }).ids
        let picked = try archive.records(ids: [ids[1], ids[3]])
        XCTAssertEqual(picked.map(\.id), [ids[1], ids[3]])
        XCTAssertEqual(picked.map(\.record.payload), [Data("p1".utf8), Data("p3".utf8)])
        XCTAssertEqual(try archive.records(ids: []), [])
    }
}
