import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Records every delegate call in order: the selected item's path, or nil.
@MainActor
private final class RecordingFileListDelegate: GitFileListDelegate {
    private(set) var events: [String?] = []
    private(set) var items: [GitFileListItem?] = []
    func fileList(_ list: GitFileListViewController, didSelect item: GitFileListItem?) {
        events.append(item?.path)
        items.append(item)
    }
}

@Suite("GitFileListViewController")
@MainActor
struct GitFileListViewControllerTests {

    private static func item(_ path: String, _ status: GitFileStatus, from old: String? = nil) -> GitFileListItem {
        GitFileListItem(path: path, oldPath: old, status: status)
    }

    private func cell(_ list: GitFileListViewController, row: Int) -> GitFileListCellView? {
        list.tableView(list.tableView, viewFor: list.tableView.tableColumns.first, row: row) as? GitFileListCellView
    }

    private func select(_ list: GitFileListViewController, row: Int) {
        list.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    @Test("the identifier names the root, scroll view and table, and the table is one headerless column")
    func identifiers() {
        let list = GitFileListViewController(identifier: "commit")
        list.loadViewIfNeeded()
        #expect(list.view.accessibilityIdentifier() == "git.fileList.commit")
        #expect(list.tableView.accessibilityIdentifier() == "git.fileList.commit.table")
        #expect(list.tableView.enclosingScrollView?.accessibilityIdentifier() == "git.fileList.commit.scroll")
        #expect(list.tableView.tableColumns.count == 1)
        #expect(list.tableView.headerView == nil)
        #expect(list.numberOfRows(in: list.tableView) == 0)
    }

    @Test("each row shows the status letter in its colour, the file type's icon and the title")
    func rows() throws {
        let list = GitFileListViewController(identifier: "staged")
        list.files = [
            Self.item("Sources/App.swift", .modified),
            Self.item("README.md", .added),
            Self.item("Makefile", .deleted),
            Self.item("ünï cødé/a b.json", .renamed, from: "x.json"),
            Self.item("line\nbreak", .added)
        ]
        list.loadViewIfNeeded()
        #expect(list.numberOfRows(in: list.tableView) == 5)

        let expected: [(String, NSColor, String, String)] = [
            ("M", .systemOrange, "swift", "Sources/App.swift"),
            ("A", .systemGreen, "doc.richtext", "README.md"),
            ("D", .systemRed, "doc", "Makefile"),
            ("R", .systemBlue, "curlybraces", "x.json → ünï cødé/a b.json"),
            ("A", .systemGreen, "doc", "line\nbreak")
        ]
        for (row, (letter, color, icon, title)) in expected.enumerated() {
            let cell = try #require(cell(list, row: row))
            #expect(cell.statusLabel.stringValue == letter)
            #expect(cell.statusLabel.textColor == color)
            #expect(cell.iconView.symbolName == icon)
            #expect(cell.titleLabel.stringValue == title)
            #expect(cell.titleLabel.toolTip == title)
            #expect(cell.titleLabel.lineBreakMode == .byTruncatingMiddle)
            #expect(cell.titleLabel.usesSingleLineMode)
            #expect(cell.titleLabel.maximumNumberOfLines == 1)
            #expect(cell.accessibilityIdentifier() == "git.fileList.file")
            #expect(cell.statusLabel.accessibilityIdentifier() == "git.fileList.status")
            #expect(cell.iconView.accessibilityIdentifier() == "git.fileList.icon")
            #expect(cell.titleLabel.accessibilityIdentifier() == "git.fileList.title")
        }
        #expect(try #require(cell(list, row: 0)).statusLabel.accessibilityLabel() == "modified")
        #expect(try #require(cell(list, row: 0)).stack.accessibilityIdentifier() == "git.fileList.fileStack")
        let rowView = list.tableView(list.tableView, rowViewForRow: 0)
        #expect(rowView?.accessibilityIdentifier() == "git.fileList.row")
    }

    @Test("a path with no extension, or a dot file, gets the doc icon")
    func iconFallback() {
        #expect(GitFileListCellView.iconName(for: "Makefile") == "doc")
        #expect(GitFileListCellView.iconName(for: ".gitignore") == "doc")
        #expect(GitFileListCellView.iconName(for: "dir/Thing.SWIFT") == "swift")
    }

    @Test("selection reports each item once, clearing reports nil, clearSelection() is silent")
    func selection() {
        let list = GitFileListViewController(identifier: "commit")
        let delegate = RecordingFileListDelegate()
        list.delegate = delegate
        list.files = [Self.item("a", .modified), Self.item("b", .added)]
        list.loadViewIfNeeded()

        select(list, row: 1)
        #expect(delegate.events == ["b"])
        select(list, row: 1)
        #expect(delegate.events == ["b"])
        list.tableView.deselectAll(nil)
        #expect(delegate.events == ["b", nil])

        select(list, row: 0)
        list.clearSelection()
        #expect(delegate.events == ["b", nil, "a"])
        #expect(list.tableView.selectedRow == -1)
        // Selecting the same item again after a silent clear is a new selection.
        select(list, row: 0)
        #expect(delegate.events == ["b", nil, "a", "a"])
    }

    @Test("setting files keeps a surviving selection silently and reports nil once when it goes")
    func filesChange() {
        let list = GitFileListViewController(identifier: "commit")
        let delegate = RecordingFileListDelegate()
        list.delegate = delegate
        list.files = [Self.item("a", .modified), Self.item("b", .added)]
        list.loadViewIfNeeded()

        select(list, row: 1)
        #expect(delegate.events == ["b"])

        list.files = [Self.item("new", .added), Self.item("a", .modified), Self.item("b", .added)]
        #expect(delegate.events == ["b"])
        #expect(list.tableView.selectedRow == 2)

        list.files = [Self.item("a", .modified)]
        #expect(delegate.events == ["b", nil])
        #expect(list.tableView.selectedRow == -1)

        list.files = []
        #expect(delegate.events == ["b", nil])
    }

    @Test("a surviving selection whose status changes is reported again as the new item")
    func survivorStatusChange() {
        let list = GitFileListViewController(identifier: "unstaged")
        let delegate = RecordingFileListDelegate()
        list.delegate = delegate
        list.files = [Self.item("a", .untracked)]
        list.loadViewIfNeeded()
        select(list, row: 0)
        list.files = [Self.item("a", .added)]
        #expect(delegate.items == [Self.item("a", .untracked), Self.item("a", .added)])
        #expect(list.tableView.selectedRow == 0)
        list.files = [Self.item("a", .added)]
        #expect(delegate.items.count == 2)
    }

    @Test("files set before the view loads are shown when it loads")
    func filesBeforeLoad() {
        let list = GitFileListViewController(identifier: "unstaged")
        list.files = [Self.item("a", .untracked)]
        list.loadViewIfNeeded()
        #expect(list.numberOfRows(in: list.tableView) == 1)
    }
}
