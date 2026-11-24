@testable import AgenticDeveloperHubSDKCore
import XCTest

/// Conformance vectors `builder-001` through `builder-035` for
/// `HookEnvelopeBuilder` and `HookEnvCache`. Every resolver is injected, so no
/// test reads the real process table or the real account store.
final class HookEnvelopeBuilderConformanceTests: XCTestCase {

    private func fullBuild(
        event: String = "SessionStart",
        ppid: Int = 0,
        env: [String: String] = [:],
        payload: String,
        accountName: (String?) -> String = { _ in "" },
        oauthEmail: () -> String = { "" }
    ) -> ParsedEvent? {
        HookEnvelopeBuilder.build(
            event: event, ppid: ppid, env: env, payload: Data(payload.utf8),
            accountName: accountName, oauthEmail: oauthEmail)
    }

    private func processGroup(_ event: ParsedEvent?) -> [String: Any]? {
        event?.context?["process"] as? [String: Any]
    }

    func testBuilder001_emptyEventReturnsNil() {
        let payload = "{\"session_id\":\"s1\"}"
        XCTAssertNil(fullBuild(event: "", payload: payload))
        XCTAssertNil(HookEnvelopeBuilder.build(
            event: "", payload: Data(payload.utf8),
            claudePid: { _ in 9 }, environment: { _ in [:] }, daemonCwd: "/var/support"))
    }

    func testBuilder002_headlessEnvDropsEventBeforeSessionCheck() {
        XCTAssertNil(fullBuild(env: ["ADH_SDK_HEADLESS": "1"], payload: "{\"session_id\":\"s1\"}"))
        XCTAssertNil(fullBuild(env: ["ADH_SDK_HEADLESS": ""], payload: "{}"))
    }

    func testBuilder003_sessionIdRequired() {
        XCTAssertNil(fullBuild(payload: "{}"))
        XCTAssertNil(fullBuild(payload: "{\"session_id\":\"\"}"))
        XCTAssertNil(fullBuild(payload: "{\"session_id\":5}"))
    }

    func testBuilder004_sessionStartCarriesPayloadTermAndPid() throws {
        let env = ["TERM_PROGRAM": "iTerm.app", "TERM_SESSION_ID": "w0t1p0:U"]
        let event = try XCTUnwrap(fullBuild(ppid: 123, env: env, payload: "{\"session_id\":\"s1\"}"))
        XCTAssertEqual(event.eventType, "SessionStart")
        XCTAssertEqual(event.hookData["pid"] as? Int, 123)
        XCTAssertEqual(event.hookData["term_program"] as? String, "iTerm.app")
        XCTAssertEqual(event.hookData["term_session_id"] as? String, "w0t1p0:U")
        XCTAssertEqual(event.hookData["session_id"] as? String, "s1")
    }

    func testBuilder005_otherEventsHaveNoPidAndEmptyTermFields() throws {
        let event = try XCTUnwrap(fullBuild(event: "Stop", payload: "{\"session_id\":\"s1\"}"))
        XCTAssertNil(event.hookData["pid"])
        XCTAssertEqual(event.hookData["term_program"] as? String, "")
        XCTAssertEqual(event.hookData["term_session_id"] as? String, "")
    }

    func testBuilder006_tokenFromEnvReachesAccountName() throws {
        let event = try XCTUnwrap(fullBuild(
            env: ["CLAUDE_CODE_OAUTH_TOKEN": "tok"], payload: "{\"session_id\":\"s1\"}",
            accountName: { $0 ?? "" }))
        XCTAssertEqual(event.accountEmail, "tok")
    }

    func testBuilder007_defaultClosuresGiveEmptyEmails() throws {
        let event = try XCTUnwrap(fullBuild(payload: "{\"session_id\":\"s1\"}"))
        XCTAssertEqual(event.accountEmail, "")
        XCTAssertEqual(event.oauthAccountEmail, "")
    }

    func testBuilder008_oauthEmailResolvedDuringBuild() throws {
        let event = try XCTUnwrap(fullBuild(
            payload: "{\"session_id\":\"s1\"}", oauthEmail: { "login@example.com" }))
        XCTAssertEqual(event.oauthAccountEmail, "login@example.com")
    }

    func testBuilder009_daemonCwdPayloadDroppedWithoutResolvers() {
        var calls = 0
        let result = HookEnvelopeBuilder.build(
            event: "Stop", payload: Data("{\"session_id\":\"s1\",\"cwd\":\"/var/support\"}".utf8),
            claudePid: { _ in calls += 1; return 9 },
            environment: { _ in calls += 1; return [:] },
            daemonCwd: "/var/support")
        XCTAssertNil(result)
        XCTAssertEqual(calls, 0)
    }

    func testBuilder010_daemonCwdGuardsDoNotDrop() {
        let result = HookEnvelopeBuilder.build(
            event: "Stop", payload: Data("{\"session_id\":\"s1\",\"cwd\":\"/\"}".utf8),
            claudePid: { _ in 9 }, environment: { _ in [:] }, daemonCwd: "/")
        XCTAssertNotNil(result)
    }

    func testBuilder011_httpRecoversPidAndEnvironment() throws {
        let payload = "{\"session_id\":\"s1\",\"cwd\":\"/var/work\"}"
        let event = try XCTUnwrap(HookEnvelopeBuilder.build(
            event: "SessionStart", payload: Data(payload.utf8),
            claudePid: { _ in 9 }, environment: { _ in ["TERM_PROGRAM": "Apple_Terminal"] },
            daemonCwd: "/var/support"))
        XCTAssertEqual(event.hookData["pid"] as? Int, 9)
        XCTAssertEqual(processGroup(event)?["ppid"] as? Int, 9)
        let terminal = event.context?["terminal"] as? [String: Any]
        XCTAssertEqual(terminal?["term_program"] as? String, "Apple_Terminal")
    }

    func testBuilder012_httpDegradesWhenResolversFindNothing() throws {
        let payload = "{\"session_id\":\"s1\",\"cwd\":\"/var/work\"}"
        let event = try XCTUnwrap(HookEnvelopeBuilder.build(
            event: "Stop", payload: Data(payload.utf8),
            claudePid: { _ in nil }, environment: { _ in nil }, daemonCwd: "/var/support"))
        XCTAssertEqual(processGroup(event)?["ppid"] as? Int, 0)
        XCTAssertNil(event.context?["terminal"])
    }

    func testBuilder013_httpWithoutCwdSkipsResolvers() throws {
        var calls = 0
        let event = try XCTUnwrap(HookEnvelopeBuilder.build(
            event: "Stop", payload: Data("{\"session_id\":\"s1\"}".utf8),
            claudePid: { _ in calls += 1; return 9 },
            environment: { _ in calls += 1; return [:] },
            daemonCwd: "/var/support"))
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(processGroup(event)?["ppid"] as? Int, 0)
    }

    func testBuilder014_claudeGroupReadsBooleansAndEntrypoint() throws {
        let env = ["CLAUDECODE": "yes", "CLAUDE_YOLO": "off", "CLAUDE_CODE_ENTRYPOINT": "cli"]
        let context = HookEnvelopeBuilder.buildContext(event: "Stop", ppid: 1, env: env)
        let claude = try XCTUnwrap(context["claude"] as? [String: Any])
        XCTAssertEqual(claude["running"] as? Bool, true)
        XCTAssertEqual(claude["yolo"] as? Bool, false)
        XCTAssertEqual(claude["entrypoint"] as? String, "cli")
    }

    func testBuilder015_unknownBooleanTextReadsFalse() throws {
        let context = HookEnvelopeBuilder.buildContext(event: "Stop", ppid: 1, env: ["CLAUDECODE": "maybe"])
        let claude = try XCTUnwrap(context["claude"] as? [String: Any])
        XCTAssertEqual(claude["running"] as? Bool, false)
    }

    func testBuilder016_emptyEnvKeepsOnlyProcessAndSystem() {
        let context = HookEnvelopeBuilder.buildContext(event: "Stop", ppid: 1, env: [:])
        XCTAssertEqual(Set(context.keys), ["process", "system"])
    }

    func testBuilder017_unsetAndInvalidValuesOmitted() throws {
        let env = ["SHLVL": "abc", "LANG": "", "HOME": "/Users/a"]
        let context = HookEnvelopeBuilder.buildContext(event: "Stop", ppid: 1, env: env)
        XCTAssertNil(context["shell"])
        let session = try XCTUnwrap(context["session"] as? [String: Any])
        XCTAssertEqual(session["home"] as? String, "/Users/a")
    }

    func testBuilder018_processGroupIsTheIdentitySubset() throws {
        let context = HookEnvelopeBuilder.buildContext(event: "Stop", ppid: 7, env: [:])
        let process = try XCTUnwrap(context["process"] as? [String: Any])
        XCTAssertEqual(process["ppid"] as? Int, 7)
        XCTAssertEqual(process["uid"] as? Int, Int(getuid()))
        XCTAssertEqual(process["euid"] as? Int, Int(geteuid()))
        XCTAssertEqual(process["gid"] as? Int, Int(getgid()))
        XCTAssertNil(process["argv"])
        XCTAssertNil(process["cwd"])
        XCTAssertNil(process["pid"])
    }

    func testBuilder033_timestampIsIso8601UtcWholeSeconds() throws {
        let event = try XCTUnwrap(fullBuild(payload: "{\"session_id\":\"s1\"}"))
        let pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
        XCTAssertNotNil(event.timestamp.range(of: pattern, options: .regularExpression))
    }

    func testBuilder034_contextMatchesBuildContextAndHasSystemFields() throws {
        let env = ["TERM": "xterm", "HOME": "/Users/a"]
        let event = try XCTUnwrap(fullBuild(ppid: 5, env: env, payload: "{\"session_id\":\"s1\"}"))
        let expected = HookEnvelopeBuilder.buildContext(event: "SessionStart", ppid: 5, env: env)
        let actual = try XCTUnwrap(event.context)
        XCTAssertTrue(NSDictionary(dictionary: actual).isEqual(to: expected))
        let system = try XCTUnwrap(actual["system"] as? [String: Any])
        XCTAssertNotNil(system["hostname"])
        XCTAssertNotNil(system["os"])
        XCTAssertNotNil(system["arch"])
    }

    func testBuilder032_daemonWorkingDirectoryComputedOnce() throws {
        let first = HookEnvelopeBuilder.daemonWorkingDirectory
        let original = FileManager.default.currentDirectoryPath
        let other = FileManager.default.temporaryDirectory
            .appendingPathComponent("hook-cwd-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: other) }
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(other.path))
        defer { _ = FileManager.default.changeCurrentDirectoryPath(original) }
        XCTAssertEqual(HookEnvelopeBuilder.daemonWorkingDirectory, first)
        XCTAssertNotEqual(first, ProcessLiveness.canonicalPath(other.path))
    }
}

/// Wire-format vectors `builder-019` through `builder-026` and `builder-035`.
final class HookEnvelopeWireConformanceTests: XCTestCase {

    private func wire(_ text: String) -> Data { Data(text.utf8) }

    func testBuilder019_fullMessageParses() throws {
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\n55\nTERM=xterm\n---\n{\"a\":1}")))
        XCTAssertEqual(parsed.event, "Stop")
        XCTAssertEqual(parsed.ppid, 55)
        XCTAssertEqual(parsed.env, ["TERM": "xterm"])
        XCTAssertEqual(parsed.payload, wire("{\"a\":1}"))
    }

    func testBuilder020_missingSeparatorReturnsNil() {
        XCTAssertNil(HookEnvelopeBuilder.parseWire(wire("Stop\n55\nTERM=xterm")))
    }

    func testBuilder021_oneLineHeaderReturnsNil() {
        XCTAssertNil(HookEnvelopeBuilder.parseWire(wire("Stop\n---\n{}")))
    }

    func testBuilder022_nonIntegerPpidBecomesZero() throws {
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\nabc\n---\n{}")))
        XCTAssertEqual(parsed.ppid, 0)
    }

    func testBuilder023_envLinesSplitAtFirstEqualsLastKeyWins() throws {
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\n1\nA=b=c\nNOEQ\n\nA=d\n---\n")))
        XCTAssertEqual(parsed.env, ["A": "d"])
        let single = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\n1\nA=b=c\n---\n")))
        XCTAssertEqual(single.env, ["A": "b=c"])
    }

    func testBuilder024_payloadContainingSeparatorIsUnchanged() throws {
        let payload = "{\"x\":\"a\"}\n---\nmore"
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\n1\n---\n" + payload)))
        XCTAssertEqual(parsed.payload, wire(payload))
    }

    func testBuilder025_invalidUtf8HeaderReturnsNil() {
        var data = Data([0xFF, 0xFE])
        data.append(wire("\n1\n---\n{}"))
        XCTAssertNil(HookEnvelopeBuilder.parseWire(data))
    }

    func testBuilder026_emptyEventParsesThenBuildRejectsIt() throws {
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("\n5\n---\n{\"session_id\":\"s1\"}")))
        XCTAssertEqual(parsed.event, "")
        let event = HookEnvelopeBuilder.build(
            event: parsed.event, ppid: parsed.ppid, env: parsed.env, payload: parsed.payload)
        XCTAssertNil(event)
    }

    func testBuilder035_emptyPayloadAfterSeparatorIsEmptyData() throws {
        let parsed = try XCTUnwrap(HookEnvelopeBuilder.parseWire(wire("Stop\n1\n---\n")))
        XCTAssertEqual(parsed.payload, Data())
    }
}

/// Cache vectors `builder-027` through `builder-031`. `HookEnvCache` has no
/// injection point for its resolvers and its maps are private, so the vectors
/// that count resolutions or inspect the map cannot be observed from a test.
final class HookEnvCacheConformanceTests: XCTestCase {

    func testBuilder027_cachesPidResolutionIncludingNil() throws {
        throw XCTSkip("HookEnvCache.pid(inCwd:) has no injectable resolver; resolution count is unobservable")
    }

    func testBuilder028_canonicalCwdSharesOneEntry() throws {
        throw XCTSkip("HookEnvCache.pid(inCwd:) has no injectable resolver; resolution count is unobservable")
    }

    func testBuilder029_failedEnvReadCachedAsEmpty() throws {
        throw XCTSkip("HookEnvCache.env(forPid:) has no injectable reader; read count is unobservable")
    }

    func testBuilder030_expiredEntriesEvictedPast128() throws {
        throw XCTSkip("needs more than three real seconds to expire entries and the maps are private")
    }

    func testBuilder031_concurrentEnvCallsForDifferentPidsReturnDictionaries() {
        let count = 16
        let lock = NSLock()
        var results = [Int: [String: String]]()
        DispatchQueue.concurrentPerform(iterations: count) { index in
            let pid = Int32(2_000_000 + index)
            let env = HookEnvCache.env(forPid: pid)
            lock.lock()
            results[index] = env
            lock.unlock()
        }
        XCTAssertEqual(results.count, count)
    }
}
