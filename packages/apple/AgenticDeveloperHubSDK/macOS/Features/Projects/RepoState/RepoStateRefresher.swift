import Foundation
import os
import AgenticDeveloperHubSDKCore

/// Reads repositories' state from disk and keeps the cache in step.
///
/// One refresh per repository at a time: a refresh asked for while one is in
/// flight waits for it and then runs once more, so a burst of file events
/// costs at most two reads, and the last one sees the final state.
@MainActor
public final class RepoStateRefresher {

    /// A repository's cached state changed; carries the new snapshot.
    public var onChange: ((UUID, RepoStateSnapshot) -> Void)?

    private let store: RepoStateStore
    private let reader: RepoStateReading
    private var inFlight: [UUID: Task<RepoStateSnapshot?, Never>] = [:]
    private var rerunRequested: Set<UUID> = []
    /// What `sweep` has still to read; emptied to stop it.
    private var sweepQueue: ArraySlice<(id: UUID, directory: URL)> = []

    public init(store: RepoStateStore, reader: RepoStateReading = GitRepoStateReader()) {
        self.store = store
        self.reader = reader
    }

    public func cachedState(forRepo repoID: UUID) -> RepoStateSnapshot? {
        store.cachedRepoState(forRepo: repoID)
    }

    /// Reads `repo` now and caches the answer when it differs. Returns the
    /// fresh snapshot, or `nil` when git could not be read (the cache is then
    /// left as it was).
    @discardableResult
    public func refresh(_ repoID: UUID, at directory: URL) async -> RepoStateSnapshot? {
        if let running = inFlight[repoID] {
            rerunRequested.insert(repoID)
            _ = await running.value
            // Whoever finds the rerun request first runs it; the rest wait on it.
            guard rerunRequested.remove(repoID) != nil else {
                return await inFlight[repoID]?.value ?? cachedState(forRepo: repoID)
            }
        }
        let task = Task { await self.read(repoID, at: directory) }
        inFlight[repoID] = task
        let result = await task.value
        if inFlight[repoID] == task { inFlight[repoID] = nil }
        return result
    }

    /// Refreshes every repository, at most `maxConcurrent` at once, in the
    /// order given — most recently opened first, so the projects likeliest to
    /// be switched to are warm soonest.
    public func sweep(_ repos: [(id: UUID, directory: URL)], maxConcurrent: Int = 4) async {
        sweepQueue = repos[...]
        let workers = (0..<max(1, maxConcurrent)).map { _ in
            Task { @MainActor in
                while let next = self.sweepQueue.popFirst() {
                    _ = await self.refresh(next.id, at: next.directory)
                }
            }
        }
        await withTaskCancellationHandler {
            for worker in workers { await worker.value }
        } onCancel: {
            Task { @MainActor in self.sweepQueue = [] }
        }
    }

    private func read(_ repoID: UUID, at directory: URL) async -> RepoStateSnapshot? {
        let fresh: RepoStateSnapshot
        do {
            fresh = try await reader.readState(at: directory)
        } catch {
            Self.logger.info("repo state read failed for \(directory.path, privacy: .public)")
            return nil
        }
        if let old = store.cachedRepoState(forRepo: repoID), old.hasSameState(as: fresh) { return fresh }
        store.saveRepoState(fresh, forRepo: repoID)
        onChange?(repoID, fresh)
        return fresh
    }
}

extension RepoStateRefresher: Loggable {
    public static nonisolated let logger = makeLogger()
}
