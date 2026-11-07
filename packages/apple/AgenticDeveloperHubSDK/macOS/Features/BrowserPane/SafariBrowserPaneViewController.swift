//
//  SafariBrowserPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit
import AgenticDeveloperHubSDKCore

/// The Safari Web Browser pane: a `WebBrowserPaneViewController` over WebKit.
@MainActor
public final class SafariBrowserPaneViewController: WebBrowserPaneViewController {

    private let webKitEngine: WebKitBrowserEngine

    /// The web view the page is in.
    public var webView: WKWebView { webKitEngine.webView }

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours. The app's shared
    ///     store by default; a test hands in an in-memory one.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = WebBrowserPaneViewController.blankPage
    ) {
        let engine = WebKitBrowserEngine(settings: settings)
        self.webKitEngine = engine
        super.init(
            engine: engine,
            engineKind: .safari,
            minimizedSymbol: "safari",
            store: store,
            settings: settings,
            history: history,
            homeURL: homeURL
        )
    }
}
