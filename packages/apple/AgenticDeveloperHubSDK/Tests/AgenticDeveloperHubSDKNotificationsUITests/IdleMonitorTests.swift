import AppKit
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

    // MARK: Sleep, screen lock and session switches

    /// The lid closes two minutes after the snooze: no sample ever read 300 s of
    /// idle, and the unlock input resets the idle clock. Sleep marks the user
    /// away, so the wake brings the return.
    func testSleepThenWakeIsAReturn() {
        let harness = SleepHarness()
        harness.monitor.start()
        harness.sample(idle: 120)
        harness.post(NSWorkspace.willSleepNotification)
        harness.advance(by: 3_000)
        harness.idle = 0
        harness.post(NSWorkspace.didWakeNotification)
        XCTAssertEqual(harness.fired, 1)
        harness.monitor.stop()
    }

    func testScreenSleepThenInputIsAReturn() {
        let harness = SleepHarness()
        harness.monitor.start()
        harness.post(NSWorkspace.screensDidSleepNotification)
        harness.advance(by: 15)
        harness.sample(idle: 135)
        XCTAssertEqual(harness.fired, 0, "no input since the screens slept")
        harness.advance(by: 60)
        harness.sample(idle: 2)
        XCTAssertEqual(harness.fired, 1)
        harness.monitor.stop()
    }

    func testSessionSwitchBackIsAReturn() {
        let harness = SleepHarness()
        harness.monitor.start()
        harness.post(NSWorkspace.sessionDidResignActiveNotification)
        harness.advance(by: 40)
        harness.idle = 1
        harness.post(NSWorkspace.sessionDidBecomeActiveNotification)
        XCTAssertEqual(harness.fired, 1)
        harness.monitor.stop()
    }

    /// A wake with no input yet, the Mac sitting at the lock screen, is not a
    /// return; the first input after it is.
    func testWakeWithoutInputWaitsForInput() {
        let harness = SleepHarness()
        harness.monitor.start()
        harness.post(NSWorkspace.willSleepNotification)
        harness.advance(by: 600)
        harness.idle = 700
        harness.post(NSWorkspace.didWakeNotification)
        XCTAssertEqual(harness.fired, 0)
        harness.advance(by: 15)
        harness.sample(idle: 3)
        XCTAssertEqual(harness.fired, 1)
        harness.monitor.stop()
    }

    func testStoppedMonitorIgnoresSleep() {
        let harness = SleepHarness()
        harness.post(NSWorkspace.willSleepNotification)
        harness.advance(by: 600)
        harness.idle = 0
        harness.post(NSWorkspace.didWakeNotification)
        XCTAssertEqual(harness.fired, 0)
    }
}

/// An `IdleMonitor` on a private notification center and a hand-moved clock.
@MainActor
private final class SleepHarness {
    let center = NotificationCenter()
    var idle: TimeInterval = 0
    var clock = Date(timeIntervalSince1970: 1_000_000)
    var fired = 0
    private(set) var monitor: IdleMonitor!

    init() {
        monitor = IdleMonitor(
            idleSeconds: { [unowned self] in idle },
            threshold: 300,
            poll: 3_600,
            notifications: center,
            now: { [unowned self] in clock }
        )
        monitor.onReturn = { [unowned self] in fired += 1 }
    }

    func sample(idle: TimeInterval) {
        self.idle = idle
        monitor.step()
    }

    func advance(by seconds: TimeInterval) {
        clock = clock.addingTimeInterval(seconds)
    }

    func post(_ name: Notification.Name) {
        center.post(name: name, object: nil)
    }
}
