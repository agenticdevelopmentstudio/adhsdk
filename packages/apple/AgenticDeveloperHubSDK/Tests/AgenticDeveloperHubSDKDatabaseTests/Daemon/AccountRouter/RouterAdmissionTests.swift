import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The allowance the router's connection cap and body budget are built on,
/// and the settings cache in front of the database.
final class RouterAdmissionTests: XCTestCase {

    func testAcquireWithinCapacityIsImmediateAndReleaseGivesBack() async {
        let allowance = AsyncAllowance(capacity: 10)
        let taken = await allowance.acquire(4)
        XCTAssertEqual(taken, 4)
        XCTAssertEqual(allowance.inUse, 4)
        allowance.release(taken)
        XCTAssertEqual(allowance.inUse, 0)
        let none = await allowance.acquire(0)
        XCTAssertEqual(none, 0)
    }

    func testARequestOverCapacityIsClampedSoItCanStillBeServed() async {
        let allowance = AsyncAllowance(capacity: 10)
        let taken = await allowance.acquire(1000)
        XCTAssertEqual(taken, 10)
        allowance.release(taken)
    }

    func testWaitersAreServedInArrivalOrderWhenUnitsFree() async throws {
        let allowance = AsyncAllowance(capacity: 2)
        let held = await allowance.acquire(2)
        let order = OrderBox()
        let big = Task {
            let units = await allowance.acquire(2)
            order.append("big")
            allowance.release(units)
        }
        while allowance.waiting < 1 { await Task.yield() }
        let small = Task {
            let units = await allowance.acquire(1)
            order.append("small")
            allowance.release(units)
        }
        while allowance.waiting < 2 { await Task.yield() }
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(order.values, [], "nobody runs while the allowance is full")
        allowance.release(held)
        await big.value
        await small.value
        XCTAssertEqual(order.values, ["big", "small"], "first come, first served: no starving the large one")
        XCTAssertEqual(allowance.inUse, 0)
    }

    /// Final review minor 6: a connection cancelled while it waits for a slot
    /// gives back nothing, so it cannot let an extra connection in.
    func testACancelledSlotWaitReleasesNothingAndServesNothing() async throws {
        let connections = AsyncAllowance(capacity: 2)
        let held = await connections.acquire(2)
        let waiter = Task { () -> (Bool, Bool) in
            var ran = false
            let served = await RouterConnection.holdingSlot(connections) { ran = true }
            return (served, ran)
        }
        while connections.waiting < 1 { await Task.yield() }
        waiter.cancel()
        let (served, ran) = await waiter.value
        XCTAssertFalse(served)
        XCTAssertFalse(ran, "a cancelled wait does not serve")
        XCTAssertEqual(connections.inUse, 2, "nothing released that was not acquired")
        connections.release(1)
        let next = await RouterConnection.holdingSlot(connections) {
            XCTAssertEqual(connections.inUse, 2)
        }
        XCTAssertTrue(next)
        XCTAssertEqual(connections.inUse, 1, "a served connection gives back exactly its slot")
        connections.release(held - 1)
        XCTAssertEqual(connections.inUse, 0)
    }

    /// Re-review N2: a cancelled waiter leaves at once with nothing, and the
    /// waiter it was blocking (FIFO) is served.
    func testACancelledWaiterGetsNothingAndUnblocksThoseBehindIt() async throws {
        let allowance = AsyncAllowance(capacity: 2)
        let held = await allowance.acquire(1)
        let big = Task { await allowance.acquire(2) }
        while allowance.waiting < 1 { await Task.yield() }
        let small = Task { await allowance.acquire(1) }
        while allowance.waiting < 2 { await Task.yield() }
        big.cancel()
        let bigGot = await big.value
        let smallGot = await small.value
        XCTAssertEqual(bigGot, 0, "cancelled: nothing granted")
        XCTAssertEqual(smallGot, 1, "the one behind it is served once it leaves")
        XCTAssertEqual(allowance.inUse, 2)
        XCTAssertEqual(allowance.waiting, 0)
        allowance.release(held)
        allowance.release(smallGot)
        XCTAssertEqual(allowance.inUse, 0)
        let late = Task { () -> Int in
            withUnsafeCurrentTask { $0?.cancel() }
            return await allowance.acquire(1)
        }
        let lateGot = await late.value
        XCTAssertEqual(lateGot, 1, "free units are granted even to a cancelled task: nothing to wait for")
        allowance.release(lateGot)
    }

    func testDefaultLimitsAlwaysFitOneMaximumBody() {
        XCTAssertGreaterThanOrEqual(RouterLimits.standard.maxBodyBytesInFlight, RouterRequestParser.maxBodyBytes)
        XCTAssertEqual(RouterLimits.standard.idleTimeout, 60)
        XCTAssertGreaterThan(RouterLimits.standard.requestDeadline, RouterLimits.standard.idleTimeout)
        XCTAssertEqual(RouterLimits.standard.sendStallTimeout, 60)
        XCTAssertEqual(RouterLimits.standard.acceptLimit, 128)
    }

    func testCachedSettingsReloadAfterTheTTLOrAnInvalidate() {
        let loads = OrderBox()
        let cache = CachedSettings(ttl: 10) {
            loads.append("load")
            return AccountRouterSettings()
        }
        let start = Date()
        _ = cache.current(now: start)
        _ = cache.current(now: start.addingTimeInterval(5))
        XCTAssertEqual(loads.values.count, 1, "within the TTL the cached value is used")
        _ = cache.current(now: start.addingTimeInterval(11))
        XCTAssertEqual(loads.values.count, 2, "past the TTL it reloads")
        cache.invalidate()
        _ = cache.current(now: start.addingTimeInterval(12))
        XCTAssertEqual(loads.values.count, 3, "an invalidate forces a reload")
    }
}

private final class OrderBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [String] = []
    var values: [String] { lock.withLock { stored } }
    func append(_ value: String) { lock.withLock { stored.append(value) } }
}
