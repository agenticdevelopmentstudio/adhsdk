import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The import methods adhd's Kitchen import writes through: each copies rows
/// from another file of the same store, keeps what is already here, and adds
/// nothing on a second run.
final class StoreImportTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoreImportTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Browser history

    private func history(_ name: String) throws -> BrowserHistoryStore {
        try BrowserHistoryStore(path: directory.appendingPathComponent(name).path)
    }

    func testVisitsAreImportedWithTheirIdsOnce() throws {
        let source = try history("source.db")
        try source.record(URL(string: "https://example.com/a")!, title: "A", at: Date(timeIntervalSince1970: 1_000))
        try source.record(URL(string: "https://example.com/b")!, title: "B", at: Date(timeIntervalSince1970: 2_000))
        let visits = try source.recent()

        let target = try history("target.db")
        let first = try target.importIfAbsent(visits)
        XCTAssertEqual(Set(first.map(\.id)), Set(visits.map(\.id)))
        XCTAssertEqual(try target.recent(), visits)

        XCTAssertEqual(try target.importIfAbsent(visits), [])
        XCTAssertEqual(try target.count(), 2)
    }

    func testAVisitWhoseIdIsTakenGetsAFreshOne() throws {
        let target = try history("target.db")
        let held = try target.record(URL(string: "https://here.example/")!, title: "Here",
                                     at: Date(timeIntervalSince1970: 500))
        let incoming = BrowserVisit(id: held, url: URL(string: "https://there.example/")!, title: "There",
                                    visitedAt: Date(timeIntervalSince1970: 900))

        let inserted = try target.importIfAbsent([incoming])
        XCTAssertEqual(inserted.count, 1)
        XCTAssertNotEqual(inserted.first?.id, held)
        XCTAssertEqual(try target.count(), 2)
        XCTAssertEqual(try target.importIfAbsent([incoming]), [])
    }

    // MARK: - Hidden items

    private func hidden(_ name: String) throws -> BrowserHiddenItemsStore {
        try BrowserHiddenItemsStore.open(at: directory.appendingPathComponent(name))
    }

    private func item(_ selector: String, list: BrowserHiddenItemList = .user) -> BrowserHiddenItem {
        BrowserHiddenItem(list: list, site: "example.com/*", selector: selector, scope: .thisItem,
                          label: selector, enabled: true, created: Date(timeIntervalSinceReferenceDate: 1_000))
    }

    func testHiddenItemsAreImportedOnce() throws {
        let source = try hidden("source.db")
        try source.add(item(".ad"))
        try source.add(item("#secret", list: .agent))
        let items = try source.allItems(list: .user) + source.allItems(list: .agent)

        let target = try hidden("target.db")
        XCTAssertEqual(try target.importIfAbsent(items).count, 2)
        XCTAssertEqual(try target.allItems(list: .user), try source.allItems(list: .user))
        XCTAssertEqual(try target.allItems(list: .agent), try source.allItems(list: .agent))
        XCTAssertEqual(try target.importIfAbsent(items), [])
    }

    func testAHiddenItemAlreadyHereKeepsItsSettings() throws {
        let target = try hidden("target.db")
        var mine = item(".ad")
        mine.enabled = false
        let kept = try target.add(mine)

        XCTAssertEqual(try target.importIfAbsent([item(".ad")]), [])
        XCTAssertEqual(try target.allItems(list: .user), [kept])
    }

    func testASiteSwitchHereIsKept() throws {
        let target = try hidden("target.db")
        try target.setSiteSwitch(list: .user, site: "example.com", on: false)

        XCTAssertFalse(try target.importSiteSwitchIfAbsent(list: .user, site: "example.com", on: true))
        XCTAssertTrue(try target.importSiteSwitchIfAbsent(list: .user, site: "other.com", on: true))
        XCTAssertEqual(try target.siteSwitches(list: .user), ["example.com": false, "other.com": true])
    }

    // MARK: - Notations

    func testANotationIsImportedOnceWhole() throws {
        let store = try NotationsStore(path: directory.appendingPathComponent("Notations.db").path)
        let notation = Notation(
            projectID: UUID(), projectName: "P", projectPath: "/tmp/p", branch: "feature",
            forkPoint: "abc", lastTip: "def", content: "# Plan", state: .archived,
            createdAt: Date(timeIntervalSince1970: 1_000), modifiedAt: Date(timeIntervalSince1970: 2_000),
            archivedAt: Date(timeIntervalSince1970: 3_000))

        XCTAssertTrue(try store.importIfAbsent(notation))
        XCTAssertEqual(try store.notation(id: notation.id), notation)

        var edited = notation
        edited.content = "changed"
        XCTAssertFalse(try store.importIfAbsent(edited))
        XCTAssertEqual(try store.notation(id: notation.id)?.content, "# Plan")
    }

    // MARK: - Dry runs

    func testADryRunAnswersAsARealRunAndWritesNothing() throws {
        let visits = [BrowserVisit(id: 1, url: URL(string: "https://example.com/")!, title: "E",
                                   visitedAt: Date(timeIntervalSince1970: 1_000))]
        let historyTarget = try history("target.db")
        XCTAssertEqual(try historyTarget.importIfAbsent(visits, dryRun: true), visits)
        XCTAssertEqual(try historyTarget.count(), 0)

        let hiddenTarget = try hidden("hidden.db")
        XCTAssertEqual(try hiddenTarget.importIfAbsent([item(".ad")], dryRun: true).count, 1)
        XCTAssertEqual(try hiddenTarget.allItems(list: .user), [])
        XCTAssertTrue(try hiddenTarget.importSiteSwitchIfAbsent(list: .user, site: "a.com", on: true, dryRun: true))
        XCTAssertEqual(try hiddenTarget.siteSwitches(list: .user), [:])

        let notations = try NotationsStore(path: directory.appendingPathComponent("Notations.db").path)
        let notation = Notation(
            projectID: UUID(), projectName: "P", projectPath: "/tmp/p", branch: "b", forkPoint: "f",
            lastTip: nil, content: "x", state: .active, createdAt: Date(), modifiedAt: Date(), archivedAt: nil)
        XCTAssertTrue(try notations.importIfAbsent(notation, dryRun: true))
        XCTAssertNil(try notations.notation(id: notation.id))
    }
}
