import XCTest
@testable import AgenticDeveloperHubSDKNotificationsUI

final class DismissAfterChoiceTests: XCTestCase {

    func testPresetsAreNeverThenFiveEightFifteenThirtySixty() {
        XCTAssertEqual(DismissAfterChoice.presets, [nil, 5, 8, 15, 30, 60])
    }

    func testEveryPresetMapsToItself() {
        for seconds in DismissAfterChoice.presets {
            XCTAssertEqual(DismissAfterChoice(seconds: seconds), .preset(seconds))
        }
    }

    func testStoredNonPresetIsCustomWithItsValue() {
        XCTAssertEqual(DismissAfterChoice(seconds: 12), .custom(12))
        XCTAssertEqual(DismissAfterChoice(seconds: 3600), .custom(3600))
    }

    func testTitles() {
        XCTAssertEqual(DismissAfterChoice.preset(nil).title, "Never")
        XCTAssertEqual(DismissAfterChoice.preset(8).title, "8 seconds")
        XCTAssertEqual(DismissAfterChoice.custom(12).title, "Custom…")
    }

    func testCustomSecondsAcceptsWholeNumbersInRangeOnly() {
        XCTAssertEqual(DismissAfterChoice.customSeconds(from: "1"), 1)
        XCTAssertEqual(DismissAfterChoice.customSeconds(from: " 3600 "), 3600)
        XCTAssertNil(DismissAfterChoice.customSeconds(from: "0"))
        XCTAssertNil(DismissAfterChoice.customSeconds(from: "3601"))
        XCTAssertNil(DismissAfterChoice.customSeconds(from: "2.5"))
        XCTAssertNil(DismissAfterChoice.customSeconds(from: "abc"))
        XCTAssertNil(DismissAfterChoice.customSeconds(from: ""))
    }
}
