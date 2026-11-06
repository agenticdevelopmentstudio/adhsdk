import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeRoutingRulesTests: XCTestCase {

    private func notice(
        source: String = "ci", category: String? = nil, urgency: Notice.Urgency = .fyi
    ) -> Notice {
        Notice(source: source, title: "t", urgency: urgency, category: category)
    }

    private func profile(style: NoticeProfile.Style) -> NoticeProfile {
        NoticeProfile(
            style: style, position: .bottomLeft, screens: .all, layer: .normal,
            autoDismiss: 3, forwardToSystem: true
        )
    }

    func testDefaultsMatchSpecTable() {
        let rules = NoticeRoutingRules.defaults
        let expected: [(Notice.Urgency, NoticeProfile.Style, NoticeProfile.Position,
                        NoticeProfile.ScreenSelection, TimeInterval?)] = [
            (.fyi, .toast, .topRight, .main, 8),
            (.eventually, .toast, .topRight, .main, nil),
            (.soon, .toast, .topRight, .cursor, nil),
            (.now, .alert, .center, .cursor, nil),
            (.emergency, .fullScreen, .center, .all, nil)
        ]
        for (urgency, style, position, screens, dismiss) in expected {
            let found = rules.profiles[urgency]
            XCTAssertEqual(found?.style, style, "\(urgency)")
            XCTAssertEqual(found?.position, position, "\(urgency)")
            XCTAssertEqual(found?.screens, screens, "\(urgency)")
            XCTAssertEqual(found?.layer, .floating, "\(urgency)")
            XCTAssertEqual(found?.autoDismiss, dismiss, "\(urgency)")
            XCTAssertEqual(found?.forwardToSystem, false, "\(urgency)")
        }
        XCTAssertEqual(rules.toastStackLimit, 4)
        XCTAssertEqual(rules.flood, FloodFolder.Configuration(threshold: 5, window: 10))
        XCTAssertEqual(rules.escalation.soonToNowAfter, 900)
        XCTAssertEqual(rules.escalation.eventuallyToSoonAfter, 0)
        XCTAssertTrue(rules.hideFromScreenSharing)
        XCTAssertTrue(rules.hotkeysEnabled)
        XCTAssertFalse(rules.crawlLeftToRight)
        XCTAssertTrue(rules.overrides.isEmpty)
    }

    func testFirstMatchingOverrideWins() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [
            .init(source: "ci", profile: profile(style: .crawl)),
            .init(source: "ci", profile: profile(style: .none))
        ]
        XCTAssertEqual(rules.profile(for: notice()).style, .crawl)
        XCTAssertEqual(rules.profile(for: notice(source: "other")).style, .toast)
    }

    func testOverrideCategoryIsCaseInsensitive() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(category: "Builds", profile: profile(style: .system))]
        XCTAssertEqual(rules.profile(for: notice(category: "bUILDS")).style, .system)
        XCTAssertEqual(rules.profile(for: notice(category: "other")).style, .toast)
        XCTAssertEqual(rules.profile(for: notice(category: nil)).style, .toast)
    }

    func testEffectiveUrgencySelectsEscalatedProfile() {
        let rules = NoticeRoutingRules.defaults
        let soon = notice(urgency: .soon)
        XCTAssertEqual(rules.profile(for: soon).style, .toast)
        XCTAssertEqual(rules.profile(for: soon, effectiveUrgency: .now).style, .alert)
    }

    func testOverrideUrgencyMatchesEffectiveUrgency() {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(urgency: .now, profile: profile(style: .crawl))]
        let soon = notice(urgency: .soon)
        XCTAssertEqual(rules.profile(for: soon).style, .toast)
        XCTAssertEqual(rules.profile(for: soon, effectiveUrgency: .now).style, .crawl)
    }

    func testLegacyDeliverTrueTurnsOnFyiForwarding() {
        let migrated = NoticeRoutingRules.migratingLegacyDeliverSetting(true, into: .defaults)
        XCTAssertEqual(migrated.profiles[.fyi]?.forwardToSystem, true)
        XCTAssertEqual(migrated.profiles[.soon]?.forwardToSystem, false)
    }

    func testLegacyDeliverNilOrFalseChangesNothing() {
        XCTAssertEqual(NoticeRoutingRules.migratingLegacyDeliverSetting(nil, into: .defaults), .defaults)
        XCTAssertEqual(NoticeRoutingRules.migratingLegacyDeliverSetting(false, into: .defaults), .defaults)
    }

    func testRulesRoundTripJSON() throws {
        var rules = NoticeRoutingRules.defaults
        rules.overrides = [.init(source: "ci", category: "builds", urgency: .soon, profile: profile(style: .crawl))]
        rules.crawlLeftToRight = true
        let data = try NoticeCoding.encoder.encode(rules)
        XCTAssertEqual(try NoticeCoding.decoder.decode(NoticeRoutingRules.self, from: data), rules)

        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains(#""fyi":{"#), "profiles are keyed by urgency name, not a flat array")
    }
}
