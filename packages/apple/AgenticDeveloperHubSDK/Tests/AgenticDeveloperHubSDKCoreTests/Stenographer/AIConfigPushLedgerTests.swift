import XCTest
@testable import AgenticDeveloperHubSDKCore

final class AIConfigPushLedgerTests: XCTestCase {

    private var suite: String!
    private var defaults: UserDefaults!

    override func setUp() {
        suite = "ai-config-ledger-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    private func config(_ id: UUID) -> ResolvedProviderConfig {
        ResolvedProviderConfig(
            id: id, name: "T", pluginIdentifier: "p", templateId: "t", model: "m", values: [:], secrets: [:])
    }

    func testFirstPushRemovesNothing() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        XCTAssertEqual(ledger.removed(configured: [UUID()]), [])
    }

    func testARecordedPushThenADroppedConfigurationIsRemoved() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let first = UUID(), second = UUID()
        ledger.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first), config(second)], removedConfigIds: []))
        XCTAssertEqual(ledger.removed(configured: [first]), [second])
    }

    func testAConfiguredButUnresolvedConfigurationIsNeitherRemovedNorForgotten() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let first = UUID(), second = UUID()
        ledger.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first), config(second)], removedConfigIds: []))
        // b is still configured but could not be resolved this time, so it is not in `configs`.
        XCTAssertEqual(ledger.removed(configured: [first, second]), [])
        ledger.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first)], removedConfigIds: []))
        XCTAssertEqual(ledger.lastPushed(), [first, second])
    }

    func testARemovalDropsTheIdFromTheLedger() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let first = UUID(), second = UUID()
        ledger.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first), config(second)], removedConfigIds: []))
        ledger.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first)], removedConfigIds: [second]))
        XCTAssertEqual(ledger.lastPushed(), [first])
    }

    func testTwoLedgersWithDifferentKeysAreIndependent() {
        let http = AIConfigPushLedger(key: "http", defaults: defaults)
        let xpc = AIConfigPushLedger(key: "xpc", defaults: defaults)
        let first = UUID()
        http.recordLanded(AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [config(first)], removedConfigIds: []))
        XCTAssertEqual(xpc.removed(configured: []), [])
    }

    func testSyncDecodesWithoutRemovedConfigIds() throws {
        let body = Data(#"{"enabled": true, "configs": []}"#.utf8)
        let sync = try JSONDecoder().decode(AIProviderConfigSync.self, from: body)
        XCTAssertNil(sync.removedConfigIds)
    }

    private func sync(_ configs: [UUID], removed: [UUID]?) -> AIProviderConfigSync {
        AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: configs.map(config), removedConfigIds: removed)
    }

    func testV7_malformedStoredIdsAreSkipped() {
        let valid = UUID()
        defaults.set(["not-a-uuid", valid.uuidString], forKey: "k")
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        XCTAssertEqual(ledger.lastPushed(), [valid])
    }

    func testV8_removedIdsComeBackInAscendingUUIDStringOrder() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let ids = [UUID(), UUID(), UUID()]
        ledger.recordLanded(sync(ids, removed: []))
        let expected = ids.sorted { $0.uuidString < $1.uuidString }
        XCTAssertEqual(ledger.removed(configured: []), expected)
    }

    func testV9_aNilRemovalListKeepsTheExistingIdsBesideTheNewOne() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let other = UUID(), fresh = UUID()
        ledger.recordLanded(sync([other], removed: []))
        ledger.recordLanded(sync([fresh], removed: nil))
        XCTAssertEqual(ledger.lastPushed(), [other, fresh])
    }

    func testV10_theStoredEntryIsASortedArrayOfUUIDStrings() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let first = UUID(), second = UUID()
        ledger.recordLanded(sync([first, second], removed: []))
        let raw = defaults.stringArray(forKey: "k")
        XCTAssertEqual(raw, [first.uuidString, second.uuidString].sorted())
    }

    func testV11_aConfigThatIsAlsoListedAsRemovedStaysInTheLedger() {
        let ledger = AIConfigPushLedger(key: "k", defaults: defaults)
        let first = UUID()
        ledger.recordLanded(sync([first], removed: [first]))
        XCTAssertEqual(ledger.lastPushed(), [first])
    }
}
