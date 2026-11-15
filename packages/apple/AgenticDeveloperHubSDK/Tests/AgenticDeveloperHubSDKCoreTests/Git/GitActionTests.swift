import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitAction verbs and arguments")
struct GitActionTests {
    private func expect(_ action: GitAction, _ verb: String, _ arguments: [String],
                        sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(action.verb == verb, sourceLocation: sourceLocation)
        #expect(action.arguments == arguments, sourceLocation: sourceLocation)
    }

    @Test("staging and unstaging")
    func staging() {
        expect(.stage(paths: ["a.txt", "-b"]), "add", ["--", ":(top,literal)a.txt", ":(top,literal)-b"])
        expect(.stageAll, "add", ["-A"])
        expect(.unstage(paths: ["a.txt"]), "reset", ["-q", "--", ":(top,literal)a.txt"])
        expect(.unstageAll, "reset", ["-q"])
    }

    @Test("discarding and removing untracked files")
    func discarding() {
        expect(.discard(paths: ["a.txt", "b.txt"]), "restore",
               ["--worktree", "--", ":(top,literal)a.txt", ":(top,literal)b.txt"])
        expect(.removeUntracked(paths: ["c.txt"]), "clean", ["-f", "-d", "--", ":(top,literal)c.txt"])
    }

    @Test("only a path-taking action with no paths has an empty path list")
    func emptyPathLists() {
        let empty: [GitAction] = [
            .stage(paths: []), .unstage(paths: []), .discard(paths: []), .removeUntracked(paths: [])
        ]
        #expect(empty.allSatisfy { $0.hasEmptyPathList })
        let full: [GitAction] = [
            .stage(paths: ["a"]), .unstage(paths: ["a"]), .discard(paths: ["a"]), .removeUntracked(paths: ["a"]),
            .stageAll, .unstageAll, .push, .stashSave(message: nil)
        ]
        #expect(!full.contains { $0.hasEmptyPathList })
    }

    @Test("committing, with and without amend")
    func committing() {
        expect(.commit(message: "subject\n\nbody", amend: false), "commit",
               ["--cleanup=strip", "-m", "subject\n\nbody"])
        expect(.commit(message: "subject", amend: true), "commit", ["--cleanup=strip", "-m", "subject", "--amend"])
    }

    @Test("fetch, pull and push")
    func network() {
        expect(.fetch(remote: nil), "fetch", ["--all", "--prune"])
        expect(.fetch(remote: "origin"), "fetch", ["--prune", "origin"])
        expect(.pull, "pull", ["--no-edit"])
        expect(.push, "push", [])
        expect(.pushSettingUpstream(remote: "origin", branch: "main"), "push", ["--set-upstream", "origin", "main"])
        expect(.pushToUpstream(remote: "origin", branch: "feat", upstreamBranch: "feature"), "push",
               ["origin", "refs/heads/feat:refs/heads/feature"])
    }

    @Test("creating branches, with and without checkout and a start point")
    func creatingBranches() {
        expect(.createBranch(name: "topic", startPoint: nil, checkout: false), "branch", ["topic"])
        expect(.createBranch(name: "topic", startPoint: "abc123", checkout: false), "branch", ["topic", "abc123"])
        expect(.createBranch(name: "topic", startPoint: nil, checkout: true), "switch", ["-c", "topic"])
        expect(.createBranch(name: "topic", startPoint: "v1", checkout: true), "switch", ["-c", "topic", "v1"])
    }

    @Test("checking out")
    func checkingOut() {
        expect(.checkout(branch: "main"), "switch", ["main"])
        expect(.checkoutTracking(remoteBranch: "origin/topic"), "switch", ["--track", "origin/topic"])
        expect(.checkoutDetached(commit: "abc123"), "switch", ["--detach", "abc123"])
    }

    @Test("renaming and deleting branches")
    func renamingAndDeletingBranches() {
        expect(.renameBranch(from: "old", to: "new"), "branch", ["-m", "old", "new"])
        expect(.deleteBranch(name: "topic", force: false), "branch", ["-d", "topic"])
        expect(.deleteBranch(name: "topic", force: true), "branch", ["-D", "topic"])
        expect(.deleteRemoteBranch(remote: "origin", name: "topic"), "push", ["origin", "--delete", "topic"])
    }

    @Test("tags, lightweight and annotated")
    func tags() {
        expect(.createTag(name: "v1", commit: "abc123", message: nil), "tag", ["v1", "abc123"])
        expect(.createTag(name: "v1", commit: "abc123", message: "version one"), "tag",
               ["-a", "v1", "-m", "version one", "abc123"])
        expect(.deleteTag(name: "v1"), "tag", ["-d", "v1"])
        expect(.pushTag(name: "v1", remote: "origin"), "push", ["origin", "refs/tags/v1"])
    }

    @Test("stashes, an empty or missing message passing no -m")
    func stashes() {
        expect(.stashSave(message: nil), "stash", ["push", "--include-untracked"])
        expect(.stashSave(message: ""), "stash", ["push", "--include-untracked"])
        expect(.stashSave(message: "wip"), "stash", ["push", "--include-untracked", "-m", "wip"])
        expect(.stashApply(index: 2), "stash", ["apply", "stash@{2}"])
        expect(.stashPop(index: 0), "stash", ["pop", "stash@{0}"])
        expect(.stashDrop(index: 1), "stash", ["drop", "stash@{1}"])
    }

    @Test("cherry-pick and revert, with and without a mainline")
    func cherryPickAndRevert() {
        expect(.cherryPick(commit: "abc123", mainline: nil), "cherry-pick", ["abc123"])
        expect(.cherryPick(commit: "abc123", mainline: 1), "cherry-pick", ["-m", "1", "abc123"])
        expect(.revert(commit: "abc123", mainline: nil), "revert", ["--no-edit", "abc123"])
        expect(.revert(commit: "abc123", mainline: 2), "revert", ["--no-edit", "-m", "2", "abc123"])
    }

    @Test("reset in every mode")
    func reset() {
        expect(.reset(commit: "abc123", mode: .soft), "reset", ["--soft", "abc123"])
        expect(.reset(commit: "abc123", mode: .mixed), "reset", ["--mixed", "abc123"])
        expect(.reset(commit: "abc123", mode: .hard), "reset", ["--hard", "abc123"])
        #expect(GitResetMode.allCases == [.soft, .mixed, .hard])
    }

    @Test("network verbs and commit are long-running; local verbs are not")
    func longRunning() {
        let long: [GitAction] = [
            .commit(message: "m", amend: false), .fetch(remote: nil), .pull, .push,
            .pushSettingUpstream(remote: "origin", branch: "main"),
            .pushToUpstream(remote: "origin", branch: "feat", upstreamBranch: "feature"),
            .deleteRemoteBranch(remote: "origin", name: "topic"), .pushTag(name: "v1", remote: "origin")
        ]
        let short: [GitAction] = [
            .stage(paths: ["a"]), .stageAll, .unstage(paths: ["a"]), .unstageAll, .discard(paths: ["a"]),
            .removeUntracked(paths: ["a"]), .createBranch(name: "b", startPoint: nil, checkout: true),
            .checkout(branch: "b"), .checkoutTracking(remoteBranch: "origin/b"), .checkoutDetached(commit: "c"),
            .renameBranch(from: "a", to: "b"), .deleteBranch(name: "b", force: false),
            .createTag(name: "t", commit: "c", message: nil), .deleteTag(name: "t"), .stashSave(message: nil),
            .stashApply(index: 0), .stashPop(index: 0), .stashDrop(index: 0),
            .cherryPick(commit: "c", mainline: nil), .revert(commit: "c", mainline: nil),
            .reset(commit: "c", mode: .hard)
        ]
        #expect(long.filter { !$0.isLongRunning }.isEmpty)
        #expect(short.filter(\.isLongRunning).isEmpty)
    }

    @Test("an empty or dash-led ref, remote or commit is invalid; paths and messages never are")
    func invalidOperands() {
        let invalid: [(GitAction, String)] = [
            (.createBranch(name: "--delete", startPoint: "main", checkout: false), "--delete"),
            (.createBranch(name: "topic", startPoint: "-f", checkout: true), "-f"),
            (.checkout(branch: "-f"), "-f"),
            (.checkoutTracking(remoteBranch: "-b"), "-b"),
            (.deleteBranch(name: "", force: false), ""),
            (.createTag(name: "-d", commit: "v2", message: nil), "-d"),
            (.createTag(name: "v1", commit: "--all", message: "m"), "--all"),
            (.deleteTag(name: "-l"), "-l"),
            (.checkoutDetached(commit: "--orphan"), "--orphan"),
            (.cherryPick(commit: "--abort", mainline: nil), "--abort"),
            (.revert(commit: "", mainline: nil), ""),
            (.reset(commit: "--hard", mode: .soft), "--hard"),
            (.fetch(remote: "--upload-pack=x"), "--upload-pack=x"),
            (.pushSettingUpstream(remote: "-q", branch: "main"), "-q"),
            (.pushSettingUpstream(remote: "origin", branch: "--force"), "--force"),
            (.pushToUpstream(remote: "-q", branch: "feat", upstreamBranch: "feature"), "-q"),
            (.pushToUpstream(remote: "origin", branch: "-f", upstreamBranch: "feature"), "-f"),
            (.pushToUpstream(remote: "origin", branch: "feat", upstreamBranch: ""), ""),
            (.deleteRemoteBranch(remote: "origin", name: "--mirror"), "--mirror"),
            (.pushTag(name: "v1", remote: "--force"), "--force"),
            (.renameBranch(from: "-M", to: "topic"), "-M"),
            (.renameBranch(from: "topic", to: "-D"), "-D")
        ]
        for (action, operand) in invalid {
            #expect(action.invalidOperand == operand, "\(action)")
        }
        let valid: [GitAction] = [
            .stage(paths: ["-a"]), .unstage(paths: ["--x"]), .discard(paths: ["-"]), .removeUntracked(paths: ["-r"]),
            .commit(message: "-m", amend: false), .stashSave(message: "--x"), .fetch(remote: nil),
            .createBranch(name: "topic", startPoint: nil, checkout: true),
            .createTag(name: "v1", commit: "HEAD", message: "-a"),
            .renameBranch(from: "a-b", to: "c-d"), .reset(commit: "HEAD~2", mode: .hard)
        ]
        #expect(valid.compactMap(\.invalidOperand).isEmpty)
    }

    @Test("applying a patch: to the index or the work tree, forward or reversed, the patch on standard input")
    func applyingPatches() {
        let patch = "diff --git a/a.txt b/a.txt\n"
        expect(.applyToIndex(patch: patch, reverse: false), "apply", ["--cached", "--whitespace=nowarn", "-"])
        expect(.applyToIndex(patch: patch, reverse: true), "apply",
               ["--cached", "--whitespace=nowarn", "--reverse", "-"])
        expect(.applyToWorktree(patch: patch, reverse: false), "apply", ["--whitespace=nowarn", "-"])
        expect(.applyToWorktree(patch: patch, reverse: true), "apply", ["--whitespace=nowarn", "--reverse", "-"])
        #expect(GitAction.applyToIndex(patch: patch, reverse: true).standardInput == Data(patch.utf8))
        #expect(GitAction.applyToWorktree(patch: patch, reverse: false).standardInput == Data(patch.utf8))
        #expect(GitAction.stage(paths: ["a"]).standardInput == nil)
        #expect(GitAction.commit(message: "m", amend: false).standardInput == nil)
        #expect(GitAction.applyToIndex(patch: "--x", reverse: false).invalidOperand == nil)
        #expect(!GitAction.applyToIndex(patch: patch, reverse: false).isLongRunning)
        #expect(GitAction.applyToIndex(patch: "", reverse: false).hasEmptyPatch)
        #expect(GitAction.applyToWorktree(patch: "", reverse: true).hasEmptyPatch)
        #expect(!GitAction.applyToWorktree(patch: patch, reverse: true).hasEmptyPatch)
        #expect(!GitAction.stage(paths: []).hasEmptyPatch)
    }
}
