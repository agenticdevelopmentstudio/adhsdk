import XCTest
@testable import AgenticDeveloperHubSDKCore

@MainActor
final class WorkTrackingUserSettingsConformanceTests: XCTestCase {
    private var created: [WorkTrackingUserSettings] = []

    override func tearDown() async throws {
        for settings in created {
            settings.enabled.remove()
            settings.addedBundleIds.remove()
            settings.removedBundleIds.remove()
            settings.retentionDays.remove()
        }
        created = []
    }

    private func make(prefix: String? = nil) -> WorkTrackingUserSettings {
        let settings = WorkTrackingUserSettings(prefix: prefix ?? "wt_conf_\(UUID().uuidString)_")
        created.append(settings)
        return settings
    }

    func testV1_freshPrefixYieldsDefaultPreferences() {
        XCTAssertEqual(make().preferences, WorkTrackingPreferences.default)
    }

    func testV2_preferencesAreNormalized() {
        let settings = make()
        settings.enabled.value = true
        settings.addedBundleIds.value = ["com.b", "com.a", "com.b"]
        settings.removedBundleIds.value = ["com.z", "com.z"]
        settings.retentionDays.value = 1
        XCTAssertEqual(settings.preferences, WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["com.a", "com.b"], removedBundleIds: ["com.z"], retentionDays: 7))
    }

    func testV3_retentionAboveRangeClampsTo3650() {
        let settings = make()
        settings.retentionDays.value = 99_999
        XCTAssertEqual(settings.preferences.retentionDays, 3650)
    }

    func testV4_storedValuesStayRaw() {
        let settings = make()
        settings.retentionDays.value = 1
        XCTAssertEqual(settings.retentionDays.value, 1)
        XCTAssertEqual(settings.preferences.retentionDays, 7)
    }

    func testV5_namesCarryThePrefix() {
        let prefix = "p_\(UUID().uuidString)_"
        let settings = make(prefix: prefix)
        XCTAssertEqual(settings.enabled.name, prefix + "activity_enabled")
        XCTAssertEqual(settings.addedBundleIds.name, prefix + "activity_added_bundle_ids")
        XCTAssertEqual(settings.removedBundleIds.name, prefix + "activity_removed_bundle_ids")
        XCTAssertEqual(settings.retentionDays.name, prefix + "activity_retention_days")
    }

    func testV6_prefixIsNotSeparated() {
        let settings = make(prefix: "p")
        XCTAssertEqual(settings.enabled.name, "pactivity_enabled")
    }

    func testV7_prefixesAreIsolated() {
        let first = make(prefix: "a_\(UUID().uuidString)_")
        let second = make(prefix: "b_\(UUID().uuidString)_")
        first.enabled.value = true
        XCTAssertTrue(first.enabled.value)
        XCTAssertFalse(second.enabled.value)
    }

    func testV8_preferencesReflectLaterChanges() {
        let settings = make()
        XCTAssertFalse(settings.preferences.enabled)
        settings.enabled.value = true
        XCTAssertTrue(settings.preferences.enabled)
    }

    func testV9_exactlyFourUserSettings() {
        let labels = Mirror(reflecting: make()).children.compactMap { child -> String? in
            String(describing: type(of: child.value)).hasPrefix("UserSetting<") ? child.label : nil
        }
        XCTAssertEqual(Set(labels), ["enabled", "addedBundleIds", "removedBundleIds", "retentionDays"])
        XCTAssertEqual(labels.count, 4)
    }
}
