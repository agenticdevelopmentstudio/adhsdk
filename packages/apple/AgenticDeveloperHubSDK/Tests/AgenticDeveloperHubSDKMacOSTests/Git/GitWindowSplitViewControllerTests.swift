import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for FSEvents: the tests deliver each change themselves through
/// `GitRepositoryModel.refresh(_:)`, as the watcher would.
private final class IdleWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// The Git window's routing (recipe `workspace/git/git-window`, "Layout" and
/// "Selection"), over a real repository and a real model.
@Suite("GitWindowSplitViewController", .serialized)
@MainActor
struct GitWindowSplitViewControllerTests {
    private static let epoch = 1_767_268_800
    private let client = GitClient(configuration: .default)

    private func commitFile(_ repository: GitTestRepository, _ name: String, _ text: String,
                            at offset: Int) async throws {
        try repository.write(text, to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit("\(name) \(offset)", at: Self.epoch + offset)
    }

    private func makeWindow(
        _ repository: GitTestRepository
    ) async -> (GitRepositoryModel, GitWindowSplitViewController) {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: IdleWatcher())
        await model.start()
        let controller = GitWindowSplitViewController(model: model, client: client, coloring: nil)
        controller.loadViewIfNeeded()
        return (model, controller)
    }

    /// Selects the sidebar row `id` the way a click does: in the list, then reported.
    private func click(_ controller: GitWindowSplitViewController, _ id: String) {
        let sidebar = controller.sidebar
        sidebar.list.selectItem(withId: id)
        sidebar.list.onSelect?(sidebar.sections.flatMap(\.items).first { $0.id == id })
    }

    /// Every row the diff shows, in whichever layout the settings pick.
    private static func diffTexts(_ diff: GitDiffViewController) -> [String] {
        [diff.inlineViewer, diff.leftViewer, diff.rightViewer].flatMap { viewer -> [String] in
            guard let source = viewer.dataSource else { return [] }
            return (0..<source.rowCount).map { source.row(at: $0).text }
        }
    }

    @Test("a commit on the selected branch, reported as refs and history at once, selects the new tip in both")
    func refsAndHistoryChangeSelectsTheNewTip() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        let (model, controller) = await makeWindow(repository)
        let first = try await repository.sha("HEAD")

        click(controller, "refs/heads/main")
        #expect(controller.selection == .ref("refs/heads/main"))
        #expect(controller.history.selectedCommitID == first)
        #expect(controller.detail.commit?.id == first)

        try await commitFile(repository, "two.txt", "two\n", at: 200)
        let second = try await repository.sha("HEAD")
        await model.refresh([.refs, .history])

        #expect(controller.history.selectedCommitID == second)
        #expect(controller.detail.commit?.id == second)
    }

    @Test("Refresh keeps a commit picked in the history while the selected ref has not moved")
    func refreshKeepsAPickedCommit() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await commitFile(repository, "two.txt", "two\n", at: 200)
        let (model, controller) = await makeWindow(repository)
        let older = try await repository.sha("HEAD~1")

        click(controller, "refs/heads/main")
        #expect(controller.history.select(commitID: older))
        await model.refresh(Set(GitRepositoryChange.allCases))
        controller.reloadAll()

        #expect(controller.history.selectedCommitID == older)
        #expect(controller.detail.commit?.id == older)
    }

    @Test("a selected branch that vanishes falls back to the working copy")
    func vanishedBranchFallsBackToWorkingCopy() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await repository.run(["branch", "feature"])
        let (model, controller) = await makeWindow(repository)

        click(controller, "refs/heads/feature")
        #expect(controller.selection == .ref("refs/heads/feature"))
        #expect(controller.centre.content === controller.history)
        #expect(controller.detail.commit != nil)

        try await repository.run(["branch", "-D", "feature"])
        await model.refresh([.refs])

        #expect(controller.selection == .workingCopy)
        #expect(controller.centre.content === controller.workingCopy)
        #expect(controller.detail.commit == nil)
    }

    @Test("a stash that cannot be read shows git's error in place of the detail")
    func stashLoadFailureShowsTheError() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        let (_, controller) = await makeWindow(repository)

        let missing = GitStash(index: 0, id: String(repeating: "ab", count: 20), message: "gone", date: Date())
        controller.sidebar(controller.sidebar, didSelectStash: missing)
        await controller.commitLoadTask?.value

        let label = controller.detailHost.errorLabel
        #expect(label.accessibilityIdentifier() == "git.window.error")
        #expect(!label.isHidden)
        #expect(!label.stringValue.isEmpty)
        #expect(controller.detail.view.isHidden)
        #expect(controller.detail.commit == nil)
    }

    @Test("editing a file already modified reloads the working-copy diff on the change and on Refresh")
    func workingCopyChangeReloadsTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "one\n", at: 100)
        try repository.write("two\n", to: "a.txt")
        let (model, controller) = await makeWindow(repository)

        controller.workingCopy(controller.workingCopy, didSelect: .unstaged(paths: ["a.txt"]))
        await controller.diff.loadTask?.value
        #expect(Self.diffTexts(controller.diff).contains("two"))

        try repository.write("three\n", to: "a.txt")
        await model.refresh([.workingCopy])
        await controller.diff.loadTask?.value
        #expect(Self.diffTexts(controller.diff).contains("three"))
        #expect(!Self.diffTexts(controller.diff).contains("two"))

        try repository.write("four\n", to: "a.txt")
        controller.reloadAll()
        await controller.diff.loadTask?.value
        #expect(Self.diffTexts(controller.diff).contains("four"))
    }

    @Test("a blame of the working file reads again when the working copy changes")
    func workingCopyChangeReloadsAWorkingFileBlame() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "one\n", at: 100)
        try repository.write("two\n", to: "a.txt")
        let (model, controller) = await makeWindow(repository)

        controller.diff(controller.diff, didRequestBlameFor: "a.txt", at: nil)
        await controller.blame.loadTask?.value
        #expect(controller.bottom.content === controller.blame)
        let before = controller.blame.viewer.dataSource.map { source in
            (0..<source.rowCount).map { source.row(at: $0).text }
        }
        #expect(before == ["two"])

        try repository.write("three\n", to: "a.txt")
        await model.refresh([.workingCopy])
        await controller.blame.loadTask?.value
        let after = controller.blame.viewer.dataSource.map { source in
            (0..<source.rowCount).map { source.row(at: $0).text }
        }
        #expect(after == ["three"])
    }

    @Test("a file's history lists a new commit after a history change")
    func historyChangeReloadsTheFileHistory() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "one\n", at: 100)
        let (model, controller) = await makeWindow(repository)

        controller.diff(controller.diff, didRequestHistoryFor: "a.txt")
        await controller.fileHistory.loadTask?.value
        #expect(controller.fileHistory.entries.count == 1)

        try await commitFile(repository, "a.txt", "two\n", at: 200)
        await model.refresh([.refs, .history])
        await controller.fileHistory.loadTask?.value
        #expect(controller.fileHistory.entries.count == 2)
    }

    @Test("the toolbar's search reaches the history, and a sha search selects its commit")
    func searchIsForwardedToTheHistory() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await commitFile(repository, "two.txt", "two\n", at: 200)
        let older = try await repository.sha("HEAD~1")
        let window = GitWindowController(
            root: repository.root, client: client, coloring: nil, onOpenDirectory: { _ in }, onClose: {})
        defer { window.model.stop() }
        window.loadWindow()

        // The window starts its model itself, and its views reload when the model tells
        // its observers, after every part has loaded; a sha search selects among those.
        var historyLoaded = false
        let observation = window.model.observe { changes in
            if changes.contains(.history) { historyLoaded = true }
        }
        for _ in 0..<250 where !historyLoaded {
            try await Task.sleep(for: .milliseconds(20))
        }
        withExtendedLifetime(observation) {}
        try #require(window.model.commits.count == 2)

        let shaSearch = "sha:" + older.prefix(8)
        window.search(shaSearch)
        await window.searchTask?.value
        #expect(window.content.history.selectedCommitID == older)

        let messageSearch = "two.txt"
        window.search(messageSearch)
        await window.searchTask?.value
        #expect(window.model.query == GitHistorySearch.parse(messageSearch))
        #expect(window.model.commits.map(\.subject) == ["two.txt 200"])
    }

    @Test("a branch read that fails keeps the last subtitle")
    func failedBranchReadKeepsTheSubtitle() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        let window = GitWindowController(
            root: repository.root, client: client, coloring: nil, onOpenDirectory: { _ in }, onClose: {})
        defer { window.model.stop() }
        window.loadWindow()
        window.updateSubtitle()
        await window.subtitleTask?.value
        #expect(window.window?.subtitle == "main")

        try FileManager.default.moveItem(at: repository.url(".git"), to: repository.url("moved-away"))
        window.updateSubtitle()
        await window.subtitleTask?.value
        #expect(window.window?.subtitle == "main")
    }
}
