import AppKit
import AgenticDeveloperHubSDKNotifications

/// One screen, as a presenter needs it: an identity that survives
/// `NSScreen.screens` refreshes, and its frames. A value, so presenters are
/// tested with made-up screens instead of reading `NSScreen`.
struct NoticeScreen: Equatable {
    let displayID: UInt32
    let frame: CGRect
    let visibleFrame: CGRect

    init(displayID: UInt32, frame: CGRect, visibleFrame: CGRect) {
        self.displayID = displayID
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    @MainActor
    init(_ screen: NSScreen) {
        self.init(displayID: screen.noticeDisplayID, frame: screen.frame, visibleFrame: screen.visibleFrame)
    }
}

/// The screens for a selection, sampled when called.
typealias NoticeScreenProvider = @MainActor (NoticeProfile.ScreenSelection) -> [NoticeScreen]

extension ScreenSelector {
    /// `current(for:)` as values.
    @MainActor
    static func noticeScreens(for selection: NoticeProfile.ScreenSelection) -> [NoticeScreen] {
        current(for: selection).map(NoticeScreen.init)
    }
}

/// Puts presenter panels on screen, gives them the keyboard, and takes them
/// away. A seam, so tests never show a window.
@MainActor
protocol NoticeWindowing: AnyObject {
    func present(_ panel: NoticePanel)
    /// Makes `panel` key, with `firstResponder` taking the keyboard in it.
    func makeKey(_ panel: NoticePanel, firstResponder: NSResponder?)
    func dismiss(_ panel: NoticePanel)
}

/// The real thing.
@MainActor
final class LiveNoticeWindowing: NoticeWindowing {

    func present(_ panel: NoticePanel) {
        panel.orderFrontRegardless()
    }

    func makeKey(_ panel: NoticePanel, firstResponder: NSResponder?) {
        panel.makeKeyAndOrderFront(nil)
        if let firstResponder {
            panel.makeFirstResponder(firstResponder)
        }
    }

    func dismiss(_ panel: NoticePanel) {
        panel.orderOut(nil)
        panel.close()
    }
}
