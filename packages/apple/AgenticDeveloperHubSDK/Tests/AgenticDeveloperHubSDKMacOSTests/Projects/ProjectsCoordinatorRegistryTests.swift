import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A coordinator whose registry is not its own window-state file — the shape
/// an app on a shared registry has. The registry here is a second
/// `ProjectDatabase`, which is a `ProjectRegistry` like any other, so the
/// coordinator mirrors it into `windowState` exactly as it would adhd's.
@MainActor
final class ProjectsCoordinatorRegistryTests: XCTestCase {

    private var root: URL!
    private var registry: ProjectDatabase!
    private var windowState: ProjectDatabase!
    private var coordinator: ProjectsCoordinator!

    /// The registry as the coordinator sees it: through the protocol.
    private var shared: any ProjectRegistry { registry }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = TestTempDirectory.make(label: "projects-coordinator-registry-test")
        root = directory.appendingPathComponent("code", isDirectory: true).standardizedFileURL
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        registry = try ProjectDatabase(path: directory.appendingPathComponent("Registry.db").path)
        windowState = try ProjectDatabase(path: directory.appendingPathComponent("Projects.db").path)
    }

    override func tearDownWithError() throws {
        coordinator?.stop()
        coordinator = nil
        registry = nil
        windowState = nil
        try super.tearDownWithError()
    }

    // MARK: - Scanning

    func testAScanWritesWhatItFindsThroughTheRegistry() async throws {
        let alpha = try makeRepo("alpha")
        coordinator = try makeCoordinator()

        coordinator.scan(showingProgress: false)
        try await waitUntil { !self.coordinator.isScanning }

        let inRegistry = try await shared.projects()
        XCTAssertEqual(inRegistry.map(\.path), [alpha.path])
        let project = try XCTUnwrap(inRegistry.first)
        XCTAssertEqual(coordinator.repos.map(\.id), [project.id])
        // The local copy holds the same row, under the same id, for the
        // window state that hangs off it.
        XCTAssertEqual(try windowState.repo(id: project.id)?.path, alpha.path)
    }

    /// A registry that has not been given this app's projects yet finds each
    /// as new; inserted under the local row's id, the local layout survives.
    func testAScanAdoptsTheIDOfTheLocalRowAtTheSamePath() async throws {
        let alpha = try makeRepo("alpha")
        let local = GitRepo(path: alpha.path, name: "alpha (mine)")
        try windowState.insert(local)
        let leaf = LayoutNode.leaf(contentType: ComposableTabsViewID("test.editor"), paneLabel: nil)
        let tab = TabRecord(edge: .left, title: "tab", root: leaf)
        try windowState.saveTabs([tab], activeTabID: tab.id, repoID: local.id)
        coordinator = try makeCoordinator()

        coordinator.scan(showingProgress: false)
        try await waitUntil { !self.coordinator.isScanning }

        let inRegistry = try await shared.project(path: alpha.path)
        XCTAssertEqual(inRegistry?.id, local.id)
        XCTAssertEqual(inRegistry?.name, "alpha (mine)")
        XCTAssertEqual(try windowState.loadTabs(repoID: local.id).tabs.map(\.id), [tab.id])
    }

    // MARK: - Following the registry

    /// Another app's write reaches this coordinator's list and its local copy
    /// over the registry's change feed, with no scan.
    func testARegistryChangeReachesTheList() async throws {
        coordinator = try makeCoordinator()
        var project = GitRepo(path: root.appendingPathComponent("beta").path, name: "beta")

        try await shared.insert(project)
        try await waitUntil { self.coordinator.repo(id: project.id) != nil }
        XCTAssertEqual(try windowState.repo(id: project.id)?.name, "beta")

        project.name = "beta renamed"
        try await shared.update(project)
        try await waitUntil { self.coordinator.repo(id: project.id)?.name == "beta renamed" }
        XCTAssertEqual(try windowState.repo(id: project.id)?.name, "beta renamed")

        try await shared.delete(id: project.id)
        try await waitUntil { self.coordinator.repo(id: project.id) == nil }
        XCTAssertNil(try windowState.repo(id: project.id))
    }

    func testTheRegistrysListReplacesTheLocalCopyOnLoad() async throws {
        let stale = GitRepo(path: root.appendingPathComponent("stale").path, name: "stale")
        try windowState.insert(stale)
        let fromRegistry = GitRepo(path: root.appendingPathComponent("shared").path, name: "shared")
        try await shared.insert(fromRegistry)
        coordinator = try makeCoordinator()
        XCTAssertEqual(coordinator.repos.map(\.id), [stale.id])

        await coordinator.loadFromRegistry()

        XCTAssertEqual(coordinator.repos.map(\.id), [fromRegistry.id])
        XCTAssertNotNil(try windowState.repo(id: fromRegistry.id))
    }

    /// A change the feed applies while the load's read is out is newer than
    /// the list the read brings back, and survives it.
    func testAChangeDuringTheLoadIsNotUndoneByIt() async throws {
        let gated = GatedRegistry(inner: registry)
        coordinator = try ProjectsCoordinator(
            registry: gated,
            windowState: windowState,
            scanner: GitRepoScanner(roots: [root]),
            commandRegistry: CommandRegistry())

        let load = Task { await self.coordinator.loadFromRegistry() }
        try await waitUntil { gated.hasRead }
        let added = GitRepo(path: root.appendingPathComponent("gamma").path, name: "gamma")
        try await shared.insert(added)
        try await waitUntil { self.coordinator.repo(id: added.id) != nil }

        gated.open()
        await load.value

        XCTAssertNotNil(coordinator.repo(id: added.id), "the older list must not drop the newer project")
        XCTAssertNotNil(try windowState.repo(id: added.id))
    }

    // MARK: - Helpers

    /// A registry whose `projects()` reads its list at once and then holds
    /// the answer until `open()`, the way a slow daemon round trip does.
    private final class GatedRegistry: ProjectRegistry, @unchecked Sendable {
        let inner: any ProjectRegistry
        private let lock = NSLock()
        private var read = false
        private var isOpen = false

        init(inner: any ProjectRegistry) { self.inner = inner }

        var hasRead: Bool { lock.withLock { read } }
        func open() { lock.withLock { isOpen = true } }

        func projects() async throws -> [GitRepo] {
            let list = try await inner.projects()
            lock.withLock { read = true }
            while !lock.withLock({ isOpen }) { try await Task.sleep(nanoseconds: 10_000_000) }
            return list
        }
        func project(id: UUID) async throws -> GitRepo? { try await inner.project(id: id) }
        func project(path: String) async throws -> GitRepo? { try await inner.project(path: path) }
        func insert(_ project: GitRepo) async throws { try await inner.insert(project) }
        func update(_ project: GitRepo) async throws { try await inner.update(project) }
        func markOpened(id: UUID, at date: Date) async throws { try await inner.markOpened(id: id, at: date) }
        func delete(id: UUID) async throws { try await inner.delete(id: id) }
        func repoState(id: UUID) async throws -> RepoStateSnapshot? { try await inner.repoState(id: id) }
        func saveRepoState(_ state: RepoStateSnapshot, id: UUID) async throws {
            try await inner.saveRepoState(state, id: id)
        }
        var changes: AsyncStream<ProjectRegistryChange> { inner.changes }
    }

    private func makeCoordinator() throws -> ProjectsCoordinator {
        try ProjectsCoordinator(
            registry: registry,
            windowState: windowState,
            scanner: GitRepoScanner(roots: [root]),
            commandRegistry: CommandRegistry())
    }

    /// A directory the scanner takes for a repository: `.git` with a `HEAD`.
    private func makeRepo(_ name: String) throws -> URL {
        let directory = root.appendingPathComponent(name, isDirectory: true)
        let gitDirectory = directory.appendingPathComponent(".git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        try "[core]\n\tbare = false\n".write(
            to: gitDirectory.appendingPathComponent("config"), atomically: true, encoding: .utf8)
        try "ref: refs/heads/main\n".write(
            to: gitDirectory.appendingPathComponent("HEAD"), atomically: true, encoding: .utf8)
        return directory.standardizedFileURL
    }

    /// Polls `condition` on the main actor, yielding between looks so the
    /// coordinator's tasks run.
    private func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("condition not met within \(timeout)s", file: file, line: line)
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
