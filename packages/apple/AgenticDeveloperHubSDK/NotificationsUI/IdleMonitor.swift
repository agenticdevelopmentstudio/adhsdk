import AppKit
import CoreGraphics
import Foundation

/// Notices when the user comes back to the Mac.
///
/// It samples the seconds since the last keyboard or mouse event. Once that
/// reaches `threshold` the user is away; the first sample under it afterwards
/// is a return, and `onReturn` fires. Sleep, screen sleep and a session switch
/// also mark the user away; the first input after one is a return. Polling and
/// observing run only between `start()` and `stop()`, so a center with nothing
/// snoozed "until I'm back" costs nothing.
@MainActor
public final class IdleMonitor {

    /// Called once per return from being away.
    public var onReturn: (@MainActor () -> Void)?

    private let idleSeconds: @MainActor () -> TimeInterval
    private let threshold: TimeInterval
    private let poll: TimeInterval
    private let notifications: NotificationCenter
    private let now: @MainActor () -> Date
    private var wasAway = false
    private var timer: Timer?

    /// - Parameters:
    ///   - idleSeconds: seconds since the last input event. Defaults to the
    ///     session's combined keyboard and mouse idle time.
    ///   - threshold: seconds without input that count as away.
    ///   - poll: seconds between samples while started.
    ///   - notifications: where sleep, wake and session changes are posted.
    ///     Defaults to `NSWorkspace`'s center; tests pass their own.
    ///   - now: the clock.
    public init(
        idleSeconds: @escaping @MainActor () -> TimeInterval = IdleMonitor.systemIdleSeconds,
        threshold: TimeInterval = 300,
        poll: TimeInterval = 15,
        notifications: NotificationCenter = NSWorkspace.shared.notificationCenter,
        now: @escaping @MainActor () -> Date = Date.init
    ) {
        self.idleSeconds = idleSeconds
        self.threshold = threshold
        self.poll = poll
        self.notifications = notifications
        self.now = now
    }

    isolated deinit {
        timer?.invalidate()
        removeObservers()
    }

    public var isRunning: Bool { timer != nil }

    public func start() {
        guard timer == nil else { return }
        wasAway = false
        awaySince = nil
        let timer = Timer(timeInterval: poll, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        addObservers()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        removeObservers()
    }

    /// Takes one sample. The timer calls this; tests call it directly.
    public func step() {
        let idle = idleSeconds()
        if let since = awaySince {
            // Marked away by sleep, a screen lock or a session switch: back
            // once there has been input since then. A sample that reads less
            // idle than the threshold is not enough, since the mark can come
            // well before 300 s of idle.
            guard idle < now().timeIntervalSince(since) else { return }
            awaySince = nil
            wasAway = false
            onReturn?()
            return
        }
        let away = idle >= threshold
        if wasAway && !away {
            wasAway = false
            onReturn?()
        } else {
            wasAway = away
        }
    }

    // MARK: Sleep, screen sleep and session switches

    /// When the Mac sleeps, its screens sleep (or lock) or the user switches
    /// to another session, the user is away whatever the idle clock says: the
    /// timer does not run during sleep, and the input that wakes or unlocks the
    /// Mac resets the idle clock before any sample can see 300 s of it.
    private var awaySince: Date?
    private var observers: [NSObjectProtocol] = []

    private static let awayNotifications: [Notification.Name] = [
        NSWorkspace.willSleepNotification,
        NSWorkspace.screensDidSleepNotification,
        NSWorkspace.sessionDidResignActiveNotification
    ]

    private static let backNotifications: [Notification.Name] = [
        NSWorkspace.didWakeNotification,
        NSWorkspace.screensDidWakeNotification,
        NSWorkspace.sessionDidBecomeActiveNotification
    ]

    private func addObservers() {
        guard observers.isEmpty else { return }
        for name in Self.awayNotifications {
            observers.append(notifications.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.markAway() }
            })
        }
        for name in Self.backNotifications {
            // A wake or switch back takes a sample at once rather than waiting
            // for the next tick; it is a return only if there has been input.
            observers.append(notifications.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.step() }
            })
        }
    }

    private func removeObservers() {
        for observer in observers {
            notifications.removeObserver(observer)
        }
        observers.removeAll()
    }

    private func markAway() {
        guard isRunning, awaySince == nil else { return }
        awaySince = now()
    }

    /// Seconds since the last keyboard or mouse event in this login session.
    nonisolated public static func systemIdleSeconds() -> TimeInterval {
        // `~0` is `kCGAnyInputEventType`: any kind of input event.
        guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
