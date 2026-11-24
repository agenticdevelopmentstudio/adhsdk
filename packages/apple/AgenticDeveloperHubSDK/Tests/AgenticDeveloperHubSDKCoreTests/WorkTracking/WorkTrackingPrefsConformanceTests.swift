import XCTest
@testable import AgenticDeveloperHubSDKCore

final class WorkTrackingPrefsConformanceTests: XCTestCase {
    private func store(_ values: [String: String] = [:]) -> PrefsConformanceStore {
        let result = PrefsConformanceStore()
        result.values = values
        return result
    }

    func testV1_loadDefaultsOnEmptyStore() throws {
        XCTAssertEqual(try WorkTrackingPrefs.load(store()), WorkTrackingPreferences(
            enabled: false, addedBundleIds: [], removedBundleIds: [], retentionDays: 90))
    }

    func testV2_retentionBelowRangeClampsTo7() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.retentionDays: "1"]))
        XCTAssertEqual(prefs.retentionDays, 7)
    }

    func testV3_retentionAboveRangeClampsTo3650() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.retentionDays: "99999"]))
        XCTAssertEqual(prefs.retentionDays, 3650)
    }

    func testV4_retentionGarbageFallsBackTo90() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.retentionDays: "abc"]))
        XCTAssertEqual(prefs.retentionDays, 90)
    }

    func testV5_enabledTextIsTrimmedAndCaseInsensitive() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.enabled: " YES "]))
        XCTAssertTrue(prefs.enabled)
    }

    func testV6_enabledGarbageIsDefaultFalse() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.enabled: "maybe"]))
        XCTAssertFalse(prefs.enabled)
    }

    func testV7_loadedIdsAreSortedAndDeduplicated() throws {
        let prefs = try WorkTrackingPrefs.load(
            store([WorkTrackingSettingsKeys.addedBundleIds: "[\"com.b\",\"com.a\",\"com.b\"]"]))
        XCTAssertEqual(prefs.addedBundleIds, ["com.a", "com.b"])
    }

    func testV8_garbageIdsLoadAsEmpty() throws {
        let prefs = try WorkTrackingPrefs.load(store([WorkTrackingSettingsKeys.addedBundleIds: "not json"]))
        XCTAssertEqual(prefs.addedBundleIds, [])
    }

    func testV9_saveWritesNormalizedValuesUnderFourKeys() throws {
        let backing = store()
        try WorkTrackingPrefs.save(WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["b", "a", "b"], removedBundleIds: ["z", "z"], retentionDays: 1), backing)
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.enabled], "true")
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.addedBundleIds], "[\"a\",\"b\"]")
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.removedBundleIds], "[\"z\"]")
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.retentionDays], "7")
    }

    func testV10_saveIsOneTransactionThatRollsBack() {
        let backing = store()
        backing.failOnWrite = 3
        let prefs = WorkTrackingPreferences(enabled: true, addedBundleIds: ["a"], removedBundleIds: [],
                                            retentionDays: 30)
        XCTAssertThrowsError(try WorkTrackingPrefs.save(prefs, backing)) { error in
            XCTAssertTrue(error is PrefsConformanceStore.WriteRefused)
        }
        XCTAssertTrue(backing.values.isEmpty, "no key changed")
    }

    func testV11_storeErrorsPropagateFromLoad() {
        let backing = store()
        backing.failReads = true
        XCTAssertThrowsError(try WorkTrackingPrefs.load(backing)) { error in
            XCTAssertTrue(error is PrefsConformanceStore.ReadRefused)
        }
    }

    func testV12_grantIsTrustedUnderItsOwnSignature() throws {
        let backing = store()
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "A", backing)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(backing, signer: "A"), .granted)
    }

    func testV13_grantIsUnknownUnderOtherOrNilSignature() throws {
        let backing = store()
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "A", backing)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(backing, signer: "B"), .unknown)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(backing, signer: nil), .unknown)
    }

    func testV14_rawAnswerIsKept() throws {
        let backing = store()
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: "A", backing)
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(backing), .granted)
    }

    func testV15_nilSignerIsStoredEmptyAndMatchesNothing() throws {
        let backing = store()
        try WorkTrackingPrefs.setLastAccessibility(.granted, signer: nil, backing)
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.accessibilitySigner], "")
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(backing, signer: ""), .unknown)
    }

    func testV16_denialHoldsUnderAnySignature() throws {
        let backing = store()
        try WorkTrackingPrefs.setLastAccessibility(.denied, signer: "A", backing)
        XCTAssertEqual(try WorkTrackingPrefs.trustedAccessibility(backing, signer: "B"), .denied)
    }

    func testV17_lastAccessibilityDefaultsToUnknown() throws {
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(store()), .unknown)
        let bogus = store([WorkTrackingSettingsKeys.accessibilityLastStatus: "bogus"])
        XCTAssertEqual(try WorkTrackingPrefs.lastAccessibility(bogus), .unknown)
    }

    func testV18_savedIdsKeepOnlyDistinctValues() throws {
        let backing = store()
        try WorkTrackingPrefs.save(WorkTrackingPreferences(
            enabled: false, addedBundleIds: ["", "", "x"], removedBundleIds: [], retentionDays: 90), backing)
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.addedBundleIds], "[\"\",\"x\"]")
    }

    func testV19_saveThenLoadReturnsNormalizedPreferences() throws {
        let backing = store()
        try WorkTrackingPrefs.save(WorkTrackingPreferences(
            enabled: true, addedBundleIds: ["com.b", "com.a", "com.b"],
            removedBundleIds: ["z.y", "a.b", "z.y", "a.b"], retentionDays: 1), backing)
        let loaded = try WorkTrackingPrefs.load(backing)
        XCTAssertEqual(loaded.addedBundleIds, ["com.a", "com.b"])
        XCTAssertEqual(loaded.removedBundleIds, ["a.b", "z.y"])
        XCTAssertEqual(loaded.retentionDays, 7)
        XCTAssertEqual(backing.values[WorkTrackingSettingsKeys.addedBundleIds], "[\"com.a\",\"com.b\"]")
    }
}

/// A settings store in a dictionary whose writes roll back and whose reads or writes can be made to fail.
private final class PrefsConformanceStore: WorkTrackingSettingsStore {
    struct ReadRefused: Error {}
    struct WriteRefused: Error {}
    var values: [String: String] = [:]
    var failOnWrite: Int?
    var failReads = false
    private var writes = 0

    func setting(for key: String) throws -> String? {
        if failReads { throw ReadRefused() }
        return values[key]
    }

    func setSetting(_ key: String, _ value: String) throws {
        writes += 1
        if writes == failOnWrite { throw WriteRefused() }
        values[key] = value
    }

    func transaction<T>(_ body: () throws -> T) throws -> T {
        let snapshot = values
        do {
            return try body()
        } catch {
            values = snapshot
            throw error
        }
    }
}
