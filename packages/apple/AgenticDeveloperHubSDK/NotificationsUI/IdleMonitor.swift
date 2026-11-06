import CoreGraphics
import Foundation

/// Notices when the user comes back to the Mac.
///
/// It samples the seconds since the last keyboard or mouse event. Once that
/// reaches `threshold` the user is away; the first sample under it afterwards
/// is a return, and `onReturn` fires. Polling runs only between `start()` and
/// `stop()`, so a center with nothing snoozed "until I'm back" costs nothing.
@MainActor
public final class IdleMonitor {

    /// Called once per return from being away.
    public var onReturn: (@MainActor () -> Void)?

    private let idleSeconds: @MainActor () -> TimeInterval
    private let threshold: TimeInterval
    private let poll: TimeInterval
    private var wasAway = false
    private var timer: Timer?

    /// - Parameters:
    ///   - idleSeconds: seconds since the last input event. Defaults to the
    ///     session's combined keyboard and mouse idle time.
    ///   - threshold: seconds without input that count as away.
    ///   - poll: seconds between samples while started.
    public init(
        idleSeconds: @escaping @MainActor () -> TimeInterval = IdleMonitor.systemIdleSeconds,
        threshold: TimeInterval = 300,
        poll: TimeInterval = 15
    ) {
        self.idleSeconds = idleSeconds
        self.threshold = threshold
        self.poll = poll
    }

    isolated deinit {
        timer?.invalidate()
    }

    public var isRunning: Bool { timer != nil }

    public func start() {
        guard timer == nil else { return }
        wasAway = false
        let timer = Timer(timeInterval: poll, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Takes one sample. The timer calls this; tests call it directly.
    public func step() {
        let away = idleSeconds() >= threshold
        if wasAway && !away {
            wasAway = false
            onReturn?()
        } else {
            wasAway = away
        }
    }

    /// Seconds since the last keyboard or mouse event in this login session.
    nonisolated public static func systemIdleSeconds() -> TimeInterval {
        // `~0` is `kCGAnyInputEventType`: any kind of input event.
        guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
