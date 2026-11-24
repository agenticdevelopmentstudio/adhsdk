import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `SessionMetricsDTO`, `ImportRequestDTO`, `TranscriptCursorStatsDTO`, `ImportSummary`.
final class SessionMetricsDTOConformanceTests: XCTestCase {

    private func json(_ text: String) -> Data { Data(text.utf8) }

    private func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func metrics() -> SessionMetricsDTO {
        SessionMetricsDTO(
            sessionId: "s1", totalInputTokens: 1, totalOutputTokens: 2, cacheReadTokens: 3,
            cacheCreationTokens: 4, totalCostUsd: 1.25, turnCount: 5, model: "m",
            firstTurnAt: "2026-01-01 00:00:00", lastTurnAt: "2026-01-02 00:00:00", updatedAt: "2026-01-03 00:00:00")
    }

    func testSessionMetricsDto001_emptyObjectDecodesToDefaults() throws {
        let summary = try StenographerWire.decoder().decode(ImportSummary.self, from: json("{}"))
        XCTAssertEqual(summary.filesScanned, 0)
        XCTAssertEqual(summary.turnsSeen, 0)
        XCTAssertEqual(summary.eventsInserted, 0)
        XCTAssertEqual(summary.eventsSkipped, 0)
        XCTAssertEqual(summary.sessionsCreated, 0)
        XCTAssertEqual(summary.sessionsTouched, 0)
        XCTAssertEqual(summary.metricsUpserted, 0)
        XCTAssertEqual(summary.linesSeen, 0)
        XCTAssertEqual(summary.linesInserted, 0)
        XCTAssertEqual(summary.linesSkipped, 0)
        XCTAssertEqual(summary.bytesRead, 0)
        XCTAssertEqual(summary.bytesSkipped, 0)
        XCTAssertTrue(summary.errors.isEmpty)
        XCTAssertFalse(summary.hasMore)
        XCTAssertNil(summary.cutoffISO)
    }

    func testSessionMetricsDto002_partialBodyKeepsDefaults() throws {
        let summary = try StenographerWire.decoder().decode(
            ImportSummary.self, from: json(#"{"files_scanned":3,"has_more":true}"#))
        XCTAssertEqual(summary.filesScanned, 3)
        XCTAssertTrue(summary.hasMore)
        XCTAssertEqual(summary.turnsSeen, 0)
        XCTAssertEqual(summary.bytesRead, 0)
        XCTAssertTrue(summary.errors.isEmpty)
        XCTAssertNil(summary.cutoffISO)
    }

    func testSessionMetricsDto003_summaryInitDefaults() {
        let summary = ImportSummary()
        XCTAssertEqual(summary.filesScanned, 0)
        XCTAssertEqual(summary.linesSkipped, 0)
        XCTAssertEqual(summary.bytesSkipped, 0)
        XCTAssertTrue(summary.errors.isEmpty)
        XCTAssertFalse(summary.hasMore)
        XCTAssertNil(summary.cutoffISO)
    }

    func testSessionMetricsDto004_cutoffMeaning() throws {
        throw XCTSkip("Integration check, not a DTO test: needs a real importer run; covered by JSONLImporterTests")
    }

    func testSessionMetricsDto005_cutoffSurvivesWireRoundTrip() throws {
        let summary = ImportSummary(cutoffISO: "2026-01-01T00:00:00Z")
        let data = try StenographerWire.encoder().encode(summary)
        XCTAssertEqual(try object(data)["cutoff_iso"] as? String, "2026-01-01T00:00:00Z")
        let decoded = try StenographerWire.decoder().decode(ImportSummary.self, from: data)
        XCTAssertEqual(decoded.cutoffISO, "2026-01-01T00:00:00Z")
    }

    func testSessionMetricsDto006_int64BytesDoNotTruncate() throws {
        let summary = ImportSummary(bytesRead: 5_000_000_000, bytesSkipped: 9_000_000_000)
        let encoded = try object(try StenographerWire.encoder().encode(summary))
        XCTAssertEqual((encoded["bytes_read"] as? NSNumber)?.int64Value, 5_000_000_000)
        XCTAssertEqual((encoded["bytes_skipped"] as? NSNumber)?.int64Value, 9_000_000_000)
        let decoded = try StenographerWire.decoder().decode(
            ImportSummary.self, from: try StenographerWire.encoder().encode(summary))
        XCTAssertEqual(decoded.bytesRead, 5_000_000_000)
        XCTAssertEqual(decoded.bytesSkipped, 9_000_000_000)
    }

    func testSessionMetricsDto007_emptyRequestBodyIsAllNil() throws {
        let request = try StenographerWire.decoder().decode(ImportRequestDTO.self, from: json("{}"))
        XCTAssertNil(request.sourceDirectory)
        XCTAssertNil(request.since)
        XCTAssertNil(request.dryRun)
    }

    func testSessionMetricsDto008_requestWireKeysAndIsoDate() throws {
        let since = Date(timeIntervalSince1970: 1_767_225_600)
        let request = ImportRequestDTO(sourceDirectory: "/x", since: since, dryRun: true)
        let data = try StenographerWire.encoder().encode(request)
        let encoded = try object(data)
        XCTAssertEqual(Set(encoded.keys), ["source_directory", "since", "dry_run"])
        XCTAssertEqual(encoded["since"] as? String, "2026-01-01T00:00:00Z")
        let decoded = try StenographerWire.decoder().decode(ImportRequestDTO.self, from: data)
        XCTAssertEqual(decoded.sourceDirectory, "/x")
        XCTAssertEqual(decoded.since, since)
        XCTAssertEqual(decoded.dryRun, true)
    }

    func testSessionMetricsDto009_defaultDecoderRejectsIsoSince() {
        let body = json(#"{"since":"2026-01-01T00:00:00Z"}"#)
        XCTAssertThrowsError(try JSONDecoder().decode(ImportRequestDTO.self, from: body)) { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
        XCTAssertNoThrow(try StenographerWire.decoder().decode(ImportRequestDTO.self, from: body))
    }

    func testSessionMetricsDto010_metricsRoundTrip() throws {
        let data = try StenographerWire.encoder().encode(metrics())
        let encoded = try object(data)
        XCTAssertEqual(Set(encoded.keys), [
            "session_id", "total_input_tokens", "total_output_tokens", "cache_read_tokens",
            "cache_creation_tokens", "total_cost_usd", "turn_count", "model", "first_turn_at",
            "last_turn_at", "updated_at"
        ])
        XCTAssertEqual(encoded["total_cost_usd"] as? Double, 1.25)
        let decoded = try StenographerWire.decoder().decode(SessionMetricsDTO.self, from: data)
        XCTAssertEqual(decoded.sessionId, "s1")
        XCTAssertEqual(decoded.totalInputTokens, 1)
        XCTAssertEqual(decoded.totalOutputTokens, 2)
        XCTAssertEqual(decoded.cacheReadTokens, 3)
        XCTAssertEqual(decoded.cacheCreationTokens, 4)
        XCTAssertEqual(decoded.totalCostUsd, 1.25)
        XCTAssertEqual(decoded.turnCount, 5)
        XCTAssertEqual(decoded.model, "m")
        XCTAssertEqual(decoded.firstTurnAt, "2026-01-01 00:00:00")
        XCTAssertEqual(decoded.lastTurnAt, "2026-01-02 00:00:00")
        XCTAssertEqual(decoded.updatedAt, "2026-01-03 00:00:00")
    }

    func testSessionMetricsDto011_metricsDecodeIsStrict() throws {
        var encoded = try object(try StenographerWire.encoder().encode(metrics()))
        encoded.removeValue(forKey: "turn_count")
        let data = try JSONSerialization.data(withJSONObject: encoded)
        XCTAssertThrowsError(try StenographerWire.decoder().decode(SessionMetricsDTO.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "turnCount")
        }
    }

    func testSessionMetricsDto012_cursorDecodeAndRoughGap() throws {
        let body = json(#"{"files":2,"bytes_covered":1000,"bytes_on_disk":990}"#)
        let stats = try StenographerWire.decoder().decode(TranscriptCursorStatsDTO.self, from: body)
        XCTAssertEqual(stats.files, 2)
        XCTAssertEqual(stats.bytesCovered, 1000)
        XCTAssertEqual(stats.bytesOnDisk, 990)
        XCTAssertNil(stats.oldestUpdatedAt)
        XCTAssertNil(stats.newestUpdatedAt)
    }

    func testSessionMetricsDto013_cursorInitKeepsNilTimestamps() {
        let stats = TranscriptCursorStatsDTO(
            files: 1, bytesCovered: 5, bytesOnDisk: 6, oldestUpdatedAt: nil, newestUpdatedAt: nil)
        XCTAssertEqual(stats.files, 1)
        XCTAssertEqual(stats.bytesCovered, 5)
        XCTAssertEqual(stats.bytesOnDisk, 6)
        XCTAssertNil(stats.oldestUpdatedAt)
        XCTAssertNil(stats.newestUpdatedAt)
    }

    func testSessionMetricsDto014_summaryEncodeWritesEveryField() throws {
        let encoded = try object(try StenographerWire.encoder().encode(ImportSummary()))
        let counters = [
            "files_scanned", "turns_seen", "events_inserted", "events_skipped", "sessions_created",
            "sessions_touched", "metrics_upserted", "lines_seen", "lines_inserted", "lines_skipped",
            "bytes_read", "bytes_skipped"
        ]
        for key in counters {
            XCTAssertEqual((encoded[key] as? NSNumber)?.intValue, 0, key)
        }
        XCTAssertEqual((encoded["errors"] as? [Any])?.count, 0)
        XCTAssertEqual(encoded["has_more"] as? Bool, false)
        XCTAssertNil(encoded["cutoff_iso"])
    }

    func testSessionMetricsDto015_requestInitDefaults() {
        let request = ImportRequestDTO()
        XCTAssertNil(request.sourceDirectory)
        XCTAssertNil(request.since)
        XCTAssertNil(request.dryRun)
    }

    func testSessionMetricsDto016_metricsInitFieldSet() {
        let value = metrics()
        XCTAssertEqual(value.sessionId, "s1")
        XCTAssertEqual(value.totalInputTokens, 1)
        XCTAssertEqual(value.totalOutputTokens, 2)
        XCTAssertEqual(value.cacheReadTokens, 3)
        XCTAssertEqual(value.cacheCreationTokens, 4)
        XCTAssertEqual(value.totalCostUsd, 1.25)
        XCTAssertEqual(value.turnCount, 5)
        XCTAssertEqual(value.model, "m")
        XCTAssertEqual(value.firstTurnAt, "2026-01-01 00:00:00")
        XCTAssertEqual(value.lastTurnAt, "2026-01-02 00:00:00")
        XCTAssertEqual(value.updatedAt, "2026-01-03 00:00:00")
    }

    func testSessionMetricsDto017_conformances() {
        func requireCodableSendable<T: Codable & Sendable>(_ value: T) -> T { value }
        let value = requireCodableSendable(metrics())
        XCTAssertEqual(value.sessionId, "s1")
        XCTAssertFalse((value as Any) is any Equatable)
    }
}
