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
/// Behavior, Appearance, Privacy and Security, Downloads, the extensions
/// topics, Chrome, Reset — and the chosen topic's controls on the right, the
/// shape the Language Servers panel has. Chrome holds what only Chromium has;
/// WebKit's own rows (AirPlay, Web Inspector, Protection, Site Data) sit in
/// the shared topics and are left out of a Chrome pane's sheet. In a pane's
/// sheet only the pane's own engine topic is listed. A control that moves
/// between topics keeps its setting key (`keys-never-change`).
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
    ///     none, and Privacy and Security's Record history says so.
    ///   - siteData: WebKit's persistent store, the global jar, which Manage
    ///     Site Data… lists. Global scope only: in pane scope the window lists
    ///     the pane's own data store. A test hands in a non-persistent one.
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
                        + "keep and do, and where downloads land. Chrome holds what only "
                        + "Chromium has; General's AirPlay and Web Inspector, Privacy and "
                        + "Security's Protection and Site Data, and Extensions are Safari's "
                        + "alone; every other setting applies to both. The history itself is "
                        + "not a setting: Browser ▸ Show History opens it. Pick a topic on "
                        + "the left."
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
        BrowserGeneralPanel.keywords + BrowserBehaviorPanel.keywords + BrowserAppearancePanel.keywords
            + BrowserPrivacySettingsPanel.keywords
            + BrowserDownloadsPanel.keywords
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
        addPanel(BrowserBehaviorPanel(binding: binding))
        addPanel(BrowserAppearancePanel(binding: binding))
        addPanel(BrowserPrivacySettingsPanel(
            binding: binding,
            siteData: showsSafariTopic ? siteDataResolver : nil,
            hasHistoryStore: history != nil
        ))
        addPanel(BrowserDownloadsPanel(binding: binding))
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

    /// True in the Settings window and in a Safari pane's sheet: where
    /// WebKit's own groups (Protection, Site Data) and the Extensions
    /// topic belong. A Chrome pane's sheet leaves them out, since they would
    /// change nothing the pane does. Chrome's topic shows when the host links
    /// Chromium, or in a Chrome pane's sheet.
    var showsSafariTopic: Bool {
        guard let pane = binding.pane else { return true }
        return pane.engineKind == .safari
    }

    /// The Extensions topic shows wherever the Safari topic does,
    /// once the app has said where extensions live, on macOS 15.4 and later.
    var safariExtensionsAvailable: Bool {
        showsSafariTopic && SafariExtensionSupport.isAvailable && safariExtensionsProfile != nil
    }

    private var safariExtensionsKeywords: [String] {
        guard #available(macOS 15.4, *), safariExtensionsAvailable else { return [] }
        return SafariExtensionsTopicPanel.keywords
    }

    /// The profile the Extensions topic lists: the global jar's in the
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

    /// The site data Manage Site Data… acts on, asked when it is pressed:
    /// the global jar's in the Settings window, and in a pane's sheet the
    /// jar its Storage setting names at that moment
    /// (`site-data-window-scope`).
    private var siteDataResolver: () -> BrowserSiteData? {
        let global = siteData
        guard let pane = binding.pane else { return { global } }
        let settings = binding.store
        return { [weak pane] in pane.flatMap { Self.siteData(for: $0, under: settings) } }
    }

    /// The pane the Extensions topic opens a page (an extension's options,
    /// the Web Store) beside when the pane is on a jar of its own: the pane
    /// whose sheet it is. The Settings window lists the global jar, whose
    /// pages open in the extensions window instead, so it has none.
    private var extensionsDestination: () -> WebBrowserPaneViewController? {
        guard let pane = binding.pane else { return { nil } }
        return { [weak pane] in pane }
    }

    // MARK: Site data and jars, by scope

    /// A Safari pane's own data store, whichever jar it resolved to: the one
    /// its web view was built on, because a private or fail-closed jar is a
    /// store no second call would hand back. `nil` for a Chrome pane. The
    /// pane's sheet and its Privacy popover both list it.
    static func siteData(for pane: WebBrowserPaneViewController) -> BrowserSiteData? {
        guard let pane = pane as? SafariBrowserPaneViewController else { return nil }
        return BrowserSiteData(dataStore: pane.webView.configuration.websiteDataStore)
    }

    /// The site data of the jar `settings` name for a Safari pane, asked when
    /// Manage Site Data… is pressed, so a Storage change made in the same
    /// sheet is the jar the window lists and Remove All… empties. The web
    /// view's own store while the settings still name the jar it was built
    /// on, since a private or fail-closed jar is a store no second call would
    /// hand back. `nil` for a Chrome pane.
    static func siteData(
        for pane: WebBrowserPaneViewController, under settings: SettingsStore
    ) -> BrowserSiteData? {
        guard let pane = pane as? SafariBrowserPaneViewController else { return nil }
        guard pane.namesBuiltJar(under: settings) else {
            return BrowserSiteData(dataStore: pane.siteDataStore(under: settings))
        }
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

    /// The same for a setting only WebKit has: in the Settings window it
    /// applies to Safari panes opened after the change, not every pane.
    func safariConstructionNote(for name: String) -> String {
        isPaneScope ? constructionNote(for: name) : "Applies to Safari panes opened after the change."
    }

    // MARK: View models

    /// Reads and writes for `key`. A locked row reads the global value and
    /// drops writes, so it cannot create the override it is locked against.
    /// Asked at each read and write, since a lock can change while the
    /// sheet is up.
    func accessors<Value: Codable & Sendable>(
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
    /// The model may show the setting as another type (a "Disable …"
    /// checkbox over an enum); only the key's name and override are used.
    func add<ModelValue: Codable & Sendable, Value: Codable & Sendable>(
        _ view: NSView,
        model: ComposableSettings.ViewModel<ModelValue>,
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
        // A pane's tab-position row shows the app-wide value while it has no
        // override, so a change to that value is a change to the row.
        let names = name == UserSettings.tabsPositions.name
            ? [name, UserSettings.browserTabsPositions.name] : [name]
        for row in names.flatMap({ rows(named: $0) }) {
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

/// What is the browser's own rather than a page's: the name it gives sites,
/// and the two WebKit-only switches that were the Safari topic's — AirPlay
/// and Web Inspector. A Chrome pane's sheet leaves those two out, since
/// Chromium honours neither (`principle-of-least-astonishment`).
@MainActor
private final class BrowserGeneralPanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "General", symbol: "gearshape", binding: binding)
    }

    /// False only in a Chrome pane's sheet.
    private var showsSafariOnlyGroups: Bool {
        binding.pane?.engineKind != .chrome
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        var topics: [ComposableSettings.PanelHelp.Topic] = [
            .init(
                title: "User Agent",
                body: "The name the browser gives sites. Blank uses each engine's own: "
                    + "WebKit's, which is what Safari sends, in Safari panes, and "
                    + "Chromium's, which is what Chrome sends, in Chrome panes. A custom "
                    + "string applies to pages loaded after the change. Some sites "
                    + "serve a different page to a browser they do not recognise, which "
                    + "is the reason to change it and the reason to leave it alone."
            )
        ]
        guard showsSafariOnlyGroups else { return ComposableSettings.PanelHelp(topics: topics) }
        topics.append(.init(
            title: "Media",
            body: "Allow AirPlay lets a page's video offer the AirPlay control, in Safari "
                + "panes only. It is fixed when a Safari pane's web view is made: in the "
                + "Settings window it applies to panes opened after the change, and in a "
                + "pane's settings when the sheet closes."
        ))
        topics.append(.init(
            title: "Web Inspector",
            body: "Safari's Web Inspector, attached to a Safari pane's page. With it "
                + "on, right-click a page and choose Inspect Element, or open Safari's "
                + "Develop menu and find this app under your Mac's name. Off is the "
                + "default because an inspectable page is one any process with "
                + "Safari's privileges can read. Chrome panes have their own developer "
                + "tools."
        ))
        return ComposableSettings.PanelHelp(topics: topics)
    }

    /// Every control's title, then the other words someone might search by.
    static let keywords: [String] = [
        "Custom user agent", "Allow AirPlay", "Allow Web Inspector",
        "user agent", "airplay", "Web Inspector", "inspect element", "develop"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeUserAgentGroup())
        if showsSafariOnlyGroups {
            settingsView.addGroup(makeMediaGroup())
            settingsView.addGroup(makeInspectorGroup())
        }
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

    private func makeMediaGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Media")
        let airPlay = binding.model(
            "Allow AirPlay", UserSettings.browserAllowsAirPlay,
            explanation: binding.safariConstructionNote(for: UserSettings.browserAllowsAirPlay.name)
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
                        + "history and site data are kept, and are cleared from the History "
                        + "window and from Manage Site Data…. Open browser panes pick up the "
                        + "defaults the same way they "
                        + "pick up any other change; a pane's own overrides are kept. Agent "
                        + "access, Agent while paused, the cookie and storage jar and Agent "
                        + "Privacy, Hide Images included, are kept as they are, so a reset never "
                        + "hands a page, its images or the privacy words back to models, nor "
                        + "deletes site data."
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
                // A private window's private browsing is what makes it that
                // window, not a pane preference; dropping it would move the
                // window onto the persistent data store under its "Private"
                // title.
                let isPrivateWindow = layered.hasOverride(UserSettings.browserPrivateBrowsing)
                    && layered.get(UserSettings.browserPrivateBrowsing)
                layered.removeAllOverrides(
                    withPrefix: "browser.",
                    keeping: isPrivateWindow ? [UserSettings.browserPrivateBrowsing.name] : []
                )
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
            detail: "Every Browser setting returns to its default, except agent access, "
                + "Agent Privacy (Hide Images included) and storage. "
                + "History and site data are not affected.",
            actionTitle: "Reset",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            BrowserSettings.reset(in: self.binding.store)
        }
    }
}
