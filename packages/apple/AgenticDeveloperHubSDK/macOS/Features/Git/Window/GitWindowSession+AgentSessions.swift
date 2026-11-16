import Foundation
import AgenticDeveloperHubSDKCore

/// Wires the agent sessions (recipe `workspace/git/git-window`, "Agent sessions") into
/// the commit detail and the refs sidebar. Without a provider nothing is wired, so the
/// detail's section and the branch menu's submenu stay absent. Read-only: the window
/// never writes to the provider.
extension GitWindowSession {
    /// The repository's root and every worktree's directory: the paths a session's
    /// working directory must lie under to belong to this repository.
    static func agentSessionRoots(_ model: GitRepositoryModel) -> [String] {
        [model.root.path] + model.worktrees.map(\.directory.path)
    }

    func configureAgentSessions() {
        guard let cache = agentSessionCache else { return }
        detail.agentSessionMatches = { [weak self, weak cache] commit in
            guard let self, let cache else { return [] }
            cache.refreshIfStale()
            return GitAgentSessionMatcher.sessions(
                cache.sessions, forCommitAt: commit.committer.date,
                branch: self.agentSessionBranch(for: commit), roots: Self.agentSessionRoots(self.model))
        }
        sidebar.agentSessionsOnBranch = { [weak self, weak cache] ref in
            guard let self, let cache else { return [] }
            cache.refreshIfStale()
            return GitAgentSessionMatcher.sessions(
                cache.sessions, onBranch: ref.name, roots: Self.agentSessionRoots(self.model))
        }
        cache.onChange = { [weak self] in self?.detail.reloadAgentSessions() }
        applyOpenAgentSession()
    }

    func applyOpenAgentSession() {
        detail.onOpenAgentSession = onOpenAgentSession
        sidebar.onOpenAgentSession = onOpenAgentSession
    }

    /// The local branch the commit is on: the first local branch pointing at it, else
    /// the selected ref when that is a local branch; nil when neither is known.
    private func agentSessionBranch(for commit: GitCommit) -> String? {
        if let ref = model.refs(at: commit.id).first(where: { $0.kind == .localBranch }) { return ref.name }
        guard case .ref(let fullName) = selection,
              let ref = model.refs.first(where: { $0.fullName == fullName }),
              ref.kind == .localBranch else { return nil }
        return ref.name
    }
}
