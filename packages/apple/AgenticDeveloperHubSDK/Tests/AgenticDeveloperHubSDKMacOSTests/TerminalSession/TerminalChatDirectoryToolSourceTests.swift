import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A chat that records what it was asked and answers with canned text.
@MainActor
final class FakeTerminalChat: TerminalChatDriving {
    var isConnected: Bool
    private(set) var calls: [String] = []
    private(set) var settles: [Duration] = []
    private(set) var timeouts: [Duration] = []
    private(set) var screenLines: [Int] = []

    init(connected: Bool = true) {
        isConnected = connected
    }

    func run(_ text: String, settle: Duration, timeout: Duration) async -> String {
        record("run \(text)", settle, timeout)
        return "ran \(text)"
    }

    func waitForOutput(settle: Duration, timeout: Duration) async -> String {
        record("wait", settle, timeout)
        return "waited"
    }

    func interruptAndWait(settle: Duration, timeout: Duration) async -> String {
        record("interrupt", settle, timeout)
        return "^C"
    }

    func screen(lines: Int) -> String? {
        calls.append("screen")
        screenLines.append(lines)
        return "$ "
    }

    private func record(_ call: String, _ settle: Duration, _ timeout: Duration) {
        calls.append(call)
        settles.append(settle)
        timeouts.append(timeout)
    }
}

@MainActor
final class FakeTerminalChatListing: TerminalChatListing {
    var chatEntries: [(chat: TerminalChatControl.Chat, session: any TerminalChatDriving)] = []

    @discardableResult
    func add(_ id: String, project: String = "P", connected: Bool = true) -> FakeTerminalChat {
        let session = FakeTerminalChat(connected: connected)
        chatEntries.append((
            chat: TerminalChatControl.Chat(id: id, project: project, directory: "/tmp/\(project)",
                                           paneNumber: chatEntries.count + 1, connected: connected),
            session: session))
        return session
    }
}

@MainActor
final class TerminalChatDirectoryToolSourceTests: XCTestCase {

    private typealias Defaults = TerminalChatControl.Defaults
    private typealias Name = TerminalChatDirectoryToolSource.ToolName

    private func call(
        _ source: TerminalChatDirectoryToolSource, _ name: String, _ arguments: [String: Any] = [:]
    ) async throws -> (content: String, isError: Bool) {
        let data = try JSONSerialization.data(withJSONObject: arguments)
        return await source.callTool(name: name, argumentsJSON: data, caller: nil)
    }

    func testItOffersTheFiveTools() async {
        let source = TerminalChatDirectoryToolSource(directory: FakeTerminalChatListing())
        let names = await source.toolDefinitions().map(\.name)
        XCTAssertEqual(names, [Name.list, Name.run, Name.wait, Name.interrupt, Name.screen])
    }

    func testListAnswersTheChatsAsJSON() async throws {
        let listing = FakeTerminalChatListing()
        listing.add("a1b2c3d4", project: "One")
        listing.add("f9e8d7c6", project: "Two", connected: false)
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.list)
        XCTAssertFalse(reply.isError)
        let chats = try JSONDecoder().decode([TerminalChatControl.Chat].self, from: Data(reply.content.utf8))
        XCTAssertEqual(chats.map(\.id), ["a1b2c3d4", "f9e8d7c6"])
        XCTAssertEqual(chats.map(\.connected), [true, false])
    }

    func testAPrefixResolves() async throws {
        let listing = FakeTerminalChatListing()
        let first = listing.add("a1b2c3d4")
        let second = listing.add("f9e8d7c6")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.run, ["chat": "F9", "command": "ls"])
        XCTAssertEqual(reply.content, "ran ls")
        XCTAssertFalse(reply.isError)
        XCTAssertEqual(second.calls, ["run ls"])
        XCTAssertTrue(first.calls.isEmpty)
    }

    func testAnAmbiguousPrefixIsAnError() async throws {
        let listing = FakeTerminalChatListing()
        let first = listing.add("a1b2c3d4")
        let second = listing.add("a1ffffff")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.wait, ["chat": "a1"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "More than one Terminal Chat matches — choose one of: a1b2c3d4, a1ffffff")
        XCTAssertTrue(first.calls.isEmpty)
        XCTAssertTrue(second.calls.isEmpty)
    }

    func testAnUnknownPrefixIsAnError() async throws {
        let listing = FakeTerminalChatListing()
        listing.add("a1b2c3d4")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.screen, ["chat": "zz"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "No Terminal Chat with id zz.")
    }

    func testWithOneChatTheChatMayBeOmitted() async throws {
        let listing = FakeTerminalChatListing()
        let only = listing.add("a1b2c3d4")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.screen)
        XCTAssertEqual(reply.content, "$ ")
        XCTAssertEqual(only.screenLines, [Defaults.lines])
    }

    func testWithTwoChatsOmittingTheChatIsAnError() async throws {
        let listing = FakeTerminalChatListing()
        listing.add("a1b2c3d4")
        listing.add("f9e8d7c6")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.interrupt)
        XCTAssertTrue(reply.isError)
    }

    func testDefaultsApplyWhenNothingIsAsked() async throws {
        let listing = FakeTerminalChatListing()
        let only = listing.add("a1b2c3d4")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        _ = try await call(source, Name.wait)
        _ = try await call(source, Name.interrupt)
        XCTAssertEqual(only.settles, [.milliseconds(Int(Defaults.settle * 1000)),
                                      .milliseconds(Int(Defaults.settle * 1000))])
        XCTAssertEqual(only.timeouts, [.milliseconds(Int(Defaults.timeout * 1000)),
                                       .milliseconds(Int(Defaults.interruptTimeout * 1000))])
    }

    func testClampingApplies() async throws {
        let listing = FakeTerminalChatListing()
        let only = listing.add("a1b2c3d4")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        _ = try await call(source, Name.run, ["command": "make", "settle": 9_999, "timeout": 9_999])
        _ = try await call(source, Name.wait, ["settle": 0, "timeout": -5])

        XCTAssertEqual(only.settles, [.milliseconds(Int(Defaults.maximumSettle * 1000)), .milliseconds(100)])
        XCTAssertEqual(only.timeouts, [.milliseconds(Int(Defaults.maximumTimeout * 1000)), .milliseconds(100)])
    }

    func testNotConnectedPassesThrough() async throws {
        let listing = FakeTerminalChatListing()
        let chat = listing.add("a1b2c3d4", connected: false)
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.run, ["command": "ls"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "Terminal Chat a1b2c3d4 is not connected to a terminal — use "
                       + "Connect to Terminal in its pane's Settings.")
        XCTAssertTrue(chat.calls.isEmpty)
    }

    func testRunWithoutACommandIsAnError() async throws {
        let listing = FakeTerminalChatListing()
        let only = listing.add("a1b2c3d4")
        let source = TerminalChatDirectoryToolSource(directory: listing)

        let reply = try await call(source, Name.run, ["command": ""])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "run needs a command.")
        XCTAssertTrue(only.calls.isEmpty)
    }

    func testAnUnknownToolIsAnError() async throws {
        let source = TerminalChatDirectoryToolSource(directory: FakeTerminalChatListing())
        let reply = try await call(source, "type")
        XCTAssertTrue(reply.isError)
    }
}
