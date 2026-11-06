import Foundation

/// What every file browser in the app leaves out.
extension UserSettings {

    /// `.gitignore`-style patterns, one per entry, matched against paths
    /// relative to each browser root — see `GitIgnoreMatcher` for the syntax.
    /// Empty by default, so the setting changes nobody's tree until it is used.
    public static var fileBrowserExcludedPatterns = UserSetting<[String]>(
        "file_browser.excluded_patterns",
        default: []
    )
}
