import AppKit
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The Secrets window: the privacy words and whatever else the app keeps
/// secret, one topic per kind in a list on the left (Private Words first),
/// edited in place and saved as they change. One window for the app.
///
/// **Hidden until shown, and whenever it is not in front.** The contents sit
/// under an eye with a line through it (``SecretsObscuredView``) unless all
/// three hold: the window is unlocked, the user has not hidden them with the
/// toolbar's eye, and it is the key window of the active app. The toolbar
/// stays usable throughout.
///
/// **Unlocking.** Opening the window shows it locked, then asks for the
/// Mac owner's authentication; the words are read from the vault only once
/// that succeeds, and the table is emptied again whenever the window locks —
/// by the toolbar's lock, by ``SecretsLockPolicy`` (background, sleep,
/// inactivity), or by closing.
///
/// **Nothing outside the app can read it.** The topics and the table are in
/// a ``ConcealedContainerView``, so accessibility clients find no element
/// there; while the words show the window is excluded from screen capture;
/// and the window answers the accessibility focus question with itself, so
/// the field being typed in is not named either.
@MainActor
public final class SecretsWindowController: NSWindowController, NSWindowDelegate {

    enum Identifier {
        static let window = "secrets.window"
        static let visibility = "secrets.toolbar.visibility"
        static let lock = "secrets.toolbar.lock"
        static let settings = "secrets.toolbar.settings"
        static let topics = "secrets.topics"
    }

    /// The topics the list offers, in order.
    enum Topic: String, CaseIterable {
        case privateWords = "Private Words"

        var symbolName: String {
            switch self {
            case .privateWords: "character.textbox"
            }
        }
    }

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "Secrets")

    /// The window on screen, kept alive while it is open.
    private(set) static var shown: SecretsWindowController?

    private let vault: PrivacyWordsVault
    private let words: PrivateWordsTopicViewController
    private let concealed = ConcealedContainerView()
    private let overlay = SecretsObscuredView()
    private lazy var lockPolicy = SecretsLockPolicy { [weak self] in self?.lock() }
    private var observers: [NSObjectProtocol] = []
    private var settingsPopover: NSPopover?
    /// A word to open once the window unlocks ("Replace Private Word…").
    private var pendingWord: String?

    /// Whether the Mac owner has authenticated since the window last locked.
    private(set) var isUnlocked = false { didSet { update() } }
    /// Whether the user has hidden the contents with the toolbar's eye.
    private(set) var isHiddenByUser = false { didSet { update() } }
    private var isAuthenticating = false { didSet { update() } }

    /// Whether the words are on screen.
    var isRevealed: Bool {
        isUnlocked && !isHiddenByUser && (window?.isKeyWindow ?? false) && NSApp.isActive
    }

    // MARK: - Opening

    /// Shows the Secrets window, or brings the open one forward, and asks to
    /// unlock it if it is locked.
    ///
    /// - Parameters:
    ///   - newWordSite: The sites a word added in this window starts on: the
    ///     page's (`PrivacySitePattern.defaultPattern(for:)`) from a web page,
    ///     `*` (the default) from anywhere else.
    ///   - startingWord: A word to replace ("Replace Private Word…" on a
    ///     page): once the window is unlocked its row, made if there is none,
    ///     opens with its Shown As cell editing.
    public static func show(
        vault: PrivacyWordsVault, newWordSite: String = PrivacySitePattern.everywhere,
        startingWord: String? = nil
    ) {
        let controller = shown ?? SecretsWindowController(vault: vault)
        shown = controller
        controller.words.newWordSite = newWordSite
        controller.pendingWord = startingWord ?? controller.pendingWord
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        if controller.isUnlocked {
            controller.openPendingWord()
        } else {
            controller.unlock()
        }
    }

    private init(vault: PrivacyWordsVault) {
        self.vault = vault
        words = PrivateWordsTopicViewController(vault: vault)
        let window = SecretsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Secrets"
        window.identifier = NSUserInterfaceItemIdentifier(Identifier.window)
        window.contentMinSize = NSSize(width: 620, height: 280)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("SecretsWindow")
        super.init(window: window)
        window.delegate = self
        window.contentView = makeContent()
        window.toolbar = makeToolbar()
        window.toolbarStyle = .unified
        if !window.setFrameUsingName("SecretsWindow") { window.center() }
        words.onSaveError = { [weak self] error in self?.showSaveError(error) }
        overlay.onAction = { [weak self] in self?.overlayPressed() }
        observeFrontness()
        update()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Layout

    private func makeContent() -> NSView {
        let root = NSView()
        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.translatesAutoresizingMaskIntoConstraints = false
        split.addArrangedSubview(makeTopicList())
        let detail = words.view
        split.addArrangedSubview(detail)
        split.setHoldingPriority(.defaultHigh, forSubviewAt: 0)

        concealed.translatesAutoresizingMaskIntoConstraints = false
        concealed.addSubview(split)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(concealed)
        root.addSubview(overlay)
        for (inner, outer) in [(split, concealed), (concealed, root), (overlay, root)] as [(NSView, NSView)] {
            NSLayoutConstraint.activate([
                inner.topAnchor.constraint(equalTo: outer.topAnchor),
                inner.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
                outer.trailingAnchor.constraint(equalTo: inner.trailingAnchor),
                outer.bottomAnchor.constraint(equalTo: inner.bottomAnchor)
            ])
        }
        return root
    }

    private func makeTopicList() -> NSView {
        let list = SecretsTopicList(topics: Topic.allCases)
        list.translatesAutoresizingMaskIntoConstraints = false
        list.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        list.widthAnchor.constraint(lessThanOrEqualToConstant: 260).isActive = true
        let preferred = list.widthAnchor.constraint(equalToConstant: 180)
        preferred.priority = .defaultLow
        preferred.isActive = true
        return list
    }

    // MARK: - State

    private func update() {
        let revealed = isRevealed
        concealed.isRevealed = revealed
        overlay.isHidden = revealed
        overlay.state = !isUnlocked ? .locked(isAuthenticating: isAuthenticating)
            : isHiddenByUser ? .hiddenByUser : .notInFront
        updateToolbarItems()
    }

    private func observeFrontness() {
        let center = NotificationCenter.default
        let names: [(Notification.Name, AnyObject?)] = [
            (NSWindow.didBecomeKeyNotification, window),
            (NSWindow.didResignKeyNotification, window),
            (NSApplication.didBecomeActiveNotification, nil),
            (NSApplication.didResignActiveNotification, nil)
        ]
        for (name, object) in names {
            observers.append(center.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.update() }
            })
        }
    }

    /// Asks the Mac owner to authenticate, then reads the words and shows them.
    func unlock() {
        guard !isUnlocked, !isAuthenticating else { return }
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.vault.authenticate(reason: "show your secrets")
                self.isAuthenticating = false
                guard Self.shown === self else { return }
                self.words.load()
                // Authenticating is asking to see them: a hide left over from
                // before the lock does not make the owner press Show as well.
                self.isHiddenByUser = false
                self.isUnlocked = true
                self.lockPolicy.start()
                self.openPendingWord()
            } catch {
                self.isAuthenticating = false
                Self.logger.info("secrets: not unlocked: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Hides the contents, empties the table and needs authentication again.
    func lock() {
        guard isUnlocked else { return }
        lockPolicy.stop()
        words.unload()
        settingsPopover?.performClose(nil)
        isUnlocked = false
    }

    private func openPendingWord() {
        guard isUnlocked else { return }
        if let word = pendingWord {
            pendingWord = nil
            words.replace(word)
        } else {
            words.beginEditingFirstRowIfEmpty()
        }
    }

    private func overlayPressed() {
        if !isUnlocked {
            unlock()
        } else if isHiddenByUser {
            isHiddenByUser = false
        }
    }

    private func showSaveError(_ error: Error) {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = "The private words could not be saved."
        alert.informativeText = error.localizedDescription
        alert.beginSheetModal(for: window, completionHandler: nil)
    }

    // MARK: - Closing

    public func windowWillClose(_ notification: Notification) {
        lock()
        pendingWord = nil
        settingsPopover?.close()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        if Self.shown === self { Self.shown = nil }
    }

    // MARK: - Toolbar actions

    @objc private func toggleVisibility(_ sender: Any?) {
        isHiddenByUser.toggle()
    }

    @objc private func toggleLock(_ sender: Any?) {
        if isUnlocked { lock() } else { unlock() }
    }

    @objc private func showSettings(_ sender: Any?) {
        if let open = settingsPopover, open.isShown {
            open.performClose(nil)
            return
        }
        guard let anchor = toolbarButton(Identifier.settings) else { return }
        let panel = SecretsSettingsPanel(vault: vault, showsOpenButton: false)
        let container = NSViewController()
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 300))
        container.addChild(panel)
        panel.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(panel.view)
        NSLayoutConstraint.activate([
            panel.view.topAnchor.constraint(equalTo: container.view.topAnchor, constant: 8),
            panel.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: panel.view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: panel.view.bottomAnchor)
        ])
        container.view.setAccessibilityIdentifier("secrets.settings.popover")
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = container
        popover.contentSize = container.view.frame.size
        settingsPopover = popover
        popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
    }
}

// MARK: - Toolbar

extension SecretsWindowController: NSToolbarDelegate {

    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "SecretsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        return toolbar
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.init(Identifier.visibility), .init(Identifier.lock), .flexibleSpace, .init(Identifier.settings)]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let action: Selector
        switch itemIdentifier.rawValue {
        case Identifier.visibility: action = #selector(toggleVisibility(_:))
        case Identifier.lock: action = #selector(toggleLock(_:))
        case Identifier.settings: action = #selector(showSettings(_:))
        default: return nil
        }
        let button = NSButton(image: NSImage(), target: self, action: action)
        button.bezelStyle = .texturedRounded
        button.setAccessibilityIdentifier(itemIdentifier.rawValue)
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = button
        if itemIdentifier.rawValue == Identifier.settings {
            Self.style(button, symbol: "gearshape", label: "Secrets Settings")
            item.label = "Settings"
        }
        return item
    }

    private func toolbarButton(_ identifier: String) -> NSButton? {
        window?.toolbar?.items.first { $0.itemIdentifier.rawValue == identifier }?.view as? NSButton
    }

    private func updateToolbarItems() {
        if let visibility = toolbarButton(Identifier.visibility) {
            Self.style(visibility, symbol: isHiddenByUser ? "eye.slash" : "eye",
                       label: isHiddenByUser ? "Show Secrets" : "Hide Secrets")
            visibility.state = isHiddenByUser ? .on : .off
        }
        if let lock = toolbarButton(Identifier.lock) {
            Self.style(lock, symbol: isUnlocked ? "lock.open" : "lock",
                       label: isUnlocked ? "Lock Secrets" : "Unlock Secrets")
            lock.isEnabled = !isAuthenticating
        }
    }

    private static func style(_ button: NSButton, symbol: String, label: String) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        button.toolTip = label
        button.setAccessibilityLabel(label)
    }
}

// MARK: - Pieces

/// The window: whatever has focus inside it, the accessibility API is told
/// the window itself is focused, so the word being typed is never named.
@MainActor
private final class SecretsWindow: NSWindow {
    override var accessibilityFocusedUIElement: Any? { self }
}

/// The topic list on the left: a source list of the window's topics, the
/// one topic selected. Lives inside the concealed container with the rest.
@MainActor
private final class SecretsTopicList: NSView, NSTableViewDataSource, NSTableViewDelegate {

    private let topics: [SecretsWindowController.Topic]
    private let table = NSTableView()

    init(topics: [SecretsWindowController.Topic]) {
        self.topics = topics
        super.init(frame: .zero)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("topic"))
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .sourceList
        table.rowSizeStyle = .default
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityIdentifier(SecretsWindowController.Identifier.topics)
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            bottomAnchor.constraint(equalTo: scroll.bottomAnchor)
        ])
        table.reloadData()
        table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func numberOfRows(in tableView: NSTableView) -> Int { topics.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let topic = topics[row]
        let cell = NSTableCellView()
        let image = NSImageView(image: NSImage(systemSymbolName: topic.symbolName, accessibilityDescription: nil)
            ?? NSImage())
        let label = NSTextField(labelWithString: topic.rawValue)
        let stack = NSStackView(views: [image, label])
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(stack)
        cell.textField = label
        cell.imageView = image
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    /// One topic is always selected: the list is the window's navigation.
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { true }
    func selectionShouldChange(in tableView: NSTableView) -> Bool { topics.count > 1 }
}

/// What covers the window's contents, below the toolbar, while they are
/// hidden: the window's background and an eye with a line through it, with
/// a button under it while there is something to press (Unlock, Show).
@MainActor
final class SecretsObscuredView: NSView {

    enum State: Equatable {
        case locked(isAuthenticating: Bool)
        case hiddenByUser
        case notInFront
    }

    var state: State = .locked(isAuthenticating: false) { didSet { apply() } }
    var onAction: (() -> Void)?

    private let button = NSButton(title: "", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        let eye = NSImageView(image: NSImage(
            systemSymbolName: "eye.slash", accessibilityDescription: "Secrets hidden") ?? NSImage())
        eye.symbolConfiguration = .init(pointSize: 64, weight: .light)
        eye.contentTintColor = .secondaryLabelColor
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(pressed(_:))
        button.setAccessibilityIdentifier("secrets.overlay.action")
        let stack = NSStackView(views: [eye, button])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        setAccessibilityIdentifier("secrets.overlay")
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    /// Clicks stop here: nothing under the eye can be reached through it.
    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) ?? (isHidden ? nil : self)
    }

    private func apply() {
        switch state {
        case .locked(let isAuthenticating):
            button.title = "Unlock"
            button.isHidden = false
            button.isEnabled = !isAuthenticating
        case .hiddenByUser:
            button.title = "Show"
            button.isHidden = false
            button.isEnabled = true
        case .notInFront:
            button.isHidden = true
        }
    }

    @objc private func pressed(_ sender: Any?) {
        onAction?()
    }
}
