import Foundation
import AgenticDeveloperHubSDKCore

/// One Git window's copy of the agent sessions under its repository (recipe
/// `workspace/git/git-window`, "Agent sessions"): read from the provider once when the
/// window opens, then again at most every `refreshInterval` when the detail changes,
/// covering the last `window`. Never writes to the provider. Used on the main thread.
@MainActor
final class GitAgentSessionCache {
    /// How far back a read reaches: 90 days.
    static let window: TimeInterval = 90 * 24 * 3600
    /// The least time between two reads.
    static let refreshInterval: TimeInterval = 60

    /// The sessions the last read returned.
    private(set) var sessions: [GitAgentSession] = []
    /// The read in flight or last finished; tests await it.
    private(set) var fetchTask: Task<Void, Never>?
    /// Called on the main thread after every read lands.
    var onChange: (() -> Void)?

    private let provider: any GitSessionsProviding
    private let roots: () -> [String]
    private let now: () -> Date
    /// When the last read started; nil before the first.
    private var fetchedAt: Date?
    private var isFetching = false

    /// - Parameters:
    ///   - roots: the repository's root and every worktree's path, read at each fetch.
    ///   - now: the clock; tests replace it.
    init(provider: any GitSessionsProviding, roots: @escaping () -> [String],
         now: @escaping () -> Date = { Date() }) {
        self.provider = provider
        self.roots = roots
        self.now = now
    }

    /// Drops a read in flight: its answer is never stored or reported. Later calls to
    /// `refreshIfStale()` read again as usual; the window that owns the cache has closed.
    func stop() {
        fetchTask?.cancel()
        onChange = nil
    }

    /// Reads the sessions again unless a read is in flight or one started less than
    /// `refreshInterval` ago.
    func refreshIfStale() {
        let now = now()
        guard !isFetching else { return }
        if let fetchedAt, now.timeIntervalSince(fetchedAt) < Self.refreshInterval { return }
        fetchedAt = now
        isFetching = true
        let roots = roots()
        let since = now.addingTimeInterval(-Self.window)
        let provider = provider
        fetchTask = Task { [weak self] in
            let found = await provider.sessions(under: roots, since: since)
            guard let self else { return }
            self.isFetching = false
            guard !Task.isCancelled, found != self.sessions else { return }
            self.sessions = found
            self.onChange?()
        }
    }
}
