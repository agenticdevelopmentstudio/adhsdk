import Foundation

/// A per-commit value read lazily for the rows a list draws (recipe
/// `workspace/git/git-repository-model`, "Signatures"; ruling R1 makes it the one piece
/// the history's signatures and reviews share): asked for by sha, cached by sha for the
/// loader's life, and loaded in debounced, coalesced batches through `provider`, which
/// does its work off the main thread.
///
/// `request(_:)` queues the shas that are neither cached nor already loading and starts a
/// batch after `delay`. A new request replaces the queued one (ruling R6: what was visible
/// a moment ago no longer matters); a batch already running finishes and is cached.
/// `request(_:replacingQueued: false)` adds to the queue instead, for a single commit
/// asked for outside the list. A sha a successful batch did not answer is not asked for
/// again; a batch that throws is reported to `onFailure` and may be asked for again.
/// `onLoad` runs after each batch that cached anything. Used on the main thread.
@MainActor
public final class GitShaBatchLoader<Value: Sendable> {
    public typealias Provider = @Sendable ([String]) async throws -> [String: Value]

    /// How long a request waits before its batch starts: 150ms. Tests may shorten it.
    public var delay: Duration

    /// Every value loaded so far, by sha.
    public private(set) var values: [String: Value] = [:]

    /// How many batches have started; tests read it.
    private(set) var batchCount = 0
    /// The queued request's wait, then the batch it starts; tests await it.
    private(set) var queueTask: Task<Void, Never>?
    /// The batch running or last finished; tests await it.
    private(set) var loadTask: Task<Void, Never>?

    private let provider: Provider
    private let onLoad: @MainActor () -> Void
    private let onFailure: (@MainActor (Error) -> Void)?
    private var queued: [String] = []
    private var running: Set<String> = []
    private var unanswered: Set<String> = []

    public init(delay: Duration = .milliseconds(150), provider: @escaping Provider,
                onLoad: @escaping @MainActor () -> Void, onFailure: (@MainActor (Error) -> Void)? = nil) {
        self.delay = delay
        self.provider = provider
        self.onLoad = onLoad
        self.onFailure = onFailure
    }

    /// The cached value for `sha`; nil when it has not been loaded (yet).
    public func value(for sha: String) -> Value? {
        values[sha]
    }

    /// Queues `shas` for the next batch; see the type's description.
    public func request(_ shas: [String], replacingQueued: Bool = true) {
        var seen = Set<String>()
        let wanted = shas.filter { needsLoad($0) && seen.insert($0).inserted }
        if replacingQueued {
            queued = wanted
        } else {
            guard !wanted.isEmpty else { return }
            queued += wanted.filter { !queued.contains($0) }
        }
        queueTask?.cancel()
        queueTask = nil
        guard !queued.isEmpty else { return }
        let delay = delay
        queueTask = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            self?.startQueued()
        }
    }

    private func needsLoad(_ sha: String) -> Bool {
        values[sha] == nil && !running.contains(sha) && !unanswered.contains(sha)
    }

    private func startQueued() {
        let batch = queued.filter { needsLoad($0) }
        queued = []
        guard !batch.isEmpty else { return }
        running.formUnion(batch)
        batchCount += 1
        let provider = provider
        loadTask = Task { [weak self] in
            let result: Result<[String: Value], Error>
            do {
                result = .success(try await provider(batch))
            } catch {
                result = .failure(error)
            }
            self?.finish(batch, result)
        }
    }

    private func finish(_ batch: [String], _ result: Result<[String: Value], Error>) {
        running.subtract(batch)
        switch result {
        case .success(let loaded):
            var cachedAny = false
            for sha in batch {
                if let value = loaded[sha] {
                    values[sha] = value
                    cachedAny = true
                } else {
                    unanswered.insert(sha)
                }
            }
            if cachedAny { onLoad() }
        case .failure(let error):
            onFailure?(error)
        }
    }
}
