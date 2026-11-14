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
}

@MainActor
private final class RecordingWorkingCopyDelegate: GitWorkingCopyDelegate {
    private(set) var events: [GitDiffTarget?] = []
    func workingCopy(_ workingCopy: GitWorkingCopyViewController, didSelect target: GitDiffTarget?) {
        events.append(target)
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
}
