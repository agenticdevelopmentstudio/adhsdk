import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NotificationCrawlSettingsPanelTests: XCTestCase {

    func testCrawlPanelWritesEverySetting() throws {
        _ = NSApplication.shared
        let store = makeTestStore()
        let panel = NotificationCrawlSettingsPanel(store: store)
        panel.loadViewIfNeeded()
        let view = panel.view
        func crawl() -> CrawlSettings { storedRules(store).crawl }
        func control<T: NSView>(_ type: T.Type, _ title: String) throws -> T {
            let rowView = try XCTUnwrap(row(titled: title, in: view), title)
            return try XCTUnwrap(first(type, in: rowView), title)
        }

        choose("Top", in: try control(NSPopUpButton.self, "Edge"))
        XCTAssertEqual(crawl().edge, .top)

        let direction = try control(NSPopUpButton.self, "Direction")
        choose("Left to Right", in: direction)
        XCTAssertTrue(crawl().leftToRight)
        choose("Right to Left", in: direction)
        XCTAssertFalse(crawl().leftToRight)

        let show = try control(NSButton.self, "Show background")
        show.state = .off
        fire(show)
        XCTAssertFalse(crawl().showsBackground)

        func slide(_ title: String, to value: Double) throws {
            let slider = try control(NSSlider.self, title)
            slider.doubleValue = value
            fire(slider)
        }
        try slide("Speed", to: 200)
        XCTAssertEqual(crawl().speed, 200, accuracy: 0.01)
        try slide("Text size", to: 20)
        XCTAssertEqual(crawl().textSize, 20, accuracy: 0.01)
        try slide("Background transparency", to: 30)
        XCTAssertEqual(crawl().backgroundOpacity, 0.7, accuracy: 0.001)
        try slide("Item transparency", to: 50)
        XCTAssertEqual(crawl().itemOpacity, 0.5, accuracy: 0.001)
    }
}
