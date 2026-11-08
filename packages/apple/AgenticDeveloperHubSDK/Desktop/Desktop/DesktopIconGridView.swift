import AppKit

/// The Desktop's icon surface for the large and small icon modes. Flipped, so
/// icon origins share `DesktopIconLayout`'s top-left coordinates.
final class DesktopIconGridView: NSView {
    var onOpen: ((String) -> Void)?
    /// Called once per drag, with the clamped final origin.
    var onMoveIcon: ((String, CGPoint) -> Void)?

    private(set) var selectedIdentifier: String?
    private var apps: [DesktopApp] = []
    private var iconViews: [String: DesktopIconView] = [:]
    private var metrics: DesktopIconLayout.Metrics = .large
    private var keepArranged = true
    private var savedPositions: [String: CGPoint] = [:]
    private var dragging: (id: String, grabOffset: CGSize, moved: Bool)?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Origins of the current icon frames, by App identifier.
    var iconOrigins: [String: CGPoint] {
        iconViews.mapValues { $0.frame.origin }
    }

    private var layoutEngine: DesktopIconLayout {
        DesktopIconLayout(metrics: metrics, containerSize: bounds.size)
    }

    /// Apps arrive sorted by name from the view controller.
    private var sortedIdentifiers: [String] { apps.map { $0.descriptor.identifier } }

    func configure(
        apps: [DesktopApp],
        metrics: DesktopIconLayout.Metrics,
        keepArranged: Bool,
        positions: [String: CGPoint]
    ) {
        let appsChanged = apps.map { $0.descriptor.identifier } != self.apps.map { $0.descriptor.identifier }
        let metricsChanged = metrics.iconSize != self.metrics.iconSize
        self.apps = apps
        self.metrics = metrics
        self.keepArranged = keepArranged
        self.savedPositions = positions
        if appsChanged || metricsChanged { rebuildIconViews() }
        needsLayout = true
    }

    private func rebuildIconViews() {
        iconViews.values.forEach { $0.removeFromSuperview() }
        iconViews = [:]
        for app in apps {
            let view = DesktopIconView(app: app, metrics: metrics)
            iconViews[app.descriptor.identifier] = view
            addSubview(view)
        }
        if let selectedIdentifier, iconViews[selectedIdentifier] == nil {
            self.selectedIdentifier = nil
        }
        updateSelection()
    }

    override func layout() {
        super.layout()
        let ids = sortedIdentifiers
        let origins = keepArranged
            ? layoutEngine.arrangedOrigins(for: ids)
            : layoutEngine.freeOrigins(for: ids, saved: savedPositions)
        for (id, view) in iconViews where dragging?.id != id {
            if let origin = origins[id] {
                view.frame = NSRect(origin: origin, size: metrics.cellSize)
            }
        }
    }

    func select(_ identifier: String?) {
        guard identifier != selectedIdentifier else { return }
        selectedIdentifier = identifier
        updateSelection()
    }

    private func updateSelection() {
        for (id, view) in iconViews { view.isSelected = id == selectedIdentifier }
    }

    private func identifier(at point: CGPoint) -> String? {
        // Later subviews draw on top, so test from the end.
        subviews.reversed().compactMap { $0 as? DesktopIconView }.first { $0.frame.contains(point) }?.appIdentifier
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        guard let id = identifier(at: point) else {
            select(nil)
            return
        }
        select(id)
        if event.clickCount >= 2 {
            onOpen?(id)
            return
        }
        beginDrag(id: id, at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        moveDrag(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseUp(with event: NSEvent) {
        endDrag()
    }

    /// Starts dragging an icon. Only free mode drags.
    func beginDrag(id: String, at point: CGPoint) {
        guard !keepArranged, let view = iconViews[id] else { return }
        let grab = CGSize(width: point.x - view.frame.origin.x, height: point.y - view.frame.origin.y)
        dragging = (id, grab, false)
    }

    func moveDrag(to point: CGPoint) {
        guard let current = dragging, let view = iconViews[current.id] else { return }
        view.frame.origin = layoutEngine.clamp(CGPoint(
            x: point.x - current.grabOffset.width,
            y: point.y - current.grabOffset.height
        ))
        dragging?.moved = true
    }

    /// Reports the final origin, but only when the icon actually moved.
    func endDrag() {
        guard let finished = dragging else { return }
        dragging = nil
        guard finished.moved, let view = iconViews[finished.id] else { return }
        onMoveIcon?(finished.id, view.frame.origin)
    }

    override func keyDown(with event: NSEvent) {
        let isReturn = event.keyCode == 36 || event.keyCode == 76
        if isReturn, let selectedIdentifier {
            onOpen?(selectedIdentifier)
        } else {
            super.keyDown(with: event)
        }
    }
}
