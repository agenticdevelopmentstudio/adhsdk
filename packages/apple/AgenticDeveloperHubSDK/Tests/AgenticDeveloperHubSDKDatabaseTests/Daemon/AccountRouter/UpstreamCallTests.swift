import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class UpstreamCallTests: XCTestCase {
    func testACallCancelledBeforeItStartsLeavesNoTask() async throws {
        let session = UpstreamCall.makeSession()
        defer { session.invalidateAndCancel() }
        let call = UpstreamCall(session: session, request: URLRequest(url: URL(string: "https://127.0.0.1:9/")!))
        // allTasks omits a task never resumed, so the task's own state shows it was left behind.
        XCTAssertEqual(call.taskState, .suspended)

        call.cancel()

        let deadline = Date().addingTimeInterval(5)
        var remaining = await session.allTasks
        while (!remaining.isEmpty || call.taskState != .completed) && Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
            remaining = await session.allTasks
        }
        XCTAssertEqual(call.taskState, .completed, "a cancelled, never-started call left its task alive")
        XCTAssertTrue(remaining.isEmpty, "a cancelled, never-started call left its task in the session")
        let next = await call.next()
        XCTAssertNil(next)
    }
}
