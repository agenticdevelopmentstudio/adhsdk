import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

@Suite("ProcessCommandRunner")
struct ProcessCommandRunnerTests {
    @Test("echo returns its output and status 0")
    func echoReturnsOutputAndZeroStatus() async {
        let result = await ProcessCommandRunner().run(["/bin/echo", "hi"])
        #expect(result.status == 0)
        #expect(result.output == "hi\n")
    }

    @Test("capture keeps stdout and stderr apart")
    func captureKeepsStdoutAndStderrApart() async {
        let result = await ProcessCommandRunner().capture(
            ["/bin/sh", "-c", "echo out; echo err 1>&2; exit 3"], environment: nil)
        #expect(result.status == 3)
        #expect(result.stdout == "out\n")
        #expect(result.stderr == "err\n")
    }

    @Test("capture replaces the environment")
    func captureReplacesTheEnvironment() async {
        let result = await ProcessCommandRunner().capture(["/usr/bin/env"], environment: ["ONLY_THIS": "1"])
        #expect(result.status == 0)
        #expect(result.stdout == "ONLY_THIS=1\n")
    }

    @Test("a name without a slash resolves through env")
    func bareNameResolvesThroughEnv() async {
        let result = await ProcessCommandRunner().run(["echo", "bare"])
        #expect(result.status == 0)
        #expect(result.output == "bare\n")
    }

    @Test("false returns a non-zero status")
    func falseReturnsNonZeroStatus() async {
        let result = await ProcessCommandRunner().run(["/usr/bin/false"])
        #expect(result.status != 0)
    }

    /// 200,000 bytes is well past the 64 KB pipe buffer: reading only after
    /// the child exits would deadlock.
    @Test("large output is returned in full")
    func largeOutputIsReturnedInFull() async {
        let result = await ProcessCommandRunner().run(["/usr/bin/head", "-c", "200000", "/dev/zero"])
        #expect(result.status == 0)
        #expect(result.output.utf8.count == 200_000)
    }

    @Test("a missing executable fails without crashing")
    func missingExecutableFailsWithoutCrashing() async {
        let result = await ProcessCommandRunner().run(["/nonexistent/definitely-not-here"])
        #expect(result.status != 0)
    }

    /// The backstop fires long before `sleep` would finish; the assertion is
    /// on the reported failure, never on elapsed time.
    @Test("a timed-out run reports failure")
    func timedOutRunReportsFailure() async {
        let result = await ProcessCommandRunner(backstop: 0.2).run(["/bin/sleep", "30"])
        #expect(result.status == -1)
        #expect(result.output.contains("timed out"))
    }

    /// A double that implements only `run` answers `capture` with the merged
    /// output as stdout.
    private struct RunOnly: CommandRunning {
        func run(_ argv: [String]) async -> (status: Int32, output: String) { (7, argv.joined(separator: " ")) }
    }

    @Test("the default capture is built on run")
    func defaultCaptureIsBuiltOnRun() async {
        let result = await RunOnly().capture(["a", "b"])
        #expect(result.status == 7)
        #expect(result.stdout == "a b")
        #expect(result.stderr == "")
    }

    @Test("V7: a missing executable reports status -1")
    func testV7_missingExecutableReportsMinusOne() async {
        let result = await ProcessCommandRunner().run(["/nonexistent/definitely-not-here"])
        #expect(result.status == -1)
    }

    @Test("V8: a timed-out run ends with the timeout text")
    func testV8_timedOutRunEndsWithTimeoutText() async {
        let result = await ProcessCommandRunner(backstop: 0.2).run(["/bin/sleep", "30"])
        #expect(result.status == -1)
        #expect(result.output.hasSuffix("\ntimed out after 0.2s"))
    }

    @Test("V10: an empty command reports failure from run and capture")
    func testV10_emptyCommandReportsFailure() async {
        let runResult = await ProcessCommandRunner().run([])
        #expect(runResult.status == -1)
        #expect(runResult.output == "empty command")
        let captured = await ProcessCommandRunner().capture([], environment: nil)
        #expect(captured.status == -1)
        #expect(captured.stdout.isEmpty)
        #expect(captured.stderr == "empty command")
    }

    @Test("V11: a name no directory holds is returned unchanged")
    func testV11_lookupMissReturnsName() {
        #expect(ProcessCommandRunner.resolve("nope", searchPath: "/usr/bin") == "nope")
    }

    @Test("V12: a name with a slash is returned verbatim")
    func testV12_slashNameIsVerbatim() {
        #expect(ProcessCommandRunner.resolve("/bin/echo", searchPath: "/nonexistent") == "/bin/echo")
    }

    @Test("V13: empty search entries are skipped and the default path is used")
    func testV13_lookupSkipsEmptyEntriesAndDefaultsPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let tool = directory.appendingPathComponent("tool")
        try Data("#!/bin/sh\n".utf8).write(to: tool)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)
        #expect(ProcessCommandRunner.resolve("tool", searchPath: "::\(directory.path)") == tool.path)

        let defaults = ["/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let expected = defaults.map { "\($0)/sh" }
            .first { FileManager.default.isExecutableFile(atPath: $0) } ?? "sh"
        #expect(ProcessCommandRunner.resolve("sh", searchPath: nil) == expected)
    }

    @Test("V14: a timed-out capture keeps stdout and appends the timeout text to stderr")
    func testV14_timedOutCaptureReportsFailure() async {
        let result = await ProcessCommandRunner(backstop: 0.2).capture(
            ["/bin/sh", "-c", "echo before; sleep 30"], environment: nil)
        #expect(result.status == -1)
        #expect(result.stdout == "before\n")
        #expect(result.stderr.hasSuffix("\ntimed out after 0.2s"))
    }

    @Test("V15: output that is not valid UTF-8 becomes an empty string")
    func testV15_undecodableOutputIsEmpty() async {
        let result = await ProcessCommandRunner().run(["/usr/bin/printf", "\\377"])
        #expect(result.status == 0)
        #expect(result.output.isEmpty)
    }

    @Test("V16: the default backstop is 600 seconds")
    func testV16_defaultBackstop() {
        #expect(ProcessCommandRunner().backstop == 600)
    }
}
