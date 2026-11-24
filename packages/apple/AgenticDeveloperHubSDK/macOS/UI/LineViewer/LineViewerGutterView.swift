import AppKit

/// The line viewer's gutter: a subview of the document view that the document
/// view keeps at the visible left edge, so the gutter columns stay in place
/// while long lines scroll sideways under it. It draws through its host, which
/// owns the rows, the columns and the palette, and lets clicks fall through to
/// the host, which decides whether a point is a gutter click.
///
/// It clips to its bounds. Since macOS 14 `clipsToBounds` defaults to false,
/// and AppKit then hands `draw` a dirty rect as wide as the host's, so the
/// gutter's background fill painted over the whole text area it sits above.
@MainActor
final class LineViewerGutterView: NSView {

    weak var host: LineViewerView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        host?.drawGutter(in: dirtyRect.intersection(bounds), width: bounds.width)
    }
}
