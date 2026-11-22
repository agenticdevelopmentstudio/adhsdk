#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// How many days of event history the session daemon keeps: the `event_history_days`
/// setting, which replaces the opt-in `retention_enabled` / `retention_days`
/// pair (neither is read anywhere else any more).
///
/// The value is always one of `StorageHistoryWindow.allowedDays` (toolkit Core,
/// shared with the app). Anything else stored there snaps to the nearest
/// allowed value at or above it, capped at 365; a value that is not an integer
/// reads as the default, 30.
enum StorageSettings {
    /// The settings-table key.
    static let key = "event_history_days"

    /// The allowed value `raw` means: `StorageHistoryWindow.snap` of the
    /// integer, `StorageHistoryWindow.defaultDays` for a non-integer.
    static func snap(_ raw: String?) -> Int {
        guard let raw, let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return StorageHistoryWindow.defaultDays
        }
        return StorageHistoryWindow.snap(value)
    }

    /// The days of history to keep, read fresh (callers read it on every run),
    /// for display: a read error shows the default.
    static func historyDays(_ database: DaemonDatabase) -> Int {
        (try? readHistoryDays(database)) ?? StorageHistoryWindow.defaultDays
    }

    /// The days of history to keep, for the trim: a missing row or a
    /// non-integer means the default, but a read that fails throws, so a pass
    /// never trims to the default window when the user chose a longer one.
    static func readHistoryDays(_ database: DaemonDatabase) throws -> Int {
        snap(try database.setting(for: key))
    }

    /// Stores `days`, snapped to an allowed value, and returns what it stored.
    /// The next trim pass reads it; this does not start one.
    @discardableResult
    static func setHistoryDays(_ days: Int, _ database: DaemonDatabase) throws -> Int {
        let snapped = StorageHistoryWindow.snap(days)
        try database.setSetting(key, String(snapped))
        return snapped
    }

    /// The value seeded on first start: the old opt-in window, snapped, when
    /// retention was on with a valid `retention_days`; otherwise the default.
    static func seedValue(_ database: DaemonDatabase) -> Int {
        let enabled = RawSetting.bool((try? database.setting(for: "retention_enabled")) ?? nil, default: false)
        let oldDays = ((try? database.setting(for: "retention_days")) ?? nil)
            .flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard enabled, let oldDays else { return StorageHistoryWindow.defaultDays }
        return StorageHistoryWindow.snap(oldDays)
    }

    /// Post-migration step: seeds `event_history_days` once. It writes only
    /// when the key is absent, so the seed's result is recorded in the setting
    /// itself and a later change of the old keys never moves it.
    static let ensureEventHistoryDays: @Sendable (DaemonDatabase) throws -> Void = { database in
        guard try database.setting(for: key) == nil else { return }
        try database.setSetting(key, String(seedValue(database)))
    }
}
#endif
