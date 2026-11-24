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

    // MARK: One unknown value costs only its element

    private func rules(_ json: String) throws -> NoticeRoutingRules {
        try JSONDecoder().decode(NoticeRoutingRules.self, from: Data(json.utf8))
    }

    func testAnItemWithAnUnknownStyleIsSkippedAndTheRulesSurvive() throws {
        let decoded = try rules("""
            {"styles":{"soon":{"items":[{"style":"hologram"},{"style":"crawl","position":"topCenter"}],
            "autoDismiss":12},"now":{"items":[{"style":"system"}]}},
            "overrides":[{"source":"ci","target":"emergency"}],"toastStackLimit":2}
            """)
        let soon = try XCTUnwrap(decoded.styles[.soon])
        XCTAssertEqual(soon.items, [NoticeProfile(style: .crawl, position: .topCenter)])
        XCTAssertEqual(soon.autoDismiss, 12)
        XCTAssertEqual(decoded.styles[.now]?.items, [NoticeProfile(style: .system)])
        XCTAssertEqual(decoded.overrides, [.init(source: "ci", target: .style(.emergency))])
        XCTAssertEqual(decoded.toastStackLimit, 2)
    }

    func testAnOverrideWithAnUnknownTargetIsSkippedAndTheRulesSurvive() throws {
        let decoded = try rules("""
            {"styles":{"fyi":{"items":[{"style":"alert"}]}},
            "overrides":[{"source":"a","target":"teleport"},{"category":"builds","target":"hide"},
            {"source":"b","urgency":"someday","target":"now"}],"hideFromScreenSharing":false}
            """)
        XCTAssertEqual(decoded.overrides, [.init(category: "builds", target: .hide)])
        XCTAssertEqual(decoded.styles[.fyi]?.items, [NoticeProfile(style: .alert)])
        XCTAssertFalse(decoded.hideFromScreenSharing)
    }

    func testALegacyOverrideThatCannotBeReadIsSkipped() throws {
        let decoded = try rules("""
            {"profiles":{"fyi":{"style":"crawl"}},
            "overrides":[{"urgency":"someday","profile":{"style":"toast"}},{"source":"ci","profile":{"style":"none"}}]}
            """)
        XCTAssertEqual(decoded.overrides, [.init(source: "ci", target: .hide)])
        XCTAssertEqual(decoded.styles[.fyi]?.items.map(\.style), [.crawl])
    }

    func testALegacyOverrideWithAnUnknownStylePointsAtFyiNotHide() throws {
        let decoded = try rules("""
            {"profiles":{"fyi":{"style":"crawl"}},
            "overrides":[{"source":"ci","profile":{"style":"banner"}}]}
            """)
        XCTAssertEqual(decoded.overrides, [.init(source: "ci", target: .style(.fyi))])
    }

    func testOneMalformedLegacyProfileDropsOnlyItself() throws {
        let decoded = try rules("""
            {"profiles":{"fyi":{"style":"crawl"},"now":{"position":"center"}}}
            """)
        XCTAssertEqual(decoded.styles[.fyi]?.items.map(\.style), [.crawl])
        XCTAssertEqual(decoded.styles[.now], NoticeRoutingRules.defaults.styles[.now])
    }

    func testAnUnknownColorSourceReadsAsTheFieldsDefaultAndTheRulesSurvive() throws {
        let decoded = try rules("""
            {"styles":{"emergency":{"items":[{"style":"fullScreen",
            "fullScreen":{"blur":0.2,"color":{"source":"accent"},"opacity":0.3}}]}},
            "crawl":{"background":{"source":"wallpaper","red":1},"speed":120,"leftToRight":true},
            "toastStackLimit":3}
            """)
        let appearance = try XCTUnwrap(decoded.styles[.emergency]?.items.first?.fullScreen)
        XCTAssertEqual(appearance.color.source, NoticeProfile.FullScreenAppearance().color.source)
        XCTAssertEqual(appearance.blur, 0.2)
        XCTAssertEqual(appearance.opacity, 0.3)
        XCTAssertEqual(decoded.crawl.background.source, CrawlSettings().background.source)
        XCTAssertEqual(decoded.crawl.background.source, .theme, "the crawl's default, not .system")
        XCTAssertEqual(decoded.crawl.speed, 120)
        XCTAssertTrue(decoded.crawl.leftToRight)
        XCTAssertEqual(decoded.toastStackLimit, 3)
    }

    func testAStandaloneColorWithAnUnknownSourceReadsAsSystem() throws {
        let color = try JSONDecoder().decode(NoticeColor.self, from: Data(#"{"source":"accent","red":0.5}"#.utf8))
        XCTAssertEqual(color, NoticeColor(source: .system, red: 0.5))
    }

    func testClampedPinsIntoTheRange() {
        XCTAssertEqual(2.0.clamped(to: 0...1), 1)
        XCTAssertEqual((-3.0).clamped(to: 0...1), 0)
        XCTAssertEqual(50.0.clamped(to: 20...400), 50)
    }
}
