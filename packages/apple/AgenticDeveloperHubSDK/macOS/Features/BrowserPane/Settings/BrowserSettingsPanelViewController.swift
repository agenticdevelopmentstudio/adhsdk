//
//  BrowserSettingsPanelViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import WebKit

import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore

/// Which settings a Browser panel shows and writes (spec section 3).
///
/// - `global`: the app's shared browser settings, in the Settings window.
/// - `pane`: one browser pane's own layer over them, in the pane's settings
///   sheet. Writes land in the layer; the global settings are never touched.
public enum BrowserSettingsScope {
    case global
    case pane(LayeredSettingsStore, WebBrowserPaneViewController)
}

/// Settings panel for the browser panes: a topic list on the left — General,
/// History, Cookies, Privacy, Media and Permissions, Downloads,
/// Safari, Chrome, Reset — and the chosen topic's controls on the right, the
/// shape the Language Servers panel has. Safari and Chrome hold what only that
/// engine has; every other topic applies to both. In a pane's sheet only the
/// pane's own engine topic is listed.
///
/// **One panel definition serves both scopes** (`dry`). Every row reads and
/// writes through `ViewModel(title:get:set:)` over the scope's store — the
/// store handed in as `settings` in global scope, the pane's
/// `LayeredSettingsStore` in pane scope — so the Settings window and a pane's
/// sheet are the same rows over different stores. The things that are not
/// settings — the visit history, WebKit's site data, Chromium's cookie jar and
/// version — are handed in for the same reason: they are stores with files
/// behind them (`dependency-injection`).
///
/// **Every setting shown is one the pane honours.** The ones an engine fixes
/// when a pane is created say so in their explanation — "new browser panes" in
/// global scope, "when this sheet closes" in pane scope, where closing the
/// sheet rebuilds the pane — so the panel never promises an effect the open
/// pane cannot deliver (`principle-of-least-astonishment`).
@MainActor
public final class BrowserSettingsPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    private let history: BrowserHistoryStore?
    private let siteData: BrowserSiteData
    private let chrome: BrowserEngineMaintenance?
    /// Every row's store and the bookkeeping behind its override marker.
    /// Internal so a test can reach the rows without pixels.
    let binding: BrowserSettingsBinding

    /// - Parameters:
    ///   - history: where the pane records visits; `nil` means the host records
    ///     none, and the History topic says so.
    ///   - siteData: WebKit's persistent store, the global jar. Global scope
    ///     only: in pane scope the topic lists the pane's own data store. A
    ///     test hands in a non-persistent one.
    ///   - settings: the store global-scope rows read and write. The app's
    ///     shared store by default. Unused in pane scope, whose store is the
    ///     pane's layer.
    ///   - scope: the Settings window's `.global`, or one pane's sheet.
    ///   - chrome: the Chromium engine's maintenance, from the host that links
    ///     it; `nil` leaves the Chrome topic out of the Settings window. A
    ///     Chrome pane's sheet lists the topic either way, without the
    ///     version row when there is none.
    ///   - privacyVault: the app's one privacy words vault, which Privacy's
    ///     Edit Privacy Words… opens in global scope; `nil` leaves the button
    ///     out there. Pane scope uses the pane's own vault, so it need not be
    ///     passed. It must be the instance the panes and private terminals
    ///     share: a vault ignores its own process's change notification.
    public init(
        history: BrowserHistoryStore?,
        siteData: BrowserSiteData = BrowserSiteData(),
        settings: SettingsStore = UserSettings.shared,
        scope: BrowserSettingsScope = .global,
        chrome: BrowserEngineMaintenance? = nil,
        privacyVault: PrivacyWordsVault? = nil
    ) {
        self.history = history
        self.siteData = siteData
        self.chrome = chrome
        self.binding = BrowserSettingsBinding(settings: settings, scope: scope, privacyVault: privacyVault)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Web Browser",
            icon: NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shown while no topic is selected; each topic carries its own.
    public override var helpContent: ComposableSettings.PanelHelp? {
        var topics: [ComposableSettings.PanelHelp.Topic] = [
            .init(
                title: "Web Browser",
                body: binding.isPaneScope
                    ? "These are the settings of one browser pane. Each starts as the global "
                        + "browser setting from the Settings window, and a change made here "
                        + "applies to this pane alone. Pick a topic on the left."
                    : "The Safari Web Browser and Chrome Web Browser panes are web "
                        + "browsers inside a Coding Project window: an address bar over a page, "
                        + "drawn by WebKit or by Chromium. These topics decide how their pages "
                        + "load, what they remember about where you have been, what sites may "
                        + "keep and do, and where downloads land. Safari and Chrome hold what "
                        + "only that browser has; every other topic applies to both. Pick a "
                        + "topic on the left."
            )
        ]
        if binding.isPaneScope {
            topics.append(.init(
                title: "Overrides",
                body: "A setting changed here overrides the global one for this pane, and its "
                    + "row shows a small dot in the accent colour for as long as it does. "
                    + "Right-click the row and choose Use Global Setting to drop the override; "
                    + "the row then follows the Settings window again. Reset clears every "
                    + "override of the pane at once. Private browsing, and Chrome's "
                    + "remote debugging port and hardware acceleration, are global only, and "
                    + "Accept cookies can be overridden only while the jar chosen here is "
                    + "the pane's own, or private browsing is on, because under a shared "
                    + "jar it would change every pane on that jar."
            ))
        }
        topics.append(.init(
            title: "When a Change Takes Effect",
            body: binding.isPaneScope
                ? "Most settings apply to the pane as you change them. Those fixed when "
                    + "the pane's page is made — the cookie and storage jar, console "
                    + "capture and, in a Safari pane, the HTTPS upgrade, autoplay and "
                    + "AirPlay — apply when this sheet closes: the pane rebuilds its page "
                    + "and reloads it, and anything the old page had half done is lost. "
                    + "JavaScript and Lockdown Mode apply to the next page a Safari pane "
                    + "loads. Chromium reads autoplay once, when it starts, so a Chrome "
                    + "pane follows it the next time the app opens."
                : "Most settings apply to every open browser pane as you change them. A few "
                    + "are fixed when a pane is created — private browsing, console "
                    + "capture, and the HTTPS upgrade, autoplay and AirPlay in Safari "
                    + "panes — and those say so beside the control: they apply to panes "
                    + "opened after the change. The cookie and storage jar is the "
                    + "exception: every open pane that follows the global value moves to "
                    + "the new jar at once, reloading its page. JavaScript and Lockdown "
                    + "Mode apply to the next page a Safari pane loads. Chromium reads "
                    + "autoplay, the remote debugging port and hardware acceleration once, "
                    + "when it starts, so in Chrome panes those apply the next time the "
                    + "app opens."
        ))
        return ComposableSettings.PanelHelp(topics: topics)
    }

    /// The topics are built when this view loads, and settings search reads
    /// a split's panels only once it has — so until the user has opened
    /// Browser, "cookies" or "downloads" would find nothing. Every topic's
    /// terms are listed here as well, from the same declarations the topics
    /// use (`dry`).
    public override var searchKeywords: [String] {
        BrowserGeneralPanel.keywords + BrowserHistoryPanel.keywords + BrowserCookiesPanel.keywords
            + BrowserPrivacySettingsPanel.keywords + BrowserMediaPanel.keywords
            + BrowserDownloadsPanel.keywords
            + (showsSafariTopic ? SafariBrowserTopicPanel.keywords : [])
            + safariExtensionsKeywords
            + (showsChromeTopic ? ChromeBrowserTopicPanel.keywords : [])
            + (extensionsProfile != nil ? ChromeExtensionsTopicPanel.keywords : [])
            + BrowserResetPanel.keywords
    }

    /// A pane's sheet has no remembered geometry to restore, and a divider
    /// dragged in a transient dialog is a setting nobody asked to keep — the
    /// project settings sheet's reasoning.
    public override var contentSizedSidebar: Bool { binding.isPaneScope }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addPanel(BrowserGeneralPanel(binding: binding))
        addPanel(BrowserHistoryPanel(history: history, binding: binding))
        addPanel(BrowserCookiesPanel(title: cookiesTitle, binding: binding))
        addPanel(BrowserPrivacySettingsPanel(binding: binding))
        addPanel(BrowserMediaPanel(binding: binding))
        addPanel(BrowserDownloadsPanel(binding: binding))
        if showsSafariTopic {
            addPanel(SafariBrowserTopicPanel(siteData: paneSiteData ?? siteData, binding: binding))
        }
        if #available(macOS 15.4, *), safariExtensionsAvailable, let profile = safariExtensionsProfile,
           let host = SafariExtensionHost.host(for: profile) {
            addPanel(SafariExtensionsTopicPanel(host: host, destination: extensionsDestination, binding: binding))
        }
        if showsChromeTopic { addPanel(ChromeBrowserTopicPanel(engine: chrome, binding: binding)) }
        if let chrome, let extensionsProfile {
            addPanel(ChromeExtensionsTopicPanel(
                engine: chrome, profile: extensionsProfile, destination: extensionsDestination, binding: binding))
        }
        addPanel(BrowserResetPanel(binding: binding))
    }

    // MARK: Engine topics, by scope

    /// The Settings window lists Safari always and Chrome when the host links
    /// Chromium; a pane's sheet lists only the pane's own engine, since the
    /// other's settings would change nothing the pane does.
    var showsSafariTopic: Bool {
        guard let pane = binding.pane else { return true }
        return pane.engineKind == .safari
    }

    /// The Safari Extensions topic shows wherever the Safari topic does,
    /// once the app has said where extensions live, on macOS 15.4 and later.
    var safariExtensionsAvailable: Bool {
        showsSafariTopic && SafariExtensionSupport.isAvailable && safariExtensionsProfile != nil
    }

    private var safariExtensionsKeywords: [String] {
        guard #available(macOS 15.4, *), safariExtensionsAvailable else { return [] }
        return SafariExtensionsTopicPanel.keywords
    }

    /// The profile the Safari Extensions topic lists: the global jar's in the
    /// Settings window, the pane's jar in its sheet; nil for a jar kept in
    /// memory, which runs no extensions.
    var safariExtensionsProfile: BrowserExtensionProfile? {
        guard let pane = binding.pane else { return .global }
        return BrowserExtensionProfile(pane.resolvedJar)
    }

    var showsChromeTopic: Bool {
        guard let pane = binding.pane else { return chrome != nil }
        return pane.engineKind == .chrome
    }

    /// The profile the Extensions topic manages: the global jar's in the
    /// Settings window, the pane's jar's in a Chrome pane's sheet. `nil`, and
    /// no topic, without the Chromium engine's maintenance, or for a pane on
    /// a jar kept in memory (private browsing), which has no extensions.
    var extensionsProfile: BrowserExtensionProfile? {
        guard chrome != nil, showsChromeTopic else { return nil }
        guard let pane = binding.pane else { return .global }
        return BrowserExtensionProfile(pane.resolvedJar)
    }

    /// The pane the Extensions topic opens a page (an extension's options,
    /// the Web Store) beside when the pane is on a jar of its own: the pane
    /// whose sheet it is. The Settings window lists the global jar, whose
    /// pages open in the extensions window instead, so it has none.
    private var extensionsDestination: () -> WebBrowserPaneViewController? {
        guard let pane = binding.pane else { return { nil } }
        return { [weak pane] in pane }
    }

    // MARK: Cookies and site data, by scope

    /// "Global Cookies" in the Settings window, whose site data is the global
    /// jar's; in a pane's sheet, the jar that pane is on.
    var cookiesTitle: String {
        guard let pane = binding.pane else { return "Global Cookies" }
        return "Cookies — \(Self.jarLabel(for: pane))"
    }

    /// A Safari pane's own data store, whichever jar it resolved to: the one
    /// its web view was built on, because a private or fail-closed jar is a
    /// store no second call would hand back.
    private var paneSiteData: BrowserSiteData? {
        guard let pane = binding.pane as? SafariBrowserPaneViewController else { return nil }
        return BrowserSiteData(dataStore: pane.webView.configuration.websiteDataStore)
    }

    /// The name a pane's current jar goes by in the sheet. Private browsing
    /// is a store the pane alone has, so it reads as the pane's own, and so
    /// does a jar that failed closed onto a non-persistent store.
    static func jarLabel(for pane: WebBrowserPaneViewController) -> String {
        guard !pane.resolvedJar.isFallback else { return "This Pane" }
        switch pane.resolvedJar.jar {
        case .global:
            return "All Browser Panes"
        case .worktree:
            guard let path = pane.paneContext.worktreePath, !path.isEmpty else { return "This Worktree" }
            return (path as NSString).lastPathComponent
        case .pane, nil:
            return "This Pane"
        }
    }
}

// MARK: - Binding

/// One row the binding knows about: what it shows, how to make it re-read its
/// store, and in pane scope whether the pane overrides it.
@MainActor
final class BrowserSettingsRow {
    /// The setting's key name.
    let name: String
    /// The row's view model; `nil` for a row that is not a model (the
    /// download folder's value row).
    let model: ComposableSettings.AbstractViewModel?
    let view: NSView
    /// The group the row is in, by its caption.
    let group: String?
    /// False for a row shown disabled with the global value. Accept cookies
    /// can change either way while the sheet is up, as the jar it shows does.
    fileprivate(set) var isEnabled: Bool
    /// The override dot, in pane scope, on a row that can be overridden.
    let marker: OverrideMarker?
    let refresh: () -> Void
    let hasOverride: () -> Bool

    init(
        name: String,
        model: ComposableSettings.AbstractViewModel?,
        view: NSView,
        group: String?,
        isEnabled: Bool,
        marker: OverrideMarker?,
        refresh: @escaping () -> Void,
        hasOverride: @escaping () -> Bool
    ) {
        self.name = name
        self.model = model
        self.view = view
        self.group = group
        self.isEnabled = isEnabled
        self.marker = marker
        self.refresh = refresh
        self.hasOverride = hasOverride
    }
}

/// What every topic of the Browser panel binds through: the scope's store,
/// the view models over it, and — in pane scope — the override marker on each
/// row and which rows are locked to the global value (spec section 3).
///
/// One object rather than each topic deciding for itself, so "how a row
/// behaves in pane scope" is answered in one place (`dry`), and a topic only
/// says which setting a row shows.
@MainActor
final class BrowserSettingsBinding {

    let scope: BrowserSettingsScope
    /// Where rows read and write: `settings` in global scope, the pane's
    /// layer in pane scope.
    let store: SettingsStore
    private(set) var rows: [BrowserSettingsRow] = []
    /// Buttons by accessibility identifier, so a test can press one.
    private(set) var buttons: [String: ComposableSettings.ButtonViewModel] = [:]
    private var cancellables: Set<AnyCancellable> = []
    /// The vault handed to the panel, for global scope.
    private let globalPrivacyVault: PrivacyWordsVault?

    init(settings: SettingsStore, scope: BrowserSettingsScope, privacyVault: PrivacyWordsVault? = nil) {
        self.scope = scope
        self.globalPrivacyVault = privacyVault
        switch scope {
        case .global: store = settings
        case .pane(let layered, _): store = layered
        }
        observeChanges()
    }

    /// The privacy words the Agent Privacy group edits: the pane's vault in
    /// pane scope (falling back to the one handed in), the one handed in
    /// globally. `nil` hides Edit Privacy Words….
    var privacyVault: PrivacyWordsVault? { pane?.privacyVault ?? globalPrivacyVault }

    var layered: LayeredSettingsStore? {
        if case .pane(let layered, _) = scope { return layered }
        return nil
    }

    var pane: WebBrowserPaneViewController? {
        if case .pane(_, let pane) = scope { return pane }
        return nil
    }

    var isPaneScope: Bool { pane != nil }

    /// The rows for one setting.
    func rows(named name: String) -> [BrowserSettingsRow] {
        rows.filter { $0.name == name }
    }

    /// Whether, in pane scope, the row for `name` shows the global value and
    /// takes no edits: a global-only setting, Autoplay in a Chrome pane
    /// (Chromium fixes it once, for every Chrome pane), or Accept cookies while the jar
    /// the sheet shows is shared with other panes. That is the jar the pane
    /// will be on once the sheet closes, not the one it was built on, so the
    /// row never takes an override that would not apply. Private browsing
    /// counts as the pane's own store: nothing else is on it.
    func isLocked(_ name: String) -> Bool {
        guard let pane else { return false }
        if BrowserSettings.globalOnlyKeyNames.contains(name) { return true }
        if pane.engineKind == .chrome, BrowserSettings.chromeProcessKeyNames.contains(name) { return true }
        if name == UserSettings.browserAcceptsCookies.name { return !pane.wouldOwnDataStore(under: store) }
        return false
    }

    /// The settings a row's lock depends on besides its own.
    private static let lockingKeyNames: Set<String> = [
        UserSettings.browserPrivacyStorageJar.name,
        UserSettings.browserPrivateBrowsing.name
    ]

    // MARK: Explanations

    /// What a construction-time row says about when it takes effect.
    func constructionNote(for name: String) -> String {
        if isPaneScope { return "Applies when this sheet closes: the pane reloads its page." }
        if name == UserSettings.browserPrivacyStorageJar.name {
            return "Open browser panes that follow this setting move to the new jar, reloading their page."
        }
        return "Applies to browser panes opened after the change."
    }

    // MARK: View models

    /// Reads and writes for `key`. A locked row reads the global value and
    /// drops writes, so it cannot create the override it is locked against.
    /// Asked at each read and write, since a lock can change while the
    /// sheet is up.
    private func accessors<Value: Codable & Sendable>(
        _ key: UserSetting<Value>
    ) -> (get: () -> Value, set: (Value) -> Void) {
        let store = self.store
        guard let fallback = layered?.fallback else {
            return ({ store.get(key) }, { store.set($0, for: key) })
        }
        let name = key.name
        return ({ [weak self] in
            self?.isLocked(name) == true ? fallback.get(key) : store.get(key)
        }, { [weak self] value in
            guard self?.isLocked(name) == false else { return }
            store.set(value, for: key)
        })
    }

    func model<Value: Codable & Sendable>(
        _ title: String, _ key: UserSetting<Value>, explanation: String? = nil
    ) -> ComposableSettings.ViewModel<Value> {
        let access = accessors(key)
        return ComposableSettings.ViewModel(title: title, get: access.get, set: access.set, explanation: explanation)
    }

    func choice<Value: Codable & Sendable & Equatable>(
        _ title: String,
        _ key: UserSetting<Value>,
        choices: [ComposableSettings.ChoiceViewModel<Value>.Choice],
        explanation: String? = nil
    ) -> ComposableSettings.ChoiceViewModel<Value> {
        let access = accessors(key)
        return ComposableSettings.ChoiceViewModel(
            title: title, choices: choices, get: access.get, set: access.set, explanation: explanation
        )
    }

    func range<Value: Codable & Sendable & Comparable>(
        _ title: String,
        _ key: UserSetting<Value>,
        bounds: ClosedRange<Value>,
        explanation: String? = nil
    ) -> ComposableSettings.RangeViewModel<Value> {
        let access = accessors(key)
        return ComposableSettings.RangeViewModel(
            title: title, minValue: bounds.lowerBound, maxValue: bounds.upperBound,
            get: access.get, set: access.set, explanation: explanation
        )
    }

    // MARK: Rows

    /// Adds `view`, the row for `key`, to `group`: disabled when locked, and
    /// in pane scope with an override marker and its "Use Global Setting" menu.
    func add<Value: Codable & Sendable>(
        _ view: NSView,
        model: ComposableSettings.ViewModel<Value>,
        key: UserSetting<Value>,
        to group: ComposableSettings.GroupView
    ) {
        add(view, name: key.name, model: model, to: group, refresh: {
            // Only some row views install a refresh handler; the slider
            // follows `onChange` alone.
            if model.refreshHandler != nil {
                model.refresh()
            } else {
                model.onChange?(model.value)
            }
        }, hasOverride: { [weak self] in
            self?.layered?.hasOverride(key) ?? false
        }, revert: { [weak self] in
            self?.layered?.removeOverride(key)
            // Forced: a field still being edited shows the override's value,
            // and ending the edit later would write it straight back.
            if model.refreshHandler != nil {
                model.revert()
            } else {
                model.onChange?(model.value)
            }
        })
    }

    /// The general form, for a row that is not a view model's.
    func add(
        _ view: NSView,
        name: String,
        model: ComposableSettings.AbstractViewModel?,
        to group: ComposableSettings.GroupView,
        refresh: @escaping () -> Void,
        hasOverride: @escaping () -> Bool,
        revert: @escaping () -> Void
    ) {
        group.addSettingSubview(view)
        let locked = isLocked(name)
        if locked { Self.setControls(enabled: false, in: view) }
        var marker: OverrideMarker?
        // A global-only row is locked for good and carries no marker; any
        // other row in pane scope does, hidden while it is locked.
        if isPaneScope, !BrowserSettings.globalOnlyKeyNames.contains(name) {
            let dot = OverrideMarker(revert: revert)
            group.setRowDecoration(leadingAccessory: dot, contextMenu: dot.rowMenu, for: view)
            marker = dot
        }
        let row = BrowserSettingsRow(
            name: name, model: model, view: view, group: group.title, isEnabled: !locked, marker: marker,
            refresh: refresh, hasOverride: hasOverride
        )
        rows.append(row)
        showMarker(of: row)
    }

    /// The marker shows an override only where one applies: never on a
    /// locked row, whose override the pane would ignore.
    private func showMarker(of row: BrowserSettingsRow) {
        row.marker?.show(overridden: row.isEnabled && row.hasOverride())
    }

    /// Records a button so a test can press it the way a click would.
    func register(_ button: ComposableSettings.ButtonViewModel, as identifier: String) {
        buttons[identifier] = button
    }

    private static func setControls(enabled: Bool, in view: NSView) {
        if let control = view as? NSControl { control.isEnabled = enabled }
        view.subviews.forEach { setControls(enabled: enabled, in: $0) }
    }

    // MARK: Following the store

    /// Re-reads a row whenever its setting changes — an edit elsewhere, an
    /// override dropped from the menu, Reset — and keeps its marker in step.
    /// `ClosureSettingObserver` announces only its own writes, so the store's
    /// `changes` is what tells a row the value under it moved. In pane scope
    /// the global store is followed too, for the locked rows, which read it
    /// directly.
    private func observeChanges() {
        var publishers = [store.changes]
        if let fallback = layered?.fallback { publishers.append(fallback.changes) }
        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                MainActor.assumeIsolated { self?.settingDidChange(name) }
            }
            .store(in: &cancellables)
    }

    func settingDidChange(_ name: String) {
        if Self.lockingKeyNames.contains(name) { updateLocks() }
        for row in rows(named: name) {
            row.refresh()
            showMarker(of: row)
        }
    }

    /// Re-decides every row's lock after a setting a lock depends on moved:
    /// a row that changes re-reads its value from its new source, and its
    /// controls and marker follow.
    private func updateLocks() {
        for row in rows where row.isEnabled == isLocked(row.name) {
            row.isEnabled.toggle()
            Self.setControls(enabled: row.isEnabled, in: row.view)
            row.refresh()
            showMarker(of: row)
        }
    }
}

// MARK: - Topic

/// One topic of the Browser panel. Every topic is listed by a title and a
/// symbol, binds through the panel's `BrowserSettingsBinding` and is never
/// made from a coder, so that is said once here rather than over and over
/// (`dry`). Internal so the Privacy and engine topics can live in
/// their own files.
@MainActor
class BrowserTopicPanel: ComposableSettings.SettingsPanelViewController {

    let binding: BrowserSettingsBinding

    init(title: String, symbol: String, binding: BrowserSettingsBinding) {
        self.binding = binding
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: title,
            icon: NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - General

@MainActor
private final class BrowserGeneralPanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "General", symbol: "gearshape", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "“New” Opens Tabs",
                body: "File ▸ New (⌘N) over a web browser window normally opens another web "
                    + "browser window. With this on, it opens a new tab in the window in front "
                    + "instead, as File ▸ New Tab does."
            ),
            .init(
                title: "Home Page",
                body: "What a new browser pane opens on when it has no page to go back to. "
                    + "Blank opens an empty page, with the address bar ready. A bare host "
                    + "such as example.com gets https:// in front, exactly as it would in "
                    + "the address bar. A pane that was closed on a page reopens on that "
                    + "page, not the home page."
            ),
            .init(
                title: "Page",
                body: "Zoom scales every page, from half size to three times, and applies "
                    + "to open panes at once. Minimum font size stops a page using text "
                    + "smaller than this many points; zero lets the page decide. "
                    + "JavaScript off applies to the next page each pane loads, and most "
                    + "of the web stops working without it; in a Chrome pane it applies at once. "
                    + "Block pop-up windows refuses a window a page opens on its own; a link that opens a new window "
                    + "still loads, in the same pane."
            ),
            .init(
                title: "User Agent",
                body: "The name the browser gives sites. Blank uses each engine's own: "
                    + "WebKit's, which is what Safari sends, in Safari panes, and "
                    + "Chromium's, which is what Chrome sends, in Chrome panes. A custom "
                    + "string applies to pages loaded after the change. Some sites "
                    + "serve a different page to a browser they do not recognise, which "
                    + "is the reason to change it and the reason to leave it alone."
            )
        ])
    }

    static let keywords: [String] = [
        "new opens tabs", "new tab", "home page", "start page", "zoom", "font size",
        "javascript", "pop-up", "popup", "user agent"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        // A window's New, not a pane's: shown only in the app's Settings.
        if !binding.isPaneScope {
            settingsView.addGroup(makeWindowsGroup())
        }
        settingsView.addGroup(makeHomeGroup())
        settingsView.addGroup(makePageGroup())
        settingsView.addGroup(makeUserAgentGroup())
    }

    private func makeWindowsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Windows")
        let checkbox = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "“New” opens tabs",
            setting: UserSettings.browserNewOpensTabs
        ))
        _ = checkbox.accessibilityID("settings.browser.general.new-opens-tabs")
        group.addSettingSubview(checkbox)
        return group
    }

    private func makeHomeGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Home Page")
        let home = binding.model(
            "Address", UserSettings.browserHomePage,
            explanation: "Blank opens an empty page. A host without a scheme gets https:// in front."
        )
        let field = ComposableSettings.TextEditView(with: home)
        field.textField.placeholderString = "example.com"
        _ = field.textField.accessibilityID("settings.browser.general.home-page")
        binding.add(field, model: home, key: UserSettings.browserHomePage, to: group)
        return group
    }

    private func makePageGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Page")

        let zoom = binding.range("Zoom", UserSettings.browserPageZoom, bounds: BrowserSettings.pageZoomRange)
        let zoomView = ComposableSettings.CaptionedSliderView(viewModel: zoom) { "\(Int(($0 * 100).rounded()))%" }
        _ = zoomView.slider.accessibilityID("settings.browser.general.zoom")
        binding.add(zoomView, model: zoom, key: UserSettings.browserPageZoom, to: group)

        let fontSize = binding.range(
            "Minimum font size", UserSettings.browserMinimumFontSize,
            bounds: BrowserSettings.minimumFontSizeRange,
            explanation: "In points. Zero lets each page choose its own."
        )
        let fontView = ComposableSettings.IntegerFieldView(viewModel: fontSize)
        _ = fontView.textField.accessibilityID("settings.browser.general.minimum-font-size")
        binding.add(fontView, model: fontSize, key: UserSettings.browserMinimumFontSize, to: group)

        let javaScript = binding.model(
            "Enable JavaScript", UserSettings.browserJavaScriptEnabled,
            explanation: "Applies to the next page each pane loads."
        )
        let javaScriptView = ComposableSettings.CheckboxView(with: javaScript)
        _ = javaScriptView.toggle.accessibilityID("settings.browser.general.javascript")
        binding.add(javaScriptView, model: javaScript, key: UserSettings.browserJavaScriptEnabled, to: group)

        let popups = binding.model("Block pop-up windows", UserSettings.browserBlocksPopups)
        let popupsView = ComposableSettings.CheckboxView(with: popups)
        _ = popupsView.toggle.accessibilityID("settings.browser.general.block-popups")
        binding.add(popupsView, model: popups, key: UserSettings.browserBlocksPopups, to: group)

        return group
    }

    private func makeUserAgentGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "User Agent")
        let agent = binding.model(
            "Custom user agent", UserSettings.browserCustomUserAgent,
            explanation: "Blank sends each browser's own. Applies to pages loaded after the change."
        )
        let field = ComposableSettings.TextEditView(with: agent)
        field.textField.placeholderString = "Default"
        _ = field.textField.accessibilityID("settings.browser.general.user-agent")
        binding.add(field, model: agent, key: UserSettings.browserCustomUserAgent, to: group)
        return group
    }
}

// MARK: - History

/// The visit history is one store for the whole app, so in pane scope this
/// topic shows only "Record history", which a pane may override; the list and
/// its clear buttons act globally and stay in the Settings window.
@MainActor
private final class BrowserHistoryPanel: BrowserTopicPanel {

    private let history: BrowserHistoryStore?
    private let searchField = NSSearchField()
    private let countRow = ComposableSettings.ValueRowView(title: "Visits recorded", value: "0")
    private var table: ComposableSettings.EditableTableCard?
    private var visits: [BrowserVisit] = []
    /// The read in flight. One at a time, so a search typed quickly cannot
    /// have an older answer land after a newer one.
    private var reloadTask: Task<Void, Never>?

    init(history: BrowserHistoryStore?, binding: BrowserSettingsBinding) {
        self.history = history
        super.init(title: "History", symbol: "clock.arrow.circlepath", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        let recording = ComposableSettings.PanelHelp.Topic(
            title: "Recording",
            body: "With recording on, every page a browser pane finishes loading is "
                + "written down: its address, its title and when. Off, nothing new is "
                + "written and what is already recorded stays until you clear it. Keep "
                + "visits for decides how long a visit is kept: anything older is "
                + "forgotten the next time a browser pane opens."
        )
        if binding.isPaneScope {
            return ComposableSettings.PanelHelp(topics: [
                recording,
                .init(
                    title: "One History",
                    body: "Every browser pane records into the same history, so how long "
                        + "visits are kept, the list of visits and Clear History are in the "
                        + "Settings window's Browser topics. Here you decide only whether "
                        + "this pane records."
                )
            ])
        }
        return ComposableSettings.PanelHelp(topics: [
            recording,
            .init(
                title: "Visits",
                body: "How many visits are recorded, and a search over them — type part "
                    + "of an address or a title and the list below narrows to the "
                    + "matches, newest first."
            ),
            .init(
                title: "Recent Visits",
                body: "The latest two hundred visits, or the matches for the search. "
                    + "Select one and press − to forget it. Clear History forgets every "
                    + "visit at once; it does not touch cookies or site data, which "
                    + "have their own topic. The pages a pane can go back to are "
                    + "the browser engine's own and are not listed here."
            )
        ])
    }

    static let keywords: [String] = ["history", "visits", "recent", "clear history", "forget"]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeRecordingGroup())
        guard !binding.isPaneScope else { return }
        settingsView.addGroup(makeVisitsGroup())
        let table = makeTable()
        self.table = table
        settingsView.addGroup(table)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        guard !binding.isPaneScope else { return }
        reload()
    }

    private func makeRecordingGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Recording")

        let records = binding.model(
            "Record history", UserSettings.browserRecordsHistory,
            explanation: history == nil
                ? "This app has no history store, so nothing is recorded whatever this says."
                : nil
        )
        let recordsView = ComposableSettings.CheckboxView(with: records)
        _ = recordsView.toggle.accessibilityID("settings.browser.history.record")
        binding.add(recordsView, model: records, key: UserSettings.browserRecordsHistory, to: group)

        guard !binding.isPaneScope else { return group }

        let retention = binding.choice(
            "Keep visits for", UserSettings.browserHistoryRetention,
            choices: BrowserHistoryRetention.allCases.map { .init(label: $0.label, value: $0) },
            explanation: "Older visits are forgotten when a browser pane opens."
        )
        let retentionView = ComposableSettings.PopupMenuChoiceView(viewModel: retention)
        _ = retentionView.popUpButton.accessibilityID("settings.browser.history.retention")
        binding.add(retentionView, model: retention, key: UserSettings.browserHistoryRetention, to: group)

        return group
    }

    private func makeVisitsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Visits")
        _ = countRow.valueLabel.accessibilityID("settings.browser.history.count")
        group.addSettingSubview(countRow)

        searchField.placeholderString = "Search addresses and titles"
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.sendsSearchStringImmediately = true
        searchField.translatesAutoresizingMaskIntoConstraints = false
        _ = searchField.accessibilityID("settings.browser.history.search")
        group.addSettingSubview(searchField)
        return group
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Recent Visits",
            columns: [
                .init(id: "when", title: "When", width: 130),
                .init(id: "title", title: "Title", width: 180),
                .init(id: "url", title: "Address", width: 260)
            ],
            emptyMessage: history == nil ? "No history store." : "No visits recorded.",
            visibleRows: 10,
            accessibilityPrefix: "settings.browser.history.visits"
        )
        // A history is removed from, never added to by hand.
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in
            guard let self, let id = Int64(rowID) else { return }
            self.change("Could not forget that visit") { try $0.remove(visit: id) }
        }
        let clear = table.addFooterButton(
            title: "Clear History…", identifier: "settings.browser.history.clear"
        ) { [weak self] in
            self?.clearHistory()
        }
        clear.isEnabled = history != nil
        return table
    }

    @objc private func searchChanged() {
        reload()
    }

    private func clearHistory() {
        guard history != nil else { return }
        ComposableSettings.Alerts.confirmDestructive(
            "Clear all browsing history?",
            detail: "Every recorded visit is forgotten. Cookies and site data are not affected.",
            actionTitle: "Clear",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            self.change("Could not clear history") { try $0.removeAll() }
        }
    }

    /// A write to the history, off the main thread, then the table reread.
    /// An error is reported on the window and the reread still runs: what
    /// the file holds is the truth to show.
    private func change(_ failure: String, _ work: @escaping @Sendable (BrowserHistoryStore) throws -> Void) {
        guard let history else { return }
        Task { [weak self] in
            do {
                try await history.perform(work)
            } catch {
                guard let self else { return }
                ComposableSettings.Alerts.report("\(failure): \(error.localizedDescription)", on: self.view.window)
            }
            self?.reload()
        }
    }

    private func reload() {
        reloadTask?.cancel()
        guard let history else {
            show([], count: 0)
            return
        }
        let text = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        reloadTask = Task { [weak self] in
            do {
                let (visits, count) = try await history.perform { store in
                    let visits = try text.isEmpty ? store.recent() : store.search(text)
                    return (visits, try store.count())
                }
                guard let self, !Task.isCancelled else { return }
                self.show(visits, count: count)
            } catch {
                guard let self, !Task.isCancelled else { return }
                ComposableSettings.Alerts.report(
                    "Could not read history: \(error.localizedDescription)", on: self.view.window)
                self.show([], count: nil)
            }
        }
    }

    /// Puts `visits` in the table; the count row keeps its number when the
    /// read that would have refreshed it failed.
    private func show(_ visits: [BrowserVisit], count: Int?) {
        self.visits = visits
        if let count { countRow.value = String(count) }
        table?.setRows(visits.map { visit in
            ComposableSettings.EditableTableRow(id: String(visit.id), cells: [
                "when": .text(LocalTimeText.dayAndClock(visit.visitedAt, timeZone: .current, locale: .current)),
                "title": visit.title.isEmpty ? .placeholder("Untitled") : .text(visit.title),
                "url": .text(visit.url.absoluteString)
            ])
        })
    }
}

// MARK: - Cookies

/// Accept cookies and private browsing, for Safari and Chrome panes alike. In
/// global scope the title says the global jar; in pane scope it names
/// whichever jar the pane is on, since Accept cookies belongs to the jar.
/// What each engine has already kept is listed in its own topic.
@MainActor
private final class BrowserCookiesPanel: BrowserTopicPanel {

    init(title: String, binding: BrowserSettingsBinding) {
        super.init(title: title, symbol: "tray.full", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Cookies",
                body: "Accept cookies decides whether sites may set cookies at all, in "
                    + "Safari and Chrome panes alike; there is no first-party-only middle. "
                    + "Off, most sites cannot keep you signed in. It belongs to the jar, "
                    + "not the pane, so in a pane's settings it can be changed only while "
                    + "the pane has a jar of its own. Private browsing gives each new "
                    + "browser pane a store of its own that is thrown away when the pane "
                    + "closes, so nothing it visits is kept. It is set for all browser "
                    + "panes in the Settings window, and applies to panes opened after the "
                    + "change; a pane already open keeps the store it was made with. What "
                    + "each browser has already kept is listed and removed from its own "
                    + "topic, Safari or Chrome."
            )
        ])
    }

    static let keywords: [String] = ["cookies", "private browsing", "incognito", "sign out"]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Cookies")

        let accepts = binding.model(
            "Accept cookies", UserSettings.browserAcceptsCookies,
            explanation: "Off, sites cannot keep you signed in."
        )
        let acceptsView = ComposableSettings.CheckboxView(with: accepts)
        _ = acceptsView.toggle.accessibilityID("settings.browser.cookies.accept-cookies")
        binding.add(acceptsView, model: accepts, key: UserSettings.browserAcceptsCookies, to: group)

        let privateBrowsing = binding.model(
            "Private browsing", UserSettings.browserPrivateBrowsing,
            explanation: "New browser panes keep nothing once closed. Applies to panes opened after the change."
        )
        let privateView = ComposableSettings.CheckboxView(with: privateBrowsing)
        _ = privateView.toggle.accessibilityID("settings.browser.cookies.private-browsing")
        binding.add(privateView, model: privateBrowsing, key: UserSettings.browserPrivateBrowsing, to: group)

        settingsView.addGroup(group)
    }
}

// MARK: - Media and permissions

@MainActor
private final class BrowserMediaPanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Media and Permissions", symbol: "play.rectangle", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Playback",
                body: "Autoplay decides whether a page may start video or audio without a "
                    + "click: allowed, only without sound (the usual browser default — a "
                    + "muted video plays, one with sound waits), or never. A Safari pane "
                    + "fixes it when the pane is created: in the Settings window it applies "
                    + "to Safari panes opened after the change, and in a Safari pane's "
                    + "settings when the sheet closes. Chromium reads it once when it "
                    + "starts, so Chrome panes follow it the next time the app opens. Never "
                    + "in a Chrome pane still lets a muted video play: Chromium has no "
                    + "policy that stops one. AirPlay is Safari's alone and is in the "
                    + "Safari topic."
            ),
            .init(
                title: "Camera and Microphone",
                body: "What happens when a page asks for the camera or microphone. Ask "
                    + "each time shows a sheet on the pane's window naming the site and "
                    + "the device, and the answer holds for that page. Always allow grants "
                    + "every request without asking; never allow refuses them all. macOS "
                    + "still asks once, the first time the app itself uses either device."
            )
        ])
    }

    static let keywords: [String] = [
        "autoplay", "video", "audio", "camera", "microphone", "permissions", "webcam"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makePlaybackGroup())
        settingsView.addGroup(makeCaptureGroup())
    }

    private func makePlaybackGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Playback")

        let autoplay = binding.choice(
            "Autoplay", UserSettings.browserAutoplay,
            choices: BrowserAutoplayPolicy.allCases.map { .init(label: $0.label, value: $0) },
            explanation: autoplayNote
        )
        let autoplayView = ComposableSettings.PopupMenuChoiceView(viewModel: autoplay)
        _ = autoplayView.popUpButton.accessibilityID("settings.browser.media.autoplay")
        binding.add(autoplayView, model: autoplay, key: UserSettings.browserAutoplay, to: group)

        return group
    }

    /// When autoplay takes effect differs by engine: a Safari pane fixes it
    /// when its page is made, Chromium once when it starts.
    private var autoplayNote: String {
        guard let pane = binding.pane else {
            return "Applies to Safari panes opened after the change, and to Chrome "
                + "panes the next time the app opens."
        }
        switch pane.engineKind {
        case .safari: return binding.constructionNote(for: UserSettings.browserAutoplay.name)
        case .chrome: return "Chrome panes all follow the Settings window's value, "
            + "from the next time the app opens."
        }
    }

    private func makeCaptureGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Camera and Microphone")
        let capture = binding.choice(
            "When a page asks", UserSettings.browserMediaCapture,
            choices: BrowserMediaCapturePolicy.allCases.map { .init(label: $0.label, value: $0) }
        )
        let captureView = ComposableSettings.PopupMenuChoiceView(viewModel: capture)
        _ = captureView.popUpButton.accessibilityID("settings.browser.media.capture")
        binding.add(captureView, model: capture, key: UserSettings.browserMediaCapture, to: group)
        return group
    }
}

// MARK: - Downloads

@MainActor
private final class BrowserDownloadsPanel: BrowserTopicPanel {

    private let folderRow = ComposableSettings.ValueRowView(title: "Folder")

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Downloads", symbol: "arrow.down.circle", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Location",
                body: "Where a file a page offers — a zip, a disk image, anything the "
                    + "browser cannot show — is saved. Your Downloads folder unless you "
                    + "choose another; Use Downloads Folder puts it back. A file whose "
                    + "name is already taken is saved as name 2, name 3 and so on, the "
                    + "way the app names every duplicate. Ask where to save each file shows a save sheet "
                    + "on the pane's window instead, starting in this folder."
            )
        ])
    }

    static let keywords: [String] = ["downloads", "download folder", "save", "where to save"]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Location")
        let key = UserSettings.browserDownloadDirectory

        _ = folderRow.valueLabel.accessibilityID("settings.browser.downloads.folder")
        binding.add(folderRow, name: key.name, model: nil, to: group, refresh: { [weak self] in
            self?.showFolder()
        }, hasOverride: { [weak binding] in
            binding?.layered?.hasOverride(key) ?? false
        }, revert: { [weak binding] in
            binding?.layered?.removeOverride(key)
        })

        let choose = ComposableSettings.ButtonViewModel(title: "Choose Folder…") { [weak self] in
            self?.chooseFolder()
        }
        let chooseView = ComposableSettings.ButtonView(viewModel: choose, placement: .leading)
        _ = chooseView.button.accessibilityID("settings.browser.downloads.choose")
        group.addSettingSubview(chooseView)

        let useDefault = ComposableSettings.ButtonViewModel(title: "Use Downloads Folder") { [weak self] in
            self?.useDownloadsFolder()
        }
        let useDefaultView = ComposableSettings.ButtonView(viewModel: useDefault, placement: .leading)
        _ = useDefaultView.button.accessibilityID("settings.browser.downloads.use-default")
        group.addSettingSubview(useDefaultView)

        let asks = binding.model("Ask where to save each file", UserSettings.browserAsksDownloadLocation)
        let asksView = ComposableSettings.CheckboxView(with: asks)
        _ = asksView.toggle.accessibilityID("settings.browser.downloads.ask")
        binding.add(asksView, model: asks, key: UserSettings.browserAsksDownloadLocation, to: group)

        settingsView.addGroup(group)
        showFolder()
    }

    private func showFolder() {
        folderRow.value = (BrowserSettings.downloadDirectory(in: binding.store).path as NSString)
            .abbreviatingWithTildeInPath
    }

    /// Globally, forgetting the folder is what puts Downloads back. In a pane
    /// the blank value is written instead: forgetting would drop the override
    /// and hand the pane whatever folder the global setting names.
    private func useDownloadsFolder() {
        if binding.isPaneScope {
            binding.store.set("", for: UserSettings.browserDownloadDirectory)
        } else {
            binding.store.remove(UserSettings.browserDownloadDirectory)
        }
    }

    private func chooseFolder() {
        ComposableSettings.Alerts.chooseFolder(
            on: view.window,
            prompt: "Choose",
            message: "Downloads from browser panes are saved here."
        ) { [weak self] url in
            guard let url else { return }
            self?.binding.store.set(url.path, for: UserSettings.browserDownloadDirectory)
        }
    }
}

// MARK: - Reset

/// Globally, every browser setting back to its default. In a pane, every
/// override dropped, so the pane follows the global settings again.
@MainActor
private final class BrowserResetPanel: BrowserTopicPanel {

    static let useGlobalIdentifier = "settings.browser.reset.use-global"

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Reset", symbol: "arrow.counterclockwise", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            binding.isPaneScope
                ? .init(
                    title: "Use Global Settings",
                    body: "Drops every setting this pane overrides, so each topic shows the "
                        + "global value from the Settings window again and follows it from "
                        + "then on. Overrides fixed when the pane's page is made — the jar, "
                        + "console capture and, in a Safari pane, the HTTPS upgrade, autoplay "
                        + "and AirPlay — take effect when this sheet closes, by rebuilding the "
                        + "pane. Agent Privacy goes back to the global switch too; the pane's "
                        + "own privacy words are kept."
                )
                : .init(
                    title: "Reset",
                    body: "Puts every setting in the Web Browser topics, Safari's and "
                        + "Chrome's included, back to its default — the "
                        + "value each control shows on a fresh install. Settings only: "
                        + "history and site data are kept, and are cleared from their own "
                        + "topics. Open browser panes pick up the defaults the same way they "
                        + "pick up any other change; a pane's own overrides are kept. Agent "
                        + "access, Agent while paused, the cookie and storage jar and Agent "
                        + "Privacy are kept as they are, so a reset never hands a page or the "
                        + "privacy words back to models, nor deletes site data."
                )
        ])
    }

    static let keywords: [String] = ["reset", "defaults", "restore", "use global settings"]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Reset")
        if let layered = binding.layered {
            // Nothing is lost that the Settings window does not still hold,
            // so this one does not ask first.
            let useGlobal = ComposableSettings.ButtonViewModel(title: "Use Global Settings for This Pane") {
                layered.removeAllOverrides(withPrefix: "browser.")
            }
            let useGlobalView = ComposableSettings.ButtonView(viewModel: useGlobal, placement: .leading)
            _ = useGlobalView.button.accessibilityID(Self.useGlobalIdentifier)
            binding.register(useGlobal, as: Self.useGlobalIdentifier)
            group.addSettingSubview(useGlobalView)
        } else {
            let reset = ComposableSettings.ButtonViewModel(title: "Reset Browser Settings…") { [weak self] in
                self?.confirmReset()
            }
            let resetView = ComposableSettings.ButtonView(viewModel: reset, placement: .leading)
            _ = resetView.button.accessibilityID("settings.browser.reset.reset")
            binding.register(reset, as: "settings.browser.reset.reset")
            group.addSettingSubview(resetView)
        }
        settingsView.addGroup(group)
    }

    private func confirmReset() {
        ComposableSettings.Alerts.confirmDestructive(
            "Reset all Browser settings?",
            detail: "Every Browser setting returns to its default, except agent access, Agent Privacy and storage. "
                + "History and site data are not affected.",
            actionTitle: "Reset",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            BrowserSettings.reset(in: self.binding.store)
        }
    }
}
