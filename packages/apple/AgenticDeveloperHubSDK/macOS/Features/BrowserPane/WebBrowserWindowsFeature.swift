//
//  WebBrowserWindowsFeature.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import os
import AgenticDeveloperHubSDKDatabase

/// File ▸ New Web Browser Window and New Private Web Browser Window: a
/// window with one browser in it (`WebBrowserWindowController`). The host
/// composes it once, after setting `WebBrowserWindowController.makePane`; the
/// items are hidden while there is no browser to build.
///
/// It also owns Show History, the command that brings up the History window
/// (`BrowserHistoryWindowController`), and registers that window with the
/// window manager so it comes back at launch as the other single windows do.
/// The host sets `BrowserHistoryWindowController.store` before composing it.
///
/// And it contributes the Browser menu (`BrowserMenuCommands`): Reload, Stop,
/// Back, Forward, Show History and Show / Hide Privacy Toolbar, for the key
/// window's browser pane, installing Back and Forward in the key command
/// registry under "Web Browser" so the person can rebind them.
///
/// It opens the hidden-items store (`BrowserHiddenItemsStore.current`) once,
/// at launch, for every pane to share.
@MainActor
public final class WebBrowserWindowsFeature: AppFeature {

    public enum CommandID {
        public static let newWindow = "browser.action.newWindow"
        public static let newPrivateWindow = "browser.action.newPrivateWindow"
        public static let showHistory = "browser.action.showHistory"
    }

    /// The Browser menu's items and Back / Forward's key commands.
    public let browserMenu: BrowserMenuCommands

    public init(
        commandRegistry registry: CommandRegistry,
        keyCommands: KeyCommandRegistry = .shared
    ) {
        browserMenu = BrowserMenuCommands(
            keyPane: { WebBrowserPaneViewController.keyPane() },
            showHistory: { BrowserHistoryWindowController.show() })
        super.init()
        Self.openHiddenItemsStore()
        keyCommands.install(BrowserMenuCommands.keySection)
        registry.register(AppCommand(
            id: CommandID.newWindow,
            title: "New Web Browser Window",
            category: "Browser",
            run: { _ = WebBrowserWindowController.openNew() }
        ))
        registry.register(AppCommand(
            id: CommandID.newPrivateWindow,
            title: "New Private Web Browser Window",
            category: "Browser",
            run: { _ = WebBrowserWindowController.openNew(purpose: .privateBrowsing) }
        ))
        // Enabled whatever the key window is: the History window opens a
        // visit in a new browser window when no browser pane is in front.
        registry.register(AppCommand(
            id: CommandID.showHistory,
            title: "Show History",
            category: "Browser",
            run: { BrowserHistoryWindowController.show() }
        ))
        WindowManager.shared.register(id: BrowserHistoryWindowController.windowID) {
            _ = BrowserHistoryWindowController.shared()
        }
        menuContributions = [
            MenuContribution(
                slot: .fileNew, title: "New Web Browser",
                commandID: CommandID.newWindow, registry: registry,
                order: 20,
                isHidden: { !WebBrowserWindowController.canOpen }
            ),
            MenuContribution(
                slot: .fileNew, title: "New Private Web Browser",
                commandID: CommandID.newPrivateWindow, registry: registry,
                order: 21,
                isHidden: { !WebBrowserWindowController.canOpen }
            )
        ] + browserMenu.contributions()
    }

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserHiddenItems")

    /// Opens `BrowserHiddenItems.db` in the app home (following
    /// `APP_TEST_HOME`) off the main thread, unless a host or test already
    /// set one. A file that cannot be opened leaves `current` nil, which every
    /// consumer takes as "no store": a degraded mode, not a launch failure.
    private static func openHiddenItemsStore() {
        guard !BrowserHiddenItemsStore.hasCurrent else { return }
        let logger = logger
        BrowserHiddenItemsStore.openCurrent(at: BrowserHiddenItemsStore.defaultURL) { error in
            logger.error("hidden-items store unavailable: \(error.localizedDescription, privacy: .public)")
        }
    }
}
