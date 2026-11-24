import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class FolderDisclosureMemoryTests: XCTestCase {

    private let setting = UserSetting<[String]>("adh_sdk_folder_disclosure_test", default: [])

    override func setUp() async throws { setting.value = [] }
    override func tearDown() async throws { setting.value = [] }

    func testAFolderNobodyTouchedIsOpen() {
        XCTAssertFalse(FolderDisclosureMemory(setting: setting).isCollapsed("/a"))
    }

    func testACloseIsRememberedAcrossInstances() {
        FolderDisclosureMemory(setting: setting).note("/a", collapsed: true)
        XCTAssertTrue(FolderDisclosureMemory(setting: setting).isCollapsed("/a"))
    }

    func testOpeningForgetsTheClose() {
        let memory = FolderDisclosureMemory(setting: setting)
        memory.note("/a", collapsed: true)
        memory.note("/a", collapsed: false)
        XCTAssertFalse(memory.isCollapsed("/a"))
        XCTAssertEqual(setting.value, [])
    }

    func testRevealOpensOnlyTheGivenFolders() {
        let memory = FolderDisclosureMemory(setting: setting)
        memory.note("/a", collapsed: true)
        memory.note("/b", collapsed: true)
        memory.reveal(["/a"])
        XCTAssertFalse(memory.isCollapsed("/a"))
        XCTAssertTrue(memory.isCollapsed("/b"))
        XCTAssertEqual(setting.value, ["/b"])
    }
}
