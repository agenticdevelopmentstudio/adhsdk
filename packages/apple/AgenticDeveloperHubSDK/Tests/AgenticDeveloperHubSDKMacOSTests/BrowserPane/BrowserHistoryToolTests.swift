import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

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
        try await store.record(URL(string: "https://docs.example/guide")!, title: "Guide",
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

    // A word scoped to another site is concealed on that site's lines while
    // the pane is on a different site (final review A-I2 / C-C1).
    func test_historyConcealsWordsScopedToAnotherSite() async throws {
        let words = [
            PrivacyWord(alias: "Globex", real: "Acme", sites: ["bank.example"]),
            PrivacyWord(alias: "Initech", real: "Hooli", sites: [PrivacySitePattern.everywhere]),
            PrivacyWord(alias: "Umbrella", real: "Wayne", isEnabled: false)
        ]
        let paneURL = URL(string: "https://news.example/")!
        // The page in front's words alone would leave "Acme" in clear.
        let paneOnly = BrowserAgentPrivacy.checking(words.filter(for: paneURL))
        XCTAssertFalse(words.filter(for: paneURL).pairs.contains { $0.real == "Acme" })
        let history = BrowserAgentPrivacy.checking(words.everySiteFilter).combined(with: paneOnly)
        let backForward = [BrowserVisitLine(title: "Acme statement", url: "https://bank.example/Acme", when: nil),
                           BrowserVisitLine(title: "Hooli Wayne", url: "https://news.example/", when: nil)]
        let reply = try await run(.currentTab, backForward: backForward, privacy: history)
        XCTAssertFalse(reply.contains("Acme"), reply)
        XCTAssertTrue(reply.contains("Globex statement"), reply)
        XCTAssertTrue(reply.contains("https://bank.example/Globex"), reply)
        XCTAssertTrue(reply.contains("Initech"), reply)
        XCTAssertTrue(reply.contains("Wayne"), "a disabled word is not applied: \(reply)")

        let store = try makeStore(visits: 0)
        try store.record(URL(string: "https://bank.example/Acme")!, title: "Acme statement")
        let all = try await run(.all, store: store, privacy: history)
        XCTAssertFalse(all.contains("Acme"), all)
    }

    // A query is matched against what the agent sees, never the concealed
    // text, so a reply cannot confirm a guess at a privacy word (review f5).
    func test_queryMatchesConcealedTextOnly() async throws {
        let privacy = BrowserAgentPrivacy.enabled(TextSubstitutionFilter(pairs: [.init(alias: "Globex", real: "Acme")]))
        let backForward = [BrowserVisitLine(title: "Acme statement", url: "https://bank.example/Acme", when: nil),
                           BrowserVisitLine(title: "News", url: "https://news.example/", when: nil)]
        let tabGuess = try await run(.currentTab, query: "acme", backForward: backForward, privacy: privacy)
        XCTAssertEqual(tabGuess, BrowserHistoryTool.emptyReply)
        let tabAlias = lines(try await run(.currentTab, query: "globex", backForward: backForward, privacy: privacy))
        XCTAssertEqual(tabAlias.count, 1, "\(tabAlias)")
        XCTAssertTrue(tabAlias[0].contains("Globex statement"))

        // More visits than one store page, the concealed ones oldest, so the
        // match has to walk past the first page and still keep its order.
        let store = try makeStore(visits: 0)
        for index in 0..<3 {
            try await store.record(URL(string: "https://bank.example/Acme/\(index)")!, title: "Acme \(index)",
                             at: Date(timeIntervalSince1970: 100 + Double(index)))
        }
        for index in 0..<(BrowserHistoryTool.matchPageSize + 10) {
            try await store.record(URL(string: "https://example.com/\(index)")!, title: "Page \(index)",
                             at: Date(timeIntervalSince1970: 1_000 + Double(index)))
        }
        let guess = try await run(.all, query: "acme", store: store, privacy: privacy)
        XCTAssertEqual(guess, BrowserHistoryTool.emptyReply)
        let alias = lines(try await run(.all, query: "Globex", limit: 2, store: store, privacy: privacy))
        XCTAssertEqual(alias.count, 2, "\(alias)")
        XCTAssertTrue(alias[0].contains("https://bank.example/Globex/2"), "newest first: \(alias)")
        XCTAssertTrue(alias[1].contains("https://bank.example/Globex/1"), "\(alias)")
        XCTAssertFalse(alias.contains { $0.localizedCaseInsensitiveContains("acme") }, "\(alias)")
        let unconcealed = lines(try await run(.all, query: "page 1", limit: 3, store: store, privacy: privacy))
        XCTAssertEqual(unconcealed.count, 3, "\(unconcealed)")
        XCTAssertTrue(unconcealed[0].contains("Page 199 "), "newest match first: \(unconcealed)")
    }

    /// A handle made without a history privacy while Agent Privacy is on
    /// refuses history rather than concealing with the page's words alone.
    @MainActor
    func test_handleWithoutHistoryPrivacyFailsClosed() {
        let automation = BrowserAutomation(webView: WKWebView(), console: BrowserConsoleLog())
        let enabled = BrowserPaneHandle(id: "p", project: "", tab: "", automation: automation,
                                        agentPrivacy: .enabled(TextSubstitutionFilter(pairs: [])), hidesImages: false)
        XCTAssertEqual(enabled.historyPrivacy, .unavailable)
        let off = BrowserPaneHandle(id: "p", project: "", tab: "", automation: automation, hidesImages: false)
        XCTAssertEqual(off.historyPrivacy, .off)
    }

    // Local files never reach the agent through history (final review A-I3).
    func test_historyLeavesOutLocalFiles() async throws {
        let store = try makeStore(visits: 3)
        for index in 0..<5 {
            try await store.record(URL(string: "file:///Users/someone/Clients/Report\(index).html")!,
                             title: "Client report \(index)", at: Date(timeIntervalSince1970: 5_000 + Double(index)))
        }
        let recent = lines(try await run(.all, limit: 3, store: store))
        XCTAssertEqual(recent.count, 3, "the limit counts only listed visits: \(recent)")
        XCTAssertFalse(recent.contains { $0.contains("file:") || $0.contains("Client report") }, "\(recent)")
        let searched = try await run(.all, query: "Report", store: store)
        XCTAssertEqual(searched, BrowserHistoryTool.emptyReply)

        let backForward = [BrowserVisitLine(title: "Local", url: "FILE:///tmp/a.html", when: nil),
                           BrowserVisitLine(title: "Web", url: "https://web.example/", when: nil)]
        let tab = lines(try await run(.currentTab, backForward: backForward))
        XCTAssertEqual(tab.count, 1, "\(tab)")
        XCTAssertTrue(tab[0].contains("https://web.example/"))
    }
}
