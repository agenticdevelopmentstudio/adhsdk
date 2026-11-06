import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

// Test doubles shared by the NotificationsUI tests.

@MainActor
final class RecordingHandler: NoticeActionHandler {

    enum Call: Equatable {
        case setState(String, Notice.Lifecycle)
        case snooze(String, Date)
        case respond(String, String, String?)
        case openURL(URL)
        case showHistory
        case sendTest(String)
    }

    var calls: [Call] = []

    func setState(_ id: String, _ state: Notice.Lifecycle) { calls.append(.setState(id, state)) }
    func snooze(_ id: String, until: Date) { calls.append(.snooze(id, until)) }
    func respond(_ id: String, actionID: String, text: String?) { calls.append(.respond(id, actionID, text)) }
    func openURL(_ url: URL) { calls.append(.openURL(url)) }
    func showHistory() { calls.append(.showHistory) }
    func sendTest(_ notice: Notice) { calls.append(.sendTest(notice.id)) }
}

@MainActor
final class RecordingPresenter: NoticePresenter {

    private(set) var shownIDs: [String] = []
    private(set) var shown: [Notice] = []
    private(set) var removed: [String] = []
    private(set) var replaced: [(old: String, new: String)] = []
    private(set) var focusedReplies: [String] = []
    private(set) var actions: [String: NoticeCardActions] = [:]
    private(set) var notices: [String: Notice] = [:]
    /// Whether this presenter draws a reply field (crawl and system do not).
    var hasReplyField = true

    func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        shown.append(notice)
        shownIDs.append(notice.id)
        self.actions[notice.id] = actions
        notices[notice.id] = notice
    }

    func remove(id: String) {
        removed.append(id)
        shownIDs.removeAll { $0 == id }
    }

    func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        replaced.append((oldID, notice.id))
        if let index = shownIDs.firstIndex(of: oldID) {
            shownIDs[index] = notice.id
        } else {
            shownIDs.append(notice.id)
        }
        self.actions[notice.id] = actions
        notices[notice.id] = notice
    }

    func focusReply(id: String) -> Bool {
        focusedReplies.append(id)
        return hasReplyField
    }
}

/// Records what a presenter does with its panels and never puts one on
/// screen.
@MainActor
final class RecordingWindowing: NoticeWindowing {
    private(set) var presented: [NoticePanel] = []
    private(set) var keyed: [NoticePanel] = []
    private(set) var dismissed: [NoticePanel] = []

    func present(_ panel: NoticePanel) { presented.append(panel) }
    func makeKey(_ panel: NoticePanel, firstResponder: NSResponder?) {
        keyed.append(panel)
        if let firstResponder { panel.makeFirstResponder(firstResponder) }
    }
    func dismiss(_ panel: NoticePanel) { dismissed.append(panel) }
}

/// A screen for presenter tests, so none reads `NSScreen`.
func testScreen(_ displayID: UInt32, width: CGFloat = 1512, originX: CGFloat = 0) -> NoticeScreen {
    let frame = CGRect(x: originX, y: 0, width: width, height: 982)
    return NoticeScreen(displayID: displayID, frame: frame, visibleFrame: frame.insetBy(dx: 0, dy: 30))
}

final class Clock {
    var now = Date(timeIntervalSince1970: 1_800_000_000)
}

/// Scripted readings for an `IdleMonitor`, consumed one per `step()`.
@MainActor
final class IdleReadings {
    private var values: [TimeInterval]
    init(_ values: [TimeInterval]) { self.values = values }
    func next() -> TimeInterval { values.isEmpty ? 0 : values.removeFirst() }
}
