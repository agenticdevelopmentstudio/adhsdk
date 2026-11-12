import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The sheet that edits the privacy words: a resizable table of words — on
/// or off, the real word, what it is shown as, and whether it is global —
/// each word edited in place, with add and remove beneath it and Save and
/// Cancel under that. Tab moves from the real word to what it is shown as and
/// on to the next row's real word; Shift-Tab goes back.
///
/// Edits are a draft until Save, which writes them to the keychain through
/// the vault — Cancel leaves the words as they were. Save does not ask the
/// user to authenticate: whoever opens this has just made them, and the vault
/// must already hold the words.
///
/// Where it is opened decides which words it shows (``PrivacyWord``):
/// - **Global** (`paneID` nil: the Web Browser settings, a private terminal,
///   a browser pane with no stable id): the global words. Every row's Global
///   box is checked and cannot be changed.
/// - **A browser pane**: the global words and that pane's own. A word added
///   here belongs to the pane; checking Global makes it apply to every
///   browser, and unchecking it gives it to this pane.
///
/// Words the context does not show — another pane's — are kept as they are
/// and written back with the rest.
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
        static let global = "global"
        /// The text columns, in Tab order.
        static let tabOrder = [real, alias]
    }

    private let vault: PrivacyWordsVault
    /// The pane the editor was opened for; nil for the global words.
    private let paneID: String?
    /// The rows the table shows, in order.
    private var rows: [DraftRow]
    /// The words this context does not show, written back untouched on Save.
    private let hiddenWords: [PrivacyWord]
    private let card: ComposableSettings.EditableTableCard
    private let window: NSWindow
    private weak var parentWindow: NSWindow?
    /// Keeps the editor alive while its sheet is up: nothing else holds it.
    private var retainedSelf: PrivacyWordsEditor?
    private var tabObserver: NSObjectProtocol?

    /// Opens the editor as a sheet on `parentWindow`.
    ///
    /// - Parameter paneID: The browser pane whose words to edit alongside the
    ///   global ones (its layout node id), or nil for the global words alone.
    public static func present(vault: PrivacyWordsVault, on parentWindow: NSWindow, paneID: String? = nil) {
        let editor = PrivacyWordsEditor(vault: vault, parentWindow: parentWindow, paneID: paneID)
        editor.retainedSelf = editor
        parentWindow.beginSheet(editor.window)
        editor.beginEditingFirstRowIfEmpty()
    }

    private init(vault: PrivacyWordsVault, parentWindow: NSWindow, paneID: String?) {
        precondition(vault.isLoaded, "The privacy words editor opened without the words loaded.")
        self.vault = vault
        self.paneID = paneID
        self.parentWindow = parentWindow
        let words = vault.words ?? []
        let shows: (PrivacyWord) -> Bool = { word in
            word.isGlobal || (paneID != nil && word.paneID == paneID)
        }
        rows = words.filter(shows).map { DraftRow(word: $0) }
        hiddenWords = words.filter { !shows($0) }
        card = ComposableSettings.EditableTableCard(
            title: "Privacy Words",
            columns: [
                .init(id: Column.enabled, title: "Enabled", width: 64, kind: .toggle,
                      headerToolTip: "Off keeps the word but applies it nowhere."),
                .init(id: Column.real, title: "Real Word", width: 200, kind: .text(editable: true)),
                .init(id: Column.alias, title: "Shown As", width: 200, kind: .text(editable: true)),
                .init(id: Column.global, title: "Global", width: 56, kind: .toggle,
                      headerToolTip: "On applies the word to every web browser; "
                        + "off, only to the browser it was defined in.")
            ],
            emptyMessage: "No privacy words yet — add one with +.",
            visibleRows: 8,
            accessibilityPrefix: "privacyWords")
        window = ConcealedSheetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 420),
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

    /// The two checkbox columns keep their width, so the width the sheet
    /// gains when it is resized goes to the word columns.
    private func fixToggleColumnWidths() {
        for id in [Column.enabled, Column.global] {
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
            let word = value.trimmingCharacters(in: .whitespaces)
            if column == Column.alias { self.rows[index].word.alias = word } else { self.rows[index].word.real = word }
            self.reloadRows()
        }
        card.onToggle = { [weak self] id, column, isOn in
            guard let self, let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            switch column {
            case Column.enabled:
                self.rows[index].word.isEnabled = isOn
            case Column.global:
                // Only a pane's editor offers the box (it is read-only in the
                // global one). Unchecked, the word belongs to this pane.
                guard let paneID = self.paneID else { break }
                self.rows[index].word.isGlobal = isOn
                if !isOn { self.rows[index].word.paneID = paneID }
            default:
                break
            }
            self.reloadRows()
        }
    }

    private func reloadRows() {
        let globalIsFixed = paneID == nil
        card.setRows(rows.map { row in
            ComposableSettings.EditableTableRow(
                id: row.id,
                cells: [
                    Column.enabled: .toggle(row.word.isEnabled),
                    Column.real: .text(row.word.real),
                    Column.alias: .text(row.word.alias),
                    Column.global: .toggle(globalIsFixed || row.word.isGlobal)
                ],
                // Half a pair is dropped on save; the tint says so before then.
                isFlagged: row.word.alias.isEmpty != row.word.real.isEmpty,
                readOnlyColumns: globalIsFixed ? [Column.global] : [])
        })
    }

    private func addRow() {
        rows.append(DraftRow(word: PrivacyWord(alias: "", real: "", isGlobal: paneID == nil, paneID: paneID)))
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
        let shown = rows.map { row -> PrivacyWord in
            var word = row.word
            if paneID == nil { word.isGlobal = true }
            return word
        }
        do {
            try vault.save(shown + hiddenWords)
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
