import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitOperationState: kinds, skip, and reading git's operation files")
struct GitOperationStateTests {
    /// A stand-in git directory: the files are written by hand, so each rule is read in isolation.
    private struct FakeGitDirectory {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-operation-state-\(UUID().uuidString)")

        var files: GitOperationState.Files {
            GitOperationState.Files(
                rebaseMerge: root.appendingPathComponent("rebase-merge"),
                rebaseApply: root.appendingPathComponent("rebase-apply"),
                mergeHead: root.appendingPathComponent("MERGE_HEAD"),
                cherryPickHead: root.appendingPathComponent("CHERRY_PICK_HEAD"),
                revertHead: root.appendingPathComponent("REVERT_HEAD")
            )
        }

        func write(_ text: String, to path: String) throws {
            let file = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try Data(text.utf8).write(to: file)
        }

        func makeDirectory(_ path: String) throws {
            try FileManager.default.createDirectory(at: root.appendingPathComponent(path),
                                                    withIntermediateDirectories: true)
        }

        func tearDown() {
            try? FileManager.default.removeItem(at: root)
        }

        var state: GitOperationState { GitOperationState.read(files) }
    }

    @Test("each state's kind, and which allow skip")
    func kindsAndSkip() {
        #expect(GitOperationState.none.kind == nil)
        #expect(GitOperationState.merging(head: "a").kind == .merge)
        #expect(GitOperationState.rebasing(branch: nil, onto: nil, step: nil, total: nil, interactive: true).kind
                    == .rebase)
        #expect(GitOperationState.cherryPicking(commit: nil).kind == .cherryPick)
        #expect(GitOperationState.reverting(commit: "b").kind == .revert)

        #expect(!GitOperationState.none.allowsSkip)
        #expect(!GitOperationState.merging(head: "a").allowsSkip)
        #expect(GitOperationState.rebasing(branch: "f", onto: "o", step: 1, total: 2, interactive: false).allowsSkip)
        #expect(GitOperationState.cherryPicking(commit: "c").allowsSkip)
        #expect(GitOperationState.reverting(commit: nil).allowsSkip)
    }

    @Test("verbs and flags")
    func verbsAndFlags() {
        #expect(GitOperationKind.allCases.map(\.verb) == ["merge", "rebase", "cherry-pick", "revert"])
        #expect([GitOperationStep.continue, .abort, .skip].map(\.flag) == ["--continue", "--abort", "--skip"])
        #expect([GitMergeFastForward.allowed, .never, .only].map(\.flag) == ["--ff", "--no-ff", "--ff-only"])
        #expect(GitOperationState.gitPathNames
                    == ["rebase-merge", "rebase-apply", "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD"])
    }

    @Test("nothing present is none")
    func nothingIsNone() {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        #expect(directory.state == .none)
    }

    @Test("rebase-merge: branch stripped of refs/heads/, onto, step, total, interactive")
    func rebaseMerge() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("refs/heads/feature\n", to: "rebase-merge/head-name")
        try directory.write("abc123\n", to: "rebase-merge/onto")
        try directory.write("2\n", to: "rebase-merge/msgnum")
        try directory.write("5\n", to: "rebase-merge/end")
        #expect(directory.state == .rebasing(branch: "feature", onto: "abc123", step: 2, total: 5, interactive: false))
        try directory.write("", to: "rebase-merge/interactive")
        #expect(directory.state == .rebasing(branch: "feature", onto: "abc123", step: 2, total: 5, interactive: true))
    }

    @Test("a plain rebase writes interactive too, with drop_redundant_commits: not interactive")
    func plainMergeBackendRebase() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("", to: "rebase-merge/interactive")
        try directory.write("", to: "rebase-merge/drop_redundant_commits")
        #expect(directory.state == .rebasing(branch: nil, onto: nil, step: nil, total: nil, interactive: false))
    }

    @Test("rebase-apply: next and last are the step and total, never interactive")
    func rebaseApply() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("refs/heads/topic\n", to: "rebase-apply/head-name")
        try directory.write("def456\n", to: "rebase-apply/onto")
        try directory.write("3\n", to: "rebase-apply/next")
        try directory.write("4\n", to: "rebase-apply/last")
        #expect(directory.state == .rebasing(branch: "topic", onto: "def456", step: 3, total: 4, interactive: false))
    }

    @Test("missing, empty or non-numeric files give nil fields, never a failure")
    func missingFieldsAreNil() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.makeDirectory("rebase-merge")
        try directory.write("x\n", to: "rebase-merge/msgnum")
        try directory.write("  \n", to: "rebase-merge/onto")
        #expect(directory.state == .rebasing(branch: nil, onto: nil, step: nil, total: nil, interactive: false))
    }

    @Test("a detached rebase's head-name is kept as git wrote it")
    func detachedHeadName() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("detached HEAD\n", to: "rebase-merge/head-name")
        #expect(directory.state == .rebasing(branch: "detached HEAD", onto: nil, step: nil, total: nil,
                                             interactive: false))
    }

    @Test("MERGE_HEAD's first commit; CHERRY_PICK_HEAD; REVERT_HEAD; rebase wins over the rest")
    func headFiles() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("bbb\n", to: "REVERT_HEAD")
        #expect(directory.state == .reverting(commit: "bbb"))
        try directory.write("ccc\n", to: "CHERRY_PICK_HEAD")
        #expect(directory.state == .cherryPicking(commit: "ccc"))
        try directory.write("aaa\nddd\n", to: "MERGE_HEAD")
        #expect(directory.state == .merging(head: "aaa"))
        try directory.makeDirectory("rebase-apply")
        #expect(directory.state == .rebasing(branch: nil, onto: nil, step: nil, total: nil, interactive: false))
    }

    @Test("an empty MERGE_HEAD is still a merge, with no head")
    func emptyMergeHead() throws {
        let directory = FakeGitDirectory()
        defer { directory.tearDown() }
        try directory.write("", to: "MERGE_HEAD")
        #expect(directory.state == .merging(head: nil))
    }
}
