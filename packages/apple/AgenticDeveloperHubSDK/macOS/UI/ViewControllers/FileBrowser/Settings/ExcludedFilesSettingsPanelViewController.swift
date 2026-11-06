import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// Settings panel for what the file browser leaves out: a list of
/// `.gitignore`-style patterns, each edited in place, with `+` and `−` beneath.
///
/// There is no draft and no Save. Every add, edit and removal is written to
/// `UserSettings.fileBrowserExcludedPatterns` as it happens, and every file
/// browser watches that setting, so the trees on screen change with the list.
@MainActor
public final class ExcludedFilesSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    private enum Column {
        static let pattern = "pattern"
    }

    /// One row of the list. The id is the row's own, not its index or its
    /// text: two rows may hold the same pattern, and a row being typed in must
    /// keep its identity while its text changes.
    private struct Row {
        let id = UUID().uuidString
        var pattern: String
    }

    private let setting: UserSetting<[String]>
    private var observer: UserSettingObserver<[String]>?
    private var rows: [Row]

    /// The patterns this panel last wrote, so the echo of its own write coming
    /// back through the observer does not rebuild the rows (and their ids)
    /// underneath an edit.
    private var lastWritten: [String]

    private lazy var card = ComposableSettings.EditableTableCard(
        title: "Excluded",
        columns: [
            .init(id: Column.pattern, title: "Pattern", width: 320, kind: .text(editable: true))
        ],
        emptyMessage: "Nothing is excluded — add a pattern with +.",
        accessibilityPrefix: "fileBrowser.excluded")

    /// The view is a table that fills the panel and scrolls itself; the detail
    /// pane must not wrap it in a second scroll view.
    public override var hostsOwnScroll: Bool { true }

    public init(setting: UserSetting<[String]> = UserSettings.fileBrowserExcludedPatterns) {
        self.setting = setting
        self.rows = setting.currentValue.map { Row(pattern: $0) }
        self.lastWritten = setting.currentValue
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Excluded",
            icon: NSImage(systemSymbolName: "eye.slash", accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Excluded",
                body: "What the file browser leaves out of its tree. Each entry is a pattern, "
                    + "written the way a line of a .gitignore file is, and matches files or "
                    + "directories. A change shows in every open file browser at once."
            ),
            .init(
                title: "Pattern Syntax",
                body: "A name with no slash matches at any depth: `*.log`, `node_modules`, "
                    + "`.DS_Store`. A trailing slash matches directories only: `build/`. A "
                    + "slash at the start or in the middle anchors the pattern to the root "
                    + "of the browser: `/dist`, `docs/*.pdf`. `*` matches anything but a "
                    + "slash, `?` a single character, `[abc]` one of a set, and `**` any "
                    + "number of directories: `**/generated`, `out/**`. A pattern starting "
                    + "with `!` brings back something an earlier pattern left out; the last "
                    + "pattern that matches decides. Lines starting with `#` are comments."
            ),
            .init(
                title: "Editing the List",
                body: "Click an entry to edit it in place, and press Return to keep the "
                    + "change. The plus button adds an entry and starts editing it; the minus "
                    + "button removes the selected one. An entry left empty is removed."
            )
        ])
    }

    public override var searchKeywords: [String] {
        ["exclude", "excluded", "ignore", "gitignore", "hidden", "hide", "filter", "pattern"]
    }

    public override func loadView() {
        let container = NSView()
        let tableArea = ComposableSettings.TableFillingView(card: card)
        tableArea.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tableArea)
        let inset = ComposableSettings.SettingsLayout.default[.panelInset]
        NSLayoutConstraint.activate([
            tableArea.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            tableArea.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            container.trailingAnchor.constraint(equalTo: tableArea.trailingAnchor, constant: inset),
            container.bottomAnchor.constraint(equalTo: tableArea.bottomAnchor, constant: inset)
        ])
        view = container

        wireCard()
        reloadRows()
        // Another panel, a sync or a script can change the setting too; the
        // list follows it, unless the change is this panel's own write.
        observer = UserSettingObserver(setting) { [weak self] patterns in
            guard let self, patterns != self.lastWritten else { return }
            self.lastWritten = patterns
            self.rows = patterns.map { Row(pattern: $0) }
            self.reloadRows()
        }
    }

    // MARK: - The list

    private func wireCard() {
        card.onAdd = { [weak self] in self?.addRow() }
        card.onRemove = { [weak self] id in
            guard let self else { return }
            self.rows.removeAll { $0.id == id }
            self.commit()
        }
        card.onEdit = { [weak self] id, _, value in
            guard let self, let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
            let pattern = value.trimmingCharacters(in: .whitespaces)
            if pattern.isEmpty {
                self.rows.remove(at: index)
            } else {
                self.rows[index].pattern = pattern
            }
            self.commit()
        }
    }

    /// Writes the list and redraws it. An empty row is still being typed in,
    /// so it stays on screen but is never written.
    private func commit() {
        let patterns = rows.map(\.pattern).filter { !$0.isEmpty }
        lastWritten = patterns
        setting.value = patterns
        reloadRows()
    }

    private func reloadRows() {
        card.setRows(rows.map { row in
            ComposableSettings.EditableTableRow(id: row.id, cells: [Column.pattern: .text(row.pattern)])
        })
    }

    private func addRow() {
        // One empty row at a time: a second `+` goes back to the first.
        if let blank = rows.firstIndex(where: { $0.pattern.isEmpty }) {
            beginEditing(row: blank)
            return
        }
        rows.append(Row(pattern: ""))
        reloadRows()
        beginEditing(row: rows.count - 1)
    }

    private func beginEditing(row: Int) {
        let table = card.tableView
        guard row < table.numberOfRows else { return }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        table.scrollRowToVisible(row)
        table.editColumn(0, row: row, with: nil, select: true)
    }
}
