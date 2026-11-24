@testable import AgenticDeveloperHubSDKCore
import Foundation
import XCTest

/// Conformance vectors for `HookCaptureCommand` that `HookCaptureTests` does not
/// cover: flag parsing, headless suppression by key, payload fallbacks, the
/// context snapshot and the token fallback. Vector ids are in the test names.
final class HookCaptureCommandConformanceTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hookcmd-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var configuration: ClaudeHookConfiguration {
        .adkdFixture(settingsURL: directory.appendingPathComponent("settings.json"))
    }

    private func build(
        event: String = "Stop", ppid: String? = nil, stdin: String = "{}", env: [String: String] = [:],
        claudePid: @escaping () -> Int32? = { nil },
        accountName: @escaping (String?) -> String = { _ in "" }
    ) -> [String: Any]? {
        HookCaptureCommand.buildEnvelope(
            eventType: event, ppidString: ppid, stdin: Data(stdin.utf8), env: env,
            claudePid: claudePid, accountName: accountName)
    }

    private func run(_ arguments: [String], drop: URL) -> Int32 {
        HookCaptureCommand.run(
            arguments: arguments, stdin: Data(#"{"session_id":"s1"}"#.utf8),
            environment: ["ADKD_DROP_DIR": drop.path], configuration: configuration,
            accountName: { _ in "" }, claudePid: { nil })
    }

    private func dropEnvelopes(_ drop: URL) throws -> [[String: Any]] {
        guard FileManager.default.fileExists(atPath: drop.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: drop, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { try JSONSerialization.jsonObject(with: Data(contentsOf: $0)) as? [String: Any] }
    }

    /// Sets (or unsets, for nil) live environment variables around `body`, then restores them.
    private func withLiveEnvironment(_ values: [String: String?], _ body: () throws -> Void) rethrows {
        var saved: [String: String?] = [:]
        for key in values.keys { saved[key] = ProcessInfo.processInfo.environment[key] }
        func apply(_ map: [String: String?]) {
            for (key, value) in map {
                if let value { setenv(key, value, 1) } else { unsetenv(key) }
            }
        }
        apply(values)
        defer { apply(saved) }
        try body()
    }

    private func context(_ envelope: [String: Any]?, _ group: String) -> [String: Any]? {
        (envelope?["context"] as? [String: Any])?[group] as? [String: Any]
    }

    // MARK: - Flags

    func testV003_eventFlagWithNoValueOrAnEmptyValueWritesNothing() throws {
        let drop = directory.appendingPathComponent("drop")
        XCTAssertEqual(run(["--event"], drop: drop), 0)
        XCTAssertEqual(run(["--event", ""], drop: drop), 0)
        XCTAssertTrue(try dropEnvelopes(drop).isEmpty)
    }

    func testV012_equalsFormIsNotParsed() throws {
        let drop = directory.appendingPathComponent("drop")
        XCTAssertEqual(run(["--event=Stop"], drop: drop), 0)
        XCTAssertTrue(try dropEnvelopes(drop).isEmpty)
    }

    func testV013_aFlagFollowedByAnotherFlagHasNoValue() throws {
        let drop = directory.appendingPathComponent("drop")
        XCTAssertEqual(run(["--event", "--ppid", "5"], drop: drop), 0)
        XCTAssertTrue(try dropEnvelopes(drop).isEmpty)
    }

    func testV022_theLastDuplicateFlagWins() throws {
        let drop = directory.appendingPathComponent("drop")
        XCTAssertEqual(run(["--event", "Stop", "--event", "Start"], drop: drop), 0)
        let envelopes = try dropEnvelopes(drop)
        XCTAssertEqual(envelopes.count, 1)
        XCTAssertEqual(envelopes.first?["event"] as? String, "Start")
    }

    func testV016_aDropDirectoryUnderARegularFileIsSwallowed() throws {
        let blocker = directory.appendingPathComponent("blocker")
        try Data("file".utf8).write(to: blocker)
        let drop = blocker.appendingPathComponent("sub")
        XCTAssertEqual(run(["--event", "Stop"], drop: drop), 0)
        var isDirectory: ObjCBool = false
        XCTAssertFalse(FileManager.default.fileExists(atPath: drop.path, isDirectory: &isDirectory))
        XCTAssertEqual(try Data(contentsOf: blocker), Data("file".utf8))
    }

    // MARK: - Headless and ppid

    func testV007_headlessIsDecidedByTheKeyEvenWhenEmpty() {
        XCTAssertNil(build(env: ["ADH_SDK_HEADLESS": ""]))
    }

    func testV009_aNonNumericPpidFallsThroughToClaudePid() throws {
        let envelope = build(event: "SessionStart", ppid: "abc", claudePid: { 4242 })
        let fields = try XCTUnwrap(envelope?["hook_data"] as? [String: Any])
        XCTAssertEqual(fields["pid"] as? Int, 4242)
    }

    // MARK: - Envelope

    func testV010_accountNameAndOauthEmailAreBothCarried() {
        let envelope = HookCaptureCommand.buildEnvelope(
            eventType: "Stop", ppidString: "1", stdin: Data(), env: [:], claudePid: { nil },
            accountName: { _ in "named@example.com" }, oauthEmail: { "x@example.com" })
        XCTAssertEqual(envelope?["account_email"] as? String, "named@example.com")
        XCTAssertEqual(envelope?["oauth_account_email"] as? String, "x@example.com")
        for key in ["event", "timestamp", "hook_data", "context"] { XCTAssertNotNil(envelope?[key], key) }
    }

    func testV011_unusablePayloadsLeaveOnlyTheLiftedKeys() throws {
        for stdin in ["", "not json", "[1,2]"] {
            let envelope = build(stdin: stdin)
            let fields = try XCTUnwrap(envelope?["hook_data"] as? [String: Any])
            XCTAssertEqual(Set(fields.keys), ["term_program", "term_session_id"], "stdin: \(stdin)")
        }
    }

    func testV017_timestampIsUTCWholeSeconds() throws {
        let stamp = try XCTUnwrap(build()?["timestamp"] as? String)
        XCTAssertNotNil(stamp.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"#, options: .regularExpression),
                        "unexpected timestamp: \(stamp)")
    }

    func testV018_contextProcessPpidIsTheFlagOrThisProcessesParent() throws {
        let flagged = context(build(ppid: "99"), "process")
        XCTAssertEqual(flagged?["ppid"] as? Int, 99)
        let unknown = context(build(ppid: nil, claudePid: { nil }), "process")
        XCTAssertEqual(unknown?["ppid"] as? Int, Int(getppid()))
        XCTAssertEqual(unknown?["pid"] as? Int, Int(getpid()))
    }

    func testV021_contextSystemCarriesHostnameOsAndArch() throws {
        let system = try XCTUnwrap(context(build(), "system"))
        XCTAssertFalse(try XCTUnwrap(system["hostname"] as? String).isEmpty)
        let osName = try XCTUnwrap(system["os"] as? String)
        XCTAssertEqual(osName.split(separator: " ", omittingEmptySubsequences: false).count, 2, osName)
        XCTAssertFalse(try XCTUnwrap(system["arch"] as? String).isEmpty)
    }

    // MARK: - Live environment

    func testV014_claudeBooleansFollowTheLiveEnvironment() {
        withLiveEnvironment(["CLAUDECODE": "TRUE", "CLAUDE_YOLO": "0"]) {
            let claude = context(build(), "claude")
            XCTAssertEqual(claude?["running"] as? Bool, true)
            XCTAssertEqual(claude?["yolo"] as? Bool, false)
        }
    }

    func testV015_unsetAndEmptyVariablesAreOmittedFromTheContext() {
        withLiveEnvironment(["LC_TERMINAL": nil, "TMPDIR": ""]) {
            let envelope = build()
            XCTAssertNil(context(envelope, "terminal")?["lc_terminal"])
            XCTAssertNil(context(envelope, "session")?["tmpdir"])
        }
    }

    // MARK: - Token recovery

    func testV019_theEnvironmentTokenIsUsedWhenTheTreeYieldsNone() throws {
        if ProcessEnv.oauthTokenWalkingUp(from: getppid()) != nil {
            throw XCTSkip("an ancestor of the test runner carries a real OAuth token, so the fallback is not reached")
        }
        nonisolated(unsafe) var received: String?
        nonisolated(unsafe) var called = false
        _ = build(env: ["CLAUDE_CODE_OAUTH_TOKEN": "tok"], accountName: { token in
            received = token
            called = true
            return ""
        })
        XCTAssertTrue(called)
        XCTAssertEqual(received, "tok")
    }

    func testV020_noTokenAnywhereCallsAccountNameWithNil() throws {
        if ProcessEnv.oauthTokenWalkingUp(from: getppid()) != nil {
            throw XCTSkip("an ancestor of the test runner carries a real OAuth token, so nil is not reached")
        }
        nonisolated(unsafe) var received: String? = "unset"
        _ = build(accountName: { token in
            received = token
            return ""
        })
        XCTAssertNil(received)
    }
}
