//
//  WebBrowserWindowsFeature.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit

/// File ▸ New Web Browser: a window with one browser in it
/// (`WebBrowserWindowController`). The host composes it once, after setting
/// `WebBrowserWindowController.makePane`; the item is hidden while there is
/// no browser to build.
@MainActor
public final class WebBrowserWindowsFeature: AppFeature {

    public enum CommandID {
        public static let newWindow = "browser.action.newWindow"
    }

    public init(commandRegistry registry: CommandRegistry) {
        super.init()
        registry.register(AppCommand(
            id: CommandID.newWindow,
            title: "New Web Browser",
            category: "Browser",
            run: { _ = WebBrowserWindowController.openNew() }
        ))
        menuContributions = [
            MenuContribution(
                slot: .file, title: "New Web Browser",
                commandID: CommandID.newWindow, registry: registry,
                order: 20,
                isHidden: { !WebBrowserWindowController.canOpen }
            )
        ]
    }
}
