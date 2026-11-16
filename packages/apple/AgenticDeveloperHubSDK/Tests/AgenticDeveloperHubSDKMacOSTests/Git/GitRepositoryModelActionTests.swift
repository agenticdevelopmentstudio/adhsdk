import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A watcher that never fires: these tests drive every refresh through `perform`.
private final class SilentWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

@Suite("GitRepositoryModel actions", .serialized)
@MainActor
struct GitRepositoryModelActionTests {
    private static let epoch = 1_767_268_800

    private func makeModel(_ repository: GitTestRepository, client: GitClient = GitClient(configuration: .default))
        -> GitRepositoryModel {
        GitRepositoryModel(root: repository.root, client: client, watcher: SilentWatcher())
    }

    private func commitFile(_ repository: GitTestRepository, _ name: String, at offset: Int) async throws {
        try repository.write("\(name)\n", to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit(name, at: Self.epoch + offset)
    }

    @Test("perform stages a file, refreshes, and tells observers the working copy changed")
    func performStagesAndRefreshes() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        try repository.write("a\n", to: "a.txt")
        let model = makeModel(repository)
        await model.start()
        #expect(model.staged.isEmpty)

        var notified: [Set<GitRepositoryChange>] = []
        let token = model.observe { notified.append($0) }
        try await model.perform(.stage(paths: ["a.txt"]))

        #expect(model.staged.map(\.path) == ["a.txt"])
        #expect(notified.contains { $0.contains(.workingCopy) })
        #expect(!model.isPerforming)
        withExtendedLifetime(token) {}
    }

    @Test("perform refreshes and notifies even when the action fails, then rethrows")
    func performRefreshesAfterAFailure() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        let model = makeModel(repository)
        await model.start()

        var notified: [Set<GitRepositoryChange>] = []
        let token = model.observe { notified.append($0) }
        await #expect(throws: GitClientError.self) {
            try await model.perform(.checkout(branch: "nope"))
        }
        #expect(!notified.isEmpty)
        #expect(!model.isPerforming)
        withExtendedLifetime(token) {}
    }

    @Test("isPerforming is true while the git call runs and false once perform returns")
    func isPerformingDuringTheAction() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        try repository.write("a\n", to: "a.txt")
        let script = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-model-slow-\(UUID().uuidString).sh")
        defer { try? FileManager.default.removeItem(at: script) }
        try "#!/bin/sh\nsleep 0.3\nexec /usr/bin/git \"$@\"\n".write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let slow = GitClient(configuration: GitClientConfiguration(executableURL: script, timeout: 10))
        let model = makeModel(repository, client: slow)
        #expect(!model.isPerforming)

        let task = Task { @MainActor in try await model.perform(.stage(paths: ["a.txt"])) }
        try await Task.sleep(for: .milliseconds(100))
        #expect(model.isPerforming)
        try await task.value
        #expect(!model.isPerforming)
        #expect(model.staged.map(\.path) == ["a.txt"])
    }

    @Test("headBranch and hasCommits: nil and false on an unborn HEAD, main and true after a commit")
    func headBranchAndHasCommits() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        let model = makeModel(repository)
        await model.start()
        #expect(model.headBranch == nil)
        #expect(!model.hasCommits)

        try await commitFile(repository, "base.txt", at: 100)
        await model.refresh(Set(GitRepositoryChange.allCases))
        #expect(model.headBranch?.name == "main")
        #expect(model.headBranch?.kind == .localBranch)
        #expect(model.hasCommits)
    }

    @Test("hasCommits is false on an orphan branch created beside others")
    func hasCommitsIsFalseOnAnOrphanBranch() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        let model = makeModel(repository)
        await model.start()
        #expect(model.hasCommits)

        try await repository.run(["switch", "--quiet", "--orphan", "fresh"])
        await model.refresh(Set(GitRepositoryChange.allCases))
        #expect(model.refs.contains { $0.kind == .localBranch })
        #expect(!model.hasCommits)
    }

    @Test("operationState follows a conflicting merge performed through the model, and its abort")
    func operationStateFollowsPerform() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try repository.write("base\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.commit("base", at: Self.epoch + 100)
        try await repository.run(["switch", "-q", "-c", "topic"])
        try repository.write("topic\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.commit("topic", at: Self.epoch + 200)
        try await repository.run(["switch", "-q", "main"])
        try repository.write("main\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.commit("main", at: Self.epoch + 300)
        let theirs = try await repository.sha("topic")
        let client = GitClient(configuration: GitClientConfiguration(
            extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
        ))
        let model = makeModel(repository, client: client)
        await model.start()
        #expect(model.operationState == .none)

        var notified: [Set<GitRepositoryChange>] = []
        let token = model.observe { notified.append($0) }
        await #expect(throws: GitClientError.self) {
            try await model.perform(.merge(ref: "topic", fastForward: .allowed))
        }
        #expect(model.operationState == .merging(head: theirs))
        #expect(notified.contains { $0.contains(.operation) })

        try await model.perform(.operation(.merge, .abort))
        #expect(model.operationState == .none)
        withExtendedLifetime(token) {}
    }

    @Test("a working-copy refresh alone reloads the operation state and reports it when it changed")
    func workingCopyRefreshReportsAnOperationChange() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        let model = makeModel(repository)
        await model.start()

        let head = try await repository.sha("HEAD")
        try repository.write("\(head)\n", to: ".git/REVERT_HEAD")
        var notified: [Set<GitRepositoryChange>] = []
        let token = model.observe { notified.append($0) }
        await model.refresh([.workingCopy])
        #expect(model.operationState == .reverting(commit: head))
        #expect(notified.last?.contains(.operation) == true)

        try FileManager.default.removeItem(at: repository.url(".git/REVERT_HEAD"))
        await model.refresh([.workingCopy])
        #expect(model.operationState == .none)
        withExtendedLifetime(token) {}
    }

    @Test("remotes and lastCommitMessage read through the client")
    func remotesAndLastCommitMessage() async throws {
        let remote = try await GitTestRepository.makeBare()
        defer { remote.tearDown() }
        let repository = try await GitTestRepository.clone(of: remote)
        defer { repository.tearDown() }
        let model = makeModel(repository)
        #expect(try await model.lastCommitMessage() == nil)
        try await commitFile(repository, "base.txt", at: 100)
        #expect(try await model.remotes() == ["origin"])
        #expect(try await model.lastCommitMessage() == "base.txt")
    }

    @Test("userMessage is git's trimmed standard error, else the error's description")
    func userMessage() {
        let failed = GitClientError.commandFailed(verb: "switch", exitStatus: 128, standardError: "  fatal: nope\n")
        #expect(GitClientError.userMessage(of: failed) == "fatal: nope")
        let silent = GitClientError.commandFailed(verb: "switch", exitStatus: 1, standardError: "\n")
        #expect(GitClientError.userMessage(of: silent) == silent.localizedDescription)
        let timedOut = GitClientError.timedOut(verb: "push")
        #expect(GitClientError.userMessage(of: timedOut) == timedOut.localizedDescription)
    }

    @Test("a text request is complete only when every required field has text")
    func textRequestCompleteness() {
        let request = GitTextRequest(
            title: "New Tag", message: "",
            fields: [GitTextField(label: "Name", initial: "", isOptional: false),
                     GitTextField(label: "Message", initial: "", isOptional: true)],
            actionTitle: "Create"
        )
        #expect(!request.isComplete(["", "note"]))
        #expect(!request.isComplete(["   ", ""]))
        #expect(request.isComplete(["v1", ""]))
        #expect(!request.isComplete(["v1"]))
    }

    @Test("writeResolution writes inside the root, and refuses a path through a linked folder that leaves it")
    func writeResolutionStaysInside() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-model-action")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", at: 100)
        let outside = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-model-outside-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: outside) }
        try FileManager.default.createSymbolicLink(at: repository.root.appendingPathComponent("linked"),
                                                   withDestinationURL: outside)
        let model = makeModel(repository)

        try await model.writeResolution("resolved\n", to: "base.txt")
        let written = try String(contentsOf: repository.root.appendingPathComponent("base.txt"), encoding: .utf8)
        #expect(written == "resolved\n")
        await #expect(throws: GitClientError.self) {
            try await model.writeResolution("escaped\n", to: "linked/escaped.txt")
        }
        #expect(!FileManager.default.fileExists(atPath: outside.appendingPathComponent("escaped.txt").path))
        await #expect(throws: GitClientError.self) {
            try await model.writeResolution("escaped\n", to: "../escaped.txt")
        }
    }
}
