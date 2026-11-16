import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Git window feature: one window per repository, keyed by its canonical
/// top level (recipe `workspace/git/git-window`).
@Suite("GitWindowFeature", .serialized)
@MainActor
struct GitWindowFeatureTests {

    /// A database of its own, deleted with `removeDatabase`.
    private let databaseURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("git-window-feature-\(UUID().uuidString).db")

    private func removeDatabase() {
        try? FileManager.default.removeItem(at: databaseURL)
    }

    /// A feature over its own registry, database, window manager and remembered-roots
    /// setting, so nothing a test opens reaches the app's real ones.
    private func makeFeature(
        _ openRoots: UserSetting<[String]>, registry: CommandRegistry = CommandRegistry(),
        notInRepository: @escaping @MainActor (URL) -> Void = { _ in }
    ) throws -> GitWindowFeature {
        let database = try ProjectDatabase(path: databaseURL.path)
        let windows = ProjectWindowManager()
        windows.attach(database: database)
        windows.gitClient = GitClient(configuration: .default)
        return GitWindowFeature(
            commandRegistry: registry,
            database: database,
            windows: windows,
            resources: nil,
            userGrammarsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("git-window-grammars-\(UUID().uuidString)"),
            extensionGrammars: { nil },
            fileTypeOverride: { _ in nil },
            client: GitClient(configuration: .default),
            openRoots: openRoots,
            notInRepository: notInRepository
        )
    }

    private func makeSetting() -> UserSetting<[String]> {
        UserSetting<[String]>("test_open_git_window_roots_\(UUID().uuidString)", default: [])
    }

    @Test("a subdirectory and its root open one window, keyed by the canonical top level")
    func openTwiceReturnsSameController() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature")
        defer { repository.tearDown() }
        try FileManager.default.createDirectory(at: repository.url("sub"), withIntermediateDirectories: true)
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }

        let first = await feature.open(path: repository.url("sub"), activates: false)
        let controller = try #require(first)
        defer { controller.window?.close() }
        let second = await feature.open(path: repository.root, activates: false)

        let key = repository.root.standardizedFileURL.resolvingSymlinksInPath().path
        #expect(second === controller)
        #expect(controller.project.repo.path == key)
        #expect(controller.project.repo.kind == .gitWindow)
        #expect(feature.sessions[controller.project.id] != nil, "the layout made the window's session")
        #expect(controller.window?.title.hasPrefix("Git: ") == true)
        #expect(setting.value == [key])

        controller.window?.close()
        #expect(feature.sessions.isEmpty, "closing the window drops its session")
    }

    @Test("the window's toolbar carries the six verbs, aimed at a toolbar kept beside the session")
    func toolbarIsWired() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature-toolbar")
        defer { repository.tearDown() }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }

        let controller = try #require(await feature.open(path: repository.root, activates: false))
        defer { controller.window?.close() }
        let identifiers = ProjectWindowTestSupport.buildToolbarItems(controller).map(\.rawValue)
        let verbs = ["fetch", "pull", "push", "branch", "stash", "pop"].map { "git.toolbar.\($0)" }

        #expect(Array(identifiers.prefix(7)) == ["project.toolbar.title"] + verbs)
        let toolbar = try #require(feature.toolbars[controller.project.id])
        #expect(toolbar.session === feature.sessions[controller.project.id])
        let fetch = try #require(
            controller.toolbarDelegate.button(for: NSToolbarItem.Identifier("git.toolbar.fetch")))
        #expect(fetch.target === toolbar)
        #expect(feature.sessions[controller.project.id]?.presenter != nil)

        controller.window?.close()
        #expect(feature.toolbars.isEmpty, "closing the window drops its toolbar")
    }

    @Test("closing a window forgets its root and, a turn later, deletes its row")
    func closeDiscardsTheRow() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature-close")
        defer { repository.tearDown() }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }
        let database = try ProjectDatabase(path: databaseURL.path)
        let key = repository.root.canonicalFileURL.path

        let controller = try #require(await feature.open(path: repository.root, activates: false))
        #expect(try database.repo(path: key, kind: .gitWindow) != nil)
        controller.window?.close()
        #expect(setting.value.isEmpty)
        await nextMainTurn()

        #expect(try database.repo(path: key, kind: .gitWindow) == nil)
    }

    @Test("restore reopens a remembered repository quietly, drops the rest and deletes rows not reopening")
    func restoreDiscardsForgottenRows() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature-restore")
        defer { repository.tearDown() }
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-window-gone-\(UUID().uuidString)").path
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let key = repository.root.canonicalFileURL.path
        setting.value = [missing, key]
        let feature = try makeFeature(setting)
        defer { feature.unregister() }
        let database = try ProjectDatabase(path: databaseURL.path)
        let stale = GitRepo(path: "/nowhere/closed-before-discard", name: "stale", kind: .gitWindow)
        try database.insert(stale)

        feature.restoreOpenWindows()

        #expect(setting.value == [key])
        #expect(try database.repo(path: stale.path, kind: .gitWindow) == nil)
        let row = try #require(try database.repo(path: key, kind: .gitWindow))
        #expect(Array(feature.sessions.keys) == [row.id], "the remembered repository reopened")
        let controller = try #require(await feature.open(path: repository.root, activates: false))
        #expect(controller.project.id == row.id)
        controller.window?.close()
    }

    @Test("an open window found without activating is not ordered front")
    func quietLookupLeavesTheWindow() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature-quiet")
        defer { repository.tearDown() }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }

        let controller = try #require(await feature.open(path: repository.root, activates: false))
        defer { controller.window?.close() }
        controller.window?.orderOut(nil)
        let again = await feature.open(path: repository.root, activates: false)

        #expect(again === controller)
        #expect(controller.window?.isVisible == false)
    }

    @Test("removing a worktree closes the window open on it, and nothing else")
    func removedWorktreeClosesItsWindow() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-feature-worktree")
        defer { repository.tearDown() }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }

        let controller = try #require(await feature.open(path: repository.root, activates: false))
        defer { controller.window?.close() }
        feature.closeWindow(at: URL(fileURLWithPath: "/nowhere/else", isDirectory: true))
        #expect(controller.window?.isVisible == true)

        feature.closeWindow(at: repository.root.canonicalFileURL)
        #expect(controller.window?.isVisible == false)
        #expect(feature.sessions.isEmpty)
        #expect(setting.value.isEmpty)
    }

    /// Lets work queued on the main queue (a closed window's row discard) run.
    private func nextMainTurn() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    @Test("a directory outside any repository opens nothing and remembers nothing")
    func nonRepositoryReturnsNil() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-window-not-a-repository-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting)
        defer { feature.unregister() }

        let controller = await feature.open(path: directory, activates: false)

        #expect(controller == nil)
        #expect(setting.value.isEmpty)
    }

    @Test("a chosen folder outside any repository tells the user, and a repository does not")
    func chosenNonRepositoryTellsTheUser() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-window-chosen-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try await GitTestRepository.make(prefix: "git-window-chosen-repo")
        defer { repository.tearDown() }
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        var told: [URL] = []
        let feature = try makeFeature(setting) { told.append($0) }
        defer { feature.unregister() }

        await feature.openChosen(directory)
        #expect(told == [directory])
        #expect(setting.value.isEmpty)

        let controller = await feature.openChosen(repository.root)
        defer { controller?.window?.close() }
        #expect(controller != nil)
        #expect(told == [directory], "a repository opens its window and says nothing")
    }

    @Test("the not-in-a-repository alert names the folder, has one OK and closes on it")
    func notInRepositoryAlert() {
        let folder = URL(fileURLWithPath: "/tmp/Downloads", isDirectory: true)
        #expect(GitWindowFeature.notInRepositoryMessage(for: folder) == "Downloads is not in a Git repository")
        var closed = 0
        let alert = NotInRepositoryAlert(message: GitWindowFeature.notInRepositoryMessage(for: folder)) {
            closed += 1
        }
        #expect(alert.alert.messageText == "Downloads is not in a Git repository")
        #expect(alert.alert.buttons.map(\.title) == ["OK"])
        #expect(alert.alert.buttons.first?.accessibilityIdentifier() == "git.prompt.ok")
        alert.alert.buttons.first?.performClick(nil)
        #expect(closed == 1)
    }

    @Test("Open Git Window for Path takes exactly one non-empty string and ignores anything else")
    func openForPathTakesOneString() {
        #expect(GitWindowFeature.path(from: ["/tmp/repo"]) == "/tmp/repo")
        #expect(GitWindowFeature.path(from: []) == nil)
        #expect(GitWindowFeature.path(from: [42]) == nil)
        #expect(GitWindowFeature.path(from: [""]) == nil)
        #expect(GitWindowFeature.path(from: ["/a", "/b"]) == nil)
    }

    @Test("Undo Last Git Action is registered and contributed to the Git menu, disabled with no Git window key")
    func undoCommand() throws {
        let registry = CommandRegistry()
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting, registry: registry)
        defer { feature.unregister() }
        let command = try #require(registry.command(id: GitWindowFeature.undoCommandID))

        #expect(GitWindowFeature.undoCommandID == "git.action.undoLastAction")
        #expect(command.title == "Undo Last Git Action")
        #expect(command.category == "Git")
        #expect(!command.isEnabled())
        #expect(command.run([]) == nil)
        let contribution = try #require(feature.menuContributions.first { $0.title == "Undo Last Git Action" })
        #expect(contribution.slot == .git)
        #expect(contribution.order == 10)
    }

    @Test("Open Git Window for Path with a missing or non-string argument opens no window")
    func openForPathIgnoresBadArguments() async throws {
        let registry = CommandRegistry()
        let setting = makeSetting()
        defer { setting.remove() }
        defer { removeDatabase() }
        let feature = try makeFeature(setting, registry: registry)
        defer { feature.unregister() }
        let command = try #require(registry.command(id: GitWindowFeature.CommandID.openForPath))

        _ = command.run([])
        _ = command.run([42])
        #expect(feature.openTask == nil, "a bad argument starts no open")
        #expect(setting.value.isEmpty)

        // A good argument starts one, which is how the bad ones are known to have been refused.
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-window-open-for-path-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = command.run([directory.path])
        let open = try #require(feature.openTask)
        await open.value
        #expect(setting.value.isEmpty, "not a repository, so nothing is remembered")
    }
}
