import AppKit
import OSLog
import UserNotifications
import AgenticDeveloperHubSDKNotifications

/// Where system notifications go. A seam, so tests never post to the real
/// Notification Center.
@MainActor
protocol SystemNotificationPosting: AnyObject {
    /// Becomes the Notification Center's delegate and registers the
    /// presenter's category.
    func becomeDelegate()
    /// Whether the user has already turned Rooster's notifications off
    /// (`getNotificationSettings` reports `.denied`).
    func isAuthorizationDenied(_ completion: @escaping @MainActor (Bool) -> Void)
    /// Asks for `[.alert, .sound]`; answers once, with the grant or the error.
    func requestAuthorization(_ completion: @escaping @MainActor (Bool, Error?) -> Void)
    /// Adds the request; answers with the error `add` reported, if any.
    func post(_ request: UNNotificationRequest, completion: @escaping @MainActor (Error?) -> Void)
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
    private enum Authorization { case unknown, pending, granted, denied }
    private var authorization = Authorization.unknown
    /// Requests that arrived before the authorization answer.
    private var queue: [UNNotificationRequest] = []
    private var deniedReported = false
    private var started = false
    private let logger = Logger(
        subsystem: "com.agentic-cookbook.AgenticDeveloperHubSDK", category: "SystemNotificationPresenter")

    /// Called once per launch when Notification Center is off for the host
    /// app, so the host can say so.
    public var onAuthorizationDenied: (@MainActor () -> Void)?

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
        if authorization == .denied { return }
        shownIDs.removeAll { $0 == notice.id }
        shownIDs.append(notice.id)
        self.actions[notice.id] = actions
        let request = UNNotificationRequest(identifier: notice.id, content: content(for: notice), trigger: nil)
        switch authorization {
        case .granted:
            add(request)
        case .pending:
            enqueue(request)
        case .unknown:
            enqueue(request)
            authorization = .pending
            resolveAuthorization()
        case .denied:
            break
        }
    }

    private func enqueue(_ request: UNNotificationRequest) {
        queue.removeAll { $0.identifier == request.identifier }
        queue.append(request)
    }

    /// One question, asked once: already denied, or ask and wait for the answer.
    private func resolveAuthorization() {
        poster.isAuthorizationDenied { [weak self] denied in
            guard let self else { return }
            if denied {
                logger.error("Notification Center authorization is denied")
                deny()
                return
            }
            poster.requestAuthorization { [weak self] granted, error in
                guard let self else { return }
                if let error {
                    // Not an answer: drop what is queued, but stay undecided so
                    // the next show asks again, and say nothing about "off".
                    logger.error("Authorization request failed: \(error.localizedDescription, privacy: .public)")
                    abandon()
                    return
                }
                logger.info("Authorization \(granted ? "granted" : "denied", privacy: .public)")
                if granted { grant() } else { deny() }
            }
        }
    }

    private func grant() {
        authorization = .granted
        let pending = queue
        queue = []
        pending.forEach(add)
    }

    /// Drops everything queued or tracked.
    private func dropQueued() {
        queue = []
        shownIDs = []
        actions = [:]
    }

    /// The authorization request itself failed: forget the queue, ask again on
    /// the next show.
    private func abandon() {
        authorization = .unknown
        dropQueued()
    }

    /// Drops what is queued and tells the host, the first time only.
    private func deny() {
        authorization = .denied
        dropQueued()
        guard !deniedReported else { return }
        deniedReported = true
        onAuthorizationDenied?()
    }

    private func add(_ request: UNNotificationRequest) {
        let id = request.identifier
        poster.post(request) { [logger] error in
            if let error {
                logger.error(
                    "Posting \(id, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public func remove(id: String) {
        guard actions.removeValue(forKey: id) != nil else { return }
        queue.removeAll { $0.identifier == id }
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

    func isAuthorizationDenied(_ completion: @escaping @MainActor (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let denied = settings.authorizationStatus == .denied
            Task { @MainActor in completion(denied) }
        }
    }

    func requestAuthorization(_ completion: @escaping @MainActor (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in completion(granted, error) }
        }
    }

    func post(_ request: UNNotificationRequest, completion: @escaping @MainActor (Error?) -> Void) {
        UNUserNotificationCenter.current().add(request) { error in
            Task { @MainActor in completion(error) }
        }
    }

    func removeDelivered(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removePending(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
