import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("PartnerProcess conformance") struct PartnerProcessConformanceTests {
    private func collect(_ stream: AsyncStream<ClaudeStreamMessage>) -> Task<[ClaudeStreamMessage], Never> {
        Task {
            var received: [ClaudeStreamMessage] = []
            for await message in stream { received.append(message) }
            return received
        }
    }

    private func drain(_ stream: AsyncStream<ClaudeStreamMessage>) async -> [ClaudeStreamMessage] {
        var received: [ClaudeStreamMessage] = []
        for await message in stream { received.append(message) }
        return received
    }

    private func channelError(_ body: () async throws -> Void) async -> SubprocessChannel.ChannelError? {
        do { try await body() } catch let error as SubprocessChannel.ChannelError { return error } catch {}
        return nil
    }

    @Test("V1: cat echoes a user message and terminate ends the stream")
    func testV1_catEchoAndTerminate() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        #expect(await process.isRunning)
        let consumer = collect(process.messages())
        try await process.send("x")
        try await Task.sleep(for: .milliseconds(300))
        await process.terminate()
        #expect(await process.isRunning == false)
        let received = await consumer.value
        #expect(received.first?.kind == .user && received.first?.blocks.first?.text == "x")
    }

    @Test("V2: a second messages call returns a finished stream")
    func testV2_secondMessagesCallIsFinished() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        _ = process.messages()
        #expect(await drain(process.messages()).isEmpty)
        await process.terminate()
    }

    @Test("V3: an undecodable line is skipped")
    func testV3_undecodableSkipped() async throws {
        let process = PartnerProcess(executable: "/bin/echo", arguments: ["not json"], environment: [:])
        try await process.start()
        #expect(await drain(process.messages()).isEmpty)
    }

    @Test("V4: a result line decodes")
    func testV4_resultLineDecodes() async throws {
        let line = #"{"type":"result","subtype":"success","is_error":false,"result":"ok","session_id":"s"}"#
        let process = PartnerProcess(executable: "/bin/echo", arguments: [line], environment: [:])
        try await process.start()
        let got = await drain(process.messages())
        #expect(got.count == 1 && got.first?.kind == .result && got.first?.resultText == "ok")
    }

    @Test("V5: send before start throws not launched")
    func testV5_sendBeforeStartThrows() async {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        let thrown = await channelError { try await process.send("x") }
        guard case .notLaunched? = thrown else {
            Issue.record("expected notLaunched, got \(String(describing: thrown))")
            return
        }
    }

    @Test("V6: a second start throws already launched")
    func testV6_startOnce() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        let thrown = await channelError { try await process.start() }
        await process.terminate()
        guard case .alreadyLaunched? = thrown else {
            Issue.record("expected alreadyLaunched, got \(String(describing: thrown))")
            return
        }
    }

    @Test("V7: a missing executable throws the launch failure")
    func testV7_launchFailure() async {
        let path = "/nonexistent-\(UUID().uuidString)/claude"
        let process = PartnerProcess(executable: path, arguments: [], environment: [:])
        let thrown = await channelError { try await process.start() }
        guard case .launchFailed? = thrown else {
            Issue.record("expected launchFailed, got \(String(describing: thrown))")
            return
        }
    }

    @Test("V8: terminate before start returns and nothing runs")
    func testV8_terminateUnstarted() async {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        await process.terminate()
        #expect(await process.isRunning == false)
    }

    @Test("V9: stderr text carries what the process wrote")
    func testV9_standardErrorText() async throws {
        let process = PartnerProcess(executable: "/bin/sh", arguments: ["-c", "echo boom >&2"],
                                     environment: [:])
        try await process.start()
        _ = await drain(process.messages())
        #expect(await process.standardErrorText().contains("boom"))
    }

    @Test("V10: two sends come back as two user messages in order")
    func testV10_twoSendsInOrder() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        let consumer = collect(process.messages())
        try await process.send("a")
        try await process.send("b")
        try await Task.sleep(for: .milliseconds(300))
        await process.terminate()
        let received = await consumer.value
        #expect(received.map(\.kind) == [.user, .user])
        #expect(received.map { $0.blocks.first?.text } == ["a", "b"])
    }

    @Test("V11: the child gets the given environment only")
    func testV11_environmentReplace() async throws {
        // A variable the parent already has, read rather than `setenv`'d: the
        // process environment is one table shared with every suite running
        // beside this one, and a `setenv` reallocates it under any thread that
        // is copying it to spawn a child. `HOME` when set (`/bin/sh` never
        // sets it itself); otherwise any shell-safe name `sh` does not set.
        let parent = ProcessInfo.processInfo.environment
        let shellSet: Set<String> = [
            "FOO", "PATH", "PWD", "OLDPWD", "SHLVL", "_", "IFS", "PS1", "PS2", "PS4", "OPTIND", "PPID"
        ]
        let candidates = parent.keys.filter { key in
            !shellSet.contains(key)
                && key.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
        }
        let preferred: String? = parent["HOME"] != nil ? "HOME" : candidates.sorted().first
        let inherited = try #require(preferred, "the test process has no environment variable to withhold")
        let script = #"echo "{\"type\":\"result\",\"subtype\":\"success\",\"is_error\":false,"#
            + #"\"result\":\"$FOO-${"# + inherited + #"-unset}\",\"session_id\":\"s\"}""#
        let process = PartnerProcess(executable: "/bin/sh", arguments: ["-c", script],
                                     environment: ["FOO": "a", "PATH": "/bin:/usr/bin"])
        try await process.start()
        let got = await drain(process.messages())
        #expect(got.count == 1 && got.first?.kind == .result && got.first?.resultText == "a-unset")
    }

    @Test("V12: a message decoded before any consumer exists is kept")
    func testV12_buffering() async throws {
        let process = PartnerProcess(executable: "/bin/cat", arguments: [], environment: [:])
        try await process.start()
        try await process.send("x")
        try await Task.sleep(for: .milliseconds(300))
        let consumer = collect(process.messages())
        await process.terminate()
        let received = await consumer.value
        #expect(received.first?.kind == .user && received.first?.blocks.first?.text == "x")
    }
}
