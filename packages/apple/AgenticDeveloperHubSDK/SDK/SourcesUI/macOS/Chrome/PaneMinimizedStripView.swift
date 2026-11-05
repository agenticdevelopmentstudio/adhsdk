import AppKit

/// What a pane looks like when it has minimized sideways: a rail one icon wide,
/// carrying whatever glyph the pane draws itself as and a way back.
///
/// Content that has no opinion about how it looks minimized still gets a rail,
/// with `defaultSymbolName`. An empty strip would be a control the user cannot
/// identify and therefore cannot decide to restore.
///
/// There is no matching view for minimizing to the top or bottom, because that
/// state *is* the title bar with nothing under it — a second view drawing the
/// same thing would be a second place to change it (`dry`).
@MainActor
public final class PaneMinimizedStripView: NSView {

    /// One small icon plus its breathing room. Fixed, so a row of minimized
    /// panes lines up.
    public static let thickness: CGFloat = 28

    /// For content that does not implement `PaneMinimizedRepresenting` — a
    /// dashed square reads as "a pane is here" without claiming to be anything
    /// in particular.
    ///
    /// `nonisolated` for the same reason `WindowDrawer.defaultContentWidth` is:
    /// it is the default argument of `init(edge:symbolName:tooltip:)` below,
    /// and a default-argument expression compiles as a standalone, non-isolated
    /// function regardless of the initializer's own actor. Reading a
    /// `@MainActor`-isolated static from one is a warning today and an error
    /// under the Swift 6 language mode.
    public static nonisolated let defaultSymbolName = "square.dashed"

    public let restoreButton = NSButton()
    public let glyphView = NSImageView()

    public var onRestore: (() -> Void)?

    public var symbolName: String {
        didSet { applyGlyph() }
    }

    public var tooltip: String {
        didSet { glyphView.toolTip = tooltip.isEmpty ? nil : tooltip }
    }

    private let background = ThemedBackgroundView(role: .elevatedSurface)
    private let hairline = ThemedSeparatorView(role: .border, axis: .vertical)

    /// - Parameter edge: which side the pane docked to. Only used to put the
    ///   hairline on the side facing the rest of the layout rather than on the
    ///   window edge, where it would draw a line against a line.
    public init(
        edge: PaneEdge,
        symbolName: String = PaneMinimizedStripView.defaultSymbolName,
        tooltip: String = ""
    ) {
        self.symbolName = symbolName
        self.tooltip = tooltip
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        restoreButton.bezelStyle = .accessoryBarAction
        restoreButton.isBordered = false
        restoreButton.imagePosition = .imageOnly
        restoreButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Restore Pane")
        restoreButton.toolTip = "Restore Pane"
        restoreButton.setAccessibilityLabel("Restore Pane")
        restoreButton.accessibilityID("pane.restore")
        restoreButton.target = self
        restoreButton.action = #selector(restoreTapped)
        restoreButton.observeTheme { button, palette in
            button.contentTintColor = palette.nsColor(.secondaryText)
        }

        glyphView.imageScaling = .scaleProportionallyDown
        glyphView.accessibilityID("pane.minimized.glyph")
        glyphView.observeTheme { view, palette in
            view.contentTintColor = palette.nsColor(.secondaryText)
        }

        for child in [background, hairline, restoreButton, glyphView] as [NSView] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }

        // The strip docks against `edge`, so the layout it shrank out of is on
        // the other side — which is where the hairline belongs.
        let inwardSide = edge == .leading
            ? hairline.trailingAnchor.constraint(equalTo: trailingAnchor)
            : hairline.leadingAnchor.constraint(equalTo: leadingAnchor)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.thickness),

            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            hairline.topAnchor.constraint(equalTo: topAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            inwardSide,

            restoreButton.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            restoreButton.centerXAnchor.constraint(equalTo: centerXAnchor),

            glyphView.topAnchor.constraint(equalTo: restoreButton.bottomAnchor, constant: 6),
            glyphView.centerXAnchor.constraint(equalTo: centerXAnchor),
            glyphView.widthAnchor.constraint(equalToConstant: 16),
            glyphView.heightAnchor.constraint(equalToConstant: 16)
        ])

        applyGlyph()
        glyphView.toolTip = tooltip.isEmpty ? nil : tooltip
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func applyGlyph() {
        glyphView.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: tooltip.isEmpty ? "Minimized Pane" : tooltip
        ) ?? NSImage(
            systemSymbolName: Self.defaultSymbolName,
            accessibilityDescription: "Minimized Pane"
        )
    }

    @objc private func restoreTapped() { onRestore?() }
}
