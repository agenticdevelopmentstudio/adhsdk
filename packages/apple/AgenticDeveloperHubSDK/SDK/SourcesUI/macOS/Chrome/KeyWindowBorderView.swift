import AppKit
import AgenticDeveloperHubSDK

/// A hairline around the inside of a window, in the theme's accent, that
/// brightens while the window is key.
///
/// A window with no title bar has nothing to say where it ends: against a dark
/// desktop a translucent chat is an edgeless smudge, and against another dark
/// window it is invisible. This draws the edge — faintly, so it reads as the
/// window's own outline rather than a frame around a picture — and uses the
/// only signal a chromeless window has left to say "you are typing into *me*":
/// the same line, brighter.
///
/// Overlaid rather than set as the content view's `layer.borderColor` because a
/// layer border is drawn *inside* the layer's bounds on all four sides at full
/// opacity and cannot be inset by the half point that keeps a 1-point stroke
/// from straddling the pixel grid. It is also click-through — `hitTest` always
/// answers `nil` — so nothing underneath loses a mouse event to it.
@MainActor
public final class KeyWindowBorderView: NSView {

    /// Corner radius of the stroke. The default is AppKit's own window corner
    /// radius; a host that rounds its content differently sets its own.
    public var cornerRadius: CGFloat = 10 { didSet { needsDisplay = true } }

    /// How much of the accent the line carries. Deliberately far apart: the
    /// inactive line has to be quiet enough to read as an edge rather than a
    /// highlight, and the difference between the two is the whole signal.
    public var inactiveAlpha: CGFloat = 0.28 { didSet { needsDisplay = true } }
    public var activeAlpha: CGFloat = 0.85 { didSet { needsDisplay = true } }

    private var accent: NSColor = .clear { didSet { needsDisplay = true } }
    private var themeObserver: ThemePaletteObserver?

    public init() {
        super.init(frame: .zero)
        wantsLayer = true
        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in
            self?.accent = palette.nsColor(.accent)
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Key state is watched per-window rather than through
    /// `NSApp.keyWindow`, and re-subscribed here, because the view is built
    /// before it has a window and may be moved between them.
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.removeObserver(self)
        guard let window else { return }
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(keyStateChanged), name: name, object: window)
        }
        needsDisplay = true
    }

    @objc private func keyStateChanged() { needsDisplay = true }

    /// Never the view that handles a click: it covers the whole window.
    public override func hitTest(_ point: NSPoint) -> NSView? { nil }

    /// The colour the line is actually drawn in. Named rather than folded into
    /// `draw(_:)` so a test can ask what the edge says about key state without
    /// rasterising it.
    var strokeColor: NSColor {
        accent.withAlphaComponent(window?.isKeyWindow == true ? activeAlpha : inactiveAlpha)
    }

    public override func draw(_ dirtyRect: NSRect) {
        // Inset by half the stroke so the line lands *on* the pixel column at
        // the window's edge rather than straddling two of them, which is what
        // turns a 1-point stroke into a 2-point smear.
        let path = NSBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            xRadius: cornerRadius, yRadius: cornerRadius)
        path.lineWidth = 1
        strokeColor.setStroke()
        path.stroke()
    }
}
