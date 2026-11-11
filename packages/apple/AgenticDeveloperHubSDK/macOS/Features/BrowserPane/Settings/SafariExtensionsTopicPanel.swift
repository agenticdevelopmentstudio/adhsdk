//
//  SafariExtensionsTopicPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore

/// The web extensions installed in one profile's Safari panes: Chrome Web
/// Store extensions run by WebKit (`SafariExtensionHost`). Add one by its
/// store ID or link, turn one on or off, remove it, open its options, and
/// ask the store for updates now. Double-click one (or its gear, or Details…) for its
/// details page: site access, pinning, private browsing and file access.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionsTopicPanel: BrowserTopicPanel {

    static let identifier = "settings.browser.safari.extensions"
    /// Empty, not absent: an empty list stays empty (no inline help text), but
    /// the card keeps its message label, which is where a failure shows.
    private static let emptyMessage = ""

    let host: SafariExtensionHost
    /// The pane Options and Get Extensions… open in, asked each time; nil
    /// in the Settings window, where they open in a Web Browser window.
    private let destination: () -> WebBrowserPaneViewController?

    private(set) var table: ComposableSettings.EditableTableCard?
    private(set) var extensions: [BrowserExtension] = []
    private(set) var addButton: NSButton?
    private(set) var getButton: NSButton?
    private(set) var optionsButton: NSButton?
    private(set) var checkButton: NSButton?
    private(set) var detailsButton: NSButton?
    /// The open details page, shown in place of the list.
    private(set) var detailsView: SafariExtensionDetailsView?
    private var tableArea: NSView?
    private var observer: NSObjectProtocol?
    private var changeTask: Task<Void, Never>?

    init(
        host: SafariExtensionHost,
        destination: @escaping () -> WebBrowserPaneViewController?,
        binding: BrowserSettingsBinding
    ) {
        self.host = host
        self.destination = destination
        super.init(title: "Safari Extensions", symbol: "puzzlepiece.extension", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Safari Extensions",
                body: "Safari Web Browser panes run Chrome extensions from the Chrome Web Store "
                    + "and the Safari extensions installed on this Mac from the App Store, "
                    + "through WebKit's own extension support (macOS 15.4 and later). "
                    + (binding.isPaneScope
                        ? "This list is the extensions of this pane's jar. "
                        : "This list is the extensions of the global jar, shared by every Safari "
                            + "pane that follows it. ")
                    + "A worktree's jar or a single pane's jar has extensions of its own. A pane "
                    + "in private browsing runs only the global jar's extensions that are allowed "
                    + "in private browsing."
            ),
            .init(
                title: "Installing",
                body: "Add… lists the Safari extensions that apps from the App Store installed "
                    + "on this Mac; choosing one copies it here. Safari extensions come only "
                    + "from the App Store: Get Safari Extensions from the App Store… opens its "
                    + "Safari Extensions page, and an app installed there appears in Add…. "
                    + "Add… also takes a Chrome extension's ID or its Chrome Web Store link. Or "
                    + "open the Chrome Web Store with Get Extensions… and, on an extension's "
                    + "page, press Add Extension in the pane's address bar. A Safari extension "
                    + "that talks to its own app does not get to here, since only Safari can "
                    + "reach the app. Before anything is installed you "
                    + "are shown what it asks to access and can decline. "
                    + (binding.isPaneScope
                        ? "The store and an extension's options open in a new tab of this pane."
                        : "For the global jar the store and an extension's options open in a "
                            + "Safari Web Browser window of their own, brought forward when it is "
                            + "already open.")
            ),
            .init(
                title: "Managing",
                body: "Switch an extension off to stop it without losing its settings. Select "
                    + "one and press − to remove it with its data. Options opens its settings "
                    + "page. Each pinned extension's button sits in the address bar of every "
                    + "Safari pane on the jar; click it for its popup, right-click it for its "
                    + "menu. Unpinned ones are in the extensions menu beside them."
            ),
            .init(
                title: "Details",
                body: "Double-click an extension, click its gear, or select it and press Details…, for its "
                    + "details page. Site access chooses where it may read and change pages: on "
                    + "click gives it only the page in front, once you click its button; on "
                    + "specific sites gives it the sites you list, separated by commas (a name "
                    + "like example.com covers every page on that site, *.example.com its "
                    + "subdomains too); on all sites gives it every site it asks for. Pin to "
                    + "toolbar puts its button in the address bar rather than the extensions "
                    + "menu. Allow in private browsing lets it run in private panes, which use "
                    + "the global jar's extensions. Allow access to file URLs, offered when it "
                    + "asks for sites that include files, lets it read pages opened from this "
                    + "Mac; it is off until you turn it on. Chrome's per-site settings have no "
                    + "WebKit counterpart, so there are none here."
            ),
            .init(
                title: "Updates",
                body: "Extensions are checked against the Chrome Web Store each time the app "
                    + "opens, and Check for Updates Now checks at once. A Safari extension is "
                    + "updated by the App Store with its app; it is copied here again when the "
                    + "app's version changes, at the same times. When its app is deleted it is "
                    + "switched off, and the Source column says so, until the app is back. An "
                    + "update that asks for more access is shown for you to accept before it is "
                    + "installed."
            )
        ])
    }

    static let keywords: [String] = [
        "safari extensions", "web extensions", "extensions", "plugins", "add-ons",
        "chrome web store", "web store", "extension updates", "remove extension",
        "app store", "mac app store", "safari web extensions"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override var hostsOwnScroll: Bool { true }

    override func loadView() {
        let container = NSView()
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        let table = makeTable()
        self.table = table
        let tableArea = ComposableSettings.TableFillingView(card: table)
        self.tableArea = tableArea
        tableArea.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tableArea)
        NSLayoutConstraint.activate([
            tableArea.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            tableArea.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            container.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: inset),
            container.bottomAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: inset)
        ])
        view = container
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if observer == nil {
            observer = NotificationCenter.default.addObserver(
                forName: SafariExtensionHost.didChangeNotification, object: host, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.reload() }
            }
        }
        reload()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Installed Extensions",
            columns: [
                .init(id: "icon", title: "", width: 24, kind: .image),
                .init(id: "name", title: "Name", width: 220),
                .init(id: "version", title: "Version", width: 80),
                .init(id: "source", title: "Source", width: 130),
                .init(id: "enabled", title: "On", width: 40, kind: .toggle),
                .init(id: "details", title: "", width: 28, kind: .button(symbol: "gearshape", label: "Details"))
            ],
            emptyMessage: Self.emptyMessage,
            visibleRows: 8,
            accessibilityPrefix: Self.identifier
        )
        table.addButton.isHidden = true
        table.onRemove = { [weak self] rowID in self?.remove(rowID) }
        table.onToggle = { [weak self] rowID, _, isOn in self?.setEnabled(rowID, isOn: isOn) }
        table.onSelectionChange = { [weak self] _ in self?.updateButtons() }
        table.onDoubleClick = { [weak self] rowID in self?.showDetails(rowID) }
        table.onButton = { [weak self] rowID, _ in self?.showDetails(rowID) }
        addButton = table.addFooterButton(title: "Add…", identifier: "\(Self.identifier).add") { [weak self] in
            self?.showAddMenu()
        }
        optionsButton = table.addFooterButton(
            title: "Options", identifier: "\(Self.identifier).options"
        ) { [weak self] in
            self?.openOptions()
        }
        detailsButton = table.addFooterButton(
            title: "Details…", identifier: "\(Self.identifier).details-button"
        ) { [weak self] in
            guard let self, let id = self.table?.selectedRowID else { return }
            self.showDetails(id)
        }
        getButton = table.addFooterButton(
            title: "Get Extensions…", identifier: "\(Self.identifier).get"
        ) { [weak self] in
            self?.showGetMenu()
        }
        checkButton = table.addFooterButton(
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

    func updateButtons() {
        optionsButton?.isEnabled = selected?.optionsURL != nil
        detailsButton?.isEnabled = selected != nil
        checkButton?.isEnabled = changeTask == nil
    }

    func reload() {
        extensions = host.extensions()
        if let detailsView, !detailsView.reload() { closeDetails() }
        if let error = host.libraryError {
            table?.emptyLabel.stringValue = error
            table?.setRows([])
            updateButtons()
            return
        }
        table?.emptyLabel.stringValue = Self.emptyMessage
        table?.setRows(extensions.map { item in
            ComposableSettings.EditableTableRow(id: item.id, cells: [
                "icon": .image(item.iconPNG),
                "name": .text(item.name),
                "version": .text(item.version),
                "source": .text(item.sourceName ?? (item.isFromWebStore ? "Chrome Web Store" : "Other")),
                "enabled": .toggle(item.isEnabled)
            ])
        })
        updateButtons()
    }

    /// Shows `id`'s details page in place of the list.
    func showDetails(_ id: String) {
        guard let container = viewIfLoaded else { return }
        closeDetails()
        let details = SafariExtensionDetailsView(
            extensionID: id, host: host, accessibilityPrefix: Self.identifier)
        details.onBack = { [weak self] in self?.closeDetails() }
        details.onOpen = { [weak self] url in self?.open(url) }
        details.onRemove = { [weak self] id in self?.remove(id) }
        details.onError = { [weak self] error in self?.report(error) }
        guard details.reload() else { return }
        container.addSubview(details)
        NSView.pinToEdges(details, of: container)
        tableArea?.isHidden = true
        detailsView = details
    }

    /// Back to the list, with the extension that was shown still selected.
    func closeDetails() {
        guard let detailsView else { return }
        detailsView.removeFromSuperview()
        self.detailsView = nil
        tableArea?.isHidden = false
    }

    /// Opens `url` in a new tab of the destination pane, or, with no pane
    /// (the Settings window), in a Safari Web Browser window of its own,
    /// found again rather than opened anew each time.
    private func open(_ url: URL) {
        if let pane = destination() {
            _ = pane.openTab(url, inBackground: false)
        } else if !WebBrowserWindowController.showExtensions(
            url, store: WebStoreExtension.storeURL, purpose: .safariExtensions) {
            NSSound.beep()
        }
    }

    func openOptions() {
        guard let url = selected?.optionsURL else { return }
        open(url)
    }

    func setEnabled(_ id: String, isOn: Bool) {
        do {
            try host.setEnabled(id, isOn)
        } catch {
            report(error)
        }
        reload()
    }

    func remove(_ id: String) {
        guard let item = extensions.first(where: { $0.id == id }) else { return }
        ComposableSettings.Alerts.confirmDestructive(
            "Remove \u{201C}\(item.name)\u{201D}?",
            detail: "It is removed from every Safari pane on this jar, with its settings and data.",
            actionTitle: "Remove",
            on: view.window
        ) { [weak self] confirmed in
            guard confirmed, let self else { return }
            self.run { host in try await host.remove(id) }
        }
    }

    func checkForUpdates() {
        let window = view.window
        run { host in
            let report = await host.checkForUpdates(presentingOn: window)
            guard let window else { return }
            let alert = NSAlert()
            if report.updated.isEmpty && report.heldBack.isEmpty && report.failures.isEmpty {
                alert.messageText = "Every extension is up to date."
            } else {
                alert.messageText = "Extension updates"
                var lines: [String] = []
                if !report.updated.isEmpty { lines.append("Updated: " + report.updated.joined(separator: ", ")) }
                if !report.heldBack.isEmpty { lines.append("Not updated: " + report.heldBack.joined(separator: ", ")) }
                lines.append(contentsOf: report.failures)
                alert.informativeText = lines.joined(separator: "\n")
            }
            alert.beginSheetModal(for: window) { _ in }
        }
    }

    /// Add…'s menu: the Safari extensions installed on this Mac that are not
    /// added yet, then a Chrome Web Store extension by ID or link, then the
    /// App Store's Safari Extensions page.
    func showAddMenu() {
        guard let button = addButton else { return }
        Task { [weak self] in
            guard let self else { return }
            let available = await host.availableAppExtensions()
            let menu = addMenu(available)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
    }

    func addMenu(_ available: [SafariAppExtension]) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for source in available {
            let item = NSMenuItem(
                title: "\(source.name) (\(source.appName))", action: #selector(addAppExtension(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = source.bundleID
            item.image = NSWorkspace.shared.icon(forFile: (SafariAppExtension.appURL(containing: source.appexURL)
                ?? source.appexURL).path)
            item.image?.size = NSSize(width: 16, height: 16)
            menu.addItem(item)
        }
        appExtensions = available
        if !available.isEmpty { menu.addItem(.separator()) }
        let webStore = NSMenuItem(
            title: "Chrome Web Store Extension…", action: #selector(promptToAddFromMenu(_:)), keyEquivalent: "")
        webStore.target = self
        menu.addItem(webStore)
        menu.addItem(appStoreItem())
        return menu
    }

    /// Get Extensions…'s menu: the two stores.
    func showGetMenu() {
        guard let button = getButton else { return }
        let menu = NSMenu()
        menu.autoenablesItems = false
        let webStore = NSMenuItem(
            title: "Chrome Web Store", action: #selector(openWebStore(_:)), keyEquivalent: "")
        webStore.target = self
        menu.addItem(webStore)
        menu.addItem(appStoreItem(title: "Safari Extensions on the App Store"))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    private func appStoreItem(title: String = "Get Safari Extensions from the App Store…") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(openAppStore(_:)), keyEquivalent: "")
        item.target = self
        return item
    }

    /// What the last Add… menu offered, read back by its items.
    private var appExtensions: [SafariAppExtension] = []

    @objc private func addAppExtension(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let source = appExtensions.first(where: { $0.bundleID == id }),
              let window = view.window else { return }
        run { host in _ = try await host.installAppExtension(source, presentingOn: window) }
    }

    @objc private func promptToAddFromMenu(_ sender: NSMenuItem) { promptToAdd() }

    @objc private func openWebStore(_ sender: NSMenuItem) { open(WebStoreExtension.storeURL) }

    /// The App Store app, on its Safari Extensions page. An extension
    /// installed there is offered by Add… once its app is installed.
    @objc private func openAppStore(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(SafariAppExtension.storeURL)
    }

    /// Asks for an extension's ID or store link, then installs it.
    func promptToAdd() {
        guard let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = "Add a Chrome Web Store extension"
        alert.informativeText = "Its ID, or the link to its page in the Chrome Web Store."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.placeholderString = "https://chromewebstore.google.com/detail/…"
        field.setAccessibilityIdentifier("\(Self.identifier).add.field")
        alert.accessoryView = field
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            // The confirm sheet needs the alert's sheet gone first.
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.run { host in _ = try await host.install(text, presentingOn: window) }
                }
            }
        }
    }

    /// One change at a time; a failure is shown as a sheet.
    private func run(_ work: @escaping @MainActor (SafariExtensionHost) async throws -> Void) {
        guard changeTask == nil else { return NSSound.beep() }
        let host = host
        changeTask = Task { [weak self] in
            do {
                try await work(host)
            } catch {
                self?.report(error)
            }
            self?.changeTask = nil
            self?.reload()
        }
        updateButtons()
    }

    private func report(_ error: Error) {
        guard let window = view.window else { return }
        NSAlert(error: error).beginSheetModal(for: window) { _ in }
    }
}
