import Foundation
import AgenticDeveloperHubSDKNotifications

/// One way of putting a notice on screen: toast, alert, full screen, crawl,
/// system. The presentation center decides which presenters a notice goes to
/// and when it leaves; a presenter only draws and removes.
///
/// A notice's style set may hold several items of one style. The center calls
/// that style's presenter once, with all of them in `profiles` (never empty),
/// each already carrying the set's `autoDismiss`.
@MainActor
public protocol NoticePresenter: AnyObject {
    /// The ids on screen, oldest first.
    var shownIDs: [String] { get }
    func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions)
    func remove(id: String)
    /// Swap `oldID`'s presentation for `notice` where it stands, rather than
    /// removing it and adding a new one at the end (replace-by-key, and a
    /// flood summary whose count grows).
    func replace(oldID: String, with notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions)
    /// Put the cursor in the notice's reply field. `false` when this
    /// presenter draws none for it (crawl, system), so the caller can offer
    /// another way to answer.
    @discardableResult
    func focusReply(id: String) -> Bool
    /// The routing rules changed: restyle or move what is already on screen
    /// where the presenter reads them live (the crawl does).
    func rulesDidChange()
}

public extension NoticePresenter {
    @discardableResult
    func focusReply(id: String) -> Bool { false }

    func rulesDidChange() {}

    /// One item: the common case, and what previews and tests reach for.
    func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        show(notice, profiles: [profile], actions: actions)
    }

    func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        replace(oldID: oldID, with: notice, profiles: [profile], actions: actions)
    }
}

/// What a card's controls do. Built by the presentation center per notice, so
/// a presenter never decides what a click means.
public struct NoticeCardActions {
    /// The card itself was clicked: run the primary action.
    public var act: @MainActor () -> Void
    /// A specific action button (its id), with reply text for a reply action.
    public var respond: @MainActor (String, String?) -> Void
    /// `nil` hides the snooze control: a flood summary has nothing to snooze,
    /// and a style set can turn snoozing off.
    public var snooze: (@MainActor (SnoozeOption) -> Void)?
    /// The times the snooze control offers, in `SnoozeOption.allCases` order.
    public var snoozeOptions: [SnoozeOption]
    /// `nil` hides the archive control.
    public var archive: (@MainActor () -> Void)?
    /// The close button, or the auto-dismiss timer running out.
    public var close: @MainActor () -> Void

    public init(
        act: @escaping @MainActor () -> Void,
        respond: @escaping @MainActor (String, String?) -> Void,
        snooze: (@MainActor (SnoozeOption) -> Void)?,
        snoozeOptions: [SnoozeOption] = SnoozeOption.allCases,
        archive: (@MainActor () -> Void)?,
        close: @escaping @MainActor () -> Void
    ) {
        self.act = act
        self.respond = respond
        self.snooze = snooze
        self.snoozeOptions = snoozeOptions
        self.archive = archive
        self.close = close
    }

    /// Controls that do nothing. For previews and tests.
    public static var inert: NoticeCardActions {
        NoticeCardActions(act: {}, respond: { _, _ in }, snooze: { _ in }, archive: {}, close: {})
    }
}
