import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// Panels are built but never ordered front, so no test leaves a window behind.
@MainActor
final class NoticePanelTests: XCTestCase {

    func testToastPanelNeverBecomesKey() {
        _ = NSApplication.shared
        let panel = NoticePanel(layer: .floating, hideFromSharing: false)
        defer { panel.close() }
        XCTAssertFalse(panel.canBecomeKey)
        XCTAssertFalse(panel.canBecomeMain)
        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertTrue(panel.becomesKeyOnlyIfNeeded)
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
        XCTAssertEqual(panel.level, .statusBar)
        XCTAssertFalse(panel.hidesOnDeactivate)
    }

    func testReplyFieldMakesPanelKeyOnlyOnClick() {
        _ = NSApplication.shared
        let panel = NoticePanel(layer: .floating, hideFromSharing: false)
        defer { panel.close() }
        XCTAssertFalse(panel.canBecomeKey)
        panel.allowKeyForReply = true
        XCTAssertTrue(panel.canBecomeKey)
        panel.allowKeyForReply = false
        XCTAssertFalse(panel.canBecomeKey)
    }

    func testTakesFocusPanelCanBecomeKey() {
        _ = NSApplication.shared
        let panel = NoticePanel(layer: .floating, hideFromSharing: false, takesFocus: true)
        defer { panel.close() }
        XCTAssertTrue(panel.canBecomeKey)
    }

    func testHideFromSharingSetsSharingTypeNone() {
        _ = NSApplication.shared
        let hidden = NoticePanel(layer: .floating, hideFromSharing: true)
        let shared = NoticePanel(layer: .floating, hideFromSharing: false)
        defer { hidden.close(); shared.close() }
        XCTAssertEqual(hidden.sharingType, .none)
        XCTAssertNotEqual(shared.sharingType, .none)
    }

    func testNormalLayerUsesNormalLevel() {
        _ = NSApplication.shared
        let panel = NoticePanel(layer: .normal, hideFromSharing: false)
        defer { panel.close() }
        XCTAssertEqual(panel.level, .normal)
        XCTAssertFalse(panel.canBecomeKey)
    }

    func testCardShowsTheNoticeAndLimitsToastActions() {
        _ = NSApplication.shared
        let notice = Notice(
            source: "ci", title: "Build failed", subtitle: "main", body: "3 tests red",
            level: .error, urgency: .soon,
            actions: [
                .init(id: "a", label: "Open", kind: .callback),
                .init(id: "b", label: "Retry", kind: .callback),
                .init(id: "c", label: "Ignore", kind: .callback)
            ])
        let toast = NoticeCardView(notice: notice, actions: .inert, style: .toast)
        XCTAssertEqual(toast.titleLabel.stringValue, "Build failed")
        XCTAssertEqual(toast.subtitleLabel.stringValue, "main")
        XCTAssertEqual(toast.detailsLabel.stringValue, "3 tests red")
        XCTAssertEqual(toast.actionButtons.map(\.title), ["Open", "Retry"])
        XCTAssertFalse(toast.urgencyBadge.isHidden)

        let alert = NoticeCardView(notice: notice, actions: .inert, style: .alert)
        XCTAssertEqual(alert.actionButtons.map(\.title), ["Open", "Retry", "Ignore"])
    }

    func testSnoozeMenuOffersEveryOption() {
        var chosen: [SnoozeOption] = []
        let menu = SnoozeMenu.make { chosen.append($0) }
        XCTAssertEqual(menu.items.map(\.title), SnoozeOption.allCases.map(\.title))
        SnoozeMenu.perform(menu.items[2])
        XCTAssertEqual(chosen, [.oneHour])
    }
}
