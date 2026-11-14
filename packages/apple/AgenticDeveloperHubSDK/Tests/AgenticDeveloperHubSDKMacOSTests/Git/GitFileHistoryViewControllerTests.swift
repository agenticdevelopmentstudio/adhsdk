import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@Suite("GitFileHistoryViewController")
@MainActor
struct GitFileHistoryViewControllerTests {

    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static let date = Date(timeIntervalSince1970: 1_790_000_000)

    private static func commit(_ prefix: String, _ subject: String) -> GitCommit {
        let person = GitPerson(name: "Ann Lee", email: "ann@example.com", date: date)
        return GitCommit(id: sha(prefix), parents: [], author: person, committer: person, subject: subject, body: "")
    }

    private static func controller(_ source: GitViewsFakeContentSource) -> GitFileHistoryViewController {
        let controller = GitFileHistoryViewController(source: source, coloring: nil,
                                                      settings: UserSettings(with: InMemorySettingsStorageProvider()))
        controller.loadViewIfNeeded()
        return controller
    }

    private static func cell(_ controller: GitFileHistoryViewController, _ row: Int) -> GitFileHistoryCellView? {
        controller.tableView(controller.tableView, viewFor: controller.tableView.tableColumns.first, row: row)
            as? GitFileHistoryCellView
    }

    @Test("the view, list and diff carry their identifiers")
    func identifiers() {
        let controller = Self.controller(GitViewsFakeContentSource())
        #expect(controller.view.accessibilityIdentifier() == "git.fileHistory")
        #expect(controller.splitView.accessibilityIdentifier() == "git.fileHistory.split")
        #expect(controller.scrollView.accessibilityIdentifier() == "git.fileHistory.scroll")
        #expect(controller.tableView.accessibilityIdentifier() == "git.fileHistory.table")
        #expect(controller.errorLabel.accessibilityIdentifier() == "git.fileHistory.error")
        #expect(controller.diffViewController.view.accessibilityIdentifier() == "git.diff")
        #expect(controller.errorLabel.isHidden)
    }

    @Test("the list shows the file's commits and the newest is shown in the diff")
    func listAndAutoSelect() async throws {
        let source = GitViewsFakeContentSource()
        source.histories["a.swift"] = [Self.commit("c2", "Second"), Self.commit("c1", "First")]
        let controller = Self.controller(source)
        controller.show(path: "a.swift")
        await controller.loadTask?.value
        await controller.diffViewController.loadTask?.value

        #expect(source.historyRequests == ["a.swift"])
        #expect(controller.commits.map(\.subject) == ["Second", "First"])
        #expect(controller.tableView.numberOfRows == 2)
        #expect(controller.tableView.selectedRow == 0)
        let cell = try #require(Self.cell(controller, 0))
        #expect(cell.subjectLabel.stringValue == "Second")
        #expect(cell.detailsLabel.stringValue
                == "c2000000 · AL · \(RelativeDateFormatting.string(for: Self.date))")
        #expect(cell.accessibilityIdentifier() == "git.fileHistory.commit")
        #expect(cell.subjectLabel.accessibilityIdentifier() == "git.fileHistory.subject")
        #expect(cell.detailsLabel.accessibilityIdentifier() == "git.fileHistory.details")
        #expect(source.diffRequests.map(\.target) == [.commit(Self.sha("c2"), paths: ["a.swift"])])
    }

    @Test("selecting a row shows that commit's change to the file")
    func selectRow() async {
        let source = GitViewsFakeContentSource()
        source.histories["a.swift"] = [Self.commit("c2", "Second"), Self.commit("c1", "First")]
        let controller = Self.controller(source)
        controller.show(path: "a.swift")
        await controller.loadTask?.value
        await controller.diffViewController.loadTask?.value

        controller.tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        await controller.diffViewController.loadTask?.value
        #expect(source.diffRequests.map(\.target) == [.commit(Self.sha("c2"), paths: ["a.swift"]),
                                                      .commit(Self.sha("c1"), paths: ["a.swift"])])
        #expect(controller.diffViewController.blameButton.isEnabled)

        controller.tableView.deselectAll(nil)
        #expect(!controller.diffViewController.blameButton.isEnabled)
    }

    @Test("a file with no history shows no rows and an empty diff")
    func empty() async {
        let source = GitViewsFakeContentSource()
        let controller = Self.controller(source)
        controller.show(path: "new.swift")
        await controller.loadTask?.value
        #expect(controller.tableView.numberOfRows == 0)
        #expect(source.diffRequests.isEmpty)
        #expect(controller.errorLabel.isHidden)
    }

    @Test("a failed history is shown with the list empty and the diff cleared")
    func failure() async {
        let source = GitViewsFakeContentSource()
        source.histories["a.swift"] = [Self.commit("c1", "First")]
        source.failing = ["history:b.swift"]
        let controller = Self.controller(source)
        controller.show(path: "a.swift")
        await controller.loadTask?.value
        await controller.diffViewController.loadTask?.value

        controller.show(path: "b.swift")
        await controller.loadTask?.value
        #expect(!controller.errorLabel.isHidden)
        #expect(controller.errorLabel.isSelectable)
        #expect(controller.errorLabel.stringValue == gitViewsFailure.localizedDescription)
        #expect(controller.tableView.numberOfRows == 0)
        #expect(!controller.diffViewController.blameButton.isEnabled)

        controller.show(path: "a.swift")
        await controller.loadTask?.value
        #expect(controller.errorLabel.isHidden)
        #expect(controller.tableView.numberOfRows == 1)
    }

    @Test("the latest show wins in either order of return", arguments: [true, false])
    func latestWins(laterReturnsFirst: Bool) async {
        let source = GitViewsFakeContentSource()
        source.histories = ["a": [Self.commit("a1", "A")], "b": [Self.commit("b1", "B"), Self.commit("b0", "B0")]]
        source.holding = ["history:a", "history:b"]
        let controller = Self.controller(source)

        controller.show(path: "a")
        let first = controller.loadTask
        await source.waitUntilHeld("history:a")
        controller.show(path: "b")
        let second = controller.loadTask
        await source.waitUntilHeld("history:b")

        if laterReturnsFirst {
            source.release("history:b")
            await second?.value
            source.release("history:a")
            await first?.value
        } else {
            source.release("history:a")
            await first?.value
            source.release("history:b")
            await second?.value
        }
        await controller.diffViewController.loadTask?.value
        #expect(controller.commits.map(\.subject) == ["B", "B0"])
        #expect(source.diffRequests.map(\.target) == [.commit(Self.sha("b1"), paths: ["b"])])
    }
}
