import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `GitClient.reflog(ref:limit:in:caller:)` against real repositories (recipe
/// `foundation/git/git-client`, "Reflog").
@Suite("GitClient reflog", .serialized)
struct GitClientReflogTests {
    private let client = GitClient(configuration: GitClientConfiguration(
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    private func commitFile(_ repository: GitTestRepository, _ path: String, _ text: String,
                            message: String, options: [String] = []) async throws {
        try repository.write(text, to: path)
        try await repository.run(["add", path])
        try await repository.run(["commit", "-q", "-m", message] + options)
    }

    @Test("three commits then an amend: the amend first, each entry pointing at the one before")
    func amendFirst() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-reflog-amend")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "one\n", message: "one")
        try await commitFile(repository, "a.txt", "two\n", message: "two")
        try await commitFile(repository, "a.txt", "three\n", message: "three")
        let beforeAmend = try await repository.sha("HEAD")
        try await commitFile(repository, "a.txt", "three, amended\n", message: "three again", options: ["--amend"])
        let afterAmend = try await repository.sha("HEAD")

        let entries = try await client.reflog(limit: 10, in: repository.root)
        #expect(entries.count == 4)
        #expect(entries.map(\.action) == ["commit (amend)", "commit", "commit", "commit (initial)"])
        #expect(entries.map(\.message) == ["three again", "three", "two", "one"])
        #expect(entries[0].selector == "HEAD@{0}")
        #expect(entries[0].sha == afterAmend)
        #expect(entries[0].previousSha == beforeAmend)
        #expect(entries[1].sha == beforeAmend)

        let two = try await client.reflog(limit: 2, in: repository.root)
        #expect(two.map(\.sha) == [afterAmend, beforeAmend])
    }

    @Test("a repository with no commits has no reflog")
    func unborn() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-reflog-unborn")
        defer { repository.tearDown() }
        #expect(try await client.reflog(limit: 10, in: repository.root).isEmpty)
    }

    @Test("a ref that would read as an option is refused before git runs")
    func optionRefused() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-reflog-option")
        defer { repository.tearDown() }
        await #expect(throws: GitClientError.self) {
            _ = try await client.reflog(ref: "--all", limit: 10, in: repository.root)
        }
    }

    @Test("undo state reads the checked-out branch's reflog, and HEAD's only when detached")
    func undoStateRef() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-reflog-undo-state")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "one\n", message: "one")
        try await commitFile(repository, "a.txt", "two\n", message: "two")
        let tip = try await repository.sha("HEAD")
        try await repository.run(["switch", "-q", "-c", "feature"])

        let branch = try await client.undoState(in: repository.root)
        #expect(branch.ref == "refs/heads/feature")
        #expect(branch.tip == tip)
        #expect(branch.entries.count == 1)
        #expect(branch.target == nil)

        try await repository.run(["switch", "-q", "--detach", "HEAD~1"])
        let detached = try await client.undoState(in: repository.root)
        #expect(detached.ref == "HEAD")
        #expect(detached.target?.sha == tip)

        let preflight = try await client.undoPreflight(in: repository.root)
        #expect(preflight.operation == .none)
        #expect(!preflight.isDirty)
    }

    @Test("an unborn branch has no undo state to act on")
    func undoStateUnborn() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-reflog-undo-unborn")
        defer { repository.tearDown() }
        let state = try await client.undoState(in: repository.root)
        #expect(state.tip == nil)
        #expect(state.entries.isEmpty)
        #expect(state.target == nil)
    }
}
