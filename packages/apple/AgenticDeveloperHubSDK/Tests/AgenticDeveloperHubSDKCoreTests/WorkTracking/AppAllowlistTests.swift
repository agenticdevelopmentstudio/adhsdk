import XCTest
@testable import AgenticDeveloperHubSDKCore

final class AppAllowlistTests: XCTestCase {
    func testDefaultsAreAllowedAndOthersAreNot() {
        let list = AppAllowlist(preferences: .default)
        XCTAssertTrue(list.isAllowed("com.apple.dt.Xcode"))
        XCTAssertFalse(list.isAllowed("com.apple.Safari"))
    }
    func testRemovedDefaultIsNotAllowedAndAddedAppIs() {
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["org.example.Editor"],
                                            removedBundleIds: ["com.apple.Terminal"], retentionDays: 90)
        let list = AppAllowlist(preferences: prefs)
        XCTAssertFalse(list.isAllowed("com.apple.Terminal"))
        XCTAssertTrue(list.isAllowed("org.example.Editor"))
        XCTAssertEqual(list.app(for: "org.example.Editor")?.resolver, .editor)
    }
    func testSublimeMergeIsAGitClientWithNoPath() {
        XCTAssertEqual(AppAllowlist(preferences: .default).app(for: "com.sublimemerge")?.resolver,
                       PathResolverKind.none)
    }
    func testDefaultBundleIdsAreUnique() {
        XCTAssertEqual(Set(AppAllowlist.defaults.map(\.bundleId)).count, AppAllowlist.defaults.count)
    }

    private func prefs(added: [String] = [], removed: [String] = []) -> WorkTrackingPreferences {
        WorkTrackingPreferences(enabled: true, addedBundleIds: added, removedBundleIds: removed, retentionDays: 90)
    }

    func testV006_removedBeatsAdded() {
        let list = AppAllowlist(preferences: prefs(added: ["org.example.Editor"], removed: ["org.example.Editor"]))
        XCTAssertFalse(list.isAllowed("org.example.Editor"))
    }

    func testV007_addedDefaultIsIgnored() {
        let list = AppAllowlist(preferences: prefs(added: ["com.apple.dt.Xcode"]))
        XCTAssertEqual(list.apps.filter { $0.bundleId == "com.apple.dt.Xcode" }.count, 1)
        XCTAssertEqual(list.app(for: "com.apple.dt.Xcode")?.resolver, .document)
    }

    func testV008_appsAreSortedByNameThenBundleId() throws {
        let apps = AppAllowlist(preferences: .default).apps
        let sorted = apps.sorted { ($0.name, $0.bundleId) < ($1.name, $1.bundleId) }
        XCTAssertEqual(apps, sorted)
        let android = try XCTUnwrap(apps.firstIndex { $0.name == "Android Studio" })
        let bbedit = try XCTUnwrap(apps.firstIndex { $0.name == "BBEdit" })
        XCTAssertLessThan(android, bbedit)
    }

    func testV009_unlistedAppLooksUpAsNil() {
        XCTAssertNil(AppAllowlist(preferences: .default).app(for: "com.apple.Safari"))
    }

    func testV010_duplicateAddedIdsCollapse() {
        let list = AppAllowlist(preferences: prefs(added: ["a.b", "a.b"]), defaults: [])
        XCTAssertEqual(list.apps.map(\.bundleId), ["a.b"])
    }

    func testV011_duplicateDefaultsFirstInSortedOrderWins() {
        let defaults = [TrackedApp(bundleId: "x.y", name: "B", resolver: .none),
                        TrackedApp(bundleId: "x.y", name: "A", resolver: .editor)]
        let list = AppAllowlist(preferences: .default, defaults: defaults)
        XCTAssertEqual(list.apps.map(\.name), ["A", "B"])
        XCTAssertEqual(list.app(for: "x.y")?.name, "A")
    }

    func testV012_trackedAppIdIsItsBundleId() {
        XCTAssertEqual(TrackedApp(bundleId: "x.y", name: "N", resolver: .none).id, "x.y")
    }

    func testV013_emptyDefaultsAllowNothing() {
        let list = AppAllowlist(preferences: .default, defaults: [])
        XCTAssertTrue(list.apps.isEmpty)
        XCTAssertFalse(list.isAllowed("com.apple.dt.Xcode"))
        XCTAssertFalse(list.isAllowed(""))
    }
}
