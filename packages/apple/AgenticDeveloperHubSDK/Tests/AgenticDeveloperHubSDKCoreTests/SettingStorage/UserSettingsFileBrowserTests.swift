import XCTest
import Combine
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for `UserSettings.fileBrowserExcludedPatterns` (user-settings-file-browser-001 to 012).
@MainActor
final class UserSettingsFileBrowserTests: XCTestCase {

    private let keyName = "file_browser.excluded_patterns"
    private var savedStore: UserSettings?
    private var savedSetting: UserSetting<[String]>?
    private var suiteName: String?

    override func setUp() async throws {
        await ExclusiveAccess.Resource.userSettings.acquire()
        savedStore = UserSettings.shared
        savedSetting = UserSettings.fileBrowserExcludedPatterns
        installStore(InMemorySettingsStorageProvider())
    }

    override func tearDown() async throws {
        if let savedStore { UserSettings.shared = savedStore }
        if let savedSetting { UserSettings.fileBrowserExcludedPatterns = savedSetting }
        if let suiteName { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }
        suiteName = nil
        await ExclusiveAccess.Resource.userSettings.release()
    }

    /// Swaps in a private store and rebuilds the declaration against it, so `currentValue` mirrors that store.
    private func installStore(_ provider: SettingsStorageProvider) {
        UserSettings.shared = UserSettings(with: provider,
                                           secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let original = UserSettings.fileBrowserExcludedPatterns
        UserSettings.fileBrowserExcludedPatterns = UserSetting<[String]>(
            original.name, default: original.defaultValue, isSecure: original.isSecure)
    }

    private func excluded(_ patterns: [String], _ path: String) -> Bool {
        GitIgnoreMatcher(patterns: patterns).isExcluded(relativePath: path, isDirectory: false)
    }

    func testV001_keyNameIsFileBrowserExcludedPatterns() {
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.name, keyName)
    }

    func testV002_defaultIsTheEmptyList() {
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.defaultValue, [String]())
    }

    func testV003_settingIsNotSecure() {
        XCTAssertFalse(UserSettings.fileBrowserExcludedPatterns.isSecure)
    }

    func testV004_emptyStoreReadsTheEmptyList() {
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.currentValue, [])
    }

    func testV005_setValueRoundTripsInOrderAndPublishesTheKey() {
        var names: [String] = []
        let cancellable = UserSettings.shared.changes.sink { names.append($0) }
        UserSettings.fileBrowserExcludedPatterns.value = ["*.log", "build/"]
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.currentValue, ["*.log", "build/"])
        XCTAssertTrue(names.contains(keyName))
        cancellable.cancel()
    }

    func testV006_bytesThatAreNotAListReadAsTheEmptyList() throws {
        let name = "UserSettingsFileBrowserTests-\(UUID().uuidString)"
        suiteName = name
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defaults.set(Data("not a list".utf8), forKey: keyName)
        installStore(UserDefaultsSettingsStorageProvider(defaults: defaults))
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.currentValue, [])
        XCTAssertEqual(UserSettings.shared.get(UserSettings.fileBrowserExcludedPatterns), [])
    }

    func testV007_entriesAreStoredUnchanged() {
        UserSettings.fileBrowserExcludedPatterns.value = ["a", "a", ""]
        XCTAssertEqual(UserSettings.fileBrowserExcludedPatterns.currentValue, ["a", "a", ""])
    }

    func testV008_negationAfterPatternKeepsTheFile() {
        let patterns = ["*.log", "!keep.log"]
        XCTAssertTrue(excluded(patterns, "a.log"))
        XCTAssertFalse(excluded(patterns, "keep.log"))
    }

    func testV009_laterPatternWins() {
        XCTAssertTrue(excluded(["!keep.log", "*.log"], "keep.log"))
    }

    func testV010_blankAndCommentEntriesAreIgnored() {
        let matcher = GitIgnoreMatcher(patterns: ["", "   ", "# *.log"])
        XCTAssertTrue(matcher.isEmpty)
        XCTAssertFalse(matcher.isExcluded(relativePath: "a.log", isDirectory: false))
    }

    func testV011_unanchoredNameMatchesAtAnyDepth() {
        XCTAssertTrue(excluded(["*.log"], "a.log"))
        XCTAssertTrue(excluded(["*.log"], "deep/er/a.log"))
        XCTAssertFalse(excluded(["*.log"], "a.log.txt"))
    }

    func testV012_theDeclarationIsOneSharedInstance() {
        let first = UserSettings.fileBrowserExcludedPatterns
        let second = UserSettings.fileBrowserExcludedPatterns
        XCTAssertTrue(first === second)
        first.value = ["x"]
        XCTAssertEqual(second.currentValue, ["x"])
    }
}
