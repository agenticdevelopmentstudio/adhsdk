import XCTest
@testable import AgenticDeveloperHubSDKMacOS
import CodeEditLanguages

final class LanguageDetectionTests: XCTestCase {
    // CodeEditLanguages' resource bundle is located for the whole bundle by
    // `TestBundleSetup` (`ensureEditorLanguageResourcesLocated()`).

    override func setUp() {
        CustomFileTypeMappings.activeDefaultsKey = "AgenticFileBrowserTests.customMappings"
        UserDefaults.standard.removeObject(forKey: CustomFileTypeMappings.activeDefaultsKey)
        CustomFileTypeMappings.save([])
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: CustomFileTypeMappings.activeDefaultsKey)
        CustomFileTypeMappings.save([])
    }

    func testBuiltinSwift() {
        let lang = LanguageDetection.language(for: URL(fileURLWithPath: "/tmp/x.swift"))
        XCTAssertEqual(lang.id, CodeLanguage.swift.id)
    }

    func testBuiltinJSON() {
        let lang = LanguageDetection.language(for: URL(fileURLWithPath: "/tmp/x.json"))
        XCTAssertEqual(lang.id, CodeLanguage.json.id)
    }

    func testCustomOverride() {
        CustomFileTypeMappings.save([
            CustomFileTypeMapping(fileExtension: "swift", languageName: "json", iconName: "curlybraces")
        ])
        let lang = LanguageDetection.language(for: URL(fileURLWithPath: "/tmp/x.swift"))
        XCTAssertEqual(lang.id, CodeLanguage.json.id)
    }
}
