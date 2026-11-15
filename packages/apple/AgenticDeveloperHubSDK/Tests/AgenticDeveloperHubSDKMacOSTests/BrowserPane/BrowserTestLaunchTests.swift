#if DEBUG
import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The UI-test launch hook's parsing and the setting keys' JSON decoding,
/// which a regression would otherwise surface only as a UI-test timeout or a
/// host exiting at launch.
@MainActor
final class BrowserTestLaunchTests: XCTestCase {

    private func makeStore() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func environment(url: String?, settings: String? = nil) -> [String: String] {
        var environment: [String: String] = [:]
        environment[BrowserTestLaunch.urlVariable] = url
        environment[BrowserTestLaunch.settingsVariable] = settings
        return environment
    }

    // MARK: - request(from:)

    func testNoURLIsNoRequest() throws {
        XCTAssertNil(try BrowserTestLaunch.request(from: [:]))
        XCTAssertNil(try BrowserTestLaunch.request(from: environment(url: "")))
        // Settings without a page ask for nothing.
        XCTAssertNil(try BrowserTestLaunch.request(from: environment(url: nil, settings: #"{"x": 1}"#)))
    }

    func testAURLAloneIsARequestWithNoOverrides() throws {
        let request = try XCTUnwrap(BrowserTestLaunch.request(from: environment(url: "https://example.com/page")))
        XCTAssertEqual(request.url.absoluteString, "https://example.com/page")
        XCTAssertTrue(request.overrides.isEmpty)
    }

    func testAnEmptySettingsVariableIsNoOverrides() throws {
        let request = try XCTUnwrap(
            BrowserTestLaunch.request(from: environment(url: "file:///tmp/a.html", settings: ""))
        )
        XCTAssertTrue(request.overrides.isEmpty)
    }

    func testATextWithoutASchemeIsRefused() {
        XCTAssertThrowsError(try BrowserTestLaunch.request(from: environment(url: "not a url"))) { error in
            guard case BrowserTestLaunch.LaunchError.badURL = error else { return XCTFail("\(error)") }
        }
    }

    func testSettingsThatAreNotAJSONObjectAreRefused() {
        for json in ["[true]", "true", "{not json", "\"text\""] {
            XCTAssertThrowsError(
                try BrowserTestLaunch.request(from: environment(url: "https://example.com", settings: json)), json
            ) { error in
                guard case BrowserTestLaunch.LaunchError.badSettingsJSON = error else {
                    return XCTFail("\(json): \(error)")
                }
            }
        }
    }

    func testAnUnknownSettingNameIsRefused() {
        let json = #"{"browser.privacy.hide_activation": true, "browser.no_such_setting": 1}"#
        XCTAssertThrowsError(
            try BrowserTestLaunch.request(from: environment(url: "https://example.com", settings: json))
        ) { error in
            guard case BrowserTestLaunch.LaunchError.unknownSetting(let name) = error else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(name, "browser.no_such_setting")
        }
    }

    func testKnownSettingsBecomeOverrides() throws {
        let json = #"{"browser.privacy.hide_activation": true, "browser.page_zoom": 1.5}"#
        let request = try XCTUnwrap(
            BrowserTestLaunch.request(from: environment(url: "https://example.com", settings: json))
        )
        XCTAssertEqual(Set(request.overrides.keys), ["browser.privacy.hide_activation", "browser.page_zoom"])
    }

    // MARK: - check and apply

    func testApplyWritesEachTypeIntoTheStore() throws {
        let store = makeStore()
        try BrowserTestLaunch.apply([
            UserSettings.browserPrivacyHideActivation.name: true,
            UserSettings.browserPageZoom.name: 1.5,
            UserSettings.browserMinimumFontSize.name: 12,
            UserSettings.browserCustomUserAgent.name: "Test Agent",
            UserSettings.browserAutoplay.name: "never",
            UserSettings.browserPrivacyKeyboard.name: "block"
        ], to: store)
        XCTAssertTrue(store.get(UserSettings.browserPrivacyHideActivation))
        XCTAssertEqual(store.get(UserSettings.browserPageZoom), 1.5)
        XCTAssertEqual(store.get(UserSettings.browserMinimumFontSize), 12)
        XCTAssertEqual(store.get(UserSettings.browserCustomUserAgent), "Test Agent")
        XCTAssertEqual(store.get(UserSettings.browserAutoplay), .never)
        XCTAssertEqual(store.get(UserSettings.browserPrivacyKeyboard), .block)
    }

    func testAValueOfTheWrongTypeIsABadValue() {
        let wrong: [(String, Any)] = [
            (UserSettings.browserPrivacyHideActivation.name, "yes"),
            (UserSettings.browserPageZoom.name, true),
            (UserSettings.browserAutoplay.name, "sometimes"),
            (UserSettings.browserCustomUserAgent.name, 3)
        ]
        for (name, value) in wrong {
            XCTAssertThrowsError(try BrowserTestLaunch.check([name: value]), name) { error in
                guard case BrowserTestLaunch.LaunchError.badValue(let badName, _) = error else {
                    return XCTFail("\(name): \(error)")
                }
                XCTAssertEqual(badName, name)
            }
        }
    }

    func testAJSONParsedBooleanDecodesAsABool() throws {
        // What `request(from:)` hands on is `JSONSerialization`'s output, an
        // NSNumber for `true`, not a Swift Bool.
        let request = try XCTUnwrap(BrowserTestLaunch.request(from: environment(
            url: "https://example.com", settings: #"{"browser.privacy.hide_activation": true}"#
        )))
        let store = makeStore()
        try BrowserTestLaunch.check(request.overrides)
        try BrowserTestLaunch.apply(request.overrides, to: store)
        XCTAssertTrue(store.get(UserSettings.browserPrivacyHideActivation))
    }

    func testAnUnknownNameIsRefusedByCheckAndApply() {
        XCTAssertThrowsError(try BrowserTestLaunch.check(["browser.nope": true])) { error in
            guard case BrowserTestLaunch.LaunchError.unknownSetting = error else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try BrowserTestLaunch.apply(["browser.nope": true], to: makeStore())) { error in
            guard case BrowserTestLaunch.LaunchError.unknownSetting = error else { return XCTFail("\(error)") }
        }
    }

    func testARequestCanBeBuiltDirectly() {
        let url = URL(string: "https://example.com")!
        let request = BrowserTestLaunch.Request(url: url)
        XCTAssertEqual(request.url, url)
        XCTAssertTrue(request.overrides.isEmpty)
    }
}
#endif
