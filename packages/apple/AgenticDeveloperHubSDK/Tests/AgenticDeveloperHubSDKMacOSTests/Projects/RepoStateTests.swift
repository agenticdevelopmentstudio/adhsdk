import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

final class RepoStateWatcherRelevanceTests: XCTestCase {

    func testBranchAndWorktreeFilesAreRelevant() {
        let paths = ["HEAD", "packed-refs", "refs/heads/main", "refs/heads/feature/x",
                     "worktrees/wt", "worktrees/wt/HEAD"]
        for path in paths {
            XCTAssertTrue(RepoStateWatcher.isRelevant(path), path)
        }
    }

    func testChurnIsNot() {
        for path in ["index", "objects/ab/cdef", "logs/HEAD", "refs/heads/main.lock", "refs/remotes/origin/main",
                     "worktrees/wt/index", "FETCH_HEAD", "ORIG_HEAD"] {
            XCTAssertFalse(RepoStateWatcher.isRelevant(path), path)
        }
    }

    func testEventsMapToTheirRepositoryOnce() {
        let first = UUID(), second = UUID()
        let dirs: [String: RepoStateWatcher.Repo] = [
            "/p/a/.git": (id: first, directory: URL(fileURLWithPath: "/p/a")),
            "/p/b/.git": (id: second, directory: URL(fileURLWithPath: "/p/b"))
        ]
        let repos = RepoStateWatcher.repos(
            touchedBy: ["/p/a/.git/HEAD", "/p/a/.git/refs/heads/x", "/p/b/.git/index", "/p/ab/.git/HEAD"],
            in: dirs)
        XCTAssertEqual(repos.map(\.id), [first])
    }
}

@MainActor
final class RepoStateRefresherTests: XCTestCase {

    /// A registry that keeps repository state in memory and counts the
    /// writes; it has no projects, which the refresher never asks for.
    private final class MemoryStore: ProjectRegistry, @unchecked Sendable {
        private let lock = NSLock()
        private var storedStates: [UUID: RepoStateSnapshot] = [:]
        private var saveCount = 0

        var states: [UUID: RepoStateSnapshot] { lock.withLock { storedStates } }
        var saves: Int { lock.withLock { saveCount } }

        func projects() async throws -> [GitRepo] { [] }
        func project(id: UUID) async throws -> GitRepo? { nil }
        func project(path: String) async throws -> GitRepo? { nil }
        func insert(_ project: GitRepo) async throws {}
        func update(_ project: GitRepo) async throws {}
        func markOpened(id: UUID, at date: Date) async throws {}
        func delete(id: UUID) async throws {}
        func repoState(id: UUID) async throws -> RepoStateSnapshot? { lock.withLock { storedStates[id] } }
        func saveRepoState(_ state: RepoStateSnapshot, id: UUID) async throws {
            lock.withLock {
                storedStates[id] = state
                saveCount += 1
            }
        }
        var changes: AsyncStream<ProjectRegistryChange> { AsyncStream { $0.finish() } }
    }

    private struct FixedReader: RepoStateReading {
        let branches: [String]
        func readState(at directory: URL) async throws -> RepoStateSnapshot {
            RepoStateSnapshot(
                checkouts: [.init(path: directory.path, branch: branches.first, isMain: true)],
                branches: branches, refreshedAt: Date())
        }
    }

    func testAChangeIsSavedAndAnnounced() async {
        let store = MemoryStore()
        let refresher = RepoStateRefresher(registry: store, reader: FixedReader(branches: ["main"]))
        var announced: [UUID] = []
        refresher.onChange = { id, _ in announced.append(id) }
        let id = UUID()
        await refresher.refresh(id, at: URL(fileURLWithPath: "/r"))
        XCTAssertEqual(store.states[id]?.branches, ["main"])
        XCTAssertEqual(announced, [id])
    }

    private struct FailingReader: RepoStateReading {
        struct Unreadable: Error {}
        func readState(at directory: URL) async throws -> RepoStateSnapshot { throw Unreadable() }
    }

    func testASweepLoadsTheRegistrysSnapshotsEvenWhenGitCannotBeRead() async throws {
        let store = MemoryStore()
        let id = UUID()
        let stored = RepoStateSnapshot(
            checkouts: [.init(path: "/r", branch: "feature", isMain: true)],
            branches: ["feature"], refreshedAt: Date())
        try await store.saveRepoState(stored, id: id)
        let refresher = RepoStateRefresher(registry: store, reader: FailingReader())
        XCTAssertNil(refresher.cachedState(forRepo: id))

        await refresher.sweep([(id: id, directory: URL(fileURLWithPath: "/r"))])

        XCTAssertEqual(refresher.cachedState(forRepo: id)?.branches, ["feature"])
    }

    func testAnUnchangedStateIsNotRewritten() async {
        let store = MemoryStore()
        let refresher = RepoStateRefresher(registry: store, reader: FixedReader(branches: ["main"]))
        let id = UUID()
        await refresher.refresh(id, at: URL(fileURLWithPath: "/r"))
        await refresher.refresh(id, at: URL(fileURLWithPath: "/r"))
        XCTAssertEqual(store.saves, 1)
    }

    func testSnapshotKnowsEachCheckoutsBranch() {
        let snapshot = RepoStateSnapshot(
            checkouts: [
                .init(path: "/r", branch: "main", isMain: true),
                .init(path: "/r/wt", branch: "x", isMain: false)
            ],
            branches: ["main", "x"], refreshedAt: Date())
        XCTAssertEqual(snapshot.branch(at: URL(fileURLWithPath: "/r/wt")), "x")
        XCTAssertEqual(snapshot.projectCheckouts.map(\.isMain), [true, false])
    }
}
