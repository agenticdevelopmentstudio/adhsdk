import Foundation

/// Runs `body` on the main run loop's next pass, in the common modes, and
/// returns at once.
///
/// For work that must get off the current call stack — a modal loop, a
/// presentation started from a menu still tracking or a SwiftUI update — and
/// that must not run as a main-*queue* block: a modal loop never returns from
/// the block that starts it, so started from `DispatchQueue.main.async` it
/// would hold the main queue for as long as it is up, and nothing else on the
/// main actor would run meanwhile — no `Task` a button starts, no `await`
/// resuming. A run loop block is not a main-queue block, so the queue keeps
/// draining underneath it.
@MainActor
public func performOnNextRunLoopPass(_ body: @escaping @MainActor () -> Void) {
    CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) {
        MainActor.assumeIsolated { body() }
    }
    CFRunLoopWakeUp(CFRunLoopGetMain())
}
