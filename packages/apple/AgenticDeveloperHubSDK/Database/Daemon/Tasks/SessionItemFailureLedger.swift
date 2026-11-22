#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

/// An in-memory, per-item retry budget for a batch task. DaemonKit's
/// `ItemFailureLedger`, here because the toolkit sits below DaemonKit.
///
/// The scheduler budgets failures per *task* (`consecutiveFailures`, and
/// DaemonKit's `CrashTracker`'s per-task strikes). A task that works through a batch of
/// items needs the finer budget: one poisoned item must not be picked again on
/// every pass while the rest of the batch keeps succeeding. The ledger counts an
/// item's failures, gives it up at `maxAttempts`, and forgets it the moment it
/// succeeds — new work on a given-up item earns a fresh set of attempts.
///
/// Thread-safe; a task holds one for the daemon's life.
public final class SessionItemFailureLedger<Key: Hashable & Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var counts: [Key: Int] = [:]
    private var givenUp: Set<Key> = []

    public init() {}

    /// Items given up on after too many failures, until they next succeed.
    /// A caller keeps these out of its re-selection.
    public var abandoned: Set<Key> {
        lock.withLock { givenUp }
    }

    /// Records a failure. Returns true when this one reaches `maxAttempts` —
    /// the caller then does whatever "give up" means for it — and resets the
    /// count, so later work earns a fresh set of attempts.
    public func failed(_ key: Key, maxAttempts: Int) -> Bool {
        lock.withLock {
            let count = counts[key, default: 0] + 1
            guard count >= maxAttempts else {
                counts[key] = count
                return false
            }
            counts[key] = nil
            givenUp.insert(key)
            return true
        }
    }

    /// Clears the item's failures and takes it off the abandoned list.
    public func succeeded(_ key: Key) {
        lock.withLock {
            counts[key] = nil
            _ = givenUp.remove(key)
        }
    }

    /// Failures recorded since the item last succeeded or was given up on.
    public func attempts(_ key: Key) -> Int {
        lock.withLock { counts[key, default: 0] }
    }
}
#endif
