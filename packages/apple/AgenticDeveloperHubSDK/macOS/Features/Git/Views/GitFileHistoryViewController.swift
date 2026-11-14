import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import os

/// The git window's file history (recipe `workspace/git/git-views`, "File history"): the
/// commits that touched one file, newest first, in a list beside a `GitDiffViewController`
/// showing the selected commit's change to that file, asked for under the file's path at
/// that commit (both paths for a rename), so commits from before a rename show their
/// change too. The newest is selected on load; an empty selection clears the diff.
///
/// The latest `show(path:)` wins, decided by the controller's own counter. A history that
/// fails is logged and its description shown, with the list emptied and the diff cleared.
/// Used on the main thread.
@MainActor
public final class GitFileHistoryViewController: NSViewController {

    let splitView = ThemedSplitView()
    let scrollView = ThemedScrollView()
    let tableView = ThemedTableView()
    /// The failed history's description, over the empty list; hidden otherwise.
    let errorLabel = ThemedLabel.wrapping("", width: 400, role: .danger, textRole: .body)
    public let diffViewController: GitDiffViewController

    /// The file's commits as of the last load, newest first, each with the file's path then.
    private(set) var entries: [GitFileHistoryEntry] = []
    var commits: [GitCommit] { entries.map(\.commit) }
    /// The history request in flight or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?
    /// Bumped by every `show` before anything awaits.
    private(set) var generation = 0

    private let source: GitContentSource
    /// True while `setCommits` moves the selection itself.
    private var isApplyingSelection = false
    /// The path last asked for, or nil before the first `show`.
    private var shownPath: String?

    private static let column = NSUserInterfaceItemIdentifier("git.fileHistory.column")

    public init(source: GitContentSource, coloring: GitSyntaxColoring?, settings: SettingsStore = UserSettings.shared) {
        self.source = source
        diffViewController = GitDiffViewController(source: source, coloring: coloring, settings: settings)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.fileHistory")

        let column = NSTableColumn(identifier: Self.column)
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 40
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.fileHistory.table")
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.accessibilityID("git.fileHistory.scroll")

        let listPane = NSView()
        errorLabel.accessibilityID("git.fileHistory.error")
        errorLabel.isSelectable = true
        errorLabel.isHidden = true
        for view in [scrollView, errorLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            listPane.addSubview(view)
        }
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: listPane.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: listPane.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: listPane.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: listPane.bottomAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: listPane.leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: listPane.trailingAnchor, constant: -12),
            errorLabel.topAnchor.constraint(equalTo: listPane.topAnchor, constant: 10),
            listPane.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])

        addChild(diffViewController)
        splitView.accessibilityID("git.fileHistory.split")
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(listPane)
        splitView.addArrangedSubview(diffViewController.view)
        splitView.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(splitView)
        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: root.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
    }

    /// Lists `path`'s commits. The previous list stays until the history arrives; it lands
    /// only if no later `show` has been made, and then the newest commit is selected.
    public func show(path: String) {
        load(path: path, keepsSelection: false)
    }

    /// Lists the shown path's commits again (new commits, or a Refresh), keeping the
    /// commit selected when the history lands selected when it is still listed, else the
    /// newest. The latest `show` or `reload` wins. Nothing shown, nothing read.
    public func reload() {
        guard let shownPath else { return }
        load(path: shownPath, keepsSelection: true)
    }

    private func load(path: String, keepsSelection: Bool) {
        shownPath = path
        generation += 1
        let generation = self.generation
        loadTask?.cancel()
        errorLabel.show(error: nil)
        loadTask = Task { [weak self, source] in
            let result: Result<[GitFileHistoryEntry], Error>
            do {
                result = .success(try await source.fileHistory(path: path))
            } catch {
                result = .failure(error)
            }
            guard let self, generation == self.generation else { return }
            switch result {
            case .failure(let error):
                self.setEntries([])
                let description = GitClientError.logDescription(of: error)
                Self.logger.error("Git file history failed: \(description, privacy: .public)")
                self.errorLabel.show(error: error)
            case .success(let entries):
                // Read now, not when the reload was asked for: the user may have picked
                // another commit while git was answering.
                let row = self.tableView.selectedRow
                let selectedID = keepsSelection && self.entries.indices.contains(row)
                    ? self.entries[row].commit.id : nil
                self.setEntries(entries, keeping: selectedID)
            }
        }
    }

    /// Lists `entries` with the commit `selectedID` selected when listed, else the newest
    /// (none when empty), and shows that in the diff once, however many selection
    /// notifications the table sends on the way.
    private func setEntries(_ entries: [GitFileHistoryEntry], keeping selectedID: String? = nil) {
        self.entries = entries
        isApplyingSelection = true
        tableView.reloadData()
        if entries.isEmpty {
            tableView.deselectAll(nil)
        } else {
            let row = selectedID.flatMap { id in entries.firstIndex { $0.commit.id == id } } ?? 0
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        isApplyingSelection = false
        selectionChanged()
    }

    private func selectionChanged() {
        let row = tableView.selectedRow
        guard entries.indices.contains(row) else {
            diffViewController.clear()
            return
        }
        let entry = entries[row]
        diffViewController.show(target: .commit(entry.commit.id, paths: entry.paths), file: entry.path)
    }
}

extension GitFileHistoryViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { entries.count }
}

extension GitFileHistoryViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard entries.indices.contains(row) else { return nil }
        let cell: GitFileHistoryCellView
        if let reused = tableView.makeView(withIdentifier: GitFileHistoryCellView.identifier,
                                           owner: self) as? GitFileHistoryCellView {
            cell = reused
        } else {
            cell = GitFileHistoryCellView()
            cell.identifier = GitFileHistoryCellView.identifier
        }
        cell.configure(entries[row].commit)
        return cell
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = GitHistoryRowView(frame: .zero)
        rowView.accessibilityID("git.fileHistory.row")
        return rowView
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isApplyingSelection else { return }
        selectionChanged()
    }
}

extension GitFileHistoryViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}

/// One commit in the file history: its subject, and below it the short sha, the author's
/// initials and the relative date.
final class GitFileHistoryCellView: NSView {

    static let identifier = NSUserInterfaceItemIdentifier("git.fileHistory.commit")

    let subjectLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let detailsLabel = ThemedLabel(role: .secondaryText, textRole: .caption)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        accessibilityID("git.fileHistory.commit")
        subjectLabel.accessibilityID("git.fileHistory.subject")
        detailsLabel.accessibilityID("git.fileHistory.details")
        for label in [subjectLabel, detailsLabel] {
            label.lineBreakMode = .byTruncatingTail
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        let stack = NSStackView(views: [subjectLabel, detailsLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(_ commit: GitCommit) {
        subjectLabel.stringValue = commit.subject
        let initials = PersonInitials.of(name: commit.author.name, fallback: commit.author.email)
        detailsLabel.stringValue = [commit.shortID, initials, RelativeDateFormatting.string(for: commit.author.date)]
            .joined(separator: " · ")
        detailsLabel.toolTip = commit.author.date.formatted(date: .abbreviated, time: .shortened)
    }
}
