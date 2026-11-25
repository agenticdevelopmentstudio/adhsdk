import Foundation
import OSLog
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Patches built from real `diff` output, parsed by the real parser, applied by `GitClient`
/// to fixture repositories.
@Suite("GitClient applying patches built from diff lines")
struct GitClientPatchTests {
    private let client = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL,
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    /// Twenty numbered lines.
    private static let original = (1...20).map { "line \($0)\n" }.joined()

    /// `original` with `early` inserted after line 2 and `late` after line 18: two hunks.
    private static let changed = (1...20).map { number -> String in
        var text = "line \(number)\n"
        if number == 2 { text += "early\n" }
        if number == 18 { text += "late\n" }
        return text
    }.joined()

    /// A repository with `original` committed as `a.txt` and `changed` in the work tree.
    private func makeRepository(_ prefix: String) async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try repository.write(Self.original, to: "a.txt")
            try await repository.run(["add", "a.txt"])
            try await repository.run(["commit", "-q", "-m", "initial"])
            try repository.write(Self.changed, to: "a.txt")
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    private func onlyFile(_ target: GitDiffTarget, in repository: GitTestRepository) async throws -> GitFileDiff? {
        let diff = try await client.diff(target, options: GitDiffOptions(), in: repository.root)
        #expect(diff.files.count <= 1)
        return diff.files.first
    }

    /// The indices of the changed lines in `hunk` whose text is `text`.
    private func lines(_ text: String, in hunk: GitDiffHunk) -> IndexSet {
        IndexSet(hunk.lines.indices.filter { hunk.lines[$0].text == text && hunk.lines[$0].kind != .context })
    }

    /// The patch selecting the changed line `text` wherever it is in `file`.
    private func patch(selecting text: String, in file: GitFileDiff, _ direction: GitPatchDirection) throws
        -> String {
        var selected: [Int: IndexSet] = [:]
        for (index, hunk) in file.hunks.enumerated() {
            let found = lines(text, in: hunk)
            if !found.isEmpty { selected[index] = found }
        }
        return try #require(GitPatchBuilder.patch(GitPatchSelection(file: file, lines: selected),
                                                  direction: direction))
    }

    private func changedTexts(_ file: GitFileDiff?) -> [String] {
        file?.hunks.flatMap(\.lines).filter { $0.kind == .added || $0.kind == .removed }.map(\.text) ?? []
    }

    private func indexBlob(_ path: String, in repository: GitTestRepository) async throws -> Data? {
        try await client.fileContents(path: path, at: ":0", in: repository.root)
    }

    @Test("stage one line of a two-hunk change, then unstage it back")
    func stageAndUnstageOneLine() async throws {
        let repository = try await makeRepository("git-patch-line")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        #expect(unstaged.hunks.count == 2)

        let forward = try patch(selecting: "early", in: unstaged, .forward)
        try await client.perform(.applyToIndex(patch: forward, reverse: false), in: repository.root)
        let staged = try await onlyFile(.staged(paths: []), in: repository)
        #expect(changedTexts(staged) == ["early"])
        #expect(changedTexts(try await onlyFile(.unstaged(paths: []), in: repository)) == ["late"])

        let stagedFile = try #require(staged)
        let reverse = try patch(selecting: "early", in: stagedFile, .reverse)
        try await client.perform(.applyToIndex(patch: reverse, reverse: true), in: repository.root)
        #expect(try await onlyFile(.staged(paths: []), in: repository) == nil)
        let head = try await client.fileContents(path: "a.txt", at: "HEAD", in: repository.root)
        #expect(try await indexBlob("a.txt", in: repository) == head)
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == Self.changed)
    }

    @Test("stage a whole hunk")
    func stageWholeHunk() async throws {
        let repository = try await makeRepository("git-patch-hunk")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let patch = try #require(GitPatchBuilder.patch(.hunk(1, of: unstaged), direction: .forward))
        try await client.perform(.applyToIndex(patch: patch, reverse: false), in: repository.root)
        #expect(changedTexts(try await onlyFile(.staged(paths: []), in: repository)) == ["late"])
        #expect(changedTexts(try await onlyFile(.unstaged(paths: []), in: repository)) == ["early"])
    }

    @Test("discard one line from the work tree; the other change stays")
    func discardOneLine() async throws {
        let repository = try await makeRepository("git-patch-discard")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let reverse = try patch(selecting: "early", in: unstaged, .reverse)
        try await client.perform(.applyToWorktree(patch: reverse, reverse: true), in: repository.root)
        let text = try String(contentsOf: repository.url("a.txt"), encoding: .utf8)
        #expect(!text.contains("early"))
        #expect(text.contains("late\n"))
        #expect(try await onlyFile(.staged(paths: []), in: repository) == nil)
    }

    @Test("a file without a trailing newline: change its last line and stage it")
    func lastLineWithoutNewline() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-patch-eof")
        defer { repository.tearDown() }
        try repository.write("one\ntwo\nthree", to: "b.txt")
        try await repository.run(["add", "b.txt"])
        try await repository.run(["commit", "-q", "-m", "initial"])
        try repository.write("one\ntwo\nTHREE", to: "b.txt")
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        #expect(unstaged.hunks.first?.lines.contains { $0.kind == .noNewlineAtEnd } == true)
        let patch = try #require(GitPatchBuilder.patch(.hunk(0, of: unstaged), direction: .forward))
        try await client.perform(.applyToIndex(patch: patch, reverse: false), in: repository.root)
        #expect(try await indexBlob("b.txt", in: repository) == Data("one\ntwo\nTHREE".utf8))
        #expect(try await onlyFile(.unstaged(paths: []), in: repository) == nil)
    }

    @Test("unstaging a line of a staged rename keeps the rename")
    func unstageLineOfRename() async throws {
        let repository = try await makeRepository("git-patch-rename")
        defer { repository.tearDown() }
        try await repository.run(["mv", "a.txt", "b.txt"])
        try await repository.run(["add", "b.txt"])
        let staged = try #require(try await onlyFile(.staged(paths: []), in: repository))
        guard case .renamed = staged.change else {
            Issue.record("expected a rename, got \(staged.change)")
            return
        }
        let reverse = try patch(selecting: "early", in: staged, .reverse)
        try await client.perform(.applyToIndex(patch: reverse, reverse: true), in: repository.root)
        let after = try #require(try await onlyFile(.staged(paths: []), in: repository))
        #expect(after.oldPath == "a.txt")
        #expect(after.newPath == "b.txt")
        #expect(changedTexts(after) == ["late"])
        #expect(try await indexBlob("a.txt", in: repository) == nil)
    }

    @Test("a patch that no longer applies throws with git's message")
    func stalePatch() async throws {
        let repository = try await makeRepository("git-patch-stale")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let forward = try patch(selecting: "early", in: unstaged, .forward)
        try repository.write(Self.original.replacingOccurrences(of: "line 2\n", with: "line two\n"), to: "a.txt")
        try await repository.run(["add", "a.txt"])
        do {
            try await client.perform(.applyToIndex(patch: forward, reverse: false), in: repository.root)
            Issue.record("a stale patch applied")
        } catch GitClientError.commandFailed(let verb, let status, let standardError) {
            #expect(verb == "apply")
            #expect(status != 0)
            #expect(standardError.contains("patch does not apply"))
        }
    }

    /// A repository with `committed` committed as `f.txt` and `working` in the work tree.
    private func makeRepository(_ prefix: String, committed: String, working: String) async throws
        -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: prefix)
        do {
            try repository.write(committed, to: "f.txt")
            try await repository.run(["add", "f.txt"])
            try await repository.run(["commit", "-q", "-m", "initial"])
            try repository.write(working, to: "f.txt")
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    @Test("appending after an old side with no final newline stages and unstages byte for byte")
    func appendAfterNoFinalNewline() async throws {
        let repository = try await makeRepository("git-patch-eof", committed: "x\na", working: "x\na\nb")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let forward = try patch(selecting: "b", in: unstaged, .forward)
        try await client.perform(.applyToIndex(patch: forward, reverse: false), in: repository.root)
        #expect(try await indexBlob("f.txt", in: repository) == Data("x\na\nb".utf8))

        let staged = try #require(try await onlyFile(.staged(paths: []), in: repository))
        let reverse = try patch(selecting: "b", in: staged, .reverse)
        try await client.perform(.applyToIndex(patch: reverse, reverse: true), in: repository.root)
        // The other staged change, `a` gaining its newline, stays staged.
        #expect(try await indexBlob("f.txt", in: repository) == Data("x\na\n".utf8))
    }

    @Test("staging one line of a CRLF file keeps every carriage return")
    func stageOneLineOfACRLFFile() async throws {
        let repository = try await makeRepository("git-patch-crlf", committed: "one\r\ntwo\r\nthree\r\n",
                                                  working: "one\r\nTWO\r\nthree\r\nfour\r\n")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let forward = try patch(selecting: "four\r", in: unstaged, .forward)
        try await client.perform(.applyToIndex(patch: forward, reverse: false), in: repository.root)
        #expect(try await indexBlob("f.txt", in: repository) == Data("one\r\ntwo\r\nthree\r\nfour\r\n".utf8))
        let rest = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        #expect(changedTexts(rest) == ["two\r", "TWO\r"])
    }

    @Test("an empty patch is refused before git runs")
    func emptyPatch() async throws {
        let repository = try await makeRepository("git-patch-empty")
        defer { repository.tearDown() }
        await #expect(throws: GitClientError.self) {
            try await client.perform(.applyToIndex(patch: "", reverse: false), in: repository.root)
        }
    }

    @Test("the command log records apply and its arguments, never the patch")
    func commandLogOmitsThePatch() async throws {
        let repository = try await makeRepository("git-patch-log")
        defer { repository.tearDown() }
        let unstaged = try #require(try await onlyFile(.unstaged(paths: []), in: repository))
        let forward = try patch(selecting: "early", in: unstaged, .forward)
        let started = Date()
        try await client.perform(.applyToIndex(patch: forward, reverse: false), in: repository.root)

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let entries = try store.getEntries(at: store.position(date: started.addingTimeInterval(-1)))
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.category == "GitCommandLog" && $0.composedMessage.contains(repository.root.path) }
            .map(\.composedMessage)
        // The command line is the spawned argv: every write runs under `-c core.editor=true`.
        let apply = entries.filter { $0.hasPrefix("git -c core.editor=true apply ") }
        #expect(apply.count == 1)
        #expect(apply.first?.contains(" --cached --whitespace=nowarn - cwd=") == true)
        #expect(!entries.contains { $0.contains("early") || $0.contains("@@") })
    }
}
