import XCTest
@testable import AgenticDeveloperHubSDKMacOS

final class ProportionalDividersTests: XCTestCase {

    func testPanesKeepTheirSharesOfANewLength() {
        // 100 and 300 of 400, given 200: 50 and 150, divider after the first.
        let positions = ProportionalDividers.positions(
            oldThicknesses: [100, 300], available: 200, start: 0, dividerThickness: 1)
        XCTAssertEqual(positions, [50])
    }

    func testPositionsAreMeasuredFromStartAndStepOverDividers() {
        let positions = ProportionalDividers.positions(
            oldThicknesses: [10, 10, 20], available: 80, start: 100, dividerThickness: 2)
        // 20, 20, 40 laid out from 100 with 2pt dividers between.
        XCTAssertEqual(positions, [120, 142])
    }

    func testNothingToDivideGivesNoPositions() {
        XCTAssertEqual(ProportionalDividers.positions(
            oldThicknesses: [100], available: 50, start: 0, dividerThickness: 1), [])
        XCTAssertEqual(ProportionalDividers.positions(
            oldThicknesses: [0, 0], available: 50, start: 0, dividerThickness: 1), [])
        XCTAssertEqual(ProportionalDividers.positions(
            oldThicknesses: [10, 10], available: 0, start: 0, dividerThickness: 1), [])
    }
}
