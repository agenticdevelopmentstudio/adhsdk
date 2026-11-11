//
//  SafariExtensionAdapters.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

/// A Safari pane as a web extension sees it: one browser window, whose tabs
/// are the pane's tabs. WebKit asks it what `chrome.windows` and
/// `chrome.tabs` answer, and it tells the host's controller about every tab
/// the pane opens, closes, switches to or navigates.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionWindow: NSObject, WKWebExtensionWindow, BrowserPaneTabObserver {

    private(set) weak var pane: WebBrowserPaneViewController?
    private(set) weak var host: SafariExtensionHost?
    /// The pane's extension buttons, where a popup is shown from.
    weak var toolbar: SafariExtensionToolbar?
    /// The pane moved to a jar on another profile: the window must be
    /// rebuilt on that profile's host.
    var onHostChange: (() -> Void)?

    /// The pane is private browsing, on the global profile's host. WebKit
    /// asks once per window, so a pane that changes either way is rebuilt.
    let isPrivatePane: Bool

    private var tabsByEngine: [ObjectIdentifier: SafariExtensionTab] = [:]

    init(pane: WebBrowserPaneViewController, host: SafariExtensionHost) {
        self.pane = pane
        self.host = host
        isPrivatePane = SafariExtensionHost.isPrivateBrowsing(pane.resolvedJar)
        super.init()
    }

    /// Whether the extension running in `context` may see this window: a
    /// private one only when it is allowed in private browsing.
    func isVisible(to context: WKWebExtensionContext) -> Bool {
        !isPrivatePane || context.hasAccessToPrivateData
    }

    /// The adapter for `engine`'s tab, made on first use; nil for an engine
    /// that is not WebKit's.
    func tab(for engine: BrowserEngine) -> SafariExtensionTab? {
        guard let webKit = engine as? WebKitBrowserEngine else { return nil }
        let key = ObjectIdentifier(webKit)
        if let tab = tabsByEngine[key] { return tab }
        let tab = SafariExtensionTab(engine: webKit, window: self)
        tabsByEngine[key] = tab
        wire(webKit)
        return tab
    }

    /// Every tab, in bar order.
    var allTabs: [SafariExtensionTab] {
        (pane?.tabEngines ?? []).compactMap { tab(for: $0) }
    }

    var activeTabAdapter: SafariExtensionTab? {
        pane.flatMap { tab(for: $0.engine) }
    }

    var nsWindow: NSWindow? { pane?.view.window }

    var isInKeyWindow: Bool { nsWindow?.isKeyWindow == true }

    /// The extensions' keyboard shortcuts and context-menu items reach the
    /// page through its web view.
    private func wire(_ engine: WebKitBrowserEngine) {
        guard let webView = engine.webView as? BrowserWebView else { return }
        webView.performsExtensionCommand = { [weak self] event in
            self?.host?.performCommand(for: event) ?? false
        }
        webView.extensionMenuItems = { [weak self, weak engine] in
            guard let self, let engine, let tab = self.tab(for: engine) else { return [] }
            return self.host?.menuItems(for: tab) ?? []
        }
    }

    private func forget(_ engine: BrowserEngine) -> SafariExtensionTab? {
        guard let webKit = engine as? WebKitBrowserEngine else { return nil }
        return tabsByEngine.removeValue(forKey: ObjectIdentifier(webKit))
    }

    // MARK: - BrowserPaneTabObserver

    func pane(_ pane: WebBrowserPaneViewController, didAddTab engine: BrowserEngine) {
        guard let tab = tab(for: engine) else { return }
        host?.controller.didOpenTab(tab)
    }

    func pane(_ pane: WebBrowserPaneViewController, willCloseTab engine: BrowserEngine) {
        guard let tab = forget(engine) else { return }
        host?.controller.didCloseTab(tab, windowIsClosing: false)
    }

    func pane(_ pane: WebBrowserPaneViewController, didActivateTab engine: BrowserEngine, previous: BrowserEngine?) {
        guard let controller = host?.controller, let tab = tab(for: engine) else { return }
        let previousTab = previous.flatMap { self.tab(for: $0) }
        controller.didActivateTab(tab, previousActiveTab: previousTab)
        if let previousTab { controller.didDeselectTabs([previousTab]) }
        controller.didSelectTabs([tab])
        toolbar?.refresh()
    }

    func pane(_ pane: WebBrowserPaneViewController, didReplaceTab old: BrowserEngine, with new: BrowserEngine) {
        if SafariExtensionHost.runningHost(for: pane.resolvedJar) !== host
            || SafariExtensionHost.isPrivateBrowsing(pane.resolvedJar) != isPrivatePane {
            onHostChange?()
            return
        }
        let wasKnown = (new as? WebKitBrowserEngine).map { tabsByEngine[ObjectIdentifier($0)] != nil } ?? false
        let oldTab = forget(old)
        guard let newTab = tab(for: new) else { return }
        if let oldTab {
            host?.controller.didReplaceTab(oldTab, with: newTab)
        } else if !wasKnown {
            host?.controller.didOpenTab(newTab)
        }
        toolbar?.refresh()
    }

    func pane(_ pane: WebBrowserPaneViewController, tabDidChange engine: BrowserEngine) {
        guard let tab = tab(for: engine) else { return }
        host?.controller.didChangeTabProperties([.title, .URL, .loading], for: tab)
        if engine === pane.engine { toolbar?.refresh() }
    }

    func paneWillBeDiscarded(_ pane: WebBrowserPaneViewController) {
        host?.unregister(self)
        tabsByEngine = [:]
    }

    // MARK: - WKWebExtensionWindow

    func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab] {
        allTabs
    }

    func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        activeTabAdapter
    }

    func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType {
        .normal
    }

    func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState {
        guard let window = nsWindow else { return .normal }
        if window.isMiniaturized { return .minimized }
        if window.styleMask.contains(.fullScreen) { return .fullscreen }
        if window.isZoomed { return .maximized }
        return .normal
    }

    func setWindowState(
        _ state: WKWebExtension.WindowState, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let window = nsWindow else {
            completionHandler(Self.error("The pane has no window."))
            return
        }
        switch state {
        case .minimized: window.miniaturize(nil)
        case .maximized: if !window.isZoomed { window.zoom(nil) }
        case .fullscreen: if !window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
        case .normal:
            if window.isMiniaturized { window.deminiaturize(nil) }
            if window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
        @unknown default: break
        }
        completionHandler(nil)
    }

    func isPrivate(for context: WKWebExtensionContext) -> Bool {
        isPrivatePane
    }

    func screenFrame(for context: WKWebExtensionContext) -> CGRect {
        nsWindow?.screen?.frame ?? NSScreen.main?.frame ?? .null
    }

    func frame(for context: WKWebExtensionContext) -> CGRect {
        nsWindow?.frame ?? .null
    }

    func setFrame(
        _ frame: CGRect, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let window = nsWindow else {
            completionHandler(Self.error("The pane has no window."))
            return
        }
        window.setFrame(frame, display: true)
        completionHandler(nil)
    }

    /// Focusing is what the extension asked for, so the window comes to the
    /// front, as `chrome.windows.update({focused: true})` does in Chrome.
    func focus(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let window = nsWindow else {
            completionHandler(Self.error("The pane has no window."))
            return
        }
        window.makeKeyAndOrderFront(nil)
        completionHandler(nil)
    }

    /// A pane's window is a project window holding other panes; an
    /// extension does not get to close it.
    func close(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(Self.error("This window cannot be closed by an extension."))
    }

    static func error(_ text: String) -> NSError {
        NSError(domain: "SafariExtensionWindow", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

/// One tab of a Safari pane, as a web extension sees it.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionTab: NSObject, WKWebExtensionTab {

    private(set) weak var engine: WebKitBrowserEngine?
    private(set) weak var window: SafariExtensionWindow?

    init(engine: WebKitBrowserEngine, window: SafariExtensionWindow) {
        self.engine = engine
        self.window = window
        super.init()
    }

    private var pane: WebBrowserPaneViewController? { window?.pane }

    func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)? {
        window
    }

    func indexInWindow(for context: WKWebExtensionContext) -> Int {
        guard let engine, let engines = pane?.tabEngines else { return NSNotFound }
        return engines.firstIndex { $0 === engine } ?? NSNotFound
    }

    func webView(for context: WKWebExtensionContext) -> WKWebView? {
        engine?.webView
    }

    func title(for context: WKWebExtensionContext) -> String? {
        engine?.title
    }

    func isSelected(for context: WKWebExtensionContext) -> Bool {
        guard let engine, let pane else { return false }
        return pane.engine === engine
    }

    func size(for context: WKWebExtensionContext) -> CGSize {
        engine?.webView.bounds.size ?? .zero
    }

    func zoomFactor(for context: WKWebExtensionContext) -> Double {
        Double(engine?.webView.pageZoom ?? 1)
    }

    func setZoomFactor(
        _ zoomFactor: Double, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let engine else { return completionHandler(Self.gone) }
        engine.webView.pageZoom = CGFloat(zoomFactor)
        completionHandler(nil)
    }

    func url(for context: WKWebExtensionContext) -> URL? {
        engine?.url
    }

    func isLoadingComplete(for context: WKWebExtensionContext) -> Bool {
        !(engine?.isLoading ?? false)
    }

    func loadURL(_ url: URL, for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let engine else { return completionHandler(Self.gone) }
        engine.load(url)
        completionHandler(nil)
    }

    func reload(
        fromOrigin: Bool, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let engine else { return completionHandler(Self.gone) }
        if fromOrigin { engine.webView.reloadFromOrigin() } else { engine.reload() }
        completionHandler(nil)
    }

    func goBack(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let engine else { return completionHandler(Self.gone) }
        engine.goBack()
        completionHandler(nil)
    }

    func goForward(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let engine else { return completionHandler(Self.gone) }
        engine.goForward()
        completionHandler(nil)
    }

    func activate(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let engine, let pane else { return completionHandler(Self.gone) }
        pane.activateTab(engine: engine)
        completionHandler(nil)
    }

    /// A pane has one selected tab, the one in front, so selecting is
    /// activating, and deselecting is not something it can do.
    func setSelected(
        _ selected: Bool, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        guard let engine, let pane else { return completionHandler(Self.gone) }
        if selected { pane.activateTab(engine: engine) }
        completionHandler(nil)
    }

    func duplicate(
        using configuration: WKWebExtension.TabConfiguration, for context: WKWebExtensionContext,
        completionHandler: @escaping ((any WKWebExtensionTab)?, (any Error)?) -> Void
    ) {
        guard let engine, let pane, let window else { return completionHandler(nil, Self.gone) }
        guard let made = pane.openTab(engine.url, inBackground: !configuration.shouldBeActive) else {
            return completionHandler(nil, Self.gone)
        }
        completionHandler(window.tab(for: made), nil)
    }

    func close(for context: WKWebExtensionContext, completionHandler: @escaping ((any Error)?) -> Void) {
        guard let engine, let pane else { return completionHandler(Self.gone) }
        pane.closeTab(engine: engine)
        completionHandler(nil)
    }

    /// A click on an extension's button grants it the page in front, as
    /// Chrome's `activeTab` does.
    func shouldGrantPermissionsOnUserGesture(for context: WKWebExtensionContext) -> Bool {
        true
    }

    private static let gone = SafariExtensionWindow.error("The tab is gone.")
}
