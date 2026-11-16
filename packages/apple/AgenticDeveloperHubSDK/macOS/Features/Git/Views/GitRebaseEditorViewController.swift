import AppKit
import AgenticDeveloperHubSDKCore

/// The git window's interactive rebase editor (recipe `workspace/git/git-rebase-editor`):
/// a plan's entries, oldest at the top, each with its action, short sha and subject. Rows
/// are dragged to reorder, or moved with Move Up and Move Down (⌥⌘↑, ⌥⌘↓); a reword's
/// subject becomes a multi-line field holding its whole message, in a row tall enough to
/// show it, where Return types a newline and never starts the rebase. Start Rebase is
/// enabled only while the plan is valid, with the reason it is not as its tooltip. The
/// editor runs nothing: `onFinish` gets the edited plan, or nil for Cancel. Used on the main thread.
@MainActor
public final class GitRebaseEditorViewController: NSViewController {

    /// The plan as edited so far.
    public private(set) var plan: GitRebasePlan
    /// Called once with the plan for Start Rebase, or nil for Cancel.
    public var onFinish: ((GitRebasePlan?) -> Void)?

    let tableView = ThemedTableView()
    let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    let startButton = NSButton(title: "Start Rebase", target: nil, action: nil)
    let moveUpButton = NSButton(title: "Move Up", target: nil, action: nil)
    let moveDownButton = NSButton(title: "Move Down", target: nil, action: nil)
    private let scrollView = ThemedScrollView()
    private lazy var measuringField = GitRebaseMessageField()

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
        tableView.rowHeight = Self.rowHeight
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
                                       (startButton, "start", #selector(startPressed(_:))),
                                       (moveUpButton, "moveUp", #selector(moveUpPressed(_:))),
                                       (moveDownButton, "moveDown", #selector(moveDownPressed(_:)))] {
            button.target = self
            button.action = action
            button.bezelStyle = .push
            button.accessibilityID("git.rebase.\(name)")
        }
        cancelButton.keyEquivalent = "\u{1b}"
        startButton.keyEquivalent = "\r"
        // NSUpArrowFunctionKey and NSDownArrowFunctionKey.
        moveUpButton.keyEquivalent = "\u{F700}"
        moveDownButton.keyEquivalent = "\u{F701}"
        for button in [moveUpButton, moveDownButton] {
            button.keyEquivalentModifierMask = [.option, .command]
        }
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        spacer.accessibilityID("git.rebase.spacer")
        let buttons = NSStackView(views: [moveUpButton, moveDownButton, spacer, cancelButton, startButton])
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
        updateMoveButtons()
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

    /// Sets the reword message of the entry at `row`, growing or shrinking the row to show
    /// all of its lines, wrapped ones included.
    func setMessage(_ message: String, at row: Int) {
        guard plan.entries.indices.contains(row) else { return }
        let before = height(ofRow: row)
        plan.entries[row].message = message
        if isViewLoaded, height(ofRow: row) != before {
            tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
        }
        updateStart()
    }

    /// The height of a row: one line, or a reword's whole message as the Subject column
    /// wraps it, measured by a field of the cell's own kind at the column's width (the theme
    /// sets its font), and never less than one line per line of the message.
    func height(ofRow row: Int) -> CGFloat {
        guard plan.entries.indices.contains(row), plan.entries[row].action == .reword else {
            return Self.rowHeight
        }
        let message = plan.entries[row].message ?? ""
        let font = measuringField.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let lineHeight = NSLayoutManager().defaultLineHeight(for: font)
        let lines = ceil(CGFloat(Self.lineCount(message)) * lineHeight) + 8
        measuringField.stringValue = message
        // What wrapping at the column's width adds over the same text unwrapped: the cell's
        // height at that width less its height at an unbounded one, so a message that fits
        // on its lines adds nothing.
        func cellHeight(width: CGFloat) -> CGFloat {
            let bounds = NSRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude)
            return ceil(measuringField.cell?.cellSize(forBounds: bounds).height ?? 0)
        }
        let wrapping = max(0, cellHeight(width: subjectWidth) - cellHeight(width: .greatestFiniteMagnitude))
        return max(Self.rowHeight, lines + wrapping)
    }

    /// The width a reword's field gets, which its message wraps at: the frame the table lays
    /// the Subject cell view out in (`frameOfCell`), the same for every row.
    var subjectWidth: CGFloat {
        let column = tableView.column(withIdentifier: Column.subject.identifier)
        guard column >= 0 else { return Column.subject.width }
        return tableView.frameOfCell(atColumn: column, row: 0).width
    }

    static let rowHeight: CGFloat = 26

    private static func lineCount(_ message: String?) -> Int {
        max(1, (message ?? "").split(separator: "\n", omittingEmptySubsequences: false).count)
    }

    /// Moves the entry at `source` to sit above the row `destination` was before the move
    /// (`entries.count` for the end), as a table drop names it.
    /// A reword field being edited (⌥⌘↑ reaches the button while the field editor has the
    /// keys) is edited again after the reload, with its insertion point where it was.
    func moveEntry(from source: Int, to destination: Int) {
        let entries = plan.entries
        guard entries.indices.contains(source), (0...entries.count).contains(destination),
              destination != source, destination != source + 1 else { return }
        let editing = editingMessage()
        let entry = plan.entries.remove(at: source)
        let target = destination > source ? destination - 1 : destination
        plan.entries.insert(entry, at: target)
        if isViewLoaded {
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: target), byExtendingSelection: false)
            tableView.scrollRowToVisible(target)
            if let editing { resumeEditing(editing) }
        }
        updateStart()
        updateMoveButtons()
    }

    /// The reword field being edited, as its entry's commit and the field editor's
    /// selection; nil when no field is.
    private func editingMessage() -> (commit: String, selection: NSRange)? {
        guard let editor = viewIfLoaded?.window?.firstResponder as? NSTextView, editor.isFieldEditor,
              let field = (editor.delegate as? NSObject) as? GitRebaseMessageField else { return nil }
        let row = tableView.row(for: field)
        guard plan.entries.indices.contains(row) else { return nil }
        return (plan.entries[row].commit, editor.selectedRange())
    }

    /// Edits `editing`'s entry's field again, wherever its row now is, with the selection
    /// it had (clamped to the text).
    private func resumeEditing(_ editing: (commit: String, selection: NSRange)) {
        let column = tableView.column(withIdentifier: Column.subject.identifier)
        guard column >= 0, let row = row(of: editing.commit),
              let field = tableView.view(atColumn: column, row: row, makeIfNecessary: true)
                as? GitRebaseMessageField,
              view.window?.makeFirstResponder(field) == true else { return }
        let length = (field.stringValue as NSString).length
        let location = min(editing.selection.location, length)
        field.currentEditor()?.selectedRange = NSRange(location: location,
                                                       length: min(editing.selection.length, length - location))
    }

    /// Moves the selected entry one row up (`offset` -1) or down (+1); nothing at an end.
    func moveSelected(by offset: Int) {
        let row = tableView.selectedRow
        guard plan.entries.indices.contains(row), plan.entries.indices.contains(row + offset) else { return }
        moveEntry(from: row, to: offset < 0 ? row - 1 : row + 2)
    }

    @objc private func moveUpPressed(_ sender: Any?) { moveSelected(by: -1) }

    @objc private func moveDownPressed(_ sender: Any?) { moveSelected(by: 1) }

    fileprivate func updateMoveButtons() {
        let row = tableView.selectedRow
        moveUpButton.isEnabled = row > 0 && row < plan.entries.count
        moveDownButton.isEnabled = row >= 0 && row < plan.entries.count - 1
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
            let cell = reused(GitRebaseActionCellView.reuseIdentifier) { GitRebaseActionCellView() }
            cell.configure(entry.action) { [weak self] action in
                guard let self, let row = self.row(of: entry.commit) else { return }
                self.setAction(action, at: row)
            }
            return cell
        case .sha:
            let label = reused(Self.shaIdentifier) { Self.label(role: .secondaryText, textRole: .code, id: "sha") }
            label.stringValue = String(entry.commit.prefix(8))
            return label
        case .subject:
            guard entry.action == .reword else {
                let label = reused(Self.subjectIdentifier) {
                    Self.label(role: .primaryText, textRole: .body, id: "subject")
                }
                label.stringValue = entry.subject
                return label
            }
            let field = reused(GitRebaseMessageField.reuseIdentifier) { GitRebaseMessageField() }
            field.configure(message: entry.message ?? "") { [weak self] text in
                guard let self, let row = self.row(of: entry.commit) else { return }
                self.setMessage(text, at: row)
            }
            return field
        }
    }

    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        height(ofRow: row)
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        updateMoveButtons()
    }

    /// A wider or narrower Subject column wraps a reword's message differently.
    public func tableViewColumnDidResize(_ notification: Notification) {
        guard tableView.numberOfRows > 0 else { return }
        tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<tableView.numberOfRows))
    }

    private static let shaIdentifier = NSUserInterfaceItemIdentifier("git.rebase.shaCell")
    private static let subjectIdentifier = NSUserInterfaceItemIdentifier("git.rebase.subjectCell")

    /// The table's spare view for `identifier`, or a new one from `make` tagged with it.
    private func reused<View: NSView>(_ identifier: NSUserInterfaceItemIdentifier, _ make: () -> View) -> View {
        if let view = tableView.makeView(withIdentifier: identifier, owner: nil) as? View { return view }
        let view = make()
        view.identifier = identifier
        return view
    }

    private static func label(role: ThemeRole, textRole: TextRole, id: String) -> ThemedLabel {
        let label = ThemedLabel(role: role, textRole: textRole)
        label.lineBreakMode = .byTruncatingTail
        label.accessibilityID("git.rebase.\(id)")
        return label
    }
}

// MARK: - Cells

/// The action column's pop-up: the six actions by name.
@MainActor
final class GitRebaseActionCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("git.rebase.actionCell")
    let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private var onChange: ((GitRebaseEntry.Action) -> Void)?

    init() {
        super.init(frame: .zero)
        accessibilityID("git.rebase.actionCell")
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

/// A reword's subject cell: an editable, wrapping field holding the whole message, one
/// line per line of it, reporting each change. Return types a newline here, so it never
/// reaches the window's default button (Start Rebase).
@MainActor
final class GitRebaseMessageField: ThemedTextField, NSTextFieldDelegate {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("git.rebase.messageCell")
    private var onChange: ((String) -> Void)?

    init() {
        super.init(string: "")
        lineBreakMode = .byWordWrapping
        usesSingleLineMode = false
        cell?.wraps = true
        cell?.isScrollable = false
        setAccessibilityLabel("Message")
        accessibilityID("git.rebase.message")
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(message: String, onChange: @escaping (String) -> Void) {
        self.onChange = nil
        stringValue = message
        self.onChange = onChange
    }

    func controlTextDidChange(_ obj: Notification) {
        onChange?(stringValue)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        onChange?(stringValue)
    }

    /// Return and Enter insert a newline into the message instead of ending the edit.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard commandSelector == #selector(NSResponder.insertNewline(_:))
            || commandSelector == #selector(NSResponder.insertLineBreak(_:)) else { return false }
        textView.insertNewlineIgnoringFieldEditor(nil)
        return true
    }
}
