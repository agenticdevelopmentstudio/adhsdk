import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// One project's notations: a disclosable section of the list.
@MainActor
final class NotationsProjectItem {
    let projectID: UUID
    let name: String
    var notations: [NotationsNotationItem]

    init(projectID: UUID, name: String, notations: [NotationsNotationItem]) {
        self.projectID = projectID
        self.name = name
        self.notations = notations
    }
}

/// One notation's row, named by its branch.
@MainActor
final class NotationsNotationItem {
    let notation: Notation
    init(notation: Notation) { self.notation = notation }
}

/// The left side of the Notations window: a filter field, an outline with one
/// section per project and one row per branch, and a bottom bar whose −
/// deletes an archived notation.
///
/// The keys follow the Project Browser's: ↑ and ↓ move the selection from the
/// filter or the list, and the details follow it; Return goes to the project.
@MainActor
final class NotationsListViewController: NSViewController {

    /// The selection changed; `nil` when no notation is selected.
    var onSelectionChange: ((Notation?) -> Void)?
    /// Go to the project of a notation (Return, the row's arrow button).
    var onGoToProject: ((Notation) -> Void)?

    var state: Notation.State = .active {
        didSet {
            guard state != oldValue else { return }
            updateRemoveButton()
            reload()
        }
    }

    private let store: NotationsStore
    private let searchField = ThemedSearchField(placeholder: "Filter Notations")
    private let outline = ThemedOutlineView(role: .windowBackground)
    private let scrollView = ThemedScrollView()
    private let removeButton = NSButton(
        image: NSImage(systemSymbolName: "minus", accessibilityDescription: "Delete Notation") ?? NSImage(),
        target: nil, action: nil)
    private var all: [Notation] = []
    private var roots: [NotationsProjectItem] = []
    private var filterText = ""
    private var loadGeneration = 0
    private var changesSubscription: AnyCancellable?

    init(store: NotationsStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    var selectedNotation: Notation? {
        let row = outline.selectedRow
        guard row >= 0 else { return nil }
        return (outline.item(atRow: row) as? NotationsNotationItem)?.notation
    }

    // MARK: - View

    override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)

        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(filterChanged(_:))
        searchField.sendsWholeSearchString = false
        searchField.sendsSearchStringImmediately = true
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.accessibilityID("notations.filter")

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("notation"))
        column.resizingMask = .autoresizingMask
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.headerView = nil
        outline.rowHeight = 24
        outline.indentationPerLevel = 14
        outline.style = .inset
        outline.allowsEmptySelection = true
        outline.allowsMultipleSelection = false
        outline.dataSource = self
        outline.delegate = self
        outline.target = self
        outline.doubleAction = #selector(rowDoubleClicked(_:))
        outline.autoresizesOutlineColumn = false
        outline.accessibilityID("notations.list")

        scrollView.documentView = outline
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        removeButton.target = self
        removeButton.action = #selector(removeSelected(_:))
        removeButton.bezelStyle = .accessoryBarAction
        removeButton.isBordered = false
        removeButton.toolTip = "Delete Archived Notation"
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.accessibilityID("notations.remove")
        removeButton.observeTheme { button, palette in
            button.contentTintColor = palette.nsColor(.secondaryText)
        }

        let bottomBar = ThemedBackgroundView(role: .surface)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(removeButton)

        let separator = ThemedSeparatorView(role: .divider)
        separator.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(searchField)
        container.addSubview(scrollView)
        container.addSubview(separator)
        container.addSubview(bottomBar)
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 28),

            removeButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 8),
            removeButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor)
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        changesSubscription = store.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.reload() }
            }
        updateRemoveButton()
        reload()
    }

    func focusFilter() {
        view.window?.makeFirstResponder(searchField)
    }

    // MARK: - Loading

    /// Reads the notations in the current state off the main thread, then
    /// rebuilds the outline, keeping the selection when it survives.
    func reload() {
        loadGeneration += 1
        let generation = loadGeneration
        let store = store
        let state = state
        Task { [weak self] in
            let notations = await Task.detached(priority: .userInitiated) {
                (try? store.all(state: state)) ?? []
            }.value
            guard let self, generation == self.loadGeneration else { return }
            self.all = notations
            self.applyFilter()
        }
    }

    private func applyFilter() {
        let previous = selectedNotation?.id
        let query = filterText.trimmingCharacters(in: .whitespaces)
        let matching = all.filter { Self.matches($0, query: query) }
        var groups: [UUID: NotationsProjectItem] = [:]
        var order: [UUID] = []
        for notation in matching {
            if let group = groups[notation.projectID] {
                group.notations.append(NotationsNotationItem(notation: notation))
            } else {
                groups[notation.projectID] = NotationsProjectItem(
                    projectID: notation.projectID, name: notation.projectName,
                    notations: [NotationsNotationItem(notation: notation)])
                order.append(notation.projectID)
            }
        }
        roots = order.compactMap { groups[$0] }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        for group in roots {
            group.notations.sort { $0.notation.branch.localizedStandardCompare($1.notation.branch) == .orderedAscending }
        }
        outline.reloadData()
        outline.expandItem(nil, expandChildren: true)

        let items = notationItems
        if let previous, let item = items.first(where: { $0.notation.id == previous }) {
            select(item)
        } else if !query.isEmpty, let first = items.first {
            select(first)
        } else {
            outline.deselectAll(nil)
        }
        selectionChanged()
    }

    static func matches(_ notation: Notation, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return notation.branch.localizedCaseInsensitiveContains(query)
            || notation.projectName.localizedCaseInsensitiveContains(query)
    }

    private var notationItems: [NotationsNotationItem] {
        roots.flatMap(\.notations)
    }

    // MARK: - Selection and keys

    private func select(_ item: NotationsNotationItem) {
        let row = outline.row(forItem: item)
        guard row >= 0 else { return }
        outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outline.scrollRowToVisible(row)
    }

    /// Moves to the next notation row up or down, stepping over the project
    /// section rows: a project has no details to show.
    private func moveSelection(by delta: Int) {
        let rows = outline.numberOfRows
        guard rows > 0 else { return }
        var row = outline.selectedRow < 0 ? (delta > 0 ? -1 : rows) : outline.selectedRow
        repeat {
            row += delta
            guard row >= 0, row < rows else { return }
        } while !(outline.item(atRow: row) is NotationsNotationItem)
        outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outline.scrollRowToVisible(row)
    }

    /// The filter field's keys: ↑ and ↓ move the selection, Return goes to
    /// the project. Answers whether it took the key.
    func handleFilterCommand(_ commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            goToSelectedProject()
            return true
        case #selector(NSResponder.moveDown(_:)):
            moveSelection(by: 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            moveSelection(by: -1)
            return true
        default:
            return false
        }
    }

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if (event.keyCode == 36 || event.keyCode == 76)
            && modifiers.subtracting([.numericPad, .function]).isEmpty {
            insertNewline(nil)
        } else {
            super.keyDown(with: event)
        }
    }

    override func insertNewline(_ sender: Any?) {
        goToSelectedProject()
    }

    /// Only an active notation's branch is somewhere to go.
    private func goToSelectedProject() {
        guard let notation = selectedNotation, notation.state == .active else { return }
        onGoToProject?(notation)
    }

    @objc private func rowDoubleClicked(_ sender: Any?) {
        let row = outline.clickedRow
        guard row >= 0 else { return }
        if let group = outline.item(atRow: row) as? NotationsProjectItem {
            if outline.isItemExpanded(group) { outline.collapseItem(group) } else { outline.expandItem(group) }
            return
        }
        goToSelectedProject()
    }

    @objc private func filterChanged(_ sender: Any?) {
        setFilter(searchField.stringValue)
    }

    private func setFilter(_ text: String) {
        guard text != filterText else { return }
        filterText = text
        applyFilter()
    }

    private func selectionChanged() {
        updateRemoveButton()
        onSelectionChange?(selectedNotation)
    }

    private func updateRemoveButton() {
        removeButton.isEnabled = state == .archived && selectedNotation?.state == .archived
    }

    // MARK: - Delete

    @objc private func removeSelected(_ sender: Any?) {
        guard state == .archived, let notation = selectedNotation, notation.state == .archived,
              let window = view.window else { return }
        let alert = NSAlert()
        alert.messageText = "Delete the notation for “\(notation.branch)”?"
        alert.informativeText = "The notes for \(notation.branch) in \(notation.projectName) are deleted for good."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        let store = store
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            Task.detached(priority: .userInitiated) {
                do {
                    try store.deleteArchived(id: notation.id)
                } catch {
                    NotationsListViewController.logger.error(
                        "Deleting notation \(notation.id.uuidString) failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Filter field

extension NotationsListViewController: NSSearchFieldDelegate {

    func controlTextDidChange(_ notification: Notification) {
        setFilter(searchField.stringValue)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        handleFilterCommand(commandSelector)
    }
}

// MARK: - Outline

extension NotationsListViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item else { return roots.count }
        return (item as? NotationsProjectItem)?.notations.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item else { return roots[index] }
        guard let group = item as? NotationsProjectItem else { return NSNull() }
        return group.notations[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        item is NotationsProjectItem
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        ThemedTableRowView()
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let group = item as? NotationsProjectItem {
            return NotationsRowView(title: group.name, symbol: "shippingbox.fill", isSection: true, goAction: nil)
        }
        guard let row = item as? NotationsNotationItem else { return nil }
        let notation = row.notation
        let go: (() -> Void)? = notation.state == .active
            ? { [weak self] in self?.onGoToProject?(notation) }
            : nil
        return NotationsRowView(title: notation.branch, symbol: "arrow.triangle.branch", isSection: false,
                                goAction: go)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        item is NotationsNotationItem
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        selectionChanged()
    }
}

extension NotationsListViewController: Loggable {
    nonisolated static let logger = makeLogger()
}

/// A row: an icon and a name, and on an active notation a right-justified
/// go-to-project button.
@MainActor
private final class NotationsRowView: NSView {

    private let goAction: (() -> Void)?

    init(title: String, symbol: String, isSection: Bool, goAction: (() -> Void)?) {
        self.goAction = goAction
        super.init(frame: .zero)

        let icon = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage())
        icon.contentTintColor = resolvedThemeScope.palette.nsColor(isSection ? .accent : .secondaryText)
        icon.setContentHuggingPriority(.required, for: .horizontal)

        let label = ThemedLabel(string: title, role: .primaryText, textRole: isSection ? .caption : .body,
                                weight: isSection ? .semibold : nil)
        label.lineBreakMode = .byTruncatingMiddle
        label.cell?.usesSingleLineMode = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        var views: [NSView] = [icon, label]
        if goAction != nil {
            let spacer = NSView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            let button = NSButton(
                image: NSImage(systemSymbolName: "arrow.forward.circle", accessibilityDescription: "Go to Project")
                    ?? NSImage(),
                target: nil, action: nil)
            button.target = self
            button.action = #selector(goPressed(_:))
            button.isBordered = false
            button.bezelStyle = .accessoryBarAction
            button.toolTip = "Go to Project"
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.accessibilityID("notations.row.go")
            button.observeTheme { button, palette in
                button.contentTintColor = palette.nsColor(.accent)
            }
            views.append(contentsOf: [spacer, button])
        }

        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func goPressed(_ sender: Any?) {
        goAction?()
    }
}
