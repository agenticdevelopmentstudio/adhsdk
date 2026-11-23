import Foundation

/// The settings every app in the suite shares, kept by adhd rather than in
/// each app's own defaults domain.
///
/// A key is shared when its name is one of `names` or starts with one of
/// `prefixes`. `all` is the suite's set: the theme, the terminal's look and
/// the AI provider registry. A secret AI field is never routed here, whatever
/// its name: `SettingsStore` sends a secure key to the secure provider (the
/// Keychain), so only the non-secret `aiplugin.config.<uuid>.*` fields reach
/// a `RoutedSettingsStorageProvider`.
public struct SharedSettingKeys: Sendable, Equatable {

    // MARK: - The key names, one spelling each

    /// The active theme's id (`UserSettings.activeThemeID`).
    public static let activeThemeID = "theme.active_theme_id"
    /// The user's own themes (`UserSettings.customThemes`).
    public static let customThemes = "theme.custom_themes"

    /// The terminal's PostScript font name.
    public static let terminalFontName = "terminal_font_name"
    /// The terminal's font size, in points.
    public static let terminalFontSize = "terminal_font_size"
    /// The terminal caret's shape.
    public static let terminalCursorShape = "terminal_cursor_shape"
    /// Whether the terminal caret blinks.
    public static let terminalCursorBlinks = "terminal_cursor_blinks"

    /// The AI provider registry: every configuration, in order.
    public static let aiProviderConfigurations = "aiplugin.configurations"
    /// The prefix of one AI configuration's own values
    /// (`aiplugin.config.<uuid>.field.<key>`, `aiplugin.config.<uuid>.model`).
    public static let aiProviderConfigPrefix = "aiplugin.config."

    /// The suite's shared set.
    public static let all = SharedSettingKeys(
        names: [
            activeThemeID, customThemes,
            terminalFontName, terminalFontSize, terminalCursorShape, terminalCursorBlinks,
            aiProviderConfigurations
        ],
        prefixes: [aiProviderConfigPrefix]
    )

    // MARK: - A set

    /// Exact key names.
    public let names: Set<String>
    /// Name prefixes: a key starting with one is in the set.
    public let prefixes: [String]

    public init(names: Set<String>, prefixes: [String] = []) {
        self.names = names
        self.prefixes = prefixes
    }

    /// Whether `key` is one of these settings.
    public func contains(_ key: String) -> Bool {
        names.contains(key) || prefixes.contains { key.hasPrefix($0) }
    }
}
