import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

final class SharedSettingsStoreTests: XCTestCase {

    private var dir: URL!
    private var store: SharedSettingsStore!

    override func setUpWithError() throws {
        dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("shared-settings-\(UUID().uuidString)", isDirectory: true)
        store = try SharedSettingsStore(path: dir.appendingPathComponent(SharedSettingsStore.fileName).path)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: dir)
    }

    private func json(_ text: String) -> Data { Data(text.utf8) }

    // MARK: - Round trip

    func testSetThenReadReturnsTheValueAtVersionOne() throws {
        let stored = try store.set(json("\"Menlo-Regular\""), forKey: "terminal_font_name")
        XCTAssertEqual(stored.version, 1)

        let read = try XCTUnwrap(store.value(forKey: "terminal_font_name"))
        XCTAssertEqual(read, SharedSetting(key: "terminal_font_name", value: json("\"Menlo-Regular\""), version: 1))
    }

    func testEachWriteBumpsTheVersion() throws {
        try store.set(json("13"), forKey: "terminal_font_size")
        let second = try store.set(json("14"), forKey: "terminal_font_size")
        XCTAssertEqual(second.version, 2)
        XCTAssertEqual(try store.value(forKey: "terminal_font_size")?.value, json("14"))
    }

    func testAnUnsetKeyReadsNil() throws {
        XCTAssertNil(try store.value(forKey: "theme.active_theme_id"))
    }

    func testAllListsEveryKeyInOrder() throws {
        try store.set(json("true"), forKey: "terminal_cursor_blinks")
        try store.set(json("\"solarized-dark\""), forKey: "theme.active_theme_id")
        XCTAssertEqual(try store.all().map(\.key), ["terminal_cursor_blinks", "theme.active_theme_id"])
    }

    func testTheValueSurvivesReopening() throws {
        try store.set(json("[1,2]"), forKey: "theme.custom_themes")
        let path = store.databasePath
        store = nil
        let reopened = try SharedSettingsStore(path: path)
        XCTAssertEqual(try reopened.value(forKey: "theme.custom_themes")?.value, json("[1,2]"))
    }

    func testRemoveForgetsTheKey() throws {
        try store.set(json("13"), forKey: "terminal_font_size")
        try store.remove(forKey: "terminal_font_size")
        XCTAssertNil(try store.value(forKey: "terminal_font_size"))
    }

    func testAValueThatIsNotJSONIsRefused() {
        XCTAssertThrowsError(try store.set(json("not json"), forKey: "terminal_font_name")) { error in
            XCTAssertEqual(error as? SharedSettingsStoreError, .invalidJSON(key: "terminal_font_name"))
        }
    }

    // MARK: - Version conflict

    func testAWriteAtTheCurrentVersionSucceeds() throws {
        try store.set(json("13"), forKey: "terminal_font_size")
        let next = try store.set(json("15"), forKey: "terminal_font_size", expectedVersion: 1)
        XCTAssertEqual(next.version, 2)
    }

    func testAStaleWriteIsRefusedAndLeavesTheValue() throws {
        try store.set(json("13"), forKey: "terminal_font_size")
        try store.set(json("14"), forKey: "terminal_font_size")

        XCTAssertThrowsError(try store.set(json("99"), forKey: "terminal_font_size", expectedVersion: 1)) { error in
            XCTAssertEqual(
                error as? SharedSettingsStoreError,
                .versionConflict(key: "terminal_font_size", expected: 1, actual: 2))
        }
        XCTAssertEqual(try store.value(forKey: "terminal_font_size")?.value, json("14"))
    }

    func testAnUnsetKeyIsAtVersionZero() throws {
        XCTAssertEqual(try store.set(json("1"), forKey: "k", expectedVersion: 0).version, 1)
        XCTAssertThrowsError(try store.set(json("2"), forKey: "other", expectedVersion: 3))
    }

    func testAStaleRemoveIsRefused() throws {
        try store.set(json("13"), forKey: "terminal_font_size")
        try store.set(json("14"), forKey: "terminal_font_size")
        XCTAssertThrowsError(try store.remove(forKey: "terminal_font_size", expectedVersion: 1))
        XCTAssertNotNil(try store.value(forKey: "terminal_font_size"))
    }

    // MARK: - Import

    func testImportIfAbsentNeverOverwrites() throws {
        XCTAssertTrue(try store.importIfAbsent(json("13"), forKey: "terminal_font_size"))
        XCTAssertFalse(try store.importIfAbsent(json("20"), forKey: "terminal_font_size"))
        XCTAssertEqual(try store.value(forKey: "terminal_font_size")?.value, json("13"))
    }

    // MARK: - Changes

    func testAWriteIsAnnouncedOnTheChangeStream() async throws {
        let changes = store.changes
        try store.set(json("13"), forKey: "terminal_font_size")
        var iterator = changes.makeAsyncIterator()
        let key = await iterator.next()
        XCTAssertEqual(key, "terminal_font_size")
    }
}
