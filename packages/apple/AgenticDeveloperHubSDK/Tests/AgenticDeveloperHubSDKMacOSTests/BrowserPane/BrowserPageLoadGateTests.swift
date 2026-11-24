import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The hidden extensions page's load: one timeout per load, failures that
/// count only while it loads, and a close that fails every caller.
@MainActor
final class BrowserPageLoadGateTests: XCTestCase {

    /// Timers armed by the gate, fired by hand.
    private var timers: [(TimeInterval, @MainActor @Sendable () -> Void)] = []

    private func makeGate() -> BrowserPageLoadGate {
        BrowserPageLoadGate(pageName: "The page", timeout: 30) { [weak self] delay, action in
            MainActor.assumeIsolated { self?.timers.append((delay, action)) }
        }
    }

    /// A caller waiting on `gate`, started and registered.
    private func waiter(_ gate: BrowserPageLoadGate) async -> Task<Result<Void, Error>, Never> {
        let before = gate.waiting
        let task = Task { @MainActor in
            do {
                try await gate.wait()
                return Result<Void, Error>.success(())
            } catch {
                return .failure(error)
            }
        }
        for _ in 0..<100 where gate.waiting == before {
            await Task.yield()
        }
        XCTAssertEqual(gate.waiting, before + 1, "the caller is waiting")
        return task
    }

    private func message(_ result: Result<Void, Error>) -> String? {
        guard case .failure(let error) = result else { return nil }
        return error.localizedDescription
    }

    func test_waitersResumeWhenThePageLoads() async {
        let gate = makeGate()
        let first = await waiter(gate)
        let second = await waiter(gate)

        gate.pageDidLoad()

        let firstResult = await first.value
        let secondResult = await second.value
        XCTAssertNil(message(firstResult))
        XCTAssertNil(message(secondResult))
        XCTAssertEqual(gate.state, .loaded)
        XCTAssertFalse(gate.hasFailed)
    }

    func test_oneTimeoutPerLoadNotPerWaiter() async {
        let gate = makeGate()
        XCTAssertEqual(timers.count, 1, "armed when the load starts")
        let first = await waiter(gate)
        let second = await waiter(gate)
        XCTAssertEqual(timers.count, 1, "a later caller waits on the same load")
        XCTAssertEqual(timers.first?.0, 30)

        timers.first?.1()

        let sentence = "The page did not load within 30 seconds."
        let firstResult = await first.value
        let secondResult = await second.value
        XCTAssertEqual(message(firstResult), sentence)
        XCTAssertEqual(message(secondResult), sentence)
        XCTAssertTrue(gate.hasFailed)
    }

    func test_timeoutAfterLoadDoesNothing() async throws {
        let gate = makeGate()
        gate.pageDidLoad()
        timers.first?.1()

        XCTAssertEqual(gate.state, .loaded)
        try await gate.wait()
    }

    func test_failureWhileLoadingFailsWaiters() async {
        let gate = makeGate()
        let caller = await waiter(gate)

        gate.pageDidFail("net::ERR_ABORTED")

        let result = await caller.value
        XCTAssertEqual(message(result), "The page did not load: net::ERR_ABORTED")
        XCTAssertTrue(gate.hasFailed)
        do {
            try await gate.wait()
            XCTFail("a failed load fails a later caller at once")
        } catch {
            XCTAssertEqual(error.localizedDescription, "The page did not load: net::ERR_ABORTED")
        }
    }

    func test_lateFailureAfterLoadIsIgnored() async throws {
        let gate = makeGate()
        gate.pageDidLoad()

        gate.pageDidFail("a sub-frame failed")

        XCTAssertFalse(gate.hasFailed, "a working page stays working")
        XCTAssertEqual(gate.state, .loaded)
        try await gate.wait()
    }

    func test_closeFailsWaitersAndLaterCallers() async {
        let gate = makeGate()
        let caller = await waiter(gate)

        gate.close()

        let result = await caller.value
        XCTAssertEqual(message(result), "Extension management closed.")
        XCTAssertFalse(gate.hasFailed, "closed is not a failed page")
        gate.pageDidLoad()
        XCTAssertEqual(gate.state, .closed, "nothing reopens a closed gate")
        do {
            try await gate.wait()
            XCTFail("a closed gate fails every later caller")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Extension management closed.")
        }
    }
}
