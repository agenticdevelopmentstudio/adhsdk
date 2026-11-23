import XCTest
import AgenticDeveloperHubSDKDatabase

/// The behaviour every `BrowserHistoryStoring` and `BrowserHiddenItemsStoring`
/// owes its consumers, written once and run against each conformer: the local
/// SQLite stores here, the daemon's adapters in adh-daemon's client tests.
///
/// Deliberately free of `@testable` and of any one store's type, so another
/// test bundle can compile this file into itself (a `sources:` path, as the
/// macOS tests share `FakeBillingClient`) and hand it its own store. Each
/// check takes a factory for an empty store, so the checks cannot see one
/// another's rows.
enum BrowserStoringConformance {

    /// How long a check waits for a change it expects, and then for one it
    /// must not see.
    static let changeWait: TimeInterval = 5
    static let quietWait: UInt64 = 300_000_000

    // MARK: - History

    static func historyRecordsAndListsNewestFirst(
        _ make: () async throws -> any BrowserHistoryStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let first = try await store.record(URL(string: "https://example.com/1")!, title: "One", at: base)
        let second = try await store.record(
            URL(string: "https://example.com/2")!, title: "Two", at: base.addingTimeInterval(60))
        let third = try await store.record(
            URL(string: "https://example.com/3")!, title: "Three", at: base.addingTimeInterval(120))
        XCTAssertNotEqual(first, second, file: file, line: line)
        XCTAssertNotEqual(second, third, file: file, line: line)

        let all = try await store.recent(limit: 200, before: nil, excludingLocalFiles: false)
        XCTAssertEqual(all.map(\.title), ["Three", "Two", "One"], file: file, line: line)
        XCTAssertEqual(all.map(\.id), [third, second, first], file: file, line: line)
        XCTAssertEqual(all.last?.visitedAt, base, file: file, line: line)
        let count = try await store.count()
        XCTAssertEqual(count, 3, file: file, line: line)

        let limited = try await store.recent(limit: 2, before: nil, excludingLocalFiles: false)
        XCTAssertEqual(limited.map(\.title), ["Three", "Two"], file: file, line: line)
        let next = try await store.recent(limit: 2, before: limited.last, excludingLocalFiles: false)
        XCTAssertEqual(next.map(\.title), ["One"], "keyset paging", file: file, line: line)

        try await store.updateTitle(ofVisit: first, to: "Uno")
        let renamed = try await store.recent(limit: 1, before: limited.last, excludingLocalFiles: false)
        XCTAssertEqual(renamed.map(\.title), ["Uno"], file: file, line: line)
    }

    static func historyLeavesOutLocalFilesWhenAsked(
        _ make: () async throws -> any BrowserHistoryStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        try await store.record(URL(string: "https://example.com/page")!, title: "Page", at: base)
        try await store.record(URL(fileURLWithPath: "/tmp/notes.html"), title: "Notes", at: base.addingTimeInterval(1))
        let shown = try await store.recent(limit: 1, before: nil, excludingLocalFiles: true)
        XCTAssertEqual(shown.map(\.title), ["Page"], "the filter applies before the limit", file: file, line: line)
        let found = try await store.search("e", limit: 200, excludingLocalFiles: true)
        XCTAssertEqual(found.map(\.title), ["Page"], file: file, line: line)
    }

    static func historySearchesAddressAndTitle(
        _ make: () async throws -> any BrowserHistoryStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        try await store.record(URL(string: "https://swift.org/docs")!, title: "Documentation", at: base)
        try await store.record(
            URL(string: "https://example.com/a")!, title: "Learning Swift", at: base.addingTimeInterval(1))
        try await store.record(
            URL(string: "https://example.com/b")!, title: "100% cotton", at: base.addingTimeInterval(2))

        let swift = try await store.search("swift", limit: 200, excludingLocalFiles: false)
        XCTAssertEqual(swift.map(\.title), ["Learning Swift", "Documentation"],
                       "address and title, any case, newest first", file: file, line: line)
        let percent = try await store.search("%", limit: 200, excludingLocalFiles: false)
        XCTAssertEqual(percent.map(\.title), ["100% cotton"], "a wildcard is searched for literally",
                       file: file, line: line)
        let limited = try await store.search("example", limit: 1, excludingLocalFiles: false)
        XCTAssertEqual(limited.count, 1, file: file, line: line)
        let none = try await store.search("nothing like it", limit: 200, excludingLocalFiles: false)
        XCTAssertTrue(none.isEmpty, file: file, line: line)
    }

    static func historyRemovesBeforeACutoffAndOneByOne(
        _ make: () async throws -> any BrowserHistoryStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        try await store.record(URL(string: "https://example.com/old")!, title: "Old", at: base)
        try await store.record(URL(string: "https://example.com/edge")!, title: "Edge", at: base.addingTimeInterval(60))
        let newest = try await store.record(
            URL(string: "https://example.com/new")!, title: "New", at: base.addingTimeInterval(120))

        try await store.removeVisits(before: base.addingTimeInterval(60))
        let kept = try await store.recent(limit: 200, before: nil, excludingLocalFiles: false)
        XCTAssertEqual(kept.map(\.title), ["New", "Edge"], "the cutoff itself is kept", file: file, line: line)

        try await store.remove(visit: newest)
        let afterOne = try await store.recent(limit: 200, before: nil, excludingLocalFiles: false)
        XCTAssertEqual(afterOne.map(\.title), ["Edge"], file: file, line: line)

        try await store.removeAll()
        let count = try await store.count()
        XCTAssertEqual(count, 0, file: file, line: line)
    }

    static func historyChangesFireOncePerWrite(
        _ make: () async throws -> any BrowserHistoryStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let counter = ChangeCounter(store.changes)
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let id = try await store.record(URL(string: "https://example.com/1")!, title: "One", at: base)
        try await store.updateTitle(ofVisit: id, to: "Uno")
        try await store.record(URL(string: "https://example.com/2")!, title: "Two", at: base.addingTimeInterval(1))
        try await store.removeVisits(before: base.addingTimeInterval(1))
        try await store.remove(visit: id)
        try await store.removeAll()
        // Reads are not writes.
        _ = try await store.recent(limit: 200, before: nil, excludingLocalFiles: false)
        _ = try await store.search("x", limit: 200, excludingLocalFiles: false)
        _ = try await store.count()
        try await counter.expect(6, file: file, line: line)
    }

    // MARK: - Hidden items

    static func hiddenItemsAddsAndListsBySite(
        _ make: () async throws -> any BrowserHiddenItemsStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let page = URL(string: "https://example.com/news/today")!
        let added = try await store.add(BrowserHiddenItem(
            list: .user, pageURL: page, selector: ".ad", scope: .allLikeIt, label: "Ads"))
        XCTAssertNotNil(added.id, file: file, line: line)
        try await store.add(BrowserHiddenItem(
            list: .user, site: "other.org", selector: "#banner", scope: .thisItem, label: "Banner"))
        try await store.add(BrowserHiddenItem(
            list: .agent, pageURL: page, selector: ".price", scope: .thisItem, label: "Price"))

        let user = try await store.items(list: .user, for: page)
        XCTAssertEqual(user.map(\.selector), [".ad"], "only this site, only this list", file: file, line: line)
        let agent = try await store.items(list: .agent, for: page)
        XCTAssertEqual(agent.map(\.selector), [".price"], file: file, line: line)
        let everywhere = try await store.allItems(list: .user)
        XCTAssertEqual(everywhere.map(\.selector), [".ad", "#banner"], "every site, oldest first",
                       file: file, line: line)
    }

    static func hiddenItemsSelectorsFollowEnablingAndTheSiteSwitch(
        _ make: () async throws -> any BrowserHiddenItemsStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let page = URL(string: "https://example.com/")!
        let adItem = try await store.add(BrowserHiddenItem(
            list: .user, pageURL: page, selector: ".ad", scope: .allLikeIt, label: "Ads"))
        try await store.add(BrowserHiddenItem(
            list: .user, pageURL: page, selector: ".popup", scope: .allLikeIt, label: "Popups"))
        let adID = try XCTUnwrap(adItem.id, file: file, line: line)

        var selectors = try await store.enabledSelectors(list: .user, for: page)
        XCTAssertEqual(selectors, [".ad", ".popup"], file: file, line: line)

        try await store.setEnabled(adID, false)
        selectors = try await store.enabledSelectors(list: .user, for: page)
        XCTAssertEqual(selectors, [".popup"], file: file, line: line)
        let listed = try await store.items(list: .user, for: page)
        XCTAssertEqual(listed.count, 2, "a disabled entry is still listed", file: file, line: line)

        let site = adItem.site
        var isOn = try await store.isSiteSwitchOn(list: .user, site: site)
        XCTAssertTrue(isOn, "a switch never set is on", file: file, line: line)
        try await store.setSiteSwitch(list: .user, site: site, on: false)
        isOn = try await store.isSiteSwitchOn(list: .user, site: site)
        XCTAssertFalse(isOn, file: file, line: line)
        selectors = try await store.enabledSelectors(list: .user, for: page)
        XCTAssertEqual(selectors, [], "the switch off hides nothing on the site", file: file, line: line)

        try await store.remove(adID)
        let remaining = try await store.allItems(list: .user)
        XCTAssertEqual(remaining.map(\.selector), [".popup"], file: file, line: line)
    }

    static func hiddenItemsRefuseAnEmptySelector(
        _ make: () async throws -> any BrowserHiddenItemsStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        do {
            try await store.add(BrowserHiddenItem(
                list: .user, site: "*", selector: "  \n", scope: .thisItem, label: "Nothing"))
            XCTFail("an empty selector was stored", file: file, line: line)
        } catch let error as BrowserHiddenItemsStoreError {
            XCTAssertEqual(error, .emptySelector, file: file, line: line)
        }
        let all = try await store.allItems(list: .user)
        XCTAssertTrue(all.isEmpty, file: file, line: line)
    }

    static func hiddenItemsChangesFireOncePerWrite(
        _ make: () async throws -> any BrowserHiddenItemsStoring, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let store = try await make()
        let counter = ChangeCounter(store.changes)
        let item = try await store.add(BrowserHiddenItem(
            list: .user, site: "*", selector: ".ad", scope: .allLikeIt, label: "Ads"))
        let id = try XCTUnwrap(item.id, file: file, line: line)
        try await store.setEnabled(id, false)
        try await store.setSiteSwitch(list: .user, site: "*", on: false)
        try await store.remove(id)
        // Reads are not writes, and a refused add changed nothing.
        _ = try await store.allItems(list: .user)
        _ = try await store.enabledSelectors(list: .user, for: nil)
        _ = try? await store.add(BrowserHiddenItem(list: .user, site: "*", selector: "", scope: .thisItem, label: ""))
        try await counter.expect(4, file: file, line: line)
    }

    // MARK: - Counting changes

    /// Counts what a change stream yields, from the moment it is made.
    final class ChangeCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var seen = 0
        private var task: Task<Void, Never>?

        init(_ changes: AsyncStream<Void>) {
            task = Task { [weak self] in
                for await _ in changes { self?.bump() }
            }
        }

        deinit { task?.cancel() }

        private func bump() {
            lock.lock()
            seen += 1
            lock.unlock()
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return seen
        }

        /// Waits until `expected` changes have arrived, then a little longer
        /// to catch any extra, and asserts the count is exactly `expected`.
        func expect(_ expected: Int, file: StaticString, line: UInt) async throws {
            let deadline = Date().addingTimeInterval(BrowserStoringConformance.changeWait)
            while count < expected, Date() < deadline {
                try await Task.sleep(nanoseconds: 20_000_000)
            }
            try await Task.sleep(nanoseconds: BrowserStoringConformance.quietWait)
            XCTAssertEqual(count, expected, "one change per write", file: file, line: line)
            task?.cancel()
        }
    }
}
