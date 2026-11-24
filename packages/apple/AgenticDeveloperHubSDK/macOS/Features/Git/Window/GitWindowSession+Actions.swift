import AppKit
import AgenticDeveloperHubSDKCore

/// The Git window's actions (recipe `workspace/git/git-window`, "Actions"): every intent
/// a view sends and every toolbar verb goes through `perform(_:)`, which runs one at a
/// time, asks the user through `presenter`, runs git through the model and shows a
/// failure under the action's title. The model has refreshed by then, so the views
/// already show what the action left behind.
extension GitWindowSession {

    /// Everything the window can be asked to do.
    enum Request {
        case workingCopy(GitWorkingCopyIntent)
        case commit(GitCommitIntent, GitCommit)
        case ref(GitRefIntent)
        /// A diff row menu's stage, unstage or discard of some lines.
        case diff(GitDiffIntent)
        /// The banner's continue, skip or abort of the operation in progress.
        case operation(GitOperationStep)
        /// The merge view's save or cancel.
        case merge(GitMergeIntent)
        /// The toolbar's verbs.
        case fetch, pull, push, newBranch, stash, popStash
        /// The Fetch menu's LFS verbs, shown while the repository uses LFS.
        case lfsFetch, lfsPull
        /// The reflog browser's reset, checkout or new branch at an entry.
        case reflog(GitReflogIntent)
        /// The toolbar's and the Git menu's Undo: a mixed reset to HEAD@{1}.
        case undo
        /// Check out or create a pull request (GitWindowSession+PullRequests.swift).
        case pullRequest(GitPullRequestIntent)
    }

    // MARK: - Toolbar verbs

    /// Fetches every remote.
    func fetch() { perform(.fetch) }
    /// Pulls into the checked-out branch.
    func pull() { perform(.pull) }
    /// Pushes the checked-out branch, setting its upstream when it has none.
    func push() { perform(.push) }
    /// Asks for a name and creates and checks out a branch at HEAD.
    func newBranch() { perform(.newBranch) }
    /// Asks for an optional message and stashes every change, untracked files too.
    func stash() { perform(.stash) }
    /// Pops the newest stash, when there is one.
    func popStash() { perform(.popStash) }
    /// Moves HEAD back to HEAD@{1} with a mixed reset, when there is an `undoTarget`.
    func undo() { perform(.undo) }

    // MARK: - The funnel

    /// Runs `request` unless an action is already running, when it is ignored; `isActing`
    /// spans the whole request, sheets included. The overview's spinner and `onBusyChange`
    /// follow only the stretches where git runs, never a sheet waiting for an answer.
    func perform(_ request: Request) {
        guard !isActing else { return }
        isActing = true
        actionTask = Task { [weak self] in
            guard let self else { return }
            await self.run(request)
            self.isActing = false
        }
    }

    private func run(_ request: Request) async {
        switch request {
        case .workingCopy(let intent): await run(intent)
        case let .commit(intent, commit): await run(intent, on: commit)
        case .ref(let intent): await run(intent)
        case .diff(let intent): await run(intent)
        case .operation(let step): await runOperation(step)
        case .merge(let intent): await run(intent)
        case .fetch:
            // Before the fetch: `gh` reads GitHub, not the fetched refs, and the refs
            // change the fetch makes then falls in the forced load's interval.
            model.pullRequestList?.load(force: true)
            await execute(.fetch(remote: nil))
        case .pull: await execute(.pull)
        case .lfsFetch: await execute(.lfsFetch)
        case .lfsPull: await execute(.lfsPull)
        case .push: await pushHead()
        case .newBranch: await createBranch(at: nil, describedAs: nil)
        case .stash: await stashChanges()
        case .popStash:
            if !model.stashes.isEmpty { await execute(.stashPop(index: 0)) }
        case .reflog(let intent): await run(intent)
        case .undo: await undoLastAction()
        case .pullRequest(let intent): await runPullRequest(intent)
        }
    }

    // MARK: - Working copy

    private func run(_ intent: GitWorkingCopyIntent) async {
        switch intent {
        case .stage(let paths): await execute(.stage(paths: paths))
        case .unstage(let paths): await execute(.unstage(paths: paths))
        case .stageAll: await stageAll()
        case .unstageAll: await execute(.unstageAll)
        case .discard(let paths): await discard(paths)
        case .discardAll: await discard(model.unstaged.map(\.path).filter { model.conflicts[$0] == nil })
        case let .commit(message, amend):
            if await execute(.commit(message: message, amend: amend)) { workingCopy.commitDidSucceed() }
        case .amendChanged(let amend):
            if amend { await fillAmendMessage() }
        case let .resolve(paths, side): await resolve(paths, using: side)
        case .markResolved(let paths): await execute(.stage(paths: paths))
        case .openMerge(let path):
            openMerge(path)
            await mergeOpenTask?.value
        }
    }

    /// Stages what the Unstaged list shows. With no conflicts that is everything, `add -A`;
    /// with conflicts it is the unstaged paths that are not conflicted, by literal
    /// pathspec, so no conflict is marked resolved with its markers in it. Nothing left
    /// to stage runs nothing.
    private func stageAll() async {
        guard !model.conflicts.isEmpty else {
            await execute(.stageAll)
            return
        }
        let paths = model.unstaged.map(\.path).filter { model.conflicts[$0] == nil }
        guard !paths.isEmpty else { return }
        await execute(.stage(paths: paths))
    }

    // MARK: - Conflicts

    /// Confirms, then takes `side` whole for each path: a path whose chosen side has the
    /// file checks that side out and stages it; one whose chosen side deleted it is
    /// removed. The removal is skipped when the first step fails.
    private func resolve(_ paths: [String], using side: GitConflictSide) async {
        guard !paths.isEmpty, let presenter else { return }
        let count = paths.count
        let ours = side == .ours
        let confirmation = GitConfirmation(
            title: "Resolve \(count) \(count == 1 ? "file" : "files") using \(ours ? "ours" : "theirs")?",
            message: "\(ours ? "Their" : "Our") changes to \(count == 1 ? "it" : "them") are lost.",
            actionTitle: ours ? "Use Ours" : "Use Theirs", isDestructive: true)
        guard await presenter.confirm(confirmation) else { return }
        let kept = paths.filter { path in
            guard let kind = model.conflicts[path] else { return true }
            return ours ? kind.hasOurs : kind.hasTheirs
        }
        let removed = paths.filter { !kept.contains($0) }
        if !kept.isEmpty {
            guard await execute(.resolve(paths: kept, side: side)),
                  await execute(.stage(paths: kept)) else { return }
        }
        if !removed.isEmpty { await execute(.removePaths(paths: removed)) }
    }

    /// Reads the working file and shows it in the merge view; a file larger than
    /// `GitMergeViewController.maximumFileBytes`, not UTF-8, or holding no conflict the
    /// parser accepts shows its `.conflicted` diff instead. The file is decoded and parsed
    /// off the main thread. Opening is a read, so it is not gated by `isActing`: selecting
    /// a conflict during a fetch still opens it. Each open supersedes the one before, and
    /// any selection made while it reads (`showDiff`, `clearDiff`) supersedes it, so only
    /// the latest selection's result is shown.
    func openMerge(_ path: String) {
        let generation = supersedeBottomPane()
        mergeOpenTask = Task { [weak self] in
            guard let self else { return }
            let data: Data?
            do {
                data = try await self.model.contents(
                    path: path, at: nil, maximumBytes: GitMergeViewController.maximumFileBytes)
            } catch {
                guard generation == self.bottomGeneration, !Task.isCancelled else { return }
                self.showFailure(title: "Open failed", error: error)
                return
            }
            let parsed = await Task.detached { () -> GitConflictDocument? in
                guard let data, let text = String(data: data, encoding: .utf8) else { return nil }
                return GitConflictDocument.parse(text)
            }.value
            guard generation == self.bottomGeneration, !Task.isCancelled else { return }
            guard let document = parsed else {
                self.showDiff(target: .conflicted(path: path), file: path)
                return
            }
            self.merge.show(path: path, document: document)
            self.bottom.show(self.merge)
        }
    }

    /// Save writes the resolved text, stages it and returns to the diff; Cancel returns at once.
    private func run(_ intent: GitMergeIntent) async {
        switch intent {
        case let .save(path, text):
            do {
                try await whileGitRuns { try await model.writeResolution(text, to: path) }
            } catch {
                showFailure(title: "Save failed", error: error)
                return
            }
            guard await execute(.stage(paths: [path])) else { return }
            showDiff(target: .staged(paths: [path]), file: path)
        case .cancel:
            bottom.show(diff)
        }
    }

    /// Confirms, then restores the tracked paths and deletes the untracked ones, as two
    /// actions when there are both; the second is skipped when the first fails.
    private func discard(_ paths: [String]) async {
        guard !paths.isEmpty, let presenter else { return }
        let count = paths.count
        let confirmation = GitConfirmation(
            title: "Discard changes to \(count) \(count == 1 ? "file" : "files")?",
            message: "This cannot be undone.", actionTitle: "Discard Changes", isDestructive: true)
        guard await presenter.confirm(confirmation) else { return }
        let untrackedPaths = Set(model.unstaged.filter(\.isUntracked).map(\.path))
        let tracked = paths.filter { !untrackedPaths.contains($0) }
        let untracked = paths.filter { untrackedPaths.contains($0) }
        if !tracked.isEmpty, !(await execute(.discard(paths: tracked))) { return }
        if !untracked.isEmpty { await execute(.removeUntracked(paths: untracked)) }
    }

    // MARK: - Diff

    /// Stages or unstages the selected lines at once; discarding them confirms first. A
    /// selection no patch can be built from does nothing, and asks nothing.
    private func run(_ intent: GitDiffIntent) async {
        switch intent {
        case .stage(let selection):
            guard let patch = GitPatchBuilder.patch(selection, direction: .forward) else { return }
            await execute(.applyToIndex(patch: patch, reverse: false))
        case .unstage(let selection):
            guard let patch = GitPatchBuilder.patch(selection, direction: .reverse) else { return }
            await execute(.applyToIndex(patch: patch, reverse: true))
        case .discard(let selection):
            guard let patch = GitPatchBuilder.patch(selection, direction: .reverse), let presenter else { return }
            let count = selection.lines.reduce(0) { total, entry in
                guard selection.file.hunks.indices.contains(entry.key) else { return total }
                let lines = selection.file.hunks[entry.key].lines
                return total + entry.value.filter { lines.indices.contains($0) && GitPatchBuilder.isChange(lines[$0]) }
                    .count
            }
            let confirmation = GitConfirmation(
                title: "Discard \(count) selected \(count == 1 ? "line" : "lines")?",
                message: "This cannot be undone.", actionTitle: "Discard", isDestructive: true)
            guard await presenter.confirm(confirmation) else { return }
            await execute(.applyToWorktree(patch: patch, reverse: true))
        }
    }

    /// Fills an empty message box with HEAD's message, for an amend.
    private func fillAmendMessage() async {
        let box = workingCopy.commitBox
        guard Self.isBlank(box.message) else { return }
        do {
            let last = try await whileGitRuns { try await model.lastCommitMessage() }
            guard let message = last, box.isAmend, Self.isBlank(box.message) else {
                return
            }
            box.message = message
        } catch {
            let description = GitClientError.logDescription(of: error)
            Self.logger.error("Could not read the last commit message: \(description, privacy: .public)")
        }
    }

    // MARK: - Commits

    private func run(_ intent: GitCommitIntent, on commit: GitCommit) async {
        let mainline = commit.parents.count > 1 ? 1 : nil
        switch intent {
        case .checkout: await execute(.checkoutDetached(commit: commit.id))
        case .createBranch: await createBranch(at: commit.id, describedAs: commit.shortID)
        case .createTag: await createTag(at: commit)
        case .cherryPick: await execute(.cherryPick(commit: commit.id, mainline: mainline))
        case .revert: await execute(.revert(commit: commit.id, mainline: mainline))
        case .reset(let mode): await reset(to: commit, mode: mode)
        case .interactiveRebase: await interactiveRebase(onto: commit)
        }
    }

    /// Plans the rebase of the commits after `commit` onto it, every entry's message filled
    /// up front (one `git log` for the range) so switching one to reword needs no fetch,
    /// shows the editor, then runs the plan it answers; Cancel runs nothing. A plan git
    /// cannot build (a merge in the range) is shown as "Interactive rebase failed"; a stop
    /// partway (a conflict, an `edit`) is the banner's.
    private func interactiveRebase(onto commit: GitCommit) async {
        guard let presenter else { return }
        var plan: GitRebasePlan
        do {
            plan = try await whileGitRuns { try await model.rebasePlan(onto: commit.id) }
            let onto = plan.onto
            let messages = try await whileGitRuns { try await model.commitMessages(after: onto) }
            for index in plan.entries.indices {
                plan.entries[index].message = messages[plan.entries[index].commit]
            }
        } catch {
            showFailure(title: "Interactive rebase failed", error: error)
            return
        }
        guard let edited = await presenter.editRebase(plan) else { return }
        await execute(.interactiveRebase(edited))
    }

    /// Soft and mixed run at once; hard confirms first. On a detached HEAD it moves HEAD.
    private func reset(to commit: GitCommit, mode: GitResetMode) async {
        if mode == .hard {
            guard let presenter else { return }
            let branch = model.headBranch?.name ?? "HEAD"
            let confirmation = GitConfirmation(
                title: "Reset \(branch) to \(commit.shortID)?", message: "Uncommitted changes are lost.",
                actionTitle: "Reset", isDestructive: true)
            guard await presenter.confirm(confirmation) else { return }
        }
        await execute(.reset(commit: commit.id, mode: mode))
    }

    // MARK: - Reflog and Undo

    /// A reflog entry's reset (hard confirms first, as the history's does), detached
    /// checkout or new branch.
    private func run(_ intent: GitReflogIntent) async {
        switch intent {
        case let .reset(entry, mode):
            if mode == .hard {
                guard let presenter else { return }
                let branch = model.headBranch?.name ?? "HEAD"
                let confirmation = GitConfirmation(
                    title: "Reset \(branch) to \(entry.shortSha)?", message: "Uncommitted changes are lost.",
                    actionTitle: "Reset", isDestructive: true)
                guard await presenter.confirm(confirmation) else { return }
            }
            await execute(.reset(commit: entry.sha, mode: mode))
        case .checkout(let entry): await execute(.checkoutDetached(commit: entry.sha))
        case .createBranch(let entry): await createBranch(at: entry.sha, describedAs: entry.shortSha)
        }
    }

    /// A reset to the undo target that loses nothing (ruling R5): soft while anything is
    /// staged, so the index is kept and the undone changes join it, mixed otherwise, so they
    /// are left unstaged. It runs at once on a clean tree and confirms on a dirty one, saying
    /// which of the two it does. Nothing happens without an `undoTarget`.
    /// Undo re-reads the ref, its tip, its target and the tree from git before acting, and
    /// again after a confirmation: when any of them differs from what the window showed (or
    /// from what was confirmed), it refreshes instead of resetting.
    private func undoLastAction() async {
        let shown = model.undoState
        guard let shownTarget = model.undoTarget else { return }
        guard let fresh = await undoPreflight(matching: shown, target: shownTarget.sha) else { return }
        if fresh.isDirty {
            guard let presenter, let target = fresh.target else { return }
            guard await presenter.confirm(Self.undoConfirmation(fresh, target: target)) else { return }
            guard let confirmed = await undoPreflight(matching: shown, target: shownTarget.sha) else { return }
            guard confirmed == fresh else {
                await model.refresh([.refs, .workingCopy, .operation])
                return
            }
        }
        guard let target = fresh.target else { return }
        await execute(.reset(commit: target.sha, mode: fresh.resetMode))
    }

    /// A fresh `undoPreflight`, when its ref, tip and target are still the ones `shown` had;
    /// nil after showing a failure, or after refreshing because they moved.
    private func undoPreflight(matching shown: GitUndoState, target: String) async -> GitUndoPreflight? {
        let fresh: GitUndoPreflight
        do {
            fresh = try await model.undoPreflight()
        } catch {
            showFailure(title: "Undo failed", error: error)
            return nil
        }
        guard fresh.target?.sha == target, fresh.state.ref == shown.ref, fresh.state.tip == shown.tip else {
            await model.refresh([.refs, .workingCopy, .operation])
            return nil
        }
        return fresh
    }

    /// Titled after the step Undo takes back, and true about what the reset does to the
    /// index: a soft reset adds the undone changes to what is staged; a mixed one (nothing
    /// staged) leaves them unstaged.
    static func undoConfirmation(_ preflight: GitUndoPreflight, target: GitReflogEntry) -> GitConfirmation {
        let title: String
        if let undone = preflight.state.undoneEntry {
            title = undone.message.isEmpty ? "Undo \(undone.action)?" : "Undo \"\(undone.message)\"?"
        } else {
            let ref = preflight.state.ref
            title = "Undo the last change to \(ref.hasPrefix("refs/heads/") ? String(ref.dropFirst(11)) : ref)?"
        }
        let message = preflight.resetMode == .soft
            ? "HEAD moves to \(target.shortSha); the undone changes are staged with what is already staged."
            : "HEAD moves to \(target.shortSha); changes stay in the working copy."
        return GitConfirmation(title: title, message: message, actionTitle: "Undo", isDestructive: false)
    }

    private func createTag(at commit: GitCommit) async {
        let request = GitTextRequest(
            title: "New Tag", message: "At \(commit.shortID)",
            fields: [GitTextField(label: "Name", initial: "", isOptional: false),
                     GitTextField(label: "Message", initial: "", isOptional: true)],
            actionTitle: "Create Tag")
        guard let values = await askForName(request, failureTitle: "Create tag failed"), values.count == 2 else {
            return
        }
        let message = values[1].isEmpty ? nil : values[1]
        await execute(.createTag(name: values[0], commit: commit.id, message: message))
    }

    // MARK: - Refs

    private func run(_ intent: GitRefIntent) async {
        switch intent {
        case .checkout(let ref): await checkout(ref)
        case .createBranch(let ref): await createBranch(at: ref.fullName, describedAs: ref.name)
        case .rename(let ref): await rename(ref)
        case .delete(let ref): await delete(ref)
        case .push(let ref): await push(ref)
        case .pull: await execute(.pull)
        case .fetch(let remote):
            model.pullRequestList?.load(force: true)
            await execute(.fetch(remote: remote))
        case .deleteTag(let ref): await deleteTag(ref)
        case .pushTag(let ref): await pushTag(ref)
        case .applyStash(let stash):
            await run(on: stash, failureTitle: "Apply stash failed") { .stashApply(index: $0) }
        case .popStash(let stash):
            await run(on: stash, failureTitle: "Pop stash failed") { .stashPop(index: $0) }
        case .dropStash(let stash): await drop(stash)
        // The menu or the drop menu the user chose from is the confirmation.
        case .merge(let ref): await execute(.merge(ref: ref.fullName, fastForward: .allowed))
        case .rebaseOnto(let ref): await execute(.rebase(onto: ref.fullName))
        case .newWorktree(let branch): await newWorktree(branch: branch)
        case .removeWorktree(let worktree): await remove(worktree)
        case .updateSubmodule(let submodule):
            await execute(.updateSubmodules(paths: [submodule.path], initialize: submodule.state == .uninitialized))
        case .updateAllSubmodules: await execute(.updateSubmodules(paths: [], initialize: true))
        // The sidebar delegate opens it without the funnel; this is the same, should it arrive here.
        case .openDirectory(let directory): onOpenDirectory?(directory)
        }
    }

    // MARK: - Worktrees

    /// Asks for a branch and a folder, adds a worktree there and opens it in its own
    /// window. A branch that names a local branch is checked out; any other is created
    /// from HEAD. An empty folder is `<parent of root>/<root's name>-<branch>`.
    private func newWorktree(branch: GitRef?) async {
        let request = GitTextRequest(
            title: "New Worktree", message: "",
            fields: [GitTextField(label: "Branch", initial: branch?.name ?? "", isOptional: false),
                     GitTextField(label: "Folder", initial: "", isOptional: true)],
            actionTitle: "Create Worktree")
        guard let values = await askForName(request, failureTitle: "Add worktree failed") else { return }
        let name = values[0]
        let folder = Self.worktreeFolder(values.count > 1 ? values[1] : "", branch: name, root: model.root)
        let exists = model.refs.contains { $0.kind == .localBranch && $0.name == name }
        guard await execute(.addWorktree(path: folder.path, branch: name, createBranch: !exists, startPoint: nil))
        else { return }
        onOpenDirectory?(folder)
    }

    /// Where a new worktree for `branch` goes: `typed` with `~` expanded, taken against
    /// the parent of `root` when relative; when blank, `<parent>/<root's name>-<branch>`
    /// with every `/` in the branch made `-`.
    static func worktreeFolder(_ typed: String, branch: String, root: URL) -> URL {
        let parent = root.deletingLastPathComponent()
        let text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            let name = "\(root.lastPathComponent)-\(branch.replacingOccurrences(of: "/", with: "-"))"
            return parent.appendingPathComponent(name, isDirectory: true)
        }
        let expanded = (text as NSString).expandingTildeInPath
        guard !expanded.hasPrefix("/") else { return URL(fileURLWithPath: expanded, isDirectory: true) }
        return parent.appendingPathComponent(expanded, isDirectory: true).standardizedFileURL
    }

    /// Confirms, removes the worktree, and when git refuses a dirty one, confirms again
    /// and forces it.
    private func remove(_ worktree: GitWorktree) async {
        guard let presenter else { return }
        let path = worktree.directory.path
        // Spelled while the folder exists: a deleted folder's symlinks no longer resolve.
        let removed = worktree.directory.canonicalFileURL
        let confirmation = GitConfirmation(
            title: "Remove worktree \(worktree.directory.lastPathComponent)?",
            message: "Its folder, \(path), is deleted.", actionTitle: "Remove", isDestructive: true)
        guard await presenter.confirm(confirmation) else { return }
        let action = GitAction.removeWorktree(path: path, force: false)
        guard let error = await attempt(action) else {
            onRemoveDirectory?(removed)
            return
        }
        guard Self.isDirtyWorktree(error) else {
            showFailure(title: action.failureTitle, error: error)
            return
        }
        let again = GitConfirmation(
            title: "Remove worktree with uncommitted changes?",
            message: "Its uncommitted changes and untracked files are lost.", actionTitle: "Remove",
            isDestructive: true)
        guard await presenter.confirm(again) else { return }
        if await execute(.removeWorktree(path: path, force: true)) {
            onRemoveDirectory?(removed)
        }
    }

    // MARK: - Operation in progress

    /// Continues, skips or aborts the operation the model says is in progress; nothing
    /// when there is none. Abort confirms first. A failure shows git's message and leaves
    /// the operation, and so the banner, in place.
    private func runOperation(_ step: GitOperationStep) async {
        guard let kind = model.operationState.kind else { return }
        if step == .abort {
            guard let presenter else { return }
            let confirmation = GitConfirmation(
                title: "Abort the \(kind.verb)?",
                message: "The working tree and the branch go back to how they were before it started.",
                actionTitle: "Abort", isDestructive: true)
            guard await presenter.confirm(confirmation) else { return }
        }
        await execute(.operation(kind, step))
    }

    /// A local branch by name; a remote branch as the local branch that already tracks
    /// it, else as a new local branch tracking it; a tag as a detached HEAD.
    private func checkout(_ ref: GitRef) async {
        switch ref.kind {
        case .localBranch:
            await execute(.checkout(branch: ref.name))
        case .remoteBranch:
            if let local = model.refs.first(where: { $0.kind == .localBranch && $0.upstream == ref.name }) {
                await execute(.checkout(branch: local.name))
            } else {
                await execute(.checkoutTracking(remoteBranch: ref.name))
            }
        case .tag:
            await execute(.checkoutDetached(commit: ref.target))
        }
    }

    /// Asks for a name, then creates the branch at `startPoint` (HEAD when nil) and
    /// checks it out.
    private func createBranch(at startPoint: String?, describedAs description: String?) async {
        let request = GitTextRequest(
            title: "New Branch", message: description.map { "From \($0)" } ?? "",
            fields: [GitTextField(label: "Name", initial: "", isOptional: false)],
            actionTitle: "Create Branch")
        guard let name = await askForName(request, failureTitle: "Create branch failed")?.first else { return }
        await execute(.createBranch(name: name, startPoint: startPoint, checkout: true))
    }

    private func rename(_ ref: GitRef) async {
        let request = GitTextRequest(
            title: "Rename Branch", message: "",
            fields: [GitTextField(label: "Name", initial: ref.name, isOptional: false)],
            actionTitle: "Rename")
        guard let name = await askForName(request, failureTitle: "Rename branch failed")?.first,
              name != ref.name else { return }
        await execute(.renameBranch(from: ref.name, to: name))
    }

    /// A local branch: confirm, delete, and when git refuses an unmerged one, confirm
    /// again and force it. A remote branch: confirm, then delete it on its remote.
    private func delete(_ ref: GitRef) async {
        guard let presenter else { return }
        switch ref.kind {
        case .localBranch:
            let confirmation = GitConfirmation(
                title: "Delete branch \(ref.name)?", message: "", actionTitle: "Delete", isDestructive: true)
            guard await presenter.confirm(confirmation) else { return }
            let action = GitAction.deleteBranch(name: ref.name, force: false)
            guard let error = await attempt(action) else { return }
            guard Self.isNotFullyMerged(error) else {
                showFailure(title: action.failureTitle, error: error)
                return
            }
            let again = GitConfirmation(
                title: "Delete unmerged branch?",
                message: "\(ref.name) has commits no other branch holds. Deleting it loses them.",
                actionTitle: "Delete", isDestructive: true)
            guard await presenter.confirm(again) else { return }
            await execute(.deleteBranch(name: ref.name, force: true))
        case .remoteBranch:
            guard let remote = ref.remote else { return }
            let name = String(ref.name.dropFirst(remote.count + 1))
            let confirmation = GitConfirmation(
                title: "Delete \(ref.name)?", message: "The branch is deleted from \(remote).",
                actionTitle: "Delete", isDestructive: true)
            guard await presenter.confirm(confirmation) else { return }
            await execute(.deleteRemoteBranch(remote: remote, name: name))
        case .tag:
            await deleteTag(ref)
        }
    }

    private func deleteTag(_ ref: GitRef) async {
        guard let presenter else { return }
        let confirmation = GitConfirmation(
            title: "Delete tag \(ref.name)?", message: "", actionTitle: "Delete", isDestructive: true)
        guard await presenter.confirm(confirmation) else { return }
        await execute(.deleteTag(name: ref.name))
    }

    private func pushTag(_ ref: GitRef) async {
        guard let remote = await pushRemote(failureTitle: "Push tag failed") else { return }
        await execute(.pushTag(name: ref.name, remote: remote))
    }

    // MARK: - Push

    private func pushHead() async {
        guard let head = model.headBranch else {
            showFailure(title: "Push failed", message: "HEAD is not on a branch.")
            return
        }
        await push(head)
    }

    /// Pushes `branch` where git would. The checked-out branch with an upstream runs a
    /// plain `git push`, so `push.default`, `pushRemote` and `remote.pushDefault` decide,
    /// and a refusal is shown as git words it. Any other branch with an upstream goes to its
    /// `@{push}`, by refspec, tracking untouched; when git names no destination, nothing is
    /// pushed. Only a branch with no upstream is pushed under its own name, setting it.
    /// Call only from inside an action (`perform`), which holds `isActing`.
    func push(_ branch: GitRef) async {
        if branch.upstream != nil {
            if branch.fullName == model.headBranch?.fullName {
                await execute(.push)
            } else {
                await pushToDestination(branch)
            }
            return
        }
        guard let remotes = await listRemotes(failureTitle: "Push failed") else { return }
        guard let remote = pushRemote(among: remotes, failureTitle: "Push failed") else { return }
        await execute(.pushSettingUpstream(remote: remote, branch: branch.name))
    }

    /// Pushes a branch that is not checked out to its `@{push}`, or shows that it has none.
    private func pushToDestination(_ branch: GitRef) async {
        let destination: String
        do {
            destination = try await whileGitRuns { try await model.pushDestination(of: branch.name) }
        } catch {
            guard !(error is CancellationError) else { return }
            Self.logger.error("Push failed: \(GitClientError.logDescription(of: error), privacy: .public)")
            showFailure(
                title: "Push failed",
                message: "\(branch.name) has no push destination. \(GitClientError.userMessage(of: error))")
            return
        }
        guard let remotes = await listRemotes(failureTitle: "Push failed") else { return }
        guard let target = Self.split(destination, among: remotes) else {
            showFailure(title: "Push failed", message: "\(branch.name) has no push destination on a remote.")
            return
        }
        await execute(.pushToUpstream(remote: target.remote, branch: branch.name, upstreamBranch: target.branch))
    }

    private func pushRemote(failureTitle: String) async -> String? {
        guard let remotes = await listRemotes(failureTitle: failureTitle) else { return nil }
        return pushRemote(among: remotes, failureTitle: failureTitle)
    }

    /// The repository's remotes, or nil with the failure shown.
    private func listRemotes(failureTitle: String) async -> [String]? {
        do {
            return try await whileGitRuns { try await model.remotes() }
        } catch {
            showFailure(title: failureTitle, error: error)
            return nil
        }
    }

    /// `origin/feature` as (`origin`, `feature`), matching the longest remote name so a
    /// remote with a slash in its name splits right; nil when no remote is its prefix.
    static func split(_ upstream: String, among remotes: [String]) -> (remote: String, branch: String)? {
        let matches = remotes.filter { upstream.hasPrefix($0 + "/") && upstream.count > $0.count + 1 }
        guard let remote = matches.max(by: { $0.count < $1.count }) else { return nil }
        return (remote, String(upstream.dropFirst(remote.count + 1)))
    }

    /// The remote to push to: `origin`, else the only remote. With none to pick, the
    /// failure is shown and the answer is nil.
    private func pushRemote(among remotes: [String], failureTitle: String) -> String? {
        if remotes.contains("origin") { return "origin" }
        if remotes.count == 1 { return remotes[0] }
        showFailure(title: failureTitle, message: remotes.isEmpty
            ? "This repository has no remote."
            : "This repository has several remotes and none is named origin.")
        return nil
    }

    // MARK: - Stashes

    private func stashChanges() async {
        let request = GitTextRequest(
            title: "Stash Changes", message: "",
            fields: [GitTextField(label: "Message", initial: "", isOptional: true)],
            actionTitle: "Stash")
        guard let presenter, let values = await presenter.askForText(request) else { return }
        let message = values.first.flatMap { $0.isEmpty ? nil : $0 }
        await execute(.stashSave(message: message))
    }

    private func drop(_ stash: GitStash) async {
        guard let presenter else { return }
        let confirmation = GitConfirmation(
            title: "Drop stash@{\(stash.index)}?", message: stash.message, actionTitle: "Drop", isDestructive: true)
        guard await presenter.confirm(confirmation) else { return }
        await run(on: stash, failureTitle: "Drop stash failed") { .stashDrop(index: $0) }
    }

    /// Runs the action `make` builds for `stash`'s index as git numbers it now. The index
    /// the row was built with can name another entry by the time git runs (a stash pushed
    /// in a terminal while a sheet was up), so the stash is found again by its sha.
    private func run(on stash: GitStash, failureTitle: String, _ make: (Int) -> GitAction) async {
        let current: [GitStash]
        do {
            current = try await whileGitRuns { try await model.currentStashes() }
        } catch {
            showFailure(title: failureTitle, error: error)
            return
        }
        guard let index = Self.currentIndex(of: stash, in: current) else {
            showFailure(title: failureTitle, message: "That stash no longer exists.")
            return
        }
        await execute(make(index))
    }

    /// `stash`'s index in `stashes`, matched by sha; nil when it is no longer there.
    static func currentIndex(of stash: GitStash, in stashes: [GitStash]) -> Int? {
        stashes.first { $0.id == stash.id }?.index
    }

    // MARK: - Running git

    /// Runs `action` through the model; a failure is shown under its title. True on success.
    @discardableResult
    private func execute(_ action: GitAction) async -> Bool {
        guard let error = await attempt(action) else { return true }
        showFailure(title: action.failureTitle, error: error)
        return false
    }

    /// Runs `action` through the model, which refreshes either way; its error, or nil.
    private func attempt(_ action: GitAction) async -> Error? {
        if Task.isCancelled { return CancellationError() }
        do {
            try await whileGitRuns { try await model.perform(action) }
            return nil
        } catch {
            return error
        }
    }

    /// Asks `request` and returns its values, refusing a first value (a name) that
    /// begins with `-`, which git would read as an option. Nil without a presenter.
    private func askForName(_ request: GitTextRequest, failureTitle: String) async -> [String]? {
        guard let presenter, let values = await presenter.askForText(request), let name = values.first else {
            return nil
        }
        guard !name.isEmpty else { return nil }
        if name.hasPrefix("-") {
            showFailure(title: failureTitle, message: "A name cannot begin with “-”.")
            return nil
        }
        return values
    }

    private func showFailure(title: String, error: Error) {
        guard !(error is CancellationError), !Task.isCancelled else { return }
        let description = GitClientError.logDescription(of: error)
        Self.logger.error("\(title, privacy: .public): \(description, privacy: .public)")
        presenter?.showFailure(title: title, message: GitClientError.userMessage(of: error))
    }

    func showFailure(title: String, message: String) {
        guard !Task.isCancelled else { return }
        Self.logger.error("\(title, privacy: .public)")
        presenter?.showFailure(title: title, message: message)
    }

    /// Runs `body` with the overview's spinner on and `onBusyChange` told, then off again.
    func whileGitRuns<T>(_ body: () async throws -> T) async rethrows -> T {
        overviewPane.setBusy(true)
        onBusyChange?(true)
        defer {
            overviewPane.setBusy(false)
            onBusyChange?(false)
        }
        return try await body()
    }

    /// Whether git refused to delete a branch because its commits are on no other branch.
    static func isNotFullyMerged(_ error: Error) -> Bool {
        guard case let .commandFailed(_, _, standardError)? = error as? GitClientError else { return false }
        return standardError.contains("not fully merged")
    }

    /// Whether git refused to remove a worktree because it has changes or untracked files.
    static func isDirtyWorktree(_ error: Error) -> Bool {
        guard case let .commandFailed(_, _, standardError)? = error as? GitClientError else { return false }
        return standardError.contains("contains modified or untracked files")
    }

    private static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension GitAction {
    /// What a failure of this action is shown under.
    var failureTitle: String {
        switch self {
        case .stage, .stageAll: "Stage failed"
        case .unstage, .unstageAll: "Unstage failed"
        case .discard, .removeUntracked: "Discard failed"
        case .commit: "Commit failed"
        case .fetch: "Fetch failed"
        case .pull: "Pull failed"
        case .push, .pushSettingUpstream, .pushToUpstream: "Push failed"
        case .createBranch: "Create branch failed"
        case .checkout, .checkoutTracking, .checkoutDetached: "Checkout failed"
        case .renameBranch: "Rename branch failed"
        case .deleteBranch, .deleteRemoteBranch: "Delete branch failed"
        case .createTag: "Create tag failed"
        case .deleteTag: "Delete tag failed"
        case .pushTag: "Push tag failed"
        case .stashSave: "Stash failed"
        case .stashApply: "Apply stash failed"
        case .stashPop: "Pop stash failed"
        case .stashDrop: "Drop stash failed"
        case .cherryPick: "Cherry-pick failed"
        case .revert: "Revert failed"
        case .reset: "Reset failed"
        case .applyToIndex(_, let reverse): reverse ? "Unstage failed" : "Stage failed"
        case .applyToWorktree(_, let reverse): reverse ? "Discard failed" : "Apply failed"
        case .merge: "Merge failed"
        case .rebase: "Rebase failed"
        case let .operation(kind, step): "\(step.title) \(kind.verb) failed"
        case .resolve: "Resolve failed"
        case .removePaths: "Remove failed"
        case .interactiveRebase: "Rebase failed"
        case .addWorktree: "Add worktree failed"
        case .removeWorktree: "Remove worktree failed"
        case .updateSubmodules: "Update submodules failed"
        case .lfsFetch: "Fetch LFS objects failed"
        case .lfsPull: "Pull LFS objects failed"
        }
    }
}

private extension GitOperationStep {
    var title: String {
        switch self {
        case .continue: "Continue"
        case .abort: "Abort"
        case .skip: "Skip"
        }
    }
}
