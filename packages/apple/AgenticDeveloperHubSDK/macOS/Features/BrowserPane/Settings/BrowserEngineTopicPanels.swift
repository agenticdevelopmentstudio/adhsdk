//
//  BrowserEngineTopicPanels.swift
//  AgenticDeveloperHubSDK
//
//  The two topics of the Web Browser panel that belong to one engine each:
//  Safari (WebKit) and Chrome (Chromium). Everything else in the panel
//  applies to both. Both bind through the panel's `BrowserSettingsBinding`,
//  so a pane's sheet shows its own engine's topic as overridable rows.
//

import AppKit
import WebKit

import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore

/// What the Chrome topic needs from the Chromium engine without linking it.
///
/// The settings panel lives in the macOS framework and Chromium in a tier
/// above it, so the host that links both hands this in
/// (`dependency-injection`, `manage-complexity-through-boundaries`). With
/// none, the Settings window has no Chrome topic, because there is no Chrome
/// to set.
@MainActor
public protocol BrowserEngineMaintenance: AnyObject {
    /// The engine's own version, as the Chrome topic shows it.
    var engineVersion: String { get }
    /// Removes every cookie Chrome panes on the global jar have kept.
    func removeAllCookies() async

    // MARK: Extensions

    /// The extensions installed in `profile`, enabled or not.
    func extensions(in profile: BrowserExtensionProfile) async throws -> [BrowserExtension]
    func setExtension(_ id: String, enabled: Bool, in profile: BrowserExtensionProfile) async throws
    /// Uninstalls `id` from `profile`, without Chrome's confirmation dialog:
    /// asking first is the caller's.
    func removeExtension(_ id: String, in profile: BrowserExtensionProfile) async throws
    /// Asks Chrome to update every extension in `profile` now, rather than
    /// at its next scheduled check.
    func checkForExtensionUpdates(in profile: BrowserExtensionProfile) async throws
    /// Closes the hidden management browsers. The topic calls it when it closes.
    func endExtensionManagement()
}

// MARK: - Safari

@MainActor
final class SafariBrowserTopicPanel: BrowserTopicPanel {

    private let siteData: BrowserSiteData
    private var table: ComposableSettings.EditableTableCard?
    private var records: [WKWebsiteDataRecord] = []
    /// The read in flight. One at a time: a Refresh pressed twice, or a
    /// removal landing while a read is out, must not let the older answer
    /// arrive last and show rows that are already gone.
    private var reloadTask: Task<Void, Never>?

    /// - Parameter siteData: the global jar's store in the Settings window;
    ///   in a Safari pane's sheet, the store the pane's web view is on.
    init(siteData: BrowserSiteData, binding: BrowserSettingsBinding) {
        self.siteData = siteData
        super.init(title: "Safari", symbol: "safari", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Safari",
                body: "Settings only Safari Web Browser panes have, because only WebKit "
                    + "offers them. Chrome panes ignore everything here."
            ),
            .init(
                title: "Protection",
                body: "Warn about fraudulent websites asks WebKit to check each page "
                    + "against Apple's list of known phishing and malware sites and show "
                    + "a warning page in place of a match. Upgrade to HTTPS loads a site "
                    + "WebKit knows supports HTTPS over HTTPS even when the address said "
                    + "http; WebKit fixes it when a pane's web view is made. "
                    + "Lockdown Mode is the same restricted mode Safari offers: certain "
                    + "web technologies, fonts and media formats are refused, which "
                    + "breaks some sites in exchange for a smaller attack surface. It "
                    + "applies to the next page each pane loads."
            ),
            .init(
                title: "Media",
                body: "Allow AirPlay lets a page's video offer the AirPlay control. It is "
                    + "fixed when a Safari pane's web view is made: in the Settings window "
                    + "it applies to panes opened after the change, and in a pane's "
                    + "settings when the sheet closes."
            ),
            .init(
                title: "Web Inspector",
                body: "Safari's Web Inspector, attached to a Safari pane's page. With it "
                    + "on, right-click a page and choose Inspect Element, or open Safari's "
                    + "Develop menu and find this app under your Mac's name. Off is the "
                    + "default because an inspectable page is one any process with "
                    + "Safari's privileges can read."
            ),
            .init(
                title: "Site Data",
                body: (binding.isPaneScope
                    ? "Everything WebKit is keeping for sites in this pane's jar, named in "
                        + "the Cookies topic's title: all browser panes, this worktree's "
                        + "panes, or this pane alone. "
                    : "Everything WebKit is keeping in the global jar, the one shared by "
                        + "every Safari pane that follows it; the jars of a worktree or a "
                        + "single pane are listed in the Coding Project window's settings. ")
                    + "One row per site: cookies, local storage, caches, service workers "
                    + "and the rest, named in the second column. Select a site and press "
                    + "− to remove what it kept, which signs you out of it. Remove All "
                    + "clears every site at once. Refresh re-reads the list, since pages "
                    + "write while it is open. Browsing history is separate and has its "
                    + "own topic."
            ),
            .init(
                title: "What Is Not Here",
                body: "There is no Do Not Track switch, because WebKit sends no such "
                    + "header and the sites that honoured it have largely stopped. "
                    + "Passwords are not saved by the browser pane; the system keychain "
                    + "is not involved. What a page can see of you (keyboard, mouse, "
                    + "focus, the agent, cookie jars and third-party scripts) is in "
                    + "Privacy."
            )
        ])
    }

    static let keywords: [String] = [
        "safari", "webkit", "privacy", "security", "fraud", "phishing", "https", "lockdown mode", "tracking",
        "airplay", "web inspector", "inspect element", "site data", "local storage", "cache"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeProtectionGroup())
        settingsView.addGroup(makeMediaGroup())
        settingsView.addGroup(makeInspectorGroup())
        let table = makeTable()
        self.table = table
        settingsView.addGroup(table)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    /// When a setting WebKit fixes at construction takes effect: in a pane's
    /// sheet the binding says; in the Settings window, Safari panes opened
    /// after the change.
    private func constructionNote(for key: String) -> String {
        binding.isPaneScope
            ? binding.constructionNote(for: key)
            : "Applies to Safari panes opened after the change."
    }

    private func makeProtectionGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Protection")

        let fraud = binding.model("Warn about fraudulent websites", UserSettings.browserFraudWarning)
        let fraudView = ComposableSettings.CheckboxView(with: fraud)
        _ = fraudView.toggle.accessibilityID("settings.browser.safari.fraud-warning")
        binding.add(fraudView, model: fraud, key: UserSettings.browserFraudWarning, to: group)

        let https = binding.model(
            "Upgrade known sites to HTTPS", UserSettings.browserUpgradesToHTTPS,
            explanation: constructionNote(for: UserSettings.browserUpgradesToHTTPS.name)
        )
        let httpsView = ComposableSettings.CheckboxView(with: https)
        _ = httpsView.toggle.accessibilityID("settings.browser.safari.upgrade-https")
        binding.add(httpsView, model: https, key: UserSettings.browserUpgradesToHTTPS, to: group)

        let lockdown = binding.model(
            "Lockdown Mode", UserSettings.browserLockdownMode,
            explanation: "Refuses some web technologies for a smaller attack surface. "
                + "Applies to the next page each pane loads."
        )
        let lockdownView = ComposableSettings.CheckboxView(with: lockdown)
        _ = lockdownView.toggle.accessibilityID("settings.browser.safari.lockdown")
        binding.add(lockdownView, model: lockdown, key: UserSettings.browserLockdownMode, to: group)

        return group
    }

    private func makeMediaGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Media")
        let airPlay = binding.model(
            "Allow AirPlay", UserSettings.browserAllowsAirPlay,
            explanation: constructionNote(for: UserSettings.browserAllowsAirPlay.name)
        )
        let airPlayView = ComposableSettings.CheckboxView(with: airPlay)
        _ = airPlayView.toggle.accessibilityID("settings.browser.safari.airplay")
        binding.add(airPlayView, model: airPlay, key: UserSettings.browserAllowsAirPlay, to: group)
        return group
    }

    private func makeInspectorGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Web Inspector")
        let inspector = binding.model(
            "Allow Web Inspector", UserSettings.browserWebInspectorEnabled,
            explanation: "Right-click a page and choose Inspect Element."
        )
        let inspectorView = ComposableSettings.CheckboxView(with: inspector)
        _ = inspectorView.toggle.accessibilityID("settings.browser.safari.inspector")
        binding.add(inspectorView, model: inspector, key: UserSettings.browserWebInspectorEnabled, to: group)
        return group
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Site Data",
            columns: [
                .init(id: "site", title: "Site", width: 220),
                .init(id: "kinds", title: "Data", width: 340)
            ],
            emptyMessage: "No site data stored.",
            visibleRows: 10,
            accessibilityPrefix: "settings.browser.safari.sites"
        )
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in
            guard let self, let record = self.records.first(where: { $0.displayName == rowID }) else { return }
            Task {
                await self.siteData.remove([record])
                self.reload()
            }
        }
        table.addFooterButton(
            title: "Remove All…", identifier: "settings.browser.safari.remove-all"
        ) { [weak self] in
            self?.removeAll()
        }
        table.addFooterButton(title: "Refresh", identifier: "settings.browser.safari.refresh") { [weak self] in
            self?.reload()
        }
        return table
    }

    private func removeAll() {
        ComposableSettings.Alerts.confirmDestructive(
            "Remove all Safari site data?",
            detail: (binding.isPaneScope
                ? "Cookies, caches and storage for every site in this jar are removed, and the panes on "
                    + "it are signed out of them. "
                : "Cookies, caches and storage for every site in the global jar are removed, and Safari "
                    + "panes on it are signed out everywhere. ")
                + "History and Chrome's data are not affected.",
            actionTitle: "Remove All",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task {
                await self.siteData.removeAll()
                self.reload()
            }
        }
    }

    private func reload() {
        reloadTask?.cancel()
        reloadTask = Task {
            let records = await siteData.records()
            guard !Task.isCancelled else { return }
            self.records = records
            table?.setRows(records.map { record in
                ComposableSettings.EditableTableRow(id: record.displayName, cells: [
                    "site": .text(record.displayName),
                    "kinds": .text(BrowserSiteData.labels(for: record))
                ])
            })
        }
    }
}

// MARK: - Chrome

@MainActor
final class ChromeBrowserTopicPanel: BrowserTopicPanel {

    /// `nil` in a Chrome pane's sheet when the host handed none in: the
    /// topic then has no version row.
    private let engine: BrowserEngineMaintenance?

    init(engine: BrowserEngineMaintenance?, binding: BrowserSettingsBinding) {
        self.engine = engine
        super.init(title: "Chrome", symbol: "globe", binding: binding)
    }

    /// Remove All Chrome Cookies empties the global jar, which a pane's
    /// sheet does not show, so it is offered in the Settings window only.
    private var offersCookieRemoval: Bool { engine != nil && !binding.isPaneScope }

    override var helpContent: ComposableSettings.PanelHelp? {
        var topics: [ComposableSettings.PanelHelp.Topic] = [
            .init(
                title: "Chrome",
                body: "Settings only Chrome Web Browser panes have, because only Chromium "
                    + "offers them. Safari panes ignore everything here. Chrome panes run "
                    + "the Chromium build shipped inside this app, not a copy of Google "
                    + "Chrome you may have installed, and share nothing with it."
            ),
            .init(
                title: "Developer Tools",
                body: "Allow developer tools adds Inspect Element to a Chrome pane's "
                    + "context menu, which opens Chromium's DevTools in a window of their "
                    + "own. Remote debugging port lets an outside tool (Chrome's own "
                    + "chrome://inspect, Playwright, Puppeteer) attach to Chrome panes "
                    + "over the DevTools protocol on that port of this Mac. Zero is off, "
                    + "the default, because anything on this Mac that can reach the port "
                    + "can read and drive every Chrome pane, whatever Privacy "
                    + "says. The port is read when Chromium starts, so a change applies "
                    + "the next time the app opens, and it is one setting for every "
                    + "Chrome pane."
            ),
            .init(
                title: "Performance",
                body: "Hardware acceleration draws pages with the graphics card. Turn it "
                    + "off only when Chrome panes draw wrongly or not at all. It is read "
                    + "when Chromium starts, so a change applies the next time the app "
                    + "opens, and it is one setting for every Chrome pane."
            )
        ]
        if offersCookieRemoval {
            topics.append(.init(
                title: "Site Data",
                body: "Remove All Chrome Cookies signs Chrome panes on the global jar out "
                    + "of every site. Safari's cookies, the browsing history and the jars "
                    + "of a worktree or a single pane are not affected: those are cleared "
                    + "in the project's settings, under Cookies and Site Data."
            ))
        }
        return ComposableSettings.PanelHelp(topics: topics)
    }

    static let keywords: [String] = [
        "chrome", "chromium", "devtools", "developer tools", "inspect element", "remote debugging",
        "debugging port", "hardware acceleration", "gpu", "chrome cookies"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeDeveloperGroup())
        settingsView.addGroup(makePerformanceGroup())
        if offersCookieRemoval { settingsView.addGroup(makeSiteDataGroup()) }
        if let engine { settingsView.addGroup(makeAboutGroup(engine)) }
    }

    private func makeDeveloperGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Developer Tools")

        let devTools = binding.model(
            "Allow developer tools", UserSettings.browserChromeDevToolsEnabled,
            explanation: "Right-click a page and choose Inspect Element."
        )
        let devToolsView = ComposableSettings.CheckboxView(with: devTools)
        _ = devToolsView.toggle.accessibilityID("settings.browser.chrome.devtools")
        binding.add(devToolsView, model: devTools, key: UserSettings.browserChromeDevToolsEnabled, to: group)

        let port = binding.range(
            "Remote debugging port", UserSettings.browserChromeRemoteDebuggingPort,
            bounds: BrowserSettings.chromeRemoteDebuggingPortRange,
            explanation: "Zero is off. Applies the next time the app opens."
        )
        let portView = ComposableSettings.IntegerFieldView(viewModel: port)
        _ = portView.textField.accessibilityID("settings.browser.chrome.remote-debugging-port")
        binding.add(portView, model: port, key: UserSettings.browserChromeRemoteDebuggingPort, to: group)

        return group
    }

    private func makePerformanceGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Performance")
        let acceleration = binding.model(
            "Use hardware acceleration", UserSettings.browserChromeHardwareAcceleration,
            explanation: "Applies the next time the app opens."
        )
        let accelerationView = ComposableSettings.CheckboxView(with: acceleration)
        _ = accelerationView.toggle.accessibilityID("settings.browser.chrome.hardware-acceleration")
        binding.add(
            accelerationView, model: acceleration, key: UserSettings.browserChromeHardwareAcceleration, to: group
        )
        return group
    }

    private func makeSiteDataGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Site Data")
        let remove = ComposableSettings.ButtonViewModel(title: "Remove All Chrome Cookies…") { [weak self] in
            self?.confirmRemoveCookies()
        }
        let removeView = ComposableSettings.ButtonView(viewModel: remove, placement: .leading)
        _ = removeView.button.accessibilityID("settings.browser.chrome.remove-cookies")
        binding.register(remove, as: "settings.browser.chrome.remove-cookies")
        group.addSettingSubview(removeView)
        return group
    }

    private func makeAboutGroup(_ engine: BrowserEngineMaintenance) -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "About")
        let version = ComposableSettings.ValueRowView(title: "Chromium", value: engine.engineVersion)
        _ = version.valueLabel.accessibilityID("settings.browser.chrome.version")
        group.addSettingSubview(version)
        return group
    }

    private func confirmRemoveCookies() {
        ComposableSettings.Alerts.confirmDestructive(
            "Remove all Chrome cookies?",
            detail: "Chrome panes on the global jar are signed out of every site. Safari's cookies and the "
                + "history are not affected.",
            actionTitle: "Remove All",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed, let engine = self.engine else { return }
            Task { await engine.removeAllCookies() }
        }
    }
}

// MARK: - Chrome extensions

/// The extensions installed in one Chrome profile, managed the way Chrome's
/// own extensions page manages them and through the same calls
/// (`native-controls`): turn one on or off, remove it, open its options, ask
/// for updates now, and (in the Settings window) how often Chrome checks.
/// Installing is the Chrome Web Store's own page, since only Chrome can
/// install from it: for the global jar, in a Web Browser window of its own
/// (one, brought forward when it is already open); for a worktree or pane
/// jar, in a new Chrome pane beside the destination pane, on that jar.
@MainActor
final class ChromeExtensionsTopicPanel: BrowserTopicPanel {

    static let identifier = "settings.browser.chrome.extensions"
    static let webStore = URL(string: "https://chromewebstore.google.com")!
    /// Empty, not absent: an empty list stays empty (no inline help text), but
    /// the card keeps its message label, which is where a failed read shows.
    private static let emptyMessage = ""

    private let engine: BrowserEngineMaintenance
    let profile: BrowserExtensionProfile
    /// The pane Options and Get Extensions… open beside, asked each time,
    /// since the pane last focused changes while the topic is up. `nil`
    /// disables both.
    private let destination: () -> WebBrowserPaneViewController?

    /// Opens a page for the destination pane: in a new Chrome pane split off
    /// beside it, on its jar, so the page it shows is left alone. A pane on a
    /// jar of its own is the only pane on that profile, so the page opens in
    /// it instead. Returns whether the page opened. A test records the call.
    var openPage: (WebBrowserPaneViewController, URL) -> Bool = { pane, url in
        guard pane.resolvedJar.jar != .pane else {
            pane.load(url)
            return true
        }
        return pane.openInNewPaneBeside(url) != nil
    }

    /// Whether `openPage` has somewhere to open a page for the pane: always
    /// for a pane on a jar of its own, otherwise only when its layout has
    /// room for another Chrome pane beside it. A test answers it directly.
    var canOpenPage: (WebBrowserPaneViewController) -> Bool = { pane in
        pane.resolvedJar.jar == .pane || pane.canOpenInNewPaneBeside
    }

    /// Where every page opens for the global jar, in either scope: the
    /// extensions window (`WebBrowserWindowController.showExtensions`), so
    /// the store is one window found again rather than a pane split off each
    /// time. `nil` for a worktree or pane jar, whose pages have to open on
    /// that jar, and a window of its own can only be on the global one: those
    /// go to `openPage`. Returns whether the page opened. A test records the
    /// call, or clears it to stand in for a jar of its own.
    var openInExtensionsWindow: ((URL) -> Bool)?

    /// Whether `openInExtensionsWindow` can open a window: the host has said
    /// how to build one. A test answers it directly.
    var canOpenExtensionsWindow: () -> Bool = { WebBrowserWindowController.canOpen }

    /// Asks before an extension is removed; the default is a sheet on this
    /// window. A test answers it directly.
    var confirmRemoval: (BrowserExtension, @escaping (Bool) -> Void) -> Void = { _, _ in }

    private(set) var table: ComposableSettings.EditableTableCard?
    private(set) var extensions: [BrowserExtension] = []
    private(set) var optionsButton: NSButton?
    private(set) var getButton: NSButton?
    /// The read in flight; one at a time, as the Safari topic's.
    private(set) var reloadTask: Task<Void, Never>?
    /// The change in flight (toggle, removal, update check), which reloads
    /// when it is done.
    private(set) var changeTask: Task<Void, Never>?

    init(
        engine: BrowserEngineMaintenance, profile: BrowserExtensionProfile,
        destination: @escaping () -> WebBrowserPaneViewController?, binding: BrowserSettingsBinding
    ) {
        self.engine = engine
        self.profile = profile
        self.destination = destination
        super.init(title: "Extensions", symbol: "puzzlepiece.extension", binding: binding)
        if profile == .global {
            openInExtensionsWindow = { url in
                WebBrowserWindowController.showExtensions(url, store: Self.webStore)
            }
        }
        confirmRemoval = { [weak self] item, completion in
            ComposableSettings.Alerts.confirmDestructive(
                "Remove \u{201C}\(item.name)\u{201D}?",
                detail: "Chrome uninstalls it from the Chrome panes on this jar, with its settings and data.",
                actionTitle: "Remove",
                on: self?.view.window,
                completion
            )
        }
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Extensions",
                body: "Chrome extensions, the same ones the Chrome Web Store offers Google "
                    + "Chrome, run in Chrome Web Browser panes; Safari panes have none. "
                    + (binding.isPaneScope
                        ? "This list is the extensions of this pane's jar. "
                        : "This list is the extensions of the global jar, the one shared by "
                            + "every Chrome pane that follows it. ")
                    + "Each jar is a Chrome profile of its own, so a worktree's jar or a single "
                    + "pane's jar has its own extensions, installed from a pane on that jar. "
                    + "A pane in private browsing keeps nothing, extensions included."
            ),
            .init(
                title: "Installing",
                body: "Get Extensions… opens the Chrome Web Store; press Add to Chrome on an "
                    + "extension's page there and confirm, and it is installed in that jar, its "
                    + "icon in the toolbar of every Chrome pane on it. For the global jar the "
                    + "store opens in a Web Browser window of its own, and pressing Get "
                    + "Extensions… again brings that window forward rather than opening another. "
                    + "For a worktree's jar it opens in a new Chrome pane beside the pane whose "
                    + "settings these are, on the same jar, and the button is off when the "
                    + "layout has no room for one. A pane with a jar of its own is the only "
                    + "pane on it, so the store opens in that pane."
            ),
            .init(
                title: "Managing",
                body: "Switch an extension off to stop it without losing its settings. "
                    + "An extension marked (new permissions) was turned off by Chrome because "
                    + "an update asks for more; switching it on opens Chrome's extensions page "
                    + "on it, where Chrome lists the new permissions for you to accept. "
                    + "Select one and press − to uninstall it. Options opens the selected "
                    + "extension's own settings page, when it has one. Both open where Get "
                    + "Extensions… opens the store, in a new tab when that is the store's "
                    + "window. Refresh re-reads the list."
            ),
            .init(
                title: "Updates",
                body: "Chrome keeps extensions from the Chrome Web Store up to date by itself "
                    + "while Chrome panes are open. Check for updates sets how often it asks "
                    + "the store, every 5 hours unless you change it, for every jar at once; "
                    + "Chrome reads it when it starts, so a change applies the next time the "
                    + "app opens. Check for Updates Now asks it to check every extension at "
                    + "once. An extension from anywhere else (Other) updates only if its "
                    + "maker set it up to."
            )
        ])
    }

    static let keywords: [String] = [
        "extensions", "chrome extensions", "plugins", "add-ons", "chrome web store", "web store",
        "extension updates", "update interval", "check for updates", "uninstall extension"
    ]

    override var searchKeywords: [String] { Self.keywords }

    static let updateIntervalIdentifier = "\(identifier).update-interval"

    /// The table scrolls itself and fills the panel to its bottom edge, so
    /// the panel is not wrapped in the settings scroll view.
    override var hostsOwnScroll: Bool { true }

    /// The update interval group over the list, in the Settings window only
    /// (the interval is Chrome's, for every jar at once), and the list below
    /// it taking whatever height is left, its bottom pinned to the panel's.
    override func loadView() {
        let container = NSView()
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        let table = makeTable()
        self.table = table
        let tableArea = ComposableSettings.TableFillingView(card: table)
        tableArea.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tableArea)
        var top = container.topAnchor
        var topSpacing = inset
        if let updates = makeUpdatesGroup() {
            // A group makes itself as wide as its superview, so it goes in a
            // holder that carries the inset rather than straight into the
            // container, where it would run to the panel's edges.
            let holder = NSView()
            holder.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(holder)
            holder.addSubview(updates)
            NSLayoutConstraint.activate([
                updates.topAnchor.constraint(equalTo: holder.topAnchor),
                updates.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
                holder.bottomAnchor.constraint(equalTo: updates.bottomAnchor),
                holder.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
                holder.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
                container.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: inset)
            ])
            top = holder.bottomAnchor
            topSpacing = ComposableSettings.SettingsLayout.default[.groupSpacing]
        }
        NSLayoutConstraint.activate([
            tableArea.topAnchor.constraint(equalTo: top, constant: topSpacing),
            tableArea.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            container.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: inset),
            container.bottomAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: inset)
        ])
        view = container
    }

    private func makeUpdatesGroup() -> ComposableSettings.GroupView? {
        guard !binding.isPaneScope else { return nil }
        let group = ComposableSettings.GroupView(withTitle: "Updates")
        let interval = binding.choice(
            "Check for updates", UserSettings.browserChromeExtensionUpdateInterval,
            choices: BrowserExtensionUpdateInterval.allCases.map { .init(label: $0.label, value: $0) },
            explanation: "Applies the next time the app opens."
        )
        let intervalView = ComposableSettings.PopupMenuChoiceView(viewModel: interval)
        _ = intervalView.popUpButton.accessibilityID(Self.updateIntervalIdentifier)
        binding.add(intervalView, model: interval, key: UserSettings.browserChromeExtensionUpdateInterval, to: group)
        return group
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    /// Management ends with the topic: nothing still in flight may ask
    /// Chrome for its extensions afterwards, which would open a hidden
    /// extensions page with nobody left to close it.
    override func viewDidDisappear() {
        super.viewDidDisappear()
        reloadTask?.cancel()
        changeTask?.cancel()
        engine.endExtensionManagement()
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Installed Extensions",
            columns: [
                .init(id: "icon", title: "", width: 24, kind: .image),
                .init(id: "name", title: "Name", width: 220),
                .init(id: "version", title: "Version", width: 80),
                .init(id: "source", title: "Source", width: 130),
                .init(id: "enabled", title: "On", width: 40, kind: .toggle)
            ],
            emptyMessage: Self.emptyMessage,
            visibleRows: 8,
            accessibilityPrefix: Self.identifier
        )
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in self?.remove(rowID) }
        table.onToggle = { [weak self] rowID, _, isOn in
            self?.setEnabled(rowID, isOn: isOn)
        }
        table.onSelectionChange = { [weak self] _ in self?.updateButtons() }
        optionsButton = table.addFooterButton(
            title: "Options", identifier: "\(Self.identifier).options"
        ) { [weak self] in
            self?.openOptions()
        }
        getButton = table.addFooterButton(
            title: "Get Extensions…", identifier: "\(Self.identifier).get"
        ) { [weak self] in
            self?.getExtensions()
        }
        _ = table.addFooterButton(
            title: "Check for Updates Now", identifier: "\(Self.identifier).check-updates"
        ) { [weak self] in
            self?.checkForUpdates()
        }
        _ = table.addFooterButton(title: "Refresh", identifier: "\(Self.identifier).refresh") { [weak self] in
            self?.reload()
        }
        updateButtons()
        return table
    }

    private var selected: BrowserExtension? {
        guard let id = table?.selectedRowID else { return nil }
        return extensions.first { $0.id == id }
    }

    /// Get Extensions… needs somewhere to open the store: for the global
    /// jar, a window it can build; otherwise the destination pane, with room
    /// in its layout for one more. Options needs the same and a selected
    /// extension that has an options page.
    func updateButtons() {
        let canOpen: Bool
        if openInExtensionsWindow != nil {
            canOpen = canOpenExtensionsWindow()
        } else if let pane = destination() {
            canOpen = canOpenPage(pane)
        } else {
            canOpen = false
        }
        getButton?.isEnabled = canOpen
        optionsButton?.isEnabled = canOpen && selected?.optionsURL != nil
    }

    func openOptions() {
        guard let url = selected?.optionsURL else { return }
        open(url)
    }

    func getExtensions() {
        open(Self.webStore)
    }

    /// A pane gone, or a layout filled since the buttons were last set, turns
    /// the click into a beep and the buttons off, rather than nothing at all.
    private func open(_ url: URL) {
        let opened: Bool
        if let openInExtensionsWindow {
            opened = openInExtensionsWindow(url)
        } else if let pane = destination() {
            opened = openPage(pane, url)
        } else {
            opened = false
        }
        guard opened else {
            NSSound.beep()
            updateButtons()
            return
        }
    }

    /// Switching on an extension Chrome turned off for new permissions opens
    /// Chrome's extensions page on it, beside the pane like Options, where
    /// Chrome's own prompt lists the permissions for the person to accept;
    /// nothing here accepts them. The switch goes back to off until then.
    func setEnabled(_ id: String, isOn: Bool) {
        if isOn, let item = extensions.first(where: { $0.id == id }), item.needsPermissionReview {
            if let url = item.reviewURL {
                open(url)
            }
            reload()
            return
        }
        change { try await $0.setExtension(id, enabled: isOn, in: $1) }
    }

    func checkForUpdates() {
        change { try await $0.checkForExtensionUpdates(in: $1) }
    }

    func remove(_ id: String) {
        guard let item = extensions.first(where: { $0.id == id }) else { return }
        confirmRemoval(item) { [weak self] confirmed in
            guard confirmed else { return }
            self?.change { try await $0.removeExtension(id, in: $1) }
        }
    }

    /// Runs one change against Chrome, then re-reads the list; a failure
    /// shows in the table in place of the rows.
    private func change(
        _ work: @escaping @MainActor (BrowserEngineMaintenance, BrowserExtensionProfile) async throws -> Void
    ) {
        let engine = engine
        let profile = profile
        changeTask = Task {
            guard !Task.isCancelled else { return }
            do {
                try await work(engine, profile)
                guard !Task.isCancelled else { return }
                reload()
            } catch {
                guard !Task.isCancelled else { return }
                show(error)
            }
        }
    }

    func reload() {
        reloadTask?.cancel()
        let engine = engine
        let profile = profile
        reloadTask = Task {
            guard !Task.isCancelled else { return }
            do {
                let list = try await engine.extensions(in: profile)
                guard !Task.isCancelled else { return }
                extensions = list
                table?.emptyLabel.stringValue = Self.emptyMessage
                table?.setRows(list.map { item in
                    ComposableSettings.EditableTableRow(id: item.id, cells: [
                        "icon": .image(item.iconPNG),
                        "name": .text(item.needsPermissionReview
                            ? "\(item.name) (new permissions)" : item.name),
                        "version": .text(item.version),
                        "source": .text(item.isFromWebStore ? "Chrome Web Store" : "Other"),
                        "enabled": .toggle(item.isEnabled)
                    ])
                })
                updateButtons()
            } catch {
                guard !Task.isCancelled else { return }
                show(error)
            }
        }
    }

    private func show(_ error: Error) {
        extensions = []
        table?.emptyLabel.stringValue = error.localizedDescription
        table?.setRows([])
        updateButtons()
    }
}
