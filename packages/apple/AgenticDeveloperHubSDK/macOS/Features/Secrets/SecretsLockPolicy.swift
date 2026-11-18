import AppKit
import AgenticDeveloperHubSDKCore

/// Decides when an unlocked Secrets window locks itself, from the user's
/// settings (``UserSettings/secretsLockWhenAppInactive``,
/// ``UserSettings/secretsLockOnSleep``,
/// ``UserSettings/secretsLockAfterIdleMinutes``), and calls `lock` when it
/// should. Each setting is read when its event arrives, so a change in
/// Settings applies to the window already open.
///
/// - **The app goes to the background**: `NSApplication.didResignActive`.
/// - **The Mac sleeps or locks**: the system and its displays going to sleep,
///   the user session switching away, and the screen locking.
/// - **Inactivity**: no key press, click or scroll in any of the app's
///   windows for the set number of minutes. The app's own events are the
///   only ones it can see, which is the point: inactivity *in the app*.
///
/// Runs only between ``start()`` and ``stop()``: the window starts it when it
/// unlocks and stops it when it locks or closes.
@MainActor
final class SecretsLockPolicy {

    private let settings: UserSettings
    private let lock: @MainActor () -> Void
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var eventMonitor: Any?
    private var idleTimer: Timer?
    private(set) var lastActivity = Date()

    init(settings: UserSettings = .shared, lock: @escaping @MainActor () -> Void) {
        self.settings = settings
        self.lock = lock
    }

    var isRunning: Bool { idleTimer != nil }

    func start() {
        guard !isRunning else { return }
        lastActivity = Date()
        observe(NotificationCenter.default, NSApplication.didResignActiveNotification) { policy in
            policy.lockIf(UserSettings.secretsLockWhenAppInactive)
        }
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            observe(workspace, name) { policy in policy.lockIf(UserSettings.secretsLockOnSleep) }
        }
        // The screen locking is announced only as this distributed
        // notification; it carries no information, only the moment.
        observe(DistributedNotificationCenter.default(), Notification.Name("com.apple.screenIsLocked")) { policy in
            policy.lockIf(UserSettings.secretsLockOnSleep)
        }
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]
        ) { [weak self] event in
            self?.lastActivity = Date()
            return event
        }
        idleTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkIdle(now: Date()) }
        }
    }

    func stop() {
        for (center, token) in observers { center.removeObserver(token) }
        observers.removeAll()
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        idleTimer?.invalidate()
        idleTimer = nil
    }

    /// Locks when the idle limit has passed since the last activity.
    func checkIdle(now: Date) {
        let minutes = settings.get(UserSettings.secretsLockAfterIdleMinutes)
        if Self.isIdle(since: lastActivity, now: now, minutes: minutes) { lock() }
    }

    /// Whether `minutes` (0 is never) have passed between `lastActivity` and `now`.
    nonisolated static func isIdle(since lastActivity: Date, now: Date, minutes: Int) -> Bool {
        minutes > 0 && now.timeIntervalSince(lastActivity) >= TimeInterval(minutes * 60)
    }

    private func lockIf(_ setting: UserSetting<Bool>) {
        if settings.get(setting) { lock() }
    }

    private func observe(
        _ center: NotificationCenter, _ name: Notification.Name,
        _ handler: @escaping @MainActor (SecretsLockPolicy) -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        observers.append((center, token))
    }
}
