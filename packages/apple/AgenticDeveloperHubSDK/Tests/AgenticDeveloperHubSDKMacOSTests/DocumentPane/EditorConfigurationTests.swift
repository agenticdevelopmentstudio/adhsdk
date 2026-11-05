import XCTest
import CodeEditSourceEditor
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class EditorConfigurationTests: XCTestCase {

    func testPeripheralsFollowTheResolvedOverride() throws {
        let override = EditorOptionsOverride(store: EphemeralPaneStateStore())
        override.setShowLineNumbers(false)
        override.setShowOverview(false)
        override.setShowInvisibles(true)

        let peripherals = EditorPeripherals.make(from: override, triggerCharacters: [])

        XCTAssertFalse(peripherals.showGutter)
        XCTAssertFalse(peripherals.showMinimap)
        XCTAssertTrue(peripherals.invisibleCharactersConfiguration.showSpaces)
        XCTAssertTrue(peripherals.invisibleCharactersConfiguration.showTabs)
        XCTAssertTrue(peripherals.invisibleCharactersConfiguration.showLineEndings)
    }

    func testInvisiblesOffIsTheEmptyConfiguration() {
        let override = EditorOptionsOverride(store: EphemeralPaneStateStore())
        override.setShowInvisibles(false)

        let peripherals = EditorPeripherals.make(from: override, triggerCharacters: [])

        XCTAssertEqual(peripherals.invisibleCharactersConfiguration, .empty)
    }
}
