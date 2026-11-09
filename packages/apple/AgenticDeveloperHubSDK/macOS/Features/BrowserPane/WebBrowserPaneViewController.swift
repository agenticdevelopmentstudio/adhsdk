//
//  WebBrowserPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import os
import WebKit
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// A web browser in a pane: an address bar over a page some `BrowserEngine`
/// renders, remembering where it was so a project window reopens on the same
/// page. `SafariBrowserPaneViewController` puts WebKit under it,
/// `ChromeBrowserPaneViewController` (the Chromium framework) Chromium.
///
/// Everything a browser pane is regardless of engine lives here — the bar,
/// the remembered address, history, downloads' destination, the media
/// question, the drive seam a model reaches it through, and every session
/// privacy setting: the input gate, the activation shield, Pause Events, the
/// storage jar and the cookie policy — so the two panes differ in exactly one
/// thing, the engine, and a privacy setting means the same on either
/// (`separation-of-concerns`, `dry`). A subclass hands in an engine factory
/// and names itself; it overrides nothing else.
///
/// The engine is made from a factory rather than handed in, because some
/// settings are fixed when an engine is made — the storage jar above all —
/// and a pane that moves jars throws its engine away and makes another on the
/// page it was showing (`rebuildEngine`).
///
/// Deliberately *not* the extension webview. That one shows HTML an extension
/// hands it behind a custom scheme and opens every link in the user's default
/// browser; this one navigates the open web in place, which is what the word
/// "browser" means to the person who split a pane off for it
/// (`principle-of-least-astonishment`).
///
/// The page area is tabs, like the Document pane's: a `MultiTabbedViewController`
/// under the address bar, one engine per tab, and the bar, the title and the
/// drive seam all follow the tab in front. A window a page opens — a
/// `target="_blank"` link, a `window.open()`, a sign-in or 2FA window — opens
/// as a new tab whose engine is tied to the opener, so `window.opener` works
/// and the window can post its answer back and close itself
/// (`browserEngine(_:didOpenPopup:)`, `browserEngineDidRequestClose`).
///
/// What it remembers in its own state store is two keys: `tabs`, every tab's
/// address and title and which was in front, and `url`, the front tab's
/// address — kept so a pane stored before tabs reopens where it was.
@MainActor
open class WebBrowserPaneViewController: NSViewController {

    /// Turns what the user typed into something an engine can load.
    ///
    /// A string with a scheme loads as written. Anything else is taken to be a
    /// host, and `https` is put in front of it — the user who types
    /// `example.com` means the site, not a file named that. Whitespace around
    /// the entry is trimmed; whitespace inside it means it was not an address,
    /// and the entry is refused rather than searched for, because a search
    /// engine is a choice this pane does not make (`explicit-over-implicit`).
    /// Returns `nil` for an entry that resolves to nothing loadable.
    public static func resolveAddress(_ entry: String) -> URL? {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty,
           // `localhost:8080` parses as scheme `localhost` with no host; a real
           // scheme carries `//` or is one of the few that never does.
           trimmed.contains("://") || ["about", "mailto", "data", "javascript"].contains(scheme.lowercased()) {
            return url
        }
        return URL(string: "https://" + trimmed)
    }

    /// The state-store key the current address lives under.
    static let addressKey = "url"

    /// The state-store key the tab list lives under (`StoredBrowserTabs`).
    static let tabsKey = "tabs"

    /// What a tab with no page and no title is called.
    public static let newTabTitle = "New Tab"

    /// The page shown when the store remembers nothing and no home was given.
    public static let blankPage = URL(string: "about:blank")!

    /// What a new pane jar is named before its page has a title.
    public static let untitledLabel = "Browser"

    public typealias ResolvedJar = BrowserResolvedJar
    public typealias EngineFactory = @MainActor (BrowserEngineConfiguration) -> BrowserEngine

    /// The engine rendering the page in the tab in front. Changes with the
    /// tab, and is replaced whole when the pane moves to another storage jar
    /// (`rebuildEngine`).
    public private(set) var engine: BrowserEngine

    /// The pane's tabs, in bar order. Never empty: closing the last tab
    /// empties it instead.
    private var tabs: [BrowserTab] = []
    /// The tab in front, whose engine is `engine`.
    private var activeTab: BrowserTab
    /// The tab bar and the page area under the address bar.
    private let tabStrip = MultiTabbedViewController()
    /// The tab list last written to the store, so an unchanged list is not
    /// written again.
    private var lastStoredTabs: String?
    /// Set while the strip is being handed the tabs, whose activations are
    /// not the user's.
    private var isInstallingTabs = false

    private let makeEngine: EngineFactory
    /// Told about each engine a rebuild makes, after the pane has wired it,
    /// so a subclass can carry its own per-engine state (a test seam) over.
    var onEngineMade: ((BrowserEngine) -> Void)?
    private let store: PaneStateStore
    let settings: SettingsStore
    private let history: BrowserHistoryStore?
    private let fallbackHomeURL: URL
    /// Which engine draws the page; what the model tools report and open by.
    public let engineKind: BrowserEngineKind
    private let minimizedSymbol: String
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// Which project, worktree and node this pane belongs to.
    public let paneContext: BrowserPaneContext
    /// The pane's own layered settings, when the factory built it with one.
    public var paneSettings: LayeredSettingsStore? { settings as? LayeredSettingsStore }
    /// Whether the user has paused this pane's events (Pause Events, spec
    /// section 7). Set only through `setEventsPaused(_:)`, so the gate, the
    /// shield and the badge always move with it. Not persisted: a relaunch
    /// reloads the page anyway, and a pane that came back paused would look
    /// broken.
    public private(set) var isEventsPaused = false
    /// Asked to open a log of the events this pane delivered and withheld
    /// (the debug-only Show Browser Log gear item). The host wires it.
    public var onShowBrowserLog: ((WebBrowserPaneViewController) -> Void)?
    /// The pane's effective Agent access, read from its own layered settings
    /// so a per-pane override counts.
    public var agentAccess: BrowserAgentAccess { settings.get(UserSettings.browserPrivacyAgentAccess) }
    /// Whether the agent is held off this pane: its events are paused and its
    /// Agent while paused setting says the agent pauses too.
    public var isPausedForAgent: Bool {
        isEventsPaused && settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
    }

    /// What the page wrote to `console.*` since the last navigation. The
    /// pane's, so it outlives an engine rebuilt under it.
    public let consoleLog = BrowserConsoleLog()
    /// What this pane delivered to its page, withheld from it, and did around
    /// it (spec section 12). In memory only, and recorded in every build; only
    /// debug builds have a pane that shows it.
    public let eventLog = BrowserEventLog()
    /// Whether the pane has left the layout for good
    /// (`paneContentWillBeDiscarded`), so a log pane stops following it.
    public private(set) var isDiscarded = false
    /// The jar the current engine was built on.
    public private(set) var resolvedJar: ResolvedJar
    /// Whether the current engine captures the page console: read once, where
    /// the engine is built, and used for the engine and the automation alike.
    /// A construction-time setting; a change waits for a rebuild.
    private(set) var capturesConsole: Bool
    /// The construction-time settings the current engine was built with
    /// (`BrowserSettings.constructionSnapshot`), so closing the settings
    /// sheet can tell whether the pane still matches them.
    private(set) var builtConstructionSettings: [String: String]
    /// The construction-time settings in effect when the pane's settings
    /// sheet opened; `nil` while no sheet is up. Closing the sheet rebuilds
    /// only for what changed since then, so a global change made earlier —
    /// which an open pane does not follow (spec sections 3 and 4) — is never
    /// applied by a Done that changed nothing.
    private(set) var settingsSheetSnapshot: [String: String]?
    /// Whether the pane's settings sheet is up. While it is, a jar change
    /// waits for the sheet to close rather than rebuilding under it.
    var isSettingsSheetOpen: Bool { settingsSheetSnapshot != nil }
    /// What the jar's row was last named, so a title change writes only when
    /// the name it would write is new.
    private var jarLabel: String?
    /// When `jarLabel` may next be rewritten.
    private var jarLabelGate = BrowserJarLabelGate()

    private var builtAutomation: BrowserAutomation?
    /// The driving seam a model reaches the pane through. Built on first
    /// use so a pane nobody drives pays nothing for it, and moved to the new
    /// engine on a rebuild, so a handle taken before it still drives the page
    /// on screen.
    public var automation: BrowserAutomation {
        if let builtAutomation { return builtAutomation }
        let automation = BrowserAutomation(driver: engine, console: consoleLog)
        automation.isConsoleCaptureOn = capturesConsole
        automation.onDriveStateChange = { [weak self] driving in
            guard let self else { return }
            // The start of every drive is a use of this pane, so it becomes
            // the default for the next caller that names none.
            if driving { BrowserPaneFocus.shared.note(self) }
            self.drivenBadge.setDriven(driving)
        }
        automation.onAction = { [weak self] name, succeeded in
            self?.eventLog.record(
                channel: "agent", event: name, decision: .info, detail: succeeded ? "succeeded" : "failed")
        }
        builtAutomation = automation
        return automation
    }

    private weak var addressBar: NSView?
    let newTabButton = NSButton()
    let drivenBadge = BrowserDrivenBadge()
    let pausedBadge = BrowserPausedBadge()
    let addressField = NSTextField()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()

    /// The window's first responder, followed while the pane is on screen.
    private var firstResponderObservation: NSKeyValueObservation?
    /// Whether the page held first responder at the last change, so the log
    /// records the page gaining and losing it rather than every move between
    /// two controls outside it.
    private var pageHeldFirstResponder: Bool?
    /// The pane's window's key and occlusion notifications, for the log.
    private var windowObservers: [NSObjectProtocol] = []
    /// The settings subscriptions; made again with every engine.
    private var cancellables: Set<AnyCancellable> = []

    /// - Parameters:
    ///   - makeEngine: Makes what renders the page, from the configuration
    ///     the pane resolved; called again on every rebuild. The pane becomes
    ///     each engine's delegate.
    ///   - engineKind: Which engine `makeEngine` makes, for the model tools,
    ///     and the name the pane calls itself while it shows nothing.
    ///   - minimizedSymbol: The SF Symbol a minimized pane shows.
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    ///   - context: The project, worktree and node the pane belongs to.
    public init(
        makeEngine: @escaping EngineFactory,
        engineKind: BrowserEngineKind,
        minimizedSymbol: String,
        store: PaneStateStore,
        settings: SettingsStore,
        history: BrowserHistoryStore?,
        homeURL: URL,
        context: BrowserPaneContext = .detached
    ) {
        self.makeEngine = makeEngine
        self.engineKind = engineKind
        self.minimizedSymbol = minimizedSymbol
        self.store = store
        self.settings = settings
        self.history = history
        self.fallbackHomeURL = homeURL
        self.paneContext = context
        let jar = Self.resolveJar(settings: settings, context: context, label: Self.untitledLabel)
        let capturesConsole = settings.get(UserSettings.browserPrivacyConsoleCapture)
        self.resolvedJar = jar
        self.capturesConsole = capturesConsole
        self.builtConstructionSettings = BrowserSettings.constructionSnapshot(in: settings)
        let configuration = BrowserEngineConfiguration(
            settings: settings, consoleLog: consoleLog, jar: jar, capturesConsole: capturesConsole
        )
        let first = makeEngine(configuration)
        self.engine = first
        // Every remembered tab gets an engine now and its page when it is
        // first brought forward (`activate`), so a pane that comes back with
        // ten tabs loads one page, not ten.
        let stored = Self.readStoredTabs(from: store)
        let selected = min(max(stored.selectedIndex, 0), max(stored.tabs.count - 1, 0))
        var restored: [BrowserTab] = []
        for (index, entry) in stored.tabs.enumerated() {
            let tabEngine = index == 0 ? first : makeEngine(configuration)
            // The front tab with no address falls back to the Home Page
            // (`restorationURL`, below); a tab behind it was on a blank page.
            let url = entry.url.flatMap { URL(string: $0, encodingInvalidCharacters: false) }
            restored.append(BrowserTab(
                engine: tabEngine, pendingURL: url ?? (index == selected ? nil : Self.blankPage),
                storedTitle: entry.title))
        }
        if restored.isEmpty { restored = [BrowserTab(engine: first, pendingURL: nil, storedTitle: nil)] }
        self.tabs = restored
        self.activeTab = restored[min(selected, restored.count - 1)]
        super.init(nibName: nil, bundle: nil)
        jarLabel = jar.jarID == nil ? nil : Self.untitledLabel
        context.jars?.noteUse(of: jar.jarID, by: self)
        recordJarFallback(jar)
        tabs.forEach { wireEngine($0.engine) }
        engine = activeTab.engine
        if activeTab.pendingURL == nil { activeTab.pendingURL = restorationURL }
        tabStrip.delegate = self
        tabStrip.setEdgeEnabled(.top, true)
        applyCookiePolicy()
        observeSettings()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public var onPaneTitleChange: (() -> Void)?

    /// Posted, with the pane as its object, whenever `paneTitle` may have
    /// changed. `onPaneTitleChange` is the host's one slot; this is for
    /// anything else following a pane, such as its Browser Log, whatever
    /// engine it is on.
    public static let paneTitleDidChangeNotification = Notification.Name("WebBrowserPaneTitleDidChange")

    private func announceTitleChange() {
        onPaneTitleChange?()
        NotificationCenter.default.post(name: Self.paneTitleDidChangeNotification, object: self)
    }

    /// The address the pane will restore to: what the store remembers, else
    /// the Home Page setting, else the registration's home.
    var restorationURL: URL {
        // `encodingInvalidCharacters: false`: since macOS 14 `URL(string:)` percent-encodes what it
        // cannot parse, so "not a url" would come back as a relative URL instead of falling through.
        if let remembered = store.paneStateValue(forKey: Self.addressKey),
           let url = URL(string: remembered, encodingInvalidCharacters: false) {
            return url
        }
        return BrowserSettings.homePage(in: settings) ?? fallbackHomeURL
    }

    // MARK: - Engine

    /// Everything a new engine needs from the pane before it shows a page.
    /// One place, so the engine a rebuild makes is wired exactly as the first
    /// one was (`dry`).
    private func wireEngine(_ engine: BrowserEngine) {
        engine.delegate = self
        engine.onInputDecision = { [weak self] channel, event, delivered, synthesized, detail in
            self?.recordInput(channel, event, delivered: delivered, synthesized: synthesized, detail: detail)
        }
        engine.inputGate = BrowserInputGate(settings: settings, isPaused: isEventsPaused)
        engine.setActivationShieldActive(isActivationShieldWanted)
    }

    /// Recomputes the engine's input gate from the pane's settings and its
    /// pause state. The one place the gate is built, so a settings change, a
    /// pause change and a rebuilt engine (through `wireEngine`) all land on
    /// the same answer. Only the page is gated; the pane's address bar and
    /// chrome never are, so the address bar and the back, forward and reload
    /// buttons still work while the pane is paused.
    private func refreshInputGate() {
        let gate = BrowserInputGate(settings: settings, isPaused: isEventsPaused)
        for tab in tabs { tab.engine.inputGate = gate }
    }

    /// Raises or lowers the activation shield from the Hide Focus setting and
    /// the pause state: up when either asks for it. The one place that answer
    /// is computed, beside `refreshInputGate` for the same reasons.
    private func refreshActivationShield() {
        let active = isActivationShieldWanted
        for tab in tabs { tab.engine.setActivationShieldActive(active) }
    }

    private var isActivationShieldWanted: Bool {
        settings.get(UserSettings.browserPrivacyHideActivation) || isEventsPaused
    }

    // MARK: - Settings

    /// Private browsing first — a store that lives only as long as the pane,
    /// whatever jar is chosen — and otherwise the jar the setting names,
    /// through the registry. With no registry there is nowhere to keep a
    /// worktree or pane jar, so the pane is on the shared store.
    ///
    /// The WebKit store stays unmade until an engine asks for it, so a
    /// Chrome pane never makes one.
    public static func resolveJar(
        settings: SettingsStore, context: BrowserPaneContext, label: String
    ) -> ResolvedJar {
        if settings.get(UserSettings.browserPrivateBrowsing) {
            return ResolvedJar(webKitDataStore: .nonPersistent(), jar: nil, jarID: nil)
        }
        let wanted = settings.get(UserSettings.browserPrivacyStorageJar)
        guard let jars = context.jars else {
            if wanted != .global {
                logger.debug("browser pane has no jar registry; using the shared jar")
            }
            return .global
        }
        let resolution = jars.resolve(wanted, context: context, label: label)
        return ResolvedJar(
            webKitDataStore: resolution.dataStore, jar: resolution.jar, jarID: resolution.jarID,
            fallbackReason: resolution.fallbackReason
        )
    }

    /// Puts a jar that failed closed in the pane's event log, where the
    /// pane's own record of what happened to it lives.
    private func recordJarFallback(_ jar: ResolvedJar) {
        guard let reason = jar.fallbackReason else { return }
        eventLog.record(
            channel: "settings", event: "jarFallback", decision: .info,
            detail: "\(jar.jar?.rawValue ?? "jar") not made, non-persistent store: \(reason)")
    }

    /// The cookie policy belongs to the store, not the page, and a global or
    /// worktree store is shared by other panes. The pane still applies it,
    /// because a private or pane store has no other owner — but only when the
    /// cookie setting itself changes, not on every browser change: a zoom
    /// slider drag is not a reason for every open pane to rewrite the shared
    /// store's policy once per tick.
    private func applyCookiePolicy() {
        let accepts = Self.acceptsCookies(settings: settings, ownsDataStore: resolvedJar.isOwnedByPane)
        for tab in tabs { tab.engine.applyCookiePolicy(acceptsCookies: accepts) }
    }

    /// The cookie policy to put on the pane's store. A pane's own override
    /// counts only on a store the pane alone uses; on a shared one it would
    /// silently change every sibling's policy, so the shared value wins.
    public static func acceptsCookies(settings: SettingsStore, ownsDataStore: Bool) -> Bool {
        if !ownsDataStore, let layered = settings as? LayeredSettingsStore {
            return layered.fallback.get(UserSettings.browserAcceptsCookies)
        }
        return settings.get(UserSettings.browserAcceptsCookies)
    }

    /// What the pane itself follows of the settings. Everything an engine can
    /// change under a page — zoom, user agent, content rules — the engine
    /// follows on its own; the pane follows what needs the pane's state: the
    /// gate and the shield (which need the pause), the cookie policy (which
    /// needs the jar) and the jar (which needs a rebuild).
    private func observeSettings() {
        cancellables.removeAll()
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                guard let self else { return }
                // A pane's layered store publishes its own overrides and only
                // the shared changes no override hides, so every key here is
                // one that took effect on this pane.
                self.eventLog.record(channel: "settings", event: "changed", decision: .info, detail: key)
                self.refreshInputGate()
                self.refreshActivationShield()
                if key == UserSettings.browserAcceptsCookies.name { self.applyCookiePolicy() }
                if key == UserSettings.browserPrivacyStorageJar.name { self.storageJarSettingDidChange() }
            }
            .store(in: &cancellables)
        // A pane overriding the cookie setting hides the shared value's
        // changes from `settings`, but on a shared store it is the shared
        // value that applies, so it is followed here as well.
        paneSettings?.fallback.changes
            .filter { $0 == UserSettings.browserAcceptsCookies.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyCookiePolicy() }
            .store(in: &cancellables)
    }

    // MARK: - Storage jar

    /// The shared jar setting moved. A pane following it — no override of
    /// its own, not private — moves too, when the jar it would now resolve to
    /// is not the one it is on. A pane's own jar override is applied by its
    /// settings sheet, not here: the sheet decides when a rebuild is due.
    /// While the sheet is up nothing moves — not even a dropped override —
    /// and the sheet's close compares what changed (spec section 4).
    private func storageJarSettingDidChange() {
        guard !isSettingsSheetOpen else { return }
        guard resolvedJar.jar != nil else { return }
        if paneSettings?.hasOverride(UserSettings.browserPrivacyStorageJar) == true { return }
        guard needsRebuildForJar() else { return }
        rebuildEngine()
    }

    /// Whether the jar setting now names a different store from the one the
    /// engine is on. Answered without making a row: a jar not made yet is a
    /// different one by definition.
    func needsRebuildForJar() -> Bool {
        let wanted = settings.get(UserSettings.browserPrivacyStorageJar)
        guard let jars = paneContext.jars, wanted != .global else {
            return resolvedJar.jar != .global
        }
        // A jar this context cannot have resolves to a non-persistent store
        // under the same name; a pane already on that has nowhere to go.
        guard jars.canIsolate(wanted, context: paneContext) else {
            return !(resolvedJar.isFallback && resolvedJar.jar == wanted)
        }
        guard resolvedJar.jar == wanted else { return true }
        return jars.jarID(for: wanted, context: paneContext) != resolvedJar.jarID
    }

    /// Throws the engine away and makes a new one on the jar the settings
    /// resolve to now, on the page the old one was showing.
    ///
    /// Both engines fix a page's session store when the page is made, so
    /// moving jars is a new engine, not a property change. The old one is
    /// torn down exactly as a discarded pane's is, so it lets go of its store
    /// — WebKit will not remove a store a web view still holds.
    ///
    /// Downloads in flight in the old engine are cancelled with it, as are
    /// its back and forward history and any form a page had half filled in.
    /// That is accepted rather than worked around: changing a pane's jar is
    /// rare and deliberate, and carrying a download across two stores would
    /// hand one jar's session to another.
    public func rebuildEngine() {
        let label = paneTitle
        // Removing the page drops a first responder it held to the window;
        // the new one takes it back, as does a paused pane's, whose page is
        // meant to be focused and frozen (spec section 7) — but only when
        // nothing else in the window holds the focus: a rebuild a global
        // setting caused must not pull the keyboard out of a terminal.
        let responder = viewIfLoaded?.window?.firstResponder
        let focusIsFree = responder == nil || responder === viewIfLoaded?.window
        let refocus = pageHolds(responder) || (isEventsPaused && focusIsFree)
        firstResponderObservation = nil
        cancellables.removeAll()
        // Where each tab was: a navigation still held for the old engine's
        // rules is where it was going, so it wins over the page it showed;
        // a tab never brought forward keeps the page it is waiting to load.
        let destinations = tabs.map { tab -> URL? in
            let shown = tab.engine.url.flatMap { $0 == Self.blankPage ? nil : $0 }
            return tab.engine.heldLoadURL ?? shown ?? tab.pendingURL
        }
        for tab in tabs {
            tab.engine.teardown()
            tab.engine.view.removeFromSuperview()
        }

        let jar = Self.resolveJar(settings: settings, context: paneContext, label: label)
        let capturesConsole = settings.get(UserSettings.browserPrivacyConsoleCapture)
        resolvedJar = jar
        self.capturesConsole = capturesConsole
        builtConstructionSettings = BrowserSettings.constructionSnapshot(in: settings)
        // What the old engine captured is not this one's to report.
        if !capturesConsole { consoleLog.clear() }
        jarLabel = jar.jarID == nil ? nil : label
        paneContext.jars?.noteUse(of: jar.jarID, by: self)
        let configuration = currentConfiguration
        for (tab, destination) in zip(tabs, destinations) {
            let made = makeEngine(configuration)
            tab.engine = made
            tab.resetVisit()
            wireEngine(made)
            onEngineMade?(made)
            tab.content.show(made.view)
            // The tab in front loads now (below); the others when brought
            // forward. A tab that was on nothing comes back on nothing.
            tab.pendingURL = destination ?? (tab === activeTab ? nil : Self.blankPage)
        }
        engine = activeTab.engine
        builtAutomation?.retarget(to: engine)
        builtAutomation?.isConsoleCaptureOn = capturesConsole
        applyCookiePolicy()
        observeSettings()
        eventLog.record(channel: "settings", event: "rebuild", decision: .info, detail: jar.jar?.rawValue ?? "private")
        recordJarFallback(jar)

        guard isViewLoaded else { return }
        browserEngineTitleDidChange(engine)
        browserEngineHistoryDidChange(engine)
        if view.window != nil { observeFirstResponder() }
        if refocus { view.window?.makeFirstResponder(engine.view) }
        let destination = activeTab.pendingURL ?? restorationURL
        activeTab.pendingURL = nil
        engine.load(destination)
    }

    /// What every engine the pane makes now is made from.
    private var currentConfiguration: BrowserEngineConfiguration {
        BrowserEngineConfiguration(
            settings: settings, consoleLog: consoleLog, jar: resolvedJar, capturesConsole: capturesConsole)
    }

    /// Keeps the pane jar's row named after the page, so a list of jars says
    /// what each was for after its pane is gone.
    ///
    /// At most once per committed navigation (`BrowserJarLabelGate`), so a
    /// page that keeps retitling itself does not keep writing the database.
    private func updateJarLabel(finished: Bool) {
        guard resolvedJar.jar == .pane, let jarID = resolvedJar.jarID, let jars = paneContext.jars else { return }
        guard let label = jarLabelGate.label(
            pageTitle: engine.title, fallback: paneTitle, finished: finished, current: jarLabel
        ) else { return }
        jarLabel = label
        jars.updateLabel(jarID: jarID, label: label)
    }

    /// Forgets visits older than the retention setting allows. Run as the
    /// pane comes up, so an old history shrinks without anyone opening the
    /// panel to ask it to.
    private func pruneHistory() {
        guard let history, let cutoff = settings.get(UserSettings.browserHistoryRetention).cutoff() else { return }
        Task { [logger] in
            do {
                try await history.perform { try $0.removeVisits(before: cutoff) }
            } catch {
                logger.error("browser history prune failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - View

    open override func loadView() {
        let root = ThemedBackgroundView(role: .windowBackground)
        view = root

        configureButton(backButton, symbol: "chevron.left", label: "Back", action: #selector(goBack))
        configureButton(forwardButton, symbol: "chevron.right", label: "Forward", action: #selector(goForward))
        configureButton(reloadButton, symbol: "arrow.clockwise", label: "Reload", action: #selector(reload))
        configureButton(newTabButton, symbol: "plus", label: "New Tab", action: #selector(newTab(_:)))
        newTabButton.setAccessibilityIdentifier("browser.newtab")

        addressField.placeholderString = "Enter an address"
        addressField.target = self
        addressField.action = #selector(navigateToTypedAddress)
        // Enter navigates; clicking elsewhere must not, or a half-typed address
        // would load the moment the user reached for the page.
        (addressField.cell as? NSTextFieldCell)?.sendsActionOnEndEditing = false
        addressField.lineBreakMode = .byTruncatingTail
        addressField.usesSingleLineMode = true
        addressField.setAccessibilityIdentifier("browser.address")
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let bar = NSStackView(views: [
            backButton, forwardButton, reloadButton, addressField, pausedBadge, drivenBadge, newTabButton
        ])
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.spacing = 4
        bar.edgeInsets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(bar)
        addressBar = bar
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: root.trailingAnchor)
        ])
        installTabStrip(below: bar)
    }

    /// Puts the tab bar and the page area under the address bar, with every
    /// tab in it and the remembered one in front.
    private func installTabStrip(below bar: NSView) {
        addChild(tabStrip)
        let strip = tabStrip.view
        strip.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(strip)
        NSLayoutConstraint.activate([
            strip.topAnchor.constraint(equalTo: bar.bottomAnchor),
            strip.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            strip.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // The strip activates the first tab it is given; which tab comes
        // forward is decided here, once, rather than by that.
        let front = activeTab
        isInstallingTabs = true
        for tab in tabs {
            tabStrip.addTab(.init(id: tab.id, title: tabTitle(for: tab), viewController: tab.content), on: .top)
        }
        tabStrip.selectTab(id: front.id, on: .top)
        isInstallingTabs = false
        activate(front)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        // The engine reports changes from here on; what is already true is
        // read once now.
        browserEngineTitleDidChange(engine)
        browserEngineAddressDidChange(engine)
        browserEngineHistoryDidChange(engine)
        pruneHistory()
        loadPendingPage(of: activeTab)
    }

    /// A pane that appears — opened, or its tab brought forward — is the one
    /// the user is now looking at, and the window's first responder is
    /// followed from here on, so clicking into the page or tabbing into it
    /// makes this the most recently focused Browser pane too.
    open override func viewDidAppear() {
        super.viewDidAppear()
        BrowserPaneFocus.shared.note(self)
        observeFirstResponder()
        observeWindow()
    }

    open override func viewDidDisappear() {
        super.viewDidDisappear()
        firstResponderObservation = nil
        pageHeldFirstResponder = nil
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
    }

    /// Whether `responder` is the page: the engine's view or a view inside it.
    private func pageHolds(_ responder: NSResponder?) -> Bool {
        guard let view = responder as? NSView else { return false }
        return view === engine.view || view.isDescendant(of: engine.view)
    }

    private func observeFirstResponder() {
        firstResponderObservation = view.window?.observe(\.firstResponder, options: [.new]) { [weak self] window, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let pageHolds = self.pageHolds(window.firstResponder)
                if pageHolds != self.pageHeldFirstResponder {
                    self.pageHeldFirstResponder = pageHolds
                    self.eventLog.record(
                        channel: "window", event: "firstResponder", decision: .info,
                        detail: pageHolds ? "page" : "outside the page")
                }
                guard pageHolds else { return }
                BrowserPaneFocus.shared.note(self)
            }
        }
    }

    /// Follows the window's key and occlusion state into the log: both
    /// decide what the page can tell about its own focus and visibility.
    private func observeWindow() {
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
        guard let window = view.window else { return }
        let center = NotificationCenter.default
        let events: [(Notification.Name, String)] = [
            (NSWindow.didBecomeKeyNotification, "becameKey"),
            (NSWindow.didResignKeyNotification, "resignedKey"),
            (NSWindow.didChangeOcclusionStateNotification, "occlusion")
        ]
        windowObservers = events.map { name, event in
            center.addObserver(forName: name, object: window, queue: .main) { [weak self, weak window] _ in
                MainActor.assumeIsolated {
                    let visible = window?.occlusionState.contains(.visible) == true
                    let detail = event == "occlusion" ? (visible ? "visible" : "occluded") : ""
                    self?.eventLog.record(channel: "window", event: event, decision: .info, detail: detail)
                }
            }
        }
    }

    /// One gate decision into the log. A withheld event the agent sent says
    /// so, since that only happens while the agent is paused too.
    private func recordInput(
        _ channel: BrowserInputChannel, _ event: String, delivered: Bool, synthesized: Bool, detail: String
    ) {
        let decision: BrowserEventLogEntry.Decision = !delivered ? .withheld : synthesized ? .synthesized : .delivered
        let shown = synthesized && !delivered ? (detail.isEmpty ? "agent" : "agent " + detail) : detail
        eventLog.record(channel: channel.rawValue, event: event, decision: decision, detail: shown)
    }

    /// A navigation into the log, by host: a path or query can carry a token.
    private func recordNavigation(_ event: String, of engine: BrowserEngine, error: Error? = nil) {
        var detail = engine.url?.host ?? ""
        if let error { detail += (detail.isEmpty ? "" : " ") + "error \((error as NSError).code)" }
        eventLog.record(channel: "navigation", event: event, decision: .info, detail: detail)
    }

    private func configureButton(_ button: NSButton, symbol: String, label: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.imagePosition = .imageOnly
        button.bezelStyle = .texturedRounded
        button.isBordered = true
        button.toolTip = label
        button.target = self
        button.action = action
        button.setAccessibilityIdentifier("browser." + label.lowercased())
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func file(_ title: String, againstVisit visitID: Int64) {
        guard let history else { return }
        Task { [logger] in
            do {
                try await history.perform { try $0.updateTitle(ofVisit: visitID, to: title) }
            } catch {
                logger.error("browser history title update failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Writes the address the pane will reopen on. Once per committed
    /// navigation rather than on every change of the engine's address — a
    /// redirect chain or a fragment change reports several — and only when it
    /// differs from what is remembered, since the store is a database write.
    private func rememberAddress() {
        let address = engine.url.flatMap { $0 == Self.blankPage ? nil : $0.absoluteString }
        guard address != store.paneStateValue(forKey: Self.addressKey) else { return }
        store.setPaneStateValue(address, forKey: Self.addressKey)
    }

    /// Files the page that just finished loading in `tab`. Only pages, only
    /// when the setting says so, and never the blank page.
    private func recordVisit(in tab: BrowserTab) {
        tab.currentVisitID = nil
        tab.visitGeneration += 1
        let engine = tab.engine
        guard let history, settings.get(UserSettings.browserRecordsHistory),
              let url = engine.url, url != Self.blankPage else { return }
        let generation = tab.visitGeneration
        let title = engine.title ?? ""
        Task { [weak self, weak tab, logger] in
            do {
                let visitID = try await history.perform { try $0.record(url, title: title) }
                guard let self, let tab, tab.visitGeneration == generation, tab.engine === engine else { return }
                tab.currentVisitID = visitID
                // A title that arrived while the row was being written found
                // no row to be filed against; file it now.
                if let later = engine.title, !later.isEmpty, later != title {
                    self.file(later, againstVisit: visitID)
                }
            } catch {
                logger.error("browser history record failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Actions

    @objc private func navigateToTypedAddress() {
        guard let url = Self.resolveAddress(addressField.stringValue) else {
            // What was typed is the user's, and may be anything; it stays out
            // of the public log.
            logger.info("browser pane refused address: \(self.addressField.stringValue, privacy: .private)")
            return
        }
        load(url)
    }

    /// Navigates the pane. Public so a host — a link in a note, a scripting
    /// command — can point it somewhere without going through the field.
    public func load(_ url: URL) {
        engine.load(url)
        view.window?.makeFirstResponder(engine.view)
    }

    @objc private func goBack() { engine.goBack() }
    @objc private func goForward() { engine.goForward() }
    @objc private func reload() { engine.reload() }

    // MARK: - Tabs

    /// The tab `engine` renders, or `nil` for one the pane has let go of.
    private func tab(for engine: BrowserEngine) -> BrowserTab? {
        tabs.first { $0.engine === engine }
    }

    /// What a tab is called in the bar: its page's title, else its host,
    /// else what it was called when the pane was last stored, else New Tab.
    private func tabTitle(for tab: BrowserTab) -> String {
        // Chromium titles a blank page with its address; that is no name.
        if let title = tab.engine.title, !title.isEmpty, title != Self.blankPage.absoluteString { return title }
        if let url = tab.engine.url, url != Self.blankPage, let host = url.host, !host.isEmpty { return host }
        if tab.engine.url == nil, let stored = tab.storedTitle, !stored.isEmpty { return stored }
        return Self.newTabTitle
    }

    private func retitle(_ tab: BrowserTab) {
        tabStrip.renameTab(id: tab.id, title: tabTitle(for: tab))
    }

    /// Brings `tab` forward: the bar, the title, the drive seam and the
    /// pane's idea of the page all follow it, and a tab brought forward for
    /// the first time loads its page.
    private func activate(_ tab: BrowserTab) {
        let responderWasInPage = pageHolds(viewIfLoaded?.window?.firstResponder)
        activeTab = tab
        engine = tab.engine
        builtAutomation?.retarget(to: engine)
        // A half-typed address was meant for the tab being left.
        if addressField.currentEditor() != nil { addressField.abortEditing() }
        let shown = engine.url ?? tab.pendingURL
        addressField.stringValue = shown.map { $0 == Self.blankPage ? "" : $0.absoluteString } ?? ""
        browserEngineHistoryDidChange(engine)
        announceTitleChange()
        loadPendingPage(of: tab)
        if responderWasInPage { view.window?.makeFirstResponder(engine.view) }
        rememberAddress()
        persistTabs()
        eventLog.record(channel: "pane", event: "tab", decision: .info, detail: engine.url?.host ?? "")
    }

    /// Loads the page `tab` is waiting for, once.
    private func loadPendingPage(of tab: BrowserTab) {
        guard let url = tab.pendingURL else { return }
        tab.pendingURL = nil
        tab.engine.load(url)
    }

    /// Adds a tab for `engine`, wired, after `opener`'s tab (else at the end),
    /// and brings it forward. Returns the tab.
    @discardableResult
    private func addTab(engine tabEngine: BrowserEngine, after opener: BrowserTab?, pendingURL: URL?) -> BrowserTab {
        let tab = BrowserTab(engine: tabEngine, pendingURL: pendingURL, storedTitle: nil)
        wireEngine(tabEngine)
        tabEngine.applyCookiePolicy(
            acceptsCookies: Self.acceptsCookies(settings: settings, ownsDataStore: resolvedJar.isOwnedByPane))
        onEngineMade?(tabEngine)
        let index = opener.flatMap { opener in tabs.firstIndex { $0 === opener } }.map { $0 + 1 } ?? tabs.count
        tabs.insert(tab, at: index)
        // The strip's tab order is the pane's: insert at the same place.
        tabStrip.insertTab(
            .init(id: tab.id, title: tabTitle(for: tab), viewController: tab.content), at: index, on: .top)
        tabStrip.selectTab(id: tab.id, on: .top)
        if activeTab !== tab { activate(tab) }
        return tab
    }

    /// A new tab on the Home Page, with the address field ready to type in.
    /// The plus button and File > New Tab both land here.
    @objc public func newTab(_ sender: Any?) {
        guard !isDiscarded else { return }
        let home = BrowserSettings.homePage(in: settings) ?? fallbackHomeURL
        addTab(engine: makeEngine(currentConfiguration), after: nil, pendingURL: home)
        view.window?.makeFirstResponder(addressField)
    }

    /// Closes `tab`. The last tab is never closed: it goes back to a blank
    /// page instead, as the Document pane's last tab empties rather than
    /// going away. `pageClosedItself` is a page's `window.close()`, whose
    /// engine is finished and is replaced rather than reused.
    private func closeTab(_ tab: BrowserTab, pageClosedItself: Bool = false) {
        guard tabs.contains(where: { $0 === tab }) else { return }
        guard tabs.count > 1 else {
            if pageClosedItself { replaceEngine(of: tab) }
            tab.storedTitle = nil
            tab.pendingURL = nil
            tab.engine.load(Self.blankPage)
            retitle(tab)
            persistTabs()
            return
        }
        // A window that came from a page hands the focus back to that page,
        // the way a closed browser window returns to the one that opened it.
        // Selected before the removal, so the strip never brings the right
        // neighbour forward on the way — activating it would load its pending
        // page and move the pane's address to it for nothing.
        if tab === activeTab, let opener = tab.opener, opener !== tab, tabs.contains(where: { $0 === opener }) {
            tabStrip.selectTab(id: opener.id, on: .top)
        }
        // Out of the list first, so any neighbour the strip brings forward is
        // activated with this one already gone.
        tabs.removeAll { $0 === tab }
        tab.engine.delegate = nil
        tab.engine.teardown()
        tabStrip.removeTab(id: tab.id)
        persistTabs()
    }

    /// A fresh engine in `tab`, made and wired as every other is.
    private func replaceEngine(of tab: BrowserTab) {
        tab.engine.delegate = nil
        tab.engine.teardown()
        tab.engine.view.removeFromSuperview()
        let made = makeEngine(currentConfiguration)
        tab.engine = made
        tab.resetVisit()
        wireEngine(made)
        made.applyCookiePolicy(
            acceptsCookies: Self.acceptsCookies(settings: settings, ownsDataStore: resolvedJar.isOwnedByPane))
        onEngineMade?(made)
        tab.content.show(made.view)
        if tab === activeTab {
            engine = made
            builtAutomation?.retarget(to: made)
        }
    }

    /// Writes the tab list, when it differs from what was last written.
    private func persistTabs() {
        let stored = StoredBrowserTabs(
            tabs: tabs.map { tab in
                let url = tab.engine.url.flatMap { $0 == Self.blankPage ? nil : $0.absoluteString }
                    ?? tab.pendingURL.flatMap { $0 == Self.blankPage ? nil : $0.absoluteString }
                let title = tab.engine.title.flatMap { $0.isEmpty ? nil : $0 } ?? tab.storedTitle
                return StoredBrowserTab(url: url, title: title)
            },
            selectedIndex: tabs.firstIndex { $0 === activeTab } ?? 0
        )
        guard let data = try? JSONEncoder().encode(stored),
              let json = String(data: data, encoding: .utf8), json != lastStoredTabs else { return }
        lastStoredTabs = json
        store.setPaneStateValue(json, forKey: Self.tabsKey)
    }

    static func readStoredTabs(from store: PaneStateStore) -> StoredBrowserTabs {
        guard let json = store.paneStateValue(forKey: tabsKey), let data = json.data(using: .utf8),
              let stored = try? JSONDecoder().decode(StoredBrowserTabs.self, from: data) else {
            return StoredBrowserTabs(tabs: [], selectedIndex: 0)
        }
        return stored
    }

    // MARK: - Downloads

    /// A file name that does not collide with one already in `directory`:
    /// `name.ext`, then `name 2.ext`, `name 3.ext` — `UniqueName`'s count,
    /// the one every "New Project" and renamed record uses (`dry`).
    static func uniqueDestination(for suggestedName: String, in directory: URL) -> URL {
        let name = suggestedName.isEmpty ? "download" : suggestedName
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let taken = ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? [])
            .filter { ($0 as NSString).pathExtension == ext }
            .map { ($0 as NSString).deletingPathExtension }
        let stem = UniqueName.next(base: base, taken: taken)
        return directory.appendingPathComponent(ext.isEmpty ? stem : "\(stem).\(ext)")
    }
}

// MARK: - Engine delegate

extension WebBrowserPaneViewController: BrowserEngineDelegate {

    /// Every engine callback names its engine; a tab behind the one in front
    /// keeps its own title, visits and stored address up to date, and only
    /// the front tab's engine moves the bar, the pane's title and the jar.
    private func isFront(_ engine: BrowserEngine) -> Bool { engine === self.engine }

    public func browserEngineTitleDidChange(_ engine: BrowserEngine) {
        guard let tab = tab(for: engine) else { return }
        retitle(tab)
        if let visitID = tab.currentVisitID, let title = engine.title, !title.isEmpty {
            file(title, againstVisit: visitID)
        }
        guard isFront(engine) else { return }
        announceTitleChange()
        updateJarLabel(finished: false)
    }

    public func browserEngineAddressDidChange(_ engine: BrowserEngine) {
        guard isFront(engine), let url = engine.url else { return }
        // A field being edited is the user's; overwriting it mid-keystroke
        // because a redirect landed would throw away what they typed. A field
        // has an editor exactly while it is being edited, so that is the test
        // -- not a comparison against the window's first responder, which is
        // nil on both sides before the pane is in a window, as it is when the
        // restoration load lands.
        if addressField.currentEditor() == nil {
            addressField.stringValue = url == Self.blankPage ? "" : url.absoluteString
        }
        announceTitleChange()
    }

    public func browserEngineHistoryDidChange(_ engine: BrowserEngine) {
        guard isFront(engine) else { return }
        backButton.isEnabled = engine.canGoBack
        forwardButton.isEnabled = engine.canGoForward
    }

    /// The visit on record is the page being left. An engine publishes the
    /// new page's title before the load finishes and files its visit, so a
    /// title that lands while a load is in flight would otherwise be written
    /// onto the previous page's row.
    public func browserEngineDidStartNavigation(_ engine: BrowserEngine) {
        tab(for: engine)?.currentVisitID = nil
        recordNavigation("start", of: engine)
    }

    public func browserEngineDidCommitNavigation(_ engine: BrowserEngine) {
        recordNavigation("commit", of: engine)
        if let tab = tab(for: engine) {
            tab.storedTitle = nil
            retitle(tab)
        }
        persistTabs()
        guard isFront(engine) else { return }
        consoleLog.clear()
        rememberAddress()
        jarLabelGate.navigationDidCommit()
    }

    public func browserEngineDidFinishNavigation(_ engine: BrowserEngine) {
        if let tab = tab(for: engine) { recordVisit(in: tab) }
        recordNavigation("finish", of: engine)
        persistTabs()
        guard isFront(engine) else { return }
        updateJarLabel(finished: true)
    }

    public func browserEngine(_ engine: BrowserEngine, didFailNavigationWith error: Error) {
        recordNavigation("fail", of: engine, error: error)
    }

    /// The page opened a window. It becomes a tab beside its opener's,
    /// brought forward at once — synchronously, because a Chromium popup's
    /// browser is created into the tab's view as soon as this returns — and
    /// its engine stays tied to the opener, which is what lets a sign-in or
    /// 2FA window post its answer back through `window.opener`.
    public func browserEngine(_ engine: BrowserEngine, didOpenPopup popup: BrowserEngine) -> Bool {
        guard !isDiscarded, let opener = tab(for: engine) else { return false }
        let tab = addTab(engine: popup, after: opener, pendingURL: nil)
        tab.opener = opener
        eventLog.record(channel: "navigation", event: "popup", decision: .info, detail: engine.url?.host ?? "")
        return true
    }

    /// The page closed its own window — a sign-in or 2FA window that has
    /// answered — so its tab goes, and the opener's tab is in front again
    /// when it is the neighbour.
    public func browserEngineDidRequestClose(_ engine: BrowserEngine) {
        guard let tab = tab(for: engine) else { return }
        eventLog.record(channel: "navigation", event: "close", decision: .info, detail: engine.url?.host ?? "")
        closeTab(tab, pageClosedItself: true)
    }

    public func browserEngine(_ engine: BrowserEngine, download event: String, host: String) {
        eventLog.record(channel: "download", event: event, decision: .info, detail: host)
    }

    /// A dialog raised while a model acts is the model's to hear about, and it
    /// is always dismissed: a panel would block the pane under a hand that is
    /// not the user's. Outside an action the same dismissal applies, since the
    /// pane shows no dialogs of its own; the answer is just not reported.
    public func browserEngine(_ engine: BrowserEngine, didRaise dialog: BrowserDialog) {
        // The message is the page's words and stays out of the log.
        let reported = builtAutomation?.isActionInFlight == true
        eventLog.record(
            channel: "dialog", event: dialog.kind.rawValue, decision: .info,
            detail: reported ? "dismissed, reported to the agent" : "dismissed")
        guard reported else { return }
        automation.dialogRaised(kind: dialog.kind, message: dialog.message)
    }

    public func browserEngine(_ engine: BrowserEngine, destinationForDownloadNamed name: String) async -> URL? {
        if settings.get(UserSettings.browserAsksDownloadLocation) {
            // Asking needs a window to ask on. A pane with none is not a
            // reason to save somewhere the user was never shown
            // (`explicit-over-implicit`): refuse the download instead.
            guard let window = view.window else {
                logger.error("browser download refused: asked to choose a location with no window to ask on")
                return nil
            }
            let panel = NSSavePanel()
            panel.nameFieldStringValue = name
            panel.directoryURL = BrowserSettings.downloadDirectory(in: settings)
            panel.canCreateDirectories = true
            let response = await panel.beginSheetModal(for: window)
            guard response == .OK, let chosen = panel.url else { return nil }
            // Replace was answered on the sheet. An engine refuses, or
            // renames around, a file already there, so the file goes first,
            // and if it will not go the download fails here rather than after
            // the transfer.
            if FileManager.default.fileExists(atPath: chosen.path) {
                do {
                    try FileManager.default.removeItem(at: chosen)
                } catch {
                    logger.error(
                        "browser download could not replace the file: \(error.localizedDescription, privacy: .public)")
                    return nil
                }
            }
            return chosen
        }
        let directory = BrowserSettings.downloadDirectory(in: settings)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            logger.error("browser download folder unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        return Self.uniqueDestination(for: name, in: directory)
    }

    /// Camera and microphone, decided by the Media setting: granted or refused
    /// outright, or asked about — on the pane's window, naming the site, so
    /// the answer is given to the page that asked and nothing else.
    public func browserEngine(
        _ engine: BrowserEngine, allowsMediaCaptureFor host: String, device: String
    ) async -> Bool? {
        eventLog.record(channel: "permission", event: "request", decision: .info, detail: "\(host) \(device)")
        let decision = await decideMediaCapture(host: host, device: device)
        let answer = switch decision {
        case true?: "granted"
        case false?: "denied"
        case nil: "left to the engine"
        }
        eventLog.record(
            channel: "permission", event: "decision", decision: .info, detail: "\(host) \(device) \(answer)"
        )
        return decision
    }

    private func decideMediaCapture(host: String, device: String) async -> Bool? {
        switch settings.get(UserSettings.browserMediaCapture) {
        case .allow: return true
        case .deny: return false
        case .ask: break
        }
        guard let window = view.window else { return nil }
        let alert = NSAlert()
        alert.messageText = "\(host) wants to use your \(device)."
        alert.informativeText = "Browser settings decide whether sites ask, are always allowed, or never are."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don’t Allow")
        let response = await alert.beginSheetModal(for: window)
        return response == .alertFirstButtonReturn
    }
}

// MARK: - Pane capabilities

extension WebBrowserPaneViewController: PaneTitleProviding {

    /// The page's title; its host while the title is still blank; the
    /// engine's name for a pane that is on nothing yet.
    public var paneTitle: String {
        if let title = engine.title, !title.isEmpty, title != Self.blankPage.absoluteString { return title }
        if let host = engine.url?.host, !host.isEmpty { return host }
        return engineKind.displayName
    }
}

extension WebBrowserPaneViewController: PaneIconProviding {

    /// The browser the pane is: Safari's icon or Chrome's.
    public var paneIcon: NSImage? { engineKind.icon }
}

// MARK: - Pause Events

extension WebBrowserPaneViewController {

    /// Pauses or unpauses the page's events (spec section 7).
    ///
    /// Pausing first makes the page the window's first responder, so the
    /// page holds focus at the moment it is frozen. That also ends an edit in
    /// the address field without navigating, because the field's cell does
    /// not send its action on end editing. Then the gate closes every user
    /// channel, the activation shield goes up (on the live page too), and the
    /// paused badge shows. Unpausing hands the gate and the shield back to
    /// the settings and hides the badge; first responder stays where it is.
    public func setEventsPaused(_ paused: Bool) {
        guard paused != isEventsPaused else { return }
        if paused { viewIfLoaded?.window?.makeFirstResponder(engine.view) }
        isEventsPaused = paused
        refreshInputGate()
        refreshActivationShield()
        pausedBadge.setPaused(paused)
        eventLog.record(channel: "pane", event: paused ? "pause" : "unpause", decision: .info)
    }
}

// MARK: - Gear menu

extension WebBrowserPaneViewController: PaneMenuProviding {

    /// After the framework's Move: Pause Events (checked while paused),
    /// Settings…, and in debug builds Show Browser Log (spec section 11).
    /// Asked on every click, so the checkmark is always the current state.
    public func makePaneMenuItems() -> [NSMenuItem] {
        let pause = NSMenuItem(title: "Pause Events", action: #selector(togglePauseEvents), keyEquivalent: "")
        pause.target = self
        pause.state = isEventsPaused ? .on : .off
        pause.accessibilityID("pane.options.browser.pause")

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showPaneSettings), keyEquivalent: "")
        settingsItem.target = self
        settingsItem.accessibilityID("pane.options.browser.settings")

        var items = [pause, settingsItem]
        #if DEBUG
        let log = NSMenuItem(title: "Show Browser Log", action: #selector(showBrowserLog), keyEquivalent: "")
        log.target = self
        log.accessibilityID("pane.options.browser.log")
        items.append(log)
        #endif
        return items
    }

    @objc func togglePauseEvents() {
        setEventsPaused(!isEventsPaused)
    }

    /// Whether the settings an engine fixes at construction now resolve to
    /// anything other than `snapshot`.
    func needsRebuild(after snapshot: [String: String]) -> Bool {
        BrowserSettings.constructionSnapshot(in: settings) != snapshot
    }

    /// Whether `settings` — the values the settings sheet shows — put this
    /// pane on a store no other pane uses: private browsing, or a pane jar
    /// the registry can make. Answers for the jar the sheet now shows, not
    /// the one the engine was built on, so the Accept cookies row is never
    /// offered as an override that would not apply after the close.
    func wouldOwnDataStore(under settings: SettingsStore) -> Bool {
        if settings.get(UserSettings.browserPrivateBrowsing) { return true }
        guard settings.get(UserSettings.browserPrivacyStorageJar) == .pane,
              let jars = paneContext.jars else { return false }
        return jars.canIsolate(.pane, context: paneContext)
    }

    /// The pane's settings sheet, ready to present: its construction-time
    /// values are recorded now, and its close rebuilds the engine for
    /// whatever of them changed while it was up (spec section 3). `nil` for a
    /// pane with no settings layer of its own. Internal so a test can drive
    /// open and close without a window.
    func makePaneSettingsSheet() -> BrowserPaneSettingsSheetController? {
        guard let sheet = BrowserPaneSettingsSheetController(pane: self, history: history) else {
            logger.info("browser pane settings requested, but the pane has no settings layer of its own")
            return nil
        }
        settingsSheetSnapshot = BrowserSettings.constructionSnapshot(in: settings)
        sheet.onClose = { [weak self] in self?.paneSettingsSheetDidClose() }
        return sheet
    }

    /// The sheet has gone: rebuild if a construction-time value differs from
    /// what it was when the sheet opened.
    private func paneSettingsSheetDidClose() {
        guard let snapshot = settingsSheetSnapshot else { return }
        settingsSheetSnapshot = nil
        guard !isDiscarded else { return }
        if needsRebuild(after: snapshot) { rebuildEngine() }
    }

    @objc func showPaneSettings() {
        guard view.window != nil else {
            logger.info("browser pane settings requested, but the pane is in no window to present a sheet on")
            return
        }
        guard let sheet = makePaneSettingsSheet() else { return }
        presentAsSheet(sheet)
    }

    @objc func showBrowserLog() {
        onShowBrowserLog?(self)
    }
}

extension WebBrowserPaneViewController: PaneMinimizedRepresenting {
    public var paneMinimizedSymbolName: String { minimizedSymbol }
    public var paneMinimizedTooltip: String { paneTitle }
}

extension WebBrowserPaneViewController: PaneContentTeardown {

    /// Lets go of the engine: a navigation or a transfer that completes into
    /// a discarded pane would otherwise call back into it. The jar is
    /// released, so the reconciler may collect it once the layout no longer
    /// holds the pane.
    public func paneContentWillBeDiscarded() {
        firstResponderObservation = nil
        cancellables.removeAll()
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
        for tab in tabs {
            tab.engine.delegate = nil
            tab.engine.teardown()
        }
        paneContext.jars?.endUse(by: self)
        // A log pane following this one lets it go on the change this sends:
        // its list empties and its title drops this pane's name.
        isDiscarded = true
        eventLog.clear()
    }
}

// MARK: - Tab strip

extension WebBrowserPaneViewController: MultiTabbedViewControllerDelegate {

    public func multiTabbedViewControllerNeedsNewTab(_ controller: MultiTabbedViewController) {
        newTab(controller)
    }

    /// The one funnel every change of the tab in front goes through: a
    /// click, a close's neighbour, a popup brought forward.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController, activeTabDidChange id: UUID?, on edge: Edge?
    ) {
        guard !isInstallingTabs, let id, let tab = tabs.first(where: { $0.id == id }), tab !== activeTab else { return }
        activate(tab)
    }

    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController, didRequestCloseTab id: UUID, on edge: Edge
    ) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        closeTab(tab)
    }

    /// The bar has already moved the tab; the pane's list follows it.
    public func multiTabbedViewController(
        _ controller: MultiTabbedViewController, didReorderTab id: UUID, to index: Int, on edge: Edge
    ) {
        guard let from = tabs.firstIndex(where: { $0.id == id }) else { return }
        let tab = tabs.remove(at: from)
        tabs.insert(tab, at: min(max(index, 0), tabs.count))
        persistTabs()
    }
}

// MARK: - Tab model

/// One tab of a browser pane: the engine drawing it and what the pane keeps
/// per page. A class, so a rebuilt engine is swapped in place and every
/// reference to the tab still names it.
@MainActor
private final class BrowserTab {
    let id = UUID()
    var engine: BrowserEngine
    /// What the tab shows under the bar; holds whichever engine is current.
    let content = BrowserTabContentViewController()
    /// The page to load when the tab is first brought forward.
    var pendingURL: URL?
    /// The title it was stored under, shown until its page loads.
    var storedTitle: String?
    /// The tab whose page opened this one, which comes forward again when
    /// this one's page closes itself.
    weak var opener: BrowserTab?
    /// The history row for the page on screen, so a title that arrives after
    /// the load is filed against it rather than lost.
    var currentVisitID: Int64?
    /// Counts page loads, so a visit row that comes back from the file after
    /// the tab has moved on to the next page is not filed as the current one.
    var visitGeneration = 0

    init(engine: BrowserEngine, pendingURL: URL?, storedTitle: String?) {
        self.engine = engine
        self.pendingURL = pendingURL
        self.storedTitle = storedTitle
        content.show(engine.view)
    }

    func resetVisit() {
        currentVisitID = nil
        visitGeneration += 1
    }
}

/// The page area of one tab: the engine's view, held still while a shelf
/// slides beside the pane — the page paints behind its frame, so resized on
/// every frame it trails the edge.
@MainActor
private final class BrowserTabContentViewController: NSViewController {
    private var pageView: NSView?
    private var holder: NSView?

    override func loadView() {
        view = NSView()
        if let pageView { install(pageView) }
    }

    /// Shows `page`, in place of whatever engine view was there.
    func show(_ page: NSView) {
        pageView = page
        guard isViewLoaded else { return }
        install(page)
    }

    private func install(_ page: NSView) {
        holder?.removeFromSuperview()
        let frameHolder = FrameHoldingView(content: page, leadsWidthChanges: true)
        frameHolder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameHolder)
        NSLayoutConstraint.activate([
            frameHolder.topAnchor.constraint(equalTo: view.topAnchor),
            frameHolder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frameHolder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frameHolder.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        holder = frameHolder
    }
}

/// The tab list as the pane stores it under `tabs`.
struct StoredBrowserTabs: Codable, Equatable {
    var tabs: [StoredBrowserTab]
    var selectedIndex: Int
}

struct StoredBrowserTab: Codable, Equatable {
    /// `nil` for a blank page.
    var url: String?
    var title: String?
}
