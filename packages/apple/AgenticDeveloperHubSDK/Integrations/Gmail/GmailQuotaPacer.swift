import Foundation

/// Keeps Gmail calls under Google's per-user quota: 15,000 units a minute, which Google
/// enforces as a moving average of about 250 units a second. Each call reserves its quota
/// cost before it is sent; once `burstUnits` have gone out back to back, calls are spaced so
/// no more than `unitsPerSecond` go out on average.
///
/// The arithmetic is the generic cell rate algorithm: `drainedAt` is when every unit reserved
/// so far would have drained at `unitsPerSecond`, and a call waits only for the part of that
/// which lies beyond the burst allowance.
///
/// `shared` paces every account in the process together. Each account has its own 250-unit
/// allowance, so sharing only slows down syncing several accounts at once; it never lets one
/// account exceed its quota.
public actor GmailQuotaPacer {
    /// Below Google's 250 units a second, leaving room for clock drift and other clients.
    public static let shared = GmailQuotaPacer(unitsPerSecond: 200, burstUnits: 200)

    private let unitsPerSecond: Double
    private let burstUnits: Double
    private let now: @Sendable () -> ContinuousClock.Instant
    private var drainedAt: ContinuousClock.Instant?

    /// - Parameter now: the clock; injected so tests control time.
    public init(unitsPerSecond: Double, burstUnits: Double,
                now: @escaping @Sendable () -> ContinuousClock.Instant = { ContinuousClock.now }) {
        precondition(unitsPerSecond > 0 && burstUnits >= 0, "the pacer needs a positive rate")
        self.unitsPerSecond = unitsPerSecond
        self.burstUnits = burstUnits
        self.now = now
    }

    /// Reserves `units` of quota and returns how long the caller must wait before sending.
    public func reserve(_ units: Int) -> Duration {
        let current = now()
        let start = max(drainedAt ?? current, current)
        let drained = start + Self.duration(Double(units) / unitsPerSecond)
        drainedAt = drained
        let wait = drained - current - Self.duration(burstUnits / unitsPerSecond)
        return max(wait, .zero)
    }

    private static func duration(_ seconds: Double) -> Duration {
        .nanoseconds(Int64((seconds * 1_000_000_000).rounded()))
    }
}

/// What each Gmail call costs against the per-user quota, from Google's published table
/// (developers.google.com/workspace/gmail/api/reference/quota).
enum GmailQuotaCost {
    static let profile = 1
    static let labelsList = 1
    static let historyList = 2
    static let messagesList = 5
    static let messagesGet = 5
    static let messagesBatchModify = 50
}
