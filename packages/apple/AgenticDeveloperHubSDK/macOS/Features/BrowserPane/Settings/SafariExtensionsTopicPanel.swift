//
//  SafariExtensionsTopicPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore
import UniformTypeIdentifiers

/// The web extensions installed in one profile's Safari panes: Chrome Web
/// Store extensions, the App Store's Safari extensions and downloaded ones,
/// run by WebKit (`SafariExtensionHost`). One table — on, icon, name,
/// version, description, gear — with + (the Add Extension menu) and ↻
/// (reload and check for updates) in its header row. The gear opens the
/// extension's details (`SafariExtensionDetailsView`) in a popover anchored to
/// it: site access, pinning, private browsing, file access, options, store
/// page and removal.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionsTopicPanel: BrowserTopicPanel {

    static let identifier = "settings.browser.safari.extensions"
    /// Empty, not absent: an empty list stays empty (no inline help text), but
    /// the card keeps its message label, which is where a failure shows.
    private static let emptyMessage = ""
    /// What Name and Version get beyond their widest cell.
    static let fitMargin: CGFloat = 12
    /// The details popover's size.
    static let detailsSize = NSSize(width: 460, height: 520)
    /// What Downloaded… lets the person choose.
    static let downloadedTypes: [UTType] = [UTType(filenameExtension: "crx"), .zip, .folder].compactMap { $0 }

    let host: SafariExtensionHost
    /// The pane Options and the Chrome Web Store open in, asked each time;
    /// nil in the Settings window, where they open in a Web Browser window.
    private let destination: () -> WebBrowserPaneViewController?

    private(set) var table: ComposableSettings.EditableTableCard?
    private(set) var extensions: [BrowserExtension] = []
    /// The header row's + and ↻.
    private(set) var addButton: NSButton?
    private(set) var refreshButton: NSButton?
    /// The open details popover, and the page in it.
    private(set) var detailsPopover: NSPopover?
    private(set) var detailsView: SafariExtensionDetailsView?
    private var urlPrompt: ExtensionURLPromptController?
    private var observer: NSObjectProtocol?
    private var changeTask: Task<Void, Never>?

    init(
        host: SafariExtensionHost,
        destination: @escaping () -> WebBrowserPaneViewController?,
        binding: BrowserSettingsBinding
    ) {
        self.host = host
        self.destination = destination
        super.init(title: "Extensions", symbol: "puzzlepiece.extension", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Extensions",
                body: "Safari Web Browser panes run Chrome extensions from the Chrome Web Store, "
                    + "the Safari extensions installed on this Mac from the App Store, and "
                    + "extensions you downloaded, through WebKit's own extension support (macOS "
                    + "15.4 and later). "
                    + (binding.isPaneScope
                        ? "This list is the extensions of this pane's jar. "
                        : "This list is the extensions of the global jar, shared by every Safari "
                            + "pane that follows it. ")
                    + "A worktree's jar or a single pane's jar has extensions of its own. A pane "
                    + "in private browsing runs only the global jar's extensions that are allowed "
                    + "in private browsing. Each row is the extension's on checkbox, icon, name, "
                    + "version and the description its manifest gives."
            ),
            .init(
                title: "Installing",
                body: "Press + in the list's header for the Add Extension menu. Chrome Web Store… "
                    + "opens the store; on an extension's page, press Add Extension in the pane's "
                    + "address bar. Apple App Store… opens the App Store's Safari Extensions page; "
                    + "an app installed there brings its Safari extension to the end of this menu, "
                    + "and choosing it copies it here. Downloaded… installs a .crx or .zip file, or "
                    + "an unpacked extension's folder (one holding manifest.json). URL… takes a "
                    + "Chrome extension's ID, its Chrome Web Store link, or the address of a .crx "
                    + "file. A Safari extension that talks to its own app does not get to here, "
                    + "since only Safari can reach the app. Before anything is installed you are "
                    + "shown what it asks to access and can decline. "
                    + (binding.isPaneScope
                        ? "The store and an extension's options open in a new tab of this pane."
                        : "For the global jar the store and an extension's options open in a "
                            + "Safari Web Browser window of their own, brought forward when it is "
                            + "already open.")
            ),
            .init(
                title: "Managing",
                body: "Uncheck an extension to stop it without losing its settings. Its gear opens "
                    + "its details, where Options opens its settings page and Remove Extension… "
                    + "removes it with its data. Each pinned extension's button sits in the "
                    + "address bar of every Safari pane on the jar; click it for its popup, "
                    + "right-click it for its menu. Unpinned ones are in the extensions menu "
                    + "beside them."
            ),
            .init(
                title: "Details",
                body: "Click an extension's gear, or double-click its row, for its details, shown "
                    + "beside the list; click outside them to close them. They say where it came "
                    + "from. Site access chooses where it may read and change pages: on "
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
                body: "Extensions from the Chrome Web Store are checked against the store each "
                    + "time the app opens, and ↻ in the list's header reloads the list and checks "
                    + "at once. A Safari extension is updated by the App Store with its app; it is "
                    + "copied here again when the app's version changes, at the same times. When "
                    + "its app is deleted it is switched off, and its details say so, until the "
                    + "app is back. A downloaded extension is updated by installing it again. An "
                    + "update that asks for more access is shown for you to accept before it is "
                    + "installed."
            )
        ])
    }

    static let keywords: [String] = [
        "extensions", "safari extensions", "web extensions", "plugins", "add-ons",
        "add extension", "chrome web store", "web store", "extension updates", "remove extension",
        "app store", "mac app store", "safari web extensions", "downloaded extension", "crx",
        "unpacked extension", "extension url"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override var hostsOwnScroll: Bool { true }

    override func loadView() {
        let container = NSView()
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        let table = makeTable()
        self.table = table
        let tableArea = ComposableSettings.TableFillingView(card: table)
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
        closeDetails()
    }

    // MARK: - Table

    private func makeTable() -> ComposableSettings.EditableTableCard {
        let table = ComposableSettings.EditableTableCard(
            title: "Installed Extensions",
            columns: [
                .init(id: "on", title: "", width: 22, kind: .toggle, headerToolTip: "On"),
                .init(id: "icon", title: "", width: 24, kind: .image),
                .init(id: "name", title: "Name", width: 160),
                .init(id: "version", title: "Version", width: 60),
                .init(id: "description", title: "Description", width: 200),
                .init(id: "gear", title: "", width: 28, kind: .button(symbol: "gearshape", label: "Details"))
            ],
            emptyMessage: Self.emptyMessage,
            visibleRows: 8,
            accessibilityPrefix: Self.identifier
        )
        // No bar under the table: adding and refreshing live in its header,
        // everything else in an extension's details.
        table.showsAddRemove = false
        // The header carries + and ↻, so it stays when the list is empty.
        table.hidesHeaderWhenEmpty = false
        table.onToggle = { [weak self] rowID, _, isOn in self?.setEnabled(rowID, isOn: isOn) }
        table.onDoubleClick = { [weak self] rowID in self?.showDetails(rowID) }
        table.onButton = { [weak self] rowID, _ in self?.showDetails(rowID) }
        configureColumns(of: table.tableView)
        addHeaderButtons(to: table.tableView)
        updateButtons()
        return table
    }

    /// Description is the one column that takes up a change of width; the
    /// others keep theirs (Name and Version are fitted to their contents).
    private func configureColumns(of tableView: NSTableView) {
        tableView.allowsColumnReordering = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        for column in tableView.tableColumns {
            if column.identifier.rawValue == "description" {
                column.resizingMask = .autoresizingMask
                column.minWidth = 40
                column.maxWidth = .greatestFiniteMagnitude
            } else {
                column.resizingMask = []
                column.minWidth = column.width
                column.maxWidth = column.width
            }
        }
    }

    /// + and ↻, right-aligned in the header row, over the trailing end of
    /// the Description header and the gear column's empty one.
    private func addHeaderButtons(to tableView: NSTableView) {
        guard let header = tableView.headerView else { return }
        let add = headerButton(
            symbol: "plus", toolTip: "Add Extension", identifier: "\(Self.identifier).add",
            action: #selector(addClicked(_:)))
        let refresh = headerButton(
            symbol: "arrow.triangle.2.circlepath", toolTip: "Refresh and Check for Updates",
            identifier: "\(Self.identifier).refresh", action: #selector(refreshClicked(_:)))
        let stack = NSStackView(views: [add, refresh])
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
        addButton = add
        refreshButton = refresh
    }

    private func headerButton(symbol: String, toolTip: String, identifier: String, action: Selector) -> NSButton {
        let button = NSButton(
            image: NSImage(systemSymbolName: symbol, accessibilityDescription: toolTip) ?? NSImage(),
            target: self, action: action)
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.toolTip = toolTip
        button.setAccessibilityLabel(toolTip)
        button.setAccessibilityIdentifier(identifier)
        return button
    }

    @objc private func addClicked(_ sender: NSButton) { showAddMenu() }

    @objc private func refreshClicked(_ sender: NSButton) { refresh() }

    func updateButtons() {
        refreshButton?.isEnabled = changeTask == nil
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
                "on": .toggle(item.isEnabled),
                "icon": .image(item.iconPNG),
                "name": .text(item.name),
                "version": .text(item.version),
                "description": .text(item.summary)
            ])
        })
        fitNameAndVersion()
        updateButtons()
    }

    /// Name and Version as wide as their widest cell, header included, plus
    /// `fitMargin`; the table then hands what is left to Description.
    func fitNameAndVersion() {
        guard let tableView = table?.tableView else { return }
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        for (id, values) in [("name", extensions.map(\.name)), ("version", extensions.map(\.version))] {
            guard let column = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id)) else {
                continue
            }
            let widest = values.reduce(column.headerCell.cellSize.width) { widest, value in
                let cell = NSTextFieldCell(textCell: value)
                cell.font = font
                return max(widest, cell.cellSize.width)
            }
            let width = ceil(widest + Self.fitMargin)
            column.minWidth = 0
            column.maxWidth = .greatestFiniteMagnitude
            column.width = width
            column.minWidth = width
            column.maxWidth = width
        }
        tableView.sizeToFit()
    }

    /// ↻: the list again, then every extension against its source.
    func refresh() {
        reload()
        checkForUpdates()
    }

    // MARK: - Details

    /// Shows `id`'s details in a popover pointing at its row's gear.
    func showDetails(_ id: String) {
        guard let tableView = table?.tableView,
              let row = table?.rows.firstIndex(where: { $0.id == id }) else { return }
        closeDetails()
        let details = SafariExtensionDetailsView(
            extensionID: id, host: host, accessibilityPrefix: Self.identifier)
        details.onOpen = { [weak self] url in self?.open(url) }
        details.onRemove = { [weak self] id in self?.remove(id) }
        details.onError = { [weak self] error in self?.report(error) }
        guard details.reload() else { return }
        let content = NSViewController()
        content.view = details
        content.preferredContentSize = Self.detailsSize
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = content
        popover.contentSize = Self.detailsSize
        popover.delegate = self
        let gear = tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("gear"))
        guard gear >= 0, tableView.window != nil else { return }
        detailsView = details
        detailsPopover = popover
        popover.show(relativeTo: tableView.frameOfCell(atColumn: gear, row: row), of: tableView, preferredEdge: .maxY)
    }

    /// Closes the details popover, if one is open.
    func closeDetails() {
        let popover = detailsPopover
        detailsPopover = nil
        detailsView = nil
        popover?.close()
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

    // MARK: - Changes

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

    // MARK: - Add Extension

    /// +'s menu: the two stores, a downloaded extension, one by address,
    /// then the Safari extensions installed on this Mac not added yet.
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
        let menu = NSMenu(title: "Add Extension")
        menu.autoenablesItems = false
        menu.addItem(menuItem("Chrome Web Store…", #selector(openWebStore(_:))))
        menu.addItem(menuItem("Apple App Store…", #selector(openAppStore(_:))))
        menu.addItem(menuItem("Downloaded…", #selector(chooseDownloaded(_:))))
        menu.addItem(menuItem("URL…", #selector(promptForURLFromMenu(_:))))
        appExtensions = available
        if !available.isEmpty { menu.addItem(.separator()) }
        for source in available {
            let item = menuItem("\(source.name) (\(source.appName))", #selector(addAppExtension(_:)))
            item.representedObject = source.bundleID
            item.image = NSWorkspace.shared.icon(forFile: (SafariAppExtension.appURL(containing: source.appexURL)
                ?? source.appexURL).path)
            item.image?.size = NSSize(width: 16, height: 16)
            menu.addItem(item)
        }
        return menu
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    /// What the last Add Extension menu offered, read back by its items.
    private var appExtensions: [SafariAppExtension] = []

    @objc private func addAppExtension(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let source = appExtensions.first(where: { $0.bundleID == id }),
              let window = view.window else { return }
        run { host in _ = try await host.installAppExtension(source, presentingOn: window) }
    }

    @objc private func openWebStore(_ sender: NSMenuItem) { open(WebStoreExtension.storeURL) }

    /// The App Store app, on its Safari Extensions page. An extension
    /// installed there is offered by + once its app is installed.
    @objc private func openAppStore(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(SafariAppExtension.storeURL)
    }

    /// Downloaded…: a `.crx`, a `.zip`, or an unpacked extension's folder.
    @objc private func chooseDownloaded(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.prompt = "Install"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = Self.downloadedTypes
        let window = view.window
        let chosen: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            // The confirm sheet needs the open panel's sheet gone first.
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    // With no window to put a sheet on, the confirmation is
                    // app-modal rather than a silent decline.
                    self.run { host in
                        _ = try await host.installDownloaded(
                            at: url, presentingOn: window, appModalWithoutWindow: window == nil)
                    }
                }
            }
        }
        if let window {
            panel.beginSheetModal(for: window, completionHandler: chosen)
        } else {
            panel.begin(completionHandler: chosen)
        }
    }

    @objc private func promptForURLFromMenu(_ sender: NSMenuItem) { promptForURL() }

    /// URL…: an extension ID, a store link or a `.crx` address, then
    /// installs what it names.
    func promptForURL() {
        let window = view.window
        let prompt = ExtensionURLPromptController(accessibilityPrefix: Self.identifier)
        urlPrompt = prompt
        prompt.begin(on: window) { [weak self] text in
            guard let self else { return }
            self.urlPrompt = nil
            guard let text else { return }
            // The confirm sheet needs the prompt's sheet gone first.
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.run { host in
                        if WebStoreExtension.id(from: text) != nil {
                            _ = try await host.install(text, presentingOn: window)
                        } else if let url = URL(string: text) {
                            _ = try await host.install(fromAddress: url, presentingOn: window)
                        }
                    }
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
        guard let window = view.window else {
            NSAlert(error: error).runModal()
            return
        }
        NSAlert(error: error).beginSheetModal(for: window) { _ in }
    }
}

@available(macOS 15.4, *)
extension SafariExtensionsTopicPanel: NSPopoverDelegate {
    /// Clicked away (transient) or closed: the popover is gone.
    func popoverDidClose(_ notification: Notification) {
        guard (notification.object as? NSPopover) === detailsPopover else { return }
        detailsPopover = nil
        detailsView = nil
    }
}
