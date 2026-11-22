import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// What the router reads from and writes to `AccountQuotaProbe`: readings merged
/// field by field from routed responses, the held-token test behind the fence,
/// and the secret-free list of saved item keys.
final class AccountQuotaObserveTests: XCTestCase {

    private func quota(
        five: String? = nil, fiveReset: String? = nil, fiveStatus: String? = nil,
        seven: String? = nil, sevenReset: String? = nil, sevenStatus: String? = nil
    ) -> [String: String] {
        var headers: [String: String] = [:]
        let prefix = "anthropic-ratelimit-unified-"
        headers[prefix + "5h-utilization"] = five
        headers[prefix + "5h-reset"] = fiveReset
        headers[prefix + "5h-status"] = fiveStatus
        headers[prefix + "7d-utilization"] = seven
        headers[prefix + "7d-reset"] = sevenReset
        headers[prefix + "7d-status"] = sevenStatus
        return headers
    }

    private func store(_ creds: [Sessions.ClaudeCredentialDTO] = []) -> AccountQuotaProbe {
        let store = AccountQuotaProbe(prober: { _ in [:] })
        store.setCredentials(creds)
        return store
    }

    func testObserveCreatesAReadingForAnAccountWithNone() {
        let store = store()
        store.observe(account: "a@x.com", credentialKind: "oauth",
                      headers: quota(five: "0.1", fiveReset: "1785003600", seven: "0.95"))
        let reading = store.reading(account: "a@x.com", credentialKind: "oauth")
        XCTAssertEqual(reading?.fiveHourPct ?? -1, 10, accuracy: 0.001)
        XCTAssertEqual(reading?.fiveHourResetsAt, 1_785_003_600)
        XCTAssertEqual(reading?.sevenDayPct ?? -1, 95, accuracy: 0.001)
        XCTAssertNil(reading?.errorText)
    }

    // Ported: "a partial reading updates only the fields it carries".
    func testAPartialReadingUpdatesOnlyTheFieldsItCarries() {
        let store = store()
        store.observe(account: "a@x.com", credentialKind: "oauth",
                      headers: quota(five: "0.1", fiveStatus: "allowed", seven: "0.95", sevenReset: "1785360000"))
        store.observe(account: "a@x.com", credentialKind: "oauth", headers: quota(five: "0.5"))
        let reading = store.reading(account: "a@x.com", credentialKind: "oauth")
        XCTAssertEqual(reading?.fiveHourPct ?? -1, 50, accuracy: 0.001)
        XCTAssertEqual(reading?.fiveHourStatus, "allowed", "the 5h status was not in the newer response")
        XCTAssertEqual(reading?.sevenDayPct ?? -1, 95, accuracy: 0.001)
        XCTAssertEqual(reading?.sevenDayResetsAt, 1_785_360_000)
    }

    // Ported: "a response without quota keeps the last reading".
    func testAResponseWithoutQuotaHeadersKeepsTheLastReading() {
        let store = store()
        store.observe(account: "a@x.com", credentialKind: "oauth", headers: quota(seven: "0.4"))
        store.observe(account: "a@x.com", credentialKind: "oauth", headers: ["content-type": "text/event-stream"])
        XCTAssertEqual(store.reading(account: "a@x.com", credentialKind: "oauth")?.sevenDayPct ?? -1, 40,
                       accuracy: 0.001)
        XCTAssertEqual(store.current().count, 1)
    }

    func testAStatusOnlyObservationClearsAStaleErrorText() {
        let failed = Sessions.AccountQuotaReadingDTO(
            account: "a@x.com", credentialKind: "oauth",
            fiveHourPct: nil, fiveHourResetsAt: nil, fiveHourStatus: nil,
            sevenDayPct: nil, sevenDayResetsAt: nil, sevenDayStatus: nil,
            fableLimitPct: nil, fableLimitResetsAt: nil, fableLimitStatus: nil,
            errorText: "probe failed")
        let statusOnly = Sessions.AccountQuotaReadingDTO(account: "a@x.com", credentialKind: "oauth",
                                             headers: quota(fiveStatus: "allowed"))
        XCTAssertTrue(statusOnly.carriesAnyWindow)
        let merged = failed.merging(statusOnly)
        XCTAssertEqual(merged.fiveHourStatus, "allowed")
        XCTAssertNil(merged.errorText, "a live status must not sit next to an error")
        XCTAssertEqual(
            failed.merging(Sessions.AccountQuotaReadingDTO(account: "a@x.com", credentialKind: "oauth")).errorText,
                       "probe failed", "an empty observation leaves the error alone")
    }

    func testObserveKeepsCredentialKindsApart() {
        let store = store()
        store.observe(account: "a@x.com", credentialKind: "oauth", headers: quota(five: "0.2"))
        store.observe(account: "a@x.com", credentialKind: "long-lived", headers: quota(five: "0.7"))
        XCTAssertEqual(store.reading(account: "a@x.com", credentialKind: "oauth")?.fiveHourPct ?? -1, 20,
                       accuracy: 0.001)
        XCTAssertEqual(store.reading(account: "a@x.com", credentialKind: "long-lived")?.fiveHourPct ?? -1, 70,
                       accuracy: 0.001)
    }

    // Review Focus 2 (store half).
    func testHoldsMatchesOnlyPushedTokens() {
        let store = store([
            Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "sk-ant-oat01-real",
                                itemKey: "oauth:a@x.com")
        ])
        XCTAssertTrue(store.holds(token: "sk-ant-oat01-real"))
        XCTAssertFalse(store.holds(token: "sk-ant-oat01-forged"))
        XCTAssertFalse(store.holds(token: "sk-ant-oat01-rea"), "a prefix is not the token")
        XCTAssertFalse(store.holds(token: ""))
    }

    func testSavedItemKeysFollowPushOrderAndCarryNoToken() {
        let store = store([
            Sessions.ClaudeCredentialDTO(account: "b", credentialKind: "long-lived", token: "sk-ant-oat01-b",
                                itemKey: "long-lived:b"),
            Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "sk-ant-oat01-a",
                                itemKey: "oauth:a@x.com")
        ])
        XCTAssertEqual(store.savedItemKeys(), ["long-lived:b", "oauth:a@x.com"])
    }

    func testFenceAcceptsAFingerprintedTokenTheStoreDoesNotHold() throws {
        let path = NSTemporaryDirectory() + "fence-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try AccountFingerprints.publish([AccountFingerprints.fingerprint(of: "sk-ant-oat01-live"): "a@x.com"],
                                        atPath: path)
        let fence = CredentialFence(source: store(), fingerprintsPath: path)
        XCTAssertTrue(fence.owns("sk-ant-oat01-live"))
        XCTAssertFalse(fence.owns("sk-ant-oat01-forged"))
    }

    func testFenceAcceptsAHeldToken() {
        let held = store([Sessions.ClaudeCredentialDTO(
            account: "a@x.com", credentialKind: "oauth", token: "sk-ant-oat01-h",
                                              itemKey: "oauth:a@x.com")])
        let absent = NSTemporaryDirectory() + "absent-\(UUID().uuidString).json"
        let fence = CredentialFence(source: held, fingerprintsPath: absent)
        XCTAssertTrue(fence.owns("sk-ant-oat01-h"))
    }

    func testFenceRejectsAnEmptyToken() throws {
        let path = NSTemporaryDirectory() + "fence-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try AccountFingerprints.publish([AccountFingerprints.fingerprint(of: ""): "a@x.com"], atPath: path)
        let held = store([Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "oauth", token: "",
                                              itemKey: "oauth:a@x.com")])
        XCTAssertFalse(CredentialFence(source: held, fingerprintsPath: path).owns(""))
    }

    func testAMalformedResetIsNoReadingRatherThanATrap() {
        for raw in ["inf", "-inf", "nan", "1e400", "1e300"] {
            let reading = Sessions.AccountQuotaReadingDTO(
                account: "a@x.com", headers: quota(five: "0.5", fiveReset: raw))
            XCTAssertNil(reading.fiveHourResetsAt, raw)
            XCTAssertEqual(reading.fiveHourPct, 50)
        }
        let millis = Sessions.AccountQuotaReadingDTO(account: "a@x.com", headers: quota(fiveReset: "1700000000123"))
        XCTAssertEqual(millis.fiveHourResetsAt, 1_700_000_000)
    }
}
