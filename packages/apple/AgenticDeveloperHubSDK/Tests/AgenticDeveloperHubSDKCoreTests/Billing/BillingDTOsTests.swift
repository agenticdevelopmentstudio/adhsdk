import XCTest
@testable import AgenticDeveloperHubSDKCore

/// The DTOs cross XPC and HTTP as snake_case JSON. This pins the wire names so
/// a rename on one side can't quietly stop decoding on the other.
final class BillingDTOsTests: XCTestCase {

    private func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func testEntryRoundTripsThroughSnakeCaseJSON() throws {
        let entry = BillingEntryDTO(
            id: "e1",
            projectId: "p1",
            clientId: "c1",
            day: "2026-09-22",
            startedAt: "2026-09-22T14:00:00Z",
            endedAt: "2026-09-22T16:15:00Z",
            rawSeconds: 8_100,
            billedSeconds: 8_100,
            rateCents: 12_500,
            currency: "USD",
            amountCents: 28_125,
            roundingMinutes: 15,
            roundingMode: "up",
            status: "unbilled",
            description: "Billing feature",
            origin: "auto",
            locked: false,
            supplementsEntryId: nil,
            createdAt: "2026-09-22T16:16:00Z",
            updatedAt: "2026-09-22T16:16:00Z"
        )

        let data = try encoder().encode(entry)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"billed_seconds\":8100"), "wire name is snake_case")
        XCTAssertTrue(json.contains("\"amount_cents\":28125"), "money is integer cents")
        XCTAssertFalse(json.contains("."), "no decimal point anywhere in the payload")

        let decoded = try decoder().decode(BillingEntryDTO.self, from: data)
        XCTAssertEqual(decoded.amountCents, 28_125)
        XCTAssertNil(decoded.supplementsEntryId)
    }

    func testSegmentRoundTripsWithARunningEndedAt() throws {
        let segment = BillingSegmentDTO(
            id: "s1",
            sessionId: "",
            origin: "manual",
            projectId: "p1",
            repoId: nil,
            projectRoot: "/Users/me/code/app",
            branch: "",
            startedAt: "2026-09-22T14:00:00Z",
            endedAt: "",
            tz: "America/Los_Angeles",
            seconds: 0,
            note: "call with client",
            entryId: nil,
            flags: "",
            createdAt: "2026-09-22T14:00:00Z",
            updatedAt: "2026-09-22T14:00:00Z"
        )

        let decoded = try decoder().decode(
            BillingSegmentDTO.self, from: try encoder().encode(segment)
        )
        XCTAssertEqual(decoded.endedAt, "", "a running segment has an empty ended_at, not null")
        XCTAssertTrue(decoded.isRunning)
    }

    func testOverviewTotalsAreIntegers() throws {
        let overview = BillingOverviewDTO(
            unbilled: BillingOverviewBucketDTO(seconds: 3600, amountCents: 12_500, entryCount: 1),
            billed: BillingOverviewBucketDTO(seconds: 7200, amountCents: 25_000, entryCount: 2),
            paid: BillingOverviewBucketDTO(seconds: 0, amountCents: 0, entryCount: 0),
            currency: "USD"
        )
        let json = try XCTUnwrap(String(data: encoder().encode(overview), encoding: .utf8))
        XCTAssertTrue(json.contains("\"amount_cents\":12500"))
        XCTAssertTrue(json.contains("\"entry_count\":1"))
    }

    /// Each currency travels as its own row; nothing is summed across them.
    func testOverviewCarriesEachCurrencyApart() throws {
        let bucket = { (cents: Int) in BillingOverviewBucketDTO(seconds: 3600, amountCents: cents, entryCount: 1) }
        let zero = BillingOverviewBucketDTO(seconds: 0, amountCents: 0, entryCount: 0)
        let overview = BillingOverviewDTO(
            unbilled: bucket(10_000), billed: zero, paid: zero, currency: "USD",
            byCurrency: [
                BillingOverviewCurrencyDTO(currency: "EUR", unbilled: bucket(4_000), billed: zero, paid: zero),
                BillingOverviewCurrencyDTO(currency: "USD", unbilled: bucket(10_000), billed: zero, paid: zero)
            ]
        )
        let data = try encoder().encode(overview)
        XCTAssertTrue(try XCTUnwrap(String(data: data, encoding: .utf8)).contains("\"by_currency\""))
        XCTAssertEqual(try decoder().decode(BillingOverviewDTO.self, from: data), overview)
    }

    /// A reply from an older daemon has no `by_currency`; it still decodes.
    func testOverviewWithoutByCurrencyStillDecodes() throws {
        let json = """
        {"unbilled":{"seconds":1,"amount_cents":2,"entry_count":1},
         "billed":{"seconds":0,"amount_cents":0,"entry_count":0},
         "paid":{"seconds":0,"amount_cents":0,"entry_count":0},"currency":"USD"}
        """
        let decoded = try decoder().decode(BillingOverviewDTO.self, from: Data(json.utf8))
        XCTAssertTrue(decoded.byCurrency.isEmpty)
        XCTAssertEqual(decoded.unbilled.amountCents, 2)
    }

    func testStatusCoversExactlyThreeStates() {
        XCTAssertEqual(BillingStatus.allCases.map(\.rawValue), ["unbilled", "billed", "paid"])
        XCTAssertEqual(BillingStatus(rawValue: "invoiced"), nil)
    }

    /// Status moves forward by hand only; nothing in the code path may skip or
    /// reverse it silently.
    func testStatusAdvanceIsOneStepForward() {
        XCTAssertEqual(BillingStatus.unbilled.next, .billed)
        XCTAssertEqual(BillingStatus.billed.next, .paid)
        XCTAssertNil(BillingStatus.paid.next)
    }

    // MARK: Conformance vectors billing-dt-os-001 ... 014

    func testV001_statusNextAdvancesThenEnds() {
        XCTAssertEqual(BillingStatus.unbilled.next, .billed)
        XCTAssertEqual(BillingStatus.billed.next, .paid)
        XCTAssertNil(BillingStatus.paid.next)
    }

    func testV002_billedLocksTheEntry() {
        XCTAssertTrue(BillingStatus.billed.locksTheEntry)
        XCTAssertTrue(BillingStatus.paid.locksTheEntry)
    }

    func testV003_unbilledDoesNotLock() {
        XCTAssertFalse(BillingStatus.unbilled.locksTheEntry)
    }

    func testV004_segmentWithEmptyEndIsRunning() {
        let running = BillingSegmentDTO(id: "s", origin: "auto", startedAt: "2026-09-22T14:00:00Z")
        XCTAssertTrue(running.isRunning)
        let ended = BillingSegmentDTO(id: "s", origin: "auto", startedAt: "2026-09-22T14:00:00Z",
                                      endedAt: "2026-09-22T15:00:00Z")
        XCTAssertFalse(ended.isRunning)
    }

    func testV005_manualOriginIsManual() {
        XCTAssertEqual(BillingSegmentDTO.manualOrigin, "manual")
        XCTAssertEqual(BillingSegmentDTO.autoOrigin, "auto")
        XCTAssertTrue(BillingSegmentDTO(id: "s", origin: "manual", startedAt: "x").isManual)
        XCTAssertFalse(BillingSegmentDTO(id: "s", origin: "auto", startedAt: "x").isManual)
    }

    func testV006_overviewKeepsOneRowPerCurrencyWithTopLevelMatchingTheFirst() throws {
        let bucket = { (cents: Int) in BillingOverviewBucketDTO(seconds: 60, amountCents: cents, entryCount: 1) }
        let zero = BillingOverviewBucketDTO(seconds: 0, amountCents: 0, entryCount: 0)
        let usd = BillingOverviewCurrencyDTO(currency: "USD", unbilled: bucket(500), billed: zero, paid: zero)
        let eur = BillingOverviewCurrencyDTO(currency: "EUR", unbilled: bucket(300), billed: zero, paid: zero)
        let overview = BillingOverviewDTO(
            unbilled: usd.unbilled, billed: usd.billed, paid: usd.paid, currency: usd.currency,
            byCurrency: [usd, eur])
        let decoded = try decoder().decode(BillingOverviewDTO.self, from: try encoder().encode(overview))
        XCTAssertEqual(decoded.byCurrency.count, 2)
        XCTAssertEqual(decoded.unbilled, decoded.byCurrency[0].unbilled)
        XCTAssertEqual(decoded.currency, decoded.byCurrency[0].currency)
    }

    func testV007_overviewWithoutByCurrencyDecodesWithEmptyList() throws {
        let json = """
        {"unbilled":{"seconds":0,"amount_cents":0,"entry_count":0},
         "billed":{"seconds":0,"amount_cents":0,"entry_count":0},
         "paid":{"seconds":0,"amount_cents":0,"entry_count":0},"currency":"USD"}
        """
        XCTAssertEqual(try decoder().decode(BillingOverviewDTO.self, from: Data(json.utf8)).byCurrency, [])
    }

    func testV008_failedListReadSentinel() {
        XCTAssertEqual(String(data: BillingWire.readFailedRow, encoding: .utf8), "{\"billing_read_failed\":true}")
        XCTAssertEqual(BillingWire.readFailedKey, "billing_read_failed")
        XCTAssertEqual(BillingWire.failedCount, -1)
    }

    func testV009_settingsKeysFromPrefixAndAllowListOfEight() {
        let keys = BillingSettingsKeys(prefix: "app_billing_")
        XCTAssertEqual(keys.idleCutoffMinutes, "app_billing_idle_cutoff_minutes")
        XCTAssertEqual(keys.all.count, 8)
        XCTAssertTrue(keys.all.allSatisfy { $0.hasPrefix("app_billing_") })
        XCTAssertTrue(keys.all.contains("app_billing_track_unassigned"))
    }

    func testV010_clampsToIdleRange() {
        XCTAssertEqual(BillingLimits.clamp(9999, to: BillingLimits.idleCutoffMinutes), 480)
        XCTAssertEqual(BillingLimits.clamp(0, to: BillingLimits.idleCutoffMinutes), 1)
        XCTAssertEqual(BillingLimits.clamp(30, to: BillingLimits.idleCutoffMinutes), 30)
    }

    func testV011_clampsToRoundingRange() {
        XCTAssertEqual(BillingLimits.clamp(0, to: BillingLimits.roundingMinutes), 1)
        XCTAssertEqual(BillingLimits.clamp(1000, to: BillingLimits.roundingMinutes), 240)
        XCTAssertEqual(BillingLimits.clamp(-5, to: BillingLimits.defaultRateCents), 0)
        XCTAssertEqual(BillingLimits.clamp(99, to: BillingLimits.manualTimerCapHours), 24)
    }

    func testV012_unconfiguredDefaults() {
        XCTAssertEqual(BillingDefaults.roundingMinutes, 15)
        XCTAssertEqual(BillingDefaults.roundingMode, "up")
        XCTAssertEqual(BillingDefaults.currency, "USD")
        XCTAssertEqual(BillingDefaults.idleCutoffMinutes, 15)
        XCTAssertEqual(BillingDefaults.granularity, "day")
        XCTAssertEqual(BillingDefaults.defaultRateCents, 0)
        XCTAssertEqual(BillingDefaults.manualTimerCapHours, 8)
        XCTAssertTrue(BillingDefaults.trackUnassigned)
    }

    func testV013_repoClaimRefusalNamesRootAndBranchScope() {
        XCTAssertEqual(
            BillingRefusalText.repoAlreadyClaimed(root: "/r", branch: ""),
            "/r (any branch) already belongs to another project.")
        XCTAssertEqual(
            BillingRefusalText.repoAlreadyClaimed(root: "/r", branch: "dev"),
            "/r (branch “dev”) already belongs to another project.")
    }

    func testV014_entrySnapshotRoundTripsAsSnakeCase() throws {
        let entry = BillingEntryDTO(
            id: "e9", projectId: "p1", clientId: "c1", day: "2026-09-22", groupKey: "rate:9000",
            startedAt: "2026-09-22T14:00:00Z", endedAt: "2026-09-22T15:00:00Z",
            rawSeconds: 3_000, billedSeconds: 3_600, rateCents: 9_000, currency: "EUR",
            amountCents: 9_000, roundingMinutes: 30, roundingMode: "nearest",
            status: "billed", description: "work", origin: "manual", locked: true,
            supplementsEntryId: "e1", createdAt: "a", updatedAt: "b")
        let data = try encoder().encode(entry)
        XCTAssertTrue(try XCTUnwrap(String(data: data, encoding: .utf8)).contains("\"billed_seconds\":3600"))
        XCTAssertEqual(try decoder().decode(BillingEntryDTO.self, from: data), entry)
    }
}
