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

    /// Whether a file browser pane keeps its width at its widest visible row
    /// plus a margin, re-measured whenever the rows change. Off by default, so
    /// the pane keeps whatever width it was given until this is turned on.
    public static var fileBrowserAdjustsWidthToContent = UserSetting<Bool>(
        "file_browser.adjusts_width_to_content",
        default: false
    )
}
