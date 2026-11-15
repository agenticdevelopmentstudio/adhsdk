//
//  WebBrowserWindowController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AppKit
import os

private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "WebBrowserWindow")

/// A window holding one web browser and nothing else: File ▸ New Web Browser,
/// and the window Get Extensions… opens the Chrome Web Store in.
///
/// The browser is a whole browser pane (its tabs, Chrome's toolbar, its
/// settings), so the window adds only what a pane in a project window gets
/// from that window: the integrated title bar a project window wears and the
/// window's title following the page in front. The pane's settings are
/// behind its own browser menu, at the end of its address row.
///
/// The pane belongs to no project, so it is on the global jar unless the
/// shared settings say otherwise, and it keeps nothing once its window
/// closes: its state store is in memory, and each window is a new one
/// (`windowID` is unique), so no frame or visibility is saved for it either.
/// What is kept is one frame for them all, the last one a browser window was
/// put at, where the next one opens (`lastFrameID`).
@MainActor
public final class WebBrowserWindowController: SingleWindowController {

    /// What a window is for. Get Extensions… looks for the window it opened
    /// before and brings that one forward rather than opening another.
    public enum Purpose: Sendable, Equatable {
        /// File ▸ New Web Browser Window.
        case browsing
        /// File ▸ New Private Web Browser Window: private browsing on for
        /// this window alone, whatever the shared setting says.
        case privateBrowsing
        /// The Chrome Web Store, for installing extensions in the global jar.
        case extensions
        /// The Chrome Web Store in a Safari pane, for installing the global
        /// jar's Safari extensions (`SafariExtensionHost`), which only a
        /// Safari pane's Add Extension button can install. Its pages (an
        /// extension's options) open there too, since only WebKit can show them.
        case safariExtensions

        var isExtensions: Bool { self == .extensions || self == .safariExtensions }
    }

    /// Builds the browser a window shows, over the state store and the
    /// settings the window made for it. The host sets it (the Chromium
    /// framework's `ChromeBrowserPaneViewController.standaloneFactory`), since
    /// this tier cannot build a Chrome pane itself; `nil` disables every
    /// way of opening a window.
    public static var makePane: ((PaneStateStore, SettingsStore) -> WebBrowserPaneViewController)?

    /// Whether a window can be opened at all: a host has said how to build
    /// the browser.
    public static var canOpen: Bool { makePane != nil }

    /// The windows open now, oldest first. A window leaves on close.
    public private(set) static var openWindows: [WebBrowserWindowController] = []

    /// The browser the window shows.
    public let pane: WebBrowserPaneViewController
    public let purpose: Purpose

    private var backdropObserver: ThemePaletteObserver?
    private var spacingObservers: [UserSettingObserver<Int>] = []
    private let host: SafeAreaHostViewController
    /// The page above, and the browser log below it while it is showing.
    private let split = NSSplitViewController()
    private var logItem: NSSplitViewItem?

    /// The id the last browser window's frame is saved under, so a new one
    /// opens where the person last put one (cascaded off any window already
    /// on that spot). Each window's own `windowID` is unique and saves
    /// nothing; this one id is shared by them all, and goes through
    /// `WindowFrameManager` like any other window's frame: kept per screen
    /// set, namespaced per app copy (`WindowStateNamespace`), validated onto
    /// the screens attached now, and never written by a move the machine
    /// made rather than the person.
    static let lastFrameID = "web-browser.last-window"

    /// The spec every browser window opens with. The window's own copy does
    /// not persist its frame (its id is never asked for again); the copy
    /// registered under `lastFrameID` does.
    private static func spec(persistsFrame: Bool) -> WindowSpec {
        WindowSpec(
            defaultSize: NSSize(width: 1100, height: 760),
            minSize: NSSize(width: 480, height: 360),
            defaultPosition: .center,
            persistsFrame: persistsFrame,
            behavior: []
        )
    }

    private static let lastFrameSpec = spec(persistsFrame: true)

    static let windowIDPrefix = "web-browser"
    static let accessibilityWindowID = "web-browser.window"

    // MARK: - Opening

    /// Opens a new window, on `url` when given, else on the Home Page, and
    /// brings it forward. `nil`, logged, when no host has set `makePane`.
    /// `configure` writes the window's own settings before the browser is
    /// built, so construction-time keys (the storage jar) take effect too.
    @discardableResult
    public static func openNew(
        url: URL? = nil, purpose: Purpose = .browsing,
        configure: ((SettingsStore) -> Void)? = nil
    ) -> WebBrowserWindowController? {
        let build: (PaneStateStore, SettingsStore) -> WebBrowserPaneViewController
        if purpose == .safariExtensions {
            build = { SafariBrowserPaneViewController(store: $0, settings: $1) }
        } else if let makePane {
            build = makePane
        } else {
            logger.info("web browser window not opened: no browser to put in it")
            return nil
        }
        let store = EphemeralPaneStateStore()
        let settings = ComposableTabsViewRegistry.paneSettings(over: store, fallback: UserSettings.shared)
        if purpose.isExtensions {
            // The store installs into the jar the page is on, and the topic
            // that opened it manages the global one; a shared setting of
            // private browsing or a pane jar would install somewhere else, or
            // nowhere at all.
            settings.set(BrowserStorageJar.global, for: UserSettings.browserPrivacyStorageJar)
            settings.set(false, for: UserSettings.browserPrivateBrowsing)
        }
        if purpose == .privateBrowsing {
            settings.set(true, for: UserSettings.browserPrivateBrowsing)
        }
        configure?(settings)
        let controller = WebBrowserWindowController(pane: build(store, settings), purpose: purpose)
        openWindows.append(controller)
        controller.showWindow()
        if let url { controller.pane.load(url) }
        return controller
    }

    /// Opens `url` in the extensions window: brings the open one forward —
    /// on its own page when `url` is the store, which it is already showing
    /// or was moved away from by the person using it, else in a new tab of
    /// it — or opens one on `url`. Returns whether the page is showing.
    @discardableResult
    public static func showExtensions(_ url: URL, store: URL, purpose: Purpose = .extensions) -> Bool {
        guard let existing = openWindows.first(where: { $0.purpose == purpose }) else {
            return openNew(url: url, purpose: purpose) != nil
        }
        if url != store { existing.pane.openInNewTab(url) }
        existing.showWindow()
        existing.window?.makeKeyAndOrderFront(nil)
        return true
    }

    // MARK: - Lifecycle

    private init(pane: WebBrowserPaneViewController, purpose: Purpose) {
        self.pane = pane
        self.purpose = purpose
        split.splitView.isVertical = false
        split.splitView.dividerStyle = .thin
        let pageItem = NSSplitViewItem(viewController: pane)
        pageItem.minimumThickness = 160
        pageItem.holdingPriority = .defaultLow
        split.addSplitViewItem(pageItem)
        let host = SafeAreaHostViewController(child: split, pinsToSafeArea: true)
        self.host = host
        super.init(
            windowID: "\(Self.windowIDPrefix)-\(UUID().uuidString)",
            contentViewController: host)
        applySpacing()
        spacingObservers = PaneSpacing.edgeSettings.values.map { setting in
            UserSettingObserver(setting) { [weak self] _ in self?.applySpacing() }
        }
        windowTitle = pane.paneTitle
        windowStyleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        windowSpec = Self.spec(persistsFrame: false)
        WindowManager.shared.frames.register(id: Self.lastFrameID, spec: Self.lastFrameSpec)
        accessibilityIdentifier = Self.accessibilityWindowID
        pane.onPaneTitleChange = { [weak self] in
            self?.refreshTitle()
        }
        pane.onShowBrowserLog = { [weak self] _ in self?.toggleBrowserLog() }
    }

    /// Shows the browser log as a panel under the page, or hides it again.
    func toggleBrowserLog() {
        if let logItem {
            split.removeSplitViewItem(logItem)
            self.logItem = nil
            return
        }
        let item = NSSplitViewItem(viewController: BrowserLogPaneViewController(following: pane))
        item.minimumThickness = 120
        item.holdingPriority = .defaultLow + 1
        split.addSplitViewItem(item)
        logItem = item
        let height = split.splitView.bounds.height
        split.splitView.setPosition(max(160, height - 240), ofDividerAt: 0)
    }

    /// The browser's icon before the page's name, as a pane's title bar shows
    /// them.
    private let titleAccessory = WindowTitlebarTitle()

    private func refreshTitle() {
        titleAccessory.icon = pane.paneIcon
        // Both names come through the pane's privacy words, as its own
        // chrome shows them.
        let prefix = purpose == .privateBrowsing ? "Private Web" : "Web"
        let text = "\(prefix): \(pane.paneSiteTitle ?? pane.paneTitle)"
        titleAccessory.text = text
        window?.title = text
    }

    public override func configureWindow(_ window: NSWindow) {
        WindowTitlebarAccessory.applyIntegratedTitlebar(to: window)
        // The clear title bar shows the window's own background, so it
        // follows the theme as a project window's does.
        backdropObserver = ThemePaletteObserver { [weak window] palette in
            window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
        }
        titleAccessory.install(in: window)
        refreshTitle()
    }

    /// The least room left between the page and the window's sides and
    /// bottom. Chrome draws the page in a child window over the pane, and a
    /// child window takes the mouse at the parent's edges, so a page flush
    /// with them leaves nothing to resize the window by.
    static let resizeMargin: CGFloat = 4

    /// The room project windows keep around their panes (Settings >
    /// Appearance > Spacing), so the browser sits in its window as a pane
    /// does, and never less than `resizeMargin` at a resizable edge.
    private func applySpacing() {
        let spacing = PaneSpacing.contentInsets
        host.insets = NSEdgeInsets(
            top: spacing.top,
            left: max(spacing.left, Self.resizeMargin),
            bottom: max(spacing.bottom, Self.resizeMargin),
            right: max(spacing.right, Self.resizeMargin))
    }

    /// A new window opens where the last browser window was put, else on the
    /// browser window in front, and then steps down and to the right past
    /// every open browser window already on that spot, so it never lands
    /// exactly on top of one: the third window opened without moving
    /// anything lands past the second, not on it.
    public override func placeWindowWithoutSavedFrame(_ window: NSWindow) {
        let others = Self.openWindows.compactMap { $0 !== self && $0.isVisible ? $0.window : nil }
        if let saved = WindowManager.shared.frames.savedFrame(for: Self.lastFrameID, spec: Self.lastFrameSpec) {
            window.setFrame(saved, display: false)
        } else if let front = others.last {
            window.setFrame(front.frame, display: false)
        } else {
            return
        }
        func topLeft(_ frame: NSRect) -> NSPoint { NSPoint(x: frame.minX, y: frame.maxY) }
        // One step per window at most: a step the screen's edge refuses
        // leaves the window where it is, and the loop must still end.
        for _ in others.indices {
            guard others.contains(where: { topLeft($0.frame) == topLeft(window.frame) }) else { break }
            // The first call puts this window's top left where it already
            // is and answers the next cascade step; the second moves it there.
            let next = window.cascadeTopLeft(from: topLeft(window.frame))
            window.cascadeTopLeft(from: next)
        }
    }

    public override func windowDidMove(_ notification: Notification) {
        super.windowDidMove(notification)
        rememberFrame()
    }

    public override func windowDidResize(_ notification: Notification) {
        super.windowDidResize(notification)
        rememberFrame()
    }

    /// Saves the frame as the one the next browser window opens at. A
    /// minimised or full-screen window's frame is not one to open another at.
    private func rememberFrame() {
        guard let window, window.isVisible, !window.isMiniaturized,
              !window.styleMask.contains(.fullScreen) else { return }
        WindowManager.shared.frames.saveFrame(for: window, id: Self.lastFrameID)
    }

    public override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        pane.paneContentWillBeDiscarded()
        Self.openWindows.removeAll { $0 === self }
        // Unique to this window, so nothing will ask for it again.
        WindowManager.shared.forgetOneOffWindow(self)
    }
}
