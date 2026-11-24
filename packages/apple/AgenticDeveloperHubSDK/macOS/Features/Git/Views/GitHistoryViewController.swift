import AppKit
import AgenticDeveloperHubSDKCore

/// What the user asked the history list to do with a commit. The view runs none of it;
/// its delegate does.
public enum GitCommitIntent: Equatable {
    case checkout, createBranch, createTag, cherryPick, revert, reset(GitResetMode)
    /// Rebase the commits after this one interactively, onto it.
    case interactiveRebase
}

/// Told which commit the history list has selected, or nil when nothing is, and every
/// action chosen from a commit's context menu.
@MainActor public protocol GitHistoryDelegate: AnyObject {
    func history(_ history: GitHistoryViewController, didSelect commit: GitCommit?)
    func history(_ history: GitHistoryViewController, didRequest intent: GitCommitIntent, for commit: GitCommit)
}

/// The git window's history list (recipe `workspace/git/git-views`, "History list"): a
/// paged table of the commit graph, the subject behind its ref badges, the author, the
/// relative date and the short sha, read from a `GitHistoryDataSource`.
///
/// The owner calls `reload()` when the model reports a history change and forwards the
/// window's search text to `setQuery(_:)`. A right-clicked row's context menu acts on that
/// row's commit, not the selection: its actions reach the delegate as `GitCommitIntent`s,
/// and Copy SHA puts the full sha on `pasteboard`. Used on the main thread; every
/// data-source call that waits is awaited.
@MainActor
public final class GitHistoryViewController: NSViewController {

    public weak var delegate: GitHistoryDelegate?

    /// Called with the full name of a ref dragged from the sidebar and dropped on any row
    /// (`TopicListViewController.itemPasteboardType`). Unset, the table takes no drop.
    public var onRefDrop: ((_ refFullName: String) -> Void)?

    /// Whether a dragged ref may be dropped at all; unset, any ref may. The owner answers
    /// it with the same rules its drop menu uses, so a drop it would refuse shows no cursor.
    public var refDropValidator: ((_ refFullName: String) -> Bool)?

    let tableView = ThemedTableView()
    /// The table's menu, refilled for the clicked row each time it opens.
    private let rowMenu = NSMenu()
    /// Where Copy SHA puts the sha.
    private let pasteboard: NSPasteboard
    /// The one pending ask for the visible rows' signatures and reviews, while a scroll
    /// posts its steps; nil between turns.
    private(set) var visibleRequestTask: Task<Void, Never>?
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

    public init(source: GitHistoryDataSource, pasteboard: NSPasteboard = .general) {
        self.source = source
        self.pasteboard = pasteboard
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
        tableView.registerForDraggedTypes([TopicListViewController.itemPasteboardType])
        rowMenu.delegate = self
        tableView.menu = rowMenu

        scrollView.documentView = tableView
        scrollView.accessibilityID("git.history.scroll")
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        observeVisibleRows()
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
        requestVisibleSignatures()
        requestVisibleReviews()
    }

    /// Redraws the subject cells of the rows on screen, where the signature and review
    /// badges sit, after a batch of either lands (`.annotations`). Nothing is re-read from
    /// the data source but those badges, the selection is untouched and no request is sent.
    public func reloadAnnotations() {
        guard isViewLoaded else { return }
        let range = tableView.rows(in: tableView.visibleRect)
        guard range.location != NSNotFound, range.length > 0,
              let column = tableView.tableColumns.firstIndex(where: { $0.identifier == Column.subject.identifier })
        else { return }
        let rows = IndexSet(integersIn: range.location..<(range.location + range.length))
        tableView.reloadData(forRowIndexes: rows, columnIndexes: IndexSet(integer: column))
    }

    // MARK: - Signatures

    /// The shas of the rows the table shows now; empty before it has a size.
    var visibleCommitIDs: [String] {
        guard isViewLoaded else { return [] }
        let range = tableView.rows(in: tableView.visibleRect)
        guard range.location != NSNotFound, range.length > 0 else { return [] }
        let rows = range.location..<(range.location + range.length)
        return rows.compactMap { commits.indices.contains($0) ? commits[$0].id : nil }
    }

    /// Watches the clip view, so scrolling and resizing ask for the rows then in
    /// `visibleRect` (`clipViewDidChange(_:)`), once per main-actor turn however many
    /// steps a scroll posts. Selector observers are removed by Foundation when the
    /// controller goes away.
    private func observeVisibleRows() {
        let clip = scrollView.contentView
        clip.postsBoundsChangedNotifications = true
        clip.postsFrameChangedNotifications = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(clipViewDidChange(_:)),
                           name: NSView.boundsDidChangeNotification, object: clip)
        center.addObserver(self, selector: #selector(clipViewDidChange(_:)),
                           name: NSView.frameDidChangeNotification, object: clip)
    }

    @objc private func clipViewDidChange(_ notification: Notification) {
        guard visibleRequestTask == nil else { return }
        visibleRequestTask = Task { [weak self] in
            guard let self else { return }
            self.visibleRequestTask = nil
            self.requestVisibleSignatures()
            self.requestVisibleReviews()
        }
    }

    /// Asks the data source for the visible rows' signatures, after every reload and every
    /// time the clip view scrolls or resizes. The data source debounces and coalesces
    /// (150ms) and each request replaces the queued one, so a scroll runs one `git log` for
    /// the rows where it stopped, and the history never waits on it.
    func requestVisibleSignatures() {
        requestVisible { source.requestSignatures(for: $0) }
    }

    /// Asks the data source for the visible rows' Coding Partner reviews (recipe
    /// `workspace/git/git-views`, "Reviews") at the same moments as the signatures, and when
    /// the review store reports a change. Debounced and coalesced the same way.
    public func requestVisibleReviews() {
        requestVisible { source.requestReviews(for: $0) }
    }

    /// Hands the visible rows' shas to `send`, unless no row is visible.
    private func requestVisible(_ send: ([String]) -> Void) {
        let shas = visibleCommitIDs
        guard !shas.isEmpty else { return }
        send(shas)
    }

    // MARK: - Selection

    /// Selects the loaded commit with exactly `commitID`, scrolls to it and tells the
    /// delegate. An id that is not loaded changes nothing.
    ///
    /// - Returns: whether the list holds the commit and selected it.
    @discardableResult
    public func select(commitID: String) -> Bool {
        guard let index = commits.firstIndex(where: { $0.id == commitID }) else { return false }
        loadViewIfNeeded()
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
        report(commits[index])
        return true
    }

    /// The commit the list has selected, or nil.
    public var selectedCommitID: String? { selectedCommit?.id }

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

    /// How long a new query waits before it is sent, so a burst of keystrokes runs one
    /// `git log` rather than one per key. Tests may shorten it.
    var searchDelay: Duration = .milliseconds(250)

    /// Applies the window's search text (`GitHistorySearch.parse(_:)`). A query that
    /// differs from the one last sent is sent to the data source after `searchDelay`,
    /// and cancels the send it replaces, so a superseded `git log` is terminated rather
    /// than left to run; a query equal to one still in flight waits for it rather than
    /// being sent again. Cancelling the latest caller cancels its send too, and the next
    /// call with that query sends it afresh. The latest call then reloads the list and,
    /// for a `sha:` search, selects the first loaded commit with that prefix. A call
    /// overtaken by a later one does neither.
    public func setQuery(_ text: String) async {
        queryGeneration += 1
        let generation = queryGeneration
        let query = GitHistorySearch.parse(text)
        if sendTask?.isCancelled == true || query != (sentQuery ?? source.query) {
            sendTask?.cancel()
            sentQuery = query
            let delay = searchDelay
            sendTask = Task { [source] in
                do { try await Task.sleep(for: delay) } catch { return }
                await source.setQuery(query)
            }
        }
        if let task = sendTask {
            await withTaskCancellationHandler {
                await task.value
            } onCancel: {
                // Only the latest caller owns the send; an older one shares it with a
                // newer call, which still wants it.
                Task { @MainActor [weak self] in
                    guard let self, generation == self.queryGeneration else { return }
                    task.cancel()
                }
            }
            guard generation == queryGeneration, !Task.isCancelled else { return }
            sendTask = nil
            reload()
        }
        guard let prefix = GitHistorySearch.shaPrefix(text) else { return }
        // The snapshot is taken when the view loads; a list never shown has none yet.
        loadViewIfNeeded()
        guard let match = commits.first(where: { $0.id.lowercased().hasPrefix(prefix) }) else { return }
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

// MARK: - Context menu

extension GitHistoryViewController: NSMenuDelegate {
    /// The context menu for `row`'s commit, or nil for a row outside the list.
    func contextMenu(forRow row: Int) -> NSMenu? {
        guard commits.indices.contains(row) else { return nil }
        let commit = commits[row]
        let menu = NSMenu()
        menu.addItem(intentItem("Checkout", "checkout", .checkout, commit))
        menu.addItem(intentItem("New Branch…", "newBranch", .createBranch, commit))
        menu.addItem(intentItem("New Tag…", "newTag", .createTag, commit))
        menu.addItem(.separator())
        menu.addItem(intentItem("Cherry-pick", "cherryPick", .cherryPick, commit))
        menu.addItem(intentItem("Revert", "revert", .revert, commit))
        // Nothing after HEAD to replay, and no new rebase while an operation is in progress.
        if commit.id != source.headCommit, source.operationState == .none {
            let title = "Interactive Rebase from Here…"
            menu.addItem(intentItem(title, "interactiveRebase", .interactiveRebase, commit))
        }
        menu.addItem(.separator())
        let reset = NSMenuItem(title: "Reset Current Branch to Here", action: nil, keyEquivalent: "")
        reset.accessibilityID("git.history.menu.reset")
        let modes = NSMenu()
        modes.addItem(intentItem("Soft", "resetSoft", .reset(.soft), commit))
        modes.addItem(intentItem("Mixed", "resetMixed", .reset(.mixed), commit))
        modes.addItem(intentItem("Hard…", "resetHard", .reset(.hard), commit))
        reset.submenu = modes
        menu.addItem(reset)
        menu.addItem(.separator())
        let copy = NSMenuItem(title: "Copy SHA", action: #selector(copySha(_:)), keyEquivalent: "")
        copy.target = self
        copy.representedObject = commit.id
        copy.accessibilityID("git.history.menu.copySha")
        menu.addItem(copy)
        return menu
    }

    /// Moves the clicked row's menu items into the table's menu as it opens; a click
    /// outside the rows leaves it empty, which AppKit does not show.
    public func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === rowMenu else { return }
        menu.replaceItems(withItemsOf: contextMenu(forRow: tableView.clickedRow))
    }

    private func intentItem(_ title: String, _ name: String, _ intent: GitCommitIntent,
                            _ commit: GitCommit) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performMenuIntent(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = MenuPayload((intent: intent, commit: commit))
        item.accessibilityID("git.history.menu.\(name)")
        return item
    }

    @objc private func performMenuIntent(_ sender: NSMenuItem) {
        guard let request = sender.payload((intent: GitCommitIntent, commit: GitCommit).self) else { return }
        delegate?.history(self, didRequest: request.intent, for: request.commit)
    }

    @objc private func copySha(_ sender: NSMenuItem) {
        guard let sha = sender.representedObject as? String else { return }
        pasteboard.clearContents()
        pasteboard.setString(sha, forType: .string)
    }
}

extension GitHistoryViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { commits.count }

    public func tableView(
        _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        guard canAcceptRefDrop(pasteboard: info.draggingPasteboard) else { return [] }
        // Any row will do: the drop names a ref, not a commit, so it is always "on".
        tableView.setDropRow(max(0, min(row, commits.count - 1)), dropOperation: .on)
        return .generic
    }

    public func tableView(
        _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        acceptRefDrop(pasteboard: info.draggingPasteboard)
    }

    /// Whether `pasteboard` carries a ref the table would take.
    func canAcceptRefDrop(pasteboard: NSPasteboard) -> Bool {
        guard onRefDrop != nil,
              let name = pasteboard.string(forType: TopicListViewController.itemPasteboardType) else { return false }
        return refDropValidator?(name) ?? true
    }

    /// Hands `pasteboard`'s ref to `onRefDrop`; false, calling nothing, when the table
    /// would not take it.
    @discardableResult
    func acceptRefDrop(pasteboard: NSPasteboard) -> Bool {
        guard canAcceptRefDrop(pasteboard: pasteboard), let onRefDrop,
              let name = pasteboard.string(forType: TopicListViewController.itemPasteboardType) else { return false }
        onRefDrop(name)
        return true
    }
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
            cell.configure(subject: commit.subject, badges: GitHistoryRefBadge.badges(for: refs),
                           signature: GitHistorySignatureBadge(source.signature(for: commit.id)),
                           review: GitHistoryReviewBadge(source.review(for: commit.id)))
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
