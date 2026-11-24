// Tests/AgenticDeveloperHubSDKMacOSTests/MCP/HostAppToolSourceTests.swift
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Counts calls made from a `@Sendable` closure.
final class OpenCounter: @unchecked Sendable {
    var count = 0
}

final class HostAppToolSourceTests: XCTestCase {

    func testHostAppToolSourceAnswersInfoAndOpensChat() async throws {
        let opened = OpenCounter()
        let host = HostAppToolSource(appName: "Kitchen", appVersion: "2.0", pluginNames: ["ClaudeAPI"],
                                     openChatWindow: { opened.count += 1 })
        let names = await host.toolDefinitions().map(\.name)
        XCTAssertEqual(names, ["host_app_info", "host_open_chat_window"])
        let info = await host.callTool(name: "host_app_info", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(info.content, "Host: Kitchen\nVersion: 2.0\nPlugins: ClaudeAPI")
        let open = await host.callTool(name: "host_open_chat_window", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(open.content, "Opened a new chat window.")
        XCTAssertEqual(opened.count, 1)
    }

    func testHostAppInfoSaysNoneWhenThereAreNoPlugins() async {
        let host = HostAppToolSource(appName: "Kitchen", appVersion: "2.0")
        let info = await host.callTool(name: "host_app_info", argumentsJSON: Data("{}".utf8), caller: nil)
        XCTAssertEqual(info.content, "Host: Kitchen\nVersion: 2.0\nPlugins: (none)")
    }
}
