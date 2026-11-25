import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitClient operations: merge, rebase, their steps and the operation state")
struct GitClientOperationTests {
    /// No global or system configuration, and `GIT_EDITOR=false`: an editor that fails at once.
    /// Every continue below would fail on it, so each one passing proves `perform` sets
    /// `GIT_EDITOR=true` over the configuration's own environment.
    private let client = GitClient(configuration: GitClientConfiguration(
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1", "GIT_EDITOR": "false"]
    ))

    private func commitFile(_ repository: GitTestRepository, _ path: String, _ text: String,
                            message: String) async throws {
        try repository.write(text, to: path)
        try await repository.run(["add", path])
        try await repository.run(["commit", "-q", "-m", message])
    }

    private func subjects(_ repository: GitTestRepository, in directory: URL? = nil) async throws -> [String] {
        var query = GitLogQuery()
        query.revisions = ["HEAD"]
        return try await client.log(query, in: directory ?? repository.root).map(\.subject)
    }

    private func failure(_ body: () async throws -> Void) async -> GitClientError? {
        do {
            try await body()
            return nil
        } catch let error as GitClientError {
            return error
        } catch {
            return nil
        }
    }

    /// `main` and `topic` both change `a.txt` from a shared base; `main` is checked out.
    private func divergedRepository(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "a.txt", "base\n", message: "base")
            try await repository.run(["branch", "topic"])
            try await commitFile(repository, "a.txt", "main\n", message: "main change")
            try await repository.run(["switch", "-q", "topic"])
            try await commitFile(repository, "a.txt", "topic\n", message: "topic change")
            try await repository.run(["switch", "-q", "main"])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// `feature` has three commits, the first conflicting with `main`'s one; `feature` is checked out.
    private func rebaseRepository(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "a.txt", "base\n", message: "base")
            try await repository.run(["branch", "feature"])
            try await commitFile(repository, "a.txt", "main\n", message: "main change")
            try await repository.run(["switch", "-q", "feature"])
            try await commitFile(repository, "a.txt", "feature\n", message: "feature one")
            try await commitFile(repository, "b.txt", "two\n", message: "feature two")
            try await commitFile(repository, "c.txt", "three\n", message: "feature three")
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    @Test("a repository with no operation in progress is none")
    func noOperation() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-op-none")
        defer { repository.tearDown() }
        #expect(try await client.operationState(in: repository.root) == .none)
        try await commitFile(repository, "a.txt", "base\n", message: "base")
        #expect(try await client.operationState(in: repository.root) == .none)
    }

    @Test("a conflicting merge throws and leaves merging their commit; abort returns to none and a clean tree")
    func conflictingMergeThenAbort() async throws {
        let repository = try await divergedRepository("git-op-merge")
        defer { repository.tearDown() }
        let theirs = try await repository.sha("topic")
        let error = await failure {
            try await client.perform(.merge(ref: "topic", fastForward: .allowed), in: repository.root)
        }
        guard case .commandFailed(let verb, _, _) = error else {
            Issue.record("expected commandFailed, got \(String(describing: error))")
            return
        }
        #expect(verb == "merge")
        let state = try await client.operationState(in: repository.root)
        #expect(state == .merging(head: theirs))
        #expect(!state.allowsSkip)

        try await client.perform(.operation(.merge, .abort), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
        let status = try await client.status(in: repository.root)
        #expect(status.stagedFiles.isEmpty)
        #expect(status.unstagedFiles.isEmpty)
    }

    @Test("merge-skip is refused before anything runs")
    func mergeSkipRefused() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-op-merge-skip")
        defer { repository.tearDown() }
        let error = await failure { try await client.perform(.operation(.merge, .skip), in: repository.root) }
        #expect(error == .invalidArgument(verb: "merge", argument: "--skip"))
    }

    @Test("a conflicting rebase stops at step 1 of 3; resolving and continuing finishes without an editor")
    func rebaseStopsThenContinues() async throws {
        let repository = try await rebaseRepository("git-op-rebase")
        defer { repository.tearDown() }
        let onto = try await repository.sha("main")
        let error = await failure { try await client.perform(.rebase(onto: "main"), in: repository.root) }
        #expect(error != nil)
        #expect(try await client.operationState(in: repository.root)
                    == .rebasing(branch: "feature", onto: onto, step: 1, total: 3, interactive: false))

        try repository.write("resolved\n", to: "a.txt")
        try await client.perform(.stage(paths: ["a.txt"]), in: repository.root)
        try await client.perform(.operation(.rebase, .continue), in: repository.root)

        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(try await subjects(repository)
                    == ["feature three", "feature two", "feature one", "main change", "base"])
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "resolved\n")
    }

    @Test("a rebase -i started outside the client reads as interactive")
    func interactiveRebaseIsInteractive() async throws {
        let repository = try await rebaseRepository("git-op-rebase-i")
        defer { repository.tearDown() }
        let onto = try await repository.sha("main")
        await #expect(throws: GitTestRepository.CommandFailed.self) {
            try await repository.run(["rebase", "-i", "main"],
                                     environment: ["GIT_SEQUENCE_EDITOR": "true", "GIT_EDITOR": "true"])
        }
        #expect(try await client.operationState(in: repository.root)
                    == .rebasing(branch: "feature", onto: onto, step: 1, total: 3, interactive: true))
        try await client.perform(.operation(.rebase, .abort), in: repository.root)
    }

    @Test("skip drops the stopped commit and carries on")
    func rebaseSkipDropsTheCommit() async throws {
        let repository = try await rebaseRepository("git-op-rebase-skip")
        defer { repository.tearDown() }
        _ = await failure { try await client.perform(.rebase(onto: "main"), in: repository.root) }
        #expect(try await client.operationState(in: repository.root).allowsSkip)

        try await client.perform(.operation(.rebase, .skip), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(try await subjects(repository) == ["feature three", "feature two", "main change", "base"])
    }

    @Test("a stopped cherry-pick is cherry-picking its commit; a stopped revert is reverting its commit")
    func cherryPickAndRevertStates() async throws {
        let repository = try await divergedRepository("git-op-pick")
        defer { repository.tearDown() }
        let picked = try await repository.sha("topic")
        _ = await failure { try await client.perform(.cherryPick(commit: picked, mainline: nil), in: repository.root) }
        #expect(try await client.operationState(in: repository.root) == .cherryPicking(commit: picked))
        try await client.perform(.operation(.cherryPick, .abort), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)

        try await commitFile(repository, "a.txt", "later\n", message: "later change")
        let reverted = try await repository.sha("HEAD~1")
        _ = await failure { try await client.perform(.revert(commit: reverted, mainline: nil), in: repository.root) }
        #expect(try await client.operationState(in: repository.root) == .reverting(commit: reverted))
        try await client.perform(.operation(.revert, .abort), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
    }

    @Test("a linked worktree reports its own rebase; the main worktree reports none")
    func linkedWorktreeRebase() async throws {
        let repository = try await rebaseRepository("git-op-worktree")
        defer { repository.tearDown() }
        try await repository.run(["switch", "-q", "main"])
        let linked = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-op-worktree-linked-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: linked) }
        try await repository.run(["worktree", "add", "-q", linked.path, "feature"])
        let onto = try await repository.sha("main")

        _ = await failure { try await client.perform(.rebase(onto: "main"), in: linked) }
        #expect(try await client.operationState(in: linked)
                    == .rebasing(branch: "feature", onto: onto, step: 1, total: 3, interactive: false))
        #expect(try await client.operationState(in: repository.root) == .none)

        try await client.perform(.operation(.rebase, .abort), in: linked)
        #expect(try await client.operationState(in: linked) == .none)
    }

    @Test("merge never fast-forwarding makes a two-parent commit; only fast-forward fails on diverged branches")
    func fastForwardRules() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-op-ff")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "base\n", message: "base")
        try await repository.run(["switch", "-q", "-c", "topic"])
        try await commitFile(repository, "b.txt", "topic\n", message: "topic change")
        try await repository.run(["switch", "-q", "main"])

        try await client.perform(.merge(ref: "topic", fastForward: .never), in: repository.root)
        let parents = try await repository.run(["rev-list", "--parents", "-n", "1", "HEAD"])
            .split(separator: " ")
        #expect(parents.count == 3)
        #expect(try await client.operationState(in: repository.root) == .none)

        try await repository.run(["switch", "-q", "topic"])
        try await commitFile(repository, "c.txt", "more\n", message: "more topic")
        try await repository.run(["switch", "-q", "main"])
        try await commitFile(repository, "d.txt", "main\n", message: "main change")
        let head = try await repository.sha("HEAD")
        let error = await failure {
            try await client.perform(.merge(ref: "topic", fastForward: .only), in: repository.root)
        }
        guard case .commandFailed = error else {
            Issue.record("expected commandFailed, got \(String(describing: error))")
            return
        }
        #expect(try await repository.sha("HEAD") == head)
        #expect(try await client.operationState(in: repository.root) == .none)
    }
}
