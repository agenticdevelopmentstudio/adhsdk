import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A reader that hands out one canned walk and counts the walks asked of it.
@MainActor
final class SpyAgentPageReader: AgentPageReader {
    var reading: AgentPageReading
    private(set) var reads: [(options: BrowserSnapshotOptions, keepingRefs: Bool)] = []

    init(_ reading: AgentPageReading) { self.reading = reading }

    func read(options: BrowserSnapshotOptions, keepingRefs: Bool) async -> AgentPageReading {
        reads.append((options, keepingRefs))
        return reading
    }
}

/// Every browser tool that reads the page reads the agent's page, through
/// one gatekeeper (recipe workspace/browser/agent-page-builder:
/// `single-gatekeeper`, `raw-page-tools-refused-when-filtered`,
/// `console-refused-under-privacy`, `wait-for-uses-agent-text`,
/// `titles-dialogs-focus-through-string-path`). The live page holds "Raw"
/// words the agent page does not, so a reply that names one came from the
/// raw page.
@MainActor
final class AgentGatekeeperRoutingTests: XCTestCase {

    private static let livePage = "<title>Beta</title><main><p>Raw words</p><button>Raw button</button></main>"

    /// "Beta" and "Two" are shown to models as "Gamma" and "Zwei".
    private let privateWords = TextSubstitutionFilter(pairs: [
        .init(alias: "Gamma", real: "Beta"), .init(alias: "Zwei", real: "Two")
    ])

    private var settings: UserSettings!
    private var page: OffscreenWebView!
    private var directory: FakeBrowserDirectory!
    private var storeDirectory: URL!

    override func setUp() async throws {
        settings = UserSettings(with: InMemorySettingsStorageProvider(),
                                secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        page = OffscreenWebView()
        await page.load(html: Self.livePage)
        directory = FakeBrowserDirectory(pages: ["A": page])
        directory.panes = [pane(privacy: .off)]
        storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgentGatekeeperRoutingTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let storeDirectory { try? FileManager.default.removeItem(at: storeDirectory) }
        page = nil
        directory = nil
    }

    // MARK: Helpers

    private func pane(privacy: BrowserAgentPrivacy) -> BrowserPaneHandle {
        let automation = directory?.panes.first?.automation
            ?? BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())
        return BrowserPaneHandle(id: "A", project: "proj", tab: "Tab A", automation: automation,
                                 agentPrivacy: privacy)
    }

    private func store(agentSelectors: [String] = []) throws -> BrowserHiddenItemsStore {
        let store = try BrowserHiddenItemsStore.open(
            at: storeDirectory.appendingPathComponent("\(UUID().uuidString)-\(BrowserHiddenItemsStore.fileName)"))
        for selector in agentSelectors {
            try store.add(BrowserHiddenItem(
                list: .agent, pageURL: URL(string: "http://fixture.test/"), selector: selector,
                scope: .allLikeIt, label: selector))
        }
        return store
    }

    private func makeTools(store: BrowserHiddenItemsStore?, spy: SpyAgentPageReader? = nil) -> BrowserToolSet {
        guard let spy else {
            return BrowserToolSet(directory: directory, settings: settings, hiddenItems: { store })
        }
        return BrowserToolSet(directory: directory, settings: settings, hiddenItems: { store },
                              agentPages: { _, _ in spy })
    }

    private func call(_ tools: BrowserToolSet, _ name: String, _ args: [String: Any] = [:]) async throws
        -> (content: String, isError: Bool) {
        let data = try JSONSerialization.data(withJSONObject: args)
        return await tools.callTool(name: name, argumentsJSON: data, caller: nil)
    }

    private static func node(_ ref: String, _ kind: AgentNodeKind, _ text: String = "",
                             attributes: [String: String] = [:], children: [AgentNode] = []) -> AgentNode {
        let content = ([text] + children.map(\.contentText)).filter { !$0.isEmpty }.joined(separator: " ")
        return AgentNode(ref: ref, kind: kind, text: text, attributes: attributes, value: nil,
                         selector: "#\(ref)", children: children, contentText: content)
    }

    /// The agent's page: a main landmark holding "Agent words" and an
    /// "Agent button" (e2), none of the live page's "Raw" words.
    private static var agentPage: AgentPage {
        let main = node("e1", .landmark, attributes: [AgentPageAllowlist.roleAttribute: "main"], children: [
            node("e3", .paragraph, children: [node("e4", .text, "Agent words")]),
            node("e2", .button, children: [node("e5", .text, "Agent button")])
        ])
        return AgentPage(url: URL(string: "http://fixture.test/"), title: "Agent title",
                         root: node("e0", .document, children: [main]))
    }

    private static func reading(_ page: AgentPage, generation: Int? = 7) -> AgentPageReading {
        AgentPageReading(page: page, generation: generation, warnings: [], failure: nil)
    }

    // MARK: Tests

    func test_snapshotTextFindShareBuilder() async throws {
        let spy = SpyAgentPageReader(Self.reading(Self.agentPage))
        let tools = makeTools(store: try store(), spy: spy)

        let snap = try await call(tools, "browser_snapshot")
        XCTAssertFalse(snap.isError, snap.content)
        XCTAssertEqual(spy.reads.count, 1)
        XCTAssertTrue(snap.content.contains("Agent button"), snap.content)
        XCTAssertTrue(snap.content.contains("generation: 7"), snap.content)
        XCTAssertFalse(snap.content.contains("Raw"), snap.content)
        XCTAssertEqual(spy.reads.last?.keepingRefs, false)

        let text = try await call(tools, "browser_text")
        XCTAssertFalse(text.isError, text.content)
        XCTAssertEqual(spy.reads.count, 2)
        XCTAssertTrue(text.content.contains("Agent words"), text.content)
        XCTAssertFalse(text.content.contains("Raw"), text.content)
        XCTAssertEqual(spy.reads.last?.keepingRefs, true)

        let find = try await call(tools, "browser_find", ["text": "agent BUTTON"])
        XCTAssertFalse(find.isError, find.content)
        XCTAssertEqual(spy.reads.count, 3)
        XCTAssertEqual(find.content, "e2 button \"Agent button\"")
        XCTAssertEqual(spy.reads.last?.keepingRefs, true)

        let miss = try await call(tools, "browser_find", ["text": "Raw button"])
        XCTAssertEqual(spy.reads.count, 4)
        XCTAssertEqual(miss.content, "no element matches")
    }

    func test_rawToolsRefusedWithAgentList() async throws {
        settings.set(true, for: UserSettings.browserAutomationEvaluate)
        let tools = makeTools(store: try store(agentSelectors: ["main p"]))
        let calls: [(String, [String: Any])] = [
            ("browser_screenshot", [:]), ("browser_click_at", ["x": 1, "y": 1]),
            ("browser_evaluate", ["expression": "document.body.innerText"])
        ]
        for (name, args) in calls {
            let reply = try await call(tools, name, args)
            XCTAssertTrue(reply.isError, name)
            XCTAssertEqual(reply.content, BrowserAgentPrivacy.agentListRefusal, name)
        }
        XCTAssertEqual(BrowserAgentPrivacy.agentListRefusal,
                       "This site has items hidden from the agent, so tools that see the raw page are refused here.")
        XCTAssertTrue(directory.revealed.isEmpty, "a refused raw tool must not put the pane on screen")
    }

    func test_rawToolsAllowedWhenNothingHidden() async throws {
        settings.set(true, for: UserSettings.browserAutomationEvaluate)
        let tools = makeTools(store: try store())
        let evaluate = try await call(tools, "browser_evaluate", ["expression": "1+1"])
        XCTAssertFalse(evaluate.isError, evaluate.content)
        XCTAssertEqual(evaluate.content, "2")
        let screenshot = try await call(tools, "browser_screenshot")
        XCTAssertNotEqual(screenshot.content, BrowserAgentPrivacy.agentListRefusal)
        let click = try await call(tools, "browser_click_at", ["x": 1, "y": 1])
        XCTAssertNotEqual(click.content, BrowserAgentPrivacy.agentListRefusal)
        let pane = try XCTUnwrap(directory.panes.first)
        let refusal = await tools.rawPageRefusal(pane: pane, tool: "browser_evaluate")
        XCTAssertNil(refusal)
    }

    func test_consoleRefusedUnderPrivacy() async throws {
        let tools = makeTools(store: try store())
        let open = try await call(tools, "browser_console")
        XCTAssertFalse(open.isError, open.content)

        directory.panes = [pane(privacy: .enabled(privateWords))]
        let refused = try await call(tools, "browser_console")
        XCTAssertTrue(refused.isError)
        XCTAssertEqual(refused.content, "Agent Privacy is on for this browser pane, so console output is not shared.")
    }

    func test_waitForUsesAgentText() async throws {
        let spy = SpyAgentPageReader(Self.reading(Self.agentPage))
        let tools = makeTools(store: try store(), spy: spy)

        let seen = try await call(tools, "browser_wait_for", ["text": "Agent words", "timeout": 2])
        XCTAssertFalse(seen.isError, seen.content)
        XCTAssertTrue(seen.content.hasPrefix("satisfied"), seen.content)
        XCTAssertFalse(spy.reads.isEmpty)
        XCTAssertTrue(spy.reads.allSatisfy(\.keepingRefs))

        // On the live page, not on the agent's: never satisfied.
        let raw = try await call(tools, "browser_wait_for", ["text": "Raw words", "timeout": 0.3])
        XCTAssertTrue(raw.isError, raw.content)

        // An unavailable agent page satisfies nothing either.
        spy.reading = Self.reading(.unavailable("the walk failed.", url: nil), generation: nil)
        let unavailable = try await call(tools, "browser_wait_for", ["text": "Agent words", "timeout": 0.3])
        XCTAssertTrue(unavailable.isError, unavailable.content)
    }

    func test_titlesConcealedInList() async throws {
        directory.panes = [pane(privacy: .enabled(privateWords))]
        let tools = makeTools(store: try store())
        let list = try await call(tools, "browser_list")
        XCTAssertFalse(list.isError, list.content)
        let rows = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(list.content.utf8)) as? [[String: Any]])
        let builder = AgentPageBuilder(privacy: .enabled(privateWords), hideImages: false)
        XCTAssertEqual(rows.first?["title"] as? String, builder.conceal("Beta"))
        XCTAssertEqual(rows.first?["title"] as? String, "Gamma")
        XCTAssertFalse(list.content.contains("Beta"), list.content)

        // A closed pane still names nothing of its page.
        directory.panes = [pane(privacy: .unavailable)]
        let closed = try await call(tools, "browser_list")
        let closedRows = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: Data(closed.content.utf8)) as? [[String: Any]])
        XCTAssertEqual(closedRows.first?["title"] as? String, "(concealed)")
    }

    func test_unavailablePageReturnsReason() async throws {
        let reason = "Agent view unavailable: the walk failed."
        let spy = SpyAgentPageReader(Self.reading(.unavailable("the walk failed.", url: nil), generation: nil))
        let tools = makeTools(store: try store(), spy: spy)
        let calls: [(String, [String: Any])] = [
            ("browser_snapshot", [:]), ("browser_text", [:]), ("browser_find", ["text": "Agent"])
        ]
        for (name, args) in calls {
            let reply = try await call(tools, name, args)
            XCTAssertFalse(reply.isError, "\(name): \(reply.content)")
            XCTAssertEqual(reply.content, reason, name)
        }
        XCTAssertEqual(spy.reads.count, 3)
    }

    func test_historyToolUsesConceal() async throws {
        let privacy = BrowserAgentPrivacy.enabled(privateWords)
        let visit = BrowserVisitLine(title: "Beta home", url: "http://fixture.test/Two", when: nil)
        let reply = try await BrowserHistoryTool.run(
            access: .currentTab, query: nil, limit: 10, store: nil, backForward: [visit], privacy: privacy)
        let builder = AgentPageBuilder(privacy: privacy, hideImages: false)
        XCTAssertEqual(reply, builder.conceal(visit.title) + "  " + builder.conceal(visit.url))
        XCTAssertFalse(reply.contains("Beta") || reply.contains("Two"), reply)

        let open = try await BrowserHistoryTool.run(
            access: .currentTab, query: nil, limit: 10, store: nil, backForward: [visit], privacy: .off)
        XCTAssertEqual(open, "Beta home  http://fixture.test/Two")
    }
}
