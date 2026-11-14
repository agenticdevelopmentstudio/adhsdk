import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// The commit list's graph column for one row (recipe
/// `ui/components/display/commit-graph-cell`): the lines entering from the top
/// edge, the lines leaving the commit's centre for the bottom edge, and the
/// commit's node — filled, or a ring for a merge — in the theme's lane colours.
///
/// It draws a `CommitGraphLayout` row and computes nothing; the table that
/// hosts one per row supplies the height, and the cell paints no background so
/// the row's own (selection included) shows through.
@MainActor
public final class CommitGraphCellView: NSView {
    public static let columnWidth: CGFloat = 14
    private static let lineWidth: CGFloat = 2
    private static let nodeRadius: CGFloat = 4

    public var row: CommitGraphLayout<String>.Row? {
        didSet {
            guard row != oldValue else { return }
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }
    }

    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityIdentifier("commitGraph.cell")
        observeTheme { view, palette in
            view.palette = palette
            view.needsDisplay = true
        }
    }

    public convenience init() { self.init(frame: .zero) }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    public override var isFlipped: Bool { true }

    public override var intrinsicContentSize: NSSize {
        NSSize(width: CGFloat(row?.width ?? 0) * Self.columnWidth, height: NSView.noIntrinsicMetric)
    }

    /// Every bottom segment leaving the commit's column is one parent edge
    /// (pass-through lines never start there), so two or more mean a merge.
    static func isMerge(_ row: CommitGraphLayout<String>.Row) -> Bool {
        row.bottom.lazy.filter { $0.from == row.column }.prefix(2).count > 1
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let row else { return }
        let midY = bounds.midY
        let centre = NSPoint(x: Self.x(row.column), y: midY)

        // Lines stop at the node's edge, so a merge's ring stays hollow and
        // nothing is painted over whatever background the host draws.
        NSGraphicsContext.saveGraphicsState()
        let clip = NSBezierPath(rect: bounds)
        clip.append(Self.circle(centre, radius: Self.nodeRadius))
        clip.windingRule = .evenOdd
        clip.addClip()
        for segment in row.top {
            stroke(segment, from: bounds.minY, to: midY)
        }
        for segment in row.bottom {
            stroke(segment, from: midY, to: bounds.maxY)
        }
        NSGraphicsContext.restoreGraphicsState()

        let colour = NSColor(palette.laneColor(row.lane))
        if Self.isMerge(row) {
            let ring = Self.circle(centre, radius: Self.nodeRadius - Self.lineWidth / 2)
            ring.lineWidth = Self.lineWidth
            colour.setStroke()
            ring.stroke()
        } else {
            colour.setFill()
            Self.circle(centre, radius: Self.nodeRadius).fill()
        }
    }

    private func stroke(_ segment: CommitGraphLayout<String>.Segment, from startY: CGFloat, to endY: CGFloat) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: Self.x(segment.from), y: startY))
        path.line(to: NSPoint(x: Self.x(segment.to), y: endY))
        path.lineWidth = Self.lineWidth
        path.lineCapStyle = .round
        NSColor(palette.laneColor(segment.lane)).setStroke()
        path.stroke()
    }

    private static func x(_ column: Int) -> CGFloat {
        (CGFloat(column) + 0.5) * columnWidth
    }

    private static func circle(_ centre: NSPoint, radius: CGFloat) -> NSBezierPath {
        NSBezierPath(ovalIn: NSRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
    }
}
