import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for FSEvents: the model refreshes itself after each action.
private final class QuietWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// Records what the session asks and answers every question as cancelled.
@MainActor
private final class RecordingPresenter: GitActionPresenting {
    var textTitles: [String] = []
    var failures: [String] = []

    func confirm(_ request: GitConfirmation) async -> Bool { false }

    func askForText(_ request: GitTextRequest) async -> [String]? {
        textTitles.append(request.title)
        return nil
    }

    func showFailure(title: String, message: String) {
        failures.append(title)
    }

    func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan? { nil }

    func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                           bases: [String]) async -> GitPullRequestDraft? { nil }
}

/// The Git window's toolbar (recipe `workspace/git/git-window`, "Toolbar"): seven verb
/// buttons (Undo last) then the Command Log toggle, in order, each aimed at the toolbar and
/// forwarding to its session.
@Suite("GitWindowToolbar", .serialized)
@MainActor
struct GitWindowToolbarTests {
    private let client = GitClient(configuration: .tests)

    private func makeSession(
        _ repository: GitTestRepository, presenter: RecordingPresenter
    ) async -> GitWindowSession {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: QuietWatcher())
        await model.start()
        let session = GitWindowSession(model: model, client: client, coloring: nil)
        for pane in [session.overviewPane, session.centre, session.commitPane] as [NSViewController] {
            pane.loadViewIfNeeded()
        }
        session.presenter = presenter
        return session
    }

    /// A repository with one commit on `main` and no remote.
    private func makeRepository() async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: "git-window-toolbar")
        try repository.write("one\n", to: "one.txt")
        try await repository.run(["add", "--", "one.txt"])
        try await repository.commit("one", at: 1_767_268_800)
        return repository
    }

    /// The selector a toolbar item sends, and the target it sends it to.
    private func wiring(_ item: WindowToolbarItem) -> (String, AnyObject?, Selector)? {
        guard case let .targetedButton(identifier, _, _, target, action) = item else { return nil }
        return (identifier.rawValue, target.object, action)
    }

    @Test("the eight items, in order, with their labels and symbols")
    func itemsInOrder() {
        let toolbar = GitWindowToolbar()
        let described: [String] = toolbar.items.compactMap { item in
            guard case let .targetedButton(identifier, symbol, label, _, _) = item else { return nil }
            return "\(identifier.rawValue) \(label) \(symbol)"
        }
        #expect(described == [
            "git.toolbar.fetch Fetch arrow.down.circle",
            "git.toolbar.pull Pull arrow.down.to.line",
            "git.toolbar.push Push arrow.up.to.line",
            "git.toolbar.branch Branch arrow.triangle.branch",
            "git.toolbar.stash Stash tray.and.arrow.down",
            "git.toolbar.pop Pop tray.and.arrow.up",
            "git.toolbar.undo Undo arrow.uturn.backward",
            "git.toolbar.commandLog Command Log list.bullet.rectangle"
        ])
    }

    @Test("a window without terminals has the seven verbs and no Command Log toggle")
    func noTerminalsNoCommandLog() {
        let identifiers = GitWindowToolbar(showsCommandLog: false).items.compactMap { wiring($0)?.0 }
        #expect(identifiers == [
            "git.toolbar.fetch", "git.toolbar.pull", "git.toolbar.push",
            "git.toolbar.branch", "git.toolbar.stash", "git.toolbar.pop", "git.toolbar.undo"
        ])
    }

    @Test("every item is aimed at the toolbar itself, with a selector it answers")
    func itemsTargetTheToolbar() {
        let toolbar = GitWindowToolbar()
        let wirings = toolbar.items.compactMap(wiring)
        #expect(wirings.count == 8)
        for (identifier, target, action) in wirings {
            #expect(target === toolbar, "\(identifier)")
            #expect(toolbar.responds(to: action), "\(identifier)")
        }
    }

    @Test("each button starts its session's action")
    func eachButtonStartsAnAction() async throws {
        let repository = try await makeRepository()
        defer { repository.tearDown() }
        let presenter = RecordingPresenter()
        let session = await makeSession(repository, presenter: presenter)
        let toolbar = GitWindowToolbar()
        toolbar.session = session

        let verbs = toolbar.items.compactMap(wiring).filter { $0.0 != "git.toolbar.commandLog" }
        #expect(verbs.count == 7)
        for (identifier, _, action) in verbs {
            session.actionTask = nil
            toolbar.perform(action, with: nil)
            #expect(session.isActing, "\(identifier)")
            let task = try #require(session.actionTask, "\(identifier)")
            await task.value
            #expect(!session.isActing, "\(identifier)")
        }
        // Branch and Stash asked their questions; Push found no remote; Pop had no stash;
        // Undo had no HEAD@{1}.
        #expect(presenter.textTitles == ["New Branch", "Stash Changes"])
        #expect(presenter.failures.contains("Push failed"))
    }

    @Test("Undo's tooltip names HEAD@{0}'s action and message, or is plain Undo")
    func undoToolTip() {
        let entry = GitReflogEntry(
            selector: "HEAD@{0}", sha: String(repeating: "a", count: 40),
            previousSha: String(repeating: "b", count: 40),
            action: "commit (amend)", message: "two", date: Date(timeIntervalSince1970: 0))
        #expect(GitWindowToolbar.undoToolTip(for: entry) == "Undo commit (amend): two")
        #expect(GitWindowToolbar.undoToolTip(for: nil) == "Undo")
        let bare = GitReflogEntry(
            selector: "HEAD@{0}", sha: String(repeating: "a", count: 40), previousSha: nil,
            action: "reset", message: "", date: Date(timeIntervalSince1970: 0))
        #expect(GitWindowToolbar.undoToolTip(for: bare) == "Undo reset")
    }

    @Test("without a session or a window, updating Undo is harmless")
    func updateUndoWithoutWindow() {
        let toolbar = GitWindowToolbar()
        toolbar.followUndo()
        #expect(toolbar.undoButton == nil)
    }

    @Test("with no session, a button does nothing")
    func noSessionDoesNothing() {
        let toolbar = GitWindowToolbar()
        for (_, _, action) in toolbar.items.compactMap(wiring) {
            toolbar.perform(action, with: nil)
        }
    }
}
