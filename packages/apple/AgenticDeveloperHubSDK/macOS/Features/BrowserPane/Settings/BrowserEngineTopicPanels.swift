//
//  BrowserEngineTopicPanels.swift
//  AgenticDeveloperHubSDK
//
//  The two topics of the Web Browser panel that belong to one engine each:
//  Safari (WebKit) and Chrome (Chromium). Everything else in the panel
//  applies to both.
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
/// none, the panel has no Chrome topic, because there is no Chrome to set.
@MainActor
public protocol BrowserEngineMaintenance: AnyObject {
    /// The engine's own version, as the Chrome topic shows it.
    var engineVersion: String { get }
    /// Removes every cookie Chrome panes have kept.
    func removeAllCookies() async
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

    init(siteData: BrowserSiteData) {
        self.siteData = siteData
        super.init(title: "Safari", symbol: "safari")
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
                    + "http; it applies to Safari panes opened after the change. "
                    + "Lockdown Mode is the same restricted mode Safari offers: certain "
                    + "web technologies, fonts and media formats are refused, which "
                    + "breaks some sites in exchange for a smaller attack surface. It "
                    + "applies to the next page each pane loads."
            ),
            .init(
                title: "Media",
                body: "Allow AirPlay lets a page's video offer the AirPlay control. It is "
                    + "fixed when a Safari pane is created and applies to panes opened "
                    + "after the change."
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
                body: "Everything WebKit is keeping for sites Safari panes have visited, "
                    + "one row per site: cookies, local storage, caches, service workers "
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
                    + "is not involved."
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

    private func makeProtectionGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Protection")

        let fraud = ComposableSettings.ViewModel<Bool>(
            title: "Warn about fraudulent websites",
            setting: UserSettings.browserFraudWarning
        )
        let fraudView = ComposableSettings.CheckboxView(with: fraud)
        _ = fraudView.toggle.accessibilityID("settings.browser.safari.fraud-warning")
        group.addSettingSubview(fraudView)

        let https = ComposableSettings.ViewModel<Bool>(
            title: "Upgrade known sites to HTTPS",
            setting: UserSettings.browserUpgradesToHTTPS,
            explanation: "Applies to Safari panes opened after the change."
        )
        let httpsView = ComposableSettings.CheckboxView(with: https)
        _ = httpsView.toggle.accessibilityID("settings.browser.safari.upgrade-https")
        group.addSettingSubview(httpsView)

        let lockdown = ComposableSettings.ViewModel<Bool>(
            title: "Lockdown Mode",
            setting: UserSettings.browserLockdownMode,
            explanation: "Refuses some web technologies for a smaller attack surface. "
                + "Applies to the next page each pane loads."
        )
        let lockdownView = ComposableSettings.CheckboxView(with: lockdown)
        _ = lockdownView.toggle.accessibilityID("settings.browser.safari.lockdown")
        group.addSettingSubview(lockdownView)

        return group
    }

    private func makeMediaGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Media")
        let airPlay = ComposableSettings.ViewModel<Bool>(
            title: "Allow AirPlay",
            setting: UserSettings.browserAllowsAirPlay,
            explanation: "Applies to Safari panes opened after the change."
        )
        let airPlayView = ComposableSettings.CheckboxView(with: airPlay)
        _ = airPlayView.toggle.accessibilityID("settings.browser.safari.airplay")
        group.addSettingSubview(airPlayView)
        return group
    }

    private func makeInspectorGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Web Inspector")
        let inspector = ComposableSettings.ViewModel<Bool>(
            title: "Allow Web Inspector",
            setting: UserSettings.browserWebInspectorEnabled,
            explanation: "Right-click a page and choose Inspect Element."
        )
        let inspectorView = ComposableSettings.CheckboxView(with: inspector)
        _ = inspectorView.toggle.accessibilityID("settings.browser.safari.inspector")
        group.addSettingSubview(inspectorView)
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
            detail: "Cookies, caches and storage for every site are removed, and Safari panes are signed out "
                + "everywhere. History and Chrome's data are not affected.",
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

    private let engine: BrowserEngineMaintenance

    init(engine: BrowserEngineMaintenance) {
        self.engine = engine
        super.init(title: "Chrome", symbol: "globe")
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
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
                    + "own. Remote debugging port lets an outside tool — Chrome's own "
                    + "chrome://inspect, Playwright, Puppeteer — attach to Chrome panes "
                    + "over the DevTools protocol on that port of this Mac. Zero is off, "
                    + "the default, because anything on this Mac that can reach the port "
                    + "can read and drive every Chrome pane. The port is read when "
                    + "Chromium starts, so a change applies the next time the app opens."
            ),
            .init(
                title: "Performance",
                body: "Hardware acceleration draws pages with the graphics card. Turn it "
                    + "off only when Chrome panes draw wrongly or not at all. It is read "
                    + "when Chromium starts, so a change applies the next time the app "
                    + "opens."
            ),
            .init(
                title: "Site Data",
                body: "Remove All Chrome Cookies signs Chrome panes out of every site. "
                    + "Safari's cookies and the browsing history are not affected."
            )
        ])
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
        settingsView.addGroup(makeSiteDataGroup())
        settingsView.addGroup(makeAboutGroup())
    }

    private func makeDeveloperGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Developer Tools")

        let devTools = ComposableSettings.ViewModel<Bool>(
            title: "Allow developer tools",
            setting: UserSettings.browserChromeDevToolsEnabled,
            explanation: "Right-click a page and choose Inspect Element."
        )
        let devToolsView = ComposableSettings.CheckboxView(with: devTools)
        _ = devToolsView.toggle.accessibilityID("settings.browser.chrome.devtools")
        group.addSettingSubview(devToolsView)

        let port = ComposableSettings.RangeViewModel<Int>(
            title: "Remote debugging port",
            setting: UserSettings.browserChromeRemoteDebuggingPort,
            minValue: BrowserSettings.chromeRemoteDebuggingPortRange.lowerBound,
            maxValue: BrowserSettings.chromeRemoteDebuggingPortRange.upperBound,
            explanation: "Zero is off. Applies the next time the app opens."
        )
        let portView = ComposableSettings.IntegerFieldView(viewModel: port)
        _ = portView.textField.accessibilityID("settings.browser.chrome.remote-debugging-port")
        group.addSettingSubview(portView)

        return group
    }

    private func makePerformanceGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Performance")
        let acceleration = ComposableSettings.ViewModel<Bool>(
            title: "Use hardware acceleration",
            setting: UserSettings.browserChromeHardwareAcceleration,
            explanation: "Applies the next time the app opens."
        )
        let accelerationView = ComposableSettings.CheckboxView(with: acceleration)
        _ = accelerationView.toggle.accessibilityID("settings.browser.chrome.hardware-acceleration")
        group.addSettingSubview(accelerationView)
        return group
    }

    private func makeSiteDataGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Site Data")
        let remove = ComposableSettings.ButtonViewModel(title: "Remove All Chrome Cookies…") { [weak self] in
            self?.confirmRemoveCookies()
        }
        let removeView = ComposableSettings.ButtonView(viewModel: remove, placement: .leading)
        _ = removeView.button.accessibilityID("settings.browser.chrome.remove-cookies")
        group.addSettingSubview(removeView)
        return group
    }

    private func makeAboutGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "About")
        let version = ComposableSettings.ValueRowView(title: "Chromium", value: engine.engineVersion)
        _ = version.valueLabel.accessibilityID("settings.browser.chrome.version")
        group.addSettingSubview(version)
        return group
    }

    private func confirmRemoveCookies() {
        ComposableSettings.Alerts.confirmDestructive(
            "Remove all Chrome cookies?",
            detail: "Chrome panes are signed out of every site. Safari's cookies and the history are not affected.",
            actionTitle: "Remove All",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task { await self.engine.removeAllCookies() }
        }
    }
}
