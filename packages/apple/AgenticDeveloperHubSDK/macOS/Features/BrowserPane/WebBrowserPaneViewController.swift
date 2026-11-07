//
//  WebBrowserPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import os
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
/// question, the drive seam a model reaches it through — so the two panes
/// differ in exactly one thing, the engine, and a model drives either the
/// same way (`separation-of-concerns`, `dry`). A subclass hands in its
/// engine and names itself; it overrides nothing else.
///
/// Deliberately *not* the extension webview. That one shows HTML an extension
/// hands it behind a custom scheme and opens every link in the user's default
/// browser; this one navigates the open web in place, which is what the word
/// "browser" means to the person who split a pane off for it
/// (`principle-of-least-astonishment`).
///
/// What it remembers in its own state store is one key, `url`.
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

    /// The page shown when the store remembers nothing and no home was given.
    public static let blankPage = URL(string: "about:blank")!

    /// The engine rendering the page.
    public let engine: BrowserEngine

    private let store: PaneStateStore
    let settings: SettingsStore
    private let history: BrowserHistoryStore?
    private let fallbackHomeURL: URL
    /// Which engine draws the page; what the model tools report and open by.
    public let engineKind: BrowserEngineKind
    private let minimizedSymbol: String
    private let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// What the page wrote to `console.*` since the last navigation.
    public var consoleLog: BrowserConsoleLog { engine.consoleLog }

    /// The driving seam a model reaches the pane through. Built on first
    /// use so a pane nobody drives pays nothing for it.
    public private(set) lazy var automation: BrowserAutomation = {
        let automation = BrowserAutomation(driver: engine, console: engine.consoleLog)
        automation.onDriveStateChange = { [weak self] driving in
            guard let self else { return }
            // The start of every drive is a use of this pane, so it becomes
            // the default for the next caller that names none.
            if driving { BrowserPaneFocus.shared.note(self) }
            self.drivenBadge.setDriven(driving)
        }
        return automation
    }()
    let drivenBadge = BrowserDrivenBadge()
    let addressField = NSTextField()
    let backButton = NSButton()
    let forwardButton = NSButton()
    let reloadButton = NSButton()

    /// The window's first responder, followed while the pane is on screen.
    private var firstResponderObservation: NSKeyValueObservation?
    /// The history row for the page on screen, so a title that arrives after
    /// the load is filed against it rather than lost.
    private var currentVisitID: Int64?
    /// Counts page loads, so a visit row that comes back from the file after
    /// the pane has moved on to the next page is not filed as the current one.
    private var visitGeneration = 0

    /// - Parameters:
    ///   - engine: What renders the page. The pane becomes its delegate.
    ///   - engineKind: Which engine `engine` is, for the model tools, and the
    ///     name the pane calls itself while it shows nothing.
    ///   - minimizedSymbol: The SF Symbol a minimized pane shows.
    ///   - store: Where the pane remembers its address between launches.
    ///   - settings: The browser settings the pane honours.
    ///   - history: Where visits are recorded; `nil` records nothing.
    ///   - homeURL: What a pane opens on when nothing is remembered *and* the
    ///     Home Page setting is blank.
    public init(
        engine: BrowserEngine,
        engineKind: BrowserEngineKind,
        minimizedSymbol: String,
        store: PaneStateStore,
        settings: SettingsStore,
        history: BrowserHistoryStore?,
        homeURL: URL
    ) {
        self.engine = engine
        self.engineKind = engineKind
        self.minimizedSymbol = minimizedSymbol
        self.store = store
        self.settings = settings
        self.history = history
        self.fallbackHomeURL = homeURL
        super.init(nibName: nil, bundle: nil)
        engine.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

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

        let bar = NSStackView(views: [backButton, forwardButton, reloadButton, addressField, drivenBadge])
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.spacing = 4
        bar.edgeInsets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false

        // Held still while a shelf slides beside the pane: the page paints
        // behind its frame, so resized on every frame it trails the edge.
        let page = FrameHoldingView(content: engine.view, leadsWidthChanges: true)
        page.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bar)
        root.addSubview(page)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            page.topAnchor.constraint(equalTo: bar.bottomAnchor),
            page.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            page.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            page.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        // The engine reports changes from here on; what is already true is
        // read once now.
        browserEngineTitleDidChange(engine)
        browserEngineAddressDidChange(engine)
        browserEngineHistoryDidChange(engine)
        pruneHistory()
        engine.load(restorationURL)
    }

    /// A pane that appears — opened, or its tab brought forward — is the one
    /// the user is now looking at, and the window's first responder is
    /// followed from here on, so clicking into the page or tabbing into it
    /// makes this the most recently focused Browser pane too.
    open override func viewDidAppear() {
        super.viewDidAppear()
        BrowserPaneFocus.shared.note(self)
        firstResponderObservation = view.window?.observe(\.firstResponder, options: [.new]) { [weak self] window, _ in
            MainActor.assumeIsolated {
                guard let self, let responder = window.firstResponder as? NSView,
                      responder === self.engine.view || responder.isDescendant(of: self.engine.view) else { return }
                BrowserPaneFocus.shared.note(self)
            }
        }
    }

    open override func viewDidDisappear() {
        super.viewDidDisappear()
        firstResponderObservation = nil
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

    /// Files the page that just finished loading. Only pages, only when the
    /// setting says so, and never the blank page.
    private func recordVisit() {
        currentVisitID = nil
        visitGeneration += 1
        guard let history, settings.get(UserSettings.browserRecordsHistory),
              let url = engine.url, url != Self.blankPage else { return }
        let generation = visitGeneration
        let title = engine.title ?? ""
        Task { [weak self, logger] in
            do {
                let visitID = try await history.perform { try $0.record(url, title: title) }
                guard let self, self.visitGeneration == generation else { return }
                self.currentVisitID = visitID
                // A title that arrived while the row was being written found
                // no row to be filed against; file it now.
                if let later = self.engine.title, !later.isEmpty, later != title {
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

    public func browserEngineTitleDidChange(_ engine: BrowserEngine) {
        onPaneTitleChange?()
        guard let visitID = currentVisitID, let title = engine.title, !title.isEmpty else { return }
        file(title, againstVisit: visitID)
    }

    public func browserEngineAddressDidChange(_ engine: BrowserEngine) {
        guard let url = engine.url else { return }
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

    public func browserEngineHistoryDidChange(_ engine: BrowserEngine) {
        backButton.isEnabled = engine.canGoBack
        forwardButton.isEnabled = engine.canGoForward
    }

    /// The visit on record is the page being left. An engine publishes the
    /// new page's title before the load finishes and files its visit, so a
    /// title that lands while a load is in flight would otherwise be written
    /// onto the previous page's row.
    public func browserEngineDidStartNavigation(_ engine: BrowserEngine) {
        currentVisitID = nil
    }

    public func browserEngineDidCommitNavigation(_ engine: BrowserEngine) {
        engine.consoleLog.clear()
        rememberAddress()
    }

    public func browserEngineDidFinishNavigation(_ engine: BrowserEngine) {
        recordVisit()
    }

    /// A dialog raised while a model acts is the model's to hear about, and it
    /// is always dismissed: a panel would block the pane under a hand that is
    /// not the user's. Outside an action the same dismissal applies, since the
    /// pane shows no dialogs of its own; the answer is just not reported.
    public func browserEngine(_ engine: BrowserEngine, didRaise dialog: BrowserDialog) {
        guard automation.isActionInFlight else { return }
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
        if let title = engine.title, !title.isEmpty { return title }
        if let host = engine.url?.host, !host.isEmpty { return host }
        return engineKind.displayName
    }
}

extension WebBrowserPaneViewController: PaneMinimizedRepresenting {
    public var paneMinimizedSymbolName: String { minimizedSymbol }
    public var paneMinimizedTooltip: String { paneTitle }
}

extension WebBrowserPaneViewController: PaneContentTeardown {

    /// Lets go of the engine: a navigation or a transfer that completes into
    /// a discarded pane would otherwise call back into it.
    public func paneContentWillBeDiscarded() {
        firstResponderObservation = nil
        engine.teardown()
    }
}
