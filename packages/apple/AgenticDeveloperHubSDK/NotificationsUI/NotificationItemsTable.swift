import AppKit
import AgenticDeveloperHubSDKNotifications

/// The item list of one style set: an `NSTableView` in an `NSScrollView`, a
/// +/− `NSSegmentedControl` under it, and a placeholder for an empty set.
///
/// Installed straight into a group's card, not into a padded row, so the
/// table runs edge to edge: the scroll view is pinned to the card's leading,
/// trailing and bottom edges and fills the height the panel leaves. The +/−
/// strip sits in a bottom inset of the scroll view, so no row is ever under it.
@MainActor
final class NotificationItemsTable: NSObject, NSTableViewDataSource, NSTableViewDelegate {

    /// Least height of the table, above the +/− strip.
    static let minimumTableHeight: CGFloat = 160
    static let footerHeight: CGFloat = 26
    static let placeholderText = "Not shown — add a notification with +"

    /// `+` was pressed.
    var onAdd: (() -> Void)?
    /// `−` was pressed with these rows selected.
    var onRemove: ((IndexSet) -> Void)?
    /// A row was double-clicked or Return was pressed on it.
    var onEdit: ((Int) -> Void)?

    let tableView = ItemsTableView()
    let scrollView = NSScrollView()
    let segmented = NSSegmentedControl()
    let placeholder = NSTextField(labelWithString: NotificationItemsTable.placeholderText)

    private(set) var items: [NoticeProfile] = []

    override init() {
        super.init()
        let column = NSTableColumn(identifier: .init("item"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        tableView.rowHeight = 28
        tableView.style = .fullWidth
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(rowDoubleClicked)
        tableView.onReturn = { [weak self] in self?.editSelected() }
        tableView.setAccessibilityLabel("Notifications")

        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: Self.footerHeight, right: 0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        segmented.segmentCount = 2
        segmented.trackingMode = .momentary
        segmented.segmentStyle = .smallSquare
        segmented.setImage(NSImage(systemSymbolName: "plus", accessibilityDescription: "Add"), forSegment: 0)
        segmented.setImage(NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove"), forSegment: 1)
        segmented.setWidth(28, forSegment: 0)
        segmented.setWidth(28, forSegment: 1)
        segmented.target = self
        segmented.action = #selector(segmentPressed)
        segmented.translatesAutoresizingMaskIntoConstraints = false

        placeholder.textColor = .secondaryLabelColor
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        updateChrome()
    }

    /// Puts the table into `card`, pinned to its leading, trailing and bottom
    /// edges (and top).
    func install(in card: NSView) {
        card.addSubview(scrollView)
        card.addSubview(placeholder)
        card.addSubview(segmented)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: card.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            scrollView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: Self.minimumTableHeight + Self.footerHeight),
            segmented.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            segmented.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -2),
            placeholder.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            placeholder.centerYAnchor.constraint(
                equalTo: scrollView.centerYAnchor, constant: -Self.footerHeight / 2)
        ])
    }

    /// Shows `items`, keeping the selection where it still means something.
    func setItems(_ items: [NoticeProfile]) {
        self.items = items
        tableView.reloadData()
        updateChrome()
    }

    private func updateChrome() {
        placeholder.isHidden = !items.isEmpty
        segmented.setEnabled(!tableView.selectedRowIndexes.isEmpty, forSegment: 1)
    }

    private func editSelected() {
        guard let row = tableView.selectedRowIndexes.first else { return }
        onEdit?(row)
    }

    @objc private func segmentPressed() {
        press(segmented.selectedSegment)
    }

    /// Runs the action of a +/− segment: 0 adds, 1 removes the selection.
    /// Its own entry point because a momentary NSSegmentedControl ignores a programmatic `selectedSegment`.
    func press(_ segment: Int) {
        switch segment {
        case 0: onAdd?()
        case 1:
            let rows = tableView.selectedRowIndexes
            if !rows.isEmpty { onRemove?(rows) }
        default: break
        }
    }

    @objc private func rowDoubleClicked() {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : (tableView.selectedRowIndexes.first ?? -1)
        if row >= 0 { onEdit?(row) }
    }

    // MARK: Data source and delegate

    func numberOfRows(in tableView: NSTableView) -> Int { items.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard items.indices.contains(row) else { return nil }
        let item = items[row]
        let cell = NSTableCellView()
        let icon = NSImageView(image: NSImage(
            systemSymbolName: NotificationStylesSettingsPanel.symbol(for: item.style),
            accessibilityDescription: nil) ?? NSImage())
        icon.contentTintColor = .secondaryLabelColor
        let text = NSTextField(labelWithString: NotificationStylesSettingsPanel.describe(item))
        text.lineBreakMode = .byTruncatingTail
        for view in [icon, text] {
            view.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(view)
        }
        cell.imageView = icon
        cell.textField = text
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -14),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateChrome()
    }
}

/// An `NSTableView` that reports Return, which edits the selected item.
@MainActor
final class ItemsTableView: NSTableView {
    var onReturn: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            onReturn?()
        } else {
            super.keyDown(with: event)
        }
    }
}
