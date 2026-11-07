import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeStyleSetTests: XCTestCase {

    func testSnoozeSettingsIsSnoozable() {
        XCTAssertTrue(SnoozeSettings().isSnoozable)
        XCTAssertFalse(SnoozeSettings(isEnabled: false, options: SnoozeOption.allCases).isSnoozable)
        XCTAssertFalse(SnoozeSettings(isEnabled: true, options: []).isSnoozable)
    }

    func testSnoozeOptionsKeepAllCasesOrderAndDropDuplicates() {
        let settings = SnoozeSettings(options: [.untilBack, .fiveMinutes, .untilBack])
        XCTAssertEqual(settings.options, [.fiveMinutes, .untilBack])
    }

    func testSnoozeOptionCodesByCaseName() throws {
        let data = try JSONEncoder().encode(SnoozeOption.allCases)
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            #"["fiveMinutes","fifteenMinutes","oneHour","tomorrowMorning","untilBack"]"#)
    }

    func testSnoozeSettingsDecodeSkipsUnknownOptions() throws {
        let json = #"{"isEnabled":false,"options":["oneHour","fortnight","fiveMinutes"]}"#
        let settings = try JSONDecoder().decode(SnoozeSettings.self, from: Data(json.utf8))
        XCTAssertEqual(settings, SnoozeSettings(isEnabled: false, options: [.fiveMinutes, .oneHour]))
    }

    func testPresentedItemsCarryTheSetsDismiss() {
        let set = NoticeStyleSet(
            items: [NoticeProfile(style: .toast), NoticeProfile(style: .system)], autoDismiss: 15)
        XCTAssertEqual(set.presentedItems.map(\.autoDismiss), [15, 15])
        XCTAssertEqual(set.items.map(\.autoDismiss), [nil, nil], "stored items never hold it")
    }

    func testItemAutoDismissIsNeverEncoded() throws {
        let item = NoticeProfile(style: .toast, autoDismiss: 30)
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(item), encoding: .utf8))
        XCTAssertFalse(json.contains("autoDismiss"))
        XCTAssertNil(try JSONDecoder().decode(NoticeProfile.self, from: Data(json.utf8)).autoDismiss)
    }

    func testCrawlSettingsClampToTheirRanges() {
        let low = CrawlSettings(backgroundOpacity: -1, speed: 1, textSize: 1, itemOpacity: 0)
        XCTAssertEqual(low.backgroundOpacity, 0)
        XCTAssertEqual(low.speed, 20)
        XCTAssertEqual(low.textSize, 10)
        XCTAssertEqual(low.itemOpacity, 0.2)
        let high = CrawlSettings(backgroundOpacity: 2, speed: 1000, textSize: 99, itemOpacity: 3)
        XCTAssertEqual(high.backgroundOpacity, 1)
        XCTAssertEqual(high.speed, 400)
        XCTAssertEqual(high.textSize, 28)
        XCTAssertEqual(high.itemOpacity, 1)
    }

    func testCrawlSettingsPartialJSONKeepsDefaults() throws {
        let crawl = try JSONDecoder().decode(CrawlSettings.self, from: Data(#"{"edge":"top","speed":120}"#.utf8))
        var expected = CrawlSettings()
        expected.edge = .top
        expected.speed = 120
        XCTAssertEqual(crawl, expected)
    }

    func testNoticeColorClampsCustomComponents() {
        let color = NoticeColor.custom(red: 2, green: -1, blue: 0.5)
        XCTAssertEqual(color, NoticeColor(source: .custom, red: 1, green: 0, blue: 0.5))
    }
}
