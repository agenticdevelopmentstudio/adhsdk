import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The database-stats wire shape: per-lane pool counters.
final class DBStatsDTOConformanceTests: XCTestCase {

    private func pool(_ name: String) -> DBStatsDTO.Pool {
        DBStatsDTO.Pool(pool: name, inFlight: 1, completed: 10, evicted: 2, p50Ms: 1.5, p99Ms: 9.0)
    }

    private func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testV001_poolReadsBackEachField() {
        let value = pool("write")
        XCTAssertEqual(value.pool, "write")
        XCTAssertEqual(value.inFlight, 1)
        XCTAssertEqual(value.completed, 10)
        XCTAssertEqual(value.evicted, 2)
        XCTAssertEqual(value.p50Ms, 1.5)
        XCTAssertEqual(value.p99Ms, 9.0)
    }

    func testV002_statsKeepsBothListsInOrder() {
        let stats = DBStatsDTO(write: [pool("a")], read: [pool("b"), pool("c")])
        XCTAssertEqual(stats.write.map(\.pool), ["a"])
        XCTAssertEqual(stats.read.map(\.pool), ["b", "c"])
    }

    func testV003_encodesTheWireKeys() throws {
        let data = try JSONEncoder().encode(DBStatsDTO(write: [pool("w")], read: []))
        let root = try object(data)
        XCTAssertEqual(Set(root.keys), ["write", "read"])
        let writes = try XCTUnwrap(root["write"] as? [[String: Any]])
        XCTAssertEqual(writes.count, 1)
        XCTAssertEqual(
            Set(try XCTUnwrap(writes.first).keys),
            ["pool", "inFlight", "completed", "evicted", "p50Ms", "p99Ms"])
    }

    func testV004_decodesWhatItEncoded() throws {
        let original = DBStatsDTO(write: [pool("w")], read: [])
        let decoded = try JSONDecoder().decode(DBStatsDTO.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.write.count, 1)
        let value = try XCTUnwrap(decoded.write.first)
        XCTAssertEqual(value.pool, "w")
        XCTAssertEqual(value.inFlight, 1)
        XCTAssertEqual(value.completed, 10)
        XCTAssertEqual(value.evicted, 2)
        XCTAssertEqual(value.p50Ms, 1.5)
        XCTAssertEqual(value.p99Ms, 9.0)
        XCTAssertTrue(decoded.read.isEmpty)
    }

    func testV005_emptyListsAreEncodedAsEmptyArrays() throws {
        let data = try JSONEncoder().encode(DBStatsDTO(write: [], read: []))
        let root = try object(data)
        XCTAssertEqual((root["write"] as? [Any])?.count, 0)
        XCTAssertEqual((root["read"] as? [Any])?.count, 0)
        let decoded = try JSONDecoder().decode(DBStatsDTO.self, from: data)
        XCTAssertTrue(decoded.write.isEmpty)
        XCTAssertTrue(decoded.read.isEmpty)
    }

    func testV006_poolValuesAreNotValidated() {
        let odd = DBStatsDTO.Pool(pool: "", inFlight: -1, completed: 0, evicted: 0, p50Ms: 5, p99Ms: 1)
        XCTAssertEqual(odd.pool, "")
        XCTAssertEqual(odd.inFlight, -1)
        XCTAssertEqual(odd.p50Ms, 5)
        XCTAssertEqual(odd.p99Ms, 1)
    }

    func testV007_decodingWithoutReadFails() {
        let json = Data(#"{"write":[]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(DBStatsDTO.self, from: json))
    }
}
