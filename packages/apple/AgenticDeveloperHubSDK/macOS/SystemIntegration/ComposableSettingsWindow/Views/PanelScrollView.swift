import AppKit
import AgenticDeveloperHubSDKCoreUI

extension ComposableSettings {

    /// The canonical scroll host for panel content: a flipped document so content
    /// top-anchors (settings read top-to-bottom), content width pinned to the
    /// viewport (fills + wrapping labels wrap; the content's fitting size never
    /// drives the pane or the window) and height at least the viewport (fills, or
    /// scrolls vertically when taller). `SplitViewController` wraps every
    /// non-self-scrolling panel in one; master/detail pickers host their detail
    /// panes in one so rebuilt content can never tug the divider.
    @MainActor
    public final class PanelScrollView: NSScrollView {

        private let document = TopAnchoredFlippedView()

        public init() {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false
            drawsBackground = false
            hasVerticalScroller = true
            hasHorizontalScroller = true
            autohidesScrollers = true
            document.translatesAutoresizingMaskIntoConstraints = false
            documentView = document
            NSLayoutConstraint.activate([
                document.topAnchor.constraint(equalTo: contentView.topAnchor),
                document.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            ])
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError() }

        /// The hosted content's width floor and its fill-the-pane preference,
        /// both constants kept at the visible width by `tile()`.
        private var contentWidthConstraints: [NSLayoutConstraint] = []

        private var visibleWidth: CGFloat { max(contentView.bounds.width, 0) }

        public override func tile() {
            super.tile()
            let width = visibleWidth
            for constraint in contentWidthConstraints where constraint.constant != width {
                constraint.constant = width
            }
        }

        /// Install `view` as the hosted content, replacing any previous content
        /// (and thereby resetting the scroll position to the top).
        public func setContent(_ view: NSView) {
            document.subviews.forEach { $0.removeFromSuperview() }
            contentWidthConstraints = []
            view.translatesAutoresizingMaskIntoConstraints = false
            document.addSubview(view)
            // The content's width is a *constant* fed from the visible width in
            // `tile()`, never a constraint to the clip view. Tied to the clip
            // view, a row that needs more width (a popup beside two buttons)
            // widened the clip view and, through it, the split this panel sits
            // in — so choosing a panel moved the sidebar the reader had sized.
            // A constant cannot reach back up: the content fills the visible
            // width at a priority wrapping labels (250) yield to, and anything
            // that truly cannot fit (750) scrolls sideways instead.
            let minimum = view.widthAnchor.constraint(greaterThanOrEqualToConstant: visibleWidth)
            let fill = view.widthAnchor.constraint(equalToConstant: visibleWidth)
            fill.priority = .defaultHigh - 1
            contentWidthConstraints = [minimum, fill]
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: document.topAnchor),
                view.leadingAnchor.constraint(equalTo: document.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: document.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: document.bottomAnchor),
                minimum,
                fill,
                view.heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor)
            ])
        }
    }
}
