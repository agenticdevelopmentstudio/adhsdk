//
//  WebKitBrowserEngine.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import os
import WebKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// Drives a `WKWebView` for automation, and nothing more: it sets no
/// delegates, so whoever owns the web view keeps owning its navigation.
/// `BrowserAutomation(webView:console:)` wraps a bare web view in one.
@MainActor
public class WebKitPageDriver: NSObject, BrowserPageDriver {

    public let webView: WKWebView

    public init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }

    public var url: URL? { webView.url }
    public var title: String? { webView.title }
    public var isLoading: Bool { webView.isLoading }
    public var view: NSView { webView }

    public var loadingChanges: AnyPublisher<Bool, Never> {
        webView.publisher(for: \.isLoading, options: [.new]).eraseToAnyPublisher()
    }

    public var viewportSize: CGSize {
        let zoom = webView.pageZoom
        return CGSize(width: webView.bounds.width / zoom, height: webView.bounds.height / zoom)
    }

    public func load(_ url: URL) { webView.load(URLRequest(url: url)) }
    public func goBack() { webView.goBack() }
    public func goForward() { webView.goForward() }

    public func installAutomationRuntime() async throws {
        try await BrowserSnapshotRuntime.install(in: webView)
    }

    public func callAsyncFunction(
        body: String, arguments: [String: Any], world: BrowserScriptWorld
    ) async throws -> Any? {
        let contentWorld: WKContentWorld = switch world {
        case .automation: BrowserSnapshotRuntime.world
        case .page: .page
        }
        return try await webView.callAsyncJavaScript(body, arguments: arguments, in: nil, contentWorld: contentWorld)
    }

    /// WebKit's snapshot rect is in view points, so the CSS rect is scaled by
    /// the page zoom on its way in.
    public func snapshot(cssRect: CGRect?) async throws -> CGImage {
        let configuration = WKSnapshotConfiguration()
        if let cssRect {
            let zoom = webView.pageZoom
            configuration.rect = CGRect(x: cssRect.minX * zoom, y: cssRect.minY * zoom,
                                        width: cssRect.width * zoom, height: cssRect.height * zoom)
        }
        let image: NSImage = try await withCheckedThrowingContinuation { continuation in
            webView.takeSnapshot(with: configuration) { image, error in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: BrowserAutomationError.script(
                        error?.localizedDescription ?? "snapshot failed"))
                }
            }
        }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw BrowserAutomationError.script("could not read the screenshot")
        }
        return cgImage
    }

    /// Mouse down/up through the web view's own responder methods, so WebKit
    /// handles it as a real click. The point is viewport CSS pixels: the web
    /// view's bounds are the viewport, so a page coordinate would be off by
    /// the scroll offset on any page that has scrolled.
    public func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {
        guard let window = webView.window else { throw BrowserAutomationError.noWindow }
        let zoom = webView.pageZoom
        var point = NSPoint(x: viewportX * zoom, y: viewportY * zoom)
        if !webView.isFlipped { point.y = webView.bounds.height - point.y }
        let inWindow = webView.convert(point, to: nil)
        let click = { [webView] in
            for (type, number) in [(NSEvent.EventType.leftMouseDown, 1), (.leftMouseUp, 2)] {
                guard let event = NSEvent.mouseEvent(
                    with: type, location: inWindow, modifierFlags: [],
                    timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: window.windowNumber, context: nil, eventNumber: number, clickCount: 1, pressure: 1
                ) else { continue }
                if type == .leftMouseDown { webView.mouseDown(with: event) } else { webView.mouseUp(with: event) }
            }
        }
        // A gated web view lets the click through as the agent's, so the
        // pane's input settings judge it as synthesized, not as the user's.
        if let gated = webView as? BrowserWebView {
            gated.deliveringAutomationInput(click)
        } else {
            click()
        }
    }
}

/// The Safari pane's engine: a `WKWebView` it configures from the browser
/// settings and is the navigation, UI and download delegate of.
///
/// What it honours comes from the Browser settings (`BrowserSettings.swift`):
/// read once where WebKit fixes a value at construction, and followed live
/// everywhere WebKit lets a value change under a page. The Session Privacy
/// settings arrive through the pane: the input gate, the activation shield
/// and the cookie policy are the pane's decisions, enforced here. Third-Party
/// Content is followed here, because holding a load until the rules are on
/// is a fact about WebKit's rule compiler.
@MainActor
public final class WebKitBrowserEngine: WebKitPageDriver, BrowserEngine {

    public weak var delegate: BrowserEngineDelegate?
    public let consoleLog: BrowserConsoleLog

    private let settings: SettingsStore
    /// Whether this web view captures the page console, read once where its
    /// configuration was built, so the handler and the hook come together or
    /// not at all.
    private let capturesConsole: Bool
    private let siteData: BrowserSiteData
    /// Hides focus and visibility changes from the page.
    let activationShield: BrowserActivationShield
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private var observations: [NSKeyValueObservation] = []
    private var cancellables: Set<AnyCancellable> = []
    private var downloads: [WKDownload] = []
    /// The theme's window background, for the area around a blank page and
    /// the backdrop under every page.
    private var themedUnderPageColor: NSColor?

    /// The Third-Party Content value last asked of this web view, so an
    /// unrelated browser key change does not compile the rules again.
    private var requestedThirdPartyContent: BrowserThirdPartyContent?
    /// The value whose rules the web view actually has. What tests wait on;
    /// the compile behind it is asynchronous.
    private(set) var appliedThirdPartyContent: BrowserThirdPartyContent?
    /// Counts content-rule requests, so a compile that finishes after a newer
    /// request — or after teardown — is dropped.
    private var contentRulesGeneration = 0
    /// Whether the current request's rule list is still being compiled or
    /// looked up. A load asked for meanwhile is held (`heldLoad`).
    private var isApplyingContentRules = false
    /// The load waiting for the rules to land, so a page never starts before
    /// the blocker it was meant to load under.
    private var heldLoad: URLRequest?
    /// Whether a load is waiting for the rules. For tests.
    var isHoldingLoad: Bool { heldLoad != nil }
    /// Where rule lists come from. The store by default; a test injects a
    /// slow or failing one to drive the generation and failure paths.
    var contentRuleListProvider: @MainActor (BrowserThirdPartyContent) async throws -> WKContentRuleList? = {
        try await BrowserContentRules.ruleList(for: $0)
    }
    /// Called as each navigation starts. A test seam: it is how a test sees
    /// what rules were on the web view when its first page began loading.
    var onNavigationStart: (() -> Void)?
    /// How many finished compiles were dropped because a newer request had
    /// come since. For tests.
    private(set) var droppedContentRules = 0

    public convenience init(configuration: BrowserEngineConfiguration) {
        self.init(configuration: configuration, contentRuleListProvider: nil)
    }

    /// - Parameter contentRuleListProvider: Where rule lists come from, when
    ///   not the store. Given here rather than set afterwards because the
    ///   first compile starts during `init`.
    init(
        configuration: BrowserEngineConfiguration,
        contentRuleListProvider: (@MainActor (BrowserThirdPartyContent) async throws -> WKContentRuleList?)?
    ) {
        if let contentRuleListProvider { self.contentRuleListProvider = contentRuleListProvider }
        self.settings = configuration.settings
        self.consoleLog = configuration.consoleLog
        self.capturesConsole = configuration.capturesConsole
        let webConfiguration = Self.makeConfiguration(
            settings: configuration.settings, consoleLog: configuration.consoleLog,
            jar: configuration.jar, capturesConsole: configuration.capturesConsole
        )
        self.siteData = BrowserSiteData(dataStore: webConfiguration.websiteDataStore)
        // Every page sits behind an input gate, open until the pane sets one.
        let webView = BrowserWebView(
            frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: webConfiguration)
        self.activationShield = BrowserActivationShield(webView: webView)
        super.init(webView: webView)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.keepPaintingUnderQuietPresentation()
        webView.observeTheme { [weak self] _, palette in
            self?.themedUnderPageColor = palette.windowBackgroundColor
            self?.updatePageBackground()
        }
        updatePageBackground()
        installUserScripts()
        applyLiveSettings()
        observeSettings()
        observeWebView()
    }

    /// An engine on the shared store — or a private one, when the settings
    /// say private browsing — with its own console log, honouring the
    /// cookie setting itself. For a host with no pane around the engine, and
    /// for tests.
    public convenience init(settings: SettingsStore) {
        let jar = WebBrowserPaneViewController.resolveJar(
            settings: settings, context: .detached, label: WebBrowserPaneViewController.untitledLabel)
        self.init(configuration: BrowserEngineConfiguration(
            settings: settings,
            consoleLog: BrowserConsoleLog(),
            jar: jar,
            capturesConsole: settings.get(UserSettings.browserPrivacyConsoleCapture)
        ))
        applyCookiePolicy(acceptsCookies: WebBrowserPaneViewController.acceptsCookies(
            settings: settings, ownsDataStore: jar.isOwnedByPane))
    }

    private var gatedWebView: BrowserWebView? { webView as? BrowserWebView }

    public var canGoBack: Bool { webView.canGoBack }
    public var canGoForward: Bool { webView.canGoForward }

    /// Loads now, or — while the current rule list is still on its way —
    /// once it is on, so a blocked resource is never fetched by a page that
    /// started first. A newer load replaces a held one.
    public override func load(_ url: URL) {
        let request = URLRequest(url: url)
        if isApplyingContentRules {
            heldLoad = request
        } else {
            webView.load(request)
        }
    }

    // History moves are not held for rules, but they do cancel a held load,
    // so a load asked for earlier cannot land over them afterwards.
    public override func goBack() {
        heldLoad = nil
        webView.goBack()
    }

    public override func goForward() {
        heldLoad = nil
        webView.goForward()
    }

    public func reload() {
        heldLoad = nil
        webView.reload()
    }

    public func stopLoading() { webView.stopLoading() }

    public var heldLoadURL: URL? { heldLoad?.url }

    // MARK: - Session privacy

    public var inputGate: BrowserInputGate {
        get { gatedWebView?.gate ?? .open }
        set { gatedWebView?.gate = newValue }
    }

    public var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)? {
        get { gatedWebView?.onInputDecision }
        set { gatedWebView?.onInputDecision = newValue }
    }

    public var isActivationShieldActive: Bool { activationShield.isActive }

    /// When the shield's state moves, the user scripts are put back so the
    /// next page load follows it; the shield itself acts on the page showing.
    public func setActivationShieldActive(_ active: Bool) {
        let wasActive = activationShield.isActive
        activationShield.apply(active: active)
        if activationShield.isActive != wasActive { installUserScripts() }
    }

    /// The cookie policy belongs to the data store, which may be shared; the
    /// pane decides what goes on it and says so only when the answer moves.
    public func applyCookiePolicy(acceptsCookies: Bool) {
        let siteData = siteData
        Task { await siteData.setAcceptsCookies(acceptsCookies) }
    }

    /// Puts every user script the engine wants on the web view's controller:
    /// the console hook when this web view captures the console, the
    /// activation shield's script while the shield is up.
    ///
    /// The only place user scripts are added or removed.
    /// `WKUserContentController` cannot remove one script, only all of them,
    /// so turning the shield off means putting back everything else, and that
    /// is safe only while one function knows what "everything" is (`dry`).
    /// The automation runtime is not a user script (it is evaluated into its
    /// own content world on demand), so clearing the list does not touch it.
    private func installUserScripts() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        if capturesConsole { controller.addUserScript(consoleLog.userScript) }
        if let shieldScript = activationShield.userScript {
            controller.addUserScript(shieldScript)
        }
    }

    // MARK: - Settings

    /// The configuration WebKit fixes when the web view is made. The settings
    /// read here take effect for the *next* Safari pane, and the panel says
    /// so beside each of them. User scripts are not added here:
    /// `installUserScripts()` owns them, so there is one owner to keep right.
    ///
    /// - Parameter capturesConsole: Whether to register the console message
    ///   handler. Off, a page has no `webkit.messageHandlers` entry to find
    ///   the hook by.
    static func makeConfiguration(
        settings: SettingsStore,
        consoleLog: BrowserConsoleLog,
        jar: BrowserResolvedJar,
        capturesConsole: Bool
    ) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if capturesConsole {
            configuration.userContentController.add(consoleLog, name: BrowserConsoleLog.handlerName)
        }
        configuration.websiteDataStore = jar.webKitDataStore
        configuration.upgradeKnownHostsToHTTPS = settings.get(UserSettings.browserUpgradesToHTTPS)
        configuration.allowsAirPlayForMediaPlayback = settings.get(UserSettings.browserAllowsAirPlay)
        configuration.mediaTypesRequiringUserActionForPlayback = switch settings.get(UserSettings.browserAutoplay) {
        case .allowed: []
        case .mutedOnly: .audio
        case .never: .all
        }
        return configuration
    }

    /// The configuration a pane in `context` would be built with now.
    static func makeConfiguration(
        settings: SettingsStore,
        consoleLog: BrowserConsoleLog,
        context: BrowserPaneContext = .detached
    ) -> WKWebViewConfiguration {
        makeConfiguration(
            settings: settings,
            consoleLog: consoleLog,
            jar: WebBrowserPaneViewController.resolveJar(
                settings: settings, context: context, label: WebBrowserPaneViewController.untitledLabel),
            capturesConsole: settings.get(UserSettings.browserPrivacyConsoleCapture)
        )
    }

    /// Every setting WebKit lets change under a page, applied from the store.
    /// Called once at construction and again whenever a browser key changes.
    private func applyLiveSettings() {
        let zoom = settings.get(UserSettings.browserPageZoom)
        let zoomRange = BrowserSettings.pageZoomRange
        webView.pageZoom = min(max(zoom, zoomRange.lowerBound), zoomRange.upperBound)
        let agent = settings.get(UserSettings.browserCustomUserAgent)
        webView.customUserAgent = agent.isEmpty ? nil : agent
        webView.isInspectable = settings.get(UserSettings.browserWebInspectorEnabled)
        applyContentRules()

        let preferences = webView.configuration.preferences
        let fontSize = settings.get(UserSettings.browserMinimumFontSize)
        let fontRange = BrowserSettings.minimumFontSizeRange
        preferences.minimumFontSize = CGFloat(min(max(fontSize, fontRange.lowerBound), fontRange.upperBound))
        preferences.javaScriptCanOpenWindowsAutomatically = !settings.get(UserSettings.browserBlocksPopups)
        preferences.isFraudulentWebsiteWarningEnabled = settings.get(UserSettings.browserFraudWarning)
    }

    /// Puts the Third-Party Content setting's rule list on the web view,
    /// live: the old list comes off and the new one goes on when its compile
    /// finishes (spec section 9). Only when the value differs from the one
    /// last asked, so a zoom drag does not recompile.
    ///
    /// The compile is asynchronous, so a request carries a generation; one
    /// that finishes after a newer request is dropped rather than applied
    /// over it. `.allow` takes the rules off at once. Until a blocking
    /// compile lands the web view keeps whatever list it had, and a load
    /// asked for meanwhile is held (`load(_:)`).
    ///
    /// A failed compile fails **open**: the web view keeps the lists it had,
    /// the held load goes ahead, the failure is logged, and the request is
    /// forgotten so the next settings change tries again. Blocking every load
    /// because the rule store errored would break browsing outright.
    private func applyContentRules() {
        let policy = settings.get(UserSettings.browserPrivacyThirdPartyContent)
        guard policy != requestedThirdPartyContent else { return }
        requestedThirdPartyContent = policy
        contentRulesGeneration += 1
        let generation = contentRulesGeneration
        guard policy != .allow else {
            webView.configuration.userContentController.removeAllContentRuleLists()
            appliedThirdPartyContent = .allow
            finishContentRules()
            return
        }
        isApplyingContentRules = true
        let provide = contentRuleListProvider
        Task { [weak self, logger] in
            do {
                let list = try await provide(policy)
                guard let self else { return }
                guard self.contentRulesGeneration == generation else {
                    self.droppedContentRules += 1
                    return
                }
                let controller = self.webView.configuration.userContentController
                controller.removeAllContentRuleLists()
                if let list { controller.add(list) }
                self.appliedThirdPartyContent = policy
                self.finishContentRules()
            } catch {
                guard let self else { return }
                // A stale failure says nothing about the current request: it
                // must neither forget that request nor release its held load.
                guard self.contentRulesGeneration == generation else {
                    self.droppedContentRules += 1
                    return
                }
                self.requestedThirdPartyContent = nil
                logger.error(
                    "browser content rules failed to compile: \(error.localizedDescription, privacy: .public)")
                self.finishContentRules()
            }
        }
    }

    /// The current request is done, one way or the other: a held load may go.
    private func finishContentRules() {
        isApplyingContentRules = false
        guard let request = heldLoad else { return }
        heldLoad = nil
        webView.load(request)
    }

    private func observeSettings() {
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyLiveSettings() }
            .store(in: &cancellables)
    }

    // MARK: - Observation

    /// Title, address and the back/forward affordances all follow the web view
    /// rather than being set by whichever code path happened to navigate —
    /// a link click, a redirect and a typed address all land here the same way.
    private func observeWebView() {
        observations = [
            webView.observe(\.title, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.delegate?.browserEngineTitleDidChange(self)
                }
            },
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.updatePageBackground()
                    self.delegate?.browserEngineAddressDidChange(self)
                }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.delegate?.browserEngineHistoryDidChange(self)
                }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.delegate?.browserEngineHistoryDidChange(self)
                }
            }
        ]
    }

    /// Nothing loaded — no address yet, or the blank page — is see-through, so
    /// the pane's themed backdrop shows instead of WebKit's white; a real page
    /// gets its opaque backdrop back the moment the address moves to it, since
    /// a site with no background of its own is written for white. See
    /// `WKWebView.setDrawsPageBackground(_:)`.
    ///
    /// The area past the page's edges follows the same split. Around a blank
    /// page it is the theme's. Around a real page it is left to WebKit, which
    /// takes the page's own background.
    ///
    /// The backdrop under every page is the theme's window background. WebKit
    /// paints out of process, a frame or more behind the web view's frame, so
    /// a resize that widens the pane uncovers a strip at the trailing edge
    /// that shows only that backdrop until the page catches up. Left at
    /// WebKit's default, `controlBackgroundColor`, it was a grey bar chasing
    /// the edge; in the page's own colour it still flashed wherever the page
    /// painted something else over its declared background. In the theme's
    /// colour it reads as the window showing through, the same surface as
    /// the pane around it. The backdrop shows only where the page has not
    /// painted: a page with no background of its own still draws white.
    private func updatePageBackground() {
        let url = webView.url
        let isPage = url != nil && url != WebBrowserPaneViewController.blankPage
        webView.setDrawsPageBackground(isPage)
        webView.underPageBackgroundColor = isPage ? nil : themedUnderPageColor
        webView.setPageBackdropColor(themedUnderPageColor)
    }

    // MARK: - Teardown

    /// Stops the page, cancels its downloads and drops the delegates: a
    /// navigation or a transfer that completes into a discarded pane would
    /// otherwise call back into it. A compile still in flight is dropped by
    /// its generation.
    public func teardown() {
        observations.removeAll()
        cancellables.removeAll()
        downloads.forEach { $0.cancel() }
        downloads.removeAll()
        contentRulesGeneration += 1
        heldLoad = nil
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        gatedWebView?.onInputDecision = nil
        delegate = nil
        onNavigationStart = nil
        // The handler holds the log strongly and the pane holds the log, so
        // without this the two outlive the pane together.
        if capturesConsole {
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: BrowserConsoleLog.handlerName
            )
        }
    }
}

// MARK: - Navigation

extension WebKitBrowserEngine: WKNavigationDelegate {

    /// Per navigation, and read off the settings each time, so switching
    /// JavaScript or Lockdown Mode takes effect on the next page rather than
    /// the next pane. WebKit picks **one** `decidePolicyFor` overload, so the
    /// download decision lives here too.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        preferences.allowsContentJavaScript = settings.get(UserSettings.browserJavaScriptEnabled)
        preferences.isLockdownModeEnabled = settings.get(UserSettings.browserLockdownMode)
        return (navigationAction.shouldPerformDownload ? .download : .allow, preferences)
    }

    /// A response the web view cannot show — a zip, a disk image — is a
    /// download, which is what every browser does with one.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        navigationResponse.canShowMIMEType ? .allow : .download
    }

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        adopt(download)
    }

    public func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload
    ) {
        adopt(download)
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.browserEngineDidStartNavigation(self)
        onNavigationStart?()
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        delegate?.browserEngineDidCommitNavigation(self)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.browserEngineDidFinishNavigation(self)
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        // A cancelled load is the next navigation starting, not a failure.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        delegate?.browserEngine(self, didFailNavigationWith: error)
        logger.error("browser pane failed to load: \(error.localizedDescription, privacy: .public)")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        delegate?.browserEngine(self, didFailNavigationWith: error)
    }
}

// MARK: - Downloads

extension WebKitBrowserEngine: WKDownloadDelegate {

    private func adopt(_ download: WKDownload) {
        download.delegate = self
        downloads.append(download)
        delegate?.browserEngine(self, download: "start", host: download.originalRequest?.url?.host ?? "")
    }

    public func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        await delegate?.browserEngine(self, destinationForDownloadNamed: suggestedFilename)
    }

    public func downloadDidFinish(_ download: WKDownload) {
        downloads.removeAll { $0 === download }
        // The host says which site it came from; the path and query can carry
        // a token or a name, and stay out of the public log.
        let host = download.originalRequest?.url?.host ?? ""
        delegate?.browserEngine(self, download: "finish", host: host)
        logger.info("browser download finished from \(host, privacy: .public)")
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeAll { $0 === download }
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        delegate?.browserEngine(self, download: "fail", host: download.originalRequest?.url?.host ?? "")
        logger.error("browser download failed: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - UI delegate

extension WebKitBrowserEngine: WKUIDelegate {

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        delegate?.browserEngine(self, didRaise: BrowserDialog(kind: .alert, message: message))
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        delegate?.browserEngine(self, didRaise: BrowserDialog(kind: .confirm, message: message))
        return false
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        delegate?.browserEngine(self, didRaise: BrowserDialog(kind: .prompt, message: prompt))
        return nil
    }

    /// A `target="_blank"` link asks for a new window. A pane has no windows to
    /// give it, so the link opens here instead — in the pane the user is
    /// looking at, which is where a click goes everywhere else.
    ///
    /// A script's `window.open()` with no address asks for a blank window to
    /// write into later. There is nothing to open for that, and loading the
    /// blank page here would throw away the page on screen and the address
    /// the pane remembers, so it is refused.
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url, url != WebBrowserPaneViewController.blankPage else { return nil }
        webView.load(navigationAction.request)
        return nil
    }

    /// Camera and microphone: the pane decides, from the Media setting; with
    /// no answer (nowhere to ask) WebKit asks in its own way.
    public func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        let device = switch type {
        case .camera: BrowserMediaDevice.describe(camera: true, microphone: false)
        case .microphone: BrowserMediaDevice.describe(camera: false, microphone: true)
        case .cameraAndMicrophone: BrowserMediaDevice.describe(camera: true, microphone: true)
        @unknown default: BrowserMediaDevice.describe(camera: false, microphone: false)
        }
        switch await delegate?.browserEngine(self, allowsMediaCaptureFor: origin.host, device: device) {
        case true?: return .grant
        case false?: return .deny
        case nil: return .prompt
        }
    }
}
