import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// What the reflog browser reports: the selected entry, for the bottom detail, and what
/// the user asked a row's menu to do. The view runs neither.
@MainActor public protocol GitReflogDelegate: AnyObject {
    func reflog(_ reflog: GitReflogViewController, didSelect entry: GitReflogEntry?)
    func reflog(_ reflog: GitReflogViewController, didRequest intent: GitReflogIntent)
}

/// The Git window's reflog browser (recipe `workspace/git/git-views`, "Reflog"): HEAD's
/// reflog, newest first, in a table of Selector, Action, Message, Commit (short sha) and
/// Commit Date. Selecting a row reports its entry; a row's menu resets HEAD to it (Soft, Mixed or
/// Hard…), checks it out detached, or creates a branch at it. Used on the main thread.
@MainActor
public final class GitReflogViewController: NSViewController {

    let scrollView = ThemedScrollView()
    let tableView = ThemedTableView()

    public weak var delegate: GitReflogDelegate?

    /// The entries shown, newest first.
    public private(set) var entries: [GitReflogEntry] = []

    private let rowMenu = NSMenu()
    /// True while `show(_:)` restores the selection, so it is not reported as the user's.
    private var isApplyingSelection = false

    enum Column: String, CaseIterable {
        case selector, action, message, commit, date

        var identifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier("git.reflog.\(rawValue)") }

        var title: String {
            switch self {
            case .selector: "Selector"
            case .action: "Action"
            case .message: "Message"
            case .commit: "Commit"
            // The commit's committer date, not the reflog entry's own time (`%ct`).
            case .date: "Commit Date"
            }
        }

        var width: CGFloat {
            switch self {
            case .selector: 80
            case .action: 120
            case .message: 320
            case .commit: 80
            case .date: 140
            }
        }
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.reflog")

        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.width = column.width
            tableColumn.minWidth = 40
            tableColumn.resizingMask = column == .message ? [.autoresizingMask, .userResizingMask] : .userResizingMask
            tableView.addTableColumn(tableColumn)
        }
        // Only Message has `.autoresizingMask`, so it alone takes up extra width.
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.rowHeight = 20
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.reflog.table")
        rowMenu.delegate = self
        tableView.menu = rowMenu

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.accessibilityID("git.reflog.scroll")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
    }

    /// Shows `entries`, keeping the selected entry selected when it is still listed. An
    /// entry is matched on its commit, date, action and message, never its selector, which
    /// shifts from `@{n}` to `@{n+1}` with every new action. A selected entry that is gone
    /// (expired, or collected) is deselected and the delegate is told nil, so the detail
    /// does not go on showing it.
    public func show(_ entries: [GitReflogEntry]) {
        loadViewIfNeeded()
        let selected = selectedEntry
        self.entries = entries
        isApplyingSelection = true
        tableView.reloadData()
        let survivor = selected.flatMap { selected in entries.firstIndex { Self.isSameStep($0, as: selected) } }
        if let survivor {
            tableView.selectRowIndexes(IndexSet(integer: survivor), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
        isApplyingSelection = false
        if selected != nil, survivor == nil {
            delegate?.reflog(self, didSelect: nil)
        }
    }

    /// Whether `entry` records the same step as `other`, wherever each sits in its list.
    static func isSameStep(_ entry: GitReflogEntry, as other: GitReflogEntry) -> Bool {
        entry.sha == other.sha && entry.date == other.date
            && entry.action == other.action && entry.message == other.message
    }

    /// The selected row's entry; nil when nothing is selected.
    public var selectedEntry: GitReflogEntry? {
        let row = tableView.selectedRow
        return entries.indices.contains(row) ? entries[row] : nil
    }

    /// Selects row `row`, as a click does, and reports it.
    func select(row: Int) {
        guard entries.indices.contains(row) else { return }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    // MARK: - Cells

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func text(of entry: GitReflogEntry, in column: Column) -> String {
        switch column {
        case .selector: entry.selector
        case .action: entry.action
        case .message: entry.message
        case .commit: entry.shortSha
        case .date: dateFormatter.string(from: entry.date)
        }
    }
}

// MARK: - Context menu

extension GitReflogViewController: NSMenuDelegate {

    /// The menu for `row`'s entry, or nil for a row outside the list.
    func contextMenu(forRow row: Int) -> NSMenu? {
        guard entries.indices.contains(row) else { return nil }
        let entry = entries[row]
        let menu = NSMenu()
        let reset = NSMenuItem(title: "Reset HEAD to Here", action: nil, keyEquivalent: "")
        reset.accessibilityID("git.reflog.menu.reset")
        let modes = NSMenu()
        modes.addItem(intentItem("Soft", "resetSoft", .reset(entry, .soft)))
        modes.addItem(intentItem("Mixed", "resetMixed", .reset(entry, .mixed)))
        modes.addItem(intentItem("Hard…", "resetHard", .reset(entry, .hard)))
        reset.submenu = modes
        menu.addItem(reset)
        menu.addItem(intentItem("Check Out (detached)", "checkout", .checkout(entry)))
        menu.addItem(intentItem("Create Branch Here…", "createBranch", .createBranch(entry)))
        return menu
    }

    /// Moves the clicked row's items into the table's menu as it opens; a click outside
    /// the rows leaves it empty, which AppKit does not show.
    public func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === rowMenu else { return }
        menu.replaceItems(withItemsOf: contextMenu(forRow: tableView.clickedRow))
    }

    private func intentItem(_ title: String, _ name: String, _ intent: GitReflogIntent) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = MenuPayload(intent)
        item.accessibilityID("git.reflog.menu.\(name)")
        return item
    }

    @objc private func performMenuIntent(_ sender: NSMenuItem) {
        guard let intent = sender.payload(GitReflogIntent.self) else { return }
        delegate?.reflog(self, didRequest: intent)
    }
}

extension GitReflogViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { entries.count }
}

extension GitReflogViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard entries.indices.contains(row), let tableColumn,
              let column = Column.allCases.first(where: { $0.identifier == tableColumn.identifier }) else { return nil }
        let cell: GitCommandLogCellView
        if let reused = tableView.makeView(withIdentifier: column.identifier, owner: self) as? GitCommandLogCellView {
            cell = reused
        } else {
            cell = GitCommandLogCellView(showsSymbol: false)
            cell.identifier = column.identifier
            cell.accessibilityID("git.reflog.cell.\(column.rawValue)")
            cell.label.accessibilityID("git.reflog.text")
        }
        cell.configure(text: Self.text(of: entries[row], in: column), symbol: nil, toolTip: nil)
        return cell
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.accessibilityID("git.reflog.row")
        return rowView
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isApplyingSelection else { return }
        delegate?.reflog(self, didSelect: selectedEntry)
    }
}
