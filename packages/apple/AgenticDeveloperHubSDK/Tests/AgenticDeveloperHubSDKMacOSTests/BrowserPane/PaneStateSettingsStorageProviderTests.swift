import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
final class PaneStateSettingsStorageProviderTests: XCTestCase {

    private func makeProvider() -> (PaneStateSettingsStorageProvider, EphemeralPaneStateStore) {
        let store = EphemeralPaneStateStore()
        return (PaneStateSettingsStorageProvider(store: store), store)
    }

    func testRoundTripsBoolIntDoubleStringAndEnum() {
        let (provider, _) = makeProvider()
        provider.set(false, for: UserSettings.browserJavaScriptEnabled)
        provider.set(14, for: UserSettings.browserMinimumFontSize)
        provider.set(1.25, for: UserSettings.browserPageZoom)
        provider.set("example.com", for: UserSettings.browserHomePage)
        provider.set(.never, for: UserSettings.browserAutoplay)

        XCTAssertEqual(provider.get(UserSettings.browserJavaScriptEnabled), false)
        XCTAssertEqual(provider.get(UserSettings.browserMinimumFontSize), 14)
        XCTAssertEqual(provider.get(UserSettings.browserPageZoom), 1.25)
        XCTAssertEqual(provider.get(UserSettings.browserHomePage), "example.com")
        XCTAssertEqual(provider.get(UserSettings.browserAutoplay), .never)
        XCTAssertTrue(provider.contains(UserSettings.browserAutoplay))

        provider.remove(UserSettings.browserAutoplay)
        XCTAssertFalse(provider.contains(UserSettings.browserAutoplay))
        XCTAssertEqual(provider.get(UserSettings.browserAutoplay), UserSettings.browserAutoplay.defaultValue)
    }

    func testStoresUnderThePrefix() {
        let (provider, store) = makeProvider()
        provider.set(1.25, for: UserSettings.browserPageZoom)
        XCTAssertNotNil(store.paneStateValue(forKey: "settings.browser.page_zoom"))
    }

    func testUndecodableOverrideFallsBack() {
        let (provider, store) = makeProvider()
        store.setPaneStateValue("not json", forKey: "settings.browser.page_zoom")
        XCTAssertFalse(provider.contains(UserSettings.browserPageZoom))
        XCTAssertEqual(provider.get(UserSettings.browserPageZoom), 1.0)

        let fallback = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        fallback.set(1.5, for: UserSettings.browserPageZoom)
        let layered = LayeredSettingsStore(overrides: provider, fallback: fallback)
        XCTAssertEqual(layered.get(UserSettings.browserPageZoom), 1.5)
        XCTAssertFalse(layered.hasOverride(UserSettings.browserPageZoom))
    }
}
