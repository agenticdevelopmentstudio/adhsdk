import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Reading the system plug-in registry's list of Safari web extensions, and
/// where an app extension's pieces are.
final class SafariAppExtensionTests: XCTestCase {

    private let dashlaneLine = "     com.dashlane.dashlanephonefinal.SafariWebExtension(6.2644.3)\t"
        + "1CEFDA4F-34C6-49D1-B856-CD40320A8E07\t2026-11-07 06:24:40 +0000\t"
        + "/Applications/Dashlane.app/Contents/PlugIns/SafariWebExtension (macOS).appex"
    private let raindropLine = "     io.raindrop.safari.extension(5.8.3)\t"
        + "C1990EE5-13B4-4D15-B483-7A246B024E68\t2026-09-16 04:40:51 +0000\t"
        + "/Applications/Save to Raindrop.io.app/Contents/PlugIns/Save to Raindrop.io Extension.appex"

    func test_parse_readsEachPlugInLineAndSkipsTheCount() {
        let output = [dashlaneLine, raindropLine, " (2 plug-ins)", ""].joined(separator: "\n")
        let found = SafariAppExtension.parse(pluginkitOutput: output)
        XCTAssertEqual(found.map(\.bundleID), [
            "com.dashlane.dashlanephonefinal.SafariWebExtension", "io.raindrop.safari.extension"
        ])
        XCTAssertEqual(found.map(\.version), ["6.2644.3", "5.8.3"])
        XCTAssertEqual(found[1].appexURL.path,
            "/Applications/Save to Raindrop.io.app/Contents/PlugIns/Save to Raindrop.io Extension.appex")
    }

    func test_parse_namesTheAppFromItsPath() {
        let found = SafariAppExtension.parse(pluginkitOutput: raindropLine)
        XCTAssertEqual(found.first?.appName, "Save to Raindrop.io")
        XCTAssertEqual(found.first?.name, "io.raindrop.safari.extension")
    }

    func test_parse_acceptsFlagsBeforeTheIdentifier() {
        let flagged = raindropLine.replacingOccurrences(of: "     io.", with: "+    io.")
        XCTAssertEqual(SafariAppExtension.parse(pluginkitOutput: flagged).first?.bundleID,
            "io.raindrop.safari.extension")
    }

    func test_parse_keepsTheFirstOfADuplicateIdentifier() {
        let second = raindropLine.replacingOccurrences(of: "/Applications/", with: "/Users/me/Applications/")
        let found = SafariAppExtension.parse(pluginkitOutput: raindropLine + "\n" + second)
        XCTAssertEqual(found.count, 1)
        XCTAssertTrue(found[0].appexURL.path.hasPrefix("/Applications/"))
    }

    func test_parse_skipsLinesThatAreNotAppExtensions() {
        let notAppex = raindropLine.replacingOccurrences(of: ".appex", with: ".bundle")
        let noVersion = raindropLine.replacingOccurrences(of: "(5.8.3)", with: "")
        XCTAssertTrue(SafariAppExtension.parse(pluginkitOutput: [notAppex, noVersion, "garbage"]
            .joined(separator: "\n")).isEmpty)
    }

    func test_resourcesURL_isTheAppexResourcesFolder() {
        let appex = URL(fileURLWithPath: "/Applications/A.app/Contents/PlugIns/B.appex", isDirectory: true)
        let found = SafariAppExtension(bundleID: "b", version: "1", appexURL: appex)
        XCTAssertEqual(found.resourcesURL.path, "/Applications/A.app/Contents/PlugIns/B.appex/Contents/Resources")
    }

    func test_appURL_isTheNearestEnclosingApp_orNil() {
        let appex = URL(fileURLWithPath: "/Applications/A.app/Contents/PlugIns/B.appex", isDirectory: true)
        XCTAssertEqual(SafariAppExtension.appURL(containing: appex)?.path, "/Applications/A.app")
        XCTAssertNil(SafariAppExtension.appURL(containing: URL(fileURLWithPath: "/Library/B.appex")))
    }

    func test_appName_fallsBackToTheAppexNameOutsideAnApp() {
        let found = SafariAppExtension(bundleID: "b", version: "1", appexURL: URL(fileURLWithPath: "/Library/B.appex"))
        XCTAssertEqual(found.appName, "B")
    }
}
