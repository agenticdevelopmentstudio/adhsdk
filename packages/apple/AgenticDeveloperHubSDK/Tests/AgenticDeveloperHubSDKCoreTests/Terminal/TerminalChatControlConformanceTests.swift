import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `TerminalChatControl`: the resolver, defaults, wire shapes and socket helpers.
final class TerminalChatControlConformanceTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tcc-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func chat(_ identifier: String) -> TerminalChatControl.Chat {
        TerminalChatControl.Chat(
            id: identifier, project: "P", directory: "/tmp", paneNumber: 1, connected: true
        )
    }

    private func touch(_ name: String) throws {
        try Data().write(to: tmpDir.appendingPathComponent(name))
    }

    func testV001_resolveOnlyChat() throws {
        let only = chat("a1b2c3d4")
        XCTAssertEqual(try TerminalChatControl.resolve(nil, in: [only]).get(), only)
    }

    func testV002_resolveNoneOpen() {
        guard case .failure(let failure) = TerminalChatControl.resolve(nil, in: []) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "There is no Terminal Chat open.")
    }

    func testV003_resolvePrefixIgnoresCase() throws {
        let both = [chat("a1b2c3d4"), chat("f9e8d7c6")]
        XCTAssertEqual(try TerminalChatControl.resolve("A1B", in: both).get().id, "a1b2c3d4")
    }

    func testV004_resolveNoMatch() {
        let both = [chat("a1b2c3d4"), chat("f9e8d7c6")]
        guard case .failure(let failure) = TerminalChatControl.resolve("zz", in: both) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "No Terminal Chat with id zz.")
    }

    func testV005_resolveManyForAPrefix() {
        let both = [chat("a1b2c3d4"), chat("a1ffffff")]
        guard case .failure(let failure) = TerminalChatControl.resolve("a1", in: both) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "More than one Terminal Chat matches — choose one of: a1b2c3d4, a1ffffff")
    }

    func testV006_resolveManyForNilQuery() {
        let both = [chat("a1b2c3d4"), chat("a1ffffff")]
        guard case .failure(let failure) = TerminalChatControl.resolve(nil, in: both) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "More than one Terminal Chat matches — choose one of: a1b2c3d4, a1ffffff")
    }

    func testV007_defaultTimeoutForAction() {
        XCTAssertEqual(TerminalChatControl.Defaults.timeout(for: .interrupt), 10)
        for action in [TerminalChatControl.Action.run, .wait, .screen, .list] {
            XCTAssertEqual(TerminalChatControl.Defaults.timeout(for: action), 60)
        }
    }

    func testV008_defaultConstants() {
        XCTAssertEqual(TerminalChatControl.Defaults.settle, 1.5)
        XCTAssertEqual(TerminalChatControl.Defaults.lines, 40)
        XCTAssertEqual(TerminalChatControl.Defaults.maximumSettle, 60)
        XCTAssertEqual(TerminalChatControl.Defaults.maximumTimeout, 600)
    }

    func testV009_requestRoundTripsWithNilOptionals() throws {
        let request = TerminalChatControl.Request(action: .list)
        let decoded = try JSONDecoder().decode(TerminalChatControl.Request.self,
                                               from: try JSONEncoder().encode(request))
        XCTAssertEqual(decoded, request)
        XCTAssertNil(decoded.chat)
        XCTAssertNil(decoded.command)
        XCTAssertNil(decoded.settle)
        XCTAssertNil(decoded.timeout)
        XCTAssertNil(decoded.lines)
    }

    func testV010_actionValues() throws {
        XCTAssertEqual(TerminalChatControl.Action.interrupt.rawValue, "interrupt")
        let decoded = try JSONDecoder().decode(TerminalChatControl.Action.self, from: Data("\"screen\"".utf8))
        XCTAssertEqual(decoded, .screen)
    }

    func testV011_failureResponse() {
        let response = TerminalChatControl.Response.failure("x")
        XCTAssertEqual(response.error, "x")
        XCTAssertFalse(response.isSuccess)
        XCTAssertNil(response.app)
        XCTAssertNil(response.chats)
        XCTAssertNil(response.chat)
        XCTAssertNil(response.output)
    }

    func testV012_outputResponseIsSuccess() {
        XCTAssertTrue(TerminalChatControl.Response(output: "ok").isSuccess)
    }

    func testV013_socketURL() {
        let url = TerminalChatControl.socketURL(pid: 4242, in: tmpDir)
        XCTAssertEqual(url, tmpDir.appendingPathComponent("4242.sock"))
    }

    func testV014_prepareCreatesOwnerOnlyDirectory() throws {
        let directory = tmpDir.appendingPathComponent("sockets")
        try TerminalChatControl.prepareSocketDirectory(directory)
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        XCTAssertEqual(attributes[.posixPermissions] as? Int, 0o700)
    }

    func testV015_runningHostsSkipsOddNames() throws {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        try touch("\(ownPid).sock")
        try touch("notes.txt")
        try touch("abc.sock")
        let hosts = TerminalChatControl.runningHosts(in: tmpDir)
        XCTAssertEqual(hosts.map(\.pid), [ownPid])
    }

    func testV016_prepareRemovesStaleSocket() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try process.run()
        process.waitUntilExit()
        let exitedPid = process.processIdentifier
        try touch("\(exitedPid).sock")
        try TerminalChatControl.prepareSocketDirectory(tmpDir)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: tmpDir.appendingPathComponent("\(exitedPid).sock").path))
    }

    func testV017_runningHostsMissingDirectoryIsEmpty() {
        let missing = tmpDir.appendingPathComponent("nope")
        XCTAssertTrue(TerminalChatControl.runningHosts(in: missing).isEmpty)
    }

    func testV018_runningHostsSortedByPid() throws {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        try touch("\(ownPid).sock")
        try touch("1.sock")
        let hosts = TerminalChatControl.runningHosts(in: tmpDir)
        XCTAssertEqual(hosts.map(\.pid), [1, ownPid].sorted())
    }

    func testV019_sendWaitMargin() throws {
        throw XCTSkip("Needs a host that answers after 40 real seconds; real time beyond a second")
    }

    func testV020_sendToNothingListeningThrows() {
        let host = TerminalChatControl.Host(pid: 1, socket: tmpDir.appendingPathComponent("none.sock"))
        XCTAssertThrowsError(try TerminalChatControl.send(.init(action: .list), to: host, wait: 1))
    }

    func testV021_resolveErrorMessageAndEquality() {
        guard case .failure(let failure) = TerminalChatControl.resolve("zz", in: []) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "No Terminal Chat with id zz.")
        XCTAssertEqual(failure, TerminalChatControl.ResolveError(message: "No Terminal Chat with id zz."))
    }

    func testV022_prepareThrowsWhenParentIsAFile() throws {
        try touch("plain")
        let directory = tmpDir.appendingPathComponent("plain/sockets")
        XCTAssertThrowsError(try TerminalChatControl.prepareSocketDirectory(directory))
    }

    func testV023_pidOneCountsAsRunning() throws {
        try touch("1.sock")
        XCTAssertEqual(TerminalChatControl.runningHosts(in: tmpDir).map(\.pid), [1])
    }

    func testV024_emptyQueryMatchesEveryChat() {
        let both = [chat("a1b2c3d4"), chat("f9e8d7c6")]
        guard case .failure(let failure) = TerminalChatControl.resolve("", in: both) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "More than one Terminal Chat matches — choose one of: a1b2c3d4, f9e8d7c6")
    }

    func testV025_responseInitDefaultsToNil() {
        let response = TerminalChatControl.Response(output: "ok")
        XCTAssertNil(response.error)
        XCTAssertNil(response.app)
        XCTAssertNil(response.chats)
        XCTAssertNil(response.chat)
        XCTAssertEqual(response.output, "ok")
    }
}
