import Foundation

/// A one-shot result that several racing tasks may try to settle; the first `finish` wins and
/// later ones are ignored. `value()` suspends until it is settled. Unlike a task group, a
/// waiter is released the moment the box settles, even if the losing tasks never finish.
final class RaceBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<T, Error>?
    private var waiters: [CheckedContinuation<T, Error>] = []

    init() {}

    /// Settles the box. Returns whether this call won the race.
    @discardableResult
    func finish(_ outcome: Result<T, Error>) -> Bool {
        let released: [CheckedContinuation<T, Error>]? = lock.withLock {
            guard result == nil else { return nil }
            result = outcome
            defer { waiters = [] }
            return waiters
        }
        guard let released else { return false }
        for waiter in released { waiter.resume(with: outcome) }
        return true
    }

    /// Whether the box has been settled.
    var isFinished: Bool { lock.withLock { result != nil } }

    /// The settled outcome, waiting for it if necessary.
    func value() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let ready: Result<T, Error>? = lock.withLock {
                if let result { return result }
                waiters.append(continuation)
                return nil
            }
            if let ready { continuation.resume(with: ready) }
        }
    }
}
