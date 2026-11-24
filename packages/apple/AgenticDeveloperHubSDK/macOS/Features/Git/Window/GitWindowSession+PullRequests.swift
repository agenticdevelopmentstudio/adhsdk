import AppKit
import AgenticDeveloperHubSDKCore

extension GitWindowSession.Selection {
    /// Whether a pull request is what the centre pane shows.
    var isPullRequest: Bool {
        if case .pullRequest = self { return true }
        return false
    }
}

/// The session's half of the Pull Requests section (recipe `workspace/git/git-views`,
/// "Pull requests"): it hands the list to the repository model, answers the sidebar's
/// and the detail's intents, and runs checkout and create. Failures show as "Pull
/// request failed" (Ruling R3), never through a `GitAction`.
extension GitWindowSession {

    static let pullRequestFailureTitle = "Pull request failed"
    static let branchChangedMessage = "The checked-out branch changed while the form was open."

    /// Turns the Pull Requests section on with `list`. Without it, `pullRequests` stays
    /// nil and the section is absent. The first load starts here only when the refs are
    /// already read; otherwise the model's first refs change starts it, so a window open
    /// loads once.
    public func configurePullRequests(_ list: GitPullRequestsModel) {
        model.pullRequestList = list
        list.onChange = { [weak self] in self?.pullRequestsDidChange() }
        pullRequestView.onIntent = { [weak self] intent in self?.requestPullRequest(intent) }
        if list.canLoad { list.load(force: true) }
    }

    /// The sidebar shows the new list, and the detail the selected pull request's new
    /// state; a selected pull request the list no longer has (merged or closed elsewhere)
    /// empties the detail, so it never offers Check Out on a stale "Open".
    private func pullRequestsDidChange() {
        sidebar.reload()
        guard case .pullRequest(let number) = selection else { return }
        pullRequestView.checkedOutBranch = model.headBranch?.name
        pullRequestView.show(model.pullRequests?.first(where: { $0.number == number }))
    }

    /// Opening in the browser runs no git and no `gh`; checkout and create are actions.
    func requestPullRequest(_ intent: GitPullRequestIntent) {
        switch intent {
        case .show(let pullRequest):
            // The row's selection shows it, through the sidebar's delegate.
            sidebar.select(pullRequestNumber: pullRequest.number)
        case .openInBrowser(let pullRequest):
            model.pullRequestList?.openInBrowser(pullRequest.url)
        case .checkout, .create:
            perform(.pullRequest(intent))
        }
    }

    func runPullRequest(_ intent: GitPullRequestIntent) async {
        guard let list = model.pullRequestList else { return }
        switch intent {
        case .checkout(let pullRequest): await checkoutPullRequest(pullRequest.number, list: list)
        case .create: await createPullRequest(list: list)
        case .show, .openInBrowser: requestPullRequest(intent)
        }
    }

    /// `gh pr checkout <number>`, then the refs and the working copy read again, refused
    /// or not; a dirty tree's refusal is shown in git's words.
    private func checkoutPullRequest(_ number: Int, list: GitPullRequestsModel) async {
        do {
            try await whileGitRuns { try await list.checkout(number) }
        } catch {
            showPullRequestFailure(error)
        }
        // The checked-out branch changing makes the list load again (`refsDidChange`).
        await model.refresh([.refs, .workingCopy])
    }

    /// The form, filled from the branch's commits; a push first when the branch has no
    /// upstream or is ahead of it; then `gh pr create`, a reload, and the new pull
    /// request selected.
    private func createPullRequest(list: GitPullRequestsModel) async {
        guard let presenter else { return }
        guard let head = model.headBranch else {
            showFailure(title: Self.pullRequestFailureTitle, message: "HEAD is not on a branch.")
            return
        }
        let remote = pullRequestRemote()
        let defaultBranch = await list.defaultBranch(remote: remote)
        let bases = pullRequestBases(remote: remote, defaultBranch: defaultBranch, excluding: head.name)
        let subjects: [String]
        do {
            let base = remote.flatMap { remote in bases.first.map { "\(remote)/\($0)" } }
            subjects = try await list.branchSubjects(notOn: base)
        } catch {
            showPullRequestFailure(error)
            return
        }
        let title = subjects.last ?? head.name
        let body = subjects.reversed().map { "- \($0)" }.joined(separator: "\n")
        guard let draft = await presenter.createPullRequest(
            head: head.name, defaultTitle: title, defaultBody: body, bases: bases) else { return }

        // The form waits on the user, so the branch is read again: a pull request is only
        // ever opened from the branch the form was filled from.
        await model.refresh([.refs])
        guard let fresh = model.headBranch, fresh.name == head.name else {
            showFailure(title: Self.pullRequestFailureTitle, message: Self.branchChangedMessage)
            return
        }
        if fresh.upstream == nil || fresh.ahead > 0 {
            await push(fresh)
            guard let pushed = model.headBranch, pushed.name == head.name,
                  pushed.upstream != nil, pushed.ahead == 0 else { return }
        }
        let url: URL
        do {
            url = try await whileGitRuns { try await list.create(draft) }
        } catch {
            showPullRequestFailure(error)
            return
        }
        await list.reload()
        sidebar.reload()
        if let number = Int(url.lastPathComponent) {
            sidebar.select(pullRequestNumber: number)
        }
    }

    /// The push remote: `origin` when it has branches, else the first remote that does.
    func pullRequestRemote() -> String? {
        let remotes = model.refs.filter { $0.kind == .remoteBranch }.compactMap(\.remote)
        return remotes.contains("origin") ? "origin" : remotes.first
    }

    /// The bases the form offers: the repository's default branch first, then the push
    /// remote's other branches without the remote's name, `head` left out. With the
    /// default branch unknown there are none, so the popup is off and `gh` picks the
    /// base itself — no branch is guessed to be the default.
    func pullRequestBases(remote: String?, defaultBranch: String?, excluding head: String) -> [String] {
        guard let defaultBranch, defaultBranch != head else { return [] }
        guard let remote else { return [defaultBranch] }
        let names = model.refs
            .filter { $0.kind == .remoteBranch && $0.remote == remote }
            .map { String($0.name.dropFirst(remote.count + 1)) }
            .filter { $0 != head && $0 != "HEAD" && $0 != defaultBranch }
        return [defaultBranch] + names
    }

    private func showPullRequestFailure(_ error: Error) {
        guard !(error is CancellationError), !Task.isCancelled else { return }
        showFailure(title: Self.pullRequestFailureTitle, message: Self.pullRequestMessage(for: error))
    }

    static func pullRequestMessage(for error: Error) -> String {
        switch error as? GitHubCLIError {
        case .timedOut: return "gh did not answer in time."
        case .failed(let message): return message
        case .notInstalled: return "gh is not installed."
        case .notAuthenticated: return "gh is not logged in."
        case .notGitHub: return "This repository has no GitHub remote."
        case nil: return GitClientError.userMessage(of: error)
        }
    }
}
