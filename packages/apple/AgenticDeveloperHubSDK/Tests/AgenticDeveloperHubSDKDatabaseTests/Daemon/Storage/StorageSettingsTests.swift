import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// `event_history_days`: the allowed values, snapping, and the one-time seed
/// from the old opt-in `retention_enabled` / `retention_days` pair.
final class StorageSettingsTests: XCTestCase {

    private var tmpDir: URL!
    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("storage-settings-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        tmpPath = tmpDir.appendingPathComponent("session.db").path
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
    }

    override func tearDownWithError() throws {
        database = nil
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func stored() throws -> String? {
        try database.setting(for: StorageSettings.key)
    }

    /// Clears the seeded value and runs the seed again, as a first start would.
    private func reseed(enabled: String?, days: String?) throws -> String? {
        try database.execute("DELETE FROM settings WHERE key IN (?, ?, ?)",
                             params: [StorageSettings.key, "retention_enabled", "retention_days"])
        if let enabled { try database.setSetting("retention_enabled", enabled) }
        if let days { try database.setSetting("retention_days", days) }
        try StorageSettings.ensureEventHistoryDays(database)
        return try stored()
    }

    // MARK: - Snapping

    func testSnapGoesToTheNearestAllowedValueAtOrAbove() {
        XCTAssertEqual(StorageSettings.snap("0"), 7)
        XCTAssertEqual(StorageSettings.snap("-5"), 7)
        XCTAssertEqual(StorageSettings.snap("7"), 7)
        XCTAssertEqual(StorageSettings.snap("8"), 14)
        XCTAssertEqual(StorageSettings.snap(" 30 "), 30)
        XCTAssertEqual(StorageSettings.snap("181"), 365)
        XCTAssertEqual(StorageSettings.snap("400"), 365)
    }

    /// The windows and the snap-up rule live once, in toolkit Core, for the
    /// daemon and the app alike.
    func testTheSharedWindowIsTheOneTheSettingUses() throws {
        XCTAssertEqual(StorageHistoryWindow.allowedDays, [7, 14, 30, 60, 90, 180, 365])
        XCTAssertEqual(StorageHistoryWindow.defaultDays, 30)
        for days in [-1, 0, 7, 8, 29, 31, 180, 181, 365, 9999] {
            XCTAssertEqual(StorageSettings.snap(String(days)), StorageHistoryWindow.snap(days), "\(days)")
        }
        XCTAssertEqual(try StorageSettings.setHistoryDays(45, database), 60)
        XCTAssertEqual(StorageHistoryWindow.snap(45, allowed: [90, 30]), 90, "unsorted allowed values still snap up")
        XCTAssertEqual(StorageHistoryWindow.snap(45, allowed: []), 45, "no allowed values leaves the number alone")
    }

    func testANonIntegerReadsAsTheDefault() {
        XCTAssertEqual(StorageSettings.snap("abc"), 30)
        XCTAssertEqual(StorageSettings.snap("7.5"), 30)
        XCTAssertEqual(StorageSettings.snap(""), 30)
        XCTAssertEqual(StorageSettings.snap(nil as String?), 30)
    }

    func testHistoryDaysReadsTheStoredValueSnapped() throws {
        try database.setSetting(StorageSettings.key, "8")
        XCTAssertEqual(StorageSettings.historyDays(database), 14)
        try database.setSetting(StorageSettings.key, "abc")
        XCTAssertEqual(StorageSettings.historyDays(database), 30)
    }

    // MARK: - Seeding

    func testAFreshDatabaseSeedsThirty() throws {
        // The shared migration seeds retention_days = 7 but never retention_enabled.
        XCTAssertEqual(try database.setting(for: "retention_days"), "7")
        XCTAssertNil(try database.setting(for: "retention_enabled"))
        XCTAssertEqual(try stored(), "30")
    }

    func testRetentionOnWithAValidWindowSeedsIt() throws {
        XCTAssertEqual(try reseed(enabled: "true", days: "7"), "7")
        XCTAssertEqual(try reseed(enabled: "1", days: "10"), "14", "the old window is snapped")
        XCTAssertEqual(try reseed(enabled: "on", days: "1000"), "365")
    }

    func testRetentionOffOrAbsentSeedsTheDefault() throws {
        XCTAssertEqual(try reseed(enabled: "false", days: "7"), "30")
        XCTAssertEqual(try reseed(enabled: nil, days: "7"), "30")
        XCTAssertEqual(try reseed(enabled: "true", days: "abc"), "30", "an invalid old window is not used")
        XCTAssertEqual(try reseed(enabled: "true", days: nil), "30")
    }

    func testTheSeedHappensOnce() throws {
        try database.setSetting(StorageSettings.key, "90")
        try database.setSetting("retention_enabled", "true")
        try database.setSetting("retention_days", "7")
        try StorageSettings.ensureEventHistoryDays(database)
        XCTAssertEqual(try stored(), "90", "a stored value is never reseeded")

        // Reopening runs every post-migration step again; the value stays.
        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertEqual(try stored(), "90")
    }

    func testReopeningAnOptedInDatabaseSeedsItsWindow() throws {
        try database.execute("DELETE FROM settings WHERE key = ?", params: [StorageSettings.key])
        try database.setSetting("retention_enabled", "yes")
        try database.setSetting("retention_days", "60")
        database = nil
        database = try TestDaemonDatabase.openFeatureDatabase(path: tmpPath)
        XCTAssertEqual(try stored(), "60")
    }
}
