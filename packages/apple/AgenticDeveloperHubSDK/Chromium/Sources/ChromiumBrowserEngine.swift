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
/// - **Live:** zoom, the user agent, JavaScript, pop-up blocking, cookies,
///   Third-Party Content and the DevTools menu item. The user agent and
///   JavaScript go through the DevTools protocol (`Emulation`), which applies
///   them to the open page; Third-Party Content applies from the next request.
/// - **When the pane is built:** the jar and the minimum font size, which
///   Chromium fixes when a browser is created, so a jar change rebuilds the
///   engine.
/// - **When Chromium starts:** autoplay, hardware acceleration and the remote
///   debugging port (`ChromiumLauncher`).
///
/// Session privacy, as the WebKit engine has it: the input gate is a local
/// event monitor in front of Chromium's own views, since they are not this
/// engine's to subclass; the activation shield is the same script, put on
/// every new document over the DevTools protocol, with Chromium's focus
/// emulation beside it.
@MainActor
public final class ChromiumBrowserEngine: NSObject, BrowserEngine {

    public weak var delegate: BrowserEngineDelegate?
    public let consoleLog: BrowserConsoleLog

    private let browserView: ChromiumBrowserView
    private let options: ChromiumBrowserOptions
    private let settings: SettingsStore
    private let capturesConsole: Bool
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private let loadingSubject = PassthroughSubject<Bool, Never>()
    private var cancellables: Set<AnyCancellable> = []
    private var zoom = 1.0
    private var appliedUserAgent: String?
    private var appliedScriptsDisabled: Bool?
    /// The automation world of the current document; a navigation discards it.
    private var automationContext: Int?
    /// Whether the main frame is loading. Chromium's own loading flag covers
    /// every frame, so an iframe would read as a navigation.
    private var mainFrameLoading = false
    /// A main-frame load has started and its commit is still to be told:
    /// Chromium reports the load start before the new address, and a commit
    /// heard first would remember the page being left.
    private var commitPending = false

    // MARK: Session privacy state

    public var inputGate: BrowserInputGate = .open
    public var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)?
    public private(set) var isActivationShieldActive = false
    /// The shield script's token: one per engine, never shared, for the
    /// reason `BrowserActivationShield.token` gives.
    private let shieldToken = UUID().uuidString
    /// The new-document script the raised shield added, to remove on lower.
    private var shieldScriptIdentifier: String?
    /// Raises and lowers in the order asked, each after the last has landed,
    /// so a lower never misses the identifier of the raise before it.
    private var shieldTask: Task<Void, Never>?
    private var eventMonitor: Any?
    /// Whether the mouse button now down went down on the page, so its drags
    /// and its release follow it wherever the pointer goes.
    private var mouseSequenceOnPage = false

    public var heldLoadURL: URL? { nil }

    public init(configuration: BrowserEngineConfiguration) {
        let settings = configuration.settings
        self.settings = settings
        consoleLog = configuration.consoleLog
        capturesConsole = configuration.capturesConsole
        let options = ChromiumBrowserOptions()
        options.cachePath = Self.cachePath(for: configuration.jar)
        options.acceptsCookies = WebBrowserPaneViewController.acceptsCookies(
            settings: settings, ownsDataStore: configuration.jar.isOwnedByPane)
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
        installInputMonitor()
    }

    /// Where a jar's session lives: the shared profile for the global jar, a
    /// store kept in memory for private browsing and for a jar that failed
    /// closed, and a profile of its own, named by the jar's row, for a
    /// worktree or pane jar.
    static func cachePath(for jar: BrowserResolvedJar) -> String? {
        if jar.isEphemeral { return "" }
        if jar.jar == .global { return nil }
        guard let jarID = jar.jarID else { return "" }
        return ChromiumLauncher.jarsDirectory().appendingPathComponent(jarID.uuidString).path
    }

    // MARK: - Page

    public var view: NSView { browserView }
    public var url: URL? { browserView.address.flatMap(URL.init(string:)) }
    public var title: String? { browserView.pageTitle }
    public var isLoading: Bool { mainFrameLoading }
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
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
        eventMonitor = nil
        shieldTask?.cancel()
        onInputDecision = nil
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
        browserView.thirdPartyBlocking = switch settings.get(UserSettings.browserPrivacyThirdPartyContent) {
        case .allow: .none
        case .blockScripts: .scripts
        case .blockAll: .all
        }

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

    /// How long a DevTools call may go unanswered. A browser that is never
    /// created — a pane with no window, Chromium gone — would otherwise leave
    /// the call, and the automation gate it holds, waiting forever.
    static let devToolsTimeout: TimeInterval = 30

    /// Resumes its continuation once: with the reply, or with the timeout,
    /// whichever comes first. Both arrive on the main thread.
    @MainActor
    private final class PendingReply {
        private var continuation: CheckedContinuation<DevToolsReply, Error>?
        init(_ continuation: CheckedContinuation<DevToolsReply, Error>) { self.continuation = continuation }
        func finish(_ result: Result<DevToolsReply, Error>) {
            continuation?.resume(with: result)
            continuation = nil
        }
    }

    private func send(_ method: String, _ params: [String: Any] = [:]) async throws -> [String: Any] {
        guard ChromiumRuntime.shared.isRunning else {
            throw BrowserAutomationError.script("Chrome is not running, so \(method) cannot be sent")
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DevToolsReply, Error>) in
            let pending = PendingReply(continuation)
            browserView.sendDevToolsMethod(method, params: params) { result, error in
                MainActor.assumeIsolated {
                    if let result {
                        pending.finish(.success(DevToolsReply(value: result)))
                    } else {
                        let message = error?.localizedDescription ?? "\(method) failed"
                        pending.finish(.failure(BrowserAutomationError.script(message)))
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.devToolsTimeout) {
                MainActor.assumeIsolated {
                    pending.finish(.failure(BrowserAutomationError.script(
                        "Chrome did not answer \(method) within \(Int(Self.devToolsTimeout)) seconds")))
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
            guard decide(.mouse, type, synthesized: true) else { continue }
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
        commitIfPending()
    }

    private func commitIfPending() {
        guard commitPending else { return }
        commitPending = false
        delegate?.browserEngineDidCommitNavigation(self)
    }

    public func chromiumBrowserViewTitleDidChange(_ view: ChromiumBrowserView) {
        delegate?.browserEngineTitleDidChange(self)
    }

    /// Chromium reports loading and history together, for every frame; only
    /// the history is read here. Loading and navigation follow the main
    /// frame's own load, below.
    public func chromiumBrowserViewLoadingStateDidChange(_ view: ChromiumBrowserView) {
        delegate?.browserEngineHistoryDidChange(self)
        // A stopped or superseded load ends with neither a load end nor a
        // reported error; a browser loading nothing has no main frame loading.
        if !view.isLoading { setMainFrameLoading(false) }
    }

    private func setMainFrameLoading(_ loading: Bool) {
        guard loading != mainFrameLoading else { return }
        mainFrameLoading = loading
        loadingSubject.send(loading)
    }

    /// Chromium's main-frame load start is the navigation's start, and the
    /// document is the new one. The commit is told when the new address
    /// arrives, or at the load's end for a load that keeps its address.
    public func chromiumBrowserViewDidStartMainFrameLoad(_ view: ChromiumBrowserView) {
        setMainFrameLoading(true)
        delegate?.browserEngineDidStartNavigation(self)
        automationContext = nil
        commitPending = true
    }

    public func chromiumBrowserViewDidFinishMainFrameLoad(_ view: ChromiumBrowserView) {
        commitIfPending()
        setMainFrameLoading(false)
        delegate?.browserEngineDidFinishNavigation(self)
    }

    public func chromiumBrowserView(
        _ view: ChromiumBrowserView, didFailLoadWithMessage message: String, address: String
    ) {
        setMainFrameLoading(false)
        logger.error("chrome pane failed to load: \(message, privacy: .public)")
    }

    public func chromiumBrowserView(_ view: ChromiumBrowserView, didLogConsoleText text: String, level: String) {
        guard capturesConsole else { return }
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

    public func chromiumBrowserViewShouldAcceptDrag(_ view: ChromiumBrowserView) -> Bool {
        decide(.dragAndDrop, "draggingEntered", synthesized: false)
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

// MARK: - Session privacy

extension ChromiumBrowserEngine {

    public func applyCookiePolicy(acceptsCookies: Bool) {
        browserView.acceptsCookies = acceptsCookies
    }

    /// Raises or lowers the shield on the page showing now and on every
    /// document after it: the same script the WebKit engine installs, added
    /// as a new-document script, run at once on the page already showing,
    /// with Chromium's focus emulation so the page reads as focused even in a
    /// window that is not key. A cross-origin frame already showing is
    /// shielded from its next load.
    public func setActivationShieldActive(_ active: Bool) {
        guard active != isActivationShieldActive else { return }
        isActivationShieldActive = active
        let previous = shieldTask
        shieldTask = Task { @MainActor [weak self] in
            await previous?.value
            guard let self, !Task.isCancelled else { return }
            await self.applyShield(active)
        }
    }

    private func applyShield(_ active: Bool) async {
        guard let source = BrowserActivationShield.script(mode: active ? "raise" : "lift", token: shieldToken) else {
            return
        }
        do {
            if active {
                let added = try await send("Page.addScriptToEvaluateOnNewDocument", [
                    "source": source, "runImmediately": true
                ])
                shieldScriptIdentifier = added["identifier"] as? String
            } else if let identifier = shieldScriptIdentifier {
                shieldScriptIdentifier = nil
                _ = try await send("Page.removeScriptToEvaluateOnNewDocument", ["identifier": identifier])
            }
            _ = try await send("Emulation.setFocusEmulationEnabled", ["enabled": active])
            if url != nil {
                _ = try await send("Runtime.evaluate", ["expression": source])
            }
        } catch {
            logger.debug("activation shield did not change: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Input gate

    /// Whether `channel` reaches the page, told to `onInputDecision` either
    /// way.
    func decide(_ channel: BrowserInputChannel, _ event: String, synthesized: Bool, detail: String = "") -> Bool {
        let delivered = inputGate.allows(channel, synthesized: synthesized, pageHasFocus: pageHasFocus)
        onInputDecision?(channel, event, delivered, synthesized, detail)
        return delivered
    }

    /// The window is key and the first responder is in the page.
    private var pageHasFocus: Bool {
        guard let window = browserView.window, window.isKeyWindow else { return false }
        return holdsFirstResponder
    }

    private var holdsFirstResponder: Bool {
        guard let responder = browserView.window?.firstResponder as? NSView else { return false }
        return responder === browserView || responder.isDescendant(of: browserView)
    }

    /// Whether the window's event at `event`'s location lands on the page:
    /// the frontmost view under it is Chromium's, so a popover or sheet over
    /// the page keeps its own clicks.
    private func isOverPage(_ event: NSEvent) -> Bool {
        guard let window = browserView.window, event.window === window,
              let frame = window.contentView?.superview ?? window.contentView,
              let hit = frame.hitTest(event.locationInWindow) else { return false }
        return hit === browserView || hit.isDescendant(of: browserView)
    }

    private static let monitoredEvents: NSEvent.EventTypeMask = [
        .keyDown, .keyUp, .flagsChanged,
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged,
        .scrollWheel, .magnify, .rotate, .swipe, .smartMagnify, .pressure,
        .mouseMoved, .mouseEntered, .mouseExited, .cursorUpdate
    ]

    /// Chromium's views are its own, so the gate sits in front of them: a
    /// local monitor sees every event before the window dispatches it, and
    /// drops the ones bound for this page that the gate refuses.
    func installInputMonitor() {
        // Local monitors run on the main thread. The block answers a Bool, not
        // the event, because NSEvent is not Sendable across the isolation hop.
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: Self.monitoredEvents) { [weak self] event in
            nonisolated(unsafe) let event = event
            let keep = MainActor.assumeIsolated {
                guard let self else { return true }
                return self.filter(event) != nil
            }
            return keep ? event : nil
        }
    }

    private func filter(_ event: NSEvent) -> NSEvent? {
        guard let window = browserView.window, event.window === window else { return event }
        switch event.type {
        case .keyDown, .keyUp, .flagsChanged:
            return filterKey(event)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            mouseSequenceOnPage = isOverPage(event)
            return gateMouse(event, applies: mouseSequenceOnPage)
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return gateMouse(event, applies: mouseSequenceOnPage)
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            let applies = mouseSequenceOnPage
            mouseSequenceOnPage = false
            return gateMouse(event, applies: applies)
        case .scrollWheel, .magnify, .rotate, .swipe, .smartMagnify, .pressure:
            return gateMouse(event, applies: isOverPage(event))
        case .mouseEntered, .mouseExited:
            guard let owner = event.trackingArea?.owner as? NSView,
                  owner === browserView || owner.isDescendant(of: browserView) else { return event }
            return decide(.pointer, Self.name(of: event), synthesized: false) ? event : nil
        case .mouseMoved, .cursorUpdate:
            guard isOverPage(event) else { return event }
            return decide(.pointer, Self.name(of: event), synthesized: false) ? event : nil
        default:
            return event
        }
    }

    private func gateMouse(_ event: NSEvent, applies: Bool) -> NSEvent? {
        guard applies else { return event }
        return decide(.mouse, Self.name(of: event), synthesized: false) ? event : nil
    }

    /// A key bound for the page is gated; one for the address bar or any
    /// other view is not. A refused key with Command still reaches the menu
    /// bar, so Close Tab and the like keep working with the page shut off,
    /// unless it is an editing command the menu would send straight back to
    /// the page.
    private func filterKey(_ event: NSEvent) -> NSEvent? {
        guard holdsFirstResponder else { return event }
        let name = event.type == .keyDown ? "keyDown" : event.type == .keyUp ? "keyUp" : "flagsChanged"
        if decide(.keyboard, name, synthesized: false, detail: BrowserEventLog.keyDetail(for: event)) {
            return event
        }
        if event.type == .keyDown, event.modifierFlags.contains(.command), !Self.isEditingShortcut(event) {
            _ = NSApp.mainMenu?.performKeyEquivalent(with: event)
        }
        return nil
    }

    /// The Edit menu's own shortcuts, whose actions go to the first responder,
    /// which is the page.
    static func isEditingShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard flags.contains(.command), !flags.contains(.control),
              let key = event.charactersIgnoringModifiers?.lowercased() else { return false }
        return ["a", "c", "v", "x", "z"].contains(key)
    }

    private static func name(of event: NSEvent) -> String {
        switch event.type {
        case .leftMouseDown: "mouseDown"
        case .leftMouseUp: "mouseUp"
        case .leftMouseDragged: "mouseDragged"
        case .rightMouseDown: "rightMouseDown"
        case .rightMouseUp: "rightMouseUp"
        case .rightMouseDragged: "rightMouseDragged"
        case .otherMouseDown: "otherMouseDown"
        case .otherMouseUp: "otherMouseUp"
        case .otherMouseDragged: "otherMouseDragged"
        case .scrollWheel: "scrollWheel"
        case .magnify: "magnify"
        case .rotate: "rotate"
        case .swipe: "swipe"
        case .smartMagnify: "smartMagnify"
        case .pressure: "pressureChange"
        case .mouseMoved: "mouseMoved"
        case .mouseEntered: "mouseEntered"
        case .mouseExited: "mouseExited"
        case .cursorUpdate: "cursorUpdate"
        default: "event"
        }
    }
}
