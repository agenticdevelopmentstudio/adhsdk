import XCTest
@testable import AgenticDeveloperHubSDKCore

final class OversightFindingDTOConformanceTests: XCTestCase {

    private func makeFinding(
        severity: Int = 88, status: String = "pending", source: String = "rule"
    ) -> OversightFindingDTO {
        OversightFindingDTO(
            id: 1, sessionId: "abcdefgh-1234-5678", observer: "context", kind: "compact",
            severity: severity, status: status, source: source, model: "", reason: "Context 88% used",
            detail: "", createdAt: "2026-01-01T00:00:00Z", updatedAt: "2026-01-01T00:00:00Z")
    }

    private func body(status: String = "acted", source: String = "rule", model: String = "\"\"",
                      createdAt: String = "2026-10-12T00:00:00Z") -> Data {
        Data("""
        {"id":7,"session_id":"s","observer":"compact","kind":"k","severity":1,"status":"\(status)",
         "source":"\(source)","model":\(model),"reason":"r","detail":"","created_at":"\(createdAt)",
         "updated_at":"2026-10-12T00:00:00Z"}
        """.utf8)
    }

    func testV001_everyFieldReadsBack() {
        let finding = makeFinding()
        XCTAssertEqual(finding.id, 1)
        XCTAssertEqual(finding.sessionId, "abcdefgh-1234-5678")
        XCTAssertEqual(finding.observer, "context")
        XCTAssertEqual(finding.kind, "compact")
        XCTAssertEqual(finding.severity, 88)
        XCTAssertEqual(finding.status, "pending")
        XCTAssertEqual(finding.source, "rule")
        XCTAssertEqual(finding.model, "")
        XCTAssertEqual(finding.reason, "Context 88% used")
        XCTAssertEqual(finding.detail, "")
        XCTAssertEqual(finding.createdAt, "2026-01-01T00:00:00Z")
        XCTAssertEqual(finding.updatedAt, "2026-01-01T00:00:00Z")
    }

    func testV002_ruleFindingKeepsEmptyModelAndDetail() {
        let finding = makeFinding()
        XCTAssertEqual(finding.model, "")
        XCTAssertEqual(finding.detail, "")
    }

    func testV003_zeroSeverityAndEmptyStringsAreKept() {
        let finding = OversightFindingDTO(
            id: 0, sessionId: "", observer: "", kind: "", severity: 0, status: "", source: "",
            model: "", reason: "", detail: "", createdAt: "", updatedAt: "")
        XCTAssertEqual(finding.severity, 0)
        XCTAssertEqual(
            [finding.sessionId, finding.observer, finding.kind, finding.status, finding.source,
             finding.model, finding.reason, finding.detail, finding.createdAt, finding.updatedAt],
            Array(repeating: "", count: 10))
    }

    func testV004_severityIsNotClamped() {
        XCTAssertEqual(makeFinding(severity: 250).severity, 250)
    }

    func testV005_encodesSnakeCaseKeys() throws {
        let data = try StenographerWire.encoder().encode(makeFinding())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let expected: Set<String> = [
            "id", "session_id", "observer", "kind", "severity", "status", "source", "model",
            "reason", "detail", "created_at", "updated_at"]
        XCTAssertEqual(Set(object.keys), expected)
    }

    func testV006_wireRoundTripIsEqual() throws {
        let original = makeFinding()
        let data = try StenographerWire.encoder().encode(original)
        XCTAssertEqual(try StenographerWire.decoder().decode(OversightFindingDTO.self, from: data), original)
    }

    func testV007_bodyMissingKeysThrows() {
        let json = Data("""
        {"id":7,"session_id":"s","observer":"compact","kind":"k","severity":1,"status":"acted",
         "reason":"r","created_at":"2026-10-12T00:00:00Z"}
        """.utf8)
        XCTAssertThrowsError(try StenographerWire.decoder().decode(OversightFindingDTO.self, from: json)) { error in
            guard case DecodingError.keyNotFound = error else { return XCTFail("expected keyNotFound: \(error)") }
        }
    }

    func testV008_unknownStatusAndSourceAreKept() throws {
        let finding = try StenographerWire.decoder().decode(
            OversightFindingDTO.self, from: body(status: "reopened", source: "human"))
        XCTAssertEqual(finding.status, "reopened")
        XCTAssertEqual(finding.source, "human")
    }

    func testV009_differingStatusIsNotEqual() {
        XCTAssertNotEqual(makeFinding(status: "pending"), makeFinding(status: "acted"))
        XCTAssertEqual(makeFinding(status: "pending"), makeFinding(status: "pending"))
    }

    func testV010_sqliteTimestampIsKeptVerbatim() throws {
        let finding = try StenographerWire.decoder().decode(
            OversightFindingDTO.self, from: body(createdAt: "2026-11-14 09:30:00"))
        XCTAssertEqual(finding.createdAt, "2026-11-14 09:30:00")
    }

    func testV011_nullModelThrows() {
        XCTAssertThrowsError(
            try StenographerWire.decoder().decode(OversightFindingDTO.self, from: body(model: "null"))
        ) { error in
            guard case DecodingError.valueNotFound = error else { return XCTFail("expected valueNotFound: \(error)") }
        }
    }

    func testV012_fullActReplyDecodes() throws {
        let finding = try StenographerWire.decoder().decode(OversightFindingDTO.self, from: body())
        XCTAssertEqual(finding.id, 7)
        XCTAssertEqual(finding.sessionId, "s")
        XCTAssertEqual(finding.observer, "compact")
        XCTAssertEqual(finding.kind, "k")
        XCTAssertEqual(finding.severity, 1)
        XCTAssertEqual(finding.status, "acted")
        XCTAssertEqual(finding.source, "rule")
        XCTAssertEqual(finding.model, "")
        XCTAssertEqual(finding.reason, "r")
        XCTAssertEqual(finding.detail, "")
        XCTAssertEqual(finding.createdAt, "2026-10-12T00:00:00Z")
        XCTAssertEqual(finding.updatedAt, "2026-10-12T00:00:00Z")
    }
}
