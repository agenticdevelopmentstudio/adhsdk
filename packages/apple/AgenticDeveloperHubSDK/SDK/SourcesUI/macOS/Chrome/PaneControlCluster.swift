import AppKit
import AgenticDeveloperHubSDK

/// The close / minimize / zoom row at the leading edge of a pane's title bar,
/// and a fourth, Move, for a host that can rearrange its panes.
///
/// Deliberately in the same left-to-right order, and with the same meanings, as
/// the three buttons at the leading edge of a window's title bar. A pane is a
/// window-shaped thing inside a window, and a reader who has to learn a second
/// arrangement for it has been charged for nothing
/// (`principle-of-least-astonishment`).
///
/// It reports and does not decide. Closing a pane, working out where it may
/// shrink to, and knowing whether it is currently zoomed all belong to whatever
/// is hosting it; this view is told, through `isZoomed`, `isMinimized`,
/// `canMinimize`, `canClose` and `canZoom`, and it renders that.
///
/// Four closures rather than a delegate: there are four events, the host is
/// always exactly one object, and a protocol would make it declare conformance
/// and write four methods to answer three of them.
@MainActor
public final class PaneControlCluster: NSStackView {

    public let closeButton = NSButton()
    public let minimizeButton = NSButton()
    public let zoomButton = NSButton()
    /// Hidden until a host sets `onMove`: only a host that can rearrange its
    /// panes has anything to put in the menu it raises.
    public let moveButton = NSButton()

    public var onClose: (() -> Void)?
    /// Handed the minimize button, because that button is the anchor the
    /// picker popover hangs from and the host would otherwise have to reach
    /// back in for it.
    public var onMinimize: ((NSButton) -> Void)?
    public var onRestore: (() -> Void)?
    public var onZoom: (() -> Void)?
    /// Handed the move button, the anchor its directions menu drops from.
    /// Setting it shows the button; `nil` hides it again.
    public var onMove: ((NSButton) -> Void)? {
        didSet { moveButton.isHidden = onMove == nil }
    }

    /// False when the pane has nowhere to go — the only pane in its tab.
    public var canMove: Bool = true { didSet { applyState() } }

    /// Flips the zoom glyph and its tooltip. Set by the host; this view never
    /// infers it from a click, because a host is free to refuse.
    public var isZoomed: Bool = false { didSet { applyState() } }

    /// Turns the middle button into restore — glyph, tooltip, action and
    /// accessibility identifier.
    public var isMinimized: Bool = false { didSet { applyState() } }

    /// False for a pane that fills its tab: there is no sibling to hand the
    /// space to. Ignored while minimized, because restoring has to stay
    /// reachable even if the tree changed shape underneath.
    public var canMinimize: Bool = true { didSet { applyState() } }

    /// False for a pane its container will not give up — the one pane a tab is
    /// required to have. A live-looking button that refuses every click reads as
    /// a broken pane; a dim one reads as a protected pane, which is what it is
    /// (`principle-of-least-astonishment`).
    public var canClose: Bool = true { didSet { applyState() } }

    /// False for a pane its host will not zoom — one a layout relationship
    /// keeps beside another pane, which never takes over the tab. Dim for the
    /// same reason as `canClose`. Ignored while zoomed, so unzooming stays
    /// reachable whatever changed underneath.
    public var canZoom: Bool = true { didSet { applyState() } }

    public init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        orientation = .horizontal
        spacing = 2
        alignment = .centerY
        setHuggingPriority(.required, for: .horizontal)

        configure(closeButton, action: #selector(closeTapped))
        configure(minimizeButton, action: #selector(minimizeTapped))
        configure(zoomButton, action: #selector(zoomTapped))
        configure(moveButton, action: #selector(moveTapped))

        closeButton.accessibilityID("pane.close")
        closeButton.setAccessibilityLabel("Close Pane")
        closeButton.toolTip = "Close Pane"
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Pane")

        moveButton.accessibilityID("pane.move")
        moveButton.setAccessibilityLabel("Move Pane")
        moveButton.toolTip = "Move Pane"
        moveButton.image = NSImage(
            systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right",
            accessibilityDescription: "Move Pane")
        moveButton.isHidden = true

        // A hidden arranged view is detached, so a pane with no Move keeps
        // the three-button row it always had.
        for button in [closeButton, minimizeButton, zoomButton, moveButton] {
            addArrangedSubview(button)
        }

        applyState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func configure(_ button: NSButton, action: Selector) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.target = self
        button.action = action
        button.observeTheme { button, palette in
            button.contentTintColor = Self.tint(for: button, in: palette)
        }
    }

    /// A disabled button has to *look* disabled. `isBordered = false` above
    /// buys the borderless look the title bar wants, and costs AppKit's own
    /// dimming of a disabled control along with it — a borderless button draws
    /// its template image in `contentTintColor` whether or not it is enabled,
    /// so without this the minimize button greys out functionally and not
    /// visually, and a pane that fills its tab shows a button that looks live
    /// and does nothing. The sibling `PaneMinimizePicker` already resolves its
    /// tint this way; this is the same rule, in one place both call sites can
    /// reach (`dry`).
    private static func tint(for button: NSButton, in palette: SemanticPalette) -> NSColor {
        palette.nsColor(button.isEnabled ? .secondaryText : .tertiaryText)
    }

    /// One place that turns the flags into what the buttons look like.
    /// Spreading it across the three `didSet`s would make the middle button's
    /// appearance depend on the order the flags were assigned in.
    private func applyState() {
        closeButton.isEnabled = canClose
        closeButton.contentTintColor = Self.tint(
            for: closeButton, in: resolvedThemeScope.palette)

        if isMinimized {
            minimizeButton.accessibilityID("pane.restore")
            minimizeButton.setAccessibilityLabel("Restore Pane")
            minimizeButton.toolTip = "Restore Pane"
            minimizeButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Restore Pane")
            minimizeButton.isEnabled = true
        } else {
            minimizeButton.accessibilityID("pane.minimize")
            minimizeButton.setAccessibilityLabel("Minimize Pane")
            minimizeButton.toolTip = "Minimize Pane"
            minimizeButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Minimize Pane")
            minimizeButton.isEnabled = canMinimize
        }
        // `observeTheme` fires on theme changes, and enabling is not one — so
        // the tint has to be re-resolved here, at the point `isEnabled` moved.
        minimizeButton.contentTintColor = Self.tint(
            for: minimizeButton, in: resolvedThemeScope.palette)

        let zoomTitle = isZoomed ? "Unzoom Pane" : "Zoom Pane"
        let zoomSymbol = isZoomed
            ? "arrow.down.right.and.arrow.up.left"
            : "arrow.up.left.and.arrow.down.right"
        zoomButton.setAccessibilityLabel(zoomTitle)
        zoomButton.toolTip = zoomTitle
        zoomButton.image = NSImage(systemSymbolName: zoomSymbol, accessibilityDescription: zoomTitle)
        zoomButton.accessibilityID("pane.zoom")
        zoomButton.isEnabled = canZoom || isZoomed
        zoomButton.contentTintColor = Self.tint(
            for: zoomButton, in: resolvedThemeScope.palette)

        moveButton.isEnabled = canMove
        moveButton.contentTintColor = Self.tint(
            for: moveButton, in: resolvedThemeScope.palette)
    }

    @objc private func closeTapped() { onClose?() }
    @objc private func zoomTapped() { onZoom?() }
    @objc private func moveTapped() { onMove?(moveButton) }

    @objc private func minimizeTapped() {
        if isMinimized {
            onRestore?()
        } else {
            onMinimize?(minimizeButton)
        }
    }
}
