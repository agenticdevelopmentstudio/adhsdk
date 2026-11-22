#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The router's settings rows. Read on every request, so a CLI
/// `enable`/`disable` takes effect on the next request with no reload signal.
public struct AccountRouterSettings: Equatable, Sendable {
    public static let enabledKey = "account_router_enabled"
    public static let accountsKey = "account_router_accounts"
    public static let ceilingKey = "account_router_five_hour_ceiling"
    public static let cooldownKey = "account_router_cooldown_seconds"
    public static let expiryMarginKey = "account_router_expiry_margin_seconds"
    public static let retryKey = "account_router_retry"
    public static let stickyKey = "account_router_sticky"
    public static let retentionDaysKey = "account_router_retention_days"
    public static let defaultCeiling = 0.95

    public static let cooldownRange = 1...3600
    public static let expiryMarginRange = 0...3600
    /// 0 keeps routing history forever.
    public static let retentionDaysRange = 0...3650

    public var enabled = false
    public var accounts: [String] = []
    public var fiveHourCeiling = AccountRouterSettings.defaultCeiling
    /// How long an entry sits out after a 401, a 429, or being found unusable.
    public var cooldownSeconds = Sessions.AccountRouterStatusDTO.defaultCooldownSeconds
    /// A token this close to its expiry is not handed out.
    public var expiryMarginSeconds = Sessions.AccountRouterStatusDTO.defaultExpiryMarginSeconds
    /// A routed 401/429 is retried once on another entry before anything is relayed.
    public var retry = true
    /// A session stays on its entry while that entry is eligible.
    public var sticky = true
    /// Days of routing history kept; 0 is forever.
    public var retentionDays = Sessions.AccountRouterStatusDTO.defaultRetentionDays

    public init() {}

    /// The three rows a caller usually sets; the tuning rows keep their defaults.
    public init(enabled: Bool, accounts: [String], fiveHourCeiling: Double = AccountRouterSettings.defaultCeiling) {
        self.enabled = enabled
        self.accounts = accounts
        self.fiveHourCeiling = fiveHourCeiling
    }

    public static func isValidCeiling(_ value: Double) -> Bool {
        value.isFinite && value > 0 && value <= 1
    }

    /// Never throws. An unreadable row, or a database still migrating, is the
    /// default, and the default is off: fail-open.
    public static func load(_ database: DaemonDatabase) -> AccountRouterSettings {
        var settings = AccountRouterSettings()
        guard database.isReady else { return settings }
        settings.enabled = row(enabledKey, database) == "1"
        if let raw = row(accountsKey, database),
           let keys = try? JSONDecoder().decode([String].self, from: Data(raw.utf8)) {
            settings.accounts = keys
        }
        if let raw = row(ceilingKey, database), let value = Double(raw), isValidCeiling(value) {
            settings.fiveHourCeiling = value
        }
        settings.cooldownSeconds = integer(cooldownKey, in: cooldownRange, database) ?? settings.cooldownSeconds
        settings.expiryMarginSeconds = integer(expiryMarginKey, in: expiryMarginRange, database)
            ?? settings.expiryMarginSeconds
        settings.retentionDays = integer(retentionDaysKey, in: retentionDaysRange, database) ?? settings.retentionDays
        settings.retry = row(retryKey, database) != "0"
        settings.sticky = row(stickyKey, database) != "0"
        return settings
    }

    private static func row(_ key: String, _ database: DaemonDatabase) -> String? {
        (try? database.setting(for: key)) ?? nil
    }

    /// The row as an Int inside `range`, or nil (garbage, empty, out of range).
    private static func integer(_ key: String, in range: ClosedRange<Int>, _ database: DaemonDatabase) -> Int? {
        guard let raw = row(key, database), let value = Int(raw), range.contains(value) else { return nil }
        return value
    }
}
#endif
