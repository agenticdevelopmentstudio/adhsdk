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
        for (type, number) in [(NSEvent.EventType.leftMouseDown, 1), (.leftMouseUp, 2)] {
            guard let event = NSEvent.mouseEvent(
                with: type, location: inWindow, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: number, clickCount: 1, pressure: 1
            ) else { continue }
            if type == .leftMouseDown { webView.mouseDown(with: event) } else { webView.mouseUp(with: event) }
        }
    }
}

/// The Safari pane's engine: a `WKWebView` it configures from the browser
/// settings and is the navigation, UI and download delegate of.
///
/// What it honours comes from the Browser settings (`BrowserSettings.swift`):
/// read once where WebKit fixes a value at construction, and followed live
/// everywhere WebKit lets a value change under a page.
@MainActor
public final class WebKitBrowserEngine: WebKitPageDriver, BrowserEngine {

    public weak var delegate: BrowserEngineDelegate?
    public let consoleLog: BrowserConsoleLog

    private let settings: SettingsStore
    private let siteData: BrowserSiteData
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private var observations: [NSKeyValueObservation] = []
    private var cancellables: Set<AnyCancellable> = []
    private var downloads: [WKDownload] = []
    /// The theme's window background, for the area around a blank page and
    /// the backdrop under every page.
    private var themedUnderPageColor: NSColor?

    public init(settings: SettingsStore) {
        self.settings = settings
        let consoleLog = BrowserConsoleLog()
        self.consoleLog = consoleLog
        let configuration = Self.makeConfiguration(settings: settings, consoleLog: consoleLog)
        self.siteData = BrowserSiteData(dataStore: configuration.websiteDataStore)
        let webView = LiveResizingWebView(
            frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: configuration)
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
        applyLiveSettings()
        applyCookiePolicy()
        observeSettings()
        observeWebView()
    }

    public var canGoBack: Bool { webView.canGoBack }
    public var canGoForward: Bool { webView.canGoForward }
    public func reload() { webView.reload() }
    public func stopLoading() { webView.stopLoading() }

    // MARK: - Settings

    /// The configuration WebKit fixes when the web view is made. The settings
    /// read here take effect for the *next* Safari pane, and the panel says
    /// so beside each of them.
    static func makeConfiguration(settings: SettingsStore, consoleLog: BrowserConsoleLog) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(consoleLog.userScript)
        configuration.userContentController.add(consoleLog, name: BrowserConsoleLog.handlerName)
        // Private browsing is a data store that lives only as long as the
        // pane; otherwise the default store, shared with every other Safari
        // pane, so a login in one pane is a login in the next.
        configuration.websiteDataStore = settings.get(UserSettings.browserPrivateBrowsing)
            ? .nonPersistent()
            : .default()
        configuration.upgradeKnownHostsToHTTPS = settings.get(UserSettings.browserUpgradesToHTTPS)
        configuration.allowsAirPlayForMediaPlayback = settings.get(UserSettings.browserAllowsAirPlay)
        configuration.mediaTypesRequiringUserActionForPlayback = switch settings.get(UserSettings.browserAutoplay) {
        case .allowed: []
        case .mutedOnly: .audio
        case .never: .all
        }
        return configuration
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

        let preferences = webView.configuration.preferences
        let fontSize = settings.get(UserSettings.browserMinimumFontSize)
        let fontRange = BrowserSettings.minimumFontSizeRange
        preferences.minimumFontSize = CGFloat(min(max(fontSize, fontRange.lowerBound), fontRange.upperBound))
        preferences.javaScriptCanOpenWindowsAutomatically = !settings.get(UserSettings.browserBlocksPopups)
        preferences.isFraudulentWebsiteWarningEnabled = settings.get(UserSettings.browserFraudWarning)
    }

    /// The cookie policy belongs to the data store, not the web view, and the
    /// persistent store is shared by every non-private pane. The engine still
    /// applies it, because a private pane's store has no other owner — but
    /// only when the cookie setting itself changes, not on every browser
    /// change: a zoom slider drag is not a reason for every open pane to
    /// rewrite the shared store's policy once per tick.
    private func applyCookiePolicy() {
        let acceptsCookies = settings.get(UserSettings.browserAcceptsCookies)
        Task { await siteData.setAcceptsCookies(acceptsCookies) }
    }

    private func observeSettings() {
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                self?.applyLiveSettings()
                if key == UserSettings.browserAcceptsCookies.name { self?.applyCookiePolicy() }
            }
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
    /// otherwise call back into it.
    public func teardown() {
        observations.removeAll()
        cancellables.removeAll()
        downloads.forEach { $0.cancel() }
        downloads.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        delegate = nil
        // The handler holds the log strongly and the engine holds the log, so
        // without this the two outlive the pane together.
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: BrowserConsoleLog.handlerName
        )
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
        logger.error("browser pane failed to load: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - Downloads

extension WebKitBrowserEngine: WKDownloadDelegate {

    private func adopt(_ download: WKDownload) {
        download.delegate = self
        downloads.append(download)
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
        logger.info("browser download finished from \(host, privacy: .public)")
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeAll { $0 === download }
        guard (error as NSError).code != NSURLErrorCancelled else { return }
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
