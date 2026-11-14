import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for FSEvents: records `start` and fires whatever change set a test hands it.
private final class FakeWatcher: GitRepositoryWatching {
    private(set) var started = false
    private var onChange: (@Sendable (Set<GitRepositoryChange>) -> Void)?

    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {
        started = true
        self.onChange = onChange
    }

    func stop() {
        onChange = nil
    }

    func fire(_ changes: Set<GitRepositoryChange>) {
        onChange?(changes)
    }
}

/// Collects `onChange` calls from the real watcher's debounce, which arrive on the main queue.
private final class ChangeRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [Set<GitRepositoryChange>] = []

    func record(_ changes: Set<GitRepositoryChange>) {
        lock.withLock { recorded.append(changes) }
    }

    var calls: [Set<GitRepositoryChange>] {
        lock.withLock { recorded }
    }
}

@Suite("GitRepositoryModel and its watcher", .serialized)
@MainActor
struct GitRepositoryModelTests {
    private static let epoch = 1_767_268_800
    private let client = GitClient(configuration: .default)

    private func makeModel(_ repository: GitTestRepository) -> (GitRepositoryModel, FakeWatcher) {
        let watcher = FakeWatcher()
        return (GitRepositoryModel(root: repository.root, client: client, watcher: watcher), watcher)
    }

    private func commitFile(_ repository: GitTestRepository, _ name: String, at offset: Int) async throws {
        try repository.write("\(name)\n", to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit(name, at: Self.epoch + offset)
    }

    @Test("start starts the watcher and loads refs, history with graph rows, and the working copy")
    func startLoadsRefsHistoryAndStatus() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", at: 100)
        try await commitFile(repository, "two.txt", at: 200)
        try await repository.run(["tag", "v1"])
        try repository.write("staged\n", to: "staged.txt")
        try await repository.run(["add", "--", "staged.txt"])
        try repository.write("loose\n", to: "loose.txt")

        let (model, watcher) = makeModel(repository)
        await model.start()

        #expect(watcher.started)
        #expect(model.refs.map(\.name) == ["main", "v1"])
        #expect(model.refs.first?.isHead == true)
        #expect(model.commits.map(\.subject) == ["two.txt", "one.txt"])
        #expect(model.graphRows.count == 2)
        #expect(model.staged == [GitFileChange(path: "staged.txt", status: .added)])
        #expect(model.unstaged == [GitFileChange(path: "loose.txt", status: .untracked)])
        #expect(model.unstaged.first?.isUntracked == true)
        #expect(model.stashes.isEmpty)
        #expect(model.submodules.isEmpty)
        #expect(model.worktrees.count == 1)
    }

    @Test("loadMore pages history and appends graph rows from the same layout")
    func historyPagesAppendGraphRows() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try await commitFile(repository, "c1.txt", at: 100)
        try await commitFile(repository, "c2.txt", at: 200)
        try await repository.run(["switch", "-c", "side"])
        try await commitFile(repository, "c3.txt", at: 300)
        try await repository.run(["switch", "main"])
        try await commitFile(repository, "c4.txt", at: 400)
        try await repository.run(["merge", "--no-ff", "side", "-m", "c5"],
                                 environment: GitTestRepository.dated(Self.epoch + 500))

        let (model, _) = makeModel(repository)
        await model.start()
        var query = GitLogQuery()
        query.limit = 2
        await model.setQuery(query)
        #expect(model.query == query)
        #expect(model.commits.count == 2)
        await model.loadMore()
        #expect(model.commits.count == 4)
        await model.loadMore()
        #expect(model.commits.count == 5)
        await model.loadMore()
        #expect(model.commits.count == 5)

        let whole = try await client.log(GitLogQuery(), in: repository.root)
        #expect(model.commits.map(\.id) == whole.map(\.id))
        var layout = CommitGraphLayout<String>()
        #expect(model.graphRows == layout.append(whole.map { (id: $0.id, parents: $0.parents) }))
        #expect(model.commit(whole[2].id) == whole[2])
        #expect(model.commit("0000") == nil)
    }

    @Test("refs(at:) joins refs to the commit they target")
    func refsAtCommitJoinsByTarget() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", at: 100)
        let first = try await repository.sha("HEAD")
        try await commitFile(repository, "two.txt", at: 200)
        let tip = try await repository.sha("HEAD")
        try await repository.run(["tag", "v1"])
        try await repository.run(["tag", "-a", "v2", "-m", "two"],
                                 environment: GitTestRepository.dated(Self.epoch + 200))
        try await repository.run(["branch", "old", first])

        let (model, _) = makeModel(repository)
        await model.start()

        #expect(model.refs(at: tip).map(\.name) == ["main", "v1", "v2"])
        #expect(model.refs(at: first).map(\.name) == ["old"])
        #expect(model.refs(at: "0000").isEmpty)
    }

    @Test("a refs change from the watcher after an outside checkout refreshes the refs")
    func externalBranchSwitchRefreshes() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", at: 100)

        let (model, watcher) = makeModel(repository)
        await model.start()
        #expect(model.refs.map(\.name) == ["main"])

        try await repository.run(["checkout", "-b", "x"])
        var token: AnyObject?
        typealias Waiter = CheckedContinuation<Set<GitRepositoryChange>, Never>
        let changes = await withCheckedContinuation { (continuation: Waiter) in
            var resumed = false
            token = model.observe { changes in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: changes)
            }
            watcher.fire([.refs])
        }
        _ = token

        #expect(changes == [.refs])
        #expect(model.refs.first { $0.name == "x" }?.isHead == true)
        #expect(model.refs.first { $0.name == "main" }?.isHead == false)
    }

    @Test("an unborn repository loads an empty history and lists its files")
    func unbornRepositoryLoadsEmptyHistory() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try repository.write("a\n", to: "a b.txt")

        let (model, _) = makeModel(repository)
        await model.start()

        #expect(model.commits.isEmpty)
        #expect(model.graphRows.isEmpty)
        #expect(model.refs.isEmpty)
        #expect(model.staged.isEmpty)
        #expect(model.unstaged == [GitFileChange(path: "a b.txt", status: .untracked)])
        await model.loadMore()
        #expect(model.commits.isEmpty)
    }

    @Test("a repository deleted underneath keeps its last state and nothing throws")
    func deletedRepositoryKeepsLastStateAndDoesNotThrow() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-repository-model")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", at: 100)
        try repository.write("changed\n", to: "one.txt")

        let (model, _) = makeModel(repository)
        await model.start()
        let refs = model.refs
        let commits = model.commits
        let rows = model.graphRows
        let unstaged = model.unstaged
        #expect(unstaged == [GitFileChange(path: "one.txt", status: .modified)])

        var notified: [Set<GitRepositoryChange>] = []
        let token = model.observe { notified.append($0) }
        repository.tearDown()
        await model.refresh([.refs, .history, .workingCopy, .operation])
        _ = token

        #expect(model.refs == refs)
        #expect(model.commits == commits)
        #expect(model.graphRows == rows)
        #expect(model.unstaged == unstaged)
        #expect(notified.isEmpty)
    }

    @Test("the watcher sorts paths into kinds of change")
    func watcherClassifiesPaths() {
        let classify = GitRepositoryWatcher.classify(relativePath:)
        #expect(classify(".git/HEAD") == [.refs, .history])
        #expect(classify(".git/refs/heads/main") == [.refs, .history])
        #expect(classify(".git/refs/stash") == [.refs, .history])
        #expect(classify(".git/packed-refs") == [.refs, .history])
        #expect(classify(".git/index") == [.workingCopy])
        #expect(classify(".git/MERGE_HEAD") == [.operation])
        #expect(classify(".git/CHERRY_PICK_HEAD") == [.operation])
        #expect(classify(".git/rebase-merge") == [.operation])
        #expect(classify(".git/rebase-merge/done") == [.operation])
        #expect(classify(".git/rebase-apply/next") == [.operation])
        #expect(classify(".git/worktrees/other") == [.refs])
        #expect(classify(".git/worktrees/other/HEAD") == [.refs])
        #expect(classify(".git/worktrees/other/index").isEmpty)
        #expect(classify(".git/worktrees/other/HEAD.lock").isEmpty)
        #expect(classify(".git/objects/ab/cdef").isEmpty)
        #expect(classify(".git/index.lock").isEmpty)
        #expect(classify(".git/refs/heads/main.lock").isEmpty)
        #expect(classify(".git/config").isEmpty)
        #expect(classify(".git/logs/HEAD").isEmpty)
        #expect(classify(".git").isEmpty)
        #expect(classify("src/a.swift") == [.workingCopy])
        #expect(classify(".gitignore") == [.workingCopy])
        #expect(classify(".github/workflows/ci.yml") == [.workingCopy])
        #expect(classify("dir/HEAD") == [.workingCopy])
        #expect(classify("") == [.workingCopy])
    }

    @Test("the watcher writes git-directory and common-directory paths as .git/<path>")
    func watcherRelativePaths() {
        let relative = { (path: String) in
            GitRepositoryWatcher.relativePath(of: path, root: "/r/wt", gitDirectory: "/r/main/.git/worktrees/wt",
                                              commonDirectory: "/r/main/.git")
        }
        #expect(relative("/r/main/.git/worktrees/wt/HEAD") == ".git/HEAD")
        #expect(relative("/r/main/.git/worktrees/wt/index") == ".git/index")
        #expect(relative("/r/main/.git/refs/heads/x") == ".git/refs/heads/x")
        #expect(relative("/r/wt/src/a b.swift") == "src/a b.swift")
        #expect(relative("/r/wt") == "")
        #expect(relative("/r/wtx/a") == nil)
        #expect(relative("/elsewhere") == nil)
    }

    @Test("a file system watcher keeps each root once and drops a root inside another")
    func fileSystemWatcherDistinctRoots() {
        #expect(FileSystemWatcher.distinctRoots(["/r/wt", "/r/wt/.git", "/r/wt/.git"]) == ["/r/wt"])
        #expect(FileSystemWatcher.distinctRoots(["/r/wt", "/r/main/.git/worktrees/wt", "/r/main/.git"])
            == ["/r/wt", "/r/main/.git"])
        #expect(FileSystemWatcher.distinctRoots(["/r/wt", "/r/wtx"]) == ["/r/wt", "/r/wtx"])
    }

    @Test("the watcher reports the union of a burst once, after the quiet period")
    func watcherDebouncesIntoOneUnion() async throws {
        let watcher = GitRepositoryWatcher(root: URL(fileURLWithPath: "/r/wt"),
                                           gitDirectory: URL(fileURLWithPath: "/r/wt/.git"),
                                           commonDirectory: URL(fileURLWithPath: "/r/wt/.git"))
        let recorder = ChangeRecorder()
        watcher.onChange = { recorder.record($0) }
        watcher.receive(paths: ["/r/wt/.git/index"])
        watcher.receive(paths: ["/r/wt/.git/objects/ab/cd", "/r/wt/.git/index.lock"])
        watcher.receive(paths: ["/r/wt/.git/refs/heads/main"])
        try await Task.sleep(for: .milliseconds(100))
        #expect(recorder.calls.isEmpty)
        try await Task.sleep(for: .milliseconds(700))
        #expect(recorder.calls == [[.workingCopy, .refs, .history]])

        watcher.receive(paths: ["/r/wt/.git/config"])
        try await Task.sleep(for: .milliseconds(700))
        #expect(recorder.calls.count == 1)
    }

    @Test("the real watcher reports refs for a branch switch in a repository under the temporary directory")
    func realWatcherReportsCheckoutUnderTemporaryDirectory() async throws {
        // The temporary directory is under /var -> /private/var: FSEvents reports the
        // /private spelling, so this fails unless the roots are canonicalised to match.
        let repository = try await GitTestRepository.make(prefix: "git-repository-watcher")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", at: 100)
        let gitDirectory = repository.url(".git")
        let watcher = GitRepositoryWatcher(root: repository.root, gitDirectory: gitDirectory,
                                           commonDirectory: gitDirectory)
        defer { watcher.stop() }
        let recorder = ChangeRecorder()
        watcher.start { recorder.record($0) }
        try await Task.sleep(for: .milliseconds(300))

        try await repository.run(["checkout", "-b", "x"])
        let deadline = Date().addingTimeInterval(10)
        while !recorder.calls.contains(where: { $0.contains(.refs) }), Date() < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(recorder.calls.contains { $0.contains(.refs) })
    }
}
