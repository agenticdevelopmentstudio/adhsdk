import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// An in-memory `AccountRouterQuotaSource`: tokens and expiries are set
/// directly, which the real store only learns from a credential round.
final class FakeQuotaSource: AccountRouterQuotaSource, @unchecked Sendable {
    struct Observation: Equatable {
        let account: String
        let credentialKind: String?
        let headers: [String: String]
    }

    private let lock = NSLock()
    private var tokens: [(itemKey: String, held: AccountQuotaProbe.HeldToken)] = []
    private var readings: [Sessions.AccountQuotaReadingDTO] = []
    private var observations: [Observation] = []

    var observed: [Observation] {
        lock.lock(); defer { lock.unlock() }
        return observations
    }

    /// Holds `token` under `itemKey`; the kind comes from the item key's prefix.
    func hold(_ itemKey: String, token: String, expiresAt: Double? = nil) {
        let kind = ClaudeCredentialKind.parse(itemKey: itemKey)?.kind.rawValue
        lock.lock(); defer { lock.unlock() }
        tokens.removeAll { $0.itemKey == itemKey }
        tokens.append((itemKey, AccountQuotaProbe.HeldToken(token: token, expiresAt: expiresAt, credentialKind: kind)))
    }

    func drop(_ itemKey: String) {
        lock.lock(); defer { lock.unlock() }
        tokens.removeAll { $0.itemKey == itemKey }
    }

    func setReading(_ reading: Sessions.AccountQuotaReadingDTO) {
        lock.lock(); defer { lock.unlock() }
        readings.removeAll { $0.account == reading.account && $0.credentialKind == reading.credentialKind }
        readings.append(reading)
    }

    func heldToken(itemKey: String) -> AccountQuotaProbe.HeldToken? {
        lock.lock(); defer { lock.unlock() }
        return tokens.first { $0.itemKey == itemKey }?.held
    }

    func holds(token: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return tokens.contains { $0.held.token == token }
    }

    func savedItemKeys() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return tokens.map(\.itemKey)
    }

    func reading(account: String, credentialKind: String?) -> Sessions.AccountQuotaReadingDTO? {
        lock.lock(); defer { lock.unlock() }
        return readings.first { $0.account == account && $0.credentialKind == credentialKind }
    }

    func observe(account: String, credentialKind: String?, headers: [String: String]) {
        lock.lock(); defer { lock.unlock() }
        observations.append(Observation(account: account, credentialKind: credentialKind, headers: headers))
    }
}

/// A settable clock for the pool's cool-downs and expiry margin.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Double

    init(_ start: Double) { current = start }

    var now: Double {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(_ seconds: Double) {
        lock.lock(); defer { lock.unlock() }
        current += seconds
    }
}
