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
        _ actions: NoticeCardActions,
        appearance: NoticeProfile.FullScreenAppearance = .init(),
        blur: WindowBackgroundBlur = .unavailable
    ) -> FullScreenNoticeView {
        _ = NSApplication.shared
        return FullScreenNoticeView(
            notice: Notice(source: "pager", title: "Prod down", urgency: .emergency),
            actions: actions, appearance: appearance, blur: blur)
    }

    /// Records every radius set, answering `succeeds`.
    @MainActor
    private final class BlurRecorder {
        var radii: [Int] = []
        var succeeds = true
        var blur: WindowBackgroundBlur {
            WindowBackgroundBlur { [self] _, radius in
                radii.append(radius)
                return succeeds
            }
        }
    }

    /// A panel with a window-server window, so the radius can be set. Never shown.
    private func host(_ view: FullScreenNoticeView) -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.borderless], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.contentView = view
        return panel
    }

    private func tint(_ view: FullScreenNoticeView) throws -> [CGFloat] {
        let cgColor = try XCTUnwrap(view.tintLayer.backgroundColor)
        let rgb = try XCTUnwrap(NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB))
        return [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent]
    }

    func testFullScreenBackdropUsesAppearance() throws {
        let plain = view(.inert, appearance: .init(blur: 0.3, color: .system, opacity: 0.55))
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
        XCTAssertEqual(try tint(view)[3], 0.2, accuracy: 0.01)
    }

    func testBlurAmountMapsToARadius() {
        XCTAssertEqual(WindowBackgroundBlur.radius(for: 0), 0)
        XCTAssertEqual(WindowBackgroundBlur.radius(for: 0.5), WindowBackgroundBlur.maximumRadius / 2)
        XCTAssertEqual(WindowBackgroundBlur.radius(for: 1), WindowBackgroundBlur.maximumRadius)
        XCTAssertEqual(WindowBackgroundBlur.radius(for: 7), WindowBackgroundBlur.maximumRadius, "clamped")
        XCTAssertEqual(WindowBackgroundBlur.radius(for: -1), 0, "clamped")
    }

    func testBlurIsTheWindowRadiusWhenAvailable() {
        let recorder = BlurRecorder()
        let view = view(.inert, appearance: .init(blur: 0.5), blur: recorder.blur)
        XCTAssertNil(view.appliedBlurRadius, "no window yet")
        let panel = host(view)
        defer { panel.close() }
        XCTAssertEqual(recorder.radii.last, WindowBackgroundBlur.radius(for: 0.5))
        XCTAssertEqual(view.appliedBlurRadius, WindowBackgroundBlur.radius(for: 0.5))
        XCTAssertTrue(view.blurView.isHidden, "the window radius replaces the all-or-nothing view")

        view.update(notice: Notice(source: "pager", title: "again"), actions: .inert, appearance: .init(blur: 0.1))
        XCTAssertEqual(view.appliedBlurRadius, WindowBackgroundBlur.radius(for: 0.1), "a change applies live")
    }

    /// An `NSVisualEffectView` below an alpha of 1 does not blur at all, so
    /// the fallback is the view at full strength, or hidden for no blur.
    func testFallbackBlursFullyOrNotAtAll() {
        let recorder = BlurRecorder()
        recorder.succeeds = false
        let some = view(.inert, appearance: .init(blur: 0.3), blur: recorder.blur)
        let panel = host(some)
        defer { panel.close() }
        XCTAssertFalse(recorder.radii.isEmpty, "the radius was tried first")
        XCTAssertNil(some.appliedBlurRadius)
        XCTAssertFalse(some.blurView.isHidden)
        XCTAssertEqual(some.blurView.alphaValue, 1, accuracy: 0.001)

        let none = view(.inert, appearance: .init(blur: 0))
        XCTAssertTrue(none.blurView.isHidden)
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
