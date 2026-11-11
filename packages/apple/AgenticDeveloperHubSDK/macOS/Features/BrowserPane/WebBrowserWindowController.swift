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
/// from that window: the integrated title bar a project window wears, the
/// pane's settings behind a gear at the right of it, and the window's title
/// following the page in front.
///
/// The pane belongs to no project, so it is on the global jar unless the
/// shared settings say otherwise, and it keeps nothing once its window
/// closes: its state store is in memory, and each window is a new one
/// (`windowID` is unique), so no frame or visibility is saved for it either.
@MainActor
public final class WebBrowserWindowController: SingleWindowController {

    /// What a window is for. Get Extensions… looks for the window it opened
    /// before and brings that one forward rather than opening another.
    public enum Purpose: Sendable, Equatable {
        /// File ▸ New Web Browser.
        case browsing
        /// The Chrome Web Store, for installing extensions in the global jar.
        case extensions
        /// The Chrome Web Store in a Safari pane, for installing the global
        /// jar's Safari extensions (`SafariExtensionHost`), which only a
        /// Safari pane's Add Extension button can install. Its pages (an
        /// extension's options) open there too, since only WebKit can show them.
        case safariExtensions

        var isExtensions: Bool { self != .browsing }
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

    static let windowIDPrefix = "web-browser"
    static let accessibilityWindowID = "web-browser.window"
    static let settingsButtonID = "web-browser.settings-button"

    // MARK: - Opening

    /// Opens a new window, on `url` when given, else on the Home Page, and
    /// brings it forward. `nil`, logged, when no host has set `makePane`.
    @discardableResult
    public static func openNew(url: URL? = nil, purpose: Purpose = .browsing) -> WebBrowserWindowController? {
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
        let host = SafeAreaHostViewController(child: pane, pinsToSafeArea: true)
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
        windowSpec = WindowSpec(
            defaultSize: NSSize(width: 1100, height: 760),
            minSize: NSSize(width: 480, height: 360),
            defaultPosition: .center,
            persistsFrame: false,
            behavior: []
        )
        accessibilityIdentifier = Self.accessibilityWindowID
        pane.onPaneTitleChange = { [weak self] in
            self?.refreshTitle()
        }
    }

    /// The browser's icon before the page's name, as a pane's title bar shows
    /// them.
    private let titleAccessory = WindowTitlebarTitle()

    private func refreshTitle() {
        titleAccessory.icon = pane.paneIcon
        titleAccessory.text = pane.paneTitle
    }

    public override func configureWindow(_ window: NSWindow) {
        WindowTitlebarAccessory.applyIntegratedTitlebar(to: window)
        // The clear title bar shows the window's own background, so it
        // follows the theme as a project window's does.
        backdropObserver = ThemePaletteObserver { [weak window] palette in
            window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
        }
        let gear = WindowTitlebarAccessory.makeButton(
            symbolName: "gearshape",
            description: "Browser Settings",
            toolTip: "Settings for this browser",
            target: self,
            action: #selector(showSettings))
        gear.setAccessibilityIdentifier(Self.settingsButtonID)
        WindowTitlebarAccessory.install([gear], in: window)
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

    /// A new window opens down and to the right of the browser window in
    /// front, so it never lands exactly on top of one.
    public override func placeWindowWithoutSavedFrame(_ window: NSWindow) {
        guard let front = Self.openWindows.last(where: { $0 !== self && $0.isVisible })?.window else { return }
        window.setFrame(NSRect(origin: window.frame.origin, size: front.frame.size), display: false)
        let topLeft = window.cascadeTopLeft(from: NSPoint(x: front.frame.minX, y: front.frame.maxY))
        window.cascadeTopLeft(from: topLeft)
    }

    @objc func showSettings() {
        pane.showPaneSettings()
    }

    public override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        pane.paneContentWillBeDiscarded()
        Self.openWindows.removeAll { $0 === self }
        // Unique to this window, so nothing will ask for it again.
        windowSpec = nil
    }
}
