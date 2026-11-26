@testable import AgenticDeveloperHubSDKCore
import Foundation
import XCTest

/// Conformance vectors `capture-006` to `capture-031` for `StatusLineCapture`
/// that `HookCaptureTests` and `DetachedProcessTests` do not already name.
/// Drop files and locks go to temporary directories; nothing touches the real
/// `~/.claude`.
final class StatusLineCaptureConformanceTests: XCTestCase {

    private var directory: URL!
    private let payload = Data(#"{"session_id":"sl-1","cwd":"/nonexistent-dir"}"#.utf8)
    /// A pid that cannot exist (macOS pids stop at 99999): the token walk from it finds nothing.
    private let deadPid = "2000000"

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("slcapture-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var config: ClaudeHookConfiguration {
        .adkdFixture(settingsURL: directory.appendingPathComponent("settings.json"))
    }

    private var dropPath: String { directory.appendingPathComponent("drop").path }

    private func lockFileNames() -> Set<String> {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(names.filter { $0.hasPrefix("adkd-statusline-feed-") })
    }

    /// True when this test process's own ancestry already holds an OAuth token,
    /// which `HookCaptureCommand.buildEnvelope` prefers over the injected one.
    private var ancestryHoldsToken: Bool {
        ProcessEnv.oauthTokenWalkingUp(from: getppid()) != nil
    }

    private func runFeed(
        captureOnly: Bool, environment: [String: String],
        seen: @escaping @Sendable (String?) -> Void,
        render: (Data, String?) -> Int32 = { _, _ in 0 }
    ) -> Int32 {
        StatusLineCapture.run(
            captureOnly: captureOnly, payload: payload, environment: environment, configuration: config,
            post: { _, _ in false }, accountName: { token in seen(token); return "" },
            lockDirectory: directory, render: render)
    }

    // MARK: - Parent pid and injected environment

    func testCapture006_feedOnceSkipsWhenTheSessionLockIsHeld() throws {
        let session = "held-\(UUID().uuidString)"
        let lock = try XCTUnwrap(FeedLock.acquire(sessionID: session, name: "adkd", directory: directory))
        defer {
            lock.release()
            try? FileManager.default.removeItem(at: FeedLock.fileURL(sessionID: session, name: "adkd",
                                                                     directory: directory))
        }
        nonisolated(unsafe) var posted = 0
        let body = Data("{\"session_id\":\"\(session)\"}".utf8)
        StatusLineCapture.feedOnce(
            payload: body, token: nil, environment: [:], configuration: config,
            post: { _, _ in posted += 1; return true }, accountName: { _ in "" }, oauthEmail: { "" },
            lockDirectory: directory)
        XCTAssertEqual(posted, 0)
    }

    func testCapture007_unparsablePayloadFeedsWithoutALock() {
        let before = lockFileNames()
        nonisolated(unsafe) var events: [String] = []
        StatusLineCapture.feedOnce(
            payload: Data("not json".utf8), token: nil, environment: [:], configuration: config,
            post: { event, _ in events.append(event); return true }, accountName: { _ in "" }, oauthEmail: { "" },
            lockDirectory: directory)
        XCTAssertEqual(events, ["StatusLine"])
        XCTAssertEqual(lockFileNames(), before)
    }

    func testCapture010_zeroAndNegativeParentValuesFallBack() {
        let variable = StatusLineCapture.parentPIDVariable
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [variable: "0"]), getppid())
        XCTAssertEqual(StatusLineCapture.parentPID(environment: [variable: "-5"]), getppid())
    }

    func testCapture011_nilTokenLeavesEnvironmentUnchanged() {
        XCTAssertEqual(StatusLineCapture.injected(["A": "1"], token: nil), ["A": "1"])
    }

    func testCapture012_tokenReplacesAnExistingValue() {
        let result = StatusLineCapture.injected(["A": "1", "CLAUDE_CODE_OAUTH_TOKEN": "old"], token: "new")
        XCTAssertEqual(result, ["A": "1", "CLAUDE_CODE_OAUTH_TOKEN": "new"])
    }

    // MARK: - Detached feed

    func testCapture013_foreignExecutableDoesNotDetach() {
        let started = StatusLineCapture.detachFeed(
            payload: payload, token: nil, parent: 1, environment: [:],
            configuration: .adkdFixture(helperPath: "/x/helper", settingsURL: directory),
            executable: "/y/other-tool")
        XCTAssertFalse(started)
    }

    func testCapture014_missingExecutableDoesNotDetach() {
        let started = StatusLineCapture.detachFeed(
            payload: payload, token: nil, parent: 1, environment: [:],
            configuration: .adkdFixture(helperPath: "/x/helper", settingsURL: directory),
            executable: nil)
        XCTAssertFalse(started)
    }

    func testCapture015_detachStartsTheHelperWithPayloadAndEnvironment() throws {
        let helper = directory.appendingPathComponent("helper")
        let out = directory.appendingPathComponent("out")
        let script = """
        #!/bin/sh
        {
        echo "$*"
        echo "$CLAUDE_CODE_OAUTH_TOKEN $CLAUDEHELPERS_STATUSLINE_PARENT_PID"
        /bin/cat
        } > "$OUT.tmp"
        /bin/mv "$OUT.tmp" "$OUT"
        """
        try script.write(to: helper, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helper.path)
        let started = StatusLineCapture.detachFeed(
            payload: Data("body\n".utf8), token: "t", parent: 99, environment: ["OUT": out.path],
            configuration: .adkdFixture(helperPath: "/x/helper", settingsURL: directory),
            executable: helper.path)
        XCTAssertTrue(started)
        let deadline = Date().addingTimeInterval(10)
        while !FileManager.default.fileExists(atPath: out.path) && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        let text = try String(contentsOf: out, encoding: .utf8)
        XCTAssertEqual(text, "statusline --capture-only\nt 99\nbody\n")
    }

    // MARK: - Token recovery

    func testCapture017_carriedTokenUsedWhenTheWalkFindsNone() throws {
        try XCTSkipIf(ancestryHoldsToken, "this process's own ancestry holds an OAuth token")
        nonisolated(unsafe) var seen: [String?] = []
        let environment = [
            "CLAUDE_CODE_OAUTH_TOKEN": "carried", StatusLineCapture.parentPIDVariable: deadPid,
            "ADKD_DROP_DIR": dropPath
        ]
        _ = runFeed(captureOnly: true, environment: environment, seen: { seen.append($0) })
        XCTAssertEqual(seen, ["carried"])
    }

    func testCapture018_feedReturnsAtTheTwentySecondDeadline() throws {
        throw XCTSkip("needs 20 real seconds; feedDeadline is a fixed constant with no injected clock")
    }

    func testCapture019_postedPayloadCarriesTheGitFingerprint() throws {
        let repo = directory.appendingPathComponent("repo")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        try runTool("/usr/bin/git", ["-C", repo.path, "init", "-q"])
        try runTool("/usr/bin/git", ["-C", repo.path, "-c", "user.name=t", "-c", "user.email=t@example.com",
                                     "commit", "-q", "--allow-empty", "-m", "first"])
        let body = Data("{\"session_id\":\"s\",\"cwd\":\"\(repo.path)\"}".utf8)
        nonisolated(unsafe) var posted = Data()
        StatusLineCapture.feed(
            payload: body, token: nil, environment: [:], configuration: config,
            post: { _, data in posted = data; return true }, accountName: { _ in "" }, oauthEmail: { "" })
        let actual = try fingerprint(of: posted)
        let expected = try fingerprint(of: GitContextFingerprint.enriched(payload: body))
        XCTAssertGreaterThan(actual.count, 0)
        XCTAssertEqual(actual, expected)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: posted) as? [String: Any])
        XCTAssertEqual(object["session_id"] as? String, "s")
    }

    func testCapture020_unwritableDropDirectoryEndsQuietly() throws {
        let blocker = directory.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let target = blocker.appendingPathComponent("drop")
        StatusLineCapture.feed(
            payload: payload, token: nil, environment: ["ADKD_DROP_DIR": target.path],
            configuration: config, post: { _, _ in false }, accountName: { _ in "" }, oauthEmail: { "" })
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names, ["blocker"])
    }

    func testCapture021_renderGetsPayloadAndTokenBeforeTheFeedStarts() {
        nonisolated(unsafe) var order: [String] = []
        nonisolated(unsafe) var renderedPayload: Data?
        nonisolated(unsafe) var renderedToken: String? = "unset"
        let status = StatusLineCapture.run(
            captureOnly: false, payload: payload,
            environment: [StatusLineCapture.parentPIDVariable: deadPid], configuration: config,
            post: { _, _ in order.append("post"); return true }, accountName: { _ in "" },
            lockDirectory: directory, render: { data, token in
                order.append("render")
                renderedPayload = data
                renderedToken = token
                return 0
            })
        XCTAssertEqual(status, 0)
        XCTAssertEqual(order, ["render", "post"])
        XCTAssertEqual(renderedPayload, payload)
        XCTAssertNil(renderedToken)
    }

    func testCapture022_walkedTokenBeatsTheCarriedOne() throws {
        try XCTSkipIf(ancestryHoldsToken, "this process's own ancestry holds an OAuth token")
        let child = Process()
        child.executableURL = URL(fileURLWithPath: "/bin/sleep")
        child.arguments = ["30"]
        child.environment = ["CLAUDE_CODE_OAUTH_TOKEN": "walked"]
        try child.run()
        defer { child.terminate() }
        // Until the child has exec'd, its process arguments are still the test runner's, so wait for the
        // token to become readable before walking up from it.
        let deadline = Date().addingTimeInterval(2)
        // (Polled through environment(forPid:), which is uncached; the walk caches its answer per pid.)
        func childToken() -> String? {
            ProcessEnv.environment(forPid: child.processIdentifier)?["CLAUDE_CODE_OAUTH_TOKEN"]
        }
        while childToken() != "walked", Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
        try XCTSkipIf(childToken() != "walked", "the child's environment never became readable")
        ProcessEnv.resetCacheForTesting()
        nonisolated(unsafe) var seen: [String?] = []
        let environment = [
            "CLAUDE_CODE_OAUTH_TOKEN": "carried",
            StatusLineCapture.parentPIDVariable: String(child.processIdentifier),
            "ADKD_DROP_DIR": dropPath
        ]
        _ = runFeed(captureOnly: true, environment: environment, seen: { seen.append($0) })
        XCTAssertEqual(seen, ["walked"])
    }

    func testCapture023_carriedTokenIgnoredWhenNotCaptureOnly() {
        nonisolated(unsafe) var renderedToken: String? = "unset"
        _ = StatusLineCapture.run(
            captureOnly: false, payload: payload,
            environment: ["CLAUDE_CODE_OAUTH_TOKEN": "carried", StatusLineCapture.parentPIDVariable: deadPid],
            configuration: config, post: { _, _ in true }, accountName: { _ in "" },
            lockDirectory: directory, render: { _, token in renderedToken = token; return 0 })
        XCTAssertNil(renderedToken)
    }

    func testCapture024_captureOnlyPrintsNothingAndFeedsInline() throws {
        let captured = directory.appendingPathComponent("stdout.txt")
        FileManager.default.createFile(atPath: captured.path, contents: nil)
        fflush(stdout)
        let saved = dup(STDOUT_FILENO)
        let target = open(captured.path, O_WRONLY)
        dup2(target, STDOUT_FILENO)
        nonisolated(unsafe) var posts = 0
        let status = StatusLineCapture.run(
            captureOnly: true, payload: payload, environment: ["ADKD_DROP_DIR": dropPath],
            configuration: config, post: { _, _ in posts += 1; return true }, accountName: { _ in "" },
            lockDirectory: directory, render: { _, _ in 5 })
        fflush(stdout)
        dup2(saved, STDOUT_FILENO)
        close(saved)
        close(target)
        XCTAssertEqual(status, 0)
        XCTAssertEqual(posts, 1)
        XCTAssertEqual(try Data(contentsOf: captured), Data())
    }

    func testCapture025_detachedFeedIsPreferredOverInline() throws {
        throw XCTSkip("the detach-succeeds branch needs the test process to be the configured helper binary")
    }

    func testCapture026_headlessEnvironmentWritesNoDropFile() {
        StatusLineCapture.feed(
            payload: payload, token: nil,
            environment: ["ADH_SDK_HEADLESS": "1", "ADKD_DROP_DIR": dropPath],
            configuration: config, post: { _, _ in false }, accountName: { _ in "" }, oauthEmail: { "" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: dropPath))
    }

    func testCapture027_givenTokenReachesTheDropEnvelope() throws {
        try XCTSkipIf(ancestryHoldsToken, "this process's own ancestry holds an OAuth token")
        nonisolated(unsafe) var seen: [String?] = []
        StatusLineCapture.feed(
            payload: payload, token: "t", environment: ["ADKD_DROP_DIR": dropPath], configuration: config,
            post: { _, _ in false }, accountName: { seen.append($0); return "" }, oauthEmail: { "" })
        XCTAssertEqual(seen, ["t"])
        let files = try FileManager.default.contentsOfDirectory(atPath: dropPath)
        XCTAssertEqual(files.filter { $0.hasSuffix(".json") }.count, 1)
    }

    func testCapture028_lockFreeAfterTheDeadlineWhileWorkRuns() throws {
        throw XCTSkip("needs more than the 20 second feedDeadline of real time")
    }

    func testCapture029_tokenWalkStopsAtSixteenHops() throws {
        throw XCTSkip("needs a live 17-deep process chain and a count of process-table reads")
    }

    func testCapture030_feedRunsOnAGlobalQueueThread() {
        nonisolated(unsafe) var feedThreadWasMain = true
        nonisolated(unsafe) var sameThread = true
        let caller = ObjectIdentifier(Thread.current)
        StatusLineCapture.feedOnce(
            payload: Data("not json".utf8), token: nil, environment: [:], configuration: config,
            post: { _, _ in
                feedThreadWasMain = Thread.isMainThread
                sameThread = ObjectIdentifier(Thread.current) == caller
                return true
            }, accountName: { _ in "" }, oauthEmail: { "" },
            lockDirectory: directory)
        XCTAssertFalse(feedThreadWasMain)
        XCTAssertFalse(sameThread)
    }

    func testCapture031_sigpipeIsIgnoredAfterRun() {
        let original = signal(SIGPIPE, SIG_DFL)
        defer { signal(SIGPIPE, original) }
        _ = StatusLineCapture.run(
            captureOnly: true, payload: payload, environment: ["ADKD_DROP_DIR": dropPath],
            configuration: config, post: { _, _ in true }, accountName: { _ in "" },
            lockDirectory: directory, render: { _, _ in 0 })
        let current = signal(SIGPIPE, SIG_IGN)
        XCTAssertEqual(unsafeBitCast(current, to: Int.self), unsafeBitCast(SIG_IGN, to: Int.self))
    }

    // MARK: - Helpers

    private func runTool(_ path: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }

    /// The posted payload's fingerprint object without its `sampled_at` clock reading.
    private func fingerprint(of data: Data) throws -> NSDictionary {
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var inner = (object[GitContextFingerprint.payloadKey] as? [String: Any]) ?? [:]
        inner.removeValue(forKey: "sampled_at")
        return NSDictionary(dictionary: inner)
    }
}
