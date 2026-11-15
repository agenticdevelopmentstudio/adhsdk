import XCTest
@testable import AgenticDeveloperHubSDKCore

/// `ProcessLiveness.claudePid(inCwd:)` against real processes: a copy of
/// `/bin/sleep` named `claude`, started in a directory of its own.
final class ProcessLivenessTests: XCTestCase {
    private var dir: URL!
    private var children: [Process] = []

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("liveness-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: URL(fileURLWithPath: "/bin/sleep"),
                                         to: dir.appendingPathComponent("claude"))
    }

    override func tearDownWithError() throws {
        for child in children where child.isRunning { child.terminate(); child.waitUntilExit() }
        try? FileManager.default.removeItem(at: dir)
    }

    private func startClaude(in cwd: URL) throws -> Process {
        let child = Process()
        child.executableURL = dir.appendingPathComponent("claude")
        child.arguments = ["30"]
        child.currentDirectoryURL = cwd
        try child.run()
        children.append(child)
        return child
    }

    private func pid(in cwd: URL) -> pid_t? {
        // The child's cwd is set between fork and exec; give it a moment.
        for _ in 0..<50 {
            if let found = ProcessLiveness.claudePid(inCwd: cwd.path) { return found }
            usleep(20_000)
        }
        return nil
    }

    func testFindsTheOneClaudeInADirectory() throws {
        let child = try startClaude(in: dir)
        XCTAssertEqual(pid(in: dir), child.processIdentifier)
    }

    func testAnotherProcessInTheDirectoryIsNotClaude() throws {
        let other = Process()
        other.executableURL = URL(fileURLWithPath: "/bin/sleep")
        other.arguments = ["30"]
        other.currentDirectoryURL = dir
        try other.run()
        children.append(other)
        usleep(200_000)
        XCTAssertNil(ProcessLiveness.claudePid(inCwd: dir.path))
    }

    func testTwoClaudesInOneDirectoryAreAmbiguous() throws {
        let first = try startClaude(in: dir)
        XCTAssertEqual(pid(in: dir), first.processIdentifier)
        _ = try startClaude(in: dir)
        var answer: pid_t? = first.processIdentifier
        for _ in 0..<50 where answer != nil {
            answer = ProcessLiveness.claudePid(inCwd: dir.path)
            usleep(20_000)
        }
        XCTAssertNil(answer, "two candidates must be refused, never guessed between")
    }

    // MARK: - The matching rule, with the probes observed

    /// A shell parked in a dead network mount: `realpath` on its directory
    /// would block. It must never be resolved, whether or not a claude is found.
    func testAnUnrelatedProcessesDirectoryIsNeverResolved() {
        let dirs: [pid_t: String] = [10: "/Volumes/share", 11: "/Users/me/app", 12: "/Users/me/other"]
        let claudes: Set<pid_t> = [11, 12]
        var resolved: [String] = []
        let canonical: (String) -> String = { resolved.append($0); return $0 }

        let hit = ProcessLiveness.uniqueClaude(
            among: [10, 11, 12], inCwd: "/Users/me/app",
            directory: { dirs[$0] }, isClaude: { claudes.contains($0) }, canonical: canonical
        )
        let miss = ProcessLiveness.uniqueClaude(
            among: [10, 11, 12], inCwd: "/Users/me/elsewhere",
            directory: { dirs[$0] }, isClaude: { claudes.contains($0) }, canonical: canonical
        )

        XCTAssertEqual(hit, 11)
        XCTAssertNil(miss)
        XCTAssertFalse(resolved.contains("/Volumes/share"), "resolved: \(resolved)")
    }

    /// A claude whose kernel path is not the canonical spelling is still found
    /// by resolving it — the fallback only claude processes reach.
    func testAClaudeFoundOnlyThroughItsResolvedPathStillMatches() {
        let found = ProcessLiveness.uniqueClaude(
            among: [20, 21], inCwd: "/private/tmp/x",
            directory: { $0 == 20 ? "/tmp/x" : "/tmp/x" },
            isClaude: { $0 == 20 },
            canonical: { $0.hasPrefix("/tmp/") ? "/private" + $0 : $0 }
        )
        XCTAssertEqual(found, 20)
    }

    func testTwoClaudesMatchingOnlyThroughTheirResolvedPathsAreAmbiguous() {
        let found = ProcessLiveness.uniqueClaude(
            among: [30, 31], inCwd: "/private/tmp/x",
            directory: { _ in "/tmp/x" }, isClaude: { _ in true },
            canonical: { "/private" + $0 }
        )
        XCTAssertNil(found)
    }

    /// The `KERN_PROCARGS2` read is for processes already in the directory.
    func testOnlyProcessesInTheDirectoryAreAskedIfTheyAreClaude() {
        var asked: [pid_t] = []
        let found = ProcessLiveness.uniqueClaude(
            among: [40, 41, 42], inCwd: "/Users/me/app",
            directory: { $0 == 41 ? "/Users/me/app" : "/Users/me/other" },
            isClaude: { asked.append($0); return $0 == 41 },
            canonical: { $0 }
        )
        XCTAssertEqual(found, 41)
        XCTAssertEqual(asked, [41])
    }

    // MARK: - Session file, headless, canonical path and identity (vectors 8-17)

    private func sessionJSON(_ fields: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: fields)
    }

    func testV008_sessionFileIsReadOnlyForItsOwnPid() throws {
        let data = try sessionJSON(["pid": 4242, "sessionId": "abc"])
        XCTAssertEqual(ProcessLiveness.sessionId(fromSessionFile: data, pid: 4242), "abc")
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: data, pid: 4243))
        let empty = try sessionJSON(["pid": 4242, "sessionId": ""])
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: empty, pid: 4242))
        XCTAssertNil(ProcessLiveness.sessionId(fromSessionFile: Data("not json".utf8), pid: 4242))
    }

    func testV009_sessionFileIsFoundUnderTheConfigDirectory() throws {
        let sessions = dir.appendingPathComponent("sessions")
        try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        try sessionJSON(["pid": 777, "sessionId": "from-config-dir"])
            .write(to: sessions.appendingPathComponent("777.json"))
        let found = ProcessLiveness.currentSessionId(ofPid: 777, environment: ["CLAUDE_CONFIG_DIR": dir.path])
        XCTAssertEqual(found, "from-config-dir")
    }

    func testV010_sessionFileEntrypointDecidesHeadlessAndOutranksArguments() throws {
        let sdk = try sessionJSON(["entrypoint": "sdk-cli"])
        XCTAssertTrue(ProcessLiveness.isHeadless(argv: ["claude"], sessionFile: sdk))
        let terminal = try sessionJSON(["entrypoint": "cli"])
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: ["claude", "-p", "x"], sessionFile: terminal))
    }

    func testV011_printSwitchInArgumentsIsHeadlessWithoutASessionFile() {
        XCTAssertTrue(ProcessLiveness.isHeadless(argv: ["claude", "-p", "ping"], sessionFile: nil))
        XCTAssertTrue(ProcessLiveness.isHeadless(argv: ["node", "cli.js", "--print", "ping"], sessionFile: nil))
    }

    func testV012_switchAfterSeparatorAndDefaultsAreNotHeadless() {
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: ["claude", "--", "-p"], sessionFile: nil))
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: ["claude"], sessionFile: nil))
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: nil, sessionFile: nil))
    }

    func testV013_terminalAttachmentIsUnknownForAProcessThatIsNotClaude() {
        XCTAssertNil(ProcessLiveness.terminalAttachment(ofPid: 0))
        XCTAssertNil(ProcessLiveness.terminalAttachment(ofPid: ProcessInfo.processInfo.processIdentifier))
    }

    func testV014_liveClaudeProcessesIsNilOrAnArrayOfWellFormedEntries() {
        guard let live = ProcessLiveness.liveClaudeProcesses() else { return }
        for entry in live {
            XCTAssertGreaterThan(entry.pid, 0)
            XCTAssertTrue(entry.sessionId != nil || !entry.cwd.isEmpty,
                          "an entry with neither a session nor a directory must be dropped")
        }
    }

    func testV015_canonicalPathFallsBackToTheInputWhenThePathDoesNotExist() {
        XCTAssertEqual(ProcessLiveness.canonicalPath("/no/such/path"), "/no/such/path")
    }

    /// Starts a copy of `/bin/sleep` launched from `relativePath` under its own
    /// root, with its own working directory, and returns that directory.
    private func startCopy(at relativePath: String, root: String) throws -> URL {
        let base = dir.appendingPathComponent(root)
        let exe = base.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: exe.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: URL(fileURLWithPath: "/bin/sleep"), to: exe)
        let cwd = base.appendingPathComponent("cwd")
        try FileManager.default.createDirectory(at: cwd, withIntermediateDirectories: true)
        let child = Process()
        child.executableURL = exe
        child.arguments = ["30"]
        child.currentDirectoryURL = cwd
        try child.run()
        children.append(child)
        return cwd
    }

    func testV016_identityFollowsTheLaunchPathAndIsCaseSensitive() throws {
        let desktop = try startCopy(at: "Claude.app/Contents/MacOS/Claude", root: "desktop")
        let capitalised = try startCopy(at: "bin/Claude", root: "capital")
        let component = try startCopy(at: "claude/bin/tool", root: "component")
        let launcher = try startCopy(at: "bin/claude", root: "launcher")
        XCTAssertNotNil(pid(in: component), "a /claude/ path component counts as Claude")
        XCTAssertNotNil(pid(in: launcher), "a last component of exactly claude counts as Claude")
        XCTAssertNil(ProcessLiveness.claudePid(inCwd: desktop.path), "the desktop app is not the CLI")
        XCTAssertNil(ProcessLiveness.claudePid(inCwd: capitalised.path), "the match is case-sensitive")
    }

    func testV017_printSwitchMatchesWholeTokensBeforeTheSeparator() {
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: ["claude", "--print=x"], sessionFile: nil))
        XCTAssertFalse(ProcessLiveness.isHeadless(argv: ["claude", "-pv"], sessionFile: nil))
        XCTAssertTrue(ProcessLiveness.isHeadless(argv: ["claude", "--model", "-p"], sessionFile: nil))
    }
}
