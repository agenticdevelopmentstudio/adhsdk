import Foundation
import XCTest

/// Runs the main run loop until every block already queued on the main queue
/// has run, `rounds` times over, for tests whose changes arrive through
/// `receive(on: DispatchQueue.main)`.
///
/// A fixed wait (`RunLoop.main.run(until: now + 0.05)`) only works while the
/// machine is idle: with the suite running in parallel, 50 ms can pass before
/// the run loop reaches the delivery, and the assertion after it sees the old
/// value. The main queue is FIFO, so a marker queued after the change runs
/// only once the change has been delivered. Each round queues a fresh marker,
/// so a delivery that hops the main queue again is drained by the next round.
/// It also serves for "nothing changed" checks: once it returns, anything the
/// change was going to do on the main queue has been done.
@MainActor
func pumpMainQueueUntilDrained(rounds: Int = 3, timeout: TimeInterval = 10,
                               file: StaticString = #filePath, line: UInt = #line) {
    final class Marker: @unchecked Sendable { var ran = false }
    let deadline = Date().addingTimeInterval(timeout)
    for _ in 0..<rounds {
        let marker = Marker()
        DispatchQueue.main.async { marker.ran = true }
        while !marker.ran {
            guard Date() < deadline else {
                XCTFail("the main queue did not drain within \(timeout)s", file: file, line: line)
                return
            }
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
    }
}
