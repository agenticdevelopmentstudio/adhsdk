import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeFilterTests: XCTestCase {

    private func notice(
        level: Notice.Level = .info,
        category: String? = nil,
        metadata: [String: String] = [:]
    ) -> Notice {
        Notice(source: "test", title: "Title", level: level, category: category, metadata: metadata)
    }

    func testLevelAtOrAboveTheFloorIsAdmitted() {
        let filter = NoticeFilter(minimumLevelRawValue: "warning", mutedCategories: "")
        for level in [Notice.Level.warning, .error] {
            XCTAssertTrue(filter.admits(notice(level: level)), "\(level) should clear a warning floor")
        }
    }

    func testLevelBelowTheFloorIsRejected() {
        let filter = NoticeFilter(minimumLevelRawValue: "warning", mutedCategories: "")
        for level in [Notice.Level.info, .success] {
            XCTAssertFalse(filter.admits(notice(level: level)), "\(level) should not clear a warning floor")
        }
    }

    /// A bad stored preference must show too much, never swallow everything.
    func testUnknownMinimumLevelFallsBackToInfo() {
        let filter = NoticeFilter(minimumLevelRawValue: "not-a-level", mutedCategories: "")
        XCTAssertEqual(filter.minimumLevel, .info)
        XCTAssertTrue(filter.admits(notice(level: .info)))
    }

    func testMutedCategoryIsRejected() {
        let filter = NoticeFilter(minimumLevelRawValue: "info", mutedCategories: "builds, cron")
        XCTAssertFalse(filter.admits(notice(level: .error, category: "builds")))
    }

    func testMutedCategoryMatchIgnoresCaseAndSpacing() {
        let filter = NoticeFilter(minimumLevelRawValue: "info", mutedCategories: "  BUILDS  ,cron")
        XCTAssertFalse(filter.admits(notice(category: "Builds")))
    }

    func testUncategorizedNoticeIsNeverMuted() {
        let filter = NoticeFilter(minimumLevelRawValue: "info", mutedCategories: "builds")
        XCTAssertTrue(filter.admits(notice(category: nil)))
    }

    func testEmptyMuteListParsesToNothing() {
        XCTAssertTrue(NoticeFilter.categoryList("").isEmpty)
        XCTAssertTrue(NoticeFilter.categoryList("  ,  ,").isEmpty)
    }

    func testExcludedMetadataIsNotAdmitted() {
        let filter = NoticeFilter(excludedMetadata: ["ingested_by": "usernoted"])
        let excluded = notice(metadata: ["ingested_by": "usernoted"])
        let other = notice(metadata: ["ingested_by": "someone-else"])

        XCTAssertFalse(filter.admits(excluded))
        XCTAssertTrue(filter.admits(other))

        let plain = NoticeFilter()
        XCTAssertTrue(plain.admits(excluded))
        XCTAssertTrue(plain.admits(other))
    }

    func testAdmittedByPreservesOrder() {
        let filter = NoticeFilter(minimumLevel: .warning)
        let notices = [notice(level: .error), notice(level: .info), notice(level: .warning)]
        XCTAssertEqual(notices.admitted(by: filter).map(\.level), [.error, .warning])
    }
}
