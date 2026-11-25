import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitClient conflicts, interactive rebase, worktrees and submodules", .timeLimit(.minutes(2)))
struct GitClientConflictTests {
    /// No global or system configuration, `GIT_EDITOR=false` (so a squash that kept its
    /// combined message proves `perform` set `GIT_EDITOR=true`), and `protocol.file.allow`
    /// for the local-path submodule clone. It goes in `GIT_CONFIG_PARAMETERS`, the variable
    /// `-c` writes, because git hands that one on to a submodule's clone and strips
    /// `GIT_CONFIG_COUNT`.
    private let client = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL, timeout: 60, extraEnvironment: [
        "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1", "GIT_EDITOR": "false",
        "GIT_CONFIG_PARAMETERS": "'protocol.file.allow=always'"
    ]))

    private func commitFile(_ repository: GitTestRepository, _ path: String, _ text: String,
                            message: String) async throws {
        try repository.write(text, to: path)
        try await repository.run(["add", path])
        try await repository.run(["commit", "-q", "-m", message])
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

    private func history(_ repository: GitTestRepository) async throws -> [GitCommit] {
        var query = GitLogQuery()
        query.revisions = ["main..HEAD"]
        return try await client.log(query, in: repository.root)
    }

    private func helperExists(_ repository: GitTestRepository) async throws -> Bool {
        let helper = try await client.gitPath(GitClient.rebaseHelperName, in: repository.root)
        return FileManager.default.fileExists(atPath: helper.path)
    }

    /// `main` has one commit; `feature`, checked out, adds `one.txt`, `two.txt` and `three.txt`
    /// in three commits, so any order of them applies cleanly.
    private func featureRepository(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "base.txt", "base\n", message: "base")
            try await repository.run(["switch", "-q", "-c", "feature"])
            try await commitFile(repository, "one.txt", "1\n", message: "add one")
            try await commitFile(repository, "two.txt", "2\n", message: "add two")
            try await commitFile(repository, "three.txt", "3\n", message: "add three")
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// Plans the rebase onto `main`, lets `edit` change it, and runs it.
    private func rebase(_ repository: GitTestRepository,
                        _ edit: (inout [GitRebaseEntry]) -> Void) async throws {
        var plan = try await client.rebasePlan(onto: "main", in: repository.root)
        edit(&plan.entries)
        try await client.perform(.interactiveRebase(plan), in: repository.root)
    }

    // MARK: - Rebase plans

    @Test("rebasePlan lists the branch's commits oldest first, all picked, onto resolved")
    func planOldestFirst() async throws {
        let repository = try await featureRepository("rebase-plan")
        defer { repository.tearDown() }
        let plan = try await client.rebasePlan(onto: "main", in: repository.root)
        #expect(plan.onto == (try await repository.sha("main")))
        #expect(plan.entries.map(\.subject) == ["add one", "add two", "add three"])
        #expect(plan.entries.map(\.action) == [.pick, .pick, .pick])
        #expect(plan.entries[0].commit == (try await repository.sha("HEAD~2")))
    }

    @Test("rebasePlan refuses a range holding a merge, an empty range, and an unknown commit")
    func planRefusals() async throws {
        let repository = try await featureRepository("rebase-plan-refusals")
        defer { repository.tearDown() }
        let empty = await failure { _ = try await client.rebasePlan(onto: "HEAD", in: repository.root) }
        guard case .invalidArgument("rebase", _)? = empty else {
            Issue.record("empty range: \(String(describing: empty))")
            return
        }
        let unknown = await failure { _ = try await client.rebasePlan(onto: "nowhere", in: repository.root) }
        #expect(unknown == .invalidArgument(verb: "rebase", argument: "“nowhere” names no commit."))

        try await repository.run(["switch", "-q", "-c", "side", "main"])
        try await commitFile(repository, "side.txt", "s\n", message: "side")
        try await repository.run(["switch", "-q", "feature"])
        try await repository.run(["merge", "-q", "--no-ff", "--no-edit", "side"])
        let merged = await failure { _ = try await client.rebasePlan(onto: "main", in: repository.root) }
        guard case .invalidArgument("rebase", let reason)? = merged else {
            Issue.record("merge: \(String(describing: merged))")
            return
        }
        #expect(reason.contains("merge commit"))
    }

    @Test("commitMessages gives every commit in the plan's range its full message, in one call")
    func commitMessagesForTheRange() async throws {
        let repository = try await featureRepository("rebase-messages")
        defer { repository.tearDown() }
        try repository.write("4\n", to: "four.txt")
        try await repository.run(["add", "four.txt"])
        try await repository.run(["commit", "-q", "-m", "add four", "-m", "with a body\nof two lines"])
        let messages = try await client.commitMessages(after: "main", in: repository.root)
        let plan = try await client.rebasePlan(onto: "main", in: repository.root)
        #expect(Set(messages.keys) == Set(plan.entries.map(\.commit)))
        #expect(messages[try await repository.sha("HEAD")] == "add four\n\nwith a body\nof two lines")
        #expect(messages[try await repository.sha("HEAD~3")] == "add one")

        let refused = await failure { _ = try await client.commitMessages(after: "-x", in: repository.root) }
        #expect(refused == .invalidArgument(verb: "log", argument: "-x"))
    }

    @Test("commitMessages parses records split by the unit and record separators")
    func commitMessagesParsing() {
        let log = "aaa\u{1F}one\n\n\u{1E}\nbbb\u{1F}two\n\nbody \u{1F} kept\n\u{1E}\nbroken\u{1E}\n"
        #expect(GitClient.commitMessages(fromLog: log) == ["aaa": "one", "bbb": "two\n\nbody \u{1F} kept"])
    }

    // MARK: - Interactive rebase

    @Test("reordering two commits")
    func reorder() async throws {
        let repository = try await featureRepository("rebase-reorder")
        defer { repository.tearDown() }
        try await rebase(repository) { $0.swapAt(0, 1) }
        #expect(try await history(repository).map(\.subject) == ["add three", "add one", "add two"])
        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(!(try await helperExists(repository)))
    }

    @Test("squashing two into one keeps the combined message without an editor")
    func squash() async throws {
        let repository = try await featureRepository("rebase-squash")
        defer { repository.tearDown() }
        try await rebase(repository) { $0[1].action = .squash }
        let commits = try await history(repository)
        #expect(commits.map(\.subject) == ["add three", "add one"])
        #expect(commits[1].body.contains("add two"))
        #expect(FileManager.default.fileExists(atPath: repository.url("two.txt").path))
    }

    @Test("a fixup folds the change in and drops its message")
    func fixup() async throws {
        let repository = try await featureRepository("rebase-fixup")
        defer { repository.tearDown() }
        try await rebase(repository) { $0[1].action = .fixup }
        let commits = try await history(repository)
        #expect(commits.map(\.subject) == ["add three", "add one"])
        #expect(!commits[1].body.contains("add two"))
        #expect(FileManager.default.fileExists(atPath: repository.url("two.txt").path))
    }

    @Test("a drop removes the commit and its change")
    func drop() async throws {
        let repository = try await featureRepository("rebase-drop")
        defer { repository.tearDown() }
        try await rebase(repository) { $0[1].action = .drop }
        #expect(try await history(repository).map(\.subject) == ["add three", "add one"])
        #expect(!FileManager.default.fileExists(atPath: repository.url("two.txt").path))
    }

    @Test("a reword sets the new message on that commit only, and the helper folder is gone after")
    func reword() async throws {
        let repository = try await featureRepository("rebase-reword")
        defer { repository.tearDown() }
        let before = try await history(repository)
        try await rebase(repository) { entries in
            entries[1].action = .reword
            entries[1].message = "renamed two\n\nwith a body, and a 'quote'"
        }
        let commits = try await history(repository)
        #expect(commits.map(\.subject) == ["add three", "renamed two", "add one"])
        #expect(commits[1].body.contains("with a body, and a 'quote'"))
        #expect(commits[2].id == before[2].id)
        #expect(commits[0].body == before[0].body)
        #expect(!(try await helperExists(repository)))
    }

    /// `main` has `base`; `feature` adds `x.txt` ("add x") then changes it ("change x"). The
    /// rebase onto `main` drops "add x" and rewords "change x", so that pick stops on a
    /// modify/delete conflict with the reword's `exec` still to run.
    private func stoppedRewordRepository(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "base.txt", "base\n", message: "base")
            try await repository.run(["switch", "-q", "-c", "feature"])
            try await commitFile(repository, "x.txt", "1\n", message: "add x")
            try await commitFile(repository, "x.txt", "2\n", message: "change x")
            _ = await failure {
                try await rebase(repository) { entries in
                    entries[0].action = .drop
                    entries[1].action = .reword
                    entries[1].message = "reworded x"
                }
            }
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    @Test("skipping a reworded pick that stopped leaves every earlier commit, onto included, alone")
    func skipStoppedReword() async throws {
        let repository = try await stoppedRewordRepository("rebase-reword-skip")
        defer { repository.tearDown() }
        let onto = try await repository.sha("main")
        #expect(try await client.operationState(in: repository.root) != .none)

        try await client.perform(.operation(.rebase, .skip), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(try await repository.sha("HEAD") == onto)
        #expect(try await repository.sha("main") == onto)
        let subject = try await repository.run(["log", "-1", "--format=%s", "HEAD"])
        #expect(subject.trimmingCharacters(in: .whitespacesAndNewlines) == "base")
        #expect(!(try await helperExists(repository)))
    }

    @Test("resolving a reworded pick that stopped, then continuing, gives it the new message")
    func continueStoppedReword() async throws {
        let repository = try await stoppedRewordRepository("rebase-reword-continue")
        defer { repository.tearDown() }
        let onto = try await repository.sha("main")
        try repository.write("2\n", to: "x.txt")
        try await repository.run(["add", "x.txt"])

        try await client.perform(.operation(.rebase, .continue), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(try await history(repository).map(\.subject) == ["reworded x"])
        #expect(try await repository.sha("HEAD~1") == onto)
        #expect(!(try await helperExists(repository)))
    }

    @Test("an edit stops as an interactive rebase, and continue finishes it")
    func editThenContinue() async throws {
        let repository = try await featureRepository("rebase-edit")
        defer { repository.tearDown() }
        try await rebase(repository) { $0[1].action = .edit }
        let state = try await client.operationState(in: repository.root)
        guard case .rebasing(_, _, _, _, let interactive) = state else {
            Issue.record("expected a rebase, got \(state)")
            return
        }
        #expect(interactive)
        #expect(try await helperExists(repository))

        try await client.perform(.operation(.rebase, .continue), in: repository.root)
        #expect(try await client.operationState(in: repository.root) == .none)
        #expect(try await history(repository).map(\.subject) == ["add three", "add two", "add one"])
        #expect(!(try await helperExists(repository)))
    }

    @Test("an invalid plan is refused before anything runs")
    func invalidPlanRefused() async throws {
        let repository = try await featureRepository("rebase-invalid")
        defer { repository.tearDown() }
        let head = try await repository.sha("HEAD")
        let error = await failure { try await rebase(repository) { $0[0].action = .squash } }
        guard case .invalidArgument("rebase", let reason)? = error else {
            Issue.record("\(String(describing: error))")
            return
        }
        #expect(reason.hasPrefix("The first commit cannot be squashed"))
        #expect(try await repository.sha("HEAD") == head)
        #expect(!(try await helperExists(repository)))
    }

    /// Leaves a helper folder holding only `message-7`, as a rebase ended outside the app would.
    private func plantStaleHelper(_ repository: GitTestRepository) async throws -> URL {
        let helper = try await client.gitPath(GitClient.rebaseHelperName, in: repository.root)
        try FileManager.default.createDirectory(at: helper, withIntermediateDirectories: true)
        try Data("stale".utf8).write(to: helper.appendingPathComponent("message-7"))
        return helper
    }

    @Test("a stale helper folder is replaced by a new plan's, and removed by an unrelated perform")
    func staleHelper() async throws {
        let repository = try await featureRepository("rebase-stale")
        defer { repository.tearDown() }
        var helper = try await plantStaleHelper(repository)
        try await rebase(repository) { $0[1].action = .edit }
        #expect(try await client.operationState(in: repository.root) != .none)
        #expect(!FileManager.default.fileExists(atPath: helper.appendingPathComponent("message-7").path))
        #expect(FileManager.default.fileExists(atPath: helper.appendingPathComponent("todo").path))
        try await client.perform(.operation(.rebase, .continue), in: repository.root)
        #expect(!(try await helperExists(repository)))

        helper = try await plantStaleHelper(repository)
        try repository.write("staged\n", to: "staged.txt")
        try await client.perform(.stage(paths: ["staged.txt"]), in: repository.root)
        #expect(!FileManager.default.fileExists(atPath: helper.path))
    }

    @Test("a perform during a stopped rebase keeps the helper folder its exec lines need")
    func helperKeptWhileStopped() async throws {
        let repository = try await featureRepository("rebase-stale-kept")
        defer { repository.tearDown() }
        try await rebase(repository) { $0[1].action = .edit }
        try repository.write("staged\n", to: "staged.txt")
        try await client.perform(.stage(paths: ["staged.txt"]), in: repository.root)
        #expect(try await helperExists(repository))
        try await client.perform(.operation(.rebase, .abort), in: repository.root)
        #expect(!(try await helperExists(repository)))
    }

    // MARK: - Conflicts

    /// `main` and `topic` both change, or one deletes, `a.txt`; `main` is checked out and
    /// `merge topic` has stopped on the conflict.
    private func conflictedRepository(_ prefix: String, deleteOnMain: Bool) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "a.txt", "base\n", message: "base")
            try await repository.run(["branch", "topic"])
            if deleteOnMain {
                try await repository.run(["rm", "-q", "a.txt"])
                try await repository.run(["commit", "-q", "-m", "delete"])
            } else {
                try await commitFile(repository, "a.txt", "main\n", message: "main change")
            }
            try await repository.run(["switch", "-q", "topic"])
            try await commitFile(repository, "a.txt", "topic\n", message: "topic change")
            try await repository.run(["switch", "-q", "main"])
            _ = try? await repository.run(["merge", "topic"])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    @Test("resolve(.ours) and stage resolve a both-modified conflict")
    func resolveOurs() async throws {
        let repository = try await conflictedRepository("resolve-ours", deleteOnMain: false)
        defer { repository.tearDown() }
        #expect(try await client.status(in: repository.root).conflicts == ["a.txt": .bothModified])
        try await client.perform(.resolve(paths: ["a.txt"], side: .ours), in: repository.root)
        try await client.perform(.stage(paths: ["a.txt"]), in: repository.root)
        let status = try await client.status(in: repository.root)
        #expect(status.conflicts.isEmpty)
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "main\n")
    }

    @Test("a deleted-by-us conflict is resolved by removing the path")
    func removeDeletedByUs() async throws {
        let repository = try await conflictedRepository("remove-deleted", deleteOnMain: true)
        defer { repository.tearDown() }
        #expect(try await client.status(in: repository.root).conflicts == ["a.txt": .deletedByUs])
        try await client.perform(.removePaths(paths: ["a.txt"]), in: repository.root)
        #expect(try await client.status(in: repository.root).conflicts.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: repository.url("a.txt").path))
    }

    // MARK: - Worktrees

    @Test("adding, refusing and removing worktrees, with worktrees() following each step")
    func worktrees() async throws {
        let repository = try await GitTestRepository.make(prefix: "worktrees")
        let temporary = FileManager.default.temporaryDirectory
        let fresh = temporary.appendingPathComponent("worktree-fresh-\(UUID().uuidString)")
        let existing = temporary.appendingPathComponent("worktree-existing-\(UUID().uuidString)")
        defer {
            repository.tearDown()
            try? FileManager.default.removeItem(at: fresh)
            try? FileManager.default.removeItem(at: existing)
        }
        try await commitFile(repository, "a.txt", "a\n", message: "base")
        try await repository.run(["branch", "existing"])
        /// The worktrees' branches; git lists the main one first and the rest in no set order.
        func branches() async throws -> Set<String> {
            let trees = try await client.worktrees(in: repository.root)
            #expect(trees.first?.isMain == true)
            return Set(trees.compactMap(\.branch))
        }

        try await client.perform(.addWorktree(path: fresh.path, branch: "fresh", createBranch: true, startPoint: nil),
                                 in: repository.root)
        #expect(try await branches() == ["main", "fresh"])
        try await client.perform(
            .addWorktree(path: existing.path, branch: "existing", createBranch: false, startPoint: nil),
            in: repository.root
        )
        #expect(try await branches() == ["main", "existing", "fresh"])

        let relative = await failure {
            try await client.perform(.addWorktree(path: "relative/wt", branch: "rel", createBranch: true,
                                                  startPoint: nil), in: repository.root)
        }
        #expect(relative == .invalidArgument(verb: "worktree", argument: "“relative/wt” is not an absolute path."))
        #expect(try await client.worktrees(in: repository.root).count == 3)

        try await client.perform(.removeWorktree(path: fresh.path, force: false), in: repository.root)
        #expect(try await branches() == ["main", "existing"])

        try "dirty\n".write(to: existing.appendingPathComponent("untracked.txt"), atomically: true, encoding: .utf8)
        let dirty = await failure {
            try await client.perform(.removeWorktree(path: existing.path, force: false), in: repository.root)
        }
        guard case .commandFailed("worktree", _, _)? = dirty else {
            Issue.record("dirty remove: \(String(describing: dirty))")
            return
        }
        #expect(try await branches() == ["main", "existing"])
        try await client.perform(.removeWorktree(path: existing.path, force: true), in: repository.root)
        #expect(try await branches() == ["main"])
    }

    // MARK: - Submodules

    @Test("updateSubmodules(initialize: true) checks out a submodule a clone left uninitialized")
    func initializeSubmodules() async throws {
        let library = try await GitTestRepository.make(prefix: "submodule-library")
        let superproject = try await GitTestRepository.make(prefix: "submodule-super")
        var clone: GitTestRepository?
        defer {
            library.tearDown()
            superproject.tearDown()
            clone?.tearDown()
        }
        try await commitFile(library, "lib.txt", "lib\n", message: "library")
        try await commitFile(superproject, "app.txt", "app\n", message: "app")
        try await superproject.run(["-c", "protocol.file.allow=always", "submodule", "add", "-q",
                                    library.root.path, "lib"])
        try await superproject.run(["commit", "-q", "-m", "add lib"])

        let cloned = try await GitTestRepository.clone(of: superproject, prefix: "submodule-clone")
        clone = cloned
        #expect(try await client.submodules(in: cloned.root).map(\.state) == [.uninitialized])

        try await client.perform(.updateSubmodules(paths: [], initialize: true), in: cloned.root)
        let submodules = try await client.submodules(in: cloned.root)
        #expect(submodules.map(\.path) == ["lib"])
        #expect(submodules.map(\.state) == [.current])
        #expect(FileManager.default.fileExists(atPath: cloned.url("lib/lib.txt").path))
    }

    @Test("updateSubmodules with a path checks out that submodule and leaves the other alone")
    func updateOneSubmoduleByPath() async throws {
        let library = try await GitTestRepository.make(prefix: "submodule-library")
        let superproject = try await GitTestRepository.make(prefix: "submodule-super")
        var clone: GitTestRepository?
        defer {
            library.tearDown()
            superproject.tearDown()
            clone?.tearDown()
        }
        try await commitFile(library, "lib.txt", "lib\n", message: "library")
        try await commitFile(superproject, "app.txt", "app\n", message: "app")
        for path in ["lib", "other lib"] {
            try await superproject.run(["-c", "protocol.file.allow=always", "submodule", "add", "-q",
                                        library.root.path, path])
        }
        try await superproject.run(["commit", "-q", "-m", "add both"])

        let cloned = try await GitTestRepository.clone(of: superproject, prefix: "submodule-clone")
        clone = cloned
        try await client.perform(.updateSubmodules(paths: ["other lib"], initialize: true), in: cloned.root)
        let states = Dictionary(uniqueKeysWithValues: try await client.submodules(in: cloned.root)
            .map { ($0.path, $0.state) })
        #expect(states == ["lib": .uninitialized, "other lib": .current])
        #expect(FileManager.default.fileExists(atPath: cloned.url("other lib/lib.txt").path))
        #expect(!FileManager.default.fileExists(atPath: cloned.url("lib/lib.txt").path))
    }
}
