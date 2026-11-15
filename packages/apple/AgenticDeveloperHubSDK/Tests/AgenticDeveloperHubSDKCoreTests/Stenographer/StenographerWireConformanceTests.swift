import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Vectors stenographer-wire-005 to 008. Vectors 001 to 004 are covered by
/// `StenographerPreferenceDTOsTests` (the vector ids name those tests).
final class StenographerWireConformanceTests: XCTestCase {

    private struct Stamped: Codable, Equatable {
        let createdAt: Date
    }

    func testV5_encoderReturnsFreshInstanceEachCall() {
        XCTAssertFalse(StenographerWire.encoder() === StenographerWire.encoder())
        XCTAssertFalse(StenographerWire.decoder() === StenographerWire.decoder())
    }

    func testV6_encoderWritesDatesAsISO8601Strings() throws {
        let date = Date(timeIntervalSince1970: 1_791_763_200) // 2026-10-12T00:00:00Z
        let data = try StenographerWire.encoder().encode(Stamped(createdAt: date))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["created_at"] as? String, "2026-10-12T00:00:00Z")
    }

    func testV7_decoderRejectsMalformedDateString() throws {
        let good = Data(#"{"created_at":"2026-10-12T00:00:00Z"}"#.utf8)
        let decoded = try StenographerWire.decoder().decode(Stamped.self, from: good)
        XCTAssertEqual(decoded.createdAt, Date(timeIntervalSince1970: 1_791_763_200))

        let bad = Data(#"{"created_at":"not a date"}"#.utf8)
        XCTAssertThrowsError(try StenographerWire.decoder().decode(Stamped.self, from: bad)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testV8_decoderDoesNotSupplyMissingKeys() {
        XCTAssertThrowsError(
            try StenographerWire.decoder().decode(SummaryPreferenceResponse.self, from: Data("{}".utf8))
        ) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
