import AppKit
import AgenticDeveloperHubSDKCore

/// Told which commit the history list has selected, or nil when nothing is.
@MainActor public protocol GitHistoryDelegate: AnyObject {
    func history(_ history: GitHistoryViewController, didSelect commit: GitCommit?)
}

/// The git window's history list (recipe `workspace/git/git-views`, "History list"): a
/// paged table of the commit graph, the subject behind its ref badges, the author, the
/// relative date and the short sha, read from a `GitHistoryDataSource`.
///
/// The owner calls `reload()` when the model reports a history change and forwards the
/// window's search text to `setQuery(_:)`. Used on the main thread; every data-source
/// call that waits is awaited.
@MainActor
public final class GitHistoryViewController: NSViewController {

    public weak var delegate: GitHistoryDelegate?

    let tableView = ThemedTableView()
    /// The page request in flight or last finished; tests await it.
    private(set) var pagingTask: Task<Void, Never>?

    /// Rows from the end of the loaded history at which the next page is asked for.
    static let pagingWindow = 50

    private let source: GitHistoryDataSource
    private let scrollView = ThemedScrollView()
    /// The data source's lists as of the last `reload()`, so the table never reads a
    /// list that changed under it between `reloadData` calls.
    private var commits: [GitCommit] = []
    private var graphRows: [CommitGraphLayout<String>.Row] = []
    /// The refs at each snapshot commit that has any, and the data source's query, both
    /// as of the last `reload()`, so badges and paging agree with the rows on screen.
    private var refsByCommit: [String: [GitRef]] = [:]
    private var shownQuery = GitLogQuery()
    /// The query and commit count when the last page was asked for; no new request until
    /// either changes. The query is part of it so a new search whose first page happens to
    /// be the same size as the last one's still pages.
    private var lastPaged: (query: GitLogQuery, count: Int)?
    /// The commit id the delegate was last told about, so it hears each change once.
    private var reportedID: String?
    /// Set while the list changes the selection itself, which reports on its own terms.
    private var isApplyingSelection = false
    /// Bumped by every `setQuery(_:)`; a call that finds it moved was overtaken.
    private(set) var queryGeneration = 0
    /// The query this list last sent to the data source (applied or still in flight), and
    /// the task sending it. Nil until the first search sends one, when the data source's
    /// own query is the starting point. Never read back from the data source afterwards:
    /// the model takes a new query before it awaits, so its query says nothing about
    /// whether the results have arrived.
    private var sentQuery: GitLogQuery?
    private var sendTask: Task<Void, Never>?

    private enum Column: String, CaseIterable {
        case graph, subject, author, date, sha

        var title: String {
            switch self {
            case .graph: return "Graph"
            case .subject: return "Subject"
            case .author: return "Author"
            case .date: return "Date"
            case .sha: return "SHA"
            }
        }

        @MainActor var width: CGFloat {
            switch self {
            case .graph: return CommitGraphCellView.columnWidth
            case .subject: return 360
            case .author: return 160
            case .date: return 110
            case .sha: return 80
            }
        }

        var identifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier(rawValue) }
    }

    public init(source: GitHistoryDataSource) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.history")

        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.width = column.width
            if column == .graph {
                tableColumn.minWidth = CommitGraphCellView.columnWidth
                tableColumn.resizingMask = []
            }
            tableView.addTableColumn(tableColumn)
        }
        tableView.headerView = ThemedTableHeaderView()
        tableView.rowHeight = 24
        tableView.intercellSpacing = NSSize(width: 4, height: 0)
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.history.table")

        scrollView.documentView = tableView
        scrollView.accessibilityID("git.history.scroll")
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
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
        reload()
    }

    // MARK: - Reloading

    /// Re-reads the data source. A selected commit that is still loaded stays selected
    /// without a delegate call; one that is gone is deselected and the delegate is told nil.
    public func reload() {
        let selectedID = selectedCommit?.id
        commits = source.commits
        graphRows = source.graphRows
        shownQuery = source.query
        var refs: [String: [GitRef]] = [:]
        for commit in commits {
            let atCommit = source.refs(at: commit.id)
            if !atCommit.isEmpty { refs[commit.id] = atCommit }
        }
        refsByCommit = refs
        guard isViewLoaded else { return }

        let widest = graphRows.map(\.width).max() ?? 1
        tableView.tableColumns.first?.width = CGFloat(max(widest, 1)) * CommitGraphCellView.columnWidth

        isApplyingSelection = true
        tableView.reloadData()
        let survivor = selectedID.flatMap { id in commits.firstIndex { $0.id == id } }
        if let survivor {
            tableView.selectRowIndexes(IndexSet(integer: survivor), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
        isApplyingSelection = false
        if survivor == nil { report(nil) }
    }

    // MARK: - Selection

    /// Selects the loaded commit with exactly `commitID`, scrolls to it and tells the
    /// delegate. An id that is not loaded changes nothing.
    public func select(commitID: String) {
        guard let index = commits.firstIndex(where: { $0.id == commitID }) else { return }
        loadViewIfNeeded()
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
        report(commits[index])
    }

    private var selectedCommit: GitCommit? {
        guard isViewLoaded else { return nil }
        let row = tableView.selectedRow
        return commits.indices.contains(row) ? commits[row] : nil
    }

    /// Tells the delegate about `commit` unless it is what the delegate last heard.
    private func report(_ commit: GitCommit?) {
        guard commit?.id != reportedID else { return }
        reportedID = commit?.id
        delegate?.history(self, didSelect: commit)
    }

    // MARK: - Search

    /// Applies the window's search text (`GitHistorySearch.parse(_:)`). A query that
    /// differs from the one last sent is sent to the data source; a query equal to one
    /// still in flight waits for it rather than being sent again. The latest call then
    /// reloads the list and, for a `sha:` search, selects the first loaded commit with
    /// that prefix. A call overtaken by a later one does neither.
    public func setQuery(_ text: String) async {
        queryGeneration += 1
        let generation = queryGeneration
        let query = GitHistorySearch.parse(text)
        if query != (sentQuery ?? source.query) {
            sentQuery = query
            sendTask = Task { [source] in await source.setQuery(query) }
        }
        if let sendTask {
            await sendTask.value
            guard generation == queryGeneration else { return }
            self.sendTask = nil
            reload()
        }
        guard let prefix = GitHistorySearch.shaPrefix(text),
              let match = commits.first(where: { $0.id.lowercased().hasPrefix(prefix) }) else { return }
        select(commitID: match.id)
    }

    // MARK: - Paging

    /// Called as the table shows `row`: a row in the last `pagingWindow` asks the data
    /// source for the next page, once per query and commit count, so the end of the
    /// history does not loop. Both come from the snapshot, so a model that cleared its
    /// commits for a search in flight does not page. The model also announces the new
    /// page, which the owner answers with `reload()`; the reload here is the one that
    /// counts, so the list does not depend on the owner for its own pages.
    func rowWillAppear(_ row: Int) {
        let count = commits.count
        let query = shownQuery
        guard row >= count - Self.pagingWindow else { return }
        if let lastPaged, lastPaged.query == query, lastPaged.count == count { return }
        lastPaged = (query, count)
        pagingTask = Task { [weak self] in
            guard let self else { return }
            await self.source.loadMore()
            self.reload()
        }
    }
}

extension GitHistoryViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { commits.count }
}

extension GitHistoryViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, let column = Column(rawValue: tableColumn.identifier.rawValue),
              commits.indices.contains(row) else { return nil }
        let commit = commits[row]
        switch column {
        case .graph:
            let cell = reuse(tableView, column.identifier) { CommitGraphCellView() }
            cell.row = graphRows.indices.contains(row) ? graphRows[row] : nil
            return cell
        case .subject:
            let cell = reuse(tableView, GitHistorySubjectCellView.identifier) { GitHistorySubjectCellView() }
            let refs = refsByCommit[commit.id] ?? []
            cell.configure(subject: commit.subject, badges: GitHistoryRefBadge.badges(for: refs))
            return cell
        case .author:
            let cell = reuse(tableView, GitHistoryAuthorCellView.identifier) { GitHistoryAuthorCellView() }
            cell.configure(author: commit.author)
            return cell
        case .date:
            let label = reuse(tableView, column.identifier) {
                Self.label(role: .secondaryText, textRole: .body, identifier: "git.history.date")
            }
            label.stringValue = RelativeDateFormatting.string(for: commit.author.date)
            label.toolTip = commit.author.date.formatted(date: .abbreviated, time: .shortened)
            return label
        case .sha:
            let label = reuse(tableView, column.identifier) {
                Self.label(role: .secondaryText, textRole: .code, identifier: "git.history.sha")
            }
            label.stringValue = commit.shortID
            return label
        }
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = GitHistoryRowView(frame: .zero)
        rowView.accessibilityID("git.history.row")
        return rowView
    }

    public func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowWillAppear(row)
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isApplyingSelection else { return }
        report(selectedCommit)
    }

    private func reuse<T: NSView>(_ tableView: NSTableView, _ identifier: NSUserInterfaceItemIdentifier,
                                  make: () -> T) -> T {
        if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? T { return reused }
        let view = make()
        view.identifier = identifier
        return view
    }

    private static func label(role: ThemeRole, textRole: TextRole, identifier: String) -> ThemedLabel {
        let label = ThemedLabel(role: role, textRole: textRole)
        label.lineBreakMode = .byTruncatingTail
        label.accessibilityID(identifier)
        return label
    }
}
