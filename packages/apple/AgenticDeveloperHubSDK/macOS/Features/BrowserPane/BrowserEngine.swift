//
//  BrowserEngine.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine

/// Which JavaScript world a call runs in.
///
/// `automation` is the isolated world the snapshot runtime lives in, out of
/// the page's reach; `page` is the page's own world, for evaluating the
/// page's JavaScript as the page sees it. See `BrowserSnapshotRuntime`.
public enum BrowserScriptWorld: Sendable {
    case automation
    case page
}

/// What a model needs from a page to drive it, whatever engine renders it.
///
/// `BrowserAutomation` is written against this and nothing else, so a tool
/// call drives a Safari pane and a Chrome pane the same way: same snapshot
/// runtime, same refs, same deltas. Only the engine underneath differs
/// (`manage-complexity-through-boundaries`).
@MainActor
public protocol BrowserPageDriver: AnyObject {
    /// The page's address; `nil` before anything has loaded.
    var url: URL? { get }
    /// The page's title; `nil` or empty while it has none.
    var title: String? { get }
    var isLoading: Bool { get }
    /// `true` when a load starts, `false` when it stops, each time.
    var loadingChanges: AnyPublisher<Bool, Never> { get }
    /// The view that shows the page; its window is the pane's window.
    var view: NSView { get }
    /// The visible viewport, in CSS pixels.
    var viewportSize: CGSize { get }

    func load(_ url: URL)
    func goBack()
    func goForward()

    /// Installs `BrowserSnapshotRuntime.source` into the automation world.
    /// Idempotent: the script itself returns early when present.
    func installAutomationRuntime() async throws

    /// Runs `body` as the body of an async function whose parameters are
    /// `arguments`' keys bound to its values, and returns what it resolves
    /// to, JSON-shaped (`nil` for `undefined`). A thrown exception comes back
    /// as an error whose message is the exception's.
    func callAsyncFunction(body: String, arguments: [String: Any], world: BrowserScriptWorld) async throws -> Any?

    /// The viewport, or `cssRect` of it, as rendered.
    func snapshot(cssRect: CGRect?) async throws -> CGImage

    /// A real mouse click at a viewport point, in CSS pixels.
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws
}

/// What an engine tells the pane that hosts it. The pane owns everything an
/// engine does not have to know about — the address bar, history, the state
/// store, which window to ask a question on.
@MainActor
public protocol BrowserEngineDelegate: AnyObject {
    func browserEngineTitleDidChange(_ engine: BrowserEngine)
    func browserEngineAddressDidChange(_ engine: BrowserEngine)
    /// `canGoBack` or `canGoForward` changed.
    func browserEngineHistoryDidChange(_ engine: BrowserEngine)
    func browserEngineDidStartNavigation(_ engine: BrowserEngine)
    func browserEngineDidCommitNavigation(_ engine: BrowserEngine)
    func browserEngineDidFinishNavigation(_ engine: BrowserEngine)
    /// A JavaScript dialog the engine has already dismissed.
    func browserEngine(_ engine: BrowserEngine, didRaise dialog: BrowserDialog)
    /// Where to save a download; `nil` refuses it.
    func browserEngine(_ engine: BrowserEngine, destinationForDownloadNamed name: String) async -> URL?
    /// Whether `host` may use `device` ("camera", "microphone", …). `nil`
    /// leaves the answer to the engine's own default.
    func browserEngine(_ engine: BrowserEngine, allowsMediaCaptureFor host: String, device: String) async -> Bool?
}

/// A browser engine under a pane: WebKit for Safari, Chromium for Chrome.
///
/// An engine reads the browser settings it is given and follows them live
/// on its own, since which settings it can honour, and when, is a fact about
/// the engine; the pane never has to know.
@MainActor
public protocol BrowserEngine: BrowserPageDriver {
    var delegate: BrowserEngineDelegate? { get set }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    /// What the page wrote to `console.*` since the last navigation.
    var consoleLog: BrowserConsoleLog { get }
    func reload()
    func stopLoading()
    /// Stops the page, cancels its transfers and lets go of every callback;
    /// the engine is not used again.
    func teardown()
}

/// The words a media-capture question names the device with, shared by every
/// engine so the question reads the same whichever engine asks it (`dry`).
public enum BrowserMediaDevice {
    public static func describe(camera: Bool, microphone: Bool) -> String {
        switch (camera, microphone) {
        case (true, true): "camera and microphone"
        case (true, false): "camera"
        case (false, true): "microphone"
        case (false, false): "camera or microphone"
        }
    }
}
