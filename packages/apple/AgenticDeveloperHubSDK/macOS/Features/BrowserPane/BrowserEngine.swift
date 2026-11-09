//
//  BrowserEngine.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import WebKit
import AgenticDeveloperHubSDKCore

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
    /// A navigation failed for a reason other than being replaced by the next.
    func browserEngine(_ engine: BrowserEngine, didFailNavigationWith error: Error)
    /// A download started, finished or failed (`event` is "start", "finish"
    /// or "fail"), from `host`.
    func browserEngine(_ engine: BrowserEngine, download event: String, host: String)
    /// The page opened a window — a `target="_blank"` link, a `window.open()`
    /// — and `popup` is the engine already showing it, tied to the opener so
    /// `window.opener` works (a sign-in or 2FA window posts its answer back
    /// through it). The host puts it in a tab and becomes its delegate, and
    /// answers `true`; `false` refuses it, and the engine tears it down.
    func browserEngine(_ engine: BrowserEngine, didOpenPopup popup: BrowserEngine) -> Bool
    /// The page closed its own window (`window.close()`); the engine has
    /// stopped and the host lets it go.
    func browserEngineDidRequestClose(_ engine: BrowserEngine)
}

extension BrowserEngineDelegate {
    public func browserEngine(_ engine: BrowserEngine, didFailNavigationWith error: Error) {}
    public func browserEngine(_ engine: BrowserEngine, download event: String, host: String) {}
    public func browserEngine(_ engine: BrowserEngine, didOpenPopup popup: BrowserEngine) -> Bool { false }
    public func browserEngineDidRequestClose(_ engine: BrowserEngine) {}
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

    // MARK: Session privacy

    /// What the page's user input passes through (Session Privacy, spec
    /// section 5). The pane computes it from its settings and pause state and
    /// sets it whole; the engine only enforces it.
    var inputGate: BrowserInputGate { get set }
    /// Told about every input the gate decided: channel, event name, whether
    /// it was delivered, whether the agent sent it, and a detail.
    var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)? { get set }
    /// Whether the page is being told it is focused and visible whatever the
    /// window really is (`BrowserActivationShield`).
    var isActivationShieldActive: Bool { get }
    /// Raises or lowers the activation shield, on the page showing now and
    /// every page after it.
    func setActivationShieldActive(_ active: Bool)
    /// Puts the cookie policy the pane decided on the engine's store. The pane
    /// decides because only it knows whether the store is shared.
    func applyCookiePolicy(acceptsCookies: Bool)
    /// A load waiting for the Third-Party Content rules to land, so a rebuild
    /// carries where the pane was going; `nil` when none is held.
    var heldLoadURL: URL? { get }
}

/// The storage jar a pane's engine is built on, resolved once by the pane.
///
/// The jar is engine-neutral: a WebKit engine reads `webKitDataStore`, a
/// Chromium engine reads `jar` and `jarID` and keeps the session in its own
/// on-disk directory named by the id, so the same jar setting isolates a
/// Safari pane and a Chrome pane alike.
public struct BrowserResolvedJar {
    /// `nil` for private browsing, which is no jar at all; `.global` for a
    /// pane with no jar registry.
    public let jar: BrowserStorageJar?
    /// The `browser_jars` row, for a worktree or pane jar.
    public let jarID: UUID?
    /// Why the worktree or pane jar asked for could not be made; the store is
    /// then a non-persistent one of the pane's own.
    public let fallbackReason: String?
    private let makeWebKitDataStore: () -> WKWebsiteDataStore

    public init(
        webKitDataStore: @autoclosure @escaping () -> WKWebsiteDataStore,
        jar: BrowserStorageJar?, jarID: UUID?, fallbackReason: String? = nil
    ) {
        self.makeWebKitDataStore = webKitDataStore
        self.jar = jar
        self.jarID = jarID
        self.fallbackReason = fallbackReason
    }

    /// The WebKit store for this jar, made when asked for: a Chrome pane
    /// never asks, so never makes a WebKit store it does not use.
    public var webKitDataStore: WKWebsiteDataStore { makeWebKitDataStore() }

    /// Whether the jar asked for was replaced by a non-persistent store.
    public var isFallback: Bool { fallbackReason != nil }

    /// Whether this pane alone uses the store, so a policy set on it changes
    /// no other pane.
    public var isOwnedByPane: Bool { jar == nil || jar == .pane || isFallback }

    /// Whether the store lives only as long as the pane: private browsing,
    /// or a jar that failed closed.
    public var isEphemeral: Bool { jar == nil || isFallback }

    /// The shared store, for a pane with no jar registry and for tests.
    public static var global: BrowserResolvedJar {
        BrowserResolvedJar(webKitDataStore: .default(), jar: .global, jarID: nil)
    }
}

/// Everything an engine is built from, decided by the pane before the engine
/// exists, so a rebuild hands the next engine exactly what the first got.
@MainActor
public struct BrowserEngineConfiguration {
    /// The settings the engine follows live.
    public let settings: SettingsStore
    /// Where the page's console goes: one per tab, handed on by the pane to
    /// the engine a rebuild puts in that tab, so it outlives the engine.
    public let consoleLog: BrowserConsoleLog
    /// The store the engine keeps its session in.
    public let jar: BrowserResolvedJar
    /// Whether the page console is captured at all. Read once, where the
    /// engine is built: a change waits for a rebuild.
    public let capturesConsole: Bool

    public init(
        settings: SettingsStore, consoleLog: BrowserConsoleLog,
        jar: BrowserResolvedJar, capturesConsole: Bool
    ) {
        self.settings = settings
        self.consoleLog = consoleLog
        self.jar = jar
        self.capturesConsole = capturesConsole
    }
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
