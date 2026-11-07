import XCTest
import Combine
@testable import AgenticDeveloperHubSDKCore

@MainActor
final class LayeredSettingsStoreTests: XCTestCase {

    private let zoom = UserSetting<Double>("browser.page_zoom", default: 1.0)
    private let home = UserSetting<String>("browser.home_page", default: "")
    private let editorFont = UserSetting<Int>("editor.font_size", default: 12)

    private func makeFallback() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makeLayered(fallback: SettingsStore) -> LayeredSettingsStore {
        LayeredSettingsStore(overrides: InMemorySettingsStorageProvider(), fallback: fallback)
    }

    func testGetFallsBackWhenNoOverride() {
        let fallback = makeFallback()
        fallback.set(1.5, for: zoom)
        let layered = makeLayered(fallback: fallback)
        XCTAssertEqual(layered.get(zoom), 1.5)
        XCTAssertFalse(layered.hasOverride(zoom))
    }

    func testOverrideWins() {
        let fallback = makeFallback()
        fallback.set(1.5, for: zoom)
        let layered = makeLayered(fallback: fallback)
        layered.set(2.0, for: zoom)
        XCTAssertEqual(layered.get(zoom), 2.0)
        XCTAssertEqual(fallback.get(zoom), 1.5)
        XCTAssertTrue(layered.hasOverride(zoom))
    }

    func testRemoveOverrideRevealsFallback() {
        let fallback = makeFallback()
        fallback.set(1.5, for: zoom)
        let layered = makeLayered(fallback: fallback)
        layered.set(2.0, for: zoom)
        layered.removeOverride(zoom)
        XCTAssertEqual(layered.get(zoom), 1.5)
        XCTAssertFalse(layered.hasOverride(zoom))
    }

    func testFallbackChangeIsPublishedWithoutOverride() {
        let fallback = makeFallback()
        let layered = makeLayered(fallback: fallback)
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        fallback.set(1.5, for: zoom)
        XCTAssertEqual(names, [zoom.name])
        cancellable.cancel()
    }

    func testFallbackChangeIsHiddenByAnOverride() {
        let fallback = makeFallback()
        let layered = makeLayered(fallback: fallback)
        layered.set(2.0, for: zoom)
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        fallback.set(1.5, for: zoom)
        XCTAssertEqual(names, [])
        XCTAssertEqual(layered.get(zoom), 2.0)
        cancellable.cancel()
    }

    func testRemoveAllOverridesWithPrefix() {
        let layered = makeLayered(fallback: makeFallback())
        layered.set(2.0, for: zoom)
        layered.set("example.com", for: home)
        layered.set(20, for: editorFont)
        layered.removeAllOverrides(withPrefix: "browser.")
        XCTAssertFalse(layered.hasOverride(zoom))
        XCTAssertFalse(layered.hasOverride(home))
        XCTAssertTrue(layered.hasOverride(editorFont))
    }
}
