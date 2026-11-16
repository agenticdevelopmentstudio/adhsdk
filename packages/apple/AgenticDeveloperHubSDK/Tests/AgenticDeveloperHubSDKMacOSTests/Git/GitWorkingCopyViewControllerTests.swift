import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A working-copy source whose lists a test sets directly, like the model's status snapshot.
@MainActor
private final class FakeWorkingCopySource: GitWorkingCopyDataSource {
    var staged: [GitFileChange] = []
    var unstaged: [GitFileChange] = []
    var conflicts: [String: GitConflictKind] = [:]
}

@MainActor
private final class RecordingWorkingCopyDelegate: GitWorkingCopyDelegate {
    private(set) var events: [GitDiffTarget?] = []
    private(set) var intents: [GitWorkingCopyIntent] = []
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?) {
        events.append(target)
    }
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didRequest intent: GitWorkingCopyIntent) {
        intents.append(intent)
    }
}

@Suite("GitWorkingCopyViewController")
@MainActor
struct GitWorkingCopyViewControllerTests {

    private static func source() -> FakeWorkingCopySource {
        let source = FakeWorkingCopySource()
        source.staged = [GitFileChange(path: "a", status: .added)]
        source.unstaged = [GitFileChange(path: "b", status: .modified), GitFileChange(path: "c", status: .untracked)]
        return source
    }

    private func select(_ list: GitFileListViewController, row: Int) {
        list.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    @Test("two lists over the source's staged and unstaged files, under counted headers")
    func lists() {
        let workingCopy = GitWorkingCopyViewController(source: Self.source())
        workingCopy.loadViewIfNeeded()

        #expect(workingCopy.view.accessibilityIdentifier() == "git.workingCopy")
        #expect(workingCopy.stagedHeader.stringValue == "Staged (1)")
        #expect(workingCopy.unstagedHeader.stringValue == "Unstaged (2)")
        #expect(workingCopy.stagedHeader.accessibilityIdentifier() == "git.workingCopy.stagedHeader")
        #expect(workingCopy.unstagedHeader.accessibilityIdentifier() == "git.workingCopy.unstagedHeader")
        #expect(workingCopy.stagedList.view.accessibilityIdentifier() == "git.fileList.staged")
        #expect(workingCopy.unstagedList.view.accessibilityIdentifier() == "git.fileList.unstaged")
        #expect(workingCopy.stagedList.files == [GitFileListItem(path: "a", oldPath: nil, status: .added)])
        #expect(workingCopy.unstagedList.files == [
            GitFileListItem(path: "b", oldPath: nil, status: .modified),
            GitFileListItem(path: "c", oldPath: nil, status: .untracked)
        ])
    }

    @Test("a clean working copy shows two empty lists counted zero")
    func clean() {
        let workingCopy = GitWorkingCopyViewController(source: FakeWorkingCopySource())
        workingCopy.loadViewIfNeeded()
        #expect(workingCopy.stagedHeader.stringValue == "Staged (0)")
        #expect(workingCopy.unstagedHeader.stringValue == "Unstaged (0)")
        #expect(workingCopy.stagedList.files.isEmpty)
        #expect(workingCopy.unstagedList.files.isEmpty)
    }

    @Test("selecting reports the diff target, and selecting in one list clears the other silently")
    func selection() {
        let workingCopy = GitWorkingCopyViewController(source: Self.source())
        let delegate = RecordingWorkingCopyDelegate()
        workingCopy.delegate = delegate
        workingCopy.loadViewIfNeeded()

        select(workingCopy.stagedList, row: 0)
        #expect(delegate.events == [.staged(paths: ["a"])])

        select(workingCopy.unstagedList, row: 1)
        #expect(delegate.events == [.staged(paths: ["a"]), .untracked(path: "c")])
        #expect(workingCopy.stagedList.tableView.selectedRow == -1)

        select(workingCopy.unstagedList, row: 0)
        #expect(delegate.events == [.staged(paths: ["a"]), .untracked(path: "c"), .unstaged(paths: ["b"])])

        select(workingCopy.stagedList, row: 0)
        #expect(workingCopy.unstagedList.tableView.selectedRow == -1)
        #expect(delegate.events.count == 4)
        #expect(delegate.events.last == .staged(paths: ["a"]))

        workingCopy.stagedList.tableView.deselectAll(nil)
        #expect(delegate.events.count == 5)
        #expect(delegate.events.last == .some(nil))
    }

    @Test("reload keeps a surviving selection silently and reports nil once when it leaves its list")
    func reload() {
        let source = Self.source()
        let workingCopy = GitWorkingCopyViewController(source: source)
        let delegate = RecordingWorkingCopyDelegate()
        workingCopy.delegate = delegate
        workingCopy.loadViewIfNeeded()

        select(workingCopy.unstagedList, row: 0)
        #expect(delegate.events == [.unstaged(paths: ["b"])])

        source.unstaged = [GitFileChange(path: "new", status: .untracked)] + source.unstaged
        workingCopy.reload()
        #expect(delegate.events == [.unstaged(paths: ["b"])])
        #expect(workingCopy.unstagedList.tableView.selectedRow == 1)
        #expect(workingCopy.unstagedHeader.stringValue == "Unstaged (3)")

        source.staged.append(GitFileChange(path: "b", status: .modified))
        source.unstaged.removeAll { $0.path == "b" }
        workingCopy.reload()
        #expect(delegate.events == [.unstaged(paths: ["b"]), nil])
        #expect(workingCopy.stagedList.tableView.selectedRow == -1)
        #expect(workingCopy.unstagedList.tableView.selectedRow == -1)
        #expect(workingCopy.stagedHeader.stringValue == "Staged (2)")
    }

    @Test("an untracked selection that becomes intent-to-add is reported again as an unstaged target")
    func untrackedBecomesIntentToAdd() {
        let source = Self.source()
        let workingCopy = GitWorkingCopyViewController(source: source)
        workingCopy.loadViewIfNeeded()
        let delegate = RecordingWorkingCopyDelegate()
        workingCopy.delegate = delegate

        select(workingCopy.unstagedList, row: 1)
        source.unstaged = [GitFileChange(path: "b", status: .modified), GitFileChange(path: "c", status: .added)]
        workingCopy.reload()
        #expect(delegate.events == [.untracked(path: "c"), .unstaged(paths: ["c"])])
    }

    @Test("the split view and every pane carry identifiers")
    func containerIdentifiers() {
        let workingCopy = GitWorkingCopyViewController(source: Self.source())
        workingCopy.loadViewIfNeeded()
        #expect(workingCopy.splitView.accessibilityIdentifier() == "git.workingCopy.split")
        #expect(workingCopy.splitView.arrangedSubviews.map { $0.accessibilityIdentifier() }
                == ["git.workingCopy.conflictsPane", "git.workingCopy.stagedPane", "git.workingCopy.unstagedPane",
                    "git.commitBox"])
    }

    // MARK: - Conflicts

    /// A UU `both.txt`, a DU `gone.txt` and an AA `added.txt`, each also an unstaged conflicted
    /// change as status reports it, beside an ordinary modified `b` and a staged `s`.
    private static func conflictSource() -> FakeWorkingCopySource {
        let source = FakeWorkingCopySource()
        source.conflicts = ["both.txt": .bothModified, "gone.txt": .deletedByUs, "added.txt": .bothAdded]
        source.staged = [GitFileChange(path: "s", status: .modified)]
        source.unstaged = [GitFileChange(path: "added.txt", status: .conflicted),
                           GitFileChange(path: "b", status: .modified),
                           GitFileChange(path: "both.txt", status: .conflicted),
                           GitFileChange(path: "gone.txt", status: .conflicted)]
        return source
    }

    @Test("the Conflicts list is shown only while there are conflicts, and holds them sorted")
    func conflictsListShownOnlyWithConflicts() {
        let source = Self.conflictSource()
        let (workingCopy, _) = loaded(source)
        let pane = workingCopy.splitView.arrangedSubviews[0]
        #expect(!pane.isHidden)
        #expect(workingCopy.conflictsHeader.stringValue == "Conflicts (3)")
        #expect(workingCopy.conflictsHeader.accessibilityIdentifier() == "git.workingCopy.conflictsHeader")
        #expect(workingCopy.conflictsList.view.accessibilityIdentifier() == "git.fileList.conflicts")
        #expect(workingCopy.conflictsList.files.map(\.path) == ["added.txt", "both.txt", "gone.txt"])
        #expect(workingCopy.conflictsList.files.allSatisfy { $0.status == .conflicted })

        source.conflicts = [:]
        source.unstaged = [GitFileChange(path: "b", status: .modified)]
        workingCopy.reload()
        #expect(pane.isHidden)
        #expect(workingCopy.conflictsList.files.isEmpty)

        let clean = GitWorkingCopyViewController(source: FakeWorkingCopySource())
        clean.loadViewIfNeeded()
        #expect(clean.splitView.arrangedSubviews[0].isHidden)
    }

    @Test("a conflicted path is listed under Conflicts and not under Unstaged")
    func conflictedPathLeavesUnstaged() {
        let (workingCopy, _) = loaded(Self.conflictSource())
        #expect(workingCopy.unstagedList.files.map(\.path) == ["b"])
        #expect(workingCopy.unstagedHeader.stringValue == "Unstaged (1)")
    }

    @Test("a conflict with markers offers Open in Merge View, a separator, Ours…, Theirs… and Mark Resolved")
    func conflictMenuWithMarkers() throws {
        let (workingCopy, delegate) = loaded(Self.conflictSource())
        let menu = try #require(workingCopy.conflictsList.contextMenu(forRow: 1))
        #expect(menu.items.map(\.title) == ["Open in Merge View", "", "Resolve Using Ours…",
                                            "Resolve Using Theirs…", "Mark Resolved"])
        #expect(menu.items[1].isSeparatorItem)
        #expect(menu.items.map { $0.accessibilityIdentifier() } == [
            "git.workingCopy.menu.openMerge", "", "git.workingCopy.menu.resolveOurs",
            "git.workingCopy.menu.resolveTheirs", "git.workingCopy.menu.markResolved"
        ])
        for index in [0, 2, 3, 4] { fire(menu.items[index]) }
        #expect(delegate.intents == [.openMerge("both.txt"), .resolve(["both.txt"], .ours),
                                     .resolve(["both.txt"], .theirs), .markResolved(["both.txt"])])
    }

    @Test("a conflict without markers (deleted by us) has no Open in Merge View")
    func conflictMenuWithoutMarkers() throws {
        let (workingCopy, delegate) = loaded(Self.conflictSource())
        let menu = try #require(workingCopy.conflictsList.contextMenu(forRow: 2))
        #expect(menu.items.map(\.title) == ["Resolve Using Ours…", "Resolve Using Theirs…", "Mark Resolved"])
        fire(menu.items[1])
        #expect(delegate.intents == [.resolve(["gone.txt"], .theirs)])
    }

    @Test("double-clicking a conflict with markers opens it in the merge view; one without does nothing")
    func conflictDoubleClick() {
        let (workingCopy, delegate) = loaded(Self.conflictSource())
        workingCopy.conflictsList.doubleClick(row: 1)
        workingCopy.conflictsList.doubleClick(row: 2)
        #expect(delegate.intents == [.openMerge("both.txt")])
    }

    @Test("selecting a conflict with markers opens the merge view; one without shows its conflicted diff")
    func conflictSelection() {
        let (workingCopy, delegate) = loaded(Self.conflictSource())
        select(workingCopy.unstagedList, row: 0)
        select(workingCopy.conflictsList, row: 1)
        #expect(delegate.events == [.unstaged(paths: ["b"])], "a marked conflict reports no diff target")
        #expect(delegate.intents == [.openMerge("both.txt")])
        #expect(workingCopy.unstagedList.tableView.selectedRow == -1)
        select(workingCopy.conflictsList, row: 2)
        #expect(delegate.events == [.unstaged(paths: ["b"]), .conflicted(path: "gone.txt")])
        #expect(delegate.intents == [.openMerge("both.txt")])
        select(workingCopy.stagedList, row: 0)
        #expect(workingCopy.conflictsList.tableView.selectedRow == -1)
    }

    // MARK: - Intents

    /// A staged rename `old` → `new` and an unstaged modified `b`.
    private static func renameSource() -> FakeWorkingCopySource {
        let source = FakeWorkingCopySource()
        source.staged = [GitFileChange(path: "new", status: .renamed)]
        source.unstaged = [GitFileChange(path: "b", status: .modified)]
        return source
    }

    private func loaded(
        _ source: FakeWorkingCopySource
    ) -> (GitWorkingCopyViewController, RecordingWorkingCopyDelegate) {
        let workingCopy = GitWorkingCopyViewController(source: source)
        let delegate = RecordingWorkingCopyDelegate()
        workingCopy.delegate = delegate
        workingCopy.loadViewIfNeeded()
        return (workingCopy, delegate)
    }

    private func fire(_ item: NSMenuItem) {
        guard let action = item.action, let target = item.target as? NSObject else {
            Issue.record("menu item \(item.title) has no target and action")
            return
        }
        _ = target.perform(action, with: item)
    }

    @Test("a staged row's menu is Unstage, and a staged rename unstages both paths")
    func stagedMenu() throws {
        let (workingCopy, delegate) = loaded(Self.renameSource())
        workingCopy.stagedList.files = [GitFileListItem(path: "new", oldPath: "old", status: .renamed)]
        let menu = try #require(workingCopy.stagedList.contextMenu(forRow: 0))
        #expect(menu.items.map(\.title) == ["Unstage"])
        #expect(menu.items.map { $0.accessibilityIdentifier() } == ["git.workingCopy.menu.unstage"])
        fire(menu.items[0])
        #expect(delegate.intents == [.unstage(["old", "new"])])
    }

    @Test("an unstaged row's menu is Stage, Discard Changes…, a separator and Discard All Changes…")
    func unstagedMenu() throws {
        let (workingCopy, delegate) = loaded(Self.renameSource())
        let menu = try #require(workingCopy.unstagedList.contextMenu(forRow: 0))
        #expect(menu.items.map(\.title) == ["Stage", "Discard Changes…", "", "Discard All Changes…"])
        #expect(menu.items[2].isSeparatorItem)
        #expect(menu.items.map { $0.accessibilityIdentifier() } == [
            "git.workingCopy.menu.stage", "git.workingCopy.menu.discard", "", "git.workingCopy.menu.discardAll"
        ])
        fire(menu.items[0])
        fire(menu.items[1])
        fire(menu.items[3])
        #expect(delegate.intents == [.stage(["b"]), .discard(["b"]), .discardAll])
    }

    @Test("no menu for a row outside the list")
    func noMenuOutsideRows() {
        let (workingCopy, _) = loaded(Self.renameSource())
        #expect(workingCopy.unstagedList.contextMenu(forRow: -1) == nil)
        #expect(workingCopy.stagedList.contextMenu(forRow: 5) == nil)
    }

    @Test("double-clicking a staged row unstages it, an unstaged row stages it")
    func doubleClick() {
        let (workingCopy, delegate) = loaded(Self.renameSource())
        workingCopy.stagedList.files = [GitFileListItem(path: "new", oldPath: "old", status: .renamed)]
        workingCopy.stagedList.doubleClick(row: 0)
        workingCopy.unstagedList.doubleClick(row: 0)
        workingCopy.unstagedList.doubleClick(row: 7)
        #expect(delegate.intents == [.unstage(["old", "new"]), .stage(["b"])])
    }

    @Test("the table's double action and menu reach the list")
    func tableWiring() {
        let (workingCopy, _) = loaded(Self.renameSource())
        let table = workingCopy.unstagedList.tableView
        #expect(table.doubleAction != nil)
        #expect(table.target === workingCopy.unstagedList)
        #expect(table.menu != nil)
    }

    @Test("Stage All and Unstage All send their intents")
    func headerButtons() {
        let (workingCopy, delegate) = loaded(Self.renameSource())
        #expect(workingCopy.stageAllButton.title == "Stage All")
        #expect(workingCopy.stageAllButton.accessibilityIdentifier() == "git.workingCopy.stageAll")
        #expect(workingCopy.stageAllButton.isBordered == false)
        #expect(workingCopy.unstageAllButton.title == "Unstage All")
        #expect(workingCopy.unstageAllButton.accessibilityIdentifier() == "git.workingCopy.unstageAll")
        workingCopy.stageAllButton.performClick(nil)
        workingCopy.unstageAllButton.performClick(nil)
        #expect(delegate.intents == [.stageAll, .unstageAll])
    }

    @Test("the commit box reports commit and amend intents, and knows whether anything is staged")
    func commitBox() {
        let source = Self.renameSource()
        let (workingCopy, delegate) = loaded(source)
        #expect(workingCopy.commitBox.hasStagedChanges == true)
        workingCopy.canAmend = true
        #expect(workingCopy.commitBox.canAmend == true)

        workingCopy.commitBox.amendBox.performClick(nil)
        workingCopy.commitBox.message = "Fix\n\nBody"
        workingCopy.commitBox.commitButton.performClick(nil)
        #expect(delegate.intents == [.amendChanged(true), .commit(message: "Fix\n\nBody", amend: true)])

        source.staged = []
        workingCopy.reload()
        #expect(workingCopy.commitBox.hasStagedChanges == false)
    }

    @Test("commitDidSucceed empties the message and unticks Amend without a report")
    func commitDidSucceed() {
        let (workingCopy, delegate) = loaded(Self.renameSource())
        workingCopy.canAmend = true
        workingCopy.commitBox.amendBox.performClick(nil)
        workingCopy.commitBox.message = "Fix"
        workingCopy.commitDidSucceed()
        #expect(workingCopy.commitBox.message == "")
        #expect(workingCopy.commitBox.isAmend == false)
        #expect(delegate.intents == [.amendChanged(true)])
    }

    @Test("commitDidSucceed also forgets the message's undo history")
    func commitDidSucceedClearsUndo() {
        let (workingCopy, _) = loaded(Self.renameSource())
        let undo = workingCopy.commitBox.messageUndoManager
        undo.registerUndo(withTarget: workingCopy) { _ in }
        #expect(undo.canUndo)
        workingCopy.commitDidSucceed()
        #expect(!undo.canUndo)
    }

    @Test("Stage All and Unstage All are disabled while their list is empty")
    func headerButtonsFollowTheirLists() {
        let source = Self.renameSource()
        let (workingCopy, delegate) = loaded(source)
        #expect(workingCopy.stageAllButton.isEnabled)
        #expect(workingCopy.unstageAllButton.isEnabled)

        source.staged = []
        workingCopy.reload()
        #expect(!workingCopy.unstageAllButton.isEnabled)
        #expect(workingCopy.stageAllButton.isEnabled)

        source.staged = [GitFileChange(path: "b", status: .modified)]
        source.unstaged = []
        workingCopy.reload()
        #expect(workingCopy.unstageAllButton.isEnabled)
        #expect(!workingCopy.stageAllButton.isEnabled)
        workingCopy.stageAllButton.performClick(nil)
        #expect(delegate.intents.isEmpty)
    }
}
