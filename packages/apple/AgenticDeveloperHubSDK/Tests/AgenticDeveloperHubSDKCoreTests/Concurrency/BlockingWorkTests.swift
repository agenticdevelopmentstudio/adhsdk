import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

@Suite("BlockingWork")
struct BlockingWorkTests {
    @Test("foundation-concurrency-003: returns what the work returned")
    func returnsValue() async {
        let value = await BlockingWork.run { 42 }
        #expect(value == 42)
    }

    @Test("foundation-concurrency-002: rethrows what the work threw")
    func rethrowsWhatTheWorkThrew() async {
        struct Boom: Error {}
        await #expect(throws: Boom.self) {
            try await BlockingWork.run { () throws -> Int in throw Boom() }
        }
    }

    /// Without `enforcedQoS` a block submitted from a user-interactive caller
    /// would run at that class; enforced, it runs at default.
    @Test("enforcedQoS pins the block's class whatever the caller's is")
    func enforcedQoSPinsTheClass() async {
        let observed = await Task(priority: .high) {
            await BlockingWork.run(qos: .default, enforcedQoS: .default) { qos_class_self().rawValue }
        }.value
        #expect(observed == QOS_CLASS_DEFAULT.rawValue)
    }

    @Test("foundation-concurrency-001: the closure runs off the calling thread at the default qos")
    @MainActor
    func closureRunsOffTheCallingThread() async {
        let ranOnMain = await BlockingWork.run { Thread.isMainThread }
        #expect(ranOnMain == false)
    }

    @Test("foundation-concurrency-004: the non-throwing overload returns its value")
    func nonThrowingOverloadReturnsItsValue() async {
        let value = await BlockingWork.run { "done" }
        #expect(value == "done")
    }

    @Test("foundation-concurrency-005: a file read happens off the caller and a missing file gives nothing")
    func fileReadHappensOffTheCaller() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("blocking-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url) }
        let bytes = Data("contents".utf8)
        try bytes.write(to: url)

        let present = await BlockingWork.run(qos: .userInitiated) {
            (try? Data(contentsOf: url), Thread.isMainThread)
        }
        #expect(present.0 == bytes)
        #expect(present.1 == false)

        let missing = url.appendingPathExtension("absent")
        let absent = await BlockingWork.run(qos: .userInitiated) { try? Data(contentsOf: missing) }
        #expect(absent == nil)
    }

    @Test("foundation-concurrency-006: cancelling the caller does not interrupt or fail the work")
    func cancellationDoesNotInterruptTheWork() async throws {
        let task = Task {
            try await BlockingWork.run { () throws -> Int in
                Thread.sleep(forTimeInterval: 0.1)
                return 7
            }
        }
        task.cancel()
        let result = try await task.value
        #expect(result == 7)
    }

    @Test("foundation-concurrency-007: ten concurrent calls all complete independently")
    func tenConcurrentCallsComplete() async {
        let onMain = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await BlockingWork.run {
                        Thread.sleep(forTimeInterval: 0.05)
                        return Thread.isMainThread
                    }
                }
            }
            var results: [Bool] = []
            for await result in group { results.append(result) }
            return results
        }
        #expect(onMain.count == 10)
        #expect(onMain.allSatisfy { $0 == false })
    }
}
