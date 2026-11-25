import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `ProcessExitWatch` against short-lived and sleeping children. The type's
/// own vectors (process-exit-watch-001 to -012); `CommandRunnerTests` only
/// exercises it through the runner.
@Suite(.serialized)
struct ProcessExitWatchConformanceTests {

    private func launch(_ path: String, _ arguments: [String]) throws -> (Process, ProcessExitWatch) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let watch = ProcessExitWatch(process)
        try process.run()
        return (process, watch)
    }

    private func elapsed(_ body: () -> Void) -> TimeInterval {
        let start = Date()
        body()
        return Date().timeIntervalSince(start)
    }

    @Test("V1: creating the watch for a running process fails a precondition",
          .disabled("a failed precondition ends the test process, and no exit-test harness is wired in"))
    func v001InstallBeforeLaunch() {}

    @Test("V2: a process that exits is signalled well before the timeout")
    func v002ExitIsSignalled() throws {
        let (_, watch) = try launch("/usr/bin/true", [])
        var exited = false
        let took = elapsed { exited = watch.waitForExit(timeout: 5) }
        #expect(exited)
        #expect(took < 4)
    }

    @Test("V3: a sleeping child times out with false after about the timeout")
    func v003WaitTimesOut() throws {
        let (process, watch) = try launch("/bin/sleep", ["30"])
        defer { _ = watch.stop(process) }
        var exited = true
        let took = elapsed { exited = watch.waitForExit(timeout: 0.2) }
        #expect(!exited)
        #expect(took >= 0.15)
        #expect(took < 2)
    }

    @Test("V4: once the exit was seen every later wait answers true at once")
    func v004WaitIsSticky() throws {
        let (_, watch) = try launch("/usr/bin/true", [])
        #expect(watch.waitForExit(timeout: 5))
        var zero = false
        var long = false
        let took = elapsed {
            zero = watch.waitForExit(timeout: 0)
            long = watch.waitForExit(timeout: 10)
        }
        #expect(zero)
        #expect(long)
        #expect(took < 1)
    }

    @Test("V5: a zero timeout on a sleeping child is a non-blocking false")
    func v005ZeroTimeoutDoesNotBlock() throws {
        let (process, watch) = try launch("/bin/sleep", ["30"])
        defer { _ = watch.stop(process) }
        var exited = true
        let took = elapsed { exited = watch.waitForExit(timeout: 0) }
        #expect(!exited)
        #expect(took < 0.5)
    }

    @Test("V6: stop ends a child that honours SIGTERM within the grace")
    func v006StopTerminatesFirst() throws {
        let (process, watch) = try launch("/bin/sleep", ["30"])
        var stopped = false
        let took = elapsed { stopped = watch.stop(process) }
        #expect(stopped)
        #expect(took < ProcessExitWatch.terminationGrace)
        #expect(!process.isRunning)
    }

    @Test("V7: stop kills a child that ignores SIGTERM after the first grace")
    func v007StopKillsSecond() throws {
        // A short grace so the test does not wait out the production two
        // seconds; the escalation it proves is the same at any length.
        let grace: TimeInterval = 0.5
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        // `exec` keeps the ignored-SIGTERM disposition in the sleeping image,
        // and `echo` (a builtin, after the trap) says the trap is armed.
        process.arguments = ["-c", "trap '' TERM; echo armed; exec sleep 30"]
        let output = Pipe()
        process.standardOutput = output
        let watch = ProcessExitWatch(process, terminationGrace: grace)
        try process.run()
        // Wait for the shell to install the trap before the first signal lands.
        var said = Data()
        while !(String(bytes: said, encoding: .utf8) ?? "").contains("armed") {
            let chunk = output.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            said.append(chunk)
        }
        #expect(String(bytes: said, encoding: .utf8)?.contains("armed") == true)
        var stopped = false
        let took = elapsed { stopped = watch.stop(process) }
        #expect(stopped)
        #expect(took >= grace * 0.9)
        #expect(took < 2 * grace)
        #expect(!process.isRunning)
    }

    @Test("V8: stop on a process already seen to exit returns true at once")
    func v008StopAfterExit() throws {
        let (process, watch) = try launch("/usr/bin/true", [])
        #expect(watch.waitForExit(timeout: 5))
        var stopped = false
        let took = elapsed { stopped = watch.stop(process) }
        #expect(stopped)
        #expect(took < 0.5)
    }

    @Test("V9: a process that survives SIGKILL makes stop return false after about four seconds",
          .disabled("no portable setup produces a process that ignores SIGKILL (uninterruptible kernel wait)"))
    func v009StopFalseIsReal() {}

    @Test("V10: an exit nobody waited for yet is still reported by the next wait")
    func v010ExitRecordedOnceSeen() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        let watch = ProcessExitWatch(process)
        // Chain behind the watch's own handler, so the test knows the exit
        // has been delivered to the watch without anyone having waited on it.
        let delivered = DispatchSemaphore(value: 0)
        let watchHandler = process.terminationHandler
        process.terminationHandler = { finished in
            watchHandler?(finished)
            delivered.signal()
        }
        try process.run()
        #expect(delivered.wait(timeout: .now() + 5) == .success)
        #expect(watch.waitForExit(timeout: 0))
    }

    @Test("V11: the watch replaces a termination handler set earlier")
    func v011HandlerReplaces() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        let earlierCalled = EarlierHandlerFlag()
        process.terminationHandler = { _ in earlierCalled.mark() }
        let watch = ProcessExitWatch(process)
        try process.run()
        #expect(watch.waitForExit(timeout: 5))
        Thread.sleep(forTimeInterval: 0.2)
        #expect(!earlierCalled.value)
    }

    @Test("V12: no member returns an exit code or a termination reason",
          .disabled("source-inspection property: a unit test cannot enumerate the members of a type"))
    func v012NoStatusAPI() {}
}

private final class EarlierHandlerFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var called = false
    func mark() { lock.withLock { called = true } }
    var value: Bool { lock.withLock { called } }
}
