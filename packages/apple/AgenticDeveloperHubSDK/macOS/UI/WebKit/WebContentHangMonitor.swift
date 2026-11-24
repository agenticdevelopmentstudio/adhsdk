//
//  WebContentHangMonitor.swift
//  AgenticDeveloperHubSDK
//

import OSLog
import WebKit
import AgenticDeveloperHubSDKCore

/// Ends a web view's content process when its page stops answering, so the
/// web view's own crash recovery can bring the page back.
///
/// WebKit reports a content process that *crashes*
/// (`webViewWebContentProcessDidTerminate(_:)`) but not one that *hangs*: a page
/// whose script never returns — an infinite loop in a `requestAnimationFrame`
/// callback, say — keeps its process at full CPU, the view frozen, for as long
/// as the app runs. This turns that hang into a termination, which every web
/// view host already knows how to recover from.
///
/// While running, it sends the page a trivial script every `Timing.interval`.
/// A page whose main thread is free answers at once, so a ping still
/// unanswered after `Timing.timeout` means the main thread is stuck: the
/// monitor ends the process, and WebKit then calls the navigation delegate's
/// `webViewWebContentProcessDidTerminate(_:)`, where the host reloads.
/// Time asleep does not count toward the timeout (`SuspendingClock`), so a
/// Mac waking from sleep never reads as a hung page.
///
/// A page paused in Web Inspector's debugger does not answer either, and is
/// ended the same way, so an inspectable web view should not be monitored
/// while someone is debugging it.
@MainActor
public final class WebContentHangMonitor {

    /// How often the page is pinged, and how long an answer may take.
    public struct Timing: Sendable, Equatable {
        public var interval: Duration
        public var timeout: Duration

        public init(interval: Duration, timeout: Duration) {
            self.interval = interval
            self.timeout = timeout
        }

        /// Generous enough that a page blocking its main thread for a few
        /// seconds of legitimate work is never ended; a page frozen for good
        /// is ended within about half a minute.
        public static let standard = Timing(interval: .seconds(5), timeout: .seconds(20))
    }

    public let timing: Timing
    private weak var webView: WKWebView?
    private var loop: Task<Void, Never>?

    /// When the unanswered ping was sent, or nil when none is outstanding.
    private var outstandingSince: SuspendingClock.Instant?
    /// Tells a late answer to a ping sent before a restart or a termination
    /// from the answer to the current one.
    private var pingGeneration = 0

    public init(webView: WKWebView, timing: Timing = .standard) {
        self.webView = webView
        self.timing = timing
    }

    public var isRunning: Bool { loop != nil }

    /// Starts watching. Calling it while already running does nothing. The
    /// loop holds the monitor weakly and ends once the monitor is gone, so
    /// releasing the monitor stops it too.
    public func start() {
        guard loop == nil else { return }
        loop = Task { [weak self, timing] in
            while !Task.isCancelled {
                // Optional chaining holds the monitor only for the call, never
                // across the sleep, where it would keep a released monitor alive.
                guard self?.tick() != nil else { return }
                try? await Task.sleep(for: timing.interval, clock: .suspending)
            }
        }
    }

    /// Stops watching; an answer to a ping already sent is ignored.
    public func stop() {
        loop?.cancel()
        loop = nil
        forgetOutstandingPing()
    }

    private func tick() {
        guard let webView else {
            stop()
            return
        }
        if let since = outstandingSince {
            guard SuspendingClock.now - since >= timing.timeout else { return }
            endHungProcess(of: webView)
        } else {
            ping(webView)
        }
    }

    private func ping(_ webView: WKWebView) {
        pingGeneration += 1
        let generation = pingGeneration
        outstandingSince = .now
        // Any completion — a value or an error — means the process's main
        // thread handled the message, which is all this asks.
        webView.evaluateJavaScript("0", in: nil, in: .defaultClient) { [weak self] _ in
            guard let self, generation == self.pingGeneration else { return }
            self.outstandingSince = nil
        }
    }

    private func endHungProcess(of webView: WKWebView) {
        forgetOutstandingPing()
        let host = webView.url?.host() ?? "(no page)"
        guard webView.terminateWebContentProcess() else {
            Self.logger.fault(
                "Page on \(host, privacy: .public) is unresponsive, and this WebKit offers no way to end its process"
            )
            stop()
            return
        }
        let timeout = timing.timeout
        Self.logger.error(
            "Page on \(host, privacy: .public) did not answer for \(timeout, privacy: .public); ended its process"
        )
    }

    private func forgetOutstandingPing() {
        outstandingSince = nil
        pingGeneration += 1
    }
}

extension WebContentHangMonitor: Loggable {
    public static nonisolated let logger = makeLogger()
}

extension WKWebView {

    /// Ends this web view's content process, as a crash would. WebKit then
    /// calls the navigation delegate's `webViewWebContentProcessDidTerminate(_:)`,
    /// and the next load starts a fresh process.
    ///
    /// SPI: `_killWebContentProcess` is not API — it is what Safari uses on a
    /// hung tab — so it is asked for by name. Returns false, having done
    /// nothing, where this WebKit has no such selector.
    @discardableResult
    public func terminateWebContentProcess() -> Bool {
        let selector = NSSelectorFromString("_killWebContentProcess")
        guard responds(to: selector) else { return false }
        perform(selector)
        return true
    }
}
