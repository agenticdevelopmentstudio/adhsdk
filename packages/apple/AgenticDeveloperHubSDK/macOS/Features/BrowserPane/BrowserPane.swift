//
//  BrowserPane.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore

extension ComposableTabsViewID {
    /// A pane holding the Safari Web Browser. It was the only browser when
    /// this was named, which is why it is not "browser.safari". The raw value
    /// is persisted in `layout_nodes`, so it is a storage format: changing it
    /// orphans every saved layout that holds one.
    public static let browser = ComposableTabsViewID("browser")
}

extension ComposableTabsViewRegistry {

    /// Registers the Safari Web Browser pane: an address bar over WebKit,
    /// reopening on the page it was last on.
    ///
    /// The same shape as `registerTerminal(preferredAxis:)`, so a host adds a
    /// browser the way it adds a shell — one call, no factory to write.
    ///
    /// - Parameters:
    ///   - preferredAxis: Which way the Split menu proposes adding another
    ///     browser. Side by side suits a pane that wants width.
    ///   - homeURL: What a fresh pane opens on when the Home Page setting is
    ///     blank. Blank by default: the address field is right there, and a
    ///     start page is a choice the host or the user makes.
    ///   - settings: The browser settings every pane honours. The app's
    ///     shared store by default — the same one the settings panel edits.
    ///   - history: Where panes record visits; `nil` records nothing. The
    ///     host hands the same store to `BrowserSettingsPanelViewController`,
    ///     so the panel lists what the panes wrote.
    @MainActor
    public func registerBrowser(
        preferredAxis: ComposableTabsAxis,
        homeURL: URL = WebBrowserPaneViewController.blankPage,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil
    ) {
        register(
            .browser,
            descriptor: .init(
                displayName: "Safari Web Browser",
                symbolName: "safari",
                preferredAxis: preferredAxis,
                // Room for the address bar's three buttons plus an address
                // worth reading, and for a page laid out for a narrow window.
                minimumThickness: 360
            )
        ) { context in
            let state = context.makeStateStore(prefix: "browser.")
            // Each pane answers from its own overrides first, then from the
            // shared settings, so one pane's zoom never moves another's.
            let layered = LayeredSettingsStore(
                overrides: PaneStateSettingsStorageProvider(store: state),
                fallback: settings
            )
            return BrowserPaneViewController(
                store: state,
                settings: layered,
                history: history,
                homeURL: homeURL,
                context: BrowserPaneContext(
                    paneNodeID: context.nodeID,
                    projectID: context.project.id,
                    projectName: context.project.displayName,
                    worktreePath: context.workingDirectory.standardizedFileURL.path
                )
            )
        }
    }
}
