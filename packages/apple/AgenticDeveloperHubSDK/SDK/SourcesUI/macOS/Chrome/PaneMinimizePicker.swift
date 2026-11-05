import AppKit

/// The four arrows, arranged as a cross:
///
/// ```
///       ↑
///     ←   →
///       ↓
/// ```
///
/// An `NSGridView` rather than nested stacks, because the shape *is* the
/// meaning: a reader sees four directions around a centre, and a grid is the
/// native control that says that structurally (`native-controls`). Nested
/// stacks would draw the same picture while claiming it is three rows.
///
/// It renders the offered set; it does not compute it. Which edges a given pane
/// may shrink toward comes from the layout tree, and this view has never heard
/// of one.
@MainActor
public final class PaneMinimizeCrossView: NSView {

    /// Which arrows are clickable. Settable rather than fixed at init: a pane's
    /// legal edges change when the tree around it does, and rebuilding the
    /// cross to say so would drop the popover holding it.
    public var availableEdges: Set<PaneEdge> {
        didSet { applyAvailability() }
    }

    public var onPick: ((PaneEdge) -> Void)?

    /// Reported when the user backs out — escape, today. Separate from
    /// `onPick` because leaving without choosing is not choosing: routing it
    /// through `onPick` would minimize the pane the user just decided not to.
    public var onCancel: (() -> Void)?

    private var buttons: [PaneEdge: NSButton] = [:]

    public init(availableEdges: Set<PaneEdge>) {
        self.availableEdges = availableEdges
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        for edge in PaneEdge.allCases {
            buttons[edge] = makeButton(for: edge)
        }

        let filler = { NSView() }
        let grid = NSGridView(views: [
            [filler(), button(for: .top), filler()],
            [button(for: .leading), filler(), button(for: .trailing)],
            [filler(), button(for: .bottom), filler()]
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 2
        grid.columnSpacing = 2
        addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            grid.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        applyAvailability()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Never optional: there are exactly four edges and every one is built in
    /// `init`, so an optional return would be a `nil` no caller can handle and
    /// every caller has to unwrap (`fail-fast`).
    public func button(for edge: PaneEdge) -> NSButton {
        guard let button = buttons[edge] else {
            fatalError("PaneMinimizeCrossView built without a button for \(edge)")
        }
        return button
    }

    private func makeButton(for edge: PaneEdge) -> NSButton {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: edge.arrowSymbolName, accessibilityDescription: edge.displayName)
        button.toolTip = edge.displayName
        button.setAccessibilityLabel(edge.displayName)
        button.accessibilityID("pane.minimize.\(edge.rawValue)")
        button.target = self
        button.action = #selector(arrowTapped(_:))
        button.observeTheme { button, palette in
            button.contentTintColor = palette.nsColor(button.isEnabled ? .primaryText : .tertiaryText)
        }
        return button
    }

    private func applyAvailability() {
        for (edge, button) in buttons {
            button.isEnabled = availableEdges.contains(edge)
            button.contentTintColor = resolvedThemeScope.palette
                .nsColor(button.isEnabled ? .primaryText : .tertiaryText)
        }
    }

    @objc private func arrowTapped(_ sender: NSButton) {
        guard let edge = buttons.first(where: { $0.value === sender })?.key else { return }
        onPick?(edge)
    }

    /// The cross is what escape has to reach, so the cross is what takes first
    /// responder. Nothing else in here can: `NSButton` accepts it only under
    /// Full Keyboard Access, so a popover holding four of them and nothing
    /// else has no first responder, never becomes key, and never sees a key
    /// press at all.
    override public var acceptsFirstResponder: Bool { true }

    /// Escape, arriving as `cancelOperation:` down the responder chain — the
    /// same route that dismisses a sheet or a find bar (`native-controls`).
    override public func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

/// The cross, hung off a button in a popover.
///
/// Separate from the cross itself so a test can ask whether the trailing arrow
/// is enabled without opening a popover — that test would be a test of
/// `NSPopover`, not of this feature (`tight-feedback-loops`).
@MainActor
public final class PaneMinimizePicker: NSObject {

    public let crossView: PaneMinimizeCrossView

    public var isShown: Bool { popover.isShown }

    private let popover = NSPopover()

    public init(availableEdges: Set<PaneEdge>, onPick: @escaping (PaneEdge) -> Void) {
        crossView = PaneMinimizeCrossView(availableEdges: availableEdges)
        super.init()

        // Close before reporting: the pane is about to change shape, and a
        // popover anchored to a button inside it would be left pointing at a
        // view that has moved.
        crossView.onPick = { [weak self] edge in
            self?.close()
            onPick(edge)
        }

        let controller = NSViewController()
        controller.view = crossView
        // `.transient` covers a click elsewhere; it does not cover escape,
        // which never reaches a popover that is not in a responder chain.
        crossView.onCancel = { [weak self] in self?.close() }

        popover.contentViewController = controller
        popover.behavior = .transient
    }

    public func show(relativeTo anchor: NSView) {
        popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
        // After showing, because the popover has no window until it is shown.
        crossView.window?.makeFirstResponder(crossView)
    }

    public func close() {
        popover.performClose(nil)
    }
}
