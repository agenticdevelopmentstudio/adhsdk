//
//  WebBrowserWindowsFeature.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit

/// File ▸ New Web Browser Window and New Private Web Browser Window: a
/// window with one browser in it (`WebBrowserWindowController`). The host
/// composes it once, after setting `WebBrowserWindowController.makePane`; the
/// items are hidden while there is no browser to build.
///
/// It also owns Show History, the command that brings up the History window
/// (`BrowserHistoryWindowController`), and registers that window with the
/// window manager so it comes back at launch as the other single windows do.
/// The host sets `BrowserHistoryWindowController.store` before composing it.
@MainActor
public final class WebBrowserWindowsFeature: AppFeature {

    public enum CommandID {
        public static let newWindow = "browser.action.newWindow"
        public static let newPrivateWindow = "browser.action.newPrivateWindow"
        public static let showHistory = "browser.action.showHistory"
    }

    public init(commandRegistry registry: CommandRegistry) {
        super.init()
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
        ]
    }
}
