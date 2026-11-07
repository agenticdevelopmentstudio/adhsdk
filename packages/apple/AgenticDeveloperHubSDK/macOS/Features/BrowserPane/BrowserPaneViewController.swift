//
//  BrowserPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import os
import UniformTypeIdentifiers
import WebKit
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// A web browser in a pane: an address bar over a `WKWebView`, remembering
/// where it was so a project window reopens on the same page.
///
/// Deliberately *not* the extension webview. That one shows HTML an extension
/// hands it behind a custom scheme and opens every link in the user's default
/// browser; this one navigates the open web in place, which is what the word
/// "browser" means to the person who split a pane off for it
/// (`principle-of-least-astonishment`). The two share a `WKWebView` and the
/// quiet-presentation helper, and nothing else, so neither has to carry the
/// other's rules (`separation-of-concerns`).
///
/// What it remembers in its own state store is one key, `url`. Everything
/// else it honours comes from the Browser settings (`BrowserSettings.swift`):
/// read once where WebKit fixes a value at construction, and followed live
/// everywhere WebKit lets a value change under a page.
@MainActor
public final class BrowserPaneViewController: NSViewController {

    /// Turns what the user typed into something WebKit can load.
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

    /// The page shown when the store remembers nothing and no home was given.
    public static let blankPage = URL(string: "about:blank")!

    private let store: PaneStateStore
    private let settings: SettingsStore
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
    public var onShowBrowserLog: ((BrowserPaneViewController) -> Void)?
    /// The pane's effective Agent access, read from its own layered settings
    /// so a per-pane override counts.
    public var agentAccess: BrowserAgentAccess { settings.get(UserSettings.browserPrivacyAgentAccess) }
    /// Whether the agent is held off this pane: its events are paused and its
    /// Agent while paused setting says the agent pauses too.
    public var isPausedForAgent: Bool {
        isEventsPaused && settings.get(UserSettings.browserPrivacyAgentWhilePaused) == .paused
    }
    private let history: BrowserHistoryStore?
    /// The data store's controls, for the store the web view is on now.
    private var siteData: BrowserSiteData
    private let fallbackHomeURL: URL
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")
    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// The page. Replaced whole when the pane moves to another storage jar,
    /// because WebKit fixes a web view's data store when it is made.
    public private(set) var webView: WKWebView
    /// Hides focus and visibility changes from the current web view's page;
    /// made again with every web view.
    private(set) var activationShield: BrowserActivationShield
    /// What the page wrote to `console.*` since the last navigation.
    public let consoleLog = BrowserConsoleLog()
    /// What this pane delivered to its page, withheld from it, and did around
    /// it (spec section 12). In memory only, and recorded in every build; only
    /// debug builds have a pane that shows it.
    public let eventLog = BrowserEventLog()
    /// Whether the pane has left the layout for good
    /// (`paneContentWillBeDiscarded`), so a log pane stops following it.
    public private(set) var isDiscarded = false
    /// The jar the current web view was built on.
    private(set) var resolvedJar: ResolvedJar
    /// Whether the current web view captures the page console: read once,
    /// where its configuration is built, and used for the message handler,
    /// the user script and the automation alike, so a later shield toggle can
    /// never install the script without its handler or the handler without
    /// its script. A construction-time setting; a change waits for a rebuild.
    private(set) var capturesConsole: Bool
    /// The construction-time settings the current web view was built with
    /// (`BrowserSettings.constructionSnapshot`), so closing the settings
    /// sheet can tell whether the pane still matches them.
    private(set) var builtConstructionSettings: [String: String]
    /// The Third-Party Content value last asked of the current web view, so
    /// an unrelated browser key change does not compile the rules again.
    /// `nil` on a web view that has been asked for nothing yet.
    private var requestedThirdPartyContent: BrowserThirdPartyContent?
    /// The value whose rules the current web view actually has. What tests
    /// wait on; the compile behind it is asynchronous.
    private(set) var appliedThirdPartyContent: BrowserThirdPartyContent?
    /// Counts content-rule requests, so a compile that finishes after a newer
    /// request — or after the web view was rebuilt — is dropped.
    private var contentRulesGeneration = 0
    /// Whether the current request's rule list is still being compiled or
    /// looked up. A load asked for meanwhile is held (`heldLoad`).
    private var isApplyingContentRules = false
    /// The load waiting for the rules to land, so a page never starts before
    /// the blocker it was meant to load under. Released when the current
    /// request finishes, whether it succeeded or failed.
    private var heldLoad: URLRequest?
    /// Whether a load is waiting for the rules. For tests.
    var isHoldingLoad: Bool { heldLoad != nil }
    /// Where rule lists come from. The store by default; a test injects a
    /// slow or failing one to drive the generation and failure paths.
    var contentRuleListProvider: @MainActor (BrowserThirdPartyContent) async throws -> WKContentRuleList? = {
        try await BrowserContentRules.ruleList(for: $0)
    }
    /// Called as each navigation starts. A test seam: it is how a test sees
    /// what rules were on the web view when its first page began loading.
    var onNavigationStart: (() -> Void)?
    /// How many finished compiles were dropped because a newer request or a
    /// rebuild had come since. For tests: what a test awaits to know a stale
    /// result has come back and been ignored, rather than waiting a while.
    private(set) var droppedContentRules = 0
    /// What the jar's row was last named, so a title change writes only when
    /// the name it would write is new.
    private var jarLabel: String?
    private var builtAutomation: BrowserAutomation?
    /// The driving seam a model reaches the pane through. Built on first
    /// use so a pane nobody drives pays nothing for it, and moved to the new
    /// web view on a rebuild, so a handle taken before it still drives the
    /// page on screen.
    public var automation: BrowserAutomation {
        if let builtAutomation { return builtAutomation }
        let automation = BrowserAutomation(webView: webView, console: consoleLog)
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
    /// What holds the web view in the view hierarchy; replaced with it.
    private var pageHost: NSView?
    private weak var addressBar: NSView?
    let drivenBadge = BrowserDrivenBadge()
    let pausedBadge = BrowserPausedBadge()
    let addressField = NSTextField()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()

    private var observations: [NSKeyValueObservation] = []
    /// The theme's window background, for the area around a blank page and
    /// the backdrop under every page.
    private var themedUnderPageColor: NSColor?
    /// The window's first responder, followed while the pane is on screen.
    private var firstResponderObservation: NSKeyValueObservation?
    /// Whether the page held first responder at the last change, so the log
    /// records the page gaining and losing it rather than every move between
    /// two controls outside it.
    private var pageHeldFirstResponder: Bool?
    /// The pane's window's key and occlusion notifications, for the log.
    private var windowObservers: [NSObjectProtocol] = []
    private var cancellables: Set<AnyCancellable> = []
    private var downloads: [WKDownload] = []
    /// The history row for the page on screen, so a title that arrives after
    /// the load is filed against it rather than lost.
    private var currentVisitID: Int64?
    /// Counts page loads, so a visit row that comes back from the file after
    /// the pane has moved on to the next page is not filed as the current one.
    private var visitGeneration = 0

    /// - Parameters:
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours. The app's shared
    ///     store by default; a test hands in an in-memory one.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    ///   - context: The project, worktree and node the pane belongs to.
    public init(
        store: PaneStateStore,
        settings: SettingsStore = UserSettings.shared,
        history: BrowserHistoryStore? = nil,
        homeURL: URL = BrowserPaneViewController.blankPage,
        context: BrowserPaneContext = .detached
    ) {
        self.paneContext = context
        self.store = store
        self.settings = settings
        self.history = history
        self.fallbackHomeURL = homeURL
        let jar = Self.resolveJar(settings: settings, context: context, label: Self.untitledLabel)
        let capturesConsole = settings.get(UserSettings.browserPrivacyConsoleCapture)
        let configuration = Self.makeConfiguration(
            settings: settings, consoleLog: consoleLog, jar: jar, capturesConsole: capturesConsole
        )
        self.resolvedJar = jar
        self.capturesConsole = capturesConsole
        self.builtConstructionSettings = BrowserSettings.constructionSnapshot(in: settings)
        self.siteData = BrowserSiteData(dataStore: configuration.websiteDataStore)
        webView = Self.makeWebView(configuration: configuration)
        activationShield = BrowserActivationShield(webView: webView)
        super.init(nibName: nil, bundle: nil)
        jarLabel = jar.jarID == nil ? nil : Self.untitledLabel
        context.jars?.noteUse(of: jar.jarID, by: self)
        wireWebView()
        applyCookiePolicy()
        observeSettings()
    }

    /// What a new pane jar is named before its page has a title.
    static let untitledLabel = "Browser"

    /// The one place a web view is made, for the first and for every rebuild,
    /// so every page the pane shows sits behind an input gate
    /// (`refreshInputGate`, reached from `wireWebView` via `applyLiveSettings`).
    private static func makeWebView(configuration: WKWebViewConfiguration) -> WKWebView {
        BrowserWebView(frame: NSRect(x: 0, y: 0, width: 640, height: 480), configuration: configuration)
    }

    /// Everything a new web view needs from the pane before it shows a page.
    /// One place, so the web view a rebuild makes is wired exactly as the
    /// first one was (`dry`).
    private func wireWebView() {
        webView.navigationDelegate = self
        webView.uiDelegate = self
        (webView as? BrowserWebView)?.onInputDecision = { [weak self] channel, event, delivered, synthesized, detail in
            self?.recordInput(channel, event, delivered: delivered, synthesized: synthesized, detail: detail)
        }
        webView.allowsBackForwardNavigationGestures = true
        webView.keepPaintingUnderQuietPresentation()
        webView.observeTheme { [weak self] _, palette in
            self?.themedUnderPageColor = palette.windowBackgroundColor
            self?.updatePageBackground()
        }
        updatePageBackground()
        installUserScripts()
        // A new web view starts with no rule lists, whatever the last one had.
        requestedThirdPartyContent = nil
        appliedThirdPartyContent = nil
        isApplyingContentRules = false
        applyLiveSettings()
    }

    /// Puts every user script the pane wants on the current web view's
    /// controller: the console hook when this web view captures the console
    /// (`capturesConsole`), the activation shield's script while the shield
    /// is up.
    ///
    /// The only place the pane adds or removes user scripts.
    /// `WKUserContentController` cannot remove one script, only all of them,
    /// so turning the shield off means putting back everything else, and that
    /// is safe only while one function knows what "everything" is (`dry`).
    /// The automation runtime is not a user script (it is evaluated into its
    /// own content world on demand), so clearing the list does not touch it.
    /// Scripts apply from the next page load.
    private func installUserScripts() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        if capturesConsole { controller.addUserScript(consoleLog.userScript) }
        if let shieldScript = activationShield.userScript {
            controller.addUserScript(shieldScript)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public var onPaneTitleChange: (() -> Void)?

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

    // MARK: - Settings

    /// The data store a pane is on, and which jar that is.
    struct ResolvedJar {
        let dataStore: WKWebsiteDataStore
        /// `nil` for private browsing, which is no jar at all; `.global` for
        /// a worktree or pane jar that could not be had.
        let jar: BrowserStorageJar?
        /// The `browser_jars` row, for a worktree or pane jar.
        let jarID: UUID?

        /// Whether this pane alone uses the store, so a policy set on it
        /// changes no other pane.
        var isOwnedByPane: Bool { jar == nil || jar == .pane }
    }

    /// Private browsing first — a store that lives only as long as the pane,
    /// whatever jar is chosen — and otherwise the jar the setting names,
    /// through the registry. With no registry there is nowhere to keep a
    /// worktree or pane jar, so the pane is on the shared store.
    static func resolveJar(settings: SettingsStore, context: BrowserPaneContext, label: String) -> ResolvedJar {
        if settings.get(UserSettings.browserPrivateBrowsing) {
            return ResolvedJar(dataStore: .nonPersistent(), jar: nil, jarID: nil)
        }
        let wanted = settings.get(UserSettings.browserPrivacyStorageJar)
        guard let jars = context.jars else {
            if wanted != .global {
                logger.debug("browser pane has no jar registry; using the shared jar")
            }
            return ResolvedJar(dataStore: .default(), jar: .global, jarID: nil)
        }
        let resolution = jars.resolve(wanted, context: context, label: label)
        return ResolvedJar(dataStore: resolution.dataStore, jar: resolution.jar, jarID: resolution.jarID)
    }

    /// The configuration WebKit fixes when the web view is made. The settings
    /// read here take effect for the *next* browser pane, and the panel says
    /// so beside each of them. User scripts are not added here: the pane's
    /// `installUserScripts()` owns them, so there is one owner to keep right.
    static func makeConfiguration(
        settings: SettingsStore,
        consoleLog: BrowserConsoleLog,
        context: BrowserPaneContext = .detached
    ) -> WKWebViewConfiguration {
        makeConfiguration(
            settings: settings,
            consoleLog: consoleLog,
            jar: resolveJar(settings: settings, context: context, label: untitledLabel),
            capturesConsole: settings.get(UserSettings.browserPrivacyConsoleCapture)
        )
    }

    /// - Parameter capturesConsole: Whether to register the console message
    ///   handler. The pane reads the setting once and hands the same answer
    ///   to `installUserScripts()`, so the handler and the hook come together
    ///   or not at all. Off, a page has no `webkit.messageHandlers` entry to
    ///   find the hook by.
    static func makeConfiguration(
        settings: SettingsStore,
        consoleLog: BrowserConsoleLog,
        jar: ResolvedJar,
        capturesConsole: Bool
    ) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if capturesConsole {
            configuration.userContentController.add(consoleLog, name: BrowserConsoleLog.handlerName)
        }
        configuration.websiteDataStore = jar.dataStore
        configuration.upgradeKnownHostsToHTTPS = settings.get(UserSettings.browserUpgradesToHTTPS)
        configuration.allowsAirPlayForMediaPlayback = settings.get(UserSettings.browserAllowsAirPlay)
        configuration.mediaTypesRequiringUserActionForPlayback = switch settings.get(UserSettings.browserAutoplay) {
        case .allowed: []
        case .mutedOnly: .audio
        case .never: .all
        }
        return configuration
    }

    /// Recomputes the web view's input gate from the pane's settings and its
    /// pause state. The one place the gate is built, so a settings change, a
    /// pause change and a rebuilt web view (through `wireWebView`) all land on
    /// the same answer. Only the web view is gated; the pane's address bar and
    /// chrome never are, so the address bar and the back, forward and reload
    /// buttons still work while the pane is paused.
    private func refreshInputGate() {
        (webView as? BrowserWebView)?.gate = BrowserInputGate(settings: settings, isPaused: isEventsPaused)
    }

    /// Raises or lowers the activation shield from the Hide Focus setting and
    /// the pause state: up when either asks for it. The one place that answer
    /// is computed, beside `refreshInputGate` for the same reasons. When the
    /// shield's state moves, the user scripts are put back so the next page
    /// load follows it; the shield itself acts on the page already showing.
    private func refreshActivationShield() {
        let wasActive = activationShield.isActive
        activationShield.apply(
            active: settings.get(UserSettings.browserPrivacyHideActivation) || isEventsPaused)
        if activationShield.isActive != wasActive { installUserScripts() }
    }

    /// Every setting WebKit lets change under a page, applied from the store.
    /// Called once at construction and again whenever a browser key changes.
    private func applyLiveSettings() {
        refreshInputGate()
        refreshActivationShield()
        let zoom = settings.get(UserSettings.browserPageZoom)
        let zoomRange = BrowserSettings.pageZoomRange
        webView.pageZoom = min(max(zoom, zoomRange.lowerBound), zoomRange.upperBound)
        let agent = settings.get(UserSettings.browserCustomUserAgent)
        webView.customUserAgent = agent.isEmpty ? nil : agent
        webView.isInspectable = settings.get(UserSettings.browserWebInspectorEnabled)
        applyContentRules()

        let preferences = webView.configuration.preferences
        let fontSize = settings.get(UserSettings.browserMinimumFontSize)
        let fontRange = BrowserSettings.minimumFontSizeRange
        preferences.minimumFontSize = CGFloat(min(max(fontSize, fontRange.lowerBound), fontRange.upperBound))
        preferences.javaScriptCanOpenWindowsAutomatically = !settings.get(UserSettings.browserBlocksPopups)
        preferences.isFraudulentWebsiteWarningEnabled = settings.get(UserSettings.browserFraudWarning)
    }

    /// Puts the Third-Party Content setting's rule list on the current web
    /// view, live: the old list comes off and the new one goes on when its
    /// compile finishes (spec section 9). Only when the value differs from
    /// the one last asked of this web view, so a zoom drag does not recompile.
    ///
    /// The compile is asynchronous, so a request carries a generation; one
    /// that finishes after a newer request, or after a rebuild (which asks
    /// again for its new web view), is dropped rather than applied over it.
    /// `.allow` takes the rules off at once, with nothing to wait for. Until a
    /// blocking compile lands the web view keeps whatever list it had, and a
    /// load asked for meanwhile is held (`loadOnceRulesAreOn`).
    ///
    /// A failed compile fails **open**: the web view keeps the lists it had,
    /// the held load goes ahead, the failure is logged, and the request is
    /// forgotten so the next settings change tries again. Blocking every load
    /// because the rule store errored would break browsing outright, which is
    /// a worse answer to a store fault than a page with its third-party
    /// content for now.
    private func applyContentRules() {
        let policy = settings.get(UserSettings.browserPrivacyThirdPartyContent)
        guard policy != requestedThirdPartyContent else { return }
        requestedThirdPartyContent = policy
        contentRulesGeneration += 1
        let generation = contentRulesGeneration
        guard policy != .allow else {
            webView.configuration.userContentController.removeAllContentRuleLists()
            appliedThirdPartyContent = .allow
            finishContentRules()
            return
        }
        isApplyingContentRules = true
        let provide = contentRuleListProvider
        Task { [weak self, logger] in
            do {
                let list = try await provide(policy)
                guard let self else { return }
                guard self.contentRulesGeneration == generation else {
                    self.droppedContentRules += 1
                    return
                }
                let controller = self.webView.configuration.userContentController
                controller.removeAllContentRuleLists()
                if let list { controller.add(list) }
                self.appliedThirdPartyContent = policy
                self.finishContentRules()
            } catch {
                guard let self else { return }
                // A stale failure says nothing about the current request: it
                // must neither forget that request nor release its held load.
                guard self.contentRulesGeneration == generation else {
                    self.droppedContentRules += 1
                    return
                }
                self.requestedThirdPartyContent = nil
                logger.error(
                    "browser content rules failed to compile: \(error.localizedDescription, privacy: .public)")
                self.finishContentRules()
            }
        }
    }

    /// The current request is done, one way or the other: a held load may go.
    private func finishContentRules() {
        isApplyingContentRules = false
        guard let request = heldLoad else { return }
        heldLoad = nil
        webView.load(request)
    }

    /// Loads `request` now, or — while the current rule list is still on its
    /// way — once it is on, so a blocked resource is never fetched by a page
    /// that started first. A newer request replaces a held one.
    private func loadOnceRulesAreOn(_ request: URLRequest) {
        if isApplyingContentRules {
            heldLoad = request
        } else {
            webView.load(request)
        }
    }

    /// The cookie policy belongs to the data store, not the web view, and a
    /// global or worktree store is shared by other panes. The pane still
    /// applies it, because a private or pane store has no other owner — but
    /// only when the cookie setting itself changes, not on every browser
    /// change: a zoom slider drag is not a reason for every open pane to
    /// rewrite the shared store's policy once per tick.
    private func applyCookiePolicy() {
        let acceptsCookies = Self.acceptsCookies(settings: settings, ownsDataStore: resolvedJar.isOwnedByPane)
        let siteData = siteData
        Task { await siteData.setAcceptsCookies(acceptsCookies) }
    }

    /// The cookie policy to put on the pane's store. A pane's own override
    /// counts only on a store the pane alone uses; on a shared one it would
    /// silently change every sibling's policy, so the shared value wins.
    static func acceptsCookies(settings: SettingsStore, ownsDataStore: Bool) -> Bool {
        if !ownsDataStore, let layered = settings as? LayeredSettingsStore {
            return layered.fallback.get(UserSettings.browserAcceptsCookies)
        }
        return settings.get(UserSettings.browserAcceptsCookies)
    }

    private func observeSettings() {
        settings.changes
            .filter { $0.hasPrefix("browser.") }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] key in
                guard let self else { return }
                // A pane's layered store publishes its own overrides and only
                // the shared changes no override hides, so every key here is
                // one that took effect on this pane.
                self.eventLog.record(channel: "settings", event: "changed", decision: .info, detail: key)
                self.applyLiveSettings()
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
    private func storageJarSettingDidChange() {
        guard resolvedJar.jar != nil else { return }
        if paneSettings?.hasOverride(UserSettings.browserPrivacyStorageJar) == true { return }
        guard needsRebuildForJar() else { return }
        rebuildWebView()
    }

    /// Whether the jar setting now names a different store from the one the
    /// web view is on. Answered without making a row: a jar not made yet is
    /// a different one by definition.
    func needsRebuildForJar() -> Bool {
        let wanted = settings.get(UserSettings.browserPrivacyStorageJar)
        guard let jars = paneContext.jars, wanted != .global,
              jars.canIsolate(wanted, context: paneContext) else {
            return resolvedJar.jar != .global
        }
        guard resolvedJar.jar == wanted else { return true }
        return jars.jarID(for: wanted, context: paneContext) != resolvedJar.jarID
    }

    /// Throws the web view away and makes a new one on the jar the settings
    /// resolve to now, on the page the old one was showing.
    ///
    /// WebKit fixes a web view's data store when it is made, so moving jars is
    /// a new web view, not a property change. The old one is detached exactly
    /// as a discarded pane's is, so it lets go of its store — WebKit will not
    /// remove a store a web view still holds.
    ///
    /// Downloads in flight in the old web view are cancelled with it, as are
    /// its back and forward history and any form a page had half filled in.
    /// That is accepted rather than worked around: changing a pane's jar is
    /// rare and deliberate, and carrying a download across two data stores
    /// would hand one jar's session to another.
    public func rebuildWebView() {
        let shownURL = webView.url.flatMap { $0 == Self.blankPage ? nil : $0 }
        // A navigation still held for the old web view's rules is where the
        // pane was going, so it wins over the page the old one was showing.
        let heldURL = heldLoad?.url
        let label = paneTitle
        detachWebView()
        webView.removeFromSuperview()
        pageHost?.removeFromSuperview()
        pageHost = nil
        heldLoad = nil

        let jar = Self.resolveJar(settings: settings, context: paneContext, label: label)
        let capturesConsole = settings.get(UserSettings.browserPrivacyConsoleCapture)
        let configuration = Self.makeConfiguration(
            settings: settings, consoleLog: consoleLog, jar: jar, capturesConsole: capturesConsole
        )
        resolvedJar = jar
        self.capturesConsole = capturesConsole
        builtConstructionSettings = BrowserSettings.constructionSnapshot(in: settings)
        // What the old web view captured is not this one's to report.
        if !capturesConsole { consoleLog.clear() }
        jarLabel = jar.jarID == nil ? nil : label
        paneContext.jars?.noteUse(of: jar.jarID, by: self)
        siteData = BrowserSiteData(dataStore: configuration.websiteDataStore)
        webView = Self.makeWebView(configuration: configuration)
        activationShield = BrowserActivationShield(webView: webView)
        wireWebView()
        builtAutomation?.retarget(to: webView)
        builtAutomation?.isConsoleCaptureOn = capturesConsole
        applyCookiePolicy()
        observeSettings()
        eventLog.record(channel: "settings", event: "rebuild", decision: .info, detail: jar.jar?.rawValue ?? "private")

        guard isViewLoaded else { return }
        installPageHost()
        observeWebView()
        if view.window != nil { observeFirstResponder() }
        loadOnceRulesAreOn(URLRequest(url: heldURL ?? shownURL ?? restorationURL))
    }

    /// Keeps the pane jar's row named after the page, so a list of jars says
    /// what each was for after its pane is gone.
    private func updateJarLabel() {
        guard resolvedJar.jar == .pane, let jarID = resolvedJar.jarID, let jars = paneContext.jars else { return }
        let label = paneTitle
        guard label != jarLabel else { return }
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

    public override func loadView() {
        let root = ThemedBackgroundView(role: .windowBackground)
        view = root

        configureButton(backButton, symbol: "chevron.left", label: "Back", action: #selector(goBack))
        configureButton(forwardButton, symbol: "chevron.right", label: "Forward", action: #selector(goForward))
        configureButton(reloadButton, symbol: "arrow.clockwise", label: "Reload", action: #selector(reload))

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

        let bar = NSStackView(views: [backButton, forwardButton, reloadButton, addressField, pausedBadge, drivenBadge])
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
        installPageHost()
    }

    /// Puts the current web view under the address bar.
    private func installPageHost() {
        guard let bar = addressBar else { return }
        // Held still while a shelf slides beside the pane: the page paints
        // behind its frame, so resized on every frame it trails the edge.
        let page = FrameHoldingView(content: webView, leadsWidthChanges: true)
        page.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(page)
        NSLayoutConstraint.activate([
            page.topAnchor.constraint(equalTo: bar.bottomAnchor),
            page.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            page.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            page.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pageHost = page
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        observeWebView()
        pruneHistory()
        loadOnceRulesAreOn(URLRequest(url: restorationURL))
    }

    /// A pane that appears — opened, or its tab brought forward — is the one
    /// the user is now looking at, and the window's first responder is
    /// followed from here on, so clicking into the page or tabbing into it
    /// makes this the most recently focused Browser pane too.
    public override func viewDidAppear() {
        super.viewDidAppear()
        BrowserPaneFocus.shared.note(self)
        observeFirstResponder()
        observeWindow()
    }

    private func observeFirstResponder() {
        firstResponderObservation = view.window?.observe(\.firstResponder, options: [.new]) { [weak self] window, _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let responder = window.firstResponder as? NSView
                let pageHolds = responder.map { $0 === self.webView || $0.isDescendant(of: self.webView) } ?? false
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

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        firstResponderObservation = nil
        pageHeldFirstResponder = nil
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []
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

    /// Title, address and the back/forward affordances all follow the web view
    /// rather than being set by whichever code path happened to navigate —
    /// a link click, a redirect and a typed address all land here the same way.
    private func observeWebView() {
        observations = [
            webView.observe(\.title, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.titleDidChange() }
            },
            webView.observe(\.url, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.addressDidChange() }
            },
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.backButton.isEnabled = self?.webView.canGoBack ?? false }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.forwardButton.isEnabled = self?.webView.canGoForward ?? false }
            }
        ]
    }

    private func titleDidChange() {
        onPaneTitleChange?()
        updateJarLabel()
        guard let visitID = currentVisitID, let title = webView.title, !title.isEmpty else { return }
        file(title, againstVisit: visitID)
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

    private func addressDidChange() {
        updatePageBackground()
        guard let url = webView.url else { return }
        // A field being edited is the user's; overwriting it mid-keystroke
        // because a redirect landed would throw away what they typed. A field
        // has an editor exactly while it is being edited, so that is the test
        // -- not a comparison against the window's first responder, which is
        // nil on both sides before the pane is in a window, as it is when the
        // restoration load lands.
        if addressField.currentEditor() == nil {
            addressField.stringValue = url == Self.blankPage ? "" : url.absoluteString
        }
        onPaneTitleChange?()
    }

    /// Nothing loaded — no address yet, or the blank page — is see-through, so
    /// the pane's themed backdrop shows instead of WebKit's white; a real page
    /// gets its opaque backdrop back the moment the address moves to it, since
    /// a site with no background of its own is written for white. See
    /// `WKWebView.setDrawsPageBackground(_:)`.
    ///
    /// The area past the page's edges follows the same split. Around a blank
    /// page it is the theme's. Around a real page it is left to WebKit, which
    /// takes the page's own background.
    ///
    /// The backdrop under every page is the theme's window background. WebKit
    /// paints out of process, a frame or more behind the web view's frame, so
    /// a resize that widens the pane uncovers a strip at the trailing edge
    /// that shows only that backdrop until the page catches up. Left at
    /// WebKit's default, `controlBackgroundColor`, it was a grey bar chasing
    /// the edge; in the page's own colour it still flashed wherever the page
    /// painted something else over its declared background. In the theme's
    /// colour it reads as the window showing through, the same surface as
    /// the pane around it. The backdrop shows only where the page has not
    /// painted: a page with no background of its own still draws white.
    private func updatePageBackground() {
        let url = webView.url
        let isPage = url != nil && url != Self.blankPage
        webView.setDrawsPageBackground(isPage)
        webView.underPageBackgroundColor = isPage ? nil : themedUnderPageColor
        webView.setPageBackdropColor(themedUnderPageColor)
    }

    /// Writes the address the pane will reopen on. Once per committed
    /// navigation rather than on every change of `webView.url` — a redirect
    /// chain or a fragment change reports several — and only when it differs
    /// from what is remembered, since the store is a database write.
    private func rememberAddress() {
        let address = webView.url.flatMap { $0 == Self.blankPage ? nil : $0.absoluteString }
        guard address != store.paneStateValue(forKey: Self.addressKey) else { return }
        store.setPaneStateValue(address, forKey: Self.addressKey)
    }

    /// Files the page that just finished loading. Only pages, only when the
    /// setting says so, and never the blank page.
    private func recordVisit() {
        currentVisitID = nil
        visitGeneration += 1
        guard let history, settings.get(UserSettings.browserRecordsHistory),
              let url = webView.url, url != Self.blankPage else { return }
        let generation = visitGeneration
        let title = webView.title ?? ""
        Task { [weak self, logger] in
            do {
                let visitID = try await history.perform { try $0.record(url, title: title) }
                guard let self, self.visitGeneration == generation else { return }
                self.currentVisitID = visitID
                // A title that arrived while the row was being written found
                // no row to be filed against; file it now.
                if let later = self.webView.title, !later.isEmpty, later != title {
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
        loadOnceRulesAreOn(URLRequest(url: url))
        view.window?.makeFirstResponder(webView)
    }

    // History moves are not held for rules, but they do cancel a held load,
    // so a load asked for earlier cannot land over them afterwards.
    @objc private func goBack() {
        heldLoad = nil
        webView.goBack()
    }
    @objc private func goForward() {
        heldLoad = nil
        webView.goForward()
    }
    @objc private func reload() {
        heldLoad = nil
        webView.reload()
    }
}

// MARK: - Pane capabilities

extension BrowserPaneViewController: PaneTitleProviding {

    /// The page's title; its host while the title is still blank; "Browser"
    /// for a pane that is on nothing yet.
    public var paneTitle: String {
        if let title = webView.title, !title.isEmpty { return title }
        if let host = webView.url?.host, !host.isEmpty { return host }
        return "Browser"
    }
}

// MARK: - Pause Events

extension BrowserPaneViewController {

    /// Pauses or unpauses the page's events (spec section 7).
    ///
    /// Pausing first makes the web view the window's first responder, so the
    /// page holds focus at the moment it is frozen. That also ends an edit in
    /// the address field without navigating, because the field's cell does
    /// not send its action on end editing. Then the gate closes every user
    /// channel, the activation shield goes up (on the live page too), and the
    /// paused badge shows. Unpausing hands the gate and the shield back to
    /// the settings and hides the badge; first responder stays where it is.
    public func setEventsPaused(_ paused: Bool) {
        guard paused != isEventsPaused else { return }
        if paused { viewIfLoaded?.window?.makeFirstResponder(webView) }
        isEventsPaused = paused
        refreshInputGate()
        refreshActivationShield()
        pausedBadge.setPaused(paused)
        eventLog.record(channel: "pane", event: paused ? "pause" : "unpause", decision: .info)
    }
}

// MARK: - Gear menu

extension BrowserPaneViewController: PaneMenuProviding {

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

    /// Whether the settings WebKit fixes at construction now resolve to
    /// anything other than `snapshot` — a change made in the pane's sheet, or
    /// one made globally since the web view was built that the pane follows.
    func needsRebuild(after snapshot: [String: String]) -> Bool {
        BrowserSettings.constructionSnapshot(in: settings) != snapshot
    }

    /// The pane's settings sheet, over the pane's own settings layer. When
    /// it closes, a construction-time setting that no longer matches the web
    /// view rebuilds it (spec section 3).
    @objc func showPaneSettings() {
        guard view.window != nil else { return }
        guard let sheet = BrowserPaneSettingsSheetController(pane: self, history: history) else {
            logger.info("browser pane settings requested, but the pane has no settings layer of its own")
            return
        }
        sheet.onClose = { [weak self] in
            guard let self, !self.isDiscarded else { return }
            if self.needsRebuild(after: self.builtConstructionSettings) { self.rebuildWebView() }
        }
        presentAsSheet(sheet)
    }

    @objc func showBrowserLog() {
        onShowBrowserLog?(self)
    }
}

extension BrowserPaneViewController: PaneMinimizedRepresenting {
    public var paneMinimizedSymbolName: String { "globe" }
    public var paneMinimizedTooltip: String { paneTitle }
}

extension BrowserPaneViewController: PaneContentTeardown {

    /// Stops the page, cancels its downloads and drops the delegates: a
    /// navigation or a transfer that completes into a discarded pane would
    /// otherwise call back into it. The jar is released, so the reconciler
    /// may collect it once the layout no longer holds the pane.
    public func paneContentWillBeDiscarded() {
        detachWebView()
        paneContext.jars?.endUse(by: self)
        // A log pane following this one lets it go on the change this sends:
        // its list empties and its title drops this pane's name.
        isDiscarded = true
        eventLog.clear()
    }

    /// Lets go of the current web view: shared by a discarded pane and by a
    /// rebuild, which discards the web view and keeps the pane.
    func detachWebView() {
        observations.removeAll()
        firstResponderObservation = nil
        cancellables.removeAll()
        downloads.forEach { $0.cancel() }
        downloads.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        // The handler holds the log strongly and the pane holds the log, so
        // without this the two outlive the pane together.
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: BrowserConsoleLog.handlerName
        )
    }
}

// MARK: - Navigation

extension BrowserPaneViewController: WKNavigationDelegate {

    /// Per navigation, and read off the settings each time, so switching
    /// JavaScript or Lockdown Mode takes effect on the next page rather than
    /// the next pane. WebKit picks **one** `decidePolicyFor` overload, so the
    /// download decision lives here too.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        preferences.allowsContentJavaScript = settings.get(UserSettings.browserJavaScriptEnabled)
        preferences.isLockdownModeEnabled = settings.get(UserSettings.browserLockdownMode)
        return (navigationAction.shouldPerformDownload ? .download : .allow, preferences)
    }

    /// A response the web view cannot show — a zip, a disk image — is a
    /// download, which is what every browser does with one.
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        navigationResponse.canShowMIMEType ? .allow : .download
    }

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        adopt(download)
    }

    public func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload
    ) {
        adopt(download)
    }

    /// The visit on record is the page being left. WebKit publishes the
    /// new page's title before `didFinish` files its visit, so a title that
    /// lands while a load is in flight would otherwise be written onto the
    /// previous page's row.
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        currentVisitID = nil
        recordNavigation("start")
        onNavigationStart?()
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        consoleLog.clear()
        rememberAddress()
        recordNavigation("commit")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recordVisit()
        recordNavigation("finish")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        recordNavigation("fail", error: error)
    }

    /// A navigation into the log, by host: a path or query can carry a token.
    private func recordNavigation(_ event: String, error: Error? = nil) {
        var detail = webView.url?.host ?? ""
        if let error { detail += (detail.isEmpty ? "" : " ") + "error \((error as NSError).code)" }
        eventLog.record(channel: "navigation", event: event, decision: .info, detail: detail)
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        // A cancelled load is the next navigation starting, not a failure.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        recordNavigation("fail", error: error)
        logger.error("browser pane failed to load: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - Downloads

extension BrowserPaneViewController: WKDownloadDelegate {

    private func adopt(_ download: WKDownload) {
        download.delegate = self
        downloads.append(download)
        recordDownload("start", download)
    }

    private func recordDownload(_ event: String, _ download: WKDownload) {
        eventLog.record(
            channel: "download", event: event, decision: .info, detail: download.originalRequest?.url?.host ?? "")
    }

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

    public func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        if settings.get(UserSettings.browserAsksDownloadLocation) {
            // Asking needs a window to ask on. A pane with none is not a
            // reason to save somewhere the user was never shown
            // (`explicit-over-implicit`): refuse the download instead.
            guard let window = view.window else {
                logger.error("browser download refused: asked to choose a location with no window to ask on")
                return nil
            }
            let panel = NSSavePanel()
            panel.nameFieldStringValue = suggestedFilename
            panel.directoryURL = BrowserSettings.downloadDirectory(in: settings)
            panel.canCreateDirectories = true
            let response = await panel.beginSheetModal(for: window)
            guard response == .OK, let chosen = panel.url else { return nil }
            // Replace was answered on the sheet. `WKDownload` refuses to write
            // over an existing file, so the file goes first, and if it will
            // not go the download fails here rather than after the transfer.
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
        return Self.uniqueDestination(for: suggestedFilename, in: directory)
    }

    public func downloadDidFinish(_ download: WKDownload) {
        downloads.removeAll { $0 === download }
        recordDownload("finish", download)
        // The host says which site it came from; the path and query can carry
        // a token or a name, and stay out of the public log.
        let host = download.originalRequest?.url?.host ?? ""
        logger.info("browser download finished from \(host, privacy: .public)")
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeAll { $0 === download }
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        recordDownload("fail", download)
        logger.error("browser download failed: \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - UI delegate

extension BrowserPaneViewController: WKUIDelegate {

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        reportDialog(.alert, message)
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        reportDialog(.confirm, message)
        return false
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        reportDialog(.prompt, prompt)
        return nil
    }

    /// A dialog raised while a model acts is the model's to hear about, and it
    /// is always dismissed: a panel would block the pane under a hand that is
    /// not the user's. Outside an action the same dismissal applies, since the
    /// pane shows no dialogs of its own; the answer is just not reported.
    private func reportDialog(_ kind: BrowserDialog.Kind, _ message: String) {
        // The message is the page's words and stays out of the log.
        let reported = builtAutomation?.isActionInFlight == true
        eventLog.record(
            channel: "dialog", event: kind.rawValue, decision: .info,
            detail: reported ? "dismissed, reported to the agent" : "dismissed")
        guard automation.isActionInFlight else { return }
        automation.dialogRaised(kind: kind, message: message)
    }

    /// A `target="_blank"` link asks for a new window. A pane has no windows to
    /// give it, so the link opens here instead — in the pane the user is
    /// looking at, which is where a click goes everywhere else.
    ///
    /// A script's `window.open()` with no address asks for a blank window to
    /// write into later. There is nothing to open for that, and loading the
    /// blank page here would throw away the page on screen and the address
    /// the pane remembers, so it is refused.
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url, url != Self.blankPage else { return nil }
        webView.load(navigationAction.request)
        return nil
    }

    /// Camera and microphone, decided by the Media setting: granted or refused
    /// outright, or asked about — on the pane's window, naming the site, so
    /// the answer is given to the page that asked and nothing else.
    public func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        let device = switch type {
        case .camera: "camera"
        case .microphone: "microphone"
        case .cameraAndMicrophone: "camera and microphone"
        @unknown default: "camera or microphone"
        }
        eventLog.record(channel: "permission", event: "request", decision: .info, detail: "\(origin.host) \(device)")
        let decision = await decideMediaCapture(origin: origin, device: device)
        let answer = switch decision {
        case .grant: "granted"
        case .deny: "denied"
        case .prompt: "left to WebKit"
        @unknown default: "unknown"
        }
        eventLog.record(
            channel: "permission", event: "decision", decision: .info, detail: "\(origin.host) \(device) \(answer)")
        return decision
    }

    private func decideMediaCapture(origin: WKSecurityOrigin, device: String) async -> WKPermissionDecision {
        switch settings.get(UserSettings.browserMediaCapture) {
        case .allow: return .grant
        case .deny: return .deny
        case .ask: break
        }
        guard let window = view.window else { return .prompt }
        let alert = NSAlert()
        alert.messageText = "\(origin.host) wants to use your \(device)."
        alert.informativeText = "Browser settings decide whether sites ask, are always allowed, or never are."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don’t Allow")
        let response = await alert.beginSheetModal(for: window)
        return response == .alertFirstButtonReturn ? .grant : .deny
    }
}
