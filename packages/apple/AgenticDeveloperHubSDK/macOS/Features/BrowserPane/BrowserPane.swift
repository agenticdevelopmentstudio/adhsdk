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

    /// A pane showing one browser pane's event log. Registered only in debug
    /// builds. Persisted in `layout_nodes` like every view id, so a storage
    /// format too.
    public static let browserLog = ComposableTabsViewID("browser-log")

    /// A pane holding the Chrome Web Browser. Declared here rather than
    /// beside the Chromium pane because the jar reconciler, which knows
    /// nothing of Chromium, has to find every browser pane in a saved layout.
    /// Persisted in `layout_nodes`, so a storage format.
    public static let chromeBrowser = ComposableTabsViewID("browser.chrome")
}

extension BrowserEngineKind {
    /// The view id a pane on this engine is saved under.
    public var viewID: ComposableTabsViewID {
        switch self {
        case .safari: .browser
        case .chrome: .chromeBrowser
        }
    }

    /// The prefix a pane on this engine files its state under. Storage
    /// format: the jar reconciler reads a closed pane's storage-jar override
    /// from the database by it.
    public nonisolated var statePrefix: String {
        switch self {
        case .safari: ComposableTabsViewRegistry.browserStatePrefix
        case .chrome: ComposableTabsViewRegistry.chromeBrowserStatePrefix
        }
    }
}

extension ComposableTabsViewRegistry {

    /// The prefix every Safari browser pane files its state under. Storage
    /// format, like the view id: the jar reconciler reads a closed pane's
    /// storage-jar override from the database by it, so the two must spell
    /// it once.
    public nonisolated static let browserStatePrefix = "browser."

    /// The prefix the debug Browser Log pane files its state under.
    public nonisolated static let browserLogStatePrefix = "browser-log."

    /// The prefix every Chrome browser pane files its state under, for the
    /// same reason as `browserStatePrefix`.
    public nonisolated static let chromeBrowserStatePrefix = "browser.chrome."

    /// The settings one browser pane answers from: its own overrides first,
    /// then the shared settings, so one pane's zoom never moves another's.
    /// Every engine's pane is built over the same shape, so the settings
    /// sheet and the reconciler read either the same way.
    public static func paneSettings(over state: PaneStateStore, fallback: SettingsStore) -> SettingsStore {
        LayeredSettingsStore(overrides: PaneStateSettingsStorageProvider(store: state), fallback: fallback)
    }

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
            let state = context.makeStateStore(prefix: Self.browserStatePrefix)
            let pane = SafariBrowserPaneViewController(
                store: state,
                settings: Self.paneSettings(over: state, fallback: settings),
                history: history,
                homeURL: homeURL,
                context: BrowserPaneContext(paneContext: context)
            )
            #if DEBUG
            pane.onShowBrowserLog = { BrowserLogPaneViewController.show(for: $0) }
            #endif
            return pane
        }
        // The project settings sheet's Cookies and Site Data topic. Jars
        // live in the project's own database, in the registry every browser
        // pane over it shares, so the topic needs nothing else.
        registerProjectSettingsTopic(for: .browser) { project in
            ProjectBrowserJarsSettingsPanel(jars: ProjectBrowserJars(
                provider: BrowserJarRegistry.shared(for: project.database),
                repoID: project.id
            ))
        }
        #if DEBUG
        registerBrowserLog(preferredAxis: preferredAxis)
        #endif
    }

    /// Registers the debug-only Browser Log pane, which follows one browser
    /// pane's event log (spec section 12). Show Browser Log opens it beside
    /// its browser pane; the host's layout spec must allow `.browserLog`
    /// there for the split to happen.
    @MainActor
    func registerBrowserLog(preferredAxis: ComposableTabsAxis) {
        register(
            .browserLog,
            descriptor: .init(
                displayName: "Browser Log",
                symbolName: "list.bullet.rectangle",
                preferredAxis: preferredAxis,
                minimumThickness: 240
            )
        ) { context in
            BrowserLogPaneViewController(store: context.makeStateStore(prefix: Self.browserLogStatePrefix))
        }
    }
}

extension BrowserPaneContext {
    /// The context of a browser pane a project window lays out: its node,
    /// its project, the tab's worktree, and the jar registry over the
    /// project's database — one registry per database, so the reconciler
    /// sees every jar held by every window's panes.
    @MainActor
    public init(paneContext context: ComposableTabsViewContext) {
        self.init(
            paneNodeID: context.nodeID,
            projectID: context.project.id,
            projectName: context.project.displayName,
            worktreePath: context.workingDirectory.standardizedFileURL.path,
            jars: BrowserJarRegistry.shared(for: context.project.database)
        )
    }
}
