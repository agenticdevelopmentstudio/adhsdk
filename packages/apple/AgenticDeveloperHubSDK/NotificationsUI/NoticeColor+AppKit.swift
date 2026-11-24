import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKNotifications

extension NoticeColor {

    /// The color this choice means for one use. The model records only which
    /// color was picked; each use names what System and Theme mean for it.
    ///
    /// - Parameters:
    ///   - system: what System resolves to here (black for the full-screen
    ///     dim, the window background for the crawl).
    ///   - themeRole: the palette role Theme resolves to here.
    ///   - palette: the live theme's palette.
    /// - Returns: an opaque color for Custom; opacity is the caller's.
    func resolved(system: NSColor, themeRole: ThemeRole, palette: SemanticPalette) -> NSColor {
        switch source {
        case .system: system
        case .theme: palette.nsColor(themeRole)
        case .custom: NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
        }
    }
}
