import AppKit
import AgenticDeveloperHubSDKCore

/// Told which file the changed-files list has selected, or nil when nothing is.
@MainActor public protocol GitFileListDelegate: AnyObject {
    func fileList(_ list: GitFileListViewController, didSelect item: GitFileListItem?)
}

/// The git window's changed-files list (recipe `workspace/git/git-views`, "Changed-files
/// list"): one row per `GitFileListItem` with its status letter, file-type icon and
/// title. The commit detail and both working-copy lists are each one of these.
///
/// The owner sets `files`; the list keeps a selected path that is still listed and tells
/// the delegate nil when it is gone. A right-click shows `menuProvider`'s menu for the
/// clicked row and a double-click calls `onDoubleClick` with it. Used on the main thread.
@MainActor
public final class GitFileListViewController: NSViewController {

    public weak var delegate: GitFileListDelegate?

    /// The list's context (`commit`, `staged`, `unstaged`), which names its identifiers.
    public let context: String

    /// The rows, in order. Setting them keeps a selected path that is still listed,
    /// without a delegate call unless its item changed (a new status), when the delegate
    /// is told the new item; a selected path that is gone is deselected and the
    /// delegate is told nil.
    public var files: [GitFileListItem] = [] {
        didSet { filesDidChange(from: oldValue) }
    }

    /// The context menu for a right-clicked row's item; nil, or a nil menu, shows none.
    public var menuProvider: ((GitFileListItem) -> NSMenu?)?

    /// Called with a double-clicked row's item.
    public var onDoubleClick: ((GitFileListItem) -> Void)?

    /// Whether a path is stored in Git LFS, which badges its row; nil badges none. Setting
    /// it redraws the rows in place: the selection stays, and the delegate hears nothing.
    public var isLFSTracked: ((String) -> Bool)? {
        didSet { redrawRows() }
    }

    /// Redraws every row's cell without a `reloadData`, which drops the selection (and
    /// so reported nil) when it runs before `files` is set to the new list.
    private func redrawRows() {
        guard isViewLoaded, tableView.numberOfRows > 0 else { return }
        isApplyingSelection = true
        tableView.reloadData(forRowIndexes: IndexSet(integersIn: 0..<tableView.numberOfRows),
                             columnIndexes: IndexSet(integersIn: 0..<tableView.numberOfColumns))
        isApplyingSelection = false
    }

    let tableView = ThemedTableView()
    /// The table's menu, refilled from `menuProvider` each time it opens.
    private let rowMenu = NSMenu()
    private let scrollView = ThemedScrollView()
    private static let column = NSUserInterfaceItemIdentifier("file")
    /// The item the delegate was last told about, so it hears each change once.
    private var reportedItem: GitFileListItem?
    /// Set while the list changes the selection itself, which reports on its own terms.
    private var isApplyingSelection = false

    public init(identifier: String) {
        self.context = identifier
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.fileList.\(context)")

        let column = NSTableColumn(identifier: Self.column)
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.rowHeight = 22
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.fileList.\(context).table")
        tableView.target = self
        tableView.doubleAction = #selector(tableDoubleClicked(_:))
        rowMenu.delegate = self
        tableView.menu = rowMenu

        scrollView.documentView = tableView
        scrollView.accessibilityID("git.fileList.\(context).scroll")
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
        tableView.reloadData()
    }

    /// Deselects without telling the delegate; the next selection, even of the same
    /// file, is reported.
    public func clearSelection() {
        reportedItem = nil
        guard isViewLoaded else { return }
        isApplyingSelection = true
        tableView.deselectAll(nil)
        isApplyingSelection = false
    }

    /// `menuProvider`'s menu for `row`'s item, or nil for a row outside the list.
    func contextMenu(forRow row: Int) -> NSMenu? {
        guard files.indices.contains(row) else { return nil }
        return menuProvider?(files[row])
    }

    /// Calls `onDoubleClick` with `row`'s item; nothing for a row outside the list.
    func doubleClick(row: Int) {
        guard files.indices.contains(row) else { return }
        onDoubleClick?(files[row])
    }

    @objc private func tableDoubleClicked(_ sender: Any?) {
        doubleClick(row: tableView.clickedRow)
    }

    private var selectedItem: GitFileListItem? {
        guard isViewLoaded else { return nil }
        let row = tableView.selectedRow
        return files.indices.contains(row) ? files[row] : nil
    }

    private func filesDidChange(from oldFiles: [GitFileListItem]) {
        guard isViewLoaded else { return }
        let row = tableView.selectedRow
        let selectedPath = oldFiles.indices.contains(row) ? oldFiles[row].path : nil
        isApplyingSelection = true
        tableView.reloadData()
        let survivor = selectedPath.flatMap { path in files.firstIndex { $0.path == path } }
        if let survivor {
            tableView.selectRowIndexes(IndexSet(integer: survivor), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
        isApplyingSelection = false
        report(survivor.map { files[$0] })
    }

    /// Tells the delegate about `item` unless it is what the delegate last heard.
    private func report(_ item: GitFileListItem?) {
        guard item != reportedItem else { return }
        reportedItem = item
        delegate?.fileList(self, didSelect: item)
    }
}

extension GitFileListViewController: NSMenuDelegate {
    /// Moves the clicked row's menu items into the table's menu as it opens; with no menu
    /// for the click it opens empty, which AppKit does not show.
    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.replaceItems(withItemsOf: contextMenu(forRow: tableView.clickedRow))
    }
}

extension GitFileListViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { files.count }
}

extension GitFileListViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard files.indices.contains(row) else { return nil }
        let cell = tableView.makeView(withIdentifier: GitFileListCellView.identifier, owner: self)
            as? GitFileListCellView ?? GitFileListCellView()
        cell.configure(files[row])
        cell.lfsBadge.isHidden = !(isLFSTracked?(files[row].path) ?? false)
        return cell
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = GitFileListRowView(frame: .zero)
        rowView.accessibilityID("git.fileList.row")
        return rowView
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isApplyingSelection else { return }
        report(selectedItem)
    }
}

/// The changed-files list's row: the themed row view, so selection follows the palette.
@MainActor
final class GitFileListRowView: ThemedTableRowView {}

/// A changed-files row: the status letter in the status's colour, the file type's icon
/// and the title, truncated in the middle with the whole title as its tooltip.
@MainActor
final class GitFileListCellView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier("git.fileList.file")

    /// Coloured by status rather than by a theme role, so not a `ThemedLabel` (which
    /// would repaint it in its role's colour); the theme sets only its font.
    let statusLabel = NSTextField(labelWithString: "")
    let iconView = ThemedSymbolImageView(symbolName: "doc", role: .secondaryText)
    let titleLabel = ThemedLabel(role: .primaryText, textRole: .body)
    /// Shown for a path stored in Git LFS.
    let lfsBadge = ThemedSymbolImageView(symbolName: "externaldrive", role: .secondaryText)
    let stack = NSStackView()

    /// The SF Symbol for `path`'s extension, `doc` when there is none to name.
    static func iconName(for path: String) -> String {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        return FileTypeIcons.builtInIcon(for: fileExtension) ?? "doc"
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        accessibilityID("git.fileList.file")
        statusLabel.accessibilityID("git.fileList.status")
        statusLabel.alignment = .center
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.observeTheme { label, palette in label.font = palette.font(.code) }
        iconView.accessibilityID("git.fileList.icon")
        titleLabel.accessibilityID("git.fileList.title")
        // One line, even for a path holding a newline.
        titleLabel.usesSingleLineMode = true
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        lfsBadge.accessibilityID("git.workingCopy.lfsBadge")
        lfsBadge.toolTip = "Stored in Git LFS"
        lfsBadge.setAccessibilityLabel("Stored in Git LFS")
        // ThemedSymbolImageView starts out hidden from accessibility; the badge is information.
        lfsBadge.setAccessibilityElement(true)
        lfsBadge.setAccessibilityRole(.image)
        lfsBadge.isHidden = true
        for view in [statusLabel, iconView, titleLabel, lfsBadge] { stack.addArrangedSubview(view) }
        stack.accessibilityID("git.fileList.fileStack")
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(_ item: GitFileListItem) {
        statusLabel.stringValue = item.status.displayCharacter
        statusLabel.textColor = item.status.nsColor
        statusLabel.setAccessibilityLabel(item.status.displayName)
        iconView.symbolName = Self.iconName(for: item.path)
        titleLabel.stringValue = item.title
        titleLabel.toolTip = item.title
    }
}
