import AppKit

/// The line viewer's gutter: a subview of the document view that the document
/// view keeps at the visible left edge, so the gutter columns stay in place
/// while long lines scroll sideways under it. It draws through its host, which
/// owns the rows, the columns and the palette, and lets clicks fall through to
/// the host, which decides whether a point is a gutter click.
@MainActor
final class LineViewerGutterView: NSView {

    weak var host: LineViewerView?

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        host?.drawGutter(in: dirtyRect, width: bounds.width)
    }
}
