import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelBodyRewriterTests: XCTestCase {
    private func roundTrip(_ object: [String: Any], maxOutput: Int?) throws -> [String: Any] {
        let data = try XCTUnwrap(ModelBodyRewriter.rewrite(object, model: "claude-sonnet-5-5", maxOutput: maxOutput))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testOnlyModelChanges() throws {
        let original: [String: Any] = ["model": "claude-opus-5-5", "max_tokens": 100, "stream": true,
                                       "messages": [["role": "user", "content": "hi"]]]
        let result = try roundTrip(original, maxOutput: nil)
        XCTAssertEqual(result["model"] as? String, "claude-sonnet-5-5")
        var expected = original
        expected["model"] = "claude-sonnet-5-5"
        XCTAssertEqual(NSDictionary(dictionary: result), NSDictionary(dictionary: expected))
    }

    func testClampsMaxTokensAndThinkingBudget() throws {
        let object: [String: Any] = ["model": "m", "max_tokens": 64_000,
                                     "thinking": ["type": "enabled", "budget_tokens": 40_000]]
        let result = try roundTrip(object, maxOutput: 32_000)
        XCTAssertEqual(result["max_tokens"] as? Int, 32_000)
        XCTAssertEqual((result["thinking"] as? [String: Any])?["budget_tokens"] as? Int, 31_999)
        XCTAssertEqual(try roundTrip(object, maxOutput: 100_000)["max_tokens"] as? Int, 64_000)
    }

    func testExtremeMaxTokensNeverTrap() throws {
        let thinking: [String: Any] = ["type": "enabled", "budget_tokens": 40_000]
        XCTAssertNil(ModelBodyRewriter.rewrite(
            ["model": "m", "max_tokens": Int.min, "thinking": thinking], model: "x", maxOutput: nil))
        XCTAssertNil(ModelBodyRewriter.rewrite(
            ["model": "m", "max_tokens": -3, "thinking": thinking], model: "x", maxOutput: nil))
        XCTAssertNil(ModelBodyRewriter.rewrite(
            ["model": "m", "max_tokens": 0, "thinking": thinking], model: "x", maxOutput: nil))
        let huge = try roundTrip(["model": "m", "max_tokens": Int.max, "thinking": thinking], maxOutput: nil)
        XCTAssertEqual(huge["max_tokens"] as? Int, Int.max)
        XCTAssertEqual((huge["thinking"] as? [String: Any])?["budget_tokens"] as? Int, 40_000)
        let clamped = try roundTrip(["model": "m", "max_tokens": Int.max, "thinking": thinking], maxOutput: 32_000)
        XCTAssertEqual(clamped["max_tokens"] as? Int, 32_000)
        XCTAssertEqual(try roundTrip(["model": "m", "max_tokens": -3], maxOutput: 32_000)["max_tokens"] as? Int, -3,
                       "no thinking budget: a negative max_tokens passes untouched for upstream to refuse")
    }
}
