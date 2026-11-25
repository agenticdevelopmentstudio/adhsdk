import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKCore

/// The billing settings holder against its conformance vectors: the shared
/// defaults, and the keys it stores under. Each test runs against a
/// `UserSettings.shared` backed by memory, so nothing touches a real defaults
/// domain, and puts the process-wide one back afterwards.
@MainActor
final class BillingUserSettingsConformanceTests: XCTestCase {

    private var previousStore: UserSettings!
    private var provider: InMemorySettingsStorageProvider!

    override func setUp() async throws {
        await ExclusiveAccess.Resource.userSettings.acquire()
        previousStore = UserSettings.shared
        provider = InMemorySettingsStorageProvider()
        UserSettings.shared = UserSettings(with: provider)
    }

    override func tearDown() async throws {
        UserSettings.shared = previousStore
        previousStore = nil
        provider = nil
        await ExclusiveAccess.Resource.userSettings.release()
    }

    private func makeHolder(prefix: String = "conformance_billing_") -> BillingUserSettings {
        BillingUserSettings(keys: BillingSettingsKeys(prefix: prefix))
    }

    /// What the settings table holds under `key`, nil when nothing was written.
    private func stored(_ key: String) -> String? {
        let probe = UserSetting<String>(key, default: "<unset>")
        return provider.contains(probe) ? provider.get(probe) : nil
    }

    func testV1_idleCutoffDefaultsTo15() {
        XCTAssertEqual(makeHolder().idleCutoffMinutes.value, 15)
    }

    func testV2_granularityDefaultsToDay() {
        XCTAssertEqual(makeHolder().granularity.value, "day")
    }

    func testV3_roundingDefaultsTo15MinutesUp() {
        let holder = makeHolder()
        XCTAssertEqual(holder.roundingMinutes.value, 15)
        XCTAssertEqual(holder.roundingMode.value, "up")
    }

    func testV4_rateDefaultsToZeroCentsAndCurrencyToUSD() {
        let holder = makeHolder()
        XCTAssertEqual(holder.defaultRateCents.value, 0)
        XCTAssertEqual(holder.currency.value, "USD")
    }

    func testV5_manualCapDefaultsTo8HoursAndUnassignedIsTracked() {
        let holder = makeHolder()
        XCTAssertEqual(holder.manualTimerCapHours.value, 8)
        XCTAssertTrue(holder.trackUnassigned.value)
    }

    func testV6_aWriteLandsUnderTheKeySetsKey() {
        let holder = makeHolder(prefix: "x")
        XCTAssertNil(stored(holder.keys.currency))
        holder.currency.value = "EUR"
        XCTAssertEqual(holder.keys.currency, "xcurrency")
        XCTAssertEqual(stored(holder.keys.currency), "EUR")
    }

    func testV7_twoKeySetsDoNotShareValues() {
        let first = makeHolder(prefix: "first_")
        let second = makeHolder(prefix: "second_")
        first.currency.value = "EUR"
        first.idleCutoffMinutes.value = 30
        XCTAssertEqual(second.currency.value, "USD")
        XCTAssertEqual(second.idleCutoffMinutes.value, 15)
        XCTAssertNil(stored(second.keys.currency))
        XCTAssertEqual(first.currency.value, "EUR")
    }

    func testV8_usedOffTheUIThreadIsRejected() throws {
        throw XCTSkip(
            "The holder is @MainActor, so a use from another thread is rejected by the compiler (Swift 6 "
                + "isolation); a compile-time rejection cannot be exercised from a running test.")
    }
}
