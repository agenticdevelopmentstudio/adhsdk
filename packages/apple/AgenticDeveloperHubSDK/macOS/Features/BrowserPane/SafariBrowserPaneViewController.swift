//
//  SafariBrowserPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit
import AgenticDeveloperHubSDKCore

/// The Safari Web Browser pane: a `WebBrowserPaneViewController` over WebKit.
/// Everything but the engine, privacy included, is the base class's.
@MainActor
public final class SafariBrowserPaneViewController: WebBrowserPaneViewController {

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours. The app's shared
    ///     store by default; a test hands in an in-memory one.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    ///   - context: The project, worktree and node the pane belongs to.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = WebBrowserPaneViewController.blankPage,
        context: BrowserPaneContext = .detached
    ) {
        let seams = Seams()
        self.seams = seams
        super.init(
            makeEngine: {
                WebKitBrowserEngine(configuration: $0, contentRuleListProvider: seams.contentRuleListProvider)
            },
            engineKind: .safari,
            minimizedSymbol: "safari",
            store: store,
            settings: settings,
            history: history,
            homeURL: homeURL,
            context: context
        )
        // A test seam set on the pane outlives the engine it was set on.
        onEngineMade = { engine in
            (engine as? WebKitBrowserEngine)?.onNavigationStart = seams.onNavigationStart
        }
    }

    /// The test seams a rebuild carries to the next engine. A box made
    /// before `super.init`, so the engine factory can read it: the rule list
    /// provider has to reach the engine before its first compile, which
    /// starts during the engine's `init`.
    private final class Seams {
        var contentRuleListProvider: ContentRuleListProvider?
        var onNavigationStart: (() -> Void)?
    }

    private let seams: Seams

    // MARK: - Web extensions

    /// The pane as its profile's extensions see it, and its buttons; nil
    /// where extensions do not run (before macOS 15.4, a jar kept in memory).
    private var extensionWindow: AnyObject?
    private var extensionToolbar: NSView?
    private var keyObserver: NSObjectProtocol?

    public override func viewDidLoad() {
        super.viewDidLoad()
        attachExtensions()
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
        keyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: view.window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.noteExtensionFocus() }
        }
        noteExtensionFocus()
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
        keyObserver = nil
    }

    private func noteExtensionFocus() {
        guard #available(macOS 15.4, *), let window = extensionWindow as? SafariExtensionWindow else { return }
        window.host?.noteFocus(window)
    }

    private func attachExtensions() {
        guard #available(macOS 15.4, *), SafariExtensionSupport.isAvailable, !isDiscarded,
              let host = SafariExtensionHost.runningHost(for: resolvedJar) else { return }
        let window = SafariExtensionWindow(pane: self, host: host)
        let toolbar = SafariExtensionToolbar(window: window, host: host)
        window.toolbar = toolbar
        window.onHostChange = { [weak self] in self?.reattachExtensions() }
        tabObserver = window
        host.register(window)
        addToolbarAccessory(toolbar)
        extensionWindow = window
        extensionToolbar = toolbar
    }

    /// The pane moved to a jar on another profile: its pages now run that
    /// profile's extensions, so its window moves to that profile's host.
    private func reattachExtensions() {
        if #available(macOS 15.4, *), let window = extensionWindow as? SafariExtensionWindow {
            window.host?.unregister(window)
        }
        tabObserver = nil
        extensionToolbar?.removeFromSuperview()
        extensionWindow = nil
        extensionToolbar = nil
        attachExtensions()
    }

    /// The WebKit engine under the page; replaced on a rebuild.
    var webKitEngine: WebKitBrowserEngine {
        guard let webKit = engine as? WebKitBrowserEngine else {
            preconditionFailure("a Safari pane's engine is always WebKit")
        }
        return webKit
    }

    /// The web view the page is in.
    public var webView: WKWebView { webKitEngine.webView }

    // MARK: - Test seams, forwarded to the current engine

    typealias ContentRuleListProvider = @MainActor (BrowserThirdPartyContent) async throws -> WKContentRuleList?

    var activationShield: BrowserActivationShield { webKitEngine.activationShield }
    var isHoldingLoad: Bool { webKitEngine.isHoldingLoad }
    var droppedContentRules: Int { webKitEngine.droppedContentRules }
    var appliedThirdPartyContent: BrowserThirdPartyContent? { webKitEngine.appliedThirdPartyContent }

    var contentRuleListProvider: @MainActor (BrowserThirdPartyContent) async throws -> WKContentRuleList? {
        get { webKitEngine.contentRuleListProvider }
        set {
            seams.contentRuleListProvider = newValue
            webKitEngine.contentRuleListProvider = newValue
        }
    }

    var onNavigationStart: (() -> Void)? {
        get { webKitEngine.onNavigationStart }
        set {
            seams.onNavigationStart = newValue
            webKitEngine.onNavigationStart = newValue
        }
    }
}
