import AgenticDeveloperHubSDKCore
import AppKit

/// Runs one window app-modal: `start()` returns at once and the session
/// begins on the next pass of the run loop; `end()` stops it, from an event or
/// from none.
///
/// - The modal loop is entered from a run loop block, never a main-queue one
///   (`performOnNextRunLoopPass`), so the main queue keeps draining while the
///   window is up: a `Task` a button starts runs, an `await` resumes.
/// - `stopModal` takes effect when the loop next handles an event, so a stop
///   that came from none — an awaited save finishing — posts one.
/// - While the system's authentication prompt is up
///   (``SystemAuthenticationPrompt``) the session steps aside, since the
///   prompt would otherwise open behind the modal window with nothing able to
///   reach it, and starts again once the prompt is answered. A prompt already
///   up when the session starts holds it back the same way.
@MainActor
public final class AppModalWindowSession {

    private weak var window: NSWindow?
    private let activates: Bool
    private var isStarted = false
    private var isEnded = false
    /// Whether `NSApp.runModal(for:)` is running this session's window.
    public private(set) var isRunning = false
    private var promptObserver: NSObjectProtocol?

    /// The sessions started and not yet ended, innermost last.
    private static var live: [AppModalWindowSession] = []

    /// `activates` brings the app forward as the session starts: a dialog
    /// that must be answered before anything else.
    public init(window: NSWindow, activates: Bool = false) {
        self.window = window
        self.activates = activates
    }

    /// Starts the session on the next pass of the run loop. Once only.
    public func start() {
        guard !isStarted, !isEnded else { return }
        isStarted = true
        Self.live.append(self)
        promptObserver = NotificationCenter.default.addObserver(
            forName: SystemAuthenticationPrompt.didChangeNotification, object: nil, queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.promptDidChange() }
        }
        scheduleRun()
    }

    /// Ends the session for good; later calls do nothing.
    public func end() {
        guard !isEnded else { return }
        isEnded = true
        Self.live.removeAll { $0 === self }
        if let promptObserver { NotificationCenter.default.removeObserver(promptObserver) }
        promptObserver = nil
        stopRunning()
    }

    private func scheduleRun() {
        performOnNextRunLoopPass { [weak self] in self?.run() }
    }

    private func run() {
        guard !isEnded, !isRunning, !SystemAuthenticationPrompt.isShowing, let window else { return }
        isRunning = true
        if activates { NSApp.activate(ignoringOtherApps: true) }
        NSApp.runModal(for: window)
        isRunning = false
        // A prompt that came up while a session inside this one was running
        // could stop only that one; each stops the next as it unwinds.
        if SystemAuthenticationPrompt.isShowing { Self.stopTopmost() }
    }

    private func promptDidChange() {
        if SystemAuthenticationPrompt.isShowing {
            stopRunning()
        } else if !isEnded, !isRunning {
            scheduleRun()
        }
    }

    /// Stops the loop when it is the one running now: `stopModal` ends the
    /// innermost session, which must be this one.
    private func stopRunning() {
        guard isRunning, let window, NSApp.modalWindow === window else { return }
        NSApp.stopModal()
        if let wake = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
                                         timestamp: 0, windowNumber: 0, context: nil,
                                         subtype: 0, data1: 0, data2: 0) {
            NSApp.postEvent(wake, atStart: true)
        }
    }

    private static func stopTopmost() {
        live.first { $0.isRunning && NSApp.modalWindow === $0.window }?.stopRunning()
    }
}
