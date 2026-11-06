import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NotificationStylesSettingsPanelTests: XCTestCase {

    func testSampleCarriesTheUrgency() {
        for urgency in Notice.Urgency.allCases {
            let sample = NotificationStylesSettingsPanel.sample(for: urgency)
            XCTAssertEqual(sample.urgency, urgency)
            XCTAssertTrue(sample.state.isActive)
            XCTAssertFalse(sample.title.isEmpty)
        }
        XCTAssertNotEqual(
            NotificationStylesSettingsPanel.sample(for: .fyi).id,
            NotificationStylesSettingsPanel.sample(for: .fyi).id,
            "each test is a new notice, so it is never deduplicated away")
    }

    func testSendTestGoesThroughTheHandler() {
        _ = NSApplication.shared
        let handler = RecordingHandler()
        let panel = NotificationStylesSettingsPanel(handler: handler)
        panel.sendTest(.now)
        XCTAssertEqual(handler.calls.count, 1)
        guard case .sendTest = handler.calls.first else {
            return XCTFail("expected sendTest, got \(handler.calls)")
        }
        XCTAssertEqual(panel.lastSentTest?.urgency, .now)
    }

    func testPanelListsEveryUrgencyAndTheUnavailableFocusRow() {
        _ = NSApplication.shared
        let panel = NotificationStylesSettingsPanel(handler: RecordingHandler())
        panel.loadViewIfNeeded()
        let text = Self.strings(in: panel.view).joined(separator: "\n")
        for urgency in Notice.Urgency.allCases {
            XCTAssertTrue(text.contains(NotificationStylesSettingsPanel.title(for: urgency)), "\(urgency)")
        }
        XCTAssertTrue(text.contains("Unavailable — needs the Focus Status entitlement"))
        XCTAssertEqual(Self.buttons(in: panel.view, titled: "Send test").count, Notice.Urgency.allCases.count)
    }

    /// An urgency's row shows that urgency's own profile: an override that
    /// happens to match the sample notice must not leak into it.
    func testUrgencyRowsIgnoreOverrides() {
        var rules = NoticeRoutingRules.defaults
        let base = NotificationStylesSettingsPanel.baseProfile(for: .fyi, in: rules)
        var crawl = base
        crawl.style = .crawl
        rules.overrides = [.init(category: "test", profile: crawl)]
        XCTAssertEqual(rules.profile(for: NotificationStylesSettingsPanel.sample(for: .fyi)).style, .crawl)
        XCTAssertEqual(NotificationStylesSettingsPanel.baseProfile(for: .fyi, in: rules), base)

        rules.profiles[.fyi] = nil
        XCTAssertEqual(
            NotificationStylesSettingsPanel.baseProfile(for: .fyi, in: rules),
            NoticeRoutingRules.defaultProfile(for: .fyi))
    }

    private static func strings(in view: NSView) -> [String] {
        var found: [String] = []
        if let field = view as? NSTextField { found.append(field.stringValue) }
        if let button = view as? NSButton { found.append(button.title) }
        return found + view.subviews.flatMap { strings(in: $0) }
    }

    private static func buttons(in view: NSView, titled title: String) -> [NSButton] {
        var found: [NSButton] = []
        if let button = view as? NSButton, button.title == title { found.append(button) }
        return found + view.subviews.flatMap { buttons(in: $0, titled: title) }
    }
}
