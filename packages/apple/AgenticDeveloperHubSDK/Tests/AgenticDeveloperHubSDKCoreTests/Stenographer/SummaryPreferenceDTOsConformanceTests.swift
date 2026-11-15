import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Vectors 001-003 and 010-015 of summary-preference-dt-os. Vectors 004-009 are
/// exercised through the daemon (`PreferencesServiceTests`, `DaemonSessionSummarizerTests`).
final class SummaryPreferenceDTOsConformanceTests: XCTestCase {

    func testV1_characterCapFloorsAtEighty() {
        XCTAssertEqual(SummaryDefaults.characterCap(maxWords: 8), 80)
        XCTAssertEqual(SummaryDefaults.characterCap(maxWords: 4), 80)
    }

    func testV2_characterCapScalesAtTwentyWords() {
        XCTAssertEqual(SummaryDefaults.characterCap(maxWords: 20), 200)
    }

    func testV3_floorEndsAboveEightWords() {
        XCTAssertEqual(SummaryDefaults.characterCap(maxWords: 8), 80)
        XCTAssertEqual(SummaryDefaults.characterCap(maxWords: 9), 90)
    }

    func testV10_clampPinsToRangeBounds() {
        XCTAssertEqual(SummaryLimits.clamp(3, to: 4...20), 4)
        XCTAssertEqual(SummaryLimits.clamp(12, to: 4...20), 12)
        XCTAssertEqual(SummaryLimits.clamp(25, to: 4...20), 20)
    }

    func testV11_timeoutSettingsKey() {
        XCTAssertEqual(SummarySettingsKeys.timeoutSeconds, "ai_summary_timeout_seconds")
    }

    func testV12_limitRanges() {
        XCTAssertEqual(SummaryLimits.maxWords, 4...20)
        XCTAssertEqual(SummaryLimits.activityLines, 10...400)
        XCTAssertEqual(SummaryLimits.detailChars, 40...500)
        XCTAssertEqual(SummaryLimits.intervalMinutes, 1...240)
        XCTAssertEqual(SummaryLimits.maxPerRun, 1...50)
        XCTAssertEqual(SummaryLimits.timeoutSeconds, 10...600)
    }

    func testV13_promptHoldsPlaceholderOnceInFirstSentence() throws {
        let prompt = SummaryDefaults.prompt
        let token = SummaryDefaults.maxWordsPlaceholder
        XCTAssertEqual(token, "{maxWords}")
        XCTAssertEqual(prompt.components(separatedBy: token).count - 1, 1)
        let tokenRange = try XCTUnwrap(prompt.range(of: token))
        let sentenceEnd = try XCTUnwrap(prompt.range(of: ". "))
        XCTAssertLessThan(tokenRange.lowerBound, sentenceEnd.lowerBound)
    }

    func testV14_defaultsSitInsideLimits() {
        XCTAssertEqual(SummaryDefaults.maxWords, 8)
        XCTAssertEqual(SummaryDefaults.activityLines, 60)
        XCTAssertEqual(SummaryDefaults.detailChars, 120)
        XCTAssertEqual(SummaryDefaults.intervalMinutes, 5)
        XCTAssertEqual(SummaryDefaults.maxPerRun, 5)
        XCTAssertEqual(SummaryDefaults.timeoutSeconds, 60)
        XCTAssertTrue(SummaryLimits.maxWords.contains(SummaryDefaults.maxWords))
        XCTAssertTrue(SummaryLimits.activityLines.contains(SummaryDefaults.activityLines))
        XCTAssertTrue(SummaryLimits.detailChars.contains(SummaryDefaults.detailChars))
        XCTAssertTrue(SummaryLimits.intervalMinutes.contains(SummaryDefaults.intervalMinutes))
        XCTAssertTrue(SummaryLimits.maxPerRun.contains(SummaryDefaults.maxPerRun))
        XCTAssertTrue(SummaryLimits.timeoutSeconds.contains(SummaryDefaults.timeoutSeconds))
    }

    func testV15_promptIsSingleLine() {
        XCTAssertFalse(SummaryDefaults.prompt.contains("\n"))
    }
}
