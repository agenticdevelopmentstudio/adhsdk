#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The account router's preference writes, beside the shared
/// `PreferencesService`. A daemon gets one from
/// ``AccountRouterServer/preferences``, so a write lands in the template
/// directory the router reads, and calls ``AccountRouterServer/settingsChanged()``
/// after it.
public struct AccountRouterPreferences {
    private let database: DaemonDatabase
    /// Where model router template copies live; tests pass a temporary directory.
    private let templateStore: ModelRouterTemplateStore

    init(database: DaemonDatabase, templateStore: ModelRouterTemplateStore) {
        self.database = database
        self.templateStore = templateStore
    }

    /// Writes the account router's settings rows: only the fields present, and
    /// only once every one of them has been validated, so a refusal changes
    /// nothing. Read on the router's next request; no reload signal.
    ///
    /// A pool entry must be a `<kind>:<name>` item key. A legacy bare-name key
    /// is refused because the router could not tell which bucket it bills.
    /// Duplicates are dropped, keeping the first, because order is the tie-break.
    /// A refused key is echoed scrubbed, in case a token was pasted in its place.
    public func setAccountRouter(_ request: Sessions.AccountRouterPreferencesRequestDTO) throws {
        if let ceiling = request.fiveHourCeiling, !AccountRouterSettings.isValidCeiling(ceiling) {
            throw AccountRouterPreferenceError(
                errorDescription: "The 5-hour ceiling must be above 0 and at most 1 (got \(ceiling)).")
        }
        if let cooldown = request.cooldownSeconds, !AccountRouterSettings.cooldownRange.contains(cooldown) {
            throw AccountRouterPreferenceError(
                errorDescription: "The cool-down must be a whole number of seconds from 1 to 3600 (got \(cooldown)).")
        }
        if let margin = request.expiryMarginSeconds, !AccountRouterSettings.expiryMarginRange.contains(margin) {
            throw AccountRouterPreferenceError(errorDescription:
                "The token expiry margin must be a whole number of seconds from 0 to 3600 (got \(margin)).")
        }
        if let days = request.retentionDays, !AccountRouterSettings.retentionDaysRange.contains(days) {
            throw AccountRouterPreferenceError(
                errorDescription: "Routing history must be kept 0 to 3650 days (got \(days)); 0 keeps it forever.")
        }
        var accountsJSON: String?
        if let accounts = request.accounts {
            var seen = Set<String>()
            var pool: [String] = []
            for key in accounts where seen.insert(key).inserted {
                guard Sessions.AccountRouterItemKey.isRoutable(key) else {
                    throw AccountRouterPreferenceError(
                        errorDescription: "\"\(AccountRouterLog.scrub(key))\" is not a saved credential's item key "
                            + "(expected oauth:<email> or long-lived:<name>).")
                }
                pool.append(key)
            }
            accountsJSON = String(bytes: try JSONEncoder().encode(pool), encoding: .utf8) ?? "[]"
        }
        // One writer at a time from plan to commit, so two requests can't race
        // between validating and writing the template files.
        ModelRouterTemplateStore.writeLock.lock()
        defer { ModelRouterTemplateStore.writeLock.unlock() }
        var enabledRow: String?
        var templatePlan: ModelRouterTemplateStore.Plan?
        if let models = request.models {
            enabledRow = Self.enabledRow(models)
            if ModelRouterTemplateStore.hasTemplateFields(models) {
                templatePlan = try templateStore.plan(models)
            }
        }
        typealias Row = ModelRouterTemplateStore.Row
        var rows: [Row] = []
        if let enabled = enabledRow { rows.append(Row(key: ModelRouterSettings.enabledKey, value: enabled)) }
        if let enabled = request.enabled {
            rows.append(Row(key: AccountRouterSettings.enabledKey, value: enabled ? "1" : "0"))
        }
        if let accountsJSON { rows.append(Row(key: AccountRouterSettings.accountsKey, value: accountsJSON)) }
        if let ceiling = request.fiveHourCeiling {
            rows.append(Row(key: AccountRouterSettings.ceilingKey, value: String(ceiling)))
        }
        if let cooldown = request.cooldownSeconds {
            rows.append(Row(key: AccountRouterSettings.cooldownKey, value: String(cooldown)))
        }
        if let margin = request.expiryMarginSeconds {
            rows.append(Row(key: AccountRouterSettings.expiryMarginKey, value: String(margin)))
        }
        if let retry = request.retry { rows.append(Row(key: AccountRouterSettings.retryKey, value: retry ? "1" : "0")) }
        if let sticky = request.sticky {
            rows.append(Row(key: AccountRouterSettings.stickyKey, value: sticky ? "1" : "0"))
        }
        if let days = request.retentionDays {
            rows.append(Row(key: AccountRouterSettings.retentionDaysKey, value: String(days)))
        }
        // Rows (with the template plan's preferred row) in one transaction,
        // then the template files; a failed file step restores the rows.
        try templateStore.commit(templatePlan, rows: rows)
    }

    /// The model-router on/off row a write sets, or nil when it leaves it alone.
    private static func enabledRow(_ models: Sessions.ModelRouterPreferencesDTO) -> String? {
        models.enabled.map { $0 ? "1" : "0" }
    }
}

/// A refused account-router preference write. Its sentence reaches the client's
/// alert and the CLI verbatim, as the error's `localizedDescription`.
public struct AccountRouterPreferenceError: LocalizedError, Equatable {
    public let errorDescription: String?
}
#endif
