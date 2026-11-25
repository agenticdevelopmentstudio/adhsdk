import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitClient write verbs against fixture repositories")
struct GitClientWriteTests {
    /// The client under test sees no global or system configuration, so a developer's hooks
    /// path, signing or editor cannot reach the fixtures' commits.
    private let client = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL,
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    private func subjects(_ repository: GitTestRepository) async throws -> [String] {
        var query = GitLogQuery()
        query.revisions = ["HEAD"]
        return try await client.log(query, in: repository.root).map(\.subject)
    }

    /// Stages `path` with `text` and commits it through the fixture, not the client.
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

    @Test("the write budgets are a minute and ten minutes")
    func budgets() {
        #expect(GitClient.writeBudget == 60)
        #expect(GitClient.longWriteBudget == 600)
    }

    @Test("stage, unstage and commit on an unborn HEAD; the last message read back")
    func stageAndCommitOnUnbornHead() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-unborn")
        defer { repository.tearDown() }
        #expect(try await client.lastCommitMessage(in: repository.root) == nil)

        try repository.write("alpha\n", to: "a.txt")
        try await client.perform(.stage(paths: ["a.txt"]), in: repository.root)
        #expect(try await client.status(in: repository.root).stagedFiles["a.txt"] == .added)

        try await client.perform(.unstage(paths: ["a.txt"]), in: repository.root)
        let unstaged = try await client.status(in: repository.root)
        #expect(unstaged.stagedFiles["a.txt"] == nil)
        #expect(unstaged.unstagedFiles["a.txt"] == .untracked)

        try await client.perform(.stage(paths: ["a.txt"]), in: repository.root)
        try await client.perform(.commit(message: "first\n\nbody", amend: false), in: repository.root)
        #expect(try await subjects(repository) == ["first"])
        #expect(try await client.lastCommitMessage(in: repository.root) == "first\n\nbody")
    }

    @Test("a message line starting with # is committed verbatim")
    func hashLinesAreKept() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-hash")
        defer { repository.tearDown() }
        try repository.write("alpha\n", to: "a.txt")
        try await client.perform(.stageAll, in: repository.root)
        try await client.perform(.commit(message: "#42 fix\n\n# not a comment  \n", amend: false),
                                 in: repository.root)
        #expect(try await client.lastCommitMessage(in: repository.root) == "#42 fix\n\n# not a comment")
    }

    @Test("amend replaces the last commit")
    func amendReplacesTheLastCommit() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-amend")
        defer { repository.tearDown() }
        try repository.write("alpha\n", to: "a.txt")
        try await client.perform(.stageAll, in: repository.root)
        try await client.perform(.commit(message: "first", amend: false), in: repository.root)
        try await client.perform(.commit(message: "second", amend: true), in: repository.root)
        #expect(try await subjects(repository) == ["second"])
    }

    @Test("discard restores a tracked file; remove untracked deletes an untracked one")
    func discardAndRemoveUntracked() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-discard")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        try repository.write("changed\n", to: "a.txt")
        try repository.write("untracked\n", to: "b.txt")

        try await client.perform(.discard(paths: ["a.txt"]), in: repository.root)
        let status = try await client.status(in: repository.root)
        #expect(status.files["a.txt"] == nil)
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "alpha\n")
        #expect(status.files["b.txt"] == .untracked)

        try await client.perform(.removeUntracked(paths: ["b.txt"]), in: repository.root)
        #expect(!FileManager.default.fileExists(atPath: repository.url("b.txt").path))
        #expect(try await client.status(in: repository.root).files.isEmpty)
    }

    @Test("discarding [ab].txt leaves a.txt and b.txt as they are")
    func discardIsLiteral() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-literal-discard")
        defer { repository.tearDown() }
        for name in ["a.txt", "b.txt", "[ab].txt"] { try repository.write("one\n", to: name) }
        try await repository.run(["add", "-A"])
        try await repository.run(["commit", "-q", "-m", "initial"])
        for name in ["a.txt", "b.txt", "[ab].txt"] { try repository.write("two\n", to: name) }

        try await client.perform(.discard(paths: ["[ab].txt"]), in: repository.root)
        #expect(try String(contentsOf: repository.url("[ab].txt"), encoding: .utf8) == "one\n")
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "two\n")
        #expect(try String(contentsOf: repository.url("b.txt"), encoding: .utf8) == "two\n")
    }

    @Test("removing the untracked *.log leaves u1.log in place")
    func removeUntrackedIsLiteral() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-literal-clean")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        for name in ["u1.log", "u2.log", "*.log"] { try repository.write("x\n", to: name) }

        try await client.perform(.removeUntracked(paths: ["*.log"]), in: repository.root)
        #expect(!FileManager.default.fileExists(atPath: repository.url("*.log").path))
        #expect(FileManager.default.fileExists(atPath: repository.url("u1.log").path))
        #expect(FileManager.default.fileExists(atPath: repository.url("u2.log").path))
    }

    @Test("a path like app/[slug]/page.tsx stages that file and no other")
    func stageIsLiteral() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-literal-stage")
        defer { repository.tearDown() }
        try repository.write("route\n", to: "app/[slug]/page.tsx")
        try repository.write("other\n", to: "app/s/page.tsx")

        try await client.perform(.stage(paths: ["app/[slug]/page.tsx"]), in: repository.root)
        let status = try await client.status(in: repository.root)
        #expect(status.stagedFiles["app/[slug]/page.tsx"] == .added)
        #expect(status.stagedFiles["app/s/page.tsx"] == nil)
    }

    @Test("a path-taking action with no paths is refused before git runs")
    func emptyPathListsAreRefused() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-empty-paths")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        try repository.write("untracked\n", to: "u.txt")
        try repository.write("staged\n", to: "s.txt")
        try await repository.run(["add", "s.txt"])

        let actions: [GitAction] = [
            .stage(paths: []), .unstage(paths: []), .discard(paths: []), .removeUntracked(paths: [])
        ]
        for action in actions {
            let error = await failure { try await client.perform(action, in: repository.root) }
            guard case .invalidArgument(let verb, _)? = error else {
                Issue.record("expected invalidArgument for \(action), got \(String(describing: error))")
                continue
            }
            #expect(verb == action.verb)
        }
        #expect(FileManager.default.fileExists(atPath: repository.url("u.txt").path))
        #expect(try await client.status(in: repository.root).stagedFiles["s.txt"] == .added)
    }

    @Test("branches are created, checked out, renamed and deleted; unmerged needs force")
    func branchCreateRenameDeleteAndCheckout() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-branch")
        defer { repository.tearDown() }
        let root = repository.root
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")

        try await client.perform(.createBranch(name: "feature", startPoint: nil, checkout: true), in: root)
        #expect(try await client.currentBranch(in: root) == "feature")
        try await client.perform(.checkout(branch: "main"), in: root)
        #expect(try await client.currentBranch(in: root) == "main")
        try await client.perform(.renameBranch(from: "feature", to: "topic"), in: root)
        #expect(try await client.branches(in: root).map(\.name).sorted() == ["main", "topic"])
        try await client.perform(.deleteBranch(name: "topic", force: false), in: root)
        #expect(try await client.branches(in: root).map(\.name) == ["main"])

        let head = try await repository.sha("HEAD")
        try await client.perform(.checkoutDetached(commit: head), in: root)
        #expect(try await client.currentBranch(in: root) == nil)
        try await client.perform(.checkout(branch: "main"), in: root)

        try await client.perform(.createBranch(name: "side", startPoint: nil, checkout: true), in: root)
        try await commitFile(repository, "side.txt", "side\n", message: "side work")
        try await client.perform(.checkout(branch: "main"), in: root)
        let error = await failure { try await client.perform(.deleteBranch(name: "side", force: false), in: root) }
        guard case .commandFailed(_, _, let standardError)? = error else {
            Issue.record("expected commandFailed, got \(String(describing: error))")
            return
        }
        #expect(standardError.contains("not fully merged"))
        try await client.perform(.deleteBranch(name: "side", force: true), in: root)
        #expect(try await client.branches(in: root).map(\.name) == ["main"])
    }

    @Test("an annotated tag is created and deleted; stashes save, apply and pop untracked files")
    func tagsAndStashes() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-tags")
        defer { repository.tearDown() }
        let root = repository.root
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        let head = try await repository.sha("HEAD")

        try await client.perform(.createTag(name: "v1", commit: head, message: "version one"), in: root)
        let tag = try await client.refs(in: root).first { $0.kind == .tag && $0.name == "v1" }
        #expect(tag?.target == head)
        #expect(try await repository.run(["cat-file", "-t", "v1"]) == "tag\n")
        try await client.perform(.deleteTag(name: "v1"), in: root)
        #expect(try await client.refs(in: root).allSatisfy { $0.kind != .tag })

        try repository.write("wip\n", to: "u.txt")
        try await client.perform(.stashSave(message: "wip"), in: root)
        #expect(try await client.stashes(in: root).count == 1)
        #expect(!FileManager.default.fileExists(atPath: repository.url("u.txt").path))

        try await client.perform(.stashApply(index: 0), in: root)
        #expect(try await client.stashes(in: root).count == 1)
        #expect(FileManager.default.fileExists(atPath: repository.url("u.txt").path))

        try FileManager.default.removeItem(at: repository.url("u.txt"))
        try await client.perform(.stashPop(index: 0), in: root)
        #expect(try await client.stashes(in: root).isEmpty)
        #expect(FileManager.default.fileExists(atPath: repository.url("u.txt").path))

        try await client.perform(.stashSave(message: nil), in: root)
        try await client.perform(.stashDrop(index: 0), in: root)
        #expect(try await client.stashes(in: root).isEmpty)
    }

    @Test("cherry-pick, revert and a hard reset back to the start")
    func cherryPickRevertReset() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-pick")
        defer { repository.tearDown() }
        let root = repository.root
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        try await repository.run(["switch", "-q", "-c", "side"])
        try await commitFile(repository, "c.txt", "picked\n", message: "side change")
        let picked = try await repository.sha("HEAD")
        try await repository.run(["switch", "-q", "main"])
        try await commitFile(repository, "m.txt", "main\n", message: "main change")
        let start = try await repository.sha("HEAD")

        try await client.perform(.cherryPick(commit: picked, mainline: nil), in: root)
        #expect(try await subjects(repository) == ["side change", "main change", "initial"])
        try await client.perform(.revert(commit: "HEAD", mainline: nil), in: root)
        #expect(try await subjects(repository).first == "Revert \"side change\"")
        try await client.perform(.reset(commit: "HEAD~2", mode: .hard), in: root)
        #expect(try await repository.sha("HEAD") == start)
        #expect(try await client.status(in: root).files.isEmpty)
    }

    @Test("push, fetch and pull through a bare repository on disk; a tag reaches it")
    func fetchPullPushAgainstALocalRemote() async throws {
        let remote = try await GitTestRepository.makeBare()
        defer { remote.tearDown() }
        let first = try await GitTestRepository.clone(of: remote, prefix: "git-write-clone-a")
        defer { first.tearDown() }
        let second = try await GitTestRepository.clone(of: remote, prefix: "git-write-clone-b")
        defer { second.tearDown() }

        try await commitFile(first, "a.txt", "alpha\n", message: "shared")
        try await client.perform(.pushSettingUpstream(remote: "origin", branch: "main"), in: first.root)
        #expect(try await first.run(["rev-parse", "--abbrev-ref", "main@{upstream}"]) == "origin/main\n")

        try await client.perform(.fetch(remote: nil), in: second.root)
        try await client.perform(.pull, in: second.root)
        #expect(try await subjects(second) == ["shared"])
        #expect(try await client.remotes(in: first.root) == ["origin"])

        try await commitFile(first, "b.txt", "beta\n", message: "second")
        try await client.perform(.push, in: first.root)
        try await client.perform(.fetch(remote: "origin"), in: second.root)
        try await client.perform(.pull, in: second.root)
        #expect(try await subjects(second) == ["second", "shared"])

        try await client.perform(.createTag(name: "v1", commit: "HEAD", message: nil), in: first.root)
        try await client.perform(.pushTag(name: "v1", remote: "origin"), in: first.root)
        let tagged = try await first.sha("HEAD")
        #expect(try await remote.sha("refs/tags/v1") == tagged)
    }

    // MARK: - Operands git would read as options

    /// Everything a refused write could have changed: every ref, HEAD and the status.
    private func snapshot(_ repository: GitTestRepository) async throws -> [String] {
        [try await repository.run(["for-each-ref"]),
         try await repository.run(["rev-parse", "--symbolic-full-name", "HEAD"]),
         try await repository.run(["status", "--porcelain"])]
    }

    /// A repository with `main`, a branch `v2`, a tag `v2`, and a remote `origin`, so a
    /// misread operand has something real to delete, move or push.
    private func repositoryWithRefs(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
            try await repository.run(["branch", "v2-branch"])
            try await repository.run(["tag", "v2"])
            try await repository.run(["remote", "add", "origin", repository.url(".git").path])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// Each action throws `.invalidArgument` naming `operand`, and the repository is unchanged.
    private func expectRefused(_ actions: [(GitAction, String)], prefix: String,
                               sourceLocation: SourceLocation = #_sourceLocation) async throws {
        let repository = try await repositoryWithRefs(prefix)
        defer { repository.tearDown() }
        let before = try await snapshot(repository)
        for (action, operand) in actions {
            let error = await failure { try await client.perform(action, in: repository.root) }
            #expect(error == .invalidArgument(verb: action.verb, argument: operand), "\(action)",
                    sourceLocation: sourceLocation)
        }
        #expect(try await snapshot(repository) == before, sourceLocation: sourceLocation)
    }

    @Test("a branch name that is empty or starts with a dash is refused")
    func refusesDashBranchNames() async throws {
        try await expectRefused([
            (.createBranch(name: "--delete", startPoint: "v2-branch", checkout: false), "--delete"),
            (.createBranch(name: "-D", startPoint: "v2-branch", checkout: true), "-D"),
            (.checkout(branch: "-f"), "-f"),
            (.checkoutTracking(remoteBranch: "--orphan"), "--orphan"),
            (.deleteBranch(name: "", force: true), ""),
            (.deleteRemoteBranch(remote: "origin", name: "--mirror"), "--mirror"),
            (.pushSettingUpstream(remote: "origin", branch: "--force"), "--force")
        ], prefix: "git-write-dash-branch")
    }

    @Test("a start point that starts with a dash is refused")
    func refusesDashStartPoints() async throws {
        try await expectRefused([
            (.createBranch(name: "topic", startPoint: "-f", checkout: false), "-f"),
            (.createBranch(name: "topic", startPoint: "--track", checkout: true), "--track")
        ], prefix: "git-write-dash-start")
    }

    @Test("a tag name that is empty or starts with a dash is refused")
    func refusesDashTagNames() async throws {
        try await expectRefused([
            (.createTag(name: "-d", commit: "v2", message: nil), "-d"),
            (.createTag(name: "", commit: "HEAD", message: "m"), ""),
            (.deleteTag(name: "-l"), "-l"),
            (.pushTag(name: "-f", remote: "origin"), "-f")
        ], prefix: "git-write-dash-tag")
    }

    @Test("a commit that is empty or starts with a dash is refused")
    func refusesDashCommits() async throws {
        try await expectRefused([
            (.createTag(name: "v3", commit: "--delete", message: nil), "--delete"),
            (.checkoutDetached(commit: "-"), "-"),
            (.cherryPick(commit: "--abort", mainline: nil), "--abort"),
            (.revert(commit: "", mainline: 1), ""),
            (.reset(commit: "--hard", mode: .soft), "--hard")
        ], prefix: "git-write-dash-commit")
    }

    @Test("a remote that is empty or starts with a dash is refused")
    func refusesDashRemotes() async throws {
        try await expectRefused([
            (.fetch(remote: "--upload-pack=touch pwned"), "--upload-pack=touch pwned"),
            (.fetch(remote: ""), ""),
            (.pushSettingUpstream(remote: "--mirror", branch: "main"), "--mirror"),
            (.deleteRemoteBranch(remote: "-f", name: "v2-branch"), "-f"),
            (.pushTag(name: "v2", remote: "--all"), "--all")
        ], prefix: "git-write-dash-remote")
    }

    @Test("a rename whose old or new name starts with a dash is refused")
    func refusesDashRenames() async throws {
        try await expectRefused([
            (.renameBranch(from: "-M", to: "v2-branch"), "-M"),
            (.renameBranch(from: "v2-branch", to: "--delete"), "--delete"),
            (.renameBranch(from: "", to: "topic"), "")
        ], prefix: "git-write-dash-rename")
    }

    @Test("a refused write never reaches the executable")
    func refusalSpawnsNothing() async throws {
        // A missing executable fails every call that gets as far as `execute` with
        // `.executableNotFound`; a refusal must come first.
        let missing = GitClient(configuration: GitClientConfiguration(
            executableURL: URL(fileURLWithPath: "/nonexistent/git-\(UUID().uuidString)")
        ))
        let directory = FileManager.default.temporaryDirectory
        let refused = await failure { try await missing.perform(.checkout(branch: "-f"), in: directory) }
        #expect(refused == .invalidArgument(verb: "switch", argument: "-f"))
        let reached = await failure { try await missing.perform(.checkout(branch: "main"), in: directory) }
        guard case .executableNotFound? = reached else {
            Issue.record("expected executableNotFound, got \(String(describing: reached))")
            return
        }
    }

    @Test("push with no remote fails as a command, not a timeout")
    func pushWithNoRemoteFailsQuickly() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-noremote")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "alpha\n", message: "initial")
        #expect(try await client.remotes(in: repository.root).isEmpty)
        let error = await failure { try await client.perform(.push, in: repository.root) }
        guard case .commandFailed? = error else {
            Issue.record("expected commandFailed, got \(String(describing: error))")
            return
        }
    }

    @Test("a remote named only by a setting, with no URL, is not a remote")
    func remoteWithoutAURLIsNotListed() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-write-ghost")
        defer { repository.tearDown() }
        try await repository.run(["config", "remote.ghost.prune", "true"])
        try await repository.run(["remote", "add", "real", "/nonexistent/remote.git"])
        #expect(try await client.remotes(in: repository.root) == ["real"])
        #expect(GitClient.remoteNames(fromVerbose: "b\t/x (fetch)\nb\t/x (push)\na\t\nc\t/y (fetch)\n") == ["b", "c"])
    }
}
