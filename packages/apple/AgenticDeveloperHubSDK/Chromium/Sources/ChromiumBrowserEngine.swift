//
//  ChromiumBrowserEngine.swift
//  AgenticDeveloperHubSDKChromium
//

import AppKit
import Combine
import ImageIO
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKMacOS

/// The Chrome pane's engine: one Chromium browser, configured from the
/// browser settings and driven through the DevTools protocol where a model
/// drives it, so `BrowserAutomation` reads a Chrome page exactly as it reads
/// a Safari one.
///
/// What it honours, and when:
///
/// - **Live:** zoom, the user agent, JavaScript, pop-up blocking, cookies and
///   the DevTools menu item. The user agent and JavaScript go through the
///   DevTools protocol (`Emulation`), which applies them to the open page.
/// - **When the pane opens:** private browsing and the minimum font size,
///   which Chromium fixes when a browser is created.
/// - **When Chromium starts:** autoplay, hardware acceleration and the remote
///   debugging port (`ChromiumLauncher`).
@MainActor
public final class ChromiumBrowserEngine: NSObject, BrowserEngine {

    public weak var delegate: BrowserEngineDelegate?
    public let consoleLog = BrowserConsoleLog()

    private let browserView: ChromiumBrowserView
    private let options: ChromiumBrowserOptions
    private let settings: SettingsStore
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private var zoom = 1.0
    private var appliedUserAgent: String?
    private var appliedScriptsDisabled: Bool?
    /// The automation world of the current document; a navigation discards it.
    private var automationContext: Int?
    private var wasLoading = false

    public init(settings: SettingsStore) {
        self.settings = settings
        let options = ChromiumBrowserOptions()
        options.privateBrowsing = settings.get(UserSettings.browserPrivateBrowsing)
        let fontRange = BrowserSettings.minimumFontSizeRange
        options.minimumFontSize = min(max(settings.get(UserSettings.browserMinimumFontSize),
                                          fontRange.lowerBound), fontRange.upperBound)
        self.options = options
        let startError = ChromiumLauncher.start(settings: settings)
        browserView = ChromiumBrowserView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), options: options)
        super.init()
        browserView.delegate = self
        // Read when the browser is created, the first time the view is in a
        // window, so the latest palette is the one a blank page shows.
        browserView.observeTheme { [options] _, palette in
            options.backgroundColor = palette.windowBackgroundColor
        }
        if let startError { showFailure(startError) }
        applyLiveSettings()
        observeSettings()
    }

    // MARK: - Page

    public var view: NSView { browserView }
    public var url: URL? { browserView.address.flatMap(URL.init(string:)) }
    public var title: String? { browserView.pageTitle }
    public var isLoading: Bool { browserView.isLoading }
    public var canGoBack: Bool { browserView.canGoBack }
    public var canGoForward: Bool { browserView.canGoForward }
    public var loadingChanges: AnyPublisher<Bool, Never> { loadingSubject.eraseToAnyPublisher() }

    public var viewportSize: CGSize {
        CGSize(width: browserView.bounds.width / zoom, height: browserView.bounds.height / zoom)
    }

    public func load(_ url: URL) { browserView.loadAddress(url.absoluteString) }
    public func goBack() { browserView.goBack() }
    public func goForward() { browserView.goForward() }
    public func reload() { browserView.reload() }
    public func stopLoading() { browserView.stopLoading() }

    public func teardown() {
        cancellables.removeAll()
        delegate = nil
        browserView.delegate = nil
        browserView.close()
    }

    /// Chromium could not start, so this pane has no page: it says why where
    /// the page would be.
    private func showFailure(_ error: Error) {
        let label = NSTextField(wrappingLabelWithString: "Chrome could not start: \(error.localizedDescription)")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        browserView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: browserView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: browserView.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: browserView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Settings

    /// Every setting Chromium lets change under a page. Called once at
    /// construction and again whenever a browser key changes; the protocol
    /// calls go out only when their value actually moved.
    private func applyLiveSettings() {
        let range = BrowserSettings.pageZoomRange
        zoom = min(max(settings.get(UserSettings.browserPageZoom), range.lowerBound), range.upperBound)
        browserView.setZoomFactor(zoom)
        browserView.allowsDevTools = settings.get(UserSettings.browserChromeDevToolsEnabled)
        ChromiumRuntime.shared.acceptsCookies = settings.get(UserSettings.browserAcceptsCookies)

        let agent = settings.get(UserSettings.browserCustomUserAgent)
        if agent != appliedUserAgent {
            appliedUserAgent = agent
            // An empty override is Chromium's own user agent back.
            sendIgnoringResult("Emulation.setUserAgentOverride", ["userAgent": agent])
        }
        let disabled = !settings.get(UserSettings.browserJavaScriptEnabled)
        if disabled != appliedScriptsDisabled {
            appliedScriptsDisabled = disabled
            sendIgnoringResult("Emulation.setScriptExecutionDisabled", ["value": disabled])
        }
    }

    private func observeSettings() {
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyLiveSettings() }
            .store(in: &cancellables)
    }

    // MARK: - DevTools protocol

    /// A DevTools reply crossing from the bridge's completion block to the
    /// awaiting caller. Its JSON is parsed fresh for each reply and never
    /// shared, so handing it over is safe though `[String: Any]` is not
    /// `Sendable`.
    private struct DevToolsReply: @unchecked Sendable {
        let value: [String: Any]
    }

    private func send(_ method: String, _ params: [String: Any] = [:]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DevToolsReply, Error>) in
            browserView.sendDevToolsMethod(method, params: params) { result, error in
                if let result {
                    continuation.resume(returning: DevToolsReply(value: result))
                } else {
                    let message = error?.localizedDescription ?? "\(method) failed"
                    continuation.resume(throwing: BrowserAutomationError.script(message))
                }
            }
        }.value
    }

    private func sendIgnoringResult(_ method: String, _ params: [String: Any]) {
        browserView.sendDevToolsMethod(method, params: params) { [logger] _, error in
            if let error {
                logger.error("\(method, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// The automation world's execution context in the current document,
    /// made the first time it is asked for after a navigation.
    private func automationContextID() async throws -> Int {
        if let automationContext { return automationContext }
        let tree = try await send("Page.getFrameTree")
        guard let frameTree = tree["frameTree"] as? [String: Any],
              let frame = frameTree["frame"] as? [String: Any],
              let frameID = frame["id"] as? String else {
            throw BrowserAutomationError.script("the page has no main frame")
        }
        let world = try await send("Page.createIsolatedWorld", [
            "frameId": frameID, "worldName": BrowserSnapshotRuntime.worldName
        ])
        guard let contextID = world["executionContextId"] as? Int else {
            throw BrowserAutomationError.script("Chromium made no automation world")
        }
        automationContext = contextID
        return contextID
    }

    /// `Runtime.evaluate` in `world`, awaiting a promise, returning the value.
    /// A context that went away with a navigation is made again, once.
    private func evaluate(_ expression: String, world: BrowserScriptWorld) async throws -> Any? {
        do {
            return try await evaluateOnce(expression, world: world)
        } catch BrowserAutomationError.script(let message) where world == .automation
                    && message.contains("Cannot find context") {
            automationContext = nil
            return try await evaluateOnce(expression, world: world)
        }
    }

    private func evaluateOnce(_ expression: String, world: BrowserScriptWorld) async throws -> Any? {
        var params: [String: Any] = ["expression": expression, "awaitPromise": true, "returnByValue": true]
        if world == .automation {
            params["contextId"] = try await automationContextID()
        }
        let response = try await send("Runtime.evaluate", params)
        if let details = response["exceptionDetails"] as? [String: Any] {
            let exception = details["exception"] as? [String: Any]
            let message = exception?["description"] as? String ?? details["text"] as? String ?? "script failed"
            throw BrowserAutomationError.script(message)
        }
        guard let result = response["result"] as? [String: Any] else { return nil }
        if result["type"] as? String == "undefined" { return nil }
        return result["value"]
    }

    public func installAutomationRuntime() async throws {
        _ = try await evaluate(try BrowserSnapshotRuntime.source, world: .automation)
    }

    /// The same call WebKit's `callAsyncJavaScript` makes: `body` as an async
    /// function of `arguments`, its parameters in a fixed order, each value
    /// passed as JSON so a string can never become code.
    public func callAsyncFunction(
        body: String, arguments: [String: Any], world: BrowserScriptWorld
    ) async throws -> Any? {
        let names = arguments.keys.sorted()
        let values = try names.map { name -> String in
            let data = try JSONSerialization.data(withJSONObject: arguments[name] ?? NSNull(),
                                                  options: [.fragmentsAllowed])
            guard let json = String(bytes: data, encoding: .utf8) else {
                throw BrowserAutomationError.script("argument \(name) is not UTF-8 JSON")
            }
            return json
        }
        let parameters = names.joined(separator: ", ")
        let expression = "(async (\(parameters)) => {\n\(body)\n})(\(values.joined(separator: ", ")))"
        return try await evaluate(expression, world: world)
    }

    /// `Page.captureScreenshot`. Its clip is in page coordinates, so a viewport
    /// rect is moved by the scroll offset on its way in.
    public func snapshot(cssRect: CGRect?) async throws -> CGImage {
        var params: [String: Any] = ["format": "png"]
        if let cssRect {
            let metrics = try await send("Page.getLayoutMetrics")
            let viewport = metrics["cssLayoutViewport"] as? [String: Any]
            let pageX = viewport?["pageX"] as? Double ?? 0
            let pageY = viewport?["pageY"] as? Double ?? 0
            params["clip"] = [
                "x": cssRect.minX + pageX, "y": cssRect.minY + pageY,
                "width": cssRect.width, "height": cssRect.height, "scale": 1
            ]
        }
        let response = try await send("Page.captureScreenshot", params)
        guard let encoded = response["data"] as? String, let data = Data(base64Encoded: encoded),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw BrowserAutomationError.script("could not read the screenshot")
        }
        return image
    }

    /// `Input.dispatchMouseEvent`, whose coordinates are the viewport's CSS
    /// pixels — the same space the snapshot runtime measures in.
    public func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {
        guard browserView.window != nil else { throw BrowserAutomationError.noWindow }
        for type in ["mousePressed", "mouseReleased"] {
            _ = try await send("Input.dispatchMouseEvent", [
                "type": type, "x": viewportX, "y": viewportY, "button": "left", "clickCount": 1
            ])
        }
    }
}

// MARK: - What the browser reports

extension ChromiumBrowserEngine: ChromiumBrowserViewDelegate {

    public func chromiumBrowserViewAddressDidChange(_ view: ChromiumBrowserView) {
        delegate?.browserEngineAddressDidChange(self)
    }

    public func chromiumBrowserViewTitleDidChange(_ view: ChromiumBrowserView) {
        delegate?.browserEngineTitleDidChange(self)
    }

    /// Chromium reports loading and history together; the pane hears a
    /// navigation start only when loading begins, as WebKit tells it.
    public func chromiumBrowserViewLoadingStateDidChange(_ view: ChromiumBrowserView) {
        delegate?.browserEngineHistoryDidChange(self)
        guard view.isLoading != wasLoading else { return }
        wasLoading = view.isLoading
        loadingSubject.send(view.isLoading)
        if view.isLoading { delegate?.browserEngineDidStartNavigation(self) }
    }

    /// Chromium's load start is the commit: the document is the new one.
    public func chromiumBrowserViewDidStartMainFrameLoad(_ view: ChromiumBrowserView) {
        automationContext = nil
        delegate?.browserEngineDidCommitNavigation(self)
    }

    public func chromiumBrowserViewDidFinishMainFrameLoad(_ view: ChromiumBrowserView) {
        delegate?.browserEngineDidFinishNavigation(self)
    }

    public func chromiumBrowserView(
        _ view: ChromiumBrowserView, didFailLoadWithMessage message: String, address: String
    ) {
        logger.error("chrome pane failed to load: \(message, privacy: .public)")
    }

    public func chromiumBrowserView(_ view: ChromiumBrowserView, didLogConsoleText text: String, level: String) {
        consoleLog.record(BrowserConsoleMessage(level: level, text: text, timestamp: Date()))
    }

    public func chromiumBrowserView(
        _ view: ChromiumBrowserView, didRaiseDialog kind: ChromiumDialogKind, message: String
    ) {
        let dialogKind: BrowserDialog.Kind = switch kind {
        case .confirm: .confirm
        case .prompt: .prompt
        default: .alert
        }
        delegate?.browserEngine(self, didRaise: BrowserDialog(kind: dialogKind, message: message))
    }

    public func chromiumBrowserView(
        _ view: ChromiumBrowserView,
        destinationForDownloadNamed name: String,
        completion: @escaping (String?) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return completion(nil) }
            let destination = await self.delegate?.browserEngine(self, destinationForDownloadNamed: name)
            completion(destination?.path)
        }
    }

    public func chromiumBrowserView(
        _ view: ChromiumBrowserView,
        allowsMediaCaptureForHost host: String,
        camera: Bool,
        microphone: Bool,
        completion: @escaping (NSNumber?) -> Void
    ) {
        let device = BrowserMediaDevice.describe(camera: camera, microphone: microphone)
        Task { @MainActor [weak self] in
            guard let self else { return completion(nil) }
            let allowed = await self.delegate?.browserEngine(self, allowsMediaCaptureFor: host, device: device)
            completion(allowed.map { NSNumber(value: $0) })
        }
    }

    /// A pane has no windows to give a pop-up, so the address opens here, the
    /// way the Safari pane does it. With pop-ups blocked, only one the user
    /// clicked for opens; an address-less `window.open()` never does.
    public func chromiumBrowserView(
        _ view: ChromiumBrowserView, didRequestPopupForAddress address: String, userGesture: Bool
    ) {
        if settings.get(UserSettings.browserBlocksPopups) && !userGesture { return }
        guard let url = URL(string: address), !address.isEmpty,
              url != WebBrowserPaneViewController.blankPage else { return }
        load(url)
    }
}
