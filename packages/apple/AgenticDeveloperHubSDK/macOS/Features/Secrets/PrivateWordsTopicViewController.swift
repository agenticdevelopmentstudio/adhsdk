import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The Secrets window's Private Words topic: a resizable table of the
/// privacy words — on or off, the real word, what it is shown as, the sites
/// it applies on (comma-separated ``PrivacySitePattern``s) and the private
/// terminals it applies in (comma-separated ``PrivacyTerminalPattern``s) —
/// each edited in place, with add and remove beneath. Tab moves across a
/// row's text cells and on to the next row's; Shift-Tab goes back.
///
/// Every edit is saved as it is made, through the vault; there is no draft
/// and nothing to confirm. A row with only one half of its pair is kept in
/// the table, tinted, and left out of what is saved until it is whole.
///
/// The rows exist only while the window is unlocked: ``load(grant:)`` fills
/// the table from the vault's words under the grant the window unlocked
/// with, and ``unload()`` empties it, so a locked window holds no word in
/// memory. A revoked grant reads and saves nothing. A change saved by another app while it is
/// open replaces the rows, unless it is this table's own save coming back.
@MainActor
final class PrivateWordsTopicViewController: NSViewController {

    private struct Row {
        let id = UUID().uuidString
        var word: PrivacyWord
    }

    enum Column {
        static let enabled = "enabled"
        static let real = "real"
        static let alias = "alias"
        static let sites = "sites"
        static let terminals = "terminals"
        /// The text columns, in Tab order.
        static let tabOrder = [real, alias, sites, terminals]
    }

    private let vault: PrivacyWordsVault
    /// The sites a new word starts on.
    var newWordSite = PrivacySitePattern.everywhere
    private var rows: [Row] = []
    /// What this table saved last, to tell its own save from another app's
    /// when the vault's words change.
    private var lastSaved: [PrivacyWord]?
    private let card: ComposableSettings.EditableTableCard
    nonisolated(unsafe) private var tabObserver: NSObjectProtocol?
    private var wordsObserver: AnyCancellable?
    /// What the window unlocked with: the only way to the words, for reading
    /// and for saving. Nil while the table is empty.
    private var grant: PrivacyWordsGrant?
    /// Shows a save that failed.
    var onSaveError: ((Error) -> Void)?

    init(vault: PrivacyWordsVault) {
        self.vault = vault
        card = ComposableSettings.EditableTableCard(
            title: "Private Words",
            columns: [
                .init(id: Column.enabled, title: "Enabled", width: 64, kind: .toggle,
                      headerToolTip: "Off keeps the word but applies it nowhere."),
                .init(id: Column.real, title: "Real Word", width: 150, kind: .text(editable: true)),
                .init(id: Column.alias, title: "Shown As", width: 150, kind: .text(editable: true)),
                .init(id: Column.sites, title: "Sites", width: 170, kind: .text(editable: true),
                      headerToolTip: "Where the word applies on the web, comma-separated: * is every "
                        + "page; google.com/* every page on google.com; foo.com/hi/* the pages under "
                        + "foo.com/hi; *.google.com any subdomain; localhost:3000/* one port. Left "
                        + "empty, it is *."),
                .init(id: Column.terminals, title: "Terminal", width: 150, kind: .text(editable: true),
                      headerToolTip: "Which private terminals the word applies in, as .gitignore "
                        + "patterns over the directory each starts in, comma-separated: * is every "
                        + "one; a name like adkitchen any directory of that name and everything in "
                        + "it; ~/work/** everything under ~/work; ! takes a directory back out. "
                        + "Left empty, none.")
            ],
            emptyMessage: "No private words yet — add one with +.",
            visibleRows: 8,
            accessibilityPrefix: "privacyWords")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let tabObserver { NotificationCenter.default.removeObserver(tabObserver) }
    }

    override func loadView() {
        let root = NSView()
        let tableArea = ComposableSettings.TableFillingView(card: card)
        tableArea.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(tableArea)
        let margin: CGFloat = 20
        NSLayoutConstraint.activate([
            tableArea.topAnchor.constraint(equalTo: root.topAnchor, constant: margin),
            tableArea.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: margin),
            root.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: margin),
            root.bottomAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: margin)
        ])
        view = root
        fixToggleColumnWidth()
        wireCard()
        observeTab()
    }

    // MARK: - Loading

    /// Fills the table from the vault's words under `grant` and follows later
    /// changes while the grant holds.
    ///
    /// - Throws: ``PrivacyWordsGrant/Revoked`` when `grant` no longer holds;
    ///   the table stays empty.
    func load(grant: PrivacyWordsGrant) throws {
        loadViewIfNeeded()
        reload(from: try vault.words(with: grant))
        self.grant = grant
        wordsObserver = vault.$words
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, let grant = self.grant,
                      let words = try? self.vault.words(with: grant), words != self.lastSaved else { return }
                self.reload(from: words)
            }
    }

    /// Commits a cell being typed in, saves, and empties the table.
    func unload() {
        commitCellEditing()
        wordsObserver = nil
        grant = nil
        rows.removeAll()
        lastSaved = nil
        if isViewLoaded { card.setRows([]) }
    }

    var isLoaded: Bool { wordsObserver != nil }

    private func reload(from words: [PrivacyWord]) {
        rows = words.map { Row(word: $0) }
        lastSaved = words
        reloadRows()
    }

    /// Ends the edit in progress, which commits and saves it.
    func commitCellEditing() {
        guard isViewLoaded, let window = view.window,
              let editor = window.firstResponder as? NSText,
              (editor.delegate as? NSView)?.isDescendant(of: card.tableView) == true else { return }
        window.makeFirstResponder(nil)
    }

    // MARK: - Saving

    private func save() {
        let kept = rows.map(\.word).filter { !$0.alias.isEmpty && !$0.real.isEmpty }
        guard kept != lastSaved, let grant else { return }
        lastSaved = kept
        do {
            try vault.save(kept, with: grant)
        } catch {
            onSaveError?(error)
        }
    }

    // MARK: - The table

    /// The checkbox column keeps its width, so the width the window gains
    /// when it is resized goes to the text columns.
    private func fixToggleColumnWidth() {
        guard let column = card.tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(Column.enabled))
        else { return }
        column.resizingMask = []
        column.minWidth = column.width
        column.maxWidth = column.width
    }

    private func wireCard() {
        card.onAdd = { [weak self] in self?.addRow() }
        card.onRemove = { [weak self] id in
            self?.rows.removeAll { $0.id == id }
            self?.changed()
        }
        card.onEdit = { [weak self] id, column, value in
            guard let self, let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            let text = value.trimmingCharacters(in: .whitespaces)
            switch column {
            case Column.alias: self.rows[index].word.alias = text
            case Column.sites: self.rows[index].word.sites = PrivacySitePattern.parse(text)
            case Column.terminals: self.rows[index].word.terminals = PrivacyTerminalPattern.parse(text)
            default: self.rows[index].word.real = text
            }
            self.changed()
        }
        card.onToggle = { [weak self] id, column, isOn in
            guard let self, column == Column.enabled,
                  let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            self.rows[index].word.isEnabled = isOn
            self.changed()
        }
    }

    private func changed() {
        reloadRows()
        save()
    }

    private func reloadRows() {
        card.setRows(rows.map { row in
            ComposableSettings.EditableTableRow(
                id: row.id,
                cells: [
                    Column.enabled: .toggle(row.word.isEnabled),
                    Column.real: .text(row.word.real),
                    Column.alias: .text(row.word.alias),
                    Column.sites: .text(PrivacySitePattern.format(row.word.sites)),
                    Column.terminals: .text(PrivacyTerminalPattern.format(row.word.terminals))
                ],
                // Half a pair is not saved; the tint says so.
                isFlagged: row.word.alias.isEmpty != row.word.real.isEmpty)
        })
    }

    private func addRow() {
        rows.append(Row(word: PrivacyWord(alias: "", real: "", sites: [newWordSite])))
        reloadRows()
        beginEditing(row: rows.count - 1, column: Column.real)
    }

    /// Opens `word`'s row with its Shown As cell editing: the row whose real
    /// word it is (ignoring case), or a new one for it on `newWordSite`.
    func replace(_ word: String) {
        let word = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return beginEditingFirstRowIfEmpty() }
        let row = Self.row(for: word, in: rows.map(\.word)) ?? {
            rows.append(Row(word: PrivacyWord(alias: "", real: word, sites: [newWordSite])))
            reloadRows()
            return rows.count - 1
        }()
        beginEditing(row: row, column: Column.alias)
    }

    /// The index of the word whose real word is `word`, ignoring case, or
    /// failing that whose alias is: a concealed page shows the alias, so a
    /// word already private is clicked as its alias.
    static func row(for word: String, in words: [PrivacyWord]) -> Int? {
        func same(_ other: String) -> Bool { other.compare(word, options: .caseInsensitive) == .orderedSame }
        return words.firstIndex { same($0.real) } ?? words.firstIndex { !$0.alias.isEmpty && same($0.alias) }
    }

    func beginEditingFirstRowIfEmpty() {
        if rows.isEmpty { addRow() }
    }

    private func beginEditing(row: Int, column columnID: String) {
        let table = card.tableView
        let column = table.column(withIdentifier: NSUserInterfaceItemIdentifier(columnID))
        guard row >= 0, row < table.numberOfRows, column >= 0 else { return }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        table.scrollRowToVisible(row)
        table.editColumn(column, row: row, with: nil, select: true)
    }

    // MARK: - Tab between cells

    /// A view-based table leaves Tab to the window's key-view loop, which
    /// skips out of the table. Watching each cell's edit end for a Tab or
    /// Shift-Tab, the topic moves to the next or previous word cell instead —
    /// across a row, then on to the next row (back to the previous one),
    /// stopping at either end of the table.
    private func observeTab() {
        tabObserver = NotificationCenter.default.addObserver(
            forName: NSControl.textDidEndEditingNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?["NSTextMovement"] as? Int else { return }
            let movement = NSTextMovement(rawValue: raw)
            guard movement == .tab || movement == .backtab else { return }
            let forward = movement == .tab
            let field = note.object as? ComposableSettings.EditableTableCellField
            MainActor.assumeIsolated {
                guard let self, let field, let binding = field.binding,
                      field.isDescendant(of: self.card.tableView) else { return }
                let rowID = binding.rowID
                let columnID = binding.columnID
                // After the card has committed the edit and applied any rows
                // it held back while the cell was being typed in.
                DispatchQueue.main.async { [weak self] in
                    self?.moveEditing(fromRow: rowID, column: columnID, forward: forward)
                }
            }
        }
    }

    private func moveEditing(fromRow rowID: String, column columnID: String, forward: Bool) {
        guard let row = rows.firstIndex(where: { $0.id == rowID }),
              let column = Column.tabOrder.firstIndex(of: columnID) else { return }
        let count = Column.tabOrder.count
        let position = row * count + column + (forward ? 1 : -1)
        guard position >= 0, position < rows.count * count else { return }
        beginEditing(row: position / count, column: Column.tabOrder[position % count])
    }
}
