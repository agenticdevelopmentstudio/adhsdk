import AppKit

/// The Desktop's list mode: Name, Version and Kind columns. Apps arrive sorted by name.
final class DesktopIconListView: NSScrollView, NSTableViewDataSource, NSTableViewDelegate {
    var onOpen: ((String) -> Void)?

    let tableView = ReturnOpeningTableView()
    private var apps: [DesktopApp] = []

    private enum Column {
        static let name = NSUserInterfaceItemIdentifier("name")
        static let version = NSUserInterfaceItemIdentifier("version")
        static let kind = NSUserInterfaceItemIdentifier("kind")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let columns: [(NSUserInterfaceItemIdentifier, String, CGFloat)] = [
            (Column.name, "Name", 240), (Column.version, "Version", 90), (Column.kind, "Kind", 140)
        ]
        for (identifier, title, width) in columns {
            let column = NSTableColumn(identifier: identifier)
            column.title = title
            column.width = width
            tableView.addTableColumn(column)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 22
        tableView.allowsMultipleSelection = false
        tableView.target = self
        tableView.doubleAction = #selector(openClickedRow)
        tableView.onReturn = { [weak self] in self?.openSelected() }
        documentView = tableView
        hasVerticalScroller = true
        drawsBackground = true
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var selectedIdentifier: String? {
        let row = tableView.selectedRow
        return apps.indices.contains(row) ? apps[row].descriptor.identifier : nil
    }

    func configure(apps newApps: [DesktopApp]) {
        let kept = selectedIdentifier
        apps = newApps
        tableView.reloadData()
        if let kept, let row = apps.firstIndex(where: { $0.descriptor.identifier == kept }) {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    private func openSelected() {
        if let selectedIdentifier { onOpen?(selectedIdentifier) }
    }

    @objc private func openClickedRow() {
        let row = tableView.clickedRow
        if apps.indices.contains(row) { onOpen?(apps[row].descriptor.identifier) }
    }

    // MARK: NSTableViewDataSource / Delegate

    func numberOfRows(in tableView: NSTableView) -> Int { apps.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, apps.indices.contains(row) else { return nil }
        let app = apps[row]
        let cell = NSTableCellView()
        let text = NSTextField(labelWithString: "")
        text.lineBreakMode = .byTruncatingTail
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(text)
        cell.textField = text
        var leading = text.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4)
        switch tableColumn.identifier {
        case Column.name:
            let icon = NSImageView(image: DesktopAppIconRenderer.image(for: app, pointSize: 16))
            icon.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(icon)
            cell.imageView = icon
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 16),
                icon.heightAnchor.constraint(equalToConstant: 16)
            ])
            leading = text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6)
            text.stringValue = app.descriptor.displayName
        case Column.version:
            text.stringValue = app.descriptor.version
        default:
            text.stringValue = "Application"
        }
        NSLayoutConstraint.activate([
            leading,
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}

/// A table that opens its selection on Return.
final class ReturnOpeningTableView: NSTableView {
    var onReturn: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            onReturn?()
        } else {
            super.keyDown(with: event)
        }
    }
}
