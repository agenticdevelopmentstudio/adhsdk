import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The git window's command log (recipe `workspace/git/git-views`, "Command log"): every
/// `git` and `gh` call the app made in this window's repository or one of its worktrees,
/// oldest at the top, from `GitCommandLog`'s ring, in a table of Time, Command,
/// Directory, Duration and Status.
///
/// It follows new entries: an entry that arrives while the list is scrolled to the bottom
/// keeps it at the bottom, and one that arrives while the user has scrolled up leaves
/// the list where it is. A row's menu copies the command; a failed row's tooltip is its
/// standard error. Used on the main thread.
@MainActor
public final class GitCommandLogViewController: NSViewController {

    let scrollView = ThemedScrollView()
    let tableView = ThemedTableView()

    /// The entries shown, oldest first: the book's entries in one of `roots`.
    private(set) var shown: [GitCommandLogEntry] = []
    /// The task reading the book's updates; nil once stopped.
    private(set) var updatesTask: Task<Void, Never>?
    /// Where Copy Command writes; tests give their own.
    var pasteboard: NSPasteboard = .general

    private let book: GitCommandLogBook
    private let roots: @MainActor () -> [URL]
    /// The newest entry id taken in, so an entry read by `reload` and then yielded
    /// by the stream is shown once.
    private var lastID: UInt64 = 0

    enum Column: String, CaseIterable {
        case time, command, directory, duration, status

        var identifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier("git.commandLog.\(rawValue)") }

        var title: String {
            switch self {
            case .time: "Time"
            case .command: "Command"
            case .directory: "Directory"
            case .duration: "Duration"
            case .status: "Status"
            }
        }

        var width: CGFloat {
            switch self {
            case .time: 70
            case .command: 360
            case .directory: 120
            case .duration: 70
            case .status: 70
            }
        }
    }

    /// - Parameters:
    ///   - book: the ring to show; the process's own by default.
    ///   - roots: the repository's root and its worktrees, asked on every reload and
    ///     every new entry, so worktrees added later are counted.
    public init(book: GitCommandLogBook = GitCommandLog.book, roots: @escaping @MainActor () -> [URL]) {
        self.book = book
        self.roots = roots
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.commandLog")

        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.width = column.width
            tableColumn.minWidth = 40
            tableColumn.resizingMask = column == .command ? [.autoresizingMask, .userResizingMask] : .userResizingMask
            tableView.addTableColumn(tableColumn)
        }
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.rowHeight = 20
        tableView.allowsMultipleSelection = false
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.commandLog.table")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Copy Command", action: #selector(copyCommand(_:)), keyEquivalent: "")
            .accessibilityID("git.commandLog.menu.copy"))
        menu.items.forEach { $0.target = self }
        tableView.menu = menu

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.accessibilityID("git.commandLog.scroll")
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
        startFollowing()
    }

    /// Lists the book's entries in `roots` again, scrolled to the newest.
    public func reload() {
        loadViewIfNeeded()
        let all = book.entries()
        lastID = all.last?.id ?? lastID
        shown = all.filter(isInRoots)
        tableView.reloadData()
        scrollToBottom()
    }

    /// Stops following the book. The list stays as it is.
    public func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    private func startFollowing() {
        // Subscribed before reading, so nothing recorded between the two is lost;
        // `lastID` drops what both see.
        let updates = book.updates()
        reload()
        updatesTask = Task { [weak self] in
            for await entry in updates {
                guard let self else { return }
                self.take(entry)
            }
        }
    }

    private func take(_ entry: GitCommandLogEntry) {
        guard entry.id > lastID else { return }
        lastID = entry.id
        guard isInRoots(entry) else { return }
        let following = isAtBottom
        shown.append(entry)
        if shown.count > book.capacity {
            shown.removeFirst(shown.count - book.capacity)
            tableView.reloadData()
        } else {
            tableView.insertRows(at: IndexSet(integer: shown.count - 1), withAnimation: [])
        }
        if following { scrollToBottom() }
    }

    /// True when the last row is in view, or there is nothing to scroll.
    var isAtBottom: Bool {
        let visible = scrollView.contentView.bounds
        return visible.maxY >= tableView.bounds.height - 1
    }

    private func scrollToBottom() {
        guard !shown.isEmpty else { return }
        tableView.scrollRowToVisible(shown.count - 1)
    }

    /// True when the entry ran in a root or below one.
    private func isInRoots(_ entry: GitCommandLogEntry) -> Bool {
        guard !entry.directory.isEmpty else { return false }
        let directory = URL(fileURLWithPath: entry.directory).standardizedFileURL.path
        return rootPaths().contains { root in directory == root || directory.hasPrefix(root + "/") }
    }

    private func rootPaths() -> Set<String> {
        Set(roots().flatMap { url in
            [url.standardizedFileURL.path, url.resolvingSymlinksInPath().standardizedFileURL.path]
        })
    }

    // MARK: - Copy

    @objc func copyCommand(_ sender: Any?) {
        let row = tableView.clickedRow >= 0 ? tableView.clickedRow : tableView.selectedRow
        copyCommand(row: row)
    }

    /// Puts row `row`'s command line on the pasteboard; a row out of range copies nothing.
    func copyCommand(row: Int) {
        guard shown.indices.contains(row) else { return }
        pasteboard.clearContents()
        pasteboard.setString(shown[row].commandLine, forType: .string)
    }

    // MARK: - Cells

    /// The tooltip for row `row`: a failed entry's standard error, else nil.
    func toolTip(forRow row: Int) -> String? {
        guard shown.indices.contains(row) else { return nil }
        return shown[row].standardError
    }

    static func text(of entry: GitCommandLogEntry, in column: Column) -> String {
        switch column {
        case .time:
            return entry.date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())
        case .command:
            return entry.commandLine
        case .directory:
            return entry.directory.isEmpty ? "" : URL(fileURLWithPath: entry.directory).lastPathComponent
        case .duration:
            let milliseconds = entry.duration.components.seconds * 1000
                + entry.duration.components.attoseconds / 1_000_000_000_000_000
            return "\(milliseconds) ms"
        case .status:
            return entry.exitStatus.map(String.init) ?? "–"
        }
    }

    /// The status column's symbol and its colour: passed, failed, or never finished.
    static func statusSymbol(of entry: GitCommandLogEntry) -> (name: String, role: ThemeRole) {
        switch entry.exitStatus {
        case 0: ("checkmark.circle", .success)
        case nil: ("clock.badge.exclamationmark", .warning)
        default: ("xmark.octagon", .danger)
        }
    }
}

extension GitCommandLogViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { shown.count }
}

extension GitCommandLogViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard shown.indices.contains(row), let tableColumn,
              let column = Column.allCases.first(where: { $0.identifier == tableColumn.identifier }) else { return nil }
        let cell: GitCommandLogCellView
        if let reused = tableView.makeView(withIdentifier: column.identifier, owner: self) as? GitCommandLogCellView {
            cell = reused
        } else {
            cell = GitCommandLogCellView(showsSymbol: column == .status)
            cell.identifier = column.identifier
            cell.accessibilityID("git.commandLog.cell.\(column.rawValue)")
        }
        let entry = shown[row]
        let symbol = column == .status ? Self.statusSymbol(of: entry) : nil
        cell.configure(text: Self.text(of: entry, in: column), symbol: symbol, toolTip: entry.standardError)
        return cell
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.accessibilityID("git.commandLog.row")
        rowView.toolTip = toolTip(forRow: row)
        return rowView
    }
}

/// One cell of the command log: a single line of text, with a leading symbol in the
/// Status column.
final class GitCommandLogCellView: NSView {

    let label = ThemedLabel(role: .primaryText, textRole: .caption)
    let symbolView: ThemedSymbolImageView?

    init(showsSymbol: Bool) {
        symbolView = showsSymbol ? ThemedSymbolImageView(symbolName: nil, pointSize: 11) : nil
        super.init(frame: .zero)
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.accessibilityID("git.commandLog.text")
        symbolView?.accessibilityID("git.commandLog.symbol")
        let stack = NSStackView(views: [symbolView, label].compactMap { $0 })
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(text: String, symbol: (name: String, role: ThemeRole)?, toolTip: String?) {
        label.stringValue = text
        label.toolTip = toolTip
        self.toolTip = toolTip
        if let symbolView, let symbol {
            symbolView.symbolName = symbol.name
            symbolView.role = symbol.role
        }
    }
}
