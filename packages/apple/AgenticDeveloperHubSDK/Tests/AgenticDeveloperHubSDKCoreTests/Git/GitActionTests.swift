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
               ["--cleanup=whitespace", "-m", "subject\n\nbody"])
        expect(.commit(message: "subject", amend: true), "commit", ["--cleanup=whitespace", "-m", "subject", "--amend"])
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
        expect(.reset(commit: "abc123", mode: .soft), "reset", ["--soft", "abc123", "--"])
        expect(.reset(commit: "abc123", mode: .mixed), "reset", ["--mixed", "abc123", "--"])
        expect(.reset(commit: "abc123", mode: .hard), "reset", ["--hard", "abc123", "--"])
        #expect(GitResetMode.allCases == [.soft, .mixed, .hard])
    }

    @Test("network verbs and commit are long-running; local verbs are not")
    func longRunning() {
        let long: [GitAction] = [
            .commit(message: "m", amend: false), .fetch(remote: nil), .pull, .push,
            .pushSettingUpstream(remote: "origin", branch: "main"),
            .pushToUpstream(remote: "origin", branch: "feat", upstreamBranch: "feature"),
            .deleteRemoteBranch(remote: "origin", name: "topic"), .pushTag(name: "v1", remote: "origin"),
            .merge(ref: "topic", fastForward: .allowed), .rebase(onto: "main"), .operation(.rebase, .continue),
            .operation(.merge, .continue), .operation(.cherryPick, .skip), .operation(.revert, .continue)
        ]
        let short: [GitAction] = [
            .stage(paths: ["a"]), .stageAll, .unstage(paths: ["a"]), .unstageAll, .discard(paths: ["a"]),
            .removeUntracked(paths: ["a"]), .createBranch(name: "b", startPoint: nil, checkout: true),
            .checkout(branch: "b"), .checkoutTracking(remoteBranch: "origin/b"), .checkoutDetached(commit: "c"),
            .renameBranch(from: "a", to: "b"), .deleteBranch(name: "b", force: false),
            .createTag(name: "t", commit: "c", message: nil), .deleteTag(name: "t"), .stashSave(message: nil),
            .stashApply(index: 0), .stashPop(index: 0), .stashDrop(index: 0),
            .cherryPick(commit: "c", mainline: nil), .revert(commit: "c", mainline: nil),
            .reset(commit: "c", mode: .hard), .operation(.merge, .abort), .operation(.rebase, .abort),
            .operation(.cherryPick, .abort), .operation(.revert, .abort)
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
            (.renameBranch(from: "topic", to: "-D"), "-D"),
            (.merge(ref: "-f", fastForward: .allowed), "-f"),
            (.merge(ref: "", fastForward: .only), ""),
            (.rebase(onto: "--root"), "--root"),
            (.rebase(onto: ""), "")
        ]
        for (action, operand) in invalid {
            #expect(action.invalidOperand == operand, "\(action)")
        }
        let valid: [GitAction] = [
            .stage(paths: ["-a"]), .unstage(paths: ["--x"]), .discard(paths: ["-"]), .removeUntracked(paths: ["-r"]),
            .commit(message: "-m", amend: false), .stashSave(message: "--x"), .fetch(remote: nil),
            .createBranch(name: "topic", startPoint: nil, checkout: true),
            .createTag(name: "v1", commit: "HEAD", message: "-a"),
            .renameBranch(from: "a-b", to: "c-d"), .reset(commit: "HEAD~2", mode: .hard),
            .merge(ref: "origin/main", fastForward: .never), .rebase(onto: "main"), .operation(.rebase, .skip)
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

    @Test("merge with each fast-forward rule; rebase onto a ref")
    func mergeAndRebase() {
        expect(.merge(ref: "topic", fastForward: .allowed), "merge", ["--no-edit", "--ff", "topic"])
        expect(.merge(ref: "topic", fastForward: .never), "merge", ["--no-edit", "--no-ff", "topic"])
        expect(.merge(ref: "origin/main", fastForward: .only), "merge", ["--no-edit", "--ff-only", "origin/main"])
        expect(.rebase(onto: "main"), "rebase", ["main"])
        #expect(GitMergeFastForward.allowed.rawValue == "allowed")
    }

    @Test("every operation kind takes every step through its own verb")
    func operationSteps() {
        let verbs: [GitOperationKind: String] = [
            .merge: "merge", .rebase: "rebase", .cherryPick: "cherry-pick", .revert: "revert"
        ]
        let flags: [GitOperationStep: String] = [.continue: "--continue", .abort: "--abort", .skip: "--skip"]
        #expect(GitOperationKind.allCases == [.merge, .rebase, .cherryPick, .revert])
        for kind in GitOperationKind.allCases {
            for (step, flag) in flags {
                expect(.operation(kind, step), verbs[kind] ?? "", [flag])
                #expect(GitAction.operation(kind, step).operands.isEmpty)
            }
        }
    }

    @Test("a merge has no skip step: only merge-skip is an unsupported step")
    func mergeSkipIsUnsupported() {
        #expect(GitAction.operation(.merge, .skip).isUnsupportedStep)
        let supported: [GitAction] = [
            .operation(.merge, .continue), .operation(.merge, .abort), .operation(.rebase, .skip),
            .operation(.cherryPick, .skip), .operation(.revert, .skip), .merge(ref: "t", fastForward: .only),
            .rebase(onto: "main"), .stageAll
        ]
        #expect(supported.filter(\.isUnsupportedStep).isEmpty)
    }

    @Test("resolving a conflict by side, and removing paths")
    func resolvingConflicts() {
        expect(.resolve(paths: ["a.txt", "-b"], side: .ours), "checkout",
               ["--ours", "--", ":(top,literal)a.txt", ":(top,literal)-b"])
        expect(.resolve(paths: ["a.txt"], side: .theirs), "checkout", ["--theirs", "--", ":(top,literal)a.txt"])
        expect(.removePaths(paths: ["gone.txt"]), "rm", ["-q", "--", ":(top,literal)gone.txt"])
        #expect(GitAction.resolve(paths: [], side: .ours).hasEmptyPathList)
        #expect(GitAction.removePaths(paths: []).hasEmptyPathList)
        #expect(!GitAction.resolve(paths: ["a"], side: .theirs).hasEmptyPathList)
    }

    @Test("an interactive rebase names only onto; its operand is checked")
    func interactiveRebase() {
        let plan = GitRebasePlan(onto: "abc1234", entries: [GitRebaseEntry(commit: "def5678", subject: "s")])
        expect(.interactiveRebase(plan), "rebase", ["-i", "abc1234"])
        #expect(GitAction.interactiveRebase(plan).operands == ["abc1234"])
        #expect(GitAction.interactiveRebase(GitRebasePlan(onto: "--root", entries: [])).invalidOperand == "--root")
        #expect(GitAction.interactiveRebase(plan).isLongRunning)
    }

    @Test("adding and removing worktrees")
    func worktrees() {
        expect(.addWorktree(path: "/tmp/wt", branch: "topic", createBranch: true, startPoint: nil), "worktree",
               ["add", "-b", "topic", "/tmp/wt"])
        expect(.addWorktree(path: "/tmp/wt", branch: "topic", createBranch: true, startPoint: "main"), "worktree",
               ["add", "-b", "topic", "/tmp/wt", "main"])
        expect(.addWorktree(path: "/tmp/wt", branch: "topic", createBranch: false, startPoint: "ignored"), "worktree",
               ["add", "/tmp/wt", "topic"])
        expect(.removeWorktree(path: "/tmp/wt", force: false), "worktree", ["remove", "/tmp/wt"])
        expect(.removeWorktree(path: "/tmp/wt", force: true), "worktree", ["remove", "--force", "/tmp/wt"])
        #expect(GitAction.addWorktree(path: "/w", branch: "-x", createBranch: true, startPoint: nil)
            .invalidOperand == "-x")
        #expect(GitAction.addWorktree(path: "/w", branch: "b", createBranch: true, startPoint: "-s")
            .invalidOperand == "-s")
        #expect(GitAction.addWorktree(path: "/w", branch: "b", createBranch: false, startPoint: "-s")
            .invalidOperand == nil)
        #expect(GitAction.addWorktree(path: "/w", branch: "b", createBranch: false, startPoint: nil).isLongRunning)
        #expect(!GitAction.removeWorktree(path: "/w", force: false).isLongRunning)
    }

    @Test("only a relative worktree path is reported as relative")
    func relativeWorktreePaths() {
        #expect(GitAction.addWorktree(path: "wt", branch: "b", createBranch: false, startPoint: nil)
            .relativeWorktreePath == "wt")
        #expect(GitAction.removeWorktree(path: "../wt", force: true).relativeWorktreePath == "../wt")
        #expect(GitAction.removeWorktree(path: "-f", force: false).relativeWorktreePath == "-f")
        #expect(GitAction.removeWorktree(path: "/tmp/wt", force: false).relativeWorktreePath == nil)
        #expect(GitAction.stageAll.relativeWorktreePath == nil)
    }

    @Test("updating submodules: every one when no paths are named, which is not an empty path list")
    func updatingSubmodules() {
        expect(.updateSubmodules(paths: [], initialize: false), "submodule", ["update", "--recursive"])
        expect(.updateSubmodules(paths: [], initialize: true), "submodule", ["update", "--init", "--recursive"])
        expect(.updateSubmodules(paths: ["lib/a"], initialize: true), "submodule",
               ["update", "--init", "--recursive", "--", ":(top,literal)lib/a"])
        #expect(!GitAction.updateSubmodules(paths: [], initialize: true).hasEmptyPathList)
        #expect(GitAction.updateSubmodules(paths: [], initialize: false).isLongRunning)
    }
}
