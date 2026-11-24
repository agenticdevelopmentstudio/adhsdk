import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `TrackingPreferenceResponse` (the shape itself; the daemon logic
/// that builds it is covered in `PreferencesServiceTests`).
final class TrackingResponseConformanceTests: XCTestCase {

    /// A consumer-side reader: `outcome` is a plain string, so an unknown word decodes.
    private struct OutcomeReader: Decodable {
        let enabled: Bool
        let disabledMarkerPresent: Bool
        let outcome: String
    }

    func testV008_memberwiseInitHoldsTheThreeValues() {
        let response = TrackingPreferenceResponse(enabled: true, disabledMarkerPresent: false, outcome: "current")
        XCTAssertTrue(response.enabled)
        XCTAssertFalse(response.disabledMarkerPresent)
        XCTAssertEqual(response.outcome, "current")
    }

    func testV009_encodesTheThreeKeysWithBoolBoolString() throws {
        let response = TrackingPreferenceResponse(enabled: true, disabledMarkerPresent: false, outcome: "current")
        let data = try JSONEncoder().encode(response)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["enabled", "disabledMarkerPresent", "outcome"])
        XCTAssertEqual(object["enabled"] as? Bool, true)
        XCTAssertEqual(object["disabledMarkerPresent"] as? Bool, false)
        XCTAssertEqual(object["outcome"] as? String, "current")
    }

    func testV011_openOutcomeStringIsAcceptedByAReader() throws {
        let json = Data(#"{"enabled":true,"disabledMarkerPresent":false,"outcome":"something_new"}"#.utf8)
        let decoded = try JSONDecoder().decode(OutcomeReader.self, from: json)
        XCTAssertEqual(decoded.outcome, "something_new")
        let encoded = try JSONEncoder().encode(
            TrackingPreferenceResponse(enabled: true, disabledMarkerPresent: false, outcome: "something_new")
        )
        XCTAssertEqual(try JSONDecoder().decode(OutcomeReader.self, from: encoded).outcome, "something_new")
    }
}
