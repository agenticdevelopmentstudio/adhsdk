// `db` is the one name for the shared DaemonDatabase, as in the rest of the tier.
// swiftlint:disable identifier_name
#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The live per-account quota readings the Usage rows show, and the two ways to
/// ask for fresh ones. The daemon that probes accounts (it holds the credentials
/// and the schedule) conforms its quota store and hands it to
/// ``DaemonDatabase/accountQuotaSource``; with none set, Usage shows no account
/// sections.
public protocol AccountQuotaSource: AnyObject, Sendable {
    /// The readings held now, without probing.
    func current() -> [Sessions.AccountQuotaReadingDTO]
    /// Starts a probe round in the background if the held readings are stale.
    func refreshIfStale()
    /// Probes every account now and calls back once the round is done, true
    /// when anything was measured.
    func remeasure(completion: @escaping @Sendable (Bool) -> Void)
}

/// The state the session feature extensions keep per database. An extension
/// cannot hold a stored property, so the Usage caches live here, reached
/// through ``DaemonDatabase/attachment(_:make:)``.
///
/// `@unchecked Sendable`: the Usage cache fields are guarded by `usageCacheLock`
/// and the Fable share cache by `fableShareCacheLock`; the rest are themselves
/// thread-safe or set once before any request is served.
final class SessionFeatureState: @unchecked Sendable {

    /// `computeUsageRows` walks 100k+ `transcript_turns` rows and runs on the
    /// serial DB queue; under ingest/import contention a live call blows past
    /// the status line's 2s HTTP timeout and the whole Usage section vanishes.
    /// So cache the last result behind this plain lock (NOT the DB queue) and
    /// serve it stale-while-revalidate — see `statusLineUsageRows`.
    let usageCacheLock = NSLock()
    var cachedUsageRows: Sessions.UsageRowsDTO?
    var cachedUsageRowsAt: Date?
    var usageRefreshInFlight = false

    /// The slow-moving activity-hours rows, held longer than the rest — see
    /// `HoursRowsCache`.
    let hoursRowsCache = HoursRowsCache()
    /// The week-comparison rows' past-week totals — see `WeekScopedMemo`.
    let weekBaselinesCache = WeekScopedMemo<WeekBaselines>()

    /// The last Fable cost share read per (account, credential, window start),
    /// for `cachedFableCostShare`. Its own lock for the same reason as
    /// `usageCacheLock`: a hot-path read must never queue behind the DB lane.
    let fableShareCacheLock = NSLock()
    var fableShareCache: [String: (share: Double?, at: Date)] = [:]

    /// See ``DaemonDatabase/accountQuotaSource``.
    var accountQuotaSource: (any AccountQuotaSource)?

    /// See ``DaemonDatabase/billingSettingsKeyPrefix``.
    var billingSettingsKeyPrefix = DaemonDatabase.defaultBillingSettingsKeyPrefix
}

extension DaemonDatabase {

    /// Status-line renders arrive every few seconds across many sessions; 15s of
    /// staleness is invisible there but collapses the recompute load enormously.
    static let usageCacheTTL: TimeInterval = 15

    /// The share moves only as fast as turns land, and every Usage recompute
    /// asks for it once per account section plus once for the top row — each a
    /// walk of the account's week of turns that its case-insensitive account
    /// match keeps off the account index (0.1 s warm, 1.4 s cold, per account).
    /// It is a fraction of a whole week, so five minutes of staleness moves no
    /// digit a reader acts on — the same horizon as `WeekScopedMemo`.
    static let fableShareCacheTTL: TimeInterval = 300

    /// The database itself. Code moved here from a wrapper class spells its
    /// calls `db.query(...)`; this keeps those lines as they were.
    var db: DaemonDatabase { self }

    var featureState: SessionFeatureState {
        attachment(SessionFeatureState.self) { SessionFeatureState() }
    }

    var usageCacheLock: NSLock { featureState.usageCacheLock }
    var cachedUsageRows: Sessions.UsageRowsDTO? {
        get { featureState.cachedUsageRows }
        set { featureState.cachedUsageRows = newValue }
    }
    var cachedUsageRowsAt: Date? {
        get { featureState.cachedUsageRowsAt }
        set { featureState.cachedUsageRowsAt = newValue }
    }
    var usageRefreshInFlight: Bool {
        get { featureState.usageRefreshInFlight }
        set { featureState.usageRefreshInFlight = newValue }
    }
    var hoursRowsCache: HoursRowsCache { featureState.hoursRowsCache }
    var weekBaselinesCache: WeekScopedMemo<WeekBaselines> { featureState.weekBaselinesCache }
    var fableShareCacheLock: NSLock { featureState.fableShareCacheLock }
    var fableShareCache: [String: (share: Double?, at: Date)] {
        get { featureState.fableShareCache }
        set { featureState.fableShareCache = newValue }
    }

    /// The live per-account quota readings the Usage rows' account sections show,
    /// nudged by `statusLineUsageRows` so probes happen only while someone is
    /// rendering. Set once by the daemon at startup, before any request is
    /// served; nil (no account sections) in a daemon that does not probe.
    public var accountQuotaSource: (any AccountQuotaSource)? {
        get { featureState.accountQuotaSource }
        set { featureState.accountQuotaSource = newValue }
    }

    /// The billing settings' key prefix when a daemon names none.
    public static let defaultBillingSettingsKeyPrefix = "billing_"

    /// Prepended to every billing settings key (``BillingSettingsKeys``). A
    /// daemon whose existing database already holds billing settings under its
    /// own prefix sets it once at startup, before any request is served, so
    /// those settings keep reading back.
    public var billingSettingsKeyPrefix: String {
        get { featureState.billingSettingsKeyPrefix }
        set { featureState.billingSettingsKeyPrefix = newValue }
    }
}
#endif
// swiftlint:enable identifier_name
