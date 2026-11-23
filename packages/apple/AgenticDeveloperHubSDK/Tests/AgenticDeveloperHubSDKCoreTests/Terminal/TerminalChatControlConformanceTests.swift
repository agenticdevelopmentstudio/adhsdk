import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `TerminalChatControl`: the resolver, defaults and wire shapes.
final class TerminalChatControlConformanceTests: XCTestCase {

    private func chat(_ identifier: String) -> TerminalChatControl.Chat {
        TerminalChatControl.Chat(
            id: identifier, project: "P", directory: "/tmp", paneNumber: 1, connected: true
        )
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

    func testV021_resolveErrorMessageAndEquality() {
        guard case .failure(let failure) = TerminalChatControl.resolve("zz", in: []) else {
            return XCTFail("expected failure")
        }
        XCTAssertEqual(failure.message, "No Terminal Chat with id zz.")
        XCTAssertEqual(failure, TerminalChatControl.ResolveError(message: "No Terminal Chat with id zz."))
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
