import Foundation

/// When the Secrets window locks itself: its words go behind the eye and
/// showing them again takes the Mac owner's authentication.
extension UserSettings {
    /// Lock when the app stops being the active app.
    public static let secretsLockWhenAppInactive = UserSetting<Bool>(
        "secrets.lock.app_inactive", default: true)

    /// Lock when the Mac sleeps, its display sleeps, its screen locks or the
    /// user switches away.
    public static let secretsLockOnSleep = UserSetting<Bool>(
        "secrets.lock.sleep", default: true)

    /// Lock after this many minutes without a key press, click or scroll
    /// anywhere in the app, whether the window is in front or not; 0 never.
    public static let secretsLockAfterIdleMinutes = UserSetting<Int>(
        "secrets.lock.idle_minutes", default: 5)

    /// The choices offered for ``secretsLockAfterIdleMinutes``.
    public static let secretsIdleMinuteChoices = [0, 1, 2, 5, 10, 15, 30, 60]
}
