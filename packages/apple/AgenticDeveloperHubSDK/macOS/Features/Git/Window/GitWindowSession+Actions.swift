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
        /// The toolbar's verbs.
        case fetch, pull, push, newBranch, stash, popStash
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
        case .fetch: await execute(.fetch(remote: nil))
        case .pull: await execute(.pull)
        case .push: await pushHead()
        case .newBranch: await createBranch(at: nil, describedAs: nil)
        case .stash: await stashChanges()
        case .popStash:
            if !model.stashes.isEmpty { await execute(.stashPop(index: 0)) }
        }
    }

    // MARK: - Working copy

    private func run(_ intent: GitWorkingCopyIntent) async {
        switch intent {
        case .stage(let paths): await execute(.stage(paths: paths))
        case .unstage(let paths): await execute(.unstage(paths: paths))
        case .stageAll: await execute(.stageAll)
        case .unstageAll: await execute(.unstageAll)
        case .discard(let paths): await discard(paths)
        case .discardAll: await discard(model.unstaged.map(\.path))
        case let .commit(message, amend):
            if await execute(.commit(message: message, amend: amend)) { workingCopy.commitDidSucceed() }
        case .amendChanged(let amend):
            if amend { await fillAmendMessage() }
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
        }
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
        case .fetch(let remote): await execute(.fetch(remote: remote))
        case .deleteTag(let ref): await deleteTag(ref)
        case .pushTag(let ref): await pushTag(ref)
        case .applyStash(let stash):
            await run(on: stash, failureTitle: "Apply stash failed") { .stashApply(index: $0) }
        case .popStash(let stash):
            await run(on: stash, failureTitle: "Pop stash failed") { .stashPop(index: $0) }
        case .dropStash(let stash): await drop(stash)
        }
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
    private func push(_ branch: GitRef) async {
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
            presenter?.showFailure(
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

    private func showFailure(title: String, message: String) {
        guard !Task.isCancelled else { return }
        Self.logger.error("\(title, privacy: .public)")
        presenter?.showFailure(title: title, message: message)
    }

    /// Runs `body` with the overview's spinner on and `onBusyChange` told, then off again.
    private func whileGitRuns<T>(_ body: () async throws -> T) async rethrows -> T {
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
        }
    }
}
