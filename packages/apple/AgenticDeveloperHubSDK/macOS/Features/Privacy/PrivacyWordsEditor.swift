import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The sheet that edits the privacy words: a resizable table of words — on
/// or off, the real word, what it is shown as, and the sites it applies on
/// (comma-separated ``PrivacySitePattern``s) — each word edited in place,
/// with add and remove beneath it and Save and Cancel under that. Tab moves
/// across a row's text cells and on to the next row's; Shift-Tab goes back.
///
/// Edits are a draft until Save, which writes them to the keychain through
/// the vault — Cancel leaves the words as they were. Save does not ask the
/// user to authenticate: whoever opens this has just made them, and the vault
/// must already hold the words.
///
/// It shows every word wherever it is opened, so every word's sites can be
/// seen and changed. Where it is opened decides only where a new word starts:
/// on the page's site (`google.com/*`) from a web page, on `*` from global
/// settings or a private terminal.
///
/// Everything in it sits inside a ``ConcealedContainerView``, revealed for as
/// long as the sheet is up, so neither the accessibility API nor a screen
/// capture can read the words off it; and the sheet's window answers the
/// accessibility focus question with itself, so the field being typed in is
/// not named either.
@MainActor
public final class PrivacyWordsEditor: NSObject {

    private struct DraftRow {
        let id = UUID().uuidString
        var word: PrivacyWord
    }

    private enum Column {
        static let enabled = "enabled"
        static let real = "real"
        static let alias = "alias"
        static let sites = "sites"
        /// The text columns, in Tab order.
        static let tabOrder = [real, alias, sites]
    }

    private let vault: PrivacyWordsVault
    /// The sites a new word starts on.
    private let newWordSite: String
    /// The rows the table shows, in order.
    private var rows: [DraftRow]
    private let card: ComposableSettings.EditableTableCard
    private let window: NSWindow
    private weak var parentWindow: NSWindow?
    /// Keeps the editor alive while its sheet is up: nothing else holds it.
    private var retainedSelf: PrivacyWordsEditor?
    private var tabObserver: NSObjectProtocol?

    /// Opens the editor as a sheet on `parentWindow`.
    ///
    /// - Parameter newWordSite: The site pattern a word added here starts on:
    ///   the page's (`PrivacySitePattern.defaultPattern(for:)`) from a web
    ///   page, `*` (the default) from anywhere else.
    public static func present(
        vault: PrivacyWordsVault, on parentWindow: NSWindow,
        newWordSite: String = PrivacySitePattern.everywhere
    ) {
        let editor = PrivacyWordsEditor(vault: vault, parentWindow: parentWindow, newWordSite: newWordSite)
        editor.retainedSelf = editor
        parentWindow.beginSheet(editor.window)
        editor.beginEditingFirstRowIfEmpty()
    }

    private init(vault: PrivacyWordsVault, parentWindow: NSWindow, newWordSite: String) {
        precondition(vault.isLoaded, "The privacy words editor opened without the words loaded.")
        self.vault = vault
        self.newWordSite = newWordSite
        self.parentWindow = parentWindow
        rows = (vault.words ?? []).map { DraftRow(word: $0) }
        card = ComposableSettings.EditableTableCard(
            title: "Privacy Words",
            columns: [
                .init(id: Column.enabled, title: "Enabled", width: 64, kind: .toggle,
                      headerToolTip: "Off keeps the word but applies it nowhere."),
                .init(id: Column.real, title: "Real Word", width: 170, kind: .text(editable: true)),
                .init(id: Column.alias, title: "Shown As", width: 170, kind: .text(editable: true)),
                .init(id: Column.sites, title: "Sites", width: 200, kind: .text(editable: true),
                      headerToolTip: "Where the word applies, comma-separated: * is everywhere, "
                        + "private terminals included; google.com/* every page on google.com; "
                        + "foo.com/hi/* the pages under foo.com/hi; *.google.com any subdomain; "
                        + "localhost:3000/* one port. An address pasted whole matches its page. "
                        + "Left empty, it is *.")
            ],
            emptyMessage: "No privacy words yet — add one with +.",
            visibleRows: 8,
            accessibilityPrefix: "privacyWords")
        window = ConcealedSheetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 420),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false)
        super.init()
        window.title = "Privacy Words"
        window.contentMinSize = NSSize(width: 480, height: 260)
        window.contentView = makeContent()
        fixToggleColumnWidths()
        wireCard()
        observeTab()
        reloadRows()
    }

    // MARK: - Layout

    private func makeContent() -> NSView {
        let concealed = ConcealedContainerView()
        concealed.isRevealed = true

        let tableArea = ComposableSettings.TableFillingView(card: card)
        tableArea.translatesAutoresizingMaskIntoConstraints = false

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.bezelStyle = .rounded
        cancel.keyEquivalent = "\u{1b}"
        let save = NSButton(title: "Save", target: self, action: #selector(save(_:)))
        save.bezelStyle = .rounded
        save.keyEquivalent = "\r"
        let buttons = NSStackView(views: [cancel, save])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        buttons.translatesAutoresizingMaskIntoConstraints = false

        for view in [tableArea, buttons] { concealed.addSubview(view) }
        let margin: CGFloat = 20
        NSLayoutConstraint.activate([
            tableArea.topAnchor.constraint(equalTo: concealed.topAnchor, constant: margin),
            tableArea.leadingAnchor.constraint(equalTo: concealed.leadingAnchor, constant: margin),
            concealed.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: margin),

            buttons.topAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: 16),
            concealed.trailingAnchor.constraint(equalTo: buttons.trailingAnchor, constant: margin),
            concealed.bottomAnchor.constraint(equalTo: buttons.bottomAnchor, constant: margin)
        ])
        return concealed
    }

    /// The checkbox column keeps its width, so the width the sheet gains
    /// when it is resized goes to the text columns.
    private func fixToggleColumnWidths() {
        for id in [Column.enabled] {
            guard let column = card.tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id))
            else { continue }
            column.resizingMask = []
            column.minWidth = column.width
            column.maxWidth = column.width
        }
    }

    // MARK: - The draft

    private func wireCard() {
        card.onAdd = { [weak self] in self?.addRow() }
        card.onRemove = { [weak self] id in
            self?.rows.removeAll { $0.id == id }
            self?.reloadRows()
        }
        card.onEdit = { [weak self] id, column, value in
            guard let self, let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            let text = value.trimmingCharacters(in: .whitespaces)
            switch column {
            case Column.alias: self.rows[index].word.alias = text
            case Column.sites: self.rows[index].word.sites = PrivacySitePattern.parse(text)
            default: self.rows[index].word.real = text
            }
            self.reloadRows()
        }
        card.onToggle = { [weak self] id, column, isOn in
            guard let self, column == Column.enabled,
                  let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            self.rows[index].word.isEnabled = isOn
            self.reloadRows()
        }
    }

    private func reloadRows() {
        card.setRows(rows.map { row in
            ComposableSettings.EditableTableRow(
                id: row.id,
                cells: [
                    Column.enabled: .toggle(row.word.isEnabled),
                    Column.real: .text(row.word.real),
                    Column.alias: .text(row.word.alias),
                    Column.sites: .text(PrivacySitePattern.format(row.word.sites))
                ],
                // Half a pair is dropped on save; the tint says so before
                // then. An emptied Sites cell needs no tint: the word takes
                // `*` (`PrivacyWord.sites` is never empty), and the cell
                // shows it at once.
                isFlagged: row.word.alias.isEmpty != row.word.real.isEmpty)
        })
    }

    private func addRow() {
        rows.append(DraftRow(word: PrivacyWord(alias: "", real: "", sites: [newWordSite])))
        reloadRows()
        beginEditing(row: rows.count - 1, column: Column.real)
    }

    private func beginEditingFirstRowIfEmpty() {
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
    /// skips from the table to the buttons. Watching each cell's edit end for
    /// a Tab or Shift-Tab, the editor moves to the next or previous word cell
    /// instead — across a row, then on to the next row (back to the previous
    /// one), stopping at either end of the table.
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

    // MARK: - Save and Cancel

    @objc private func save(_ sender: Any?) {
        // A cell still being typed in commits by losing focus.
        window.makeFirstResponder(nil)
        do {
            try vault.save(rows.map(\.word))
            close()
        } catch {
            let alert = NSAlert()
            alert.messageText = "The privacy words could not be saved."
            alert.informativeText = error.localizedDescription
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
    }

    @objc private func cancel(_ sender: Any?) {
        close()
    }

    private func close() {
        if let tabObserver { NotificationCenter.default.removeObserver(tabObserver) }
        tabObserver = nil
        // The draft goes with the sheet: nothing typed here outlives it.
        rows.removeAll()
        card.setRows([])
        parentWindow?.endSheet(window)
        window.orderOut(nil)
        retainedSelf = nil
    }
}

/// The sheet's window: whatever has focus inside it, the accessibility API is
/// told the window itself is focused, so the word being typed is never named.
@MainActor
private final class ConcealedSheetWindow: NSWindow {
    override var accessibilityFocusedUIElement: Any? { self }
}
