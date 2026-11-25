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
struct ExclusiveAccess: SuiteTrait, TestTrait, TestScoping {

    /// One process-wide resource that tests take turns with.
    actor Resource {
        private var held = false
        private var waiters: [CheckedContinuation<Void, Never>] = []

        func acquire() async {
            guard held else {
                held = true
                return
            }
            await withCheckedContinuation { waiters.append($0) }
        }

        /// Hands the resource straight to the next waiter, in arrival order.
        func release() {
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
        await resource.acquire()
        do {
            try await function()
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
