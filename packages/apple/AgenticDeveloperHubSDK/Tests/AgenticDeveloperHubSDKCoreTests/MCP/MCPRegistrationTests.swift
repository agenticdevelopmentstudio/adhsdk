import XCTest
@testable import AgenticDeveloperHubSDKCore

final class MCPRegistrationTests: XCTestCase {

    private func config(_ json: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("claude-\(UUID().uuidString).json")
        try json.write(to: url, atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func testEachChannelHasItsOwnNameAndPort() {
        XCTAssertEqual(MCPRegistration.Channel.dev.serverName, "adhd-dev")
        XCTAssertEqual(MCPRegistration.Channel.dev.port, 22871)
        XCTAssertEqual(MCPRegistration.Channel.dev.url, "http://127.0.0.1:22871/mcp")
        XCTAssertEqual(MCPRegistration.Channel.release.serverName, "adhd")
        XCTAssertEqual(MCPRegistration.Channel.release.port, 22850)
        XCTAssertEqual(MCPRegistration.Channel.release.url, "http://127.0.0.1:22850/mcp")
    }

    func testClaudeCommandIsTheHeadersHelperForm() {
        let command = MCPRegistration.claudeCommand(channel: .dev, adhdPath: "/opt/adhd/adhd")
        XCTAssertEqual(command,
            "claude mcp add-json --scope user adhd-dev "
            + #"'{"headersHelper":"/opt/adhd/adhd mcp headers","type":"http","url":"http://127.0.0.1:22871/mcp"}'"#)
        XCTAssertFalse(command.contains("Bearer"))
    }

    func testAPathWithSpacesIsOneShellWordInTheHelper() throws {
        let path = "/Users/a/Library/Application Support/com.agentic-cookbook.adhd.dev/adhd"
        let json = MCPRegistration.entryJSON(channel: .release, adhdPath: path)
        let entry = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: String])
        XCTAssertEqual(entry["headersHelper"], "'\(path)' mcp headers")
        XCTAssertEqual(entry["url"], "http://127.0.0.1:22850/mcp")
        XCTAssertEqual(entry["type"], "http")

        // The helper's own single quotes survive the shell quoting of the whole entry.
        let command = MCPRegistration.claudeCommand(channel: .release, adhdPath: path)
        XCTAssertTrue(command.hasPrefix("claude mcp add-json --scope user adhd '"))
        XCTAssertTrue(command.contains(#"'\''"#))
    }

    func testRegisteredWhenTheEntryPointsAtTheChannel() throws {
        let url = try config(#"{"mcpServers":{"adhd-dev":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}"#)
        XCTAssertTrue(MCPRegistration.isRegistered(claudeConfig: url, channel: .dev))
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, channel: .release))
    }

    func testTheOldKitchenEntryIsNotARegistration() throws {
        let url = try config(#"{"mcpServers":{"adkitchen":{"type":"http","url":"http://127.0.0.1:22871/mcp"}}}"#)
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, channel: .dev))
    }

    func testNotRegisteredWhenThePortDiffers() throws {
        let url = try config(#"{"mcpServers":{"adhd-dev":{"type":"http","url":"http://127.0.0.1:22850/mcp"}}}"#)
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, channel: .dev))
    }

    func testNotRegisteredWhenTheFileIsMissingOrNotJSON() throws {
        let missing = URL(fileURLWithPath: "/nonexistent/.claude.json")
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: missing, channel: .dev))
        let url = try config("not json")
        XCTAssertFalse(MCPRegistration.isRegistered(claudeConfig: url, channel: .dev))
    }

    func testThePortFormMatchesTheChannelForm() {
        XCTAssertEqual(MCPRegistration.entryJSON(port: 22871, adhdPath: "/opt/adhd"),
                       MCPRegistration.entryJSON(channel: .dev, adhdPath: "/opt/adhd"))
        XCTAssertEqual(MCPRegistration.claudeCommand(serverName: "adhd", port: 22850, adhdPath: "/opt/adhd"),
                       MCPRegistration.claudeCommand(channel: .release, adhdPath: "/opt/adhd"))
    }

    func testAnyPortAndNameReachTheLine() {
        XCTAssertEqual(MCPRegistration.url(port: 22995), "http://127.0.0.1:22995/mcp")
        XCTAssertEqual(
            MCPRegistration.claudeCommand(serverName: "adhd-dev", port: 22995, adhdPath: "/opt/adhd/adhd"),
            "claude mcp add-json --scope user adhd-dev "
            + #"'{"headersHelper":"/opt/adhd/adhd mcp headers","type":"http","url":"http://127.0.0.1:22995/mcp"}'"#)
    }

    func testShellQuotingKeepsPlainWordsAndQuotesTheRest() {
        XCTAssertEqual(MCPRegistration.shellQuoted("/opt/adhd/adhd"), "/opt/adhd/adhd")
        XCTAssertEqual(MCPRegistration.shellQuoted("a b"), "'a b'")
        XCTAssertEqual(MCPRegistration.shellQuoted("it's"), #"'it'\''s'"#)
    }

    func testTheRegisteredPathIsTheOneServed() {
        XCTAssertEqual(MCPRegistration.path, "/mcp")
    }
}
