import XCTest
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKCore

/// `BrowserHistoryTool.run`, the `browser_history` tool's answer apart from
/// the pane (the Agent History Tool recipe).
final class BrowserHistoryToolTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHistoryToolTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// A store holding `count` visits to `https://example.com/<n>`, titled
    /// "Page <n>", one second apart, so the last one is the newest.
    private func makeStore(visits count: Int) throws -> BrowserHistoryStore {
        let store = try BrowserHistoryStore(path: directory.appendingPathComponent("BrowserHistory.db").path)
        for index in 0..<count {
            try store.record(URL(string: "https://example.com/\(index)")!, title: "Page \(index)",
                             at: Date(timeIntervalSince1970: 1_000 + Double(index)))
        }
        return store
    }

    private func run(
        _ access: BrowserAgentHistoryAccess, query: String? = nil, limit: Int = BrowserHistoryTool.defaultLimit,
        store: BrowserHistoryStore? = nil, backForward: [BrowserVisitLine] = [], privacy: BrowserAgentPrivacy = .off
    ) async throws -> String {
        try await BrowserHistoryTool.run(access: access, query: query, limit: limit, store: store,
                                         backForward: backForward, privacy: privacy)
    }

    private func lines(_ reply: String) -> [String] {
        reply.split(separator: "\n").map(String.init)
    }

    // agent-history-tool-005
    func test_noneRefuses() async throws {
        let store = try makeStore(visits: 5)
        do {
            let reply = try await run(.none, store: store,
                                      backForward: [BrowserVisitLine(title: "A", url: "https://a.example/", when: nil)])
            XCTFail("None must refuse, got \(reply)")
        } catch let error as BrowserToolSet.ToolError {
            XCTAssertEqual(error.sentence,
                           "History is not shared with the agent for this pane "
                           + "(Settings › Web Browser › Privacy and Security › Agent can see history).")
        }
    }

    // agent-history-tool-006
    func test_currentTabUsesBackForwardOnly() async throws {
        let store = try makeStore(visits: 5)
        let backForward = [
            BrowserVisitLine(title: "Current", url: "https://tab.example/current", when: nil),
            BrowserVisitLine(title: "Back", url: "https://tab.example/back", when: nil)
        ]
        let reply = lines(try await run(.currentTab, store: store, backForward: backForward))
        XCTAssertEqual(reply.count, 2, reply.joined(separator: "\n"))
        XCTAssertTrue(reply[0].contains("https://tab.example/current"))
        XCTAssertTrue(reply[1].contains("https://tab.example/back"))
        XCTAssertFalse(reply.contains { $0.contains("example.com") }, "the store must not be read")
    }

    // agent-history-tool-008, agent-history-tool-009
    func test_allSearchesStore() async throws {
        let store = try makeStore(visits: 5)
        try store.record(URL(string: "https://docs.example/guide")!, title: "Guide",
                         at: Date(timeIntervalSince1970: 500))

        let recent = lines(try await run(.all, store: store))
        XCTAssertEqual(recent.count, 6)
        XCTAssertTrue(recent[0].contains("https://example.com/4"), "newest first")

        let found = lines(try await run(.all, query: "docs", store: store))
        XCTAssertEqual(found.count, 1, found.joined(separator: "\n"))
        XCTAssertTrue(found[0].contains("https://docs.example/guide"))
        XCTAssertTrue(found[0].contains("Guide"))
    }

    // agent-history-tool-012
    func test_historyConcealsTitles() async throws {
        let privacy = BrowserAgentPrivacy.enabled(TextSubstitutionFilter(pairs: [.init(alias: "Globex", real: "Acme")]))
        let reply = try await run(.currentTab, backForward: [
            BrowserVisitLine(title: "Acme Inc", url: "https://news.example/", when: nil)
        ], privacy: privacy)
        XCTAssertTrue(reply.contains("Globex Inc"), reply)
        XCTAssertFalse(reply.localizedCaseInsensitiveContains("Acme"), reply)
    }

    // agent-history-tool-013
    func test_historyConcealsURLForms() async throws {
        let privacy = BrowserAgentPrivacy.enabled(
            TextSubstitutionFilter(pairs: [.init(alias: "Globex Co", real: "Acme Corp")]))
        let urls = ["https://x/?q=Acme%20Corp", "https://x/?q=acme%20corp", "https://x/?q=Acme+Corp"]
        let reply = try await run(.currentTab, backForward: urls.map {
            BrowserVisitLine(title: "Search", url: $0, when: nil)
        }, privacy: privacy)
        XCTAssertEqual(lines(reply).count, 3, reply)
        XCTAssertFalse(reply.localizedCaseInsensitiveContains("acme"), reply)
        XCTAssertTrue(reply.contains("Globex%20Co"), reply)
        XCTAssertTrue(reply.contains("Globex+Co"), reply)
    }

    // agent-history-tool-010
    func test_limitClampedTo200() async throws {
        let store = try makeStore(visits: 300)
        let byDefault = try await run(.all, store: store)
        XCTAssertEqual(lines(byDefault).count, 50)
        let capped = try await run(.all, limit: 500, store: store)
        XCTAssertEqual(lines(capped).count, 200)
        let backForward = (0..<300).map { BrowserVisitLine(title: "T\($0)", url: "https://t.example/\($0)", when: nil) }
        let cappedTab = try await run(.currentTab, limit: 500, backForward: backForward)
        XCTAssertEqual(lines(cappedTab).count, 200)
    }
}
