import AppKit
import UserNotifications
import AgenticDeveloperHubSDKNotifications

/// Where system notifications go. A seam, so tests never post to the real
/// Notification Center.
@MainActor
protocol SystemNotificationPosting: AnyObject {
    func requestAuthorization()
    func post(_ request: UNNotificationRequest)
    func removeDelivered(withIdentifiers identifiers: [String])
}

/// The `system` style, and `forwardToSystem`: the notice goes to macOS's own
/// Notification Center as a banner, under the notice's id, so it can be
/// withdrawn when the notice is acted on anywhere else. Clicking the banner
/// acts on the notice, like clicking its card.
@MainActor
public final class SystemNotificationPresenter: NSObject, NoticePresenter, UNUserNotificationCenterDelegate {

    public private(set) var shownIDs: [String] = []

    private var injectedPoster: SystemNotificationPosting?
    private let playsSound: @MainActor () -> Bool
    private var actions: [String: NoticeCardActions] = [:]
    private var authorized = false

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

    // MARK: NoticePresenter

    public func show(_ notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
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
        poster.removeDelivered(withIdentifiers: [id])
    }

    public func replace(oldID: String, with notice: Notice, profile: NoticeProfile, actions: NoticeCardActions) {
        remove(id: oldID)
        show(notice, profile: profile, actions: actions)
    }

    // MARK: Taps

    /// A banner was clicked. One this presenter no longer tracks (the notice
    /// was acted on elsewhere since) does nothing.
    func handleTap(identifier: String) {
        actions[identifier]?.act()
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
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let identifier = response.notification.request.identifier
        await MainActor.run { self.handleTap(identifier: identifier) }
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
        return content
    }
}

/// The real Notification Center. Becomes its delegate when authorization is
/// first asked for, so banner clicks come back to the presenter.
@MainActor
private final class UserNotificationCenterPoster: SystemNotificationPosting {

    private weak var delegate: UNUserNotificationCenterDelegate?

    init(delegate: UNUserNotificationCenterDelegate) {
        self.delegate = delegate
    }

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = delegate
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func removeDelivered(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
