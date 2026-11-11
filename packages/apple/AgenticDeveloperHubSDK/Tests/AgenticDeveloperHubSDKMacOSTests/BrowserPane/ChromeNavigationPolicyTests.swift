import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Where a Chrome pane may not go: Chrome's settings are the Kitchen's, and
/// a private pane has no extensions to install or manage.
final class ChromeNavigationPolicyTests: XCTestCase {

    private func refusal(_ address: String, isPrivate: Bool) throws -> String? {
        ChromeNavigationPolicy.refusal(for: try XCTUnwrap(URL(string: address)), isPrivate: isPrivate)
    }

    func test_settingsPagesRefusedEverywhere() throws {
        let sentence = "Chrome settings are managed in Settings > Web Browser."
        XCTAssertEqual(try refusal("chrome://settings", isPrivate: false), sentence)
        XCTAssertEqual(try refusal("chrome://settings/cookies", isPrivate: false), sentence)
        XCTAssertEqual(try refusal("CHROME://Settings/", isPrivate: true), sentence)
    }

    func test_historyDownloadsAndPasswordPagesRefusedEverywhere() throws {
        let sentence = "This Chrome page is not available in the Kitchen."
        for address in [
            "chrome://history", "chrome://history/syncedTabs", "chrome://downloads",
            "chrome://password-manager/passwords", "chrome://passwords", "CHROME://History/"
        ] {
            XCTAssertEqual(try refusal(address, isPrivate: false), sentence, address)
            XCTAssertEqual(try refusal(address, isPrivate: true), sentence, address)
        }
        XCTAssertNil(try refusal("https://example.com/history", isPrivate: false))
    }

    func test_extensionsPageAllowedInRegularPane() throws {
        XCTAssertNil(try refusal("chrome://extensions", isPrivate: false))
        XCTAssertNil(try refusal("https://chromewebstore.google.com/detail/x/abc", isPrivate: false))
    }

    func test_privatePaneRefusesStoreAndExtensionsPage() throws {
        let sentence = "Extensions are not available in private panes."
        XCTAssertEqual(try refusal("https://chromewebstore.google.com/detail/x/abc", isPrivate: true), sentence)
        XCTAssertEqual(try refusal("https://chrome.google.com/webstore/detail/abc", isPrivate: true), sentence)
        XCTAssertEqual(try refusal("chrome://extensions", isPrivate: true), sentence)
        XCTAssertEqual(try refusal("chrome://extensions/?id=abc", isPrivate: true), sentence)
    }

    func test_ordinaryPagesAllowed() throws {
        XCTAssertNil(try refusal("https://example.com", isPrivate: true))
        XCTAssertNil(try refusal("https://chrome.google.com/search", isPrivate: true), "only /webstore is the store")
        XCTAssertNil(try refusal("https://example.com/chrome://settings", isPrivate: false))
    }
}
