//
//  SafariExtensionToolbar.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

/// A Safari pane's extension buttons, in its address bar: one per pinned
/// extension that is on, showing its action for the tab in front (icon,
/// label, badge); an extensions menu holding the unpinned ones; and an Add
/// Extension button while the tab in front is a Chrome Web Store page for an
/// extension not yet installed. A private pane shows only the extensions
/// allowed in private browsing.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionToolbar: NSStackView {

    private weak var extensionWindow: SafariExtensionWindow?
    private weak var host: SafariExtensionHost?
    private var buttons: [ActionButton] = []
    private let addButton: NSButton
    /// The extensions menu: the unpinned extensions, and their popups' anchor.
    private let overflowButton: NSButton
    private var unpinned: [WKWebExtensionContext] = []
    nonisolated(unsafe) private var observers: [NSObjectProtocol] = []
    private var isInstalling = false

    init(window: SafariExtensionWindow, host: SafariExtensionHost) {
        self.extensionWindow = window
        self.host = host
        addButton = NSButton(title: "Add Extension", target: nil, action: nil)
        overflowButton = NSButton(frame: NSRect(x: 0, y: 0, width: 24, height: 22))
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 2
        setHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setAccessibilityIdentifier("safari-extension-toolbar")

        addButton.bezelStyle = .accessoryBarAction
        addButton.controlSize = .small
        addButton.image = NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil)
        addButton.imagePosition = .imageLeading
        addButton.target = self
        addButton.action = #selector(addFromStore)
        addButton.setAccessibilityIdentifier("safari-extension-add")

        overflowButton.isBordered = false
        overflowButton.bezelStyle = .accessoryBarAction
        overflowButton.imagePosition = .imageOnly
        overflowButton.image = NSImage(
            systemSymbolName: "puzzlepiece.extension", accessibilityDescription: "Extensions")
        overflowButton.toolTip = "Extensions"
        overflowButton.target = self
        overflowButton.action = #selector(showOverflowMenu)
        overflowButton.setAccessibilityIdentifier("safari-extension-overflow")

        let center = NotificationCenter.default
        for name in [SafariExtensionHost.actionsDidChangeNotification, SafariExtensionHost.didChangeNotification] {
            observers.append(center.addObserver(forName: name, object: host, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    /// Rebuilds the buttons for the tab in front.
    func refresh() {
        guard let host, let extensionWindow else { return }
        let tab = extensionWindow.activeTabAdapter
        let contexts = host.loadedContexts.filter { extensionWindow.isVisible(to: $0) }
        unpinned = contexts.filter { !host.isPinned($0.uniqueIdentifier) && $0.action(for: tab) != nil }
        let actions = contexts.filter { host.isPinned($0.uniqueIdentifier) }
            .compactMap { context -> (WKWebExtensionContext, WKWebExtension.Action)? in
            guard let action = context.action(for: tab) else { return nil }
            return (context, action)
        }
        // Keep each button while its extension stays, so an open popup keeps
        // its anchor.
        let kept = Dictionary(
            buttons.map { (ObjectIdentifier($0.context), $0) }, uniquingKeysWith: { first, _ in first })
        buttons = actions.map { context, action in
            let button = kept[ObjectIdentifier(context)] ?? ActionButton(context: context, toolbar: self)
            button.show(action)
            return button
        }
        var views: [NSView] = buttons
        if !unpinned.isEmpty { views.append(overflowButton) }
        if let id = WebStoreExtension.detailID(of: tab?.engine?.url), !host.isInstalled(id) {
            views.append(addButton)
        }
        if arrangedSubviews != views {
            arrangedSubviews.forEach { removeArrangedSubview($0); $0.removeFromSuperview() }
            views.forEach(addArrangedSubview)
        }
        isHidden = views.isEmpty
    }

    /// Shows `action`'s popup under its button, or under the extensions menu
    /// for an unpinned one; false when there is nothing on screen to anchor
    /// it.
    func presentPopup(for action: WKWebExtension.Action) -> Bool {
        guard let context = action.webExtensionContext,
              let button = buttons.first(where: { $0.context === context })
                ?? (unpinned.contains { $0 === context } ? overflowButton : nil),
              button.window != nil,
              let popover = action.popupPopover else { return false }
        popover.behavior = .transient
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        return true
    }

    /// A click on the button whose popup is open closes it, as in Safari;
    /// otherwise the extension performs its action.
    fileprivate func perform(_ context: WKWebExtensionContext) {
        let tab = extensionWindow?.activeTabAdapter
        if let popover = context.action(for: tab)?.popupPopover, popover.isShown {
            popover.performClose(nil)
            return
        }
        context.performAction(for: tab)
    }

    fileprivate func menu(for button: ActionButton) -> NSMenu {
        let menu = NSMenu()
        let context = button.context
        if let action = context.action(for: extensionWindow?.activeTabAdapter) {
            action.menuItems.forEach(menu.addItem)
            if !action.menuItems.isEmpty { menu.addItem(.separator()) }
        }
        let options = NSMenuItem(title: "Options…", action: #selector(openOptions(_:)), keyEquivalent: "")
        options.target = self
        options.representedObject = context
        options.isEnabled = context.optionsPageURL != nil
        menu.addItem(options)
        let unpin = NSMenuItem(title: "Unpin from Toolbar", action: #selector(togglePin(_:)), keyEquivalent: "")
        unpin.target = self
        unpin.representedObject = context
        menu.addItem(unpin)
        let remove = NSMenuItem(title: "Remove…", action: #selector(remove(_:)), keyEquivalent: "")
        remove.target = self
        remove.representedObject = context
        menu.addItem(remove)
        return menu
    }

    /// The unpinned extensions, each running its action when chosen, then a
    /// Pin item for each.
    @objc private func showOverflowMenu() {
        let menu = NSMenu()
        let tab = extensionWindow?.activeTabAdapter
        for context in unpinned {
            let name = context.webExtension.displayName ?? context.uniqueIdentifier
            let item = NSMenuItem(title: name, action: #selector(performFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = context
            let action = context.action(for: tab)
            item.image = action?.icon(for: CGSize(width: 16, height: 16))
                ?? context.webExtension.icon(for: CGSize(width: 16, height: 16))
            item.isEnabled = action?.isEnabled ?? false
            menu.addItem(item)
        }
        menu.addItem(.separator())
        for context in unpinned {
            let name = context.webExtension.displayName ?? context.uniqueIdentifier
            let pin = NSMenuItem(
                title: "Pin \u{201C}\(name)\u{201D} to Toolbar", action: #selector(togglePin(_:)), keyEquivalent: "")
            pin.target = self
            pin.representedObject = context
            menu.addItem(pin)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: overflowButton.bounds.maxY + 4), in: overflowButton)
    }

    @objc private func performFromMenu(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? WKWebExtensionContext else { return }
        perform(context)
    }

    @objc private func togglePin(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? WKWebExtensionContext, let host else { return }
        let id = context.uniqueIdentifier
        do { try host.setPinned(id, !host.isPinned(id)) } catch {
            if let nsWindow = extensionWindow?.nsWindow { Self.report(error, on: nsWindow) }
        }
    }

    @objc private func openOptions(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? WKWebExtensionContext,
              let url = context.optionsPageURL else { return }
        _ = extensionWindow?.pane?.openTab(url, inBackground: false)
    }

    @objc private func remove(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? WKWebExtensionContext,
              let host, let nsWindow = extensionWindow?.nsWindow else { return }
        let id = context.uniqueIdentifier
        let alert = NSAlert()
        alert.messageText = "Remove “\(context.webExtension.displayName ?? id)”?"
        alert.informativeText = "Its settings and the data it stored are deleted."
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        alert.beginSheetModal(for: nsWindow) { response in
            guard response == .alertFirstButtonReturn else { return }
            Task { @MainActor in
                do { try await host.remove(id) } catch { Self.report(error, on: nsWindow) }
            }
        }
    }

    @objc private func addFromStore() {
        guard !isInstalling, let host, let extensionWindow,
              let id = WebStoreExtension.detailID(of: extensionWindow.activeTabAdapter?.engine?.url) else { return }
        let nsWindow = extensionWindow.nsWindow
        isInstalling = true
        addButton.isEnabled = false
        Task { @MainActor in
            defer {
                isInstalling = false
                addButton.isEnabled = true
                refresh()
            }
            do {
                _ = try await host.install(id, presentingOn: nsWindow)
            } catch {
                if let nsWindow { Self.report(error, on: nsWindow) }
            }
        }
    }

    static func report(_ error: Error, on window: NSWindow) {
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window) { _ in }
    }
}

/// One extension's button: its icon, its label as the tooltip, and its
/// badge in the corner. A right click shows its menu.
@available(macOS 15.4, *)
@MainActor
private final class ActionButton: NSButton {

    let context: WKWebExtensionContext
    private weak var toolbar: SafariExtensionToolbar?
    private let badge = NSTextField(labelWithString: "")

    init(context: WKWebExtensionContext, toolbar: SafariExtensionToolbar) {
        self.context = context
        self.toolbar = toolbar
        super.init(frame: NSRect(x: 0, y: 0, width: 24, height: 22))
        isBordered = false
        bezelStyle = .accessoryBarAction
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyDown
        target = self
        action = #selector(clicked)
        setAccessibilityIdentifier("safari-extension-\(context.uniqueIdentifier)")
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 24),
            heightAnchor.constraint(equalToConstant: 22)
        ])

        badge.font = .systemFont(ofSize: 8, weight: .bold)
        badge.textColor = .white
        badge.alignment = .center
        badge.wantsLayer = true
        badge.layer?.backgroundColor = NSColor.systemRed.cgColor
        badge.layer?.cornerRadius = 5
        badge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badge)
        NSLayoutConstraint.activate([
            badge.trailingAnchor.constraint(equalTo: trailingAnchor),
            badge.bottomAnchor.constraint(equalTo: bottomAnchor),
            badge.heightAnchor.constraint(equalToConstant: 10),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func show(_ action: WKWebExtension.Action) {
        let icon = action.icon(for: CGSize(width: 16, height: 16))
            ?? context.webExtension.icon(for: CGSize(width: 16, height: 16))
        image = icon ?? NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil)
        let label = action.label.isEmpty ? (context.webExtension.displayName ?? "") : action.label
        toolTip = label
        setAccessibilityLabel(label)
        isEnabled = action.isEnabled
        badge.stringValue = action.badgeText.isEmpty ? "" : " \(action.badgeText) "
        badge.isHidden = action.badgeText.isEmpty
    }

    @objc private func clicked() {
        toolbar?.perform(context)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let toolbar else { return super.rightMouseDown(with: event) }
        NSMenu.popUpContextMenu(toolbar.menu(for: self), with: event, for: self)
    }
}
