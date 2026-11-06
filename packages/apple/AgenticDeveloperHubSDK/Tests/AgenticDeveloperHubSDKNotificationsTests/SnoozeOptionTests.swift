import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class SnoozeOptionTests: XCTestCase {

    private func calendar(_ zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: zone))
        return calendar
    }

    private func date(_ calendar: Calendar, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws -> Date {
        let parts = DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)
        return try XCTUnwrap(calendar.date(from: parts))
    }

    func testTomorrowMorningAcrossDST() throws {
        let calendar = try calendar("America/Los_Angeles")
        let now = try date(calendar, 11, 1, 1, 30)
        let expected = try date(calendar, 11, 2, 9, 0)
        XCTAssertEqual(SnoozeOption.tomorrowMorning.until(now: now, calendar: calendar), expected)
    }

    func testTomorrowMorningAcrossSpringForward() throws {
        let calendar = try calendar("America/Los_Angeles")
        let now = try date(calendar, 3, 7, 22, 0)
        let expected = try date(calendar, 3, 8, 9, 0)
        XCTAssertEqual(SnoozeOption.tomorrowMorning.until(now: now, calendar: calendar), expected)
    }

    func testTomorrowMorningAcrossFallBack() throws {
        let calendar = try calendar("America/Los_Angeles")
        let now = try date(calendar, 10, 31, 22, 0)
        let expected = try date(calendar, 11, 1, 9, 0)
        XCTAssertEqual(SnoozeOption.tomorrowMorning.until(now: now, calendar: calendar), expected)
    }

    func testTomorrowMorningLateEvening() throws {
        let calendar = try calendar("America/New_York")
        let now = try date(calendar, 3, 10, 23, 59)
        let expected = try date(calendar, 3, 11, 9, 0)
        XCTAssertEqual(SnoozeOption.tomorrowMorning.until(now: now, calendar: calendar), expected)
    }

    func testFixedDurations() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(SnoozeOption.fiveMinutes.until(now: now, calendar: calendar), now.addingTimeInterval(300))
        XCTAssertEqual(SnoozeOption.fifteenMinutes.until(now: now, calendar: calendar), now.addingTimeInterval(900))
        XCTAssertEqual(SnoozeOption.oneHour.until(now: now, calendar: calendar), now.addingTimeInterval(3_600))
        XCTAssertEqual(SnoozeOption.untilBack.until(now: now, calendar: calendar), now.addingTimeInterval(86_400))
    }

    func testTitles() {
        XCTAssertEqual(
            SnoozeOption.allCases.map(\.title),
            ["5 minutes", "15 minutes", "1 hour", "Tomorrow at 9:00", "Until I'm back"]
        )
    }
}
