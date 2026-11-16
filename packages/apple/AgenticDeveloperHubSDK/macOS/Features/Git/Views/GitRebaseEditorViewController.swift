import AppKit
import AgenticDeveloperHubSDKCore

/// The git window's interactive rebase editor (recipe `workspace/git/git-rebase-editor`):
/// a plan's entries, oldest at the top, each with its action, short sha and subject. Rows
/// are dragged to reorder; a reword's subject becomes an editable field holding its
/// message. Start Rebase is enabled only while the plan is valid, with the reason it is
/// not as its tooltip. The editor runs nothing: `onFinish` gets the edited plan, or nil
/// for Cancel. Used on the main thread.
@MainActor
public final class GitRebaseEditorViewController: NSViewController {

    /// The plan as edited so far.
    public private(set) var plan: GitRebasePlan
    /// Called once with the plan for Start Rebase, or nil for Cancel.
    public var onFinish: ((GitRebasePlan?) -> Void)?

    let tableView = ThemedTableView()
    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    let startButton = NSButton(title: "Start Rebase", target: nil, action: nil)
    private let scrollView = ThemedScrollView()

    /// The pasteboard type a dragged row carries: its index, meaningful only to this table.
    static let rowPasteboardType = NSPasteboard.PasteboardType("com.agenticdeveloperhub.git.rebase.row")

    enum Column: String, CaseIterable {
        case action, sha, subject

        var title: String {
            switch self {
            case .action: return "Action"
            case .sha: return "SHA"
            case .subject: return "Subject"
            }
        }

        var width: CGFloat {
            switch self {
            case .action: return 110
            case .sha: return 80
            case .subject: return 420
            }
        }

        var identifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier(rawValue) }
    }

    public init(plan: GitRebasePlan) {
        self.plan = plan
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = ThemedBackgroundView()
        root.accessibilityID("git.rebase")

        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: column.identifier)
            tableColumn.title = column.title
            tableColumn.width = column.width
            tableView.addTableColumn(tableColumn)
        }
        tableView.headerView = ThemedTableHeaderView()
        tableView.rowHeight = 26
        tableView.intercellSpacing = NSSize(width: 6, height: 2)
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityID("git.rebase.table")
        tableView.registerForDraggedTypes([Self.rowPasteboardType])
        tableView.setDraggingSourceOperationMask(.move, forLocal: true)
        tableView.draggingDestinationFeedbackStyle = .gap

        scrollView.documentView = tableView
        scrollView.accessibilityID("git.rebase.scroll")
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        for (button, name, action) in [(cancelButton, "cancel", #selector(cancelPressed(_:))),
                                       (startButton, "start", #selector(startPressed(_:)))] {
            button.target = self
            button.action = action
            button.bezelStyle = .push
            button.accessibilityID("git.rebase.\(name)")
        }
        cancelButton.keyEquivalent = "\u{1b}"
        startButton.keyEquivalent = "\r"
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let buttons = NSStackView(views: [spacer, cancelButton, startButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.accessibilityID("git.rebase.buttons")

        for view in [scrollView, buttons] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            buttons.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            buttons.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            buttons.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            buttons.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
            root.widthAnchor.constraint(greaterThanOrEqualToConstant: 660),
            root.heightAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])
        view = root
        preferredContentSize = NSSize(width: 680, height: 380)
        updateStart()
    }

    // MARK: - Editing

    /// Sets the action of the entry at `row`. Switching to reword with no message fills it
    /// with the subject, so the field never starts empty.
    func setAction(_ action: GitRebaseEntry.Action, at row: Int) {
        guard plan.entries.indices.contains(row), plan.entries[row].action != action else { return }
        plan.entries[row].action = action
        if action == .reword, plan.entries[row].message == nil {
            plan.entries[row].message = plan.entries[row].subject
        }
        if isViewLoaded {
            tableView.reloadData(forRowIndexes: IndexSet(integer: row),
                                 columnIndexes: IndexSet(integersIn: 0..<tableView.numberOfColumns))
        }
        updateStart()
    }

    /// Sets the reword message of the entry at `row`.
    func setMessage(_ message: String, at row: Int) {
        guard plan.entries.indices.contains(row) else { return }
        plan.entries[row].message = message
        updateStart()
    }

    /// Moves the entry at `source` to sit above the row `destination` was before the move
    /// (`entries.count` for the end), as a table drop names it.
    func moveEntry(from source: Int, to destination: Int) {
        let entries = plan.entries
        guard entries.indices.contains(source), (0...entries.count).contains(destination),
              destination != source, destination != source + 1 else { return }
        let entry = plan.entries.remove(at: source)
        let target = destination > source ? destination - 1 : destination
        plan.entries.insert(entry, at: target)
        if isViewLoaded {
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: target), byExtendingSelection: false)
        }
        updateStart()
    }

    private func updateStart() {
        let error = plan.validationError
        startButton.isEnabled = error == nil
        startButton.toolTip = error
    }

    @objc private func cancelPressed(_ sender: Any?) { finish(nil) }

    @objc private func startPressed(_ sender: Any?) {
        guard plan.validationError == nil else { return }
        // A field still being edited has already sent each change; ending it commits nothing new.
        view.window?.makeFirstResponder(nil)
        finish(plan)
    }

    private func finish(_ result: GitRebasePlan?) {
        let handler = onFinish
        onFinish = nil
        handler?(result)
    }

    /// The row whose entry is `commit`, or nil.
    fileprivate func row(of commit: String) -> Int? {
        plan.entries.firstIndex { $0.commit == commit }
    }
}

// MARK: - Table

extension GitRebaseEditorViewController: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int { plan.entries.count }

    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: Self.rowPasteboardType)
        return item
    }

    public func tableView(
        _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        guard (info.draggingSource as? NSTableView) === tableView,
              Self.draggedRow(info.draggingPasteboard) != nil else { return [] }
        tableView.setDropRow(row, dropOperation: .above)
        return .move
    }

    public func tableView(
        _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        guard (info.draggingSource as? NSTableView) === tableView,
              let source = Self.draggedRow(info.draggingPasteboard) else { return false }
        moveEntry(from: source, to: row)
        return true
    }

    /// The row index a dragged row put on `pasteboard`, or nil.
    static func draggedRow(_ pasteboard: NSPasteboard) -> Int? {
        pasteboard.string(forType: rowPasteboardType).flatMap { Int($0) }
    }
}

extension GitRebaseEditorViewController: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn, let column = Column(rawValue: tableColumn.identifier.rawValue),
              plan.entries.indices.contains(row) else { return nil }
        let entry = plan.entries[row]
        switch column {
        case .action:
            let cell = GitRebaseActionCellView()
            cell.configure(entry.action) { [weak self] action in
                guard let self, let row = self.row(of: entry.commit) else { return }
                self.setAction(action, at: row)
            }
            return cell
        case .sha:
            let label = ThemedLabel(role: .secondaryText, textRole: .code)
            label.lineBreakMode = .byTruncatingTail
            label.stringValue = String(entry.commit.prefix(8))
            label.accessibilityID("git.rebase.sha")
            return label
        case .subject:
            guard entry.action == .reword else {
                let label = ThemedLabel(role: .primaryText, textRole: .body)
                label.lineBreakMode = .byTruncatingTail
                label.stringValue = entry.subject
                label.accessibilityID("git.rebase.subject")
                return label
            }
            let field = GitRebaseMessageField(message: entry.message ?? "") { [weak self] text in
                guard let self, let row = self.row(of: entry.commit) else { return }
                self.setMessage(text, at: row)
            }
            return field
        }
    }
}

// MARK: - Cells

/// The action column's pop-up: the six actions by name.
@MainActor
final class GitRebaseActionCellView: NSTableCellView {
    let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private var onChange: ((GitRebaseEntry.Action) -> Void)?

    init() {
        super.init(frame: .zero)
        popUp.addItems(withTitles: GitRebaseEntry.Action.allCases.map(\.rawValue))
        popUp.controlSize = .small
        popUp.target = self
        popUp.action = #selector(chosen(_:))
        popUp.accessibilityID("git.rebase.action")
        popUp.translatesAutoresizingMaskIntoConstraints = false
        addSubview(popUp)
        NSLayoutConstraint.activate([
            popUp.leadingAnchor.constraint(equalTo: leadingAnchor),
            popUp.trailingAnchor.constraint(equalTo: trailingAnchor),
            popUp.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(_ action: GitRebaseEntry.Action, onChange: @escaping (GitRebaseEntry.Action) -> Void) {
        popUp.selectItem(withTitle: action.rawValue)
        self.onChange = onChange
    }

    @objc private func chosen(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem, let action = GitRebaseEntry.Action(rawValue: title) else {
            return
        }
        onChange?(action)
    }
}

/// A reword's subject cell: an editable field holding the new message, reporting each change.
@MainActor
final class GitRebaseMessageField: ThemedTextField, NSTextFieldDelegate {
    private let onChange: (String) -> Void

    init(message: String, onChange: @escaping (String) -> Void) {
        self.onChange = onChange
        super.init(string: message)
        lineBreakMode = .byTruncatingTail
        usesSingleLineMode = false
        cell?.wraps = false
        cell?.isScrollable = true
        setAccessibilityLabel("Message")
        accessibilityID("git.rebase.message")
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func controlTextDidChange(_ obj: Notification) {
        onChange(stringValue)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        onChange(stringValue)
    }
}
