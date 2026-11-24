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

    func testRemoveOverrideEmitsAChangeForThatKey() {
        let layered = makeLayered(fallback: makeFallback())
        layered.set(2.0, for: zoom)
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        layered.removeOverride(zoom)
        XCTAssertEqual(names, [zoom.name])
        cancellable.cancel()
    }

    func testSecureKeyGoesStraightToTheFallback() {
        let secret = UserSetting<String>("test.secret", default: "", isSecure: true)
        let fallback = makeFallback()
        let overrides = InMemorySettingsStorageProvider()
        let layered = LayeredSettingsStore(overrides: overrides, fallback: fallback)
        layered.set("s3cret", for: secret)
        XCTAssertEqual(fallback.get(secret), "s3cret")
        XCTAssertFalse(overrides.contains(secret))
        XCTAssertFalse(layered.hasOverride(secret))
        XCTAssertEqual(layered.get(secret), "s3cret")
    }

    private let secret = UserSetting<String>("test.secret", default: "", isSecure: true)

    func testV9_containsIsOverrideOnly() {
        let fallback = makeFallback()
        fallback.set(1.5, for: zoom)
        let layered = makeLayered(fallback: fallback)
        XCTAssertFalse(layered.contains(zoom))
    }

    func testV10_containsSecureComesFromFallback() {
        let fallback = makeFallback()
        let layered = makeLayered(fallback: fallback)
        XCTAssertFalse(layered.contains(secret))
        fallback.set("v", for: secret)
        XCTAssertTrue(layered.contains(secret))
    }

    func testV11_keysComeFromOverrides() {
        let fallback = makeFallback()
        fallback.set(1, for: UserSetting<Int>("a.x", default: 0))
        let layered = makeLayered(fallback: fallback)
        layered.set(2, for: UserSetting<Int>("a.y", default: 0))
        XCTAssertEqual(layered.keys(withPrefix: "a."), ["a.y"])
    }

    func testV12_secureFallbackChangeIsRelayedOnce() {
        let fallback = makeFallback()
        let layered = makeLayered(fallback: fallback)
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        fallback.set("v", for: secret)
        XCTAssertEqual(names, [secret.name])
        cancellable.cancel()
    }

    func testV13_removeSecureRemovesFromFallback() {
        let fallback = makeFallback()
        fallback.set("v", for: secret)
        let layered = makeLayered(fallback: fallback)
        layered.remove(secret)
        XCTAssertFalse(fallback.contains(secret))
    }

    func testV14_overrideSetIsPublished() {
        let layered = makeLayered(fallback: makeFallback())
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        layered.set(2.0, for: zoom)
        XCTAssertEqual(names, [zoom.name])
        cancellable.cancel()
    }

    func testV15_releasedStorePassesFallbackChangesThrough() {
        let fallback = makeFallback()
        let overrides = InMemorySettingsStorageProvider()
        overrides.set(2.0, for: zoom)
        var layered: LayeredSettingsStore? = LayeredSettingsStore(overrides: overrides, fallback: fallback)
        var names: [String] = []
        let cancellable = layered?.changes.sink { names.append($0) }
        layered = nil
        fallback.set(1.5, for: zoom)
        XCTAssertEqual(names, [zoom.name])
        cancellable?.cancel()
    }

    func testV16_overrideHoldingSecureNameHidesFallbackChange() {
        let fallback = makeFallback()
        let overrides = InMemorySettingsStorageProvider()
        overrides.set("held", for: UserSetting<String>(secret.name, default: ""))
        let layered = LayeredSettingsStore(overrides: overrides, fallback: fallback)
        var names: [String] = []
        let cancellable = layered.changes.sink { names.append($0) }
        fallback.set("v", for: secret)
        XCTAssertEqual(names, [])
        cancellable.cancel()
    }
}
