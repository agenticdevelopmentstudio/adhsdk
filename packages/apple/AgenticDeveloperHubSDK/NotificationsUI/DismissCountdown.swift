import Foundation

/// A scheduled one-shot callback that can be called off.
@MainActor
protocol CountdownToken: AnyObject {
    func cancel()
}

/// Where a countdown gets its timers. The card uses `TimerCountdownScheduler`;
/// tests drive a manual one, so expiry is checked without waiting or windows.
@MainActor
protocol CountdownScheduler {
    func schedule(after interval: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> CountdownToken
}

/// `Timer` on the main run loop, in `.common` mode so it keeps running while a
/// menu is tracking.
struct TimerCountdownScheduler: CountdownScheduler {

    private final class TimerToken: CountdownToken {
        let timer: Timer
        init(_ timer: Timer) { self.timer = timer }
        func cancel() { timer.invalidate() }
    }

    func schedule(after interval: TimeInterval, _ fire: @escaping @MainActor () -> Void) -> CountdownToken {
        let timer = Timer(timeInterval: interval, repeats: false) { _ in
            MainActor.assumeIsolated { fire() }
        }
        RunLoop.main.add(timer, forMode: .common)
        return TimerToken(timer)
    }
}

/// A card's auto-dismiss: counts down while nothing pauses it, keeps the time
/// left across pauses, and expires exactly once.
///
/// Several things pause it independently — the pointer over the card, the
/// pointer over another placement of the same notice, the card being folded
/// behind the "+N more" pill — and it runs only when none does.
@MainActor
final class DismissCountdown {

    enum PauseReason: Hashable {
        /// The pointer is over this card.
        case hover
        /// The pointer is over the same notice on another screen.
        case peerHover
        /// The card is in a stack's overflow, so nobody can see it.
        case hidden
    }

    private let scheduler: CountdownScheduler
    private let clock: () -> Date
    private var pauses: Set<PauseReason> = []
    /// Seconds left; `nil` when there is no countdown.
    private var remaining: TimeInterval?
    private var deadline: Date?
    private var token: CountdownToken?
    private var onExpire: (@MainActor () -> Void)?

    init(scheduler: CountdownScheduler = TimerCountdownScheduler(), clock: @escaping () -> Date = Date.init) {
        self.scheduler = scheduler
        self.clock = clock
    }

    /// Whether a timer is armed right now (not paused, not stopped, not done).
    var isRunning: Bool { token != nil }

    /// Starts over with `seconds` (none when `nil`), replacing any countdown
    /// already running. Pauses in force stay in force.
    func start(after seconds: TimeInterval?, _ onExpire: @escaping @MainActor () -> Void) {
        stop()
        guard let seconds else { return }
        remaining = seconds
        self.onExpire = onExpire
        resumeIfFree()
    }

    /// Cancels the countdown for good; a later resume does not bring it back.
    func stop() {
        token?.cancel()
        token = nil
        deadline = nil
        remaining = nil
        onExpire = nil
    }

    func setPaused(_ paused: Bool, for reason: PauseReason) {
        if paused {
            pauses.insert(reason)
            suspend()
        } else {
            pauses.remove(reason)
            resumeIfFree()
        }
    }

    private func suspend() {
        guard let token, let deadline else { return }
        token.cancel()
        self.token = nil
        self.deadline = nil
        // At least a second back, so leaving a card just before it expires
        // does not snap it shut under the pointer.
        remaining = max(1, deadline.timeIntervalSince(clock()))
    }

    private func resumeIfFree() {
        guard pauses.isEmpty, token == nil, let remaining else { return }
        deadline = clock().addingTimeInterval(remaining)
        token = scheduler.schedule(after: remaining) { [weak self] in self?.expire() }
    }

    private func expire() {
        let action = onExpire
        token = nil
        deadline = nil
        remaining = nil
        onExpire = nil
        action?()
    }
}
