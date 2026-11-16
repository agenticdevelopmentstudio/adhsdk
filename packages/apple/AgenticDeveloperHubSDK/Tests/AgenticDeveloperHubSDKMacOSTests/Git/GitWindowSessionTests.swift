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
@Suite("GitWindowSession", .serialized)
@MainActor
struct GitWindowSessionTests {
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
    ) async -> (GitRepositoryModel, GitWindowSession) {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: IdleWatcher())
        await model.start()
        let controller = GitWindowSession(model: model, client: client, coloring: nil)
        for pane in [controller.overviewPane, controller.centre, controller.commitPane] as [NSViewController] {
            pane.loadViewIfNeeded()
        }
        return (model, controller)
    }

    /// Selects the sidebar row `id` the way a click does: in the list, then reported.
    private func click(_ controller: GitWindowSession, _ id: String) {
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

    @Test("the toolbar's search reaches the history through its pane, and a sha search selects its commit")
    func searchIsForwardedToTheHistory() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await commitFile(repository, "two.txt", "two\n", at: 200)
        let older = try await repository.sha("HEAD~1")
        let (model, session) = await makeWindow(repository)
        defer { session.stop() }
        try #require(model.commits.count == 2)
        let pane: any PaneSearchable = session.centre
        #expect(pane.paneSearchPlaceholder == "Search History")

        let shaSearch = "sha:" + older.prefix(8)
        pane.paneSearch(for: shaSearch)
        await session.searchTask?.value
        // The window opened on the working copy; the search brought the checked-out branch's history forward.
        #expect(session.centre.content === session.history)
        #expect(session.selection != .workingCopy)
        #expect(session.history.selectedCommitID == older)

        let messageSearch = "two.txt"
        pane.paneSearch(for: messageSearch)
        await session.searchTask?.value
        #expect(model.query == GitHistorySearch.parse(messageSearch))
        #expect(model.commits.map(\.subject) == ["two.txt 200"])
    }

    @Test("a search over the working copy on a detached HEAD shows the history with no sidebar row selected")
    func detachedHeadSearchLeavesNoRowSelected() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-detached")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await repository.run(["checkout", "--quiet", "--detach"])
        let (_, session) = await makeWindow(repository)
        defer { session.stop() }
        #expect(session.selection == .workingCopy)
        #expect(session.sidebar.selectedID != nil)

        session.search("one")
        await session.searchTask?.value

        #expect(session.centre.content === session.history)
        #expect(session.selection == .history)
        #expect(session.sidebar.selectedID == nil, "the Working Copy row no longer claims the centre")
    }

    @Test("the history pane is titled after what it shows, and says so when that changes")
    func historyPaneTitleFollowsItsContent() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        let (_, session) = await makeWindow(repository)
        defer { session.stop() }
        #expect(session.centre.paneTitle == "Working Copy")
        var changes = 0
        session.centre.onPaneTitleChange = { changes += 1 }

        click(session, "refs/heads/main")
        #expect(session.centre.paneTitle == "History")
        #expect(changes == 1)
        click(session, "refs/heads/main")
        #expect(changes == 1)
        #expect(session.overviewPane.paneTitle == "Overview")
        #expect(session.commitPane.paneTitle == "Commit")
    }

    @Test("the refs changing asks the window to read its branch again")
    func refsChangeAsksForTheBranch() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-split")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        let (model, session) = await makeWindow(repository)
        defer { session.stop() }
        var asked = 0
        session.onRefsChange = { asked += 1 }
        await model.refresh([.history])
        #expect(asked == 0)
        try await repository.run(["branch", "other"])
        await model.refresh([.refs])
        #expect(asked == 1)
    }

    @Test("without terminals the Git panes are three fixed panes of one each")
    func panesSpecValidates() throws {
        let session = makeIdleSession()
        let layout = try GitWindowPanes.layout(terminals: nil) { _ in session }
        let tree = layout.spec.blueprint()
        let leaves = ComposableTabLayoutSpec.leaves(in: tree)
        #expect(leaves.map { ComposableTabLayoutSpec.viewID(ofLeaf: $0.id, in: tree) }
            == [GitWindowPanes.overview, GitWindowPanes.history, GitWindowPanes.commit])
        #expect(leaves.allSatisfy { layout.spec.isFixed($0.id, in: tree) })
    }

    @Test("with terminals a terminal sits under the commit pane, splittable but never closed while alone")
    func panesSpecHasATerminalUnderTheCommit() throws {
        let session = makeIdleSession()
        let terminals = TerminalPaneFamily(preferredAxis: .vertical)
        let layout = try GitWindowPanes.layout(terminals: terminals) { _ in session }
        let tree = layout.spec.blueprint()
        let leaves = ComposableTabLayoutSpec.leaves(in: tree)
        let ids = leaves.map { ComposableTabLayoutSpec.viewID(ofLeaf: $0.id, in: tree) }
        #expect(ids == [GitWindowPanes.overview, GitWindowPanes.history, GitWindowPanes.commit, .terminal])
        let terminal = try #require(leaves.last)
        #expect(!layout.spec.isFixed(terminal.id, in: tree))
        #expect(layout.spec.canSplit(terminal.id, in: tree))
        #expect(!layout.spec.canRemove(terminal.id, from: tree))
        let offered = layout.spec.allowedInsertions(at: terminal.id, in: tree, registry: layout.registry)
            .map(\.viewID)
        #expect(Set(offered) == Set([.terminal, .terminalChat, GitWindowPanes.commandLog]))
        for leaf in leaves.dropLast() {
            #expect(layout.spec.isFixed(leaf.id, in: tree))
            #expect(layout.spec.allowedInsertions(at: leaf.id, in: tree, registry: layout.registry).isEmpty)
        }
        let commandLog = try #require(
            GitWindowPanes.terminalAllowances(terminals).first { $0.viewID == GitWindowPanes.commandLog })
        #expect(commandLog.min == 0)
        #expect(commandLog.max == 1)
        #expect(layout.registry.descriptor(for: GitWindowPanes.commandLog).displayName == "Command Log")
    }

    @Test("the Command Log toggle opens the log beside the terminal, and closes it again")
    func toggleCommandLog() throws {
        let session = makeIdleSession()
        let registry = ComposableTabsViewRegistry()
        GitWindowPanes.register(in: registry, terminals: nil) { _ in session }
        // Stand-ins: a real terminal would start a shell.
        for viewID in [ComposableTabsViewID.terminal, .terminalChat] {
            registry.register(viewID, descriptor: .init(displayName: "Stand-in")) { _ in NSViewController() }
        }
        let terminals = TerminalPaneFamily(preferredAxis: .vertical)
        let layout = try ComposableTabsLayout(registry: registry, spec: GitWindowPanes.spec(terminals: terminals))
        let project = ProjectWindowTestSupport.makeProject(label: "GitCommandLogToggle")
        let root = ComposableTabsViewController.make(
            from: layout.spec.blueprint(), project: project, workingDirectory: project.directoryURL, isRoot: true)
        root.layoutOverride = layout
        root.view.frame = NSRect(x: 0, y: 0, width: 1200, height: 800)
        root.view.layoutSubtreeIfNeeded()
        let fixed = [GitWindowPanes.overview, GitWindowPanes.history, GitWindowPanes.commit]
        func shown() -> [ComposableTabsViewID] { session.commitPane.tabPanes().map(\.viewID) }
        #expect(shown() == fixed + [.terminal])

        session.toggleCommandLog()
        #expect(shown() == fixed + [.terminal, GitWindowPanes.commandLog])
        let pane = try #require(session.commitPane.tabPanes().last)
        pane.loadViewIfNeeded()
        #expect(pane.contentViewController === session.commandLog)

        session.toggleCommandLog()
        #expect(shown() == fixed + [.terminal])
        session.stop()
    }

    private func makeIdleSession() -> GitWindowSession {
        let model = GitRepositoryModel(
            root: URL(fileURLWithPath: "/nonexistent"), client: client, watcher: IdleWatcher())
        return GitWindowSession(model: model, client: client, coloring: nil)
    }

    @Test("a window's title names its kind: Git and Code with the branch, Files with the folder")
    func titleNamesTheKind() {
        let directory = URL(fileURLWithPath: "/tmp/adkitchen")
        #expect(ComposableTabsWindowController.title(kind: .gitWindow, name: "adkitchen", directory: directory,
                                                     branch: "main") == "Git: adkitchen \u{2192} main")
        #expect(ComposableTabsWindowController.title(kind: .gitWindow, name: "adkitchen", directory: directory,
                                                     branch: nil) == "Git: adkitchen")
        #expect(ComposableTabsWindowController.title(kind: .project, name: "adkitchen", directory: directory,
                                                     branch: "main") == "Code: adkitchen \u{2192} main")
        #expect(ComposableTabsWindowController.title(kind: .fileBrowser, name: "x", directory: directory,
                                                     branch: "main") == "Files: adkitchen")
    }
}
