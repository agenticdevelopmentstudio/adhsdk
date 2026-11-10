//
//  ChromeBrowserPane.swift
//  AgenticDeveloperHubSDKChromium
//

import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS

/// The Chrome Web Browser pane: a `WebBrowserPaneViewController` over
/// Chromium. Everything but the engine, privacy included, is the base
/// class's, so it behaves as the Safari pane does — address bar, history,
/// restoration, automation, jars, the input gate and the activation shield.
@MainActor
public final class ChromeBrowserPaneViewController: WebBrowserPaneViewController {

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    ///   - context: The project, worktree and node the pane belongs to.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = WebBrowserPaneViewController.blankPage,
        context: BrowserPaneContext = .detached
    ) {
        ChromiumLauncher.registerJarStores()
        super.init(
            makeEngine: { ChromiumBrowserEngine(configuration: $0) },
            engineKind: .chrome,
            minimizedSymbol: "globe",
            store: store,
            settings: settings,
            history: history,
            homeURL: homeURL,
            context: context
        )
        engineMaintenance = ChromiumMaintenance(settings: settings)
    }

    /// What a host gives `WebBrowserWindowController.makePane` so its
    /// windows hold Chrome: a pane that belongs to no project, recording
    /// visits in `history`.
    public static func standaloneFactory(
        history: BrowserHistoryStore?
    ) -> (PaneStateStore, SettingsStore) -> WebBrowserPaneViewController {
        { store, settings in
            let pane = ChromeBrowserPaneViewController(store: store, settings: settings, history: history)
            #if DEBUG
            pane.onShowBrowserLog = { BrowserLogPaneViewController.show(for: $0) }
            #endif
            return pane
        }
    }
}

extension ComposableTabsViewRegistry {

    /// Registers the Chrome Web Browser pane, the Safari pane's twin over
    /// Chromium. A host that links this framework calls it beside
    /// `registerBrowser(preferredAxis:)`; one that does not never ships
    /// Chromium.
    ///
    /// Its panes keep their state under their own prefix, so a Safari pane and
    /// a Chrome pane never read each other's remembered address; their
    /// per-pane settings sit on that state the way the Safari pane's do.
    @MainActor
    public func registerChromeBrowser(
        preferredAxis: ComposableTabsAxis,
        homeURL: URL = WebBrowserPaneViewController.blankPage,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        privacyVault: PrivacyWordsVault? = nil
    ) {
        ChromiumLauncher.registerJarStores()
        register(
            .chromeBrowser,
            descriptor: .init(
                displayName: "Chrome Web Browser",
                symbolName: "globe",
                preferredAxis: preferredAxis,
                minimumThickness: 360
            )
        ) { context in
            let state = context.makeStateStore(prefix: Self.chromeBrowserStatePrefix)
            let pane = ChromeBrowserPaneViewController(
                store: state,
                settings: Self.paneSettings(over: state, fallback: settings),
                history: history,
                homeURL: homeURL,
                context: BrowserPaneContext(paneContext: context)
            )
            // The private terminals' words, for the pane's Agent Privacy.
            pane.privacyVault = privacyVault
            #if DEBUG
            pane.onShowBrowserLog = { BrowserLogPaneViewController.show(for: $0) }
            #endif
            return pane
        }
    }
}
