import XCTest
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// Every test runs against its own defaults suite and settings store, never
/// the process's standard defaults.
@MainActor
final class NoticeSettingsTests: XCTestCase {

    private let legacyKey = "legacy_deliver_notifications"
    private var suiteNames: [String] = []
    private var defaults = UserDefaults.standard
    private var store = SettingsStore()

    override func setUp() async throws {
        try await super.setUp()
        freshDomain()
    }

    override func tearDown() async throws {
        for name in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        try await super.tearDown()
    }

    private func freshDomain() {
        let name = "NoticeSettingsTests.\(UUID().uuidString)"
        suiteNames.append(name)
        defaults = UserDefaults(suiteName: name) ?? .standard
        store = SettingsStore(
            with: UserDefaultsSettingsStorageProvider(defaults: defaults),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    private var rules: NoticeRoutingRules { store.get(NoticeSettings.routingRules) }

    private func migrate() {
        NoticeSettings.migrateLegacyDeliverSetting(defaults: defaults, legacyKey: legacyKey, store: store)
    }

    func testMigrationActsOnlyOnExplicitTrue() {
        migrate()
        XCTAssertEqual(rules.profiles[.fyi]?.forwardToSystem, false, "an absent key is not a choice")

        freshDomain()
        defaults.set(true, forKey: legacyKey)
        migrate()
        XCTAssertEqual(rules.profiles[.fyi]?.forwardToSystem, true)
        XCTAssertNil(defaults.object(forKey: legacyKey), "the legacy key is retired")

        freshDomain()
        defaults.set(false, forKey: legacyKey)
        migrate()
        XCTAssertEqual(rules.profiles[.fyi]?.forwardToSystem, false)
    }

    func testMigrationRunsOnce() {
        defaults.set(true, forKey: legacyKey)
        migrate()
        XCTAssertTrue(defaults.bool(forKey: "notice_routing_migrated_v1"))
        XCTAssertEqual(rules.profiles[.fyi]?.forwardToSystem, true)

        // The user turns forwarding back off; a stale legacy value reappearing
        // must not turn it on again.
        store.set(NoticeRoutingRules.defaults, for: NoticeSettings.routingRules)
        defaults.set(true, forKey: legacyKey)
        migrate()
        XCTAssertEqual(rules.profiles[.fyi]?.forwardToSystem, false)
    }

    func testRoutingRulesSettingDefaults() {
        XCTAssertEqual(NoticeSettings.routingRules.name, "notice_routing_rules")
        XCTAssertEqual(NoticeSettings.routingRules.defaultValue, .defaults)
    }
}
