import XCTest
@testable import AgenticDeveloperHubSDKCore

/// A settings-only `BillingPersistence`: the settings table and the derivation
/// reset are real, every other requirement is outside what `BillingPrefs` calls.
private final class PrefsSettingsStore: BillingPersistence {
    struct Unsupported: Error {}
    struct ReadFailure: Error {}

    var values: [String: String] = [:]
    var readError: Error?
    private(set) var resetCount = 0
    let billingSettingsKeys = BillingSettingsKeys(prefix: "test_billing_")

    func setting(for key: String) throws -> String? {
        if let readError { throw readError }
        return values[key]
    }
    func setSetting(_ key: String, _ value: String) throws { values[key] = value }
    func transaction<T>(_ body: () throws -> T) throws -> T { try body() }
    func resetBillingDerivationOfDerivedSessions() throws -> Int { resetCount += 1; return 3 }

    func resetBillingDerivation(projectId: String) throws -> Int { throw Unsupported() }
    func billingClients(includeArchived: Bool) throws -> [BillingClientDTO] { throw Unsupported() }
    func billingClient(id: String) throws -> BillingClientDTO? { throw Unsupported() }
    func upsertBillingClient(_ dto: BillingClientDTO) throws { throw Unsupported() }
    func deleteBillingClient(id: String) throws { throw Unsupported() }
    func billingLockedEntryCount(clientId: String) throws -> Int { throw Unsupported() }
    func billingProjects(includeArchived: Bool) throws -> [BillingProjectDTO] { throw Unsupported() }
    func billingProject(id: String) throws -> BillingProjectDTO? { throw Unsupported() }
    func upsertBillingProject(_ dto: BillingProjectDTO) throws { throw Unsupported() }
    func billingEntryCount(projectId: String) throws -> Int { throw Unsupported() }
    func deleteBillingProject(id: String) throws { throw Unsupported() }
    func billingRepos(projectId: String?) throws -> [BillingRepoDTO] { throw Unsupported() }
    func billingRepo(id: String) throws -> BillingRepoDTO? { throw Unsupported() }
    func upsertBillingRepo(_ dto: BillingRepoDTO) throws { throw Unsupported() }
    func deleteBillingRepo(id: String) throws { throw Unsupported() }
    func billingSegment(id: String) throws -> BillingSegmentDTO? { throw Unsupported() }
    func runningBillingSegments(origin: String?) throws -> [BillingSegmentDTO] { throw Unsupported() }
    func closeBillingSegment(id: String, endedAt: String, seconds: Int) throws -> Bool { throw Unsupported() }
    func addBillingSegmentFlag(id: String, flag: String) throws -> Bool { throw Unsupported() }
    func upsertBillingSegment(_ dto: BillingSegmentDTO) throws { throw Unsupported() }
    func billingHistoryStart(sessionId: String, sessionStartedAt: String) throws -> String? { throw Unsupported() }
    func billingActivitySeconds(sessionId: String, afterId: Int64) throws -> (seconds: [Int], lastId: Int64) {
        throw Unsupported()
    }
    func markBillingDerived(sessionId: String, at value: String) throws { throw Unsupported() }
    func replaceDerivedSegments(
        sessionId: String, runs: [BillingRun], context: BillingSegmentContext, historyStartsAt: String?
    ) throws -> Int { throw Unsupported() }
    func billingAppSpansNeedingDerivation(limit: Int) throws -> [BillingAppSpanRow] { throw Unsupported() }
    func billingIdleIntervals(from start: String, to end: String) throws -> [BillingIdleInterval] {
        throw Unsupported()
    }
    func markAppSpanBillingDerived(spanId: String, at value: String) throws { throw Unsupported() }
    func billingEntries(projectId: String?, status: String?, since: String) throws -> [BillingEntryDTO] {
        throw Unsupported()
    }
    func billingEntry(id: String) throws -> BillingEntryDTO? { throw Unsupported() }
    func upsertBillingEntry(_ dto: BillingEntryDTO, overwrite: BillingEntryOverwrite) throws -> Bool {
        throw Unsupported()
    }
    func deleteBillingEntry(id: String) throws { throw Unsupported() }
    func billingFrozenSupplementCount(of entryId: String) throws -> Int { throw Unsupported() }
    func billingEntryForSlot(projectId: String, day: String, groupKey: String) throws -> StoredBillingEntry? {
        throw Unsupported()
    }
    func billingOpenSupplement(of entryId: String) throws -> StoredBillingEntry? { throw Unsupported() }
    func billingEntriesOnDay(projectId: String, day: String) throws -> [StoredBillingEntry] { throw Unsupported() }
    func billingEntriesOverlapping(
        projectId: String, from: String, until: String
    ) throws -> [StoredBillingEntry] { throw Unsupported() }
    func billingEntryDays() throws -> [BillingProjectDay] { throw Unsupported() }
    func billingUnsettledDays() throws -> [BillingProjectDay] { throw Unsupported() }
    func setBillingEntryBilledRanges(id: String, ranges: String) throws { throw Unsupported() }
    func deleteEmptyBillingEntry(id: String) throws -> Bool { throw Unsupported() }
    func markBillingEntryDescriptionEdited(id: String) throws { throw Unsupported() }
    func setBillingEntryDescription(id: String, description: String, at now: String) throws -> Bool {
        throw Unsupported()
    }
    func billingRollupCandidates(ids: [String]?) throws -> [BillingSegmentDTO] { throw Unsupported() }
    func billingSegmentsForEntry(id: String) throws -> [BillingSegmentDTO] { throw Unsupported() }
    func attachSegments(ids: [String], toEntry entryId: String) throws { throw Unsupported() }
    func appendBillingAudit(
        entryId: String, field: String, oldValue: String, newValue: String, source: String
    ) throws { throw Unsupported() }
    func billingSessionTitles(sessionIds: [String]) throws -> BillingSessionTitles { throw Unsupported() }
    func unassignedSegmentIDs(projectRoot: String) throws -> [String] { throw Unsupported() }
    func assignSegments(ids: [String], toProject projectId: String?) throws -> Int { throw Unsupported() }
    func billingOverviewBuckets() throws -> [(currency: String, buckets: [String: BillingOverviewBucketDTO])] {
        throw Unsupported()
    }
}

final class BillingPrefsConformanceTests: XCTestCase {

    func testV001_emptySettingsTableYieldsTheSharedDefaults() throws {
        let snapshot = try BillingPrefs.snapshot(PrefsSettingsStore())

        XCTAssertEqual(snapshot.idleCutoffSeconds, 900)
        XCTAssertEqual(snapshot.granularity, .day)
        XCTAssertEqual(snapshot.roundingMinutes, 15)
        XCTAssertEqual(snapshot.roundingMode, "up")
        XCTAssertEqual(snapshot.defaultRateCents, 0)
        XCTAssertEqual(snapshot.currency, "USD")
        XCTAssertEqual(snapshot.manualTimerCapSeconds, 28_800)
        XCTAssertTrue(snapshot.trackUnassigned)
    }

    func testV002_idleCutoffZeroClampsToOneMinute() throws {
        let store = PrefsSettingsStore()
        store.values[store.billingSettingsKeys.idleCutoffMinutes] = "0"
        XCTAssertEqual(try BillingPrefs.snapshot(store).idleCutoffSeconds, 60)
    }

    func testV003_idleCutoffAboveTheLimitClampsTo480Minutes() throws {
        let store = PrefsSettingsStore()
        store.values[store.billingSettingsKeys.idleCutoffMinutes] = "9999"
        XCTAssertEqual(try BillingPrefs.snapshot(store).idleCutoffSeconds, 28_800)
    }

    func testV004_unrecognisedGranularityFallsBackToDay() throws {
        let store = PrefsSettingsStore()
        store.values[store.billingSettingsKeys.granularity] = "weekly"
        XCTAssertEqual(try BillingPrefs.snapshot(store).granularity, .day)
    }

    func testV005_aFailedSettingsReadThrowsRatherThanFallingBackToDefaults() {
        let store = PrefsSettingsStore()
        store.readError = PrefsSettingsStore.ReadFailure()
        XCTAssertThrowsError(try BillingPrefs.snapshot(store)) { error in
            XCTAssertTrue(error is PrefsSettingsStore.ReadFailure)
        }
    }

    func testV006_applyWritesOnlyBillingKeys() throws {
        let store = PrefsSettingsStore()
        let keys = store.billingSettingsKeys
        try BillingPrefs.apply([keys.currency: "EUR", "unrelated_key": "x"], database: store)

        XCTAssertEqual(store.values[keys.currency], "EUR")
        XCTAssertNil(store.values["unrelated_key"])
        XCTAssertEqual(store.values.count, 1)
    }

    func testV007_changingTheIdleCutoffResetsDerivation() throws {
        let store = PrefsSettingsStore()
        let keys = store.billingSettingsKeys
        store.values[keys.idleCutoffMinutes] = "15"

        let result = try BillingPrefs.apply([keys.idleCutoffMinutes: "30"], database: store)

        XCTAssertEqual(store.resetCount, 1)
        XCTAssertEqual(result.idleCutoffSeconds, 1800, "apply returns the snapshot now in force")
    }

    func testV008_changingOnlyTheCurrencyDoesNotResetDerivation() throws {
        let store = PrefsSettingsStore()
        let keys = store.billingSettingsKeys
        store.values[keys.idleCutoffMinutes] = "15"

        try BillingPrefs.apply([keys.currency: "EUR"], database: store)

        XCTAssertEqual(store.resetCount, 0)
    }

    func testV009_wireFormConvertsSecondsBackToMinutesAndHours() {
        let snapshot = BillingPrefs.Snapshot(
            idleCutoffSeconds: 900, granularity: .day, defaultRateCents: 0, currency: "USD",
            roundingMinutes: 15, roundingMode: "up", manualTimerCapSeconds: 28_800, trackUnassigned: true
        )
        XCTAssertEqual(snapshot.wireForm.idleCutoffMinutes, 15)
        XCTAssertEqual(snapshot.wireForm.manualTimerCapHours, 8)
    }

    func testApplyStoresValuesVerbatimAndClampsOnRead() throws {
        let store = PrefsSettingsStore()
        let keys = store.billingSettingsKeys
        let result = try BillingPrefs.apply([keys.idleCutoffMinutes: "9999"], database: store)

        XCTAssertEqual(store.values[keys.idleCutoffMinutes], "9999")
        XCTAssertEqual(result.idleCutoffSeconds, 28_800)
    }

    func testRollupOptionsCarryGranularityRateAndCurrency() {
        let snapshot = BillingPrefs.Snapshot(
            idleCutoffSeconds: 900, granularity: .day, defaultRateCents: 12_500, currency: "EUR",
            roundingMinutes: 15, roundingMode: "up", manualTimerCapSeconds: 28_800, trackUnassigned: true
        )
        let options = snapshot.rollupOptions
        XCTAssertEqual(options.granularity, .day)
        XCTAssertEqual(options.defaultRateCents, 12_500)
        XCTAssertEqual(options.currency, "EUR")
    }
}
