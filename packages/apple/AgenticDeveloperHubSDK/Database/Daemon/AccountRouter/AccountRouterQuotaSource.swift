#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Everything the account router needs from the daemon's credential holder
/// (its ``AccountQuotaProbe``), as a protocol so the pool's tests can hand in
/// expiries the probe only learns from a credential round.
public protocol AccountRouterQuotaSource: AnyObject, Sendable {
    func heldToken(itemKey: String) -> AccountQuotaProbe.HeldToken?
    func holds(token: String) -> Bool
    func savedItemKeys() -> [String]
    func reading(account: String, credentialKind: String?) -> Sessions.AccountQuotaReadingDTO?
    func observe(account: String, credentialKind: String?, headers: [String: String])
}

extension AccountQuotaProbe: AccountRouterQuotaSource {}

extension Sessions.AccountQuotaReadingDTO {
    /// The response carried at least one window field.
    var carriesAnyWindow: Bool {
        let numbers: [Double?] = [fiveHourPct, sevenDayPct, fableLimitPct]
        let resets: [Int?] = [fiveHourResetsAt, sevenDayResetsAt, fableLimitResetsAt]
        let statuses: [String?] = [fiveHourStatus, sevenDayStatus, fableLimitStatus]
        return numbers.contains { $0 != nil } || resets.contains { $0 != nil } || statuses.contains { $0 != nil }
    }

    /// `newer`'s fields where it has them, this reading's elsewhere. Any window
    /// in `newer` is a live answer, so it clears a stale `errorText`.
    func merging(_ newer: Sessions.AccountQuotaReadingDTO) -> Sessions.AccountQuotaReadingDTO {
        return Sessions.AccountQuotaReadingDTO(
            account: account,
            credentialKind: credentialKind,
            fiveHourPct: newer.fiveHourPct ?? fiveHourPct,
            fiveHourResetsAt: newer.fiveHourResetsAt ?? fiveHourResetsAt,
            fiveHourStatus: newer.fiveHourStatus ?? fiveHourStatus,
            sevenDayPct: newer.sevenDayPct ?? sevenDayPct,
            sevenDayResetsAt: newer.sevenDayResetsAt ?? sevenDayResetsAt,
            sevenDayStatus: newer.sevenDayStatus ?? sevenDayStatus,
            fableLimitPct: newer.fableLimitPct ?? fableLimitPct,
            fableLimitResetsAt: newer.fableLimitResetsAt ?? fableLimitResetsAt,
            fableLimitStatus: newer.fableLimitStatus ?? fableLimitStatus,
            errorText: newer.carriesAnyWindow ? nil : errorText)
    }
}

/// "The bearer token is one of yours": the daemon holds it, or its SHA-256 is
/// in the account-fingerprints file. A yes/no answer only. The fingerprint
/// file names an account, not a saved item, so the fence never chooses an
/// account; the pool does.
struct CredentialFence: Sendable {
    let source: any AccountRouterQuotaSource
    let fingerprintsPath: String

    func owns(_ token: String) -> Bool {
        guard !token.isEmpty else { return false }
        if source.holds(token: token) { return true }
        return !AccountFingerprints.accountName(forToken: token, atPath: fingerprintsPath).isEmpty
    }
}
#endif
