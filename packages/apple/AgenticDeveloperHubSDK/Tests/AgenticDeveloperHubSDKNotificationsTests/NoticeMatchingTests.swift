import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeMatchingTests: XCTestCase {

    func testEmptyFilterMatchesEverything() {
        XCTAssertTrue(Notice(source: "ci", title: "t").matches(filters: [:]))
    }

    func testReservedKeysMatchFieldsAndEverythingElseMatchesMetadata() {
        let notice = Notice(
            source: "ci", title: "t", level: .warning, category: "builds", metadata: ["repo": "rooster"]
        )
        XCTAssertTrue(notice.matches(filters: ["source": "ci"]))
        XCTAssertFalse(notice.matches(filters: ["source": "other"]))
        XCTAssertTrue(notice.matches(filters: ["level": "warning"]))
        XCTAssertTrue(notice.matches(filters: ["category": "builds", "repo": "rooster"]))
        XCTAssertFalse(notice.matches(filters: ["repo": "stenographer"]))
        XCTAssertFalse(notice.matches(filters: ["absent": "anything"]))
    }

    func testMinLevelComparesByRankNotByString() {
        let warning = Notice(source: "ci", title: "t", level: .warning)
        XCTAssertTrue(warning.matches(filters: ["min_level": "info"]))
        XCTAssertTrue(warning.matches(filters: ["min_level": "warning"]))
        XCTAssertFalse(warning.matches(filters: ["min_level": "error"]))
    }

    func testEveryFilterKeyMustMatch() {
        let notice = Notice(source: "ci", title: "t", category: "builds")
        XCTAssertFalse(notice.matches(filters: ["source": "ci", "category": "deploys"]))
    }

    func testAJunkMinLevelMatchesNothing() {
        let notice = Notice(source: "ci", title: "t", level: .info)
        XCTAssertFalse(notice.matches(filters: ["min_level": "nonsense"]))
        XCTAssertFalse(notice.matches(filters: ["min_level": "warning"]))
    }

    func testMinUrgencyFiltersByRank() {
        let soon = Notice(source: "ci", title: "t", urgency: .soon)
        XCTAssertTrue(soon.matches(filters: ["min_urgency": "soon"]))
        XCTAssertTrue(soon.matches(filters: ["min_urgency": "fyi"]))
        XCTAssertFalse(soon.matches(filters: ["min_urgency": "now"]))
    }

    func testUnknownMinUrgencyMatchesNothing() {
        let notice = Notice(source: "ci", title: "t", urgency: .emergency)
        XCTAssertFalse(notice.matches(filters: ["min_urgency": "bogus"]))
    }
}
