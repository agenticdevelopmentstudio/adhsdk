//
//  BrowserEngineTopicPanels.swift
//  AgenticDeveloperHubSDK
//
//  The Web Browser panel's Chrome topics, which belong to Chromium alone;
//  WebKit's own rows sit in the shared topics. They bind through the panel's
//  `BrowserSettingsBinding`, so a Chrome pane's sheet shows them as
//  overridable rows.
//

import AppKit

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
    /// The read in flight; one at a time, as the Site Data window's.
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
