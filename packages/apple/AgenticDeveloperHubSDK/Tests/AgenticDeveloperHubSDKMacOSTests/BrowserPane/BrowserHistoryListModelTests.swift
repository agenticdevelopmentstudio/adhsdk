import XCTest
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// The History panel's list model, on a store in a temporary directory —
/// never the user's history file.
@MainActor
final class BrowserHistoryListModelTests: XCTestCase {

    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHistoryListModelTests-\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> BrowserHistoryStore {
        try BrowserHistoryStore(path: directory.appendingPathComponent("BrowserHistory.db").path)
    }

    @discardableResult
    private func record(
        _ store: BrowserHistoryStore, _ url: String, _ title: String, at seconds: TimeInterval
    ) throws -> Int64 {
        try store.record(URL(string: url)!, title: title, at: Date(timeIntervalSince1970: seconds))
    }

    func test_emptyFilterShowsRecent() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/1", "One", at: 1_000)
        try record(store, "https://example.com/2", "Two", at: 2_000)
        try record(store, "https://example.com/3", "Three", at: 3_000)
        let model = BrowserHistoryListModel(store: store)

        await model.reload()

        XCTAssertEqual(model.visits.count, 3)
        XCTAssertEqual(model.visits.map(\.title), ["Three", "Two", "One"])
    }

    func test_filterSearchesTitleAndAddress() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/home", "Kitchen", at: 1_000)
        try record(store, "https://kit.example", "Tools", at: 2_000)
        try record(store, "https://example.com/other", "Elsewhere", at: 3_000)
        let model = BrowserHistoryListModel(store: store)

        model.filter = "kit"
        await model.reload()

        XCTAssertEqual(model.visits.map(\.title), ["Tools", "Kitchen"])
    }

    func test_filterIsTrimmed() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/home", "Kitchen", at: 1_000)
        try record(store, "https://example.com/other", "Elsewhere", at: 2_000)
        let model = BrowserHistoryListModel(store: store)

        model.filter = "  kit "
        await model.reload()
        XCTAssertEqual(model.visits.map(\.title), ["Kitchen"])

        model.filter = "   "
        await model.reload()
        XCTAssertEqual(model.visits.map(\.title), ["Elsewhere", "Kitchen"])
    }

    func test_latestFilterWins() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/alpha", "Alpha", at: 1_000)
        try record(store, "https://example.com/abbey", "Abbey", at: 2_000)
        let model = BrowserHistoryListModel(store: store)
        var published: [[String]] = []
        let changed = expectation(description: "the list changed")
        changed.assertForOverFulfill = true
        model.onChange = {
            published.append(model.visits.map(\.title))
            changed.fulfill()
        }

        // Neither change is awaited: the reload for "a" is still in flight
        // when "ab" replaces it, and only "ab"'s answer may be published.
        model.filter = "a"
        model.filter = "ab"
        await fulfillment(of: [changed], timeout: 5)

        XCTAssertEqual(published, [["Abbey"]])
        XCTAssertEqual(model.visits.map(\.title), ["Abbey"])
    }

    func test_removeDeletesFromStore() async throws {
        let store = try makeStore()
        let first = try record(store, "https://example.com/1", "One", at: 1_000)
        try record(store, "https://example.com/2", "Two", at: 2_000)
        let model = BrowserHistoryListModel(store: store)
        await model.reload()
        let countBefore = try await store.count()
        XCTAssertEqual(countBefore, 2)

        await model.remove([first])

        let countAfter = try await store.count()
        XCTAssertEqual(countAfter, 1)
        XCTAssertEqual(model.visits.map(\.title), ["Two"])
    }

    func test_clearAll() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/1", "One", at: 1_000)
        try record(store, "https://example.com/2", "Two", at: 2_000)
        let model = BrowserHistoryListModel(store: store)
        await model.reload()
        XCTAssertEqual(model.visits.count, 2)

        await model.clearAll()

        let remaining = try await store.count()
        XCTAssertEqual(remaining, 0)
        XCTAssertTrue(model.visits.isEmpty)
    }

    /// A visit recorded while the list is open appears in it (final review
    /// C-M2).
    func test_aVisitRecordedElsewhereRereadsTheList() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/1", "One", at: 1_000)
        let model = BrowserHistoryListModel(store: store)
        await model.reload()
        XCTAssertEqual(model.visits.map(\.title), ["One"])

        let reread = expectation(description: "the list reread")
        model.onChange = { if model.visits.count == 2 { reread.fulfill() } }
        _ = try await store.perform { try $0.record(URL(string: "https://example.com/2")!, title: "Two") }
        await fulfillment(of: [reread], timeout: 5)
        XCTAssertEqual(model.visits.map(\.title), ["Two", "One"])
    }

    /// Return opens every selected visit, not only the first (final review
    /// C-M2).
    func test_panelOpensEverySelectedVisit() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/1", "One", at: 1_000)
        try record(store, "https://example.com/2", "Two", at: 2_000)
        try record(store, "https://example.com/3", "Three", at: 3_000)
        let model = BrowserHistoryListModel(store: store)
        var opened: [String] = []
        let panel = BrowserHistoryPanelViewController(model: model, open: { opened.append($0.absoluteString) })
        _ = panel.view
        await model.reload()

        panel.selectRows(IndexSet([0, 2]))
        panel.openSelected()

        XCTAssertEqual(opened, ["https://example.com/3", "https://example.com/1"])
    }

    /// A visit recorded at the top while a row is selected keeps the same
    /// visit selected, not the one that moved into its row (review f6).
    func test_panelSelectionSurvivesAReloadByVisitID() async throws {
        let store = try makeStore()
        try record(store, "https://example.com/a", "A", at: 1_000)
        let visitB = try record(store, "https://example.com/b", "B", at: 2_000)
        let visitC = try record(store, "https://example.com/c", "C", at: 3_000)
        let model = BrowserHistoryListModel(store: store)
        let panel = BrowserHistoryPanelViewController(model: model, open: { _ in })
        _ = panel.view
        await model.reload()
        XCTAssertEqual(model.visits.map(\.title), ["C", "B", "A"])

        panel.selectRows(IndexSet([1]))
        XCTAssertEqual(panel.selectedVisitIDs, [visitB])

        let panelChanged = model.onChange
        let reread = expectation(description: "the list reread")
        model.onChange = {
            panelChanged?()
            if model.visits.count == 4 { reread.fulfill() }
        }
        _ = try await store.perform {
            try $0.record(URL(string: "https://example.com/n")!, title: "N", at: Date(timeIntervalSince1970: 4_000))
        }
        await fulfillment(of: [reread], timeout: 5)

        XCTAssertEqual(model.visits.map(\.title), ["N", "C", "B", "A"])
        XCTAssertEqual(panel.selectedVisitIDs, [visitB])
        XCTAssertNotEqual(panel.selectedVisitIDs, [visitC])
    }
}
