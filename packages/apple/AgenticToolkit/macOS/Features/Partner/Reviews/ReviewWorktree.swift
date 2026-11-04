import Foundation
import AgenticToolkitCore

/// Keeps one review worktree per repo on a fix branch and brings it up to the branch tip before each review.
public struct ReviewWorktree: Sendable {

    public enum Outcome: Sendable, Equatable { case created, fastForwarded, reset, rebased, upToDate }

    public enum Failure: Error, LocalizedError, Equatable {
        /// The worktree has uncommitted or untracked changes; nothing was touched.
        case dirty
        /// Rebasing the fix branch onto the tip conflicted; the rebase was aborted. Carries git's stderr.
        case rebaseConflict(String)
        /// The directory is not a worktree of the repo (another repo's checkout, a plain folder, the main
        /// checkout), so no destructive verb was run in it. Carries the reason.
        case notReviewWorktree(String)
        /// Git refused to add or switch the worktree because a path or branch is already taken (the directory
        /// exists, the fix branch is checked out in another worktree). The owner's to clear. Carries git's stderr.
        case conflict(String)

        public var errorDescription: String? {
            switch self {
            case .dirty: return "the review worktree has uncommitted changes"
            case .rebaseConflict(let detail): return "rebasing the fix branch onto the tip conflicted: \(detail)"
            case .notReviewWorktree(let detail): return detail
            case .conflict(let detail): return "git refused the review worktree: \(detail)"
            }
        }
    }

    private let git: ReviewGit

    public init(git: ReviewGit = ReviewGit()) {
        self.git = git
    }

    /// Brings `worktree` (on `fixBranch`) up to the tip of `branch` in `repo`, creating it when needed.
    public func prepare(repo: URL, branch: String, fixBranch: String, worktree: URL) async throws -> Outcome {
        guard let tip = try await git.resolveCommit("refs/heads/\(branch)", in: repo) else {
            throw GitClientError.commandFailed(verb: "resolve", exitStatus: 1,
                                               standardError: "no branch named \(branch)")
        }

        guard try await git.resolveCommit("refs/heads/\(fixBranch)", in: repo) != nil else {
            try await Self.refusingConflicts {
                _ = try await git.run(["worktree", "add", "-b", fixBranch, worktree.path, tip], in: repo)
            }
            return .created
        }

        if !FileManager.default.fileExists(atPath: worktree.path) {
            // Drop only our own stale registration: a repo-wide `worktree prune` would also drop the owner's
            // worktrees whose directories are merely absent (an unmounted volume), along with their locks.
            let missing = Self.canonical(worktree)
            if try await git.worktrees(in: repo).contains(where: { Self.canonical($0.directory) == missing }) {
                _ = try await git.run(["worktree", "remove", "--force", worktree.path], in: repo)
            }
            try await Self.refusingConflicts {
                _ = try await git.run(["worktree", "add", worktree.path, fixBranch], in: repo)
            }
        }

        // Observe the worktree before running anything destructive in it.
        let wanted = Self.canonical(worktree)
        guard let entry = try await git.worktrees(in: repo)
            .first(where: { !$0.isMain && !$0.isBare && Self.canonical($0.directory) == wanted }) else {
            throw Failure.notReviewWorktree("\(worktree.path) is not a worktree of \(repo.path)")
        }

        // A rebase an earlier start was cut off in (the process killed, the abort never ran) would otherwise
        // read as dirty, or fail the switch below, on every review until someone aborted it by hand.
        if try await git.isRebasing(worktree: worktree) { try await abortRebase(in: worktree) }

        guard try await git.isClean(worktree: worktree) else { throw Failure.dirty }

        if entry.branch != fixBranch {
            // Detached, or on a branch of the session's own making: put it back on the fix branch first, so
            // the reset and rebase below move the branch and not whatever HEAD happened to be.
            try await Self.refusingConflicts { _ = try await git.run(["switch", fixBranch], in: worktree) }
        }

        guard let fix = try await git.resolveCommit("refs/heads/\(fixBranch)", in: repo) else {
            throw Failure.notReviewWorktree("branch \(fixBranch) disappeared from \(repo.path)")
        }
        if fix == tip { return .upToDate }

        if try await git.isAncestor(fix, of: tip, in: repo) {
            // The fix branch has nothing the tip lacks. It either sits on the tip's own line of history (the
            // tip simply moved on) or arrived through a merge: walking the tip's first parents down to fix
            // ends exactly on fix only in the first case.
            let walk = try await git.run(["rev-list", "--first-parent", "--parents", "\(fix)..\(tip)"], in: repo)
            let oldest = walk.split(separator: "\n").last?.split(separator: " ").dropFirst().first
            _ = try await git.run(["reset", "--hard", tip], in: worktree)
            return oldest.map(String.init) == fix ? .fastForwarded : .reset
        }

        do {
            _ = try await git.run(["rebase", tip, fixBranch], in: worktree)
        } catch {
            // Whatever stopped the rebase (a conflict, a timeout, cancellation), never leave it half done. The
            // abort's own failure must not replace the rebase's error: that error is what the owner needs to read.
            var abortError: Error?
            do { try await abortRebase(in: worktree) } catch { abortError = error }
            // A cancelled start kills git mid-rebase, which reads as a failed rebase, not a conflict.
            if Task.isCancelled && abortError == nil { throw CancellationError() }
            throw Self.rebaseFailure(error, abortError: abortError)
        }
        return .rebased
    }

    /// What git says when a worktree path or branch is already taken: conditions the owner clears, not failures.
    static let conflictMarkers = ["already exists", "already checked out", "is already used by worktree"]

    /// Runs `body`, turning a git refusal that names a taken path or branch into ``Failure/conflict(_:)``.
    static func refusingConflicts(_ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch GitClientError.commandFailed(_, _, let standardError)
                    where conflictMarkers.contains(where: { standardError.contains($0) }) {
            throw Failure.conflict(standardError.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /// `rebase --abort` on an unstructured task, so it still runs when the caller has been cancelled: the
    /// cancellation that interrupted the rebase would otherwise kill its cleanup too.
    private func abortRebase(in worktree: URL) async throws {
        let git = git
        try await Task { _ = try await git.run(["rebase", "--abort"], in: worktree) }.value
    }

    /// The error a failed rebase is reported with: a git failure becomes ``Failure/rebaseConflict(_:)``
    /// with its stderr, and an abort that also failed is appended as "(abort failed: …)", so the worktree
    /// left mid-rebase is named. Anything else is passed on unless the abort failed too.
    static func rebaseFailure(_ error: Error, abortError: Error?) -> Error {
        let abortNote = abortError.map { abort -> String in
            var detail = abort.localizedDescription
            if case GitClientError.commandFailed(_, _, let standardError) = abort,
               !standardError.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detail = standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return " (abort failed: \(detail))"
        }
        if case GitClientError.commandFailed(_, _, let standardError) = error {
            return Failure.rebaseConflict(standardError + (abortNote ?? ""))
        }
        guard let abortNote else { return error }
        return Failure.rebaseConflict(error.localizedDescription + abortNote)
    }

    /// Standardized with symlinks resolved, so `/var/...` and `/private/var/...` compare equal. A missing path
    /// resolves through its nearest existing ancestor, since symlinks resolve only in paths that exist.
    private static func canonical(_ url: URL) -> String {
        let standardized = url.standardizedFileURL
        guard !FileManager.default.fileExists(atPath: standardized.path) else {
            return standardized.resolvingSymlinksInPath().path
        }
        let parent = standardized.deletingLastPathComponent()
        guard parent.path != standardized.path else { return standardized.path }
        return URL(fileURLWithPath: canonical(parent)).appendingPathComponent(standardized.lastPathComponent).path
    }
}
