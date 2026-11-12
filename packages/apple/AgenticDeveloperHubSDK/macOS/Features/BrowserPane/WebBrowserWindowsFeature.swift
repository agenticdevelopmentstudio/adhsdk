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
@MainActor
public final class WebBrowserWindowsFeature: AppFeature {

    public enum CommandID {
        public static let newWindow = "browser.action.newWindow"
        public static let newPrivateWindow = "browser.action.newPrivateWindow"
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
