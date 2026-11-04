import AppKit

/// Hosts one view controller — below the window's safe area, or over the whole
/// height — on a backdrop that fills the whole pane, the strip behind the clear
/// titlebar included.
@MainActor
final class SafeAreaHostViewController: NSViewController {

    private let child: NSViewController
    private let pinsToSafeArea: Bool

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
        let horizontal = [
            childView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ]
        for constraint in horizontal { constraint.priority = .defaultHigh }

        NSLayoutConstraint.activate(horizontal + [
            childView.topAnchor.constraint(
                equalTo: pinsToSafeArea ? container.safeAreaLayoutGuide.topAnchor : container.topAnchor),
            childView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.view = container
    }
}
