import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitWorktree.parse")
struct GitWorktreeParserTests {
    @Test("-z output: NUL-terminated records keep a newline in a path")
    func nulTerminated() {
        let output = "worktree /repo\0HEAD abc\0branch refs/heads/main\0\0"
            + "worktree /wt/two\nlines\0HEAD def\0detached\0\0"
        let trees = GitWorktree.parse(porcelain: output)
        #expect(trees.map(\.directory.path) == ["/repo", "/wt/two\nlines"])
        #expect(trees.map(\.branch) == ["main", nil])
        #expect(trees.map(\.isDetached) == [false, true])
    }
    private let sample = """
    worktree /repo
    HEAD 1111111111111111111111111111111111111111
    branch refs/heads/main

    worktree /repo/.claude/worktrees/tabs
    HEAD 2222222222222222222222222222222222222222
    branch refs/heads/tabs

    worktree /repo/.claude/worktrees/spike
    HEAD 3333333333333333333333333333333333333333
    detached

    worktree /bare.git
    bare

    """

    @Test("the first entry is the main worktree")
    func firstIsMain() {
        let trees = GitWorktree.parse(porcelain: sample)
        #expect(trees.count == 4)
        #expect(trees[0].isMain)
        // Spelled with the flavour, because the parser spells it too. A URL
        // built without `isDirectory:` asks the filesystem, and `/repo` does
        // not exist, so Foundation would call it a file and the two would
        // compare unequal over a trailing slash — which is exactly the
        // stat-dependent equality the parser stopped relying on.
        #expect(trees[0].directory == URL(fileURLWithPath: "/repo", isDirectory: true))
        #expect(trees[0].branch == "main")
        #expect(trees[0].head == "1111111111111111111111111111111111111111")
        #expect(trees[1].isMain == false)
    }

    @Test("branch refs are shortened to their name")
    func shortBranchNames() {
        let trees = GitWorktree.parse(porcelain: sample)
        #expect(trees[1].branch == "tabs")
    }

    @Test("detached and bare entries are flagged")
    func detachedAndBare() {
        let trees = GitWorktree.parse(porcelain: sample)
        #expect(trees[2].isDetached)
        #expect(trees[2].branch == nil)
        #expect(trees[3].isBare)
    }

    @Test("empty output yields no worktrees")
    func empty() {
        #expect(GitWorktree.parse(porcelain: "").isEmpty)
    }

    @Test("no trailing blank line still flushes the last entry")
    func noTrailingBlankLine() {
        let trees = GitWorktree.parse(porcelain: "worktree /solo\nHEAD abc\nbranch refs/heads/solo")
        #expect(trees.count == 1)
        #expect(trees[0].isMain)
        #expect(trees[0].branch == "solo")
    }

    @Test("a locked worktree is flagged, with or without a reason; the flag does not carry over")
    func locked() {
        let output = "worktree /a\nHEAD 1\nbranch refs/heads/a\nlocked\n\n"
            + "worktree /b\nHEAD 2\nbranch refs/heads/b\nlocked on a removable disk\n\n"
            + "worktree /c\nHEAD 3\nbranch refs/heads/c\n"
        let trees = GitWorktree.parse(porcelain: output)
        #expect(trees.map(\.isLocked) == [true, true, false])
    }
}
