import AppKit
import UserNotifications
import AgenticDeveloperHubSDKNotifications

/// Where system notifications go. A seam, so tests never post to the real
/// Notification Center.
@MainActor
protocol SystemNotificationPosting: AnyObject {
    /// Becomes the Notification Center's delegate and registers the
    /// presenter's category.
    func becomeDelegate()
    func requestAuthorization()
    func post(_ request: UNNotificationRequest)
    func removeDelivered(withIdentifiers identifiers: [String])
    func removePending(withIdentifiers identifiers: [String])
}

/// The `system` style item of a set: the notice goes to macOS's own
/// Notification Center as a banner, under the notice's id, so it can be
/// withdrawn when the notice is acted on anywhere else. Clicking the banner
/// acts on the notice, like clicking its card; clearing it closes the notice.
///
/// Call `start()` at launch, so a banner clicked after a relaunch (or the one
/// that launched the app) still reaches the presenter.
@MainActor
public final class SystemNotificationPresenter: NSObject, NoticePresenter, UNUserNotificationCenterDelegate {

    public private(set) var shownIDs: [String] = []

    private var injectedPoster: SystemNotificationPosting?
    private let playsSound: @MainActor () -> Bool
    private var actions: [String: NoticeCardActions] = [:]
    private var authorized = false
    private var started = false

    /// The category every banner is posted under. It asks for the dismiss
    /// callback, so a banner the user clears comes back as a close.
    static let categoryIdentifier = "com.agentic-cookbook.notice"

    /// Posts through `UNUserNotificationCenter.current()`, which is touched
    /// only once the first notice is shown.
    /// - Parameter playsSound: read per notice; `false` posts silently.
    public convenience init(playsSound: @escaping @MainActor () -> Bool = { true }) {
        self.init(poster: nil, playsSound: playsSound)
    }

    init(poster: SystemNotificationPosting?, playsSound: @escaping @MainActor () -> Bool) {
        self.injectedPoster = poster
        self.playsSound = playsSound
        super.init()
    }

    private var poster: SystemNotificationPosting {
        if let injectedPoster { return injectedPoster }
        let made = UserNotificationCenterPoster(delegate: self)
        injectedPoster = made
        return made
    }

    /// Makes this presenter the `UNUserNotificationCenter` delegate. Call it
    /// once at launch, before the app finishes launching, so banner clicks
    /// and clears after a relaunch arrive here. It replaces any delegate the
    /// host set: a host that needs its own must forward to this presenter.
    /// Idempotent; `show` calls it too.
    public func start() {
        guard !started else { return }
        started = true
        poster.becomeDelegate()
    }

    // MARK: NoticePresenter

    /// One banner per notice, however many system items the set holds.
    public func show(_ notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        guard !profiles.isEmpty else { return }
        start()
        if !authorized {
            authorized = true
            poster.requestAuthorization()
        }
        shownIDs.removeAll { $0 == notice.id }
        shownIDs.append(notice.id)
        self.actions[notice.id] = actions
        poster.post(UNNotificationRequest(identifier: notice.id, content: content(for: notice), trigger: nil))
    }

    public func remove(id: String) {
        guard actions.removeValue(forKey: id) != nil else { return }
        shownIDs.removeAll { $0 == id }
        poster.removePending(withIdentifiers: [id])
        poster.removeDelivered(withIdentifiers: [id])
    }

    public func replace(oldID: String, with notice: Notice, profiles: [NoticeProfile], actions: NoticeCardActions) {
        remove(id: oldID)
        show(notice, profiles: profiles, actions: actions)
    }

    // MARK: Taps

    /// A banner was clicked. One this presenter no longer tracks (the notice
    /// was acted on elsewhere since) does nothing.
    func handleTap(identifier: String) {
        actions[identifier]?.act()
    }

    /// The user cleared a banner: the notice closes, which takes it out of
    /// the center's newest-shown order so a hotkey does not act on it.
    func handleDismiss(identifier: String) {
        actions[identifier]?.close()
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Shown even while the host app is frontmost.
        [.banner, .sound, .list]
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            await MainActor.run { self.handleTap(identifier: identifier) }
        case UNNotificationDismissActionIdentifier:
            await MainActor.run { self.handleDismiss(identifier: identifier) }
        default:
            break
        }
    }

    // MARK: Content

    private func content(for notice: Notice) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = notice.title
        content.subtitle = notice.subtitle
            ?? [notice.source, notice.category].compactMap { $0 }.joined(separator: " · ")
        content.body = notice.body ?? ""
        content.sound = playsSound() ? .default : nil
        content.threadIdentifier = notice.source
        content.categoryIdentifier = Self.categoryIdentifier
        return content
    }
}

/// The real Notification Center.
@MainActor
private final class UserNotificationCenterPoster: SystemNotificationPosting {

    private weak var delegate: UNUserNotificationCenterDelegate?

    init(delegate: UNUserNotificationCenterDelegate) {
        self.delegate = delegate
    }

    func becomeDelegate() {
        let center = UNUserNotificationCenter.current()
        center.delegate = delegate
        center.setNotificationCategories([UNNotificationCategory(
            identifier: SystemNotificationPresenter.categoryIdentifier, actions: [], intentIdentifiers: [],
            options: [.customDismissAction])])
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func removeDelivered(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removePending(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
