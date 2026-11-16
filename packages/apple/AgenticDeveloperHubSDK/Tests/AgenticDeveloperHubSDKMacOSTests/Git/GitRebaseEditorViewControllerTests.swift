import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKCore

/// The interactive rebase editor (recipe `workspace/git/git-rebase-editor`): rows in plan
/// order, an action pop-up per row, drag to reorder, a message field for a reword, and Start
/// Rebase enabled only while the plan is valid.
@Suite("GitRebaseEditorViewController")
@MainActor
struct GitRebaseEditorViewControllerTests {

    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static func plan(_ count: Int = 3) -> GitRebasePlan {
        GitRebasePlan(onto: sha("b"), entries: (0..<count).map {
            GitRebaseEntry(commit: sha(String(format: "e%03d", $0)), subject: "commit \($0)",
                           message: "commit \($0)\n\nbody \($0)")
        })
    }

    private static func editor(_ plan: GitRebasePlan = plan()) -> GitRebaseEditorViewController {
        let editor = GitRebaseEditorViewController(plan: plan)
        editor.loadViewIfNeeded()
        return editor
    }

    private func cell<T: NSView>(_ editor: GitRebaseEditorViewController, _ column: String, row: Int) -> T? {
        let table = editor.tableView
        let tableColumn = table.tableColumns.first { $0.identifier.rawValue == column }
        return editor.tableView(table, viewFor: tableColumn, row: row) as? T
    }

    @Test("rows are the plan's entries in order, oldest at the top, with action, short sha and subject")
    func rowsInOrder() throws {
        let editor = Self.editor()
        #expect(editor.tableView.numberOfRows == 3)
        #expect(editor.tableView.tableColumns.map(\.identifier.rawValue) == ["action", "sha", "subject"])
        for row in 0..<3 {
            let action: GitRebaseActionCellView = try #require(cell(editor, "action", row: row))
            #expect(action.popUp.itemTitles == ["pick", "reword", "edit", "squash", "fixup", "drop"])
            #expect(action.popUp.titleOfSelectedItem == "pick")
            let sha: NSTextField = try #require(cell(editor, "sha", row: row))
            #expect(sha.stringValue == String(Self.sha(String(format: "e%03d", row)).prefix(8)))
            let subject: NSTextField = try #require(cell(editor, "subject", row: row))
            #expect(subject.stringValue == "commit \(row)")
            #expect(!(subject is GitRebaseMessageField))
        }
    }

    @Test("every view and control carries its accessibility id")
    func identifiers() throws {
        let editor = Self.editor()
        #expect(editor.view.accessibilityIdentifier() == "git.rebase")
        #expect(editor.tableView.accessibilityIdentifier() == "git.rebase.table")
        #expect(editor.cancelButton.accessibilityIdentifier() == "git.rebase.cancel")
        #expect(editor.startButton.accessibilityIdentifier() == "git.rebase.start")
        let action: GitRebaseActionCellView = try #require(cell(editor, "action", row: 0))
        #expect(action.popUp.accessibilityIdentifier() == "git.rebase.action")
        let sha: NSTextField = try #require(cell(editor, "sha", row: 0))
        #expect(sha.accessibilityIdentifier() == "git.rebase.sha")
        let subject: NSTextField = try #require(cell(editor, "subject", row: 0))
        #expect(subject.accessibilityIdentifier() == "git.rebase.subject")
    }

    @Test("choosing an action in a row's pop-up updates the plan")
    func popUpChangesAction() throws {
        let editor = Self.editor()
        let action: GitRebaseActionCellView = try #require(cell(editor, "action", row: 1))
        action.popUp.selectItem(withTitle: "drop")
        let item = try #require(action.popUp.selectedItem)
        _ = action.popUp.sendAction(action.popUp.action, to: action.popUp.target)
        #expect(item.title == "drop")
        #expect(editor.plan.entries.map(\.action) == [.pick, .drop, .pick])
    }

    @Test("a reword's subject cell is an editable field holding its message, and typing changes it")
    func rewordField() throws {
        let editor = Self.editor()
        editor.setAction(.reword, at: 0)
        let field: GitRebaseMessageField = try #require(cell(editor, "subject", row: 0))
        #expect(field.isEditable)
        #expect(field.stringValue == "commit 0\n\nbody 0")
        #expect(field.accessibilityIdentifier() == "git.rebase.message")
        field.stringValue = "renamed"
        field.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        #expect(editor.plan.entries[0].message == "renamed")
        #expect(editor.plan.entries[0].action == .reword)
    }

    @Test("switching to reword with no message fills it with the subject")
    func rewordWithoutMessage() {
        var plan = Self.plan()
        plan.entries[2].message = nil
        let editor = Self.editor(plan)
        editor.setAction(.reword, at: 2)
        #expect(editor.plan.entries[2].message == "commit 2")
        #expect(editor.startButton.isEnabled)
    }

    @Test("moving a row reorders the plan's entries, drop-above as the table names it")
    func moveReorders() {
        let editor = Self.editor()
        let ids = editor.plan.entries.map(\.commit)
        editor.moveEntry(from: 0, to: 3)
        #expect(editor.plan.entries.map(\.commit) == [ids[1], ids[2], ids[0]])
        editor.moveEntry(from: 2, to: 0)
        #expect(editor.plan.entries.map(\.commit) == ids)
        editor.moveEntry(from: 1, to: 1)
        editor.moveEntry(from: 1, to: 2)
        #expect(editor.plan.entries.map(\.commit) == ids, "a drop onto its own place moves nothing")
        editor.moveEntry(from: 2, to: 1)
        #expect(editor.plan.entries.map(\.commit) == [ids[0], ids[2], ids[1]])
        #expect(editor.tableView.selectedRow == 1)
    }

    @Test("a dragged row carries its index on a pasteboard type local to the table")
    func dragPasteboard() throws {
        let editor = Self.editor()
        #expect(editor.tableView.registeredDraggedTypes.contains(GitRebaseEditorViewController.rowPasteboardType))
        let writer = try #require(editor.tableView(editor.tableView, pasteboardWriterForRow: 2) as? NSPasteboardItem)
        #expect(writer.string(forType: GitRebaseEditorViewController.rowPasteboardType) == "2")
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("git.rebase.test.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        pasteboard.clearContents()
        pasteboard.writeObjects([writer])
        #expect(GitRebaseEditorViewController.draggedRow(pasteboard) == 2)
    }

    @Test("Start Rebase is disabled, with the reason as its tooltip, for a leading squash")
    func leadingSquashDisablesStart() {
        let editor = Self.editor()
        #expect(editor.startButton.isEnabled)
        #expect(editor.startButton.toolTip == nil)
        editor.setAction(.squash, at: 0)
        #expect(!editor.startButton.isEnabled)
        #expect(editor.startButton.toolTip == editor.plan.validationError)
        #expect(editor.startButton.toolTip != nil)
        editor.setAction(.pick, at: 0)
        #expect(editor.startButton.isEnabled)
        #expect(editor.startButton.toolTip == nil)
    }

    @Test("Start Rebase is disabled for a reword whose message is empty")
    func emptyRewordDisablesStart() throws {
        let editor = Self.editor()
        editor.setAction(.reword, at: 1)
        #expect(editor.startButton.isEnabled)
        editor.setMessage("   ", at: 1)
        #expect(!editor.startButton.isEnabled)
        #expect(editor.startButton.toolTip == editor.plan.validationError)
        editor.setMessage("fine", at: 1)
        #expect(editor.startButton.isEnabled)
    }

    @Test("Cancel finishes with nil, once")
    func cancelFinishesWithNil() {
        let editor = Self.editor()
        var results: [GitRebasePlan?] = []
        editor.onFinish = { results.append($0) }
        editor.cancelButton.performClick(nil)
        editor.cancelButton.performClick(nil)
        #expect(results.count == 1)
        #expect(results.first == .some(nil))
    }

    @Test("Start Rebase finishes with the edited plan, and does nothing while the plan is invalid")
    func startFinishesWithPlan() {
        let editor = Self.editor()
        var results: [GitRebasePlan?] = []
        editor.onFinish = { results.append($0) }
        editor.setAction(.fixup, at: 0)
        editor.startButton.performClick(nil)
        #expect(results.isEmpty)
        editor.setAction(.pick, at: 0)
        editor.setAction(.drop, at: 2)
        editor.moveEntry(from: 1, to: 0)
        editor.startButton.performClick(nil)
        #expect(results.count == 1)
        let finished = results.first ?? nil
        #expect(finished == editor.plan)
        #expect(finished?.entries.map(\.action) == [.pick, .pick, .drop])
    }
}
