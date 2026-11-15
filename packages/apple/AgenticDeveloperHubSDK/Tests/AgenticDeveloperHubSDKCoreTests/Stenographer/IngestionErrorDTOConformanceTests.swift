import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The quarantine shapes: a live quarantined file, a log row, and retry progress.
/// (The log row's status lifecycle is covered through the database by `IngestionErrorLogTests`.)
final class IngestionErrorDTOConformanceTests: XCTestCase {

    private func quarantined(
        retryCount: Int = 0, lastRetriedAt: String? = nil, exhausted: Bool = false
    ) -> IngestionErrorDTO {
        IngestionErrorDTO(
            filename: "a.json", eventType: "Stop", sessionId: "s1", quarantinedAt: "2026-11-10T09:00:00Z",
            reason: "disk full", retryCount: retryCount, lastRetriedAt: lastRetriedAt, exhausted: exhausted)
    }

    private func logRow(
        sqliteCode: Int?, retryCount: Int, lastRetriedAt: String?, status: String, resolvedAt: String?
    ) -> IngestionErrorLogDTO {
        IngestionErrorLogDTO(
            filename: "a.json", eventType: "Stop", sessionId: "s1", reason: "disk full", sqliteCode: sqliteCode,
            quarantinedAt: "2026-11-10T09:00:00Z", retryCount: retryCount, lastRetriedAt: lastRetriedAt,
            status: status, resolvedAt: resolvedAt, updatedAt: "2026-11-10T09:06:00Z")
    }

    func testV001_errorDefaults() {
        let value = IngestionErrorDTO(
            filename: "a.json", eventType: "Stop", sessionId: "s1", quarantinedAt: "2026-11-10T09:00:00Z",
            reason: "disk full")
        XCTAssertEqual(value.retryCount, 0)
        XCTAssertNil(value.lastRetriedAt)
        XCTAssertFalse(value.exhausted)
    }

    func testV002_errorReadsBackEveryField() {
        let value = quarantined(retryCount: 5, lastRetriedAt: "2026-11-10T09:05:00Z", exhausted: true)
        XCTAssertEqual(value.filename, "a.json")
        XCTAssertEqual(value.eventType, "Stop")
        XCTAssertEqual(value.sessionId, "s1")
        XCTAssertEqual(value.quarantinedAt, "2026-11-10T09:00:00Z")
        XCTAssertEqual(value.reason, "disk full")
        XCTAssertEqual(value.retryCount, 5)
        XCTAssertEqual(value.lastRetriedAt, "2026-11-10T09:05:00Z")
        XCTAssertTrue(value.exhausted)
    }

    func testV003_logRowReadsBackEveryField() {
        let row = logRow(
            sqliteCode: 5, retryCount: 2, lastRetriedAt: "2026-11-10T09:05:00Z", status: "recovered",
            resolvedAt: "2026-11-10T09:06:00Z")
        XCTAssertEqual(row.status, "recovered")
        XCTAssertEqual(row.resolvedAt, "2026-11-10T09:06:00Z")
        XCTAssertEqual(row.sqliteCode, 5)
        XCTAssertEqual(row.retryCount, 2)
        XCTAssertEqual(row.lastRetriedAt, "2026-11-10T09:05:00Z")
        XCTAssertEqual(row.filename, "a.json")
        XCTAssertEqual(row.updatedAt, "2026-11-10T09:06:00Z")
    }

    func testV004_lostRowHasNoRetryOrSqliteCode() {
        let row = logRow(sqliteCode: nil, retryCount: 0, lastRetriedAt: nil, status: "lost", resolvedAt: nil)
        XCTAssertEqual(row.status, "lost")
        XCTAssertNil(row.lastRetriedAt)
        XCTAssertNil(row.sqliteCode)
        XCTAssertEqual(row.retryCount, 0)
    }

    func testV005_logRowEncodingHasNoExhaustedKey() throws {
        let row = logRow(sqliteCode: 5, retryCount: 5, lastRetriedAt: nil, status: "exhausted", resolvedAt: nil)
        let data = try JSONEncoder().encode(row)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(root["exhausted"])
        XCTAssertEqual(root["status"] as? String, "exhausted")
    }

    func testV006_progressReadsBackEveryField() {
        let value = RetryProgressDTO(running: true, total: 10, processed: 4, recovered: 3, stillFailing: 1)
        XCTAssertTrue(value.running)
        XCTAssertEqual(value.total, 10)
        XCTAssertEqual(value.processed, 4)
        XCTAssertEqual(value.recovered, 3)
        XCTAssertEqual(value.stillFailing, 1)
    }

    func testV007_finishedProgressCarriesTheStopSignalAcrossTheWire() throws {
        let done = RetryProgressDTO(running: false, total: 10, processed: 10, recovered: 8, stillFailing: 2)
        let decoded = try JSONDecoder().decode(RetryProgressDTO.self, from: JSONEncoder().encode(done))
        XCTAssertFalse(decoded.running)
        XCTAssertEqual(decoded.processed, decoded.total)
    }

    func testV008_nilLastRetriedIsOmittedAndDecodesToNil() throws {
        let data = try JSONEncoder().encode(quarantined())
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(root["lastRetriedAt"])
        let decoded = try JSONDecoder().decode(IngestionErrorDTO.self, from: data)
        XCTAssertNil(decoded.lastRetriedAt)
    }

    func testV009_statusIsNotValidated() {
        let row = logRow(sqliteCode: nil, retryCount: 0, lastRetriedAt: nil, status: "mystery", resolvedAt: nil)
        XCTAssertEqual(row.status, "mystery")
    }

    func testV010_logRowHasNoDefaults() throws {
        throw XCTSkip("compile-time check: every IngestionErrorLogDTO argument must be written; no runtime behavior")
    }
}
