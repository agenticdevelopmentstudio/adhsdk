import AppKit
import AgenticDeveloperHubSDKNotifications

/// Which screens notices present on. Takes the screens and the main screen as
/// arguments rather than reading `NSScreen`, so it is testable and a caller
/// decides when to sample them.
public enum ScreenSelector {

    @MainActor
    public static func screens(
        for selection: NoticeProfile.ScreenSelection,
        all: [NSScreen],
        main: NSScreen?
    ) -> [NSScreen] {
        guard !all.isEmpty else { return [] }
        switch selection {
        case .all:
            return all
        case .main:
            return [main ?? all[0]]
        }
    }

    /// The screens for `selection`, sampled now.
    @MainActor
    static func current(for selection: NoticeProfile.ScreenSelection) -> [NSScreen] {
        screens(for: selection, all: NSScreen.screens, main: NSScreen.main)
    }
}

extension NSScreen {
    /// A stable identity for a screen across `NSScreen.screens` refreshes.
    var noticeDisplayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
