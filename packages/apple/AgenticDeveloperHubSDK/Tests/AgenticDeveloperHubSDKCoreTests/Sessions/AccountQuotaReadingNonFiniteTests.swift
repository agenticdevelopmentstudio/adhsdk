@testable import AgenticDeveloperHubSDKCore
import XCTest

/// `reading-pct-non-finite`: a utilization that is NaN, infinite or overflows
/// when scaled to a percentage is no reading. The percentage is nil, it does
/// not count toward a reading, and the DTO always encodes.
final class AccountQuotaReadingNonFiniteTests: XCTestCase {

    private func headers(fiveHour: String, sevenDay: String? = nil, fable: String? = nil) -> [String: String] {
        var headers = ["anthropic-ratelimit-unified-5h-utilization": fiveHour]
        if let sevenDay { headers["anthropic-ratelimit-unified-7d-utilization"] = sevenDay }
        if let fable { headers["anthropic-ratelimit-unified-7d_oi-utilization"] = fable }
        return headers
    }

    func testNonFiniteUtilizationsYieldNilPercentages() {
        for raw in ["nan", "NaN", "inf", "-inf", "infinity", "1e308"] {
            let reading = Sessions.AccountQuotaReadingDTO(
                account: "a", headers: headers(fiveHour: raw, sevenDay: raw, fable: raw))
            XCTAssertNil(reading.fiveHourPct, raw)
            XCTAssertNil(reading.sevenDayPct, raw)
            XCTAssertNil(reading.fableLimitPct, raw)
            XCTAssertEqual(reading.errorText, "no usage readings in response", "\(raw) is not a reading")
        }
    }

    func testOneFiniteWindowStillCountsAsAReading() {
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: headers(fiveHour: "nan", sevenDay: "0.27"))
        XCTAssertNil(reading.fiveHourPct)
        XCTAssertEqual(reading.sevenDayPct ?? 0, 27, accuracy: 1e-9)
        XCTAssertNil(reading.errorText)
    }

    func testMemberwiseInitDropsNonFinitePercentages() {
        let reading = Sessions.AccountQuotaReadingDTO(
            account: "a", fiveHourPct: .nan, sevenDayPct: .infinity, fableLimitPct: -.infinity)
        XCTAssertNil(reading.fiveHourPct)
        XCTAssertNil(reading.sevenDayPct)
        XCTAssertNil(reading.fableLimitPct)
    }

    func testAReadingFromNonFiniteHeadersEncodesWithTheWireCoder() throws {
        let reading = Sessions.AccountQuotaReadingDTO(account: "a", headers: headers(fiveHour: "inf", sevenDay: "nan"))
        let data = try StenographerWire.encoder().encode(reading)
        let text = try XCTUnwrap(String(bytes: data, encoding: .utf8))
        XCTAssertFalse(text.lowercased().contains("nan"))
        XCTAssertFalse(text.lowercased().contains("inf"))
    }
}
