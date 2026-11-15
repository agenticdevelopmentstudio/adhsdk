import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// The point of the helper is to get off the caller's stack: the work never
/// runs inside the call, and it does run once the run loop turns.
@Suite("performOnNextRunLoopPass")
@MainActor
struct NextRunLoopPassTests {

    @Test func runsLaterNotInline() async {
        var ran = false
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            performOnNextRunLoopPass {
                ran = true
                continuation.resume()
            }
            #expect(!ran, "the work does not run inside the call")
        }
        #expect(ran)
    }
}
