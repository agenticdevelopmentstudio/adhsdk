import Foundation

/// The decisions behind a notation's life, kept free of git and the store so
/// they can be tested on facts alone. `NotationsReconciler` gathers the facts.
public enum NotationLifecycle {

    /// What a reconcile knows about an active notation's branch.
    public struct ArchiveFacts: Sendable, Equatable {
        /// The commit `refs/heads/<branch>` names; `nil` when the local ref is gone.
        public var localTip: String?
        /// The fork point the notation was keyed by.
        public var forkPoint: String
        /// Whether `localTip` is reachable from the default branch
        /// (`merge-base --is-ancestor <tip> <default>`).
        public var tipReachableFromDefault: Bool
        /// Whether the branch is the default branch itself, which is always
        /// reachable from itself and is never "merged".
        public var isDefaultBranch: Bool

        public init(localTip: String?, forkPoint: String, tipReachableFromDefault: Bool, isDefaultBranch: Bool) {
            self.localTip = localTip
            self.forkPoint = forkPoint
            self.tipReachableFromDefault = tipReachableFromDefault
            self.isDefaultBranch = isDefaultBranch
        }
    }

    /// Archive when the local ref is gone, or when the branch has commits of
    /// its own (tip ≠ fork point) that the default branch now contains. A
    /// branch with no commits yet that still exists stays active.
    public static func shouldArchive(_ facts: ArchiveFacts) -> Bool {
        guard let tip = facts.localTip else { return true }
        if facts.isDefaultBranch { return false }
        return tip != facts.forkPoint && facts.tipReachableFromDefault
    }

    /// What a reconcile knows about an archived notation's branch.
    public struct DeleteFacts: Sendable, Equatable {
        /// Whether the project's directory still exists. A project whose
        /// directory is gone counts as having no refs.
        public var directoryExists: Bool
        /// Whether a local `refs/heads/<branch>` exists whose merge-base with
        /// the default branch is the notation's fork point.
        public var matchingLocalRefExists: Bool
        /// Whether `git ls-remote --heads origin <branch>` lists the branch;
        /// `nil` when it could not be asked (no network, no origin), which
        /// keeps the notation.
        public var remoteHeadExists: Bool?

        public init(directoryExists: Bool, matchingLocalRefExists: Bool, remoteHeadExists: Bool?) {
            self.directoryExists = directoryExists
            self.matchingLocalRefExists = matchingLocalRefExists
            self.remoteHeadExists = remoteHeadExists
        }

        /// No ref with the notation's name and fork point exists anywhere.
        public var noRefRemains: Bool {
            guard directoryExists else { return true }
            return !matchingLocalRefExists && remoteHeadExists == false
        }
    }

    /// Whether an archived notation has been archived longer than the
    /// retention setting allows.
    public static func isPastRetention(archivedAt: Date?, now: Date, retentionDays: Int) -> Bool {
        guard let archivedAt else { return false }
        let days = max(1, retentionDays)
        return now.timeIntervalSince(archivedAt) > TimeInterval(days) * 86_400
    }

    /// Delete only when both hold: archived past retention, and no ref with
    /// its name and fork point remains.
    public static func shouldDelete(archivedAt: Date?, now: Date, retentionDays: Int, facts: DeleteFacts) -> Bool {
        isPastRetention(archivedAt: archivedAt, now: now, retentionDays: retentionDays) && facts.noRefRemains
    }

    /// Which of a branch's active notations belongs to it now: the one keyed
    /// by its current fork point, else the newest whose fork point is still
    /// an ancestor of the tip (a rebased branch, or the default branch whose
    /// "fork point" moves with every commit). `nil` means the first edit
    /// creates a notation at `currentForkPoint`.
    public static func resolve(
        candidates: [Notation],
        currentForkPoint: String,
        isAncestorOfTip: (String) -> Bool
    ) -> Notation? {
        let active = candidates.filter { $0.state == .active }
        if let exact = active.first(where: { $0.forkPoint == currentForkPoint }) { return exact }
        return active.sorted { $0.createdAt > $1.createdAt }.first { isAncestorOfTip($0.forkPoint) }
    }
}
