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
///
/// Every notice panel is non-activating, the full-screen one included: a
/// non-activating panel can be key without activating its app, which is how
/// Spotlight takes typing without stealing the frontmost app. It also means
/// nothing waits on `NSApp.activate()`, which is only a request on macOS 14
/// and later.
public class NoticePanel: NSPanel {

    public let takesFocus: Bool

    /// Set by a card's reply field when the user clicks into it; cleared when
    /// the reply is sent or cancelled.
    public var allowKeyForReply = false

    public init(layer: NoticeProfile.Layer, hideFromSharing: Bool, takesFocus: Bool = false) {
        self.takesFocus = takesFocus
        super.init(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)

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

    /// Applies the "hide from screen sharing" setting to the notice panels
    /// already on screen, so changing it takes effect without waiting for the
    /// next notice. New panels read it from the rules when they are built.
    /// Windows that are not notice panels are left alone. The default reads
    /// `NSApplication.shared`, not `NSApp`: `NSApp` is nil until something
    /// creates the shared application, and a host may call this that early.
    public static func applyHideFromSharing(
        _ hide: Bool, to windows: [NSWindow] = NSApplication.shared.windows
    ) {
        for case let panel as NoticePanel in windows {
            panel.sharingType = hide ? .none : .readOnly
        }
    }

    public override var canBecomeKey: Bool { takesFocus || allowKeyForReply }

    /// A click into a view that takes typing must make the panel key-capable
    /// before AppKit sees it. `NSWindow.sendEvent` decides whether a panel
    /// clicked into becomes key — and whether a text field's mouse-down is
    /// delivered at all — from `canBecomeKey` at that moment, so asking from
    /// the field's own `mouseDown` is too late: the click never reaches it.
    public override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            keyRequester(at: event.locationInWindow)?.panelWillDeliverClick()
        }
        super.sendEvent(event)
    }

    /// The view under `point` (window coordinates), or its nearest ancestor,
    /// that asks for the keyboard when clicked. The field editor inside a
    /// field being edited resolves to the field.
    func keyRequester(at point: NSPoint) -> NoticePanelKeyRequester? {
        guard let content = contentView else { return nil }
        let inSuperview = content.superview?.convert(point, from: nil) ?? point
        var view = content.hitTest(inSuperview)
        while let current = view {
            if let requester = current as? NoticePanelKeyRequester { return requester }
            view = current.superview
        }
        return nil
    }

    public override var canBecomeMain: Bool { takesFocus }

    /// Hands the keyboard back to the app the user was in, once a reply is
    /// sent or cancelled. Reordering a panel that can no longer become key
    /// lets the window server give key to the active app; it never calls
    /// `resignKey()` or `NSApp.deactivate()`. A full-screen panel keeps the
    /// keyboard, with its backdrop as first responder so Esc still snoozes.
    func relinquishKey() {
        allowKeyForReply = false
        if takesFocus {
            makeFirstResponder(contentView)
            return
        }
        makeFirstResponder(nil)
        handOffKey(self)
    }

    /// How a reply field asks for the keyboard: makes the panel key, then
    /// reports whether it took. The answer is read on the next default-mode
    /// turn of the run loop, after the click that started the reply has been
    /// tracked, since a panel clicked into may only become key on mouse-up.
    /// `false` means the window server refused (an inactive agent app, a panel
    /// off screen), and no resign notification will ever follow. A seam, so
    /// tests never make a real window key.
    typealias KeyTaker = @MainActor (NoticePanel, @escaping @MainActor @Sendable (Bool) -> Void) -> Void
    final var takeKey: KeyTaker = { panel, done in
        panel.makeKey()
        RunLoop.main.perform(inModes: [.default]) {
            MainActor.assumeIsolated { done(panel.isKeyWindow) }
        }
    }

    /// How `relinquishKey()` returns key. A seam, so tests never reorder a
    /// real window.
    final var handOffKey: @MainActor (NoticePanel) -> Void = { panel in
        guard panel.isKeyWindow else { return }
        panel.orderOut(nil)
        panel.orderFrontRegardless()
    }
}

/// A view in a notice panel that needs the keyboard when clicked — the reply
/// field. The panel tells it before delivering the click, so it can let the
/// panel become key first.
@MainActor
protocol NoticePanelKeyRequester: AnyObject {
    func panelWillDeliverClick()
}
