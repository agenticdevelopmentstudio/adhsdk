import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class FullScreenPresenterTests: XCTestCase {

    private final class Recorder {
        var snoozes: [SnoozeOption] = []
        var closes = 0
    }

    private func actions(
        _ recorder: Recorder, snoozable: Bool = true, options: [SnoozeOption] = SnoozeOption.allCases
    ) -> NoticeCardActions {
        var snooze: (@MainActor (SnoozeOption) -> Void)?
        if snoozable {
            snooze = { recorder.snoozes.append($0) }
        }
        return NoticeCardActions(
            act: {}, respond: { _, _ in }, snooze: snooze,
            snoozeOptions: options, archive: nil, close: { recorder.closes += 1 })
    }

    private func view(
        _ actions: NoticeCardActions, appearance: NoticeProfile.FullScreenAppearance = .init()
    ) -> FullScreenNoticeView {
        _ = NSApplication.shared
        return FullScreenNoticeView(
            notice: Notice(source: "pager", title: "Prod down", urgency: .emergency),
            actions: actions, appearance: appearance)
    }

    private func tint(_ view: FullScreenNoticeView) throws -> [CGFloat] {
        let cgColor = try XCTUnwrap(view.tintLayer.backgroundColor)
        let rgb = try XCTUnwrap(NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB))
        return [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent]
    }

    func testFullScreenBackdropUsesAppearance() throws {
        let plain = view(.inert, appearance: .init(blur: 0.3, color: .system, opacity: 0.55))
        XCTAssertEqual(plain.blurView.alphaValue, 0.3, accuracy: 0.001)
        XCTAssertEqual(plain.blurView.material, .fullScreenUI)
        XCTAssertEqual(plain.blurView.blendingMode, .behindWindow)
        XCTAssertEqual(plain.blurView.state, .active)
        let black = try tint(plain)
        XCTAssertEqual(black[0], 0, accuracy: 0.01)
        XCTAssertEqual(black[3], 0.55, accuracy: 0.01, "system is black at the item's opacity")

        let red = view(.inert, appearance: .init(blur: 0.3, color: .custom(red: 1, green: 0, blue: 0), opacity: 0.4))
        let components = try tint(red)
        XCTAssertEqual(components[0], 1, accuracy: 0.01)
        XCTAssertEqual(components[1], 0, accuracy: 0.01)
        XCTAssertEqual(components[3], 0.4, accuracy: 0.01)
    }

    func testUpdateRedrawsTheBackdrop() throws {
        let view = view(.inert)
        view.update(
            notice: Notice(source: "pager", title: "again"), actions: .inert,
            appearance: .init(blur: 0.9, color: .custom(red: 0, green: 1, blue: 0), opacity: 0.2))
        XCTAssertEqual(view.blurView.alphaValue, 0.9, accuracy: 0.001)
        XCTAssertEqual(try tint(view)[3], 0.2, accuracy: 0.01)
    }

    func testEscSnoozesFirstOfferedOptionOrCloses() {
        // Five minutes offered: that one.
        let all = Recorder()
        view(actions(all)).cancelOperation(nil)
        XCTAssertEqual(all.snoozes, [.fiveMinutes])

        // Five minutes not offered: the first option that is.
        let some = Recorder()
        view(actions(some, options: [.oneHour, .untilBack])).cancelOperation(nil)
        XCTAssertEqual(some.snoozes, [.oneHour])
        XCTAssertEqual(some.closes, 0)

        // Not snoozable: Esc closes the notice.
        let off = Recorder()
        view(actions(off, snoozable: false)).cancelOperation(nil)
        XCTAssertTrue(off.snoozes.isEmpty)
        XCTAssertEqual(off.closes, 1)

        // Snoozable in name but offering nothing: still closes.
        let none = Recorder()
        view(actions(none, options: [])).cancelOperation(nil)
        XCTAssertTrue(none.snoozes.isEmpty)
        XCTAssertEqual(none.closes, 1)
    }
}
