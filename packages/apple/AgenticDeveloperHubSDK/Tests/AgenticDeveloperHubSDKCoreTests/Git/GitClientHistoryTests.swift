import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitClient history, diff, blame and ref verbs", .serialized)
struct GitClientHistoryTests {
    /// `café` as ISO Latin-1 bytes: not valid UTF-8, so only the Latin-1 fallback reads it.
    private static let latin1Cafe = Data([0x63, 0x61, 0x66, 0xE9, 0x0A])
    private static let epoch = 1_767_268_800

    /// `main` with three commits, `feature` merged with `--no-ff`, an annotated tag `v1` on
    /// the rename, a stash, `a b.txt` renamed to `c d.txt`, a Latin-1 file and a commit whose
    /// message is Latin-1 under `i18n.commitEncoding=latin1`. Every commit is a hundred
    /// seconds after the one before, so date order is known.
    private struct History {
        let repository: GitTestRepository
        let initial: String
        let rename: String
        let feature: String
        let latin1: String
        let merge: String
        let stash: String

        var root: URL { repository.root }

        static func make() async throws -> History {
            let repository = try await GitTestRepository.make(prefix: "git-client-history")
            do {
                try repository.write("alpha\n", to: "a b.txt")
                try repository.write(GitClientHistoryTests.latin1Cafe, to: "latin.txt")
                try await repository.run(["add", "a b.txt", "latin.txt"])
                try await repository.commit("initial", at: epoch + 100)

                try await repository.run(["mv", "a b.txt", "c d.txt"])
                try await repository.commit("rename a b to c d", at: epoch + 200)
                try await repository.run(["tag", "-a", "v1", "-m", "version one"],
                                         environment: GitTestRepository.dated(epoch + 200))

                try await repository.run(["switch", "-c", "feature"])
                try repository.write("feature\n", to: "feature.txt")
                try await repository.run(["add", "feature.txt"])
                try await repository.commit("feature work", at: epoch + 300,
                                            author: "Other Person <other@example.com>")

                try await repository.run(["switch", "main"])
                try repository.write("alpha\nneedle\n", to: "c d.txt")
                try await repository.run(["add", "c d.txt"])
                // Inside .git, so the message file is never part of the working tree.
                try repository.write(GitClientHistoryTests.latin1Cafe, to: ".git/latin1-message")
                try await repository.run(["-c", "i18n.commitEncoding=latin1", "commit", "-F", ".git/latin1-message"],
                                         environment: GitTestRepository.dated(epoch + 400))

                try await repository.run(["merge", "--no-ff", "feature", "-m", "Merge branch 'feature'"],
                                         environment: GitTestRepository.dated(epoch + 500))
                try await repository.run(["branch", "--set-upstream-to=main", "feature"])

                try repository.write("alpha\nneedle\nstashed\n", to: "c d.txt")
                try await repository.run(["stash", "push", "-m", "wip"],
                                         environment: GitTestRepository.dated(epoch + 600))

                return History(
                    repository: repository,
                    // main's first-parent chain: merge, latin1, rename, initial.
                    initial: try await repository.sha("main~3"),
                    rename: try await repository.sha("main~2"),
                    feature: try await repository.sha("feature"),
                    latin1: try await repository.sha("main^1"),
                    merge: try await repository.sha("main"),
                    stash: try await repository.sha("stash@{0}")
                )
            } catch {
                repository.tearDown()
                throw error
            }
        }

        func tearDown() {
            repository.tearDown()
        }
    }

    private let client = GitClient(configuration: .default)

    // MARK: - log

    @Test("log walks every branch in date order, the merge with both parents")
    func logReturnsAllBranchesInDateOrder() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let commits = try await client.log(GitLogQuery(), in: history.root)
        #expect(commits.map(\.id) == [history.merge, history.latin1, history.feature, history.rename, history.initial])
        #expect(commits.first?.parents == [history.latin1, history.feature])
    }

    @Test("log on an unborn HEAD is empty and does not throw")
    func logOnUnbornHeadIsEmpty() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        #expect(try await client.log(GitLogQuery(), in: repository.root).isEmpty)
        var follow = GitLogQuery()
        follow.path = "x.txt"
        follow.followRenames = true
        #expect(try await client.log(follow, in: repository.root).isEmpty)
    }

    @Test("log of a path follows it across a rename only when asked")
    func logFollowsRename() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        var query = GitLogQuery()
        query.path = "c d.txt"
        let plain = try await client.log(query, in: history.root).map(\.id)
        #expect(plain == [history.latin1, history.rename])
        query.followRenames = true
        let followed = try await client.log(query, in: history.root).map(\.id)
        #expect(followed == [history.latin1, history.rename, history.initial])
    }

    @Test("file history follows a rename and names the file's path at each commit")
    func fileHistoryFollowsRename() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let entries = try await client.fileHistory(path: "c d.txt", in: history.root)
        #expect(entries.map(\.commit.id) == [history.latin1, history.rename, history.initial])
        #expect(entries.map(\.path) == ["c d.txt", "c d.txt", "a b.txt"])
        #expect(entries.map(\.oldPath) == [nil, "a b.txt", nil])
        #expect(entries.map(\.paths) == [["c d.txt"], ["a b.txt", "c d.txt"], ["a b.txt"]])
    }

    @Test("file history on an unborn HEAD is empty")
    func fileHistoryOnUnbornHeadIsEmpty() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        #expect(try await client.fileHistory(path: "a.txt", in: repository.root).isEmpty)
    }

    @Test("log narrows by author, by message (case-insensitively) and by pickaxe")
    func logSearchesMessageAuthorAndPickaxe() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        var byAuthor = GitLogQuery()
        byAuthor.author = "Other Person"
        #expect(try await client.log(byAuthor, in: history.root).map(\.id) == [history.feature])
        var byMessage = GitLogQuery()
        byMessage.messageGrep = "RENAME"
        #expect(try await client.log(byMessage, in: history.root).map(\.id) == [history.rename])
        var byPickaxe = GitLogQuery()
        byPickaxe.pickaxe = "needle"
        #expect(try await client.log(byPickaxe, in: history.root).map(\.id) == [history.latin1])
    }

    @Test("a Latin-1 commit message decodes to the expected subject")
    func latin1MessageDecodes() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let commits = try await client.log(GitLogQuery(), in: history.root)
        #expect(commits.first { $0.id == history.latin1 }?.subject == "café")
    }

    @Test("Latin-1 message bytes with no encoding header decode through the Latin-1 fallback")
    func latin1MessageWithoutEncodingHeaderDecodes() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        try repository.write("x\n", to: "x.txt")
        try await repository.run(["add", "x.txt"])
        try repository.write(Self.latin1Cafe, to: ".git/latin1-message")
        // No i18n.commitEncoding: git stores the bytes as they are and prints them back raw.
        try await repository.run(["commit", "-F", ".git/latin1-message"])
        let object = try await repository.run(["cat-file", "commit", "HEAD"])
        #expect(!object.contains("\nencoding "), "the fixture must hand GitClient raw Latin-1, not re-encoded text")
        #expect(try await client.log(GitLogQuery(), in: repository.root).first?.subject == "café")
    }

    // MARK: - refs, stashes, submodules, top level

    @Test("refs list branches and tags: v1 peeled, main is HEAD, feature behind its upstream")
    func refsIncludeTagAheadBehind() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let refs = try await client.refs(in: history.root)
        #expect(Set(refs.map(\.fullName)) == ["refs/heads/main", "refs/heads/feature", "refs/tags/v1"])
        let tag = try #require(refs.first { $0.fullName == "refs/tags/v1" })
        #expect(tag.kind == .tag)
        #expect(tag.target == history.rename)
        let main = try #require(refs.first { $0.name == "main" })
        #expect(main.isHead)
        #expect(main.target == history.merge)
        let feature = try #require(refs.first { $0.name == "feature" })
        #expect(!feature.isHead)
        #expect(feature.upstream == "main")
        #expect(feature.ahead == 0)
        #expect(feature.behind == 2)
    }

    @Test("stashes list the stash entry")
    func stashesListTheStash() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let stashes = try await client.stashes(in: history.root)
        #expect(stashes.count == 1)
        #expect(stashes.first?.index == 0)
        #expect(stashes.first?.id == history.stash)
        #expect(stashes.first?.message.contains("wip") == true)
    }

    @Test("submodules are empty without .gitmodules and list an added submodule")
    func submodules() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        #expect(try await client.submodules(in: history.root).isEmpty)

        let other = try await GitTestRepository.make(prefix: "git-client-submodule")
        defer { other.tearDown() }
        try other.write("inner\n", to: "inner.txt")
        try await other.run(["add", "inner.txt"])
        try await other.run(["commit", "-m", "inner"])
        try await history.repository.run(["-c", "protocol.file.allow=always", "submodule", "add", "--quiet",
                                          other.root.path, "vendored lib"])
        let submodules = try await client.submodules(in: history.root)
        #expect(submodules == [GitSubmodule(path: "vendored lib", id: try await other.sha("HEAD"), state: .current)])
    }

    @Test("topLevel answers the working tree root from a subdirectory")
    func topLevelFromSubdirectory() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        let nested = repository.url("one/two")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let top = try await client.topLevel(of: nested)
        #expect(top.resolvingSymlinksInPath().path == repository.root.resolvingSymlinksInPath().path)
    }

    @Test("refs, stashes, submodules and file contents on an unborn HEAD answer empty without throwing")
    func unbornHeadAnswersEmpty() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        #expect(try await client.refs(in: repository.root).isEmpty)
        #expect(try await client.stashes(in: repository.root).isEmpty)
        #expect(try await client.submodules(in: repository.root).isEmpty)
        #expect(try await client.fileContents(path: "x.txt", at: "HEAD", in: repository.root) == nil)
    }

    // MARK: - diff

    @Test("a root commit diffs against the empty tree; a merge and a stash against their first parent")
    func diffCommitAndRootCommit() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let root = try await client.diff(.commit(history.initial, paths: []), options: GitDiffOptions(),
                                         in: history.root)
        #expect(root.files.map(\.path) == ["a b.txt", "latin.txt"])
        #expect(root.files.allSatisfy { $0.change == .added })
        // Non-UTF-8 content decodes through the Latin-1 fallback rather than vanishing.
        #expect(root.files.last?.hunks.first?.lines.first?.text == "café")

        let merge = try await client.diff(.commit(history.merge, paths: []), options: GitDiffOptions(),
                                          in: history.root)
        #expect(merge.files.map(\.path) == ["feature.txt"])
        #expect(merge.files.first?.change == .added)

        let rename = try await client.diff(.commit(history.rename, paths: []), options: GitDiffOptions(),
                                           in: history.root)
        #expect(rename.files.count == 1)
        #expect(rename.files.first?.oldPath == "a b.txt")
        #expect(rename.files.first?.newPath == "c d.txt")
        #expect(rename.files.first?.change == .renamed(similarity: 100))

        let stash = try await client.diff(.commit(history.stash, paths: []), options: GitDiffOptions(),
                                          in: history.root)
        #expect(stash.files.map(\.path) == ["c d.txt"])
        #expect(stash.files.first?.hunks.first?.lines.last == GitDiffLine(kind: .added, text: "stashed",
                                                                           oldNumber: nil, newNumber: 3))
    }

    @Test("a range diff limits itself to its paths")
    func diffRange() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let all = try await client.diff(.range(from: history.initial, to: history.merge, paths: []),
                                        options: GitDiffOptions(), in: history.root)
        // "alpha" → "alpha\nneedle" across the rename is below rename similarity, so git
        // reports the old name deleted and the new one added.
        #expect(Set(all.files.map(\.path)) == ["a b.txt", "c d.txt", "feature.txt"])
        let one = try await client.diff(.range(from: history.initial, to: history.merge, paths: ["feature.txt"]),
                                        options: GitDiffOptions(), in: history.root)
        #expect(one.files.map(\.path) == ["feature.txt"])
    }

    @Test("unstaged and staged diffs, with paths relative to the top level from a subdirectory")
    func diffUnstagedAndStaged() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        try history.repository.write("alpha\nneedle\nlocal\n", to: "c d.txt")
        let nested = history.repository.url("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        let unstaged = try await client.diff(.unstaged(paths: ["c d.txt"]), options: GitDiffOptions(), in: nested)
        #expect(unstaged.files.map(\.path) == ["c d.txt"])
        #expect(unstaged.files.first?.change == .modified)
        #expect(try await client.diff(.staged(paths: []), options: GitDiffOptions(), in: history.root).files.isEmpty)

        try await history.repository.run(["add", "c d.txt"])
        let staged = try await client.diff(.staged(paths: ["c d.txt"]), options: GitDiffOptions(), in: nested)
        #expect(staged.files.map(\.path) == ["c d.txt"])
        #expect(try await client.diff(.unstaged(paths: []), options: GitDiffOptions(), in: history.root).files.isEmpty)
    }

    @Test("diff options: whitespace-only changes vanish when ignored, and the context follows contextLines")
    func diffOptions() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        try history.repository.write("alpha  \nneedle\n", to: "c d.txt")
        var options = GitDiffOptions()
        #expect(try await client.diff(.unstaged(paths: []), options: options, in: history.root).files.count == 1)
        options.ignoreWhitespace = true
        let ignored = try await client.diff(.unstaged(paths: []), options: options, in: history.root)
        #expect(ignored.files.allSatisfy { $0.hunks.isEmpty })

        try history.repository.write("alpha\nchanged\n", to: "c d.txt")
        options = GitDiffOptions()
        options.contextLines = 0
        let tight = try await client.diff(.unstaged(paths: []), options: options, in: history.root)
        let kinds = tight.files.first?.hunks.first?.lines.map(\.kind)
        #expect(kinds == [.removed, .added])
    }

    @Test("an untracked file diffs as one added file, awkward name and binary content included")
    func diffUntrackedFile() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let awkward = "new\tü file.txt"
        try history.repository.write("fresh\n", to: awkward)
        let text = try await client.diff(.untracked(path: awkward), options: GitDiffOptions(), in: history.root)
        #expect(text.files.count == 1)
        #expect(text.files.first?.path == awkward)
        #expect(text.files.first?.change == .added)
        #expect(text.files.first?.hunks.first?.lines.map(\.text) == ["fresh"])

        try history.repository.write(Data([0x00, 0x01, 0x02, 0xFF]), to: "blob.bin")
        let binary = try await client.diff(.untracked(path: "blob.bin"), options: GitDiffOptions(), in: history.root)
        #expect(binary.files.count == 1)
        #expect(binary.files.first?.isBinary == true)
        #expect(binary.files.first?.change == .added)
    }

    @Test("an untracked path that does not exist throws instead of reading as no change")
    func diffMissingUntrackedFileThrows() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        await #expect(throws: GitClientError.self) {
            try await client.diff(.untracked(path: "absent.txt"), options: GitDiffOptions(), in: history.root)
        }
    }

    @Test("a staged file on an unborn HEAD diffs as added")
    func diffStagedOnUnbornHead() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        try repository.write("staged\n", to: "s.txt")
        try await repository.run(["add", "s.txt"])
        let staged = try await client.diff(.staged(paths: []), options: GitDiffOptions(), in: repository.root)
        #expect(staged.files.map(\.path) == ["s.txt"])
        #expect(staged.files.first?.change == .added)
        #expect(try await client.diff(.unstaged(paths: []), options: GitDiffOptions(), in: repository.root)
            .files.isEmpty)
    }

    // MARK: - blame and file contents

    @Test("blame at HEAD follows the rename; blame of the working tree includes uncommitted lines")
    func blameAtHead() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        let blame = try await client.blame(path: "c d.txt", at: "HEAD", in: history.root)
        #expect(blame.lines.map(\.text) == ["alpha", "needle"])
        #expect(blame.lines.map(\.commitID) == [history.initial, history.latin1])
        #expect(blame.commits[history.latin1]?.summary == "café")

        try history.repository.write("alpha\nneedle\nlocal\n", to: "c d.txt")
        let working = try await client.blame(path: "c d.txt", at: nil, in: history.root)
        #expect(working.lines.map(\.text) == ["alpha", "needle", "local"])
        #expect(working.lines.last?.commitID.allSatisfy { $0 == "0" } == true)
    }

    @Test("fileContents reads a revision, the index and the working file, byte for byte")
    func fileContentsAtRevisionAndIndex() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        #expect(try await client.fileContents(path: "latin.txt", at: "HEAD", in: history.root) == Self.latin1Cafe)
        #expect(try await client.fileContents(path: "a b.txt", at: history.initial, in: history.root)
            == Data("alpha\n".utf8))

        try history.repository.write("staged\n", to: "c d.txt")
        try await history.repository.run(["add", "c d.txt"])
        try history.repository.write("working\n", to: "c d.txt")
        #expect(try await client.fileContents(path: "c d.txt", at: ":0", in: history.root) == Data("staged\n".utf8))
        #expect(try await client.fileContents(path: "c d.txt", at: "HEAD", in: history.root)
            == Data("alpha\nneedle\n".utf8))
        let nested = history.repository.url("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        #expect(try await client.fileContents(path: "c d.txt", at: nil, in: nested) == Data("working\n".utf8))
    }

    @Test("fileContents reads the diff views' revision specs, <id>^1 and :0, for a path with spaces and Unicode")
    func fileContentsAtDiffRevisionsForAwkwardPath() async throws {
        let repository = try await GitTestRepository.make()
        defer { repository.tearDown() }
        let path = "dir é/naïve file.swift"
        try FileManager.default.createDirectory(at: repository.url("dir é"), withIntermediateDirectories: true)
        try repository.write("let a = 1\n", to: path)
        try await repository.run(["add", path])
        try await repository.commit("first", at: Self.epoch + 100)
        try repository.write("let a = 2\n", to: path)
        try await repository.run(["add", path])
        try await repository.commit("second", at: Self.epoch + 200)
        let second = try await repository.sha("HEAD")
        try repository.write("let a = 3\n", to: path)
        try await repository.run(["add", path])

        // The views read with the path the diff names. Process passes arguments decomposed,
        // so a `<rev>:<path>` lookup would miss the precomposed name git stores.
        let diff = try await client.diff(.commit(second, paths: []), options: GitDiffOptions(), in: repository.root)
        let named = try #require(diff.files.first?.newPath)
        #expect(named == path)
        #expect(try await client.fileContents(path: "dir é", at: second, in: repository.root) == nil)
        #expect(try await client.fileContents(path: "dir é/missing", at: ":0", in: repository.root) == nil)
        // A commit's old side is `<id>^1`, its new side `<id>`; the unstaged old side is `:0`.
        #expect(try await client.fileContents(path: named, at: second + "^1", in: repository.root)
            == Data("let a = 1\n".utf8))
        #expect(try await client.fileContents(path: named, at: second, in: repository.root) == Data("let a = 2\n".utf8))
        #expect(try await client.fileContents(path: named, at: ":0", in: repository.root) == Data("let a = 3\n".utf8))
    }

    @Test("fileContents of an absent path is nil, at a revision and in the working tree")
    func fileContentsMissingIsNil() async throws {
        let history = try await History.make()
        defer { history.tearDown() }
        #expect(try await client.fileContents(path: "nope.txt", at: "HEAD", in: history.root) == nil)
        #expect(try await client.fileContents(path: "nope.txt", at: ":0", in: history.root) == nil)
        #expect(try await client.fileContents(path: "nope.txt", at: nil, in: history.root) == nil)
        #expect(try await client.fileContents(path: "a b.txt", at: "HEAD", in: history.root) == nil)
    }
}
