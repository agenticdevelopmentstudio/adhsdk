import Foundation

/// A per-commit value read lazily for the rows a list draws (recipe
/// `workspace/git/git-repository-model`, "Signatures"; ruling R1 makes it the one piece
/// the history's signatures and reviews share): asked for by sha, cached by sha for the
/// loader's life, and loaded in debounced, coalesced batches through `provider`, which
/// does its work off the main thread.
///
/// `request(_:)` queues the shas that are neither cached nor already loading and starts a
/// batch after `delay`. A new request replaces the queued one (ruling R6: what was visible
/// a moment ago no longer matters); a batch already running finishes and is cached. One
/// batch runs at a time: a batch due while another runs waits for it to land, then starts
/// with whatever is queued by then, so stepped scrolling never runs several `git log`s.
/// `request(_:replacingQueued: false)` is for a single commit asked for outside the list:
/// it is kept apart from the list's queue, so no replacement drops it, and joins the next
/// batch. A sha a successful batch did not answer is not asked for again. A batch that
/// throws is reported to `onFailure`, and its shas are not asked for again until
/// `failureCooldown` has passed, so a verifier that keeps timing out is not re-run on every
/// scroll. `onLoad` runs after each batch that changed the cache: a new value, a value that
/// differs from the cached one, or (after `invalidate()`) a removal. A re-answer equal to the
/// cached value is not a change. Used on the main thread.
@MainActor
public final class GitShaBatchLoader<Value: Sendable & Equatable> {
    public typealias Provider = @Sendable ([String]) async throws -> [String: Value]

    /// How long a request waits before its batch starts: 150ms. Tests may shorten it.
    public var delay: Duration
    /// How long the shas of a failed batch are left alone before a request may ask for them
    /// again: one minute. Tests may change it.
    public var failureCooldown: Duration = .seconds(60)

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
    /// The list's queued shas, replaced by each replacing request.
    private var queued: [String] = []
    /// Single shas asked for outside the list (`replacingQueued: false`); no replacement
    /// drops them, and they join the next batch.
    private var kept: [String] = []
    /// When each sha's last batch failed, for `failureCooldown`.
    private var failedAt: [String: ContinuousClock.Instant] = [:]
    private var running: Set<String> = []
    private var unanswered: Set<String> = []
    /// Cached shas `invalidate()` marked for loading again; each keeps its value until it does.
    private var stale: Set<String> = []
    /// Bumped by `invalidate()`; a batch started before it is dropped when it lands.
    private var generation = 0
    /// Set when a batch fell due while another was running; the running one starts it as
    /// it lands.
    private var isWaitingForRunning = false

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

    /// Marks every cached and unanswered sha for loading again, for values that change after
    /// they load (reviews). A cached value stays readable until its sha's next batch lands,
    /// which replaces it, or removes it when that batch no longer answers the sha. The queued
    /// request is dropped, and a batch still running is dropped when it lands, since it may
    /// have read what changed; the caller requests the rows it shows again.
    public func invalidate() {
        generation += 1
        stale.formUnion(values.keys)
        unanswered = []
        failedAt = [:]
        running = []
        queued = []
        kept = []
        isWaitingForRunning = false
        queueTask?.cancel()
        queueTask = nil
    }

    /// Queues `shas` for the next batch; see the type's description.
    public func request(_ shas: [String], replacingQueued: Bool = true) {
        var seen = Set<String>()
        let wanted = shas.filter { needsLoad($0) && seen.insert($0).inserted }
        if replacingQueued {
            queued = wanted
        } else {
            guard !wanted.isEmpty else { return }
            kept += wanted.filter { !kept.contains($0) }
        }
        queueTask?.cancel()
        queueTask = nil
        guard !queued.isEmpty || !kept.isEmpty else { return }
        let delay = delay
        queueTask = Task { [weak self] in
            do { try await Task.sleep(for: delay) } catch { return }
            self?.startQueued()
        }
    }

    private func needsLoad(_ sha: String) -> Bool {
        let wanted = (values[sha] == nil || stale.contains(sha)) && !running.contains(sha)
            && !unanswered.contains(sha)
        guard wanted else { return false }
        guard let failed = failedAt[sha] else { return true }
        return ContinuousClock.now - failed >= failureCooldown
    }

    private func startQueued() {
        guard running.isEmpty else {
            isWaitingForRunning = true
            return
        }
        isWaitingForRunning = false
        var seen = Set<String>()
        let batch = (kept + queued).filter { needsLoad($0) && seen.insert($0).inserted }
        queued = []
        kept = []
        guard !batch.isEmpty else { return }
        running.formUnion(batch)
        batchCount += 1
        let provider = provider
        let generation = generation
        loadTask = Task { [weak self] in
            let result: Result<[String: Value], Error>
            do {
                result = .success(try await provider(batch))
            } catch {
                result = .failure(error)
            }
            self?.finish(batch, result, generation: generation)
        }
    }

    private func finish(_ batch: [String], _ result: Result<[String: Value], Error>, generation: Int) {
        guard generation == self.generation else { return }
        running.subtract(batch)
        switch result {
        case .success(let loaded):
            var cachedAny = false
            for sha in batch {
                failedAt[sha] = nil
                let wasStale = stale.remove(sha) != nil
                if let value = loaded[sha] {
                    if values[sha] != value { cachedAny = true }
                    values[sha] = value
                } else {
                    if wasStale, values.removeValue(forKey: sha) != nil { cachedAny = true }
                    unanswered.insert(sha)
                }
            }
            if cachedAny { onLoad() }
        case .failure(let error):
            let now = ContinuousClock.now
            for sha in batch { failedAt[sha] = now }
            onFailure?(error)
        }
        if isWaitingForRunning { startQueued() }
    }
}
