import XCTest
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class IdleMonitorTests: XCTestCase {

    func testReturnFiresAfterIdleThenInput() {
        let readings = IdleReadings([0, 301, 302, 1])
        let monitor = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        var fired: [Int] = []
        for index in 1...4 {
            monitor.onReturn = { fired.append(index) }
            monitor.step()
        }
        XCTAssertEqual(fired, [4], "fires once, at the reading of 1")
    }

    func testNoFireWithoutIdle() {
        let readings = IdleReadings([0, 10, 299, 1, 5, 120])
        let monitor = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        var fired = 0
        monitor.onReturn = { fired += 1 }
        for _ in 0..<6 {
            monitor.step()
        }
        XCTAssertEqual(fired, 0)
    }

    func testFiresAgainAfterASecondAbsence() {
        let readings = IdleReadings([301, 1, 2, 305, 0])
        let monitor = IdleMonitor(idleSeconds: readings.next, threshold: 300, poll: 15)
        var fired = 0
        monitor.onReturn = { fired += 1 }
        for _ in 0..<5 {
            monitor.step()
        }
        XCTAssertEqual(fired, 2)
    }
}
