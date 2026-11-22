#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The router's resource limits. Injectable so tests can use tiny ones.
///
/// The router runs inside the capture daemon, so its memory must stay
/// bounded whatever local clients do: at most `maxConnections` are served at
/// once, request bodies held in memory never total more than
/// `maxBodyBytesInFlight`, and a request must arrive within
/// `requestDeadline` of being admitted however slowly it trickles in.
///
/// Fail-open shapes how the first two bite: hitting either makes the next
/// connection *wait*, never fail. A waiting connection is accepted but not
/// read, so its bytes sit in the kernel's socket buffer, not in the daemon;
/// past `maxConnections + maxWaiting` the listener stops accepting and the
/// kernel's backlog holds the rest. Nothing a client does can hold a slot
/// forever: the request has `requestDeadline`, each read `idleTimeout`, each
/// send `sendStallTimeout`, so every waiter is eventually served.
struct RouterLimits: Sendable, Equatable {
    static let standard = RouterLimits()

    /// Connections served at once; later ones wait their turn, first come first served.
    var maxConnections = 64
    /// Request bodies held at once, in bytes. At least one maximum-size body
    /// (`RouterRequestParser.maxBodyBytes`) always fits.
    var maxBodyBytesInFlight = 256 * 1024 * 1024
    /// Connections accepted beyond `maxConnections` that wait in the daemon
    /// for a slot. Past that the listener stops accepting: further clients
    /// wait in the kernel's listen backlog, still not refused, holding no
    /// descriptor in the daemon.
    var maxWaiting = 64
    /// Silence allowed between two reads of the request.
    var idleTimeout: TimeInterval = 60
    /// How long one send to the client may make no progress (a client that
    /// stopped reading) before the exchange is dropped and its slot and body
    /// budget are released.
    var sendStallTimeout: TimeInterval = 60
    /// The whole request head and body must arrive within this, counted from
    /// admission and excluding any wait for body budget. 64 MiB over loopback
    /// takes well under a second; five minutes is room for a busy machine.
    var requestDeadline: TimeInterval = 300
    /// A provider attempt's response head must arrive within this, or the
    /// request falls back to Anthropic as if the provider were unreachable.
    var providerHeadDeadline: TimeInterval = 45
    /// The head deadline for a reply the client did not ask to stream: the
    /// provider sends no head until the whole answer is written, which for a
    /// long answer takes minutes.
    var providerUnstreamedHeadDeadline: TimeInterval = 300
    /// While a provider's reply can still fall back (nothing has reached the
    /// client), silence longer than this from the provider falls back too.
    var providerIdleDeadline: TimeInterval = 45

    /// Connections the daemon holds at once, served or waiting.
    var acceptLimit: Int { max(1, maxConnections) + max(0, maxWaiting) }
}

/// The two allowances every connection draws on, shared by all of them.
final class RouterAdmission: Sendable {
    let connections: AsyncAllowance
    let bodyBytes: AsyncAllowance

    init(_ limits: RouterLimits) {
        connections = AsyncAllowance(capacity: limits.maxConnections)
        bodyBytes = AsyncAllowance(capacity: limits.maxBodyBytesInFlight)
    }
}

/// A first-come-first-served counting allowance for async callers: `acquire`
/// suspends until the units are free, `release` hands them back and wakes
/// whoever is next. Strict FIFO, so a large request is never starved by a
/// stream of small ones. A request for more than the capacity is clamped to
/// it, so it waits for an idle allowance rather than forever. A cancelled
/// waiter leaves the queue at once and gets nothing.
final class AsyncAllowance: @unchecked Sendable {
    private struct Waiter {
        let id: Int
        let units: Int
        let continuation: CheckedContinuation<Bool, Never>
    }

    let capacity: Int
    private let lock = NSLock()
    private var available: Int
    private var waiters: [Waiter] = []
    private var nextID = 0

    init(capacity: Int) {
        self.capacity = max(1, capacity)
        available = self.capacity
    }

    /// Units in use right now.
    var inUse: Int { lock.withLock { capacity - available } }

    /// Callers suspended in `acquire`.
    var waiting: Int { lock.withLock { waiters.count } }

    /// Waits for `units` (clamped to `0...capacity`) and returns how many were
    /// taken; give exactly that back to `release`. 0 if the task is cancelled
    /// before the units are granted.
    func acquire(_ units: Int) async -> Int {
        let wanted = min(max(0, units), capacity)
        guard wanted > 0 else { return 0 }
        let id = lock.withLock { () -> Int in
            nextID += 1
            return nextID
        }
        let granted = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                lock.lock()
                if waiters.isEmpty && available >= wanted {
                    available -= wanted
                    lock.unlock()
                    continuation.resume(returning: true)
                } else if Task.isCancelled {
                    lock.unlock()
                    continuation.resume(returning: false)
                } else {
                    waiters.append(Waiter(id: id, units: wanted, continuation: continuation))
                    lock.unlock()
                }
            }
        } onCancel: {
            leave(id)
        }
        return granted ? wanted : 0
    }

    /// Takes `units` (clamped as in `acquire`) only if `acquire` would grant
    /// them without waiting: how many were taken, or nil when it would wait.
    func tryAcquire(_ units: Int) -> Int? {
        let wanted = min(max(0, units), capacity)
        guard wanted > 0 else { return 0 }
        return lock.withLock {
            guard waiters.isEmpty, available >= wanted else { return nil }
            available -= wanted
            return wanted
        }
    }

    func release(_ units: Int) {
        guard units > 0 else { return }
        let ready = lock.withLock { () -> [CheckedContinuation<Bool, Never>] in
            available = min(capacity, available + units)
            return wakeReady()
        }
        for continuation in ready { continuation.resume(returning: true) }
    }

    /// A cancelled waiter's exit. Removing it may unblock those behind it.
    private func leave(_ id: Int) {
        typealias Exits = (CheckedContinuation<Bool, Never>?, [CheckedContinuation<Bool, Never>])
        let (gone, ready) = lock.withLock { () -> Exits in
            guard let index = waiters.firstIndex(where: { $0.id == id }) else { return (nil, []) }
            let gone = waiters.remove(at: index).continuation
            return (gone, wakeReady())
        }
        gone?.resume(returning: false)
        for continuation in ready { continuation.resume(returning: true) }
    }

    /// Grants waiters from the front while they fit. Call with the lock held.
    private func wakeReady() -> [CheckedContinuation<Bool, Never>] {
        var woken: [CheckedContinuation<Bool, Never>] = []
        while let first = waiters.first, first.units <= available {
            available -= first.units
            waiters.removeFirst()
            woken.append(first.continuation)
        }
        return woken
    }
}
#endif
