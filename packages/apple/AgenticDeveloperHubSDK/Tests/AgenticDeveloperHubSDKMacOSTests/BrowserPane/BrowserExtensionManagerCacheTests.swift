import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// One extension manager per profile for the process: shared by every
/// topic, rebuilt after a failure, closed when the last topic lets go.
@MainActor
final class BrowserExtensionManagerCacheTests: XCTestCase {

    private final class Manager {
        let profile: BrowserExtensionProfile
        var failed = false
        var closed = false
        init(_ profile: BrowserExtensionProfile) { self.profile = profile }
    }

    private final class Holder {}

    private let other = BrowserExtensionProfile.jar(UUID())
    private var made = 0

    private func makeCache() -> BrowserExtensionManagerCache<Manager> {
        BrowserExtensionManagerCache(hasFailed: { $0.failed }, close: { $0.closed = true })
    }

    private func manager(
        _ cache: BrowserExtensionManagerCache<Manager>, _ profile: BrowserExtensionProfile, _ holder: Holder
    ) throws -> Manager {
        try cache.manager(for: profile, holder: holder) {
            made += 1
            return Manager(profile)
        }
    }

    func test_holdersShareOneManagerPerProfile() throws {
        let cache = makeCache()
        let sheet = Holder()
        let window = Holder()

        let first = try manager(cache, .global, sheet)
        let second = try manager(cache, .global, window)
        let jar = try manager(cache, other, window)

        XCTAssertTrue(first === second, "two topics on one profile drive one page")
        XCTAssertFalse(first === jar)
        XCTAssertEqual(made, 2)
        XCTAssertEqual(cache.profiles, [.global, other])
    }

    func test_failedManagerIsClosedAndRebuilt() throws {
        let cache = makeCache()
        let holder = Holder()
        let first = try manager(cache, .global, holder)
        first.failed = true

        let second = try manager(cache, .global, holder)

        XCTAssertTrue(first.closed)
        XCTAssertFalse(first === second)
        XCTAssertFalse(second.closed)
        XCTAssertEqual(made, 2)
    }

    func test_managersCloseOnlyWhenTheLastHolderLetsGo() throws {
        let cache = makeCache()
        let sheet = Holder()
        let window = Holder()
        let shared = try manager(cache, .global, sheet)
        _ = try manager(cache, .global, window)

        cache.release(holder: sheet)
        XCTAssertFalse(shared.closed, "the other topic still uses it")
        XCTAssertEqual(cache.profiles, [.global])

        cache.release(holder: window)
        XCTAssertTrue(shared.closed)
        XCTAssertTrue(cache.profiles.isEmpty)
    }

    func test_aHolderFreedWithoutLettingGoStopsCounting() throws {
        let cache = makeCache()
        let window = Holder()
        var sheet: Holder? = Holder()
        let shared = try manager(cache, .global, sheet!)
        _ = try manager(cache, .global, window)

        sheet = nil
        cache.release(holder: window)

        XCTAssertTrue(shared.closed, "a freed holder does not keep the page open")
        XCTAssertTrue(cache.profiles.isEmpty)
    }

    func test_aFailedMakeCachesNothing() {
        let cache = makeCache()
        XCTAssertThrowsError(try cache.manager(for: .global, holder: Holder()) {
            throw BrowserExtensionError.unavailable("Chrome did not start")
        })
        XCTAssertTrue(cache.profiles.isEmpty)
    }
}
