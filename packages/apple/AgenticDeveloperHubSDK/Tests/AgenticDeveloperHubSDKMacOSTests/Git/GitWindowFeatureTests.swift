import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Git window feature: one window per repository, keyed by its canonical
/// top level (recipe `workspace/git/git-window`).
@Suite("GitWindowFeature", .serialized)
@MainActor
struct GitWindowFeatureTests {

    /// A feature over its own registry and its own remembered-roots setting, so
    /// nothing a test opens reaches the app's real list.
    private func makeFeature(_ openRoots: UserSetting<[String]>) -> GitWindowFeature {
        GitWindowFeature(
            commandRegistry: CommandRegistry(),
            resources: nil,
            userGrammarsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("git-window-grammars-\(UUID().uuidString)"),
            extensionGrammars: { nil },
            fileTypeOverride: { _ in nil },
            client: GitClient(configuration: .default),
            openRoots: openRoots
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
        let feature = makeFeature(setting)
        defer { feature.unregister() }

        let first = await feature.open(path: repository.url("sub"), activates: false)
        let controller = try #require(first)
        defer { controller.window?.close() }
        let second = await feature.open(path: repository.root, activates: false)

        let key = repository.root.standardizedFileURL.resolvingSymlinksInPath().path
        #expect(second === controller)
        #expect(controller.windowID == "git:" + key)
        #expect(setting.value == [key])
    }

    @Test("a directory outside any repository opens nothing and remembers nothing")
    func nonRepositoryReturnsNil() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-window-not-a-repository-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let setting = makeSetting()
        defer { setting.remove() }
        let feature = makeFeature(setting)
        defer { feature.unregister() }

        let controller = await feature.open(path: directory, activates: false)

        #expect(controller == nil)
        #expect(setting.value.isEmpty)
    }

    @Test("Open Git Window for Path takes exactly one non-empty string and ignores anything else")
    func openForPathTakesOneString() {
        #expect(GitWindowFeature.path(from: ["/tmp/repo"]) == "/tmp/repo")
        #expect(GitWindowFeature.path(from: []) == nil)
        #expect(GitWindowFeature.path(from: [42]) == nil)
        #expect(GitWindowFeature.path(from: [""]) == nil)
        #expect(GitWindowFeature.path(from: ["/a", "/b"]) == nil)
    }

    @Test("Open Git Window for Path with a missing or non-string argument opens no window")
    func openForPathIgnoresBadArguments() async throws {
        let registry = CommandRegistry()
        let setting = makeSetting()
        defer { setting.remove() }
        let feature = GitWindowFeature(
            commandRegistry: registry, resources: nil,
            userGrammarsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("git-window-grammars-\(UUID().uuidString)"),
            extensionGrammars: { nil }, fileTypeOverride: { _ in nil },
            client: GitClient(configuration: .default), openRoots: setting)
        defer { feature.unregister() }
        let command = try #require(registry.command(id: GitWindowFeature.CommandID.openForPath))

        _ = command.run([])
        _ = command.run([42])
        for _ in 0..<100 { await Task.yield() }

        #expect(setting.value.isEmpty)
    }
}
