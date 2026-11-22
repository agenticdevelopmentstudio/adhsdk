import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

/// The single-instance slot: only a pid naming one other process may own it.
final class SessionAppRegistryTests: XCTestCase {

    /// This test process plays the app; the daemon is some other pid.
    private let appPid = ProcessInfo.processInfo.processIdentifier
    private let daemonPid: Int32 = 999_999

    private func makeRegistry() -> SessionAppRegistry {
        SessionAppRegistry(daemonPid: daemonPid)
    }

    func testALivePidRegistersAndHoldsTheSlot() async {
        let registry = makeRegistry()

        let result = await registry.register(pid: appPid)
        let owner = await registry.currentOwner()

        XCTAssertEqual(result, .registered)
        XCTAssertEqual(owner, appPid)
    }

    /// `kill(0, 0)` and `kill(-1, 0)` succeed for process groups, so these
    /// would never go stale; they are refused and nothing is stored.
    func testZeroAndNegativePidsAreRefusedAndNeverStored() async {
        let registry = makeRegistry()

        for pid: Int32 in [0, -1, -42, Int32.min] {
            let result = await registry.register(pid: pid)
            XCTAssertEqual(result, .invalidPid, "pid \(pid)")
        }
        let owner = await registry.currentOwner()
        XCTAssertNil(owner)
        let later = await registry.register(pid: appPid)
        XCTAssertEqual(later, .registered, "an invalid pid must not block the real app")
    }

    func testTheDaemonsOwnPidIsRefused() async {
        let registry = makeRegistry()

        let result = await registry.register(pid: daemonPid)
        let owner = await registry.currentOwner()

        XCTAssertEqual(result, .invalidPid)
        XCTAssertNil(owner)
    }

    func testValidityIsPositiveAndNotTheDaemon() {
        let registry = makeRegistry()

        XCTAssertTrue(registry.isValidOwner(pid: appPid))
        XCTAssertFalse(registry.isValidOwner(pid: 0))
        XCTAssertFalse(registry.isValidOwner(pid: -1))
        XCTAssertFalse(registry.isValidOwner(pid: daemonPid))
    }

    func testTheDefaultDaemonPidIsTheRunningProcess() {
        XCTAssertFalse(SessionAppRegistry().isValidOwner(pid: appPid))
    }

    func testUnregisteringAnInvalidPidReleasesNothing() async {
        let registry = makeRegistry()
        _ = await registry.register(pid: appPid)

        let zero = await registry.unregister(pid: 0)
        let negative = await registry.unregister(pid: -1)
        let owner = await registry.currentOwner()

        XCTAssertFalse(zero)
        XCTAssertFalse(negative)
        XCTAssertEqual(owner, appPid)
    }
}
