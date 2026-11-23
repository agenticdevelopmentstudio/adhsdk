import XCTest
import AgenticDeveloperHubSDKDatabase

/// `BrowserStoringConformance` run against the app's own SQLite stores, each
/// check on a fresh file. The daemon's adapters run the same checks in
/// adh-daemon's client tests.
final class BrowserHistoryStoringConformanceTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHistoryStoringConformanceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> any BrowserHistoryStoring {
        try BrowserHistoryStore(path: directory.appendingPathComponent("History-\(UUID().uuidString).db").path)
    }

    func test_recordsAndListsNewestFirst() async throws {
        try await BrowserStoringConformance.historyRecordsAndListsNewestFirst(makeStore)
    }

    func test_leavesOutLocalFilesWhenAsked() async throws {
        try await BrowserStoringConformance.historyLeavesOutLocalFilesWhenAsked(makeStore)
    }

    func test_searchesAddressAndTitle() async throws {
        try await BrowserStoringConformance.historySearchesAddressAndTitle(makeStore)
    }

    func test_removesBeforeACutoffAndOneByOne() async throws {
        try await BrowserStoringConformance.historyRemovesBeforeACutoffAndOneByOne(makeStore)
    }

    func test_changesFireOncePerWrite() async throws {
        try await BrowserStoringConformance.historyChangesFireOncePerWrite(makeStore)
    }
}

/// The same for the hidden-items store.
final class BrowserHiddenItemsConformanceTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserHiddenItemsConformanceTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> any BrowserHiddenItemsStoring {
        try BrowserHiddenItemsStore.open(
            at: directory.appendingPathComponent(UUID().uuidString)
                .appendingPathComponent(BrowserHiddenItemsStore.fileName))
    }

    func test_addsAndListsBySite() async throws {
        try await BrowserStoringConformance.hiddenItemsAddsAndListsBySite(makeStore)
    }

    func test_selectorsFollowEnablingAndTheSiteSwitch() async throws {
        try await BrowserStoringConformance.hiddenItemsSelectorsFollowEnablingAndTheSiteSwitch(makeStore)
    }

    func test_refusesAnEmptySelector() async throws {
        try await BrowserStoringConformance.hiddenItemsRefuseAnEmptySelector(makeStore)
    }

    func test_changesFireOncePerWrite() async throws {
        try await BrowserStoringConformance.hiddenItemsChangesFireOncePerWrite(makeStore)
    }
}
