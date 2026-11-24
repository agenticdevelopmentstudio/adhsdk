//
//  BrowserHiddenItemsPopover.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import OSLog

/// The popover the address bar's "Hide distracting items" button opens
/// (recipe `workspace/browser/element-picker`): for the page's site, the
/// user list's switch, the button that starts selecting mode, a divider,
/// and the list's entries, each a checkbox that enables or disables it,
/// under a header whose − removes the selected one. Every change goes to the
/// store at once; the store's notification re-renders the page and reloads
/// this list. The list is a parameter, so the agent list reuses it; the
/// switch is the user list's alone.
@MainActor
final class BrowserHiddenItemsPopover: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
    NSPopoverDelegate {

    static let siteSwitchTitle = "Hide distracting items"
    static let removeToolTip = "Remove Selected Item"

    static func selectTitle(for list: BrowserHiddenItemList) -> String {
        list == .agent ? "Select items to hide from the agent" : "Select distracting items to hide"
    }

    let list: BrowserHiddenItemList
    private let store: BrowserHiddenItemsStore
    private let url: URL?
    private let onSelect: () -> Void
    /// The site pattern the switch and new entries use for this page.
    let site: String

    let popover = NSPopover()
    let siteCheckbox = NSButton(
        checkboxWithTitle: BrowserHiddenItemsPopover.siteSwitchTitle, target: nil, action: nil)
    let selectButton = NSButton(title: "", target: nil, action: nil)
    let removeButton = NSButton(title: "", target: nil, action: nil)
    let tableView = NSTableView()
    /// The entries shown, oldest first.
    private(set) var items: [BrowserHiddenItem] = []
    private var changeObserver: NSObjectProtocol?
    private var loadGeneration = 0
    /// The button the popover opened from, for the toggle.
    weak var anchor: NSView?
    /// The event number of the press on `anchor` that closed the popover:
    /// the click it begins (its mouse-up carries the same number) closes it
    /// rather than opening it again, and no later click does.
    private(set) var closingPressNumber: Int?
    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    init(list: BrowserHiddenItemList, store: BrowserHiddenItemsStore, url: URL?,
         onSelect: @escaping () -> Void) {
        self.list = list
        self.store = store
        self.url = url
        self.onSelect = onSelect
        site = PrivacySitePattern.defaultPattern(for: url)
        super.init(nibName: nil, bundle: nil)
        popover.behavior = .transient
        popover.contentViewController = self
        popover.delegate = self
        changeObserver = NotificationCenter.default.addObserver(
            forName: BrowserHiddenItemsStore.didChangeNotification, object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    isolated deinit {
        if let changeObserver { NotificationCenter.default.removeObserver(changeObserver) }
    }

    /// Opens the popover under `button`.
    func show(relativeTo button: NSView) {
        _ = view
        anchor = button
        closingPressNumber = nil
        reload()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

    // MARK: - Toggle

    /// A click on the button the popover opened from: whether it is the
    /// toggle that closes the popover, so the caller does not open it again.
    /// True while the popover shows (it is closed now), and when the click's
    /// own press is what just closed it: a transient popover closes on the
    /// mouse-down, before the button's action runs on the mouse-up. The
    /// press is matched by event number, so a press released off the button
    /// (no action) leaves nothing that swallows a later click.
    func closesOnAnchorClick(_ event: NSEvent?) -> Bool {
        if popover.isShown {
            popover.performClose(nil)
            return true
        }
        guard let pressNumber = closingPressNumber else { return false }
        closingPressNumber = nil
        guard let event, Self.isMouseEvent(event) else { return false }
        return event.eventNumber == pressNumber
    }

    func popoverWillClose(_ notification: Notification) {
        noteClosing(by: NSApp.currentEvent)
    }

    /// Records whether `event`, the event closing the popover, is a press on
    /// `anchor`.
    func noteClosing(by event: NSEvent?) {
        closingPressNumber = nil
        guard let event, event.type == .leftMouseDown,
              let anchor, let window = anchor.window, event.window === window,
              anchor.bounds.contains(anchor.convert(event.locationInWindow, from: nil)) else { return }
        closingPressNumber = event.eventNumber
    }

    private static func isMouseEvent(_ event: NSEvent) -> Bool {
        event.type == .leftMouseUp || event.type == .leftMouseDown
    }

    // MARK: - View

    override func loadView() {
        siteCheckbox.target = self
        siteCheckbox.action = #selector(siteSwitchToggled(_:))
        siteCheckbox.setAccessibilityIdentifier("browser.hide-items.site")
        siteCheckbox.isHidden = list != .user

        selectButton.title = Self.selectTitle(for: list)
        selectButton.toolTip = Self.selectTitle(for: list)
        selectButton.bezelStyle = .push
        selectButton.target = self
        selectButton.action = #selector(selectItems(_:))
        selectButton.setAccessibilityIdentifier("browser.hide-items.select")

        let separator = NSBox()
        separator.boxType = .separator

        removeButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: Self.removeToolTip)
        removeButton.imagePosition = .imageOnly
        removeButton.bezelStyle = .smallSquare
        removeButton.toolTip = Self.removeToolTip
        removeButton.target = self
        removeButton.action = #selector(removeSelected(_:))
        removeButton.isEnabled = false
        removeButton.setAccessibilityIdentifier("browser.hide-items.remove")
        let headerSpacer = NSView()
        headerSpacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let header = NSStackView(views: [headerSpacer, removeButton])
        header.orientation = .horizontal

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("item"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setAccessibilityIdentifier("browser.hide-items.list")
        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [siteCheckbox, selectButton, separator, header, scroll])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.detachesHiddenViews = true
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let root = NSView()
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            root.widthAnchor.constraint(equalToConstant: 320),
            separator.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24),
            scroll.heightAnchor.constraint(equalToConstant: 160)
        ])
        view = root
    }

    // MARK: - Loading

    /// Reads the site's entries and switch off the main thread; a read
    /// overtaken by a newer one is dropped.
    func reload() {
        loadGeneration += 1
        let generation = loadGeneration
        let list = list
        let url = url
        let site = site
        Task { [weak self, store] in
            do {
                let loaded = try await store.perform { store in
                    (try store.items(list: list, for: url), try store.isSiteSwitchOn(list: list, site: site))
                }
                guard let self, generation == self.loadGeneration else { return }
                self.show(items: loaded.0, siteSwitchOn: loaded.1)
            } catch {
                Self.logger.error("hidden items could not be read: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func show(items newItems: [BrowserHiddenItem], siteSwitchOn: Bool) {
        let selectedID = selectedItem?.id
        items = newItems
        siteCheckbox.state = siteSwitchOn ? .on : .off
        tableView.reloadData()
        if let selectedID, let row = items.firstIndex(where: { $0.id == selectedID }) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        updateRemoveButton()
    }

    private var selectedItem: BrowserHiddenItem? {
        let row = tableView.selectedRow
        return items.indices.contains(row) ? items[row] : nil
    }

    private func updateRemoveButton() {
        removeButton.isEnabled = selectedItem?.id != nil
    }

    // MARK: - Actions

    @objc func siteSwitchToggled(_ sender: NSButton) {
        let isOn = sender.state == .on
        let list = list
        let site = site
        write { try $0.setSiteSwitch(list: list, site: site, on: isOn) }
    }

    @objc func selectItems(_ sender: Any?) {
        popover.performClose(sender)
        onSelect()
    }

    /// The row is resolved when the click lands, not when the cell was made:
    /// a reload in between can reorder or shorten `items`.
    @objc func rowToggled(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        guard items.indices.contains(row), let id = items[row].id else { return }
        let isOn = sender.state == .on
        write { try $0.setEnabled(id, isOn) }
    }

    @objc func removeSelected(_ sender: Any?) {
        guard let id = selectedItem?.id else { return }
        write { try $0.remove(id) }
    }

    private func write(_ change: @escaping @Sendable (BrowserHiddenItemsStore) throws -> Void) {
        Task { [store] in
            do {
                try await store.perform(change)
            } catch {
                Self.logger.error("hidden items could not be changed: \(error.localizedDescription, privacy: .public)")
                await MainActor.run { NSSound.beep() }
            }
        }
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard items.indices.contains(row) else { return nil }
        let item = items[row]
        let checkbox = NSButton(checkboxWithTitle: item.label, target: self, action: #selector(rowToggled(_:)))
        checkbox.state = item.enabled ? .on : .off
        checkbox.lineBreakMode = .byTruncatingTail
        checkbox.toolTip = item.label
        checkbox.setAccessibilityLabel(item.label)
        let cell = NSTableCellView()
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            checkbox.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
            checkbox.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateRemoveButton()
    }
}
