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

    private final class MemoryStore: RepoStateStore {
        var states: [UUID: RepoStateSnapshot] = [:]
        var saves = 0
        func cachedRepoState(forRepo repoID: UUID) -> RepoStateSnapshot? { states[repoID] }
        func saveRepoState(_ state: RepoStateSnapshot, forRepo repoID: UUID) { states[repoID] = state; saves += 1 }
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
        let refresher = RepoStateRefresher(store: store, reader: FixedReader(branches: ["main"]))
        var announced: [UUID] = []
        refresher.onChange = { id, _ in announced.append(id) }
        let id = UUID()
        await refresher.refresh(id, at: URL(fileURLWithPath: "/r"))
        XCTAssertEqual(store.states[id]?.branches, ["main"])
        XCTAssertEqual(announced, [id])
    }

    func testAnUnchangedStateIsNotRewritten() async {
        let store = MemoryStore()
        let refresher = RepoStateRefresher(store: store, reader: FixedReader(branches: ["main"]))
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
