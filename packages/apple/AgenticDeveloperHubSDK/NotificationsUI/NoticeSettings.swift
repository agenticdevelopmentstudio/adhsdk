import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications

/// Where the notification styles are stored: the routing rules as one
/// setting, which the settings panel edits and a host reads into its
/// presentation center.
@MainActor
public enum NoticeSettings {

    /// Every profile, override and global switch, JSON-encoded under one key.
    public static let routingRules = UserSetting<NoticeRoutingRules>(
        "notice_routing_rules", default: .defaults)

    /// How far the user dragged each toast stack from its position's anchor,
    /// keyed by `NoticeProfile.Position.rawValue`; it applies on every screen.
    public static let toastStackOffsets = UserSetting<[String: NoticeStackOffset]>(
        "notice_toast_stack_offsets", default: [:])

    /// Set once the legacy migration has run, so it never runs twice.
    static let migratedMarkerKey = "notice_routing_migrated_v1"

    /// Carries a host's retired "deliver notifications" boolean into the
    /// rules, once: a stored `true` adds a system item to `fyi`'s set. The
    /// legacy key is removed either way, and a marker keeps a stale value that
    /// reappears later from undoing the user's choice.
    public static func migrateLegacyDeliverSetting(
        defaults: UserDefaults,
        legacyKey: String,
        store: SettingsStore = UserSettings.shared
    ) {
        guard !defaults.bool(forKey: migratedMarkerKey) else { return }
        let legacy = defaults.object(forKey: legacyKey) as? Bool
        if legacy == true {
            let current = store.get(routingRules)
            store.set(NoticeRoutingRules.migratingLegacyDeliverSetting(legacy, into: current), for: routingRules)
        }
        defaults.removeObject(forKey: legacyKey)
        defaults.set(true, forKey: migratedMarkerKey)
    }
}
