import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class BrowserHiddenItemsStoreTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHiddenItemsStoreTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var fileURL: URL { directory.appendingPathComponent(BrowserHiddenItemsStore.fileName) }

    private func makeStore() throws -> BrowserHiddenItemsStore {
        try BrowserHiddenItemsStore.open(at: fileURL)
    }

    private func entry(
        _ list: BrowserHiddenItemList, site: String = "example.com/*", selector: String,
        enabled: Bool = true
    ) -> BrowserHiddenItem {
        BrowserHiddenItem(
            list: list, site: site, selector: selector, scope: .thisItem, label: selector,
            enabled: enabled, created: Date(timeIntervalSinceReferenceDate: 1_000))
    }

    private let examplePage = URL(string: "https://example.com/")!

    // hidden-items-store-001
    func test_addAndListBySite() throws {
        let store = try makeStore()
        let added = try store.add(entry(.user, selector: ".ad"))
        XCTAssertNotNil(added.id)
        XCTAssertEqual(try store.items(list: .user, for: URL(string: "https://example.com/a")!), [added])
        XCTAssertEqual(try store.items(list: .user, for: URL(string: "https://other.com/")!), [])
    }

    // hidden-items-store-002
    func test_listsAreSeparate() throws {
        let store = try makeStore()
        let agent = try store.add(entry(.agent, selector: "#secret"))
        XCTAssertEqual(try store.items(list: .user, for: examplePage), [])
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [])
        XCTAssertEqual(try store.items(list: .agent, for: examplePage), [agent])
    }

    // hidden-items-store-003
    func test_everyFieldRoundTrips() throws {
        let store = try makeStore()
        let item = BrowserHiddenItem(
            list: .agent, site: "foo.com/hi/*", selector: "div.x", scope: .allLikeIt,
            label: #"div "Sponsored""#, enabled: false, created: Date(timeIntervalSince1970: 1_700_000_000.25))
        let added = try store.add(item)
        var expected = item
        expected.id = added.id
        XCTAssertEqual(try store.items(list: .agent, for: URL(string: "https://foo.com/hi/there")!), [expected])
    }

    // hidden-items-store-004
    func test_siteDefaultsFromThePage() {
        let fromPage = BrowserHiddenItem(
            list: .user, pageURL: URL(string: "https://News.Example.com/story/1"), selector: ".a",
            scope: .thisItem, label: "")
        XCTAssertEqual(fromPage.site, "news.example.com/*")
        let noHost = BrowserHiddenItem(
            list: .user, pageURL: URL(string: "about:blank"), selector: ".a", scope: .thisItem, label: "")
        XCTAssertEqual(noHost.site, "*")
    }

    // hidden-items-store-005
    func test_noAddressMatchesOnlyEverywhere() throws {
        let store = try makeStore()
        let everywhere = try store.add(entry(.user, site: "*", selector: ".all"))
        try store.add(entry(.user, selector: ".ex"))
        XCTAssertEqual(try store.items(list: .user, for: nil), [everywhere])
    }

    // hidden-items-store-006
    func test_disabledNotInEnabledSelectors() throws {
        let store = try makeStore()
        try store.add(entry(.user, selector: ".a"))
        try store.add(entry(.user, selector: ".b", enabled: false))
        XCTAssertEqual(try store.items(list: .user, for: examplePage).map(\.selector), [".a", ".b"])
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [".a"])
    }

    // hidden-items-store-007
    func test_setEnabledChangesOnlyTheFlag() throws {
        let store = try makeStore()
        let first = try store.add(entry(.user, selector: ".a"))
        let id = try XCTUnwrap(first.id)
        try store.setEnabled(id, false)
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [])
        var disabled = first
        disabled.enabled = false
        XCTAssertEqual(try store.items(list: .user, for: examplePage), [disabled])
        try store.setEnabled(id, true)
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [".a"])
    }

    // hidden-items-store-008
    func test_removeDeletesTheEntry() throws {
        let store = try makeStore()
        let first = try store.add(entry(.user, selector: ".a"))
        try store.add(entry(.user, selector: ".b", enabled: false))
        try store.remove(try XCTUnwrap(first.id))
        XCTAssertEqual(try store.items(list: .user, for: examplePage).map(\.selector), [".b"])
    }

    // hidden-items-store-009
    func test_siteSwitchDefaultsOn() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.isSiteSwitchOn(list: .user, site: "example.com/*"))
        XCTAssertTrue(try store.isSiteSwitchOn(list: .agent, site: "example.com/*"))
    }

    // hidden-items-store-010
    func test_siteSwitchOffHidesUserList() throws {
        let store = try makeStore()
        try store.add(entry(.user, selector: ".a"))
        try store.setSiteSwitch(list: .user, site: "example.com/*", on: false)
        XCTAssertFalse(try store.isSiteSwitchOn(list: .user, site: "example.com/*"))
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [])
        XCTAssertEqual(try store.items(list: .user, for: examplePage).map(\.selector), [".a"])
        try store.setSiteSwitch(list: .user, site: "example.com/*", on: true)
        XCTAssertEqual(try store.enabledSelectors(list: .user, for: examplePage), [".a"])
    }

    // hidden-items-store-011
    func test_agentListIgnoresSiteSwitch() throws {
        let store = try makeStore()
        try store.add(entry(.agent, selector: "#s"))
        try store.setSiteSwitch(list: .user, site: "example.com/*", on: false)
        try store.setSiteSwitch(list: .agent, site: "example.com/*", on: false)
        XCTAssertEqual(try store.enabledSelectors(list: .agent, for: examplePage), ["#s"])
    }

    // hidden-items-store-012
    func test_changePostsNotification() throws {
        let store = try makeStore()
        let record = NotificationRecord()
        let page = examplePage
        let observer = NotificationCenter.default.addObserver(
            forName: BrowserHiddenItemsStore.didChangeNotification, object: store, queue: nil
        ) { _ in
            record.note((try? store.enabledSelectors(list: .user, for: page)) ?? ["<error>"])
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let first = try store.add(entry(.user, selector: ".a"))
        XCTAssertEqual(record.count, 1)
        XCTAssertEqual(record.lastSelectors, [".a"], "posted after the add is readable")
        let id = try XCTUnwrap(first.id)
        try store.setEnabled(id, false)
        XCTAssertEqual(record.count, 2)
        XCTAssertEqual(record.lastSelectors, [], "posted after the disable is readable")
        try store.remove(id)
        XCTAssertEqual(record.count, 3)
        try store.setSiteSwitch(list: .user, site: "example.com/*", on: false)
        XCTAssertEqual(record.count, 4)
    }

    // hidden-items-store-013
    func test_reopenKeepsEntries() throws {
        var store: BrowserHiddenItemsStore? = try makeStore()
        let first = try XCTUnwrap(store).add(entry(.user, selector: ".a"))
        let second = try XCTUnwrap(store).add(entry(.agent, selector: "#b", enabled: false))
        try XCTUnwrap(store).setSiteSwitch(list: .user, site: "example.com/*", on: false)
        store = nil

        let reopened = try makeStore()
        XCTAssertEqual(try reopened.items(list: .user, for: examplePage), [first])
        XCTAssertEqual(try reopened.items(list: .agent, for: examplePage), [second])
        XCTAssertFalse(try reopened.isSiteSwitchOn(list: .user, site: "example.com/*"))
    }

    func test_emptySelectorIsRefused() throws {
        let store = try makeStore()
        XCTAssertThrowsError(try store.add(entry(.user, selector: "  "))) { error in
            XCTAssertEqual(error as? BrowserHiddenItemsStoreError, .emptySelector)
        }
    }

    // hidden-items-store-014
    func test_defaultURLIsItsOwnFileInTheAppHome() {
        let home = URL(fileURLWithPath: "/Users/someone")
        let url = BrowserHiddenItemsStore.defaultURL(
            environment: [:], home: home, token: "AgenticDeveloperKitchen")
        XCTAssertEqual(url.path, "/Users/someone/.agenticdeveloperkitchen/BrowserHiddenItems.db")
    }

    // hidden-items-store-015
    func test_defaultURLFollowsTestHome() {
        let url = BrowserHiddenItemsStore.defaultURL(
            environment: ["APP_TEST_HOME": "/tmp/scratch"], home: URL(fileURLWithPath: "/Users/someone"),
            token: "AgenticDeveloperKitchen")
        XCTAssertEqual(url.path, "/tmp/scratch/.agenticdeveloperkitchen/BrowserHiddenItems.db")
    }

    /// The launch open runs off the main thread, and a read before it is done
    /// waits for the store rather than answering "no store" (final review
    /// C-M3: privacy fails closed).
    @MainActor
    func test_currentOpensInTheBackgroundAndAReadWaitsForIt() throws {
        let saved = BrowserHiddenItemsStore.current
        defer { BrowserHiddenItemsStore.current = saved }
        BrowserHiddenItemsStore.current = nil
        XCTAssertFalse(BrowserHiddenItemsStore.hasCurrent)

        BrowserHiddenItemsStore.openCurrent(at: fileURL)
        XCTAssertTrue(BrowserHiddenItemsStore.hasCurrent)
        let store = try XCTUnwrap(
            BrowserHiddenItemsStore.current as? BrowserHiddenItemsStore, "a read in the gap saw no store")
        XCTAssertEqual(store.url, fileURL)
        XCTAssertTrue(BrowserHiddenItemsStore.current === store)

        // A file that cannot be opened leaves no store, and says so.
        let blocker = directory.appendingPathComponent("file")
        try Data().write(to: blocker)
        let failed = expectation(description: "failure reported")
        BrowserHiddenItemsStore.openCurrent(at: blocker.appendingPathComponent("x.db")) { _ in failed.fulfill() }
        XCTAssertNil(BrowserHiddenItemsStore.current)
        wait(for: [failed], timeout: 5)
    }

    /// ``currentStore()`` awaits the open in flight rather than blocking the
    /// main thread on it, and answers nil when the open failed (re-review
    /// follow-up).
    @MainActor
    func test_currentStoreAwaitsTheOpenAndFailsClosedToNil() async throws {
        let saved = BrowserHiddenItemsStore.current
        defer { BrowserHiddenItemsStore.current = saved }
        BrowserHiddenItemsStore.current = nil
        let none = await BrowserHiddenItemsStore.currentStore()
        XCTAssertNil(none)

        BrowserHiddenItemsStore.openCurrent(at: fileURL)
        let awaited = await BrowserHiddenItemsStore.currentStore()
        let store = try XCTUnwrap(awaited as? BrowserHiddenItemsStore, "an await in the gap saw no store")
        XCTAssertEqual(store.url, fileURL)
        let again = await BrowserHiddenItemsStore.currentStore()
        XCTAssertTrue(again === store)
        XCTAssertTrue(BrowserHiddenItemsStore.current === store, "the blocking getter agrees")

        let blocker = directory.appendingPathComponent("file")
        try Data().write(to: blocker)
        BrowserHiddenItemsStore.openCurrent(at: blocker.appendingPathComponent("x.db"))
        let failed = await BrowserHiddenItemsStore.currentStore()
        XCTAssertNil(failed)
        XCTAssertFalse(BrowserHiddenItemsStore.hasCurrent)
    }
}

/// What the change observer saw, behind a lock: the observer block is
/// `@Sendable`, so it cannot mutate a captured local.
private final class NotificationRecord: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    private var _lastSelectors: [String] = []

    var count: Int { lock.withLock { _count } }
    var lastSelectors: [String] { lock.withLock { _lastSelectors } }

    func note(_ selectors: [String]) {
        lock.withLock {
            _count += 1
            _lastSelectors = selectors
        }
    }
}
