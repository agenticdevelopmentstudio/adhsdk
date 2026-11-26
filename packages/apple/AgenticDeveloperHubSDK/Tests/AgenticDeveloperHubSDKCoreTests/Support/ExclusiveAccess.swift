import Testing

/// A test trait that gives each test case sole use of one process-wide
/// resource: `@Suite(.exclusiveAccess(to: .userSettings))`.
///
/// Swift Testing runs suites side by side. Some state is one global for the
/// whole test process (`UserSettings.shared`, the static stub table behind
/// `StubURLProtocol`), so two suites writing it at once corrupt each other: one
/// suite's reset wipes another's setup part way through a test. `.serialized`
/// only orders the tests inside one suite. This trait orders every test case,
/// in every suite that carries it, that names the same resource. Suites that
/// leave the resource alone still run in parallel with all of them.
///
/// The wait suspends; it never blocks a thread.
///
/// Holding is re-entrant within the task that holds: a nested suite or test
/// that names a resource its enclosing scope already holds, or a test that
/// calls `acquire()` on it directly, goes straight through instead of waiting
/// on its own hold, which would park forever (a time limit cannot cancel the
/// continuation) and stall every later user of the resource in the bundle.
struct ExclusiveAccess: SuiteTrait, TestTrait, TestScoping {

    /// The resources the current task holds through a trait scope. Child
    /// tasks of the test inherit it, so work the test starts is inside the hold.
    @TaskLocal static var heldByCurrentTask: Set<ObjectIdentifier> = []

    /// One process-wide resource that tests take turns with.
    actor Resource {
        private var held = false
        private var waiters: [CheckedContinuation<Void, Never>] = []
        /// Direct `acquire()` calls made while the current task already held
        /// the resource through a trait scope; each one's `release()` only
        /// unwinds this count. Only the holder can make one, so one count
        /// serves.
        private var reentrantAcquires = 0

        func acquire() async {
            if ExclusiveAccess.heldByCurrentTask.contains(ObjectIdentifier(self)) {
                reentrantAcquires += 1
                return
            }
            guard held else {
                held = true
                return
            }
            await withCheckedContinuation { waiters.append($0) }
        }

        /// Hands the resource straight to the next waiter, in arrival order.
        func release() {
            if reentrantAcquires > 0 {
                reentrantAcquires -= 1
                return
            }
            if waiters.isEmpty {
                held = false
            } else {
                waiters.removeFirst().resume()
            }
        }
    }

    let resource: Resource

    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // A suite's own scope has no test case: only the cases inside it
        // touch the resource, and holding it for the whole suite would stop
        // the next suite from interleaving with nothing gained.
        guard testCase != nil else {
            try await function()
            return
        }
        let id = ObjectIdentifier(resource)
        let alreadyHeld = Self.heldByCurrentTask
        // Swift Testing does not dedupe trait occurrences: an inner suite or
        // test naming the same resource runs inside the outer hold.
        guard !alreadyHeld.contains(id) else {
            try await function()
            return
        }
        await resource.acquire()
        do {
            try await Self.$heldByCurrentTask.withValue(alreadyHeld.union([id])) {
                try await function()
            }
        } catch {
            await resource.release()
            throw error
        }
        await resource.release()
    }
}

extension ExclusiveAccess.Resource {
    /// `UserSettings.shared`, and every static `UserSetting` bound to it.
    static let userSettings = ExclusiveAccess.Resource()
}

extension Trait where Self == ExclusiveAccess {
    static func exclusiveAccess(to resource: ExclusiveAccess.Resource) -> Self {
        ExclusiveAccess(resource: resource)
    }
}
