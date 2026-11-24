import WebKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The extension list as Chrome's extensions page reports it, and which
/// profile a pane's jar puts its extensions in.
@MainActor
final class BrowserExtensionTests: XCTestCase {

    private func element(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var item: [String: Any] = [
            "id": "abc", "name": "JSON Formatter", "version": "0.7.1", "description": "d",
            "state": "ENABLED", "location": "FROM_STORE",
            "optionsPage": ["url": "chrome-extension://abc/options.html"],
            "iconUrl": "data:image/png;base64,iVBORw0KGgo="
        ]
        item.merge(overrides) { $1 }
        return item
    }

    func test_decodesEnabledStoreExtension() throws {
        let list = try BrowserExtension.decodeList([element()])
        let ext = try XCTUnwrap(list.first)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(ext.id, "abc")
        XCTAssertEqual(ext.name, "JSON Formatter")
        XCTAssertEqual(ext.version, "0.7.1")
        XCTAssertEqual(ext.summary, "d")
        XCTAssertTrue(ext.isEnabled)
        XCTAssertTrue(ext.isFromWebStore)
        XCTAssertEqual(ext.optionsURL, URL(string: "chrome-extension://abc/options.html"))
        XCTAssertEqual(ext.iconPNG, Data(base64Encoded: "iVBORw0KGgo="))
    }

    func test_disabledAndUnpacked() throws {
        let ext = try XCTUnwrap(BrowserExtension.decodeList([
            element(["state": "DISABLED", "location": "UNPACKED"])
        ]).first)
        XCTAssertFalse(ext.isEnabled)
        XCTAssertFalse(ext.isFromWebStore)
    }

    func test_missingOptionsAndIcon() throws {
        var item = element()
        item.removeValue(forKey: "optionsPage")
        item.removeValue(forKey: "iconUrl")
        let ext = try XCTUnwrap(BrowserExtension.decodeList([item]).first)
        XCTAssertNil(ext.optionsURL)
        XCTAssertNil(ext.iconPNG)
    }

    /// Chrome's generic icon is an address, not image data.
    func test_genericIconAddressGivesNoIcon() throws {
        let ext = try XCTUnwrap(BrowserExtension.decodeList([
            element(["iconUrl": "chrome://extension-icon/abc/48/0"])
        ]).first)
        XCTAssertNil(ext.iconPNG)
    }

    func test_rejectsNonArray() {
        XCTAssertThrowsError(try BrowserExtension.decodeList(["x": 1])) { error in
            guard case BrowserExtensionError.unexpectedShape = error else {
                return XCTFail("expected unexpectedShape, got \(error)")
            }
        }
    }

    func test_rejectsElementWithoutID() {
        var item = element()
        item.removeValue(forKey: "id")
        XCTAssertThrowsError(try BrowserExtension.decodeList([item])) { error in
            guard case BrowserExtensionError.unexpectedShape = error else {
                return XCTFail("expected unexpectedShape, got \(error)")
            }
        }
    }

    func test_profileFromJar() {
        let id = UUID()
        XCTAssertEqual(BrowserExtensionProfile(.global), .global)
        XCTAssertEqual(BrowserExtensionProfile(BrowserResolvedJar(
            webKitDataStore: .nonPersistent(), jar: .worktree, jarID: id)), .jar(id))
        XCTAssertEqual(BrowserExtensionProfile(BrowserResolvedJar(
            webKitDataStore: .nonPersistent(), jar: .pane, jarID: id)), .jar(id))
        XCTAssertNil(BrowserExtensionProfile(BrowserResolvedJar(
            webKitDataStore: .nonPersistent(), jar: nil, jarID: nil)), "private browsing")
        XCTAssertNil(BrowserExtensionProfile(BrowserResolvedJar(
            webKitDataStore: .nonPersistent(), jar: .worktree, jarID: id, fallbackReason: "x")),
            "a jar that failed closed is in memory")
    }
}
