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
        #expect(editor.moveUpButton.accessibilityIdentifier() == "git.rebase.moveUp")
        #expect(editor.moveDownButton.accessibilityIdentifier() == "git.rebase.moveDown")
        #expect(action.accessibilityIdentifier() == "git.rebase.actionCell")
    }

    @Test("Return in a reword's field types a newline and never finishes the editor")
    func returnInRewordInsertsNewline() throws {
        let editor = Self.editor()
        var results: [GitRebasePlan?] = []
        editor.onFinish = { results.append($0) }
        editor.setAction(.reword, at: 0)
        let field: GitRebaseMessageField = try #require(cell(editor, "subject", row: 0))
        let textView = NSTextView()
        textView.string = "subject"
        textView.setSelectedRange(NSRange(location: 7, length: 0))
        for command in [#selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertLineBreak(_:))] {
            #expect(field.control(field, textView: textView, doCommandBy: command))
        }
        #expect(textView.string == "subject\n\n")
        #expect(!field.control(field, textView: textView, doCommandBy: #selector(NSResponder.cancelOperation(_:))))
        #expect(results.isEmpty)
        #expect(field.lineBreakMode == .byWordWrapping)
        #expect(field.cell?.wraps == true)
        #expect(!field.usesSingleLineMode)
    }

    @Test("a reword's row is as tall as its message, and grows and shrinks with it")
    func rewordRowHeight() {
        let editor = Self.editor()
        #expect(editor.height(ofRow: 0) == GitRebaseEditorViewController.rowHeight)
        editor.setAction(.reword, at: 0)
        let threeLines = editor.height(ofRow: 0)
        #expect(threeLines > GitRebaseEditorViewController.rowHeight, "commit 0, a blank line, body 0")
        editor.setMessage("one\ntwo\nthree\nfour\nfive", at: 0)
        #expect(editor.height(ofRow: 0) > threeLines)
        editor.setMessage("one", at: 0)
        #expect(editor.height(ofRow: 0) == GitRebaseEditorViewController.rowHeight)
        #expect(editor.height(ofRow: 1) == GitRebaseEditorViewController.rowHeight)
    }

    @Test("a reword line too long for the Subject column wraps, and its row is tall enough for the wrap")
    func wrappedRewordRowHeight() throws {
        let editor = Self.editor()
        editor.setAction(.reword, at: 0)
        editor.setMessage("short", at: 0)
        let oneLine = editor.height(ofRow: 0)
        let long = Array(repeating: "a long subject line that wraps", count: 8).joined(separator: " ")
        editor.setMessage(long, at: 0)
        #expect(!long.contains("\n"))
        let wrapped = editor.height(ofRow: 0)
        #expect(wrapped > oneLine, "one line of text, several lines on screen")

        let subject = editor.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("subject"))
        let fieldWidth = editor.tableView.frameOfCell(atColumn: subject, row: 0).width
        #expect(editor.subjectWidth == fieldWidth, "measured at the frame the Subject cell view is laid out in")
        let field: GitRebaseMessageField = try #require(cell(editor, "subject", row: 0))
        field.stringValue = long
        let bounds = NSRect(x: 0, y: 0, width: editor.subjectWidth, height: .greatestFiniteMagnitude)
        let needed = try #require(field.cell?.cellSize(forBounds: bounds).height)
        #expect(wrapped >= needed, "the row holds the field at its own width")

        let column = try #require(editor.tableView.tableColumns.first { $0.identifier.rawValue == "subject" })
        column.width *= 2
        #expect(editor.height(ofRow: 0) < wrapped, "a wider column wraps less")
    }

    @Test("⌥⌘↓ while a reword field is being edited moves the row and keeps the edit and its insertion point")
    func moveWhileEditingKeepsTheEdit() throws {
        let editor = Self.editor()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 400), styleMask: [.titled],
                              backing: .buffered, defer: true)
        window.contentView = editor.view
        window.layoutIfNeeded()
        let ids = editor.plan.entries.map(\.commit)
        editor.setAction(.reword, at: 0)
        editor.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        let column = editor.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier("subject"))
        let field = try #require(editor.tableView.view(atColumn: column, row: 0, makeIfNecessary: true)
            as? GitRebaseMessageField)
        #expect(window.makeFirstResponder(field))
        field.currentEditor()?.selectedRange = NSRange(location: 3, length: 0)

        let event = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.option, .command], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, characters: "\u{F701}",
            charactersIgnoringModifiers: "\u{F701}", isARepeat: false, keyCode: 125))
        #expect(window.contentView?.performKeyEquivalent(with: event) == true)

        #expect(editor.plan.entries.map(\.commit) == [ids[1], ids[0], ids[2]])
        let editorView = try #require(window.firstResponder as? NSTextView, "still editing")
        #expect(editorView.isFieldEditor)
        let editing = try #require((editorView.delegate as? NSObject) as? GitRebaseMessageField)
        #expect(editor.tableView.row(for: editing) == 1, "the moved row's field")
        #expect(editorView.selectedRange() == NSRange(location: 3, length: 0))
        #expect(editorView.string == "commit 0\n\nbody 0")
    }

    @Test("Move Up and Move Down move the selected row one place, disabled at the ends")
    func moveButtons() {
        let editor = Self.editor()
        let ids = editor.plan.entries.map(\.commit)
        #expect(!editor.moveUpButton.isEnabled)
        #expect(!editor.moveDownButton.isEnabled)
        editor.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        #expect(!editor.moveUpButton.isEnabled)
        #expect(editor.moveDownButton.isEnabled)
        editor.moveDownButton.performClick(nil)
        #expect(editor.plan.entries.map(\.commit) == [ids[1], ids[0], ids[2]])
        #expect(editor.tableView.selectedRow == 1)
        editor.moveDownButton.performClick(nil)
        #expect(editor.plan.entries.map(\.commit) == [ids[1], ids[2], ids[0]])
        #expect(!editor.moveDownButton.isEnabled)
        editor.moveUpButton.performClick(nil)
        editor.moveUpButton.performClick(nil)
        #expect(editor.plan.entries.map(\.commit) == [ids[0], ids[1], ids[2]])
        #expect(editor.tableView.selectedRow == 0)
        #expect(!editor.moveUpButton.isEnabled)
        #expect(editor.moveUpButton.keyEquivalentModifierMask == [.option, .command])
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

    @Test("moving an entry before the view loads reorders the plan without loading the view")
    func moveBeforeLoadLeavesTheViewUnloaded() {
        let editor = GitRebaseEditorViewController(plan: Self.plan())
        let ids = editor.plan.entries.map(\.commit)
        editor.moveEntry(from: 0, to: 3)
        #expect(editor.plan.entries.map(\.commit) == [ids[1], ids[2], ids[0]])
        #expect(!editor.isViewLoaded)
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
