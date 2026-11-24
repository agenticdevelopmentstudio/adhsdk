import AppKit

/// Hosts one view controller — below the window's safe area, or over the whole
/// height — on a backdrop that fills the whole pane, the strip behind the clear
/// titlebar included.
@MainActor
final class SafeAreaHostViewController: NSViewController {

    private let child: NSViewController
    private let pinsToSafeArea: Bool

    /// How far the child is held off each edge (the top one measured from
    /// the safe area when `pinsToSafeArea`). Zero by default.
    var insets = NSEdgeInsetsZero {
        didSet { applyInsets() }
    }

    private var leadingEdge: NSLayoutConstraint?
    private var trailingEdge: NSLayoutConstraint?
    private var topEdge: NSLayoutConstraint?
    private var bottomEdge: NSLayoutConstraint?

    var backdropColor: NSColor = .clear {
        didSet { view.layer?.backgroundColor = backdropColor.cgColor }
    }

    /// - Parameter pinsToSafeArea: Whether the child starts below the
    ///   titlebar, or is given the whole height to place things itself.
    init(child: NSViewController, pinsToSafeArea: Bool = true) {
        self.child = child
        self.pinsToSafeArea = pinsToSafeArea
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        // A shelf sliding in is narrower than its contents; show the part
        // that fits rather than letting the rest spill over the panes.
        container.clipsToBounds = true
        addChild(child)
        let childView = child.view
        childView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(childView)

        // The leading and trailing edges give below required, as the
        // Conversations shelf's do: a collapsing pane animates to zero width,
        // and a required edge is one AppKit has to break, loudly, to get there.
        let leading = childView.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        let trailing = childView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        let top = childView.topAnchor.constraint(
            equalTo: pinsToSafeArea ? container.safeAreaLayoutGuide.topAnchor : container.topAnchor)
        let bottom = childView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        leading.priority = .defaultHigh
        trailing.priority = .defaultHigh
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
        (leadingEdge, trailingEdge, topEdge, bottomEdge) = (leading, trailing, top, bottom)
        self.view = container
        applyInsets()
    }

    private func applyInsets() {
        leadingEdge?.constant = insets.left
        trailingEdge?.constant = -insets.right
        topEdge?.constant = insets.top
        bottomEdge?.constant = -insets.bottom
    }
}
