import AppKit
import AgenticDeveloperHubSDKNotifications

/// Which screens a profile presents on. Takes the screens, the main screen and
/// the pointer as arguments rather than reading `NSScreen`, so it is testable
/// and a caller decides when to sample them.
public enum ScreenSelector {

    @MainActor
    public static func screens(
        for selection: NoticeProfile.ScreenSelection,
        all: [NSScreen],
        main: NSScreen?,
        mouse: CGPoint
    ) -> [NSScreen] {
        guard !all.isEmpty else { return [] }
        let fallback = main ?? all[0]
        switch selection {
        case .all:
            return all
        case .main:
            return [fallback]
        case .cursor:
            // `contains` excludes the max edges, so a pointer pinned to the
            // right or top edge of a screen still has to count as on it.
            let hit = all.first { NSMouseInRect(mouse, $0.frame, false) }
            return [hit ?? fallback]
        }
    }

    /// The screens for `selection`, sampled now.
    @MainActor
    static func current(for selection: NoticeProfile.ScreenSelection) -> [NSScreen] {
        screens(for: selection, all: NSScreen.screens, main: NSScreen.main, mouse: NSEvent.mouseLocation)
    }
}

extension NSScreen {
    /// A stable identity for a screen across `NSScreen.screens` refreshes.
    var noticeDisplayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
