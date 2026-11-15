import XCTest
@testable import AgenticDeveloperHubSDKCore

final class AIInteractionDTOConformanceTests: XCTestCase {

    private func makeDTO(outcome: String = "ok", error: String = "", response: String = "reply") -> AIInteractionDTO {
        AIInteractionDTO(
            id: 7, feature: "summarize", sessionId: "sess", providerKind: "cli", configName: "",
            model: "haiku", systemPrompt: "sys", userPrompt: "user", response: response,
            durationMs: 42, outcome: outcome, error: error, truncated: false,
            createdAt: "2026-07-10 12:00:00")
    }

    func testV1_anOkOutcomeIsNotAFailure() {
        XCTAssertFalse(makeDTO(outcome: "ok").isFailure)
    }

    func testV2_aGuardBlockedOutcomeIsAFailureWithItsReason() {
        let dto = makeDTO(outcome: "guard_blocked", error: "blocked: over the threshold", response: "")
        XCTAssertTrue(dto.isFailure)
        XCTAssertEqual(dto.error, "blocked: over the threshold")
        XCTAssertEqual(dto.response, "")
    }

    func testV3_aGuardDeferredOutcomeIsAFailureWithItsReason() {
        let dto = makeDTO(outcome: "guard_deferred", error: "deferred: memory pressure", response: "")
        XCTAssertTrue(dto.isFailure)
        XCTAssertEqual(dto.error, "deferred: memory pressure")
    }

    func testV4_anErrorOutcomeIsAFailure() {
        XCTAssertTrue(makeDTO(outcome: "error", error: "boom", response: "").isFailure)
    }

    func testV5_anOutcomeOutsideTheVocabularyIsAFailure() {
        XCTAssertTrue(makeDTO(outcome: "surprise").isFailure)
    }

    func testV6_theOutcomeComparisonIsCaseSensitive() {
        XCTAssertTrue(makeDTO(outcome: "OK").isFailure)
    }

    func testV7_encodingThenDecodingGivesTheOriginal() throws {
        let original = makeDTO(outcome: "error", error: "boom", response: "")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIInteractionDTO.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testV8_decodingWithoutTruncatedThrowsKeyNotFound() throws {
        let data = try JSONEncoder().encode(makeDTO())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "truncated")
        let stripped = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try JSONDecoder().decode(AIInteractionDTO.self, from: stripped)) { thrown in
            guard case DecodingError.keyNotFound(let key, _) = thrown else {
                return XCTFail("expected keyNotFound, got \(thrown)")
            }
            XCTAssertEqual(key.stringValue, "truncated")
        }
    }
}
