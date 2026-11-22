import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelRequestFactsTests: XCTestCase {
    private func head(_ method: String = "POST", _ target: String = "/v1/messages") -> RouterRequestHead {
        RouterRequestHead(method: method, target: target, version: "HTTP/1.1", fields: [])
    }

    private func body(_ object: [String: Any]) -> Data {
        // swiftlint:disable:next force_try
        try! JSONSerialization.data(withJSONObject: object)
    }

    private func facts(_ object: [String: Any]) throws -> ModelRequestFacts {
        try ModelRequestFacts.extract(head: head(), body: body(object)).get().0
    }

    private let claudeCode = "You are Claude Code, Anthropic's official CLI for Claude."
    private let readTool: [String: Any] = ["name": "Read"]

    private func base(system: Any? = nil, tools: [[String: Any]]? = nil) -> [String: Any] {
        var object: [String: Any] = ["model": "claude-opus-5-5", "max_tokens": 1000,
                                     "messages": [["role": "user", "content": "hi"]]]
        if let system { object["system"] = system }
        if let tools { object["tools"] = tools }
        return object
    }

    func testThreadShapes() throws {
        XCTAssertEqual(try facts(base(system: claudeCode, tools: [readTool])).thread, .main)
        XCTAssertEqual(try facts(base(system: [["type": "text", "text": claudeCode]])).thread, .main)
        XCTAssertEqual(try facts(base(system: "You are a helper.", tools: [readTool])).thread, .subagent)
        XCTAssertEqual(try facts(base(system: "You are a helper.", tools: [])).thread, .side)
        XCTAssertEqual(try facts(base(system: "You are a helper.")).thread, .side)
        XCTAssertEqual(try facts(base()).thread, .other)
    }

    func testWrites() throws {
        XCTAssertTrue(try facts(base(system: "s", tools: [readTool, ["name": "Edit"]])).writes)
        XCTAssertTrue(try facts(base(system: "s", tools: [["name": "NotebookEdit"]])).writes)
        XCTAssertFalse(try facts(base(system: "s", tools: [readTool, ["name": "Bash"]])).writes)
    }

    func testCommandsMeansABashTool() throws {
        XCTAssertTrue(try facts(base(system: "s", tools: [readTool, ["name": "Bash"]])).commands)
        XCTAssertFalse(try facts(base(system: "s", tools: [readTool, ["name": "Edit"]])).commands)
        XCTAssertFalse(try facts(base(system: "s", tools: [["name": "bash"]])).commands)
        XCTAssertFalse(try facts(base(system: "s")).commands)
    }

    // Shapes captured from Claude Code 2.1.302 (system block prefixes and tool names only).
    private let sdkIdentity = "You are a Claude agent, built on Anthropic's Claude Agent SDK."
    private let mainTools: [[String: Any]] = ["Agent", "Bash", "Edit", "NotebookEdit", "Read", "Write",
                                              "WebFetch", "WebSearch", "Skill", "mcp__x__y"].map { ["name": $0] }
    private let exploreTools: [[String: Any]] = ["Bash", "Read", "WebFetch", "WebSearch", "Skill", "mcp__x__y"]
        .map { ["name": $0] }

    private func billing(_ entrypoint: String, subagent: Bool = false) -> [String: Any] {
        let flag = subagent ? " cc_is_subagent=true;" : ""
        let line = "x-anthropic-billing-header: cc_version=2.1.302.cfd; cc_entrypoint=\(entrypoint);\(flag)"
        return ["type": "text", "text": line]
    }

    private func text(_ value: String) -> [String: Any] { ["type": "text", "text": value] }

    func testMainThreadUnderTheSDKEntrypointIsMain() throws {
        let system = [billing("sdk-cli"), text(sdkIdentity),
                      text("\nYou are an agent working with the user toward their goals, using your own judgment.")]
        let found = try facts(base(system: system, tools: mainTools))
        XCTAssertEqual(found.thread, .main)
        XCTAssertTrue(found.writes)
        XCTAssertTrue(found.commands)
    }

    func testInteractiveMainThreadIsMain() throws {
        let system = [billing("cli"), text("You are an interactive agent that helps users.")]
        XCTAssertEqual(try facts(base(system: system, tools: mainTools)).thread, .main)
    }

    func testMainThreadWithoutAnAgentToolIsStillMain() throws {
        let system = [billing("cli"), text(sdkIdentity)]
        XCTAssertEqual(try facts(base(system: system, tools: exploreTools)).thread, .main)
    }

    func testExploreSubagentIsSubagent() throws {
        let system = [billing("sdk-cli", subagent: true), text(sdkIdentity),
                      text("You are a file search specialist for Claude Code, Anthropic's official CLI for Claude.")]
        let found = try facts(base(system: system, tools: exploreTools))
        XCTAssertEqual(found.thread, .subagent)
        XCTAssertFalse(found.writes)
        XCTAssertTrue(found.commands)
    }

    func testSideCallsHaveNoTools() throws {
        XCTAssertEqual(try facts(base(system: [billing("cli"), text("Summarize this.")], tools: [])).thread, .side)
        XCTAssertEqual(try facts(base(system: [billing("cli", subagent: true), text("Title it.")])).thread, .side)
    }

    func testBillingLineInsideOneStringSystem() throws {
        let system = "x-anthropic-billing-header: cc_version=1; cc_is_subagent=true;\n\(claudeCode)"
        XCTAssertEqual(try facts(base(system: system, tools: [readTool])).thread, .subagent)
    }

    func testOldStyleMarkerIsMain() throws {
        let system = [text(claudeCode), text("You are an interactive CLI tool.")]
        XCTAssertEqual(try facts(base(system: system, tools: [readTool])).thread, .main)
    }

    func testNoBillingLineWithAnAgentToolIsMain() throws {
        XCTAssertEqual(try facts(base(system: "You are a helper.", tools: [["name": "Agent"]])).thread, .main)
        XCTAssertEqual(try facts(base(system: "You are a helper.", tools: [readTool, ["name": "Task"]])).thread, .main)
    }

    func testThreadKeyIgnoresTheBillingLine() throws {
        let one = [billing("cli"), text(sdkIdentity)]
        var other = one
        other[0] = ["type": "text", "text": "x-anthropic-billing-header: cc_version=2.1.302.11f; cc_entrypoint=cli;"]
        XCTAssertEqual(try facts(base(system: one, tools: mainTools)).threadKey,
                       try facts(base(system: other, tools: mainTools)).threadKey)
    }

    func testFamilyAndBasics() throws {
        let found = try facts(base())
        XCTAssertEqual(found.family, .opus)
        XCTAssertEqual(found.requestedModel, "claude-opus-5-5")
        XCTAssertEqual(found.maxTokens, 1000)
    }

    private func reason(_ head: RouterRequestHead, _ data: Data) -> ModelPassReason? {
        if case .failure(let reason) = ModelRequestFacts.extract(head: head, body: data) { return reason }
        return nil
    }

    func testMaxTokensIsNeverNegative() throws {
        var object = base()
        object["max_tokens"] = -5
        XCTAssertEqual(try facts(object).maxTokens, 0)
        object["max_tokens"] = Int.min
        XCTAssertEqual(try facts(object).maxTokens, 0)
        object["max_tokens"] = Int.max
        XCTAssertEqual(try facts(object).maxTokens, Int.max)
    }

    func testNotCandidates() {
        XCTAssertEqual(reason(head("POST", "/v1/messages/count_tokens"), body(base())), .notMessages)
        XCTAssertEqual(reason(head("GET"), body(base())), .notMessages)
        XCTAssertEqual(reason(head(), Data("nope".utf8)), .notJSON)
        var gpt = base()
        gpt["model"] = "gpt-4"
        XCTAssertEqual(reason(head(), body(gpt)), .noModel)
        XCTAssertNil(reason(head("POST", "/v1/messages?beta=true"), body(base())))
    }

    func testThreadKeyIgnoresLaterMessagesAndKeyOrder() throws {
        var first = base(system: "s")
        first["messages"] = [["role": "user", "content": "hi"]]
        var later = base(system: "s")
        later["messages"] = [["role": "user", "content": "hi"], ["role": "assistant", "content": "yo"]]
        var reordered = base(system: "s")
        reordered["messages"] = [["content": "hi", "role": "user"]]
        var different = base(system: "s")
        different["messages"] = [["role": "user", "content": "other"]]
        let key = try facts(first).threadKey
        XCTAssertEqual(key.count, 64)
        XCTAssertEqual(try facts(later).threadKey, key)
        XCTAssertEqual(try facts(reordered).threadKey, key)
        XCTAssertNotEqual(try facts(different).threadKey, key)
    }
}
