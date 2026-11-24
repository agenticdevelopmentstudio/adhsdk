import os
import Foundation
import AgenticDeveloperHubSDKCore

/// Brings `Notations.db` in line with the branches on disk: archives the
/// notations whose branch is gone or merged, records each live branch's tip,
/// and deletes archived notations past retention whose branch is gone
/// everywhere. Runs off the main thread; every git question goes through
/// `NotationsGit`.
///
/// A git failure on one notation skips that notation, never the pass: a
/// project mid-rebase or a slow remote must not stall the rest.
public actor NotationsReconciler {

    public struct Summary: Sendable, Equatable {
        public var archived = 0
        public var deleted = 0
        public var skipped = 0
    }

    private let store: NotationsStore
    private let git: NotationsGit
    private let fileExists: @Sendable (String) -> Bool
    private var isRunning = false

    public init(
        store: NotationsStore,
        git: NotationsGit = NotationsGit(),
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.store = store
        self.git = git
        self.fileExists = fileExists
    }

    /// One pass. `projectID` limits it to one project (a Coding Project
    /// window became key); `nil` covers every notation. A pass that arrives
    /// while one is running is dropped: the running one covers it.
    @discardableResult
    public func reconcile(retentionDays: Int, projectID: UUID? = nil, now: Date = Date()) async -> Summary {
        guard !isRunning else { return Summary() }
        isRunning = true
        defer { isRunning = false }

        var summary = Summary()
        let notations: [Notation]
        do {
            notations = try store.all().filter { projectID == nil || $0.projectID == projectID }
        } catch {
            Self.logger.error("Notations reconcile could not read the store: \(error.localizedDescription)")
            return summary
        }

        var defaultBranches: [String: String?] = [:]
        for notation in notations {
            if Task.isCancelled { break }
            let directory = URL(fileURLWithPath: notation.projectPath)
            // A missing directory is not a definite no: the project may have
            // been moved or renamed (its id survives, its stored path does
            // not), or sit on a volume that is not mounted. Nothing is
            // archived or deleted on that evidence alone.
            guard fileExists(notation.projectPath) else {
                summary.skipped += 1
                continue
            }
            let directoryExists = true
            do {
                switch notation.state {
                case .active:
                    if try await reconcileActive(notation, in: directory, directoryExists: directoryExists,
                                                 defaultBranches: &defaultBranches, now: now) {
                        summary.archived += 1
                    }
                case .archived:
                    guard NotationLifecycle.isPastRetention(
                        archivedAt: notation.archivedAt, now: now, retentionDays: retentionDays) else { continue }
                    let facts = await deleteFacts(for: notation, in: directory, directoryExists: directoryExists,
                                                  defaultBranches: &defaultBranches)
                    if NotationLifecycle.shouldDelete(archivedAt: notation.archivedAt, now: now,
                                                      retentionDays: retentionDays, facts: facts),
                       try store.deleteArchived(id: notation.id) {
                        summary.deleted += 1
                    }
                }
            } catch {
                summary.skipped += 1
                Self.logger.debug(
                    "Notations reconcile skipped \(notation.id.uuidString): \(error.localizedDescription)")
            }
        }
        return summary
    }

    /// True when the notation was archived.
    private func reconcileActive(
        _ notation: Notation,
        in directory: URL,
        directoryExists: Bool,
        defaultBranches: inout [String: String?],
        now: Date
    ) async throws -> Bool {
        guard directoryExists else {
            return try store.archive(id: notation.id, at: now)
        }
        let tip = try await git.tip(of: notation.branch, in: directory)
        guard let tip else {
            return try store.archive(id: notation.id, at: now)
        }
        let hasHadOwnCommits = notation.lastTip.map { $0 != notation.forkPoint } ?? false
        guard let defaultBranch = try await defaultBranch(for: notation.projectPath, in: directory,
                                                          cache: &defaultBranches) else {
            if tip != notation.lastTip { try store.recordTip(id: notation.id, tip: tip) }
            return false
        }
        let isDefault = notation.branch == defaultBranch
        let reachable = isDefault
            ? true
            : try await git.isAncestor(tip, of: "refs/heads/\(defaultBranch)", in: directory)
        let facts = NotationLifecycle.ArchiveFacts(
            localTip: tip, forkPoint: notation.forkPoint,
            tipReachableFromDefault: reachable, isDefaultBranch: isDefault,
            hasHadOwnCommits: hasHadOwnCommits)
        // The recorded tip is the branch's last commit of its own; an empty
        // branch carried along the default branch has none to record.
        if tip != notation.lastTip, !facts.isEmptyBranchMovedAlongDefault {
            try store.recordTip(id: notation.id, tip: tip)
        }
        guard NotationLifecycle.shouldArchive(facts) else { return false }
        return try store.archive(id: notation.id, at: now)
    }

    private func deleteFacts(
        for notation: Notation,
        in directory: URL,
        directoryExists: Bool,
        defaultBranches: inout [String: String?]
    ) async -> NotationLifecycle.DeleteFacts {
        guard directoryExists else {
            return .init(directoryExists: false, matchingLocalRefExists: false, remoteHeadExists: false)
        }
        // Anything git cannot answer counts as "the ref may still be there":
        // a notation is only ever deleted on a definite no.
        let matchingLocal: Bool
        do {
            if try await git.tip(of: notation.branch, in: directory) == nil {
                matchingLocal = false
            } else if let defaultBranch = try await defaultBranch(for: notation.projectPath, in: directory,
                                                                  cache: &defaultBranches) {
                let forkPoint = try await git.forkPoint(of: notation.branch, defaultBranch: defaultBranch,
                                                        in: directory)
                matchingLocal = forkPoint == notation.forkPoint
            } else {
                matchingLocal = true
            }
        } catch {
            matchingLocal = true
        }
        guard !matchingLocal else {
            return .init(directoryExists: true, matchingLocalRefExists: true, remoteHeadExists: nil)
        }
        let remote = await git.remoteHeadExists(notation.branch, in: directory)
        return .init(directoryExists: true, matchingLocalRefExists: false, remoteHeadExists: remote)
    }

    /// The project's default branch, asked once per pass; `nil` when it has
    /// none git can name.
    private func defaultBranch(
        for projectPath: String,
        in directory: URL,
        cache: inout [String: String?]
    ) async throws -> String? {
        if let cached = cache[projectPath] { return cached }
        let resolved: String?
        do {
            resolved = try await git.defaultBranch(in: directory)
        } catch GitClientError.commandFailed {
            resolved = nil
        }
        cache[projectPath] = resolved
        return resolved
    }
}

extension NotationsReconciler: Loggable {
    public static nonisolated let logger = makeLogger()
}
