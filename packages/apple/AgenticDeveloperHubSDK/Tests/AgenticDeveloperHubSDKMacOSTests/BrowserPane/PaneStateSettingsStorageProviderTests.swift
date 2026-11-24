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

    private func makeFallback() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    /// An override written in an earlier launch must still be found and
    /// cleared by a provider built over the same pane state afterwards.
    func testOverridesFromAnEarlierProviderCanBeRemovedAfterARelaunch() {
        let store = EphemeralPaneStateStore()
        let first = PaneStateSettingsStorageProvider(store: store)
        first.set(1.25, for: UserSettings.browserPageZoom)
        first.set("example.com", for: UserSettings.browserHomePage)

        let fallback = makeFallback()
        fallback.set(1.5, for: UserSettings.browserPageZoom)
        fallback.set("global.com", for: UserSettings.browserHomePage)
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: store),
            fallback: fallback
        )
        XCTAssertTrue(layered.hasOverride(UserSettings.browserPageZoom))

        layered.removeAllOverrides(withPrefix: "browser.")

        XCTAssertFalse(layered.hasOverride(UserSettings.browserPageZoom))
        XCTAssertFalse(layered.hasOverride(UserSettings.browserHomePage))
        XCTAssertEqual(layered.get(UserSettings.browserPageZoom), 1.5)
        XCTAssertEqual(layered.get(UserSettings.browserHomePage), "global.com")
    }

    func testACorruptOverrideStillReceivesTheGlobalChange() {
        let store = EphemeralPaneStateStore()
        store.setPaneStateValue("not json", forKey: "settings.browser.page_zoom")
        let fallback = makeFallback()
        let layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: store),
            fallback: fallback
        )
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        fallback.set(1.5, for: UserSettings.browserPageZoom)
        XCTAssertEqual(names, [UserSettings.browserPageZoom.name])
        XCTAssertEqual(layered.get(UserSettings.browserPageZoom), 1.5)
        cancellable.cancel()
    }

    func testKeysWithPrefixListsOnlyWellFormedStoredNames() {
        let (provider, store) = makeProvider()
        provider.set(1.25, for: UserSettings.browserPageZoom)
        provider.set("example.com", for: UserSettings.browserHomePage)
        provider.set(true, for: UserSettings.browserJavaScriptEnabled)
        XCTAssertEqual(
            provider.keys(withPrefix: "browser."),
            ["browser.home_page", "browser.javascript_enabled", "browser.page_zoom"]
        )
        XCTAssertEqual(provider.keys(withPrefix: "browser.p"), ["browser.page_zoom"])
        XCTAssertEqual(provider.keys(withPrefix: "editor."), [])

        store.setPaneStateValue("not json", forKey: "settings.browser.page_zoom")
        provider.remove(UserSettings.browserHomePage)
        XCTAssertEqual(provider.keys(withPrefix: "browser."), ["browser.javascript_enabled"])
    }

    func testRemoveOnlyPublishesWhenSomethingWasStored() {
        let (provider, _) = makeProvider()
        var names: [String] = []
        let cancellable = provider.changes.sink { names.append($0) }
        provider.remove(UserSettings.browserPageZoom)
        XCTAssertEqual(names, [])
        provider.set(1.25, for: UserSettings.browserPageZoom)
        provider.remove(UserSettings.browserPageZoom)
        XCTAssertEqual(names, ["browser.page_zoom", "browser.page_zoom"])
        cancellable.cancel()
    }
}
