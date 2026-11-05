import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// Local doubles: `TestSupport.swift` in this target builds `InboundEvent`s
/// from the coordinator's own wire types and has no standalone command
/// fixtures, and `AgenticDeveloperHubSDKUITests`'s `ChatFixtures` doesn't
/// cross the framework boundary.
private struct StubInvocation: CommandInvocation {
    var id: String
    var commandName: String = "search"
    var invokerID: String = "persona-1"
    var invokerKind: CommandInvoker = .other
    var argumentsJSON: String = "{}"
    var requestedAt: Date = Date()
}

private struct StubResult: CommandResult {
    var invocationID: String
    var ok: Bool = true
    var resultJSON: String? = nil
    var errorMessage: String? = nil
    var completedAt: Date = Date()
}

@Suite("CommandActivity")
struct CommandActivityTests {

    @Test("an activity with no result yet is running, and takes the invocation's id")
    func runningWithoutResult() {
        let activity = CommandActivity(invocation: StubInvocation(id: "inv-1"))
        #expect(activity.isRunning)
        #expect(activity.id == "inv-1")
        #expect(activity.result == nil)
    }

    @Test("an activity carrying a result is no longer running")
    func completedWithResult() {
        let activity = CommandActivity(
            invocation: StubInvocation(id: "inv-1"),
            result: StubResult(invocationID: "inv-1"))
        #expect(!activity.isRunning)
        #expect(activity.result?.ok == true)
    }

    @Test("its identity stays the invocation's across completion, so a view can match rows")
    func identityIsStableAcrossCompletion() {
        let invocation = StubInvocation(id: "inv-7")
        let running = CommandActivity(invocation: invocation)
        let done = CommandActivity(invocation: invocation, result: StubResult(invocationID: "inv-7", ok: false))
        #expect(running.id == done.id)
        #expect(done.result?.ok == false)
    }
}
