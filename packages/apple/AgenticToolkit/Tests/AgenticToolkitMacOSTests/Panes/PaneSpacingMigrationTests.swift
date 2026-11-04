import XCTest
@testable import AgenticToolkitMacOS
import AgenticToolkitCore

@MainActor
final class PaneSpacingMigrationTests: XCTestCase {

    private func makeStore() -> SettingsStore {
        SettingsStore(with: InMemorySettingsStorageProvider(),
                      secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    func testASavedTerminalPaddingBecomesThePaneContentSpacing() {
        let store = makeStore()
        store.set(0, for: PaneSpacing.legacyTerminalPadding[.top]!)
        store.set(4, for: PaneSpacing.legacyTerminalPadding[.trailing]!)

        PaneSpacing.migrateLegacyTerminalPadding(in: store)

        XCTAssertEqual(store.get(UserSettings.paneContentSpacingTop), 0)
        XCTAssertEqual(store.get(UserSettings.paneContentSpacingTrailing), 4)
        XCTAssertFalse(store.contains(UserSettings.paneContentSpacingLeading))
        XCTAssertFalse(store.contains(PaneSpacing.legacyTerminalPadding[.top]!))
        XCTAssertFalse(store.contains(PaneSpacing.legacyTerminalPadding[.trailing]!))
    }

    func testAStoredPaneContentSpacingIsNotOverwritten() {
        let store = makeStore()
        store.set(2, for: UserSettings.paneContentSpacingTop)
        store.set(0, for: PaneSpacing.legacyTerminalPadding[.top]!)

        PaneSpacing.migrateLegacyTerminalPadding(in: store)

        XCTAssertEqual(store.get(UserSettings.paneContentSpacingTop), 2)
        XCTAssertFalse(store.contains(PaneSpacing.legacyTerminalPadding[.top]!))
    }

    func testNothingSavedLeavesTheDefaults() {
        let store = makeStore()
        PaneSpacing.migrateLegacyTerminalPadding(in: store)
        for setting in PaneSpacing.contentSettings.values {
            XCTAssertFalse(store.contains(setting))
        }
    }
}
