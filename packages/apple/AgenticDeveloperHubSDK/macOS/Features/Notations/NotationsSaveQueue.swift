import Foundation

/// The one serial line every Notations edit is written through, so saves land
/// in the order they were typed and quit can wait for all of them.
///
/// The store is `async` (it may be adhd across a socket), so a save can no
/// longer be a block on a serial dispatch queue that quit drains with
/// `sync {}`. Each operation here starts after the one before it finishes;
/// `drain()` returns once everything enqueued so far has run.
public final class NotationsSaveQueue: @unchecked Sendable {

    public static let shared = NotationsSaveQueue()

    private let lock = NSLock()
    private var tail: Task<Void, Never>?

    public init() {}

    /// Runs `operation` after every operation enqueued before it.
    public func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        lock.withLock {
            let previous = tail
            tail = Task {
                await previous?.value
                await operation()
            }
        }
    }

    /// Waits for every operation enqueued so far.
    public func drain() async {
        let last = lock.withLock { tail }
        await last?.value
    }
}
