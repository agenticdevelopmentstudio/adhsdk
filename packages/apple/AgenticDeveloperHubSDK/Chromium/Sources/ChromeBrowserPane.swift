//
//  ChromeBrowserPane.swift
//  AgenticDeveloperHubSDKChromium
//

import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS

/// The Chrome Web Browser pane: a `WebBrowserPaneViewController` over
/// Chromium. Everything but the engine is the base class's, so it behaves as
/// the Safari pane does — address bar, history, restoration, automation.
@MainActor
public final class ChromeBrowserPaneViewController: WebBrowserPaneViewController {

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = WebBrowserPaneViewController.blankPage
    ) {
        super.init(
            engine: ChromiumBrowserEngine(settings: settings),
            engineKind: .chrome,
            minimizedSymbol: "globe",
            store: store,
            settings: settings,
            history: history,
            homeURL: homeURL
        )
    }
}

extension ComposableTabsViewID {
    /// A pane holding the Chrome Web Browser. Persisted in `layout_nodes`, so
    /// it is a storage format: changing it orphans every saved layout that
    /// holds one.
    public static let chromeBrowser = ComposableTabsViewID("browser.chrome")
}

extension ComposableTabsViewRegistry {

    /// Registers the Chrome Web Browser pane, the Safari pane's twin over
    /// Chromium. A host that links this framework calls it beside
    /// `registerBrowser(preferredAxis:)`; one that does not never ships
    /// Chromium.
    ///
    /// Its panes keep their state under their own prefix, so a Safari pane and
    /// a Chrome pane never read each other's remembered address.
    @MainActor
    public func registerChromeBrowser(
        preferredAxis: ComposableTabsAxis,
        homeURL: URL = WebBrowserPaneViewController.blankPage,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil
    ) {
        register(
            .chromeBrowser,
            descriptor: .init(
                displayName: "Chrome Web Browser",
                symbolName: "globe",
                preferredAxis: preferredAxis,
                minimumThickness: 360
            )
        ) { context in
            ChromeBrowserPaneViewController(
                store: context.makeStateStore(prefix: "browser.chrome."),
                settings: settings,
                history: history,
                homeURL: homeURL
            )
        }
    }
}
