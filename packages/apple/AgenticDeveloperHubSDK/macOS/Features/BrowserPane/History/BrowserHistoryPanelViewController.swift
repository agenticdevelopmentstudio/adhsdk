//
//  BrowserHistoryPanelViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKDatabase

/// The browsing history as a filter over a list, in the Settings sidebar's
/// style (`TopicListViewController`): a search field and the header buttons
/// above a source-style list of visits, newest first.
///
/// Reusable on purpose: it knows its list model and the `open` callback it
/// is handed, and nothing of the window, shelf or browser that hosts it
/// (`manage-complexity-through-boundaries`). Opening a visit is the host's
/// decision — a new tab, a new window — so the panel only hands the address
/// over.
@MainActor
public final class BrowserHistoryPanelViewController: NSViewController {

    private let model: BrowserHistoryListModel
    private let open: (URL) -> Void

    private let searchField = ThemedSearchField()
    private let removeButton = NSButton()
    private let clearButton = NSButton(title: "Clear History…", target: nil, action: nil)
    private let tableView = HistoryTableView()
    private let scrollView = NSScrollView()
    private let relativeTime: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private var themeObserver: ThemePaletteObserver?
    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette

    public init(model: BrowserHistoryListModel, open: @escaping (URL) -> Void) {
        self.model = model
        self.open = open
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - View

    public override func loadView() {
        let root = NSView()

        searchField.placeholderString = "Filter History"
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(filterChanged(_:))
        searchField.sendsWholeSearchString = false
        searchField.sendsSearchStringImmediately = true
        searchField.controlSize = .small
        searchField.translatesAutoresizingMaskIntoConstraints = false
        _ = searchField.accessibilityID("browser-history.filter")

        removeButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove Selected Visits")
        removeButton.imagePosition = .imageOnly
        removeButton.bezelStyle = .accessoryBarAction
        removeButton.controlSize = .small
        removeButton.toolTip = "Remove Selected Visits"
        removeButton.setAccessibilityLabel("Remove Selected Visits")
        removeButton.target = self
        removeButton.action = #selector(removeSelected(_:))
        removeButton.isEnabled = false
        _ = removeButton.accessibilityID("browser-history.remove")

        clearButton.bezelStyle = .accessoryBarAction
        clearButton.controlSize = .small
        clearButton.toolTip = "Clear All History"
        clearButton.target = self
        clearButton.action = #selector(clearHistory(_:))
        _ = clearButton.accessibilityID("browser-history.clear")

        let header = NSStackView(views: [searchField, removeButton, clearButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 6
        header.translatesAutoresizingMaskIntoConstraints = false
        searchField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        removeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BrowserHistoryColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        // `.automatic`, as the Settings sidebar uses: `.sourceList` brings a
        // visual-effect material that ignores the theme.
        tableView.style = .automatic
        tableView.focusRingType = .none
        tableView.rowSizeStyle = .custom
        tableView.rowHeight = 38
        tableView.allowsMultipleSelection = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(openClicked(_:))
        tableView.onReturn = { [weak self] in self?.openSelected() }
        tableView.setAccessibilityLabel("History")
        _ = tableView.accessibilityID("browser-history.list")

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(header)
        root.addSubview(scrollView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor, constant: 10),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -10),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root

        themeObserver = ThemePaletteObserver(host: view) { [weak self] palette in
            self?.applyTheme(palette)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        model.onWillChange = { [weak self] in self?.modelWillChange() }
        model.onChange = { [weak self] in self?.modelChanged() }
        searchField.stringValue = model.filter
        Task { await model.reload() }
    }

    /// Each time the panel comes back, so its relative times are current.
    public override func viewWillAppear() {
        super.viewWillAppear()
        Task { await model.reload() }
    }

    private func applyTheme(_ palette: SemanticPalette) {
        self.palette = palette
        let background = palette.windowBackgroundColor
        view.wantsLayer = true
        view.layer?.backgroundColor = background.cgColor
        scrollView.backgroundColor = background
        tableView.backgroundColor = background
        searchField.applyTheme(palette)
        reloadKeepingSelection(Set(selectedVisitIDs))
    }

    // MARK: - Model

    /// The ids selected when the model last said it was about to replace
    /// its visits, read while the table's row indexes still name them.
    private var selectionBeforeChange: Set<Int64>?

    private func modelWillChange() {
        selectionBeforeChange = Set(selectedVisitIDs)
    }

    private func modelChanged() {
        let selected = selectionBeforeChange ?? []
        selectionBeforeChange = nil
        reloadKeepingSelection(selected)
    }

    /// Reloads the rows and selects again whichever of the visits `selected`
    /// names are still listed — by id, never by row, since a visit recorded
    /// at the top moves every other one down.
    private func reloadKeepingSelection(_ selected: Set<Int64>) {
        tableView.reloadData()
        let rows = IndexSet(model.visits.indices.filter { selected.contains(model.visits[$0].id) })
        tableView.selectRowIndexes(rows, byExtendingSelection: false)
        updateButtons()
    }

    private var selectedVisits: [BrowserVisit] {
        tableView.selectedRowIndexes.compactMap { row in
            model.visits.indices.contains(row) ? model.visits[row] : nil
        }
    }

    /// The selected visits' ids, in list order.
    var selectedVisitIDs: [Int64] {
        selectedVisits.map(\.id)
    }

    private func updateButtons() {
        removeButton.isEnabled = !tableView.selectedRowIndexes.isEmpty
    }

    // MARK: - Actions

    @objc private func filterChanged(_ sender: Any?) {
        model.filter = searchField.stringValue
    }

    @objc private func removeSelected(_ sender: Any?) {
        let ids = selectedVisits.map(\.id)
        guard !ids.isEmpty else { return }
        Task { await model.remove(ids) }
    }

    @objc private func clearHistory(_ sender: Any?) {
        ComposableSettings.Alerts.confirmDestructive(
            "Clear all browsing history?",
            detail: "Every recorded visit is forgotten. Cookies and site data are not affected.",
            actionTitle: "Clear History",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task { await self.model.clearAll() }
        }
    }

    /// A double-click on a selected row opens every selected visit; on any
    /// other row, that row's.
    @objc private func openClicked(_ sender: Any?) {
        let row = tableView.clickedRow
        guard model.visits.indices.contains(row) else { return }
        if tableView.selectedRowIndexes.contains(row) {
            openSelected()
        } else {
            open(model.visits[row].url)
        }
    }

    /// Return: every selected visit, in list order.
    func openSelected() {
        for visit in selectedVisits { open(visit.url) }
    }

    /// Selects the rows `rows`, for a test.
    func selectRows(_ rows: IndexSet) {
        tableView.selectRowIndexes(rows, byExtendingSelection: false)
    }

    /// Puts the keyboard in the list, for a host bringing the panel up.
    public func focusList() {
        view.window?.makeFirstResponder(tableView)
    }
}

// MARK: - Filter

extension BrowserHistoryPanelViewController: NSSearchFieldDelegate {

    /// Each edit as it is made, listened to as `ProjectShelfViewController`
    /// listens to its filter, beside the field's action.
    public func controlTextDidChange(_ notification: Notification) {
        model.filter = searchField.stringValue
    }
}

// MARK: - Table

extension BrowserHistoryPanelViewController: NSTableViewDataSource, NSTableViewDelegate {

    public func numberOfRows(in tableView: NSTableView) -> Int {
        model.visits.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard model.visits.indices.contains(row) else { return nil }
        let cell = (tableView.makeView(withIdentifier: HistoryVisitCell.identifier, owner: nil) as? HistoryVisitCell)
            ?? HistoryVisitCell()
        let visit = model.visits[row]
        let when = relativeTime.localizedString(for: visit.visitedAt, relativeTo: Date())
        cell.show(
            title: visit.title.isEmpty ? (visit.url.host ?? visit.url.absoluteString) : visit.title,
            address: visit.url.absoluteString,
            when: when,
            palette: palette
        )
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }
}

/// A table that reports Return, which `NSTableView` otherwise passes up the
/// responder chain unread.
@MainActor
private final class HistoryTableView: NSTableView {

    var onReturn: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Return and the keypad's Enter.
        if event.keyCode == 36 || event.keyCode == 76, !selectedRowIndexes.isEmpty {
            onReturn?()
            return
        }
        super.keyDown(with: event)
    }
}

/// One visit: its title over its address and when it happened.
@MainActor
private final class HistoryVisitCell: NSTableCellView {

    static let identifier = NSUserInterfaceItemIdentifier("BrowserHistoryVisitCell")

    private let titleLabel = NSTextField(labelWithString: "")
    private let addressLabel = NSTextField(labelWithString: "")
    private let whenLabel = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier
        for label in [titleLabel, addressLabel, whenLabel] {
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        addressLabel.lineBreakMode = .byTruncatingMiddle
        whenLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        whenLabel.setContentHuggingPriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField = titleLabel
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            addressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: whenLabel.leadingAnchor, constant: -8),

            whenLabel.firstBaselineAnchor.constraint(equalTo: addressLabel.firstBaselineAnchor),
            whenLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(title: String, address: String, when: String, palette: SemanticPalette) {
        titleLabel.stringValue = title
        addressLabel.stringValue = address
        whenLabel.stringValue = when
        titleLabel.font = palette.font(.body)
        titleLabel.textColor = palette.primaryTextColor
        for label in [addressLabel, whenLabel] {
            label.font = palette.font(.caption)
            label.textColor = palette.secondaryTextColor
        }
        setAccessibilityLabel("\(title), \(address), \(when)")
    }
}
