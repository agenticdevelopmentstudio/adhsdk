//
//  WebContentHangMonitor.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import OSLog
import WebKit
import AgenticDeveloperHubSDKCore

/// Ends a web view's content process when its page stops answering, so the
/// host's crash recovery can bring the page back.
///
/// WebKit reports a content process that *crashes*
/// (`webViewWebContentProcessDidTerminate(_:)`) but not one that *hangs*: a page
/// whose script never returns — an infinite loop in a `requestAnimationFrame`
/// callback, say — keeps its process at full CPU, the view frozen, for as long
/// as the app runs. This turns that hang into a termination.
///
/// **The host must recover from the termination.** WebKit calls the
/// navigation delegate's `webViewWebContentProcessDidTerminate(_:)`: a host
/// that reloads there gets its page back in a fresh process, and one that does
/// nothing is left with a blank view. Every web view sharing the process — a
/// pop-up made from the configuration WebKit hands to
/// `webView(_:createWebViewWith:for:windowFeatures:)` — is ended with it, and
/// needs the same recovery.
///
/// While running, it sends the page a trivial script every `Timing.interval`.
/// A page whose main thread is free answers at once, so a ping still
/// unanswered after `Timing.timeout` means the main thread is stuck. The count
/// covers only time in which a stuck page is the one explanation:
/// - time asleep does not count (`SuspendingClock`), so a Mac waking from
///   sleep never reads as a hung page;
/// - a stall of the app's own main thread restarts it, since the page's
///   answer may be queued behind the stall;
/// - a navigation restarts it, since a ping sent to the page being left may
///   never be answered;
/// - while the app shows a modal window, or the web view's window a sheet —
///   where a page's `alert()`, `confirm()` or `prompt()` is shown while its
///   process waits on the answer — nothing is ended;
/// - an inspectable web view (`isInspectable`) is never ended, since a page
///   paused at a Web Inspector breakpoint does not answer either.
@MainActor
public final class WebContentHangMonitor {

    /// How often the page is pinged, and how long an answer may take.
    public struct Timing: Sendable, Equatable {
        public let interval: Duration
        public let timeout: Duration

        /// `interval` must be positive, and `timeout` at least one `interval`,
        /// since the deadline is checked once per interval.
        public init(interval: Duration, timeout: Duration) {
            precondition(interval > .zero, "the ping interval must be positive")
            precondition(timeout >= interval, "the timeout must be at least one ping interval")
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
    private var navigationObservation: NSKeyValueObservation?

    /// When the unanswered ping was sent, or nil when none is outstanding.
    private var outstandingSince: SuspendingClock.Instant?
    /// Tells a late answer to a ping sent before a restart, a navigation or a
    /// termination from the answer to the current one.
    private var pingGeneration = 0
    /// When the loop last ran, to tell a stall of the app's own main thread.
    private var lastTick: SuspendingClock.Instant?
    /// Set once this WebKit has shown it cannot end a process; from then on
    /// watching is pointless, and `start()` does nothing.
    private var cannotEndProcesses = false

    public init(webView: WKWebView, timing: Timing = .standard) {
        self.webView = webView
        self.timing = timing
    }

    public var isRunning: Bool { loop != nil }

    /// Starts watching. Calling it while already running does nothing. The
    /// loop holds the monitor weakly and ends once the monitor is gone, so
    /// releasing the monitor stops it too.
    public func start() {
        guard loop == nil, !cannotEndProcesses, let webView else { return }
        navigationObservation = webView.observe(\.url) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.forgetOutstandingPing() }
        }
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
        navigationObservation?.invalidate()
        navigationObservation = nil
        lastTick = nil
        forgetOutstandingPing()
    }

    private func tick() {
        guard let webView else {
            stop()
            return
        }
        let now = SuspendingClock.now
        defer { lastTick = now }
        guard let since = outstandingSince else {
            ping(webView)
            return
        }
        if let lastTick, now - lastTick > timing.interval * 2 {
            // The app's own main thread was stuck, and the answer may be
            // queued behind it: measure again from here.
            outstandingSince = now
            return
        }
        guard now - since >= timing.timeout else { return }
        if webView.isInspectable || Self.isShowingModalUI(for: webView) {
            outstandingSince = now
            return
        }
        endHungProcess(of: webView)
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

    private static func isShowingModalUI(for webView: WKWebView) -> Bool {
        NSApp?.modalWindow != nil || webView.window?.attachedSheet != nil
    }

    private func endHungProcess(of webView: WKWebView) {
        forgetOutstandingPing()
        let page = Self.describe(webView.url)
        guard webView.terminateWebContentProcess() else {
            Self.logger.fault(
                "\(page, privacy: .public) is unresponsive, and this WebKit offers no way to end its process"
            )
            cannotEndProcesses = true
            stop()
            return
        }
        let timeout = timing.timeout
        Self.logger.error(
            "\(page, privacy: .public) did not answer for \(timeout, privacy: .public); ended its process"
        )
    }

    /// Names a page for the log: its host, or — for a URL with none (`file:`,
    /// `about:`, `data:`) — the start of the URL itself.
    static func describe(_ url: URL?) -> String {
        guard let url else { return "A page with no URL" }
        if let host = url.host(), !host.isEmpty { return "Page on \(host)" }
        return "Page \(url.absoluteString.prefix(80))"
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
    /// calls the navigation delegate's `webViewWebContentProcessDidTerminate(_:)`
    /// — for every web view sharing the process — and the next load starts a
    /// fresh process.
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
