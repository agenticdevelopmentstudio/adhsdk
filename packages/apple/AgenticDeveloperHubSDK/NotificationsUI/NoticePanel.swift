import AppKit
import AgenticDeveloperHubSDKNotifications

/// The window every notice presentation lives in.
///
/// A floating notice must never take keyboard focus: a toast that appears
/// while the user is typing would otherwise swallow their keystrokes, and a
/// Return meant for another app could press its button. So the panel is
/// non-activating and cannot become key, with exactly two exceptions:
/// - `takesFocus` (full screen), because it covers the user's work and
///   keystrokes must not keep going to a hidden app;
/// - `allowKeyForReply`, set only once the user clicks into a reply field.
///   A non-activating panel can be key without activating its app, which is
///   how Spotlight takes typing without stealing the frontmost app.
public final class NoticePanel: NSPanel {

    public let takesFocus: Bool

    /// Set by a card's reply field when the user clicks into it; cleared when
    /// the reply is sent or cancelled.
    public var allowKeyForReply = false

    public init(layer: NoticeProfile.Layer, hideFromSharing: Bool, takesFocus: Bool = false) {
        self.takesFocus = takesFocus
        var style: NSWindow.StyleMask = [.borderless]
        if !takesFocus {
            style.insert(.nonactivatingPanel)
        }
        super.init(contentRect: .zero, styleMask: style, backing: .buffered, defer: true)

        isFloatingPanel = layer == .floating
        // After `isFloatingPanel`, which sets its own level.
        level = layer == .floating ? .statusBar : .normal
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        // `.none` keeps the panel out of screen shares and recordings that
        // honour it. ScreenCaptureKit on recent macOS may not; see the spec.
        sharingType = hideFromSharing ? .none : .readOnly
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        animationBehavior = .utilityWindow
        isMovable = false
    }

    public override var canBecomeKey: Bool { takesFocus || allowKeyForReply }

    public override var canBecomeMain: Bool { takesFocus }
}
